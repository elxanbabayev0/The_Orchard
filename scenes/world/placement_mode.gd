extends Node2D
## Placement mode for planting saplings.
## (Decision: mouse placement with a half-transparent "ghost" snapped to the
## 64 px grid; green = can plant, red = cannot; only near the player and only
## on a free spot of the farm ground.)
##
## Started by InventoryPanel.plant_requested (connected in main.tscn).
## Left click plants, right click / Esc cancels.

const TILE_SIZE := 64
## How far from the player (pixels) a sapling can be planted. TEMPORARY test value.
const PLANT_RANGE := 192.0
## Area above the target spot that must be free of bodies (trees, props, the player...).
## Almost 2 tiles wide, so two trees cannot stand right next to each other with
## overlapping crowns. TEMPORARY test value — tree spacing is not decided.
const FOOTPRINT_SIZE := Vector2(120, 56)
const COLOR_OK := Color(0.5, 1.0, 0.5, 0.6)
const COLOR_BLOCKED := Color(1.0, 0.35, 0.35, 0.6)
const FRUIT_TREE_SCENE := preload("res://scenes/trees/fruit_tree.tscn")

## Set in main.tscn.
@export var player: Node2D
## New trees are added here (must be inside the Y-sorted Entities node).
@export var trees_parent: Node2D
## Saplings can only be planted on this ground area.
@export var ground: Control

## The sapling being placed (null = placement mode is off).
var _item: ItemData = null
var _target := Vector2.ZERO
var _can_place := false
var _footprint := RectangleShape2D.new()

@onready var ghost: Sprite2D = $Ghost
@onready var hint_layer: CanvasLayer = $HintLayer


func _ready() -> void:
	_footprint.size = FOOTPRINT_SIZE
	_set_active(false)


func is_active() -> bool:
	return _item != null


## Starts placing a sapling. Connected to InventoryPanel.plant_requested.
func start(item: ItemData) -> void:
	if item == null or item.grows_into == null or not Inventory.has_item(item):
		return
	_item = item
	var texture := item.grows_into.sapling_texture
	ghost.texture = texture
	# Same "origin on the ground" lift as FruitTree: the picture stands on the spot.
	ghost.offset = Vector2(0, -texture.get_height() / 2.0) if texture else Vector2.ZERO
	_set_active(true)


func cancel() -> void:
	_item = null
	_set_active(false)


func _set_active(active: bool) -> void:
	visible = active
	hint_layer.visible = active
	# Only work (and listen to clicks) while placing.
	set_physics_process(active)
	set_process_unhandled_input(active)


## Physics queries are safest in _physics_process, so the check happens here.
func _physics_process(_delta: float) -> void:
	_target = snap_to_grid(get_global_mouse_position())
	_can_place = can_place_at(_target)
	ghost.global_position = _target
	ghost.modulate = COLOR_OK if _can_place else COLOR_BLOCKED


## Turns any point into a tree spot: the middle of the tile horizontally and
## the BOTTOM edge of the tile vertically ("origin on the ground" rule).
static func snap_to_grid(point: Vector2) -> Vector2:
	var column := floori(point.x / TILE_SIZE)
	var row := floori(point.y / TILE_SIZE)
	return Vector2(column * TILE_SIZE + TILE_SIZE / 2.0, (row + 1) * TILE_SIZE)


func can_place_at(spot: Vector2) -> bool:
	# 1) Close enough to the player.
	if player.global_position.distance_to(spot) > PLANT_RANGE:
		return false
	# 2) On the farm ground (checked at the middle of the tile).
	if ground != null and not ground.get_global_rect().has_point(spot - Vector2(0, TILE_SIZE / 2.0)):
		return false
	# 3) Nothing standing there: ask the physics engine if any body overlaps
	#    the footprint rectangle just above the spot.
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = _footprint
	query.transform = Transform2D(0.0, spot - Vector2(0, FOOTPRINT_SIZE.y / 2.0))
	return get_world_2d().direct_space_state.intersect_shape(query, 1).is_empty()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_try_plant()
			get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			cancel()
			get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_cancel"):
		cancel()
		get_viewport().set_input_as_handled()


func _try_plant() -> void:
	if not _can_place:
		return
	# Take the sapling first; if it is somehow gone, stop.
	if not Inventory.remove_item(_item, 1):
		cancel()
		return
	var tree := FRUIT_TREE_SCENE.instantiate() as FruitTree
	tree.data = _item.grows_into # must be set before add_child (FruitTree._ready reads it)
	tree.position = trees_parent.to_local(_target)
	trees_parent.add_child(tree)
	Progression.on_planted()
	# Keep placing while saplings of this kind are left.
	if not Inventory.has_item(_item):
		cancel()
