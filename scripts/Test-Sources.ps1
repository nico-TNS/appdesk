param([switch]$Online,[string]$FortiPackage='')
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot '..\src\Sources.ps1')
function Expect-Failure([scriptblock]$Action){$failed=$false;try{& $Action|Out-Null}catch{$failed=$true};if(!$failed){throw 'Expected source rejection did not occur.'}}
$office=Resolve-OfficeHtml '<a href="https://download.microsoft.com/download/a/b/officedeploymenttool_19999-10000.exe">old</a><a href="https://download.microsoft.com/download/a/b/officedeploymenttool_20430-20146.exe">new</a>'
if($office.Version -ne [version]'20430.20146'){throw 'Office latest version resolution failed.'}
$forti=Resolve-FortiHtml '<a href="https://s3.cn-north-1.amazonaws.com.cn/support.fortinet.com.cn/files/FortiClientVPNSetup_7.4.3.6002_x64.exe">VPN</a><a href="https://filestore.fortinet.com/forticlient/FortiClientVPNSetup_7.4.2.9999_x64.exe">old</a><a href="https://filestore.fortinet.com/forticlient/FortiClientSetup_9.9.9.9999_x64.exe">Full EMS: excluded</a>'
if($forti.Version -ne [version]'7.4.3.6002'){throw 'Forti VPN latest resolution failed.'}
Expect-Failure {Resolve-OfficeHtml '<a href="https://attacker.example/officedeploymenttool_99999-99999.exe">fake</a>'}
Expect-Failure {Resolve-FortiHtml '<a href="https://attacker.example/FortiClientVPNSetup_9.9.9.9999_x64.exe">fake</a>'}
Expect-Failure {Resolve-FortiHtml '<a href="https://filestore.fortinet.com/forticlient/FortiClientVPNSetup_9.9.9.9999_arm64.exe">wrong architecture</a>'}
Expect-Failure {Assert-DownloadUri 'http://download.microsoft.com/a.exe' @('download.microsoft.com')}
Expect-Failure {Assert-DownloadUri 'https://download.microsoft.com.attacker.example/a.exe' @('download.microsoft.com')}
Expect-Failure {Assert-DownloadUri 'https://user@download.microsoft.com/a.exe' @('download.microsoft.com')}
Expect-Failure {Assert-DownloadUri 'https://download.microsoft.com:444/a.exe' @('download.microsoft.com')}
Expect-Failure {Test-FortiDownload $PSCommandPath ([version]'7.4.3.6002')}
$remove=[xml](Get-OfficeRemovalXml @('O365HomePremRetail','OneNoteFreeRetail'))
if($remove.Configuration.Remove.All -ne 'FALSE' -or $remove.Configuration.Remove.Product.Count -ne 2 -or $remove.Configuration.Remove.Product.ID -notcontains 'OneNoteFreeRetail' -or $remove.Configuration.Add -or $remove.Configuration.RemoveMSI -or $remove.Configuration.Property.Value -ne 'FALSE'){throw 'Office and OneNote removal scope is incorrect.'}
foreach($id in @('VisioPro2024Volume','ProjectPro2024Volume','O365HomePremRetail"/><Remove All="TRUE"/>','')){Expect-Failure {Get-OfficeRemovalXml @($id)}}
Expect-Failure {Get-OfficeRemovalXml @('O365HomePremRetail','O365HomePremRetail')}
if((Get-OfficeInstallDisposition @('OneNoteFreeRetail') 'Standard2024Volume' 'x64' $true) -ne 'Install'){throw 'Standalone OneNote falsely blocks Office installation.'}
if((Get-OfficeInstallDisposition @('OneNoteFreeRetail','VisioPro2024Volume','ProjectPro2024Volume') 'O365BusinessRetail' 'x64' $true) -ne 'Install'){throw 'Standalone products were mistaken for an Office suite.'}
if((Get-OfficeInstallDisposition @('O365BusinessRetail','OneNoteFreeRetail') 'O365BusinessRetail' 'x64' $false) -ne 'Keep'){throw 'Existing matching suite is not preserved.'}
if((Get-OfficeInstallDisposition @('O365BusinessRetail','OneNoteFreeRetail') 'O365BusinessRetail' 'x64' $true) -ne 'Update'){throw 'Existing matching suite cannot update.'}
Expect-Failure {Get-OfficeInstallDisposition @('O365HomePremRetail','OneNoteFreeRetail') 'Standard2024Volume' 'x64' $true}
Expect-Failure {Get-OfficeInstallDisposition @('OneNoteFreeRetail') 'Standard2024Volume' 'x86' $true}
if($Online){
    $office=Get-OfficeSource;$forti=Get-FortiSource
    if($FortiPackage){Test-FortiDownload $FortiPackage $forti.Version}
    [pscustomobject]@{Office=$office;FortiClient=$forti;FullFortiSignatureChecked=[bool]$FortiPackage;ApplicationsInstalled=0}|ConvertTo-Json -Depth 5
}else{'Source parsing, version ordering, allowed hosts, architecture, invalid signatures and fail-closed checks: OK.'}
