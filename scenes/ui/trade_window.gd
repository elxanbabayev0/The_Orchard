extends PanelContainer
## Trade window. Opened by a merchant's `trade_requested` signal.
## Two sections:
## - Sell: items the merchant buys (today's price, owned, amount, total, Sell button).
## - Buy:  items the merchant sells (shop price, owned, amount, total, Buy button).
## A section is hidden when the merchant has nothing for it.
## Texts come from translation keys (localization/translations.csv); the look is a placeholder.

const ICON_SIZE := Vector2(40, 40)
const FONT_SIZE := 24
## Most items the Buy amount box allows at once.
const MAX_BUY_AMOUNT := 99

## The merchant we are trading with right now (null when closed).
var _merchant: Merchant

@onready var title_label: Label = $Margin/VBox/Header/Title
@onready var close_button: Button = $Margin/VBox/Header/CloseButton
@onready var empty_label: Label = $Margin/VBox/EmptyLabel
@onready var sell_header: Label = $Margin/VBox/SellHeader
@onready var sell_rows: VBoxContainer = $Margin/VBox/SellRows
@onready var buy_header: Label = $Margin/VBox/BuyHeader
@onready var buy_rows: VBoxContainer = $Margin/VBox/BuyRows


func _ready() -> void:
	hide()
	# While this window is open the game is paused (it keeps working itself).
	UIState.track(self)
	close_button.pressed.connect(close)
	# Rebuild when amounts, prices or money change (after a trade, on a new day...).
	# unbind() drops the signal's arguments, which we do not need here.
	Inventory.inventory_changed.connect(_on_data_changed.unbind(2))
	Market.prices_changed.connect(_on_data_changed.unbind(1))
	Wallet.money_changed.connect(_on_data_changed.unbind(2))


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
	for child in sell_rows.get_children() + buy_rows.get_children():
		child.queue_free()
	if _merchant == null:
		return
	# Closed stall (night): only a message, no trading.
	var is_open := _merchant.is_open()
	var has_sell := is_open and not _merchant.buys.is_empty()
	var has_buy := is_open and not _merchant.sells.is_empty()
	sell_header.visible = has_sell
	sell_rows.visible = has_sell
	buy_header.visible = has_buy
	buy_rows.visible = has_buy
	empty_label.visible = not has_sell and not has_buy
	if not is_open:
		empty_label.text = tr("UI_MERCHANT_CLOSED") % [_merchant.display_name, _merchant.open_hour, _merchant.close_hour]
		return
	empty_label.text = "UI_MERCHANT_NOTHING_TO_TRADE"
	sell_header.text = tr("UI_TRADE_SELL_HEADER") % _merchant.display_name
	buy_header.text = tr("UI_TRADE_BUY_HEADER") % _merchant.display_name
	for item in _merchant.buys:
		sell_rows.add_child(_make_sell_row(item))
	for item in _merchant.sells:
		buy_rows.add_child(_make_buy_row(item))


## Sell row: [icon] Name | Price: 10 | You have: 7 | [amount] | = 65 | [Sell]
func _make_sell_row(item: ItemData) -> HBoxContainer:
	var owned := Inventory.get_count(item)
	var row := _make_row_start(item)
	var fresh := Inventory.get_fresh_count(item)
	# With fresh fruit: "Price: 10 (fresh 12)" and "You have: 7 (3 fresh)".
	var price_text := tr("UI_PRICE") % Market.get_price(item)
	var owned_text := tr("UI_OWNED") % owned
	if fresh > 0:
		price_text += tr("UI_FRESH_PRICE_SUFFIX") % Market.get_fresh_price(item)
		owned_text += tr("UI_FRESH_SUFFIX") % fresh
	row.add_child(_make_label(price_text))
	row.add_child(_make_label(owned_text))
	# Limited to what the player owns; defaults to selling everything.
	var amount_box := _make_amount_box(owned, owned)
	row.add_child(amount_box)
	var total_label := _make_total_label()
	row.add_child(total_label)
	var sell_button := _make_button(tr("UI_SELL"))
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


## Buy row: [icon] Name | Price: 40 | You have: 1 | [amount] | = 40 | [Buy]
func _make_buy_row(item: ItemData) -> HBoxContainer:
	var price := Market.get_buy_price(item)
	# How many the player can pay for right now (capped).
	var affordable := 0
	if price > 0:
		# floori(): round down on purpose — you can only buy whole items.
		affordable = mini(floori(float(Wallet.money) / price), MAX_BUY_AMOUNT)
	var row := _make_row_start(item)
	row.add_child(_make_label(tr("UI_PRICE") % price))
	row.add_child(_make_label(tr("UI_OWNED") % Inventory.get_count(item)))
	# Limited to what the player can afford; defaults to 1 (if affordable).
	var amount_box := _make_amount_box(affordable, mini(1, affordable))
	row.add_child(amount_box)
	var total_label := _make_total_label()
	row.add_child(total_label)
	var buy_button := _make_button(tr("UI_BUY"))
	row.add_child(buy_button)

	var update_total := func(value: float) -> void:
		var amount := int(value)
		total_label.text = "= %d" % (price * amount)
		buy_button.disabled = amount <= 0 or not Wallet.can_afford(price * amount)
	amount_box.value_changed.connect(update_total)
	update_total.call(amount_box.value)

	buy_button.pressed.connect(func() -> void:
		Market.buy(item, int(amount_box.value))
	)
	return row


## The part every row starts with: [icon] Name (the name fills the free space).
func _make_row_start(item: ItemData) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	var icon := TextureRect.new()
	icon.texture = item.icon
	icon.custom_minimum_size = ICON_SIZE
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	row.add_child(icon)
	var name_label := _make_label(tr(item.display_name))
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(name_label)
	return row


## SpinBox = a number field with up/down arrows.
func _make_amount_box(max_amount: int, start_amount: int) -> SpinBox:
	var box := SpinBox.new()
	box.min_value = 0
	box.max_value = max_amount
	box.value = start_amount
	box.editable = max_amount > 0
	return box


func _make_total_label() -> Label:
	var label := _make_label("")
	label.custom_minimum_size.x = 90
	return label


func _make_button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.add_theme_font_size_override("font_size", FONT_SIZE)
	return button


func _make_label(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", FONT_SIZE)
	return label
