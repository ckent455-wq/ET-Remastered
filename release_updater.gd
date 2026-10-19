extends Node
## Public release checks and verified, backed-up Windows portable updates.
const REPOSITORY="https://github.com/ckent455-wq/ET-Remastered"
const API="https://api.github.com/repos/ckent455-wq/ET-Remastered/releases?per_page=100"
const HEADERS=["User-Agent: FarFromHome-Updater","Accept: application/vnd.github+json","X-GitHub-Api-Version: 2022-11-28"]
var game
var phase="idle"
var candidate={}
var request:HTTPRequest
var panel:Panel
var status:Label
var progress:ProgressBar
var primary:Button
var back:Button
var current_version=""
var previous_result_shown=false
var cache_directory="user://updates"
var download_path="user://updates/release.zip.part"
func _ready():
 name="ReleaseUpdater"
 current_version=str(ProjectSettings.get_setting("application/config/version","0.0.0"))
 request=HTTPRequest.new();request.use_threads=true;request.timeout=20;request.body_size_limit=2097152
 add_child(request);request.request_completed.connect(completed)
 panel=Panel.new();panel.position=Vector2(62,64);panel.size=Vector2(516,300);panel.z_index=100
 panel.mouse_filter=Control.MOUSE_FILTER_STOP
 var style=StyleBoxFlat.new();style.bg_color=Color("111b1c");style.border_color=Color("817461");style.set_border_width_all(1);panel.add_theme_stylebox_override("panel",style)
 game.hud.add_child(panel);panel.hide()
 var title=Label.new();title.text="BLACKWOOD / GAME UPDATES";title.position=Vector2(18,16);title.add_theme_font_size_override("font_size",21);panel.add_child(title)
 status=Label.new();status.position=Vector2(18,58);status.size=Vector2(480,142);status.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;status.add_theme_font_size_override("font_size",14);panel.add_child(status)
 progress=ProgressBar.new();progress.position=Vector2(18,205);progress.size=Vector2(480,12);progress.show_percentage=false;panel.add_child(progress)
 primary=make_button("CHECK GITHUB",Vector2(18,242),Vector2(290,36),activate)
 back=make_button("BACK",Vector2(322,242),Vector2(176,36),close)
 for control in [title,status,primary,back]:control.add_theme_font_override("font",preload("res://assets/font.ttf"))
 refresh("Check for newer Windows builds, including published previews.\nInstalled version: "+current_version)
func make_button(caption:String,position:Vector2,size:Vector2,action:Callable)->Button:
 var button=Button.new();button.text=caption;button.position=position;button.size=size;button.add_theme_font_size_override("font_size",15);button.pressed.connect(action);panel.add_child(button);return button
func opened()->bool:return panel.visible
func buttons()->Array:return [primary,back].filter(func(button):return button.visible and not button.disabled)
func open():
 panel.show();primary.grab_focus()
 if not previous_result_shown:
  previous_result_shown=true
  var log_path="user://updates/result.json"
  if FileAccess.file_exists(log_path):
   var result=JSON.parse_string(FileAccess.get_file_as_string(log_path).trim_prefix("\ufeff"))
   if result is Dictionary and not result.get("ok",true):
    phase="error";refresh(str(result.get("message","The last update could not finish."))+"\nChoose Check Again to retry.");return
 if phase in ["idle","error","current"]:check_releases()
func close():
 if phase in ["checking","downloading"]:
  request.cancel_request();phase="idle";candidate.clear()
 panel.hide()
 if game.state=="title":game.hud.menu_buttons[4].grab_focus()
func _input(event):
 if opened() and event is InputEventKey and event.pressed and not event.echo and event.keycode==KEY_ESCAPE:
  close();get_viewport().set_input_as_handled()
func _process(_delta):
 if opened() and game.state!="title":close()
 if phase=="downloading":
  progress.value=100.0*request.get_downloaded_bytes()/maxf(1,float(candidate.get("size",1)))
func refresh(message:String):
 status.text=message
 progress.visible=phase=="downloading"
 primary.disabled=phase in ["checking","downloading","installing"]
 primary.text={"available":"DOWNLOAD UPDATE","ready":"INSTALL & RESTART","checking":"CHECKING...","downloading":"DOWNLOADING...","installing":"RESTARTING..."}.get(phase,"CHECK AGAIN")
 back.text="CANCEL" if phase in ["checking","downloading"] else "BACK"
 if opened():
  if primary.disabled:back.grab_focus()
  else:primary.grab_focus()
func fail(message:String):
 phase="error";refresh(message+"\nYour current game files have not been changed.")
func activate():
 if game.state!="title":return
 if phase=="available":download()
 elif phase=="ready":install()
 elif phase in ["idle","current","error"]:check_releases()
func check_releases():
 if phase in ["checking","downloading","installing"]:return
 candidate.clear();phase="checking";refresh("Checking GitHub releases...\nInstalled version: "+current_version)
 request.download_file="";request.timeout=20;request.body_size_limit=2097152
 var error=request.request(API,HEADERS)
 if error!=OK:fail("Could not start the update check. Please try again.")
static func version_parts(value:String)->Array:
 var regex=RegEx.new();regex.compile("^v?([0-9]{1,6})\\.([0-9]{1,6})(?:\\.([0-9]{1,6}))?$")
 var found=regex.search(value)
 if not found:return []
 return [int(found.get_string(1)),int(found.get_string(2)),int(found.get_string(3))]
static func newer(left:String,right:String)->bool:
 var a=version_parts(left);var b=version_parts(right)
 if a.is_empty() or b.is_empty():return false
 for i in range(3):
  if a[i]!=b[i]:return a[i]>b[i]
 return false
static func select_release(releases:Array,installed:String)->Dictionary:
 var selected={}
 var digest_pattern=RegEx.new();digest_pattern.compile("^sha256:[a-fA-F0-9]{64}$")
 for release in releases:
  if not release is Dictionary or release.get("draft",true):continue
  var tag=str(release.get("tag_name",""));var parts=version_parts(tag)
  if parts.is_empty() or not newer(tag,installed):continue
  if not selected.is_empty() and not newer(tag,selected.version):continue
  var version="%d.%d.%d" % parts
  var name="FarFromHome-v"+version+"-Windows-x64.zip"
  var assets=release.get("assets",[])
  if not assets is Array:continue
  for asset in assets:
   if not asset is Dictionary or asset.get("name","")!=name or asset.get("state","")!="uploaded":continue
   var url=str(asset.get("browser_download_url",""));var digest=str(asset.get("digest",""));var bytes=int(asset.get("size",0))
   if not url.begins_with(REPOSITORY+"/releases/download/"+tag+"/") or url.get_file()!=name:continue
   if not digest_pattern.search(digest) or bytes<=0 or bytes>1073741824:continue
   selected={"version":version,"url":url,"sha256":digest.substr(7).to_lower(),"size":bytes,"preview":bool(release.get("prerelease",false))}
 return selected
func completed(result:int,code:int,_headers:PackedStringArray,body:PackedByteArray):
 if phase not in ["checking","downloading"]:return
 if result!=HTTPRequest.RESULT_SUCCESS or code!=200:
  fail("GitHub is temporarily unavailable or the download was interrupted. Try again later." if code!=403 else "GitHub's update-check limit has been reached. Try again later.");return
 if phase=="checking":
  var releases=JSON.parse_string(body.get_string_from_utf8())
  if not releases is Array:fail("GitHub returned an unreadable release list.");return
  candidate=select_release(releases,current_version)
  if candidate.is_empty():
   phase="current";refresh("You're up to date (v"+current_version+").\nNo newer verified Windows release is available.")
  else:
   phase="available";refresh("Version "+candidate.version+(" (preview)" if candidate.preview else "")+" is available.\nDownload: %.1f MB.\nThe download is verified before installation. Installing closes and restarts the game; the previous build is backed up." % (candidate.size/1048576.0))
   if not can_install():refresh(status.text+"\nYou're running the source project. Install updates from an exported Windows build.");primary.disabled=true;back.grab_focus()
 else:
  if not verify_download():fail("Download verification failed. Please download the update again.");return
  phase="ready";refresh("Version "+candidate.version+" downloaded and verified.\nInstall & Restart closes this game, backs up the current installation and applies the update. Your achievements are kept.")
func can_install()->bool:
 var executable=OS.get_executable_path()
 return OS.get_name()=="Windows" and not OS.has_feature("editor") and executable.get_file().to_lower()=="farfromhome.exe" and FileAccess.file_exists(executable.get_base_dir().path_join("FarFromHome.pck"))
func download():
 if not can_install():fail("Updates install from exported Windows builds. Your Godot source project stays unchanged.");return
 if candidate.is_empty():return
 if DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(cache_directory))!=OK:fail("The update download folder is not writable.");return
 phase="downloading";progress.value=0;refresh("Downloading version "+candidate.version+"...\nYou can cancel and keep playing the current version.")
 request.download_file=download_path;request.timeout=300;request.body_size_limit=candidate.size+1024
 var error=request.request(candidate.url,["User-Agent: FarFromHome-Updater"])
 if error!=OK:fail("Could not start the download.")
func verify_download()->bool:
 if candidate.is_empty() or not FileAccess.file_exists(download_path):return false
 var file=FileAccess.open(download_path,FileAccess.READ)
 if not file:return false
 var length=file.get_length();file.close()
 return length==int(candidate.size) and FileAccess.get_sha256(download_path)==candidate.sha256
func install():
 if phase!="ready" or not can_install() or not verify_download():fail("The verified Windows update is not ready to install.");return
 var directory=OS.get_executable_path().get_base_dir()
 var probe_path=directory.path_join(".ffh-update-write-test-"+str(Time.get_ticks_usec()))
 var probe=FileAccess.open(probe_path,FileAccess.WRITE)
 if not probe:fail("This game folder is read-only. Move the complete game folder to a writable location, then retry.");return
 probe.close();DirAccess.remove_absolute(probe_path)
 var base=ProjectSettings.globalize_path(cache_directory)
 var helper=base.path_join("install-update.ps1");var plan=base.path_join("plan.json")
 var source=FileAccess.open("res://windows_update.ps1",FileAccess.READ)
 var output=FileAccess.open(helper,FileAccess.WRITE)
 if not source or not output:fail("The update installer could not be prepared.");return
 output.store_string(source.get_as_text());output.close();source.close()
 var job=FileAccess.open(plan,FileAccess.WRITE)
 if not job:fail("The update plan could not be written.");return
 job.store_string(JSON.stringify({"archive":ProjectSettings.globalize_path(download_path),"target":directory,"version":candidate.version,"sha256":candidate.sha256,"size":candidate.size,"pid":OS.get_process_id()}));job.close()
 var pid=OS.create_process("powershell.exe",["-NoProfile","-NonInteractive","-ExecutionPolicy","Bypass","-WindowStyle","Hidden","-File",helper,"-Plan",plan])
 if pid<=0:fail("Windows could not start the update installer.");return
 phase="installing";refresh("Closing the game to install version "+candidate.version+"...")
 get_tree().quit()
