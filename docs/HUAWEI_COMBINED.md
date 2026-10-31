# Combined project v0.18

This project starts from our v0.16 game. Only Huawei-related integrations and
translation adapters were brought across from the friend's older project.
The two original projects have not been edited.

## Preserved
- Our login art, buttons, full-page dark-brown Settings and account-management UI.
- Start Game -> Play with Friends / Solo vs Bots / Quick Match.
- All three 3D map viewers, task selection, routes and gameplay geometry.
- Five-second start countdown and sixty-second Quick Match search.
- Ten characters, eight Villagers/two Nenek, bot tasks/chat/votes and current rules.
- Firebase Google and email/password login, account linking, email/password changes.
- Current online server protocol 7. An already deployed v0.16 server needs no
  new deployment for this client-only integration.

## Integrated
- Huawei Account Kit native Android sign-in, cancel, HMS Core checks and sign-out.
- Huawei Scan Kit room scanning and QR images. Host: Show Room QR. Guest:
  Join Room -> Scan QR. Scanning fills the code; joining still needs confirmation.
  Typing room codes remains supported. Camera permission is requested on use.
- Huawei ML Kit translation bridge and bundled language catalogues. Our Language
  Settings now offers English (default), Malay, Chinese and Tamil. Bundled strings
  work offline. Additional authored text needs the configured Huawei service and
  internet; English remains a fallback if translation fails.
- Automatic translation sends only exact authored strings in the allowlist.
  Player-input/chat/account details are excluded. The handwritten language
  catalogues should still be reviewed by fluent speakers before release.

## What can be tested now
Import this folder's project.godot in Godot 4.7.2. Desktop testing covers the
existing game, four language choices, bundled translations and host QR display.
Huawei sign-in, camera scanning and cloud translation run in the Android APK.
No real Huawei device/service test has been completed.

## Huawei configuration added
The supplied agconnect-services (3).json matches package
org.godotengine.nenekkebayan and has been added to the local combined project.
The Android APK has verified App ID metadata and public SDK configuration for
Huawei Account and ML Kit. The raw JSON and its secret fields are not bundled.
The downloadable project ZIP includes only a minimal configuration containing
client.app_id, client.package_name and the public Android client.api_key, sufficient
for this project's exporter. The original full JSON stays local. Keep the signing
certificate registered in Huawei AppGallery Connect for real device testing:
adb3dbdcf317e07d92a6f140183318c7af1dfd3824167af5c938361cf21de3ee
No real Huawei account, Scan Kit camera, or cloud translation has been exercised
by the desktop tests. Test the APK on Android with the required services enabled.

## v0.18 UI and controls
Solo description: "1 human and 9 bots." Host waiting-room action: "START".
Settings > Controls & Display > Joystick Display offers Always Visible,
Always Hidden and Show on Touch (Default). Each option keeps movement enabled.
Show on Touch displays the joystick at the first finger's lower-left position;
release hides it. A second finger cannot steal/release the movement thumb.
Opening dialogs, resizing and losing focus clear joystick movement. The setting
persists locally and Restore control defaults restores Show on Touch.
Walking speed, collision and multiplayer rules remain unchanged.

## Account boundaries
Huawei SDK sign-in is NOT a Firebase credential and does not create a Firebase
account. Local names and avatars are scoped to the Huawei OpenID. Huawei ID email
and passwords are managed by Huawei. Removing the local game profile does not
delete the Huawei ID. Firebase account actions continue to work for Firebase users.
Huawei/Firebase account linking or cross-device cloud saves are not implemented.

## Build and verification
APK versionCode 18, versionName 0.18-huawei-controls; Godot 4.7.2, Android arm64.
Native sources and the matching prebuilt AAR are included. Use JDK 17 and Gradle
Build in the Android export preset. tools/verify_huawei_apk.ps1 checks all three
native plugins. The configured APK passes strict verification without -AllowUnconfigured.

Regression scripts cover Firebase account behavior, Huawei callbacks/cancellation,
all four language layouts, QR parsing/display, translation allowlisting and
placeholder handling, our account UI, all three 3D maps/routes, and game modes.
Original-source checksum manifests are retained in docs for comparison.
