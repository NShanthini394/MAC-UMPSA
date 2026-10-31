extends RefCounted
## Account landing page using the game's own title artwork.
const UI = preload("res://scripts/game_ui.gd")
const Data = preload("res://scripts/game_data.gd")
const WHITE := Color("fff8e9")
const MUTED := Color("d2bc99")
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
	UI.apply_menu_button(button, "light" if light else ("wood" if outlined else "red"))
	button.add_theme_font_size_override("font_size", 24)
	return button


static func provider_mark(button: Button, provider: String) -> void:
	var title := button.text
	button.text = ""
	button.accessibility_name = title
	var font := button.get_theme_font("font")
	var title_width := font.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, 24).x
	var group := Control.new()
	group.position = Vector2((button.size.x - title_width - 40) * 0.5, (button.size.y - 34) * 0.5)
	group.size = Vector2(title_width + 40, 34)
	group.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(group)
	var mark := TextureRect.new()
	mark.name = "ProviderLogo"
	var logo := load("res://assets/ui/providers/google.png" if provider == "Google" else "res://assets/ui/providers/huawei.png") as Texture2D
	# The supplied Huawei image includes transparent space on both sides.
	mark.texture = logo if provider == "Google" else UI.make_map_texture(logo, Rect2(100, 0, 300, 281))
	mark.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	mark.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	mark.position = Vector2(0, 3); mark.size = Vector2(28, 28)
	mark.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	group.add_child(mark)
	var label := Label.new()
	label.name = "ProviderTitle"
	# Use the same size as the width measurement. Shared labels normally enlarge
	# their font, which wrapped the provider name below this single-line button.
	label.add_theme_font_size_override("font_size", 24)
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.text = title
	label.position = Vector2(40, 0); label.size = Vector2(title_width + 2, 34)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_color_override("font_color", Color("302015"))
	label.add_theme_color_override("font_shadow_color", Color.TRANSPARENT)
	group.add_child(label)


static func build(app: Control) -> void:
	var background := TextureRect.new()
	background.name = "LoginBackground"
	background.texture = load("res://assets/ui/login_background.png") as Texture2D
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	app.add_child(background)
	var layout := centered_layout(app)
	var hero := UI.make_panel(layout, Rect2(420, 12, 440, 210), SURFACE)
	hero.name = "LoginHero"
	hero.clip_contents = true
	hero.add_theme_stylebox_override("panel", flat_style(SURFACE, BORDER))
	var art := load("res://assets/ui/login_nenek_banner.png") as Texture2D
	var hero_image := TextureRect.new()
	hero_image.name = "LoginTitleArtwork"
	# Frame Nenek's face and shoulders at the centre of the wide banner.
	hero_image.texture = UI.make_map_texture(art, Rect2(650, 0, 1296, 408))
	hero_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	hero_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	hero_image.position = Vector2(4, 4); hero_image.size = Vector2(432, 136)
	hero_image.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	hero_image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hero.add_child(hero_image)
	UI.make_child_label(hero, "Nenek Kebayan", 28, Data.GOLD, HORIZONTAL_ALIGNMENT_CENTER, Rect2(12, 144, 416, 36))
	UI.make_child_label(hero, "Siapa Pengkhianat?", 18, MUTED, HORIZONTAL_ALIGNMENT_CENTER, Rect2(12, 179, 416, 24))
	var form := Control.new()
	form.name = "LoginPanel"
	form.position = Vector2(380, 228); form.size = Vector2(520, 480)
	layout.add_child(form)
	UI.make_child_label(form, "Welcome, Player!", 28, WHITE, HORIZONTAL_ALIGNMENT_CENTER, Rect2(-40, 0, 600, 36))
	UI.make_child_label(form, "Sign in, create an account, or join as a guest.", 21, MUTED, HORIZONTAL_ALIGNMENT_CENTER, Rect2(-40, 38, 600, 28))
	var google := account_button(form, "Continue with Google", Callable(app.firebase_auth, "google_sign_in"), Rect2(0, 74, 520, 60), true)
	google.name = "LoginGoogleButton"; provider_mark(google, "Google")
	var email := account_button(form, "Sign in with Email", Callable(app, "show_email_sign_in"), Rect2(0, 144, 520, 60))
	email.name = "LoginEmailButton"
	var huawei := account_button(form, "Continue with Huawei ID", Callable(app.firebase_auth, "huawei_sign_in"), Rect2(0, 214, 520, 60), true)
	huawei.name = "LoginHuaweiButton"; provider_mark(huawei, "Huawei")
	var create := account_button(form, "Create Account", Callable(app, "show_create_account"), Rect2(0, 284, 520, 60), false, true)
	create.name = "LoginCreateAccountButton"
	var divider := ColorRect.new()
	divider.position = Vector2(12, 354); divider.size = Vector2(496, 1)
	divider.color = Color("745132"); divider.mouse_filter = Control.MOUSE_FILTER_IGNORE
	form.add_child(divider)
	var guest := account_button(form, "▷  Play as Guest", Callable(app, "_continue_as_guest"), Rect2(0, 364, 520, 60), false, true)
	guest.name = "LoginGuestButton"
	var notice := UI.make_child_label(form, "", 20, Color("ffd79a"), HORIZONTAL_ALIGNMENT_CENTER, Rect2(-180, 432, 880, 48))
	notice.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	notice.name = "LoginNoticeLabel"
	var footer := UI.make_child_label(form, "Step into the village. Play your part.", 18, MUTED, HORIZONTAL_ALIGNMENT_CENTER, Rect2(-80, 440, 680, 28))
	footer.name = "LoginFooterLabel"

static func centered_layout(parent: Control) -> Control:
	var layout := Control.new()
	layout.name = "AccountLayout"
	layout.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(layout)
	layout.set_anchors_preset(Control.PRESET_CENTER)
	layout.offset_left = -640; layout.offset_right = 640
	layout.offset_top = -360; layout.offset_bottom = 360
	return layout


static func show_create_account(app: Control) -> void:
	show_email_form(app, "create")

static func show_email_form(app: Control, mode: String) -> void:
	if app.find_child("CreateAccountOverlay", true, false) != null: return
	var shade := ColorRect.new()
	shade.name = "CreateAccountOverlay"
	shade.color = Color(0, 0, 0, 0.65)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	app.add_child(shade)
	var panel_height := 600 if mode == "create" else (540 if mode == "signin" else 420)
	var submit_y := 446 if mode == "create" else (342 if mode == "signin" else 190)
	var notice_y := 370 if mode == "create" else (414 if mode == "signin" else 264)
	var back_y := 524 if mode == "create" else (480 if mode == "signin" else 350)
	var panel := UI.make_panel(centered_layout(shade), Rect2(330, (720 - panel_height) * 0.5, 620, panel_height), SURFACE)
	panel.add_theme_stylebox_override("panel", flat_style(SURFACE, BORDER))
	var heading: String = {"create": "Create your account", "signin": "Sign in with Email", "reset": "Reset your password"}[mode]
	UI.make_child_label(panel, heading, 30, Data.GOLD, HORIZONTAL_ALIGNMENT_CENTER, Rect2(30, 18, 560, 44))
	var fields := [["Email", "AuthEmail", false]]
	if mode != "reset": fields.append(["Password", "AuthPassword", true])
	if mode == "create": fields.append(["Confirm password", "AuthConfirmPassword", true])
	for index in fields.size():
		var entry: Array = fields[index]
		UI.make_child_label(panel, str(entry[0]), 22, WHITE, HORIZONTAL_ALIGNMENT_LEFT, Rect2(40, 80 + index * 96, 540, 28))
		var input := LineEdit.new()
		input.name = str(entry[1])
		input.position = Vector2(40, 112 + index * 96)
		input.size = Vector2(540, 56)
		input.secret = bool(entry[2])
		input.placeholder_text = "At least 6 characters" if mode == "create" and index == 1 else str(entry[0])
		input.virtual_keyboard_type = LineEdit.KEYBOARD_TYPE_PASSWORD if input.secret else LineEdit.KEYBOARD_TYPE_EMAIL_ADDRESS
		input.max_length = 4096 if input.secret else 254
		input.add_theme_font_size_override("font_size", 24)
		panel.add_child(input)
		if index == fields.size() - 1: input.text_submitted.connect(func(_text): app.call("_submit_email_auth", mode))
		if index == 0: input.grab_focus()
	var notice := UI.make_child_label(panel, "", 20, Color("ffd79a"), HORIZONTAL_ALIGNMENT_CENTER, Rect2(35, notice_y, 550, 68 if mode == "create" else 54))
	notice.name = "AuthNoticeLabel"
	notice.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var submit := account_button(panel, "CREATE ACCOUNT" if mode == "create" else ("SEND RESET LINK" if mode == "reset" else "SIGN IN"), Callable(app, "_submit_email_auth").bind(mode), Rect2(40, submit_y, 540, 62))
	submit.name = "AuthSubmitButton"
	if mode == "signin":
		var reset := account_button(panel, "Forgot password?", func(): app.firebase_auth.cancel(); shade.get_parent().remove_child(shade); shade.queue_free(); show_email_form(app, "reset"), Rect2(40, 284, 540, 46), false, true)
		reset.name = "AuthResetButton"
	var close := account_button(panel, "Back", Callable(app, "_close_email_auth"), Rect2(210, back_y, 200, 46 if mode == "signin" else 52), false, true)
	close.name = "CreateAccountBackButton"
