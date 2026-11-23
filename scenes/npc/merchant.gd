class_name Merchant
extends StaticBody2D
## A merchant standing at a stall. The player presses interact near the
## stall to trade. (Decision: for now the merchant is always on the farm,
## in a fixed spot.) The first merchant is Bruno.
##
## Which items this merchant buys is set in the Inspector (`buys`), so
## future buyers with their own tastes can reuse this scene.

## Emitted when the player wants to trade. The sell window will listen to this.
signal trade_requested(merchant: Merchant)

@export var display_name: String = "Bruno"
## Items this merchant is willing to buy.
@export var buys: Array[ItemData] = []

@onready var name_label: Label = $NameLabel


func _ready() -> void:
	name_label.text = display_name


## Called by the player when they press the interact key near the stall.
func interact(_player: Node) -> void:
	trade_requested.emit(self)
	# Temporary: there is no sell window yet, so show today's prices in the Output panel.
	print("%s: Today's prices:" % display_name)
	for item in buys:
		print("  %s: %d (you have %d)" % [item.display_name, Market.get_price(item), Inventory.get_count(item)])
