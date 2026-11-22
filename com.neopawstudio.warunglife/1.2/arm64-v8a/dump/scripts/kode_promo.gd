extends CanvasLayer




const GH: = preload("res://scripts/gaya_hud.gd")

var _kolom: LineEdit
var _pesan: Label
var _pakai: Button


func _ready() -> void :
	layer = 96
	process_mode = Node.PROCESS_MODE_ALWAYS
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

	var kartu: PanelContainer = GH.panel_emas(Vector4(30, 24, 30, 24))
	kartu.custom_minimum_size = Vector2(600, 0)
	tengah.add_child(kartu)
	var isi: = VBoxContainer.new()
	isi.add_theme_constant_override("separation", 14)
	kartu.add_child(isi)
	var judul: = Label.new()
	judul.text = "Kode promo"
	judul.theme_type_variation = &"LabelKepala"
	judul.add_theme_font_size_override("font_size", 30)
	judul.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	isi.add_child(judul)
	var ket: = Label.new()
	ket.text = "Punya kode dari NeoPaw Studio? Ketik di sini untuk mendapat hadiahnya."
	ket.add_theme_font_size_override("font_size", 19)
	ket.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ket.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ket.custom_minimum_size.x = 560
	isi.add_child(ket)
	var baris: = HBoxContainer.new()
	baris.add_theme_constant_override("separation", 12)
	isi.add_child(baris)
	_kolom = LineEdit.new()
	_kolom.placeholder_text = "KODE PROMO"
	_kolom.max_length = 40
	_kolom.custom_minimum_size = Vector2(0, 54)
	_kolom.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_kolom.add_theme_font_size_override("font_size", 22)
	_kolom.text_submitted.connect( func(_t): _pakai_kode())
	baris.add_child(_kolom)
	_pakai = Button.new()
	_pakai.text = "Pakai"
	_pakai.theme_type_variation = &"TombolHijau"
	_pakai.custom_minimum_size = Vector2(150, 54)
	_pakai.add_theme_font_size_override("font_size", 22)
	_pakai.pressed.connect(_pakai_kode)
	baris.add_child(_pakai)
	_pesan = Label.new()
	_pesan.add_theme_font_size_override("font_size", 19)
	_pesan.add_theme_color_override("font_color", GH.KUNING)
	_pesan.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_pesan.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_pesan.custom_minimum_size.x = 560
	_pesan.hide()
	isi.add_child(_pesan)
	var tutup: = Button.new()
	tutup.text = "Tutup"
	tutup.theme_type_variation = &"TombolKayu"
	tutup.custom_minimum_size = Vector2(0, 56)
	tutup.add_theme_font_size_override("font_size", 22)
	tutup.pressed.connect( func():
		GameState.klik()
		queue_free())
	isi.add_child(tutup)
	GameState.pesan_toko.connect(_on_pesan_toko)


func _on_pesan_toko(teks: String) -> void :
	if is_instance_valid(_pesan):
		_pesan.text = teks
		_pesan.add_theme_color_override("font_color", GH.HIJAU_UANG)
		_pesan.show()


func _pakai_kode() -> void :
	GameState.klik()
	if _kolom.text.strip_edges() == "":
		return
	_pakai.disabled = true
	_pesan.text = "Memeriksa kode..."
	_pesan.add_theme_color_override("font_color", GH.KUNING)
	_pesan.show()
	var alasan: String = await GameState.pakai_kode_promo(_kolom.text)
	if not is_instance_valid(_pakai):
		return
	_pakai.disabled = false
	if alasan != "":
		_pesan.text = alasan
		_pesan.add_theme_color_override("font_color", Color(1, 0.55, 0.45))
		GameState.bunyi("salah")
	else:
		_kolom.text = ""
