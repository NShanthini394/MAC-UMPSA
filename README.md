# Kampung Legenda: Misteri Tiga Rumah

A Godot 4.7 mobile landscape folklore deduction game. The current build is an **offline practice game** with a complete menu-to-match loop, three folklore maps, selectable characters, task collection, separate identity clues, meetings, voting, and both role win paths.

## Run

Open this folder in Godot 4.7 or later and press **F6/F5**. The main scene is `res://scenes/main.tscn`.

Controls:

- Move with **WASD**, the **arrow keys**, or the on-screen directional pad.
- Press **E** or **INTERACT** near a task, villager, or the meeting gong.
- Use **INSPECT CLUE** near a glowing clue marker; the **CLUE JOURNAL** keeps evidence separate from task progress.
- Impostors also get an **ELIMINATE** action near a local suspect.

## Included in this build

- English interface text; Malay character and place names are preserved.
- Illustrated main menu, three map previews and cropped map backdrops from the supplied references.
- Eleven selectable character names. The selected visual character is kept separate from the randomly assigned practice role.
- Eight map-specific task chains per map. Collection tasks require the specified number of interactions, and other activities use a choice challenge.
- Three randomized identity clue markers tied to the Impostor's visual character. Clues do not count as tasks.
- Emergency meeting, suspect voting, task victory, and an Impostor elimination victory.
- Keyboard and on-screen movement controls in landscape layout.

## Supplied art

The project includes the menu art, palace/village map collections, and folklore character references under `assets/`. The large reference sheets are retained as source art; the current gameplay maps use cropped regions of the supplied composite map image. Characters in the practice map are simple interface markers, not animated sprite-sheet actors yet.

## Current limits

This is a local practice build, not the full online game described in the master prompt. It currently has no network room creation/joining, room codes, authoritative dedicated server, synchronized 5–10 player lobby, multiplayer movement, networked role secrecy, active NPC AI, real-time drag/timing mini-games, production collision map, audio, or export presets. The local suspects are used to exercise the task, clue, meeting, and elimination loop. Do not advertise online play as available until a reachable server and separate clients have been implemented and verified.

The game uses no external service or server. A public internet multiplayer release still needs a hosted authoritative Godot server, a public address, UDP port forwarding/firewall rules, and separate Android/iOS client testing. iOS export requires macOS and Xcode.

## Next implementation milestones

1. Add animated character actors and collision-backed tile/map scenes.
2. Implement interactive multi-step mini-games and clue inspection illustrations.
3. Add an authoritative ENet server with 5–10 player room codes, character reservations, synchronized movement, role privacy, meetings, votes, and disconnect handling.
4. Host the server on a reachable public endpoint; configure the clients and verify matches across separate networks.
5. Add original/licensed audio, Android export configuration, and iOS export instructions/build validation.

## Project layout

- `scenes/main.tscn` — game entry scene.
- `scripts/main.gd` — screen flow and local practice gameplay.
- `assets/ui/` — menu artwork.
- `assets/maps/` — supplied map reference images.
- `assets/characters/` — supplied character sprite/reference sheets.
