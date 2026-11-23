extends CanvasModulate
## Tints the world by the time of day (decision: simple day/night tint).
## CanvasModulate multiplies the color of everything on its canvas layer
## (the world), but not the UI, which lives on its own CanvasLayer.

## Colors through one day. Left edge = 00:00, middle = 12:00, right edge = 24:00.
## White = normal colors; darker / bluer = night. Edit it in the Inspector.
@export var day_colors: Gradient


func _ready() -> void:
	GameClock.time_advanced.connect(_on_time_advanced)
	_update_color()


func _on_time_advanced(_delta_days: float) -> void:
	_update_color()


func _update_color() -> void:
	if day_colors == null:
		return
	color = day_colors.sample(GameClock.get_day_progress())
