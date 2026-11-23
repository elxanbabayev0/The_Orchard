class_name FruitTree
extends StaticBody2D
## A fruit tree placed in the world.
## All numbers and pictures come from `data` (a TreeData resource),
## so this one scene works for every tree type.

## SAPLING and YOUNG happen once. FLOWERING -> UNRIPE -> RIPE is the fruit cycle,
## which starts again from FLOWERING after a harvest.
enum Stage { SAPLING, YOUNG, FLOWERING, UNRIPE, RIPE }

## Emitted after a successful harvest (the fruit is already in the Inventory by then).
signal harvested(item: ItemData, amount: int)

## Every fruit tree is in this group (e.g. Quests counts the trees of the orchard).
const GROUP := &"fruit_trees"
## Game days before the same tree gives another cutting. TEMPORARY test value.
const CUTTING_COOLDOWN_DAYS := 3.0
## Same as TreeActionMenu.GROUP (the harvest / cutting choice menu).
const ACTION_MENU_GROUP := &"tree_action_menu"
## Same as the feature id in chapter_1.tres (Oona teaches cuttings).
const CUTTINGS_FEATURE := &"cuttings"

@export var data: TreeData

var stage: Stage = Stage.SAPLING
## Game days spent in the current stage.
var stage_time: float = 0.0
## Game days until this tree can give a cutting again (0 = ready).
var cutting_cooldown: float = 0.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var stage_label: Label = $StageLabel


func _ready() -> void:
	if data == null:
		push_error("FruitTree '%s' has no TreeData assigned." % name)
		return
	add_to_group(GROUP)
	if data.fruit == null:
		push_warning("TreeData '%s' has no fruit item assigned." % data.id)
	_update_visuals()
	# Grow together with the game clock (also pauses when the clock is paused).
	GameClock.time_advanced.connect(advance_time)


## Moves the tree forward by `amount` game days.
## Called by GameClock.time_advanced; can also be called directly (tests, sleeping).
func advance_time(amount: float) -> void:
	# The cutting cooldown counts plain game days (not sped up by growth bonuses).
	cutting_cooldown = maxf(0.0, cutting_cooldown - amount)
	if stage == Stage.RIPE:
		return # Ripe fruit waits on the tree until harvested.
	# Skill: trees grow faster (e.g. +20%) while that character is active.
	# Tree type speed (e.g. Snow Mulberry) × skill bonus (e.g. Freya's +20%).
	stage_time += amount * data.growth_speed * (1.0 + Characters.get_bonus(SkillData.Effect.GROWTH_SPEED))
	# "while", not "if": a big time jump can pass several stages at once.
	while stage != Stage.RIPE and stage_time >= _get_stage_duration(stage):
		stage_time -= _get_stage_duration(stage)
		_set_stage((stage + 1) as Stage)
	if stage == Stage.RIPE:
		stage_time = 0.0


## Called by the player when they press the interact key near this tree.
## A grown rare tree (once Oona taught cuttings) opens the choice menu
## (Harvest / Take cutting); every other tree just harvests when ripe.
func interact(_player: Node) -> void:
	var menu := get_tree().get_first_node_in_group(ACTION_MENU_GROUP)
	if menu != null and (_offers_cuttings() or can_graft()):
		menu.open(self)
	elif can_harvest():
		harvest()
	else:
		print("%s is not ripe yet (%s)." % [tr(data.display_name), Stage.keys()[stage]])


# --- Cuttings (propagating rare trees) -----------------------------------------
# Decision: a grown rare tree gives a cutting; then it skips one fruit cycle
# (back to FLOWERING) and needs CUTTING_COOLDOWN_DAYS before the next one.

## A grown rare tree whose cuttings Oona has taught (cooldown or not).
func _offers_cuttings() -> bool:
	return stage >= Stage.FLOWERING \
		and Registry.get_cutting_for(data) != null \
		and Quests.is_feature_unlocked(CUTTINGS_FEATURE)


func can_take_cutting() -> bool:
	return _offers_cuttings() and cutting_cooldown <= 0.0


## Whole game days until the next cutting (0 = ready now).
func get_cutting_days_left() -> int:
	return ceili(cutting_cooldown)


## Grafting: a cutting from the Inventory whose variety belongs to this (common,
## grown) tree's type, e.g. a Golden Sweet Cherry Cutting for a Sweet Cherry tree.
## null if grafting is not possible here.
func get_graft_cutting() -> ItemData:
	if stage < Stage.FLOWERING or not Quests.is_feature_unlocked(CUTTINGS_FEATURE):
		return null
	for item in Inventory.get_items():
		if item.category == ItemData.Category.CUTTING and item.grows_into != null \
				and item.grows_into.variety_of == data:
			return item
	return null


func can_graft() -> bool:
	return get_graft_cutting() != null


## Grafts a matching cutting onto this tree: it becomes the rare variety, goes
## back to FLOWERING (fruit is lost) and its cutting cooldown starts (decision:
## same rules as taking a cutting). Returns false if not possible.
func graft() -> bool:
	var cutting := get_graft_cutting()
	if cutting == null or not Inventory.remove_item(cutting, 1):
		return false
	data = cutting.grows_into
	cutting_cooldown = CUTTING_COOLDOWN_DAYS
	stage_time = 0.0
	_set_stage(Stage.FLOWERING)
	GameEvents.tree_grafted.emit(data, self) # Oona's "have N trees" tasks...
	return true


## Gives one cutting to the Inventory. The tree goes back to FLOWERING (any
## unripe or ripe fruit is lost) and the cooldown starts. Returns false if not possible.
func take_cutting() -> bool:
	if not can_take_cutting():
		return false
	var cutting := Registry.get_cutting_for(data)
	Inventory.add_item(cutting, 1)
	GameEvents.cutting_taken.emit(cutting, self) # Oona's tasks...
	cutting_cooldown = CUTTING_COOLDOWN_DAYS
	stage_time = 0.0
	_set_stage(Stage.FLOWERING)
	return true


func can_harvest() -> bool:
	return stage == Stage.RIPE


## Picks the ripe fruit and starts the fruit cycle again from FLOWERING.
## Returns how many fruits were picked (0 if nothing was ripe).
func harvest() -> int:
	if not can_harvest():
		return 0
	# Skill: extra fruit per harvest (all fruit, or one fruit specialty).
	var amount := data.harvest_yield + roundi(Characters.get_bonus(SkillData.Effect.HARVEST_BONUS, data.fruit))
	stage_time = 0.0
	_set_stage(Stage.FLOWERING)
	if data.fruit != null:
		Inventory.add_item(data.fruit, amount)
		GameEvents.fruit_harvested.emit(data.fruit, amount) # XP, Oona's tasks...
	# The signal stays for things like sounds or effects later.
	harvested.emit(data.fruit, amount)
	return amount


func _set_stage(new_stage: Stage) -> void:
	var grew_up := stage == Stage.YOUNG and new_stage == Stage.FLOWERING
	stage = new_stage
	_update_visuals()
	if grew_up:
		GameEvents.tree_grown.emit(data, self) # Oona's tasks...


func _get_stage_duration(for_stage: Stage) -> float:
	match for_stage:
		Stage.SAPLING:
			return data.sapling_days
		Stage.YOUNG:
			return data.young_days
		Stage.FLOWERING:
			return data.flowering_days
		Stage.UNRIPE:
			return data.unripe_days
		_:
			return INF # RIPE has no duration: it waits.


func _get_stage_texture(for_stage: Stage) -> Texture2D:
	match for_stage:
		Stage.SAPLING:
			return data.sapling_texture
		Stage.YOUNG:
			return data.young_texture
		Stage.FLOWERING:
			return data.flowering_texture
		Stage.UNRIPE:
			return data.unripe_texture
		_:
			return data.ripe_texture


func _update_visuals() -> void:
	var texture := _get_stage_texture(stage)
	sprite.texture = texture
	if texture != null:
		# Lift the picture so its bottom edge sits on the origin (bottom of the trunk).
		sprite.offset = Vector2(0, -texture.get_height() / 2.0)
	# Debug text so we can see the stage while there is no real art.
	stage_label.text = Stage.keys()[stage]


# --- Save / load -------------------------------------------------------------
# "type" and the position are used by whoever re-creates the tree when loading
# (it sets `data` from the Registry and the position before add_child).
# load_save_data() itself only restores the growth state, after the tree is in the scene.

func get_save_data() -> Dictionary:
	return {
		"type": String(data.id),
		"x": global_position.x,
		"y": global_position.y,
		"stage": stage,
		"stage_time": stage_time,
		"cutting_cooldown": cutting_cooldown,
	}


func load_save_data(saved: Dictionary) -> void:
	# clampi(): a broken or very old save can never put the tree in a stage that does not exist.
	stage = clampi(int(saved.get("stage", Stage.SAPLING)), 0, Stage.size() - 1) as Stage
	stage_time = float(saved.get("stage_time", 0.0))
	cutting_cooldown = clampf(float(saved.get("cutting_cooldown", 0.0)), 0.0, CUTTING_COOLDOWN_DAYS)
	_update_visuals()
