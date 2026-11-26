extends SceneTree
## Tool (not part of the game): makes the tree sprites for every growth stage
## from ONE AI picture of ripe fruit trees (decision "Tree art": 9 ripe trees
## on a plain white background, 3 × 3 grid).
##
## Two steps (Godot must import the new PNGs between them):
##
## 1) cut — finds the trees, samples them on the art-pixel grid and DERIVES the
##    other stages from the ripe tree:
##      RIPE      = the tree as drawn
##      UNRIPE    = fruit pixels recoloured light green
##      FLOWERING = fruit pixels turned into white / pale pink blossoms
##      YOUNG     = fruit pixels filled with the nearby leaf colour, 75 % size
##      SAPLING   = the young tree at 45 % size (placeholder until sapling art exists)
##    Output: scenes/trees/sprites/<tree id>_<stage>.png (1 art pixel = 2 × 2 image pixels)
##    and scenes/trees/sprites/_preview.png (all trees, all stages, for checking).
##
##      & $g --headless --path . --script res://tools/make_tree_sprites.gd -- cut <picture> <id,id,...> [tree height in art px]
##    The ids are TreeData ids in reading order (row by row, left to right), e.g.
##      gilas,alca,visne,albali,tut,golden_gilas,snow_tut,midnight_albali,frost_visne
##
## 2) import, then apply — puts the PNGs into each TreeData file's stage textures:
##      & $g --headless --path . --import
##      & $g --headless --path . --script res://tools/make_tree_sprites.gd -- apply <id,id,...>
##
## Look at _preview.png and in the game before committing!

const OUT_DIR := "res://scenes/trees/sprites/"
const TYPES_DIR := "res://scenes/trees/types/"
const STAGES := ["sapling", "young", "flowering", "unripe", "ripe"]
## Default tree height in art pixels (≈ 3 tiles tall on screen: 88 × 2 = 176 px).
## TEMPORARY — exact sprite sizes are not decided.
const DEFAULT_ART_HEIGHT := 88
## Background = pixels close to the corner colour (white), found by flood fill from the borders.
const BG_TOLERANCE := 0.12
## Pieces smaller than this share of the biggest piece are ignored (specks, leaves flying off).
const MIN_PIECE_SHARE := 0.15
const YOUNG_SCALE := 0.75
const SAPLING_SCALE := 0.45


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() >= 3 and args[0] == "cut":
		_cut(_abs(args[1]), args[2].split(",", false), int(args[3]) if args.size() >= 4 else DEFAULT_ART_HEIGHT)
	elif args.size() >= 2 and args[0] == "apply":
		_apply(args[1].split(",", false))
	else:
		push_error("Usage: -- cut <picture> <id,id,...> [height]  |  -- apply <id,id,...>")
	quit()


# --- cut -----------------------------------------------------------------------

func _cut(path: String, ids: PackedStringArray, art_height: int) -> void:
	var img := _load(path)
	if img == null:
		return
	var w := img.get_width()
	var h := img.get_height()
	var bg := _background_mask(img)
	var pieces := _find_pieces(bg, w, h)
	if pieces.size() < ids.size():
		push_error("found %d trees, expected %d" % [pieces.size(), ids.size()])
		return
	pieces = pieces.slice(0, ids.size()) # the biggest ones
	pieces = _reading_order(pieces)
	var tallest := 0
	for r: Rect2i in pieces:
		tallest = maxi(tallest, r.size.y)
	var block := float(tallest) / art_height # one scale for all trees
	print("trees: %d, source px per art pixel: %.2f" % [pieces.size(), block])
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	var rows: Array = []
	for i in ids.size():
		var ripe := _sample(img, bg, w, pieces[i], block)
		var stages := _derive_stages(ripe)
		for stage in STAGES:
			_save_2x(stages[stage], OUT_DIR + "%s_%s.png" % [ids[i], stage])
		rows.append(stages)
		print("  %s: %s art px" % [ids[i], ripe.get_size()])
	_save_preview(rows)


## Flood fill from the borders over pixels close to the corner colour.
func _background_mask(img: Image) -> PackedByteArray:
	var w := img.get_width()
	var h := img.get_height()
	var bg_color := img.get_pixel(0, 0)
	var mask := PackedByteArray()
	mask.resize(w * h)
	var stack: Array[Vector2i] = []
	for x in w:
		stack.append(Vector2i(x, 0)); stack.append(Vector2i(x, h - 1))
	for y in h:
		stack.append(Vector2i(0, y)); stack.append(Vector2i(w - 1, y))
	while not stack.is_empty():
		var p: Vector2i = stack.pop_back()
		if p.x < 0 or p.y < 0 or p.x >= w or p.y >= h:
			continue
		var i := p.y * w + p.x
		if mask[i] == 1 or not _close(img.get_pixelv(p), bg_color):
			continue
		mask[i] = 1
		stack.append(p + Vector2i(1, 0)); stack.append(p + Vector2i(-1, 0))
		stack.append(p + Vector2i(0, 1)); stack.append(p + Vector2i(0, -1))
	return mask


func _close(a: Color, b: Color) -> bool:
	return absf(a.r - b.r) + absf(a.g - b.g) + absf(a.b - b.b) < BG_TOLERANCE * 3.0


## Connected non-background pieces (8 neighbours), biggest first, small specks dropped.
func _find_pieces(bg: PackedByteArray, w: int, h: int) -> Array:
	var seen := PackedByteArray()
	seen.resize(w * h)
	var found := [] # [area, Rect2i]
	for y in h:
		for x in w:
			var i := y * w + x
			if bg[i] == 1 or seen[i] == 1:
				continue
			var area := 0
			var lo := Vector2i(x, y)
			var hi := Vector2i(x, y)
			var stack: Array[Vector2i] = [Vector2i(x, y)]
			seen[i] = 1
			while not stack.is_empty():
				var p: Vector2i = stack.pop_back()
				area += 1
				lo = Vector2i(mini(lo.x, p.x), mini(lo.y, p.y))
				hi = Vector2i(maxi(hi.x, p.x), maxi(hi.y, p.y))
				for dy in range(-1, 2):
					for dx in range(-1, 2):
						var q := p + Vector2i(dx, dy)
						if q.x < 0 or q.y < 0 or q.x >= w or q.y >= h:
							continue
						var j := q.y * w + q.x
						if bg[j] == 0 and seen[j] == 0:
							seen[j] = 1
							stack.append(q)
			found.append([area, Rect2i(lo, hi - lo + Vector2i.ONE)])
	found.sort_custom(func(a, b): return a[0] > b[0])
	var result := []
	for f in found:
		if f[0] >= found[0][0] * MIN_PIECE_SHARE:
			result.append(f[1])
	return result


## Row by row (by the middle height), left to right inside a row.
func _reading_order(pieces: Array) -> Array:
	pieces.sort_custom(func(a: Rect2i, b: Rect2i): return a.get_center().y < b.get_center().y)
	var rows := []
	for r: Rect2i in pieces:
		if rows.is_empty() or r.get_center().y - rows.back()[0].get_center().y > r.size.y * 0.5:
			rows.append([r])
		else:
			rows.back().append(r)
	var ordered := []
	for row in rows:
		row.sort_custom(func(a: Rect2i, b: Rect2i): return a.position.x < b.position.x)
		ordered.append_array(row)
	return ordered


## One image pixel per art pixel: the most common colour of each block
## (removes JPEG noise); a block that is mostly background becomes transparent.
func _sample(img: Image, bg: PackedByteArray, w: int, r: Rect2i, block: float) -> Image:
	var aw := ceili(r.size.x / block)
	var ah := ceili(r.size.y / block)
	var art := Image.create(aw, ah, false, Image.FORMAT_RGBA8)
	for ay in ah:
		for ax in aw:
			var buckets := {}
			var count := 0
			var total := 0
			for sy in range(int(r.position.y + ay * block), mini(int(r.position.y + (ay + 1) * block), r.end.y)):
				for sx in range(int(r.position.x + ax * block), mini(int(r.position.x + (ax + 1) * block), r.end.x)):
					total += 1
					if bg[sy * w + sx] == 1:
						continue
					count += 1
					var c := img.get_pixel(sx, sy)
					var key := (c.r8 >> 4) << 8 | (c.g8 >> 4) << 4 | (c.b8 >> 4)
					if not buckets.has(key):
						buckets[key] = [0, Color(0, 0, 0, 0)]
					buckets[key][0] += 1
					buckets[key][1] += c
			if total == 0 or count * 2 < total:
				continue # mostly background → transparent
			var best = null
			for key in buckets:
				if best == null or buckets[key][0] > best[0]:
					best = buckets[key]
			var c: Color = best[1] / float(best[0])
			c.a = 1.0
			art.set_pixel(ax, ay, c)
	var used := art.get_used_rect()
	return art.get_region(used)


# --- stages --------------------------------------------------------------------

func _is_leaf(c: Color) -> bool:
	return c.h >= 0.16 and c.h <= 0.5 and c.s >= 0.18 and c.v >= 0.12


## Brown trunk / branches, also their light highlights and their dark
## olive shadows. Bright, strongly coloured orange (e.g. Golden Sweet Cherry
## fruit) is NOT wood: s > 0.75 or v > 0.72.
func _is_wood(c: Color) -> bool:
	if c.h >= 0.03 and c.h <= 0.12 and c.s >= 0.2 and c.s <= 0.75 and c.v <= 0.72:
		return true
	return c.h > 0.12 and c.h < 0.17 and c.v <= 0.35 # dark olive shadow


func _is_outline(c: Color) -> bool:
	return c.v < 0.15 and c.s < 0.35


## Fruit = coloured pixels in the crown that are not leaves, wood or outline.
func _fruit_mask(art: Image) -> PackedByteArray:
	var w := art.get_width()
	var h := art.get_height()
	var leaf_rows := PackedInt32Array()
	leaf_rows.resize(h)
	var most := 0
	for y in h:
		for x in w:
			var c := art.get_pixel(x, y)
			if c.a > 0.5 and _is_leaf(c):
				leaf_rows[y] += 1
		most = maxi(most, leaf_rows[y])
	# The crown = every row down to the last row that is still clearly crown;
	# below it is the trunk (no fruit there). The thin top of the crown counts too.
	var last_crown_row := 0
	for y in h:
		if leaf_rows[y] >= most * 0.3:
			last_crown_row = y
	var mask := PackedByteArray()
	mask.resize(w * h)
	for y in h:
		if y > last_crown_row:
			continue # trunk rows: no fruit there
		for x in w:
			var c := art.get_pixel(x, y)
			if c.a > 0.5 and not _is_leaf(c) and not _is_wood(c) and not _is_outline(c):
				mask[y * w + x] = 1
	# Grow every fruit by its dark rim: the shaded / outline pixels of a fruit
	# look like wood or outline on their own, but touch the fruit (1 pass, so
	# real branches and the crown outline further away are not taken).
	var grown := mask.duplicate()
	for y in h:
		if y > last_crown_row:
			continue
		for x in w:
			var i := y * w + x
			if mask[i] == 1:
				continue
			var c := art.get_pixel(x, y)
			if c.a <= 0.5 or _is_leaf(c) or _is_wood(c):
				continue # never grow into leaves or the trunk
			for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var q := Vector2i(x, y) + d
				if q.x >= 0 and q.y >= 0 and q.x < w and q.y < h and mask[q.y * w + q.x] == 1:
					grown[i] = 1
					break
	return grown


func _derive_stages(ripe: Image) -> Dictionary:
	var w := ripe.get_width()
	var h := ripe.get_height()
	var fruit := _fruit_mask(ripe)
	var unripe := ripe.duplicate() as Image
	var flowering := ripe.duplicate() as Image
	var young := ripe.duplicate() as Image
	for y in h:
		for x in w:
			if fruit[y * w + x] == 0:
				continue
			var l := ripe.get_pixel(x, y).get_luminance()
			unripe.set_pixel(x, y, Color(0.32, 0.5, 0.16).lerp(Color(0.72, 0.86, 0.36), clampf(l * 1.4, 0.0, 1.0)))
			flowering.set_pixel(x, y, Color(0.86, 0.68, 0.74).lerp(Color(1.0, 0.98, 0.96), clampf(l * 1.6, 0.0, 1.0)))
			young.set_pixel(x, y, _nearest_leaf(ripe, fruit, x, y))
	var small := young.duplicate() as Image
	small.resize(maxi(1, roundi(w * YOUNG_SCALE)), maxi(1, roundi(h * YOUNG_SCALE)), Image.INTERPOLATE_NEAREST)
	var sapling := young.duplicate() as Image
	sapling.resize(maxi(1, roundi(w * SAPLING_SCALE)), maxi(1, roundi(h * SAPLING_SCALE)), Image.INTERPOLATE_NEAREST)
	return {"ripe": ripe, "unripe": unripe, "flowering": flowering, "young": small, "sapling": sapling}


## The closest leaf pixel's colour (so a removed fruit looks like crown).
func _nearest_leaf(art: Image, fruit: PackedByteArray, x0: int, y0: int) -> Color:
	var w := art.get_width()
	for radius in range(1, 8):
		for dy in range(-radius, radius + 1):
			for dx in range(-radius, radius + 1):
				var x := x0 + dx
				var y := y0 + dy
				if x < 0 or y < 0 or x >= w or y >= art.get_height() or fruit[y * w + x] == 1:
					continue
				var c := art.get_pixel(x, y)
				if c.a > 0.5 and _is_leaf(c):
					return c
	return Color(0.25, 0.5, 0.2)


func _save_2x(art: Image, path: String) -> void:
	var big := art.duplicate() as Image
	big.resize(art.get_width() * 2, art.get_height() * 2, Image.INTERPOLATE_NEAREST)
	big.save_png(ProjectSettings.globalize_path(path))


## All trees (rows) × all stages (columns), bottom-aligned, on grass green.
func _save_preview(rows: Array) -> void:
	var cell := Vector2i.ZERO
	for stages in rows:
		for stage in STAGES:
			cell = cell.max(stages[stage].get_size() * 2)
	cell += Vector2i(8, 8)
	var preview := Image.create(cell.x * STAGES.size(), cell.y * rows.size(), false, Image.FORMAT_RGBA8)
	preview.fill(Color(0.36, 0.62, 0.22))
	for r in rows.size():
		for s in STAGES.size():
			var img: Image = rows[r][STAGES[s]].duplicate()
			img.resize(img.get_width() * 2, img.get_height() * 2, Image.INTERPOLATE_NEAREST)
			var pos := Vector2i(s * cell.x + (cell.x - img.get_width()) / 2, r * cell.y + cell.y - 4 - img.get_height())
			preview.blend_rect(img, Rect2i(Vector2i.ZERO, img.get_size()), pos)
	preview.save_png(ProjectSettings.globalize_path(OUT_DIR + "_preview.png"))
	print("preview: ", OUT_DIR + "_preview.png")


# --- apply ---------------------------------------------------------------------

func _apply(ids: PackedStringArray) -> void:
	var by_id := {}
	for file in ResourceLoader.list_directory(TYPES_DIR):
		if file.ends_with(".tres"):
			var data = load(TYPES_DIR + file)
			if data != null and data.get("id") != null:
				by_id[String(data.id)] = [data, TYPES_DIR + file]
	for id in ids:
		if not by_id.has(id):
			push_error("no TreeData with id " + id)
			continue
		var data: Resource = by_id[id][0]
		for stage in STAGES:
			var texture := load(OUT_DIR + "%s_%s.png" % [id, stage]) as Texture2D
			if texture == null:
				push_error("missing %s_%s.png — run cut and --import first" % [id, stage])
				return
			data.set("%s_texture" % stage, texture)
		var err := ResourceSaver.save(data, by_id[id][1])
		print("  %s → %s (%s)" % [id, by_id[id][1], "ok" if err == OK else "error %d" % err])


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
	if path.begins_with("res://"):
		return ProjectSettings.globalize_path(path)
	if path.is_absolute_path():
		return path
	return ProjectSettings.globalize_path("res://") + path
