"""Inspect generated alpha silhouettes and author Godot atlas resources.

PNG pixels are never changed. This tool only reads the image alpha to write
AtlasTexture regions, aligned margins, SpriteFrames, and a QA report.
"""
from __future__ import annotations

import argparse
import json
from collections import deque
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
ASSETS = ROOT / "assets/characters/animated"
MANIFEST = ROOT / "docs/character-sprite-prompts.json"


def components(alpha: Image.Image, window: tuple[int, int, int, int], threshold=128):
    # Alpha threshold ignores near-transparent compression/antialias noise.
    mask = alpha.crop(window).point(lambda value: 1 if value >= threshold else 0)
    width, height = mask.size
    pixels = bytearray(mask.tobytes())
    result = []
    for start in range(len(pixels)):
        if not pixels[start]:
            continue
        pixels[start] = 0
        pending = deque([start])
        min_x = max_x = start % width
        min_y = max_y = start // width
        count = 0
        while pending:
            index = pending.popleft()
            x, y = index % width, index // width
            count += 1
            min_x, max_x = min(min_x, x), max(max_x, x)
            min_y, max_y = min(min_y, y), max(max_y, y)
            for other in (index - width, index + width):
                if 0 <= other < len(pixels) and pixels[other]:
                    pixels[other] = 0
                    pending.append(other)
            if x and pixels[index - 1]:
                pixels[index - 1] = 0
                pending.append(index - 1)
            if x + 1 < width and pixels[index + 1]:
                pixels[index + 1] = 0
                pending.append(index + 1)
        if count >= 12:
            result.append({"count": count, "box": (window[0] + min_x, window[1] + min_y,
                                                   window[0] + max_x + 1, window[1] + max_y + 1)})
    return sorted(result, key=lambda part: part["count"], reverse=True)


def gutter(profile: list[int], expected: int, radius: int = 48) -> int:
    first, last = max(1, expected - radius), min(len(profile) - 1, expected + radius)
    minimum = min(profile[first:last])
    runs = []
    start = None
    for index in range(first, last + 1):
        if index < last and profile[index] == minimum:
            if start is None:
                start = index
        elif start is not None:
            runs.append((start, index))
            start = None
    run = max(runs, key=lambda r: (r[1] - r[0], -abs((r[0] + r[1]) / 2 - expected)))
    return round((run[0] + run[1]) / 2)


def inspect_frames(path: Path, entry: dict) -> tuple[list[dict], dict]:
    image = Image.open(path)
    if image.mode != "RGBA":
        raise ValueError(f"{path.name} has no alpha channel")
    alpha = image.getchannel("A")
    if alpha.getextrema()[0] != 0:
        raise ValueError(f"{path.name} has an opaque background")
    width, height = image.size
    # Hand-checked overrides are possible if a generated gutter is uneven.
    binary = alpha.point(lambda p: 1 if p >= 128 else 0)
    columns = [sum(binary.crop((x, 0, x + 1, height)).tobytes()) for x in range(width)]
    x_cuts = entry.get("x_cuts", [0] + [gutter(columns, round(width * x / 5)) for x in range(1, 5)] + [width])
    row_cuts = []
    for column in range(5):
        rows = [sum(binary.crop((x_cuts[column], y, x_cuts[column + 1], y + 1)).tobytes()) for y in range(height)]
        default_cuts = entry.get("y_cuts", [0, gutter(rows, round(height / 3)), gutter(rows, round(height * 2 / 3)), height])
        row_cuts.append(entry.get("row_cuts_by_column", {}).get(str(column), default_cuts))
    frames = []
    for row in range(3):
        for column in range(5):
            window = (x_cuts[column], row_cuts[column][row], x_cuts[column + 1], row_cuts[column][row + 1])
            parts = components(alpha, window)
            if not parts:
                raise ValueError(f"Empty pose {row}/{column} in {path.name}")
            # A faint glow can join a hovering companion to the hero at alpha
            # 128. A higher threshold separates that glow for body anchoring.
            body_parts = components(alpha, window, threshold=230)
            body = body_parts[0]["box"] if body_parts else parts[0]["box"]
            meaningful = [part["box"] for part in parts if part["count"] >= max(12, parts[0]["count"] * 0.0008)]
            box = [max(window[0], min(p[0] for p in meaningful) - 3),
                   max(window[1], min(p[1] for p in meaningful) - 3),
                   min(window[2], max(p[2] for p in meaningful) + 3),
                   min(window[3], max(p[3] for p in meaningful) + 3)]
            body_height = body[3] - body[1]
            # Anchor the main character, not the combined width of a companion.
            upper = alpha.crop((body[0], body[1], body[2], body[1] + max(1, round(body_height * 0.3))))
            upper_box = upper.point(lambda p: 255 if p >= 128 else 0).getbbox()
            anchor_x = body[0] + (upper_box[0] + upper_box[2]) / 2
            frames.append({"row": row, "column": column, "window": window, "region": box,
                           "body": body, "anchor_x": anchor_x, "height": body_height})
    left = max((f["anchor_x"] - f["region"][0]) / f["height"] for f in frames)
    right = max((f["region"][2] - f["anchor_x"]) / f["height"] for f in frames)
    above = max((f["body"][3] - f["region"][1]) / f["height"] for f in frames)
    below = max((f["region"][3] - f["body"][3]) / f["height"] for f in frames)
    size_factor = (max(left, right) * 2 + 0.08, above + below + 0.08)
    baseline = above + 0.04
    for frame in frames:
        x, y, end_x, end_y = frame["region"]
        canvas_width = frame["height"] * size_factor[0]
        canvas_height = frame["height"] * size_factor[1]
        frame["margin"] = [canvas_width * 0.5 - (frame["anchor_x"] - x),
                           frame["height"] * baseline - (frame["body"][3] - y),
                           canvas_width - (end_x - x), canvas_height - (end_y - y)]
    return frames, {"size": image.size, "alpha_min_max": alpha.getextrema(),
                    "canvas_aspect": size_factor[0] / size_factor[1], "frames": frames}


def rect(values) -> str:
    return "Rect2(" + ", ".join(f"{value:.4f}" for value in values) + ")"


def region_rect(box):
    return (box[0], box[1], box[2] - box[0], box[3] - box[1])


def atlas_text(atlas_path: str, frame: dict, margin=True) -> str:
    source = ['[gd_resource type="AtlasTexture" load_steps=2 format=3]', "",
              f'[ext_resource type="Texture2D" path="{atlas_path}" id="1"]', "", '[resource]',
              'atlas = ExtResource("1")', f'region = {rect(region_rect(frame["region"]))}']
    if margin:
        source.append(f'margin = {rect(frame["margin"])}')
    source.extend(['filter_clip = true', ""])
    return "\n".join(source)


def build(entry: dict) -> dict:
    slug = entry["slug"]
    path = ASSETS / f"{slug}.png"
    frames, report = inspect_frames(path, entry)
    atlas_path = f"res://assets/characters/animated/{slug}.png"
    source = ['[gd_resource type="SpriteFrames" load_steps=17 format=3]', "",
              f'[ext_resource type="Texture2D" path="{atlas_path}" id="1"]', ""]
    for index, frame in enumerate(frames):
        source.extend([f'[sub_resource type="AtlasTexture" id="pose_{index}"]',
                       'atlas = ExtResource("1")', f'region = {rect(region_rect(frame["region"]))}',
                       f'margin = {rect(frame["margin"])}', 'filter_clip = true', ""])
    animations = []
    for row, direction in enumerate(["front", "back", "side"]):
        for state, columns in [("idle", [0]), ("walk", [1, 2, 3, 4])]:
            records = [f'{{"duration": 1.0, "texture": SubResource("pose_{row * 5 + column}")}}'
                       for column in columns]
            animations.append('{"frames": [' + ", ".join(records) + '], "loop": true, '
                              f'"name": &"{direction}_{state}", "speed": 8.0' + '}')
    source.extend(['[resource]', 'animations = [\n' + ",\n".join(animations) + '\n]', ""])
    (ASSETS / f"{slug}.tres").write_text("\n".join(source), encoding="utf-8")
    (ASSETS / f"{slug}_portrait.tres").write_text(atlas_text(atlas_path, frames[0]), encoding="utf-8")
    front = frames[0]
    bx, by, _, _ = front["body"]
    head_width = front["height"] * 0.72
    avatar = {"region": [max(front["window"][0], front["anchor_x"] - head_width * 0.5), by,
                         min(front["window"][2], front["anchor_x"] + head_width * 0.5),
                         by + front["height"] * 0.46]}
    (ASSETS / f"{slug}_avatar.tres").write_text(atlas_text(atlas_path, avatar, margin=False), encoding="utf-8")
    return report


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--allow-partial", action="store_true")
    args = parser.parse_args()
    manifest = json.loads(MANIFEST.read_text(encoding="utf-8"))
    reports = {}
    for entry in manifest["characters"]:
        if args.allow_partial and not (ASSETS / f'{entry["slug"]}.png').exists():
            continue
        reports[entry["name"]] = build(entry)
        print(f'Built {entry["name"]}: 3 idle poses, 12 walking poses')
    (ASSETS / "atlas-inspection.json").write_text(json.dumps(reports, indent=2), encoding="utf-8")
    print(f"Built {len(reports)} character resources; PNG pixels unchanged.")


if __name__ == "__main__":
    main()
