extends SceneTree
func _initialize() -> void:
 var constants := ClassDB.class_get_integer_constant_list("RenderingServer")
 print("Splash cover supported: ", "SPLASH_STRETCH_MODE_COVER" in constants)
 if "SPLASH_STRETCH_MODE_COVER" in constants:
  print("Cover value: ", ClassDB.class_get_integer_constant("RenderingServer", "SPLASH_STRETCH_MODE_COVER"))
 print("Configured mode: ", ProjectSettings.get_setting("application/boot_splash/stretch_mode"))
 quit()
