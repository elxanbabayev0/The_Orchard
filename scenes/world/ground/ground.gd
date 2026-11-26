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

## Other nodes find the ground through this group (e.g. FootstepEffects in the
## player scene, which cannot point to main.tscn with a NodePath).
const GROUP := &"ground"
const SURFACE_LAYER := "surface"
## Returned where there is no ground tile at all.
const NO_SURFACE := &""


## Surface whose tiles get mixed variants (see _vary_tiles).
const VARIED_SURFACE := &"grass"


func _ready() -> void:
	add_to_group(GROUP)
	_vary_tiles()


## Grass has several tiles in the TileSet (all with surface "grass", cut from
## art/zemin.jfif). The map is painted with ONE grass tile in the editor; when
## the game starts every grass cell gets one of the variants, chosen by the
## cell's position (always the same for a cell, so nothing needs saving) and
## weighted by each tile's `probability` in the TileSet (plain grass is more
## common than grass with flowers or bushes). Only the picture changes: the
## surface stays "grass", so footsteps, planting etc. work as before.
func _vary_tiles() -> void:
	var variants: Array[Vector2i] = []
	var weights: Array[float] = []
	var source_id := -1
	for s in tile_set.get_source_count():
		var source := tile_set.get_source(tile_set.get_source_id(s)) as TileSetAtlasSource
		if source == null:
			continue
		for t in source.get_tiles_count():
			var coords := source.get_tile_id(t)
			var data := source.get_tile_data(coords, 0)
			if data.get_custom_data(SURFACE_LAYER) == VARIED_SURFACE:
				source_id = tile_set.get_source_id(s)
				variants.append(coords)
				weights.append(maxf(0.0, data.probability))
	if variants.size() < 2:
		return
	var total := 0.0
	for w in weights:
		total += w
	for cell in get_used_cells():
		if get_cell_source_id(cell) != source_id:
			continue
		var tile := get_cell_tile_data(cell)
		if tile == null or tile.get_custom_data(SURFACE_LAYER) != VARIED_SURFACE:
			continue
		# A stable "random" number 0..1 for this cell.
		var roll := float(posmod(hash(cell), 10000)) / 10000.0 * total
		for i in variants.size():
			roll -= weights[i]
			if roll < 0.0:
				set_cell(cell, source_id, variants[i])
				break


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
