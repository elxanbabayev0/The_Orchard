extends Node
## Finds every item and tree type by its `id`. Registered as the autoload "Registry".
##
## Save files only store short ids (e.g. "gilas"), not whole resources.
## When loading, the Registry turns an id back into its ItemData / TreeData.
## It reads all .tres files in the type folders once, when the game starts,
## so new items/trees are found automatically — no list to keep up to date.

const ITEM_FOLDER := "res://scenes/items/types/"
const TREE_FOLDER := "res://scenes/trees/types/"

## id -> ItemData
var _items: Dictionary[StringName, ItemData] = {}
## id -> TreeData
var _trees: Dictionary[StringName, TreeData] = {}


func _ready() -> void:
	for resource in _load_folder(ITEM_FOLDER):
		if resource is ItemData:
			_add(_items, resource.id, resource)
	for resource in _load_folder(TREE_FOLDER):
		if resource is TreeData:
			_add(_trees, resource.id, resource)


## Returns the item with this id, or null (with a warning) if there is none.
func get_item(id: StringName) -> ItemData:
	if not _items.has(id):
		push_warning("Registry: unknown item id '%s'." % id)
		return null
	return _items[id]


## Returns the tree type with this id, or null (with a warning) if there is none.
func get_tree_type(id: StringName) -> TreeData:
	if not _trees.has(id):
		push_warning("Registry: unknown tree id '%s'." % id)
		return null
	return _trees[id]


func get_all_items() -> Array[ItemData]:
	var result: Array[ItemData] = []
	result.assign(_items.values())
	return result


func get_all_tree_types() -> Array[TreeData]:
	var result: Array[TreeData] = []
	result.assign(_trees.values())
	return result


## Loads every resource file in a folder.
## ResourceLoader.list_directory() also works in exported games, where Godot
## may convert and rename .tres files.
func _load_folder(folder: String) -> Array[Resource]:
	var result: Array[Resource] = []
	for file_name in ResourceLoader.list_directory(folder):
		if file_name.ends_with("/"):
			continue # a sub-folder
		var resource := load(folder + file_name)
		if resource != null:
			result.append(resource)
	return result


func _add(table: Dictionary, id: StringName, resource: Resource) -> void:
	if id == &"":
		push_warning("Registry: %s has an empty id." % resource.resource_path)
		return
	if table.has(id):
		push_warning("Registry: duplicate id '%s' (%s and %s)." % [id, table[id].resource_path, resource.resource_path])
		return
	table[id] = resource
