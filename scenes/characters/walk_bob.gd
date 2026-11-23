class_name WalkBob
extends Node
## Procedural walk animation for characters that have ONE picture per direction.
## (Decision: a "bob" animation now — rhythmic hop, a little squash/stretch and
## sway — to be replaced by real frame-by-frame walk cycles later.)
##
## Every step the picture hops up and lands again. Its owner calls
## update(delta, speed_ratio) every physics frame. The sprite must have its pivot
## at the feet (Sprite2D.offset lifts the picture, position stays at 0), so squash
## and sway happen around the feet, and this node owns position/scale/rotation.
##
## Pixel art note: the hop moves in whole art pixels (PIXEL_STEP), so it stays
## sharp. Squash and sway scale/rotate the pixels, which can look uneven in
## pixel art — keep them small, or 0 to switch them off.

## Screen pixels per art pixel (CLAUDE.md "Visual style": 1 art pixel = 2 screen pixels).
const PIXEL_STEP := 2.0

## The picture to animate.
@export var sprite: Sprite2D
## Steps per second at normal walking speed (faster walking = faster steps).
@export var steps_per_second: float = 4.0
## How high each hop goes, in screen pixels (4 = 2 art pixels).
@export var bob_height: float = 4.0
## How much the picture squashes when the foot lands (0.03 = 3%). 0 = off.
@export_range(0.0, 0.2, 0.01) var squash: float = 0.03
## Side-to-side lean per step, in degrees. 0 = off (rotated pixel art looks jagged).
@export_range(0.0, 10.0, 0.5) var sway_degrees: float = 0.0

## Position in the step cycle (one step = PI).
var _phase := 0.0
## 0 = standing still, 1 = walking (eases in/out so starting and stopping look soft).
var _amount := 0.0


## speed_ratio: current speed / normal walking speed (0 = standing still).
func update(delta: float, speed_ratio: float) -> void:
	if sprite == null:
		return
	var moving := speed_ratio > 0.01
	_amount = move_toward(_amount, 1.0 if moving else 0.0, delta * 8.0)
	if moving:
		_phase = fmod(_phase + delta * steps_per_second * speed_ratio * PI, TAU)
	elif _amount == 0.0:
		_phase = 0.0 # fully stopped: the next walk starts with a fresh step

	# 0 when the foot touches the ground, 1 in the middle of the step.
	var step := absf(sin(_phase))
	var lift := snappedf(step * bob_height * _amount, PIXEL_STEP)
	sprite.position = Vector2(0.0, -lift)
	# Squash on landing (wider + shorter), normal in the air.
	var squeeze := (1.0 - step) * squash * _amount
	sprite.scale = Vector2(1.0 + squeeze, 1.0 - squeeze)
	# sin() changes sign every step, so the lean goes left, right, left...
	sprite.rotation = deg_to_rad(sin(_phase) * sway_degrees * _amount)
