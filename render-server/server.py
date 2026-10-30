"""HTTP health endpoint and streaming WebSocket gateway for the Godot server.

Render terminates HTTPS/WSS; the Godot listener stays on loopback. No external
Python packages are required. A failed child exits the service for Render to restart.
"""
import asyncio
import contextlib
import os
from pathlib import Path
import signal
import sys

GAME_PORT = int(os.environ.get("GAME_PORT", "7000"))
PUBLIC_PORT = int(os.environ.get("PORT", "10000"))
MAX_CONNECTIONS = 120
active = 0


async def reply(writer, status, body):
    data = body.encode()
    writer.write((f"HTTP/1.1 {status}\r\nContent-Type: text/plain\r\n"
                  f"Content-Length: {len(data)}\r\nConnection: close\r\n\r\n").encode() + data)
    await writer.drain()


async def pipe(reader, writer):
    while data := await reader.read(65536):
        writer.write(data)
        await writer.drain()


async def handle(reader, writer):
    global active
    upstream = None
    counted = False
    try:
        header = await asyncio.wait_for(reader.readuntil(b"\r\n\r\n"), 10)
        if len(header) > 16384:
            await reply(writer, "431 Request Header Fields Too Large", "Header too large\n")
            return
        lines = header.decode("latin-1").split("\r\n")
        method, path, _version = lines[0].split(" ", 2)
        headers = {}
        for line in lines[1:]:
            if ":" in line:
                key, value = line.split(":", 1)
                headers[key.lower()] = value.strip().lower()
        if method == "GET" and path in ("/", "/healthz"):
            try:
                _r, probe = await asyncio.wait_for(asyncio.open_connection("127.0.0.1", GAME_PORT), 2)
                probe.close()
                await probe.wait_closed()
            except OSError:
                await reply(writer, "503 Service Unavailable", "Game server starting\n")
                return
            await reply(writer, "200 OK", "Nenek Kebayan server ready\nlobby_protocol=4\n")
            return
        if method != "GET" or path.split("?", 1)[0] != "/ws" or headers.get("upgrade") != "websocket":
            await reply(writer, "404 Not Found", "Use /healthz or /ws\n")
            return
        if active >= MAX_CONNECTIONS:
            await reply(writer, "503 Service Unavailable", "Server full\n")
            return
        active += 1
        counted = True
        remote, upstream = await asyncio.wait_for(asyncio.open_connection("127.0.0.1", GAME_PORT), 5)
        upstream.write(header)
        await upstream.drain()
        tasks = [asyncio.create_task(pipe(reader, upstream)), asyncio.create_task(pipe(remote, writer))]
        try:
            await asyncio.wait(tasks, return_when=asyncio.FIRST_COMPLETED)
        finally:
            for task in tasks:
                task.cancel()
            await asyncio.gather(*tasks, return_exceptions=True)
    except (OSError, ValueError, asyncio.TimeoutError, asyncio.IncompleteReadError, asyncio.LimitOverrunError):
        pass
    finally:
        if counted:
            active -= 1
        for connection in (upstream, writer):
            if connection:
                connection.close()
                with contextlib.suppress(OSError):
                    await connection.wait_closed()


async def main():
    child = None
    if "--proxy-only" not in sys.argv:
        project = Path(__file__).resolve().parent
        child = await asyncio.create_subprocess_exec(
            os.environ.get("GODOT_EXECUTABLE", "godot"), "--headless", "--path", str(project),
            "res://scenes/server.tscn", "--", "--server", "--websocket", "--port", str(GAME_PORT))
    stop = asyncio.Event()
    loop = asyncio.get_running_loop()
    for sig in (signal.SIGINT, signal.SIGTERM):
        with contextlib.suppress(NotImplementedError):
            loop.add_signal_handler(sig, stop.set)
    server = await asyncio.start_server(handle, "0.0.0.0", PUBLIC_PORT, limit=16384)
    print(f"HTTP/WebSocket gateway listening on 0.0.0.0:{PUBLIC_PORT}", flush=True)
    tasks = [asyncio.create_task(stop.wait())]
    if child:
        tasks.append(asyncio.create_task(child.wait()))
    try:
        async with server:
            await asyncio.wait(tasks, return_when=asyncio.FIRST_COMPLETED)
    finally:
        for task in tasks:
            task.cancel()
        await asyncio.gather(*tasks, return_exceptions=True)
        if child and child.returncode is None:
            child.terminate()
            try:
                await asyncio.wait_for(child.wait(), 5)
            except asyncio.TimeoutError:
                child.kill()
                await child.wait()
    if child and child.returncode not in (None, 0, -signal.SIGTERM):
        raise SystemExit(child.returncode or 1)


if __name__ == "__main__":
    asyncio.run(main())
