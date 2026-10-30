# Realistic village task art and animation

All twelve playable task boards now use generated, textured props on a timber
worktable. The artwork follows the existing village setting: worn stone,
terracotta, batik, brass, glass, pandan leaves and fishing cord.

| Task | Animated feedback |
| --- | --- |
| Cook rice | Rising steam, pouring grains/water, fire under the pot |
| Light a wood fire | Flint impact, sparks and growing flame |
| Sweep the floor | Broom movement, drifting dust and debris feedback |
| Hang the laundry | Cloth follows the pointer, sways on the line and settles after placement |
| Find the flowers | Leaves sway and picked jasmine rises and fades |
| Shoot marbles | Glass marble rotates while rolling; landing feedback preserves the existing physics |
| Repair the lamp | Flexible wires, connection sparks and lantern glow |
| Arrange the shoes | Lifted shoe shadow and a short easing movement into each slot |
| Pound the herbs | Separate ingredients, moving stone pestle and herb dust on every strike |
| Water the plants | Pouring can, falling droplets, ripples and gently moving seedlings |
| Weave a pandan mat | Textured pandan strips slide into their numbered rows |
| Mend the fishing net | Moving cord, curved rope and tightening knot rings |

`scripts/task_realistic_art.gd` draws the image props and effects. The existing
`scripts/task_minigame.gd` retains hit targets, progress rules, mouse/touch
ownership and the server acknowledgement gate. Animation advances using elapsed
time; it never submits additional progress. Effects survive an acknowledgement
and expire automatically. Closing a task removes its board and visual effects.
The footwear board uses a transparent traditional-footwear atlas while retaining its alpha hit tests.

Artwork is stored in `assets/tasks/realistic/`. The final prop atlas is a
1536×1024 transparent image with six columns and four rows. A few authored crop
regions exclude neighboring sprite tips. `generation_prompts.json` records the
exact prompts and identifies the built-in image generation tool used. The first
atlas is kept as a source version; gameplay uses `village_props_v2.png`.
The separate `hanging_batik.png` provides ivory fabric that can be tinted to
match each laundry target while preserving its folds and printed pattern.

Validation:

```powershell
godot --headless --path . --script res://tests/village_tasks_validation.gd
godot --headless --path . --script res://tests/task_animation_validation.gd
godot --path . --rendering-method gl_compatibility --script res://tests/task_realistic_preview.gd
```

The preview renders all twelve boards plus four action frames per task into
`tmp/task-art-preview/`. The contact sheet uses a dedicated 792×382 viewport for
each board, independently of the game window's scaling settings.

Checked on Windows with Godot 4.7.2 and the OpenGL compatibility renderer.
Physical phone performance has not been measured.

Final validation: 640 task checks and 136 animation checks passed. All twelve boards and 48 action frames rendered successfully. The shareable contact sheet is saved at `output/task-art/task-overview.png`.

Traditional footwear update: blue wooden terompah, yellow capal, red embroidered slipper and green woven sandal now replace the modern footwear. `traditional_footwear.png` stores the generated two-by-two atlas. All 41 footwear interaction checks pass for mouse and touch. `output/task-art/traditional-footwear.png` shows the updated board.

Map task stations now use the same realistic artwork, with a black silhouette outline of approximately 1.8 world pixels. All twelve objects accept mouse clicks and touch input while retaining the existing proximity, open-path, role and modal checks. Map props use isolated cached textures so outlines cannot pick up adjacent atlas cells. Validation passed 676 task checks, including station-to-task click/touch routing on all three maps. Preview: `output/task-art/realistic-map-stations.png`.
