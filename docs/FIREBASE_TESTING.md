# Firebase sign-in testing

The Android Firebase registration is `org.godotengine.nenekkebayan`. Its client configuration is `config/google-services.json`. This is a Firebase client configuration, not an administrator credential. Do not add service-account keys or OAuth client secrets to the game.

## PC testing

Run the project in Godot. Choose Create Account and enter email, password, and confirmation. Successful registration opens the main menu. SIGN OUT returns to the login screen. Sign in with Email reopens the same account. Forgot password sends a reset link through Firebase when the player requests it. Google sign-in requires the Android APK; the PC button explains this limitation. Guest play uses no Firebase account.

Passwords and session tokens are held in memory only. Closing the game requires a fresh sign-in next time. There is no cloud progress storage or automatic account linking in this testing stage. Registration does not automatically send a verification email or require verified email.

## Android testing

The enabled `addons/kampung_google` editor plugin packages Google's Credential Manager bridge. The Android export uses Gradle and requires Android API 24 or newer. Firebase Authentication REST exchanges the Google ID token for a Firebase user session; a Google chooser result alone never grants entry.

Export Android with **Export With Debug** enabled for the registered debug certificate. Install the APK on a compatible Android phone or tablet with Google Play services and internet. Test Google account selection, cancellation, sign-out, email registration/sign-in, reset password, and guest play. Real Google chooser/device behavior must be confirmed on a device.

The game requests landscape orientation and preserves a 1280×720 logical viewport. Other screen shapes use letterboxing so the main menu artwork and its tap areas stay aligned. Simulated screen-touch checks cover 16:9, 4:3, 16:10, wide landscape and portrait windows. Install the latest APK and check every menu button on the tablet as well.

The login screen includes a Huawei ID button for the planned Account Kit integration. It currently shows a setup notice; Huawei authentication is not connected yet.

The configured debug certificate's SHA-1 is `97:28:5F:6E:F9:50:89:DF:17:24:D3:1D:AD:8F:0D:08:42:88:F7:6E`. Register a different certificate's fingerprints when using a release key or Play App Signing. After changing Firebase Google provider/client settings, download a fresh `google-services.json` and replace `config/google-services.json`.

The debug APK is `builds/FirebaseTest/NenekKebayan.apk`. Its signature, package name, Google plugin registration, internet permission and embedded Firebase configuration have been checked. Its signing certificate matches the Android OAuth client in the supplied Firebase configuration. Google account selection has not yet been exercised on a physical phone.

## Validation

Run Godot headlessly with `--script res://tests/firebase_auth_validation.gd` for configuration and UI validation. Add `-- --live` to create a disposable `codex-auth-test-...@example.com` Firebase user, test duplicate registration, incorrect password and successful login, then delete the disposable user. The test does not send verification/reset emails or print passwords/tokens. Ordinary user accounts are never touched.

The bridge source is in `native/google_sign_in`. Building with Gradle's `assembleRelease` requires Java 17, Android SDK 36, and a compile-only Godot AAR extracted from the installed export templates into `.godot/firebase-native/godot.aar`. Copy the resulting AAR from `native/google_sign_in/build/outputs/aar/` into `addons/kampung_google/bin/KampungGoogleSignIn.aar`. Runtime dependencies are declared by the editor export plugin. The prebuilt AAR is supplied for the current project.
