extends VBoxContainer
## Shows the player's level, an XP bar for the current level, and an
## "Invite family (N)" button while an invitation can be used.
## Texts come from translation keys (UI_LEVEL, UI_INVITE_BUTTON); the look is a placeholder.

## Emitted when the player clicks the invite button.
## Connected to InvitationWindow.open in main.tscn.
signal invite_requested

@onready var level_label: Label = $LevelLabel
@onready var xp_bar: ProgressBar = $XPBar
@onready var invite_button: Button = $InviteButton


func _ready() -> void:
	Progression.xp_changed.connect(func(_xp: int, _level: int) -> void: _update())
	Progression.invitations_changed.connect(func(_count: int) -> void: _update())
	Characters.character_unlocked.connect(func(_character: CharacterData) -> void: _update())
	invite_button.pressed.connect(invite_requested.emit)
	_update()


func _update() -> void:
	level_label.text = tr("UI_LEVEL") % Progression.level
	xp_bar.value = Progression.get_level_progress() * 100.0
	# Only when an invitation exists AND someone can actually be invited.
	invite_button.visible = Progression.invitations > 0 and not Characters.get_invitable_now().is_empty()
	invite_button.text = tr("UI_INVITE_BUTTON") % Progression.invitations
