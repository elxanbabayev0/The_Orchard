extends Node
## When Oona is on the farm and what happens when the player talks to her.
## Registered as the autoload "OonaVisits".
## (Decision: she comes, gives one task and leaves; she comes back 1–2 days
## after the task is done with the reward and the next task. No rush.)
##
## Suggestions, NOT confirmed by the user (TEMPORARY values):
## - she waits on the farm until the player talks to her,
## - after talking she leaves when the next day starts,
## - she returns RETURN_DELAY_DAYS after the task is done (in the morning),
## - in a new game she is there on day 1.
##
## The task state itself lives in Quests; the Oona NPC scene only shows her
## while is_present() and calls talk().

## Emitted when she arrives or leaves (the NPC shows / hides itself).
signal presence_changed(present: bool)

## Game days after a finished task before she comes back. TEMPORARY test value.
const RETURN_DELAY_DAYS := 1

## What happened in a talk (for the dialogue window in the next step).
enum Talk {
	NOTHING,         ## she is not here
	GAVE_TASK,       ## she gave a new task
	REMINDER,        ## a task is still in progress
	REWARD_AND_TASK, ## reward for the done task + the next task
	REWARD_LAST,     ## reward, and she has no more tasks
	NO_TASKS,        ## nothing left to give
}

var _present := false
## She already talked today: she leaves when the next day starts.
var _talked_today := false
## Day she comes back (0 = no visit planned).
var _next_visit_day := 0


func _ready() -> void:
	GameClock.day_changed.connect(_on_day_changed)
	Quests.quest_done.connect(_on_quest_done)


func is_present() -> bool:
	return _present


## The player talks to Oona. Returns what happened (see Talk).
func talk() -> Talk:
	if not _present:
		return Talk.NOTHING
	_talked_today = true
	if Quests.is_done():
		Quests.claim_reward()
		_next_visit_day = 0
		return Talk.REWARD_AND_TASK if Quests.start_next() != null else Talk.REWARD_LAST
	if Quests.get_active() != null:
		return Talk.REMINDER
	return Talk.GAVE_TASK if Quests.start_next() != null else Talk.NO_TASKS


func _on_quest_done(_quest: QuestData) -> void:
	# If she is still here she can reward right away; otherwise she comes back later.
	if not _present:
		_next_visit_day = GameClock.day + RETURN_DELAY_DAYS


func _on_day_changed(day: int) -> void:
	if _present and _talked_today:
		_set_present(false)
	_talked_today = false
	if not _present and _next_visit_day > 0 and day >= _next_visit_day:
		_next_visit_day = 0
		_set_present(true)


func _set_present(present: bool) -> void:
	if _present == present:
		return
	_present = present
	presence_changed.emit(present)


# --- Save / load -------------------------------------------------------------
# load_save_data({}) = new game: she is on the farm on day 1.

func get_save_data() -> Dictionary:
	return {"present": _present, "talked_today": _talked_today, "next_visit_day": _next_visit_day}


func load_save_data(data: Dictionary) -> void:
	_present = bool(data.get("present", true))
	_talked_today = bool(data.get("talked_today", false))
	_next_visit_day = maxi(0, int(data.get("next_visit_day", 0)))
	presence_changed.emit(_present)
