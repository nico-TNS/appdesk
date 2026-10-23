$ErrorActionPreference='Stop'
# Exercise the actual production guard functions while replacing system/installer IO.
$file=Join-Path $PSScriptRoot '..\src\Engine.ps1';$tokens=$null;$errors=$null
$ast=[Management.Automation.Language.Parser]::ParseFile($file,[ref]$tokens,[ref]$errors)
foreach($name in @('Install-Forti','Install-Office')){
    $node=$ast.Find({param($n) $n -is [Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -eq $name},$true)
    . ([scriptblock]::Create($node.Extent.Text))
}
$job=[pscustomobject]@{UpdateOnly=$true;Update=$true;Office='Standard2024Volume';OfficeChannel='PerpetualVL2024'}
$channels=@{Standard2024Volume='PerpetualVL2024'}
function Installed-Forti {return $false}
function Get-OfficeSetup {throw 'UNEXPECTED INSTALLER CALL'}
function Get-ItemProperty {return $script:config}
function Assert-Guard($block,$expected){$message='';try{& $block}catch{$message=$_.Exception.Message};if($message -notmatch $expected -or $message -match 'UNEXPECTED'){throw ('Update-only guard failed: '+$message)}}
Assert-Guard {Install-Forti} 'FortiClient est absent'
$script:config=$null;Assert-Guard {Install-Office} 'Edition Office absente'
$script:config=[pscustomobject]@{ProductReleaseIds='O365BusinessRetail';UpdateChannel='https://officecdn.microsoft.com/pr/492350f6-3a01-4f97-b9c0-c7c6ddf67d60';CDNBaseUrl=''}
Assert-Guard {Install-Office} 'Edition Office absente'
$script:config=[pscustomobject]@{ProductReleaseIds='Standard2024Volume';UpdateChannel='https://officecdn.microsoft.com/pr/55336b82-a18d-4dd6-b5f6-9e5095c314a6';CDNBaseUrl='https://officecdn.microsoft.com/pr/7983bac0-e531-40cf-be00-fd24fe66619c'}
Assert-Guard {Install-Office} 'Canal Office non pris en charge'
'Update-only: absent FortiClient, absent Office, changed edition and active channel override rejected before installer IO. OK.'
