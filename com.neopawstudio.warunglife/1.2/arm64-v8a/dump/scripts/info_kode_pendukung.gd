extends CanvasLayer




const GH: = preload("res://scripts/gaya_hud.gd")

var kode: = ""


func _ready() -> void :
	layer = 95
	process_mode = Node.PROCESS_MODE_ALWAYS
	var lapisan: = ColorRect.new()
	lapisan.color = Color(0.03, 0.02, 0.01, 0.7)
	lapisan.set_anchors_preset(Control.PRESET_FULL_RECT)
	lapisan.mouse_filter = Control.MOUSE_FILTER_STOP
	lapisan.theme = GH.tema_jendela_emas()
	add_child(lapisan)
	var tengah: = CenterContainer.new()
	tengah.set_anchors_preset(Control.PRESET_FULL_RECT)
	lapisan.add_child(tengah)
	var kartu: = PanelContainer.new()
	kartu.add_theme_stylebox_override("panel", GH.bingkai_emas())
	kartu.custom_minimum_size = Vector2(600, 0)
	tengah.add_child(kartu)
	var isi: = VBoxContainer.new()
	isi.add_theme_constant_override("separation", 14)
	kartu.add_child(isi)
	var judul: = Label.new()
	judul.text = "Terima kasih sudah mendukung!"
	judul.theme_type_variation = &"LabelKepala"
	judul.add_theme_font_size_override("font_size", 30)
	judul.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	isi.add_child(judul)
	var label_kode: = Label.new()
	label_kode.text = GameState.tk("Kode pendukungmu: %s") % kode
	label_kode.add_theme_font_size_override("font_size", 26)
	label_kode.add_theme_color_override("font_color", GH.KUNING)
	label_kode.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	isi.add_child(label_kode)
	var ket: = Label.new()
	ket.text = "Simpan kode ini. Kalau pindah HP atau pasang ulang game, masukkan kodenya di Dukung Kami."
	ket.add_theme_font_size_override("font_size", 19)
	ket.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ket.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ket.custom_minimum_size.x = 560
	isi.add_child(ket)
	var baris: = HBoxContainer.new()
	baris.add_theme_constant_override("separation", 12)
	isi.add_child(baris)
	var salin: = Button.new()
	salin.text = "Salin kode"
	salin.theme_type_variation = &"TombolKayu"
	salin.custom_minimum_size = Vector2(0, 58)
	salin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	salin.add_theme_font_size_override("font_size", 22)
	salin.pressed.connect( func():
		GameState.klik()
		DisplayServer.clipboard_set(kode)
		salin.text = "Sudah disalin")
	baris.add_child(salin)
	var oke: = Button.new()
	oke.text = "Oke"
	oke.theme_type_variation = &"TombolHijau"
	oke.custom_minimum_size = Vector2(0, 58)
	oke.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	oke.add_theme_font_size_override("font_size", 22)
	oke.pressed.connect( func():
		GameState.klik()
		queue_free())
	baris.add_child(oke)
