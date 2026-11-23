extends PanelContainer
## Inventory panel. Opens / closes with the "toggle_inventory" action.
## Lists every item in the Inventory with its icon, name and amount.
## Saplings and cuttings get a "Plant" button that starts the placement mode.
## Texts come from translation keys (localization/translations.csv); the look is a placeholder.

## Emitted when the player presses "Plant" on a sapling.
## Connected to PlacementMode.start in main.tscn.
signal plant_requested(item: ItemData)

const ICON_SIZE := Vector2(48, 48)
const FONT_SIZE := 26

@onready var rows: VBoxContainer = $Margin/VBox/Rows
@onready var empty_label: Label = $Margin/VBox/EmptyLabel


func _ready() -> void:
	hide()
	# While this panel is open the game is paused (it keeps working itself).
	UIState.track(self)
	Inventory.inventory_changed.connect(_on_inventory_changed)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_inventory"):
		# Do not open on top of another window (trade window, pause menu).
		if not visible and UIState.is_blocking():
			return
		visible = not visible
		if visible:
			_refresh()
		# Stop other nodes from also reacting to this key press.
		get_viewport().set_input_as_handled()
	elif visible and event.is_action_pressed("ui_cancel"):
		hide() # Esc closes the panel (and does not open the pause menu)
		get_viewport().set_input_as_handled()


func _on_inventory_changed(_item: ItemData, _new_amount: int) -> void:
	# No need to rebuild the list while nobody can see it.
	if visible:
		_refresh()


## Rebuilds the whole list. Simple and fast enough for a small inventory.
func _refresh() -> void:
	for child in rows.get_children():
		child.queue_free()
	var items := Inventory.get_items()
	empty_label.visible = items.is_empty()
	for item in items:
		rows.add_child(_make_row(item))


## One row: [icon]  Name ............ × amount  [Plant]  (button only for plantable items)
func _make_row(item: ItemData) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)

	var icon := TextureRect.new()
	icon.texture = item.icon
	icon.custom_minimum_size = ICON_SIZE
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	row.add_child(icon)

	var name_label := Label.new()
	name_label.text = tr(item.display_name)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.add_theme_font_size_override("font_size", FONT_SIZE)
	row.add_child(name_label)

	var amount_label := Label.new()
	amount_label.text = "× %d" % Inventory.get_count(item)
	amount_label.add_theme_font_size_override("font_size", FONT_SIZE)
	row.add_child(amount_label)

	if _is_plantable(item):
		var plant_button := Button.new()
		plant_button.text = tr("UI_PLANT")
		plant_button.add_theme_font_size_override("font_size", FONT_SIZE)
		plant_button.pressed.connect(func() -> void:
			hide() # close the panel so the player can see where to plant
			plant_requested.emit(item)
		)
		row.add_child(plant_button)

	return row


## Saplings and cuttings that grow into a tree can be planted.
func _is_plantable(item: ItemData) -> bool:
	var kind_ok := item.category == ItemData.Category.SAPLING or item.category == ItemData.Category.CUTTING
	return kind_ok and item.grows_into != null
