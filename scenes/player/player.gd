extends CharacterBody2D

@export var speed: float = 200.0

## Finds things around the player's feet that can be interacted with.
@onready var interaction_area: Area2D = $InteractionArea
@onready var sprite: Sprite2D = $Sprite2D
@onready var name_label: Label = $NameLabel


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
	if character.texture != null:
		sprite.texture = character.texture
		# "Origin on the ground": the bottom of the picture sits on the feet.
		sprite.position = Vector2(0, -character.texture.get_height() / 2.0)
	# A name, not a translation key: shown as it is.
	name_label.text = Characters.get_display_name(character)


func _physics_process(_delta):
	var direction := Input.get_vector(
		"move_left",
		"move_right",
		"move_up",
		"move_down"
	)

	# Skill: faster walking while that character is active.
	velocity = direction * speed * (1.0 + Characters.get_bonus(SkillData.Effect.WALK_SPEED))
	move_and_slide()


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
