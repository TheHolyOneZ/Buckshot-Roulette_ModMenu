extends "res://scripts/DealerIntelligence.gd"

func Shoot(who: String) -> void:
	var state := get_tree().root.get_node_or_null("TZModMenuState")
	if state:
		state.round_manager = roundManager
	var original: int = roundManager.currentShotgunDamage

	if state and who == "player" and state.god_mode_enabled:
		roundManager.currentShotgunDamage = 0

	await super(who)

	roundManager.currentShotgunDamage = original
