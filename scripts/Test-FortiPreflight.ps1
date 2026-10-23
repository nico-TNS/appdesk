$ErrorActionPreference='Stop'
# Run the production function with read-only dependencies mocked; no real downloads/installs.
$tokens=$null;$errors=$null
$ast=[Management.Automation.Language.Parser]::ParseFile((Join-Path $PSScriptRoot '..\src\Engine.ps1'),[ref]$tokens,[ref]$errors)
$node=$ast.Find({param($n) $n -is [Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -eq 'Install-Forti'},$true)
. ([scriptblock]::Create($node.Extent.Text))
$job=[pscustomobject]@{UpdateOnly=$false;Update=$true;Forti=''}
$run=[IO.Path]::GetTempPath()
function Report {}
function Installed-Forti {return $script:installed}
function Get-FortiSource {return [pscustomobject]@{Version=$script:available;FileName='FortiClientVPNSetup.exe';Url='https://filestore.fortinet.com/test.exe'}}
function Test-Path {return $true}
function Get-ItemProperty {return [pscustomobject]@{DisplayName='FortiClient VPN';DisplayVersion=$script:version}}
function Download {$script:downloads++;throw 'DOWNLOAD_REACHED'}
function Run-Hidden {throw 'INSTALLER_MUST_NOT_RUN'}
function Check($installed,$version,$available,$expected){
    $script:installed=$installed;$script:version=$version;$script:available=[version]$available;$script:downloads=0
    $result=$null;$errorText='';try{$result=Install-Forti}catch{$errorText=$_.Exception.Message}
    if($expected -eq 'Keep'){
        if($script:downloads -ne 0 -or $result -ne -1978335135 -or $errorText){throw "Redundant transfer for installed version $version : $errorText"}
    }elseif($expected -eq 'Download'){
        if($script:downloads -ne 1 -or $errorText -ne 'DOWNLOAD_REACHED'){throw "Required update skipped for version $version : $errorText"}
    }elseif($expected -eq 'Unknown'){
        if($script:downloads -ne 0 -or $errorText -notmatch 'inconnue'){throw 'Unknown installed version did not fail before transfer.'}
    }
}
Check $true '7.4.3.6002' '7.4.3.6002' 'Keep'
Check $true '7.4.4.1000' '7.4.3.6002' 'Keep'
Check $true '7.4.3.4726' '7.4.3.6002' 'Download'
Check $true '7.4.3.9' '7.4.3.10' 'Download'
Check $true 'unknown' '7.4.3.6002' 'Unknown'
Check $false '' '7.4.3.6002' 'Download'
$job.Update=$false;Check $true '7.4.3.4726' '7.4.3.6002' 'Keep'
[pscustomobject]@{EqualVersionTransfer='Skipped';NewerInstalledTransfer='Skipped';OlderInstalledTransfer='Required';NumericVersionOrdering='OK';UnknownVersion='Rejected before download';KeepExisting='No transfer';ApplicationsInstalled=0}|ConvertTo-Json
