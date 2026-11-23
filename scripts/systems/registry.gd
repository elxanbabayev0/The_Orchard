extends Node
## Finds every item, tree type, character and quest by its `id`. Registered as the autoload "Registry".
##
## Save files only store short ids (e.g. "gilas"), not whole resources.
## When loading, the Registry turns an id back into its ItemData / TreeData / CharacterData.
## It reads all .tres files in the type folders once, when the game starts,
## so new content is found automatically — no list to keep up to date.

const ITEM_FOLDER := "res://scenes/items/types/"
const TREE_FOLDER := "res://scenes/trees/types/"
const CHARACTER_FOLDER := "res://scenes/characters/types/"
const QUEST_FOLDER := "res://scenes/quests/types/"
const QUEST_TEMPLATE_FOLDER := "res://scenes/quests/templates/"

## id -> ItemData
var _items: Dictionary[StringName, ItemData] = {}
## id -> TreeData
var _trees: Dictionary[StringName, TreeData] = {}
## id -> CharacterData
var _characters: Dictionary[StringName, CharacterData] = {}
## id -> QuestData
var _quests: Dictionary[StringName, QuestData] = {}
## Templates for generated tasks (no ids: they are never saved by id).
var _quest_templates: Array[QuestTemplate] = []


func _ready() -> void:
	for resource in _load_folder(ITEM_FOLDER):
		if resource is ItemData:
			_add(_items, resource.id, resource)
	for resource in _load_folder(TREE_FOLDER):
		if resource is TreeData:
			_add(_trees, resource.id, resource)
	for resource in _load_folder(CHARACTER_FOLDER):
		if resource is CharacterData:
			_add(_characters, resource.id, resource)
	for resource in _load_folder(QUEST_FOLDER):
		if resource is QuestData:
			_add(_quests, resource.id, resource)
	for resource in _load_folder(QUEST_TEMPLATE_FOLDER):
		if resource is QuestTemplate:
			_quest_templates.append(resource)


## Returns the quest with this id, or null (with a warning) if there is none.
func get_quest(id: StringName) -> QuestData:
	if not _quests.has(id):
		push_warning("Registry: unknown quest id '%s'." % id)
		return null
	return _quests[id]


func get_all_quest_templates() -> Array[QuestTemplate]:
	return _quest_templates.duplicate()


func get_all_quests() -> Array[QuestData]:
	var result: Array[QuestData] = []
	result.assign(_quests.values())
	return result


## Returns the character with this id, or null (with a warning) if there is none.
func get_character(id: StringName) -> CharacterData:
	if not _characters.has(id):
		push_warning("Registry: unknown character id '%s'." % id)
		return null
	return _characters[id]


func get_all_characters() -> Array[CharacterData]:
	var result: Array[CharacterData] = []
	result.assign(_characters.values())
	return result


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
