extends PanelContainer
## Top-right corner: who the player is controlling right now and what their
## skill does (e.g. "Nils — +2 Sour Cherry on every harvest").
## Updates when the player switches characters or the name changes.
## The skill text comes from Characters.get_skill_text(); the look is a placeholder.

@onready var portrait: TextureRect = $Margin/HBox/Portrait
@onready var name_label: Label = $Margin/HBox/VBox/NameLabel
@onready var skill_label: Label = $Margin/HBox/VBox/SkillLabel


func _ready() -> void:
	Characters.active_character_changed.connect(func(_character: CharacterData) -> void: _update())
	Characters.player_name_changed.connect(func(_new_name: String) -> void: _update())
	_update()


func _update() -> void:
	var character := Characters.get_active()
	if character == null:
		return
	portrait.texture = character.texture
	name_label.text = Characters.get_display_name(character)
	skill_label.text = Characters.get_skill_text(character)
