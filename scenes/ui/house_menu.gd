extends PanelContainer
## Small menu at Rosa's house: Sleep / Kitchen (decision "Processing: jam in
## Rosa's kitchen"). Opened by RosaHouse.menu_requested; the choices are
## signals connected in main.tscn (sleep_chosen → SleepPrompt.open,
## kitchen_chosen → KitchenWindow.open), so this menu knows neither window.
## The look is a placeholder.

signal sleep_chosen
signal kitchen_chosen

@onready var sleep_button: Button = $Margin/VBox/Buttons/SleepButton
@onready var kitchen_button: Button = $Margin/VBox/Buttons/KitchenButton
@onready var close_button: Button = $Margin/VBox/Buttons/CloseButton


func _ready() -> void:
	hide()
	UIState.track(self)
	# Hide first, then open the next window (one window at a time).
	sleep_button.pressed.connect(func() -> void:
		hide()
		sleep_chosen.emit()
	)
	kitchen_button.pressed.connect(func() -> void:
		hide()
		kitchen_chosen.emit()
	)
	close_button.pressed.connect(hide)


func open() -> void:
	show()
	kitchen_button.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		hide()
		get_viewport().set_input_as_handled()
