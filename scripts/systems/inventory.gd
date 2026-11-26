extends Node
## The shared farm inventory. Registered as the autoload "Inventory".
## (Decision: a simple "item -> amount" list, unlimited, shared by all characters.)
##
## Items are counted by their ItemData.id. The ItemData itself is remembered
## too, so the UI can show names and icons.

## Emitted whenever the amount of an item changes (added or removed).
## After loading a save it is also emitted once with item = null ("everything may have changed").
signal inventory_changed(item: ItemData, new_amount: int)
## Emitted only when items are added, with how many were added (for "+3 Gilas" pop-ups).
signal item_added(item: ItemData, amount: int)

## id -> amount
var _amounts: Dictionary[StringName, int] = {}
## id -> ItemData (so we know the name and icon of each id)
var _items: Dictionary[StringName, ItemData] = {}
## id -> how many of `_amounts` are "fresh" (decision "Day / night rework":
## fruit picked early in the morning sells a little higher). Always <= the amount.
## The rules (when fruit is fresh, until when, how much more it is worth) live
## in Market; the Inventory only counts.
var _fresh: Dictionary[StringName, int] = {}


## `fresh`: the added units are fresh fruit (see Market.is_fresh_picking_time).
func add_item(item: ItemData, amount: int = 1, fresh: bool = false) -> void:
	if item == null or amount <= 0:
		push_warning("Inventory.add_item: invalid item or amount.")
		return
	_items[item.id] = item
	_amounts[item.id] = get_count(item) + amount
	if fresh:
		_fresh[item.id] = get_fresh_count(item) + amount
	item_added.emit(item, amount)
	inventory_changed.emit(item, _amounts[item.id])


## How many of this item are fresh (0 for most items).
func get_fresh_count(item: ItemData) -> int:
	if item == null:
		return 0
	return _fresh.get(item.id, 0)


## Every fresh unit becomes a normal one (called by Market when freshness ends).
func clear_fresh() -> void:
	if _fresh.is_empty():
		return
	var changed := _fresh.keys()
	_fresh.clear()
	for id in changed:
		if _items.has(id):
			inventory_changed.emit(_items[id], _amounts[id])


## Removes items. Returns false (and removes nothing) if there are not enough.
## Fresh units go first (Market.get_sell_total prices them the same way).
func remove_item(item: ItemData, amount: int = 1) -> bool:
	if item == null or amount <= 0:
		push_warning("Inventory.remove_item: invalid item or amount.")
		return false
	if not has_item(item, amount):
		return false
	var new_amount := get_count(item) - amount
	var fresh_left := maxi(0, get_fresh_count(item) - amount)
	if fresh_left > 0:
		_fresh[item.id] = fresh_left
	else:
		_fresh.erase(item.id)
	if new_amount == 0:
		_amounts.erase(item.id)
		_items.erase(item.id)
	else:
		_amounts[item.id] = new_amount
	inventory_changed.emit(item, new_amount)
	return true


func get_count(item: ItemData) -> int:
	if item == null:
		return 0
	return _amounts.get(item.id, 0)


func has_item(item: ItemData, amount: int = 1) -> bool:
	return get_count(item) >= amount


## All items currently in the inventory (in the order they were first added).
func get_items() -> Array[ItemData]:
	var result: Array[ItemData] = []
	result.assign(_items.values())
	return result


# --- Save / load -------------------------------------------------------------
# Items are saved by id; the Registry turns ids back into ItemData.
# Saved as a LIST (not a dictionary) because JSON sorts dictionary keys
# alphabetically — a list keeps the order the player is used to.
# load_save_data({}) = new-game state (empty inventory).

func get_save_data() -> Dictionary:
	var entries := []
	for id in _amounts:
		entries.append({"id": String(id), "amount": _amounts[id]})
	var fresh_entries := []
	for id in _fresh:
		fresh_entries.append({"id": String(id), "amount": _fresh[id]})
	return {"items": entries, "fresh": fresh_entries}


func load_save_data(data: Dictionary) -> void:
	_amounts.clear()
	_items.clear()
	_fresh.clear()
	var entries: Array = data.get("items", [])
	for entry in entries:
		var item := Registry.get_item(StringName(entry.get("id", "")))
		var amount := int(entry.get("amount", 0))
		if item == null or amount <= 0:
			continue # unknown or removed item: skip it instead of crashing
		_items[item.id] = item
		_amounts[item.id] = amount
	# Older saves have no "fresh" list: then nothing is fresh.
	for entry in data.get("fresh", []):
		var id := StringName(str(entry.get("id", "")))
		var fresh := mini(int(entry.get("amount", 0)), _amounts.get(id, 0))
		if fresh > 0:
			_fresh[id] = fresh
	# Tell the UI to refresh. item_added is NOT emitted (no "+3" pop-ups on load).
	for id in _items:
		inventory_changed.emit(_items[id], _amounts[id])
	inventory_changed.emit(null, 0) # also refresh when the inventory became empty
