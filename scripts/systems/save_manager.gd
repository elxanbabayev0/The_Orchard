extends Node
## Saves and loads the game. Registered as the autoload "SaveManager".
## (Decision: automatic saving on every new game day and when quitting;
## one slot for now, but the code works with slot names; JSON in user://.)
##
## Every system has get_save_data() / load_save_data(data). This script only
## collects their data into one JSON file and gives it back when loading.

## Bump this when the save layout changes, and teach _upgrade() to convert old saves.
const SAVE_VERSION := 1
const SAVE_FOLDER := "user://saves/"
const DEFAULT_SLOT := "slot_1"
## The world scene the menu starts.
const WORLD_SCENE := "res://scenes/world/main.tscn"
const MAIN_MENU_SCENE := "res://scenes/ui/main_menu.tscn"
## Where the trees live inside the world scene (main.tscn).
const TREES_PATH := "Entities/Trees"
## Where the family members standing on the farm live (scenes/world/family_members.gd).
const FAMILY_PATH := "Entities/Family"
const PLAYER_PATH := "Entities/Player"
const FRUIT_TREE_SCENE := preload("res://scenes/trees/fruit_tree.tscn")


func _ready() -> void:
	GameClock.day_changed.connect(_on_day_changed)


## Main menu → "New Game": fresh systems, the world with its starting orchard,
## and the name the player typed in for their character.
func new_game(player_name: String = "") -> void:
	_start_world(false, DEFAULT_SLOT, player_name)


## Main menu → "Continue": the world, then the saved state on top of it.
func continue_game(slot: String = DEFAULT_SLOT) -> void:
	_start_world(true, slot, "")


func _start_world(load_save: bool, slot: String, player_name: String) -> void:
	_reset_systems()
	if not load_save:
		Characters.set_player_name(player_name)
	get_tree().change_scene_to_file(WORLD_SCENE)
	# Changing scenes takes a moment; wait until the world is really there.
	await get_tree().scene_changed
	if load_save:
		load_game(slot)
	GameClock.paused = false


## Pause menu → "Main Menu": save, then leave the world.
func return_to_main_menu() -> void:
	save_game()
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)


## Pause menu → "Quit": save, then close the game.
## (get_tree().quit() does not send the "window closing" notification, so save here.)
func quit_game() -> void:
	save_game()
	get_tree().quit()


## Puts every system back to the new-game state (load_save_data({}) = defaults).
func _reset_systems() -> void:
	GameClock.load_save_data({})
	Wallet.load_save_data({})
	Inventory.load_save_data({})
	Market.load_save_data({})
	Progression.load_save_data({})
	Characters.load_save_data({})
	Quests.load_save_data({})


func has_save(slot: String = DEFAULT_SLOT) -> bool:
	return FileAccess.file_exists(_path(slot))


## Writes the whole game state to the slot's file. Returns false on failure.
func save_game(slot: String = DEFAULT_SLOT) -> bool:
	var trees_container := _get_trees_container()
	if trees_container == null:
		return false # not in the world (e.g. in a menu): nothing to save
	var trees := []
	for tree in trees_container.get_children():
		if tree is FruitTree:
			trees.append(tree.get_save_data())
	var data := {
		"version": SAVE_VERSION,
		"saved_at": Time.get_datetime_string_from_system(),
		"clock": GameClock.get_save_data(),
		"wallet": Wallet.get_save_data(),
		"inventory": Inventory.get_save_data(),
		"market": Market.get_save_data(),
		"progression": Progression.get_save_data(),
		"characters": Characters.get_save_data(),
		"quests": Quests.get_save_data(),
		"trees": trees,
	}
	var player := _get_world_node(PLAYER_PATH)
	if player != null:
		data["player"] = player.get_save_data()
	var family := _get_world_node(FAMILY_PATH)
	if family != null:
		data["family"] = family.get_save_data()
	DirAccess.make_dir_recursive_absolute(SAVE_FOLDER)
	# Safe writing: write a temporary file first, then replace the real one.
	# If the game crashes while writing, the old save is still fine.
	var temp_path := _path(slot) + ".tmp"
	var file := FileAccess.open(temp_path, FileAccess.WRITE)
	if file == null:
		push_error("SaveManager: cannot write %s (error %d)." % [temp_path, FileAccess.get_open_error()])
		return false
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
	var error := DirAccess.rename_absolute(temp_path, _path(slot))
	if error != OK:
		push_error("SaveManager: cannot replace the save file (error %d)." % error)
		return false
	print("Game saved: %s (day %d)" % [_path(slot), GameClock.day])
	return true


## Reads the slot's file and restores the game state. Returns false on failure
## (no file, broken file, or a save from a newer game version).
func load_game(slot: String = DEFAULT_SLOT) -> bool:
	var trees_container := _get_trees_container()
	if trees_container == null or not has_save(slot):
		return false
	var text := FileAccess.get_file_as_string(_path(slot))
	var data = JSON.parse_string(text)
	if not data is Dictionary:
		push_error("SaveManager: %s is not a valid save file." % _path(slot))
		return false
	var version := int(data.get("version", 0))
	if version > SAVE_VERSION:
		push_error("SaveManager: this save is from a newer version of the game.")
		return false
	data = _upgrade(data, version)

	GameClock.load_save_data(data.get("clock", {}))
	Wallet.load_save_data(data.get("wallet", {}))
	Inventory.load_save_data(data.get("inventory", {}))
	Market.load_save_data(data.get("market", {}))
	Progression.load_save_data(data.get("progression", {}))
	Characters.load_save_data(data.get("characters", {}))
	Quests.load_save_data(data.get("quests", {}))
	_load_trees(trees_container, data.get("trees", []))
	var player := _get_world_node(PLAYER_PATH)
	if player != null:
		player.load_save_data(data.get("player", {}))
	# After Characters (who is invited / active) and the player (arrivals stand near them).
	var family := _get_world_node(FAMILY_PATH)
	if family != null:
		family.load_save_data(data.get("family", {}))
	print("Game loaded: %s (day %d)" % [_path(slot), GameClock.day])
	return true


## Replaces every tree in the world with the saved ones.
func _load_trees(container: Node, saved_trees: Array) -> void:
	for old_tree in container.get_children():
		container.remove_child(old_tree)
		old_tree.queue_free()
	for saved in saved_trees:
		var tree_type := Registry.get_tree_type(StringName(saved.get("type", "")))
		if tree_type == null:
			continue # unknown tree type: skip it instead of crashing
		var tree := FRUIT_TREE_SCENE.instantiate() as FruitTree
		tree.data = tree_type # before add_child: FruitTree._ready() reads it
		tree.position = container.to_local(Vector2(float(saved.get("x", 0)), float(saved.get("y", 0))))
		container.add_child(tree)
		tree.load_save_data(saved) # after add_child: needs its child nodes
		tree.name = "%s_%d" % [String(tree_type.id).capitalize(), container.get_child_count()]


## Converts an old save to the current layout. Nothing to do yet (only version 1 exists).
func _upgrade(data: Dictionary, _from_version: int) -> Dictionary:
	return data


func _get_trees_container() -> Node:
	return _get_world_node(TREES_PATH)


## A node inside the world scene, or null outside the world (e.g. in a menu).
func _get_world_node(path: String) -> Node:
	var scene := get_tree().current_scene
	if scene == null:
		return null
	return scene.get_node_or_null(path)


func _path(slot: String) -> String:
	return SAVE_FOLDER + slot + ".json"


func _on_day_changed(_day: int) -> void:
	save_game()


## Save when the player closes the game window.
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_game()
