using System;
using System.IO;
using System.Linq;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.ComponentModel;
using System.Diagnostics;
using System.Reflection;
using System.Security.Principal;
using System.Text;
using System.Text.RegularExpressions;
using System.Web.Script.Serialization;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Data;
using System.Windows.Markup;
using System.Windows.Media;
using System.Windows.Media.Imaging;
using System.Windows.Threading;
using Microsoft.Win32;

[assembly: AssemblyTitle("AppDesk — Mon installateur")]
[assembly: AssemblyDescription("Installation groupée et silencieuse d’applications Windows")]
[assembly: AssemblyCompany("AppDesk contributors")]
[assembly: AssemblyProduct("AppDesk")]
[assembly: AssemblyCopyright("Copyright (c) 2026 AppDesk contributors")]
[assembly: AssemblyFileVersion("2.4.0.0")]
[assembly: AssemblyInformationalVersion("2.4.0.0")]
[assembly: AssemblyVersion("2.4.0.0")]

public sealed class AppItem : INotifyPropertyChanged {
 public string Id {get;set;} public string Title {get;set;} public string Subtitle {get;set;}
 public string Category {get;set;} public string Glyph {get;set;} public string Color {get;set;}
 public string Kind {get;set;}
 bool selected; string status="";
 public bool Selected {get{return selected;} set{selected=value;Changed("Selected");}}
 public string Status {get{return status;} set{status=value;Changed("Status");}}
 string installedText="Installée : recherche…",availableText="Disponible : recherche…",versionHint="";
 public bool Installed {get;set;}
 public string InstalledText {get{return installedText;} set{installedText=value;Changed("InstalledText");}}
 public string AvailableText {get{return availableText;} set{availableText=value;Changed("AvailableText");}}
 public string VersionHint {get{return versionHint;} set{versionHint=value;Changed("VersionHint");}}
 public event PropertyChangedEventHandler PropertyChanged;
 void Changed(string name){if(PropertyChanged!=null)PropertyChanged(this,new PropertyChangedEventArgs(name));}
}
public sealed class Job {
 public string[] Ids {get;set;} public bool Update {get;set;} public string Office {get;set;}
 public string Forti {get;set;} public string Winget {get;set;} public bool Simulate {get;set;}
 public string Action {get;set;} public string[] OfficeProducts {get;set;} public bool RemovalConfirmed {get;set;}
 public bool ReplaceStandaloneOneNoteConfirmed {get;set;}
 public bool UpdateOnly {get;set;} public string OfficeChannel {get;set;}
}
public sealed class SelectionProfile {public int Schema{get;set;} public string[] Ids{get;set;} public string Office{get;set;} public bool Update{get;set;}}
public sealed class InventoryRow {public string Id{get;set;} public bool Installed{get;set;} public string InstalledVersion{get;set;} public string AvailableVersion{get;set;} public string Source{get;set;} public string Issue{get;set;} public string OfficeProduct{get;set;} public string OfficeChannel{get;set;}}
public sealed class OfficeVersion {public string Channel{get;set;} public string Version{get;set;}}
public sealed class InventorySnapshot {public bool Complete{get;set;} public string CheckedAt{get;set;} public InventoryRow[] Rows{get;set;} public OfficeVersion[] OfficeVersions{get;set;}}
public static class SelectionTools {
 public static SelectionProfile Validate(SelectionProfile p){
  string[] products={"O365BusinessRetail","O365ProPlusRetail","HomeBusiness2024Retail","Professional2024Retail","Standard2024Volume","ProPlus2024Volume"};
  var allowed=Entry.Catalog().Select(a=>a.Id).ToArray();
  if(p==null||p.Schema!=1||p.Ids==null||p.Ids.Length>9||p.Ids.Distinct().Count()!=p.Ids.Length||p.Ids.Any(id=>!allowed.Contains(id))||!products.Contains(p.Office))throw new InvalidDataException("Sélection enregistrée invalide ou incompatible.");
  return p;
 }
 public static string[] Failed(State state,Job job){
  if(state==null||job==null||job.Ids==null||state.outcomes==null)return new string[0];
  var allowed=Entry.Catalog().Select(a=>a.Id);
  return job.Ids.Where(id=>allowed.Contains(id)&&state.outcomes.Any(o=>o.id==id&&o.status=="Échec")).Distinct().ToArray();
 }
}
public sealed class Outcome {public string id{get;set;} public string status{get;set;} public string detail{get;set;} public int code{get;set;}}
public sealed class ReportRow {public string Title{get;set;} public string Status{get;set;} public string Detail{get;set;} public string Code{get;set;} public string Color{get;set;}}
public sealed class State {
 public int completed{get;set;} public int total{get;set;} public string current{get;set;}
 public string phase{get;set;} public double percent{get;set;} public string message{get;set;}
 public bool done{get;set;} public bool reboot{get;set;} public bool stopped{get;set;} public bool fatal{get;set;}
 public List<Outcome> outcomes{get;set;}
}
public static class Entry {
 public static readonly JavaScriptSerializer Json=new JavaScriptSerializer();
 public static string Resource(string name){using(var s=Assembly.GetExecutingAssembly().GetManifestResourceStream(name))using(var r=new StreamReader(s,Encoding.UTF8))return r.ReadToEnd();}
 public static string Quote(string value){return "\""+value.Replace("\"","")+"\"";}
 public static List<AppItem> Catalog(){return new List<AppItem>{
  Item("Google.Chrome","Google Chrome","Navigation web","Navigateurs","C","#4285F4","winget"),
  Item("Mozilla.Firefox","Mozilla Firefox","Navigation web","Navigateurs","F","#F17936","winget"),
  Item("Opera.Opera","Opera","Navigation web","Navigateurs","O","#E64D64","winget"),
  Item("Adobe.Acrobat.Reader.64-bit","Acrobat Reader","Documents PDF · 64 bits","Bureautique","A","#E8494D","winget"),
  Item("WireGuard.WireGuard","WireGuard","VPN WireGuard","VPN","W","#A33147","winget"),
  Item("Fortinet.VPN","FortiClient VPN","VPN · téléchargement automatique","VPN","F","#D55149","fortinet"),
  Item("OpenVPNTechnologies.OpenVPN","OpenVPN","VPN · édition Community","VPN","O","#EB9339","winget"),
  Item("3CX.Softphone","3CX","Client téléphonique Windows","Bureautique","3","#4561BD","winget"),
  Item("Microsoft.Office","Microsoft Office","Microsoft 365 · 2024 · LTSC","Bureautique","M","#D96B3D","office")
 };}
 static AppItem Item(string id,string title,string sub,string category,string glyph,string color,string kind){return new AppItem{Id=id,Title=title,Subtitle=sub,Category=category,Glyph=glyph,Color=color,Kind=kind};}
 [STAThread] public static int Main(string[] args){
  try{
   if(args.Length==2&&args[0]=="--worker")return Worker(args[1]);
   if(args.Length>0&&args[0]=="--self-test")return SelfTest(args.Length>1?args[1]:null);
   var application=new Application();
   var ui=new InstallerUi(args);
   application.Run(ui.Window);
   return ui.ExitCode;
  }catch(Exception ex){
   string path=Path.Combine(Path.GetTempPath(),"AppDesk-error.txt");File.WriteAllText(path,ex.ToString());
   if(!args.Any(a=>a=="--self-test"||a=="--preview"||a=="--test-run"||a=="--worker"))MessageBox.Show(ex.Message+"\n\nDétails : "+path,"AppDesk",MessageBoxButton.OK,MessageBoxImage.Error);return 1;
  }
 }
 static int Worker(string path){
  Job job=Json.Deserialize<Job>(File.ReadAllText(path));
  try{
  if(!job.Simulate&&!new WindowsPrincipal(WindowsIdentity.GetCurrent()).IsInRole(WindowsBuiltInRole.Administrator))throw new InvalidOperationException("Les droits administrateur requis n’ont pas été accordés.");
  string script=Path.Combine(Path.GetDirectoryName(path),"engine.ps1");
  File.WriteAllText(script,Resource("engine"),new UTF8Encoding(true));
  File.WriteAllText(Path.Combine(Path.GetDirectoryName(path),"Sources.ps1"),Resource("sources"),new UTF8Encoding(true));
  var info=new ProcessStartInfo(Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.System),@"WindowsPowerShell\v1.0\powershell.exe"));
  info.Arguments="-NoProfile -NonInteractive -ExecutionPolicy Bypass -File "+Quote(script)+" -JobPath "+Quote(Path.GetFullPath(path));
  info.UseShellExecute=false;info.CreateNoWindow=true;info.WindowStyle=ProcessWindowStyle.Hidden;info.RedirectStandardOutput=true;info.RedirectStandardError=true;
  using(var p=Process.Start(info)){
   var output=p.StandardOutput.ReadToEndAsync();var errors=p.StandardError.ReadToEndAsync();p.WaitForExit();
   File.WriteAllText(Path.Combine(Path.GetDirectoryName(path),"engine.stdout.log"),output.Result,new UTF8Encoding(true));
   File.WriteAllText(Path.Combine(Path.GetDirectoryName(path),"engine.stderr.log"),errors.Result,new UTF8Encoding(true));
   if(p.ExitCode!=0)WorkerFailure(path,job,"Le moteur a échoué (code "+p.ExitCode+"). "+errors.Result);
   return p.ExitCode;
  }
  }catch(Exception ex){WorkerFailure(path,job,"Démarrage du moteur impossible : "+ex.Message);return 1;}
 }
 static void WorkerFailure(string path,Job job,string detail){
  string statePath=Path.Combine(Path.GetDirectoryName(path),"state.json");State state=null;
  try{if(File.Exists(statePath))state=Json.Deserialize<State>(File.ReadAllText(statePath));}catch{}
  if(state==null)state=new State{total=job.Ids==null?0:job.Ids.Length,outcomes=new List<Outcome>()};
  if(state.done&&state.fatal)return;
  state.done=true;state.fatal=true;state.phase="Interrompu";state.message=detail.Length>1400?detail.Substring(0,1400)+"… Voir engine.stderr.log.":detail;
  File.WriteAllText(statePath,Json.Serialize(state),new UTF8Encoding(true));
 }
 static int SelfTest(string path){
  var apps=Catalog();
  if(apps.Count!=9||apps.Select(x=>x.Id).Distinct().Count()!=9)throw new Exception("Catalogue invalide.");
  string xaml=Resource("ui");var w=(Window)XamlReader.Parse(xaml);
  if(w.FindName("Overall")==null||w.FindName("Install")==null)throw new Exception("Interface invalide.");
  if(w.FindName("ReportPanel")==null||Resource("sources").IndexOf("Get-FortiSource")<0)throw new Exception("Ressources de bilan ou sources absentes.");
  if(w.FindName("RetryFailed")==null||w.FindName("UpdatePresent")==null||Resource("inventory").IndexOf("Read-OfficeVersions")<0)throw new Exception("Ressources des versions et sélections absentes.");
  w.Close();
  if(path!=null)File.WriteAllText(path,"Catalogue: 9\nWPF: OK\nRessources embarquées: OK\nAucune installation lancée.");
  return 0;
 }
}
public sealed class InstallerUi {
 public Window Window;public int ExitCode;
 ObservableCollection<AppItem> apps;ICollectionView view;
 ItemsControl cards;TextBox search;ComboBox edition;CheckBox updates,consent;
 Button install,stop;TextBlock title,completed,activity,fortiHint;ProgressBar overall,activityBar;
 readonly string[] products={"O365BusinessRetail","O365ProPlusRetail","HomeBusiness2024Retail","Professional2024Retail","Standard2024Volume","ProPlus2024Volume"};
 string category="",forti="",runPath="",settingsRoot;bool running,simulating,removingOffice;
 Process worker;DispatcherTimer timer;DateTime startTime;State lastState;
 AppItem[] queuedApps;List<ReportRow> reportRows;string reportText="";DateTime? reportEndedAt;
 Job reportJob;bool updateOnly,refreshPending;InventorySnapshot inventory;Process inventoryProcess;DispatcherTimer inventoryTimer;string inventoryFolder,inventoryFile;
 readonly string[] args;
 T Find<T>(string name)where T:class{return Window.FindName(name)as T;}
 public InstallerUi(string[] arguments){
  args=arguments;settingsRoot=Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.MyDocuments),"AppDesk");
  Window=(Window)XamlReader.Parse(Entry.Resource("ui"));
  Window.MinHeight=Math.Min(Window.MinHeight,Math.Max(500,SystemParameters.WorkArea.Height-40));Window.Height=Math.Min(Window.Height,SystemParameters.WorkArea.Height-40);
  cards=Find<ItemsControl>("Cards");search=Find<TextBox>("Search");edition=Find<ComboBox>("OfficeEdition");
  updates=Find<CheckBox>("UpdateExisting");consent=Find<CheckBox>("Consent");install=Find<Button>("Install");stop=Find<Button>("Stop");
  title=Find<TextBlock>("ProgressTitle");completed=Find<TextBlock>("Completed");activity=Find<TextBlock>("Activity");fortiHint=Find<TextBlock>("FortiHint");overall=Find<ProgressBar>("Overall");activityBar=Find<ProgressBar>("ActivityBar");
  apps=new ObservableCollection<AppItem>(Entry.Catalog());view=CollectionViewSource.GetDefaultView(apps);view.Filter=Filter;cards.ItemsSource=view;
  foreach(var app in apps)app.PropertyChanged+=(o,e)=>{if(e.PropertyName=="Selected")UpdateSelection();};
  foreach(string label in new[]{"Microsoft 365 Apps — Business","Microsoft 365 Apps — Enterprise","Office 2024 — Famille et Petite Entreprise","Office 2024 — Professionnel","Office LTSC 2024 — Standard","Office LTSC 2024 — Professionnel Plus"})edition.Items.Add(label);
  edition.SelectedIndex=0;
  search.TextChanged+=(s,e)=>view.Refresh();
  Find<Button>("NavAll").Click+=(s,e)=>Navigate("");Find<Button>("NavWeb").Click+=(s,e)=>Navigate("Navigateurs");Find<Button>("NavVpn").Click+=(s,e)=>Navigate("VPN");Find<Button>("NavWork").Click+=(s,e)=>Navigate("Bureautique");
  Find<Button>("SelectAll").Click+=(s,e)=>{updateOnly=false;foreach(AppItem item in view)item.Selected=true;UpdateSelection();};
  Find<Button>("ClearAll").Click+=(s,e)=>{updateOnly=false;foreach(var item in apps)item.Selected=false;UpdateSelection();};
  consent.Checked+=(s,e)=>UpdateSelection();consent.Unchecked+=(s,e)=>UpdateSelection();
  Find<Button>("ChooseForti").Click+=(s,e)=>ChooseForti();
  Find<Button>("AutoForti").Click+=(s,e)=>{forti="";DetectForti();};
  Find<Button>("RefreshVersions").Click+=(s,e)=>RefreshVersions();
  Find<Button>("UpdatePresent").Click+=(s,e)=>SelectPresent();
  Find<Button>("SaveSelection").Click+=(s,e)=>SaveSelection();
  Find<Button>("LoadSelection").Click+=(s,e)=>LoadSelection(true);
  Find<Button>("RetryFailed").Click+=(s,e)=>RetryFailed();
  edition.SelectionChanged+=(s,e)=>ApplyInventory();
  Find<Button>("UninstallOffice").Click+=(s,e)=>StartOfficeRemoval();
  Find<Button>("BackToApps").Click+=(s,e)=>ShowReport(false);
  Find<Button>("ShowReport").Click+=(s,e)=>ShowReport(true);
  Find<Button>("ExportReport").Click+=(s,e)=>{var d=new SaveFileDialog{Title="Exporter le rapport",Filter="Rapport texte (*.txt)|*.txt",FileName="AppDesk-rapport-"+DateTime.Now.ToString("yyyyMMdd-HHmmss")+".txt"};if(d.ShowDialog(Window)==true)try{File.WriteAllText(d.FileName,reportText,new UTF8Encoding(true));}catch(Exception ex){MessageBox.Show(Window,"Export impossible : "+ex.Message,"Rapport AppDesk");}};
  Find<Button>("ReportLogs").Click+=(s,e)=>{if(Directory.Exists(runPath))Process.Start(new ProcessStartInfo("explorer.exe",Entry.Quote(runPath)){UseShellExecute=true});};
  Find<System.Windows.Documents.Hyperlink>("OpenLogs").Click+=(s,e)=>{if(Directory.Exists(runPath))Process.Start(new ProcessStartInfo("explorer.exe",Entry.Quote(runPath)){UseShellExecute=true});};
  install.Click+=(s,e)=>Start(false);
  stop.Click+=(s,e)=>{File.WriteAllText(Path.Combine(runPath,"stop.request"),"stop");stop.IsEnabled=false;activity.Text="Arrêt demandé après l’application en cours.";};
  Find<Button>("CloseWindow").Click+=(s,e)=>Window.Close();Find<Button>("Minimize").Click+=(s,e)=>Window.WindowState=WindowState.Minimized;
  Find<System.Windows.Controls.Grid>("TitleBar").MouseLeftButtonDown+=(s,e)=>{if(e.ClickCount==2)return;Window.DragMove();};
  Window.Closing+=(s,e)=>{if(running){e.Cancel=true;activity.Text="Utilisez « Arrêter après cette app » et attendez la fin de l’installation en cours.";}else if(inventoryProcess!=null){try{if(!inventoryProcess.HasExited)inventoryProcess.Kill();}catch{}inventoryProcess.Dispose();inventoryProcess=null;if(inventoryTimer!=null)inventoryTimer.Stop();}};
  Window.Loaded+=(s,e)=>OnLoaded();
  timer=new DispatcherTimer{Interval=TimeSpan.FromMilliseconds(350)};timer.Tick+=(s,e)=>Poll();
  DetectForti();UpdateSelection();
 }
 void SaveSelection(){
  try{
   var profile=SelectionTools.Validate(new SelectionProfile{Schema=1,Ids=apps.Where(a=>a.Selected).Select(a=>a.Id).ToArray(),Office=products[edition.SelectedIndex],Update=updates.IsChecked==true});
   Directory.CreateDirectory(settingsRoot);string path=Path.Combine(settingsRoot,"selection.json"),temp=path+".tmp";
   File.WriteAllText(temp,Entry.Json.Serialize(profile),new UTF8Encoding(false));
   if(File.Exists(path))File.Replace(temp,path,null);else File.Move(temp,path);
   activity.Text="Sélection enregistrée. Elle sera restaurée au prochain lancement.";
  }catch(Exception ex){activity.Text="Enregistrement impossible : "+ex.Message;}
 }
 void LoadSelection(bool explicitLoad){
  try{
   string path=Path.Combine(settingsRoot,"selection.json");if(!File.Exists(path)){if(explicitLoad)activity.Text="Aucune sélection enregistrée.";return;}
   if(new FileInfo(path).Length>65536)throw new InvalidDataException("Fichier de sélection trop volumineux.");
   var profile=SelectionTools.Validate(Entry.Json.Deserialize<SelectionProfile>(File.ReadAllText(path,Encoding.UTF8)));
   updateOnly=false;foreach(var a in apps)a.Selected=profile.Ids.Contains(a.Id);edition.SelectedIndex=Array.IndexOf(products,profile.Office);updates.IsChecked=profile.Update;
   consent.IsChecked=false;UpdateSelection();activity.Text="Sélection restaurée. Vérifiez les choix avant de lancer l’installation.";
  }catch(Exception ex){activity.Text="Restauration impossible : "+ex.Message;}
 }
 void RetryFailed(){
  if(running)return;var ids=SelectionTools.Failed(lastState,reportJob);if(ids.Length==0)return;
  if(reportJob.Action=="RemoveOffice"){StartOfficeRemoval();return;}
  updateOnly=reportJob.UpdateOnly;foreach(var a in apps)a.Selected=ids.Contains(a.Id);
  int index=Array.IndexOf(products,reportJob.Office);if(index>=0)edition.SelectedIndex=index;
  updates.IsChecked=reportJob.Update;forti=reportJob.Forti??"";DetectForti();consent.IsChecked=false;
  category="";search.Text="";view.Refresh();ShowReport(false);UpdateSelection();
  activity.Text=ids.Length+" échec(s) sélectionné(s). Vérifiez puis lancez la nouvelle tentative.";
 }
 void SelectPresent(){
  if(running)return;
  if(inventory==null||inventory.Rows==null){activity.Text="La détection des applications est encore en cours.";return;}
  var office=inventory.Rows.FirstOrDefault(r=>r.Id=="Microsoft.Office"&&r.Installed);
  bool officeSupported=office!=null&&Array.IndexOf(products,office.OfficeProduct)>=0&&office.OfficeChannel== (office.OfficeProduct.EndsWith("Volume")?"PerpetualVL2024":"Current");
  updateOnly=true;
  foreach(var a in apps)a.Selected=inventory.Rows.Any(r=>r.Id==a.Id&&r.Installed)&&(a.Kind!="office"||officeSupported);
  if(officeSupported)edition.SelectedIndex=Array.IndexOf(products,office.OfficeProduct);
  updates.IsChecked=true;forti="";DetectForti();consent.IsChecked=false;category="";search.Text="";view.Refresh();ShowReport(false);UpdateSelection();
  activity.Text="Mode mise à jour seule : aucune application absente ne sera installée."+(office!=null&&!officeSupported?" Office exclu : édition ou canal non pris en charge.":"");
 }
 void RefreshVersions(){
  if(running)return;if(inventoryProcess!=null){refreshPending=true;return;}
  try{
   inventoryFolder=Path.Combine(Path.GetTempPath(),"AppDesk-inventory-"+Guid.NewGuid().ToString("N"));Directory.CreateDirectory(inventoryFolder);
   foreach(string resource in new[]{"inventory","sources"})File.WriteAllText(Path.Combine(inventoryFolder,resource=="inventory"?"Inventory.ps1":"Sources.ps1"),Entry.Resource(resource),new UTF8Encoding(true));
   inventoryFile=Path.Combine(inventoryFolder,"versions.json");
   var p=new ProcessStartInfo(Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.System),@"WindowsPowerShell\v1.0\powershell.exe"));
   p.Arguments="-NoProfile -NonInteractive -ExecutionPolicy Bypass -File "+Entry.Quote(Path.Combine(inventoryFolder,"Inventory.ps1"))+" -OutputPath "+Entry.Quote(inventoryFile)+" -Winget "+Entry.Quote(Winget());
   p.UseShellExecute=false;p.CreateNoWindow=true;p.RedirectStandardError=true;
   inventoryProcess=Process.Start(p);var errors=inventoryProcess.StandardError.ReadToEndAsync();
   Find<Button>("RefreshVersions").IsEnabled=false;Find<TextBlock>("VersionsStatus").Text="Recherche des versions en ligne…";
   inventoryTimer=new DispatcherTimer{Interval=TimeSpan.FromMilliseconds(600)};
   inventoryTimer.Tick+=(s,e)=>{
    try{if(File.Exists(inventoryFile)){var value=Entry.Json.Deserialize<InventorySnapshot>(File.ReadAllText(inventoryFile,Encoding.UTF8));inventory=value;ApplyInventory();}}catch(IOException){}catch(ArgumentException){}
    if(inventoryProcess!=null&&inventoryProcess.HasExited){
     bool ok=inventory!=null&&inventory.Complete&&inventoryProcess.ExitCode==0;inventoryTimer.Stop();inventoryProcess.Dispose();inventoryProcess=null;
     Find<Button>("RefreshVersions").IsEnabled=!running;
     Find<TextBlock>("VersionsStatus").Text=ok?"Versions vérifiées à "+DateTime.Now.ToString("HH:mm")+" · dernière version connue des sources":"Recherche incomplète · cliquez sur Actualiser";
     Find<TextBlock>("VersionsStatus").ToolTip=errors.IsCompleted?errors.Result:"";
     try{Directory.Delete(inventoryFolder,true);}catch(IOException){}catch(UnauthorizedAccessException){}
     if(refreshPending){refreshPending=false;RefreshVersions();}
    }
   };inventoryTimer.Start();
  }catch(Exception ex){Find<TextBlock>("VersionsStatus").Text="Recherche impossible : "+ex.Message;Find<Button>("RefreshVersions").IsEnabled=true;}
 }
 void ApplyInventory(){
  if(inventory==null||inventory.Rows==null)return;
  if(inventory.Complete){DateTime checkedAt;Find<TextBlock>("VersionsStatus").Text="Versions consultées"+(DateTime.TryParse(inventory.CheckedAt,out checkedAt)?" à "+checkedAt.ToString("HH:mm"):"")+" · sources en ligne";}
  foreach(var a in apps){
   var row=inventory.Rows.FirstOrDefault(r=>r.Id==a.Id);if(row==null)continue;
   a.Installed=row.Installed;
   a.InstalledText="Installée : "+(row.Installed?(string.IsNullOrEmpty(row.InstalledVersion)?"version inconnue":row.InstalledVersion):"absente");
   string available=row.AvailableVersion,source=row.Source,issue=row.Issue;
   if(a.Kind=="office"){
    string channel=products[Math.Max(0,edition.SelectedIndex)].EndsWith("Volume")?"PerpetualVL2024":"Current";
    var v=inventory.OfficeVersions==null?null:inventory.OfficeVersions.FirstOrDefault(x=>x.Channel==channel);available=v==null?"":v.Version;source="Microsoft · "+channel;
    if(row.Installed)source+="\nProduit installé : "+row.OfficeProduct+" · "+row.OfficeChannel;
   }
   a.AvailableText="Disponible : "+(!string.IsNullOrEmpty(available)?available:!string.IsNullOrEmpty(issue)||inventory.Complete?"indisponible":"recherche…");
   a.VersionHint=a.InstalledText+"\n"+a.AvailableText+"\n"+source+(string.IsNullOrEmpty(issue)?"":"\n"+issue)+"\nLecture seule : version résolue de nouveau à l’installation.";
  }
 }
 bool Filter(object value){var app=(AppItem)value;return(category==""||app.Category==category)&&(app.Title.IndexOf(search.Text,StringComparison.OrdinalIgnoreCase)>=0||app.Subtitle.IndexOf(search.Text,StringComparison.OrdinalIgnoreCase)>=0);}
 void Navigate(string value){ShowReport(false);category=value;view.Refresh();}
 void UpdateSelection(){
  int count=apps.Count(a=>a.Selected);if(!running)completed.Text=count+" application"+(count>1?"s":"")+" sélectionnée"+(count>1?"s":"");
  install.IsEnabled=!running&&count>0&&consent.IsChecked==true;
  if(!running)install.Content=updateOnly?"Mettre à jour la sélection  →":"Installer la sélection  →";
  edition.IsEnabled=!running&&!updateOnly&&apps.Any(a=>a.Kind=="office"&&a.Selected);
 }
 bool IsFullPackage(string path){
  if(Path.GetExtension(path).Equals(".msi",StringComparison.OrdinalIgnoreCase))return true;
  var version=FileVersionInfo.GetVersionInfo(path);
  return new FileInfo(path).Length>20000000&&(version.FileDescription??"").IndexOf("online",StringComparison.OrdinalIgnoreCase)<0;
 }
 void DetectForti(){
  fortiHint.Text=forti==""?"Versions résolues en ligne · FortiClient VPN : portail officiel régional Fortinet, signature vérifiée.":"FortiClient manuel : "+Path.GetFileName(forti)+" · cliquez sur Automatique pour rechercher la dernière version.";
 }
 void ChooseForti(){
  var dialog=new OpenFileDialog{Title="Package complet officiel FortiClient VPN",Filter="Installateur FortiClient (*.msi;*.exe)|*.msi;*.exe"};
  string dir=Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.UserProfile),@"Nextcloud\Commun\Installateurs\FortiClient");if(Directory.Exists(dir))dialog.InitialDirectory=dir;
  if(dialog.ShowDialog(Window)!=true)return;
  if(!IsFullPackage(dialog.FileName)){MessageBox.Show(Window,"Ce fichier est un lanceur en ligne. Sélectionnez le MSI ou l’EXE complet FortiClient VPN pour une installation silencieuse.","Package incomplet",MessageBoxButton.OK,MessageBoxImage.Information);return;}
  forti=dialog.FileName;DetectForti();
 }
 void Enable(bool enabled){
  cards.IsEnabled=enabled;search.IsEnabled=enabled;updates.IsEnabled=enabled;consent.IsEnabled=enabled;
  foreach(string name in new[]{"SelectAll","ClearAll","ChooseForti","AutoForti","UninstallOffice","NavAll","NavWeb","NavVpn","NavWork","ShowReport","UpdatePresent","SaveSelection","LoadSelection","RetryFailed"})Find<Button>(name).IsEnabled=enabled;
  Find<Button>("RefreshVersions").IsEnabled=enabled&&inventoryProcess==null;
  stop.Visibility=enabled?Visibility.Collapsed:Visibility.Visible;stop.IsEnabled=true;UpdateSelection();
  install.Content=enabled?(updateOnly?"Mettre à jour la sélection  →":"Installer la sélection  →"):"En cours…";
 }
 string Winget(){
  string alias=Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),@"Microsoft\WindowsApps\winget.exe");
  if(File.Exists(alias))return alias;
  foreach(string folder in(Environment.GetEnvironmentVariable("PATH")??"").Split(';')){try{string p=Path.Combine(folder,"winget.exe");if(File.Exists(p))return p;}catch{}}
  return "";
 }
 void Start(bool demo){
  var selected=apps.Where(a=>a.Selected).ToArray();if(selected.Length==0||running)return;
  string winget=Winget();if(!demo&&selected.Any(a=>a.Kind=="winget")&&winget==""){MessageBox.Show(Window,"Installez « Programme d’installation d’application » de Microsoft pour disposer de WinGet.","WinGet requis");return;}
  var officeRow=inventory==null||inventory.Rows==null?null:inventory.Rows.FirstOrDefault(r=>r.Id=="Microsoft.Office");
  var job=new Job{Ids=selected.Select(a=>a.Id).ToArray(),Update=updateOnly||updates.IsChecked==true,Office=products[edition.SelectedIndex],Forti=forti,Winget=winget,Simulate=demo,Action="Install",UpdateOnly=updateOnly,OfficeChannel=updateOnly&&officeRow!=null?officeRow.OfficeChannel:null};
  if(!demo&&selected.Any(a=>a.Id=="Microsoft.Office")&&job.Office.EndsWith("Volume")&&InstalledOfficeProducts().Contains("OneNoteFreeRetail")){
   string message="OneNote autonome est encore installé. Microsoft ne prend pas en charge cette édition autonome avec Office LTSC.\n\nPour installer l’édition LTSC choisie, l’outil Microsoft retirera OneNote autonome et installera OneNote avec la nouvelle suite Office. Vos blocs-notes ne sont pas ciblés par la suppression ; vérifiez leur synchronisation ou sauvegarde et fermez OneNote avant de continuer.\n\nConfirmer ce remplacement de OneNote pendant l’installation Office ?";
   if(MessageBox.Show(Window,message,"Compatibilité OneNote et Office LTSC",MessageBoxButton.YesNo,MessageBoxImage.Warning,MessageBoxResult.No)!=MessageBoxResult.Yes)return;
   job.ReplaceStandaloneOneNoteConfirmed=true;
  }
  StartJob(job,selected,demo);
 }
 string[] InstalledOfficeProducts(){
  var found=new List<string>();
  foreach(var view in new[]{RegistryView.Registry64,RegistryView.Registry32})using(var hive=RegistryKey.OpenBaseKey(RegistryHive.LocalMachine,view))using(var key=hive.OpenSubKey(@"SOFTWARE\Microsoft\Office\ClickToRun\Configuration")){
   if(key!=null)foreach(var id in Convert.ToString(key.GetValue("ProductReleaseIds","")).Split(','))if(id!="")found.Add(id);
  }
  return found.Distinct().OrderBy(x=>x).ToArray();
 }
 string[] InstalledOfficeRemovalProducts(){return InstalledOfficeProducts().Where(id=>id=="OneNoteFreeRetail"||Regex.IsMatch(id,@"^(?:O365[A-Za-z0-9]*Retail|(?:HomeBusiness|HomeStudent|Professional|ProPlus|Standard|Personal)(?:20(?:16|19|21|24))?(?:Retail|Volume))$")).ToArray();}
 string OfficeProductName(string id){
  if(id=="O365HomePremRetail")return "Microsoft 365 Personnel / Famille";
  if(id=="OneNoteFreeRetail")return "Microsoft OneNote (autonome)";
  if(id.StartsWith("O365Business"))return "Microsoft 365 Apps — Business";
  if(id.StartsWith("O365ProPlus"))return "Microsoft 365 Apps — Enterprise";
  var names=new[]{"Microsoft 365 Apps — Business","Microsoft 365 Apps — Enterprise","Office 2024 — Famille et Petite Entreprise","Office 2024 — Professionnel","Office LTSC 2024 — Standard","Office LTSC 2024 — Professionnel Plus"};
  int index=Array.IndexOf(products,id);return index>=0?names[index]:"Microsoft Office ("+id+")";
 }
 void StartOfficeRemoval(){
  if(running)return;
  string[] targets;
  try{targets=InstalledOfficeRemovalProducts();}catch(Exception ex){MessageBox.Show(Window,"Détection Office impossible : "+ex.Message,"Désinstaller Office");return;}
  if(targets.Length==0){MessageBox.Show(Window,"Aucune suite Office ni OneNote autonome Click-to-Run compatible n’a été détecté. Les anciennes installations MSI et les versions Microsoft Store doivent être supprimées depuis les applications installées de Windows.","Désinstaller Office",MessageBoxButton.OK,MessageBoxImage.Information);return;}
  string list=string.Join("\n",targets.Select(id=>"• "+OfficeProductName(id)).ToArray());
  string message="Les produits suivants seront désinstallés :\n\n"+list+"\n\nOffice Removal inclut OneNote autonome lorsqu’il est présent. Vérifiez la synchronisation ou la sauvegarde de vos blocs-notes, enregistrez vos documents et fermez Office et OneNote. Aucun programme ouvert ne sera fermé automatiquement.\n\nVisio et Project ne sont pas ciblés. Cette action ne supprime pas vos documents personnels et ne résilie pas votre abonnement. Une licence sera nécessaire pour réinstaller Office.\n\nConfirmer la désinstallation de cette sélection ?";
  if(MessageBox.Show(Window,message,"Confirmer la désinstallation Office",MessageBoxButton.YesNo,MessageBoxImage.Warning,MessageBoxResult.No)!=MessageBoxResult.Yes)return;
  var job=new Job{Ids=new[]{"Microsoft.Office"},Office=products[edition.SelectedIndex],Action="RemoveOffice",OfficeProducts=targets,RemovalConfirmed=true,Simulate=false};
  StartJob(job,new[]{apps.First(a=>a.Id=="Microsoft.Office")},false);
 }
 void StartJob(Job job,AppItem[] selected,bool demo){
  try{
   removingOffice=job.Action=="RemoveOffice";
   reportJob=Entry.Json.Deserialize<Job>(Entry.Json.Serialize(job));
   queuedApps=selected;reportEndedAt=null;ShowReport(false);Find<Button>("ShowReport").Visibility=Visibility.Collapsed;
   runPath=Path.Combine(settingsRoot,"Sessions",DateTime.Now.ToString("yyyyMMdd-HHmmss")+"-"+Guid.NewGuid().ToString("N").Substring(0,6));Directory.CreateDirectory(runPath);
   string path=Path.Combine(runPath,"job.json");File.WriteAllText(path,Entry.Json.Serialize(job),new UTF8Encoding(false));
   foreach(var app in apps)app.Status=selected.Any(a=>a.Id==app.Id)?"Dans la file":"";
   var start=new ProcessStartInfo(Assembly.GetExecutingAssembly().Location,"--worker "+Entry.Quote(path));
   start.UseShellExecute=!demo;start.CreateNoWindow=true;start.WindowStyle=ProcessWindowStyle.Hidden;if(!demo)start.Verb="runas";
   worker=Process.Start(start);running=true;simulating=demo;lastState=null;startTime=DateTime.Now;
   Enable(false);overall.Value=0;title.Text=demo?"Démonstration — aucune installation":"Préparation de votre sélection…";activity.Text="Vérification des prérequis et démarrage du moteur.";timer.Start();
  }catch(Win32Exception ex){activity.Text=ex.NativeErrorCode==1223?"Autorisation Windows annulée. Aucune opération n’a démarré.":ex.Message;}
  catch(Exception ex){activity.Text=ex.Message;}
 }
 void Poll(){
  string path=Path.Combine(runPath,"state.json");
  try{if(File.Exists(path)){State state;using(var file=new FileStream(path,FileMode.Open,FileAccess.Read,FileShare.ReadWrite|FileShare.Delete))using(var reader=new StreamReader(file,Encoding.UTF8)){state=Entry.Json.Deserialize<State>(reader.ReadToEnd());}lastState=state;Apply(state);if(state.done){Finish(state);return;}}}catch(IOException){}catch(ArgumentException){}
  if(worker!=null&&worker.HasExited){
   try{if(File.Exists(path)){var finalState=Entry.Json.Deserialize<State>(File.ReadAllText(path,Encoding.UTF8));if(finalState.done){lastState=finalState;Apply(finalState);Finish(finalState);return;}}}catch(IOException){}catch(ArgumentException){}
   if(lastState==null||!lastState.done){Finish(lastState);title.Text="Installation interrompue";activity.Text="Le moteur s’est arrêté sans bilan complet. Consultez le rapport.";ExitCode=simulating?1:0;}
  }
 }
 void Apply(State state){
  overall.Value=state.total>0?100.0*state.completed/state.total:0;
  completed.Text=state.completed+" / "+state.total+" terminée(s)";
  var current=apps.FirstOrDefault(a=>a.Id==state.current);
  title.Text=simulating?"Démonstration — aucune installation":removingOffice?"Microsoft Office — désinstallation":current!=null?current.Title:"Traitement de la sélection";
  activity.Text=state.message;
  activityBar.Visibility=state.done?Visibility.Collapsed:Visibility.Visible;
  activityBar.IsIndeterminate=state.percent<0;if(state.percent>=0)activityBar.Value=state.percent;
  if(current!=null&&!state.done)current.Status=state.phase;
  if(state.outcomes!=null)foreach(var result in state.outcomes){var app=apps.FirstOrDefault(a=>a.Id==result.id);if(app!=null)app.Status=result.status;}
 }
 void Finish(State state){
  timer.Stop();running=false;Enable(true);activityBar.Visibility=Visibility.Collapsed;
  if(worker!=null){worker.Dispose();worker=null;}
  if(state!=null){
   int errors=state.outcomes==null?0:state.outcomes.Count(x=>x.status=="Échec");
   title.Text=simulating?"Démonstration terminée":state.stopped?"File arrêtée":state.fatal||state.completed<state.total?"Traitement interrompu":errors>0?"Terminé avec "+errors+" erreur(s)":"Votre sélection est prête.";
   completed.Text=state.completed+" / "+state.total+" traitée(s)";
   string issue=state.fatal?state.message:errors>0?state.outcomes.First(x=>x.status=="Échec").detail:"Les applications traitées sont indiquées ci-dessus.";
   activity.Text=(state.reboot?"Redémarrage requis (non lancé). ":"")+issue;activity.ToolTip=activity.Text+"\nJournaux : "+runPath;
   foreach(var app in apps.Where(a=>a.Status=="Dans la file"))app.Status="Non traitée";
  }
  BuildReport(state);ShowReport(true);Find<Button>("ShowReport").Visibility=Visibility.Visible;
  if(!simulating&&!args.Contains("--preview"))RefreshVersions();
  if(simulating&&args.Contains("--test-run")){
   string output=ArgumentValue("--test-run");if(output!=null){Directory.CreateDirectory(output);File.WriteAllText(Path.Combine(output,"simulation-result.json"),Entry.Json.Serialize(state));File.WriteAllText(Path.Combine(output,"report.txt"),reportText);Capture(Path.Combine(output,"simulation.png"));}
   ExitCode=state!=null&&state.done&&state.completed==9?0:1;Window.Close();
  }
 }
 void ShowReport(bool show){Find<Grid>("ReportPanel").Visibility=show?Visibility.Visible:Visibility.Collapsed;Find<Grid>("CatalogPanel").Visibility=show?Visibility.Collapsed:Visibility.Visible;}
 void BuildReport(State state){
  lastState=state;
  var results=state==null||state.outcomes==null?new List<Outcome>():state.outcomes;
  reportRows=new List<ReportRow>();
  foreach(var app in queuedApps??new AppItem[0]){
   var result=results.FirstOrDefault(x=>x.id==app.Id);
   string status=result==null?"Non traitée":result.status;
   string detail=result==null?(state!=null&&state.stopped?"File arrêtée avant cette application.":state!=null&&state.fatal?state.message:"Le moteur n’a pas fourni de résultat pour cette application."):result.detail;
   reportRows.Add(new ReportRow{Title=removingOffice&&app.Id=="Microsoft.Office"?"Microsoft Office — désinstallation":app.Title,Status=status,Detail=detail,Code=result==null?"":("Code "+result.code+" · 0x"+unchecked((uint)result.code).ToString("X8")),Color=result==null?"#7C8BA3":status=="Échec"?"#C13C4B":result.code==3010?"#9A6A15":"#237E63"});
  }
  int failed=results.Count(x=>x.status=="Échec"),installed=results.Count(x=>x.code==0||x.code==3010),kept=results.Count-failed-installed,missing=reportRows.Count-results.Count;
  Find<TextBlock>("ReportTitle").Text=state==null||!state.done||state.fatal||(!state.stopped&&state.completed<state.total)?"Parcours interrompu":simulating?"Bilan de démonstration":state.stopped?"Bilan après arrêt":failed>0?(removingOffice?"Désinstallation terminée avec des erreurs":"Installation terminée avec des erreurs"):removingOffice?"Désinstallation Office terminée":"Votre sélection est prête.";
  Find<TextBlock>("ReportSummary").Text=installed+" réussie(s) · "+kept+" conservée(s) · "+failed+" échec(s) · "+Math.Max(0,missing)+" non traitée(s)";
  DateTime ended=reportEndedAt??DateTime.Now;
  Find<TextBlock>("ReportContext").Text=(simulating?"Simulation : aucune application installée. · ":"")+ended.ToString("dd/MM/yyyy HH:mm")+" · Durée : "+(ended-startTime).ToString(@"hh\:mm\:ss")+(state!=null&&state.reboot?" · Redémarrage requis, non lancé.":"");
  Find<TextBlock>("ReportIssue").Text=state!=null&&state.fatal?state.message:state==null||!state.done?"Résultats partiels : le moteur s’est arrêté sans bilan complet.":"";
  Find<ItemsControl>("ReportRows").ItemsSource=reportRows;
  Find<Button>("RetryFailed").Visibility=SelectionTools.Failed(state,reportJob).Length>0?Visibility.Visible:Visibility.Collapsed;
  var text=new StringBuilder();text.AppendLine("APPDESK — "+Find<TextBlock>("ReportTitle").Text);text.AppendLine(Find<TextBlock>("ReportContext").Text);text.AppendLine(Find<TextBlock>("ReportSummary").Text);text.AppendLine(Find<TextBlock>("ReportIssue").Text);
  foreach(var row in reportRows){text.AppendLine();text.AppendLine(row.Title+" : "+row.Status);text.AppendLine(row.Detail);text.AppendLine(row.Code);}
  string sources=Path.Combine(runPath,"sources.jsonl");if(File.Exists(sources)){text.AppendLine();text.AppendLine("Provenance des téléchargements vérifiés :");text.AppendLine(File.ReadAllText(sources));}
  text.AppendLine();text.AppendLine("Journaux : "+runPath);reportText=text.ToString();
  try{File.WriteAllText(Path.Combine(runPath,"rapport.txt"),reportText,new UTF8Encoding(true));}catch(IOException){}catch(UnauthorizedAccessException){}
 }
 string ArgumentValue(string key){int n=Array.IndexOf(args,key);return n>=0&&n+1<args.Length?args[n+1]:null;}
 void OnLoaded(){
  string snapshot=ArgumentValue("--inventory-snapshot");if(snapshot!=null&&args.Contains("--preview")){inventory=Entry.Json.Deserialize<InventorySnapshot>(File.ReadAllText(snapshot));ApplyInventory();}
  string requestedEdition=ArgumentValue("--office-edition");
  if(requestedEdition!=null&&Array.IndexOf(products,requestedEdition)>=0){edition.SelectedIndex=Array.IndexOf(products,requestedEdition);apps.First(a=>a.Id=="Microsoft.Office").Selected=true;}
  string session=ArgumentValue("--report-session");
  if(session!=null){
   runPath=Path.GetFullPath(session);var job=Entry.Json.Deserialize<Job>(File.ReadAllText(Path.Combine(runPath,"job.json")));removingOffice=job.Action=="RemoveOffice";
   reportJob=job;
   queuedApps=apps.Where(a=>job.Ids.Contains(a.Id)).ToArray();startTime=Directory.GetCreationTime(runPath);reportEndedAt=File.GetLastWriteTime(Path.Combine(runPath,"state.json"));simulating=job.Simulate;
   var state=Entry.Json.Deserialize<State>(File.ReadAllText(Path.Combine(runPath,"state.json")));BuildReport(state);ShowReport(true);Find<Button>("ShowReport").Visibility=Visibility.Visible;
  }
  string preview=ArgumentValue("--preview");
  if(preview!=null){
   if(args.Contains("--busy")){apps[0].Selected=true;apps[3].Selected=true;apps[8].Selected=true;apps[0].Status="Installée";apps[3].Status="Téléchargement";apps[8].Status="Dans la file";title.Text="Acrobat Reader";completed.Text="1 / 3 terminée(s)";overall.Value=100.0/3;activity.Text="Téléchargement du programme d’installation · 62 %";activityBar.Visibility=Visibility.Visible;activityBar.Value=62;}
   Window.Dispatcher.BeginInvoke(new Action(()=>{Capture(preview);Window.Close();}),DispatcherPriority.ApplicationIdle);
  }
  if(args.Contains("--test-run")){foreach(var app in apps)app.Selected=true;consent.IsChecked=true;Start(true);}
  if(session==null&&!args.Contains("--preview")&&!args.Contains("--test-run")){
   if(requestedEdition==null){var detected=InstalledOfficeProducts();if(detected.Length==1&&Array.IndexOf(products,detected[0])>=0)edition.SelectedIndex=Array.IndexOf(products,detected[0]);}
   LoadSelection(false);RefreshVersions();
  }
 }
 void Capture(string path){
  Window.UpdateLayout();
  var bitmap=new RenderTargetBitmap((int)Window.ActualWidth,(int)Window.ActualHeight,96,96,PixelFormats.Pbgra32);bitmap.Render(Window);
  var png=new PngBitmapEncoder();png.Frames.Add(BitmapFrame.Create(bitmap));using(var stream=File.Create(path))png.Save(stream);
 }
}
