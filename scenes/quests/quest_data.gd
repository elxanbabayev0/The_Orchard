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
	GROW_SAPLINGS,  ## `target` saplings grow up into fruit trees (trees of `filter_item` fruit, if set)
	HAVE_TREES,     ## have `target` fruit trees in the orchard (of `filter_item` fruit, if set) —
	                ## counts the trees that are there, also the ones planted before the task
	TAKE_CUTTING,   ## take `target` cuttings from rare trees (only `filter_item` cuttings, if set)
	GRAFT_TREE,     ## graft `target` trees (only with `filter_item` cuttings, if set)
	EARN_MONEY,     ## earn `target` money by selling (only selling `filter_item`, if set)
	INVITE_FAMILY,  ## invite `target` family members
	SWITCH_CHARACTER, ## switch characters `target` times (walk up to a family member, press E)
}

## Unique, never-changing name used in save files (e.g. &"plant_two").
@export var id: StringName = &""
## Story chapter this written task belongs to (see ChapterData). Generated tasks: 0.
@export var chapter: int = 1
## Oona gives the tasks of a chapter in this order (lowest first).
@export var order: int = 0
@export var goal: Goal = Goal.PLANT_SAPLINGS
## How many (saplings, harvests, fruit...). TEMPORARY test values.
@export var target: int = 1
## Optional: only this item counts (a sapling for PLANT_SAPLINGS, a fruit for
## the others; for tree goals: trees that grow this fruit). Empty = any.
@export var filter_item: ItemData
## HAVE_TREES only: count only grown trees (flowering or later) — also the ones
## that grew before the task started (e.g. "Have a grown Golden Sweet Cherry tree").
@export var grown_only: bool = false
## Oona's line when she gives this task (a translation KEY; empty = her general
## "I have a task for you" line — generated tasks have none).
@export var line: String = ""

@export_group("Reward")
@export var reward_xp: int = 0
## Optional item reward (saplings now, rare varieties later).
@export var reward_item: ItemData
@export var reward_amount: int = 1


## Does an event with this item count for the task?
func counts_item(item: ItemData) -> bool:
	return filter_item == null or filter_item == item


## Does a tree of this type count (tree goals: compared by its fruit)?
func counts_tree(tree_type: TreeData) -> bool:
	return tree_type != null and counts_item(tree_type.fruit)


## Player-facing task text, e.g. "Plant 2 saplings" or "Sell 10 × Mulberry".
## For a target of 1 a "_ONE" key is used if it exists ("Plant a sapling"),
## because the CSV translation table has no plural forms.
func get_description() -> String:
	var key := "QUEST_GOAL_%s" % Goal.keys()[goal]
	if goal == Goal.HAVE_TREES and grown_only:
		key = "QUEST_GOAL_HAVE_GROWN_TREES"
	if filter_item != null:
		key += "_ITEM"
	if target == 1 and tr(key + "_ONE") != key + "_ONE":
		key += "_ONE"
	var text := tr(key)
	if filter_item != null:
		return text % [target, tr(filter_item.display_name)] if text.count("%") >= 2 else text % tr(filter_item.display_name)
	return text % target if text.contains("%") else text


# --- Generated tasks in save files --------------------------------------------
# Written tasks are saved by id. Generated ones (QuestGenerator) have no file,
# so all their parameters are saved instead. Rebuilding them needs the Registry,
# so that part lives in Quests (data resources must not use autoloads: they can
# be compiled before the autoloads exist).

func to_dict() -> Dictionary:
	return {
		"goal": goal,
		"target": target,
		"filter": String(filter_item.id) if filter_item != null else "",
		"reward_xp": reward_xp,
		"reward_item": String(reward_item.id) if reward_item != null else "",
		"reward_amount": reward_amount,
	}
