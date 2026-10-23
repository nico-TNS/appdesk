param([string]$Executable=(Join-Path $PSScriptRoot '..\dist\MonInstallateur.exe'))
$ErrorActionPreference='Stop'
Add-Type -AssemblyName PresentationFramework,PresentationCore,WindowsBase,System.Xaml,System.Web.Extensions
[void][Reflection.Assembly]::LoadFrom([IO.Path]::GetFullPath($Executable))
$folder=Join-Path ([IO.Path]::GetTempPath()) ('appdesk-selections-'+[guid]::NewGuid().ToString('N'))
[void][IO.Directory]::CreateDirectory($folder)
$flags=[Reflection.BindingFlags]'Instance,NonPublic'
$ui=New-Object InstallerUi -ArgumentList (,[string[]]@('--preview'))
function Field($name){$ui.GetType().GetField($name,$flags)}
function Set-Field($name,$value){(Field $name).SetValue($ui,$value)}
function Call($name){$ui.GetType().GetMethod($name,$flags).Invoke($ui,@())}
function Control($name){$ui.Window.FindName($name)}
Set-Field 'settingsRoot' $folder
$apps=(Field 'apps').GetValue($ui)
$apps[0].Selected=$true;$apps[8].Selected=$true
(Control 'OfficeEdition').SelectedIndex=4;(Control 'UpdateExisting').IsChecked=$false
(Control 'Consent').IsChecked=$true
Call 'SaveSelection'
$profile=Get-Content -LiteralPath (Join-Path $folder 'selection.json') -Raw|ConvertFrom-Json
if($profile.Office -ne 'Standard2024Volume' -or $profile.Update -or $profile.Ids.Count -ne 2){throw 'Profile did not persist selection and Office edition.'}
if($profile.PSObject.Properties.Name -contains 'Consent' -or $profile.PSObject.Properties.Name -contains 'Forti' -or $profile.PSObject.Properties.Name -contains 'RemovalConfirmed'){throw 'Profile persisted consent, package path or destructive confirmation.'}
foreach($a in $apps){$a.Selected=$false}
(Control 'OfficeEdition').SelectedIndex=0
$ui.GetType().GetMethod('LoadSelection',$flags).Invoke($ui,@($true))
if(!$apps[0].Selected -or !$apps[8].Selected -or (Control 'OfficeEdition').SelectedIndex -ne 4 -or (Control 'Consent').IsChecked){throw 'Profile restore changed consent or lost choices.'}
# A corrupted/untrusted file cannot partially change the current selection.
'{"Schema":1,"Ids":["unknown.exe"],"Office":"Standard2024Volume"}'|Set-Content (Join-Path $folder 'selection.json')
$ui.GetType().GetMethod('LoadSelection',$flags).Invoke($ui,@($true))
if(!$apps[0].Selected -or !$apps[8].Selected){throw 'Invalid profile partially applied.'}
foreach($json in @('{"Schema":2,"Ids":[],"Office":"Standard2024Volume"}','{"Schema":1,"Ids":["Google.Chrome","Google.Chrome"],"Office":"Standard2024Volume"}')){
    $rejected=$false;try{[void][SelectionTools]::Validate([Entry]::Json.Deserialize($json,[SelectionProfile]))}catch{$rejected=$true}
    if(!$rejected){throw 'Invalid schema/duplicates accepted.'}
}
$job=New-Object Job;$job.Ids=@('Google.Chrome','Microsoft.Office','WireGuard.WireGuard','3CX.Softphone');$job.Office='Standard2024Volume';$job.Update=$true;$job.Action='Install'
$state=New-Object State;$state.outcomes=New-Object 'Collections.Generic.List[Outcome]'
foreach($row in @(@('Google.Chrome','Installée',0),@('Microsoft.Office','Échec',1),@('WireGuard.WireGuard','Redémarrage requis',3010),@('unknown.exe','Échec',1))){$o=New-Object Outcome;$o.id=$row[0];$o.status=$row[1];$o.code=$row[2];$state.outcomes.Add($o)}
$failed=@([SelectionTools]::Failed($state,$job))
if($failed.Count -ne 1 -or $failed[0] -ne 'Microsoft.Office'){throw 'Retry included success, reboot, unprocessed or unknown application.'}
Set-Field 'reportJob' $job;Set-Field 'lastState' $state
Call 'RetryFailed'
if(@($apps|Where-Object Selected).Count -ne 1 -or !$apps[8].Selected -or (Control 'Consent').IsChecked){throw 'Retry UI did not isolate failures and reset consent.'}
$inv=New-Object InventorySnapshot;$inv.Complete=$true
$chrome=New-Object InventoryRow;$chrome.Id='Google.Chrome';$chrome.Installed=$true;$chrome.InstalledVersion='120.0';$chrome.AvailableVersion='121.0'
$office=New-Object InventoryRow;$office.Id='Microsoft.Office';$office.Installed=$true;$office.InstalledVersion='16.0.17932.21056';$office.OfficeProduct='Standard2024Volume';$office.OfficeChannel='PerpetualVL2024'
$inv.Rows=@($chrome,$office);$current=New-Object OfficeVersion;$current.Channel='Current';$current.Version='16.0.20527.20088';$ltsc=New-Object OfficeVersion;$ltsc.Channel='PerpetualVL2024';$ltsc.Version='16.0.17932.21056';$inv.OfficeVersions=@($current,$ltsc)
Set-Field 'inventory' $inv;Call 'ApplyInventory';Call 'SelectPresent'
if(@($apps|Where-Object Selected).Count -ne 2 -or !$apps[0].Selected -or !$apps[8].Selected -or !(Field 'updateOnly').GetValue($ui)){throw 'Update-only selection includes absent apps.'}
if((Control 'OfficeEdition').SelectedIndex -ne 4 -or (Control 'OfficeEdition').IsEnabled -or (Control 'Consent').IsChecked){throw 'Update-only switched Office edition or kept consent.'}
if($apps[8].AvailableText -notmatch '17932.21056'){throw 'Office displayed Current channel version for LTSC.'}
$office.OfficeChannel='MonthlyEnterprise';Call 'SelectPresent'
if($apps[8].Selected){throw 'Unsupported Office channel was silently migrated.'}
$ui.Window.Close()
[pscustomobject]@{ProfileRoundTrip='OK';UntrustedProfile='OK';RetryOnlyFailures='OK';UpdateOnlySelection='OK';OfficeChannel='OK';ConsentReset='OK';ApplicationsInstalled=0}|ConvertTo-Json
