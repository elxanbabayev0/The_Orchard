extends Label
## Shows the current game day and time. Updates only when the minute changes.
## The text format is a placeholder: the game's UI language and style are not decided.


func _ready() -> void:
	GameClock.minute_changed.connect(_on_minute_changed)
	_update_text()


func _on_minute_changed(_day: int, _hour: int, _minute: int) -> void:
	_update_text()


func _update_text() -> void:
	text = "Gün %d   %02d:%02d" % [GameClock.day, GameClock.get_hour(), GameClock.get_minute()]
