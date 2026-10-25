# Kampung Legenda: Misteri Tiga Rumah

Godot 4.7 landscape project. The game is currently **offline-first**: Play opens map selection and selecting a map enters the local practice lobby. Join Room explains that online multiplayer is coming later. The ENet room code remains in the project but is not exposed in the player flow until it is ready.

## Run the client

Open the folder in Godot 4.7 or later and run `res://scenes/main.tscn` (F6/F5). Choose **Play**, select a map and character, then enter the local practice match. Online room creation and joining are intentionally unavailable from the game menus for now.

Controls: WASD/arrow keys or the on-screen joystick; E or INTERACT near tasks and the gong; INSPECT CLUE and CLUE JOURNAL for evidence.

## Run a local room server

With Godot on PATH, start the dedicated headless server from this project folder:

```powershell
godot --headless --path . -- --server --port 7000
```

Keep the server running. Start clients on the same computer with server address `127.0.0.1`. For a different device, use the host's LAN address. Internet play needs a publicly reachable server and UDP port 7000 allowed through its firewall/router. No public server is bundled or hosted by this repository.

Rooms use server-generated five-character codes, have a ten-player cap, reserve characters on the server, synchronize readiness and movement, privately assign one Nenek Kebayan role, and handle shared task progress, clue collection, meetings, votes, eliminations, and outcomes on the server. A room needs five players to start; at ten players it starts automatically when everyone is Ready.

## Assets and content

The supplied menu, map atlas, portraits, and character assets remain under `assets/`. The three maps, eleven visual characters, and eight task entries per map are currently defined in `scripts/game_data.gd`. Task content still comes from the existing project data: the referenced task PDF has not yet been supplied, so it has not been used to validate or replace those entries.

## Known limits / verification status

- A Godot executable/editor is not installed or discoverable in this workspace, so GDScript parsing, scene launch, and actual multi-client play have not been verified here.
- The ENet server and separate client flow are implemented for local/LAN testing, but no public endpoint is configured or tested.
- Gameplay uses the existing cropped composite map art and screen-space positions. There are no collision-backed connected paths, door transitions, or animated player sprites yet; online players use the supplied portrait assets as markers.
- Task challenges use the current choice prompts and shared counters. Unique minigame mechanics and the PDF's exact eight tasks per map remain pending the original task PDF.
- The waiting room has a synchronized 10-slot player list; avatar movement inside that lobby is not implemented.
- Android/iOS export presets, mobile device testing, and production audio are not included.

## Project layout

- `scenes/main.tscn` — unchanged game entry scene.
- `scenes/server.tscn` — additive headless room-server scene.
- `scripts/main.gd` — existing screen flow with network UI integration.
- `scripts/network_manager.gd` — ENet room authority and RPC handlers.
- `scripts/game_data.gd`, `scripts/game_ui.gd`, `scripts/game_screen.gd` — shared content and modular UI/gameplay helpers.
