extends Node
## Firebase client authentication. Passwords and session tokens are never written to disk.
signal authenticated
signal failed(message: String)
signal reset_sent
signal busy_changed(value: bool)
signal account_updated(action: String, message: String)
signal account_deleted(uid: String)

const CONFIG_PATH := "res://config/google-services.json"
const PACKAGE := "org.godotengine.nenekkebayan"
var api_key := ""
var web_client_id := ""
var project_id := ""
var busy := false
var user: Dictionary = {}
var _http: HTTPRequest
var _generation := 0
var _google: Object
var _google_action: Dictionary = {}
var _login_provider := "password"

func _ready() -> void:
	load_configuration()
	if Engine.has_singleton("KampungGoogleSignIn"):
		_google = Engine.get_singleton("KampungGoogleSignIn")
		_google.connect("google_token", _on_google_token)
		_google.connect("google_error", _on_google_error)

func load_configuration(path: String = CONFIG_PATH) -> bool:
	api_key = ""
	web_client_id = ""
	if not FileAccess.file_exists(path): return false
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not parsed is Dictionary: return false
	project_id = str(parsed.get("project_info", {}).get("project_id", ""))
	for client in parsed.get("client", []):
		if str(client.get("client_info", {}).get("android_client_info", {}).get("package_name", "")) != PACKAGE: continue
		for key in client.get("api_key", []): api_key = str(key.get("current_key", ""))
		for oauth in client.get("oauth_client", []):
			if int(oauth.get("client_type", 0)) == 3: web_client_id = str(oauth.get("client_id", ""))
	return not api_key.is_empty()

func _begin() -> bool:
	if busy: return false
	if api_key.is_empty():
		failed.emit("Firebase configuration is missing. Please add google-services.json.")
		return false
	busy = true
	busy_changed.emit(true)
	return true

func _finish() -> void:
	busy = false
	busy_changed.emit(false)

func cancel() -> void:
	_google_action.clear()
	_generation += 1
	if is_instance_valid(_http):
		var pending := _http
		pending.cancel_request()
		# Resolve the suspended request; the generation check discards its result.
		pending.request_completed.emit(HTTPRequest.RESULT_REQUEST_FAILED, 0, PackedStringArray(), PackedByteArray())
		_http = null
	if _google != null: _google.call("cancelSignIn")
	_finish()

func sign_out() -> void:
	cancel()
	user.clear()

func email_sign_in(email: String, password: String, create: bool = false) -> void:
	email = email.strip_edges()
	if email.is_empty() or not email.contains("@") or password.is_empty():
		failed.emit("Enter a valid email address and your password.")
		return
	if create and password.length() < 6:
		failed.emit("Use a password with at least 6 characters.")
		return
	if not _begin(): return
	_login_provider = "password"
	var generation := _generation
	var result: Dictionary = await _request("accounts:signUp" if create else "accounts:signInWithPassword", {"email": email, "password": password, "returnSecureToken": true})
	if generation != _generation: return
	_accept(result)

func reset_password(email: String) -> void:
	email = email.strip_edges()
	if not email.contains("@"):
		failed.emit("Enter your account email address.")
		return
	if not _begin(): return
	var generation := _generation
	var result: Dictionary = await _request("accounts:sendOobCode", {"requestType": "PASSWORD_RESET", "email": email})
	if generation != _generation: return
	_finish()
	# Avoid disclosing whether another player's address has an account.
	if result.has("error") and str(result.error).get_slice(" : ", 0) != "EMAIL_NOT_FOUND": failed.emit(error_message(str(result.error)))
	else: reset_sent.emit()

func google_sign_in() -> void:
	if OS.get_name() != "Android":
		failed.emit("Google sign-in is available in the Android test APK. On this computer, use email/password or Play as Guest.")
		return
	if _google == null or web_client_id.is_empty():
		failed.emit("Google sign-in is not configured in this Android build.")
		return
	if not _begin(): return
	_login_provider = "google.com"
	_google_action = {}
	_google.call("signIn", web_client_id)

func _on_google_token(token: String) -> void:
	if not busy: return
	var generation := _generation
	var operation := _google_action.duplicate(true)
	_google_action.clear()
	var payload := {"postBody": "id_token=" + token.uri_encode() + "&providerId=google.com", "requestUri": "http://localhost", "returnSecureToken": true, "returnIdpCredential": true}
	# A Firebase guest identity, if present, must be linked, not replaced.
	if operation.get("action", "") == "link_google" and not user.is_empty(): payload["idToken"] = user.id_token
	if not operation.is_empty() and operation.get("action", "") != "link_google": payload["autoCreate"] = false
	var result: Dictionary = await _request("accounts:signInWithIdp", payload)
	if generation != _generation: return
	if operation.is_empty():
		_accept(result)
		return
	if result.has("error"): _account_error(result); return
	if str(operation.action) == "link_google":
		if str(result.get("localId", "")).is_empty() or str(result.get("idToken", "")).is_empty(): _account_error({"error":"SERVICE_UNAVAILABLE"}); return
		if not user.is_empty() and str(result.get("localId", "")) != str(user.uid): _account_error({"error":"USER_MISMATCH"}); return
		_adopt_session(result, "google.com")
		_finish(); authenticated.emit()
		account_updated.emit("linked", "Google account linked. Your local guest profile is kept.")
		return
	# Reauthentication must prove the same account; choosing a different Google
	# account must never switch the identity being edited or deleted.
	if str(result.get("localId", "")) != str(operation.uid): _account_error({"error":"USER_MISMATCH"}); return
	_adopt_session(result, "google.com")
	await _perform_account_action(str(operation.action), operation.get("fields", {}), generation)

func _on_google_error(message: String) -> void:
	if not busy: return
	_google_action.clear()
	_finish()
	failed.emit(message)

func _accept(result: Dictionary) -> void:
	_finish()
	if result.has("error"):
		failed.emit(error_message(str(result.error)))
		return
	if str(result.get("localId", "")).is_empty() or str(result.get("idToken", "")).is_empty():
		failed.emit("The sign-in service returned an incomplete response. Please try again.")
		return
	_adopt_session(result, _login_provider)
	authenticated.emit()

func _adopt_session(result: Dictionary, provider: String = "") -> void:
	user["uid"] = str(result.get("localId", user.get("uid", "")))
	user["email"] = str(result.get("email", user.get("email", "")))
	user["display_name"] = str(result.get("displayName", user.get("display_name", "")))
	user["id_token"] = str(result.get("idToken", user.get("id_token", "")))
	user["email_verified"] = bool(result.get("emailVerified", user.get("email_verified", false)))
	if not provider.is_empty(): user["provider"] = provider
	if result.has("providerUserInfo"):
		user["providers"] = []
		for info in result.providerUserInfo: user.providers.append(str(info.get("providerId", "")))
	elif not provider.is_empty(): user["providers"] = [provider]

func _account_error(result: Dictionary) -> void:
	_finish()
	failed.emit(error_message(str(result.get("error", "SERVICE_UNAVAILABLE"))))

func update_username(value: String) -> void:
	var cleaned := value.strip_edges().substr(0, 20)
	if cleaned.is_empty(): failed.emit("Enter a username."); return
	if user.is_empty(): failed.emit("No signed-in account."); return
	if not _begin(): return
	var generation := _generation
	var result := await _request("accounts:update", {"idToken": user.id_token, "displayName": cleaned, "returnSecureToken": true})
	if generation != _generation: return
	if result.has("error"): _account_error(result); return
	_adopt_session(result); user["display_name"] = cleaned
	_finish(); account_updated.emit("username", "Username updated.")

func convert_guest(email: String, password: String) -> void:
	if not user.is_empty() and not user.get("anonymous", false): failed.emit("This account is already signed in."); return
	if not email.strip_edges().contains("@") or password.length() < 6: failed.emit("Enter a valid email and a password with at least 6 characters."); return
	if not _begin(): return
	var generation := _generation
	var previous_uid := str(user.get("uid", ""))
	var payload := {"email": email.strip_edges(), "password": password, "returnSecureToken": true}
	# signUp with idToken supports linking with email-enumeration protection.
	if not user.is_empty(): payload["idToken"] = user.id_token
	var result := await _request("accounts:signUp", payload)
	if generation != _generation: return
	if result.has("error"): _account_error(result); return
	if str(result.get("localId", "")).is_empty() or str(result.get("idToken", "")).is_empty(): _account_error({"error":"SERVICE_UNAVAILABLE"}); return
	if not previous_uid.is_empty() and str(result.get("localId", "")) != previous_uid: _account_error({"error":"USER_MISMATCH"}); return
	_adopt_session(result, "password"); user.erase("anonymous")
	_finish(); authenticated.emit(); account_updated.emit("linked", "Account created. Your local guest profile is kept.")

func link_google() -> void:
	if not user.is_empty() and not user.get("anonymous", false): failed.emit("This account is already signed in."); return
	if not _google_available(): return
	if not _begin(): return
	_google_action = {"action":"link_google"}
	_google.call("signIn", web_client_id)

func _google_available() -> bool:
	if OS.get_name() != "Android": failed.emit("Google account actions are available in the Android APK."); return false
	if _google == null or web_client_id.is_empty(): failed.emit("Google sign-in is not configured in this build."); return false
	return true

func manage_account(action: String, fields: Dictionary, current_password: String = "") -> void:
	if user.is_empty(): failed.emit("Sign in before managing an account."); return
	if action not in ["email", "password", "delete", "verify"]: return
	if action == "email" and (not str(fields.get("email", "")).strip_edges().contains("@") or str(fields.email).strip_edges() == str(user.email)):
		failed.emit("Enter a different valid email address."); return
	if action == "password" and str(fields.get("password", "")).length() < 6: failed.emit("Use at least 6 characters for the new password."); return
	if str(user.get("provider", "password")) == "google.com":
		if not _google_available(): return
		if not _begin(): return
		_google_action = {"action":action, "uid":str(user.uid), "fields":fields.duplicate()}
		_google.call("signIn", web_client_id)
		return
	if current_password.is_empty(): failed.emit("Enter your current password to confirm this action."); return
	if not _begin(): return
	var generation := _generation
	var expected_uid := str(user.uid)
	var fresh := await _request("accounts:signInWithPassword", {"email":user.email, "password":current_password, "returnSecureToken":true})
	if generation != _generation: return
	if fresh.has("error"): _account_error(fresh); return
	if str(fresh.get("localId", "")) != expected_uid: _account_error({"error":"USER_MISMATCH"}); return
	_adopt_session(fresh)
	await _perform_account_action(action, fields, generation)

func _perform_account_action(action: String, fields: Dictionary, generation: int) -> void:
	var endpoint := "accounts:update"
	var payload := {"idToken":user.id_token, "returnSecureToken":true}
	var uid := str(user.uid)
	match action:
		"email":
			endpoint = "accounts:sendOobCode"
			payload = {"idToken":user.id_token, "requestType":"VERIFY_AND_CHANGE_EMAIL", "newEmail":str(fields.email).strip_edges()}
		"password": payload["password"] = fields.password
		"delete": endpoint = "accounts:delete"; payload = {"idToken":user.id_token}
		"verify": endpoint = "accounts:sendOobCode"; payload = {"idToken":user.id_token, "requestType":"VERIFY_EMAIL"}
	var result := await _request(endpoint, payload)
	if generation != _generation: return
	if result.has("error"): _account_error(result); return
	if action == "delete":
		user.clear(); _finish(); account_deleted.emit(uid); return
	_adopt_session(result)
	_finish()
	var message: String = {"email":"Check your new email and confirm the verification link. Then refresh Account Information.", "password":"Game account password updated.", "verify":"Verification email requested. Check your inbox."}.get(action, "Account updated.")
	account_updated.emit(action, message)

func refresh_account() -> void:
	if user.is_empty() or not _begin(): return
	var generation := _generation
	var result := await _request("accounts:lookup", {"idToken":user.id_token})
	if generation != _generation: return
	if result.has("error"): _account_error(result); return
	if result.get("users", []).is_empty(): _account_error({"error":"USER_NOT_FOUND"}); return
	_adopt_session(result.users[0]); _finish(); account_updated.emit("refresh", "Account information refreshed.")

func _request(endpoint: String, payload: Dictionary) -> Dictionary:
	var request := HTTPRequest.new()
	request.timeout = 20.0
	add_child(request)
	_http = request
	var status := request.request("https://identitytoolkit.googleapis.com/v1/" + endpoint + "?key=" + api_key.uri_encode(), PackedStringArray(["Content-Type: application/json"]), HTTPClient.METHOD_POST, JSON.stringify(payload))
	if status != OK:
		request.queue_free()
		_http = null
		return {"error": "NETWORK_ERROR"}
	var response: Array = await request.request_completed
	request.queue_free()
	_http = null
	if int(response[0]) != HTTPRequest.RESULT_SUCCESS: return {"error": "NETWORK_ERROR"}
	var body = JSON.parse_string((response[3] as PackedByteArray).get_string_from_utf8())
	if not body is Dictionary: return {"error": "SERVICE_UNAVAILABLE"}
	if int(response[1]) != 200: return {"error": str(body.get("error", {}).get("message", "SERVICE_UNAVAILABLE"))}
	return body

static func error_message(code: String) -> String:
	match code.get_slice(" : ", 0):
		"INVALID_LOGIN_CREDENTIALS", "EMAIL_NOT_FOUND", "INVALID_PASSWORD": return "The email or password is incorrect. Please try again."
		"EMAIL_EXISTS": return "An account already uses this email. Sign in or reset your password."
		"WEAK_PASSWORD", "PASSWORD_DOES_NOT_MEET_REQUIREMENTS": return "Choose a stronger password that meets this project's password policy."
		"USER_MISMATCH": return "Choose the same account that is signed in to this game. No changes were made."
		"CREDENTIAL_TOO_OLD_LOGIN_AGAIN", "TOKEN_EXPIRED", "INVALID_ID_TOKEN": return "Please sign in again to confirm your account, then retry."
		"USER_NOT_FOUND": return "This account no longer exists. Sign out and return to Sign In."
		"INVALID_EMAIL": return "Enter a valid email address."
		"USER_DISABLED": return "This account has been disabled."
		"TOO_MANY_ATTEMPTS_TRY_LATER", "QUOTA_EXCEEDED": return "Too many attempts. Please wait and try again."
		"OPERATION_NOT_ALLOWED": return "This sign-in method is not enabled in Firebase."
		"NETWORK_ERROR": return "Cannot reach the sign-in service. Check your internet connection and try again."
		"API_KEY_INVALID", "API_KEY_SERVICE_BLOCKED", "PROJECT_NOT_FOUND", "CONFIGURATION_NOT_FOUND": return "Firebase configuration needs checking for this build."
		"INVALID_IDP_RESPONSE", "INVALID_CREDENTIAL": return "Google sign-in could not be verified. Please try again."
		"FEDERATED_USER_ID_ALREADY_LINKED", "EMAIL_EXISTS_WITH_DIFFERENT_CREDENTIAL", "ACCOUNT_EXISTS_WITH_DIFFERENT_CREDENTIAL": return "Sign in using the method you originally used for this email."
	return "Sign-in could not be completed. Please try again."
