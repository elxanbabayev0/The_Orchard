class_name PlacedProp
extends StaticBody2D
## Root script of every object the player places from the inventory (e.g. the
## path lantern). The world object remembers which item it came from, so the
## SaveManager can save it as {item, x, y} and rebuild it from that item's
## `places` scene when loading. All placed props live in Entities/Props.
##
## Built like every world object: origin on the ground, collision only at the base.

## The item this prop was placed from. Set BEFORE add_child (by PlacementMode
## or SaveManager).
var item: ItemData


func get_save_data() -> Dictionary:
	return {
		"item": String(item.id) if item != null else "",
		"x": global_position.x,
		"y": global_position.y,
	}
