extends Node
## Firebase client authentication. Passwords and session tokens are never written to disk.
signal authenticated
signal failed(message: String)
signal reset_sent
signal busy_changed(value: bool)

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
	_google.call("signIn", web_client_id)

func _on_google_token(token: String) -> void:
	if not busy: return
	var generation := _generation
	var result: Dictionary = await _request("accounts:signInWithIdp", {"postBody": "id_token=" + token.uri_encode() + "&providerId=google.com", "requestUri": "http://localhost", "returnSecureToken": true, "returnIdpCredential": true})
	if generation != _generation: return
	_accept(result)

func _on_google_error(message: String) -> void:
	if not busy: return
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
	user = {"uid": result.localId, "email": result.get("email", ""), "display_name": result.get("displayName", ""), "id_token": result.idToken}
	authenticated.emit()

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
		"INVALID_EMAIL": return "Enter a valid email address."
		"USER_DISABLED": return "This account has been disabled."
		"TOO_MANY_ATTEMPTS_TRY_LATER", "QUOTA_EXCEEDED": return "Too many attempts. Please wait and try again."
		"OPERATION_NOT_ALLOWED": return "This sign-in method is not enabled in Firebase."
		"NETWORK_ERROR": return "Cannot reach the sign-in service. Check your internet connection and try again."
		"API_KEY_INVALID", "API_KEY_SERVICE_BLOCKED", "PROJECT_NOT_FOUND", "CONFIGURATION_NOT_FOUND": return "Firebase configuration needs checking for this build."
		"INVALID_IDP_RESPONSE", "INVALID_CREDENTIAL": return "Google sign-in could not be verified. Please try again."
		"FEDERATED_USER_ID_ALREADY_LINKED", "EMAIL_EXISTS_WITH_DIFFERENT_CREDENTIAL", "ACCOUNT_EXISTS_WITH_DIFFERENT_CREDENTIAL": return "Sign in using the method you originally used for this email."
	return "Sign-in could not be completed. Please try again."
