extends VBoxContainer
## Left side of the screen, under the level: Oona's current task and its progress,
## e.g. "Oona's task" / "Plant 2 saplings  1 / 2", or "Done! Oona will come back."
## Hidden while there is no task. The look is a placeholder.

@onready var title_label: Label = $TitleLabel
@onready var task_label: Label = $TaskLabel


func _ready() -> void:
	Quests.quest_started.connect(func(_quest: QuestData) -> void: _update())
	Quests.quest_progressed.connect(func(_quest: QuestData, _progress: int) -> void: _update())
	Quests.quest_rewarded.connect(func(_quest: QuestData) -> void: _update())
	OonaVisits.presence_changed.connect(func(_present: bool) -> void: _update())
	_update()


func _update() -> void:
	var quest := Quests.get_active()
	visible = quest != null
	if quest == null:
		return
	if Quests.is_done():
		# She may still be on the farm: then just go and talk to her.
		task_label.text = tr("UI_QUEST_TRACKER_DONE_HERE" if OonaVisits.is_present() else "UI_QUEST_TRACKER_DONE")
	else:
		task_label.text = "%s  %s" % [quest.get_description(), tr("UI_QUEST_PROGRESS") % [Quests.get_progress(), quest.target]]
