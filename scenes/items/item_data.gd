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
## Translation KEY of the name shown to the player (e.g. "ITEM_GILAS").
## The real text is in localization/translations.csv; UI code shows it with tr().
@export var display_name: String = ""
@export var category: Category = Category.FRUIT
## Picture shown in the inventory and pop-ups.
@export var icon: Texture2D
## Translation KEY of the description (e.g. "ITEM_GILAS_DESC").
@export var description: String = ""

@export_group("Economy")
## The "normal" price of one item. The merchant's real price changes every day
## around this value and drops when the player sells a lot (see the market system).
## 0 = cannot be sold. Values are TEMPORARY test numbers — balance is not decided.
@export_range(0, 100000, 1) var base_price: int = 0
