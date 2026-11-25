extends Control
## "Go to sleep?" window and the fade to black while sleeping.
## Opened by RosaHouse.sleep_requested (connection in main.tscn).
##
## - Too early (before GameClock.SLEEP_START_HOUR): only a message + Close.
## - Late enough: Sleep / Cancel. Sleep fades the screen to black, skips the
##   clock to the morning (GameClock.sleep_until_morning), saves, fades back.
##
## The root covers the whole screen and is tracked by UIState, so the game is
## paused while the question or the fade is shown (the clock is moved directly
## by sleep_until_morning, which works while paused). The look is a placeholder.

## Seconds for the fade out and for the fade in. TEMPORARY values.
const FADE_TIME := 0.6
## Black screen time between the fades, so the night "passes".
const DARK_TIME := 0.4

var _sleeping := false

@onready var panel: PanelContainer = $Panel
@onready var message: Label = $Panel/Margin/VBox/Message
@onready var sleep_button: Button = $Panel/Margin/VBox/Buttons/SleepButton
@onready var cancel_button: Button = $Panel/Margin/VBox/Buttons/CancelButton
@onready var fade: ColorRect = $Fade


func _ready() -> void:
	hide()
	UIState.track(self)
	sleep_button.pressed.connect(_on_sleep_pressed)
	cancel_button.pressed.connect(hide)


func open() -> void:
	if visible:
		return
	_sleeping = false
	fade.modulate.a = 0.0
	panel.show()
	var can_sleep := GameClock.can_sleep()
	sleep_button.visible = can_sleep
	if can_sleep:
		message.text = tr("UI_SLEEP_QUESTION")
		cancel_button.text = "UI_CANCEL"
	else:
		message.text = tr("UI_SLEEP_TOO_EARLY") % GameClock.SLEEP_START_HOUR
		cancel_button.text = "UI_CLOSE"
	show()
	(sleep_button if can_sleep else cancel_button).grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if visible and not _sleeping and event.is_action_pressed("ui_cancel"):
		hide()
		get_viewport().set_input_as_handled()


func _on_sleep_pressed() -> void:
	_sleeping = true
	panel.hide()
	var tween := create_tween()
	tween.tween_property(fade, "modulate:a", 1.0, FADE_TIME)
	tween.tween_callback(_sleep)
	tween.tween_interval(DARK_TIME)
	tween.tween_property(fade, "modulate:a", 0.0, FADE_TIME)
	tween.tween_callback(_wake_up)


func _sleep() -> void:
	if GameClock.sleep_until_morning():
		# The autosave on day_changed runs before the trees get the night's
		# growth (time_advanced comes after it), so save once more now.
		SaveManager.save_game()


func _wake_up() -> void:
	_sleeping = false
	hide()
