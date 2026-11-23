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
## Where the trees live inside the world scene (main.tscn).
const TREES_PATH := "Entities/Trees"
const FRUIT_TREE_SCENE := preload("res://scenes/trees/fruit_tree.tscn")


func _ready() -> void:
	GameClock.day_changed.connect(_on_day_changed)
	# TEMPORARY until the main menu exists (next step): load the save on start.
	_load_on_start.call_deferred()


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
		"trees": trees,
	}
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
	_load_trees(trees_container, data.get("trees", []))
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
	var scene := get_tree().current_scene
	if scene == null:
		return null
	return scene.get_node_or_null(TREES_PATH)


func _path(slot: String) -> String:
	return SAVE_FOLDER + slot + ".json"


func _load_on_start() -> void:
	if has_save():
		load_game()


func _on_day_changed(_day: int) -> void:
	save_game()


## Save when the player closes the game window.
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_game()
