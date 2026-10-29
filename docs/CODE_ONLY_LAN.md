# Joining a Wi-Fi room with its code

Host and joining devices must run the updated native game on the same local
network. The host chooses HOST WI-FI ROOM and shares the five-character code.
Friends choose JOIN ROOM, enter their name and that code, and join. There is no
Wi-Fi address field. COPY ROOM CODE copies just the code, and the waiting-room
footer no longer asks players to share addresses.

The embedded game server, five-to-ten-player rule, secret roles, readiness,
15-second countdown, movement, and task completion remain the existing systems.
Discovery is a way to locate the server, not a replacement for its admission
checks. Full or started rooms are still rejected by the authoritative server.

## Discovery flow

`scripts/lan_discovery.gd` uses JSON UDP requests and unicast replies. A joining
client sends only its requested code and a fresh random request token. The host
answers only for a room that currently exists. The client uses the reply's
source address and validated game port to make the ordinary ENet connection.
No internet service, remote directory, or IP-range scan is involved.

- Game traffic remains UDP 7000 by default.
- Lookup uses UDP 7001, configurable as `network/discovery_port`.
- Clients bind ephemeral reply ports so several games can join from one device.
- Broadcast queries are sent from the default socket and each local IPv4
  interface, avoiding a fixed subnet assumption. A loopback query also supports
  multiple test windows on one computer.
- Searches retry every 450 ms, with a six-second timeout. A short response
  collection window deduplicates interfaces belonging to one host and reports
  multiple responding hosts using the same code instead of choosing randomly.
- Reply tokens, code, protocol version, source port, and destination game port
  are checked. Messages are size-limited JSON; malformed messages are ignored.
- Cancelling, retrying, leaving the room, or closing the app releases search
  sockets. Closing the embedded host also closes its discovery listener.
- Started rooms still reply to lookup so users get the real "Game Already
  Started" response instead of a misleading room-not-found timeout.

`NetworkManager.join_room(code, name)` is the code-only path. The explicit-address
overload remains available to development tools and older direct-connection
tests. Player-facing forms always use discovery.

## Network and phone checks

The local network must allow broadcasts and device-to-device game traffic.
Guest Wi-Fi, AP isolation, some VPN configurations, and firewall rules can block
discovery. On Windows, allow the game on Private networks when prompted. A
custom port-based firewall needs both game and discovery UDP traffic. The game
does not change firewall rules or router settings.

Use the updated game on both host and guests: an older host will not answer the
new lookup protocol. This feature is for a shared IPv4 LAN, not different
internet connections or browser exports. Native phone exports and their local
network permissions must be set up before testing on devices. Godot specifically
requires Android's INTERNET permission for network communication, including
local UDP ([Godot PacketPeerUDP documentation](https://docs.godotengine.org/en/stable/classes/class_packetpeerudp.html)).

Physical Android/iOS phones and a separate-device Wi-Fi session have not been
tested here. The automated tests use real local sockets and actual broadcast
traffic on the Windows host; they do not prove a particular router's behavior.

## Validation (Godot 4.7.2, Windows, 2026-10-29)

```powershell
godot --headless --path . --script res://tests/lan_discovery_validation.gd
godot --headless --path . --script res://tests/code_only_lan_validation.gd
godot --headless --path . --script res://tests/village_network_validation.gd
```

- Discovery: 35 checks, zero failures. Includes real broadcast with loopback
  probing disabled, reply validation, code mismatch, cancellation, retry,
  collisions, listener shutdown, and malformed packets.
- Code-only app flow: 32 checks, zero failures. Includes five real game clients,
  UI without addresses, stale endpoint replacement, timeout/retry, cancellation,
  the ready countdown, gameplay, late joining, and host-loss recovery.
- Existing five-player gameplay: 58 checks, zero failures. Covers movement,
  animations, all eight shared tasks, and the village victory.

`tests/code_only_lan_preview.tscn` captures host setup, the code invitation, and
the address-free join form in `.godot/page-previews/`.
