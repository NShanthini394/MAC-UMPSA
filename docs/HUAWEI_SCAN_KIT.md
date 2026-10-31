# Huawei Scan Kit room invitations

Join Room now offers both the existing five-character code field and a **SCAN
QR** button. Scanning reads the host's invite, fills the code field, and asks the
player to press **JOIN ROOM** to confirm. It uses the same configured online
server and normal room validation as typed codes. Guests can also scan; Huawei
account sign-in is not a prerequisite for the UI.

Hosts can press **SHOW ROOM QR** after creating an online room or from their
waiting room. The QR overlay displays the room code as a readable fallback.
Both devices need internet connectivity; QR scanning does not provide a network
transport or make an unavailable/full/started room joinable. Local Wi-Fi-only
room invites remain typed-code based.

## Android implementation

- Huawei dependency: `com.huawei.hms:scanplus:2.12.0.301`.
- Native singleton: `KampungHuaweiScan`, packaged in the same compiled AAR as
  `KampungHuaweiAccount`. Their activity result and permission request codes
  are separate.
- The native bridge invokes Huawei's `ScanUtil.startScan` with QR-only options.
  Camera access is requested when the player starts a scan, not at app launch.
  Denial and cancellation leave manual entry available.
- Android hosts also invoke `ScanUtil.buildBitmap` for their room QR. PNG bytes
  are transferred in memory; no photo or image needs to be saved on the phone.
- The exporter supplies both Account Kit and Scan Kit dependencies. Rebuild
  the APK using the existing Android Gradle export preset to include the new
  plugin and camera permission. Existing installed APKs will not gain scanning
  until replaced with this build.

## Payload and desktop support

Room QRs contain exactly `NKR1:` followed by a valid uppercase five-character
room code, such as `NKR1:7KX9Q`. They do not contain account credentials, server
URLs or executable instructions. Arbitrary web URLs and unrelated/malformed QRs
are rejected. Closing the join screen or beginning a typed join cancels pending
scan results. Scanning never automatically connects.

Windows hosts generate the same payload with the bounded version-1 QR encoder
in `scripts/room_qr.gd`. The four-module quiet zone and nearest texture filtering
keep the QR readable. Desktop users can host and show QR invitations, but use
typed codes when joining; the camera scanner itself uses the Android Huawei SDK.

## Validation and device checks

- The combined native AAR compiled successfully with Scan Kit.
- 33 room QR checks passed, covering format rejection, cancellation, form
  population, confirmation, host rendering and desktop fallback.
- Five different desktop-generated codes were independently decoded by ZXing.
- Account Kit regression: 19 checks passed. Firebase/guest regression: 14 passed.
- UI previews: `output/huawei/join-type-or-scan.png`,
  `output/huawei/host-share-qr.png`, `output/huawei/room-qr.png`.

Real camera scanning and two-device QR joining have **not** been verified on a
physical Android device. On your phone, check permission granted/denied,
scanner cancellation, unrelated QRs, an expired room and successful joining of
a live host. In Huawei's console, complete any Scan Kit service setup requested
for your Android app.

References: [Huawei Scan Kit](https://developer.huawei.com/consumer/en/hms/huawei-scankit)
and [ScanUtil API](https://developer.huawei.com/consumer/es/doc/HMSCore-References/scan-scanutil4-0000001050167699).
