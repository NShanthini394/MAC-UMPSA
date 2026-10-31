# Nenek Kebayan: Siapa Pengkhianat?

Godot 4.7 landscape Android game with online room-code multiplayer and offline practice.

## Playing modes: v0.13

Main menu: Start Game, How to Play, Exit. Account sign-in/log-out is in Settings.
Start Game opens Play with Friends, Solo vs Bots and Quick Match.

- Friends: Create / Join a room code; at least two humans. The host can start as
  soon as guests are ready, with bots filling remaining slots. No timeout.
- Solo vs Bots: local game, no internet; one human Villager and nine bots.
- Quick Match: public search for up to sixty seconds, or earlier when ten humans
  are ready. Remaining spaces fill with bots, including when only one human waits.

Each match has ten characters: eight Villagers and two Nenek. A ten-second
preparation countdown follows bot filling. Locked matches accept no new joins.
Bots navigate the map, perform tasks, use powers, discuss observations and vote.
Villagers need all twelve tasks AND both Nenek eliminated to win.
Meetings retain 45-second chat and 20-second voting. Tutorial work is deferred.

Online changes require the matching **protocol 5 server** on Render and the
v0.13 APK on every device. Regenerate the server with
`python tools/prepare_render_server.py`; see [deployment steps](docs/RENDER_SETUP.md).
Solo works independently of the cloud service. No public deployment has been
performed automatically from this workspace.

## Palace map viewer

The Istana in-game map now uses an angled 3D cutaway with jade, blue, stone and
gold colours inside a original dark purple outer frame. Drag to rotate, use + / - to zoom, and FIT to restore the view.
The two house map viewers remain 2D. MAP / TASKS now highlights the selected tab
on all three maps. The chosen task row turns red on all maps and automatically opens MAP. SHOW ROUTE gently pulses to guide the player. Private role
cards retain their large fonts with separate text rows and a five-second display
whose final three seconds show 3, 2, 1. See [palace map viewer notes](docs/PALACE_MAP_VIEW.md).

## Account and main menu

Google and Huawei provider labels stay on one line at the intended font size.
The centre menu uses live gold-trimmed wood/red buttons with hover and press
feedback, matching Offline Practice and the login controls. Their text and icons
are separate from the background artwork.

## Development

All three maps use the updated palace, homestead, and coastal gong artwork with
invisible floor blockers, visible entrance arrows, and connected rooms. See the
[map floor guide](docs/MAP_FLOORS.md) for the artwork mapping and validation.
Nearby unfinished tasks now show a direction arrow and task-name prompt; entering
a room no longer announces its section name.
All maps share twelve interactive village chores, placed one per section. The map
button opens a parchment floor plan with rooms, doors, player position, task
markers, and zoom controls. See the [village tasks guide](docs/VILLAGE_TASKS.md).

The ten selectable characters now use the supplied reference designs with
directional standing and walking frames, portraits, and avatars. See the
[character animation guide](docs/CHARACTER_ANIMATIONS.md) for asset paths,
generation prompts, and focused animation/multiplayer validation.

Run scenes/main.tscn. Play leads to map selection, then host or offline practice. Online roles are randomized with exactly one Nenek Kebayan. Firebase email/password and Android Google sign-in are connected for testing. Huawei sign-in and persistent game profiles remain pending.

The viewport expands for landscape phone/tablet ratios. Menus keep their original
proportions and touch alignment, with scenery filling extra screen space. The
game world expands while the HUD stays inside a centered 1280×720 layout.

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
godot --headless --path . --script res://tests/meeting_matchmaking_validation.gd
godot --headless --path . --script res://tests/two_nenek_rules_validation.gd
godot --path . --script res://tests/responsive_v4_validation.gd
godot --path . --script res://tests/lobby_refresh_validation.gd
```

These cover floor reachability, all eight mouse/touch mini-games, room placement,
map controls, movement, readiness, and five connected app clients completing all
shared chores through the village victory. Localhost checks do not prove that
physical phones or other computers can connect through Wi-Fi/firewall settings.

See [meeting and matchmaking notes](docs/MEETINGS_AND_MATCHMAKING.md) for the
new rules, asset sources, and validation limits.

## Remaining release work

Firebase email/password registration, sign-in, reset password and sign-out are connected for testing. Google sign-in is included in the Android debug APK through Credential Manager. See [Firebase testing](docs/FIREBASE_TESTING.md) for PC and Android instructions and validation limits.

The user confirmed earlier APK connections on mobile data and mixed university
Wi-Fi/mobile data. Repeat physical Android testing with v0.5 after updating
Render and every APK. Huawei authentication, persistent profiles, iOS builds,
production audio, security/load review and signed public packaging remain
separate release tasks.

[Godot networking documentation](https://docs.godotengine.org/en/4.7/tutorials/networking/high_level_multiplayer.html)
