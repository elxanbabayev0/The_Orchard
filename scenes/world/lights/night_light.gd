class_name NightLight
extends PointLight2D
## A light that turns on at night (decision "Day / night rework": lights at
## night). Its brightness follows GameClock.get_night_amount(): off during the
## day, fading in in the evening and out in the morning.
##
## Why a PointLight2D: DayNightTint (CanvasModulate) darkens the whole world;
## 2D lights brighten the area around them again, so they shine in the dark.
## Used by Rosa's house windows and the path lantern. Set color, texture and
## texture_scale in the Inspector as usual; `max_energy` is the night brightness.

@export var max_energy: float = 1.0


func _ready() -> void:
	GameClock.time_advanced.connect(func(_days: float) -> void: _update())
	_update()


func _update() -> void:
	var amount := GameClock.get_night_amount()
	energy = max_energy * amount
	enabled = amount > 0.0 # a light with energy 0 still costs drawing time
