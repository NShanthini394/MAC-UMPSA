extends SceneTree
const Auth = preload("res://scripts/firebase_auth.gd")
var checks := 0
var failures := 0
func _initialize() -> void:
	run.call_deferred()
func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		printerr("FAIL: " + message)
func run() -> void:
	var app = load("res://scenes/main.tscn").instantiate()
	root.add_child(app)
	await process_frame
	await process_frame
	check(app.current_screen == "login", "Starts at sign-in")
	app.show_create_account()
	check(app.find_child("AuthEmail", true, false) != null, "Create account email field")
	check(app.find_child("AuthPassword", true, false).secret, "Password masked")
	check(app.find_child("AuthConfirmPassword", true, false).secret, "Confirmation masked")
	app.find_child("AuthEmail", true, false).text = "test@example.com"
	app.find_child("AuthPassword", true, false).text = "OnePassword9!"
	app.find_child("AuthConfirmPassword", true, false).text = "DifferentPassword9!"
	app._submit_email_auth("create")
	check(not app.firebase_auth.busy, "Mismatched passwords never contact Firebase")
	check(app.find_child("AuthNoticeLabel", true, false).text.contains("do not match"), "Mismatch feedback")
	app.navigate_back()
	await process_frame
	app._continue_as_guest()
	await process_frame
	await process_frame
	check(app.current_screen == "menu", "Guest enters menu without authentication")
	check(app.firebase_auth.user.is_empty(), "Guest has no Firebase identity")
	var auth := Auth.new()
	root.add_child(auth)
	check(not auth.api_key.is_empty(), "Matching Firebase package configuration loads")
	check(not auth.web_client_id.is_empty(), "Google web client ID present")
	var events := {"success": 0, "error": ""}
	auth.authenticated.connect(func(): events.success += 1)
	auth.failed.connect(func(message): events.error = message)
	await auth.email_sign_in("invalid", "")
	check(not auth.busy and events.success == 0, "Invalid input rejected locally")
	# Start then immediately cancel a real pending request; stale callbacks must not sign in.
	auth.email_sign_in("cancelled-request@example.com", "not-a-real-account-password")
	auth.cancel()
	await process_frame
	check(not auth.busy and auth.user.is_empty() and events.success == 0, "Cancellation discards pending authentication")
	app.firebase_auth.user = {"uid": "ui-test-only", "email": "ui@example.com"}
	await app.build_menu()
	check(app.find_child("SignOutButton", true, false) != null, "Authenticated menu exposes sign-out")
	app._sign_out()
	await process_frame
	await process_frame
	check(app.current_screen == "login" and app.firebase_auth.user.is_empty(), "Sign-out returns to login and clears identity")
	if "--live" in OS.get_cmdline_user_args():
		# Disposable account only. Never send email or log passwords/tokens.
		var random := Crypto.new().generate_random_bytes(16).hex_encode()
		var email := "codex-auth-test-" + random + "@example.com"
		var password := "Test!9aA" + Crypto.new().generate_random_bytes(24).hex_encode()
		await auth.email_sign_in(email, password, true)
		check(events.success == 1, "Live Firebase creates disposable account: " + str(events.error))
		if not auth.user.is_empty():
			var cleanup_token: String = auth.user.id_token
			var uid: String = auth.user.uid
			await auth.email_sign_in(email, password, true)
			check(events.success == 1 and str(events.error).contains("already uses"), "Duplicate account does not authenticate")
			auth.sign_out()
			check(auth.user.is_empty(), "Sign-out clears in-memory session")
			await auth.email_sign_in(email, password + "wrong")
			check(events.success == 1 and auth.user.is_empty(), "Wrong password cannot authenticate")
			await auth.email_sign_in(email, password)
			check(events.success == 2 and auth.user.get("uid", "") == uid, "Live sign-in returns same user")
			var deleted: Dictionary = await auth._request("accounts:delete", {"idToken": cleanup_token})
			check(not deleted.has("error"), "Disposable Firebase account removed")
			auth.sign_out()
			await auth.email_sign_in(email, password)
			check(auth.user.is_empty(), "Deleted account can no longer sign in")
		auth.busy = true
		await auth._on_google_token("invalid-test-token")
		check(auth.user.is_empty() and not auth.busy and events.success == 2, "Invalid Google token never grants a Firebase session")
	print("Firebase validation: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
