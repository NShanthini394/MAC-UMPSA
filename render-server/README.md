# Nenek Kebayan Render test server

This folder contains the authoritative Godot server, geometry and content data.
It excludes Firebase configuration, authentication tokens, artwork and Android builds.
The v0.5 APK and this folder use lobby protocol 3. Update the server before
installing v0.5 on every player's device. Older APKs are incompatible with this
lobby update; create a fresh room after deployment.

## Deploy

1. Upload the complete `render-server` folder into the existing GitHub repository root.
   Upload the folder itself so GitHub shows `render-server/Dockerfile`.
   Do not replace the main game's root `project.godot` with this server project.
2. Render service: repository `MAC-UMPSA`, branch `main`, Language `Docker`,
   Region `Singapore` if available, Compute `Free`.
3. Set **Root Directory** to `render-server`. Dockerfile Path: `./Dockerfile`.
   Leave Docker Command blank: the Dockerfile supplies the command.
4. Under Advanced, set **Health Check Path** to `/healthz`.
   No environment variables or database are required. Remove any empty variable row.
5. Deploy. The build downloads the official Godot 4.7.2 Linux binary.
6. Once Live, open `https://YOUR-SERVICE.onrender.com/healthz`.
   Expect `Nenek Kebayan server ready` and `lobby_protocol=3` on separate lines.
7. Give the developer the exact Render HTTPS address. In the main game, set
   `network/online_server_url` to `wss://YOUR-SERVICE.onrender.com/ws`, then rebuild
   the APK. Do not guess this address from the requested service name.
8. Every player installs the matching v0.5 APK. Creating/joining automatically
   uses the online service on both shared Wi-Fi and different networks. Guests
   enter only the five-character room code. Every device needs internet access.
   Local broadcast networking is retained for developer tests, without a player
   network selector. Local-practice helpers are for developer checks only;
   there is no offline/practice option in the player menus.

## Waiting room

Each player can edit their own name in their card; press the keyboard's submit
button or tap outside to save. Name changes appear on all devices. Guests choose
a character, then press **ARE YOU READY?**. Ready cannot be undone and locks their
character. The host's **START** stays grey until the room has 5–10 players and all
guests are ready. It then turns green. Only the host starts the five-second
countdown. A departure cancels a pending countdown. Names and characters lock
during the countdown. The map is chosen before a private room is created.

Play now joins the public matchmaking queue. At least five real players must be
online and searching. A short three-second grouping window admits up to ten.
Searching players can also fill an existing public waiting room before its host
starts, including replacing someone who leaves. Private rooms never receive
strangers. There is no offline/practice button in the player flow; Keep Waiting stays in the
queue and the close button leaves it. Private Create Room / Join Code remains.

When the host presses Start, unused slots are filled to ten with server-controlled
walking companions. They use remaining characters and ordinary names. They do
not perform tasks, count toward the five-human minimum, or affect victory. They
abstain from voting; only active human votes and human Skips affect the result.
Bot status and roles are removed from public roster data, although movement and
lack of chat may still make companions recognizable. Both Nenek are humans.

The gong marker circle has been removed. An active player approaches the actual
gong and presses Interact: 3.2-second shared alarm and gong sound, 20-second chat,
10-second voting, then a seven-second synchronized reveal. Voting never ends
early. A unique leading player is eliminated only when their votes exceed Skip.
Ties and unanswered human votes produce Skip/no elimination. Spectators can
watch but cannot chat or vote. Villagers win only after all eight tasks AND both
Nenek are gone. Nenek win when no active human villagers remain. Six clues cover
the two hidden identities. The final result follows the reveal animation.

Render handles the public HTTPS certificate and WSS connection. The Python gateway
listens on `0.0.0.0:$PORT` (default 10000), forwards `/ws` to Godot on loopback
port 7000 and serves health checks only while the game listener is reachable.
If Godot exits, the container exits so Render can restart it.

## Testing and limits

Free instances sleep after 15 minutes with no inbound traffic. First connection
warms the server via HTTPS and can take up to two minutes. If connection fails,
retry. Room state is in memory; a restart, sleep or redeploy ends existing rooms.
This is a test/demo deployment, not guaranteed continuous hosting. Stay within
Render's free usage limits. Do not deploy changes during an active demonstration.
University networks can still block the service; test on the actual university
Wi-Fi and mobile data before the demonstration. Internet mode requires internet.

The server retains the current project's gameplay validation; adding WebSockets
does not add stronger verification of minigame input or a cloud save system.
Do not use this project demo as a paid competitive service without further work.

## Developer maintenance

Run `python tools/prepare_render_server.py` from the main project after changing
server logic, then upload the updated generated folder. Do not edit generated
copies independently. Do not upload `.godot` folders.
Docker Desktop is not installed on the development PC. Render built the Linux
image successfully on 2026-10-30. The deployed endpoint is
`https://nenek-kebayan-server.onrender.com`, with the game at
`wss://nenek-kebayan-server.onrender.com/ws`. A previous five-client public WSS test
passed creation/joining, private roles and movement. The user also confirmed
mobile-data and mixed university-Wi-Fi connections. Protocol 3 has passed local
five-client name, Ready, host Start, five-second countdown, gameplay and map
checks. Public testing of v0.5 must be repeated after uploading this folder and
installing the matching APKs.

## Understanding deployment logs

"Deploy succeeded / Live" means Render accepted the service's startup and health
check. It does not mean every subsequent incoming request is valid.
Godot's `Not enough response headers, got: 3, expected >= 4` message can be
reproduced by sending a plain HTTP GET directly to the internal game listener.
That listener expects a WebSocket upgrade. An automated port probe is a possible
source; the error alone does not identify the caller. Normal HTTP health checks
must target the public gateway on `$PORT` (10000) at `/healthz`, not game port 7000.
Repeated requests to the gateway health endpoint did not reproduce the message.
Do not suppress all Godot errors to hide it. If the health endpoint or real game
connections fail, inspect the current logs and the selected HTTP port.
