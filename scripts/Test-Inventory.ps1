$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot '..\src\Inventory.ps1') -FunctionsOnly
foreach($sample in @("Version : 1.2.3","Version$([char]0xa0): 7.4.3.6002","Versión : 2.4")){
    if(!(Read-WingetVersion $sample)){throw 'Localized version not read.'}
}
$rejected=$false;try{Read-WingetVersion "Installer SHA256: 123456`nURL: https://example.com/9.9.exe"}catch{$rejected=$true}
if(!$rejected){throw 'Invented version from unrelated numeric metadata.'}
# Mock network only: no dependency on today's Office build or a public server.
$script:disposed=$false
function Open-PublisherResponse {
    $json='[{"channelId":"Current","latestVersion":"16.0.20000.10000"},{"channelId":"PerpetualVL2024","latestVersion":"16.0.17932.21056"}]'
    $obj=[pscustomobject]@{ContentType='application/json';Data=[Text.Encoding]::UTF8.GetBytes($json)}
    $obj|Add-Member ScriptMethod GetResponseStream {New-Object IO.MemoryStream(,$this.Data)}
    $obj|Add-Member ScriptMethod Dispose {$script:disposed=$true}
    return $obj
}
$office=@(Read-OfficeVersions)
if($office.Count -ne 2 -or ($office|Where-Object Channel -eq 'PerpetualVL2024').Version -ne '16.0.17932.21056' -or !$script:disposed){throw 'Office channel resolution or response disposal failed.'}
'Read-only inventory parsing, localized metadata, unavailable versions and Office channels: OK.'
