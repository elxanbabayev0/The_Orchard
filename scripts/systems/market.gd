extends Node
## Market prices and selling. Registered as the autoload "Market".
## (Decision: daily market + supply/demand, single-player.)
##
##   price = base_price × daily factor × sales factor   (at least 1)
##
## - Daily factor: picked at random for each item every new game day.
## - Sales factor: every unit the player sells lowers the price a bit
##   ("saturation"). Saturation slowly goes away as game time passes.
##
## All numbers below are TEMPORARY test values — price balance is not decided.

## Emitted when prices change because of a new day (item = null) or a sale.
signal prices_changed(item: ItemData)

## Daily price can be this much lower or higher than the base price (0.2 = ±20%).
const DAILY_RANGE := 0.2
## Each unit sold lowers the price by this fraction (0.02 = 2%).
const DROP_PER_UNIT := 0.02
## The sales effect can never push the price below this fraction (0.5 = half).
const MIN_SALES_FACTOR := 0.5
## How many units of saturation disappear per game day (prices recover).
const RECOVERY_PER_DAY := 25.0

## Fresh fruit (decision "Day / night rework"): fruit harvested from
## FRESH_PICK_START_HOUR until FRESH_PICK_END_HOUR is fresh, stays fresh until
## FRESH_UNTIL_HOUR the same day and sells FRESH_PRICE_BONUS higher.
## Bruno opens at 08:00, so there is a short morning window to sell it.
## TEMPORARY test values.
const FRESH_PICK_START_HOUR := 5
const FRESH_PICK_END_HOUR := 9
const FRESH_UNTIL_HOUR := 12
const FRESH_PRICE_BONUS := 0.2

## id -> today's random factor
var _daily_factor: Dictionary[StringName, float] = {}
## id -> how many units were sold "recently" (fades over time)
var _saturation: Dictionary[StringName, float] = {}

var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()
	GameClock.day_changed.connect(_on_day_changed)
	GameClock.time_advanced.connect(_on_time_advanced)
	GameClock.minute_changed.connect(_on_minute_changed)


## Price of ONE normal unit right now. 0 = this item cannot be sold.
func get_price(item: ItemData) -> int:
	return _unit_price(item, _get_saturation(item))


## Price of ONE fresh unit right now (FRESH_PRICE_BONUS higher).
func get_fresh_price(item: ItemData) -> int:
	return _unit_price(item, _get_saturation(item), true)


## Is fruit harvested right now fresh? (FruitTree.harvest asks this.)
func is_fresh_picking_time() -> bool:
	var hour := GameClock.get_hour()
	return hour >= FRESH_PICK_START_HOUR and hour < FRESH_PICK_END_HOUR


## Total money for selling `amount` units now. Each unit is a bit cheaper
## than the one before, because every sold unit adds saturation. The fresh
## units in the Inventory are sold first (like Inventory.remove_item) and
## each of them is worth FRESH_PRICE_BONUS more.
func get_sell_total(item: ItemData, amount: int) -> int:
	var total := 0
	var saturation := _get_saturation(item)
	var fresh := Inventory.get_fresh_count(item)
	for i in amount:
		total += _unit_price(item, saturation + i * _saturation_per_unit(item), i < fresh)
	return total


## Sells items from the Inventory to the merchant.
## Returns the money earned, or 0 if the sale was not possible.
func sell(item: ItemData, amount: int) -> int:
	if item == null or amount <= 0 or item.base_price <= 0:
		return 0
	var total := get_sell_total(item, amount)
	# All-or-nothing: if the inventory does not have enough, nothing happens.
	if not Inventory.remove_item(item, amount):
		return 0
	Wallet.add_money(total)
	GameEvents.item_sold.emit(item, amount, total) # XP, Oona's tasks...
	_saturation[item.id] = _get_saturation(item) + amount * _saturation_per_unit(item)
	prices_changed.emit(item)
	return total


## Shop price of ONE unit the player can buy (e.g. a sapling). Fixed for now.
## 0 = this item cannot be bought.
func get_buy_price(item: ItemData) -> int:
	if item == null or item.base_price <= 0:
		return 0
	if item.category == ItemData.Category.SAPLING:
		# Skill: cheaper saplings while that character is active.
		var discount := Characters.get_bonus(SkillData.Effect.SAPLING_PRICE)
		return maxi(1, roundi(item.base_price * (1.0 - discount)))
	return item.base_price


## Buys items from a merchant into the Inventory.
## All-or-nothing: returns false (and nothing changes) if the player cannot pay.
func buy(item: ItemData, amount: int) -> bool:
	var price := get_buy_price(item)
	if amount <= 0 or price <= 0:
		return false
	if not Wallet.spend_money(price * amount):
		return false
	Inventory.add_item(item, amount)
	return true


## Today's random factor for an item (e.g. 1.15 = 15% above the base price).
## Useful for the UI to show if today is a good or bad day to sell.
func get_daily_factor(item: ItemData) -> float:
	if not _daily_factor.has(item.id):
		# Picked the first time it is needed, then kept for the rest of the day.
		_daily_factor[item.id] = _rng.randf_range(1.0 - DAILY_RANGE, 1.0 + DAILY_RANGE)
	return _daily_factor[item.id]


func _unit_price(item: ItemData, saturation: float, fresh: bool = false) -> int:
	if item == null or item.base_price <= 0:
		return 0
	var sales_factor := maxf(MIN_SALES_FACTOR, 1.0 - saturation * DROP_PER_UNIT)
	# Skill: better sell price (all fruit, or one fruit specialty).
	var skill_factor := 1.0 + Characters.get_bonus(SkillData.Effect.SELL_PRICE, item)
	var fresh_factor := 1.0 + FRESH_PRICE_BONUS if fresh else 1.0
	var price := item.base_price * get_daily_factor(item) * sales_factor * skill_factor * fresh_factor
	return maxi(1, roundi(price))


## When freshness ends (FRESH_UNTIL_HOUR), all fresh fruit becomes normal.
## minute_changed also fires after a big jump (sleeping), so it is never missed.
func _on_minute_changed(_day: int, hour: int, _minute: int) -> void:
	if hour >= FRESH_UNTIL_HOUR:
		Inventory.clear_fresh()


## How much one sold unit lowers the price: the item's own factor (e.g. Midnight
## Morello 0.5) × the skill "selling lowers prices slower" (e.g. Elena).
func _saturation_per_unit(item: ItemData) -> float:
	return item.price_drop_factor * maxf(0.0, 1.0 - Characters.get_bonus(SkillData.Effect.PRICE_DROP))


func _get_saturation(item: ItemData) -> float:
	return _saturation.get(item.id, 0.0)


func _on_day_changed(_day: int) -> void:
	# Forget yesterday's factors; new ones are picked when first needed.
	_daily_factor.clear()
	prices_changed.emit(null)


func _on_time_advanced(delta_days: float) -> void:
	# Saturation fades a little with every bit of game time (prices recover).
	for id in _saturation.keys():
		_saturation[id] = maxf(0.0, _saturation[id] - RECOVERY_PER_DAY * delta_days)


# --- Save / load -------------------------------------------------------------
# load_save_data({}) = new-game state (fresh prices, no saturation).

func get_save_data() -> Dictionary:
	return {
		"daily_factor": _to_text_keys(_daily_factor),
		"saturation": _to_text_keys(_saturation),
	}


func load_save_data(data: Dictionary) -> void:
	_daily_factor.clear()
	_saturation.clear()
	var factors: Dictionary = data.get("daily_factor", {})
	for id_text in factors:
		_daily_factor[StringName(id_text)] = float(factors[id_text])
	var saturation: Dictionary = data.get("saturation", {})
	for id_text in saturation:
		_saturation[StringName(id_text)] = float(saturation[id_text])
	prices_changed.emit(null)


## JSON keys must be plain text, so StringName keys are turned into String.
func _to_text_keys(table: Dictionary) -> Dictionary:
	var result := {}
	for key in table:
		result[String(key)] = table[key]
	return result
