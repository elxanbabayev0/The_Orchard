extends CharacterBody2D

@export var speed: float = 200.0

## Finds things around the player's feet that can be interacted with.
@onready var interaction_area: Area2D = $InteractionArea


func _physics_process(_delta):
	var direction := Input.get_vector(
		"move_left",
		"move_right",
		"move_up",
		"move_down"
	)

	velocity = direction * speed
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
