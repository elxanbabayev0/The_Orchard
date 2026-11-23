class_name ItemData
extends Resource
## Data for one kind of item (e.g. gilas fruit).
## Each item is a separate .tres file built from this script, so new items
## (fruits, varieties, later tools or products) can be added without new code.
## The inventory counts items by their `id`.

## Broad item groups (useful for sorting / filtering the inventory).
## New categories must be added at the END: .tres files store the number, not the name.
enum Category { FRUIT, OTHER, SAPLING }

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
## The "normal" price of one item.
## - Items the player SELLS (fruit): the merchant's real price changes every day
##   around this value and drops when the player sells a lot (see Market).
## - Items the player BUYS (saplings): the shop price (fixed for now).
## 0 = no price (cannot be traded). Values are TEMPORARY test numbers — balance is not decided.
@export_range(0, 100000, 1) var base_price: int = 0
## How much selling this item lowers its market price, compared to normal
## (1.0 = normal, 0.5 = drops half as fast — e.g. Midnight Morello's trait).
@export_range(0.0, 2.0, 0.05) var price_drop_factor: float = 1.0
## Rare varieties (decision: only Oona gives them, at the end of story chapters).
## Rare items are never given by generated tasks or sold by merchants.
@export var rare: bool = false

@export_group("Planting")
## For saplings: the tree type this sapling grows into when planted. Empty for other items.
@export var grows_into: TreeData
