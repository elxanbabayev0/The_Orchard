class_name CharacterData
extends Resource
## Data for one playable character: the player's own character or a family member.
## Each character is a separate .tres file in scenes/characters/types/, so new
## characters can be added without new code. Skills come later.

## Unique, never-changing name used in code and save files (e.g. &"elio").
@export var id: StringName = &""
## The character's name. A NAME, not a translation key (names are not translated).
## Empty for the player's own character: the player types it in at New Game.
@export var display_name: String = ""
## id of this character's parent in the family tree ("" = none / not decided).
## This makes the family tree data-driven too.
@export var parent_id: StringName = &""
## Picture (placeholder for now). Drawn like the player sprite: bottom edge at the feet.
@export var texture: Texture2D
