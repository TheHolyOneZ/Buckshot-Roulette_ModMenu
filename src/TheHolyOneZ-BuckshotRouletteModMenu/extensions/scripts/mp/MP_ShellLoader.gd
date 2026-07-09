extends "res://multiplayer/scripts/global scripts/MP_ShellLoader.gd"

func SpawnShells() -> void:
	super()
	var state := get_tree().root.get_node_or_null("TZModMenuState")
	if state == null:
		return
	state.mp_game_state = game_state
	var seq: Array = []
	var dict = game_state.MAIN_active_sequence_dict
	if typeof(dict) == TYPE_DICTIONARY:
		if dict.has("sequence_in_shotgun"):
			seq = (dict.sequence_in_shotgun as Array).duplicate()
		elif dict.has("sequence_visible"):
			seq = (dict.sequence_visible as Array).duplicate()
	state.mp_snapshot_shells(seq)
