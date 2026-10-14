extends "res://singletons/item_service.gd"

const UNLIMITED_BUNNY_ID = "item_dangerous_bunny"

func _ready() -> void:
	_remove_bunny_limit()
	._ready()

func init_unlocked_pool() -> void:
	# Also apply when pools are rebuilt for a new or restored run.
	_remove_bunny_limit()
	.init_unlocked_pool()

func _remove_bunny_limit() -> void:
	for item in items:
		if item.my_id == UNLIMITED_BUNNY_ID:
			# max_nb == 0 means disabled, not an ownership cap; preserve it.
			if item.max_nb > 0:
				item.max_nb = -1
			return

func get_limited_items(from_items: Array) -> Dictionary:
	var limited = .get_limited_items(from_items)
	var bunny_hash = Keys.generate_hash(UNLIMITED_BUNNY_ID)
	# Old saved copies may still have max_nb=3/4. Vanilla normalizes cursed
	# copies to the base resource, then would incorrectly compare count >= -1.
	# Exclude only the now-unlimited bunny from ownership-cap filtering.
	if is_item_id(bunny_hash) and get_item_from_id(bunny_hash).max_nb == -1:
		limited.erase(bunny_hash)
	return limited

func apply_item_effect_modifications(item: ItemParentData, player_index: int) -> ItemParentData:
	var modified_item = .apply_item_effect_modifications(item, player_index)
	# DLC-generated cursed offers must not regain a finite limit.
	if modified_item.my_id == UNLIMITED_BUNNY_ID and modified_item.max_nb > 0:
		modified_item.max_nb = -1
	return modified_item
