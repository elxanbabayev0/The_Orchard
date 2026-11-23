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
- **Characters:** the player starts with their own character — a grandchild of Rosa whose name the player types in (confirmed 2026-11-23). Other family members are unlocked through XP levels ("invitations", the player chooses whom to invite) and become playable; each character has unique skills that affect gameplay and work while that character is active. Later they may also work as helpers. Skills are passive bonuses / fruit specialties, themed per family branch (Sofia: trade, Henrik: gardening, Yuki: movement/planting); invited characters stand on the farm and the player switches by walking up and pressing E (confirmed 2026-11-23). Each character's skill is listed in the Decision log; bonus numbers, XP amounts and level thresholds are **not decided**. See Decision log "XP and characters" and "Character skills and switching".
- **Merchant Bruno** (was "Orxan"; renamed 2026-11-23, see Decision log): buys the player's produce. Prices are **dynamic**: daily market price + the player's own sales (confirmed 2026-11-23, see Decision log). Prices based on other real players would need multiplayer/a server, which is **not decided** — do not assume multiplayer exists.
- **Buyer NPCs:** more buyers with their own personalities are planned. Names, looks, dialogue and order mechanics are not decided.
- **Visiting old woman (quest giver):** an elderly woman who visits the farm from time to time and gives tasks; completing them gives XP (confirmed 2026-11-23). She is **not** Rosa (unless the user decides otherwise). Her name (foreign, user approves), looks, personality, how often she comes, task types and rewards besides XP are **not decided**.
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

**Player-facing text (localization rule)** — confirmed 2026-11-23:
1. Never hard-code text the player sees. Use a translation key (e.g. `UI_SELL`, `ITEM_GILAS`) and add it to the translation CSV (`en` column for now).
2. In scripts use `tr("KEY")` (with `%` formatting for numbers, e.g. `tr("UI_PRICE") % price`); in scenes put the key directly into a `Label`/`Button` text (Godot translates it automatically).
3. Debug `print` messages, warnings and code comments are plain English and are not translated. Character names are not translated.

**Windows and Esc** — confirmed 2026-11-23:
1. Every new window (panel, dialog, menu inside the world) calls `UIState.track(self)` in `_ready` (after `hide()`), so the game pauses while it is open.
2. A window that can be closed handles `ui_cancel` (Esc) itself in `_unhandled_input` while visible and calls `get_viewport().set_input_as_handled()`.
3. Keep `PauseLayer` the first child of `Main`, so the pause menu only opens when nothing else used Esc.

## Current technical state (verify — may be outdated)
- Project main scene: `scenes/ui/main_menu.tscn` (see "Main menu" below). World scene: `scenes/world/main.tscn` → `Main` (`Node2D`) with `PauseLayer` (MUST stay the FIRST child — see "Pause menu"), `Ground` (placeholder `ColorRect`), `Entities` (Y-sorted: `Obstacles/Box1`, `Obstacles/Box2`, `Trees/` (Gilas1, Alca1 in the first row at y=192; Visne1, Tut1, Albali1 in the second row at y=448), `NPCs/Bruno`, `Family` (family members standing on the farm, filled in code), `Player` instance), `PlacementMode` (after `Entities`, so the ghost is drawn on top), `DayNightTint` and `UI` (`CanvasLayer`, does not move with the camera and is not tinted) → `ClockLabel`, `MoneyDisplay`, `LevelDisplay`, `ActiveCharacterDisplay`, `InventoryPanel`, `ItemPopups`, `TradeWindow`, `InvitationWindow`. Signal connections in the scene file: `Bruno.trade_requested` → `TradeWindow.open`, `InventoryPanel.plant_requested` → `PlacementMode.start`, `LevelDisplay.invite_requested` → `InvitationWindow.open`.
- Autoloads (order matters — later ones use earlier ones in `_ready`): `Registry`, `GameClock`, `Inventory`, `Wallet`, `Market`, `Progression`, `Characters`, `UIState`, `SaveManager`.
- Day/night: `DayNightTint` (`CanvasModulate`, `scenes/world/day_night_tint.gd`) samples its `day_colors` `Gradient` (editable in the Inspector; left = 00:00, right = 24:00) with `GameClock.get_day_progress()`. Affects only the world layer (layer 0), not the UI. The colors are a suggestion, not a decision.
- Game clock: autoload **`GameClock`** (`scripts/systems/game_clock.gd`, no `class_name` on purpose — the autoload name is already global). Stores `day` (from 1) + `minute_of_day` (0..1440), starts at 06:00, endless 24 h loop. All time moves through `advance(days)` (called from `_process` now; a future sleep mechanic can call it to skip time). `paused` stops time. Signals: `minute_changed(day, hour, minute)`, `day_changed(day)`, `time_advanced(delta_days)`. Helpers: `get_hour()`, `get_minute()`, `get_day_progress()` (0..1). Speed: `real_seconds_per_day = 120.0` — a TEMPORARY test value (edit it in the script; script autoloads do not show in the Inspector).
- Player: `scenes/player/player.tscn` (`CharacterBody2D` + `CollisionShape2D` + `Sprite2D` + `Camera2D` + `InteractionArea` (`Area2D`, circle r=40 at the feet)), placeholder 64×110, origin at the feet. Walking speed × (1 + `WALK_SPEED` skill bonus). Saves its position (`get_save_data()` → `{x, y}`); who it is comes from `Characters`.
- Movement: `scenes/player/player.gd`, speed `200`, `Input.get_vector("move_left", "move_right", "move_up", "move_down")`. Actions are bound to physical WASD + arrow keys in `project.godot`.
- Interaction: `interact` action (physical **E** — a suggestion, not a confirmed control scheme). On press, the player calls `interact(player)` on the nearest body in `InteractionArea` that has that method (duck typing: any tree / NPC / door becomes interactable just by having `interact(player)`).
- Trees (`scenes/trees/`):
  - `tree_data.gd` → `class_name TreeData` (`Resource`): id, `display_name` (translation key, e.g. `TREE_GILAS`), stage durations in **game days** (`sapling_days`, `young_days`, `flowering_days`, `unripe_days`; fractions allowed), `fruit: ItemData`, `harvest_yield`, one texture per stage.
  - `types/*.tres` → one file per tree type: `gilas.tres` (TREE_GILAS, 0.1 game day per stage ≈ 12 real s, yield 3, red), `alca.tres` (TREE_ALCA, faster: 0.08/0.08/0.06/0.1, yield 4, white flowers, yellow fruit), `visne.tres` (TREE_VISNE, yield 3, white flowers, bright red), `tut.tres` (TREE_TUT, yield 5, greenish flowers, dark purple), `albali.tres` (TREE_ALBALI, slowest, yield 3, white flowers, very dark red). All numbers are TEMPORARY test values; textures are placeholder gradients. New tree = duplicate a `.tres`, change values, add translation keys — no code.
  - `fruit_tree.tscn` / `fruit_tree.gd` → `class_name FruitTree` (`StaticBody2D`). **Not** named `Tree`, because Godot already has a built-in `Tree` UI class. Stages `SAPLING → YOUNG → FLOWERING → UNRIPE → RIPE`; ripe waits; `harvest()` adds `data.fruit` × `harvest_yield` to the `Inventory` (direct call), returns the amount, goes back to `FLOWERING` and emits `harvested(item, amount)` (kept for future sounds/effects/quests). Time is fed through `advance_time(game_days)`, connected to `GameClock.time_advanced` in `_ready()` (so trees pause with the clock and will grow during a future sleep skip). `StageLabel` is a temporary debug label.
- Items (`scenes/items/`): `item_data.gd` → `class_name ItemData` (`Resource`): `id` (stable, used for counting and future saves), `display_name` (translation key, e.g. `ITEM_GILAS`), `category` (enum `FRUIT`, `OTHER`, `SAPLING` — new values only at the END, .tres files store the number), `icon`, `description` (translation key), `base_price` (int, "Economy" group: market base price for sold items, fixed shop price for bought items; 0 = cannot be traded), `grows_into: TreeData` ("Planting" group, saplings only). `types/*.tres` → one file per item: `gilas.tres` (ITEM_GILAS "Sweet Cherry", base price 10), `alca.tres` (ITEM_ALCA "Cherry Plum", base price 7), `visne.tres` (ITEM_VISNE "Sour Cherry", 9), `tut.tres` (ITEM_TUT "Mulberry", 8), `albali.tres` (ITEM_ALBALI "Morello Cherry", 12); placeholder 48×48 icons; prices are test values. Saplings: `gilas_sapling.tres`, `alca_sapling.tres`, `visne_sapling.tres`, `tut_sapling.tres`, `albali_sapling.tres` (category `SAPLING`, `grows_into` → the matching tree type, test prices 30–50, icon = fruit colour fading to green, keys `ITEM_X_SAPLING` / `ITEM_X_SAPLING_DESC`). Note: `trees/types/X.tres` is the tree, `items/types/X.tres` is the fruit.
- Inventory: autoload **`Inventory`** (`scripts/systems/inventory.gd`). Shared, unlimited "id → amount" list (`_amounts`) plus `_items` (id → ItemData) for names/icons. API: `add_item(item, amount)`, `remove_item(item, amount)` (all-or-nothing, returns `bool`; items at 0 are removed from the list), `get_count(item)`, `has_item(item, amount)`, `get_items()`. Signals: `inventory_changed(item, new_amount)`, `item_added(item, amount)`.
- Inventory UI (`scenes/ui/`, the look is a placeholder):
  - `inventory_panel.tscn` / `.gd` — `PanelContainer` centered on screen, toggled by the `toggle_inventory` action (physical **I** — a suggestion). Rows (icon, name, "× amount") are built in code under `Margin/VBox/Rows`; sapling rows (category `SAPLING` with `grows_into`) get a `UI_PLANT` button that hides the panel and emits `plant_requested(item)`; shows `EmptyLabel` (`UI_INVENTORY_EMPTY`) when empty; title `UI_INVENTORY_TITLE`; refreshes on `Inventory.inventory_changed` only while visible. Tracked by `UIState` (game paused while open). `I` does not open it on top of another window; Esc closes it.
  - `item_popups.tscn` / `.gd` — `VBoxContainer` at the bottom center; on `Inventory.item_added` shows "[icon] +3 Sweet Cherry" (`UI_ITEM_GAINED`), which stays 1.5 s and fades out over 0.5 s with a `Tween`, then is freed.
- Money: autoload **`Wallet`** (`scripts/systems/wallet.gd`). Integer `money` (no cents), `STARTING_MONEY = 0` (TEMPORARY test value). API: `add_money(amount)`, `spend_money(amount)` (all-or-nothing, returns `bool`), `can_afford(amount)`; zero/negative amounts are rejected with a warning. Signal: `money_changed(new_amount, change)`. UI: `scenes/ui/money_display.tscn` (placeholder radial-gradient coin icon + amount, under the clock).
- Market: autoload **`Market`** (`scripts/systems/market.gd`). `price = base_price × daily factor × sales factor`, rounded, at least 1 (0 if `base_price` is 0). Daily factor: random per item, picked when first needed each day, cleared on `GameClock.day_changed`. Sales factor: `max(MIN_SALES_FACTOR, 1 − saturation × DROP_PER_UNIT)`; saturation += units sold and fades continuously via `GameClock.time_advanced`. TEMPORARY constants: `DAILY_RANGE 0.2`, `DROP_PER_UNIT 0.02`, `MIN_SALES_FACTOR 0.5`, `RECOVERY_PER_DAY 25`. API: `get_price(item)`, `get_sell_total(item, amount)` (each unit priced one by one, no side effects), `sell(item, amount)` (all-or-nothing via `Inventory.remove_item`, pays via `Wallet.add_money`, returns money earned or 0), `get_daily_factor(item)`, `get_buy_price(item)` (= `base_price`, fixed for now), `buy(item, amount)` (all-or-nothing via `Wallet.spend_money`, then `Inventory.add_item`, returns `bool`). Signal: `prices_changed(item)` (`null` = new day).
- Merchant (`scenes/npc/`): `merchant.tscn` / `merchant.gd` → `class_name Merchant` (`StaticBody2D`): stall + placeholder person, origin at the counter's bottom edge, collision only at the counter base; the person sprite is drawn before the counter so he stands behind it. `@export display_name` ("Bruno"), `@export buys: Array[ItemData]` (what the merchant buys — Bruno: all five fruits), `@export sells: Array[ItemData]` (what the merchant sells — Bruno: all five saplings; can move to another NPC later) — reusable for future buyers. `interact(player)` emits `trade_requested(merchant)`.
- Trade window: `scenes/ui/trade_window.tscn` / `.gd` (`PanelContainer`, centered; renamed from SellWindow). `open(merchant)` shows two sections, each hidden when empty (`EmptyLabel` `UI_MERCHANT_NOTHING_TO_TRADE` if both are): **Sell** (`UI_TRADE_SELL_HEADER`, rows for `merchant.buys`: icon, name, `UI_PRICE`, `UI_OWNED`, `SpinBox` 0..owned defaulting to all, live total from `Market.get_sell_total`, `UI_SELL` → `Market.sell`) and **Buy** (`UI_TRADE_BUY_HEADER`, rows for `merchant.sells`: icon, name, price, owned, `SpinBox` 0..affordable (max 99) defaulting to 1, total, `UI_BUY` → `Market.buy`). Rebuilds on `Inventory.inventory_changed`, `Market.prices_changed` and `Wallet.money_changed` while visible. Closes with `UI_CLOSE` or Esc. Tracked by `UIState` (game paused while open).
- Planting: `scenes/world/placement_mode.tscn` / `.gd` (`Node2D` with `Ghost` `Sprite2D` and `HintLayer` → `Hint` label `UI_PLACEMENT_HINT`). `start(item)` shows the sapling texture of `item.grows_into` as a half-transparent ghost; `snap_to_grid(point)` → tile centre (x) and tile BOTTOM edge (y) ("origin on the ground"); every physics frame `can_place_at(spot)` checks: within `PLANT_RANGE` (192 px) of the player, tile centre inside the `ground` rect, and no physics body overlapping the `FOOTPRINT_SIZE` (120×56) rect above the spot (trees, props, stall, player — anything with a collision shape counts automatically). Green/red `modulate`. Left click → `Inventory.remove_item(item, 1)`, instance `fruit_tree.tscn` with `data = grows_into` (set BEFORE `add_child`), add to `trees_parent` (`Entities/Trees`); stays active while saplings of that kind remain. Right click / Esc cancels. Exports set in `main.tscn`: `player`, `trees_parent`, `ground` (NodePaths). `PLANT_RANGE` and `FOOTPRINT_SIZE` are TEMPORARY test values (tree spacing not decided). Planted trees are saved by `SaveManager` like all other trees.
- Localization: `localization/translations.csv` (`keys,en`; Godot imports it to `translations.en.translation`, registered in Project Settings → Localization → Translations, i.e. `[internationalization] locale/translations` in `project.godot`). Key prefixes: `UI_` interface, `ITEM_` items, `TREE_` trees. Scenes put keys directly into `Label`/`Button` text (auto-translated when drawn — the `text` property still holds the key); scripts use `tr("KEY")` with `%` formatting. Fallback locale is `en`, so an unsupported OS language (e.g. `az_AZ`) shows English. Not translated: character names, numbers/symbols, debug prints, `StageLabel`.
- Registry: autoload **`Registry`** (`scripts/systems/registry.gd`, FIRST autoload). On start loads every resource in `scenes/items/types/`, `scenes/trees/types/` and `scenes/characters/types/` with `ResourceLoader.list_directory()` (also works in exported games) and maps `id` → resource. API: `get_item(id)`, `get_tree_type(id)` (NOT `get_tree` — that is a built-in Node method), `get_character(id)`, `get_all_items()`, `get_all_tree_types()`, `get_all_characters()`. Unknown ids return `null` with a warning; empty or duplicate ids are warned about and skipped. New items/trees are found automatically — no list to maintain.
- Save/load contract: every stateful system has `get_save_data() -> Dictionary` (plain JSON-safe values) and `load_save_data(data: Dictionary)`; `load_save_data({})` resets to the new-game state (missing keys fall back to defaults via `data.get(key, default)`). JSON returns every number as float → whole numbers are converted back with `int()`. Loading is silent: no `item_added` pop-ups, no `day_changed`. Implemented in `GameClock` (day, minute_of_day), `Wallet` (money), `Inventory` (`items` = ordered LIST of `{id, amount}` — a list because JSON sorts dictionary keys), `Market` (daily_factor, saturation) and `FruitTree` (`type`, `x`, `y`, `stage`, `stage_time`; its `load_save_data` only restores growth — the creator sets `data` and position before `add_child`). Unknown ids are skipped and broken values are clamped instead of crashing. **New systems that need saving must implement both functions and be added to `SaveManager`.**
- Saving: autoload **`SaveManager`** (`scripts/systems/save_manager.gd`, LAST autoload). File `user://saves/<slot>.json` (default slot `slot_1`; on Windows `%APPDATA%\Godot\app_userdata\The Orchard\saves\`; editor: Project → Open User Data Folder). Contents: `version` (`SAVE_VERSION = 1`), `saved_at`, `clock`, `wallet`, `inventory`, `market`, `progression`, `characters`, `trees` (every child of `Entities/Trees`), `player` (position, `Entities/Player`), `family` (positions of `Entities/Family` members). Load order matters: `characters` before `player` before `family`. Missing keys (older saves) fall back to defaults. Safe writing: `.tmp` file, then rename. Loading refuses broken files and newer versions; old versions go through `_upgrade()` (empty for now). On load all trees in `Entities/Trees` are replaced by the saved ones (the 5 trees in `main.tscn` are the new-game starting orchard). Autosave on `GameClock.day_changed` and on `NOTIFICATION_WM_CLOSE_REQUEST` (closing the window). The editor Stop button / F8 kills the game WITHOUT saving. `save_game` does nothing outside the world scene (no `Entities/Trees`). API: `has_save()`, `save_game()`, `load_game()`, `new_game()`, `continue_game()` (both: reset systems → `change_scene_to_file(WORLD_SCENE)` → `await get_tree().scene_changed` → load if continuing → unpause clock).
- Main menu: `scenes/ui/main_menu.tscn` / `.gd` (`Control`; placeholder green background, "The Orchard" title — a name, not translated). Pauses `GameClock`. Buttons `UI_MENU_CONTINUE` (only visible if `SaveManager.has_save()`), `UI_MENU_NEW_GAME` (if a save exists, a `ConfirmationDialog` asks first: `UI_MENU_NEW_GAME_CONFIRM_TEXT` / `_OK` / `UI_CANCEL`), `UI_MENU_QUIT`. The first visible button gets keyboard focus. Tip: open `main.tscn` and press F6 to test the world directly (fresh state, no load). New Game (after the confirm dialog, if any) shows the `NameEntry` panel ("UI_NAME_STORY": "You are Rosa's grandchild…", `UI_NAME_QUESTION`, `LineEdit` max 16 chars with `UI_NAME_PLACEHOLDER`, `UI_CANCEL` / `UI_NAME_START`); Start is disabled for an empty name, Enter starts, Esc cancels; it calls `SaveManager.new_game(player_name)`.
- XP / levels: autoload **`Progression`** (`scripts/systems/progression.gd`). All XP rules live here; other systems only report events: `on_harvest(fruit_count)` (in `FruitTree.harvest`), `on_sale(money)` (in `Market.sell`, with a money carry so small sales add up), `on_planted()` (in `PlacementMode`). `add_xp(amount)` (also for future old-woman tasks). XP is never spent; level thresholds: XP from level L to L+1 = `XP_PER_LEVEL_STEP` × L (L2 = 50, L3 = 150, L4 = 300…). Each level gained gives +1 `invitations` (`use_invitation()` for step 3). Signals `xp_changed(xp, level)`, `level_up(new_level)`, `invitations_changed(count)`. TEMPORARY test values: 1 XP per fruit, 1 XP per 10 money, 5 XP per sapling, step 50. `add_xp` adds the `XP` skill bonus (fraction kept in `_bonus_xp_carry`). Save: `xp`, `invitations`, `sale_money_carry`, `bonus_xp_carry` (level is recalculated from XP). UI: `scenes/ui/level_display.tscn` (`UI_LEVEL` + XP bar of the current level, under the money); "Level up!" (`UI_LEVEL_UP`, gold) via `ItemPopups.show_message(text, icon, color)`.
- Characters: `scenes/characters/character_data.gd` → `class_name CharacterData` (`Resource`): `id`, `display_name` (a NAME, not a translation key; empty for the player's own character), `parent_id` (family tree link, "" = none/not decided), `texture` (placeholder). Also `invitable` (false for Rosa and the player). Files in `scenes/characters/types/`: `player.tres` and the 14 family members (`rosa`, `sofia` → `elio`/`elias`/`elena`/`eloy`, `henrik` → `freya`/`nils`/`astrid`, `yuki` → `kenji`/`hana`/`aiko`) with placeholder colours per branch (Mediterranean warm, Scandinavian blue, Japanese pink/indigo, Rosa purple-grey). Autoload **`Characters`** (`scripts/systems/characters.gd`): `player_name` (typed in at New Game, `clean_name()` trims and limits to 16 chars), `set_player_name()`, `get_display_name(character)`, signal `player_name_changed`. Active character: `get_active()`, `is_active(c)`, `can_switch_to(c)` (own character or invited), `switch_to(c)` (all-or-nothing), signal `active_character_changed(c)` (also emitted after loading). Invitations: `can_invite(c)` (invitable, not unlocked yet, parent unlocked — a non-invitable parent like Rosa does not block), `get_invitable_now()` (parents first, then by name), `invite(c)` (all-or-nothing, uses `Progression.use_invitation()`), `get_unlocked()`, `is_unlocked(c)`, signal `character_unlocked(c)`. Save `{player_name, unlocked: [ids], active}` (unknown / duplicate / non-invitable ids skipped; an active id that is not playable → own character). `clean_name()` is a normal (not static) function — static functions called through an autoload give warnings. The player scene takes its sprite from `Characters.get_active().texture` (bottom at the feet) and shows the name in `NameLabel` above the head (`auto_translate_mode = DISABLED` so names are never translated); it updates on `active_character_changed`.
- Skills: `scenes/characters/skill_data.gd` → `class_name SkillData` (`Resource`): `effect` (enum `SELL_PRICE`, `SAPLING_PRICE`, `PRICE_DROP`, `HARVEST_BONUS`, `GROWTH_SPEED`, `WALK_SPEED`, `PLANT_RANGE`, `XP` — new values only at the END), `value` (meaning per effect, documented in the enum; TEMPORARY test values), `fruit` (fruit specialty, null = all), `applies_to(item)`, `get_description()` (text built from the numbers with `SKILL_*` keys). Each character's skill is a sub-resource inside its own `.tres` (`CharacterData.skill`; null for the player and Rosa). Systems never read skills directly: they call `Characters.get_bonus(effect, item)` (0.0 unless the ACTIVE character's skill matches). Hooks: `Market._unit_price` (sell price), `Market.get_buy_price` (saplings only), `Market._saturation_per_unit` (price drop), `FruitTree.harvest` (yield), `FruitTree.advance_time` (growth), `player.gd` (walking), `PlacementMode.get_plant_range()` (extra tiles), `Progression.add_xp` (XP). `Characters.get_skill_text(c)` = description or `UI_SKILL_NONE`.
- Family on the farm: `scenes/characters/family_member.tscn` / `.gd` → `class_name FamilyMember` (`StaticBody2D`, built like the player: collision at the feet, `NameLabel`). One stands on the farm for every playable character who is NOT active (invited members, and the player's own character while someone else is played). `interact(player)` (E) = switch: the player becomes this character and moves to this spot; this NPC becomes the previous character at the player's spot. Managed by `scenes/world/family_members.gd` on `Entities/Family` (Y-sorted; exports `player`, `ground`): new arrivals (`character_unlocked`) and members without a saved spot wait in a queue and are placed in `_physics_process` (only runs while unpaused; physics queries are safe there) on the first free spot from `ARRIVAL_OFFSETS` around the player. Save `{members: [{id, x, y}]}`; `load_save_data` rebuilds everyone from `Characters` (who is invited / active).
- Invitation UI: `scenes/ui/level_display.tscn` has an `InviteButton` (`UI_INVITE_BUTTON` "Invite family (%d)"), visible only while `Progression.invitations > 0` AND someone can be invited; it emits `invite_requested` → `InvitationWindow.open` (connection in `main.tscn`). `scenes/ui/invitation_window.tscn` / `.gd` (`PanelContainer`, tracked by `UIState`, Esc closes): `UI_INVITE_TITLE`, `UI_INVITATIONS_LEFT`, cards in an `HFlowContainer` (portrait, name with auto-translate disabled, `UI_CHILD_OF`, `UI_INVITE` button); each card also shows the skill (`Characters.get_skill_text`, gold); closes itself when no invitation or nobody is left. `ItemPopups` shows `UI_CHARACTER_JOINED` ("%s has come to the orchard!").
- Active character HUD: `scenes/ui/active_character_display.tscn` / `.gd` (`PanelContainer`, top-right corner, placeholder look): portrait, name (auto-translate disabled) and the skill text; updates on `active_character_changed` / `player_name_changed`.
- UI state: autoload **`UIState`** (`scripts/systems/ui_state.gd`). `track(window)` (called once in a window's `_ready`, after `hide()`) sets the window to `PROCESS_MODE_ALWAYS` and watches `visibility_changed` / `tree_exiting`. While at least one tracked window is visible, `get_tree().paused = true` — Godot's built-in pause stops everything with the default process mode (player, `GameClock`, trees, tweens…), so those scripts need no pause code. A window removed with its scene is dropped, so the game never stays paused. `is_blocking()`, signal `blocking_changed(blocking)`. Tracked: `InventoryPanel`, `TradeWindow`, `InvitationWindow`, `PauseMenu`. NOT tracked: `PlacementMode` (the player must walk while planting).
- Pause menu: `scenes/ui/pause_menu.tscn` / `.gd` → `PauseLayer` (`CanvasLayer`, layer 10, drawn on top) → `PauseMenu` (`Control`: `Dim` half-black `ColorRect` + panel with `UI_PAUSE_TITLE`, `UI_PAUSE_RESUME`, `UI_PAUSE_MAIN_MENU`, `UI_MENU_QUIT`). Tracked by `UIState`. Main Menu → hide first (un-pauses), then `SaveManager.return_to_main_menu()` (save + change scene); Quit → `SaveManager.quit_game()` (save + quit — `get_tree().quit()` sends no close notification). **Esc order:** `_unhandled_input` reaches nodes from the bottom of the scene tree up, so `PauseLayer` being the FIRST child of `Main` means it hears Esc LAST: trade window, inventory panel and placement mode close themselves first (`set_input_as_handled()`); only if nobody used Esc and `UIState.is_blocking()` is false does the pause menu open. Esc again = Resume.
- Check the real files before relying on this.

## Open questions (do not treat as decided)
Exact sprite sizes and art source resolution · map structure and world size · inventory capacity limits / slots / storage building (later) · money balance · XP amounts and level thresholds · tree balance numbers (stage durations, yields) and length of a game day · sleep / energy / day-start mechanic (later) · tree care, fallen/overripe fruit and quality (later) · seasons and weather · crafting / processing · buildings and farm expansion · quest types, rewards and the old woman's visit schedule · name of the visiting old woman (foreign, user approves) · NPC dialogue and AI · skill bonus numbers (the skill list is decided, numbers are test values) · where newly invited characters appear on the farm · the player character's parent in the family tree (left open) · Rosa's role as a background NPC · multiplayer or not · price balance (base prices, random range, drop/recovery speed, starting money) · currency name · merchant schedule (later) · sapling prices · planting range / farm boundaries · moving or removing trees (later) · separate sapling-seller NPC (later, name approved by user) · manual save / multiple save slots UI (later) · settings menu (later) · whether placement mode should pause time (suggestion: no) · names of future characters / buyer NPCs (foreign, user approves) · more UI languages later (e.g. Azerbaijani) and whether fruit names get translated then · game font (must support all chosen languages) · sound and music · target platforms (PC / mobile).

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

---

- **Date:** 2026-11-23
- **Topic:** UI language
- **Decision:** Variant D — the game UI is **English for now**, but built **localization-ready** from the start with Godot's translation system: every player-facing text is a translation **key** (e.g. `UI_SELL`), and the real texts live in a translation table (CSV) that currently has only an `en` column. Adding another language later = adding a column, no code changes.
- **Status:** Confirmed
- **Affected systems:** all UI texts (clock label, inventory panel, item pop-ups, sell window, merchant name label), `ItemData.display_name` (becomes a key, e.g. `ITEM_GILAS` → "Sweet Cherry"), a new translation CSV registered in Project Settings → Localization → Translations, code uses `tr("KEY")` for texts built in scripts
- **Notes:** Rule for new code: never hard-code player-facing text; always add a key to the translation table. Debug `print` messages and code comments stay plain English (not translated). Character names (Bruno, Rosa, …) are names, not translated. **Not decided:** which other languages come later (e.g. Azerbaijani), whether fruit names would be translated in those languages (the earlier decision says fruit names are shown in English), and the game font — it must support every chosen language's letters (for Azerbaijani: ə, ğ, ı, ö, ü, ç, ş).

---

- **Date:** 2026-11-23
- **Topic:** Spending money — buying and planting saplings
- **Decision:**
  1. **What to buy first:** saplings (new fruit trees).
  2. **Who sells them:** Bruno for now. The `Merchant` scene gets a separate `sells` list, so a different NPC (e.g. a nursery seller) can take it over later without code changes.
  3. **Where to plant:** freely, anywhere on the farm ground, snapped to the 64 px grid, only if the spot is free (no tree, prop, stall, etc.).
  4. **How to plant:** placement mode with the mouse — the chosen sapling shows a half-transparent "ghost" under the cursor, snapped to the grid, green = can plant, red = cannot; click to plant. Only works within a range around the player character.
  5. **Bought saplings go into the inventory** as items (e.g. "Sweet Cherry Sapling ×2") and are planted from there.
- **Status:** Confirmed
- **Affected systems:** `ItemData` (sapling items, category `SAPLING`, link to the `TreeData` they grow into), `Merchant` (`sells` list), trade/sell window (needs a buy side), `Wallet.spend_money`, `Inventory`, new placement mode (ghost preview, grid snap, free-spot check, range check), `FruitTree` instances created at runtime under `Entities/Trees`, translation keys for sapling names and buy UI
- **Notes:** Sapling prices, the planting range and farm boundaries are **not decided** (test values; the current ground is the placeholder `Ground` rect). Moving/removing trees, land expansion, tools, processing and buildings are later topics. Tilling soil with a tool before planting was not chosen (too close to other well-known farming games). Saplings planted at runtime will need save/load later (not decided).

---

- **Date:** 2026-11-23
- **Topic:** Save / load
- **Decision:**
  1. **When:** automatic — on every new game day (`GameClock.day_changed`) and when the player quits. No manual save button for now.
  2. **Slots:** one save for now, but the code works with a slot name (e.g. `"slot_1"`), so more slots can be added later without rewriting.
  3. **Format:** JSON text file in `user://` (on Windows: `%APPDATA%\Godot\app_userdata\The Orchard\`), with a `version` number so old saves can be upgraded later.
  4. **Start of the game:** a simple main menu — "Continue" (only if a save exists), "New Game", "Quit".
- **Status:** Confirmed
- **Affected systems:** new save system (likely an autoload), new main menu scene (becomes the project's main scene), `GameClock` (day, minute), `Wallet` (money), `Inventory` (id → amount), `Market` (daily factors, saturation), trees (every tree: type id, position, stage, stage time — all trees under `Entities/Trees` are saved; on load the scene's trees are replaced, so the trees placed in `main.tscn` are the "new game" starting orchard), item/tree lookup by `id` (needs a registry of all `ItemData` / `TreeData` files), translation keys for menu texts
- **Notes:** Godot `Resource` (`.tres`) files were rejected as a save format because they can carry script code (security risk when sharing saves). Binary was rejected for being hard to read/debug. Cheating by editing the JSON is acceptable in a single-player game. Manual saving, multiple slots in the UI and a settings menu (language, sound) are later topics.

---

- **Date:** 2026-11-23
- **Topic:** Windows, pausing and the pause menu
- **Decision:**
  1. **While a window is open** (inventory panel, trade window, pause menu, future windows): the player cannot move **and** the game clock stops. Trees, market recovery etc. wait too.
  2. **Pause menu on Esc** inside the game: "Resume", "Main Menu" (save, then go to the main menu), "Quit" (save, then quit). The game is paused while it is open. Esc first closes whatever is open (trade window, inventory, placement mode); only if nothing is open does it open the pause menu.
- **Status:** Confirmed
- **Affected systems:** new small UI-state tracker (e.g. a `UIState` autoload: windows report "opened"/"closed"; while at least one is open, player movement and `GameClock` are paused), `InventoryPanel`, `TradeWindow`, player movement/interaction, `GameClock.paused`, new pause menu scene, `SaveManager` (save before leaving to the menu or quitting), translation keys
- **Notes:** Question 3 (auto-close the trade window when walking away) is no longer needed: the player cannot walk while it is open. **Suggestion, not confirmed by the user:** the sapling placement mode is NOT counted as a window — the player must be able to walk to the planting spot, so movement and the clock keep running there.

---

- **Date:** 2026-11-23
- **Topic:** XP and characters
- **Decision:**
  1. **Starting character:** the player's own character, a **grandchild of Rosa**; the player types in the character's name (a name entry screen at New Game).
  2. **XP sources:**
     - everyday work: harvesting, selling, planting (each action gives a little XP);
     - **tasks from a visiting old woman**: an elderly woman comes to the farm from time to time and gives tasks; completing them gives XP. (Added by the user.)
  3. **How XP works:** levels. XP accumulates and is never spent; every new level gives an **"invitation"** — the player chooses which family member to invite to the orchard (unlocks that character).
  4. **What unlocked characters do:** they become **playable** — the player switches between characters, and a character's skill works while that character is active. Later they may also work on the farm as helpers (NPC AI, not now).
- **Status:** Confirmed
- **Affected systems:** new XP/level system (likely an autoload, with save/load), `FruitTree.harvest` / `Market.sell` / planting (give XP), new `CharacterData` resource (name, family branch, sprites, skill) for data-driven characters, player scene (uses the active character's data), skill effects in existing systems (e.g. harvest yield, growth speed, prices, movement speed, planting range), new quest system + old woman NPC (visits on a schedule via `GameClock`), name entry screen in the New Game flow, character switching and invitation UI, `SaveManager`, translation keys
- **Notes:** Not decided: XP per action and level thresholds; the skill list and which character gets which skill (example ideas, NOT decided: +1 harvest, faster growth, better sell prices, cheaper saplings, faster walking, larger planting range); the old woman's name (foreign, user approves), looks and personality, her visit schedule, task types and any rewards besides XP; whether invitations follow any order (e.g. by family branch); the helper role. The old woman is not Rosa unless the user decides otherwise.

---

- **Date:** 2026-11-23
- **Topic:** Invitations (unlocking family members)
- **Decision:**
  1. **Who can be invited:** 13 family members — Sofia, Henrik, Yuki and all 10 grandchildren (Elio, Elias, Elena, Eloy, Freya, Nils, Astrid, Kenji, Hana, Aiko). **Rosa is not playable**: she is the owner of the orchard and stays a background character (may become an NPC later).
  2. **Order — family rule:** a parent must be invited before their children. At the start only Sofia, Henrik and Yuki can be invited; after Sofia comes, Elio, Elias, Elena and Eloy become available, and so on. Within that rule the player chooses freely (one invitation per level).
  3. **The player character's parent:** left open for now — the player is simply "Rosa's grandchild".
- **Status:** Confirmed
- **Affected systems:** `CharacterData` files for the 13 family members (+ Rosa as data for the family tree, not invitable), `parent_id` used for the unlock rule, `Characters` (unlocked list, save/load), `Progression.use_invitation()`, a new invitation window (opens when an invitation is available), translation keys
- **Notes:** Rosa as a background NPC (role, dialogue) and the player's parent in the family tree are not decided. Character sprites are placeholders until real art exists; skills come in the next step.

---

- **Date:** 2026-11-23
- **Topic:** Character skills and switching
- **Decision:**
  1. **Skill type:** passive bonuses (D = A + B). While a character is active, their skill changes numbers in existing systems (e.g. harvest yield, growth speed, sell price, sapling price, walking speed, planting range, XP). Some characters get a **fruit specialty** instead (a bonus only for one fruit type). Active once-a-day skills (variant C) are not now, but the skill system should allow adding them later as new data, not new code.
  2. **Who gets what:** each family branch has its own theme — **Sofia's branch: trade** (prices, cheaper saplings), **Henrik's branch: gardening** (yield, growth), **Yuki's branch: movement / planting** (walking speed, planting range, XP). The parent has the general version of the branch skill, the children have different variations of it.
  3. **Switching:** invited characters **stand on the farm** as NPCs. The player walks to one and presses interact (E) to switch; the previous character stays standing at that spot.
  4. **Cost:** switching is free, any time (walking to the character is the natural limit).
  5. **The player's own character:** no special skill for now (an all-round character).
- **Status:** Confirmed
- **Affected systems:** new skill data (likely a `SkillData` resource referenced from `CharacterData`), `Characters` (active character id, switching, save/load), player scene (applies the active character's texture/name/speed), new family-member NPC scene in `Entities` (interact → switch, positions saved), `Inventory`/`FruitTree.harvest` (yield), `FruitTree` growth, `Market` (sell/buy prices), `PlacementMode` (range), `Progression` (XP), `SaveManager`, translation keys for skill names/descriptions
- **Skill list (confirmed 2026-11-23; the numbers are TEMPORARY test values):**
  - Trade — **Sofia**: all fruit sell +10% · Elio: saplings 15% cheaper · Elias: Sweet Cherry sells +25% · Elena: selling lowers prices half as fast · Eloy: Morello Cherry sells +25%
  - Gardening — **Henrik**: +1 fruit on every harvest · Freya: trees grow 20% faster · Nils: Sour Cherry harvest +2 · Astrid: Cherry Plum harvest +2
  - Movement / planting — **Yuki**: walking speed +25% · Kenji: Mulberry harvest +2 · Hana: planting range +2 tiles · Aiko: all XP +25%
- **Notes:** Each fruit has one specialist among the grandchildren; the parent holds the general branch skill. Where unlocked characters stand when they arrive (spawn spot) is a technical detail (suggestion: near the player / a fixed spot). Helper AI (characters working on their own) is still a later topic.
