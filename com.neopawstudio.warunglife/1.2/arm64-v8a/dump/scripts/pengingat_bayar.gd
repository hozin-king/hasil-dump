extends CanvasLayer






const LAMA: = 11.0

var _kartu: PanelContainer


func isi(judul: String, teks: String, warna_judul: = Color(1.0, 0.82, 0.4)) -> void :
	layer = 96
	process_mode = Node.PROCESS_MODE_ALWAYS
	var akar: = Control.new()
	akar.theme = load("res://scripts/gaya_hud.gd").tema_jendela()
	akar.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	akar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(akar)
	_kartu = PanelContainer.new()

	var gaya: = StyleBoxFlat.new()
	gaya.bg_color = Color(0.09, 0.065, 0.045, 0.97)
	gaya.border_color = Color(1.0, 0.8, 0.45, 0.85)
	gaya.set_border_width_all(2)
	gaya.set_corner_radius_all(18)
	gaya.content_margin_left = 24
	gaya.content_margin_right = 24
	gaya.content_margin_top = 14
	gaya.content_margin_bottom = 12
	_kartu.add_theme_stylebox_override("panel", gaya)
	_kartu.anchor_left = 0.5
	_kartu.anchor_right = 0.5
	_kartu.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_kartu.offset_top = 18
	_kartu.custom_minimum_size = Vector2(640, 0)
	_kartu.mouse_filter = Control.MOUSE_FILTER_STOP
	_kartu.gui_input.connect( func(e: InputEvent):
		if e is InputEventMouseButton and e.pressed:
			tutup())
	akar.add_child(_kartu)
	var isi_kartu: = VBoxContainer.new()
	isi_kartu.add_theme_constant_override("separation", 6)
	_kartu.add_child(isi_kartu)
	var l_judul: = Label.new()
	l_judul.text = judul
	l_judul.add_theme_font_size_override("font_size", 22)
	l_judul.add_theme_color_override("font_color", warna_judul)
	l_judul.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	isi_kartu.add_child(l_judul)
	var l_teks: = Label.new()
	l_teks.text = teks
	l_teks.add_theme_font_size_override("font_size", 18)
	l_teks.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l_teks.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l_teks.custom_minimum_size.x = 600
	isi_kartu.add_child(l_teks)
	var l_tutup: = Label.new()
	l_tutup.text = "(ketuk untuk menutup)"
	l_tutup.add_theme_font_size_override("font_size", 14)
	l_tutup.add_theme_color_override("font_color", Color(1, 1, 1, 0.55))
	l_tutup.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	isi_kartu.add_child(l_tutup)
	_kartu.modulate.a = 0.0



func _ready() -> void :
	if _kartu == null:
		return
	create_tween().tween_property(_kartu, "modulate:a", 1.0, 0.3)
	GameState.get_tree().create_timer(LAMA, true, false, true).timeout.connect(tutup)


func tutup() -> void :
	if _kartu == null or not is_instance_valid(_kartu) or is_queued_for_deletion():
		return
	var tw: = create_tween()
	tw.tween_property(_kartu, "modulate:a", 0.0, 0.3)
	tw.tween_callback(queue_free)
	_kartu = null
