extends PanelContainer
## Sell window. Opened by a merchant's `trade_requested` signal.
## Shows every item the merchant buys: today's price, how many the player has,
## how many to sell, the total, and a Sell button.
## (Decision: selling happens through a window, so dynamic prices are visible.)
## Texts and look are placeholders: UI language and style are not decided.

const ICON_SIZE := Vector2(40, 40)
const FONT_SIZE := 24

## The merchant we are trading with right now (null when closed).
var _merchant: Merchant

@onready var title_label: Label = $Margin/VBox/Header/Title
@onready var close_button: Button = $Margin/VBox/Header/CloseButton
@onready var empty_label: Label = $Margin/VBox/EmptyLabel
@onready var rows: VBoxContainer = $Margin/VBox/Rows


func _ready() -> void:
	hide()
	close_button.pressed.connect(close)
	# Rebuild when amounts or prices change (e.g. after a sale or on a new day).
	# unbind() drops the signal's arguments, which we do not need here.
	Inventory.inventory_changed.connect(_on_data_changed.unbind(2))
	Market.prices_changed.connect(_on_data_changed.unbind(1))


## Connected to Merchant.trade_requested in main.tscn.
func open(merchant: Merchant) -> void:
	_merchant = merchant
	title_label.text = merchant.display_name
	show()
	_refresh()


func close() -> void:
	hide()
	_merchant = null


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()


func _on_data_changed() -> void:
	if visible:
		_refresh()


func _refresh() -> void:
	for child in rows.get_children():
		child.queue_free()
	if _merchant == null:
		return
	empty_label.visible = _merchant.buys.is_empty()
	for item in _merchant.buys:
		rows.add_child(_make_row(item))


## One row: [icon] Name | Qiymət: 10 | Səndə: 7 | [amount] | = 65 | [Sat]
func _make_row(item: ItemData) -> HBoxContainer:
	var owned := Inventory.get_count(item)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)

	var icon := TextureRect.new()
	icon.texture = item.icon
	icon.custom_minimum_size = ICON_SIZE
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	row.add_child(icon)

	var name_label := _make_label(item.display_name)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(name_label)

	row.add_child(_make_label("Qiymət: %d" % Market.get_price(item)))
	row.add_child(_make_label("Səndə: %d" % owned))

	# SpinBox = a number field with up/down arrows. Limited to what the player owns.
	var amount_box := SpinBox.new()
	amount_box.min_value = 0
	amount_box.max_value = owned
	amount_box.value = owned
	amount_box.editable = owned > 0
	row.add_child(amount_box)

	var total_label := _make_label("")
	total_label.custom_minimum_size.x = 90
	row.add_child(total_label)

	var sell_button := Button.new()
	sell_button.text = "Sat"
	sell_button.add_theme_font_size_override("font_size", FONT_SIZE)
	row.add_child(sell_button)

	# Keep the total and the button in sync with the chosen amount.
	var update_total := func(value: float) -> void:
		var amount := int(value)
		total_label.text = "= %d" % Market.get_sell_total(item, amount)
		sell_button.disabled = amount <= 0
	amount_box.value_changed.connect(update_total)
	update_total.call(amount_box.value)

	sell_button.pressed.connect(func() -> void:
		Market.sell(item, int(amount_box.value))
	)
	return row


func _make_label(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", FONT_SIZE)
	return label
