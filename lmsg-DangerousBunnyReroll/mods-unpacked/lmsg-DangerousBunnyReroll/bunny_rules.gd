extends Reference

const BUNNY_ID = "item_dangerous_bunny"
const COST_THRESHOLD = 20
const MAX_ADDITIONAL_CHANCE = 0.5

static func additional_chance(paid_cost: int, item_price: int) -> float:
	if paid_cost <= COST_THRESHOLD:
		return 0.0
	if item_price <= COST_THRESHOLD:
		return MAX_ADDITIONAL_CHANCE
	var progress = clamp(float(paid_cost - COST_THRESHOLD) / float(item_price - COST_THRESHOLD), 0.0, 1.0)
	return MAX_ADDITIONAL_CHANCE * progress * progress

static func contains_bunny(shop: Array) -> bool:
	for entry in shop:
		if entry[0].my_id == BUNNY_ID:
			return true
	return false

static func safe_indices(shop: Array, locked_count: int, protected_ids: Array, forced_count: int, minimum_weapons: int) -> Array:
	var weapon_count = 0
	for entry in shop:
		if entry[0] is WeaponData:
			weapon_count += 1
	var candidates = []
	for index in range(shop.size()):
		if index < locked_count or index < forced_count:
			continue
		var item = shop[index][0]
		if protected_ids.has(item.my_id_hash) or protected_ids.has(item.my_id):
			continue
		if not item.can_be_looted:
			continue
		if item is WeaponData and weapon_count <= minimum_weapons:
			continue
		candidates.append(index)
	return candidates
