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
[assembly: AssemblyFileVersion("2.2.0.0")]
[assembly: AssemblyInformationalVersion("2.2.0.0")]
[assembly: AssemblyVersion("2.2.0.0")]

public sealed class AppItem : INotifyPropertyChanged {
 public string Id {get;set;} public string Title {get;set;} public string Subtitle {get;set;}
 public string Category {get;set;} public string Glyph {get;set;} public string Color {get;set;}
 public string Kind {get;set;}
 bool selected; string status="";
 public bool Selected {get{return selected;} set{selected=value;Changed("Selected");}}
 public string Status {get{return status;} set{status=value;Changed("Status");}}
 public event PropertyChangedEventHandler PropertyChanged;
 void Changed(string name){if(PropertyChanged!=null)PropertyChanged(this,new PropertyChangedEventArgs(name));}
}
public sealed class Job {
 public string[] Ids {get;set;} public bool Update {get;set;} public string Office {get;set;}
 public string Forti {get;set;} public string Winget {get;set;} public bool Simulate {get;set;}
 public string Action {get;set;} public string[] OfficeProducts {get;set;} public bool RemovalConfirmed {get;set;}
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
  if(!job.Simulate&&!new WindowsPrincipal(WindowsIdentity.GetCurrent()).IsInRole(WindowsBuiltInRole.Administrator))return 740;
  string script=Path.Combine(Path.GetDirectoryName(path),"engine.ps1");
  File.WriteAllText(script,Resource("engine"),new UTF8Encoding(true));
  File.WriteAllText(Path.Combine(Path.GetDirectoryName(path),"Sources.ps1"),Resource("sources"),new UTF8Encoding(true));
  var info=new ProcessStartInfo(Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.System),@"WindowsPowerShell\v1.0\powershell.exe"));
  info.Arguments="-NoProfile -NonInteractive -ExecutionPolicy Bypass -File "+Quote(script)+" -JobPath "+Quote(Path.GetFullPath(path));
  info.UseShellExecute=false;info.CreateNoWindow=true;info.WindowStyle=ProcessWindowStyle.Hidden;
  using(var p=Process.Start(info)){p.WaitForExit();return p.ExitCode;}
 }
 static int SelfTest(string path){
  var apps=Catalog();
  if(apps.Count!=9||apps.Select(x=>x.Id).Distinct().Count()!=9)throw new Exception("Catalogue invalide.");
  string xaml=Resource("ui");var w=(Window)XamlReader.Parse(xaml);
  if(w.FindName("Overall")==null||w.FindName("Install")==null)throw new Exception("Interface invalide.");
  if(w.FindName("ReportPanel")==null||Resource("sources").IndexOf("Get-FortiSource")<0)throw new Exception("Ressources de bilan ou sources absentes.");
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
 readonly string[] args;
 T Find<T>(string name)where T:class{return Window.FindName(name)as T;}
 public InstallerUi(string[] arguments){
  args=arguments;settingsRoot=Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.MyDocuments),"AppDesk");
  Window=(Window)XamlReader.Parse(Entry.Resource("ui"));
  cards=Find<ItemsControl>("Cards");search=Find<TextBox>("Search");edition=Find<ComboBox>("OfficeEdition");
  updates=Find<CheckBox>("UpdateExisting");consent=Find<CheckBox>("Consent");install=Find<Button>("Install");stop=Find<Button>("Stop");
  title=Find<TextBlock>("ProgressTitle");completed=Find<TextBlock>("Completed");activity=Find<TextBlock>("Activity");fortiHint=Find<TextBlock>("FortiHint");overall=Find<ProgressBar>("Overall");activityBar=Find<ProgressBar>("ActivityBar");
  apps=new ObservableCollection<AppItem>(Entry.Catalog());view=CollectionViewSource.GetDefaultView(apps);view.Filter=Filter;cards.ItemsSource=view;
  foreach(var app in apps)app.PropertyChanged+=(o,e)=>{if(e.PropertyName=="Selected")UpdateSelection();};
  foreach(string label in new[]{"Microsoft 365 Apps — Business","Microsoft 365 Apps — Enterprise","Office 2024 — Famille et Petite Entreprise","Office 2024 — Professionnel","Office LTSC 2024 — Standard","Office LTSC 2024 — Professionnel Plus"})edition.Items.Add(label);
  edition.SelectedIndex=0;
  search.TextChanged+=(s,e)=>view.Refresh();
  Find<Button>("NavAll").Click+=(s,e)=>Navigate("");Find<Button>("NavWeb").Click+=(s,e)=>Navigate("Navigateurs");Find<Button>("NavVpn").Click+=(s,e)=>Navigate("VPN");Find<Button>("NavWork").Click+=(s,e)=>Navigate("Bureautique");
  Find<Button>("SelectAll").Click+=(s,e)=>{foreach(AppItem item in view)item.Selected=true;};
  Find<Button>("ClearAll").Click+=(s,e)=>{foreach(var item in apps)item.Selected=false;};
  consent.Checked+=(s,e)=>UpdateSelection();consent.Unchecked+=(s,e)=>UpdateSelection();
  Find<Button>("ChooseForti").Click+=(s,e)=>ChooseForti();
  Find<Button>("AutoForti").Click+=(s,e)=>{forti="";DetectForti();};
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
  Window.Closing+=(s,e)=>{if(running){e.Cancel=true;activity.Text="Utilisez « Arrêter après cette app » et attendez la fin de l’installation en cours.";}};
  Window.Loaded+=(s,e)=>OnLoaded();
  timer=new DispatcherTimer{Interval=TimeSpan.FromMilliseconds(350)};timer.Tick+=(s,e)=>Poll();
  DetectForti();UpdateSelection();
 }
 bool Filter(object value){var app=(AppItem)value;return(category==""||app.Category==category)&&(app.Title.IndexOf(search.Text,StringComparison.OrdinalIgnoreCase)>=0||app.Subtitle.IndexOf(search.Text,StringComparison.OrdinalIgnoreCase)>=0);}
 void Navigate(string value){ShowReport(false);category=value;view.Refresh();}
 void UpdateSelection(){
  int count=apps.Count(a=>a.Selected);if(!running)completed.Text=count+" application"+(count>1?"s":"")+" sélectionnée"+(count>1?"s":"");
  install.IsEnabled=!running&&count>0&&consent.IsChecked==true;
  edition.IsEnabled=!running&&apps.Any(a=>a.Kind=="office"&&a.Selected);
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
  foreach(string name in new[]{"SelectAll","ClearAll","ChooseForti","AutoForti","UninstallOffice","NavAll","NavWeb","NavVpn","NavWork","ShowReport"})Find<Button>(name).IsEnabled=enabled;
  stop.Visibility=enabled?Visibility.Collapsed:Visibility.Visible;stop.IsEnabled=true;UpdateSelection();
  install.Content=enabled?"Installer la sélection  →":"En cours…";
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
  var job=new Job{Ids=selected.Select(a=>a.Id).ToArray(),Update=updates.IsChecked==true,Office=products[edition.SelectedIndex],Forti=forti,Winget=winget,Simulate=demo,Action="Install"};
  StartJob(job,selected,demo);
 }
 string[] InstalledOfficeSuites(){
  var found=new List<string>();
  foreach(var view in new[]{RegistryView.Registry64,RegistryView.Registry32})using(var hive=RegistryKey.OpenBaseKey(RegistryHive.LocalMachine,view))using(var key=hive.OpenSubKey(@"SOFTWARE\Microsoft\Office\ClickToRun\Configuration")){
   if(key!=null)foreach(var id in Convert.ToString(key.GetValue("ProductReleaseIds","")).Split(','))if(Regex.IsMatch(id,@"^(?:O365[A-Za-z0-9]*Retail|(?:HomeBusiness|HomeStudent|Professional|ProPlus|Standard|Personal)(?:20(?:16|19|21|24))?(?:Retail|Volume))$"))found.Add(id);
  }
  return found.Distinct().OrderBy(x=>x).ToArray();
 }
 string OfficeProductName(string id){
  if(id=="O365HomePremRetail")return "Microsoft 365 Personnel / Famille";
  if(id.StartsWith("O365Business"))return "Microsoft 365 Apps — Business";
  if(id.StartsWith("O365ProPlus"))return "Microsoft 365 Apps — Enterprise";
  var names=new[]{"Microsoft 365 Apps — Business","Microsoft 365 Apps — Enterprise","Office 2024 — Famille et Petite Entreprise","Office 2024 — Professionnel","Office LTSC 2024 — Standard","Office LTSC 2024 — Professionnel Plus"};
  int index=Array.IndexOf(products,id);return index>=0?names[index]:"Microsoft Office ("+id+")";
 }
 void StartOfficeRemoval(){
  if(running)return;
  string[] targets;
  try{targets=InstalledOfficeSuites();}catch(Exception ex){MessageBox.Show(Window,"Détection Office impossible : "+ex.Message,"Désinstaller Office");return;}
  if(targets.Length==0){MessageBox.Show(Window,"Aucune suite Office Click-to-Run compatible n’a été détectée. Les anciennes installations MSI et les versions Microsoft Store doivent être supprimées depuis les applications installées de Windows.","Désinstaller Office",MessageBoxButton.OK,MessageBoxImage.Information);return;}
  string list=string.Join("\n",targets.Select(id=>"• "+OfficeProductName(id)).ToArray());
  string message="Les produits suivants seront désinstallés :\n\n"+list+"\n\nFermez Word, Excel, Outlook et les autres applications Office après avoir enregistré vos documents. Aucun programme ouvert ne sera fermé automatiquement.\n\nOneNote autonome, Visio et Project ne sont pas ciblés. Cette action ne supprime pas vos documents personnels et ne résilie pas votre abonnement. Une licence sera nécessaire pour réinstaller Office.\n\nConfirmer la désinstallation de cette sélection ?";
  if(MessageBox.Show(Window,message,"Confirmer la désinstallation Office",MessageBoxButton.YesNo,MessageBoxImage.Warning,MessageBoxResult.No)!=MessageBoxResult.Yes)return;
  var job=new Job{Ids=new[]{"Microsoft.Office"},Office=products[edition.SelectedIndex],Action="RemoveOffice",OfficeProducts=targets,RemovalConfirmed=true,Simulate=false};
  StartJob(job,new[]{apps.First(a=>a.Id=="Microsoft.Office")},false);
 }
 void StartJob(Job job,AppItem[] selected,bool demo){
  try{
   removingOffice=job.Action=="RemoveOffice";
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
  if(simulating&&args.Contains("--test-run")){
   string output=ArgumentValue("--test-run");if(output!=null){Directory.CreateDirectory(output);File.WriteAllText(Path.Combine(output,"simulation-result.json"),Entry.Json.Serialize(state));File.WriteAllText(Path.Combine(output,"report.txt"),reportText);Capture(Path.Combine(output,"simulation.png"));}
   ExitCode=state!=null&&state.done&&state.completed==9?0:1;Window.Close();
  }
 }
 void ShowReport(bool show){Find<Grid>("ReportPanel").Visibility=show?Visibility.Visible:Visibility.Collapsed;Find<Grid>("CatalogPanel").Visibility=show?Visibility.Collapsed:Visibility.Visible;}
 void BuildReport(State state){
  var results=state==null||state.outcomes==null?new List<Outcome>():state.outcomes;
  reportRows=new List<ReportRow>();
  foreach(var app in queuedApps??new AppItem[0]){
   var result=results.FirstOrDefault(x=>x.id==app.Id);
   string status=result==null?"Non traitée":result.status;
   string detail=result==null?(state!=null&&state.stopped?"File arrêtée avant cette application.":state!=null&&state.fatal?state.message:"Le moteur n’a pas fourni de résultat pour cette application."):result.detail;
   reportRows.Add(new ReportRow{Title=removingOffice&&app.Id=="Microsoft.Office"?"Microsoft Office — désinstallation":app.Title,Status=status,Detail=detail,Code=result==null?"":("Code "+result.code+" · 0x"+unchecked((uint)result.code).ToString("X8")),Color=result==null?"#7C8BA3":status=="Échec"?"#C13C4B":result.code==3010?"#9A6A15":"#237E63"});
  }
  int failed=results.Count(x=>x.status=="Échec"),installed=results.Count(x=>x.code==0||x.code==3010),kept=results.Count-failed-installed,missing=reportRows.Count-results.Count;
  Find<TextBlock>("ReportTitle").Text=simulating?"Bilan de démonstration":state==null||!state.done||state.fatal||(!state.stopped&&state.completed<state.total)?"Parcours interrompu":state.stopped?"Bilan après arrêt":failed>0?(removingOffice?"Désinstallation terminée avec des erreurs":"Installation terminée avec des erreurs"):removingOffice?"Désinstallation Office terminée":"Votre sélection est prête.";
  Find<TextBlock>("ReportSummary").Text=installed+" réussie(s) · "+kept+" conservée(s) · "+failed+" échec(s) · "+Math.Max(0,missing)+" non traitée(s)";
  DateTime ended=reportEndedAt??DateTime.Now;
  Find<TextBlock>("ReportContext").Text=(simulating?"Simulation : aucune application installée. · ":"")+ended.ToString("dd/MM/yyyy HH:mm")+" · Durée : "+(ended-startTime).ToString(@"hh\:mm\:ss")+(state!=null&&state.reboot?" · Redémarrage requis, non lancé.":"");
  Find<TextBlock>("ReportIssue").Text=state!=null&&state.fatal?state.message:state==null||!state.done?"Résultats partiels : le moteur s’est arrêté sans bilan complet.":"";
  Find<ItemsControl>("ReportRows").ItemsSource=reportRows;
  var text=new StringBuilder();text.AppendLine("APPDESK — "+Find<TextBlock>("ReportTitle").Text);text.AppendLine(Find<TextBlock>("ReportContext").Text);text.AppendLine(Find<TextBlock>("ReportSummary").Text);text.AppendLine(Find<TextBlock>("ReportIssue").Text);
  foreach(var row in reportRows){text.AppendLine();text.AppendLine(row.Title+" : "+row.Status);text.AppendLine(row.Detail);text.AppendLine(row.Code);}
  string sources=Path.Combine(runPath,"sources.jsonl");if(File.Exists(sources)){text.AppendLine();text.AppendLine("Provenance des téléchargements vérifiés :");text.AppendLine(File.ReadAllText(sources));}
  text.AppendLine();text.AppendLine("Journaux : "+runPath);reportText=text.ToString();
  try{File.WriteAllText(Path.Combine(runPath,"rapport.txt"),reportText,new UTF8Encoding(true));}catch(IOException){}catch(UnauthorizedAccessException){}
 }
 string ArgumentValue(string key){int n=Array.IndexOf(args,key);return n>=0&&n+1<args.Length?args[n+1]:null;}
 void OnLoaded(){
  string session=ArgumentValue("--report-session");
  if(session!=null){
   runPath=Path.GetFullPath(session);var job=Entry.Json.Deserialize<Job>(File.ReadAllText(Path.Combine(runPath,"job.json")));removingOffice=job.Action=="RemoveOffice";
   queuedApps=apps.Where(a=>job.Ids.Contains(a.Id)).ToArray();startTime=Directory.GetCreationTime(runPath);reportEndedAt=File.GetLastWriteTime(Path.Combine(runPath,"state.json"));simulating=job.Simulate;
   var state=Entry.Json.Deserialize<State>(File.ReadAllText(Path.Combine(runPath,"state.json")));BuildReport(state);ShowReport(true);Find<Button>("ShowReport").Visibility=Visibility.Visible;
  }
  string preview=ArgumentValue("--preview");
  if(preview!=null){
   if(args.Contains("--busy")){apps[0].Selected=true;apps[3].Selected=true;apps[8].Selected=true;apps[0].Status="Installée";apps[3].Status="Téléchargement";apps[8].Status="Dans la file";title.Text="Acrobat Reader";completed.Text="1 / 3 terminée(s)";overall.Value=100.0/3;activity.Text="Téléchargement du programme d’installation · 62 %";activityBar.Visibility=Visibility.Visible;activityBar.Value=62;}
   Window.Dispatcher.BeginInvoke(new Action(()=>{Capture(preview);Window.Close();}),DispatcherPriority.ApplicationIdle);
  }
  if(args.Contains("--test-run")){foreach(var app in apps)app.Selected=true;consent.IsChecked=true;Start(true);}
 }
 void Capture(string path){
  Window.UpdateLayout();
  var bitmap=new RenderTargetBitmap((int)Window.ActualWidth,(int)Window.ActualHeight,96,96,PixelFormats.Pbgra32);bitmap.Render(Window);
  var png=new PngBitmapEncoder();png.Frames.Add(BitmapFrame.Create(bitmap));using(var stream=File.Create(path))png.Save(stream);
 }
}
