extends SceneTree
const Profiles=preload("res://scripts/account_profiles.gd")
const Data=preload("res://scripts/game_data.gd")
var app:Control
var checks:=0
var failures:=0
func _initialize()->void:run.call_deferred()
func check(ok:bool,message:String)->void:
 checks+=1
 if not ok:failures+=1;push_error(message)
func settle()->void:
 await process_frame;await process_frame;await process_frame
func capture(name_:String)->void:
 if DisplayServer.get_name()=="headless":return
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://.godot/page-previews/account_"+name_+"15.png")
func run()->void:
 var old_path:=Profiles.path;Profiles.path="user://account-ui-test.cfg"
 app=load("res://scenes/main.tscn").instantiate();root.add_child(app);await settle();await app.build_menu()
 app.page_controls.show_settings();await settle()
 var page:Control=app.find_child("SettingsPage",true,false)
 for dimensions in [Vector2i(1280,720),Vector2i(2340,1080),Vector2i(1920,1200)]:
  root.size=dimensions;await settle()
  for signed_in in [false,true]:
   app.firebase_auth.user={"uid":"ui-only-account","email":"player@example.test","display_name":"Player With Long Name","provider":"password"} if signed_in else {}
   var sections:Array=["ACCOUNT","CHANGE USERNAME","CHANGE AVATAR"]
   sections.append_array(["CHANGE EMAIL","CHANGE PASSWORD","ACCOUNT SECURITY","DELETE ACCOUNT","VERIFY EMAIL"] if signed_in else ["CREATE ACCOUNT"])
   for section in sections:
    page.show_section(section);await settle()
    for label in page.find_children("*","Label",true,false):
     if label.text.is_empty():continue
     check(label.get_line_count()*label.get_line_height()<=label.size.y+2,"Text fits: "+section+" / "+label.text.left(30))
    check(page.find_child("SettingsSavedLabel",true,false).text.is_empty(),"Removed automatic-saving footer")
    if section=="ACCOUNT":
     check(page.find_child("AccountUsername",true,false)!=null and page.find_child("AccountAvatar",true,false)!=null,"Guest and signed-in users can edit profile")
     check(page.find_child("AccountDelete",true,false)!=null if signed_in else page.find_child("AccountConvertGuest",true,false)!=null,"Correct permanent/guest actions")
     for label in page.find_children("*","Label",true,false):
      check(not label.text.contains("To reset an email-account") and not label.text.contains("Player names can be changed") and not label.text.contains("ui-only-account"),"Marked text and raw ID removed")
    if dimensions==Vector2i(1280,720):await capture(("signed_" if signed_in else "guest_")+section.to_lower().replace(" ","_"))
  app.firebase_auth.user={};page.show_section("CHANGE USERNAME");await settle()
  page.find_child("AccountNameInput",true,false).text="Guest Siti"
  page.find_child("AccountSaveName",true,false).pressed.emit();await settle()
  check(Profiles.profile({}).username=="Guest Siti" and app.lobby_player_name=="Guest Siti","Guest username control works")
  page.show_section("CHANGE AVATAR");await settle();page.find_child("ProfileAvatar_2",true,false).pressed.emit();await settle()
  check(Profiles.profile({}).avatar==Data.CHARACTERS[2],"Avatar selection persists")
  app.firebase_auth.user={"uid":"ui-only-account","email":"player@example.test","provider":"password"}
  page.show_section("DELETE ACCOUNT");await settle()
  page.find_child("AccountDeleteConfirmation",true,false).text=""
  page.find_child("AccountSubmit",true,false).pressed.emit()
  check(not app.firebase_auth.busy and page.status.text.contains("Type DELETE"),"Deletion cannot run without typed confirmation")
  page.show_section("CREATE ACCOUNT");await settle()
  page.find_child("AccountNewPassword",true,false).text="ExamplePassword9!";page.find_child("AccountConfirmPassword",true,false).text="Different!"
  page.find_child("AccountSubmit",true,false).pressed.emit()
  check(not app.firebase_auth.busy and page.status.text.contains("do not match"),"Password confirmation blocks requests")
 page.show_section("ACCOUNT");app.room_code="ABCDE";page.show_section("ACCOUNT");await settle()
 check(page.find_child("AccountDelete",true,false).disabled,"Sensitive account changes disabled inside rooms")
 app.room_code="";app.firebase_auth.user={};app.page_controls.close_dialog();app.queue_free();await settle()
 DirAccess.remove_absolute(Profiles.path);Profiles.path=old_path
 print("ACCOUNT SETTINGS UI: %d checks; %d failures"%[checks,failures]);quit(1 if failures else 0)
