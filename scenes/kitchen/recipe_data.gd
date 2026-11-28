class_name RecipeData
extends Resource
## One recipe of Rosa's kitchen (decision "Processing: jam in Rosa's kitchen"):
## `input_amount` × `input` (fruit) → `output_amount` × `output` (a jar of jam),
## ready the next morning. Each recipe is a .tres file in scenes/kitchen/recipes/,
## found by the Registry — a new recipe needs no new code.

## Unique, never-changing name (saved in the kitchen's pots).
@export var id: StringName = &""
## Position in the kitchen window (lower = higher up).
@export var order: int = 0
@export var input: ItemData
@export_range(1, 99) var input_amount: int = 5
@export var output: ItemData
@export_range(1, 99) var output_amount: int = 1
