extends Node
signal code_scanned(code: String)
signal failed(message: String)
signal qr_ready(payload: String, texture: Texture2D)
const RoomQr = preload("res://scripts/room_qr.gd")
var native: Object
var scan_pending := false

func _ready() -> void:
	if Engine.has_singleton("KampungHuaweiScan"):
		native = Engine.get_singleton("KampungHuaweiScan")
		native.connect("scan_result",_on_result)
		native.connect("scan_error",_on_error)
		native.connect("qr_image",_on_image)

func start_scan() -> void:
	if scan_pending: return
	if OS.get_name()!="Android" or native==null:
		failed.emit("Scan QR is available in the Android APK. On this device, type the room code instead.")
		return
	scan_pending = true
	native.call("scanRoom")

func cancel_scan() -> void:
	scan_pending = false
	if native!=null: native.call("cancelScan")

func request_image(code: String) -> void:
	var value := RoomQr.payload(code)
	if native!=null and not value.is_empty(): native.call("generateRoomQr",value)

func _on_result(value: String) -> void:
	if not scan_pending: return
	scan_pending = false
	var code := RoomQr.parse(value)
	if code.is_empty(): failed.emit("This is not a Nenek Kebayan room QR. Scan the QR displayed by the host.")
	else: code_scanned.emit(code)

func _on_error(message: String) -> void:
	scan_pending = false
	failed.emit(message)

func _on_image(value: String, png: String) -> void:
	if RoomQr.parse(value).is_empty() or png.length()>2000000: return
	var image := Image.new()
	if image.load_png_from_buffer(Marshalls.base64_to_raw(png))==OK:
		qr_ready.emit(value,ImageTexture.create_from_image(image))
