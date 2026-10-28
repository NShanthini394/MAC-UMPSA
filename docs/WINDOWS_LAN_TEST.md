NENEK KEBAYAN: SIAPA PENGKHIANAT? - WINDOWS WI-FI TEST

WHAT YOU NEED
- Windows 10/11 computers on the same private Wi-Fi, or Ethernet on the same router.
- This same game bundle on each computer. Extract the ZIP completely before playing.
- One computer stays on and runs the hosting game for the entire session.
- Five to ten player windows for a match. Extra windows on one computer are allowed for testing.
- No Google/Huawei login, paid server, or router port forwarding is needed for this LAN test.

HOST A ROOM
1. Double-click Play.cmd and choose Play as Guest.
2. Choose PLAY, select a map, enter your name, then choose HOST WI-FI ROOM.
3. If Windows asks, allow this game executable on Private networks.
4. Share the invitation's five-character room code and host Wi-Fi address.
5. Enter the waiting room. Keep this game open while friends play.

JOIN FROM ANOTHER COMPUTER
1. Extract the same bundle and double-click Play.cmd.
2. Choose Play as Guest, then JOIN ROOM.
3. Enter your name, the host's Wi-Fi address, and the room code.
4. Choose JOIN ROOM. Your public character is assigned automatically; CHOOSE CHARACTER lets you change it.
5. Everyone chooses READY. With at least five players, the room host chooses START GAME. Ten ready players start automatically.

FEWER THAN FIVE COMPUTERS
- Run extra copies of Play.cmd until there are five actual player windows.
- Extra windows on the HOST computer use 127.0.0.1 as the host address.
- OTHER computers use the host's Wi-Fi address, never 127.0.0.1.
- Host only one server per computer/port. All extra windows choose JOIN ROOM.

IF JOINING FAILS
- Check that the host has the game open, the network matches, and the room code is correct.
- On the host, run ipconfig in Command Prompt and read IPv4 Address under the active Wi-Fi/Ethernet adapter.
- If the invite lists multiple addresses (VPN/virtual adapters), use the active Wi-Fi/Ethernet IPv4 address.
- Allow KampungLegenda.exe (or Godot.exe in the editor) through Windows Defender Firewall on Private networks. The listener uses UDP port 7000. Do not turn the firewall off.
- Guest/public Wi-Fi can isolate devices. Use a private router network allowing device-to-device access.
- Room codes do not connect different internet connections automatically. Public internet hosting is a later step.

RULES AND LIMITS
- Exactly one random Nenek Kebayan per online match; the host is not forced into that role.
- Public lobby avatars stay public; secret roles are revealed privately.
- Jampi Tidur permanently sleeps a villager for that match. Fog lasts 20 seconds; door locking lasts 10 seconds.
- Offline practice remains available after map selection, with its existing Nenek testing override.
- If a room host player leaves but keeps the app open, a remaining player becomes room host. Closing the server-hosting app ends its connections.
- Guest identities are temporary. Account login and cross-device profile saving are not connected.

This is a private development bundle using the project's installed Godot executable and an exported game resource pack. It is not a signed public release or an installer. Keep its files together. Other PCs do not need Godot installed.

Engine: Godot Engine, MIT license. Copyright (c) 2014-present Godot Engine contributors; Copyright (c) 2007-2014 Juan Linietsky, Ariel Manzur. License and third-party notices: https://godotengine.org/license/
