extends "res://multiplayer/scripts/user scripts/MP_ShotgunInteraction.gd"

func _ready() -> void:
	super()
	var s := _tz()
	if s:
		s.mp_intermediary = intermediary

func _tz() -> Node:
	return get_tree().root.get_node_or_null("TZModMenuState")

func _local_socket() -> int:
	if intermediary == null or not is_instance_valid(intermediary):
		return -999
	for p in intermediary.instance_handler.instance_property_array:
		if p != null and is_instance_valid(p) and p.is_active:
			return p.socket_number
	return -999

func ReceivePacket_Shoot(packet_dictionary: Dictionary = {}) -> void:
	super(packet_dictionary)
	var s := _tz()
	if s == null or not s.multiplayer_enabled:
		return
	s.mp_intermediary = intermediary
	var my_socket := _local_socket()

	if s.god_mode_enabled and active_shooter_socket_target == my_socket:
		active_shooter_shotgun_damage = 0

	if s.instakill_dealer_enabled and active_shooter_socket_self == my_socket \
			and active_shooter_socket_target != my_socket:
		active_shooter_shell = "live"
		active_shooter_shotgun_damage = 99
		if intermediary != null and is_instance_valid(intermediary):
			intermediary.game_state.MAIN_shooter_shell = "live"

	if packet_dictionary.has("sent_from_socket") \
			and packet_dictionary.sent_from_socket == properties.socket_number:
		s.mp_on_shell_fired()
