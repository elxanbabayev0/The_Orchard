class_name TreeData
extends Resource
## Data for one tree type (e.g. gilas, alça, tut).
## Each tree type is a separate .tres file built from this script,
## so new trees can be added in the editor without writing new code.
##
## Durations are in SECONDS for now (prototype test values).
## They will switch to game days once the game clock exists.

@export var id: StringName = &""
@export var display_name: String = ""

@export_group("Growth (happens once)")
## Time from planting until the sapling becomes a young tree.
@export var sapling_duration: float = 5.0
## Time from young tree until mature tree. After this the fruit cycle starts.
@export var young_duration: float = 5.0

@export_group("Fruit cycle (repeats)")
## Time the tree spends flowering.
@export var flowering_duration: float = 5.0
## Time from unripe fruit until ripe fruit. Ripe fruit then waits until harvested.
@export var unripe_duration: float = 5.0

@export_group("Harvest")
## Which fruit this tree gives. Temporary: will become an item reference
## once the inventory / item system exists.
@export var fruit_id: StringName = &""
## How many fruits one harvest gives.
@export var harvest_yield: int = 3
