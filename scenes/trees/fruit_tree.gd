class_name FruitTree
extends StaticBody2D
## A fruit tree placed in the world.
## All numbers and pictures come from `data` (a TreeData resource),
## so this one scene works for every tree type.

## SAPLING and YOUNG happen once. FLOWERING -> UNRIPE -> RIPE is the fruit cycle,
## which starts again from FLOWERING after a harvest.
enum Stage { SAPLING, YOUNG, FLOWERING, UNRIPE, RIPE }

@export var data: TreeData

var stage: Stage = Stage.SAPLING
## Time spent in the current stage (seconds for now, game days later).
var stage_time: float = 0.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var stage_label: Label = $StageLabel


func _ready() -> void:
	if data == null:
		push_error("FruitTree '%s' has no TreeData assigned." % name)
		set_process(false)
		return
	_update_visuals()


func _process(delta: float) -> void:
	advance_time(delta)


## Moves the tree forward in time.
## Kept separate from _process so the game clock can drive it later.
func advance_time(amount: float) -> void:
	if stage == Stage.RIPE:
		return # Ripe fruit waits on the tree until harvested.
	stage_time += amount
	# "while", not "if": a big time jump can pass several stages at once.
	while stage != Stage.RIPE and stage_time >= _get_stage_duration(stage):
		stage_time -= _get_stage_duration(stage)
		_set_stage((stage + 1) as Stage)
	if stage == Stage.RIPE:
		stage_time = 0.0


func _set_stage(new_stage: Stage) -> void:
	stage = new_stage
	_update_visuals()


func _get_stage_duration(for_stage: Stage) -> float:
	match for_stage:
		Stage.SAPLING:
			return data.sapling_duration
		Stage.YOUNG:
			return data.young_duration
		Stage.FLOWERING:
			return data.flowering_duration
		Stage.UNRIPE:
			return data.unripe_duration
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
