extends Node
## Rosa's kitchen: making jam. Registered as the autoload "Kitchen".
## (Decision "Processing: jam in Rosa's kitchen": the player starts a pot during
## the day, the jam sets overnight and is ready the next morning at
## GameClock.WAKE_HOUR. No timers or production queues.)
##
## A pot holds one recipe (e.g. 5 × Sweet Cherry → 1 Sweet Cherry Jam). The
## fruit is taken when cooking starts; in the morning the jar goes straight to
## the Inventory (with the usual "+1 Sweet Cherry Jam" pop-up).
## The kitchen window (scenes/ui/kitchen_window.gd) only calls cook() and
## reads the state; recipes come from the Registry.

## Emitted when a pot starts or finishes (the kitchen window refreshes).
signal pots_changed

## How many pots can cook at the same time. TEMPORARY balance value.
const POTS := 3

## Pots that are cooking: [{recipe: RecipeData, ready_day: int}]
var _pots: Array[Dictionary] = []


func _ready() -> void:
	GameClock.minute_changed.connect(func(_d: int, _h: int, _m: int) -> void: _finish_ready_pots())


## The pots that are cooking right now (copies, for the UI).
func get_pots() -> Array[Dictionary]:
	return _pots.duplicate(true)


func get_free_pots() -> int:
	return POTS - _pots.size()


## Is there a free pot and enough fruit for this recipe?
func can_cook(recipe: RecipeData) -> bool:
	return recipe != null and get_free_pots() > 0 \
		and Inventory.has_item(recipe.input, recipe.input_amount)


## Starts a pot. All-or-nothing: returns false (and takes nothing) if not possible.
func cook(recipe: RecipeData) -> bool:
	if not can_cook(recipe):
		return false
	if not Inventory.remove_item(recipe.input, recipe.input_amount):
		return false
	_pots.append({"recipe": recipe, "ready_day": _next_morning_day()})
	pots_changed.emit()
	return true


## The day whose WAKE_HOUR the jam will be ready: today if it is still before
## the morning (e.g. cooked at 02:00), otherwise tomorrow.
func _next_morning_day() -> int:
	return GameClock.day if GameClock.get_hour() < GameClock.WAKE_HOUR else GameClock.day + 1


func _is_ready(pot: Dictionary) -> bool:
	var ready_day: int = pot["ready_day"]
	return GameClock.day > ready_day \
		or (GameClock.day == ready_day and GameClock.get_hour() >= GameClock.WAKE_HOUR)


## Morning: every ready pot gives its jars. minute_changed also fires after a
## big time jump (sleeping), so no morning is missed.
func _finish_ready_pots() -> void:
	var finished := false
	for pot in _pots.duplicate():
		if not _is_ready(pot):
			continue
		var recipe: RecipeData = pot["recipe"]
		_pots.erase(pot)
		finished = true
		if recipe.output != null:
			Inventory.add_item(recipe.output, recipe.output_amount)
			GameEvents.item_produced.emit(recipe.output, recipe.output_amount)
	if finished:
		pots_changed.emit()


# --- Save / load -------------------------------------------------------------
# load_save_data({}) = new-game state (all pots empty).

func get_save_data() -> Dictionary:
	var pots := []
	for pot in _pots:
		pots.append({"recipe": String(pot["recipe"].id), "ready_day": pot["ready_day"]})
	return {"pots": pots}


func load_save_data(data: Dictionary) -> void:
	_pots.clear()
	for saved in data.get("pots", []):
		if not saved is Dictionary or _pots.size() >= POTS:
			continue
		var recipe := Registry.get_recipe(StringName(str(saved.get("recipe", ""))))
		if recipe == null:
			continue # unknown recipe: skip it instead of crashing
		_pots.append({"recipe": recipe, "ready_day": maxi(1, int(saved.get("ready_day", 1)))})
	pots_changed.emit()
