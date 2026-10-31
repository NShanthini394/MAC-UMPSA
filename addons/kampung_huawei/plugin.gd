@tool
extends EditorPlugin

class HuaweiExport extends EditorExportPlugin:
	func _supports_platform(platform: EditorExportPlatform) -> bool:
		return platform is EditorExportPlatformAndroid
	func _get_name() -> String: return "KampungHuaweiAccount"
	func _export_file(path: String, _type: String, _features: PackedStringArray) -> void:
		if path == "res://config/agconnect-services.json": skip()
	func _export_begin(features: PackedStringArray, _debug: bool, _path: String, _flags: int) -> void:
		if not "Android" in features and not "android" in features: return
		var path := "res://config/agconnect-services.json"
		if not FileAccess.file_exists(path): return
		var data = JSON.parse_string(FileAccess.get_file_as_string(path))
		if not data is Dictionary or not data.get("client") is Dictionary: return
		var client: Dictionary = data.client
		# Android client API key is public SDK configuration, never client_secret.
		var public_data := {"client":{"app_id":str(client.get("app_id","")),"package_name":str(client.get("package_name","")),"api_key":str(client.get("api_key",""))}}
		add_file("res://config/huawei-public.json",JSON.stringify(public_data).to_utf8_buffer(),false)
	func _get_android_libraries(_platform: EditorExportPlatform, _debug: bool) -> PackedStringArray:
		return PackedStringArray(["res://addons/kampung_huawei/bin/KampungHuaweiAccount.aar"])
	func _get_android_dependencies(_platform: EditorExportPlatform, _debug: bool) -> PackedStringArray:
		return PackedStringArray(["com.huawei.hms:hwid:6.12.0.300", "com.huawei.hms:scanplus:2.12.0.301", "com.huawei.hms:ml-computer-translate:3.11.0.302"])
	func _get_android_dependencies_maven_repos(_platform: EditorExportPlatform, _debug: bool) -> PackedStringArray:
		return PackedStringArray(["https://developer.huawei.com/repo/"])
	func _get_android_manifest_application_element_contents(_platform: EditorExportPlatform, _debug: bool) -> String:
		var path := "res://config/agconnect-services.json"
		if not FileAccess.file_exists(path): return ""
		var data = JSON.parse_string(FileAccess.get_file_as_string(path))
		if not data is Dictionary: return ""
		var client: Dictionary = data.get("client",{})
		if str(client.get("package_name","")) != "org.godotengine.nenekkebayan": return ""
		var app_id := str(client.get("app_id",""))
		if not app_id.is_valid_int() or app_id.to_int()<=0: return ""
		return '<meta-data android:name="com.huawei.hms.client.appid" android:value="appid=%s" />' % app_id

var exporter: HuaweiExport
func _enter_tree() -> void:
	exporter = HuaweiExport.new()
	add_export_plugin(exporter)
func _exit_tree() -> void: remove_export_plugin(exporter)
