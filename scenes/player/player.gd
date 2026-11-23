extends CharacterBody2D

@export var speed: float = 200.0

## Finds things around the player's feet that can be interacted with.
@onready var interaction_area: Area2D = $InteractionArea
@onready var sprite: Sprite2D = $Sprite2D
@onready var name_label: Label = $NameLabel
@onready var walk_bob: WalkBob = $WalkBob

## Which way the player looks. Changes while walking; kept when standing still.
var facing: CharacterData.Facing = CharacterData.Facing.DOWN


func _ready() -> void:
	_apply_character(Characters.get_active())
	Characters.player_name_changed.connect(func(_new_name: String) -> void:
		_apply_character(Characters.get_active())
	)
	Characters.active_character_changed.connect(_apply_character)


## Shows the active character: its picture and its name above the head.
func _apply_character(character: CharacterData) -> void:
	if character == null:
		return
	_update_picture()
	# A name, not a translation key: shown as it is.
	name_label.text = Characters.get_display_name(character)


func set_facing(new_facing: CharacterData.Facing) -> void:
	if new_facing == facing:
		return
	facing = new_facing
	_update_picture()


## The active character's picture for the current facing.
func _update_picture() -> void:
	var character := Characters.get_active()
	var picture := character.get_texture_for(facing) if character != null else null
	if picture == null:
		return
	sprite.texture = picture
	# "Origin on the ground": the bottom of the picture sits on the feet.
	# offset (not position) lifts the picture, so the sprite's pivot stays at the
	# feet and WalkBob can hop / squash it around the feet.
	sprite.offset = Vector2(0, -picture.get_height() / 2.0)


func _physics_process(delta: float) -> void:
	var direction := Input.get_vector(
		"move_left",
		"move_right",
		"move_up",
		"move_down"
	)

	if direction != Vector2.ZERO:
		set_facing(CharacterData.facing_from_vector(direction))
	# Skill: faster walking while that character is active.
	velocity = direction * speed * (1.0 + Characters.get_bonus(SkillData.Effect.WALK_SPEED))
	move_and_slide()
	# The real speed after collisions: walking into a wall = no steps.
	walk_bob.update(delta, get_real_velocity().length() / speed)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		_interact()


## Interacts with the nearest object that has an `interact(player)` method.
## Any object (tree, NPC, door...) becomes interactable just by having that method.
func _interact() -> void:
	var target := _find_nearest_interactable()
	if target != null:
		target.interact(self)


func _find_nearest_interactable() -> Node2D:
	var nearest: Node2D = null
	var nearest_distance := INF
	for body in interaction_area.get_overlapping_bodies():
		if body == self or not body.has_method("interact"):
			continue
		var distance := global_position.distance_to(body.global_position)
		if distance < nearest_distance:
			nearest = body
			nearest_distance = distance
	return nearest


# --- Save / load -------------------------------------------------------------
# Only the position: who the player is comes from Characters.

func get_save_data() -> Dictionary:
	return {"x": global_position.x, "y": global_position.y}


## load_save_data({}) keeps the start position from main.tscn.
func load_save_data(data: Dictionary) -> void:
	if data.has("x") and data.has("y"):
		global_position = Vector2(float(data["x"]), float(data["y"]))
