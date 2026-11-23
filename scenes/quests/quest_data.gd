class_name QuestData
extends Resource
## One of Oona's tasks. Each task is a .tres file in scenes/quests/types/,
## so new tasks can be added without new code.
## (Decision: activity goals and orchard-care goals; rewards are XP + items,
## no money.)
##
## The task text is built from the goal and the numbers (get_description()),
## so the text and the numbers can never disagree.

## What the player has to do. Add new values only at the END (.tres files store the number).
enum Goal {
	PLANT_SAPLINGS, ## plant `target` saplings (of `filter_item`, if set)
	HARVEST_TIMES,  ## harvest trees `target` times (trees of `filter_item` fruit, if set)
	PICK_FRUIT,     ## pick `target` pieces of fruit in total (only `filter_item`, if set)
	SELL_FRUIT,     ## sell `target` pieces of fruit to a merchant (only `filter_item`, if set)
}

## Unique, never-changing name used in save files (e.g. &"plant_two").
@export var id: StringName = &""
## Oona gives her tasks in this order (lowest first).
@export var order: int = 0
@export var goal: Goal = Goal.PLANT_SAPLINGS
## How many (saplings, harvests, fruit...). TEMPORARY test values.
@export var target: int = 1
## Optional: only this item counts (a sapling for PLANT_SAPLINGS, a fruit for
## the others). Empty = any.
@export var filter_item: ItemData

@export_group("Reward")
@export var reward_xp: int = 0
## Optional item reward (saplings now, rare varieties later).
@export var reward_item: ItemData
@export var reward_amount: int = 1


## Does an event with this item count for the task?
func counts_item(item: ItemData) -> bool:
	return filter_item == null or filter_item == item


## Player-facing task text, e.g. "Plant 2 saplings" or "Sell 10 × Mulberry".
func get_description() -> String:
	var key: String = Goal.keys()[goal]
	if filter_item != null:
		return tr("QUEST_GOAL_%s_ITEM" % key) % [target, tr(filter_item.display_name)]
	return tr("QUEST_GOAL_%s" % key) % target
