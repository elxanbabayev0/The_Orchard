extends Node
## Oona's tasks: which one is active and how far along it is.
## Registered as the autoload "Quests".
## (Decision: Oona gives one task at a time; when it is done she comes back
## later with the reward and the next task. Rewards: XP + items, no money.)
##
## This script only keeps the task state. Oona herself (coming and going,
## talking) is a separate NPC that calls start_next() and claim_reward().
## Progress comes from GameEvents and only counts while a task is active.
##
## Written tasks (scenes/quests/types/) belong to story chapters
## (scenes/quests/chapters/) and come first: chapter by chapter, in `order`.
## A chapter opens when the player reaches its required level. While no written
## task is available (waiting for a level, or all chapters done), Oona gives
## generated everyday tasks (QuestGenerator), so she never runs out
## (decision "After Oona's tasks").

## Oona gave a new task.
signal quest_started(quest: QuestData)
## Progress changed (also emitted after loading, to refresh the UI).
signal quest_progressed(quest: QuestData, progress: int)
## The goal was reached; the reward waits until Oona comes back.
signal quest_done(quest: QuestData)
## Oona gave the reward; the task is finished.
signal quest_rewarded(quest: QuestData)
## The last task of a story chapter was rewarded (Oona "goes on a journey").
signal chapter_completed(chapter: ChapterData)
## Oona taught something new at the end of a chapter (e.g. &"cuttings").
signal feature_unlocked(feature: StringName)

## The task being worked on (null = none).
var _active: QuestData = null
var _progress: int = 0
## ids of finished (rewarded) WRITTEN tasks (generated ones are not listed).
var _finished: Array[StringName] = []
## Goal of the last task given (-1 = none): the generator does not repeat it.
var _last_goal: int = -1
var _generator := QuestGenerator.new()


## Same as FruitTree.GROUP (not referenced directly: autoloads compile early).
const TREE_GROUP := &"fruit_trees"


func _ready() -> void:
	GameEvents.fruit_harvested.connect(_on_fruit_harvested)
	GameEvents.item_sold.connect(_on_item_sold)
	GameEvents.sapling_planted.connect(_on_sapling_planted)
	GameEvents.tree_grown.connect(_on_tree_grown)
	GameEvents.tree_grafted.connect(func(_type: TreeData, _tree: Node2D) -> void: _refresh_tree_count())


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


## The next WRITTEN task: lowest chapter first, then lowest `order`, only from
## chapters that are open for the player's level. null when none is available
## (then start_next() generates a task).
func get_next() -> QuestData:
	var best: QuestData = null
	for quest in Registry.get_all_quests():
		if is_finished(quest) or quest == _active or not is_chapter_open(quest.chapter):
			continue
		if best == null or quest.chapter < best.chapter \
				or (quest.chapter == best.chapter and quest.order < best.order):
			best = quest
	return best


# --- Chapters ----------------------------------------------------------------

## A chapter is open when it exists and the player has its required level.
## (Lower chapters always come first because get_next() picks the lowest.)
func is_chapter_open(number: int) -> bool:
	var chapter := Registry.get_chapter(number)
	return chapter != null and Progression.level >= chapter.required_level


## Every written task of this chapter has been rewarded.
func is_chapter_complete(number: int) -> bool:
	var has_tasks := false
	for quest in Registry.get_all_quests():
		if quest.chapter == number:
			has_tasks = true
			if not is_finished(quest):
				return false
	return has_tasks


## The first chapter that is not complete yet (null = all done).
func get_current_chapter() -> ChapterData:
	for chapter in Registry.get_all_chapters():
		if not is_chapter_complete(chapter.number):
			return chapter
	return null


## Has Oona taught this feature yet? True when a complete chapter unlocks it.
## Derived from the finished tasks, so nothing extra is saved (and older saves
## that already finished the chapter get it automatically).
func is_feature_unlocked(feature: StringName) -> bool:
	for chapter in Registry.get_all_chapters():
		if chapter.unlocks.has(feature) and is_chapter_complete(chapter.number):
			return true
	return false


## The level the player needs for the next story chapter, or 0 if no chapter is
## waiting for a level (one is open, or all are done). Oona mentions it.
func get_next_chapter_level() -> int:
	var chapter := get_current_chapter()
	if chapter == null or is_chapter_open(chapter.number):
		return 0
	return chapter.required_level


## Oona gives the next task: the next written one, or a generated one when
## none is left. Returns it, or null if a task is already active (or there are
## no templates at all).
func start_next() -> QuestData:
	if _active != null:
		return null
	var quest := get_next()
	if quest == null:
		quest = _generator.generate(Progression.level, _last_goal)
	if quest == null:
		return null
	_active = quest
	_last_goal = quest.goal
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
	if not is_generated(quest):
		_finished.append(quest.id)
	if quest.reward_xp > 0:
		Progression.add_xp(quest.reward_xp)
	if quest.reward_item != null and quest.reward_amount > 0:
		Inventory.add_item(quest.reward_item, quest.reward_amount)
	quest_rewarded.emit(quest)
	if not is_generated(quest) and is_chapter_complete(quest.chapter):
		var chapter := Registry.get_chapter(quest.chapter)
		if chapter != null:
			chapter_completed.emit(chapter)
			for feature in chapter.unlocks:
				feature_unlocked.emit(feature)
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


func is_generated(quest: QuestData) -> bool:
	return quest != null and quest.id == QuestGenerator.GENERATED_ID


## Rebuilds a generated task from QuestData.to_dict() data. Broken values are
## fixed: unknown goal → null; unknown items are dropped; numbers kept sensible.
func _generated_from_dict(data: Dictionary) -> QuestData:
	var goal_value := int(data.get("goal", -1))
	if goal_value < 0 or goal_value >= QuestData.Goal.size():
		return null
	var quest := QuestData.new()
	quest.id = QuestGenerator.GENERATED_ID
	quest.chapter = 0
	quest.goal = goal_value as QuestData.Goal
	quest.target = maxi(1, int(data.get("target", 1)))
	quest.filter_item = _item_or_null(str(data.get("filter", "")))
	quest.reward_xp = maxi(0, int(data.get("reward_xp", 0)))
	quest.reward_item = _item_or_null(str(data.get("reward_item", "")))
	quest.reward_amount = maxi(0, int(data.get("reward_amount", 1)))
	return quest


func _item_or_null(id_text: String) -> ItemData:
	return Registry.get_item(StringName(id_text)) if id_text != "" else null


# --- Save / load -------------------------------------------------------------
# load_save_data({}) = new-game state (no task, nothing finished).

func get_save_data() -> Dictionary:
	var finished := []
	for id in _finished:
		finished.append(String(id))
	var data := {
		"active": String(_active.id) if _active != null else "",
		"progress": _progress,
		"finished": finished,
		"last_goal": _last_goal,
	}
	if is_generated(_active):
		data["generated"] = _active.to_dict() # no file to find it by id
	return data


func load_save_data(data: Dictionary) -> void:
	_finished.clear()
	for id_text in data.get("finished", []):
		var quest := Registry.get_quest(StringName(str(id_text)))
		if quest != null and not _finished.has(quest.id):
			_finished.append(quest.id)
	_last_goal = int(data.get("last_goal", -1))
	var active_id := StringName(str(data.get("active", "")))
	if active_id == QuestGenerator.GENERATED_ID:
		var saved = data.get("generated", {})
		_active = _generated_from_dict(saved) if saved is Dictionary else null
	elif active_id != &"":
		_active = Registry.get_quest(active_id)
	else:
		_active = null
	if _active != null and _finished.has(_active.id):
		_active = null
	_progress = clampi(int(data.get("progress", 0)), 0, _active.target) if _active != null else 0
	quest_progressed.emit(_active, _progress)
	# The saved trees are put back into the world right after this: count them then.
	_refresh_tree_count.call_deferred()
