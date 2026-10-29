@tool
extends EditorPlugin

class GoogleExport extends EditorExportPlugin:
	func _supports_platform(platform: EditorExportPlatform) -> bool:
		return platform is EditorExportPlatformAndroid
	func _get_name() -> String:
		return "KampungGoogleSignIn"
	func _get_android_libraries(_platform: EditorExportPlatform, _debug: bool) -> PackedStringArray:
		return PackedStringArray(["res://addons/kampung_google/bin/KampungGoogleSignIn.aar"])
	func _get_android_dependencies(_platform: EditorExportPlatform, _debug: bool) -> PackedStringArray:
		return PackedStringArray(["androidx.credentials:credentials:1.3.0", "androidx.credentials:credentials-play-services-auth:1.3.0", "com.google.android.libraries.identity.googleid:googleid:1.1.1"])

var exporter: GoogleExport
func _enter_tree() -> void:
	exporter = GoogleExport.new()
	add_export_plugin(exporter)
func _exit_tree() -> void:
	remove_export_plugin(exporter)
