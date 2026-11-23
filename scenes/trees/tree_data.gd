class_name TreeData
extends Resource
## Data for one tree type (e.g. gilas, alça, tut).
## Each tree type is a separate .tres file built from this script,
## so new trees can be added in the editor without writing new code.
##
## Durations are in GAME DAYS (fractions allowed: 0.5 = half a day).
## The tree grows continuously with the GameClock.

@export var id: StringName = &""
## Translation KEY of the tree's name (e.g. "TREE_GILAS"); shown with tr().
@export var display_name: String = ""

@export_group("Growth (happens once)")
## Time from planting until the sapling becomes a young tree.
@export var sapling_days: float = 1.0
## Time from young tree until mature tree. After this the fruit cycle starts.
@export var young_days: float = 1.0

## How fast this tree grows compared to normal (1.0 = normal, 1.3 = 30% faster —
## e.g. Snow Mulberry's trait). Affects every stage.
@export_range(0.1, 5.0, 0.05) var growth_speed: float = 1.0

@export_group("Fruit cycle (repeats)")
## Time the tree spends flowering.
@export var flowering_days: float = 1.0
## Time from unripe fruit until ripe fruit. Ripe fruit then waits until harvested.
@export var unripe_days: float = 1.0

@export_group("Harvest")
## Which item (fruit) this tree gives.
@export var fruit: ItemData
## How many fruits one harvest gives.
@export var harvest_yield: int = 3

@export_group("Variety")
## For rare varieties: the common tree type it is a variety of (Golden Sweet
## Cherry → Sweet Cherry). Its cuttings can be grafted onto trees of that type.
## Empty for common trees.
@export var variety_of: TreeData

@export_group("Visuals")
## One picture per stage. The bottom edge of each picture is placed on the
## tree's origin (the bottom of the trunk), following the "origin on the ground" rule.
@export var sapling_texture: Texture2D
@export var young_texture: Texture2D
@export var flowering_texture: Texture2D
@export var unripe_texture: Texture2D
@export var ripe_texture: Texture2D
