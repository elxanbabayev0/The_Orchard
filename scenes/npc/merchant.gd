class_name Merchant
extends StaticBody2D
## A merchant standing at a stall. The player presses interact near the
## stall to trade. (Decision: for now the merchant is always on the farm,
## in a fixed spot.) The first merchant is Bruno.
##
## What this merchant buys and sells is set in the Inspector (`buys`, `sells`),
## so future merchants with their own goods can reuse this scene.

## Emitted when the player wants to trade. Connected to TradeWindow.open in main.tscn.
signal trade_requested(merchant: Merchant)

@export var display_name: String = "Bruno"
## Items this merchant is willing to buy from the player (e.g. fruit).
@export var buys: Array[ItemData] = []
## Items this merchant sells to the player (e.g. saplings).
@export var sells: Array[ItemData] = []

@export_group("Opening hours")
## The stall is open from open_hour until close_hour (decision "Day / night
## rework": Bruno's stall is closed at night). Closed = no buying and no
## selling; the merchant is not standing at the stall. TEMPORARY values.
@export_range(0, 23) var open_hour: int = 8
@export_range(1, 24) var close_hour: int = 20

@onready var name_label: Label = $NameLabel
@onready var person_sprite: Sprite2D = $PersonSprite


func _ready() -> void:
	name_label.text = display_name
	GameClock.minute_changed.connect(func(_d: int, _h: int, _m: int) -> void: _update_presence())
	_update_presence()


func is_open() -> bool:
	var hour := GameClock.get_hour()
	return hour >= open_hour and hour < close_hour


## Called by the player when they press the interact key near the stall.
## The trade window itself shows "closed" when the stall is closed.
func interact(_player: Node) -> void:
	trade_requested.emit(self)


func _update_presence() -> void:
	person_sprite.visible = is_open()
