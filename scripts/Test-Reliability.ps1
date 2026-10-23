$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot '..\src\Sources.ps1')
$root=Join-Path ([IO.Path]::GetTempPath()) ('appdesk-reliability-'+[guid]::NewGuid().ToString('N'))
[void][IO.Directory]::CreateDirectory($root)
$target=Join-Path $root 'download.exe'
[IO.File]::WriteAllText($target,'original')
$script:attempts=0
function Open-PublisherResponse {
    param($Url,$Hosts)
    $script:attempts++
    $bytes=[byte[]]@(1,2,3)
    $length=if($script:attempts -eq 1){5}else{3}
    $response=[pscustomobject]@{ContentLength=$length;Bytes=$bytes}
    $response|Add-Member ScriptMethod GetResponseStream {return ,([IO.MemoryStream]::new($this.Bytes))}
    $response|Add-Member ScriptMethod Dispose {}
    return $response
}
Save-PublisherDownload 'https://download.microsoft.com/test.exe' $target @('download.microsoft.com')
if($script:attempts -ne 2 -or (Get-Item $target).Length -ne 3 -or (Get-ChildItem $root -Filter '*.part')){throw 'Interrupted download recovery failed.'}
[IO.File]::WriteAllText($target,'original')
$script:attempts=0
function Open-PublisherResponse {param($Url,$Hosts) $script:attempts++;throw [Net.WebException]::new('Test timeout',[Net.WebExceptionStatus]::Timeout)}
$failed=$false;try{Save-PublisherDownload 'https://download.microsoft.com/test.exe' $target @('download.microsoft.com')}catch{$failed=$true}
if(!$failed -or $script:attempts -ne 3 -or [IO.File]::ReadAllText($target) -ne 'original' -or (Get-ChildItem $root -Filter '*.part')){throw 'Failed download damaged an existing file or left partial data.'}
$script:attempts=0
try{Save-PublisherDownload 'https://attacker.example/test.exe' $target @('download.microsoft.com')}catch{}
if($script:attempts -ne 0){throw 'Unexpected download host was contacted.'}
$lock=Enter-AppDeskQueue $true
try{
    $ready=Join-Path $root 'lock-result.txt'
    $source=(Resolve-Path (Join-Path $PSScriptRoot '..\src\Sources.ps1')).Path.Replace("'","''")
    $child=Join-Path $root 'lock-test.ps1'
    $resultPath=$ready.Replace("'","''")
    $code=". '$source'`r`ntry{`$other=Enter-AppDeskQueue `$true;`$other.ReleaseMutex();`$other.Dispose();'FAILED'|Set-Content '$resultPath'}catch{'BLOCKED'|Set-Content '$resultPath'}"
    [IO.File]::WriteAllText($child,$code,(New-Object Text.UTF8Encoding($true)))
    $p=Start-Process -FilePath "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe" -ArgumentList @('-NoProfile','-File',('"'+$child+'"')) -WindowStyle Hidden -Wait -PassThru
    if($p.ExitCode -ne 0 -or (Get-Content $ready -Raw).Trim() -ne 'BLOCKED'){throw 'Concurrent queue was not blocked.'}
}finally{$lock.ReleaseMutex();$lock.Dispose()}
$lock=Enter-AppDeskQueue $true;$lock.ReleaseMutex();$lock.Dispose()
[pscustomobject]@{InterruptedTransferRetry='OK';BoundedRetries='OK';OriginalFilePreserved='OK';PartialFilesCleaned='OK';UnknownHostBlocked='OK';ConcurrentQueueBlocked='OK';LockReleased='OK';ApplicationsInstalled=0}|ConvertTo-Json
