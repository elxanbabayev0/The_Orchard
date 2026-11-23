extends Control
## Main menu (decision: "Continue" only if a save exists, "New Game", "Quit").
## This is the project's main scene. Texts come from translation keys; the look is a placeholder.

@onready var continue_button: Button = $Center/VBox/ContinueButton
@onready var new_game_button: Button = $Center/VBox/NewGameButton
@onready var quit_button: Button = $Center/VBox/QuitButton
@onready var confirm_dialog: ConfirmationDialog = $ConfirmNewGame


func _ready() -> void:
	# No game time passes while the player is in the menu.
	GameClock.paused = true
	continue_button.visible = SaveManager.has_save()

	continue_button.pressed.connect(SaveManager.continue_game)
	new_game_button.pressed.connect(_on_new_game_pressed)
	quit_button.pressed.connect(get_tree().quit)
	confirm_dialog.confirmed.connect(SaveManager.new_game)

	# Keyboard / gamepad: the first visible button is selected, so Enter works right away.
	if continue_button.visible:
		continue_button.grab_focus()
	else:
		new_game_button.grab_focus()


func _on_new_game_pressed() -> void:
	# Starting over would overwrite the old save at the next autosave, so ask first.
	if SaveManager.has_save():
		confirm_dialog.popup_centered()
	else:
		SaveManager.new_game()
