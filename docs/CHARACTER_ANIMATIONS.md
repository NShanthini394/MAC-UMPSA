# Reference character walking animations

All ten selectable characters use replacement artwork based on the ten PNG
reference boards supplied on 29 October 2026. Each has a front, rear, and side
standing pose plus four walking frames in each of those directions. Left-facing
movement mirrors the right-facing art. Walks play at eight frames per second.

Select any character normally in the lobby, then move with WASD/arrows or the
on-screen joystick. The selected appearance is used for both local and remote
players. Stopping keeps the last facing direction in a standing pose; sleeping
stops playback. The existing role, reservation, movement, and collision rules
are preserved.

## Shipped assets

All paths below are under `assets/characters/animated/`:

| Character | Sprite atlas |
| --- | --- |
| Puteri Gunung Ledang | `puteri_gunung_ledang.png` |
| Pak Kaduk | `pak_kaduk.png` |
| Badang | `badang.png` |
| Mahsuri | `mahsuri.png` |
| Pak Pandir | `pak_pandir.png` |
| Bawang Putih | `bawang_putih.png` |
| Bawang Merah | `bawang_merah.png` |
| Raja Bersiung | `raja_bersiung.png` |
| Orang Kampung Lelaki | `orang_kampung_lelaki.png` |
| Orang Kampung Perempuan | `orang_kampung_perempuan.png` |

Each atlas has a corresponding `<name>.tres` SpriteFrames resource,
`<name>_portrait.tres`, and `<name>_avatar.tres`. Standing and walking poses share
the same transparent atlas. The artwork includes the reference companions where
present. NPCs using these character appearances share the same rendering code.

The built-in imagegen tool produced the RGBA PNGs. Exact final prompts, identity
references, selected generation outputs, and the one checked gutter override
are recorded in [character-sprite-prompts.json](character-sprite-prompts.json).

`tools/build_character_animations.py` reads alpha silhouettes to locate individual
poses and generate the Godot resources. It writes region/margin metadata only;
it never changes the generated PNG pixels. Normalized margins align each main
character's feet and scale across poses, including frames with companions.
Its inspection output is `assets/characters/animated/atlas-inspection.json`.

## Validation and previews

```powershell
godot --headless --path . --script res://tests/cast_animation_validation.gd
godot --headless --path . --script res://tests/cast_network_animation_validation.gd
```

The first covers all ten animation resources, transparency, moving leg/hem
pixels, frame looping, facing, idle and sleeping behavior, updated portraits,
selected local/remote appearances, and actual physics/network-driven controls.
The second runs five full app clients against a localhost ENet server, checking
all 25 actor views and walking/standing transitions from real server movement.

`tests/cast_walk_preview.tscn` renders two cast galleries, alternate animation
frames, gameplay, and the updated character-selection screen into
`.godot/page-previews/cast_*.png`, then closes automatically.

Verified results: 433 character checks and 29 multiplayer integration checks,
all passing. Phone exports and physical phone testing remain separate steps.
