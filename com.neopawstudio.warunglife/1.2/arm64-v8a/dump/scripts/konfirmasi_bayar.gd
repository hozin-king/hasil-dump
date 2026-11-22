extends CanvasLayer











const GH: = preload("res://scripts/gaya_hud.gd")
const JEDA_YA: = 0.45

signal selesai(setuju: bool)

var _sudah: = false
var _ya: Button = null




static func tanya(asal: Node, judul: String, jumlah: = 0, teks: = "", label_ya: = "Ya, bayar", bahaya: = false) -> bool:
	if asal == null or not is_instance_valid(asal) or not asal.is_inside_tree():
		return false
	var k: CanvasLayer = load("res://scripts/konfirmasi_bayar.gd").new()
	asal.add_child(k)
	k.call("_bangun", judul, jumlah, teks, label_ya, bahaya)
	return await k.selesai


func _bangun(judul: String, jumlah: int, teks: String, label_ya: String, bahaya: bool) -> void :
	layer = 126
	var lapisan: = ColorRect.new()
	lapisan.color = Color(0.03, 0.02, 0.01, 0.6)
	lapisan.set_anchors_preset(Control.PRESET_FULL_RECT)
	lapisan.mouse_filter = Control.MOUSE_FILTER_STOP
	lapisan.add_to_group("lapisan_atas")
	add_child(lapisan)
	var tengah: = CenterContainer.new()
	tengah.set_anchors_preset(Control.PRESET_FULL_RECT)
	tengah.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lapisan.add_child(tengah)
	var panel: = PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	GH.pasang_emas(panel)
	tengah.add_child(panel)
	var isi: = VBoxContainer.new()
	isi.add_theme_constant_override("separation", 14)
	panel.add_child(isi)
	var l_judul: = GH.label(judul, 26, Color.WHITE, true, 0)
	l_judul.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l_judul.custom_minimum_size.x = 520
	l_judul.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	isi.add_child(l_judul)
	if jumlah > 0:
		var l_jumlah: = GH.label(GameState.format_rupiah(jumlah), 40, GH.KUNING, true, 0)
		l_jumlah.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l_jumlah.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
		isi.add_child(l_jumlah)
	if teks != "":
		var l_teks: = GH.label(teks, 19, Color(1, 1, 1, 0.8), false, 0)
		l_teks.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l_teks.custom_minimum_size.x = 520
		l_teks.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		isi.add_child(l_teks)
	var baris: = HBoxContainer.new()
	baris.add_theme_constant_override("separation", 24)
	isi.add_child(baris)
	var batal: = Button.new()
	batal.text = "Batal"
	GH.gaya_tombol_emas(batal, false, 24)
	batal.custom_minimum_size = Vector2(0, 64)
	batal.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	batal.pressed.connect( func(): _jawab(false))
	baris.add_child(batal)
	_ya = Button.new()
	_ya.text = label_ya
	GH.gaya_tombol_emas(_ya, true, 24)
	if bahaya:
		_ya.modulate = Color(1, 0.62, 0.55)
	_ya.custom_minimum_size = Vector2(0, 64)
	_ya.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_ya.disabled = true
	_ya.pressed.connect( func(): _jawab(true))
	baris.add_child(_ya)
	get_tree().create_timer(JEDA_YA, true, false, true).timeout.connect( func():
		if is_instance_valid(_ya):
			_ya.disabled = false)

	lapisan.gui_input.connect( func(e: InputEvent):
		if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT and not e.pressed\
		and not panel.get_global_rect().has_point(e.position):
			_jawab(false))
	panel.scale = Vector2(0.92, 0.92)
	panel.resized.connect( func(): panel.pivot_offset = panel.size / 2.0)
	create_tween().tween_property(panel, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _unhandled_input(event: InputEvent) -> void :
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_jawab(false)


func _notification(what: int) -> void :
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		_jawab(false)


func _jawab(setuju: bool) -> void :
	if _sudah:
		return
	_sudah = true
	GameState.klik()
	queue_free()
	selesai.emit(setuju)
