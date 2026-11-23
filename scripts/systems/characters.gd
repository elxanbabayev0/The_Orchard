extends Node
## Playable characters. Registered as the autoload "Characters".
## (Decisions: the player starts as Rosa's grandchild with a name they type in;
## family members are unlocked with level "invitations"; a parent must be
## invited before their children; Rosa is not playable.)
## One character is "active" (the one the player controls); the player can
## switch to their own character or to any invited family member.

signal player_name_changed(new_name: String)
## Emitted when a family member accepts an invitation.
signal character_unlocked(character: CharacterData)
## Emitted when the player switches to another character (also after loading).
signal active_character_changed(character: CharacterData)

## id of the player's own character file (scenes/characters/types/player.tres).
const PLAYER_CHARACTER_ID := &"player"
const MAX_NAME_LENGTH := 16

## The name the player typed in at New Game.
var player_name: String = ""
## ids of invited family members, in the order they came.
var _unlocked: Array[StringName] = []
## id of the character the player controls right now.
var _active_id: StringName = PLAYER_CHARACTER_ID


func set_player_name(new_name: String) -> void:
	player_name = clean_name(new_name)
	player_name_changed.emit(player_name)


## Trims spaces at both ends and limits the length.
func clean_name(raw_name: String) -> String:
	return raw_name.strip_edges().left(MAX_NAME_LENGTH)


## The character the player is controlling right now.
func get_active() -> CharacterData:
	return Registry.get_character(_active_id)


func is_active(character: CharacterData) -> bool:
	return character != null and character.id == _active_id


## Playable = the player's own character or an invited family member.
func can_switch_to(character: CharacterData) -> bool:
	if character == null:
		return false
	return character.id == PLAYER_CHARACTER_ID or is_unlocked(character)


## Makes another character the active one. Returns false (nothing changes)
## if that character is not playable or is already active.
func switch_to(character: CharacterData) -> bool:
	if not can_switch_to(character) or is_active(character):
		return false
	_active_id = character.id
	active_character_changed.emit(character)
	return true


## A character's shown name: the typed-in name for the player's own character.
func get_display_name(character: CharacterData) -> String:
	if character != null and character.id == PLAYER_CHARACTER_ID:
		return player_name
	return character.display_name if character != null else ""


# --- Skills ------------------------------------------------------------------
# (Decision: a skill works only while its character is active.)

## The active character's skill (null = none, e.g. the player's own character).
func get_active_skill() -> SkillData:
	var active := get_active()
	return active.skill if active != null else null


## How big the active skill's bonus is for `effect` (and `item`, for fruit
## specialties). 0.0 if the active skill does something else.
## Systems call this instead of reading skills themselves, e.g.
##   Characters.get_bonus(SkillData.Effect.HARVEST_BONUS, fruit)
func get_bonus(effect: SkillData.Effect, item: ItemData = null) -> float:
	var skill := get_active_skill()
	if skill == null or skill.effect != effect or not skill.applies_to(item):
		return 0.0
	return skill.value


# --- Invitations ---------------------------------------------------------------

func is_unlocked(character: CharacterData) -> bool:
	return character != null and _unlocked.has(character.id)


## Family rule: invitable, not here yet, and the parent is already here
## (a parent who cannot be invited — Rosa — does not block their children).
func can_invite(character: CharacterData) -> bool:
	if character == null or not character.invitable or is_unlocked(character):
		return false
	if character.parent_id == &"":
		return true
	var parent := Registry.get_character(character.parent_id)
	return parent == null or not parent.invitable or is_unlocked(parent)


## Everyone who could be invited right now, parents first, then by name.
func get_invitable_now() -> Array[CharacterData]:
	var result: Array[CharacterData] = []
	for character in Registry.get_all_characters():
		if can_invite(character):
			result.append(character)
	result.sort_custom(func(a: CharacterData, b: CharacterData) -> bool:
		var depth_a := _family_depth(a)
		var depth_b := _family_depth(b)
		if depth_a != depth_b:
			return depth_a < depth_b
		return a.display_name < b.display_name
	)
	return result


## Uses one invitation to bring a family member to the orchard.
## Returns false (and nothing changes) if the rule does not allow it or no invitation is left.
func invite(character: CharacterData) -> bool:
	if not can_invite(character):
		return false
	if not Progression.use_invitation():
		return false
	_unlocked.append(character.id)
	character_unlocked.emit(character)
	return true


## All invited family members, in the order they came.
func get_unlocked() -> Array[CharacterData]:
	var result: Array[CharacterData] = []
	for id in _unlocked:
		var character := Registry.get_character(id)
		if character != null:
			result.append(character)
	return result


## How many steps from the top of the family tree (Rosa = 0, her children = 1...).
func _family_depth(character: CharacterData) -> int:
	var depth := 0
	var current := character
	while current != null and current.parent_id != &"" and depth < 10:
		current = Registry.get_character(current.parent_id)
		depth += 1
	return depth


# --- Save / load -------------------------------------------------------------
# load_save_data({}) = new-game state.

func get_save_data() -> Dictionary:
	var unlocked := []
	for id in _unlocked:
		unlocked.append(String(id))
	return {"player_name": player_name, "unlocked": unlocked, "active": String(_active_id)}


func load_save_data(data: Dictionary) -> void:
	player_name = clean_name(str(data.get("player_name", "")))
	_unlocked.clear()
	for id_text in data.get("unlocked", []):
		var character := Registry.get_character(StringName(id_text))
		# Skip unknown ids, duplicates and anyone who is not invitable.
		if character != null and character.invitable and not _unlocked.has(character.id):
			_unlocked.append(character.id)
	# The active character must be playable; otherwise fall back to the player's own.
	# (Older saves have no "active" key → the player's own character.)
	var active_text := str(data.get("active", ""))
	var active := Registry.get_character(StringName(active_text)) if active_text != "" else null
	_active_id = active.id if can_switch_to(active) else PLAYER_CHARACTER_ID
	player_name_changed.emit(player_name)
	active_character_changed.emit(get_active())
