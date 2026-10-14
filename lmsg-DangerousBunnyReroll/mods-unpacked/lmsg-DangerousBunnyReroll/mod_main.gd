extends Node

const MOD_ID = "lmsg-DangerousBunnyReroll"

func _init() -> void:
	var mod_path = ModLoaderMod.get_unpacked_dir().plus_file(MOD_ID)
	ModLoaderMod.install_script_extension(mod_path.plus_file("extensions/ui/menus/shop/base_shop.gd"))
	ModLoaderMod.install_script_extension(mod_path.plus_file("extensions/singletons/item_service.gd"))

func _ready() -> void:
	ModLoaderLog.info("Dangerous Bunny reroll enhancement loaded.", MOD_ID)
