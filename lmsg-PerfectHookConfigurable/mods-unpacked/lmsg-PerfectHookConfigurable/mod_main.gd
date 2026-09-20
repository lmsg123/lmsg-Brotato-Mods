extends Node

const MOD_ID := "lmsg-PerfectHookConfigurable"
const MOD_LOG := "lmsg-PerfectHookConfigurable"
var mod_dir_path := ""

func _init() -> void:
	mod_dir_path = ModLoaderMod.get_unpacked_dir().plus_file("lmsg-PerfectHookConfigurable/")
	install_script_extensions()

func install_script_extensions() -> void:
	var ext_dir = mod_dir_path.plus_file("extensions")
	ModLoaderMod.install_script_extension(ext_dir.plus_file("ui/menus/shop/base_shop.gd"))
	# 核心桥梁：绝对不能删！
	ModLoaderMod.install_script_extension(mod_dir_path.plus_file("progress_data.gd"))

func _ready() -> void:
	RunData.set_meta("lmsg_curse_mode", 0)
	RunData.set_meta("lmsg_curse_strength_mode", 0)
	
	yield(get_tree(), "idle_frame")
	yield(get_tree(), "idle_frame")
	register_mod_options()

func register_mod_options() -> void:
	var api = get_node_or_null("/root/ModLoader/Oudstand-ModOptions/ModOptionsAPI")
	if api == null:
		api = get_node_or_null("/root/ModLoader/Oudstand-ModOptions/ModOptions")
	if api == null:
		ModLoaderLog.warning("未检测到 ModOptions，将使用默认配置运行。", MOD_LOG)
		return

	# 直接向 Brotato 的内部存档要语言数据，这是最真实的玩家设置
	var is_zh = false
	if ProgressData.settings and "language" in ProgressData.settings:
		if "zh" in str(ProgressData.settings.language):
			is_zh = true
	else:
		# 兜底方案
		is_zh = TranslationServer.get_locale().begins_with("zh")
	
	# 根据语言分配文案
	var t_title = "完美鱼钩 (PerfectHook)" if is_zh else "PerfectHook Settings"
	var t_curse_label = "诅咒概率模式" if is_zh else "Curse Mode"
	var t_c0 = "每波至少诅咒 1 个锁定物品" if is_zh else "At Least One Cursed per Wave"
	var t_c1 = "100% 诅咒所有锁定物品" if is_zh else "100% Curse All Locked Items"
	var t_c2 = "原版概率 (不保证触发)" if is_zh else "Vanilla Random Chance"
	
	var t_str_label = "诅咒属性强度" if is_zh else "Curse Strength"
	var t_s0 = "原版动态强度 (随波次浮动)" if is_zh else "Dynamic (Vanilla)"
	var t_s1 = "固定 110% 额外强度 (最大值)" if is_zh else "Fixed 110% Extra Strength"
	
	var t_info = "在商店锁定物品后，下一波触发的鱼钩机制。修改后立即生效。" if is_zh else "Configure the Fish Hook behavior for locked items. Changes take effect immediately."

	api.register_mod_options(MOD_ID, {
		"tab_title": t_title,
		"options": [
			{
				"type": "dropdown",
				"id": "curse_mode",
				"label": t_curse_label,
				"choices": [t_c0, t_c1, t_c2],
				"default": t_c0
			},
			{
				"type": "dropdown",
				"id": "curse_strength_mode",
				"label": t_str_label,
				"choices": [t_s0, t_s1],
				"default": t_s0
			}
		],
		"info_text": t_info
	})
	api.connect("config_changed", self, "_on_config_changed")
	
	_update_meta("curse_mode", api.get_value(MOD_ID, "curse_mode"))
	_update_meta("curse_strength_mode", api.get_value(MOD_ID, "curse_strength_mode"))
	ModLoaderLog.info("PerfectHook 模组加载完成 (最终发行版)", MOD_LOG)

func _on_config_changed(mod_id: String, option_id: String, new_value) -> void:
	if mod_id == MOD_ID:
		_update_meta(option_id, new_value)

func _update_meta(option_id: String, value) -> void:
	var val_str = str(value)
	var parsed_val = 0
	
	# 双语关键字兼容匹配
	if "100" in val_str:
		parsed_val = 1
	elif "原版" in val_str or "Vanilla" in val_str:
		parsed_val = 2
		
	if option_id == "curse_mode":
		RunData.set_meta("lmsg_curse_mode", parsed_val)
	elif option_id == "curse_strength_mode":
		var strength_val = 0
		if "110" in val_str:
			strength_val = 1
		RunData.set_meta("lmsg_curse_strength_mode", strength_val)