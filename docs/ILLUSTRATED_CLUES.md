# Illustrated clues

Clue discovery and the clue journal show illustrations without clue names, character names, or explanatory wording. The confirmation button uses a checkmark. Undiscovered world markers retain their animated investigation symbol so they do not disclose the clue before collection.

Each clue has a separate transparent PNG under assets/clues. Internal string identifiers are unchanged for network compatibility. scripts/clue_art.gd maps identifiers to filenames and adds a brief fade/scale reveal followed by a gentle floating loop. Journal images remain scrollable for large collections.

Images are generated with built-in imagegen, one image per clue. Prompts require one isolated Malaysian folklore game object, warm painterly materials and transparent background, without letters, numbers, labels or captions. Exact prompts are retained in generation-prompts.json.

Validation: tests/clue_art_validation.gd verifies asset coverage, transparency, wordless discovery, complete journal coverage and reveal/float animation.

Completed: 33 generated transparent images. All 168 clue-art checks passed. Popup and full icon overview were rendered for visual review. Godot reports local log-directory and test cleanup warnings. APK was not rebuilt.
