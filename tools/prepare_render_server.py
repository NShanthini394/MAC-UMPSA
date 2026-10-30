"""Produce an allowlisted, standalone server folder for uploading to GitHub."""
from pathlib import Path
import shutil

ROOT = Path(__file__).resolve().parents[1]
DEST = ROOT / "render-server"
SCRIPTS = ("server_runner", "network_manager", "game_data", "map_geometry",
           "map_layouts", "floor_plan", "nenek_powers", "lan_discovery")


def main():
    DEST.mkdir(exist_ok=True)
    # Fail closed if unrelated files were added: never accidentally publish them.
    allowed = {"Dockerfile", "project.godot", "server.py", "README.md", ".dockerignore"}
    allowed |= {f"scripts/{name}.gd" for name in SCRIPTS}
    allowed.add("scenes/server.tscn")
    for path in DEST.rglob("*"):
        if path.is_file() and ".godot" not in path.relative_to(DEST).parts:
            if path.relative_to(DEST).as_posix() not in allowed:
                raise RuntimeError(f"Unexpected file in server upload: {path}")
    for name in ("Dockerfile", "project.godot", "server.py"):
        shutil.copyfile(ROOT / "deploy/render" / name, DEST / name)
    for name in SCRIPTS:
        target = DEST / f"scripts/{name}.gd"
        target.parent.mkdir(exist_ok=True)
        shutil.copyfile(ROOT / f"scripts/{name}.gd", target)
    (DEST / "scenes").mkdir(exist_ok=True)
    shutil.copyfile(ROOT / "scenes/server.tscn", DEST / "scenes/server.tscn")
    (DEST / ".dockerignore").write_text(".godot\n.git\n__pycache__\n*.pyc\n", encoding="utf-8")
    shutil.copyfile(ROOT / "docs/RENDER_SETUP.md", DEST / "README.md")
    print(f"Prepared {DEST}: {sum(p.stat().st_size for p in DEST.rglob('*') if p.is_file())} bytes")


if __name__ == "__main__":
    main()
