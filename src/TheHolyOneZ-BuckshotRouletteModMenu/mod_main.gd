extends Node

const MOD_DIR := "res://mods-unpacked/TheHolyOneZ-BuckshotRouletteModMenu"

func _init() -> void:
	install_script_extensions()

func _ready() -> void:
	var state := Node.new()
	state.name = "TZModMenuState"
	state.set_script(load(MOD_DIR + "/state.gd"))
	get_tree().root.call_deferred("add_child", state)

func install_script_extensions() -> void:
	ModLoaderMod.install_script_extension(MOD_DIR + "/extensions/scripts/ShotgunShooting.gd")
	ModLoaderMod.install_script_extension(MOD_DIR + "/extensions/scripts/DealerIntelligence.gd")
	ModLoaderMod.install_script_extension(MOD_DIR + "/extensions/scripts/ShellSpawner.gd")
	ModLoaderMod.install_script_extension(MOD_DIR + "/extensions/scripts/mp/MP_ShellLoader.gd")
	ModLoaderMod.install_script_extension(MOD_DIR + "/extensions/scripts/mp/MP_ShotgunInteraction.gd")
	ModLoaderMod.install_script_extension(MOD_DIR + "/extensions/scripts/mp/MP_PacketVerification.gd")
