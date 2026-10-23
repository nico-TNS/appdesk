param([string]$Executable=(Join-Path $PSScriptRoot '..\dist\MonInstallateur.exe'))
$ErrorActionPreference='Stop'
$Executable=[IO.Path]::GetFullPath($Executable)
$folder=Join-Path ([IO.Path]::GetTempPath()) ('appdesk-report-qa-'+[guid]::NewGuid().ToString('N'))
[void][IO.Directory]::CreateDirectory($folder)
$job=@{Ids=@('Mozilla.Firefox','Microsoft.Office','WireGuard.WireGuard','3CX.Softphone');Office='Standard2024Volume';Update=$true;Forti='';Winget='';Simulate=$false}
$job|ConvertTo-Json|Set-Content (Join-Path $folder 'job.json') -Encoding UTF8
$state=@{completed=3;total=4;done=$true;fatal=$false;stopped=$true;reboot=$true;outcomes=@(@{id='Mozilla.Firefox';status='Installée';code=0;detail='Réussite de test.'},@{id='WireGuard.WireGuard';status='Redémarrage requis';code=3010;detail='Aucun redémarrage automatique.'},@{id='Microsoft.Office';status='Échec';code=1;detail='Une autre édition Office est déjà présente.'})}
function Open-TestReport {
    $state|ConvertTo-Json -Depth 5|Set-Content (Join-Path $folder 'state.json') -Encoding UTF8
    $image=Join-Path $folder 'report.png'
    $p=Start-Process -FilePath $Executable -ArgumentList @('--report-session',('"'+$folder+'"'),'--preview',('"'+$image+'"')) -PassThru -WindowStyle Hidden -Wait
    if($p.ExitCode -ne 0 -or !(Test-Path $image)){throw 'Report view failed to render.'}
    return Get-Content (Join-Path $folder 'rapport.txt') -Raw -Encoding UTF8
}
$report=Open-TestReport
if($report -notmatch '2 réussie\(s\).*1 échec\(s\).*1 non traitée' -or $report -notmatch 'autre édition Office' -or $report -notmatch 'Redémarrage requis, non lancé' -or $report -notmatch 'File arrêtée avant cette application'){throw 'Mixed outcomes/stop/reboot report is incomplete.'}
$state.fatal=$true;$state.stopped=$false;$state.completed=0;$state.outcomes=@();$state.message='Erreur fatale de test.'
$report=Open-TestReport
if($report -notmatch 'Parcours interrompu' -or $report -notmatch 'Erreur fatale de test' -or $report -notmatch '4 non traitée'){throw 'Fatal-error report is incomplete.'}
$state.done=$false;$state.fatal=$false;$state.message='';$state.reboot=$false
$report=Open-TestReport
if($report -notmatch 'Résultats partiels' -or $report -notmatch '4 non traitée'){throw 'Partial report is incomplete.'}
$job.Ids=@('Microsoft.Office');$job.Action='RemoveOffice';$job|ConvertTo-Json|Set-Content (Join-Path $folder 'job.json') -Encoding UTF8
$state.done=$true;$state.completed=1;$state.total=1;$state.outcomes=@(@{id='Microsoft.Office';status='Désinstallée';code=0;detail='Suppression simulée pour tester le rapport.'})
$report=Open-TestReport
if($report -notmatch 'Désinstallation Office terminée' -or $report -notmatch 'Désinstallée'){throw 'Removal report incorrectly presented as an installation.'}
[pscustomobject]@{MixedOutcomes='OK';StopAndReboot='OK';FatalError='OK';PartialResults='OK';ReportRendering='OK';ApplicationsInstalled=0;TestDirectory=$folder}|ConvertTo-Json
