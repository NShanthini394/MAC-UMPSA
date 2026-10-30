# Shared village chores and parchment map

All three maps use the same twelve Orang Kampung tasks, defined once in
`scripts/game_data.gd`. Cooking and lighting firewood are independent tasks;
neither requires completion of the other. Nenek Kebayan cannot complete them.

| Task | Interaction | Steps |
| --- | --- | --- |
| Masak nasi | Put rice and water into the pot, then lift it during the green cooking window | 3 |
| Nyalakan kayu api | Place kindling, add logs, then tap the flint five times | 3 |
| Sapu sampah | Swipe through five patches of dirt | 5 |
| Sidai kain | Drag four cloths to matching places on a clothesline | 4 |
| Cari bunga | Find five flowers partially hidden among leaves | 5 |
| Masukkan guli dalam bulatan | Pull back to aim and set strength, release, and land four rolling marbles fully inside the circle | 4 |
| Baiki lampu | Join three matching colored, lettered wire ends | 3 |
| Susun selipar | Match four left slippers to their right partners | 4 |
| Tumbuk herba | Add ginger, turmeric and leaves, then pound five times | 4 |
| Siram tanaman | Move the watering can to each of four dry plants | 4 |
| Anyam tikar pandan | Place four pandan strips in matching numbered rows | 4 |
| Baiki jala | Join four loose cords to matching numbered knots | 4 |

The boards support mouse and touch dragging. Object placement also supports
tapping the source and then its target, except the shooting game. Sweeping
requires an actual stroke; cooking requires the timing window. Wrong actions do
not advance progress.
Input waits for server acknowledgement after each successful LAN step, and
finger releases are still tracked while waiting. Reopening a board resumes its
acknowledged stage. Completing all twelve tasks wins the match for the villagers.

### Guli shooting

`scripts/marble_shot.gd` shares one friction calculation between aiming and
motion. Pulling backward changes launch direction and strength; releasing sends
the marble rolling from the pulled position. A green arrow and endpoint preview
indicate a landing wholly inside the circle, while red indicates a miss. A shot
passing through the circle but stopping outside earns no mark. A tap, dragging
directly into the circle, or a partially overlapping marble also earns none.
Misses can be retried; four settled landings complete the task. There is no cue
stick. Mouse and touch use the same gesture, and scoring waits for the shot to
finish before sending a LAN progress update.

## Locations

Each map places its twelve tasks at distinct stations in suitable rooms and outdoor sections. The precise clear
floor coordinates and assigned section IDs are in `scripts/map_layouts.gd`.
The kitchen location is next to the stove, outside its collision footprint.
Added station symbols identify the relevant activity without blocking paths.

| Task | Palace | Pak Kaduk homestead | Mahsuri coastal house |
| --- | --- | --- | --- |
| Masak nasi | Dapur | Dapur | Dapur, near the stove |
| Nyalakan kayu api | Taman Timur, southern paved corner | Reban Ayam yard | Laman belakang approach |
| Sapu sampah | Balairung Takhta | Ruang Keluarga | Ruang Tamu |
| Sidai kain | Taman Timur, sunny northern walkway | Perigi dan Halaman Timur | Upper pier |
| Cari bunga | Taman Barat, pavilion steps | Kebun | Halaman dan Kebun |
| Masukkan guli dalam bulatan | Dewan Makan, clear floor | Ruang Makan | Open front/east yard |
| Baiki lampu | Bilik Senjata | Bilik Tidur | Bilik Tidur |
| Susun kasut | Lobi | Serambi | Front stairs |
| Tumbuk herba | Dapur, separate preparation corner | Dapur | Dapur, preparation corner |
| Siram tanaman | Taman Barat, garden walkway | Kebun | Garden edge, west of front stairs |
| Anyam tikar | Bilik Tetamu, clear floor | Serambi | Serambi |
| Baiki jala | Taman Barat, walkway beside the pond | East yard | Lower pier |

Local and server task interactions check range and the clear path to a station,
including locked doors. The nearby-task card, task list, guide routes, station
symbols, and map markers use the same task coordinates and completion state.

## Map view

The map button opens a parchment, timber, brass, and garden-green floor plan.
Only this view changes: source artwork and gameplay floor collisions stay intact.
`scripts/floor_map_canvas.gd` draws the existing floor polygons, wall edges,
furniture footprints, room names, and actual door thresholds. It does not invent
connections from the visual reference image. A russet arrow marks the local
player; numbered task markers become green checks when completed.

PETA shows the legend and the selected task's number, wrapped name, and section.
TUGAS lists the twelve chores without repeating selection details or highlighting
a selected number. The instruction reads "Pilih nombor tugasan untuk melihat
lokasinya:"; the old "Seret peta" sentence has been removed. Long names and
section names occupy separate aligned rows.

TUNJUK LALUAN appears only on PETA after choosing a task. It is optional guidance:
it returns to gameplay and draws a safe walking path to that task. Players can
complete tasks without it. The plan still supports dragging to pan, wheel or
+ / − zoom, and MUAT to reset. Opening the map stops player input and hides the
three utility icons so they cannot overlap the map or its close button. The icons
return when the map closes. Room-entry notices remain removed from gameplay.

## Waiting room

The 15-second explanation appears once in a permanent label beneath ARE YOU
READY?, with no duplicate hover tooltip. The existing readiness, cancellation,
minimum-player rule, and 15-second countdown are unchanged.

## Validation (Godot 4.7.2, Windows, 2026-10-29)

```powershell
godot --headless --path . --script res://tests/village_tasks_validation.gd
godot --headless --path . --script res://tests/marble_map_validation.gd
godot --headless --path . --script res://tests/map_floor_validation.gd
godot --headless --path . --script res://tests/task_guidance_validation.gd
godot --headless --path . --script res://tests/movement_lobby_validation.gd
godot --headless --path . --script res://tests/village_network_validation.gd
```

- Village tasks: 435 checks, zero failures, including all mouse/touch stages,
  delayed acknowledgements, one task per section, all three offline victories,
  waiting text, and map interaction.
- Marble shots and map UI: 263 checks, zero failures. Covers predicted versus
  actual landings at 30/60/144 fps, aim/power mistakes, partial overlaps, rolling
  input, four marks, tab contents, wording, wrapping, and icon restoration.
- Floor plans: 527 checks, zero failures, including all new task locations.
- Nearby guidance: 158 checks, zero failures.
- Movement and lobby: 199 checks, zero failures.
- Five-player LAN: 58 checks, zero failures, including real client board input,
  all eight shared tasks, and victory on all clients.

`tests/village_tasks_preview.tscn` renders all three parchment maps, twelve task
boards, and the waiting instruction into `.godot/page-previews/`.
`tests/marble_map_preview.tscn` captures clean task/PETA tabs, green and red aiming
previews, and a rolling shot.
Touch events were tested on Windows; physical phone builds remain untested.

## Additional village tasks (2026-10-30)

All maps now have twelve tasks. The four added boards share the existing mouse, touch, tap-to-place, progress and server acknowledgement rules. The HUD and map task lists scroll to reach every entry. Herbs are prepared in the kitchen; plants are watered in the garden; mats are woven in the guest room or veranda; nets are repaired in the armoury, east yard or pier. The standalone render-server task data and map placements are synchronized; an existing hosted server requires deployment of these updated files.

Validation: village task checks cover all twelve boards, collision clearance, map entries, HUD expand/collapse and offline victory on all three maps.

## Palace and Mahsuri placement review (2026-10-30)

Both maps include all twelve playable tasks with realistic outlined station props. Locations were reviewed against the actual map artwork and synchronized to the standalone server package. All 712 task checks passed, including player clearance, assigned sections, routes from spawn, click/touch station selection and offline completion on all maps. Nearby guidance passed 229 checks. Placement previews are saved in `output/task-art/task-locations-istana.png` and `output/task-art/task-locations-mahsuri.png`. Hosted servers must run the updated map data to use the new authoritative locations.
