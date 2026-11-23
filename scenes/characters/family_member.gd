class_name FamilyMember
extends StaticBody2D
## A playable character who is NOT active right now, standing on the farm.
## (Decision: invited characters stand on the farm; walk up and press E to
## switch; the character you leave stays standing where you were.)
##
## Created by FamilyMembers (scenes/world/family_members.gd), never placed by hand.

## Who this is. Set before add_child (or later with set_character).
var character: CharacterData
## Which way this character looks while standing.
var facing: CharacterData.Facing = CharacterData.Facing.DOWN

@onready var sprite: Sprite2D = $Sprite2D
@onready var name_label: Label = $NameLabel


func _ready() -> void:
	_update_look()
	# The player's own character can stand here too; its name may change.
	Characters.player_name_changed.connect(func(_new_name: String) -> void: _update_look())


func set_character(new_character: CharacterData) -> void:
	character = new_character
	if is_node_ready():
		_update_look()


## Called by the player (E). Swap: the player becomes this character and moves
## to this spot; this NPC becomes the character the player was, at the player's spot.
func interact(player: Node2D) -> void:
	var previous := Characters.get_active()
	if not Characters.switch_to(character):
		return
	var player_spot := player.global_position
	player.global_position = global_position
	global_position = player_spot
	# The character left behind keeps looking where the player was looking.
	facing = player.facing
	set_character(previous)


func _update_look() -> void:
	if character == null:
		return
	var picture := character.get_texture_for(facing)
	if picture != null:
		sprite.texture = picture
		# "Origin on the ground": the bottom of the picture sits on the feet.
		sprite.position = Vector2(0, -picture.get_height() / 2.0)
	name_label.text = Characters.get_display_name(character)
	name = "Member_%s" % character.id
