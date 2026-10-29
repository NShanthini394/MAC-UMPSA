# Map artwork and movement boundaries

The three supplied images are used in gameplay, map selection, waiting-room
previews, and gameplay:

| Game map | Supplied image | Project asset |
| --- | --- | --- |
| Istana Puteri Gunung Ledang | Isometric Palace Gardens and Throne Hall.png | assets/maps/istana_puteri_gunung_ledang.png |
| Rumah Pak Kaduk | Cozy Wooden Homestead Diorama.png | assets/maps/rumah_pak_kaduk.png |
| Rumah Mahsuri | Tropical Coastal House Diorama.png | assets/maps/rumah_mahsuri.png |

The supplied PNGs are preserved unchanged. Visible added connections are drawn
over them in the game. Movement boundaries and furniture blockers are invisible
to players; green double arrows show entrances. There is no dark collision tint
or ambient darkening over the maps. The map button now opens a separate parchment
floor plan with room names, doors, numbered chores, and a russet player arrow.
See [the village tasks guide](VILLAGE_TASKS.md). Developers can explicitly enable
`debug_boundaries` on a gameplay paths visual to inspect collision outlines;
gameplay leaves it disabled.

## Floors and entrances

`scripts/map_layouts.gd` defines each map's floor areas, outdoor paths, furniture,
entrance thresholds, interaction locations, and visible connection patches.
Coordinates use the original 1448 × 1086 house images. Palace design coordinates
use 2048 × 683 and scale to the original 2172 × 724 image.

The floor union excludes roofs, water, walls, fences, garden beds, and enclosed
outbuildings. Room walls remain blocked except at the marked entrances. Furniture
uses its base footprint so players can move around it. Overlapping floor areas
have no collision seam between them.

Added connections, following the approved choice to make the main sections
reachable:

- Palace: two garden bridges and two connections between the lobby and the lower
  wings. Existing stairs connect the throne hall and upper rooms.
- Homestead: a family-room entrance and an opened front compound gate. Existing
  bedroom, kitchen, and front stairs remain usable.
- Coastal house: a wider front landing and dining-room entrance. Existing room
  stairs, front gate, and both pier approaches remain usable.

Roofed sheds and pavilions remain exterior scenery; players can approach them
without walking over their roofs.

`scripts/floor_plan.gd` derives the outer floor edges from these areas.
`scripts/map_geometry.gd` supplies the same clearance and wall checks to the
server and players. The game also creates physical collision segments along the
floor edges and solid furniture. Door locks use the actual entrance thresholds.
`scripts/map_navigation.gd` routes objective guidance through valid floor areas,
with full player clearance around corners and furniture.

Offline and server movement share `MapGeometry.move_position`. A rejected
diagonal selects one validated axis slide, preventing independently checked axes
from being combined into a move that clips an inside corner. Local physical
collision uses a centered circle matching the same 14-pixel clearance. Physics
does not apply another unchecked slide after the geometry chooses the motion.
Nearby old positions inside the clearance band can recover to valid floor on
the same side of walls and furniture.

## Nearby task guidance

Entering a section no longer announces a room name. The task arrow that
previously sat at the screen edge has been replaced by a passive HUD card built
by `scripts/nearby_task_hint.gd`. It displays "ADA TUGAS BERHAMPIRAN", the actual
unfinished task name, and a green direction arrow. Within interaction range it
explains to press INTERAKSI.

The card considers tasks within 220 world pixels and with a walkable route of
less than 280 pixels. Direction follows the first route waypoint through open
entrances. Completed, distant, and inaccessible tasks are excluded. It hides
during dialogs, maps, journals, minigames, meetings, sleep, and spectator mode.
Fog limits detection to the player's reduced sight range. The card does not
intercept movement or touch input. Small double arrows on the map continue to
mark entrances.

## Validation

Run with Godot 4.7.2 from the project directory:

```powershell
godot --headless --path . --script res://tests/map_floor_validation.gd
godot --headless --path . --script res://tests/movement_lobby_validation.gd
godot --headless --path . --script res://tests/task_guidance_validation.gd
godot --headless --path . --script res://tests/cast_animation_validation.gd
godot --headless --path . --script res://tests/cast_network_animation_validation.gd
```

Validated on 2026-10-29:

- Map floors: 527 checks, zero failures. Covers all maps, forbidden landmarks,
  wall crossing, doorway clearance and locks, actual character-body traversal,
  reachable objectives, ten distinct spawn positions per map, and safe guidance
  routes.
- Movement and lobby regressions: 199 checks, zero failures. Covers the reproduced
  corner freeze, recovery, actual joystick/physics movement on all three maps,
  invisible boundaries, and 15-second practice and server countdowns.
- Character animations: 433 checks, zero failures.
- Nearby task UI: 158 checks, zero failures. Covers all 24 task locations,
  directions, completion, proximity, kitchen entrance routing, locks, modal
  visibility, removal of section-entry notices, and centered Settings controls.
- Five-player local network match: 40 checks, zero failures. Covers countdown synchronization,
  cancellation, and real input at the reproduced inside corner.

`tests/map_floor_preview.tscn` captures path overviews, actual gameplay, and the
full-map UI in `.godot/page-previews/`. Files ending in `_floor_trace.png` are
diagnostic views only; their colored fills are absent from gameplay.
`tests/task_guidance_preview.tscn` captures the nearby-task prompts and centered
Leave Game button.

These checks ran on Windows. They do not establish connectivity or movement on
physical Android/iOS phones; those exports and device checks remain necessary.
