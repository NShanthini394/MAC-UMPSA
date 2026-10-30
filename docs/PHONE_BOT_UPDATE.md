# Phone controls and bot testing update

The lower-left half of the screen now accepts a floating, invisible joystick. It tracks the initiating finger so other taps do not cancel movement, and expands into wide-phone margins. Shared text and buttons, player names, navigation icons, task rows and voting portraits were enlarged. The vote cards use two lines for readable names and characters.

Discussion is 45 seconds. A dedicated 3.2-second TIME TO VOTE presentation precedes a full 20-second voting phase. The elimination reveal uses full-screen background artwork. Private role cards remain revealed for five seconds after the shuffle, without a second countdown.

Sleeping players can walk while remaining unable to do tasks, inspect clues, chat or vote. Their sprites remain upright and animate movement. Input updates are throttled; stop messages are reliable and sequence numbers prevent old movement packets from restarting a stopped character. Player physics bodies no longer collide with each other.

Online waiting rooms show a two-minute timer. Find Match sends later arrivals to the same waiting room. At expiry the room fills to ten. One real player receives nine bots. With fewer than five people, bots participate in roles, tasks and voting and can call meetings at the gong. Their names include Malay, Indian and Chinese names. Bot behavior is basic testing AI. A ready group of at least five humans can still start early. The offline practice entry retains its shorter practice flow.

The host leaving ends the room for everybody, with a GAME ENDED message; there is no host migration.

Validation: 19 LAN transport checks, 20 WebSocket checks, 12 phone UI/role-timing checks, and 1516 shared rule checks passed. Phone HUD, vote introduction and full-screen reveal were rendered for visual review. Physical-device and public-server latency testing remain necessary. Some older validation scripts retain assertions for the previous matchmaking, host-migration and sleeping behavior and have not been migrated.

Deploy the updated render-server folder and rebuild all client APKs together. Health protocol is now lobby_protocol=4, preventing clients from silently connecting to a server with incompatible movement RPCs. No deployment or APK build was performed here.

Pending: the user will provide a screenshot of the marked-character issue.
