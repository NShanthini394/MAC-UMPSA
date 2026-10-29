# Menu and footwear artwork

The built-in imagegen tool was used for these project assets. The supplied originals are retained in Downloads; project files do not depend on Downloads or the generated-images cache.

## Saved assets

- `assets/ui/login_background.png`: copied from **Moonlit Temple Village by the Lake.png** supplied by the user.
- `assets/ui/main_menu_no_center_settings.png`: edited main-menu artwork with the centre Settings row removed. The top-right Settings icon remains.
- `assets/tasks/flip_flop.png`: isolated blue flip-flop.
- `assets/tasks/trainer.png`: isolated yellow trainer.
- `assets/tasks/slipper.png`: isolated red checked slipper.
- `assets/tasks/sandal.png`: isolated green strap sandal.

The footwear pieces are based on **Scattered Shoes on a Wooden Floor.png**. The game renders each type twice, mirrors the second shoe, scatters all eight on the left, and aligns matching pairs in four right-hand spaces labelled **Blue, Yellow, Red and Green**. Players match by colour. Only two correctly placed shoes of the same colour award one progress step. Four pairs complete the task. Touch dragging and tap-to-place use the same matching rules. Existing shared network progress remains four steps, with duplicate input blocked while awaiting acknowledgement.

## Final prompts

### Menu

Use case: precise-object-edit. Edit target: this game's existing main menu artwork. Remove ONLY the SETTINGS button from the centre vertical button stack below JOIN ROOM. Move HOW TO PLAY up into the old SETTINGS row, move EXIT up into the old HOW TO PLAY row. Fill the old bottom EXIT row with matching unobstructed wooden village decking/background. Preserve exact overall composition, aspect ratio, pixel-art style, all characters, Nenek Kebayan title/logo, subtitle, moon, village buildings and the three top-right icon buttons. Preserve PLAY, CREATE ROOM, JOIN ROOM exactly at their original positions. Preserve the original appearance and exact text/icons of HOW TO PLAY and EXIT as they are moved up one row. Final centre stack has exactly five buttons: PLAY, CREATE ROOM, JOIN ROOM, HOW TO PLAY, EXIT, in that order. No centre SETTINGS button. Do not change anything else.

### Footwear (four separate calls)

The following exact template was used with each subject listed below:

Use case: background-extraction. Create ONE isolated game sprite of **SUBJECT** from the attached footwear picture. Keep its exact design, colours, textures and 3D illustration style. Remove the wooden floor, every other shoe, every cast shadow and all other content. Only one complete shoe, centred vertically and horizontally on a square TRANSPARENT alpha canvas, toes toward the top. Use a nearly top-down view matching the reference. Fit the whole shoe within the central 65 percent of the canvas; clear transparent margin on all four sides. Clean tight opaque shoe edges, no coloured halo, no glow, no soft background, no shadow, no text. This is an individual draggable game piece.

Subjects:

1. the blue flip-flop
2. the yellow lace-up sneaker
3. the red checked fabric slipper
4. the olive green two-strap sandal

Earlier atlas drafts were discarded because their cell spacing and edges were unsuitable for independent game pieces.
