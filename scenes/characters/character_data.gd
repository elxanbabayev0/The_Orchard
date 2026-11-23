class_name CharacterData
extends Resource
## Data for one playable character: the player's own character or a family member.
## Each character is a separate .tres file in scenes/characters/types/, so new
## characters can be added without new code.

## Unique, never-changing name used in code and save files (e.g. &"elio").
@export var id: StringName = &""
## The character's name. A NAME, not a translation key (names are not translated).
## Empty for the player's own character: the player types it in at New Game.
@export var display_name: String = ""
## id of this character's parent in the family tree ("" = none / not decided).
## This makes the family tree data-driven too.
@export var parent_id: StringName = &""
## Which way a character looks. DOWN = towards the camera (front view).
enum Facing { DOWN, UP, LEFT, RIGHT }

## Front view (facing DOWN, towards the camera). Also used for portraits and
## for any direction that has no picture of its own.
## Drawn like the player sprite: bottom edge at the feet.
@export var texture: Texture2D
@export_group("Directions")
## Back view (walking UP / away from the camera).
@export var texture_back: Texture2D
## Looking LEFT.
@export var texture_left: Texture2D
## Looking RIGHT.
@export var texture_right: Texture2D
@export_group("")
## Can this character be invited with a level invitation?
## False for Rosa (background character) and for the player's own character.
@export var invitable: bool = false
## Passive bonus while this character is active (null = no skill, e.g. the player's own).
## Written inside this file. Systems use Characters.get_bonus(), not this directly.
@export var skill: SkillData


## The picture for a direction; falls back to the front view if it is missing.
func get_texture_for(facing: Facing) -> Texture2D:
	var picture: Texture2D = null
	match facing:
		Facing.UP:
			picture = texture_back
		Facing.LEFT:
			picture = texture_left
		Facing.RIGHT:
			picture = texture_right
	return picture if picture != null else texture


## Turns a movement direction into a facing: the stronger axis wins
## (moving diagonally up-left = LEFT if the sideways part is bigger).
static func facing_from_vector(direction: Vector2) -> Facing:
	if absf(direction.x) > absf(direction.y):
		return Facing.RIGHT if direction.x > 0.0 else Facing.LEFT
	return Facing.DOWN if direction.y > 0.0 else Facing.UP
