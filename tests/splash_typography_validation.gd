extends SceneTree
const Typography = preload("res://scripts/game_typography.gd")
var checks := 0
var failures := 0

func _initialize() -> void: run.call_deferred()
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(message)

func run() -> void:
	root.content_scale_size = Vector2i(1280,720)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
	var splash: Control = load("res://scenes/splash.tscn").instantiate()
	splash.auto_continue = false
	root.add_child(splash)
	for dimensions in [Vector2i(1280,720), Vector2i(1920,864), Vector2i(1024,768), Vector2i(720,1280)]:
		root.size = dimensions
		await process_frame; await process_frame
		var artwork := splash.get_node("Artwork") as TextureRect
		check(artwork.get_global_rect().position.is_equal_approx(Vector2.ZERO), "Splash starts at the screen edge")
		check(artwork.size.is_equal_approx(root.get_visible_rect().size), "Splash adapts to " + str(dimensions))
		check(artwork.stretch_mode==TextureRect.STRETCH_KEEP_ASPECT_CENTERED, "The complete splash artwork stays visible without distortion")
		var backdrop := splash.get_node("ScenicBackdrop") as TextureRect
		check(backdrop.size.is_equal_approx(artwork.size) and backdrop.stretch_mode==TextureRect.STRETCH_KEEP_ASPECT_COVERED, "Scenery extends to every device edge")
	splash.queue_free(); await process_frame
	check(Typography.HEADING.get_font_name().contains("Cinzel"), "Headings load real Cinzel")
	check(Typography.BODY.get_font_name().contains("Noto Sans"), "Body text loads real Noto Sans")
	check(Typography.BODY.has_char("த".unicode_at(0)), "Bundled font chain covers Tamil")
	check(Typography.BODY.has_char("中".unicode_at(0)), "Bundled font chain covers Chinese")
	check(Typography.HEADING.has_char("த".unicode_at(0)), "Cinzel headings fall back for Tamil")
	check(Typography.HEADING.has_char("中".unicode_at(0)), "Cinzel headings fall back for Chinese")
	root.size = Vector2i(1280,720)
	var app: Control = load("res://scenes/main.tscn").instantiate()
	root.add_child(app)
	await process_frame; await process_frame
	var title: Label = app.GameUI.make_child_label(app,"HOW TO PLAY",28,Color.WHITE,HORIZONTAL_ALIGNMENT_CENTER,Rect2(0,0,600,60))
	check(title.get_theme_font("font")==Typography.HEADING, "Shared headings use Cinzel")
	var copy: Label = app.GameUI.make_child_label(app,"Collect the clues.",18,Color.WHITE,HORIZONTAL_ALIGNMENT_LEFT,Rect2(0,70,600,40))
	check(copy.get_theme_font("font")==Typography.BODY, "Instructions use Noto Sans")
	var button: Button = app.GameUI.make_button(app,"JOIN ROOM",func(): pass,260,50)
	check(button.get_theme_font("font")==Typography.THEME.get_font("font","Button"), "Buttons inherit the bundled interface font")
	check(ThemeDB.fallback_font==Typography.BODY, "Canvas task labels use the bundled font chain")
	check(ProjectSettings.get_setting("application/run/main_scene")=="res://scenes/splash.tscn", "Normal startup opens the responsive splash")
	app.queue_free(); await process_frame
	var boot: Control = load("res://scenes/splash.tscn").instantiate()
	root.add_child(boot)
	current_scene = boot
	var deadline := Time.get_ticks_msec() + 10000
	while is_instance_valid(boot) and Time.get_ticks_msec() < deadline:
		await process_frame
	check(is_instance_valid(current_scene) and current_scene.scene_file_path=="res://scenes/main.tscn", "Splash loads and transitions into the real game")
	if is_instance_valid(current_scene): current_scene.queue_free()
	await process_frame
	print("SPLASH / TYPOGRAPHY CHECKS: %d checks; %d failures" % [checks,failures])
	quit(1 if failures else 0)
