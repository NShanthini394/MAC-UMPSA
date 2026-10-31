# Palace map viewer update

Istana Puteri Gunung Ledang uses a real 3D cutaway inside the in-game map overlay.
The other two maps retain their 2D floor plans. All three viewers now use the original dark purple
outer frame with readable cream text and gold trim. The inner blue map surface, jade buttons, blue moat,
green gardens and pale stone walls retain their existing colours. Gameplay itself
is unchanged by this presentation update.

The model is built from the current floor polygons, merged boundaries, solids,
sections and doors in map_layouts.gd. Roofs are open so rooms remain visible.
Camera-projected player and task markers use the current gameplay coordinates.
All twelve tasks are retained. Nenek has no task markers or task list.

Drag the palace map to rotate its camera; use + / - or the mouse wheel to zoom.
FIT restores the default angle and zoom. Tap a task marker to choose its task;
choosing a task automatically opens MAP with its name, place and Show Route
action. Gameplay routes use dark charcoal on all three maps. A gentle gold glow and 3% scale pulse draw attention to Show Route. The
animation stops in TASKS or for completed/unavailable tasks. TASKS shows the
scrollable list. Selecting either tab updates its red highlight on all maps.
Task rows use equal widths/heights and allow two lines of text. In all three
viewers, the chosen task row turns red using the same style as the active tab;
other task rows keep their original jade-blue or wood style. Completion uses a check
mark and does not tint away the selected red. The palace retains its 3D model and the houses retain their 2D floor plans.

The 3D scene has an isolated SubViewport, uses shared primitive materials and
renders only when the map refreshes. Closing the overlay frees it. It never
changes game actors, collision geometry, movement, room rules or networking.

Validation: tests/palace_map_view_validation.gd exercises touch tabs on all three
maps, all twelve tasks, marker selection, player projection, completion updates,
Nenek restrictions, zoom, rotation and Fit, plus wide phone/tablet alignment.
Graphical captures are saved under .godot/page-previews/palace_*.png.
The current Android test APK uses version code 13 (0.13-play-modes). The map styling is retained; the playing-mode update requires server protocol 5.


## Private role card spacing and countdown

The shared private-role presentation is wider and has separate text rows for
the lobby pick, assigned character and instructions. The readable font sizes
are retained. All ten character designs are checked in both Villager and Nenek
roles at standard landscape, wide phone and tablet ratios. The portrait and
text column have separate space; the privacy note and countdown each have their
own row beneath the content.

After the card finishes flipping, it stays visible for five seconds. Players
have two seconds to read, then see Entering the village in 3, 2, 1, with the
matching tick sounds, before gameplay opens. Leaving the reveal cancels this
transition through the existing screen/card validity guards.

Focused verification: palace viewer 229 checks, role-card layout/timing 2618
checks and role audio 11 checks, all passing. Physical Android testing remains
the final device check. Server logic and protocol were not changed.

Route-flow validation: tests/map_route_flow_validation.gd checks task selection, automatic tab changes, glow/pulse lifecycle, completion updates and the actual route action on all three maps.
