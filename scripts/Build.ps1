param([string]$OutputDirectory=(Join-Path $PSScriptRoot '..\dist'))
$ErrorActionPreference='Stop'
$root=Split-Path -Parent $PSScriptRoot
$src=Join-Path $root 'src'
$version=(Get-Content -LiteralPath (Join-Path $root 'VERSION') -Raw).Trim()
if($version -notmatch '^\d+\.\d+\.\d+\.\d+$'){throw 'Invalid VERSION file.'}
$framework=Join-Path $env:SystemRoot 'Microsoft.NET\Framework\v4.0.30319'
$wpf=Join-Path $framework 'WPF'
$compiler=Join-Path $framework 'csc.exe'
if(!(Test-Path -LiteralPath $compiler)){throw '.NET Framework C# compiler is required on Windows.'}
[void][IO.Directory]::CreateDirectory($OutputDirectory)
$destination=Join-Path ([IO.Path]::GetFullPath($OutputDirectory)) 'MonInstallateur.exe'
$references=@('System.dll','System.Core.dll','System.Xml.dll','System.Web.Extensions.dll','System.Xaml.dll')|ForEach-Object{"/reference:$(Join-Path $framework $_)"}
$references+=@('WindowsBase.dll','PresentationCore.dll','PresentationFramework.dll')|ForEach-Object{"/reference:$(Join-Path $wpf $_)"}
& $compiler /nologo /target:winexe /platform:x64 /optimize+ /codepage:65001 @references "/win32manifest:$src\App.manifest" "/win32icon:$src\AppDesk.ico" "/resource:$src\Interface.xaml,ui" "/resource:$src\Engine.ps1,engine" "/resource:$src\Sources.ps1,sources" "/out:$destination" "$src\App.cs"
if($LASTEXITCODE -ne 0){throw 'C# compilation failed.'}
$metadata=[Diagnostics.FileVersionInfo]::GetVersionInfo($destination)
if($metadata.ProductName -ne 'AppDesk' -or $metadata.CompanyName -ne 'AppDesk contributors' -or $metadata.FileVersion -ne $version -or $metadata.ProductVersion -ne $version -or $metadata.OriginalFilename -ne 'MonInstallateur.exe'){throw 'PE metadata does not match the signing policy.'}
$hash=(Get-FileHash -LiteralPath $destination -Algorithm SHA256).Hash.ToLowerInvariant()
[IO.File]::WriteAllText((Join-Path $OutputDirectory 'SHA256SUMS.txt'),"$hash  MonInstallateur.exe`n",(New-Object Text.UTF8Encoding($false)))
if($env:GITHUB_OUTPUT){[IO.File]::AppendAllText($env:GITHUB_OUTPUT,"version=$version`n",(New-Object Text.UTF8Encoding($false)))}
[pscustomobject]@{File=$destination;Version=$version;Product=$metadata.ProductName;SHA256=$hash;Signed=$false}
