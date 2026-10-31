# Huawei Account Kit setup

The Android login button now calls the native Huawei Account Kit SDK. Successful
sign-in opens the game menu, shows the Huawei display name, and uses it as the
initial lobby name. The existing sign-out button signs out of the game and asks
the Huawei SDK to clear its app session. Guest, email and Google login remain
available. No Edit Profile page is needed.

## Register your app

1. Register and verify your Huawei developer account, then open
   [AppGallery Connect](https://developer.huawei.com/consumer/en/service/josp/agc/index.html).
2. Create a project and an **Android app** with package name
   **org.godotengine.nenekkebayan**. This must match the Android export preset.
3. Enable **Account Kit** for this app and complete any required service
   agreements/settings shown in your console.
4. Add the **SHA-256 fingerprint of the certificate signing your APK**. Register
   the debug certificate for debug APKs and the release certificate for release
   APKs. Do not use the Google OAuth SHA-1 value in place of SHA-256.
5. Download **agconnect-services.json** after saving the app configuration. Copy
   it to `config/agconnect-services.json` in this project. The `client.app_id`
   and `client.package_name` fields must describe this Android app. Do not put an
   app secret in GDScript or in the native plugin.

To inspect your certificate using the JDK, run the following and enter the
keystore password when prompted (never paste the password into chat):

```powershell
keytool -list -v -keystore "C:/path/to/your.keystore" -alias "your-alias"
```

## Build and test

- Use Godot **4.7.2** and the **Android** export preset with **Gradle Build**
  enabled (already configured). Keep the `Kampung Huawei Account Kit` editor
  plugin enabled.
- The exporter adds the Huawei Maven repository, Account Kit dependency and
  `com.huawei.hms.client.appid` manifest metadata from your JSON configuration.
  The native plugin supplies its own registration metadata and package queries.
  Your original Huawei JSON is excluded from exports; the public app ID,
  package name and Android client API key (used by ML Kit) are added to
  `config/huawei-public.json` inside the APK; client secrets are excluded.
- To rebuild the native AAR, use JDK 17 or 21, an Android SDK with platform 36,
  Gradle 8.9, and:

```powershell
./tools/build_huawei_account.ps1 -GradlePath "C:/path/to/gradle.bat"
```

  Optionally pass `-GodotAar "C:/path/to/godot.aar"`; otherwise the build uses
  Godot's published 4.7.2 Android library. This native build does not need your
  Huawei account credentials. APK export does need your app configuration.
- Export a signed Android APK and install it on an Android device with HMS
  Core available and internet access. Tap **Continue with Huawei ID**, complete
  Huawei's sign-in screen, and confirm the menu displays the account name.
- Verify the lobby name, cancellation, sign-out and re-sign-in. Repeat with
  your release APK after registering its signing certificate.
- Windows builds show an Android-only explanation when Huawei sign-in is
  selected. They continue to support guest/email login.

## Identity and storage

This integration uses the Huawei SDK's successful basic sign-in result. The
game keeps a provider-tagged, app-scoped Huawei OpenID and display name **in
memory**, separate from Firebase users. It never stores account passwords,
access tokens or app secrets. A Huawei SDK session is **not** a Firebase token
and is not sent to the multiplayer server as proof of identity.

This does not yet create cloud profiles, save progress, link Huawei and Firebase
accounts, or authenticate privileged server requests. Those require a separate
backend flow with server-side credential verification; do not trust a client
OpenID as authentication. Account Kit alone is the implemented kit here, not
Game Service or Scan Kit.

## Files

- Native SDK bridge: `native/huawei_account/`.
- Godot Android exporter: `addons/kampung_huawei/`.
- Provider handling: `scripts/firebase_auth.gd` (shared login controller).
- Configuration to supply: `config/agconnect-services.json`.

References: [Huawei Account Kit](https://developer.huawei.com/consumer/en/hms/huawei-accountkit)
and [Huawei's Android Account Kit codelab](https://developer.huawei.com/consumer/en/codelab/HMSAccounts/index.html).

## Validation completed

The native release AAR compiled successfully against Godot 4.7.2 and Huawei
Account Kit 6.12.0.300. The 19 Godot integration checks pass using a mock native
callback to cover UI routing, identity separation, cancellation and sign-out.
The existing Firebase/guest validation also passed 14 checks. Mock callbacks do
not demonstrate a real Huawei sign-in. Real device sign-in and signed APK export
with your Huawei app configuration remain pending the registration above.

## Phones from other brands

Tecno and other supported Android phones can use HMS Core. A missing-HMS-Core
message requires the user to install/update HMS Core through Huawei AppGallery,
then reopen the game. The native bridge now exposes getHmsStatus; login checks
it before requesting sign-in. The login screen includes an HMS Core help link
to Huawei's official installation guide. Missing Core does not leave the UI
busy. An outstanding sign-in also has a cancellation-safe timeout.

Official guide: https://consumer.huawei.com/en/support/content/en-us15841704/
