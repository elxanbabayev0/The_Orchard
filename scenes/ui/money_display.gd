extends HBoxContainer
## Shows the farm's money: [coin icon] 120
## The icon is a placeholder; the look is not decided.

@onready var amount_label: Label = $Amount


func _ready() -> void:
	Wallet.money_changed.connect(_on_money_changed)
	_update_text()


func _on_money_changed(_new_amount: int, _change: int) -> void:
	_update_text()


func _update_text() -> void:
	amount_label.text = str(Wallet.money)
