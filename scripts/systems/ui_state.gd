extends Node
## Keeps track of open windows. Registered as the autoload "UIState".
## (Decision: while a window is open the player cannot move and the clock stops.)
##
## How it works: while at least one tracked window is visible, the whole game
## is paused with Godot's built-in pause (get_tree().paused). Everything with the
## default process mode stops: player, GameClock, trees, NPCs, animations...
## Tracked windows are set to PROCESS_MODE_ALWAYS, so they keep working.
##
## A window only has to call `UIState.track(self)` once (in its _ready).

## Emitted when the game becomes blocked (first window opened) or free again.
signal blocking_changed(blocking: bool)

var _open_windows: Array[Node] = []


## Starts watching a window. It counts as "open" whenever it is visible.
func track(window: CanvasItem) -> void:
	window.process_mode = Node.PROCESS_MODE_ALWAYS
	window.visibility_changed.connect(_on_visibility_changed.bind(window))
	# A window that disappears with its scene (e.g. going to the main menu) must not
	# keep the game paused forever.
	window.tree_exiting.connect(_set_open.bind(window, false))
	_set_open(window, window.visible)


## True while any tracked window is open.
func is_blocking() -> bool:
	return not _open_windows.is_empty()


func _on_visibility_changed(window: CanvasItem) -> void:
	_set_open(window, window.visible)


func _set_open(window: Node, open: bool) -> void:
	var was_blocking := is_blocking()
	if open and not _open_windows.has(window):
		_open_windows.append(window)
	elif not open:
		_open_windows.erase(window)
	if is_blocking() != was_blocking:
		get_tree().paused = is_blocking()
		blocking_changed.emit(is_blocking())
