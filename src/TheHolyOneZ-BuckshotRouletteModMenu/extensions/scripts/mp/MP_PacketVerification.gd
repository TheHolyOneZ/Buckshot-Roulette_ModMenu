extends "res://multiplayer/scripts/global scripts/MP_PacketVerification.gd"

func _local_socket() -> int:
	if instance_handler == null or not is_instance_valid(instance_handler):
		return -999
	for p in instance_handler.instance_property_array:
		if p != null and is_instance_valid(p) and p.is_active:
			return p.socket_number
	return -999

func PacketSort(dict: Dictionary):
	var s = get_tree().root.get_node_or_null("TZModMenuState")
	if s != null and s.multiplayer_enabled and dict.get("packet alias", "") == "shoot user request":
		var seq_dict = game_state.MAIN_active_sequence_dict
		if typeof(seq_dict) == TYPE_DICTIONARY and seq_dict.has("sequence_in_shotgun") \
				and (seq_dict.sequence_in_shotgun as Array).size() > 0:
			var my_socket := _local_socket()
			var shooter: int = dict.get("sent_from_socket", -2)
			var target: int = dict.get("socket_to_shoot", -1)
			if s.god_mode_enabled and target == my_socket:
				seq_dict.sequence_in_shotgun[0] = "blank"
			if s.instakill_dealer_enabled and shooter == my_socket and target != my_socket:
				seq_dict.sequence_in_shotgun[0] = "live"
				game_state.MAIN_barrel_sawed_off = true
	super(dict)
