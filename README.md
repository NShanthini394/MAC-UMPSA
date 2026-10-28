# Kampung Legenda: Misteri Tiga Rumah

Godot 4.7 landscape game with guest LAN multiplayer and offline practice.

## Windows / same Wi-Fi

Run `tools/build_windows_lan.ps1` to create `builds/KampungLegenda-Windows-LAN.zip`. Extract that bundle on every PC and launch `Play.cmd`. See [the full LAN guide](docs/WINDOWS_LAN_TEST.md).

Host: Guest -> Play -> map -> Host Wi-Fi Room. Friends: Guest -> Join Room -> host IPv4 address and room code. The game runs an embedded ENet server; no separate server process or provider login is required. Keep the hosting app open. Windows may ask to allow the executable on Private networks (UDP 7000). The project does not change firewall rules.

Matches require 5-10 actual player windows. Extra windows on the host PC can use 127.0.0.1. Other computers use the host's Wi-Fi/Ethernet address. Public internet hosting is not configured; LAN room codes alone cannot connect different networks.

## Development

Run scenes/main.tscn. Play leads to map selection, then host or offline practice. Online roles are randomized with exactly one Nenek Kebayan. The offline Nenek testing override remains enabled. Google/Huawei login and persistent accounts are not connected.

Movement/collisions, characters, readiness, permanent sleep, fog/locks, task progress, clues, meetings, votes and outcomes are server controlled. WASD/arrows or joystick move; E interacts. Sleeping villagers only watch nearby events.

Optional dedicated server (Godot on PATH):

```powershell
godot --headless --path . res://scenes/server.tscn -- --server --port 7000
```

## Validation

```powershell
godot --headless --path . --script res://tests/nenek_powers_validation.gd
godot --headless --path . --script res://tests/lan_multiplayer_validation.gd
```

The first covers game/power rules and five localhost clients. The second exercises complete app screens with the embedded host, retries, readiness, private roles, movement, fog, cancellation and host-loss recovery. tests/lan_process_smoke.gd also validates five separate game processes. Localhost checks do not prove that another physical computer can connect through Wi-Fi/firewall settings; use the bundle to perform that test.

## Remaining release work

Physical multi-computer testing, public internet hosting, provider authentication and persistent profiles, Android/iOS builds/device testing, production audio, final task content, security/load review, and signed public packaging remain separate release tasks.

[Godot networking documentation](https://docs.godotengine.org/en/4.7/tutorials/networking/high_level_multiplayer.html)
