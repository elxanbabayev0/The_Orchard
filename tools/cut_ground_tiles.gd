extends SceneTree
## Tool (not part of the game): cuts ground tiles out of an AI pixel-art
## picture (e.g. art/zemin.jfif, a grass field) for the Ground TileSet.
##
## The picture is first sampled on its art-pixel grid (`block` source pixels
## per art pixel, starting at `phase`) — the same idea as cut_character_sheet.gd,
## which removes JPEG noise and the uneven AI pixels. Then 32 × 32 art-pixel
## squares are cut at the given art-pixel positions and saved side by side at
## 2× (1 art pixel = 2 × 2 image pixels, so each tile is 64 × 64 — the game's
## tile size). A preview mosaic (tiles picked like Ground does it) is saved too.
##
## Run from the project folder (PowerShell, $g = path to the Godot exe):
##   & $g --headless --path . --script res://tools/cut_ground_tiles.gd -- <picture> <block> <phase> <out.png> <x,y;x,y;...> [preview.png]
## Example (art/zemin.jfif: 7.15 source px per art pixel):
##   & $g --headless --path . --script res://tools/cut_ground_tiles.gd -- art/zemin.jfif 7.15 1.5 scenes/world/ground/grass_tiles.png "8,22;40,22;72,22"
## Look at the result before using it!

const TILE_ART := 32 # art pixels per tile side
const SCALE := 2 # image pixels per art pixel


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() < 5:
		push_error("Usage: -- <picture> <block> <phase> <out.png> <x,y;x,y;...> [preview.png]")
		quit(1)
		return
	var source := _load(_abs(args[0]))
	if source == null:
		quit(1)
		return
	var art := _sample(source, float(args[1]), float(args[2]))
	print("art image: ", art.get_size())
	var origins: Array[Vector2i] = []
	if args[4].begins_with("auto:"):
		origins = _auto_pick(art, int(args[4].substr(5)))
	else:
		for pair in args[4].split(";", false):
			var xy := pair.split(",")
			origins.append(Vector2i(int(xy[0]), int(xy[1])))
	print("tiles at: ", origins)
	var tile_px := TILE_ART * SCALE
	var atlas := Image.create(tile_px * origins.size(), tile_px, false, Image.FORMAT_RGBA8)
	for i in origins.size():
		var o := origins[i]
		if o.x < 0 or o.y < 0 or o.x + TILE_ART > art.get_width() or o.y + TILE_ART > art.get_height():
			push_error("tile %d at %s is outside the picture" % [i, o])
			quit(1)
			return
		for ay in TILE_ART:
			for ax in TILE_ART:
				atlas.fill_rect(Rect2i((i * TILE_ART + ax) * SCALE, ay * SCALE, SCALE, SCALE), art.get_pixel(o.x + ax, o.y + ay))
	atlas.save_png(_abs(args[3]))
	print("saved ", args[3], " (", origins.size(), " tiles)")
	if args.size() >= 6:
		_save_preview(atlas, origins.size(), _abs(args[5]))
	quit()


## "auto:N": picks N tiles that do not overlap and have as few "object" pixels
## (bushes, tufts — clearly darker than the grass) on their border as
## possible, so no bush is cut in half at a tile edge. Squares that touch the
## white background (e.g. above the grass edge) are skipped.
func _auto_pick(art: Image, count: int) -> Array[Vector2i]:
	var lums: Array[float] = []
	for y in art.get_height():
		for x in art.get_width():
			lums.append(art.get_pixel(x, y).get_luminance())
	lums.sort()
	var dark_limit := lums[lums.size() / 2] * 0.8 # clearly darker than the median grass
	var candidates := []
	for y in art.get_height() - TILE_ART + 1:
		for x in art.get_width() - TILE_ART + 1:
			var score := _border_score(art, x, y, dark_limit)
			if score >= 0:
				candidates.append([score, Vector2i(x, y)])
	candidates.sort_custom(func(a, b): return a[0] < b[0])
	var picked: Array[Vector2i] = []
	for c in candidates:
		var o: Vector2i = c[1]
		var free := true
		for p in picked:
			if absi(p.x - o.x) < TILE_ART and absi(p.y - o.y) < TILE_ART:
				free = false
				break
		if free:
			picked.append(o)
			print("  pick %s border score %d" % [o, c[0]])
			if picked.size() == count:
				break
	return picked


## Dark pixels on a 3-pixel-wide border ring; -1 if the square has background (near white).
func _border_score(art: Image, x0: int, y0: int, dark_limit: float) -> int:
	var score := 0
	for y in TILE_ART:
		for x in TILE_ART:
			var c := art.get_pixel(x0 + x, y0 + y)
			if c.r > 0.85 and c.g > 0.85 and c.b > 0.85:
				return -1
			var on_border := x < 3 or y < 3 or x >= TILE_ART - 3 or y >= TILE_ART - 3
			if on_border and c.get_luminance() < dark_limit:
				score += 1
	return score


## A 10 × 6 tile mosaic, each cell picking a tile the way Ground does.
func _save_preview(atlas: Image, count: int, path: String) -> void:
	var tile_px := TILE_ART * SCALE
	var preview := Image.create(tile_px * 10, tile_px * 6, false, Image.FORMAT_RGBA8)
	for cy in 6:
		for cx in 10:
			var pick := posmod(hash(Vector2i(cx, cy)), count)
			preview.blit_rect(atlas, Rect2i(pick * tile_px, 0, tile_px, tile_px), Vector2i(cx * tile_px, cy * tile_px))
	preview.save_png(path)
	print("preview ", path)


## Samples the middle of every art-pixel block -> 1 image pixel per art pixel.
func _sample(img: Image, block: float, phase: float) -> Image:
	var cols := int((img.get_width() - phase) / block)
	var rows := int((img.get_height() - phase) / block)
	var art := Image.create(cols, rows, false, Image.FORMAT_RGBA8)
	for ay in rows:
		for ax in cols:
			art.set_pixel(ax, ay, img.get_pixel(int(phase + (ax + 0.5) * block), int(phase + (ay + 0.5) * block)))
	return art


func _load(path: String) -> Image:
	var img := Image.new()
	var bytes := FileAccess.get_file_as_bytes(path)
	var err := img.load_png_from_buffer(bytes) if path.get_extension().to_lower() == "png" else img.load_jpg_from_buffer(bytes)
	if err != OK:
		push_error("cannot read " + path)
		return null
	img.convert(Image.FORMAT_RGBA8)
	return img


func _abs(path: String) -> String:
	if path.begins_with("res://") or path.is_absolute_path():
		return ProjectSettings.globalize_path(path) if path.begins_with("res://") else path
	return ProjectSettings.globalize_path("res://") + path
