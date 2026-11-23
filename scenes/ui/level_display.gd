extends VBoxContainer
## Shows the player's level and an XP bar for the current level.
## Text comes from the translation key UI_LEVEL; the look is a placeholder.

@onready var level_label: Label = $LevelLabel
@onready var xp_bar: ProgressBar = $XPBar


func _ready() -> void:
	Progression.xp_changed.connect(_on_xp_changed)
	_update()


func _on_xp_changed(_xp: int, _level: int) -> void:
	_update()


func _update() -> void:
	level_label.text = tr("UI_LEVEL") % Progression.level
	xp_bar.value = Progression.get_level_progress() * 100.0
