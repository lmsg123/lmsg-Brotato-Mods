extends "res://ui/menus/shop/base_shop.gd"

# 【业界标准】调试开关：发布创意工坊前，请将这里改为 false，调试为ture
const DEBUG_LOG = false

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
	var cursed_count = 0
	for i in range(locked_items.size()):
		if not locked_items[i][0].is_cursed:
			var new_item = _call_curse_item(locked_items[i][0], player_index)
			if new_item != null:
				locked_items[i][0] = new_item
				cursed_count += 1
				
	if cursed_count > 0:
		RunData.players_data[player_index].curse_locked_shop_items_pity = 0
		RunData.set_tracked_value(player_index, Keys.item_fish_hook_hash, 0)
		if DEBUG_LOG: ModLoaderLog.info("100%% 模式：共强制诅咒了 %d 个物品" % cursed_count, "lmsg-PerfectHook")

func _apply_vanilla_curse(player_index: int, locked_items: Array, curse_locked_items: float) -> void:
	# 健壮性升级：提纯未诅咒物品池
	var uncursed_indices = []
	for i in range(locked_items.size()):
		if not locked_items[i][0].is_cursed:
			uncursed_indices.push_back(i)

	if uncursed_indices.size() == 0:
		return

	var has_cursed_an_item = false
	uncursed_indices.shuffle()

	for i in uncursed_indices:
		var chance = (RunData.players_data[player_index].curse_locked_shop_items_pity + curse_locked_items) / 100.0
		if Utils.get_chance_success(chance):
			var new_item = _call_curse_item(locked_items[i][0], player_index)
			if new_item != null:
				has_cursed_an_item = true
				RunData.players_data[player_index].curse_locked_shop_items_pity = 0
				RunData.set_tracked_value(player_index, Keys.item_fish_hook_hash, 0)
				locked_items[i][0] = new_item

	# 原版怜悯值（Pity）累加逻辑：基于未命中数量
	if not has_cursed_an_item:
		# 此时 uncursed_indices.size() 就是没有被诅咒的物品数量，代码更精简
		var added_pity = int(uncursed_indices.size() * (curse_locked_items / 4.0))
		RunData.players_data[player_index].curse_locked_shop_items_pity += added_pity
		RunData.set_tracked_value(player_index, Keys.item_fish_hook_hash, RunData.players_data[player_index].curse_locked_shop_items_pity)
		if DEBUG_LOG: ModLoaderLog.info("原版模式：全未命中，怜悯值增加 %d" % added_pity, "lmsg-PerfectHook")
	elif DEBUG_LOG:
		ModLoaderLog.info("原版模式：成功触发诅咒", "lmsg-PerfectHook")

func _apply_at_least_one_curse(player_index: int, locked_items: Array, curse_locked_items: float) -> void:
	# 健壮性升级：提纯未诅咒物品池
	var uncursed_indices = []
	for i in range(locked_items.size()):
		if not locked_items[i][0].is_cursed:
			uncursed_indices.push_back(i)

	# 如果所有锁定的物品都已经带有诅咒（例如上波锁了没买），直接退出，杜绝空转！
	if uncursed_indices.size() == 0:
		if DEBUG_LOG: ModLoaderLog.info("保底模式：所有锁定物品均已诅咒，跳过判定", "lmsg-PerfectHook")
		return

	var has_cursed_an_item: bool = false
	var cursed_count: int = 0
	var max_retries: int = 5
	var attempt: int = 0

	# 核心模拟 SL 循环
	while not has_cursed_an_item and attempt < max_retries:
		attempt += 1
		cursed_count = 0
		uncursed_indices.shuffle()

		for i in uncursed_indices:
			var chance = (RunData.players_data[player_index].curse_locked_shop_items_pity + curse_locked_items) / 100.0
			if Utils.get_chance_success(chance):
				var new_item = _call_curse_item(locked_items[i][0], player_index)
				if new_item != null:
					has_cursed_an_item = true
					cursed_count += 1
					RunData.players_data[player_index].curse_locked_shop_items_pity = 0
					RunData.set_tracked_value(player_index, Keys.item_fish_hook_hash, 0)
					locked_items[i][0] = new_item
					# 不加 break，保留同一波“多黄蛋”的可能

	if not has_cursed_an_item:
		if DEBUG_LOG: ModLoaderLog.info("模拟 SL %d 次失败，触发保底强制诅咒 1 个" % max_retries, "lmsg-PerfectHook")
		
		# 因为在进入 while 前以及 while 内都确保了有可用物品，且打乱了顺序，直接取第 0 个即可实现随机保底
		var target_idx = uncursed_indices[0]
		var new_item = _call_curse_item(locked_items[target_idx][0], player_index)
		if new_item != null:
			RunData.players_data[player_index].curse_locked_shop_items_pity = 0
			RunData.set_tracked_value(player_index, Keys.item_fish_hook_hash, 0)
			locked_items[target_idx][0] = new_item
	else:
		if DEBUG_LOG: ModLoaderLog.info("模拟 SL 成功，在第 %d 次重试中诅咒了 %d 件物品" % [attempt, cursed_count], "lmsg-PerfectHook")