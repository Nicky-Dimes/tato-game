# Godot for this project — exact version, where to get it, how to run the checks

Round one of the overhaul could not run Godot, so nothing was tested before it came
back. This file is everything needed to run the same checks Claude runs.

## The engine

| | |
|---|---|
| Engine | **Godot 4.7.2 stable**, official **standard** build (not the .NET / mono build) |
| Version string | `4.7.2.stable.official.ed1daf0bf` |
| Language | GDScript only. No C#, no plugins, no GDExtension |
| Renderer | Compatibility (OpenGL 3 / WebGL 2). Tests run headless and need no display or GPU |
| Project file | `game/project.godot` (`config/features = "4.7", "GL Compatibility"`) |

Use exactly 4.7.2. Other 4.x versions may rewrite `.import` and scene files.

## Official downloads

All from the Godot project's release page:
`https://github.com/godotengine/godot/releases/tag/4.7.2-stable`
(also listed at `https://godotengine.org/download/archive/4.7.2-stable/`).

| File | Size | For |
|---|---|---|
| `Godot_v4.7.2-stable_linux.x86_64.zip` | 77,860,424 bytes | **a Linux x86-64 sandbox (most likely what you need)** |
| `Godot_v4.7.2-stable_linux.arm64.zip` | 77,008,699 bytes | Linux on ARM |
| `Godot_v4.7.2-stable_macos.universal.zip` | 170,622,178 bytes | macOS |
| `Godot_v4.7.2-stable_win64.exe.zip` | 86,013,866 bytes | Windows |
| `Godot_v4.7.2-stable_export_templates.tpz` | 1,281,349,702 bytes | only for exporting builds; **not needed to run or test** |

Direct link pattern:
`https://github.com/godotengine/godot/releases/download/4.7.2-stable/<file name>`

SHA-512 from the release's `SHA512-SUMS.txt`:

```
9aa00f7a605200940bce3027a567b782f49bd8e940dd06ae9e987bd65aee1b1467edd56ed84fcdcbdd44354bf613bdbb4e5d2913e925850368e150c59ed54c65  Godot_v4.7.2-stable_linux.x86_64.zip
dd59918da086bd49bde2f5450b5e567ff8650cbde9abbd7b8f4ca1197ff8c609baa38834666d032deafb47099078d7822279e2a0e06e5665745468f26533e7e2  Godot_v4.7.2-stable_linux.arm64.zip
```

**If your environment has no internet access:** ask the owner to download
`Godot_v4.7.2-stable_linux.x86_64.zip` from the link above and upload it to the
conversation next to the project ZIP. It is a single self-contained executable.

Engine source code (for reading how something works): `https://github.com/godotengine/godot`,
tag `4.7.2-stable`. Documentation: `https://docs.godotengine.org/`.

## Set up and run the checks (Linux)

```bash
unzip Godot_v4.7.2-stable_linux.x86_64.zip
chmod +x Godot_v4.7.2-stable_linux.x86_64
export GODOT="$PWD/Godot_v4.7.2-stable_linux.x86_64"

cd TATO_CURRENT_PROJECT_HANDOFF_V2      # the unpacked project
tools/check.sh
```

`tools/check.sh` does three things and prints one result line:

1. `--import` — builds Godot's cache (`game/.godot/`) and registers every `class_name`.
   **Run this first, and again after adding any picture or script.**
2. Loads every script, scene and resource (`game/tools/CheckScripts.tscn`).
3. Runs the 39 automated tests, including a robot that plays all 24 non-boss stages.

What a healthy run prints (this is the real output from the snapshot in this ZIP):

```
Godot: 4.7.2.stable.official.ed1daf0bf
1/3 import (builds game/.godot from nothing if it is missing)
    exit 0, 0 error/warning lines
2/3 every script, scene and resource loads
    checked 122 files, 0 problem(s)
3/3 tests
    TESTS: 39 passed, 0 failed  (31.7s)

RESULT: all checks passed
```

`tools/check.sh quick` runs only the fast unit tests (a few seconds).

The same steps by hand:

```bash
$GODOT --headless --path game --import
$GODOT --headless --path game res://tools/CheckScripts.tscn
$GODOT --headless --fixed-fps 60 --path game res://tests/TestRunner.tscn
$GODOT --headless --fixed-fps 60 --path game res://tests/TestRunner.tscn -- --only=test_combat
$GODOT --headless --fixed-fps 60 --path game res://tests/TestRunner.tscn -- --group=smoke --stage=W3
```

## Things to know

- **Headless is enough for all checks.** Not verified in your environment: Claude has
  only run this on macOS. Godot's Linux build normally starts headless in a plain
  container; if it complains about a missing library, report the exact message.
- **A test fails if the game logs any script or engine error** while it runs, so a wrong
  dictionary key or a call on a missing node is caught even when no check compares it.
- **Screenshots need a real display.** `-- --shot=...` (see `docs/DEVELOPMENT.md`) draws
  with OpenGL and will not work with `--headless`. With `xvfb` and software OpenGL it
  may work (`xvfb-run -a $GODOT --path game --rendering-driver opengl3 -- --level=W1-L1
  --shot=/tmp/s.png --shot-after=150`); untested.
- `game/.godot/` is a cache. Do not include it when sending the project back.
- New pictures get a `.import` file beside them when imported. Sending those back is
  fine. Never hand-write or edit `.import` or `.uid` files.
- The tests write and then restore one save slot under Godot's user data folder
  (`~/.local/share/godot/app_userdata/TATO!/` on Linux).
- If a script uses a new `class_name`, the import step must run before anything else or
  Godot reports "Could not find type".
