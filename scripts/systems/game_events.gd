extends Node
## Game events that several systems care about. Registered as the autoload "GameEvents".
##
## The system where something happens only EMITS the signal ("a tree was
## harvested"); everyone interested connects to it (Progression for XP, Quests
## for Oona's tasks, later sounds or achievements). So a new listener never
## needs changes in the tree, the market or the planting code.
##
## No state and no logic here — only signals.
## (@warning_ignore: the signals are emitted by OTHER scripts, which Godot's
## "unused signal" check cannot see.)

## A tree was harvested: `amount` pieces of `fruit` went into the Inventory.
@warning_ignore("unused_signal")
signal fruit_harvested(fruit: ItemData, amount: int)
## The player sold `amount` × `item` to a merchant for `money`.
@warning_ignore("unused_signal")
signal item_sold(item: ItemData, amount: int, money: int)
## The player planted one `sapling` item; `tree` is the new FruitTree node.
## (Typed as Node2D: autoloads compile before scene classes in some situations.)
@warning_ignore("unused_signal")
signal sapling_planted(sapling: ItemData, tree: Node2D)
