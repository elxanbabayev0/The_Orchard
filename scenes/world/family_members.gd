extends Node2D
## Keeps the family on the farm: one FamilyMember for every playable character
## who is not active right now (invited family members, and the player's own
## character while someone else is being played).
## Lives at Main/Entities/Family (Y-sorted, so members sort with everything else).
##
## Newly invited characters appear on a free spot near the player.
## Saved by SaveManager (positions of everyone standing here).

const FAMILY_MEMBER_SCENE := preload("res://scenes/characters/family_member.tscn")
## Where a new arrival may stand, relative to the player (tried in this order).
const ARRIVAL_OFFSETS: Array[Vector2] = [
	Vector2(96, 0), Vector2(-96, 0), Vector2(0, 96), Vector2(0, -96),
	Vector2(96, 96), Vector2(-96, 96), Vector2(96, -96), Vector2(-96, -96),
	Vector2(192, 0), Vector2(-192, 0), Vector2(0, 192), Vector2(0, -192),
]
## Area at the feet that must be free (a bit larger than a character's feet).
const FREE_AREA_SIZE := Vector2(56, 32)

## Set in main.tscn.
@export var player: Node2D
## Arrivals must stand where this ground has a tile.
@export var ground: Ground

## Characters waiting for a spot. Physics queries are safest in _physics_process,
## and that only runs while the game is not paused (the invitation window pauses it).
var _waiting: Array[CharacterData] = []
var _free_area := RectangleShape2D.new()


func _ready() -> void:
	_free_area.size = FREE_AREA_SIZE
	Characters.character_unlocked.connect(_on_character_unlocked)
	# New game / F6: build from the current state (usually nobody yet).
	load_save_data({})


func _on_character_unlocked(character: CharacterData) -> void:
	_waiting.append(character)


func _physics_process(_delta: float) -> void:
	while not _waiting.is_empty():
		var character: CharacterData = _waiting.pop_front()
		if _find_member(character) == null and not Characters.is_active(character):
			_add_member(character, _find_arrival_spot())


## A free spot next to the player; if everything is blocked, right next to them.
func _find_arrival_spot() -> Vector2:
	for offset in ARRIVAL_OFFSETS:
		var spot := player.global_position + offset
		if _is_free(spot):
			return spot
	return player.global_position + ARRIVAL_OFFSETS[0]


func _is_free(spot: Vector2) -> bool:
	if ground != null and not ground.has_ground_at(spot):
		return false
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = _free_area
	query.transform = Transform2D(0.0, spot - Vector2(0, FREE_AREA_SIZE.y / 2.0))
	return get_world_2d().direct_space_state.intersect_shape(query, 1).is_empty()


func _add_member(character: CharacterData, spot: Vector2) -> FamilyMember:
	var member := FAMILY_MEMBER_SCENE.instantiate() as FamilyMember
	member.character = character # before add_child: _ready() reads it
	member.position = to_local(spot)
	add_child(member)
	return member


func _find_member(character: CharacterData) -> FamilyMember:
	for child in get_children():
		if child is FamilyMember and child.character == character:
			return child
	return null


## Everyone who should be standing here: playable and not active.
func _get_standing_characters() -> Array[CharacterData]:
	var result: Array[CharacterData] = []
	var own := Registry.get_character(Characters.PLAYER_CHARACTER_ID)
	if own != null and not Characters.is_active(own):
		result.append(own)
	for character in Characters.get_unlocked():
		if not Characters.is_active(character):
			result.append(character)
	return result


# --- Save / load -------------------------------------------------------------
# Called after Characters is loaded (it decides who is unlocked and active).

func get_save_data() -> Dictionary:
	var members := []
	for child in get_children():
		if child is FamilyMember and child.character != null:
			members.append({
				"id": String(child.character.id),
				"x": child.global_position.x,
				"y": child.global_position.y,
			})
	return {"members": members}


func load_save_data(data: Dictionary) -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	_waiting.clear()
	var saved_spots := {}
	for saved in data.get("members", []):
		if saved is Dictionary:
			saved_spots[StringName(str(saved.get("id", "")))] = Vector2(
				float(saved.get("x", 0)), float(saved.get("y", 0)))
	for character in _get_standing_characters():
		if saved_spots.has(character.id):
			_add_member(character, saved_spots[character.id])
		else:
			_waiting.append(character) # no saved spot: placed near the player
