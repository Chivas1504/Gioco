class_name CardRules
extends RefCounted

const CLASS_NEUTRAL := "neutral"
const CLASS_WARRIOR := "warrior"
const CLASS_RANGER := "ranger"
const CLASS_MAGE := "mage"
const CLASS_VAMPIRE := "vampire"

const RARITY_COMMON := "common"
const RARITY_UNCOMMON := "uncommon"
const RARITY_RARE := "rare"
const RARITY_LEGENDARY := "legendary"

const TYPE_BUILD := "build"
const TYPE_CONSUMABLE := "consumable"
const TYPE_ARTIFACT := "artifact"

const COLLECTION_MAX := 40
const LOADOUT_MIN := 4
const LOADOUT_MAX := 12
const CONSUMABLE_MAX := 4

const STARTING_HEALTH := 30
const STARTING_STAMINA := 30
const STAT_CAP := 100
const LEVEL_STAT_GAIN := 5

const RARITY_POWER := {
	RARITY_COMMON: 1,
	RARITY_UNCOMMON: 2,
	RARITY_RARE: 4,
	RARITY_LEGENDARY: 8,
}

const OUT_OF_CLASS_STAMINA_PENALTY := {
	RARITY_COMMON: 0,
	RARITY_UNCOMMON: 1,
	RARITY_RARE: 2,
	RARITY_LEGENDARY: 4,
}

static func rarity_power(rarity: String) -> int:
	return RARITY_POWER.get(rarity, 0)


static func out_of_class_penalty(rarity: String) -> int:
	return OUT_OF_CLASS_STAMINA_PENALTY.get(rarity, 0)


static func is_class_card(card: Dictionary) -> bool:
	return card.get("class_id", CLASS_NEUTRAL) != CLASS_NEUTRAL


static func is_off_class(card: Dictionary, active_class: String) -> bool:
	var card_class := card.get("class_id", CLASS_NEUTRAL)
	if card_class == CLASS_NEUTRAL:
		return false
	if active_class == CLASS_NEUTRAL:
		return false
	return card_class != active_class
