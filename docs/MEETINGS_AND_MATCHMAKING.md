# v0.5: two Nenek, gong meetings, and matchmaking

Both the Android APK (version code 5) and the generated Render server folder must
be updated together. `/healthz` must report `lobby_protocol=3`. Upload the whole
`render-server` folder to the GitHub repository root, wait for Render to become
Live, then install the matching APK on all devices and create a fresh room.

## Player flow

- Play searches the shared online queue. It groups 5–10 real people, with a short
  three-second grouping window after the fifth arrives. Searching players can
  also fill an existing public lobby before its host starts. With fewer people,
  Keep Waiting stays in the queue. Closing the page leaves the queue. There is no
  offline/practice alternative in the player menus.
- Create Room lets a private host choose a map. Friends use Join Room and a code.
- Guest Ready is permanent; the host starts the shared five-second countdown.
  Up to ten characters are present when play begins. Unused slots are walking
  companions, assigned unused character designs and ordinary display names.
- Exactly two real players receive Nenek roles. Server-only companion metadata
  and roles are not sent in public rosters. This does not guarantee companions
  will be indistinguishable from humans: they do not chat or do tasks.
- Companions do not affect the human minimum, task completion, vote tally or
  victory. They abstain instead of contributing an artificial Skip majority.
  They can still be selected as a voting target and can be put to sleep.

## Gong and meetings

The extra yellow circle is gone from all maps. The actual gong is approached
and activated through Interact by any active player, including a Nenek. The
server drives every phase: alarm (3.2 seconds), discussion (20 seconds), voting
(10 seconds), reveal (7 seconds), then gameplay or the final result.

All connected humans, including spectators, see the alarm and reveals. Active
humans can chat and vote once. Spectators only watch. Full voting time is kept
even when everyone submits early. A unique top candidate must beat the human
Skip count. Ties eliminate nobody. Unanswered human votes count as Skip.

The correct reveal dissolves the voted player's actual animated character into
Nenek through moving glow rings and sparks. The innocent reveal starts close,
then shows that character bowing and walking away down the path. Names and
remaining-Nenek messages are drawn dynamically rather than baked into a picture.

Villagers win only after all eight shared tasks AND both Nenek are eliminated.
Finding both first lets remaining villagers finish the chores. Completing tasks
first leaves the investigation active. Nenek win when no awake human villagers
remain. Walking companions cannot keep a lost match running. Six clues cover
both hidden character identities.

## Assets

Supplied originals are retained in `assets/meetings/emergency_meeting.png`,
`eliminate_nenek.png`, `eliminate_villager.png`, and `assets/audio/gong.mp3`.
The alarm uses the two clean strike poses from the storyboard, with a moving
red sweep and dynamic title. Storyboard numbering is not shown in the game.
The 54-second supplied gong recording plays from the start, then its tail fades
between 4.5 and 7 seconds to avoid covering the discussion or overlapping hits.

Two project assets were made using the built-in image generation tool and
saved in the project, based on the supplied reference storyboards:

- `assets/meetings/departure_background.png`: continuous, empty gate/path scene.
- `assets/meetings/nenek_reveal.png`: transparent full-body Nenek for the reveal.

Final background prompt:

> Use case: precise-object-edit. Project game asset: a single clean landscape background for an animated villager elimination scene. Input image is the supplied multi-panel storyboard 'Eliminate Orang Kampung.png'. Extract/recreate ONLY the setting in panel 8: front-facing view through a traditional Malay wooden gateway into a moonlit tropical village path, carved timber posts, warm hanging lanterns and torches, dense vegetation, low mist, deep blue night. Preserve the illustrated pixel-art game style, warm gold versus dark blue colours, and the central perspective from that panel. Fill one 16:9 landscape canvas, clear foreground floor where an animated character will be composited by the game. Remove ALL people, silhouettes, text, numbers, panel labels, grids, borders, UI and overlays. This must be one continuous empty environment, not a storyboard. No characters whatsoever. The archway and pathway should be visible centrally. No new narrative objects. Output just the clean background, no lettering.

Final Nenek prompt:

> Use case: background-extraction, identity-preserve. Game sprite asset. Input is the supplied Nenek Kebayan elimination storyboard. Isolate just the SAME frightening grey-haired Nenek Kebayan character shown in panels 3, 9 and 10. Create one clean full-body front-facing cutout for a magical transformation animation, centered upright, sinister slight forward lean, arms loosely raised with long fingers. Preserve her elderly wrinkled face, glowing red eyes, long flowing silver-grey hair, tiny gold floral crown, maroon/dark patterned traditional clothing, pixel-art illustrated game aesthetic and warm red rim light. No gore. Match the storyboard identity closely. Include whole figure and feet with a little clear margin around all hair and fingers. True transparent background. Remove all scene backgrounds, red smoke clouds, text, captions, numbers, panel frames, other people, inset panels and black disks. No lettering, no logo, no surrounding aura baked into the image; the game will add the magical glow itself. Output only a single transparent character cutout.

## Validation and limits

The focused tests exercise real local WebSocket clients, public queue grouping,
minimum-human enforcement, companion movement and geometry, two human Nenek,
role privacy, shared gong playback, natural discussion/voting deadlines, chat,
wrong and correct reveals, spectators and both victory requirements. Pure rule
tests cover ties, missing votes, Skip and companion-excluded victory. The eight
minigames are exercised through actual networked task input separately.

The prepared standalone server is checked through the same HTTP/WebSocket
gateway used on Render. Render's Linux build and physical Android/public-network
testing of v0.5 remain to be repeated after the user deploys and installs it.
This has not been load-tested for many concurrent rooms on Render Free. Queue
and match state remain in memory and end on a restart or redeploy.
