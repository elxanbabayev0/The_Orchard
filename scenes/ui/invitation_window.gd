extends PanelContainer
## Invitation window: choose which family member to invite to the orchard.
## (Decision: one invitation per level; a parent must come before their children.)
## Opened by LevelDisplay.invite_requested (connected in main.tscn).
## Texts come from translation keys; the look is a placeholder.

const PORTRAIT_SIZE := Vector2(48, 82)
const FONT_SIZE := 22
const SKILL_COLOR := Color(1.0, 0.88, 0.35)

@onready var close_button: Button = $Margin/VBox/Header/CloseButton
@onready var invitations_label: Label = $Margin/VBox/InvitationsLabel
@onready var cards: HFlowContainer = $Margin/VBox/Cards


func _ready() -> void:
	hide()
	UIState.track(self)
	close_button.pressed.connect(hide)


func open() -> void:
	show()
	_refresh()


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		hide()
		get_viewport().set_input_as_handled()


func _refresh() -> void:
	for child in cards.get_children():
		child.queue_free()
	invitations_label.text = tr("UI_INVITATIONS_LEFT") % Progression.invitations
	for character in Characters.get_invitable_now():
		cards.add_child(_make_card(character))


## One card: picture, name, "Rosa's child", skill, [Invite]
func _make_card(character: CharacterData) -> VBoxContainer:
	var card := VBoxContainer.new()
	card.custom_minimum_size = Vector2(150, 0)
	card.add_theme_constant_override("separation", 6)

	var portrait := TextureRect.new()
	portrait.texture = character.texture
	portrait.custom_minimum_size = PORTRAIT_SIZE
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	card.add_child(portrait)

	var name_label := _make_label(character.display_name)
	name_label.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED # a name
	card.add_child(name_label)

	var parent := Registry.get_character(character.parent_id) if character.parent_id != &"" else null
	if parent != null:
		var relation := _make_label(tr("UI_CHILD_OF") % parent.display_name)
		relation.add_theme_font_size_override("font_size", FONT_SIZE - 4)
		card.add_child(relation)

	# What this character would bring: their skill.
	var skill := _make_label(Characters.get_skill_text(character))
	skill.add_theme_font_size_override("font_size", FONT_SIZE - 4)
	skill.add_theme_color_override("font_color", SKILL_COLOR)
	skill.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	skill.custom_minimum_size = Vector2(150, 0)
	card.add_child(skill)

	var invite_button := Button.new()
	invite_button.text = tr("UI_INVITE")
	invite_button.add_theme_font_size_override("font_size", FONT_SIZE)
	invite_button.disabled = Progression.invitations <= 0
	invite_button.pressed.connect(func() -> void:
		if Characters.invite(character):
			# Nothing left to do here? Close; otherwise show who can come next.
			if Progression.invitations <= 0 or Characters.get_invitable_now().is_empty():
				hide()
			else:
				_refresh()
	)
	card.add_child(invite_button)
	return card


func _make_label(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", FONT_SIZE)
	return label
