extends PanelContainer
## Rosa's kitchen window (decision "Processing: jam in Rosa's kitchen").
## Shows the pots that are cooking and one row per recipe:
##   [jar icon] Sweet Cherry Jam | 5 × Sweet Cherry | You have: 7 | [Cook]
## Cook → Kitchen.cook(recipe): the fruit is taken now, the jar comes in the
## morning. Common recipes are always listed; a rare variety's recipe only
## once the player owns that fruit (no spoilers). The look is a placeholder.

const ICON_SIZE := Vector2(40, 40)
const FONT_SIZE := 24
const HIGHLIGHT := Color(1.0, 0.88, 0.35)

@onready var pots_label: Label = $Margin/VBox/PotsLabel
@onready var cooking_list: VBoxContainer = $Margin/VBox/CookingList
@onready var rows: VBoxContainer = $Margin/VBox/Rows
@onready var close_button: Button = $Margin/VBox/Header/CloseButton


func _ready() -> void:
	hide()
	UIState.track(self)
	close_button.pressed.connect(hide)
	Inventory.inventory_changed.connect(_on_data_changed.unbind(2))
	Kitchen.pots_changed.connect(_on_data_changed)


## Connected to HouseMenu.kitchen_chosen in main.tscn.
func open() -> void:
	show()
	_refresh()
	close_button.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		hide()
		get_viewport().set_input_as_handled()


func _on_data_changed() -> void:
	if visible:
		_refresh()


func _refresh() -> void:
	for child in cooking_list.get_children() + rows.get_children():
		child.queue_free()
	var pots := Kitchen.get_pots()
	pots_label.text = tr("UI_KITCHEN_POTS") % [pots.size(), Kitchen.POTS]
	for pot in pots:
		var recipe: RecipeData = pot["recipe"]
		var line := _make_label(tr("UI_KITCHEN_COOKING") % [tr(recipe.output.display_name), GameClock.WAKE_HOUR])
		line.add_theme_color_override("font_color", HIGHLIGHT)
		cooking_list.add_child(line)
	for recipe in Registry.get_all_recipes():
		if recipe.input == null or recipe.output == null:
			continue
		if recipe.input.rare and Inventory.get_count(recipe.input) == 0:
			continue # rare varieties appear once the player has that fruit
		rows.add_child(_make_row(recipe))


## [jar icon] Jam name | 5 × Fruit | You have: 7 | [Cook]
func _make_row(recipe: RecipeData) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	var icon := TextureRect.new()
	icon.texture = recipe.output.icon
	icon.custom_minimum_size = ICON_SIZE
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	row.add_child(icon)
	var name_label := _make_label(tr(recipe.output.display_name))
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(name_label)
	row.add_child(_make_label(tr("UI_KITCHEN_NEEDS") % [recipe.input_amount, tr(recipe.input.display_name)]))
	row.add_child(_make_label(tr("UI_OWNED") % Inventory.get_count(recipe.input)))
	var cook_button := Button.new()
	cook_button.text = tr("UI_KITCHEN_COOK")
	cook_button.add_theme_font_size_override("font_size", FONT_SIZE)
	cook_button.disabled = not Kitchen.can_cook(recipe)
	cook_button.pressed.connect(func() -> void: Kitchen.cook(recipe))
	row.add_child(cook_button)
	return row


func _make_label(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", FONT_SIZE)
	return label
