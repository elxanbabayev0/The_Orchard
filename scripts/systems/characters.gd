extends Node
## Playable characters. Registered as the autoload "Characters".
## (Decision: the player starts as Rosa's grandchild with a name they type in;
## family members are unlocked later through level "invitations".)
## For now it holds the player's name; unlocked characters and the active
## character come in the next steps.

signal player_name_changed(new_name: String)

## id of the player's own character file (scenes/characters/types/player.tres).
const PLAYER_CHARACTER_ID := &"player"
const MAX_NAME_LENGTH := 16

## The name the player typed in at New Game.
var player_name: String = ""


func set_player_name(new_name: String) -> void:
	player_name = clean_name(new_name)
	player_name_changed.emit(player_name)


## Trims spaces at both ends and limits the length.
static func clean_name(raw_name: String) -> String:
	return raw_name.strip_edges().left(MAX_NAME_LENGTH)


## The character the player is controlling right now (only the player's own for now).
func get_active() -> CharacterData:
	return Registry.get_character(PLAYER_CHARACTER_ID)


## A character's shown name: the typed-in name for the player's own character.
func get_display_name(character: CharacterData) -> String:
	if character != null and character.id == PLAYER_CHARACTER_ID:
		return player_name
	return character.display_name if character != null else ""


# --- Save / load -------------------------------------------------------------
# load_save_data({}) = new-game state.

func get_save_data() -> Dictionary:
	return {"player_name": player_name}


func load_save_data(data: Dictionary) -> void:
	player_name = clean_name(str(data.get("player_name", "")))
	player_name_changed.emit(player_name)
