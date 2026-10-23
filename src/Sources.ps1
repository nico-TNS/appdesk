# Only publisher-owned pages supply download URLs. No downloaded code/catalog is evaluated.
$script:OfficePage='https://www.microsoft.com/en-us/download/details.aspx?id=49117'
$script:FortiPage='https://support.fortinet.com.cn/vpn/forticlient_vpn/fct_download'
$script:OfficeSuitePattern='^(?:O365[A-Za-z0-9]*Retail|(?:HomeBusiness|HomeStudent|Professional|ProPlus|Standard|Personal)(?:20(?:16|19|21|24))?(?:Retail|Volume))$'
function Test-OfficeSuiteId([string]$Id){return $Id -match $script:OfficeSuitePattern}
function Test-OfficeRemovalId([string]$Id){return (Test-OfficeSuiteId $Id) -or $Id -eq 'OneNoteFreeRetail'}
function Get-OfficeInstallDisposition([string[]]$InstalledProducts,[string]$RequestedProduct,[string]$Platform,[bool]$Update){
    if($InstalledProducts.Count -and $Platform -and $Platform -ne 'x64'){throw 'Office 32 bits est deja present. La migration x64 doit etre effectuee manuellement.'}
    $suites=@($InstalledProducts|Where-Object {Test-OfficeSuiteId $_})
    if(!$suites.Count){return 'Install'}
    if($RequestedProduct -notin $suites){throw 'Une autre suite Office est deja presente. Utilisez Desinstaller Office avant de changer edition.'}
    if($Update){return 'Update'}
    return 'Keep'
}
function Get-OfficeRemovalXml([string[]]$Products){
    if(!$Products.Count -or @($Products|Select-Object -Unique).Count -ne $Products.Count){throw 'Liste de produits Office vide ou dupliquee.'}
    foreach($product in $Products){if(!(Test-OfficeRemovalId $product)){throw 'Produit Office non autorise pour la desinstallation ciblee.'}}
    $items=($Products|ForEach-Object {'<Product ID="'+$_+'" />'}) -join ''
    return '<Configuration><Remove All="FALSE">'+$items+'</Remove><Display Level="None" AcceptEULA="TRUE" /><Property Name="FORCEAPPSHUTDOWN" Value="FALSE" /></Configuration>'
}
function Get-InstalledOfficeRemovalIds {
    @(foreach($root in @('HKLM:\SOFTWARE\Microsoft\Office\ClickToRun\Configuration','HKLM:\SOFTWARE\WOW6432Node\Microsoft\Office\ClickToRun\Configuration')){
        $config=Get-ItemProperty -LiteralPath $root -ErrorAction SilentlyContinue
        if($config.ProductReleaseIds){[string]$config.ProductReleaseIds -split ','|Where-Object {Test-OfficeRemovalId $_}}
    })|Sort-Object -Unique
}
function Assert-DownloadUri([string]$Url,[string[]]$Hosts){
    $uri=$null
    if(![Uri]::TryCreate($Url,[UriKind]::Absolute,[ref]$uri) -or $uri.Scheme -ne 'https' -or $uri.UserInfo -or !$uri.IsDefaultPort -or $uri.Host -notin $Hosts){throw 'Adresse de telechargement non autorisee.'}
    return $uri
}
function Open-PublisherResponse([string]$Url,[string[]]$Hosts){
    [Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12
    for($redirect=0;$redirect -le 5;$redirect++){
        $uri=Assert-DownloadUri $Url $Hosts
        $request=[Net.HttpWebRequest]::Create($uri)
        $request.AllowAutoRedirect=$false;$request.Timeout=30000;$request.ReadWriteTimeout=30000
        $request.UserAgent='AppDesk/2.1 (publisher download resolver)'
        $response=$request.GetResponse()
        if([int]$response.StatusCode -in @(301,302,303,307,308)){
            $location=$response.Headers['Location'];$response.Dispose()
            if(!$location){throw 'Redirection de telechargement vide.'}
            $Url=([Uri]::new($uri,$location)).AbsoluteUri
        }elseif([int]$response.StatusCode -eq 200){return $response}
        else{$response.Dispose();throw 'Reponse du serveur de telechargement inattendue.'}
    }
    throw 'Trop de redirections de telechargement.'
}
function Read-PublisherPage([string]$Url,[string[]]$Hosts){
    $response=Open-PublisherResponse $Url $Hosts
    $reader=$null
    try{
        if($response.ContentType -notmatch '(?i)(text/html|application/xhtml)'){throw 'La source ne fournit pas une page HTML.'}
        $reader=New-Object IO.StreamReader($response.GetResponseStream(),[Text.Encoding]::UTF8)
        $buffer=New-Object char[] 8192;$text=New-Object Text.StringBuilder
        while(($count=$reader.Read($buffer,0,$buffer.Length)) -gt 0){
            if($text.Length+$count -gt 5MB){throw 'Page de telechargement trop volumineuse.'}
            [void]$text.Append($buffer,0,$count)
        }
        return $text.ToString()
    }finally{if($reader){$reader.Dispose()};$response.Dispose()}
}
function Resolve-OfficeHtml([string]$Html){
    $pattern='https://download\.microsoft\.com/download/[a-zA-Z0-9/_.-]+/officedeploymenttool_(?<version>\d+(?:-\d+)+)\.exe'
    $candidates=@(foreach($match in [regex]::Matches([Net.WebUtility]::HtmlDecode($Html),$pattern)){
        $version=$null
        if([version]::TryParse($match.Groups['version'].Value.Replace('-','.'),[ref]$version)){
            [pscustomobject]@{Url=$match.Value;Version=$version;Page=$script:OfficePage;FileName=[IO.Path]::GetFileName($match.Value)}
        }
    })
    $latest=$candidates|Sort-Object Version -Descending|Select-Object -First 1
    if(!$latest){throw 'Le lien officiel Office Deployment Tool est introuvable. Aucun ancien outil ne sera utilise.'}
    return $latest
}
function Resolve-FortiHtml([string]$Html){
    # This official regional portal publishes full VPN-only x64 packages, unlike the global bootstrapper.
    $pattern='https://(?:s3\.cn-north-1\.amazonaws\.com\.cn/support\.fortinet\.com\.cn/files|filestore\.fortinet\.com/forticlient(?:/downloads)?)/FortiClientVPNSetup_(?<version>\d+\.\d+\.\d+\.\d+)_x64\.exe'
    $candidates=@(foreach($match in [regex]::Matches([Net.WebUtility]::HtmlDecode($Html),$pattern)){
        $version=$null
        if([version]::TryParse($match.Groups['version'].Value,[ref]$version)){
            [pscustomobject]@{Url=$match.Value;Version=$version;Page=$script:FortiPage;FileName=[IO.Path]::GetFileName($match.Value)}
        }
    })
    $latest=$candidates|Sort-Object Version -Descending|Select-Object -First 1
    if(!$latest){throw 'Aucun package complet FortiClient VPN x64 sur le portail officiel. Reessayez ou choisissez un package officiel manuellement.'}
    return $latest
}
function Get-OfficeSource {Resolve-OfficeHtml (Read-PublisherPage $script:OfficePage @('www.microsoft.com','microsoft.com'))}
function Get-FortiSource {Resolve-FortiHtml (Read-PublisherPage $script:FortiPage @('support.fortinet.com.cn'))}
function Test-PublisherSignature([string]$File,[string]$Publisher){
    $signature=Get-AuthenticodeSignature -LiteralPath $File
    if($signature.Status -ne 'Valid' -or $signature.SignerCertificate.Subject -notmatch $Publisher){throw 'Signature numerique editeur invalide ou inattendue.'}
}
function Test-FortiDownload([string]$File,[version]$ExpectedVersion){
    Test-PublisherSignature $File 'O=("?Fortinet(?:,? Inc\.?)?"?|Fortinet Technologies \(Canada\) ULC)(,|$)'
    $item=Get-Item -LiteralPath $File
    $version=$null
    if($item.Length -lt 20000000 -or $item.VersionInfo.FileDescription -match 'online' -or ![version]::TryParse($item.VersionInfo.ProductVersion,[ref]$version) -or $version -ne $ExpectedVersion){throw 'Package FortiClient incomplet ou version differente de la source officielle.'}
}
