extends SceneTree
const Auth=preload("res://scripts/firebase_auth.gd")
const Profiles=preload("res://scripts/account_profiles.gd")
class GoogleStub extends RefCounted:
 var called:=false
 func signIn(_id:String)->void:called=true
 func cancelSignIn()->void:pass
class MockAuth extends Auth:
 var responses:Array=[]
 var requests:Array=[]
 func _request(endpoint:String,payload:Dictionary)->Dictionary:
  requests.append({"endpoint":endpoint,"payload":payload.duplicate(true)})
  var response:Dictionary=responses.pop_front() if not responses.is_empty() else {"error":"SERVICE_UNAVAILABLE"}
  await get_tree().process_frame
  return response
 func _google_available()->bool:return true
var checks:=0
var failures:=0
func _initialize()->void:run.call_deferred()
func check(ok:bool,message:String)->void:
 checks+=1
 if not ok:failures+=1;push_error(message)
func session(provider:String="password")->Dictionary:
 return {"uid":"account-A","id_token":"fake-token","email":"old@example.test","display_name":"Arun","provider":provider}
func fresh(uid:String="account-A")->Dictionary:return {"localId":uid,"idToken":"fresh-fake-token","email":"old@example.test"}
func run()->void:
 var auth:=MockAuth.new();root.add_child(auth)
 var errors:Array=[];var updates:Array=[];var deleted:Array=[]
 auth.failed.connect(func(message):errors.append(message))
 auth.account_updated.connect(func(action,message):updates.append({"action":action,"message":message}))
 auth.account_deleted.connect(func(uid):deleted.append(uid))
 auth.user=session()
 auth.responses=[{"localId":"account-A","displayName":"Mei Ling","idToken":"updated-fake-token"}]
 await auth.update_username(" Mei Ling ")
 check(auth.user.display_name=="Mei Ling" and auth.requests[-1].payload.displayName=="Mei Ling","Username saved to authenticated Firebase profile")
 var before:=auth.requests.size()
 await auth.manage_account("delete",{},"")
 check(auth.requests.size()==before and not auth.user.is_empty(),"Deleting requires current password")
 auth.responses=[{"error":"INVALID_PASSWORD"}]
 await auth.manage_account("delete",{},"wrong")
 check(deleted.is_empty() and not auth.user.is_empty() and auth.requests[-1].endpoint=="accounts:signInWithPassword","Wrong password never reaches deletion")
 auth.responses=[fresh(),{}]
 await auth.manage_account("email",{"email":"new@example.test"},"current-password")
 check(auth.requests[-1].endpoint=="accounts:sendOobCode" and auth.requests[-1].payload.requestType=="VERIFY_AND_CHANGE_EMAIL","Email changes require new-email verification")
 check(auth.requests[-1].payload.newEmail=="new@example.test" and auth.user.email=="old@example.test","Primary email not changed before link confirmation")
 check(auth.requests[-1].payload.idToken=="fresh-fake-token","Sensitive changes use fresh proof of identity")
 auth.responses=[{"users":[{"localId":"account-A","email":"new@example.test","emailVerified":true,"providerUserInfo":[{"providerId":"password"}]}]}]
 await auth.refresh_account()
 check(auth.user.email=="new@example.test" and auth.user.email_verified,"Account refresh reads verified server email")
 auth.responses=[fresh(),{"idToken":"password-token"}]
 await auth.manage_account("password",{"password":"NewPassword!9"},"current-password")
 check(auth.requests[-1].endpoint=="accounts:update" and auth.requests[-1].payload.password=="NewPassword!9","Password update follows reauthentication")
 auth.responses=[fresh(),{"error":"CREDENTIAL_TOO_OLD_LOGIN_AGAIN"}]
 await auth.manage_account("delete",{},"current-password")
 check(deleted.is_empty() and not auth.user.is_empty(),"Failed deletion preserves session and local profile")
 auth.responses=[fresh(),{}]
 await auth.manage_account("delete",{},"current-password")
 check(deleted==["account-A"] and auth.user.is_empty(),"Successful deletion clears session and reports exact deleted UID")
 auth.user={};auth.responses=[{}]
 await auth.convert_guest("guest@example.test","Password9!")
 check(auth.user.is_empty(),"Malformed conversion response cannot authenticate")
 auth.user={};auth.responses=[{"error":"EMAIL_EXISTS"}]
 await auth.convert_guest("existing@example.test","Password9!")
 check(auth.user.is_empty(),"Email collision never replaces guest with another account")
 auth.responses=[{"localId":"new-account","idToken":"new-fake-token","email":"guest@example.test"}]
 await auth.convert_guest("guest@example.test","Password9!")
 check(auth.user.uid=="new-account" and updates[-1].action=="linked","Offline guest conversion creates permanent account")
 auth.user={"uid":"anonymous-A","id_token":"anonymous-token","anonymous":true}
 auth.responses=[{"localId":"anonymous-A","idToken":"linked-fake-token","email":"guest@example.test"}]
 await auth.convert_guest("guest@example.test","Password9!")
 check(auth.requests[-1].endpoint=="accounts:signUp" and auth.requests[-1].payload.idToken=="anonymous-token" and auth.user.uid=="anonymous-A","Firebase anonymous linking preserves UID with signUp idToken")
 auth.user=session("google.com");auth._google=GoogleStub.new()
 auth.manage_account("delete",{})
 check(auth._google.called and auth.busy,"Google deletion opens Google reauthentication")
 before=auth.requests.size();auth.responses=[fresh("wrong-account")]
 await auth._on_google_token("stub-token")
 check(auth.user.uid=="account-A" and deleted.size()==1 and auth.requests.size()==before+1,"Wrong Google identity cannot edit/delete or switch account")
 check(auth.requests[-1].payload.get("autoCreate",true)==false,"Google reauthentication cannot create another game account")
 auth.manage_account("delete",{});auth.responses=[fresh(),{}]
 await auth._on_google_token("stub-token")
 check(auth.user.is_empty() and deleted.size()==2,"Matching Google reauthentication allows requested deletion")
 auth.user={};auth.link_google();auth.responses=[{"localId":"google-linked","idToken":"google-token","email":"google@example.test","providerId":"google.com"}]
 await auth._on_google_token("stub-token")
 check(auth.user.uid=="google-linked" and updates[-1].action=="linked","Guest Google linking completes without a password")
 auth.user=session();auth.responses=[fresh(),{}]
 var events:=deleted.size()
 auth.manage_account("delete",{},"Password9!");auth.cancel();await process_frame;await process_frame
 check(deleted.size()==events and auth.user.uid=="account-A","Cancelled reauthentication cannot continue to deletion")
 var settings=load("res://scripts/settings_store.gd");settings.load_values();var original_settings:Dictionary=settings.values.duplicate(true)
 var old_path:=Profiles.path;Profiles.path="user://account-test-profiles.cfg"
 Profiles.save({},"username","Guest Arun");Profiles.save({},"avatar","Badang")
 Profiles.link_guest({"uid":"profile-A"})
 check(Profiles.profile({"uid":"profile-A"}).username=="Guest Arun" and Profiles.profile({"uid":"profile-A"}).avatar=="Badang","Guest profile and avatar retained when linking")
 Profiles.save({"uid":"profile-B"},"username","Existing Siti");Profiles.link_guest({"uid":"profile-B"})
 check(Profiles.profile({"uid":"profile-B"}).username=="Existing Siti","Existing permanent profile is not overwritten")
 Profiles.erase_account("profile-A")
 check(Profiles.profile({"uid":"profile-B"}).username=="Existing Siti","Deletion leaves other account profiles intact")
 var contents:=FileAccess.get_file_as_string(Profiles.path)
 check(not contents.contains("fake-token") and not contents.contains("Password9"),"Profile storage contains no passwords or auth tokens")
 DirAccess.remove_absolute(Profiles.path);Profiles.path=old_path
 for key in original_settings:settings.set_value(key,original_settings[key])
 auth.queue_free();await process_frame
 print("ACCOUNT MANAGEMENT: %d checks; %d failures"%[checks,failures]);quit(1 if failures else 0)
