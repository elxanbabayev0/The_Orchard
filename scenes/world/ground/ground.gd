class_name Ground
extends TileMapLayer
## The farm ground: a grid of 64 px tiles (grass, dirt...).
## (Decision: real ground system with a TileMapLayer; every tile has a
## "surface" type, used e.g. for dust / grass bits at the player's feet.)
##
## Each tile in the TileSet (ground_tileset.tres) has a custom data value
## "surface" (a StringName like &"grass" or &"dirt"). Paint the map in the
## editor: select the Ground node → TileMap panel at the bottom.
##
## Other systems only ask the two questions below, never read tiles directly.

const SURFACE_LAYER := "surface"
## Returned where there is no ground tile at all.
const NO_SURFACE := &""


## Is there a ground tile under this world point?
func has_ground_at(global_point: Vector2) -> bool:
	return get_cell_source_id(_cell_at(global_point)) != -1


## The surface type under this world point (e.g. &"grass", &"dirt"), or NO_SURFACE.
func get_surface_at(global_point: Vector2) -> StringName:
	var tile := get_cell_tile_data(_cell_at(global_point))
	if tile == null:
		return NO_SURFACE
	return tile.get_custom_data(SURFACE_LAYER)


func _cell_at(global_point: Vector2) -> Vector2i:
	return local_to_map(to_local(global_point))
