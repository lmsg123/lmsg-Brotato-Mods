extends "res://ui/menus/shop/base_shop.gd"

func _on_tree_exited() -> void:
	for player_index in range(RunData.get_player_count()):
		var curse_locked_items_raw: int = RunData.get_player_effect(Keys.curse_locked_items_hash, player_index)
		var curse_locked_items: float = min(curse_locked_items_raw, 100.0)
		var locked_items: Array = RunData.locked_shop_items[player_index]

		if locked_items.size() == 0 or curse_locked_items <= 0:
			continue

		var mode_val = 0
		if RunData.has_meta("lmsg_curse_mode"):
			mode_val = RunData.get_meta("lmsg_curse_mode")

		if mode_val == 1:
			_apply_100_percent_curse(player_index, locked_items)
		elif mode_val == 2:
			_apply_vanilla_curse(player_index, locked_items, curse_locked_items)
		else:
			_apply_at_least_one_curse(player_index, locked_items, curse_locked_items)

func _call_curse_item(item, player_index):
	for dlc_id in RunData.enabled_dlcs:
		var dlc_data = ProgressData.get_dlc_data(dlc_id)
		if dlc_data and dlc_data.has_method("curse_item"):
			return dlc_data.curse_item(item, player_index)
	return null

func _apply_100_percent_curse(player_index: int, locked_items: Array) -> void:
	for i in range(locked_items.size()):
		if not locked_items[i][0].is_cursed:
			var new_item = _call_curse_item(locked_items[i][0], player_index)
			if new_item != null:
				locked_items[i][0] = new_item
	RunData.players_data[player_index].curse_locked_shop_items_pity = 0
	RunData.set_tracked_value(player_index, Keys.item_fish_hook_hash, 0)

func _apply_vanilla_curse(player_index: int, locked_items: Array, curse_locked_items: float) -> void:
	var nb_locked_items_that_didnt_get_cursed: int = 0
	var has_cursed_an_item = false
	var randomized_positions = []
	for i in locked_items.size():
		randomized_positions.push_back(i)
	randomized_positions.shuffle()

	for i in randomized_positions:
		var chance = (RunData.players_data[player_index].curse_locked_shop_items_pity + curse_locked_items) / 100.0
		if not locked_items[i][0].is_cursed and Utils.get_chance_success(chance):
			var new_item = _call_curse_item(locked_items[i][0], player_index)
			if new_item != null:
				has_cursed_an_item = true
				RunData.players_data[player_index].curse_locked_shop_items_pity = 0
				RunData.set_tracked_value(player_index, Keys.item_fish_hook_hash, 0)
				locked_items[i][0] = new_item
		elif not locked_items[i][0].is_cursed:
			nb_locked_items_that_didnt_get_cursed += 1

	if curse_locked_items > 0 and locked_items.size() > 0 and not has_cursed_an_item and nb_locked_items_that_didnt_get_cursed > 0:
		RunData.players_data[player_index].curse_locked_shop_items_pity += int(nb_locked_items_that_didnt_get_cursed * (curse_locked_items / 4.0))
		RunData.set_tracked_value(player_index, Keys.item_fish_hook_hash, RunData.players_data[player_index].curse_locked_shop_items_pity)

func _apply_at_least_one_curse(player_index: int, locked_items: Array, curse_locked_items: float) -> void:
	var has_cursed_an_item: bool = false
	var nb_locked_items_that_didnt_get_cursed: int = 0
	var randomized_positions: Array = []
	for i in locked_items.size():
		randomized_positions.push_back(i)
	randomized_positions.shuffle()

	for i in randomized_positions:
		var chance = (RunData.players_data[player_index].curse_locked_shop_items_pity + curse_locked_items) / 100.0
		if not locked_items[i][0].is_cursed and Utils.get_chance_success(chance):
			var new_item = _call_curse_item(locked_items[i][0], player_index)
			if new_item != null:
				has_cursed_an_item = true
				RunData.players_data[player_index].curse_locked_shop_items_pity = 0
				RunData.set_tracked_value(player_index, Keys.item_fish_hook_hash, 0)
				locked_items[i][0] = new_item
		elif not locked_items[i][0].is_cursed:
			nb_locked_items_that_didnt_get_cursed += 1

	if not has_cursed_an_item and nb_locked_items_that_didnt_get_cursed > 0:
		for i in randomized_positions:
			if not locked_items[i][0].is_cursed:
				var new_item = _call_curse_item(locked_items[i][0], player_index)
				if new_item != null:
					RunData.players_data[player_index].curse_locked_shop_items_pity = 0
					RunData.set_tracked_value(player_index, Keys.item_fish_hook_hash, 0)
					locked_items[i][0] = new_item
					break