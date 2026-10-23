param([Parameter(Mandatory=$true)][string]$JobPath,[switch]$Plan)
$ErrorActionPreference='Stop'
$ProgressPreference='SilentlyContinue'
. (Join-Path $PSScriptRoot 'Sources.ps1')
$job=Get-Content -LiteralPath $JobPath -Raw -Encoding UTF8 | ConvertFrom-Json
$run=Split-Path -Parent $JobPath
$allowed=@('Google.Chrome','Mozilla.Firefox','Opera.Opera','Adobe.Acrobat.Reader.64-bit','WireGuard.WireGuard','Fortinet.VPN','OpenVPNTechnologies.OpenVPN','3CX.Softphone','Microsoft.Office')
$channels=@{O365BusinessRetail='Current';O365ProPlusRetail='Current';HomeBusiness2024Retail='Current';Professional2024Retail='Current';Standard2024Volume='PerpetualVL2024';ProPlus2024Volume='PerpetualVL2024'}
if(!$job.Ids.Count -or @($job.Ids|Select-Object -Unique).Count -ne $job.Ids.Count){throw 'Selection vide ou doublons.'}
foreach($id in $job.Ids){if($id -notin $allowed){throw 'Application non autorisee dans ce catalogue.'}}
if(!$channels.ContainsKey([string]$job.Office)){throw 'Edition Office non reconnue.'}

function Office-Xml {
@"
<Configuration>
 <Add OfficeClientEdition="64" Channel="$($channels[[string]$job.Office])">
  <Product ID="$($job.Office)"><Language ID="fr-fr" /></Product>
 </Add>
 <Display Level="None" AcceptEULA="TRUE" />
 <Updates Enabled="TRUE" />
 <Property Name="FORCEAPPSHUTDOWN" Value="FALSE" />
 <Property Name="AUTOACTIVATE" Value="0" />
</Configuration>
"@
}
function Winget-Arguments($id){
    $arguments=@('install','--id',$id,'--exact','--source','winget','--silent','--accept-package-agreements','--accept-source-agreements','--disable-interactivity')
    if(!$job.Update){$arguments+='--no-upgrade'}
    return $arguments
}
if($Plan){
    $operations=@(foreach($id in $job.Ids){
        if($id -eq 'Microsoft.Office'){@{id=$id;xml=(Office-Xml);source='Microsoft Download Center';latest=$true;arguments=@('/configure','office.xml');silent=$true}}
        elseif($id -eq 'Fortinet.VPN'){@{id=$id;source=if($job.Forti){'Manual override'}else{'Fortinet official regional portal'};automatic=![bool]$job.Forti;arguments=@('/quiet','/norestart','/log','forticlient.log');silent=$true}}
        else{@{id=$id;arguments=@(Winget-Arguments $id);silent=$true}}
    })
    @{operations=$operations;installationStarted=$false}|ConvertTo-Json -Depth 8
    return
}
$state=[ordered]@{completed=0;total=$job.Ids.Count;current='';phase='Préparation';percent=-1;message='Initialisation du moteur…';done=$false;fatal=$false;reboot=$false;stopped=$false;outcomes=@()}
function Save-State {
    $temp=Join-Path $run 'state.tmp'
    [IO.File]::WriteAllText($temp,($state|ConvertTo-Json -Depth 8 -Compress),(New-Object Text.UTF8Encoding($false)))
    Move-Item -LiteralPath $temp -Destination (Join-Path $run 'state.json') -Force
}
function Report($phase,$message,$percent=-1){$state.phase=$phase;$state.message=$message;$state.percent=$percent;Save-State}
function Outcome($id,$status,$code,$detail){
    $state.outcomes+=@{id=$id;status=$status;code=[int]$code;detail=$detail}
    $state.completed++;Save-State
    Add-Content -LiteralPath (Join-Path $run 'bilan.txt') -Value "$id | $status | $code | $detail" -Encoding UTF8
}
function Verify-Signer($file,$publisher,$hash=''){
    if($hash -and (Get-FileHash -LiteralPath $file -Algorithm SHA256).Hash -ne $hash){throw 'Empreinte SHA-256 incorrecte.'}
    $signature=Get-AuthenticodeSignature -LiteralPath $file
    if($signature.Status -ne 'Valid' -or $signature.SignerCertificate.Subject -notmatch $publisher){throw 'Signature numerique de lʼediteur invalide ou inattendue.'}
}
function Download($url,$file,$hosts){
    Report 'Téléchargement' 'Connexion au serveur de téléchargement…'
    $response=$null;$source=$null;$dest=$null
    try{
        $response=Open-PublisherResponse $url $hosts;$length=$response.ContentLength
        $source=$response.GetResponseStream();$dest=[IO.File]::Create($file)
        $buffer=New-Object byte[] 262144;$received=0L;$last=[DateTime]::MinValue
        while(($n=$source.Read($buffer,0,$buffer.Length)) -gt 0){
            $dest.Write($buffer,0,$n);$received+=$n
            if(([DateTime]::Now-$last).TotalMilliseconds -gt 350){
                $percent=if($length -gt 0){[math]::Min(100,[math]::Round(100*$received/$length))}else{-1}
                Report 'Téléchargement' ("Téléchargement · {0:N1} Mo" -f ($received/1MB)) $percent
                $last=[DateTime]::Now
            }
        }
        if($length -ge 0 -and $received -ne $length){throw 'Telechargement incomplet.'}
    }finally{if($dest){$dest.Dispose()};if($source){$source.Dispose()};if($response){$response.Dispose()}}
}
function Record-Source($info,$file){
    @{page=$info.Page;url=$info.Url;version=[string]$info.Version;sha256=(Get-FileHash -LiteralPath $file -Algorithm SHA256).Hash.ToLowerInvariant();file=[IO.Path]::GetFileName($file)}|ConvertTo-Json -Compress|Add-Content -LiteralPath (Join-Path $run 'sources.jsonl') -Encoding UTF8
}
function Run-Hidden($file,$arguments,$prefix,$parseWinget=$false){
    $stdout=Join-Path $run ($prefix+'.stdout.log');$stderr=Join-Path $run ($prefix+'.stderr.log')
    $process=Start-Process -FilePath $file -ArgumentList $arguments -PassThru -WindowStyle Hidden -RedirectStandardOutput $stdout -RedirectStandardError $stderr
    try{
        $unused=$process.Handle
        while(!$process.HasExited){
            if($parseWinget -and (Test-Path -LiteralPath $stdout)){
                try{
                    $content=[IO.File]::ReadAllText($stdout)
                    $installing=$content -match '(?i)(Starting package install|Démarrage de lʼinstallation|Démarrage de l.installation|Successfully installed|Installation réussie)'
                    if($installing){Report 'Installation' 'Installation silencieuse en cours…'}
                    else{
                        $matches=[regex]::Matches($content,'(?<!\d)(\d{1,3}(?:[.,]\d+)?)\s*%')
                        if($matches.Count){$value=[double]::Parse($matches[$matches.Count-1].Groups[1].Value.Replace(',','.'),[Globalization.CultureInfo]::InvariantCulture);if($value -le 100){Report 'Téléchargement' "Téléchargement · $value %" $value}}
                    }
                }catch [IO.IOException]{}
            }
            Start-Sleep -Milliseconds 450
        }
        $process.WaitForExit();return [int]$process.ExitCode
    }finally{$process.Dispose()}
}
function Installed-Forti {
    foreach($root in @('HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall','HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall')){
        if(Test-Path $root){$found=Get-ItemProperty "$root\*" -ErrorAction SilentlyContinue|Where-Object {$_.DisplayName -match '^FortiClient VPN'};if($found){return $true}}
    }
    return $false
}
function Install-Forti {
    if((Installed-Forti) -and !$job.Update){return -1978335135} # 0x8A150061 : deja installe
    $package=$job.Forti
    if(!$package){
        Report 'Recherche de version' 'Recherche du dernier package VPN x64 sur le portail officiel Fortinet…'
        $info=Get-FortiSource
        $package=Join-Path $run $info.FileName
        Download $info.Url $package @('s3.cn-north-1.amazonaws.com.cn','filestore.fortinet.com')
        Report 'Vérification' ('Vérification de FortiClient VPN '+$info.Version+' et de sa signature Fortinet…')
        Test-FortiDownload $package $info.Version
        Record-Source $info $package
        if(Installed-Forti){
            $installedVersions=@(foreach($root in @('HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall','HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall')){
                if(Test-Path $root){Get-ItemProperty "$root\*" -ErrorAction SilentlyContinue|Where-Object {$_.DisplayName -match '^FortiClient VPN'}|ForEach-Object {$v=$null;if([version]::TryParse($_.DisplayVersion,[ref]$v)){$v}}}
            })
            if(!$installedVersions.Count){throw 'Version FortiClient installee inconnue : mise a jour automatique annulee.'}
            if(($installedVersions|Sort-Object -Descending|Select-Object -First 1) -ge $info.Version){return -1978335135}
        }
    }
    if(!(Test-Path -LiteralPath $package)){throw 'Le package FortiClient selectionne est introuvable.'}
    $extension=[IO.Path]::GetExtension($package).ToLowerInvariant()
    if($extension -notin @('.msi','.exe')){throw 'Format de package FortiClient non pris en charge.'}
    $copy=Join-Path $run ('FortiClient-package'+$extension)
    Report 'Vérification' 'Copie et vérification du package FortiClient VPN…'
    Copy-Item -LiteralPath $package -Destination $copy
    Verify-Signer $copy 'O=("?Fortinet(?:,? Inc\.?)?"?|Fortinet Technologies \(Canada\) ULC)(,|$)'
    $log=Join-Path $run 'forticlient-msi.log'
    if($extension -eq '.exe'){
        $version=(Get-Item -LiteralPath $copy).VersionInfo
        if((Get-Item -LiteralPath $copy).Length -lt 20000000 -or $version.FileDescription -match 'online' -or (($version.FileDescription+' '+$version.ProductName+' '+[IO.Path]::GetFileName($package)) -notmatch 'FortiClient.?VPN')){throw 'Le lanceur en ligne ne permet pas une installation silencieuse garantie. Utilisez le package VPN complet.'}
        Report 'Installation' 'Installation silencieuse de FortiClient VPN…'
        $code=Run-Hidden $copy @('/quiet','/norestart','/log',('"'+$log+'"')) 'fortinet'
    }else{
        $installer=New-Object -ComObject WindowsInstaller.Installer
        $database=$installer.GetType().InvokeMember('OpenDatabase','InvokeMethod',$null,$installer,@($copy,0))
        $view=$database.GetType().InvokeMember('OpenView','InvokeMethod',$null,$database,@("SELECT Value FROM Property WHERE Property='ProductName'"))
        [void]$view.GetType().InvokeMember('Execute','InvokeMethod',$null,$view,$null)
        $record=$view.GetType().InvokeMember('Fetch','InvokeMethod',$null,$view,$null)
        $name=$record.GetType().InvokeMember('StringData','GetProperty',$null,$record,1)
        foreach($com in @($record,$view,$database,$installer)){[void][Runtime.InteropServices.Marshal]::FinalReleaseComObject($com)}
        if($name -notmatch 'FortiClient.?VPN'){throw 'Ce MSI ne correspond pas a FortiClient VPN.'}
        Report 'Installation' 'Installation silencieuse de FortiClient VPN…'
        $code=Run-Hidden "$env:SystemRoot\System32\msiexec.exe" @('/i',('"'+$copy+'"'),'/qn','/norestart','REBOOT=ReallySuppress','DONT_PROMPT_REBOOT=1','/L*v',('"'+$log+'"')) 'fortinet'
    }
    if($code -in @(0,3010) -and !(Installed-Forti)){throw 'Le package sʼest termine mais FortiClient VPN nʼa pas ete detecte.'}
    return $code
}
function Install-Office {
    foreach($key in @('HKLM:\SOFTWARE\Microsoft\Office\ClickToRun\Configuration','HKLM:\SOFTWARE\WOW6432Node\Microsoft\Office\ClickToRun\Configuration')){
        $existing=Get-ItemProperty -LiteralPath $key -ErrorAction SilentlyContinue
        if($existing.ProductReleaseIds){
            if(([string]$existing.ProductReleaseIds -split ',') -contains [string]$job.Office){
                if(!$job.Update){return -1978335135}
                if($existing.Platform -and $existing.Platform -ne 'x64'){throw 'Office 32 bits est deja present. La mise a jour x64 necessite une migration manuelle.'}
            }else{throw 'Une autre edition Office est deja presente. Aucune desinstallation automatique nʼa ete effectuee.'}
        }
    }
    $setup=Join-Path $run 'office-setup.exe'
    Report 'Recherche de version' 'Recherche du dernier Office Deployment Tool chez Microsoft…'
    $info=Get-OfficeSource
        $odt=Join-Path $run 'OfficeDeploymentTool.exe'
        Download $info.Url $odt @('download.microsoft.com')
        Report 'Vérification' 'Vérification de lʼoutil officiel Microsoft…'
        Verify-Signer $odt 'O=Microsoft Corporation'
        Record-Source $info $odt
        $code=Run-Hidden $odt @('/quiet',('/extract:"'+$run+'"')) 'office-extract'
        if($code -ne 0){throw "Extraction Office : code $code."}
        Copy-Item -LiteralPath (Join-Path $run 'setup.exe') -Destination $setup
        Verify-Signer $setup 'O=Microsoft Corporation'
    $xml=Join-Path $run 'office.xml';[IO.File]::WriteAllText($xml,(Office-Xml),(New-Object Text.UTF8Encoding($false)))
    Report 'Installation' 'Téléchargement et installation Office en arrière-plan. Cette étape peut être longue.'
    $code=Run-Hidden $setup @('/configure',('"'+$xml+'"')) 'office'
    if($code -in @(0,3010)){
        $installed=Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Office\ClickToRun\Configuration' -ErrorAction SilentlyContinue
        if((([string]$installed.ProductReleaseIds) -split ',') -notcontains [string]$job.Office){throw 'Office nʼa pas ete detecte dans lʼedition demandee.'}
    }
    return $code
}
$wingetRefreshed=$false
try{
    Save-State
    foreach($id in $job.Ids){
        if(Test-Path -LiteralPath (Join-Path $run 'stop.request')){$state.stopped=$true;break}
        $state.current=$id
        Report 'Préparation' 'Préparation et vérification des prérequis…'
        try{
            if($job.Simulate){
                Report 'Téléchargement' 'Démonstration · téléchargement simulé · aucune installation' 35
                Start-Sleep -Milliseconds 220
                Report 'Installation' 'Démonstration · installation simulée · aucune modification'
                Start-Sleep -Milliseconds 220
                $code=0
            }
            elseif($id -eq 'Fortinet.VPN'){$code=Install-Forti}
            elseif($id -eq 'Microsoft.Office'){$code=Install-Office}
            else{
                if(!$job.Winget -or !(Test-Path -LiteralPath $job.Winget)){throw 'WinGet est introuvable.'}
                if(!$wingetRefreshed){
                    Report 'Mise à jour du catalogue' 'Actualisation de la source WinGet avant résolution des versions…'
                    $refresh=Run-Hidden $job.Winget @('source','update','--name','winget','--disable-interactivity') 'winget-source'
                    if($refresh -ne 0){throw 'Actualisation du catalogue WinGet impossible. Reessayez avec une connexion Internet.'}
                    $wingetRefreshed=$true
                }
                Report 'Téléchargement / installation' 'Résolution de la version actuelle et installation silencieuse…'
                $code=Run-Hidden $job.Winget (Winget-Arguments $id) $id $true
            }
            $hex='{0:X8}' -f ([long]$code -band 0xFFFFFFFFL)
            if($code -eq 0){Outcome $id 'Installée' $code 'Operation terminee avec succes.'}
            elseif($code -eq 3010){$state.reboot=$true;Outcome $id 'Redémarrage requis' $code 'Aucun redemarrage automatique.'}
            elseif($hex -in @('8A150061','8A15002B')){Outcome $id 'Déjà présente / à jour' $code 'Application conservee.'}
            else{Outcome $id 'Échec' $code "Code $hex. Voir les journaux de lʼapplication."}
        }catch{Outcome $id 'Échec' 1 $_.Exception.Message}
    }
}catch{
    $state.fatal=$true
    $state.message=$_.Exception.Message
    Add-Content -LiteralPath (Join-Path $run 'engine-error.log') -Value $_.Exception.ToString() -Encoding UTF8
}finally{
    $state.done=$true;$state.percent=-1;$state.phase='Terminé';Save-State
}
