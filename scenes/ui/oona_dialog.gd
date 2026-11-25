extends PanelContainer
## Oona's dialogue window: her words, the task and its progress, and the reward.
## Opened by Oona.talked(result, portrait) (connection in main.tscn).
## Oona's lines are neutral PLACEHOLDERS (UI_OONA_* keys) — her personality and
## dialogue are not decided. The look is a placeholder.

const FONT_SIZE := 26
const ICON_SIZE := Vector2(40, 40)
const HIGHLIGHT := Color(1.0, 0.88, 0.35)

## The task Oona just rewarded (remembered from Quests.quest_rewarded, which
## fires inside OonaVisits.talk(), right before this window opens).
var _rewarded: QuestData = null
## Set when that reward finished a story chapter (Quests.chapter_completed).
var _chapter_done: ChapterData = null

@onready var portrait: TextureRect = $Margin/HBox/Portrait
@onready var lines: VBoxContainer = $Margin/HBox/VBox/Lines
@onready var close_button: Button = $Margin/HBox/VBox/CloseButton


func _ready() -> void:
	hide()
	UIState.track(self)
	close_button.pressed.connect(hide)
	Quests.quest_rewarded.connect(func(quest: QuestData) -> void: _rewarded = quest)
	Quests.chapter_completed.connect(func(chapter: ChapterData) -> void: _chapter_done = chapter)


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		hide()
		get_viewport().set_input_as_handled()


## result: OonaVisits.Talk. Connected to Oona.talked in main.tscn.
func open(result: int, portrait_texture: Texture2D) -> void:
	portrait.texture = portrait_texture
	for child in lines.get_children():
		child.queue_free()
	match result:
		OonaVisits.Talk.GAVE_TASK:
			_add_new_task("UI_OONA_GIVE_TASK")
		OonaVisits.Talk.REMINDER:
			_add_line(tr("UI_OONA_REMINDER"))
			_add_task()
		OonaVisits.Talk.REWARD_AND_TASK:
			_add_reward()
			_add_new_task("UI_OONA_NEXT_TASK")
		OonaVisits.Talk.REWARD_JOURNEY:
			# End of a story chapter: reward, her memory of Rosa (end scene),
			# what she teaches (e.g. cuttings), then she travels.
			_add_reward()
			if _chapter_done != null:
				for key in _chapter_done.end_lines:
					_add_line(tr(key))
				for feature in _chapter_done.unlocks:
					_add_line(tr("UI_OONA_UNLOCK_%s" % String(feature).to_upper()), HIGHLIGHT)
			# After the LAST chapter its own end scene already says goodbye.
			if Quests.get_current_chapter() != null:
				_add_line(tr("UI_OONA_CHAPTER_DONE"))
		OonaVisits.Talk.JOURNEY_PACKING:
			_add_line(tr("UI_OONA_PACKING"))
		OonaVisits.Talk.REWARD_LAST:
			_add_reward()
			_add_line(tr("UI_OONA_NO_TASKS"))
		_:
			_add_line(tr("UI_OONA_NO_TASKS"))
	_rewarded = null
	_chapter_done = null
	show()
	close_button.grab_focus() # Enter / Space closes too


## The task Oona just gave: the chapter's start scene first (if it is the
## chapter's first task), then her line for the task (or a general line), then the task.
func _add_new_task(general_line_key: String) -> void:
	var quest := Quests.get_active()
	if quest != null and Quests.is_first_task_of_chapter(quest):
		var chapter := Registry.get_chapter(quest.chapter)
		if chapter != null:
			for key in chapter.start_lines:
				_add_line(tr(key))
	_add_line(tr(quest.line) if quest != null and quest.line != "" else tr(general_line_key))
	_add_task()


## "  Plant 2 saplings   1 / 2"
func _add_task() -> void:
	var quest := Quests.get_active()
	if quest == null:
		return
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	row.add_child(_make_label("• " + quest.get_description(), HIGHLIGHT))
	row.add_child(_make_label(tr("UI_QUEST_PROGRESS") % [Quests.get_progress(), quest.target]))
	lines.add_child(row)


## "Well done! This is for you:  +30 XP  [icon] +1 Morello Cherry Sapling"
func _add_reward() -> void:
	_add_line(tr("UI_OONA_REWARD"))
	if _rewarded == null:
		return
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	if _rewarded.reward_xp > 0:
		row.add_child(_make_label(tr("UI_REWARD_XP") % _rewarded.reward_xp, HIGHLIGHT))
	if _rewarded.reward_item != null:
		var icon := TextureRect.new()
		icon.texture = _rewarded.reward_item.icon
		icon.custom_minimum_size = ICON_SIZE
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		row.add_child(icon)
		row.add_child(_make_label(tr("UI_ITEM_GAINED") % [_rewarded.reward_amount, tr(_rewarded.reward_item.display_name)], HIGHLIGHT))
	lines.add_child(row)


func _add_line(text: String, color: Color = Color.WHITE) -> void:
	var label := _make_label(text, color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lines.add_child(label)


func _make_label(text: String, color: Color = Color.WHITE) -> Label:
	var label := Label.new()
	label.text = text
	label.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED # already translated
	label.add_theme_font_size_override("font_size", FONT_SIZE)
	label.add_theme_color_override("font_color", color)
	return label
