# AGENTS.md

## 执行原则
请回答前，先向我提问。要求：一次只问一个问题。然后根据我的回答继续追问，直到你有90%的信心，完全理解我的真实需求和目标时，再给出最终方案

## Project overview

`tiny_swords` is a 2D top-down action game built with **Godot 4.6** (GDScript), using the
third-party "Tiny Swords (Free Pack)" pixel-art asset pack. The player fights a fixed set of
enemies on a tilemap island; killing all enemies triggers victory, dying triggers defeat.
The game has a main menu → gameplay → game-over screen flow managed by a scene handler.

There is no build system, package manager, test suite, or CI — everything is configured
through `project.godot` and the Godot editor.

## Technology stack

- **Engine:** Godot 4.6 (config `config/features` includes `"4.6"`, `GL Compatibility`).
  Godot 4.6.2 is installed on this machine at `/d/Software/Godot/Godot_v4.6.2/godot`.
- **Language:** GDScript only (`.gd` files; every script has a sibling `.uid` file — do not
  delete `.uid` files, Godot uses them for stable resource references).
- **Renderer:** GL Compatibility (`gl_compatibility`), Windows driver `d3d12`.
- **Viewport:** 1920×1080.

## Running the project

- **Editor:** open `project.godot` in Godot 4.6 and press F5 (main scene is
  `scene_handler.tscn`).
- **CLI:** `/d/Software/Godot/Godot_v4.6.2/godot --path .` (add `-e` for the editor).
- **Syntax check a script:** `godot --headless --path . --check-only --script <file.gd>`.
- There are **no automated tests**. Verification is done by running the game and playing
  through: main menu → New Game → kill all enemies / die → game-over screen.

## Scene and runtime architecture

Entry point flow (main scene `scene_handler.tscn`, script `scene_handler.gd`):

1. `Scene_handler` (Control) instantiates `UI/Menus/main_menu.tscn`.
2. On `new_game_pressed` it frees the menu and instantiates `game.tscn` (`game.gd`, the
   gameplay root). It connects `game.game_over(victory)` to the end screen.
3. On game over it instantiates `UI/Menus/game_end_menu.tscn` inside `Game/UI` and disables
   processing for player and enemies.

`game.tscn` contains:

- an instance of `test_scene.tscn` — the actual level: stacked `TileMapLayer`s
  (water, ground, decorations, `navigateLayer` for navigation), a `player` instance
  (`Entities/Player/player.tscn`), and two `enemy` instances
  (`Entities/Enemies/BaseEnemy/enemy.tscn`) under an `enemys` node;
- an `effects` node (`Entities/Effects/effects.tscn`) holding exported effect scenes;
- a `UI` CanvasLayer with the `HUD` (script `VFX/hud.gd` — note: HUD script lives in `VFX/`,
  not `UI/HUD/`).

### Key gameplay mechanics

- **Player** (`Entities/Player/player.gd`): `CharacterBody2D` with an enum state machine
  (IDLE / RUN / GUARD / ATTACK) driving an `AnimationTree` state machine. WASD movement,
  left-click attack, hold right-click to guard (blocks frontal attacks). Emits
  `hp_changed(percent)` for the HUD.
- **Enemy** (`Entities/Enemies/BaseEnemy/enemy.gd`): `CharacterBody2D` with enum state
  machine (IDLE / CHASE / ATTACK); chases via `NavigationAgent2D` when the player is within
  `chase_distance`. Emits `die(experience, position)` on death; `game.gd` counts kills and
  awards experience.
- **Leveling:** `game.gd` accumulates experience in the `player_data` autoload and levels up
  against `level_data.level_experience_list` (max level 5). Level-ups emit `levelUp`, which
  the player uses to recalculate attack speed via `Equations.calculate_attack_speed()`.

### Communication conventions

- Nodes are **decoupled via signals** (`game_over`, `die`, `hp_changed`, `levelUp`, and menu
  `*_pressed(origin: String)` signals). Menus pass a string `origin` (e.g. `"main_menu"`,
  `"game_over"`) so the handler knows which scene to free.
- Entity lookup uses **global groups**: `"player"` and `"enemies"` (declared in
  `project.godot`). Root nodes of `player.tscn` / `enemy.tscn` are in these groups.
- Enemy references the player via the unique-name accessor `%player`.
- Damage is applied by calling `take_damage(...)` directly on the body entered in a
  `hitArea` Area2D `body_entered` callback.

### Autoloads and global classes (`project.godot`)

- `player_data` → `scripts/global/player_data.gd` — global singleton: `level`, `experience`.
  Also handles persistence: loads `user://save_game.json` on startup (`load_data()`) and
  auto-saves via `save_data()` whenever `game.gd` awards experience or levels up.
- `level_data` → `scripts/data/level_data.gd` — global singleton: `max_level`,
  `level_experience_list`.
- `Equations` (`scripts/classes/equations.gd`, `class_name Equations`) — static game-formula
  helpers; reads the `player_data` singleton.
- Scripts reference autoloads directly by their lowercase names (`player_data.level`, ...).

### Input map and physics layers

- Input actions: `up`/`down`/`left`/`right` (W/A/S/D), `click_left` (attack),
  `click_right` (guard).
- 2D physics layers: 1 = `world`, 5 = `playerDamage`, 6 = `enemyDamage`.

## Directory layout

- `game.tscn` / `game.gd`, `scene_handler.tscn` / `scene_handler.gd`, `test_scene.tscn` —
  project-root scenes (root is where main scenes live; do not move them casually, scene
  paths are hardcoded, e.g. `game.gd` looks up `get_node("test_scene")`).
- `Entities/` — gameplay entities: `Player/`, `Enemies/BaseEnemy/`, `Effects/` (plus `death/`
  effect). `Enemies/Goblin/`, `Enemies/Slime/`, `Items/` exist but are empty (planned).
- `Levels/` — `BaseLevel/`, `Menus/`, `World_01/` — currently empty placeholders.
- `UI/` — `Menus/` (main menu, game-end menu), `HUD/`, `Inventory/` (empty), plus art
  (`buttons/`, `elements/`).
- `scripts/` — non-scene scripts: `classes/` (`Equations`), `data/` (`level_data`),
  `global/` (`player_data`).
- `core/` (`AutoLoads/`, `Components/`, `Utils/`) and `Data/` (`JSON/`, `Resources/`,
  `Saves/`) — empty placeholder scaffolding for future systems. Note: the actual save file
  lives at `user://save_game.json` (see `player_data`), not in `Data/Saves/` — exported
  builds cannot write to `res://`.
- `assets/` — art/audio/fonts. `assets/Tiny Swords (Free Pack)/` is the third-party pack
  (kept as-is; don't reorganize). `VFX/` currently only holds `hud.gd`.
- Convention: each scene/script lives in its own folder as `<name>.gd` + `<name>.tscn` +
  generated `.uid` files.

## Code style guidelines

- GDScript with **static typing everywhere**: typed vars, params, and return types
  (`func attack() -> void:`, `var playerState: PlayerState = PlayerState.IDLE`).
- Indentation: tabs (Godot default). `.editorconfig` only sets `charset = utf-8`.
- Naming is **mixed** in existing code: mostly snake_case (`max_health`, `take_damage`,
  `hp_changed`) but some camelCase (`playerState`, `moveDirection`, `currentHealth`,
  `enemyState`). Match the style of the file you edit; don't mass-rename.
- State machines use `enum` + `AnimationTree` playback (`playback.travel("run")`).
- Exported tunables are grouped with `@export_category("Stats")` / `@export_category("Attack")`.
- Debugging is done with `print()` calls — they are pervasive in existing code.
- Comments and documentation are in **English**; keep it that way.

## Testing instructions

There is no test framework or test directory. After changes:

1. Run `godot --headless --path . --quit` to catch parse/import errors.
2. Launch the game and verify manually: menu buttons work, player moves/attacks/guards,
   enemies chase and die, XP/level-up updates the HUD label, win and lose both reach the
   game-over screen.

## Deployment

No export presets or CI exist yet. Deployment would be done via Godot's export templates
(Project → Export) — none are configured.

## Security / housekeeping notes

- No secrets, network code, or external services are involved.
- Leftover/artifact files exist and are safe to leave alone unless cleaning up is requested:
  `game.tscn*.tmp` (editor temp files), `Entities/Player/player.gd.bak`, a stray `.tscn`
  file at the root, and `assets/Tiny Swords (Free Pack).zip`.
- `.gitignore` only ignores `.godot/` and `/android/`; everything else (including `.import`
  and `.uid` files) is committed and should stay committed.
