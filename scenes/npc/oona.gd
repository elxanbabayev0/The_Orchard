extends StaticBody2D
## Oona on the farm. Visible (and solid, and interactable) only while
## OonaVisits.is_present(). Pressing E near her = OonaVisits.talk().
## Placeholder look until real pixel art exists.

## Emitted after every talk, with the result (OonaVisits.Talk).
## The dialogue window will listen to this (next step).
signal talked(result: int)

@onready var collision: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	OonaVisits.presence_changed.connect(_update_presence)
	_update_presence(OonaVisits.is_present())


func interact(_player: Node2D) -> void:
	var result := OonaVisits.talk()
	if result != OonaVisits.Talk.NOTHING:
		talked.emit(result)


func _update_presence(present: bool) -> void:
	visible = present
	# A hidden Oona must not block the way or answer E (set_deferred: safe
	# even if this happens during a physics callback).
	collision.set_deferred("disabled", not present)
