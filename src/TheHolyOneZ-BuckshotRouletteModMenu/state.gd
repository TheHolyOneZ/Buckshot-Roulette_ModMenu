extends Node

var god_mode_enabled := false
var instakill_dealer_enabled := false
var shell_esp_enabled := true

var multiplayer_enabled := false
var mp_game_state: Object = null
var mp_intermediary: Object = null
var mp_shells_fired := 0
var _mp_mode_label: Label = null

var round_manager: Object = null
var dealer_ai: Object = null
var health_counter: Object = null

var _full_sequence: Array = []
var _spawner: Object = null
var _last_consumed := -999

var _canvas: CanvasLayer
var _root: Control
var _esp_label: RichTextLabel
var _hp_label: Label
var _menu_visible := true
var _font: Font
var _rows: Array = []

const ACCENT := Color("#e63946")
const BG := Color(0.07, 0.07, 0.08, 0.96)
const ON_COL := Color("#5ad469")
const OFF_COL := Color(0.58, 0.58, 0.6)
const FONT_PATH := "res://fonts/AveriaSerif-Bold.ttf"

const FS_TITLE := 11
const FS_SUB := 7
const FS_BTN := 9
const FS_KEY := 7
const FS_ESP := 8
const FS_HINT := 6
const PANEL_W := 158

func _ready() -> void:
	set_process(true)
	call_deferred("_build_ui")

func _build_ui() -> void:
	_font = load(FONT_PATH) as Font

	_canvas = CanvasLayer.new()
	_canvas.name = "TZModMenuCanvas"
	_canvas.layer = 128
	get_tree().root.add_child(_canvas)

	var panel := PanelContainer.new()
	panel.position = Vector2(8, 8)
	panel.custom_minimum_size = Vector2(PANEL_W, 0)
	var sb := StyleBoxFlat.new()
	sb.bg_color = BG
	sb.set_corner_radius_all(0)
	sb.border_color = ACCENT
	sb.border_width_left = 3
	sb.content_margin_left = 6
	sb.content_margin_right = 6
	sb.content_margin_top = 5
	sb.content_margin_bottom = 5
	panel.add_theme_stylebox_override("panel", sb)
	_canvas.add_child(panel)
	_root = panel

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 2)
	panel.add_child(vb)

	vb.add_child(_lbl("TheHolyOneZ", ACCENT, FS_TITLE))
	vb.add_child(_lbl("Buckshot Roulette • Mod Menu", Color(0.72, 0.72, 0.74), FS_SUB))
	vb.add_child(_gap(2))

	_add_toggle(vb, "Multiplayer Mode", "F5",
		func(): return multiplayer_enabled,
		func(v): multiplayer_enabled = v; _notify("Multiplayer Mode: %s" % v); _update_mode_label(); _draw_esp())
	_mp_mode_label = _lbl("", Color(0.72, 0.72, 0.74), FS_HINT)
	vb.add_child(_mp_mode_label)
	vb.add_child(_gap(2))

	_add_toggle(vb, "God Mode", "F1",
		func(): return god_mode_enabled,
		func(v): god_mode_enabled = v; _notify("God Mode: %s" % v))
	_add_toggle(vb, "Instant-Kill Dealer", "F4",
		func(): return instakill_dealer_enabled,
		func(v): instakill_dealer_enabled = v; _notify("Instant-Kill Dealer: %s" % v))
	_add_toggle(vb, "Shell Order ESP", "F3",
		func(): return shell_esp_enabled,
		func(v): shell_esp_enabled = v; _notify("Shell ESP: %s" % v); _draw_esp())

	vb.add_child(_gap(3))
	_hp_label = _lbl("You: –   Dealer: –", Color(0.9, 0.9, 0.92), FS_SUB)
	vb.add_child(_hp_label)
	var hprow := HBoxContainer.new()
	hprow.add_theme_constant_override("separation", 6)
	vb.add_child(hprow)
	hprow.add_child(_action_btn("+ Heal You", func():
		if multiplayer_enabled:
			mp_heal_self()
		elif round_manager:
			round_manager.health_player += 1
			_refresh_health_display()))
	hprow.add_child(_action_btn("- Others", func():
		if multiplayer_enabled:
			mp_hurt_others()
		elif round_manager:
			round_manager.health_opponent = max(int(round_manager.health_opponent) - 1, 1)
			_refresh_health_display()))

	vb.add_child(_gap(3))
	vb.add_child(_lbl("SHELL ORDER  (▶ current, ! dealer knows)", Color(0.72, 0.72, 0.74), FS_SUB))
	_esp_label = RichTextLabel.new()
	_esp_label.bbcode_enabled = true
	_esp_label.fit_content = true
	_esp_label.add_theme_font_override("normal_font", _font)
	_esp_label.add_theme_font_size_override("normal_font_size", FS_ESP)
	_esp_label.custom_minimum_size = Vector2(PANEL_W - 18, 16)
	vb.add_child(_esp_label)

	vb.add_child(_gap(2))
	vb.add_child(_lbl("Right Shift  —  hide / show", Color(0.5, 0.5, 0.53), FS_HINT))

	_refresh_toggles()
	_draw_esp()
	_update_mode_label()

func _update_mode_label() -> void:
	if not is_instance_valid(_mp_mode_label):
		return
	if multiplayer_enabled:
		var role := _mp_role()
		_mp_mode_label.text = "◆ MULTIPLAYER  —  you are %s" % role
		_mp_mode_label.add_theme_color_override("font_color",
			ON_COL if role == "HOST" else Color(1.0, 0.7, 0.3))
	else:
		_mp_mode_label.text = "◇ Single-player"
		_mp_mode_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.53))

func _mp_role() -> String:
	var gs = get_tree().root.get_node_or_null("GlobalSteam")
	if gs == null or not is_instance_valid(gs):
		return "?"
	if int(gs.STEAM_ID) == 0 or int(gs.HOST_ID) == 0:
		return "?"
	return "HOST" if int(gs.STEAM_ID) == int(gs.HOST_ID) else "CLIENT"

func _lbl(text: String, col: Color, size: int) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", _font)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	return l

func _gap(h: int) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, h)
	return c

func _action_btn(text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.add_theme_font_override("font", _font)
	b.add_theme_font_size_override("font_size", FS_BTN)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.pressed.connect(func(): cb.call())
	return b

func _add_toggle(parent: Node, label: String, key: String, getter: Callable, setter: Callable) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	parent.add_child(row)

	var btn := Button.new()
	btn.flat = true
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	btn.add_theme_font_override("font", _font)
	btn.add_theme_font_size_override("font_size", FS_BTN)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.pressed.connect(func():
		setter.call(not bool(getter.call()))
		_refresh_toggles())
	row.add_child(btn)

	row.add_child(_lbl(key, ACCENT, FS_KEY))
	_rows.append({"btn": btn, "label": label, "getter": getter})

func _refresh_toggles() -> void:
	for r in _rows:
		var on: bool = bool(r["getter"].call())
		r["btn"].text = ("● " if on else "○ ") + r["label"]
		r["btn"].add_theme_color_override("font_color", ON_COL if on else OFF_COL)
		r["btn"].add_theme_color_override("font_hover_color", ON_COL if on else OFF_COL)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_F1:
				god_mode_enabled = not god_mode_enabled
				_notify("God Mode: %s" % god_mode_enabled); _refresh_toggles()
			KEY_F4:
				instakill_dealer_enabled = not instakill_dealer_enabled
				_notify("Instant-Kill Dealer: %s" % instakill_dealer_enabled); _refresh_toggles()
			KEY_F3:
				shell_esp_enabled = not shell_esp_enabled
				_notify("Shell ESP: %s" % shell_esp_enabled); _refresh_toggles(); _draw_esp()
			KEY_F5:
				multiplayer_enabled = not multiplayer_enabled
				_notify("Multiplayer Mode: %s" % multiplayer_enabled)
				_refresh_toggles(); _update_mode_label(); _draw_esp()
			KEY_SHIFT:
				if event.location != 1:
					_menu_visible = not _menu_visible
					if is_instance_valid(_root):
						_root.visible = _menu_visible

func snapshot_shells(sequence: Array, spawner: Object, ai: Object) -> void:
	_full_sequence = sequence.duplicate()
	_spawner = spawner
	dealer_ai = ai
	_last_consumed = -999

func clear_shells() -> void:
	_full_sequence = []
	_spawner = null
	_last_consumed = -999
	_draw_esp()

func mp_snapshot_shells(sequence: Array) -> void:
	multiplayer_enabled = true
	dealer_ai = null
	_spawner = null
	_full_sequence = sequence.duplicate()
	mp_shells_fired = 0
	_last_consumed = 0
	if is_instance_valid(_mp_mode_label):
		_refresh_toggles(); _update_mode_label()
	_draw_esp()

func mp_on_shell_fired() -> void:
	mp_shells_fired += 1
	_last_consumed = clampi(mp_shells_fired, 0, _full_sequence.size())
	_draw_esp()

func _process(_delta: float) -> void:
	if multiplayer_enabled:
		_process_mp()
		return

	if is_instance_valid(_hp_label) and round_manager != null and is_instance_valid(round_manager):
		_hp_label.text = "You: %s   Dealer: %s" % [round_manager.health_player, round_manager.health_opponent]

	if _spawner == null or _full_sequence.is_empty() or not is_instance_valid(_spawner):
		return
	var consumed: int = _full_sequence.size() - _spawner.sequenceArray.size()
	if consumed != _last_consumed:
		_last_consumed = consumed
		_draw_esp()

func _process_mp() -> void:
	if is_instance_valid(_hp_label) and mp_intermediary != null and is_instance_valid(mp_intermediary):
		var ih = mp_intermediary.instance_handler
		if ih != null and is_instance_valid(ih):
			var parts := PackedStringArray()
			var arr: Array = ih.instance_property_array
			for p in arr:
				if p == null or not is_instance_valid(p):
					continue
				var tag: String = "You" if p.is_active else str(p.user_name)
				parts.append("%s:%s" % [tag, p.health_current])
			if parts.size() > 0:
				_hp_label.text = "  ".join(parts)
			_update_mode_label()

	var live: Array = _mp_live_sequence()
	if not live.is_empty():
		if live != _full_sequence:
			_full_sequence = live.duplicate()
			_last_consumed = 0
			_draw_esp()

func _mp_live_sequence() -> Array:
	if _mp_role() != "HOST":
		return []
	if mp_game_state == null or not is_instance_valid(mp_game_state):
		return []
	var d = mp_game_state.MAIN_active_sequence_dict
	if typeof(d) == TYPE_DICTIONARY and d.has("sequence_in_shotgun"):
		return d.sequence_in_shotgun
	return []

func _draw_esp() -> void:
	if not is_instance_valid(_esp_label):
		return
	_esp_label.modulate.a = 1.0 if shell_esp_enabled else 0.3
	if _full_sequence.is_empty():
		_esp_label.text = "[color=#888](waiting for round…)[/color]"
		return
	var consumed: int = maxi(_last_consumed, 0)
	var known: Array = []
	if dealer_ai != null and is_instance_valid(dealer_ai):
		known = dealer_ai.sequenceArray_knownShell
	var parts := PackedStringArray()
	for i in range(_full_sequence.size()):
		var live := str(_full_sequence[i]) == "live"
		var nm := "LIVE" if live else "blank"
		if i < consumed:
			parts.append("[color=#555555][s]%s[/s][/color]" % nm)
		else:
			var live_idx := i - consumed
			var dealer_knows: bool = live_idx < known.size() and bool(known[live_idx])
			var mark := "!" if dealer_knows else ""
			if i == consumed:
				var col := "#ff5a67" if live else "#74c0fc"
				parts.append("[color=%s]▶%s%s[/color]" % [col, nm.to_upper(), mark])
			else:
				var col := "#e63946" if live else "#4dabf7"
				parts.append("[color=%s]%s%s%s[/color]" % [col, ("●" if live else "○"), nm, mark])
	_esp_label.text = "  ".join(parts)

func _refresh_health_display() -> void:
	if health_counter != null and is_instance_valid(health_counter):
		health_counter.UpdateDisplay()

func _mp_instances() -> Array:
	if mp_intermediary == null or not is_instance_valid(mp_intermediary):
		return []
	var ih = mp_intermediary.instance_handler
	if ih == null or not is_instance_valid(ih):
		return []
	return ih.instance_property_array

func _mp_hc_capacity(inst: Object) -> int:
	if inst.health_counter != null and is_instance_valid(inst.health_counter):
		var arr: Array = inst.health_counter.ui_charge_array
		if arr != null and arr.size() > 0:
			return arr.size()
	return 4

func mp_heal_self() -> void:
	for p in _mp_instances():
		if p != null and is_instance_valid(p) and p.is_active:
			p.health_current = _mp_hc_capacity(p)
			if p.health_counter != null and is_instance_valid(p.health_counter):
				p.health_counter.UpdateDisplay()
			return

func mp_hurt_others() -> void:
	for p in _mp_instances():
		if p == null or not is_instance_valid(p) or p.is_active:
			continue
		p.health_current = maxi(int(p.health_current) - 1, 0)
		if p.health_counter != null and is_instance_valid(p.health_counter):
			p.health_counter.UpdateDisplay()

func _notify(_msg: String) -> void:
	pass
