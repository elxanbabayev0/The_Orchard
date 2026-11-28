class_name RosaHouse
extends StaticBody2D
## Rosa's house on the farm (decision "Day / night rework": an optional bed in
## the house). For now only the front of the house exists — no interior. The
## player walks up to it and presses interact (E) to open the house menu (Sleep / Kitchen).
##
## Built like every world object: the origin is on the ground at the bottom
## middle of the wall, the collision covers only the base, so the player can
## walk behind the roof. The look (Polygon2D shapes) is a PLACEHOLDER until
## real pixel art exists. `Windows` is kept as its own node so the night-light
## step can light it up.

## Emitted when the player presses E at the house. Connected to HouseMenu.open
## in main.tscn (the menu offers Sleep / Kitchen).
signal menu_requested


## Called by the player when they press the interact key near the house.
func interact(_player: Node) -> void:
	menu_requested.emit()
