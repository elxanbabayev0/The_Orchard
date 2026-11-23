extends PanelContainer
## Small choice menu above a grown rare tree (decision: pressing E at a rare
## tree opens "Harvest" / "Take cutting", so a cutting is never taken by accident).
## FruitTree finds this menu through the group GROUP (trees are created at run
## time, so a connection in main.tscn is not possible) and calls open(tree).
## The look is a placeholder.

const GROUP := &"tree_action_menu"
## How far above the tree's origin (the trunk bottom) the menu sits, in screen pixels.
const ABOVE_TREE := 220.0

## The tree the menu is open for.
var _tree: Node2D = null

@onready var title_label: Label = $Margin/VBox/TitleLabel
@onready var harvest_button: Button = $Margin/VBox/Buttons/HarvestButton
@onready var cutting_button: Button = $Margin/VBox/Buttons/CuttingButton
@onready var close_button: Button = $Margin/VBox/Buttons/CloseButton


func _ready() -> void:
	hide()
	add_to_group(GROUP)
	UIState.track(self)
	harvest_button.pressed.connect(func() -> void:
		var tree := _tree
		hide()
		if is_instance_valid(tree):
			tree.harvest()
	)
	cutting_button.pressed.connect(func() -> void:
		var tree := _tree
		hide()
		if is_instance_valid(tree):
			tree.take_cutting()
	)
	close_button.pressed.connect(hide)
	visibility_changed.connect(func() -> void:
		if not visible:
			_tree = null
	)


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		hide()
		get_viewport().set_input_as_handled()


## Opens the menu for a FruitTree (duck typed: can_harvest, can_take_cutting,
## get_cutting_days_left, harvest, take_cutting, data).
func open(tree: Node2D) -> void:
	_tree = tree
	title_label.text = tr(tree.data.display_name)
	harvest_button.disabled = not tree.can_harvest()
	cutting_button.disabled = not tree.can_take_cutting()
	var days_left: int = tree.get_cutting_days_left()
	if days_left <= 0:
		cutting_button.text = tr("UI_TREE_TAKE_CUTTING")
	elif days_left == 1:
		cutting_button.text = tr("UI_TREE_CUTTING_WAIT_ONE")
	else:
		cutting_button.text = tr("UI_TREE_CUTTING_WAIT") % days_left
	show()
	reset_size()
	# Above the tree, on screen (the menu lives on the UI layer, not in the world).
	var screen_point := tree.get_global_transform_with_canvas().origin
	position = screen_point - Vector2(size.x / 2.0, ABOVE_TREE + size.y)
	position = position.clamp(Vector2.ZERO, get_viewport_rect().size - size)
	(harvest_button if not harvest_button.disabled else cutting_button if not cutting_button.disabled else close_button).grab_focus()
