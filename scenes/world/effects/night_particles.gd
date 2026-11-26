class_name NightParticles
extends CPUParticles2D
## Particles that only appear at night, e.g. fireflies (decision "Day / night
## rework": fireflies at night, atmosphere only). Emits while
## GameClock.get_night_amount() is at least `night_threshold`; when morning
## comes it just stops emitting, so the last fireflies fade out naturally.
##
## Night colours: DayNightTint (CanvasModulate) multiplies everything by a dark
## blue, which would make normal yellow dots almost black. So the particle
## `color` is set ABOVE 1.0 (e.g. 3, 3.2, 1.4): after the night multiply it is
## still a bright yellow-green. The blinking comes from the alpha of `color_ramp`.

## How dark it must be before they appear (0 = always, 1 = only in full night).
@export_range(0.0, 1.0, 0.05) var night_threshold: float = 0.6


func _ready() -> void:
	emitting = false
	GameClock.time_advanced.connect(func(_days: float) -> void: _update())
	_update()


func _update() -> void:
	var should_emit := GameClock.get_night_amount() >= night_threshold
	if emitting != should_emit:
		emitting = should_emit
