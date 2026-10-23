param([string]$Executable=(Join-Path $PSScriptRoot '..\dist\MonInstallateur.exe'))
$ErrorActionPreference='Stop'
Add-Type -AssemblyName PresentationFramework,PresentationCore,WindowsBase,System.Xaml,System.Web.Extensions
$exe=[IO.Path]::GetFullPath($Executable);[void][Reflection.Assembly]::LoadFrom($exe)
$helper=Join-Path ([IO.Path]::GetTempPath()) ('appdesk-io-test-'+[guid]::NewGuid().ToString('N'))
[void][IO.Directory]::CreateDirectory($helper)
$library=Join-Path $helper 'AppDeskUnderTest.dll';Copy-Item -LiteralPath $exe -Destination $library
Add-Type -ReferencedAssemblies $library -TypeDefinition @'
using System;
public static class StateAccessFailure {
 public static State Read(string path){throw new UnauthorizedAccessException("TEST denied state.json");}
 public static void Write(string path,string content){throw new UnauthorizedAccessException("TEST denied stop.request");}
}
'@
$ui=New-Object InstallerUi -ArgumentList (,[string[]]@('--preview'))
$flags=[Reflection.BindingFlags]'Instance,NonPublic'
function Field($n){$ui.GetType().GetField($n,$flags)}
function Set-Field($n,$v){(Field $n).SetValue($ui,$v)}
function Call($n){$ui.GetType().GetMethod($n,$flags).Invoke($ui,@())}
function Control($n){$ui.Window.FindName($n)}
Set-Field 'settingsRoot' '\\unreachable.invalid\redirected-documents\AppDesk'
$apps=(Field 'apps').GetValue($ui);$apps[0].Selected=$true
(Control 'Consent').IsChecked=$true
$ui.GetType().GetMethod('Start',$flags).Invoke($ui,@($true))
$run=(Field 'runPath').GetValue($ui)
$expected=Join-Path $env:LOCALAPPDATA 'AppDesk\Sessions'
if(!$run.StartsWith($expected,[StringComparison]::OrdinalIgnoreCase) -or $run.StartsWith('\\')){throw 'Session depends on redirected Documents.'}
$until=[DateTime]::Now.AddSeconds(30)
while((Field 'running').GetValue($ui) -and [DateTime]::Now -lt $until){Start-Sleep -Milliseconds 150;Call 'Poll'}
if((Field 'running').GetValue($ui)){throw 'Local simulation did not finish.'}
$state=Get-Content -LiteralPath (Join-Path $run 'state.json') -Raw|ConvertFrom-Json
if(!$state.done -or $state.fatal -or $state.completed -ne 1){throw 'Simulation failed with redirected Documents.'}
# Inject the exception seen on the TNS workstation without changing any ACLs.
Set-Field 'readState' ([Delegate]::CreateDelegate([Func[string,State]],[StateAccessFailure].GetMethod('Read')))
Set-Field 'lastState' $null;Set-Field 'running' $true
$current=[Diagnostics.Process]::GetCurrentProcess();Set-Field 'worker' $current
Call 'Poll'
if(!(Field 'running').GetValue($ui) -or (Control 'Activity').Text -notmatch 'Suivi temporairement indisponible'){throw 'Denied read crashed UI or incorrectly completed active worker.'}
Set-Field 'writeStop' ([Delegate]::CreateDelegate([Action[string,string]],[StateAccessFailure].GetMethod('Write')))
(Control 'Stop').IsEnabled=$true;Call 'RequestStop'
if(!(Control 'Stop').IsEnabled -or (Control 'Activity').Text -notmatch 'Impossible de transmettre'){throw 'Failed stop request was reported as accepted.'}
$current.Dispose()
$start=New-Object Diagnostics.ProcessStartInfo
$start.FileName=Join-Path $env:SystemRoot 'System32\cmd.exe';$start.Arguments='/c exit 0';$start.UseShellExecute=$false;$start.CreateNoWindow=$true
$ended=[Diagnostics.Process]::Start($start);$ended.WaitForExit();Set-Field 'worker' $ended
Call 'Poll'
if((Field 'running').GetValue($ui) -or (Control 'ReportTitle').Text -ne 'Parcours interrompu' -or (Control 'ReportIssue').Text -notmatch 'Lecture du bilan impossible'){throw 'Denied final read was reported as success or escaped.'}
$ui.Window.Close()
[pscustomobject]@{RedirectedDocuments='Session remains local';SimulatedQueue='OK';DeniedReadWhileRunning='No crash, worker continues';DeniedStop='Not falsely acknowledged';DeniedFinalRead='Interrupted report';ApplicationsInstalled=0}|ConvertTo-Json
