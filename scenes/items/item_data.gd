class_name ItemData
extends Resource
## Data for one kind of item (e.g. gilas fruit).
## Each item is a separate .tres file built from this script, so new items
## (fruits, varieties, later tools or products) can be added without new code.
## The inventory counts items by their `id`.

## Broad item groups (useful later for sorting / filtering the inventory).
enum Category { FRUIT, OTHER }

## Unique, never-changing name used in code and save files (e.g. &"gilas").
@export var id: StringName = &""
## Name shown to the player.
@export var display_name: String = ""
@export var category: Category = Category.FRUIT
## Picture shown in the inventory and pop-ups.
@export var icon: Texture2D
@export_multiline var description: String = ""
