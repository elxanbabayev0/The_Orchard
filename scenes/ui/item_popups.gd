extends VBoxContainer
## Short messages at the bottom of the screen that fade out after a moment:
## - "[icon] +3 Sweet Cherry" every time items are added to the Inventory,
## - "Level up! Level 2" when the player gains a level.
## Texts come from translation keys (localization/translations.csv); the look is a placeholder.

## How long a message stays fully visible (seconds).
const SHOW_TIME := 1.5
## How long the fade-out takes (seconds).
const FADE_TIME := 0.5
const ICON_SIZE := Vector2(40, 40)
const FONT_SIZE := 28
const LEVEL_UP_COLOR := Color(1.0, 0.88, 0.35)


func _ready() -> void:
	Inventory.item_added.connect(_on_item_added)
	Progression.level_up.connect(_on_level_up)


func _on_item_added(item: ItemData, amount: int) -> void:
	show_message(tr("UI_ITEM_GAINED") % [amount, tr(item.display_name)], item.icon)


func _on_level_up(new_level: int) -> void:
	show_message(tr("UI_LEVEL_UP") % new_level, null, LEVEL_UP_COLOR)


## Shows one message: optional icon + text. It stays, fades out, then is deleted.
func show_message(text: String, icon_texture: Texture2D = null, color: Color = Color.WHITE) -> void:
	var popup := HBoxContainer.new()
	popup.alignment = BoxContainer.ALIGNMENT_CENTER
	popup.mouse_filter = Control.MOUSE_FILTER_IGNORE
	popup.add_theme_constant_override("separation", 10)

	if icon_texture != null:
		var icon := TextureRect.new()
		icon.texture = icon_texture
		icon.custom_minimum_size = ICON_SIZE
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		popup.add_child(icon)

	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", FONT_SIZE)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 8)
	popup.add_child(label)

	add_child(popup)
	# A Tween changes a property smoothly over time:
	# wait SHOW_TIME, fade transparency to 0 over FADE_TIME, then delete the popup.
	var tween := popup.create_tween()
	tween.tween_interval(SHOW_TIME)
	tween.tween_property(popup, "modulate:a", 0.0, FADE_TIME)
	tween.tween_callback(popup.queue_free)
