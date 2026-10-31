extends SceneTree
const Qr = preload("res://scripts/room_qr.gd")
const Scan = preload("res://scripts/huawei_scan.gd")
var checks := 0
var failures := 0
var read_code := ""
var error := ""
func _initialize() -> void: run.call_deferred()
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(message)
func run() -> void:
	DirAccess.make_dir_recursive_absolute("res://tmp/qr-validation")
	for code in ["ABCDE","7KX9Q","ZZZZZ","23456","HMS22"]:
		check(Qr.parse(Qr.payload(code))==code,"Game QR payload round-trips")
		var image := Qr.image_for_code(code)
		check(image!=null and image.get_size()==Vector2i(232,232),"Host QR is generated")
		check(image.get_pixel(0,0)==Color.WHITE,"QR quiet zone is white")
		image.save_png("res://tmp/qr-validation/%s.png"%code)
	for invalid in ["https://example.com","ABCDE","NKR1:ABCD0","NKR1:ABCDEjunk","NKR1:abcde","NKR1:ABC"]:
		check(Qr.parse(invalid).is_empty(),"Non-game or malformed QR cannot be used to join")
	check(Qr.image_for_code("ABCDEextra")==null,"Invalid host code cannot generate an invite")
	var scan := Scan.new()
	root.add_child(scan)
	scan.code_scanned.connect(func(code: String): read_code=code)
	scan.failed.connect(func(message: String): error=message)
	scan._on_result("NKR1:ABCDE")
	check(read_code.is_empty(),"Unsolicited scanner callback is ignored")
	scan.scan_pending=true; scan._on_result("NKR1:ABCDE")
	check(read_code=="ABCDE" and not scan.scan_pending,"Pending scan returns the validated room code")
	read_code=""; scan.scan_pending=true; scan.cancel_scan(); scan._on_result("NKR1:ABCDE")
	check(read_code.is_empty(),"Closing Join Room ignores late results")
	scan.scan_pending=true; scan._on_result("https://example.com")
	check(not error.is_empty() and read_code.is_empty(),"Unrelated QR produces feedback")
	var app: Control = load("res://scenes/main.tscn").instantiate()
	root.add_child(app)
	await process_frame; await process_frame
	await app.build_menu()
	app.show_join_room()
	check(app.find_child("JoinCodeEntry",true,false)!=null,"Manual room entry remains available")
	var button := app.find_child("ScanRoomQrButton",true,false) as Button
	check(button!=null,"Join Room offers Scan QR")
	button.pressed.emit()
	check(not button.disabled,"Unsupported desktop scanner restores the button")
	app.huawei_scan.scan_pending=true; app.huawei_scan._on_result("NKR1:7KX9Q")
	check(app.find_child("JoinCodeEntry",true,false).text=="7KX9Q","Scan fills the existing room code field")
	check(not app.network_manager.connection_pending,"Scanning does not connect until Join is confirmed")
	app._cancel_join_room()
	app.room_code="7KX9Q"; app.internet_mode=true; app.room_is_host=true
	app._show_room_qr()
	check(app.find_child("RoomQrImage",true,false).texture!=null,"Host displays a room QR without Android native services")
	app.navigate_back()
	check(app.find_child("RoomQrOverlay",true,false)==null or app.find_child("RoomQrOverlay",true,false).is_queued_for_deletion(),"Back closes the QR overlay")
	app.queue_free(); scan.queue_free(); await process_frame
	print("ROOM QR CHECKS: %d checks; %d failures"%[checks,failures])
	quit(1 if failures else 0)
