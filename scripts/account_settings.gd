extends RefCounted
const Profiles = preload("res://scripts/account_profiles.gd")
const Data = preload("res://scripts/game_data.gd")
const UI = preload("res://scripts/game_ui.gd")
const ACTIONS = ["CHANGE USERNAME", "CHANGE AVATAR", "CHANGE EMAIL", "CHANGE PASSWORD", "ACCOUNT SECURITY", "DELETE ACCOUNT", "CREATE ACCOUNT"]

static func build(page: Control, action: String = "ACCOUNT") -> void:
	var auth = page.app.firebase_auth
	var huawei: bool = auth.user.get("provider", "") == "huawei"
	var guest: bool = auth.user.is_empty() or auth.user.get("anonymous", false)
	var in_room: bool = not str(page.app.room_code).is_empty()
	if action == "ACCOUNT":
		page.profile()
		page.heading("YOUR PROFILE")
		page.row("Change Username", "profile", page.show_section.bind("CHANGE USERNAME"), "AccountUsername").disabled = in_room
		page.row("Change Avatar", "profile", page.show_section.bind("CHANGE AVATAR"), "AccountAvatar")
		page.heading("ACCOUNT")
		if guest:
			page.row("Link Google Account", "security", auth.link_google, "AccountLinkGoogle").disabled = in_room
			page.row("Convert Guest to Email Account", "security", page.show_section.bind("CREATE ACCOUNT"), "AccountConvertGuest").disabled = in_room
		elif huawei:
			page.paragraph("Signed in with Huawei ID. Your game username and avatar are saved on this device.")
			page.row("Huawei Account Security", "security", page.show_section.bind("ACCOUNT SECURITY"), "AccountSecurity").disabled = in_room
			page.row("Remove Huawei Profile from This Device", "exit", page.show_section.bind("DELETE ACCOUNT"), "AccountDelete").disabled = in_room
			page.row("Log Out", "exit", page.app._open_account_settings, "AccountLogout").disabled = in_room
		else:
			page.paragraph("Linked email: " + str(auth.user.get("email", "")))
			page.row("Account ID — tap to copy", "info", func(): DisplayServer.clipboard_set(str(auth.user.uid)); page.status.text = "Account ID copied.", "AccountCopyID")
			page.row("Change Email Address", "profile", page.show_section.bind("CHANGE EMAIL"), "AccountEmail").disabled = in_room
			page.row("Change / Add Game Password", "security", page.show_section.bind("CHANGE PASSWORD"), "AccountPassword").disabled = in_room
			page.row("Account Security", "security", page.show_section.bind("ACCOUNT SECURITY"), "AccountSecurity").disabled = in_room
			page.row("Permanently Delete Account", "exit", page.show_section.bind("DELETE ACCOUNT"), "AccountDelete").disabled = in_room
			page.row("Log Out", "exit", page.app._open_account_settings, "AccountLogout").disabled = in_room
		if in_room: page.paragraph("Leave the room before changing your username or sign-in details.")
		return
	if action == "DELETE ACCOUNT" and huawei:
		if in_room: page.paragraph("Leave the room before changing account details."); return
		page.paragraph("Remove this game's saved Huawei profile from this device and log out. Your Huawei ID is not deleted. You can sign in again later.")
		var confirmation := field(page, "Type DELETE to confirm", "AccountDeleteConfirmation", false, "", 6)
		page.row("REMOVE LOCAL PROFILE", "exit", func():
			if confirmation.text != "DELETE": page.status.text = "Type DELETE to confirm."; return
			var uid: String = auth.user.uid
			auth.sign_out(); page.app._account_deleted(uid), "AccountSubmit")
		return
	if action == "CHANGE AVATAR": avatars(page); return
	if action == "ACCOUNT SECURITY" and huawei:
		page.heading("HUAWEI ACCOUNT SECURITY")
		page.paragraph("Huawei manages your Huawei ID email, password and account security. This sign-in is separate from Firebase email and Google accounts.")
		page.paragraph("Removing this game's local profile does not delete your Huawei ID. Cloud account linking and progress sync are not part of this integration.")
		page.row("Manage Huawei ID", "security", func(): OS.shell_open("https://id5.cloud.huawei.com/"), "AccountHuaweiSecurity")
		return
	if action == "ACCOUNT SECURITY":
		page.heading("SIGN-IN SECURITY")
		page.paragraph("Email verified: " + ("Yes" if auth.user.get("email_verified", false) else "Not yet confirmed"))
		page.paragraph("Sign-in method: " + ("Google" if auth.user.get("provider", "password") == "google.com" else "Email & password"))
		page.row("Refresh Account Information", "reset", auth.refresh_account, "AccountRefresh")
		if not auth.user.get("email_verified", false):
			page.row("Verify Email Address", "security", func(): page.show_section("VERIFY EMAIL"), "AccountVerifyEmail")
		page.paragraph("Email changes, password changes and account deletion require you to confirm your identity again.")
		return
	if in_room: page.paragraph("Leave the room before changing account details."); return
	var inputs: Dictionary = {}
	if action == "CHANGE USERNAME":
		inputs.name = field(page, "Username", "AccountNameInput", false, str(Profiles.profile(auth.user).username), 20)
		page.row("Save Username", "profile", func():
			var value_: String = inputs.name.text.strip_edges()
			if value_.is_empty(): page.status.text = "Enter a username."; return
			if guest:
				if Profiles.save({}, "username", value_) != OK: page.status.text = "Could not save the username. Try again."; return
				page.app.lobby_player_name = value_; page.show_section("ACCOUNT"); page.status.text = "Username updated."
			else: auth.update_username(value_), "AccountSaveName")
		return
	if action in ["CHANGE EMAIL", "CREATE ACCOUNT"]:
		inputs.email = field(page, "New email address" if action == "CHANGE EMAIL" else "Email address", "AccountEmailInput")
	if action in ["CHANGE PASSWORD", "CREATE ACCOUNT"]:
		inputs.password = field(page, "New password", "AccountNewPassword", true)
		inputs.confirm = field(page, "Confirm new password", "AccountConfirmPassword", true)
	var google: bool = auth.user.get("provider", "password") == "google.com"
	if action != "CREATE ACCOUNT":
		if google: page.paragraph("Confirm with the same Google account when prompted. This changes your game account, not your Google password or Gmail address.")
		else: inputs.current = field(page, "Current password", "AccountCurrentPassword", true)
	if action == "DELETE ACCOUNT":
		page.paragraph("Permanently delete your game sign-in account and its saved profile on this device. This cannot be undone. Your Google account itself will not be deleted.")
		inputs.delete = field(page, "Type DELETE to confirm", "AccountDeleteConfirmation", false, "", 6)
	if action == "CHANGE EMAIL":
		page.paragraph("We will send a verification link to the new address. After confirming it, choose Refresh Account Information here.")
		page.row("Refresh Account Information", "reset", auth.refresh_account, "AccountRefresh")
	var title: String = {"CHANGE EMAIL":"Send Verification Link", "CHANGE PASSWORD":"Change Game Password", "CREATE ACCOUNT":"Create Permanent Account", "DELETE ACCOUNT":"PERMANENTLY DELETE ACCOUNT", "VERIFY EMAIL":"Send Verification Email"}.get(action, "Confirm")
	var submit: Button = page.row(title, "exit" if action == "DELETE ACCOUNT" else "security", func():
		if auth.busy: return
		if inputs.has("confirm") and inputs.password.text != inputs.confirm.text: page.status.text = "The new passwords do not match."; return
		if action == "DELETE ACCOUNT" and inputs.delete.text != "DELETE": page.status.text = "Type DELETE to confirm permanent deletion."; return
		if action == "CREATE ACCOUNT": auth.convert_guest(inputs.email.text, inputs.password.text); return
		var values: Dictionary = {}
		if inputs.has("email"): values.email = inputs.email.text
		if inputs.has("password"): values.password = inputs.password.text
		var password: String = inputs.current.text if inputs.has("current") else ""
		var operation: String = {"CHANGE EMAIL":"email", "CHANGE PASSWORD":"password", "DELETE ACCOUNT":"delete", "VERIFY EMAIL":"verify"}.get(action, "")
		auth.manage_account(operation, values, password), "AccountSubmit")
	if action == "DELETE ACCOUNT":
		var danger := submit.get_theme_stylebox("normal").duplicate() as StyleBoxFlat
		danger.bg_color = Color("792b31"); danger.border_color = Data.GOLD
		submit.add_theme_stylebox_override("normal", danger)

static func field(page: Control, title: String, node_name: String, secret: bool = false, value: String = "", maximum: int = 254) -> LineEdit:
	var label: Label = page.label_(title, 20, Data.GOLD); page.content.add_child(label)
	var input := LineEdit.new(); input.name = node_name; input.secret = secret
	input.text = value; input.max_length = maximum; input.placeholder_text = title
	input.custom_minimum_size.y = 52; input.add_theme_font_size_override("font_size", 22)
	page.content.add_child(input)
	return input

static func avatars(page: Control) -> void:
	page.paragraph("Choose a profile avatar. It does not change your character in a match.")
	var grid := GridContainer.new(); grid.columns = 5; grid.add_theme_constant_override("h_separation", 14); grid.add_theme_constant_override("v_separation", 14); page.content.add_child(grid)
	for name_ in Data.CHARACTERS:
		var button := UI.make_button(grid, "", func():
			if Profiles.save(page.app.firebase_auth.user, "avatar", name_) != OK: page.status.text = "Could not save the avatar. Try again."; return
			page.show_section("ACCOUNT"); page.status.text = "Avatar saved on this device.", 202, 156)
		button.name = "ProfileAvatar_"+str(Data.CHARACTERS.find(name_))
		var image := TextureRect.new(); image.texture = load(Data.CHARACTER_AVATARS[name_]); image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		image.position = Vector2(61, 8); image.size = Vector2(80, 80); image.mouse_filter = Control.MOUSE_FILTER_IGNORE; button.add_child(image)
		UI.make_child_label(button, name_, 16, Data.CREAM, HORIZONTAL_ALIGNMENT_CENTER, Rect2(10, 94, 182, 54))
