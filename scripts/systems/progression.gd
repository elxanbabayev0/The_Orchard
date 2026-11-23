extends Node
## XP and levels. Registered as the autoload "Progression".
## (Decision: XP is collected and never spent; every new level gives one
## "invitation" — the player chooses which family member to invite.)
##
## All XP rules live here. Other systems only report what happened through
## GameEvents signals (fruit_harvested, item_sold, sapling_planted), which are
## connected to on_harvest / on_sale / on_planted below. All numbers are TEMPORARY test values —
## XP amounts and level thresholds are not decided.

## Emitted whenever XP changes.
signal xp_changed(xp: int, level: int)
## Emitted once for every level gained.
signal level_up(new_level: int)
## Emitted when the number of unused invitations changes.
signal invitations_changed(count: int)

const XP_PER_HARVESTED_FRUIT := 1
## One XP for every this much money earned by selling.
const MONEY_PER_XP := 10
const XP_PER_PLANTED_SAPLING := 5
## XP needed to go from level L to L+1 = XP_PER_LEVEL_STEP × L (50, 100, 150...).
const XP_PER_LEVEL_STEP := 50

## Total XP ever earned.
var xp: int = 0
## Level gained so far (starts at 1).
var level: int = 1
## Invitations earned by levelling up but not used yet.
var invitations: int = 0
## Sale money that has not been turned into XP yet (less than MONEY_PER_XP).
## Kept so many small sales add up instead of each rounding down to 0 XP.
var _sale_money_carry: int = 0
## Fraction of an XP point left over from the XP skill (e.g. +25% of 1 XP = 0.25).
## Kept so small bonuses add up instead of rounding down to 0.
var _bonus_xp_carry: float = 0.0


func _ready() -> void:
	GameEvents.fruit_harvested.connect(func(_fruit: ItemData, amount: int) -> void: on_harvest(amount))
	GameEvents.item_sold.connect(func(_item: ItemData, _amount: int, money: int) -> void: on_sale(money))
	GameEvents.sapling_planted.connect(func(_sapling: ItemData, _tree: Node2D) -> void: on_planted())


# --- What gives XP -----------------------------------------------------------

func on_harvest(fruit_count: int) -> void:
	add_xp(fruit_count * XP_PER_HARVESTED_FRUIT)


func on_sale(money_earned: int) -> void:
	_sale_money_carry += money_earned
	var gained := floori(float(_sale_money_carry) / MONEY_PER_XP)
	_sale_money_carry -= gained * MONEY_PER_XP
	add_xp(gained)


func on_planted() -> void:
	add_xp(XP_PER_PLANTED_SAPLING)


## Later also used by the old woman's tasks.
func add_xp(amount: int) -> void:
	if amount <= 0:
		return
	# Skill: more XP while that character is active.
	var bonus := amount * Characters.get_bonus(SkillData.Effect.XP) + _bonus_xp_carry
	var bonus_whole := floori(bonus)
	_bonus_xp_carry = bonus - bonus_whole
	xp += amount + bonus_whole
	# "while": a big reward can pass several levels at once.
	while xp >= get_level_start_xp(level + 1):
		level += 1
		invitations += 1
		level_up.emit(level)
		invitations_changed.emit(invitations)
	xp_changed.emit(xp, level)


# --- Level math --------------------------------------------------------------

## Total XP needed to REACH a level (level 1 = 0, level 2 = 50, level 3 = 150...).
func get_level_start_xp(for_level: int) -> int:
	var total := 0
	for l in range(1, for_level):
		total += XP_PER_LEVEL_STEP * l
	return total


## How far through the current level we are: 0.0 .. 1.0 (for the XP bar).
func get_level_progress() -> float:
	var start := get_level_start_xp(level)
	var end := get_level_start_xp(level + 1)
	return float(xp - start) / float(end - start)


## Uses one invitation (step 3: inviting a family member). False if none are left.
func use_invitation() -> bool:
	if invitations <= 0:
		return false
	invitations -= 1
	invitations_changed.emit(invitations)
	return true


# --- Save / load -------------------------------------------------------------
# load_save_data({}) = new-game state. The level is not saved: it is
# recalculated from XP, so the two can never disagree.

func get_save_data() -> Dictionary:
	return {
		"xp": xp,
		"invitations": invitations,
		"sale_money_carry": _sale_money_carry,
		"bonus_xp_carry": _bonus_xp_carry,
	}


func load_save_data(data: Dictionary) -> void:
	xp = maxi(0, int(data.get("xp", 0)))
	invitations = maxi(0, int(data.get("invitations", 0)))
	_sale_money_carry = clampi(int(data.get("sale_money_carry", 0)), 0, MONEY_PER_XP - 1)
	_bonus_xp_carry = clampf(float(data.get("bonus_xp_carry", 0.0)), 0.0, 0.999)
	level = 1
	while xp >= get_level_start_xp(level + 1):
		level += 1
	# Refresh the UI only: no level_up pop-ups when loading.
	xp_changed.emit(xp, level)
	invitations_changed.emit(invitations)
