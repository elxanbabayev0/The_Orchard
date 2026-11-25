class_name RosaHouse
extends StaticBody2D
## Rosa's house on the farm (decision "Day / night rework": an optional bed in
## the house). For now only the front of the house exists — no interior. The
## player walks up to it and presses interact (E) to go to bed.
##
## Built like every world object: the origin is on the ground at the bottom
## middle of the wall, the collision covers only the base, so the player can
## walk behind the roof. The look (Polygon2D shapes) is a PLACEHOLDER until
## real pixel art exists. `Windows` is kept as its own node so the night-light
## step can light it up.

## Emitted when the player wants to sleep. Connected to SleepPrompt.open in main.tscn.
signal sleep_requested


## Called by the player when they press the interact key near the house.
func interact(_player: Node) -> void:
	sleep_requested.emit()
