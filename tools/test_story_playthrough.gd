extends SceneTree
## Tool (not part of the game): plays Oona's whole story from a NEW GAME to the
## end, headless, like a player would — using the real game functions
## (planting, harvesting, selling, buying, cuttings, grafting, inviting,
## switching characters) and the real game clock. Prints every talk with Oona
## and a list of problems at the end.
##
## Nothing is saved: SaveManager.current_slot stays "" (autosave does nothing).
## Still back up user://saves before running (see the project's test rules).
##
## Run from the project folder (PowerShell, $g = path to the Godot console exe):
##   & $g --headless --path . --script res://tools/test_story_playthrough.gd

const WORLD_SCENE := "res://scenes/world/main.tscn"
const FRUIT_TREE_SCENE := "res://scenes/trees/fruit_tree.tscn"

# QuestData.Goal (numbers, so this script does not depend on class loading order).
const PLANT_SAPLINGS := 0
const HARVEST_TIMES := 1
const PICK_FRUIT := 2
const SELL_FRUIT := 3
const GROW_SAPLINGS := 4
const HAVE_TREES := 5
const TAKE_CUTTING := 6
const GRAFT_TREE := 7
const EARN_MONEY := 8
const INVITE_FAMILY := 9
const SWITCH_CHARACTER := 10
# FruitTree.Stage
const FLOWERING := 2
const RIPE := 4
# OonaVisits.Talk names, for the log.
const TALK_NAMES := ["NOTHING", "GAVE_TASK", "REMINDER", "REWARD_AND_TASK", "REWARD_LAST", "NO_TASKS", "REWARD_JOURNEY", "JOURNEY_PACKING"]
const REWARD_JOURNEY := 6
const JOURNEY_PACKING := 7
## Generated tasks to play after the last chapter (checks the endless part).
const EXTRA_GENERATED_AFTER_STORY := 2
const TIME_STEP := 0.02 # game days per clock step

var problems: Array[String] = []
var world: Node
var trees: Node
var player: Node2D
var clock: Node
var quests: Node
var oona: Node
var registry: Node
var inventory: Node
var market: Node
var wallet: Node
var characters: Node
var progression: Node
var _next_spot := 0
var _generated_done := 0
var _story_finished_at_generated := -1


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var save_manager := root.get_node("SaveManager")
	registry = root.get_node("Registry")
	clock = root.get_node("GameClock")
	quests = root.get_node("Quests")
	oona = root.get_node("OonaVisits")
	inventory = root.get_node("Inventory")
	market = root.get_node("Market")
	wallet = root.get_node("Wallet")
	characters = root.get_node("Characters")
	progression = root.get_node("Progression")

	save_manager._reset_systems()
	save_manager.current_slot = "" # never save anything
	characters.set_player_name("Tester")
	change_scene_to_file(WORLD_SCENE)
	await scene_changed
	world = current_scene
	trees = world.get_node("Entities/Trees")
	player = world.get_node("Entities/Player")
	clock.paused = true # time only moves when this script moves it
	quests.quest_rewarded.connect(_on_rewarded)
	quests.chapter_completed.connect(func(c): print("   ★ chapter %d complete" % c.number))
	quests.feature_unlocked.connect(func(f): print("   ★ feature unlocked: %s" % f))

	_check_texts()

	var talks := 0
	while talks < 400:
		if _story_finished_at_generated >= 0 \
				and _generated_done - _story_finished_at_generated >= EXTRA_GENERATED_AFTER_STORY:
			break
		if not oona.is_present():
			if not _wait_for_oona():
				problems.append("Oona never came back (day %d, active task: %s)" % [clock.day, _quest_name(quests.get_active())])
				break
		var result: int = oona.talk()
		talks += 1
		var quest = quests.get_active()
		print("Day %2d  talk → %-16s task: %s" % [clock.day, TALK_NAMES[result], _quest_name(quest)])
		if result == 5 or result == 4: # NO_TASKS / REWARD_LAST: she should never run out
			problems.append("Oona ran out of tasks (talk result %s)" % TALK_NAMES[result])
			break
		if result == REWARD_JOURNEY:
			# Talking again the same day must NOT give a task (she is leaving).
			var again: int = oona.talk()
			print("Day %2d  talk → %-16s (talked again on the journey day)" % [clock.day, TALK_NAMES[again]])
			if again != JOURNEY_PACKING or quests.get_active() != null:
				problems.append("Talking again after the journey goodbye gave %s" % TALK_NAMES[again])
			# Wait until she has left, then until she is back.
			for i in int(2.0 / TIME_STEP):
				if not oona.is_present():
					break
				_step()
			var left_day: int = clock.day
			if oona.is_present():
				problems.append("Oona did not leave for her journey")
			elif not _wait_for_oona():
				problems.append("Oona never came back from her journey")
				break
			print("        (journey: away from day %d, back on day %d)" % [left_day, clock.day])
			continue
		if quest != null and not quests.is_done():
			var before: int = quests.get_progress()
			await _do_task(quest)
			if not quests.is_done():
				problems.append("Could not finish task %s (progress %d → %d of %d)" % [_quest_name(quest), before, quests.get_progress(), quest.target])
				break
		# Leave the rest of the day: she rewards on the next talk (now or after returning).
		await process_frame

	print("\n=== RESULT ===")
	print("Day %d, level %d, money %d, chapters complete: %s" % [clock.day, progression.level, wallet.money, _complete_chapters()])
	if quests.get_current_chapter() != null:
		problems.append("Story not finished: chapter %d still open" % quests.get_current_chapter().number)
	if problems.is_empty():
		print("No problems found.")
	else:
		print("%d problem(s):" % problems.size())
		for p in problems:
			print("  - " + p)
	quit()


func _on_rewarded(quest) -> void:
	var text := "   ✓ reward: %d XP" % quest.reward_xp
	if quest.reward_item != null:
		text += " + %d × %s" % [quest.reward_amount, tr(quest.reward_item.display_name)]
	print(text + "  (level %d, invitations %d)" % [progression.level, progression.invitations])
	if quests.is_generated(quest):
		_generated_done += 1
		if quests.get_current_chapter() == null and _story_finished_at_generated < 0:
			_story_finished_at_generated = _generated_done - 1
	elif quests.get_current_chapter() == null and _story_finished_at_generated < 0:
		_story_finished_at_generated = _generated_done


# --- Doing a task like a player ---------------------------------------------

func _do_task(quest) -> void:
	for attempt in 60:
		if quests.is_done():
			return
		match quest.goal:
			PLANT_SAPLINGS:
				var sapling = quest.filter_item if quest.filter_item != null else _cheapest_sapling()
				_plant(sapling)
			HARVEST_TIMES, PICK_FRUIT:
				_harvest_one(_fruit_or_any(quest.filter_item))
			SELL_FRUIT:
				_sell_fruit(quest.filter_item, quest.target - quests.get_progress())
			EARN_MONEY:
				_sell_fruit(quest.filter_item, 5)
			GROW_SAPLINGS:
				var tree = _plant(_sapling_for_fruit(quest.filter_item) if quest.filter_item != null else _cheapest_sapling())
				_grow_until(tree, FLOWERING)
			HAVE_TREES:
				var tree = _plant(_sapling_for_fruit(quest.filter_item))
				if quest.grown_only:
					_grow_until(tree, FLOWERING)
			TAKE_CUTTING:
				_take_cutting()
			GRAFT_TREE:
				_graft()
			INVITE_FAMILY:
				await _invite()
			SWITCH_CHARACTER:
				await _switch()
			_:
				problems.append("Test bot does not know goal %d" % quest.goal)
				return
		await process_frame
	if not quests.is_done():
		problems.append("Gave up on %s after 60 attempts" % _quest_name(quest))


func _plant(sapling) -> Node:
	if sapling == null:
		problems.append("No sapling to plant (day %d)" % clock.day)
		return null
	if not inventory.has_item(sapling):
		if sapling.rare or sapling.base_price <= 0:
			problems.append("Need %s but it is not in the inventory and cannot be bought" % tr(sapling.display_name))
			return null
		_buy(sapling)
	# Same steps as PlacementMode._try_plant.
	if not inventory.remove_item(sapling, 1):
		return null
	var tree: Node2D = load(FRUIT_TREE_SCENE).instantiate()
	tree.data = sapling.grows_into
	tree.position = trees.to_local(_free_spot())
	trees.add_child(tree)
	root.get_node("GameEvents").sapling_planted.emit(sapling, tree)
	return tree


func _buy(item) -> void:
	var price: int = market.get_buy_price(item)
	if not wallet.can_afford(price):
		_sell_fruit(null, 999) # sell everything first
	if not wallet.can_afford(price):
		_earn_money(price)
	if not market.buy(item, 1):
		problems.append("Could not buy %s (money %d, price %d)" % [tr(item.display_name), wallet.money, price])


func _earn_money(amount: int) -> void:
	for i in 40:
		if wallet.money >= amount:
			return
		_harvest_one(null)
		_sell_fruit(null, 999)


func _harvest_one(fruit) -> void:
	var tree = _find_tree(fruit, -1)
	if tree == null:
		tree = _plant(_sapling_for_fruit(fruit))
	if tree == null:
		return
	_grow_until(tree, RIPE)
	if tree.harvest() <= 0:
		problems.append("Harvest gave nothing (%s)" % tr(tree.data.display_name))


func _sell_fruit(fruit, amount: int) -> void:
	var left := amount
	for i in 30:
		if left <= 0:
			return
		var sold_any := false
		for item in inventory.get_items():
			if left <= 0:
				break
			if item.category != 0 or (fruit != null and item != fruit) or item.base_price <= 0:
				continue # FRUIT category only
			var n := mini(left, inventory.get_count(item))
			if n > 0 and market.sell(item, n) > 0:
				left -= n
				sold_any = true
		if not sold_any:
			if amount >= 999:
				return # "sell everything" and nothing is left
			_harvest_one(fruit)


func _take_cutting() -> void:
	for tree in trees.get_children():
		if tree.data.variety_of != null: # rare tree
			_grow_until(tree, FLOWERING)
			for i in 400:
				if tree.can_take_cutting():
					break
				_step()
			if tree.take_cutting():
				return
	problems.append("No rare tree to take a cutting from (day %d)" % clock.day)


func _graft() -> void:
	for tree in trees.get_children():
		if tree.data.variety_of == null and tree.can_graft():
			tree.graft()
			return
	# No cutting or no grown common tree: get a cutting first, then try again.
	var had_cutting := false
	for item in inventory.get_items():
		if item.category == 3: # CUTTING
			had_cutting = true
	if not had_cutting:
		_take_cutting()
	for tree in trees.get_children():
		if tree.data.variety_of == null and tree.stage < FLOWERING:
			_grow_until(tree, FLOWERING)


func _invite() -> void:
	var candidates: Array = characters.get_invitable_now()
	if candidates.is_empty():
		problems.append("INVITE task: nobody can be invited")
		return
	if progression.invitations <= 0:
		problems.append("INVITE task given while the player has NO invitation (level %d) — the bot earns XP until the next level" % progression.level)
		var target_level: int = progression.level + 1
		for i in 200:
			if progression.level >= target_level:
				break
			_harvest_one(null)
			_sell_fruit(null, 999)
	characters.invite(candidates[0])
	await physics_frame
	await physics_frame


func _switch() -> void:
	await physics_frame
	await physics_frame
	var family := world.get_node("Entities/Family")
	for member in family.get_children():
		if member.has_method("interact"):
			member.interact(player)
			return
	problems.append("SWITCH task: no family member standing on the farm")


# --- Helpers -------------------------------------------------------------------

func _step() -> void:
	clock.advance(TIME_STEP)


func _grow_until(tree, stage: int) -> void:
	if tree == null:
		return
	for i in 2000:
		if tree.stage >= stage:
			return
		_step()
	problems.append("Tree %s never reached stage %d" % [tr(tree.data.display_name), stage])


func _wait_for_oona() -> bool:
	for i in int(10.0 / TIME_STEP): # at most 10 game days
		_step()
		if oona.is_present():
			return true
	return false


func _find_tree(fruit, min_stage: int):
	var best = null
	for tree in trees.get_children():
		if tree.is_queued_for_deletion() or tree.stage < min_stage:
			continue
		if fruit != null and tree.data.fruit != fruit:
			continue
		if fruit == null and tree.data.variety_of != null:
			continue # "any fruit": use common trees
		if best == null or tree.stage > best.stage:
			best = tree
	return best


func _fruit_or_any(fruit):
	return fruit


## A sapling (or cutting, for rare fruit) that grows the given fruit.
func _sapling_for_fruit(fruit):
	if fruit == null:
		return _cheapest_sapling()
	for item in inventory.get_items(): # owned first (rare saplings / cuttings)
		if item.grows_into != null and item.grows_into.fruit == fruit:
			return item
	for item in registry.get_all_items():
		if item.category == 2 and item.grows_into != null and item.grows_into.fruit == fruit:
			return item
	problems.append("No sapling grows %s" % tr(fruit.display_name))
	return null


func _cheapest_sapling():
	var best = null
	for item in registry.get_all_items():
		if item.category == 2 and not item.rare and item.base_price > 0:
			if best == null or item.base_price < best.base_price:
				best = item
	return best


func _free_spot() -> Vector2:
	# A grid far away from the starting orchard, on the ground (-1024..1024).
	var col := _next_spot % 12
	var row := _next_spot / 12
	_next_spot += 1
	return Vector2(-896 + col * 128, 576 + row * 128)


func _quest_name(quest) -> String:
	if quest == null:
		return "-"
	var chapter := "everyday" if quests.is_generated(quest) else "ch%d.%d" % [quest.chapter, quest.order]
	return "%s \"%s\"" % [chapter, quest.get_description()]


func _complete_chapters() -> Array:
	var done := []
	for chapter in registry.get_all_chapters():
		if quests.is_chapter_complete(chapter.number):
			done.append(chapter.number)
	return done


## Every text key the story uses must exist in the translation table.
func _check_texts() -> void:
	var keys: Array[String] = ["UI_OONA_CHAPTER_DONE", "UI_OONA_GIVE_TASK", "UI_OONA_NEXT_TASK", "UI_OONA_PACKING"]
	for chapter in registry.get_all_chapters():
		keys.append_array(chapter.start_lines)
		keys.append_array(chapter.end_lines)
		for feature in chapter.unlocks:
			keys.append("UI_OONA_UNLOCK_%s" % String(feature).to_upper())
	for quest in registry.get_all_quests():
		if quest.line != "":
			keys.append(quest.line)
		if quest.get_description().begins_with("QUEST_GOAL"):
			problems.append("Task %s has no description text (%s)" % [quest.id, quest.get_description()])
	var missing := 0
	for key in keys:
		if tr(key) == key:
			problems.append("Missing translation text: " + key)
			missing += 1
	print("Text check: %d keys, %d missing" % [keys.size(), missing])
