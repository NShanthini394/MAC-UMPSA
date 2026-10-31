extends SceneTree
var app: Control
var checks := 0
var failures := 0
func _initialize() -> void: run.call_deferred()
func check(ok: bool, message: String) -> void:
 checks += 1
 if not ok: failures += 1; push_error(message)
func settle() -> void:
 await process_frame; await process_frame; await process_frame
func run() -> void:
 app = load("res://scenes/main.tscn").instantiate(); root.add_child(app); await settle()
 app.online_server_url = ""
 var store = load("res://scripts/settings_store.gd")
 var saved: Dictionary = store.values.duplicate()
 for dimensions in [Vector2i(1280,720), Vector2i(2340,1080), Vector2i(1920,1200)]:
  root.size = dimensions; await settle(); await app.build_menu(); await settle()
  var buttons: Array = []
  for name_ in ["StartGameButton", "MainHelpButton", "MainExitButton"]: buttons.append(app.find_child(name_, true, false))
  check(buttons[0].size == buttons[1].size and buttons[1].size == buttons[2].size, "Equal menu button sizes")
  check(is_equal_approx(buttons[1].position.y-buttons[0].position.y, buttons[2].position.y-buttons[1].position.y), "Equal menu gaps")
  if dimensions == Vector2i(1280,720) and DisplayServer.get_name() != "headless":
   await RenderingServer.frame_post_draw
   root.get_texture().get_image().save_png("res://.godot/page-previews/main_settings14.png")
  app.page_controls.show_settings(); await settle()
  var page: Control = app.find_child("SettingsPage",true,false)
  check(page != null and page.size == Vector2(1280,720), "Settings is a full page")
  check(app.current_screen == "menu", "Settings preserves underlying screen")
  for section in ["", "ACCOUNT", "AUDIO", "CONTROLS & DISPLAY", "LANGUAGE", "HOW TO PLAY", "REPORT A PROBLEM", "DATA & PRIVACY", "ABOUT THE GAME"]:
   page.show_section(section); await settle()
   for label in page.find_children("*", "Label", true, false):
    if label.text.is_empty(): continue
    check(label.get_line_count()*label.get_line_height() <= label.size.y+2, "Settings text fits: "+section+" / "+label.text.left(30))
   check(page.find_child("SettingsPageClose",true,false).get_global_rect().end.x <= app.get_viewport_rect().end.x, "Close remains visible")
   if dimensions == Vector2i(1280,720) and section in ["", "ACCOUNT", "LANGUAGE", "AUDIO", "CONTROLS & DISPLAY"] and DisplayServer.get_name() != "headless":
    await RenderingServer.frame_post_draw
    root.get_texture().get_image().save_png("res://.godot/page-previews/settings_"+("overview" if section.is_empty() else section.to_lower().replace(" & ","_"))+".png")
  page.show_section("ACCOUNT"); await settle()
  check(page.find_child("AccountGuestID",true,false)==null,"Guest ID action is removed")
  for label in page.find_children("*","Label",true,false):
   check(not label.text.contains("GUEST-"),"Guest account page hides internal identity")
  check(page.color==load("res://scripts/game_data.gd").SECTION_PANEL,"Settings uses shared dark brown")
  page.show_section("LANGUAGE"); await settle()
  check(store.DEFAULTS.language=="en","English is the default language")
  page.find_child("LanguageMalay",true,false).pressed.emit(); await settle()
  check(store.get_value("language")=="ms","Malay choice saves its preference")
  var language_config:=ConfigFile.new()
  check(language_config.load("user://preferences.cfg")==OK and language_config.get_value("settings","language")=="ms","Malay preference persists")
  check(app.huawei_translation.app_language.selected==1,"Malay is connected to the language service")
  page.find_child("LanguageEnglish",true,false).pressed.emit(); await settle()
  check(store.get_value("language")=="en","Can switch back to English")
  page.show_section("AUDIO"); await settle()
  page.find_child("Preference_music",true,false).value=37
  check(is_equal_approx(db_to_linear(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Music"))),0.37), "Music volume applies independently")
  check(float(store.get_value("music")) == 37, "Music preference saved")
  var config:=ConfigFile.new()
  check(config.load("user://preferences.cfg")==OK and float(config.get_value("settings","music",0))==37,"Preferences persist to disk")
  app.navigate_back(); await settle()
  check(app.find_child("SettingsPage",true,false)==null and app.current_screen=="menu", "Back closes settings without rebuilding menu")
 app.firebase_auth.user={"display_name":"A Long Player Name", "email":"player@example.test", "uid":"test-account"}
 app.page_controls.show_settings(); await settle()
 app.find_child("SettingsPage",true,false).show_section("ACCOUNT"); await settle()
 check(app.find_child("AccountLogout",true,false)!=null,"Signed-in account action available")
 app.page_controls.close_dialog(); app.firebase_auth.user={}
 store.values=saved
 for key in saved: store.set_value(key,saved[key])
 store.apply(app)
 root.size=Vector2i(1280,720);await settle()
 app.selected_character="Badang";app.player_is_impostor=false
 app.completed_tasks.clear();app.task_progress.clear()
 for i in 12: app.completed_tasks.append(0);app.task_progress.append(0)
 await app.build_game();await settle()
 app.page_controls.show_settings();await settle()
 check(app.current_screen=="game" and is_instance_valid(app.game_world),"Settings keeps active game and connection alive")
 app.navigate_back();await settle()
 check(app.current_screen=="game" and not app._utility_dialog_open(),"Close resumes same game")
 app.lobby_players=[]
 var data=load("res://scripts/game_data.gd")
 for i in 10:app.lobby_players.append({"id":i+2,"name":"Player With Long Name" if i==0 else ["Mei Ling","Arun Kumar","Siti","Dahlia","Hakim"][i%5],"character":data.CHARACTERS[i],"alive":true,"sleeping":false})
 app._show_network_discussion();await settle()
 for i in 25:app._on_network_chat_received(2,"Mei Ling","I was checking the rooms. Did you see anyone cast a spell near the kitchen?")
 check(app.find_child("MeetingChatLog",true,false) is RichTextLabel,"Long chats use a scrollable log")
 for kind in ["discussion","voting"]:
  if kind=="voting":app._show_network_voting(app.lobby_players);await settle()
  var panel:Panel=app.find_child("MeetingPanel",true,false)
  for label in panel.find_children("*","Label",true,false):
   if label.text.is_empty() or label.clip_text:continue
   check(label.get_line_count()*label.get_line_height()<=label.size.y+1,"Meeting text fits: "+label.text)
  if DisplayServer.get_name()!="headless":
   await RenderingServer.frame_post_draw
   root.get_texture().get_image().save_png("res://.godot/page-previews/meeting_"+kind+"14.png")
 app.queue_free(); await settle()
 print("SETTINGS PAGE: %d checks; %d failures" % [checks, failures]); quit(1 if failures else 0)
