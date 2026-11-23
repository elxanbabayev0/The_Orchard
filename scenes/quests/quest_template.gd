class_name QuestTemplate
extends Resource
## A recipe for Oona's generated everyday tasks (decision: generated tasks
## between and after story chapters; targets grow with the player's level;
## rewards are XP + common saplings).
## Each template is a .tres file in scenes/quests/templates/ — balance them in
## the Inspector. All numbers are TEMPORARY test values.

@export var goal: QuestData.Goal = QuestData.Goal.PLANT_SAPLINGS
## Target at level 1.
@export var base_target: int = 1
## How much the target grows per level above 1 (fractions add up: 0.5 = +1 every 2 levels).
@export var target_per_level: float = 0.0
## Chance (0..1) that the task is about one fruit only (e.g. "Sell 6 × Mulberry").
## Only used for fruit goals (HARVEST_TIMES, PICK_FRUIT, SELL_FRUIT).
@export_range(0.0, 1.0, 0.05) var filter_chance: float = 0.0
## Reward XP for each unit of the target (e.g. 2 XP per fruit sold).
@export var xp_per_unit: float = 1.0
## How often this template is picked compared to the others (0 = never).
@export var weight: int = 1
