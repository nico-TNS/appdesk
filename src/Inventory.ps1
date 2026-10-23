param([string]$OutputPath,[string]$Winget,[switch]$FunctionsOnly)
$ErrorActionPreference='Stop'
$ProgressPreference='SilentlyContinue'
. (Join-Path $PSScriptRoot 'Sources.ps1')

# Read-only catalogue inspection. No installer or downloaded script is executed.
function Read-InstalledCatalogue {
    $patterns=@{
        'Google.Chrome'='^Google Chrome$'; 'Mozilla.Firefox'='^Mozilla Firefox(?:\s|$)'; 'Opera.Opera'='^Opera(?: Stable)?(?:\s|$)'
        'Adobe.Acrobat.Reader.64-bit'='^Adobe Acrobat(?: Reader)?(?: \(64-bit\))?$'
        'WireGuard.WireGuard'='^WireGuard$'; 'Fortinet.VPN'='^FortiClient VPN$'
        'OpenVPNTechnologies.OpenVPN'='^OpenVPN(?:\s|$)'; '3CX.Softphone'='^3CX(?: Desktop App)?$'
    }
    $entries=@(foreach($root in @('HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall','HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall','HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall','HKCU:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall')){
        if(Test-Path -LiteralPath $root){Get-ItemProperty "$root\*" -ErrorAction SilentlyContinue}
    })
    $rows=@(foreach($id in $patterns.Keys){
        $matches=@($entries|Where-Object {$_.DisplayName -match $patterns[$id]})
        [pscustomobject]@{Id=$id;Installed=[bool]$matches.Count;InstalledVersion=(@($matches.DisplayVersion|Where-Object {$_}|Sort-Object -Unique) -join ' / ');AvailableVersion='';Source='';Issue='';OfficeProduct='';OfficeChannel=''}
    })
    $config=$null
    foreach($key in @('HKLM:\SOFTWARE\Microsoft\Office\ClickToRun\Configuration','HKLM:\SOFTWARE\WOW6432Node\Microsoft\Office\ClickToRun\Configuration')){
        $candidate=Get-ItemProperty -LiteralPath $key -ErrorAction SilentlyContinue
        if($candidate.ProductReleaseIds){$config=$candidate;break}
    }
    $suites=@(([string]$config.ProductReleaseIds -split ',')|Where-Object {Test-OfficeSuiteId $_})
    $channel=''
    # Resolve channel IDs by the installed CDN, rather than comparing LTSC to Microsoft 365.
    $channels=@{'492350f6-3a01-4f97-b9c0-c7c6ddf67d60'='Current';'55336b82-a18d-4dd6-b5f6-9e5095c314a6'='MonthlyEnterprise';'7983bac0-e531-40cf-be00-fd24fe66619c'='PerpetualVL2024';'5030841d-c919-4594-8d2d-84ae4f96e58e'='PerpetualVL2021';'f2e724c1-748f-4b47-8fb8-8e0d210e9208'='PerpetualVL2019';'7ffbc6bf-bc32-4f92-8982-f9dd17fd3114'='SemiAnnual';'b8f9b850-328d-4355-9145-c59439a0c4cf'='SemiAnnualPreview'}
    $channelUrl=if($config.UpdateChannel){[string]$config.UpdateChannel}else{[string]$config.CDNBaseUrl}
    foreach($guid in $channels.Keys){if($channelUrl -match $guid){$channel=$channels[$guid];break}}
    $rows+=[pscustomobject]@{Id='Microsoft.Office';Installed=[bool]$suites.Count;InstalledVersion=[string]$config.VersionToReport;AvailableVersion='';Source='Microsoft Office Releases';Issue='';OfficeProduct=($suites -join ',');OfficeChannel=$channel}
    return $rows
}
function Invoke-InventoryWinget([string[]]$Arguments){
    if(!$Winget -or !(Test-Path -LiteralPath $Winget)){throw 'WinGet indisponible.'}
    $start=New-Object Diagnostics.ProcessStartInfo
    $start.FileName=$Winget;$start.Arguments=$Arguments -join ' ';$start.UseShellExecute=$false;$start.CreateNoWindow=$true
    $start.RedirectStandardOutput=$true;$start.RedirectStandardError=$true
    $start.StandardOutputEncoding=[Text.Encoding]::UTF8;$start.StandardErrorEncoding=[Text.Encoding]::UTF8
    $p=[Diagnostics.Process]::Start($start)
    try{
        $out=$p.StandardOutput.ReadToEndAsync();$err=$p.StandardError.ReadToEndAsync()
        if(!$p.WaitForExit(20000)){$p.Kill();throw 'Recherche WinGet expiree (20 s).'}
        $p.WaitForExit()
        if($p.ExitCode -ne 0){throw ('Recherche WinGet impossible (code '+$p.ExitCode+').')}
        return $out.Result
    }finally{$p.Dispose()}
}
function Read-WingetVersion([string]$Text){
    # Never infer a version from a URL, installer hash or arbitrary numeric line.
    $match=[regex]::Match($Text,'(?im)^\s*(?:Version|Versión|版本|バージョン|Версия)\s*:\s*([^\s]+)\s*$')
    if(!$match.Success){throw 'Version du catalogue non lisible.'}
    return $match.Groups[1].Value
}
function Read-OfficeVersions {
    $response=Open-PublisherResponse 'https://clients.config.office.net/releases/v1.0/OfficeReleases' @('clients.config.office.net')
    $reader=$null
    try{
        if($response.ContentType -notmatch 'application/json'){throw 'La source Office ne fournit pas de JSON.'}
        $reader=New-Object IO.StreamReader($response.GetResponseStream(),[Text.Encoding]::UTF8)
        $buffer=New-Object char[] 8192;$text=New-Object Text.StringBuilder
        while(($n=$reader.Read($buffer,0,$buffer.Length)) -gt 0){if($text.Length+$n -gt 5MB){throw 'Catalogue Office trop volumineux.'};[void]$text.Append($buffer,0,$n)}
        $data=$text.ToString()|ConvertFrom-Json
        @(foreach($item in $data){if($item.channelId -and $item.latestVersion -match '^16\.0\.\d+\.\d+$'){[pscustomobject]@{Channel=[string]$item.channelId;Version=[string]$item.latestVersion}}})
    }finally{if($reader){$reader.Dispose()};$response.Dispose()}
}
function Write-InventorySnapshot {
    $json=@{Complete=$script:complete;CheckedAt=[DateTime]::Now.ToString('o');Rows=@($script:rows);OfficeVersions=@($script:officeVersions)}|ConvertTo-Json -Depth 6
    $temp=$OutputPath+'.tmp';[IO.File]::WriteAllText($temp,$json,(New-Object Text.UTF8Encoding($false)))
    Move-Item -LiteralPath $temp -Destination $OutputPath -Force
}
if($FunctionsOnly){return}
$script:complete=$false;$script:officeVersions=@();$script:rows=@(Read-InstalledCatalogue)
Write-InventorySnapshot
try{
    $list=Invoke-InventoryWinget @('list','--source','winget','--disable-interactivity')
    foreach($row in $script:rows|Where-Object {$_.Id -notin @('Fortinet.VPN','Microsoft.Office')}){
        $match=[regex]::Match($list,'(?m)\s'+[regex]::Escape($row.Id)+'\s+(\S+)(?:\s+(\S+))?\s*$')
        if($match.Success){$row.Installed=$true;$row.InstalledVersion=$match.Groups[1].Value}
    }
}catch{} # Registry evidence remains available when WinGet cannot respond.
Write-InventorySnapshot
foreach($row in $script:rows){
    try{
        if($row.Id -eq 'Fortinet.VPN'){$row.AvailableVersion=[string](Get-FortiSource).Version;$row.Source='Portail officiel régional Fortinet'}
        elseif($row.Id -eq 'Microsoft.Office'){
            $script:officeVersions=@(Read-OfficeVersions)
            if(!$script:officeVersions.Count){throw 'Versions Office indisponibles.'}
        }else{$row.AvailableVersion=Read-WingetVersion (Invoke-InventoryWinget @('show','--id',$row.Id,'--exact','--source','winget','--disable-interactivity'));$row.Source='Catalogue WinGet'}
    }catch{$row.Issue=$_.Exception.Message}
    Write-InventorySnapshot
}
$script:complete=$true;Write-InventorySnapshot
