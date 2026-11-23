extends Label
## Shows the current game day and time. Updates only when the minute changes.
## Text comes from the translation key UI_CLOCK (localization/translations.csv).


func _ready() -> void:
	GameClock.minute_changed.connect(_on_minute_changed)
	_update_text()


func _on_minute_changed(_day: int, _hour: int, _minute: int) -> void:
	_update_text()


func _update_text() -> void:
	text = tr("UI_CLOCK") % [GameClock.day, GameClock.get_hour(), GameClock.get_minute()]
