extends "res://ui/menus/shop/base_shop.gd"

const BunnyRules = preload("res://mods-unpacked/lmsg-DangerousBunnyReroll/bunny_rules.gd")

# Context exists only while the original manual reroll method is running.
# No timers, frame polling, extra shop generation or hot-path logging.
var _bunny_reroll_contexts = {}

func _on_RerollButton_pressed(player_index: int) -> void:
	if _bunny_reroll_contexts.has(player_index):
		return
	var paid_cost = _reroll_price[player_index]
	if paid_cost <= BunnyRules.COST_THRESHOLD:
		._on_RerollButton_pressed(player_index)
		return
	_bunny_reroll_contexts[player_index] = {"paid_cost": paid_cost, "consumed": false}
	._on_RerollButton_pressed(player_index)
	_bunny_reroll_contexts.erase(player_index)

func fill_shop_items(player_locked_items: Array, player_index: int, just_entered_shop: bool = false) -> void:
	var apply_after_generation = not just_entered_shop and _bunny_reroll_contexts.has(player_index)
	if apply_after_generation:
		apply_after_generation = not _bunny_reroll_contexts[player_index]["consumed"]
	if not apply_after_generation:
		.fill_shop_items(player_locked_items, player_index, just_entered_shop)
		return

	# Mark before the parent call: another extension re-entering fill cannot
	# perform a second post-pass for this reroll.
	_bunny_reroll_contexts[player_index]["consumed"] = true
	var previous_items = _shop_items[player_index].duplicate()
	var forced_count = min(RunData.forced_shop_items.size(), ItemService.NB_SHOP_ITEMS)
	var protected_ids = []
	for guaranteed_item in RunData.get_player_effect(Keys.guaranteed_shop_items_hash, player_index):
		protected_ids.append(guaranteed_item[0])
	var has_tier_override = false
	for tier_effect in RunData.get_player_effect(Keys.increase_tier_on_reroll_hash, player_index):
		if tier_effect[1] != 0:
			has_tier_override = true
	.fill_shop_items(player_locked_items, player_index, just_entered_shop)
	# The original may consume a Goldfish to increase every generated tier.
	# Preserve that entire special reroll rather than substitute a lower tier.
	if has_tier_override:
		return

	_try_add_bunny(player_index, player_locked_items.size(), previous_items, protected_ids, forced_count,
		_bunny_reroll_contexts[player_index]["paid_cost"])

func _try_add_bunny(player_index: int, locked_count: int, previous_items: Array,
		protected_ids: Array, forced_count: int, paid_cost: int) -> void:
	var shop = _shop_items[player_index]
	if BunnyRules.contains_bunny(shop) or BunnyRules.contains_bunny(previous_items):
		return
	# Debug overrides are intentional and must not be modified by this mod.
	if DebugService.force_item_in_shop != "":
		return
	var bunny_hash = Keys.generate_hash(BunnyRules.BUNNY_ID)
	if not ItemService.is_item_id(bunny_hash):
		return
	var bunny = ItemService.get_item_from_id(bunny_hash)
	if not _bunny_is_allowed(bunny, player_index):
		return
	var candidates = BunnyRules.safe_indices(shop, locked_count, protected_ids, forced_count,
		_minimum_weapon_count(player_index))
	if candidates.empty():
		return

	var price = ItemService.get_value(RunData.current_wave, bunny.value, player_index, true, false, bunny.my_id_hash)
	var chance = BunnyRules.additional_chance(paid_cost, price)
	if chance <= 0.0 or (chance < 1.0 and randf() >= chance):
		return
	var index = candidates[randi() % candidates.size()]
	# Reuse vanilla DLC effect updates and the standard [resource, wave] pair.
	var offered_bunny = ItemService.apply_item_effect_modifications(bunny, player_index)
	shop[index] = [offered_bunny, RunData.current_wave]

func _minimum_weapon_count(player_index: int) -> int:
	if not RunData.player_has_weapon_slots(player_index):
		return 0
	var minimum = 0
	if RunData.current_wave <= ItemService.MAX_WAVE_TWO_WEAPONS_GUARANTEED:
		minimum = 2
	elif RunData.current_wave <= ItemService.MAX_WAVE_ONE_WEAPON_GUARANTEED:
		minimum = 1
	return int(max(minimum, RunData.get_player_effect(Keys.minimum_weapons_in_shop_hash, player_index)))

func _bunny_is_allowed(bunny, player_index: int) -> bool:
	if not bunny.can_be_looted or bunny.max_nb == 0 or not ProgressData.items_unlocked.has(bunny.my_id_hash):
		return false
	var banned_items = RunData.players_data[player_index].banned_items
	if banned_items.has(bunny.my_id_hash) or banned_items.has(bunny.my_id):
		return false
	for tag in RunData.get_player_effect(Keys.remove_shop_items_hash, player_index):
		if bunny.tags.has(Keys.hash_to_string.get(tag, str(tag))):
			return false
	var character = RunData.get_player_character(player_index)
	if RunData.current_wave < RunData.nb_of_waves:
		if character.banned_items.has(bunny.my_id):
			return false
		for group in character.banned_item_groups:
			if ItemService.item_groups.has(group) and ItemService.item_groups[group].has(bunny.my_id):
				return false
	elif ItemService.banned_items_for_endless.has(bunny.my_id_hash) or ItemService.banned_items_for_endless.has(bunny.my_id):
		return false
	# No bunny exists in this player's shop (checked by the caller), so
	# vanilla's cached owned count is sufficient. It uses the base max_nb,
	# including when owned copies are cursed, without copying the inventory.
	if RunData.get_remaining_max_nb_item(bunny, player_index) <= 0:
		return false
	return true
