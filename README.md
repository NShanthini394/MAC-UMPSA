# Nenek Kebayan: Siapa Pengkhianat?

Godot 4.7 landscape Android game with online room-code multiplayer and offline practice.

## Multiplayer testing: v0.5

Upload the generated `render-server` folder to GitHub and wait for Render to
redeploy before installing `builds/OnlineTest/NenekKebayan.apk` on every device.
The server health endpoint must include `lobby_protocol=3`. See the
[Render setup guide](docs/RENDER_SETUP.md) for the exact settings.

Play -> Find Match automatically groups searching players once at least five
real people are available. Keep Waiting continues searching; there is no offline
practice option in the player flow.

Private host: Create Room -> choose map -> Create Room. Friends: Join Room -> code.
Creating and joining automatically use the online service on both shared Wi-Fi
and different networks. All devices need internet access; no network selector or
IP address is required. Walking companions fill unused character slots to ten once the host starts. They
do not count toward the five-real-player minimum or perform tasks.

In the waiting room, tap your own name to rename yourself. Guests choose a
character and press **Are you ready?** once; Ready and the character then lock.
With 5–10 players and all guests ready, the host's **Start** turns green. The host
starts a five-second countdown. A departure cancels the countdown. Maps are
selected before room creation. The two Nenek are always real people. Companions abstain from voting.

Approach the real gong and press Interact to call an emergency meeting. All
devices receive the supplied gong sound and animation, followed by 20 seconds of
chat, 10 seconds of voting, and a shared animated reveal. Skip, ties, and
unanswered votes do not eliminate a player. Eliminated humans become spectators.
Villagers must complete all eight tasks AND eliminate both Nenek to win.

The ENet and local-practice helpers remain for developer validation, without
player-facing offline/network selectors. The older LAN guides describe that
earlier flow.

## Development

All three maps use the updated palace, homestead, and coastal gong artwork with
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
