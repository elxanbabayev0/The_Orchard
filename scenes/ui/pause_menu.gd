extends Control
## Pause menu (decision: Esc in the game → "Resume", "Main Menu", "Quit";
## Main Menu and Quit save first). The game is paused while it is open (UIState).
## Texts come from translation keys; the look is a placeholder.
##
## Esc order: other things (trade window, inventory, placement mode) get Esc
## FIRST and close themselves. The pause menu only opens if nobody used Esc.
## This works because its PauseLayer (CanvasLayer, layer 10) is the FIRST child
## of Main: _unhandled_input goes through the scene tree from the bottom up, so
## the first child hears the key last. Keep PauseLayer first when editing main.tscn!
## (layer 10 still draws it on top of everything.)

@onready var resume_button: Button = $Center/Panel/Margin/VBox/ResumeButton
@onready var main_menu_button: Button = $Center/Panel/Margin/VBox/MainMenuButton
@onready var quit_button: Button = $Center/Panel/Margin/VBox/QuitButton


func _ready() -> void:
	hide()
	UIState.track(self)
	resume_button.pressed.connect(hide)
	main_menu_button.pressed.connect(_on_main_menu_pressed)
	quit_button.pressed.connect(_on_quit_pressed)


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_cancel"):
		return
	if visible:
		hide() # Esc again = Resume
	elif not UIState.is_blocking():
		show()
		resume_button.grab_focus()
	get_viewport().set_input_as_handled()


func _on_main_menu_pressed() -> void:
	# Hide first: this un-pauses the game, otherwise the main menu would be frozen.
	hide()
	SaveManager.return_to_main_menu()


func _on_quit_pressed() -> void:
	SaveManager.quit_game()
