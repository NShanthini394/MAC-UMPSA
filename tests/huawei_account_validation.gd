extends SceneTree
const Auth = preload("res://scripts/firebase_auth.gd")
var checks := 0
var failures := 0
class NativeMock extends RefCounted:
	var cancelled := 0
	var signed_out := 0
	func cancelSignIn() -> void: cancelled += 1
	func signOut() -> void: signed_out += 1

func _initialize() -> void: run.call_deferred()
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(message)

func run() -> void:
	var config := "res://tmp/huawei-account-test-config.json"
	var file := FileAccess.open(config,FileAccess.WRITE)
	file.store_string(JSON.stringify({"client":{"app_id":"123456789","package_name":Auth.PACKAGE}})); file.close()
	check(Auth.valid_huawei_configuration(config),"Matching Huawei app configuration is accepted")
	file = FileAccess.open(config,FileAccess.WRITE)
	file.store_string(JSON.stringify({"client":{"app_id":"123456789","package_name":"other.app"}})); file.close()
	check(not Auth.valid_huawei_configuration(config),"A different Android app configuration is rejected")
	file = FileAccess.open(config,FileAccess.WRITE)
	file.store_string("{}"); file.close()
	check(not Auth.valid_huawei_configuration(config),"Incomplete configuration is rejected")
	DirAccess.remove_absolute(config)
	check(not Auth.valid_huawei_configuration(config),"Missing configuration is rejected")
	var app: Control = load("res://scenes/main.tscn").instantiate()
	root.add_child(app)
	await process_frame; await process_frame
	var auth: Node = app.firebase_auth
	var native := NativeMock.new()
	auth._huawei = native
	var button := app.find_child("LoginHuaweiButton",true,false) as Button
	check(button!=null,"Huawei login button exists")
	button.pressed.emit()
	check(not auth.busy and auth.user.is_empty(),"Unsupported desktop login does not fake a signed-in account")
	var notice := app.find_child("LoginNoticeLabel",true,false) as Label
	check(notice!=null and notice.text.contains("Android"),"Huawei button provides the Android-only explanation")
	auth._on_huawei_account("ignored","Ignored")
	check(auth.user.is_empty(),"Unsolicited callback cannot sign in")
	auth.busy=true; auth._huawei_pending=true
	auth._on_huawei_account("","Player")
	check(not auth.busy and auth.user.is_empty(),"Incomplete SDK result does not sign in")
	auth.busy=true; auth._huawei_pending=true
	auth.cancel()
	auth._on_huawei_account("late","Late")
	check(auth.user.is_empty() and not auth.busy,"Cancellation discards a late SDK callback")
	check(native.cancelled>0,"Cancellation reaches the native bridge")
	auth.busy=true; auth._huawei_pending=true
	auth._on_huawei_account("test-app-openid","Huawei Player")
	await process_frame; await process_frame
	check(auth.user.get("provider")=="huawei","Provider is explicitly marked as Huawei")
	check(auth.user.get("uid")=="huawei:test-app-openid","Huawei identity is namespaced separately from Firebase")
	check(not auth.user.has("id_token"),"Huawei SDK result is not treated as a Firebase token")
	check(app.current_screen=="menu","Successful SDK callback enters the game menu")
	check(app.lobby_player_name=="Huawei Player","Huawei display name populates the lobby name")
	check(app.find_child("SignedInAccountLabel",true,false).text.contains("Huawei Player"),"Signed-in name is visible without an edit-profile page")
	app._sign_out()
	await process_frame; await process_frame
	check(auth.user.is_empty() and app.current_screen=="login","Sign-out clears the local identity")
	check(native.signed_out==1,"Sign-out reaches the Huawei SDK bridge")
	app.queue_free(); await process_frame
	print("HUAWEI ACCOUNT CHECKS: %d checks; %d failures"%[checks,failures])
	quit(1 if failures else 0)
