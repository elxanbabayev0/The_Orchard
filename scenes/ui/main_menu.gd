extends Control
## Main menu (decision: "Continue" only if a save exists, "New Game", "Quit").
## New Game asks for the player's name first (decision: the player is Rosa's
## grandchild with a name they type in).
## This is the project's main scene. Texts come from translation keys; the look is a placeholder.

@onready var continue_button: Button = $Center/VBox/ContinueButton
@onready var new_game_button: Button = $Center/VBox/NewGameButton
@onready var quit_button: Button = $Center/VBox/QuitButton
@onready var confirm_dialog: ConfirmationDialog = $ConfirmNewGame
@onready var name_entry: Control = $NameEntry
@onready var name_edit: LineEdit = $NameEntry/Center/Panel/Margin/VBox/NameEdit
@onready var start_button: Button = $NameEntry/Center/Panel/Margin/VBox/Buttons/StartButton
@onready var cancel_button: Button = $NameEntry/Center/Panel/Margin/VBox/Buttons/CancelButton


func _ready() -> void:
	# No game time passes while the player is in the menu.
	GameClock.paused = true
	continue_button.visible = SaveManager.has_save()

	continue_button.pressed.connect(SaveManager.continue_game)
	new_game_button.pressed.connect(_on_new_game_pressed)
	quit_button.pressed.connect(get_tree().quit)
	confirm_dialog.confirmed.connect(_show_name_entry)

	name_edit.text_changed.connect(func(_text: String) -> void: _update_start_button())
	name_edit.text_submitted.connect(func(_text: String) -> void: _start_new_game())
	start_button.pressed.connect(_start_new_game)
	cancel_button.pressed.connect(name_entry.hide)

	# Keyboard / gamepad: the first visible button is selected, so Enter works right away.
	if continue_button.visible:
		continue_button.grab_focus()
	else:
		new_game_button.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if name_entry.visible and event.is_action_pressed("ui_cancel"):
		name_entry.hide()
		new_game_button.grab_focus()
		get_viewport().set_input_as_handled()


func _on_new_game_pressed() -> void:
	# Starting over would overwrite the old save at the next autosave, so ask first.
	if SaveManager.has_save():
		confirm_dialog.popup_centered()
	else:
		_show_name_entry()


func _show_name_entry() -> void:
	name_edit.text = ""
	_update_start_button()
	name_entry.show()
	name_edit.grab_focus()


func _update_start_button() -> void:
	start_button.disabled = Characters.clean_name(name_edit.text).is_empty()


func _start_new_game() -> void:
	var player_name := Characters.clean_name(name_edit.text)
	if player_name.is_empty():
		return
	SaveManager.new_game(player_name)
