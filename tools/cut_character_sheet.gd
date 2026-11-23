extends SceneTree
## Tool (not part of the game): turns an AI-generated 4-view character sheet
## (4 figures side by side on a white background, JPEG/PNG) into 4 clean
## pixel-art PNGs with transparency, 1 art pixel = 2x2 image pixels
## (the game's pixel scale, see CLAUDE.md "Visual style").
##
## How it works: the white background is flood-filled from the image borders
## (so white INSIDE the figure, like eyes, stays); the 4 figures are found by
## empty columns between them; each figure is sampled on an art-pixel grid
## (the most common colour of each block, which also removes JPEG noise).
##
## Run from the project folder (PowerShell, $g = path to the Godot exe):
##   & $g --headless --path . --script res://tools/cut_character_sheet.gd -- <sheet file> <name prefix> [views]
## Example:
##   & $g --headless --path . --script res://tools/cut_character_sheet.gd -- art/sheet.jfif test_boy front,right,left,back
## Output: scenes/characters/sprites/<prefix>_<view>.png. Look at the result before using it!

const ART_HEIGHT := 55.0 # target figure height in art pixels (about 110 px on screen)
const WHITE_LIMIT := 225 # background = all channels above this (0..255)
const OUT_DIR := "res://scenes/characters/sprites/"

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() < 2:
		push_error("Usage: -- <sheet file> <name prefix> [views, default front,right,left,back]")
		quit(1)
		return
	var path := args[0]
	if not path.is_absolute_path():
		path = ProjectSettings.globalize_path("res://") + path
	var views := ["front", "right", "left", "back"]
	if args.size() >= 3:
		views = Array(args[2].split(","))
	DirAccess.make_dir_recursive_absolute(OUT_DIR)
	_process_sheet(path, args[1], views)
	quit()

func _is_bg(c: Color) -> bool:
	return c.r8 > WHITE_LIMIT and c.g8 > WHITE_LIMIT and c.b8 > WHITE_LIMIT

func _process_sheet(path: String, prefix: String, views: Array) -> void:
	var img := Image.new()
	var bytes := FileAccess.get_file_as_bytes(path)
	# .jfif is JPEG; anything else is tried as PNG.
	var err := img.load_png_from_buffer(bytes) if path.get_extension().to_lower() == "png" else img.load_jpg_from_buffer(bytes)
	if err != OK:
		push_error("cannot read " + path)
		return
	img.convert(Image.FORMAT_RGBA8)
	var w := img.get_width()
	var h := img.get_height()
	print(prefix, ": ", w, "x", h)

	# 1) Flood fill the background from the borders -> transparent.
	var bg := PackedByteArray()
	bg.resize(w * h)
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
		if bg[i] == 1 or not _is_bg(img.get_pixelv(p)):
			continue
		bg[i] = 1
		stack.append(p + Vector2i(1, 0)); stack.append(p + Vector2i(-1, 0))
		stack.append(p + Vector2i(0, 1)); stack.append(p + Vector2i(0, -1))

	# 2) Columns that contain figure pixels -> 4 figures.
	var col_has := []
	for x in w:
		var has := false
		for y in h:
			if bg[y * w + x] == 0:
				has = true
				break
		col_has.append(has)
	var figures: Array[Rect2i] = []
	var start := -1
	for x in w + 1:
		var has: bool = x < w and col_has[x]
		if has and start < 0:
			start = x
		elif not has and start >= 0:
			if x - start > 40: # ignore specks
				figures.append(_bbox(bg, w, h, start, x))
			start = -1
	print("  figures: ", figures)
	if figures.size() != views.size():
		push_error("expected %d figures" % views.size())
		return

	# 3) One block size for the whole sheet, from the tallest figure.
	var tallest := 0
	for r in figures:
		tallest = maxi(tallest, r.size.y)
	var block := tallest / ART_HEIGHT
	print("  block size (source px per art pixel): ", block)

	for k in figures.size():
		var r: Rect2i = figures[k]
		var aw := ceili(r.size.x / block)
		var ah := ceili(r.size.y / block)
		var out := Image.create(aw * 2, ah * 2, false, Image.FORMAT_RGBA8)
		for ay in ah:
			for ax in aw:
				var c := _block_color(img, bg, w, h, r.position.x + ax * block, r.position.y + ay * block, block)
				for dy in 2:
					for dx in 2:
						out.set_pixel(ax * 2 + dx, ay * 2 + dy, c)
		var file := OUT_DIR + "%s_%s.png" % [prefix, views[k]]
		out.save_png(file)
		print("  ", file, " ", out.get_size())

func _bbox(bg: PackedByteArray, w: int, h: int, x0: int, x1: int) -> Rect2i:
	var top := h
	var bottom := 0
	for x in range(x0, x1):
		for y in h:
			if bg[y * w + x] == 0:
				top = mini(top, y)
				bottom = maxi(bottom, y)
	return Rect2i(x0, top, x1 - x0, bottom - top + 1)

## Most common (quantised) colour in the middle of a block; transparent if the block is mostly background.
func _block_color(img: Image, bg: PackedByteArray, w: int, h: int, fx: float, fy: float, block: float) -> Color:
	var counts := {}
	var sums := {}
	var total := 0
	var bg_count := 0
	var inset := block * 0.25
	var x0 := int(fx + inset)
	var x1 := int(fx + block - inset)
	var y0 := int(fy + inset)
	var y1 := int(fy + block - inset)
	for y in range(y0, maxi(y0 + 1, y1)):
		for x in range(x0, maxi(x0 + 1, x1)):
			if x < 0 or y < 0 or x >= w or y >= h:
				continue
			total += 1
			if bg[y * w + x] == 1:
				bg_count += 1
				continue
			var c := img.get_pixel(x, y)
			var key := Vector3i(c.r8 / 24, c.g8 / 24, c.b8 / 24)
			counts[key] = counts.get(key, 0) + 1
			sums[key] = sums.get(key, Vector3.ZERO) + Vector3(c.r, c.g, c.b)
	if total == 0 or bg_count * 2 >= total:
		return Color(0, 0, 0, 0)
	var best = null
	for key in counts:
		if best == null or counts[key] > counts[best]:
			best = key
	var avg: Vector3 = sums[best] / counts[best]
	return Color(avg.x, avg.y, avg.z, 1.0)
