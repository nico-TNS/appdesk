$ErrorActionPreference='Stop'
$root=Split-Path -Parent $PSScriptRoot
foreach($required in @('LICENSE','VERSION','README.md','CODE_SIGNING.md','PRIVACY.md','SECURITY.md','THIRD_PARTY.md','docs\UNINSTALL.md','src\App.cs','src\Interface.xaml','src\Engine.ps1','signpath\artifact-configuration.xml')){
    if(!(Test-Path -LiteralPath (Join-Path $root $required))){throw "Missing required project file: $required"}
}
foreach($file in Get-ChildItem -LiteralPath $root -Recurse -File -Filter '*.ps1'){
    $tokens=$null;$errors=$null
    [void][Management.Automation.Language.Parser]::ParseFile($file.FullName,[ref]$tokens,[ref]$errors)
    if($errors.Count){throw ($file.FullName+': '+($errors.Message -join '; '))}
}
$version=(Get-Content -LiteralPath (Join-Path $root 'VERSION') -Raw).Trim()
$source=[IO.File]::ReadAllText((Join-Path $root 'src\App.cs'))
foreach($attribute in @('AssemblyVersion','AssemblyFileVersion','AssemblyInformationalVersion')){
    if($source -notmatch ($attribute+'\("'+[regex]::Escape($version)+'"\)')){throw "Version mismatch for $attribute"}
}
Add-Type -AssemblyName PresentationFramework,PresentationCore,WindowsBase,System.Xaml
$window=[Windows.Markup.XamlReader]::Parse([IO.File]::ReadAllText((Join-Path $root 'src\Interface.xaml')))
foreach($name in @('Overall','ActivityBar','Cards','Install','OfficeEdition','ChooseForti','OpenLogs')){if(!$window.FindName($name)){throw "Missing UI control $name"}}
$window.Close()
$xml=New-Object Xml.XmlDocument
$xml.XmlResolver=$null
$xml.Load((Join-Path $root 'signpath\artifact-configuration.xml'))
if($xml.DocumentElement.NamespaceURI -ne 'http://signpath.io/artifact-configuration/v1'){throw 'Invalid SignPath namespace.'}
$ns=New-Object Xml.XmlNamespaceManager($xml.NameTable);$ns.AddNamespace('s',$xml.DocumentElement.NamespaceURI)
$pe=$xml.SelectSingleNode('/s:artifact-configuration/s:zip-file/s:pe-file',$ns)
if(!$pe -or $pe.GetAttribute('path') -ne 'MonInstallateur.exe' -or $pe.GetAttribute('product-name') -ne 'AppDesk'){throw 'Unexpected signing target.'}
if($xml.SelectNodes('//s:authenticode-sign',$ns).Count -ne 1){throw 'Exactly one owned binary should be signed.'}
$forbidden=Get-ChildItem -LiteralPath (Join-Path $root 'src') -Recurse -File | Where-Object Extension -in @('.exe','.msi','.msix','.pfx','.p12','.key')
if($forbidden){throw 'Unexpected installer, executable or private key in source tree.'}
'Project files, PowerShell syntax, version, WPF layout and signing target: OK. No installations started.'
