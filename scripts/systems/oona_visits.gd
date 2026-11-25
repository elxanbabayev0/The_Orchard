extends Node
## When Oona is on the farm and what happens when the player talks to her.
## Registered as the autoload "OonaVisits".
## (Decision: she comes, gives one task and leaves; she comes back 1–2 days
## after the task is done with the reward and the next task. No rush.)
##
## Rules (confirmed, see Decision log "Oona's visit rules and journey"):
## - she waits on the farm until the player talks to her,
## - after talking she leaves when the next day starts,
## - she returns in the morning SMALL_TASK_RETURN_DAYS after a small task is
##   done, BIG_TASK_RETURN_DAYS after a big one (reward XP >= BIG_TASK_XP),
## - after the last task of a story chapter she goes on a real journey: no new
##   task that day, back after JOURNEY_DAYS with an everyday task.
## Suggestion (not confirmed): in a new game she is there on day 1.
##
## The task state itself lives in Quests; the Oona NPC scene only shows her
## while is_present() and calls talk().

## Emitted when she arrives or leaves (the NPC shows / hides itself).
signal presence_changed(present: bool)

## A task with at least this much reward XP counts as "big". TEMPORARY test value.
const BIG_TASK_XP := 40
## Game days after a finished task before she comes back. TEMPORARY test values.
const SMALL_TASK_RETURN_DAYS := 1
const BIG_TASK_RETURN_DAYS := 2
## Game days she is away on her journey after a story chapter. TEMPORARY test value.
const JOURNEY_DAYS := 3

## What happened in a talk (for the dialogue window in the next step).
enum Talk {
	NOTHING,         ## she is not here
	GAVE_TASK,       ## she gave a new task
	REMINDER,        ## a task is still in progress
	REWARD_AND_TASK, ## reward for the done task + the next task
	REWARD_LAST,     ## reward, and she has no more tasks
	NO_TASKS,        ## nothing left to give
	REWARD_JOURNEY,  ## reward for a chapter's last task; she goes on her journey (no new task)
	JOURNEY_PACKING, ## talked again on the day she leaves for her journey: no task yet
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
		var quest := Quests.get_active()
		Quests.claim_reward()
		_next_visit_day = 0
		if not Quests.is_generated(quest) and Quests.is_chapter_complete(quest.chapter):
			# End of a story chapter: she really travels and comes back later.
			_next_visit_day = GameClock.day + JOURNEY_DAYS
			return Talk.REWARD_JOURNEY
		return Talk.REWARD_AND_TASK if Quests.start_next() != null else Talk.REWARD_LAST
	if Quests.get_active() != null:
		return Talk.REMINDER
	# She already said goodbye for her journey (her return day is planned):
	# she only packs today and brings the next task when she comes back.
	if _next_visit_day > GameClock.day:
		return Talk.JOURNEY_PACKING
	return Talk.GAVE_TASK if Quests.start_next() != null else Talk.NO_TASKS


func _on_quest_done(quest: QuestData) -> void:
	# If she is still here she can reward right away; otherwise she comes back later.
	if not _present:
		_next_visit_day = GameClock.day + get_return_days(quest)


## 1 day after a small task, 2 days after a big one (decision: by reward XP).
func get_return_days(quest: QuestData) -> int:
	return BIG_TASK_RETURN_DAYS if quest.reward_xp >= BIG_TASK_XP else SMALL_TASK_RETURN_DAYS


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
