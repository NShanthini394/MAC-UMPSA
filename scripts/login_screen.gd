extends RefCounted
## Account landing page using the game's own title artwork.
const UI = preload("res://scripts/game_ui.gd")
const Data = preload("res://scripts/game_data.gd")
const WHITE := Color("fff8e9")
const MUTED := Color("d2bc99")
const BACKGROUND := Color("21170f")
const SURFACE := Color("392719")
const BORDER := Color("ac7d3e")


static func flat_style(fill: Color, border: Color = Color.TRANSPARENT) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(9)
	return style


static func account_button(parent: Control, title: String, callback: Callable, rect: Rect2, light: bool = false, outlined: bool = false) -> Button:
	var button := UI.make_button(parent, title, callback, rect.size.x, rect.size.y)
	button.position = rect.position
	var fill := WHITE if light else Color("7d431e")
	if outlined: fill = Color("2b1d13")
	button.add_theme_stylebox_override("normal", flat_style(fill, BORDER if not light else fill))
	button.add_theme_stylebox_override("hover", flat_style(fill.darkened(0.08) if light else fill.lightened(0.12), Data.GOLD))
	button.add_theme_stylebox_override("pressed", flat_style(fill.darkened(0.15)))
	button.add_theme_color_override("font_color", Color("20242c") if light else WHITE)
	button.add_theme_color_override("font_hover_color", Color("20242c") if light else WHITE)
	button.add_theme_color_override("font_pressed_color", Color("20242c") if light else WHITE)
	button.add_theme_font_size_override("font_size", 16)
	return button


static func provider_mark(button: Button, provider: String) -> void:
	var mark := TextureRect.new()
	mark.name = "ProviderLogo"
	var logo := load("res://assets/ui/providers/google.png" if provider == "Google" else "res://assets/ui/providers/huawei.png") as Texture2D
	# The supplied Huawei image includes transparent space on both sides.
	mark.texture = logo if provider == "Google" else UI.make_map_texture(logo, Rect2(100, 0, 300, 281))
	mark.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	mark.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	mark.position = Vector2(14, 6); mark.size = Vector2(32, 32)
	mark.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(mark)


static func build(app: Control) -> void:
	UI.add_color_overlay(app, BACKGROUND)
	var hero := UI.make_panel(app, Rect2(240, 14, 800, 250), SURFACE)
	hero.name = "LoginHero"
	hero.clip_contents = true
	hero.add_theme_stylebox_override("panel", flat_style(SURFACE, BORDER))
	var art := load(Data.MENU_ART) as Texture2D
	var hero_image := TextureRect.new()
	hero_image.name = "LoginTitleArtwork"
	hero_image.texture = UI.make_map_texture(art, Rect2(art.get_width() * 0.11, 0, art.get_width() * 0.72, art.get_height() * 0.33))
	hero_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	hero_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	hero_image.position = Vector2(10, 10); hero_image.size = Vector2(780, 188)
	hero_image.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	hero_image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hero.add_child(hero_image)
	UI.make_child_label(hero, "KAMPUNG LEGENDA", 20, WHITE, HORIZONTAL_ALIGNMENT_CENTER, Rect2(20, 199, 760, 28))
	UI.make_child_label(hero, "Misteri Tiga Rumah", 12, MUTED, HORIZONTAL_ALIGNMENT_CENTER, Rect2(20, 228, 760, 18))
	var form := Control.new()
	form.name = "LoginPanel"
	form.position = Vector2(365, 278); form.size = Vector2(550, 356)
	app.add_child(form)
	UI.make_child_label(form, "Welcome, Player!", 23, WHITE, HORIZONTAL_ALIGNMENT_CENTER, Rect2(0, 0, 550, 34))
	UI.make_child_label(form, "Sign in, create an account, or join as a guest.", 14, MUTED, HORIZONTAL_ALIGNMENT_CENTER, Rect2(0, 36, 550, 28))
	var google := account_button(form, "Continue with Google", Callable(app, "_login_provider_unavailable").bind("Google"), Rect2(0, 72, 550, 44), true)
	google.name = "LoginGoogleButton"; provider_mark(google, "Google")
	var huawei := account_button(form, "Continue with Huawei", Callable(app, "_login_provider_unavailable").bind("Huawei"), Rect2(0, 126, 550, 44), true)
	huawei.name = "LoginHuaweiButton"; provider_mark(huawei, "Huawei")
	var create := account_button(form, "Create Account", Callable(app, "show_create_account"), Rect2(0, 180, 550, 44), false, true)
	create.name = "LoginCreateAccountButton"
	UI.make_child_label(form, "────────────  or  ────────────", 13, MUTED, HORIZONTAL_ALIGNMENT_CENTER, Rect2(0, 229, 550, 25))
	var guest := account_button(form, "▶  Play as Guest", Callable(app, "_continue_as_guest"), Rect2(0, 262, 550, 44))
	guest.name = "LoginGuestButton"
	var notice := UI.make_child_label(form, "", 13, Color("ffd79a"), HORIZONTAL_ALIGNMENT_CENTER, Rect2(0, 312, 550, 42))
	notice.name = "LoginNoticeLabel"
	UI.make_child_label(app, "Google and Huawei sign-in require provider setup. Guest play is available now.", 12, MUTED, HORIZONTAL_ALIGNMENT_CENTER, Rect2(230, 651, 820, 26))


static func show_create_account(app: Control) -> void:
	if app.find_child("CreateAccountOverlay", true, false) != null: return
	var shade := ColorRect.new()
	shade.name = "CreateAccountOverlay"
	shade.color = Color(0, 0, 0, 0.65)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	app.add_child(shade)
	var panel := UI.make_panel(shade, Rect2(390, 190, 500, 340), SURFACE)
	panel.add_theme_stylebox_override("panel", flat_style(SURFACE, BORDER))
	UI.make_child_label(panel, "Create your account", 25, WHITE, HORIZONTAL_ALIGNMENT_CENTER, Rect2(25, 20, 450, 40))
	UI.make_child_label(panel, "Choose Google or Huawei to get started.", 14, MUTED, HORIZONTAL_ALIGNMENT_CENTER, Rect2(25, 66, 450, 30))
	for index in 2:
		var provider: String = ["Google", "Huawei"][index]
		var button := account_button(panel, "Create with " + provider, func(): shade.queue_free(); app.call("_login_provider_unavailable", provider), Rect2(35, 112 + index * 58, 430, 46), true)
		button.name = "Create" + provider + "Button"
		provider_mark(button, provider)
	var close := account_button(panel, "Back", func(): shade.queue_free(), Rect2(160, 264, 180, 42), false, true)
	close.name = "CreateAccountBackButton"
