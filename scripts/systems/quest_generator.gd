class_name QuestGenerator
extends RefCounted
## Makes Oona's everyday tasks from QuestTemplates (scenes/quests/templates/).
## Not an autoload: Quests creates one and asks it for a task when needed.
##
##   target = base_target + target_per_level × (level − 1)   (× FILTER_TARGET_FACTOR for one-fruit tasks)
##   reward = target × xp_per_unit XP (at least MIN_REWARD_XP) + one common sapling
##
## The created QuestData only lives in memory (id GENERATED_ID); the save file
## stores its parameters (see QuestData.to_dict / from_dict).

const GENERATED_ID := &"generated"
## One-fruit tasks are harder, so their target is smaller. TEMPORARY.
const FILTER_TARGET_FACTOR := 0.6
const MIN_REWARD_XP := 5
## One more sapling as reward every this many levels. TEMPORARY.
const LEVELS_PER_EXTRA_SAPLING := 5

## Goals that can be limited to one fruit.
const FRUIT_GOALS: Array[QuestData.Goal] = [
	QuestData.Goal.HARVEST_TIMES,
	QuestData.Goal.PICK_FRUIT,
	QuestData.Goal.SELL_FRUIT,
]

var _rng := RandomNumberGenerator.new()


func _init(seed_value: int = -1) -> void:
	if seed_value >= 0:
		_rng.seed = seed_value # tests: the same tasks every time
	else:
		_rng.randomize()


## A new task for this level. `previous_goal` (-1 = none) is not repeated, so
## two tasks in a row are always different. Returns null if there are no templates.
func generate(level: int, previous_goal: int = -1) -> QuestData:
	var template := _pick_template(previous_goal)
	if template == null:
		return null
	var quest := QuestData.new()
	quest.id = GENERATED_ID
	quest.chapter = 0 # not part of a story chapter
	quest.goal = template.goal
	var target := template.base_target + template.target_per_level * maxi(0, level - 1)
	if FRUIT_GOALS.has(template.goal) and _rng.randf() < template.filter_chance:
		quest.filter_item = _random_item(ItemData.Category.FRUIT)
		if quest.filter_item != null:
			target *= FILTER_TARGET_FACTOR
	quest.target = maxi(1, roundi(target))
	quest.reward_xp = maxi(MIN_REWARD_XP, roundi(quest.target * template.xp_per_unit))
	quest.reward_item = _random_item(ItemData.Category.SAPLING)
	quest.reward_amount = 1 + floori(float(level) / LEVELS_PER_EXTRA_SAPLING)
	return quest


## Weighted random template, skipping `previous_goal` when anything else exists.
func _pick_template(previous_goal: int) -> QuestTemplate:
	var choices: Array[QuestTemplate] = []
	for template in Registry.get_all_quest_templates():
		if template.weight > 0 and template.goal != previous_goal:
			choices.append(template)
	if choices.is_empty(): # only one kind exists: repeating is better than nothing
		for template in Registry.get_all_quest_templates():
			if template.weight > 0:
				choices.append(template)
	var total := 0
	for template in choices:
		total += template.weight
	if total <= 0:
		return null
	var roll := _rng.randi_range(1, total)
	for template in choices:
		roll -= template.weight
		if roll <= 0:
			return template
	return choices.back()


## A random COMMON item of a category (fruit for filters, sapling for rewards).
## Rare varieties are never used: they only come from story chapters.
func _random_item(category: ItemData.Category) -> ItemData:
	var items: Array[ItemData] = []
	for item in Registry.get_all_items():
		if item.category == category and not item.rare:
			items.append(item)
	if items.is_empty():
		return null
	items.sort_custom(func(a: ItemData, b: ItemData) -> bool: return a.id < b.id) # same order every run
	return items[_rng.randi_range(0, items.size() - 1)]
