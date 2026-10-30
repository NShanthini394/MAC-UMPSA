# Android 0.3 network and lobby update

Use Internet (recommended) on both devices for university Wi-Fi, even when
they share the same network. Internet mode is now the default when the cloud
server URL is configured. Local Wi-Fi / hotspot remains available for private
networks. If a room was created in Local mode, leave it and create a new Internet
room; the local room's code does not refer to a room on the cloud server.

Room updates previously cleared the entire waiting-room or character page and
waited one frame before rebuilding. Ready and character changes now update the
existing controls, retaining confirmation dialogs and the page background.
Page navigation detaches old content and builds the replacement in the same
call without waiting for a new frame. Audio and utility controls stay persistent.

Validation:
- Local two-client WebSocket UI: 21 checks passed, 43 rendered pages monitored,
  zero blank frames.
- Live Render two-client UI: 20 checks passed, 94 rendered pages monitored,
  zero blank frames; covers ready, character reservation, confirmation, departure.
- Five-player code-only LAN: 32 checks passed.
- Five-player gameplay, countdown, movement and all eight chores: 58 checks passed.
- Tablet touch, character page and role/game UI: 97 checks passed.

The campus network itself cannot be changed by the app. Actual university Wi-Fi
and physical Android device testing remains with the players.
No server protocol changed and no Render redeploy is needed for this APK update.
