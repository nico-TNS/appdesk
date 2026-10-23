$ErrorActionPreference='Stop'
$engine=Join-Path $PSScriptRoot '..\src\Engine.ps1'
$temp=Join-Path ([IO.Path]::GetTempPath()) ('appdesk-qa-'+[guid]::NewGuid().ToString('N'))
[void][IO.Directory]::CreateDirectory($temp)
$ids=@('Google.Chrome','Mozilla.Firefox','Opera.Opera','Adobe.Acrobat.Reader.64-bit','WireGuard.WireGuard','Fortinet.VPN','OpenVPNTechnologies.OpenVPN','3CX.Softphone','Microsoft.Office')
$job=@{Ids=$ids;Update=$false;Office='O365BusinessRetail';Forti='';Winget='';Simulate=$true}
function Write-Job {$job|ConvertTo-Json -Depth 4|Set-Content -LiteralPath (Join-Path $temp 'job.json') -Encoding UTF8}
function Invoke-Plan {& $engine -JobPath (Join-Path $temp 'job.json') -Plan|ConvertFrom-Json}
Write-Job
$plan=Invoke-Plan
if($plan.operations.Count -ne 9 -or $plan.installationStarted){throw 'Plan catalogue incorrect.'}
foreach($operation in $plan.operations){if(!$operation.silent){throw 'Mode non silencieux.'}}
if(($plan.operations|Where-Object id -eq 'Google.Chrome').arguments -notcontains '--no-upgrade'){throw 'Mode conservation incorrect.'}
if(!($plan.operations|Where-Object id -eq 'Fortinet.VPN').automatic){throw 'Forti automatic source is not default.'}
$job.Forti='manual.exe';Write-Job;$plan=Invoke-Plan
if(($plan.operations|Where-Object id -eq 'Fortinet.VPN').automatic){throw 'Manual override ignored.'}
$job.Forti=''
$job.Update=$true;Write-Job;$plan=Invoke-Plan
if(($plan.operations|Where-Object id -eq 'Google.Chrome').arguments -contains '--no-upgrade'){throw 'Mode mise a jour incorrect.'}
$job.UpdateOnly=$true;Write-Job;$plan=Invoke-Plan
if(($plan.operations|Where-Object id -eq 'Google.Chrome').arguments[0] -ne 'upgrade'){throw 'Update-only would install absent applications.'}
$job.UpdateOnly=$false;Write-Job
foreach($product in @('O365BusinessRetail','O365ProPlusRetail','HomeBusiness2024Retail','Professional2024Retail','Standard2024Volume','ProPlus2024Volume')){
    $job.Office=$product;Write-Job;$plan=Invoke-Plan
    $xml=[xml](($plan.operations|Where-Object id -eq 'Microsoft.Office').xml)
    if($xml.Configuration.Display.Level -ne 'None' -or $xml.Configuration.Add.Product.ID -ne $product -or $xml.Configuration.RemoveMSI){throw 'Configuration Office incorrecte.'}
    if($xml.Configuration.Add.Version -or $xml.Configuration.Add.SourcePath -or $xml.Configuration.Updates.Enabled -ne 'TRUE'){throw 'Office is pinned to an old build or local cache.'}
    if($xml.Configuration.Add.Channel -ne $xml.Configuration.Updates.Channel){throw 'Office update channel differs from the installation channel.'}
}
$job.Office='Standard2024Volume';$job.ReplaceStandaloneOneNoteConfirmed=$true;Write-Job;$plan=Invoke-Plan
$xml=[xml](($plan.operations|Where-Object id -eq 'Microsoft.Office').xml)
if($xml.Configuration.Remove.All -ne 'FALSE' -or $xml.Configuration.Remove.Product.ID -ne 'OneNoteFreeRetail' -or $xml.Configuration.Add.Product.ID -ne 'Standard2024Volume' -or $xml.Configuration.RemoveMSI){throw 'Confirmed OneNote replacement is not narrowly scoped.'}
$job.ReplaceStandaloneOneNoteConfirmed=$false;Write-Job
& $engine -JobPath (Join-Path $temp 'job.json')
$state=Get-Content -LiteralPath (Join-Path $temp 'state.json') -Raw -Encoding UTF8|ConvertFrom-Json
if(!$state.done -or $state.fatal -or $state.completed -ne 9){throw 'Simulation incomplete.'}
Set-Content -LiteralPath (Join-Path $temp 'stop.request') 'stop'
& $engine -JobPath (Join-Path $temp 'job.json')
$state=Get-Content -LiteralPath (Join-Path $temp 'state.json') -Raw -Encoding UTF8|ConvertFrom-Json
if(!$state.done -or !$state.stopped -or $state.completed -ne 0){throw 'Arret de file incorrect.'}
Remove-Item -LiteralPath (Join-Path $temp 'stop.request')
$job.Ids=@('Google.Chrome');$job.Simulate=$false;$job.Winget=Join-Path $temp 'not-installed.exe';Write-Job
& $engine -JobPath (Join-Path $temp 'job.json')
$state=Get-Content -LiteralPath (Join-Path $temp 'state.json') -Raw -Encoding UTF8|ConvertFrom-Json
if(!$state.done -or $state.outcomes[0].status -ne 'Échec'){throw 'Erreur de dependance non signalee.'}
[pscustomobject]@{Catalogue=9;OfficeEditions=6;SilentPlans='OK';Simulation='9/9';Stop='OK';DependencyFailure='OK';ApplicationsInstalled=0;RunDirectory=$temp}|ConvertTo-Json
