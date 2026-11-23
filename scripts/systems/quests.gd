extends Node
## Oona's tasks: which one is active and how far along it is.
## Registered as the autoload "Quests".
## (Decision: Oona gives one task at a time; when it is done she comes back
## later with the reward and the next task. Rewards: XP + items, no money.)
##
## This script only keeps the task state. Oona herself (coming and going,
## talking) is a separate NPC that calls start_next() and claim_reward().
## Progress comes from GameEvents and only counts while a task is active.

## Oona gave a new task.
signal quest_started(quest: QuestData)
## Progress changed (also emitted after loading, to refresh the UI).
signal quest_progressed(quest: QuestData, progress: int)
## The goal was reached; the reward waits until Oona comes back.
signal quest_done(quest: QuestData)
## Oona gave the reward; the task is finished.
signal quest_rewarded(quest: QuestData)

## The task being worked on (null = none).
var _active: QuestData = null
var _progress: int = 0
## ids of finished (rewarded) tasks.
var _finished: Array[StringName] = []


## Same as FruitTree.GROUP (not referenced directly: autoloads compile early).
const TREE_GROUP := &"fruit_trees"


func _ready() -> void:
	GameEvents.fruit_harvested.connect(_on_fruit_harvested)
	GameEvents.item_sold.connect(_on_item_sold)
	GameEvents.sapling_planted.connect(_on_sapling_planted)
	GameEvents.tree_grown.connect(_on_tree_grown)


# --- State -------------------------------------------------------------------

func get_active() -> QuestData:
	return _active


func get_progress() -> int:
	return _progress


## Goal reached, reward not given yet.
func is_done() -> bool:
	return _active != null and _progress >= _active.target


func is_finished(quest: QuestData) -> bool:
	return quest != null and _finished.has(quest.id)


## The next task Oona would give (lowest `order` not finished yet), or null if
## she has nothing left. What happens after the last task is not decided.
func get_next() -> QuestData:
	var best: QuestData = null
	for quest in Registry.get_all_quests():
		if is_finished(quest) or quest == _active:
			continue
		if best == null or quest.order < best.order:
			best = quest
	return best


## Oona gives the next task. Returns it, or null if a task is already active
## or there is nothing left.
func start_next() -> QuestData:
	if _active != null:
		return null
	var quest := get_next()
	if quest == null:
		return null
	_active = quest
	_progress = 0
	quest_started.emit(quest)
	quest_progressed.emit(quest, _progress)
	_refresh_tree_count() # HAVE_TREES: trees already there count
	return quest


## Oona gives the reward for a done task. Returns false if it is not done yet.
func claim_reward() -> bool:
	if not is_done():
		return false
	var quest := _active
	_active = null
	_progress = 0
	_finished.append(quest.id)
	if quest.reward_xp > 0:
		Progression.add_xp(quest.reward_xp)
	if quest.reward_item != null and quest.reward_amount > 0:
		Inventory.add_item(quest.reward_item, quest.reward_amount)
	quest_rewarded.emit(quest)
	return true


# --- Progress from game events -------------------------------------------------

func _on_fruit_harvested(fruit: ItemData, amount: int) -> void:
	if _active == null or not _active.counts_item(fruit):
		return
	match _active.goal:
		QuestData.Goal.HARVEST_TIMES:
			_add_progress(1)
		QuestData.Goal.PICK_FRUIT:
			_add_progress(amount)


func _on_item_sold(item: ItemData, amount: int, _money: int) -> void:
	if _active != null and _active.goal == QuestData.Goal.SELL_FRUIT and _active.counts_item(item):
		_add_progress(amount)


func _on_sapling_planted(sapling: ItemData, _tree: Node2D) -> void:
	if _active != null and _active.goal == QuestData.Goal.PLANT_SAPLINGS and _active.counts_item(sapling):
		_add_progress(1)
	_refresh_tree_count()


func _on_tree_grown(tree_type: TreeData, _tree: Node2D) -> void:
	if _active != null and _active.goal == QuestData.Goal.GROW_SAPLINGS and _active.counts_tree(tree_type):
		_add_progress(1)


## HAVE_TREES is a state, not an event: count the matching trees in the world.
func _refresh_tree_count() -> void:
	if _active == null or _active.goal != QuestData.Goal.HAVE_TREES or is_done():
		return
	var count := 0
	for tree in get_tree().get_nodes_in_group(TREE_GROUP):
		if not tree.is_queued_for_deletion() and _active.counts_tree(tree.get("data")):
			count += 1
	if count > _progress:
		_add_progress(count - _progress)


func _add_progress(amount: int) -> void:
	if is_done():
		return # already done: extra work does not matter
	_progress = mini(_progress + amount, _active.target)
	quest_progressed.emit(_active, _progress)
	if is_done():
		quest_done.emit(_active)


# --- Save / load -------------------------------------------------------------
# load_save_data({}) = new-game state (no task, nothing finished).

func get_save_data() -> Dictionary:
	var finished := []
	for id in _finished:
		finished.append(String(id))
	return {
		"active": String(_active.id) if _active != null else "",
		"progress": _progress,
		"finished": finished,
	}


func load_save_data(data: Dictionary) -> void:
	_finished.clear()
	for id_text in data.get("finished", []):
		var quest := Registry.get_quest(StringName(str(id_text)))
		if quest != null and not _finished.has(quest.id):
			_finished.append(quest.id)
	var active_text := str(data.get("active", ""))
	_active = Registry.get_quest(StringName(active_text)) if active_text != "" else null
	if _active != null and _finished.has(_active.id):
		_active = null
	_progress = clampi(int(data.get("progress", 0)), 0, _active.target) if _active != null else 0
	quest_progressed.emit(_active, _progress)
	# The saved trees are put back into the world right after this: count them then.
	_refresh_tree_count.call_deferred()
