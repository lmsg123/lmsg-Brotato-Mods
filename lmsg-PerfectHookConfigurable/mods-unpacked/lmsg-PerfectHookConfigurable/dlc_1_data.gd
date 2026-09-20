extends "res://dlcs/dlc_1/dlc_1_data.gd"

func get_cursed_item_effect_modifier(turn_randomization_off: bool = false, min_modifier: float = 0.0) -> float:
	var strength_val = 0
	if RunData.has_meta("lmsg_curse_strength_mode"):
		strength_val = RunData.get_meta("lmsg_curse_strength_mode")

	if strength_val == 1:
		return 1.1
	else:
		return .get_cursed_item_effect_modifier(turn_randomization_off, min_modifier)

func _get_cursed_item_effect_modifier(turn_randomization_off: bool = false, min_modifier: float = 0.0) -> float:
	var strength_val = 0
	if RunData.has_meta("lmsg_curse_strength_mode"):
		strength_val = RunData.get_meta("lmsg_curse_strength_mode")

	if strength_val == 1:
		return 1.1
	else:
		return ._get_cursed_item_effect_modifier(turn_randomization_off, min_modifier)