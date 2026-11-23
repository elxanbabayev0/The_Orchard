extends SceneTree
## Tool (not part of the game): writes the debug TEST SAVE (slot "test",
## user://saves/test.json). The main menu shows "Load test save (debug)" in
## editor runs when this file exists. The real slot_1 is never touched.
##
## The test save is a ready-made state for trying the newer systems:
## - Oona's story chapter 1 is finished → cuttings and grafting are taught,
##   Oona is on the farm and gives an everyday task (chapter 2 needs level 3),
## - a ripe Golden Sweet Cherry tree (take a cutting from it),
## - a Golden Sweet Cherry Cutting + a Snow Mulberry Cutting in the inventory
##   (graft them onto the ripe Sweet Cherry / Mulberry trees, or plant them),
## - Sofia and Henrik invited (switch characters / skills), some money and saplings.
##
## Run from the project folder (PowerShell, $g = path to the Godot exe):
##   & $g --headless --path . --script res://tools/make_test_save.gd
## Run it again any time to get a fresh test save.

const WORLD_SCENE := "res://scenes/world/main.tscn"
const FRUIT_TREE_SCENE := "res://scenes/trees/fruit_tree.tscn"
const RIPE := 4
const FLOWERING := 2


func _initialize() -> void:
	_make.call_deferred()


func _make() -> void:
	# Autoloads by node (class names of autoloads are not known in --script mode).
	var save_manager := root.get_node("SaveManager")
	var registry := root.get_node("Registry")
	var clock := root.get_node("GameClock")

	save_manager._reset_systems()
	save_manager.current_slot = "" # nothing may autosave into a real slot here
	root.get_node("Characters").load_save_data({"player_name": "Tester", "unlocked": ["sofia", "henrik"]})
	change_scene_to_file(WORLD_SCENE)
	await scene_changed
	clock.paused = true
	var world := current_scene

	# Time, money, XP (level 2: chapter 2 waits for level 3).
	clock.load_save_data({"day": 3, "minute_of_day": 8 * 60})
	root.get_node("Wallet").add_money(300)
	root.get_node("Progression").load_save_data({"xp": 60})

	# Oona: chapter 1 finished (= cuttings taught), she is on the farm.
	var chapter_one := []
	for quest in registry.get_all_quests():
		if quest.chapter == 1:
			chapter_one.append(String(quest.id))
	root.get_node("Quests").load_save_data({"finished": chapter_one})
	root.get_node("OonaVisits").load_save_data({})

	# Inventory.
	var inventory := root.get_node("Inventory")
	for entry in [["golden_gilas_cutting", 1], ["snow_tut_cutting", 1], ["gilas_sapling", 2], ["tut_sapling", 1]]:
		inventory.add_item(registry.get_item(StringName(entry[0])), entry[1])

	# Orchard: every starting tree ripe, plus a ripe Golden Sweet Cherry tree.
	var trees := world.get_node("Entities/Trees")
	for tree in trees.get_children():
		tree.load_save_data({"stage": RIPE})
	var golden: Node2D = load(FRUIT_TREE_SCENE).instantiate()
	golden.data = registry.get_tree_type(&"golden_gilas")
	golden.position = trees.to_local(Vector2(736, 192))
	trees.add_child(golden)
	golden.load_save_data({"stage": RIPE})

	# Player next to the orchard; invited family members get placed near them.
	world.get_node("Entities/Player").global_position = Vector2(448, 320)
	await physics_frame
	await physics_frame

	var ok: bool = save_manager.save_game(save_manager.TEST_SLOT)
	print("Test save written: %s → %s" % [ok, ProjectSettings.globalize_path("user://saves/test.json")])
	quit()
