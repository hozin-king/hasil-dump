extends CanvasLayer





const GH: = preload("res://scripts/gaya_hud.gd")


func _ready() -> void :
	layer = 95
	process_mode = Node.PROCESS_MODE_ALWAYS
	GameState.akun.tandai_ajak()
	var lapisan: = ColorRect.new()
	lapisan.color = Color(0.03, 0.02, 0.01, 0.7)
	lapisan.set_anchors_preset(Control.PRESET_FULL_RECT)
	lapisan.mouse_filter = Control.MOUSE_FILTER_STOP
	lapisan.theme = GH.tema_jendela_emas()
	lapisan.add_to_group("lapisan_atas")
	add_child(lapisan)
	var tengah: = CenterContainer.new()
	tengah.set_anchors_preset(Control.PRESET_FULL_RECT)
	lapisan.add_child(tengah)
	var kartu: PanelContainer = GH.panel_emas(Vector4(32, 26, 32, 26))
	kartu.custom_minimum_size = Vector2(560, 0)
	tengah.add_child(kartu)
	var isi: = VBoxContainer.new()
	isi.add_theme_constant_override("separation", 14)
	kartu.add_child(isi)
	var judul: = _label("Amankan warungmu!", 32, GH.KUNING)
	judul.theme_type_variation = &"LabelKepala"
	isi.add_child(judul)

	var ios: = OS.get_name() == "iOS"
	isi.add_child(_label("Tautkan akun supaya simpanan warung tidak hilang walau HP rusak atau ganti HP." if ios
		else "Tautkan akun Google supaya simpanan warung tidak hilang walau HP rusak atau ganti HP.", 20, Color.WHITE))
	isi.add_child(_label("Bonus Rp100.000", 28, GH.HIJAU_UANG))
	var masuk: = _tombol("Tautkan akun" if ios else "Tautkan akun Google", &"TombolHijau", 24, 66)
	masuk.pressed.connect( func():
		GameState.klik()
		var jendela: CanvasLayer = load("res://scripts/akun_tautan.gd").new()
		jendela.mulai_masuk = true
		get_tree().root.add_child(jendela)
		queue_free())
	isi.add_child(masuk)
	var nanti: = _tombol("Nanti saja", &"TombolKayu", 20, 52)
	nanti.pressed.connect( func():
		GameState.klik()
		queue_free())
	isi.add_child(nanti)
	isi.add_child(_label("Bisa juga kapan saja lewat Pengaturan > Tautkan akun.", 16, Color(0.8, 0.8, 0.8)))


func _label(teks: String, ukuran: int, warna: Color) -> Label:
	var l: = Label.new()
	l.text = teks
	l.add_theme_font_size_override("font_size", ukuran)
	l.add_theme_color_override("font_color", warna)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.custom_minimum_size.x = 500
	return l


func _tombol(teks: String, gaya: StringName, ukuran: int, tinggi: int) -> Button:
	var b: = Button.new()
	b.text = teks
	b.theme_type_variation = gaya
	b.custom_minimum_size = Vector2(0, tinggi)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.add_theme_font_size_override("font_size", ukuran)
	return b
