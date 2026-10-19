extends SceneTree
const UPDATER=preload("res://release_updater.gd")
func _initialize():call_deferred("run")
func release(version:String,preview=false)->Dictionary:
 var name="FarFromHome-v"+version+"-Windows-x64.zip"
 return {"draft":false,"prerelease":preview,"tag_name":"v"+version,"assets":[{"name":name,"state":"uploaded","browser_download_url":UPDATER.REPOSITORY+"/releases/download/v"+version+"/"+name,"size":1024,"digest":"sha256:"+"a".repeat(64)}]}
func run():
 assert(UPDATER.newer("v1.10.0","1.9.0") and not UPDATER.newer("1.1.0","v1.1"))
 assert(not UPDATER.newer("2.0.0-rc.1","1.1.0") and UPDATER.version_parts("bad").is_empty())
 var first=release("1.2.0",true);var newer=release("1.10.0",true)
 assert(UPDATER.select_release([newer,first],"1.1.0").version=="1.10.0","Choose by version rather than publication order; published previews count")
 var draft=release("99.0.0");draft.draft=true
 assert(UPDATER.select_release([draft,first],"1.1.0").version=="1.2.0")
 for key in ["digest","browser_download_url","state","size"]:
  var bad=release("1.2.0");bad.assets[0][key]={"digest":"sha256:bad","browser_download_url":"https://example.com/game.zip","state":"new","size":0}[key]
  assert(UPDATER.select_release([bad],"1.1.0").is_empty(),"Reject unverified, wrong-host and incomplete assets")
 assert(UPDATER.select_release([first],"2.0.0").is_empty(),"Never downgrade")
 var g=load("res://main.tscn").instantiate();root.add_child(g);g.set_physics_process(false);g.enemies.set_physics_process(false)
 g.set_state("title");var u=g.updater
 u.current_version="1.1.0"
 assert(not u.can_install(),"Editor cannot overwrite source project")
 u.phase="checking";u.completed(HTTPRequest.RESULT_SUCCESS,200,[],JSON.stringify([first]).to_utf8_buffer())
 assert(u.phase=="available" and u.primary.disabled and "source project" in u.status.text)
 u.phase="checking";u.completed(HTTPRequest.RESULT_SUCCESS,200,[],"bad json".to_utf8_buffer());assert(u.phase=="error")
 u.phase="checking";u.completed(HTTPRequest.RESULT_SUCCESS,403,[],[]);assert(u.phase=="error" and "limit" in u.status.text)
 u.phase="checking";u.completed(HTTPRequest.RESULT_SUCCESS,200,[],"[]".to_utf8_buffer());assert(u.phase=="current")
 u.download_path="user://updater-unit-test.part"
 var file=FileAccess.open(u.download_path,FileAccess.WRITE);file.store_string("payload");file.close()
 u.candidate={"size":7,"sha256":"payload".sha256_text()};assert(u.verify_download())
 u.candidate.sha256="0".repeat(64);assert(not u.verify_download())
 DirAccess.remove_absolute(ProjectSettings.globalize_path(u.download_path))
 u.phase="checking";u.panel.show();u.close();assert(u.phase=="idle" and not u.opened())
 # Use the real public endpoint once, including its normal asynchronous callback.
 u.check_releases();await u.request.request_completed
 assert(u.phase in ["current","available"],"Actual GitHub release request succeeds: "+u.status.text)
 u.panel.show();g.hud._process(0)
 for button in g.hud.menu_buttons:assert(not button.visible,"Modal update UI hides title buttons")
 g.controller.activate(0);u.back.grab_focus();g.controller.button(JOY_BUTTON_A);assert(not u.opened(),"Controller can close updater")
 print("PASS: semantic release ordering, preview channel, drafts, no downgrades, checksum/host guards, errors, source protection, file verification, cancel, modal controller menus and live GitHub check")
 g.queue_free();await process_frame;quit()
