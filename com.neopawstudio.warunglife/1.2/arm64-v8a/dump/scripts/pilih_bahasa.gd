extends Control






signal dipilih(kode: String)

const PILIHAN: = [["id", "Bahasa Indonesia", "Main dalam Bahasa Indonesia"], ["en", "English", "Play in English"]]


func _ready() -> void :
	theme = load("res://scripts/gaya_hud.gd").tema_jendela()
	auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var latar: = ColorRect.new()
	latar.color = Color(0.06, 0.05, 0.04)
	latar.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	latar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(latar)
	var tengah: = CenterContainer.new()
	tengah.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(tengah)
	var panel: = PanelContainer.new()
	tengah.add_child(panel)
	var tepi: = MarginContainer.new()
	for sisi in ["left", "right", "top", "bottom"]:
		tepi.add_theme_constant_override("margin_" + sisi, 36)
	panel.add_child(tepi)
	var kolom: = VBoxContainer.new()
	kolom.add_theme_constant_override("separation", 18)
	tepi.add_child(kolom)
	var judul: = Label.new()
	judul.text = "Pilih Bahasa  ·  Choose Language"
	judul.theme_type_variation = &"LabelKepala"
	judul.add_theme_font_size_override("font_size", 34)
	judul.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	kolom.add_child(judul)
	var saran: = GameState.bahasa_perangkat()
	var urut: Array = PILIHAN.duplicate()
	if saran == "en":
		urut.reverse()
	for p in urut:
		var b: = Button.new()
		b.text = String(p[1])
		b.theme_type_variation = &"TombolHijau" if p[0] == saran else &"TombolKayu"
		b.custom_minimum_size = Vector2(460, 76)
		b.add_theme_font_size_override("font_size", 32)
		var kode: String = p[0]
		b.pressed.connect( func(): _pilih(kode))
		kolom.add_child(b)
		var ket: = Label.new()
		ket.text = String(p[2])
		ket.add_theme_font_size_override("font_size", 18)
		ket.modulate = Color(1, 1, 1, 0.7)
		ket.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		kolom.add_child(ket)
	var catatan: = Label.new()
	catatan.text = "Bisa diganti di Pengaturan  ·  You can change this in Settings"
	catatan.add_theme_font_size_override("font_size", 16)
	catatan.modulate = Color(1, 1, 1, 0.55)
	catatan.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	kolom.add_child(catatan)


func _pilih(kode: String) -> void :
	GameState.atur_bahasa(kode)
	dipilih.emit(kode)
	queue_free()
