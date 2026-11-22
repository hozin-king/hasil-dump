extends CanvasLayer





const GH: = preload("res://scripts/gaya_hud.gd")

var dalam_game: = false

var _label_kode: Label
var _salin: Button
var _buat: Button
var _pesan_atas: Label
var _kolom: LineEdit
var _ambil: Button
var _pesan_bawah: Label
var _yakin: = false
var _kode: = ""
var _selesai: = false


func _ready() -> void :
	layer = 96
	process_mode = Node.PROCESS_MODE_ALWAYS
	var lapisan: = ColorRect.new()
	lapisan.color = Color(0.03, 0.02, 0.01, 0.78)
	lapisan.set_anchors_preset(Control.PRESET_FULL_RECT)
	lapisan.mouse_filter = Control.MOUSE_FILTER_STOP
	lapisan.theme = GH.tema_jendela_emas()


	lapisan.add_to_group("lapisan_atas")
	add_child(lapisan)
	var tengah: = CenterContainer.new()
	tengah.set_anchors_preset(Control.PRESET_FULL_RECT)
	lapisan.add_child(tengah)

	var kartu: PanelContainer = GH.panel_emas(Vector4(30, 24, 30, 24))
	kartu.custom_minimum_size = Vector2(680, 0)
	tengah.add_child(kartu)
	var isi: = VBoxContainer.new()
	isi.add_theme_constant_override("separation", 10)
	kartu.add_child(isi)
	var judul: = _label("Pindah HP", 30, GH.KUNING)
	judul.theme_type_variation = &"LabelKepala"
	isi.add_child(judul)

	if OS.get_name() == "iOS":
		isi.add_child(_label("Bawa progres warung dan pembelian (Tanpa Iklan, dukungan, baju) ke HP lain.", 18, Color.WHITE))
	else:
		isi.add_child(_label("Bawa progres warung dan pembelian (Tanpa Iklan, dukungan, baju) ke HP lain, Android maupun iPhone.", 18, Color.WHITE))


	isi.add_child(_label("1. Di HP LAMA", 22, GH.KUNING))
	_label_kode = _label("", 30, GH.HIJAU_UANG)
	_label_kode.hide()
	isi.add_child(_label_kode)
	var baris_atas: = HBoxContainer.new()
	baris_atas.add_theme_constant_override("separation", 12)
	isi.add_child(baris_atas)
	_buat = _tombol("Buat kode pindah", &"TombolHijau")
	_buat.pressed.connect(_buat_kode)
	baris_atas.add_child(_buat)
	_salin = _tombol("Salin kode", &"TombolKayu")
	_salin.hide()
	_salin.pressed.connect( func():
		GameState.klik()
		DisplayServer.clipboard_set(_kode)
		_salin.text = "Sudah disalin")
	baris_atas.add_child(_salin)
	_pesan_atas = _label("", 17, Color(0.9, 0.9, 0.9))
	_pesan_atas.hide()
	isi.add_child(_pesan_atas)


	isi.add_child(_label("2. Di HP BARU", 22, GH.KUNING))
	var baris_bawah: = HBoxContainer.new()
	baris_bawah.add_theme_constant_override("separation", 12)
	isi.add_child(baris_bawah)
	_kolom = LineEdit.new()
	_kolom.placeholder_text = "PH-XXXX-XXXX / W-XXXX-XXXX"
	_kolom.max_length = 16
	_kolom.custom_minimum_size = Vector2(0, 54)
	_kolom.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_kolom.add_theme_font_size_override("font_size", 22)
	_kolom.text_changed.connect( func(_t): _yakin = false)
	baris_bawah.add_child(_kolom)
	_ambil = _tombol("Ambil", &"TombolHijau")
	_ambil.size_flags_horizontal = Control.SIZE_FILL
	_ambil.custom_minimum_size.x = 150
	_ambil.pressed.connect(_ambil_kode)
	baris_bawah.add_child(_ambil)
	_pesan_bawah = _label("", 17, Color(0.9, 0.9, 0.9))
	isi.add_child(_pesan_bawah)
	if dalam_game:


		_kolom.editable = false
		_ambil.disabled = true
		baris_bawah.hide()
		_pesan_bawah.add_theme_color_override("font_color", GH.KUNING)
		_pesan_bawah.add_theme_font_size_override("font_size", 19)
		_pesan_bawah.text = "Mau memasukkan kode di HP ini? Keluar dulu ke menu utama, lalu buka Pengaturan > Pindah HP dari menu utama."
	else:
		_pesan_bawah.text = "Kode pindah (PH-...) berlaku 7 hari untuk satu HP. Kode warung (W-...) dari menu jeda berlaku selamanya."

	var tutup: = _tombol("Tutup", &"TombolKayu")
	tutup.size_flags_horizontal = Control.SIZE_FILL
	tutup.pressed.connect(_tutup)
	isi.add_child(tutup)


func _label(teks: String, ukuran: int, warna: Color) -> Label:
	var l: = Label.new()
	l.text = teks
	l.add_theme_font_size_override("font_size", ukuran)
	l.add_theme_color_override("font_color", warna)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.custom_minimum_size.x = 620
	return l


func _tombol(teks: String, gaya: StringName) -> Button:
	var b: = Button.new()
	b.text = teks
	b.theme_type_variation = gaya
	b.custom_minimum_size = Vector2(0, 56)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.add_theme_font_size_override("font_size", 22)
	return b


func _buat_kode() -> void :
	GameState.klik()
	_buat.disabled = true
	_pesan_atas.text = "Mengunggah progres..."
	_pesan_atas.show()
	var hasil: Dictionary = await GameState.buat_kode_pindah()
	if not is_instance_valid(_buat):
		return
	_buat.disabled = false
	if hasil.has("alasan"):
		_pesan_atas.text = String(hasil["alasan"])
		GameState.bunyi("salah")
		return
	_kode = String(hasil["kode"])
	_label_kode.text = _kode
	_label_kode.show()
	_salin.show()
	_salin.text = "Salin kode"
	_buat.text = "Buat kode baru"
	GameState.bunyi("koin")
	_pesan_atas.text = "Ketik kode ini di HP baru dalam 7 hari. Progres yang dibawa adalah progres saat kode dibuat; kalau masih main di HP ini, buat kode baru sebelum pindah."


func _ambil_kode() -> void :
	GameState.klik()
	if _selesai:
		_tutup()
		return
	if _kolom.text.strip_edges() == "":
		return

	var kode_w: String = GameState.cadangan.rapikan_kode(_kolom.text) if GameState.cadangan != null else ""
	if kode_w != "":
		await _ambil_kode_warung(kode_w)
		return
	var ada: int = GameState.jumlah_slot_terisi()
	if ada > 0 and not _yakin:
		_yakin = true
		_pesan_bawah.text = GameState.tk("HP ini punya %d simpanan. Semuanya akan DIGANTI progres dari HP lama. Tekan Ambil sekali lagi untuk lanjut.") % ada
		_pesan_bawah.add_theme_color_override("font_color", Color(1, 0.7, 0.4))
		return
	_ambil.disabled = true
	_pesan_bawah.text = "Mengambil progres..."
	_pesan_bawah.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	var alasan: String = await GameState.pakai_kode_pindah(_kolom.text)
	if not is_instance_valid(_ambil):
		return
	_ambil.disabled = false
	_yakin = false
	if alasan != "":
		_pesan_bawah.text = alasan
		_pesan_bawah.add_theme_color_override("font_color", Color(1, 0.55, 0.45))
		GameState.bunyi("salah")
		return
	_selesai = true
	GameState.bunyi("hadiah")
	_pesan_bawah.text = "Berhasil! Progres dan pembelian sudah pindah ke HP ini. Jangan main lagi di HP lama supaya tidak bingung."
	_pesan_bawah.add_theme_color_override("font_color", GH.HIJAU_UANG)
	if GameState.info_pindah_iklan != "":
		_pesan_bawah.text = GameState.tk("Progres sudah pindah ke HP ini.") + "\n" + GameState.tk(GameState.info_pindah_iklan)
		_pesan_bawah.add_theme_color_override("font_color", Color(1, 0.8, 0.45))
	_kolom.editable = false
	_ambil.text = "Oke"



func _ambil_kode_warung(kode_w: String) -> void :
	_ambil.disabled = true
	_pesan_bawah.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	if not _yakin:
		_pesan_bawah.text = "Memeriksa kode warung..."
		var info: Dictionary = await GameState.cadangan.lihat(kode_w)
		if not is_instance_valid(_ambil):
			return
		_ambil.disabled = false
		if info.has("pesan"):
			_pesan_bawah.text = String(info["pesan"])
			_pesan_bawah.add_theme_color_override("font_color", Color(1, 0.55, 0.45))
			GameState.bunyi("salah")
			return
		_yakin = true
		var teks: = GameState.tk("Ditemukan: %s, Level %d, hari ke-%d.") % [GameState.cadangan.nama_tampil(String(info.get("nama", ""))), int(info.get("level", 1)), int(info.get("hari", 1))]
		var ada: int = GameState.jumlah_slot_terisi()
		if ada > 0:
			teks += "\n" + GameState.tk("HP ini punya %d simpanan. Semuanya akan DIGANTI warung ini.") % ada
		teks += "\n" + GameState.tk("Tekan Ambil sekali lagi untuk memulihkan.")
		_pesan_bawah.text = teks
		_pesan_bawah.add_theme_color_override("font_color", Color(1, 0.8, 0.45))
		return
	_pesan_bawah.text = "Memulihkan warung..."
	var alasan: String = await GameState.cadangan.pulihkan(kode_w)
	if not is_instance_valid(_ambil):
		return
	_ambil.disabled = false
	_yakin = false
	if alasan != "":
		_pesan_bawah.text = alasan
		_pesan_bawah.add_theme_color_override("font_color", Color(1, 0.55, 0.45))
		GameState.bunyi("salah")
		return
	_selesai = true
	GameState.bunyi("hadiah")
	_pesan_bawah.text = "Berhasil! Warungmu sudah kembali di HP ini."
	_pesan_bawah.add_theme_color_override("font_color", GH.HIJAU_UANG)
	if GameState.info_pindah_iklan != "":
		_pesan_bawah.text = GameState.tk("Warungmu sudah kembali di HP ini.") + "\n" + GameState.tk(GameState.info_pindah_iklan)
		_pesan_bawah.add_theme_color_override("font_color", Color(1, 0.8, 0.45))
	_kolom.editable = false
	_ambil.text = "Oke"


func _tutup() -> void :
	GameState.klik()
	var muat_ulang: = _selesai
	queue_free()

	if muat_ulang and GameState.get_tree().current_scene != null:
		GameState.get_tree().reload_current_scene()
