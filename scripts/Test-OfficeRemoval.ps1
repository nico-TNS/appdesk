$ErrorActionPreference='Stop'
$engine=Join-Path $PSScriptRoot '..\src\Engine.ps1'
$temp=Join-Path ([IO.Path]::GetTempPath()) ('appdesk-removal-plan-'+[guid]::NewGuid().ToString('N'))
[void][IO.Directory]::CreateDirectory($temp)
$path=Join-Path $temp 'job.json'
$job=@{Ids=@('Microsoft.Office');Office='O365BusinessRetail';Action='RemoveOffice';OfficeProducts=@('O365HomePremRetail');RemovalConfirmed=$true;Simulate=$true}
function Write-RemovalJob {$job|ConvertTo-Json -Depth 4|Set-Content -LiteralPath $path -Encoding UTF8}
function Assert-Rejected {$failed=$false;try{& $engine -JobPath $path -Plan|Out-Null}catch{$failed=$true};if(!$failed){throw 'Unsafe removal plan accepted.'}}
Write-RemovalJob
$plan=& $engine -JobPath $path -Plan|ConvertFrom-Json
$xml=[xml]$plan.operations[0].xml
if($plan.operations[0].action -ne 'RemoveOffice' -or $xml.Configuration.Remove.All -ne 'FALSE' -or $xml.Configuration.Remove.Product.ID -ne 'O365HomePremRetail' -or $xml.Configuration.Add -or $xml.Configuration.RemoveMSI){throw 'Removal plan targets unexpected products.'}
& $engine -JobPath $path
$state=Get-Content (Join-Path $temp 'state.json') -Raw -Encoding UTF8|ConvertFrom-Json
if(!$state.done -or $state.completed -ne 1 -or $state.outcomes[0].status -ne 'Désinstallée'){throw 'Removal simulation failed.'}
$job.RemovalConfirmed=$false;Write-RemovalJob;Assert-Rejected
$job.RemovalConfirmed=$true;$job.OfficeProducts=@('VisioPro2024Volume');Write-RemovalJob;Assert-Rejected
$job.OfficeProducts=@('O365HomePremRetail');$job.Ids=@('Microsoft.Office','Google.Chrome');Write-RemovalJob;Assert-Rejected
$job.Ids=@('Microsoft.Office');$job.Action='Unknown';Write-RemovalJob;Assert-Rejected
[pscustomobject]@{TargetedRemovalXml='OK';ConfirmationRequired='OK';NoMixedInstallQueue='OK';ProtectedProducts='OK';RemovalSimulation='OK';ApplicationsRemoved=0}|ConvertTo-Json
