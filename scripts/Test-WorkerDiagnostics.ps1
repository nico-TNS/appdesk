param([string]$Executable=(Join-Path $PSScriptRoot '..\dist\MonInstallateur.exe'))
$ErrorActionPreference='Stop'
$folder=Join-Path ([IO.Path]::GetTempPath()) ('appdesk-worker-error-'+[guid]::NewGuid().ToString('N'))
[void][IO.Directory]::CreateDirectory($folder)
$job=Join-Path $folder 'job.json'
@{Ids=@('Invalid.Catalog.Entry');Office='O365BusinessRetail';Simulate=$true;Action='Install'}|ConvertTo-Json|Set-Content -LiteralPath $job -Encoding UTF8
$p=Start-Process -FilePath ([IO.Path]::GetFullPath($Executable)) -ArgumentList @('--worker',('"'+$job+'"')) -WindowStyle Hidden -PassThru -Wait
if($p.ExitCode -eq 0){throw 'Invalid worker unexpectedly succeeded.'}
$state=Get-Content -LiteralPath (Join-Path $folder 'state.json') -Raw -Encoding UTF8|ConvertFrom-Json
if(!$state.done -or !$state.fatal -or $state.completed -ne 0 -or !$state.message){throw 'Worker startup error has no final diagnostic state.'}
if((Get-Item -LiteralPath (Join-Path $folder 'engine.stderr.log')).Length -eq 0){throw 'PowerShell error output was lost.'}
$image=Join-Path $folder 'error-report.png'
$p=Start-Process -FilePath ([IO.Path]::GetFullPath($Executable)) -ArgumentList @('--report-session',('"'+$folder+'"'),'--preview',('"'+$image+'"')) -WindowStyle Hidden -PassThru -Wait
if($p.ExitCode -ne 0 -or !(Test-Path -LiteralPath $image)){throw 'Worker failure report could not be rendered.'}
if((Get-Content -LiteralPath (Join-Path $folder 'rapport.txt') -Raw -Encoding UTF8) -notmatch 'Parcours interrompu'){throw 'Worker failure was presented as success.'}
[pscustomobject]@{InvalidJobRejected='OK';ErrorLogCaptured='OK';FatalStateWritten='OK';InterruptedReportRendered='OK';ApplicationsInstalled=0}|ConvertTo-Json
