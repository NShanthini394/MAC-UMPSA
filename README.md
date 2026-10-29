# Nenek Kebayan: Siapa Pengkhianat?

Godot 4.7 landscape game with guest LAN multiplayer and offline practice.

## Windows / same Wi-Fi

Run `tools/build_windows_lan.ps1` to create `builds/KampungLegenda-Windows-LAN.zip`. Extract that bundle on every PC and launch `Play.cmd`. See [the full LAN guide](docs/WINDOWS_LAN_TEST.md).

Host: Guest -> Play -> map -> Host Wi-Fi Room. Friends: Guest -> Join Room -> room
code only. The game discovers the host automatically on the same Wi-Fi and uses
the embedded ENet server; no separate server or provider login is required.
Keep the host's game open. Windows may ask to allow the game on Private networks
(UDP 7000 for gameplay and 7001 for discovery). The project does not change
firewall rules. See the [code-only LAN guide](docs/CODE_ONLY_LAN.md).

Tap **Are you ready?** in the waiting room. Practice waits 15 seconds after
readiness. LAN rooms automatically count down for 15 seconds when at least five
players are all ready; changing to unready cancels the countdown for everyone.

Matches require 5-10 actual player windows. Extra windows on the host PC and
devices on the same network enter only the room code. Use the updated game on
every device. Public internet hosting is not configured; LAN codes do not connect
different internet networks.

## Development

All three maps use the supplied palace, homestead, and coastal artwork with
invisible floor blockers, visible entrance arrows, and connected rooms. See the
[map floor guide](docs/MAP_FLOORS.md) for the artwork mapping and validation.
Nearby unfinished tasks now show a direction arrow and task-name prompt; entering
a room no longer announces its section name.
All maps share eight interactive village chores, placed one per section. The map
button opens a parchment floor plan with rooms, doors, player position, task
markers, and zoom controls. See the [village tasks guide](docs/VILLAGE_TASKS.md).

The ten selectable characters now use the supplied reference designs with
directional standing and walking frames, portraits, and avatars. See the
[character animation guide](docs/CHARACTER_ANIMATIONS.md) for asset paths,
generation prompts, and focused animation/multiplayer validation.

Run scenes/main.tscn. Play leads to map selection, then host or offline practice. Online roles are randomized with exactly one Nenek Kebayan. The offline Nenek testing override remains enabled. Google/Huawei login and persistent accounts are not connected.

Movement/collisions, characters, readiness, permanent sleep, fog/locks, task progress, clues, meetings, votes and outcomes are server controlled. WASD/arrows or joystick move; E interacts. Sleeping villagers only watch nearby events.

Optional dedicated server (Godot on PATH):

```powershell
godot --headless --path . res://scenes/server.tscn -- --server --port 7000
```

## Validation

```powershell
godot --headless --path . --script res://tests/map_floor_validation.gd
godot --headless --path . --script res://tests/village_tasks_validation.gd
godot --headless --path . --script res://tests/movement_lobby_validation.gd
godot --headless --path . --script res://tests/village_network_validation.gd
godot --headless --path . --script res://tests/lan_discovery_validation.gd
godot --headless --path . --script res://tests/code_only_lan_validation.gd
```

These cover floor reachability, all eight mouse/touch mini-games, room placement,
map controls, movement, readiness, and five connected app clients completing all
shared chores through the village victory. Localhost checks do not prove that
physical phones or other computers can connect through Wi-Fi/firewall settings.

## Remaining release work

Firebase email/password registration, sign-in, reset password and sign-out are connected for testing. Google sign-in is included in the Android debug APK through Credential Manager. See [Firebase testing](docs/FIREBASE_TESTING.md) for PC and Android instructions and validation limits.

Physical multi-computer testing, public internet hosting, Huawei authentication and persistent profiles, Google sign-in on physical Android devices, iOS builds/device testing, production audio, security/load review, and signed public packaging remain separate release tasks.

[Godot networking documentation](https://docs.godotengine.org/en/4.7/tutorials/networking/high_level_multiplayer.html)
