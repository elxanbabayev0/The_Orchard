class_name NightGlow
extends Polygon2D
## A shape that glows at night, e.g. a window pane or a lantern's glass:
## its colour moves from the normal (day) colour to `lit_color` with
## GameClock.get_night_amount(). Pair it with a NightLight that lights the
## area around it. (Placeholder shapes for now; real pixel art can use the
## same idea later with a lit sprite.)

## Colour when the light is fully on (warm lamp light).
@export var lit_color: Color = Color(1.0, 0.85, 0.45)

var _day_color: Color


func _ready() -> void:
	_day_color = color
	GameClock.time_advanced.connect(func(_days: float) -> void: _update())
	_update()


func _update() -> void:
	color = _day_color.lerp(lit_color, GameClock.get_night_amount())
