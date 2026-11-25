extends Node2D
## Placement mode for planting saplings / cuttings and placing props (e.g. the
## path lantern).
## (Decision: mouse placement with a half-transparent "ghost" snapped to the
## 64 px grid; green = can plant, red = cannot; only near the player and only
## on a free spot of the farm ground.)
##
## Started by InventoryPanel.plant_requested (connected in main.tscn).
## Left click plants / places, right click / Esc cancels.
## Saplings become FruitTrees in `trees_parent` (and emit sapling_planted: XP,
## Oona's tasks); PLACEABLE items become their `places` scene in `props_parent`
## (no XP — placing a lantern is not planting).

const TILE_SIZE := 64
## How far from the player (pixels) a sapling can be planted. TEMPORARY test value.
const PLANT_RANGE := 192.0
## Area above the target spot that must be free of bodies (trees, props, the player...).
## Almost 2 tiles wide, so two trees cannot stand right next to each other with
## overlapping crowns. TEMPORARY test value — tree spacing is not decided.
const FOOTPRINT_SIZE := Vector2(120, 56)
## Free area needed for a placed prop (a lantern is small). TEMPORARY test value.
const PROP_FOOTPRINT_SIZE := Vector2(48, 24)
const COLOR_OK := Color(0.5, 1.0, 0.5, 0.6)
const COLOR_BLOCKED := Color(1.0, 0.35, 0.35, 0.6)
const FRUIT_TREE_SCENE := preload("res://scenes/trees/fruit_tree.tscn")

## Set in main.tscn.
@export var player: Node2D
## New trees are added here (must be inside the Y-sorted Entities node).
@export var trees_parent: Node2D
## Placed props are added here (must be inside the Y-sorted Entities node).
@export var props_parent: Node2D
## Saplings can only be planted where this ground has a tile.
@export var ground: Ground

## The sapling or prop item being placed (null = placement mode is off).
var _item: ItemData = null
var _target := Vector2.ZERO
var _can_place := false
var _footprint := RectangleShape2D.new()
## For props: a see-through copy of the prop scene (collision off) used as the ghost.
var _prop_ghost: Node2D = null

@onready var ghost: Sprite2D = $Ghost
@onready var hint_layer: CanvasLayer = $HintLayer
@onready var hint: Label = $HintLayer/Hint


func _ready() -> void:
	_footprint.size = FOOTPRINT_SIZE
	_set_active(false)


func is_active() -> bool:
	return _item != null


## Starts placing a sapling / cutting / prop. Connected to InventoryPanel.plant_requested.
func start(item: ItemData) -> void:
	if item == null or not Inventory.has_item(item):
		return
	if item.grows_into == null and item.places == null:
		return
	_free_prop_ghost() # starting again with another item
	_item = item
	_can_place = false # never trust a result from an earlier placement session
	if item.places != null:
		_footprint.size = PROP_FOOTPRINT_SIZE
		ghost.hide()
		_prop_ghost = item.places.instantiate() as Node2D
		# A ghost must not block anything (or the footprint check would find it).
		for child in _prop_ghost.find_children("*", "CollisionShape2D"):
			child.disabled = true
		add_child(_prop_ghost)
		hint.text = "UI_PLACEMENT_HINT_PROP"
	else:
		_footprint.size = FOOTPRINT_SIZE
		var texture := item.grows_into.sapling_texture
		ghost.texture = texture
		# Same "origin on the ground" lift as FruitTree: the picture stands on the spot.
		ghost.offset = Vector2(0, -texture.get_height() / 2.0) if texture else Vector2.ZERO
		ghost.show()
		hint.text = "UI_PLACEMENT_HINT"
	_set_active(true)


func cancel() -> void:
	_item = null
	_can_place = false
	_free_prop_ghost()
	_set_active(false)


func _free_prop_ghost() -> void:
	if _prop_ghost != null:
		_prop_ghost.queue_free()
		_prop_ghost = null


func _set_active(active: bool) -> void:
	visible = active
	hint_layer.visible = active
	# Only work (and listen to clicks) while placing.
	set_physics_process(active)
	set_process_unhandled_input(active)


## Physics queries are safest in _physics_process, so the check happens here.
func _physics_process(_delta: float) -> void:
	_target = _get_mouse_spot()
	_can_place = can_place_at(_target)
	var shown: Node2D = _prop_ghost if _prop_ghost != null else ghost
	shown.global_position = _target
	shown.modulate = COLOR_OK if _can_place else COLOR_BLOCKED


## The tree spot under the mouse cursor.
func _get_mouse_spot() -> Vector2:
	return snap_to_grid(get_global_mouse_position())


## Turns any point into a tree spot: the middle of the tile horizontally and
## the BOTTOM edge of the tile vertically ("origin on the ground" rule).
static func snap_to_grid(point: Vector2) -> Vector2:
	var column := floori(point.x / TILE_SIZE)
	var row := floori(point.y / TILE_SIZE)
	return Vector2(column * TILE_SIZE + TILE_SIZE / 2.0, (row + 1) * TILE_SIZE)


## Planting range in pixels, plus the active skill's extra tiles.
func get_plant_range() -> float:
	return PLANT_RANGE + Characters.get_bonus(SkillData.Effect.PLANT_RANGE) * TILE_SIZE


func can_place_at(spot: Vector2) -> bool:
	# 1) Close enough to the player.
	if player.global_position.distance_to(spot) > get_plant_range():
		return false
	# 2) On the farm ground (checked at the middle of the tile).
	if ground != null and not ground.has_ground_at(spot - Vector2(0, TILE_SIZE / 2.0)):
		return false
	# 3) Nothing standing there: ask the physics engine if any body overlaps
	#    the footprint rectangle just above the spot.
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = _footprint
	query.transform = Transform2D(0.0, spot - Vector2(0, _footprint.size.y / 2.0))
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
	# Check again at the moment of the click: the values from the last physics
	# frame can be out of date (e.g. a fast double click on "Plant" arrives before
	# any physics frame of the new session, and a tree may have just been planted).
	_target = _get_mouse_spot()
	_can_place = can_place_at(_target)
	if not _can_place:
		return
	# Take the item first; if it is somehow gone, stop.
	if not Inventory.remove_item(_item, 1):
		cancel()
		return
	if _item.places != null:
		_place_prop()
	else:
		_plant_tree()
	# Keep placing while items of this kind are left.
	if not Inventory.has_item(_item):
		cancel()


func _place_prop() -> void:
	var prop := _item.places.instantiate() as PlacedProp
	prop.item = _item # before add_child, like FruitTree.data
	prop.position = props_parent.to_local(_target)
	props_parent.add_child(prop)


func _plant_tree() -> void:
	var tree := FRUIT_TREE_SCENE.instantiate() as FruitTree
	tree.data = _item.grows_into # must be set before add_child (FruitTree._ready reads it)
	tree.position = trees_parent.to_local(_target)
	trees_parent.add_child(tree)
	GameEvents.sapling_planted.emit(_item, tree) # XP, Oona's tasks...
