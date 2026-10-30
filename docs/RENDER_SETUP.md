# Nenek Kebayan Render test server

This folder contains the authoritative Godot server, geometry and content data.
It excludes Firebase configuration, authentication tokens, artwork and Android builds.
Clients must use the updated WebSocket networking code; the previous APK uses LAN only.

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
   Expect `Nenek Kebayan server ready`.
7. Give the developer the exact Render HTTPS address. In the main game, set
   `network/online_server_url` to `wss://YOUR-SERVICE.onrender.com/ws`, then rebuild
   the APK. Do not guess this address from the requested service name.
8. Every player chooses **Internet (different networks)** when creating/joining.
   Guests enter only the five-character room code. Same Wi-Fi remains available.

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
`wss://nenek-kebayan-server.onrender.com/ws`. A real five-client public WSS test
passed creation/joining, private roles, the 15-second countdown and movement.
Android device and university-network testing is still required.

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
