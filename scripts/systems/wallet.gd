extends Node
## The farm's money. Registered as the autoload "Wallet".
## (Decision: no currency name for now — the UI shows an icon and a number.)
## Money is a whole number (no cents), which keeps the math simple and exact.

## Emitted whenever the money changes. `change` is positive when earning,
## negative when spending.
signal money_changed(new_amount: int, change: int)

## Money at the start of a new game.
## TEMPORARY test value — starting money is a balance number, not decided yet.
const STARTING_MONEY := 0

var money: int = STARTING_MONEY


func add_money(amount: int) -> void:
	if amount <= 0:
		push_warning("Wallet.add_money: amount must be positive.")
		return
	money += amount
	money_changed.emit(money, amount)


## Spends money. Returns false (and spends nothing) if there is not enough.
func spend_money(amount: int) -> bool:
	if amount <= 0:
		push_warning("Wallet.spend_money: amount must be positive.")
		return false
	if not can_afford(amount):
		return false
	money -= amount
	money_changed.emit(money, -amount)
	return true


func can_afford(amount: int) -> bool:
	return money >= amount


# --- Save / load -------------------------------------------------------------
# load_save_data({}) = new-game state.

func get_save_data() -> Dictionary:
	return {"money": money}


func load_save_data(data: Dictionary) -> void:
	money = int(data.get("money", STARTING_MONEY))
	money_changed.emit(money, 0)
