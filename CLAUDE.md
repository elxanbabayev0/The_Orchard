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
- **Fruits:** alça (cherry plum), vişnə (sour cherry), tut (mulberry), albalı (morello cherry), gilas (sweet cherry) and its varieties. The system must support adding more trees, fruits and varieties later. **In the game, fruit names are shown in English** (Cherry Plum, Sour Cherry, Mulberry, Morello Cherry, Sweet Cherry) — confirmed 2026-11-23, see Decision log.
- **Characters:** the player starts with their own character. Other characters are unlocked with XP. Each character will have unique skills that affect gameplay (the skill list, XP costs and unlock order are **not decided**).
- **Merchant Bruno** (was "Orxan"; renamed 2026-11-23, see Decision log): buys the player's produce. Prices are **dynamic**: daily market price + the player's own sales (confirmed 2026-11-23, see Decision log). Prices based on other real players would need multiplayer/a server, which is **not decided** — do not assume multiplayer exists.
- **Buyer NPCs:** more buyers with their own personalities are planned. Names, looks, dialogue and order mechanics are not decided.
- **Family tree** (names confirmed 2026-11-23, see Decision log) — keep names and relations exactly as written. Each branch has its own cultural origin. Roles/ages/personalities are not decided.
  ```
  Rosa (grandmother)
  ├── Sofia (Mediterranean branch): Elio, Elias, Elena, Eloy
  ├── Henrik (Scandinavian branch): Freya, Nils, Astrid
  └── Yuki (Japanese branch): Kenji, Hana, Aiko
  ```
  Old working names (only for reading `docs/The_Orchard_Project_Context.md`): Zöhrə → Rosa; Gulnarə → Sofia (Elman → Elio, Elxan → Elias, Elnaz → Elena, Eltac → Eloy); İlqar → Henrik (Duyğu → Freya, Səid → Nils, Ülkər → Astrid); Aytən → Yuki (Vüqar → Kenji, Nubar → Hana, Zəhrə → Aiko). Do not use the old names in the game.

## Technical conventions (confirmed)
**Origin on the ground (Y-sort rule)** — applies to every object that stands in the world (player, trees, buildings, NPCs, bushes, props):
1. The node's origin (0, 0) is the point where the object touches the ground (player: feet; tree: bottom of the trunk; box: bottom edge).
2. The `Sprite2D` is moved up so its bottom edge sits on the origin (e.g. a 64×110 sprite → `position = (0, -55)`).
3. The collision shape covers only the "feet / base" part, not the whole picture, so the player can walk behind the top part of objects.
4. All such objects live under `Main/Entities` (a `Node2D` with `y_sort_enabled = true`). Sub-group nodes inside it (like `Obstacles`) also need `y_sort_enabled = true`, so their children are sorted together with the player.
5. The ground (`Ground`, later `TileMapLayer`s for soil/grass) stays **outside** `Entities`, so it is always drawn behind everything.

## Current technical state (verify — may be outdated)
- Main scene: `scenes/world/main.tscn` → `Main` (`Node2D`) with `Ground` (placeholder `ColorRect`), `Entities` (Y-sorted: `Obstacles/Box1`, `Obstacles/Box2`, `Trees/Gilas1`, `NPCs/Bruno`, `Player` instance), `DayNightTint` and `UI` (`CanvasLayer`, does not move with the camera and is not tinted) → `ClockLabel`, `MoneyDisplay`, `InventoryPanel`, `ItemPopups`, `SellWindow`. Signal connection in the scene file: `Bruno.trade_requested` → `SellWindow.open`.
- Autoloads (order matters — later ones use earlier ones in `_ready`): `GameClock`, `Inventory`, `Wallet`, `Market`.
- Day/night: `DayNightTint` (`CanvasModulate`, `scenes/world/day_night_tint.gd`) samples its `day_colors` `Gradient` (editable in the Inspector; left = 00:00, right = 24:00) with `GameClock.get_day_progress()`. Affects only the world layer (layer 0), not the UI. The colors are a suggestion, not a decision.
- Game clock: autoload **`GameClock`** (`scripts/systems/game_clock.gd`, no `class_name` on purpose — the autoload name is already global). Stores `day` (from 1) + `minute_of_day` (0..1440), starts at 06:00, endless 24 h loop. All time moves through `advance(days)` (called from `_process` now; a future sleep mechanic can call it to skip time). `paused` stops time. Signals: `minute_changed(day, hour, minute)`, `day_changed(day)`, `time_advanced(delta_days)`. Helpers: `get_hour()`, `get_minute()`, `get_day_progress()` (0..1). Speed: `real_seconds_per_day = 120.0` — a TEMPORARY test value (edit it in the script; script autoloads do not show in the Inspector).
- Player: `scenes/player/player.tscn` (`CharacterBody2D` + `CollisionShape2D` + `Sprite2D` + `Camera2D` + `InteractionArea` (`Area2D`, circle r=40 at the feet)), placeholder 64×110, origin at the feet.
- Movement: `scenes/player/player.gd`, speed `200`, `Input.get_vector("move_left", "move_right", "move_up", "move_down")`. Actions are bound to physical WASD + arrow keys in `project.godot`.
- Interaction: `interact` action (physical **E** — a suggestion, not a confirmed control scheme). On press, the player calls `interact(player)` on the nearest body in `InteractionArea` that has that method (duck typing: any tree / NPC / door becomes interactable just by having `interact(player)`).
- Trees (`scenes/trees/`):
  - `tree_data.gd` → `class_name TreeData` (`Resource`): id, display name, stage durations in **game days** (`sapling_days`, `young_days`, `flowering_days`, `unripe_days`; fractions allowed), `fruit: ItemData`, `harvest_yield`, one texture per stage.
  - `types/gilas.tres` → the first tree type (test values: 0.1 game day per stage ≈ 12 real seconds, yield 3, placeholder gradient textures).
  - `fruit_tree.tscn` / `fruit_tree.gd` → `class_name FruitTree` (`StaticBody2D`). **Not** named `Tree`, because Godot already has a built-in `Tree` UI class. Stages `SAPLING → YOUNG → FLOWERING → UNRIPE → RIPE`; ripe waits; `harvest()` adds `data.fruit` × `harvest_yield` to the `Inventory` (direct call), returns the amount, goes back to `FLOWERING` and emits `harvested(item, amount)` (kept for future sounds/effects/quests). Time is fed through `advance_time(game_days)`, connected to `GameClock.time_advanced` in `_ready()` (so trees pause with the clock and will grow during a future sleep skip). `StageLabel` is a temporary debug label.
- Items (`scenes/items/`): `item_data.gd` → `class_name ItemData` (`Resource`): `id` (stable, used for counting and future saves), `display_name`, `category` (enum `FRUIT`, `OTHER`), `icon`, `description`, `base_price` (int, "Economy" group, 0 = cannot be sold; gilas test value 10). `types/gilas.tres` = the gilas fruit item (placeholder 48×48 icon). Note: `trees/types/gilas.tres` is the tree, `items/types/gilas.tres` is the fruit.
- Inventory: autoload **`Inventory`** (`scripts/systems/inventory.gd`). Shared, unlimited "id → amount" list (`_amounts`) plus `_items` (id → ItemData) for names/icons. API: `add_item(item, amount)`, `remove_item(item, amount)` (all-or-nothing, returns `bool`; items at 0 are removed from the list), `get_count(item)`, `has_item(item, amount)`, `get_items()`. Signals: `inventory_changed(item, new_amount)`, `item_added(item, amount)`.
- Inventory UI (`scenes/ui/`, texts/look are placeholders):
  - `inventory_panel.tscn` / `.gd` — `PanelContainer` centered on screen, toggled by the `toggle_inventory` action (physical **I** — a suggestion). Rows (icon, name, "× amount") are built in code under `Margin/VBox/Rows`; shows `EmptyLabel` ("Boşdur") when empty; refreshes on `Inventory.inventory_changed` only while visible. The player can still move and the clock keeps running while it is open.
  - `item_popups.tscn` / `.gd` — `VBoxContainer` at the bottom center; on `Inventory.item_added` shows "[icon] +3 Gilas", which stays 1.5 s and fades out over 0.5 s with a `Tween`, then is freed.
- Money: autoload **`Wallet`** (`scripts/systems/wallet.gd`). Integer `money` (no cents), `STARTING_MONEY = 0` (TEMPORARY test value). API: `add_money(amount)`, `spend_money(amount)` (all-or-nothing, returns `bool`), `can_afford(amount)`; zero/negative amounts are rejected with a warning. Signal: `money_changed(new_amount, change)`. UI: `scenes/ui/money_display.tscn` (placeholder radial-gradient coin icon + amount, under the clock).
- Market: autoload **`Market`** (`scripts/systems/market.gd`). `price = base_price × daily factor × sales factor`, rounded, at least 1 (0 if `base_price` is 0). Daily factor: random per item, picked when first needed each day, cleared on `GameClock.day_changed`. Sales factor: `max(MIN_SALES_FACTOR, 1 − saturation × DROP_PER_UNIT)`; saturation += units sold and fades continuously via `GameClock.time_advanced`. TEMPORARY constants: `DAILY_RANGE 0.2`, `DROP_PER_UNIT 0.02`, `MIN_SALES_FACTOR 0.5`, `RECOVERY_PER_DAY 25`. API: `get_price(item)`, `get_sell_total(item, amount)` (each unit priced one by one, no side effects), `sell(item, amount)` (all-or-nothing via `Inventory.remove_item`, pays via `Wallet.add_money`, returns money earned or 0), `get_daily_factor(item)`. Signal: `prices_changed(item)` (`null` = new day).
- Merchant (`scenes/npc/`): `merchant.tscn` / `merchant.gd` → `class_name Merchant` (`StaticBody2D`): stall + placeholder person, origin at the counter's bottom edge, collision only at the counter base; the person sprite is drawn before the counter so he stands behind it. `@export display_name` ("Bruno"), `@export buys: Array[ItemData]` (Bruno buys gilas) — reusable for future buyers. `interact(player)` emits `trade_requested(merchant)`.
- Sell window: `scenes/ui/sell_window.tscn` / `.gd` (`PanelContainer`, centered; texts are placeholders). `open(merchant)` lists each item in `merchant.buys`: icon, name, "Qiymət", "Səndə", a `SpinBox` (0..owned, defaults to all), live total from `Market.get_sell_total`, "Sat" button → `Market.sell`. Rebuilds on `Inventory.inventory_changed` / `Market.prices_changed` while visible. Closes with "Bağla" or `ui_cancel` (Esc). The player can still move and the clock keeps running while it is open.
- Not applied yet in code: fruit display names in English (gilas still shows "Gilas"), UI language (texts are placeholder Azerbaijani).
- Check the real files before relying on this.

## Open questions (do not treat as decided)
Exact sprite sizes and art source resolution · map structure and world size · inventory capacity limits / slots / storage building (later) · money and XP balance · tree balance numbers (stage durations, yields) and length of a game day · sleep / energy / day-start mechanic (later) · tree care, fallen/overripe fruit and quality (later) · seasons and weather · crafting / processing · buildings and farm expansion · quests · NPC dialogue and AI · character skills · multiplayer or not · price balance (base prices, random range, drop/recovery speed, starting money) · currency name · merchant schedule (later) · save/load · names of future characters / buyer NPCs (foreign, user approves) · UI language (fruit names are English; rest not decided) · sound and music · target platforms (PC / mobile).

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

---

- **Date:** 2026-11-23
- **Topic:** Inventory
- **Decision:**
  1. **Structure:** a simple list of "item → amount" (no slots, no stack limits).
  2. **Capacity:** unlimited for now.
  3. **Owner:** one shared farm inventory used by all characters (not one per character).
  4. **UI:** a panel opened with a key, listing items and amounts, **plus** a small pop-up notification on harvest (e.g. "+3 Gilas").
- **Status:** Confirmed
- **Affected systems:** new `ItemData` resource (replaces the temporary `fruit_id` in `TreeData`), new `Inventory` autoload (`add_item`, `remove_item`, `get_count`, `has_item`, `inventory_changed` signal), harvesting (`FruitTree.harvested` → inventory), UI (inventory panel, harvest pop-up), future save/load and merchant selling
- **Notes:** Slots/stack limits, capacity limits and a storage building were postponed: they depend on the economy and farm expansion, which are not decided. The public functions (`add_item` etc.) are meant to stay the same if the inventory later moves to slots, so mostly the UI would change. If a storage building is added later, it must not copy Hay Day's barn/silo capacity model. The key that opens the panel (suggested: **I**) and the UI style are suggestions, not decisions. No item quality yet (postponed earlier).

---

- **Date:** 2026-11-23
- **Topic:** Merchant, money and selling
- **Decision:**
  1. **Money:** no currency name for now — just a money icon and a number. The name can be chosen later without code changes.
  2. **Dynamic prices (single-player):** daily market + supply/demand. Every morning each fruit's price changes randomly within a range around its base price; on top of that, selling a lot of one fruit lowers its price, which slowly recovers over game days.
  3. **How selling works:** a sell window. Press interact near the merchant → a window lists each fruit with its current price and lets the player choose how many to sell.
  4. **Where / when:** for now the merchant is always on the farm in a fixed spot (e.g. a stall). A schedule tied to `GameClock` (e.g. only 08:00–18:00) can come later.
- **Status:** Confirmed
- **Affected systems:** new money/wallet system (likely an autoload), `ItemData` (needs a base price), new market/price system (daily price + sales effect, listens to `GameClock.day_changed`), merchant NPC scene (`interact(player)`), sell window UI, `Inventory.remove_item` (all-or-nothing)
- **Notes:** Starting money, base prices, the random range and how fast prices drop/recover are balance numbers and are **not decided** (temporary test values). Prices from other real players are not possible without multiplayer; the model should allow adding that later. A "sell box emptied overnight" was rejected because it is too close to other well-known farming games. Idea (not a decision): with seasons, fruit could be cheaper in its own season. The merchant's name is being changed (was "Orxan"); the new name is pending.

---

- **Date:** 2026-11-23
- **Topic:** Names in the game
- **Decision:**
  1. **All character names in the game are foreign names** of mixed international origin (different characters may come from different countries, e.g. Marco, Sofia, Leon, Yuki).
  2. This applies to **everyone**: the merchant (was "Orxan"), future buyer NPCs and the **whole family tree**. The family **relations stay exactly the same**; only the names are replaced.
  3. **Fruit names are shown in English in the game** (Cherry Plum, Sour Cherry, Mulberry, Morello Cherry, Sweet Cherry).
- **Status:** Confirmed
- **Affected systems:** characters / NPCs, family tree, merchant, `ItemData.display_name` of every fruit (e.g. `items/types/gilas.tres` "Gilas" → "Sweet Cherry"), harvest pop-ups and inventory panel (they show `display_name`)
- **Notes:** The new names themselves are **not chosen yet** — the user approves every name; do not invent official names. The old names (Orxan, Zöhrə, Gulnarə, …) remain only in `docs/The_Orchard_Project_Context.md` as original notes. **Not decided:** the language of the rest of the UI (currently placeholder Azerbaijani texts such as "İnventar", "Boşdur", "Gün"), and whether internal ids / file names (e.g. `&"gilas"`, `gilas.tres`) should also become English — ids are never shown to the player.

---

- **Date:** 2026-11-23
- **Topic:** New character names
- **Decision:** Variant A — each family branch has its own cultural origin; the merchant is **Bruno**.
  ```
  Rosa (grandmother)
  ├── Sofia (Mediterranean): Elio, Elias, Elena, Eloy
  ├── Henrik (Scandinavian): Freya, Nils, Astrid
  └── Yuki (Japanese): Kenji, Hana, Aiko
  ```
  Mapping from the old names: Zöhrə → Rosa · Gulnarə → Sofia · Elman → Elio · Elxan → Elias · Elnaz → Elena · Eltac → Eloy · İlqar → Henrik · Duyğu → Freya · Səid → Nils · Ülkər → Astrid · Aytən → Yuki · Vüqar → Kenji · Nubar → Hana · Zəhrə → Aiko · Orxan → Bruno.
- **Status:** Confirmed
- **Affected systems:** characters / NPCs, family tree, merchant, future dialogue and UI texts
- **Notes:** Genders were kept from the old names (female: Rosa, Sofia, Elena, Yuki, Freya, Astrid, Hana, Aiko; male: Elio, Elias, Eloy, Henrik, Nils, Kenji, Bruno). The "El-" pattern of Sofia's four children was kept on purpose. Future characters and buyer NPCs also get foreign names, approved by the user. `docs/The_Orchard_Project_Context.md` still contains the old names as original notes.
