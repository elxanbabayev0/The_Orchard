class_name FootstepEffects
extends Node2D
## Little particles at a walking character's feet, chosen by the ground surface:
## dust on dirt, grass bits on grass.
## (Decision: "while walking, small particles appear at the feet depending on
## the surface under them".)
##
## Put it in a CharacterBody2D scene at the feet (position 0, 0). It watches the
## body's real speed and asks Ground.get_surface_at() where the feet are.
## Each surface has its own CPUParticles2D child (see EFFECTS); the look of each
## effect is edited in the Inspector of that child. Pixel-art style: the particles
## are plain squares, 1-2 art pixels big.

## Surface (Ground custom data "surface") → name of the child particle node.
## New surface type = add a CPUParticles2D child + one line here.
const EFFECTS := {
	&"dirt": "Dust",
	&"grass": "GrassBits",
}
## Slower than this (pixels per second) counts as standing still.
const MIN_SPEED := 10.0

var _body: CharacterBody2D
var _ground: Ground


func _ready() -> void:
	_body = get_parent() as CharacterBody2D
	_stop_all()


func _physics_process(_delta: float) -> void:
	if _body == null:
		return
	var moving := _body.get_real_velocity().length() > MIN_SPEED
	var surface: StringName = Ground.NO_SURFACE
	if moving and _find_ground() != null:
		surface = _ground.get_surface_at(global_position)
	# Only the effect for the current surface emits; the others stop
	# (their particles already in the air finish and fade out).
	for key in EFFECTS:
		var particles := get_node_or_null(EFFECTS[key]) as CPUParticles2D
		if particles != null:
			particles.emitting = (key == surface)


## The Ground of the current world (found once, again after a scene change).
func _find_ground() -> Ground:
	if _ground == null or not is_instance_valid(_ground):
		_ground = get_tree().get_first_node_in_group(Ground.GROUP) as Ground
	return _ground


func _stop_all() -> void:
	for key in EFFECTS:
		var particles := get_node_or_null(EFFECTS[key]) as CPUParticles2D
		if particles != null:
			particles.emitting = false
