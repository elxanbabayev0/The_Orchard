class_name SkillData
extends Resource
## One character skill: a passive bonus that works while its character is active.
## (Decision: passive bonuses + fruit specialties, themed per family branch.)
## Stored inside each character's .tres file (CharacterData.skill).
## Systems ask Characters.get_bonus(effect, item) — they never read skills directly.

## What the skill changes. Add new values only at the END (.tres files store the number).
enum Effect {
	SELL_PRICE,    ## value 0.10 = fruit sells for 10% more
	SAPLING_PRICE, ## value 0.15 = saplings cost 15% less
	PRICE_DROP,    ## value 0.5 = selling lowers prices 50% slower
	HARVEST_BONUS, ## value 1 = +1 fruit on every harvest
	GROWTH_SPEED,  ## value 0.2 = trees grow 20% faster
	WALK_SPEED,    ## value 0.25 = walk 25% faster
	PLANT_RANGE,   ## value 2 = plant up to 2 tiles farther
	XP,            ## value 0.25 = 25% more XP
}

@export var effect: Effect = Effect.SELL_PRICE
## How strong (meaning depends on `effect`, see above). TEMPORARY test values.
@export var value: float = 0.0
## Fruit specialty: only this fruit (null = every fruit / not fruit-related).
@export var fruit: ItemData


## Does this skill apply to `item`? (null item = a general question, e.g. walking.)
func applies_to(item: ItemData) -> bool:
	return fruit == null or fruit == item


## Player-facing text built from the numbers, e.g. "+2 Sour Cherry on every harvest".
func get_description() -> String:
	var percent := roundi(value * 100.0)
	var fruit_name := tr(fruit.display_name) if fruit != null else ""
	match effect:
		Effect.SELL_PRICE:
			if fruit != null:
				return tr("SKILL_SELL_PRICE_FRUIT") % [fruit_name, percent]
			return tr("SKILL_SELL_PRICE_ALL") % percent
		Effect.SAPLING_PRICE:
			return tr("SKILL_SAPLING_PRICE") % percent
		Effect.PRICE_DROP:
			return tr("SKILL_PRICE_DROP") % percent
		Effect.HARVEST_BONUS:
			if fruit != null:
				return tr("SKILL_HARVEST_BONUS_FRUIT") % [roundi(value), fruit_name]
			return tr("SKILL_HARVEST_BONUS_ALL") % roundi(value)
		Effect.GROWTH_SPEED:
			return tr("SKILL_GROWTH_SPEED") % percent
		Effect.WALK_SPEED:
			return tr("SKILL_WALK_SPEED") % percent
		Effect.PLANT_RANGE:
			return tr("SKILL_PLANT_RANGE") % roundi(value)
		Effect.XP:
			return tr("SKILL_XP") % percent
	return ""
