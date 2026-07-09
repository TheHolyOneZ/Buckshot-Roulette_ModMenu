extends "res://scripts/ShotgunShooting.gd"

func Shoot(who: String) -> void:
	var state := get_tree().root.get_node_or_null("TZModMenuState")
	if state:
		state.round_manager = roundManager
	var original: int = roundManager.currentShotgunDamage

	if state and who == "self" and state.god_mode_enabled:
		roundManager.currentShotgunDamage = 0
	elif state and who == "dealer" and state.instakill_dealer_enabled:
		if shellSpawner.sequenceArray.size() > 0:
			shellSpawner.sequenceArray[0] = "live"
		roundManager.currentShotgunDamage = 9999

	await super(who)

	roundManager.currentShotgunDamage = original
