extends CanvasLayer





const GH: = preload("res://scripts/gaya_hud.gd")

signal selesai(berhasil: bool)

var _kolom: LineEdit
var _pesan: Label
var _tombol: Button
var _sibuk: = false


func _ready() -> void :
	layer = 125
	process_mode = Node.PROCESS_MODE_ALWAYS
	var lapisan: = ColorRect.new()
	lapisan.color = Color(0.03, 0.02, 0.01, 0.6)
	lapisan.set_anchors_preset(Control.PRESET_FULL_RECT)
	lapisan.mouse_filter = Control.MOUSE_FILTER_STOP
	lapisan.theme = preload("res://scripts/tema_tenang.gd").tema_emas()
	lapisan.add_to_group("lapisan_atas")
	add_child(lapisan)
	var panel: = PanelContainer.new()
	panel.custom_minimum_size = Vector2(520, 0)
	lapisan.add_child(panel)
	var isi: = VBoxContainer.new()
	isi.add_theme_constant_override("separation", 10)
	panel.add_child(isi)
	var judul: = Label.new()
	judul.text = "Ganti nama warung"
	judul.theme_type_variation = &"LabelKepala"
	judul.add_theme_font_size_override("font_size", 30)
	judul.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	isi.add_child(judul)
	var ket: = Label.new()
	ket.text = "Sekarang: %s\n%s" % [GameState.nama_warung_lengkap(), 
		"Ganti nama pertama GRATIS." if GameState.ganti_nama_gratis() else "Ganti nama berikutnya: tonton 1 iklan dulu."]
	ket.add_theme_font_size_override("font_size", 18)
	ket.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	isi.add_child(ket)
	_kolom = LineEdit.new()
	_kolom.max_length = GameState.MAKS_NAMA_WARUNG
	_kolom.placeholder_text = "nama baru (maks. %d huruf)" % GameState.MAKS_NAMA_WARUNG
	_kolom.alignment = HORIZONTAL_ALIGNMENT_CENTER
	_kolom.custom_minimum_size = Vector2(0, 58)
	_kolom.add_theme_font_size_override("font_size", 26)
	_kolom.text_submitted.connect( func(_t): _simpan())
	isi.add_child(_kolom)
	_pesan = Label.new()
	_pesan.add_theme_font_size_override("font_size", 17)
	_pesan.add_theme_color_override("font_color", Color(1, 0.55, 0.5))
	_pesan.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_pesan.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	isi.add_child(_pesan)
	var baris: = HBoxContainer.new()
	baris.add_theme_constant_override("separation", 12)
	isi.add_child(baris)
	var batal: = Button.new()
	batal.text = "Batal"
	batal.theme_type_variation = &"TombolKayu"
	batal.custom_minimum_size = Vector2(0, 58)
	batal.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	batal.add_theme_font_size_override("font_size", 22)
	batal.pressed.connect( func(): _tutup(false))
	baris.add_child(batal)
	_tombol = Button.new()
	_tombol.text = "Simpan" if GameState.ganti_nama_gratis() else ("Simpan" if GameState.tanpa_iklan else "Tonton iklan & simpan")
	_tombol.theme_type_variation = &"TombolUtama"
	_tombol.custom_minimum_size = Vector2(0, 58)
	_tombol.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_tombol.add_theme_font_size_override("font_size", 22)
	_tombol.pressed.connect(_simpan)
	baris.add_child(_tombol)
	panel.reset_size()

	var layar: = get_viewport().get_visible_rect().size
	panel.position = Vector2((layar.x - panel.size.x) / 2.0, 16)
	_kolom.grab_focus()


func _simpan() -> void :
	if _sibuk:
		return
	var alasan: = GameState.cek_nama_warung_baru(_kolom.text)
	if alasan != "":
		GameState.bunyi("salah")
		_pesan.text = alasan
		return
	if not GameState.ganti_nama_gratis():
		_sibuk = true
		_tombol.disabled = true
		_pesan.text = ""
		var ok: bool = await GameState.tonton_iklan(self)
		_sibuk = false
		if not is_instance_valid(_tombol):
			return
		_tombol.disabled = false
		if not ok:
			_pesan.text = "Iklan belum selesai, nama belum diganti. Coba lagi, ya."
			return
	alasan = GameState.ganti_nama_warung(_kolom.text)
	if alasan != "":
		_pesan.text = alasan
		return
	GameState.bunyi("hadiah")
	var adegan: = get_tree().current_scene
	if adegan != null and adegan.has_method("perbarui_nama_warung"):
		adegan.perbarui_nama_warung()
	_tutup(true)


func _tutup(berhasil: bool) -> void :
	selesai.emit(berhasil)
	queue_free()
