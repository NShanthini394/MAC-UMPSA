# App languages and Huawei ML Kit

Settings → Language selects English, Bahasa Melayu, Chinese or Tamil for the game UI.
English and Malay work offline. Malay has 480 bundled game messages in
scripts/language_malay.gd in addition to the shared navigation catalogue.
This includes character selection, rooms, all twelve task names/instructions,
clues, map areas, meetings, powers and the guide. Malay does not enqueue cloud
requests. Bundled copy overrides any older cached machine translations.

Chinese and Tamil use bundled navigation plus Huawei ML Kit for additional game
text. Selecting these languages enables cloud translation as screens are opened;
Settings explains the internet requirement. Only exact authored-source allowlist
entries from localization/sources.json can be sent. Account data, names, room
codes, passwords and chat messages are not sent. Successful cloud results are
cached on the device. Source game state is unchanged.

Separate Translate buttons on tasks, clues and the guide have been removed.
The internal translation bridge/dialog remains covered by regression tests.
A clue now displays its name directly in the chosen language.

## Huawei cloud setup

1. In AppGallery Connect, enable ML Kit for this Android app and activate the
   cloud translation service where required.
2. Check service availability, quota/billing and API-key permissions/restrictions
   in the Huawei console. Installing HMS Core alone does not verify cloud setup.
3. Replace config/agconnect-services.json with the latest app configuration.
4. Enable the Kampung Huawei editor plugin, reopen Godot, and export using Gradle
   Build. The exporter includes only public client configuration and excludes
   the raw JSON. The manifest application hook ends in _element_contents.

The SDK is com.huawei.hms:ml-computer-translate:3.11.0.302. The native bridge
queries Huawei's supported languages before translating en→ms/zh/ta. The public
Android API key is SDK configuration; no OAuth client secret is bundled.

## Verification

Run tools/verify_huawei_apk.ps1 against the exported APK to verify all three
native Huawei class registrations, DEX classes, App ID, public configuration,
source catalogue and exclusion of the raw configuration.

The Godot tests cover offline Malay on real game screens, source allowlisting,
placeholder preservation, stale callbacks, language persistence between pages,
clues without extra translation actions, full-screen shading and keyboard
avoidance. Previews are in output/huawei/phone-*.png.

Actual Huawei sign-in/cloud translation and Android keyboard events still need
physical-phone testing. Tests of the translation bridge use mock callbacks.
