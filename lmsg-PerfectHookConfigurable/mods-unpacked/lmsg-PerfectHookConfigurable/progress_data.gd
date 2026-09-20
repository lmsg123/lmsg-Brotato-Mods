extends "res://singletons/progress_data.gd"

func load_dlc_pcks() -> void:
	.load_dlc_pcks()
	var dir = ModLoaderMod.get_unpacked_dir() + "lmsg-PerfectHookConfigurable/"
	ModLoaderMod.install_script_extension(dir.plus_file("dlc_1_data.gd"))