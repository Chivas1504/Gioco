class_name CardRules
extends RefCounted

const CLASS_NEUTRAL = "neutral"
const CLASS_WARRIOR = "warrior"
const CLASS_ELF = "elf"
const CLASS_SORCERER = "sorcerer"
const CLASS_VAMPIRE = "vampire"
const CLASS_WEREWOLF = "werewolf"
const CLASS_ZOMBIE = "zombie"
const CLASS_GHOST = "ghost"
const CLASS_CLERIC = "cleric"
const CLASS_NECROMANCER = "necromancer"
const CLASS_MONSTER_HUNTER = "monster_hunter"
const CLASS_THIEF = "thief"
const CLASS_DJIN = "djin"

const RARITY_COMMON = "common"
const RARITY_UNCOMMON = "uncommon"
const RARITY_RARE = "rare"
const RARITY_LEGENDARY = "legendary"

const TYPE_BUILD = "build"
const TYPE_CONSUMABLE = "consumable"
const TYPE_ARTIFACT = "artifact"

const COLLECTION_MAX = 40
const LOADOUT_MIN = 4
const LOADOUT_MAX = 12
const CONSUMABLE_MAX = 4

const STARTING_HEALTH = 30
const STARTING_STAMINA = 30
const STAT_CAP = 100
const LEVEL_STAT_GAIN = 5

const FEAR_MAX = 100
const FEAR_LOW_HEALTH_THRESHOLD = 0.3
const FEAR_LOW_HEALTH_GAIN = 10
const FEAR_NO_LEVEL_COMBAT_LIMIT = 3
const FEAR_NO_LEVEL_GAIN = 10
const FEAR_SHADOW_ESCAPE_GAIN = 50
const FEAR_SHADOW_RETURN_THRESHOLD = 90

const START_MAP_X = 0
const START_MAP_Y = 0
const FINAL_BOSS_X = 6
const FINAL_BOSS_Y = 6

const RARITY_POWER = {
	RARITY_COMMON: 1,
	RARITY_UNCOMMON: 2,
	RARITY_RARE: 4,
	RARITY_LEGENDARY: 8,
}

const OUT_OF_CLASS_STAMINA_PENALTY = {
	RARITY_COMMON: 0,
	RARITY_UNCOMMON: 1,
	RARITY_RARE: 2,
	RARITY_LEGENDARY: 4,
}

static func rarity_power(rarity: String) -> int:
	return RARITY_POWER.get(rarity, 0)


static func out_of_class_penalty(rarity: String) -> int:
	return OUT_OF_CLASS_STAMINA_PENALTY.get(rarity, 0)


static func is_monster_class(class_id: String) -> bool:
	return (
		class_id == CLASS_VAMPIRE
		or class_id == CLASS_WEREWOLF
		or class_id == CLASS_ZOMBIE
		or class_id == CLASS_GHOST
	)


static func is_class_match(card_class: String, active_class: String) -> bool:
	if card_class == active_class:
		return true
	if active_class == CLASS_NECROMANCER:
		return card_class == CLASS_ZOMBIE or card_class == CLASS_GHOST or card_class == CLASS_NECROMANCER
	return false


static func is_class_card(card: Dictionary) -> bool:
	return card.get("class_id", CLASS_NEUTRAL) != CLASS_NEUTRAL


static func is_off_class(card: Dictionary, active_class: String) -> bool:
	var card_class = card.get("class_id", CLASS_NEUTRAL)
	if card_class == CLASS_NEUTRAL:
		return false
	if active_class == CLASS_NEUTRAL:
		return false
	return not is_class_match(card_class, active_class)
