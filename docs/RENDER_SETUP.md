# Nenek Kebayan server: v0.16 / protocol 7

Upload this complete generated `render-server` folder to the existing GitHub
repository and let Render deploy it BEFORE testing online with the v0.16 APK.
All players need the matching APK. Older versions use incompatible lobby rules.
Solo vs Bots runs locally and does not require the Render update or internet.

## Render settings

- Repository: MAC-UMPSA, branch main
- Root Directory: render-server
- Language: Docker; Dockerfile Path: ./Dockerfile; Docker Command: blank
- Region: Singapore; Compute: Free
- Health Check Path: /healthz
- No database or additional environment variables are required.

Open https://nenek-kebayan-server.onrender.com/healthz after deployment.
It must show `Nenek Kebayan server ready` and `lobby_protocol=7`.
The APK uses wss://nenek-kebayan-server.onrender.com/ws.
The Python gateway handles HTTP health checks and forwards WebSockets to Godot
on internal port 7000. Render supplies HTTPS/WSS termination.

## Playing modes

Start Game opens Play with Friends, Solo vs Bots and Quick Match. Friends opens
Create Room / Join Room. Solo goes to map selection without a network form.
Main menu centre: Start Game, How to Play, Exit. Sign In / Log Out is in Settings.
No first-time tutorial or tutorial video is included in this update.

Private rooms require two humans and all guests Ready before the host can press
Start with Bots. There is no forced waiting timeout. Bots fill to ten immediately
when the host starts, followed by a five-second preparation countdown. Characters
and names lock during this countdown. Ready cannot be undone.

Quick Match places people in a public waiting room immediately. Search lasts
up to sixty seconds; joining people do not restart it. Ten ready humans start
early. At timeout even one human can start with the remaining slots filled by
bots, followed by the five-second preparation countdown. The search duration
excludes waking or connecting to the cloud service. Locked matches accept no
new players. Further searches enter another waiting room.

Solo uses the same authoritative game service locally on the Android device.
The human is a Villager with seven Villager bots and two Nenek bots. It needs
no internet or matchmaking wait. The player chooses a character in the lobby
and starts the five-second preparation countdown.

Every match has ten characters: eight Villagers and two Nenek Kebayan. Roles
are randomly assigned among humans and bots; one-human matches keep the human
a Villager, and two-human matches retain at least one human Villager. Bots use
ordinary Malay, Chinese and Indian names. Their hidden roles and AI memory are
removed from public rosters. The AI is rule-based, not human-equivalent chat.

Villager bots navigate to task stations and perform timed task steps. Nenek
bots pursue awake Villagers, cast Sleep Spell, and use fog or locks. Villager
bots can witness nearby visible spells and discuss them. Votes use observations
and public human nominations; an uninformed Villager bot may Skip. Bots cannot
perform tasks through walls and obey the same mapped walkable geometry.

Emergency meetings retain the gong sound/cinematic, 45-second discussion,
voting introduction, 20-second voting and seven-second reveal. Sleeping or
eliminated players cannot act or vote. Sleeping humans can still move. Villagers
win only after completing all twelve tasks AND eliminating both Nenek. Nenek
win when no awake Villagers remain. Host departure ends an active match for
all participants. A public waiting-room host may be replaced before play starts.

## Packaging and validation

Run `python tools/prepare_render_server.py` from the main project after changes.
It creates an allowlisted server package without artwork, Firebase configuration,
authentication tokens or APKs. Upload the folder itself, not its contents into
the main game's project root. Do not upload .godot caches.

Local UDP and WebSocket tests cover private readiness, two-person starts,
sixty-second public searches, five-second start countdowns, late-join rejection,
solo roles, ten-human early starts, bot tasks/powers/votes and host departure.
Movement simulations cover all three maps. Real Android devices and the deployed
Render endpoint must be checked after uploading this package.

The free Render service can sleep or restart; rooms are stored in memory and
will be lost. Avoid deploying during a match. Cold startup may take up to two
minutes before the sixty-second search begins. Check the service health path
if connection fails. Plain HTTP probes reaching the internal WebSocket listener
can produce Godot header errors; the health endpoint belongs to the public
Python gateway, not internal game port 7000.

## v0.16 changes

The preparation countdown is five seconds in Friends, Solo and Quick Match.
Quick Match still searches for sixty seconds before bot filling. Protocol 7
prevents connecting this APK to older ten-second servers. All three in-game
map viewers now use 3D cutaways; gameplay collision and walking paths are unchanged.
Purple panels use the dark brown map-selection palette. Settings has English
(default) and Malay language preferences; actual Malay translation awaits Huawei
ML Kit. Guest IDs are no longer shown, but internal profile identities remain.

## Previous changes

Bots coordinate unfinished tasks and reply to human chat on staggered schedules.
Confirmed Vote or Skip cannot be changed. Results begin when every eligible
awake human and bot has submitted; otherwise the 20-second deadline applies.
Settings is a full-screen page. Preferences remain local to each device.
