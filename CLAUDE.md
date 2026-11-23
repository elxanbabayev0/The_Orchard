# The Orchard — Project Context for Claude Code

The full original design notes (in Azerbaijani) are in `docs/The_Orchard_Project_Context.md`. This file is the short working version. Newer decisions from the user override anything written here.

## Communication
- The user writes in **Azerbaijani**. Reply in Azerbaijani; keep code, file names, node names and variable names in English.
- The user is a solo developer who is **learning** game development. Explain step by step and explain *why*, not just *what*.
- The user does not know C#. Use **GDScript** only. Suggest C# only with a clear reason, explained first.

## Project overview
- **Name:** The Orchard
- **Genre:** 2D farming / life simulation / management game
- **Engine:** Godot **4.7** (confirmed 2026-11-23; the installed build is the .NET/mono one, but the project uses GDScript only)
- **Platform:** Developed on Windows. Version control with Git / GitHub (repo: `The_Orchard.git`).
- **Inspiration:** Hay Day — but this must be an **original** game. Never copy its mechanics, UI or art one-to-one.
- **Goal:** a long-playing, expandable game, not a short fixed story.

## Visual style (confirmed)
- 2D, **hand-painted** look: colorful, soft, atmospheric.
- **Not** pixel art. Not an overly flat/simple 2D style either.
- All assets (trees, fruit, soil, buildings, characters, environment) must look like they belong to the same game.
- **Camera angle (confirmed 2026-11-23):** 3/4 top-down oblique view — see Decision log.
- **Tile size (confirmed 2026-11-23):** 64 × 64 px, square. **Base resolution:** 1920 × 1080 — see Decision log.
- Not decided yet: color palette, exact sprite sizes, art source resolution (1× or 2×), animation standards.

## Core gameplay loop (concept)
1. The player works in the orchard.
2. Grows fruit trees and plants.
3. Harvests ripe produce.
4. Sells produce to the merchant (later, other buyers too).
5. Uses income to expand the farm.
6. Earns XP and unlocks new characters.
7. New characters and skills open up new possibilities.

Balance details (growth times, energy, inventory size, currency, levels) are **not decided**.

## Confirmed content
- **Fruits:** alça (cherry plum), vişnə (sour cherry), tut (mulberry), albalı (morello cherry), gilas (sweet cherry) and its varieties. The system must support adding more trees, fruits and varieties later.
- **Characters:** the player starts with their own character. Other characters are unlocked with XP. Each character will have unique skills that affect gameplay (the skill list, XP costs and unlock order are **not decided**).
- **Merchant Orxan:** buys the player's produce. His prices are meant to be **dynamic** and may be affected by what other players sell for. How this works technically (multiplayer, server, price formula) is **not decided** — do not assume multiplayer exists.
- **Buyer NPCs:** more buyers with their own personalities are planned. Names, looks, dialogue and order mechanics are not decided.
- **Family tree** (keep names and relations exactly as written; roles/ages/personalities are not decided):
  ```
  Zöhrə
  ├── Gulnarə: Elman, Elxan, Elnaz, Eltac
  ├── İlqar: Duyğu, Səid, Ülkər
  └── Aytən: Vüqar, Nubar, Zəhrə
  ```

## Technical conventions (confirmed)
**Origin on the ground (Y-sort rule)** — applies to every object that stands in the world (player, trees, buildings, NPCs, bushes, props):
1. The node's origin (0, 0) is the point where the object touches the ground (player: feet; tree: bottom of the trunk; box: bottom edge).
2. The `Sprite2D` is moved up so its bottom edge sits on the origin (e.g. a 64×110 sprite → `position = (0, -55)`).
3. The collision shape covers only the "feet / base" part, not the whole picture, so the player can walk behind the top part of objects.
4. All such objects live under `Main/Entities` (a `Node2D` with `y_sort_enabled = true`). Sub-group nodes inside it (like `Obstacles`) also need `y_sort_enabled = true`, so their children are sorted together with the player.
5. The ground (`Ground`, later `TileMapLayer`s for soil/grass) stays **outside** `Entities`, so it is always drawn behind everything.

## Current technical state (verify — may be outdated)
- Main scene: `scenes/world/main.tscn` → `Main` (`Node2D`) with `Ground` (placeholder `ColorRect`) and `Entities` (Y-sorted: `Obstacles/Box1`, `Obstacles/Box2`, `Trees/Gilas1`, `Player` instance).
- Player: `scenes/player/player.tscn` (`CharacterBody2D` + `CollisionShape2D` + `Sprite2D` + `Camera2D` + `InteractionArea` (`Area2D`, circle r=40 at the feet)), placeholder 64×110, origin at the feet.
- Movement: `scenes/player/player.gd`, speed `200`, `Input.get_vector("move_left", "move_right", "move_up", "move_down")`. Actions are bound to physical WASD + arrow keys in `project.godot`.
- Interaction: `interact` action (physical **E** — a suggestion, not a confirmed control scheme). On press, the player calls `interact(player)` on the nearest body in `InteractionArea` that has that method (duck typing: any tree / NPC / door becomes interactable just by having `interact(player)`).
- Trees (`scenes/trees/`):
  - `tree_data.gd` → `class_name TreeData` (`Resource`): id, display name, stage durations (seconds for now, game days later), `fruit_id` (temporary, until an item system exists), `harvest_yield`, one texture per stage.
  - `types/gilas.tres` → the first tree type (test values: 5 s per stage, yield 3, placeholder gradient textures).
  - `fruit_tree.tscn` / `fruit_tree.gd` → `class_name FruitTree` (`StaticBody2D`). **Not** named `Tree`, because Godot already has a built-in `Tree` UI class. Stages `SAPLING → YOUNG → FLOWERING → UNRIPE → RIPE`; ripe waits; `harvest()` returns the amount, goes back to `FLOWERING` and emits `harvested(fruit_id, amount)`. Time is fed through `advance_time(amount)` (currently from `_process(delta)`, later from the game clock). `StageLabel` is a temporary debug label.
- No inventory yet: harvests are only printed to the Output panel.
- Check the real files before relying on this.

## Open questions (do not treat as decided)
Exact sprite sizes and art source resolution · map structure and world size · inventory · money and XP balance · tree balance numbers (stage durations, yields) and length of a game day · sleep / energy / day-start mechanic (later) · tree care, fallen/overripe fruit and quality (later) · seasons and weather · crafting / processing · buildings and farm expansion · quests · NPC dialogue and AI · character skills · multiplayer or not · dynamic pricing implementation · save/load · sound and music · target platforms (PC / mobile).

When one of these comes up, present options with pros and cons and let the user choose. Do not turn a suggestion into an official decision without the user's approval.

## How to work
1. **Look first.** Read the current files, scene tree and code before changing anything. Never restructure the project blindly.
2. **Small steps.** Split every big feature into small stages. Get one stage working before starting the next.
3. **Verify each step.** After a change, run the project (Godot MCP) and check for errors. Tell the user what to test in the editor.
4. **Be precise.** Say exactly which file, which node, and which Godot Editor actions are needed (e.g. "add an `Area2D` as a child of `Player`").
5. **Explain the code.** Short explanation of what each new piece does and why it was designed this way.
6. **Don't break working code.** Don't rewrite working parts without a reason.
7. **Clean architecture.** Separate systems into their own scripts/scenes (e.g. player, crops/trees, inventory, economy, UI). Prefer data-driven definitions (e.g. `Resource` files for fruit/tree types) so new content can be added without new code. Avoid one giant script.
8. **Keep it simple, but expandable.** No over-engineering, but plan for future growth.
9. **Label ideas clearly.** When proposing something new, say whether it is a confirmed decision or just a suggestion.
10. **Consistent naming.** Keep node names, file names and variables consistent across the project.
11. **Git.** Suggest a commit after each working step so the user can roll back.

## Decision log
Add new decisions here in this format:

- **Date:**
- **Topic:**
- **Decision:**
- **Status:** Confirmed / Testing / Just an idea
- **Affected systems:**
- **Notes:**

---

- **Date:** 2026-11-23
- **Topic:** Camera angle / perspective
- **Decision:** 3/4 top-down oblique view. The ground is a square grid; trees, buildings and characters are drawn from the front (trunk, branches and fruit visible). Not isometric, not pure top-down.
- **Status:** Confirmed
- **Affected systems:** art (all sprites drawn front-facing), world/tiles (`TileMapLayer` with square tiles), draw order (Y-sort), player movement (stays as is: `Input.get_vector` with `move_*` actions)
- **Notes:** Chosen because it shows fruit and tree growth stages clearly, suits the hand-painted style, is the simplest for a solo developer, and looks clearly different from Hay Day (isometric). Tile size was decided separately (see next entry).

---

- **Date:** 2026-11-23
- **Topic:** Tile size and base resolution
- **Decision:** Tile size **64 × 64 px** (square grid). Base resolution (viewport) **1920 × 1080**, with the existing `canvas_items` stretch mode and `expand` aspect. About 30 × 17 tiles are visible on screen.
- **Status:** Confirmed
- **Affected systems:** world/tiles (`TileSet` tile size 64), all art (painted to fit the 64 px grid), placeholders (player 32×32 and boxes 48×48 must be resized), `project.godot` display settings, camera
- **Notes:** 64 px was chosen because hand-painted detail (fruit, growth stages) needs more pixels than pixel-art sizes like 32 px, while 128 px shows too little of the world and means too much art work for a solo developer. Rough size guidelines (suggestions, NOT confirmed): character ≈ 64 px wide × 100–120 px tall; mature tree ≈ 2 tiles wide × 3 tiles tall, trunk base on 1 tile. Painting art at 2× (128 px) and scaling down is still an open question — decide when the first real art is made.

---

- **Date:** 2026-11-23
- **Topic:** Draw order / origin convention (Y-sort)
- **Decision:** Every world object has its origin on the ground, sprite shifted up, collision only on the base; all such objects live under the Y-sorted `Main/Entities` node. Full rule: see "Technical conventions".
- **Status:** Confirmed
- **Affected systems:** world scene structure, player, all future trees/buildings/NPCs/props, collision shapes
- **Notes:** Needed for the 3/4 oblique view: objects lower on screen are drawn in front, and the player can walk behind the top part of trees and buildings.

---

- **Date:** 2026-11-23
- **Topic:** Tree growth and harvest rules
- **Decision:**
  1. **Time:** in-game time (own game clock with a day cycle). Trees grow in game days. Time stops while the game is closed — no offline progress.
  2. **Growth:** a tree grows **once** (sapling → young tree → mature tree), then a **repeating fruit cycle** runs: flowering → unripe fruit → ripe fruit → [harvest] → flowering …
  3. **After harvest:** the tree keeps producing forever (no limited number of harvests, no dying).
  4. **Unharvested fruit:** waits on the tree indefinitely (no spoiling, no falling).
  5. **Care:** none for now — the tree grows by itself.
- **Status:** Confirmed
- **Affected systems:** trees (`TreeData` resource + `Tree` scene), a future game clock / day cycle system, harvesting, inventory, save/load
- **Notes:** Real-time timers were rejected (clock cheating, offline-time math, and it is Hay Day's core mechanic). Limited harvests → withering was rejected because it is too close to Hay Day. Length of a game day, stage durations and yields are balance numbers and are **not decided**; the prototype uses temporary test values in seconds. Code must be built so these can be added later without rewriting (status: **Just an idea**): tree health/age affected by care (pruning, fertilizer) instead of dying; fallen fruit that can still be collected at lower quality (possible link to processing, e.g. jam/compote); simple watering; each fruit type bearing fruit in its real-life season (alça in spring, gilas/tut in May–June, albalı/vişnə in June–July) once seasons exist.

---

- **Date:** 2026-11-23
- **Topic:** Game clock details
- **Decision:**
  1. **Tree growth is continuous:** trees grow a little with every passing game minute. Stage durations are written in game days and may be fractional (e.g. 1.5 days, 0.5 day).
  2. **Day structure:** for now an endless 24-hour loop (00:00 → 23:59 → 00:00), no sleeping. The clock must be built so a day/sleep mechanic (day starts in the morning, bed skips to the next morning) can be added later without rewriting.
  3. **Day/night visuals:** simple tint — the screen slowly turns dark blue in the evening and brightens in the morning (`CanvasModulate`).
- **Status:** Confirmed
- **Affected systems:** new `GameClock` autoload, a clock label in the UI, `FruitTree` (time comes from the clock instead of `_process(delta)`), `TreeData` (durations in game days), world scene (day/night tint)
- **Notes:** The length of a game day in real time is a balance number and is **not decided**; a temporary test value is used (e.g. 1 game day = 2 real minutes), exposed as an editable setting. Sleep, energy, house/bed and pausing the clock in menus are later topics.
