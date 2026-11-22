extends Control






signal ditutup

const GH: = preload("res://scripts/gaya_hud.gd")
const KREM: = Color(1.0, 0.97, 0.88)
const COKLAT: = Color(0.36, 0.2, 0.08)
const COKLAT_REDUP: = Color(0.45, 0.3, 0.18, 0.85)
const ORANYE: = Color(1.0, 0.55, 0.12)
const KUNING_CERAH: = Color(1.0, 0.86, 0.35)
const HIJAU_MUDA: = Color(0.74, 0.92, 0.66)
const HIJAU: = Color(0.2, 0.66, 0.28)
const MERAH: = Color(0.8, 0.22, 0.15)

var hari_ke: = 1
var mode: = "ambil"
var _tombol_ambil: Button
var _tombol_nanti: Button
var _ket: Label
var _kotak: = {}
var _sedang: = false
var _selesai: = false


static func _kotak_gaya(warna: Color, radius: int, tepi: = 0, warna_tepi: = Color.TRANSPARENT, bawah: = 0) -> StyleBoxFlat:
	var sb: = StyleBoxFlat.new()
	sb.bg_color = warna
	sb.set_corner_radius_all(radius)
	sb.set_border_width_all(tepi)
	sb.border_color = warna_tepi
	if bawah > 0:
		sb.border_width_bottom = tepi + bawah
	sb.content_margin_left = 4
	sb.content_margin_right = 4
	sb.content_margin_top = 4
	sb.content_margin_bottom = 4
	return sb


func _teks(teks: String, ukuran: int, warna: Color, besar: = false) -> Label:
	var l: = Label.new()
	l.text = teks
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.add_theme_font_override("font", GH.cetak() if besar else GH.font("Nunito", 800))
	l.add_theme_font_size_override("font_size", GH.ukuran_cetak(ukuran) if besar else ukuran)
	l.add_theme_color_override("font_color", warna)
	l.add_theme_constant_override("outline_size", 0)
	return l


func _ready() -> void :
	theme = GH.tema_jendela_emas()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 120
	add_to_group("lapisan_atas")
	var latar: = ColorRect.new()
	latar.color = Color(0.05, 0.04, 0.02, 0.55)
	latar.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	latar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(latar)
	var tengah: = CenterContainer.new()
	tengah.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tengah.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(tengah)
	var kartu: = PanelContainer.new()
	var gaya: = _kotak_gaya(KREM, 26, 6, ORANYE, 4)
	gaya.content_margin_left = 24
	gaya.content_margin_right = 24
	gaya.content_margin_top = 12
	gaya.content_margin_bottom = 16
	gaya.shadow_color = Color(0, 0, 0, 0.35)
	gaya.shadow_size = 18
	kartu.add_theme_stylebox_override("panel", gaya)
	kartu.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tengah.add_child(kartu)
	var kolom: = VBoxContainer.new()
	kolom.add_theme_constant_override("separation", 8)
	kartu.add_child(kolom)

	var pita: = PanelContainer.new()
	var gp: = _kotak_gaya(ORANYE, 18)
	gp.content_margin_left = 30
	gp.content_margin_right = 30
	pita.add_theme_stylebox_override("panel", gp)
	pita.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	pita.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pita.add_child(_teks("Kalender Hadiah", 34, Color.WHITE, true))
	kolom.add_child(pita)
	kolom.add_child(_teks("Absen sekali sehari dapat Rp15.000. Setiap 4 hari hadiah besar, akhir bulan baju baru!", 18, COKLAT))
	var layar: = get_viewport_rect().size
	var sel: = Vector2(clampf((layar.x - 160.0) / 6.0 - 6.0, 104.0, 132.0), clampf((layar.y - 262.0) / 5.0 - 6.0, 58.0, 70.0))
	var kisi: = GridContainer.new()
	kisi.columns = 6
	kisi.add_theme_constant_override("h_separation", 6)
	kisi.add_theme_constant_override("v_separation", 6)
	kisi.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	kolom.add_child(kisi)
	for n in range(1, GameState.login_harian.PANJANG + 1):
		var k: = _kotak_hari(n, sel)
		kisi.add_child(k)
		_kotak[n] = k
	_ket = _teks("Butuh internet untuk absen. Hari yang terlewat tidak mengulang kalender.", 16, COKLAT_REDUP)
	_ket.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_ket.custom_minimum_size.x = sel.x * 6 + 30
	kolom.add_child(_ket)
	var tombol: = HBoxContainer.new()
	tombol.alignment = BoxContainer.ALIGNMENT_CENTER
	tombol.add_theme_constant_override("separation", 16)
	kolom.add_child(tombol)
	_tombol_nanti = Button.new()
	_tombol_nanti.text = "Nanti"
	_tombol_nanti.theme_type_variation = &"TombolKayu"
	_tombol_nanti.focus_mode = Control.FOCUS_NONE
	_tombol_nanti.custom_minimum_size = Vector2(170, 58)
	_tombol_nanti.add_theme_font_size_override("font_size", 22)
	_tombol_nanti.pressed.connect( func():
		if not _selesai:
			GameState.login_harian.tunda()
		_tutup())
	tombol.add_child(_tombol_nanti)
	_tombol_ambil = Button.new()
	var h: Dictionary = GameState.login_harian.hadiah(hari_ke)
	_tombol_ambil.text = tr("Ambil %s") % String(h["teks"])
	_tombol_ambil.theme_type_variation = &"TombolHijau"
	_tombol_ambil.focus_mode = Control.FOCUS_NONE
	_tombol_ambil.custom_minimum_size = Vector2(320, 58)
	_tombol_ambil.add_theme_font_size_override("font_size", 23)
	_tombol_ambil.pressed.connect(_ambil)
	tombol.add_child(_tombol_ambil)
	if mode != "ambil":
		_tombol_ambil.hide()
		_tombol_nanti.text = "Tutup"
		_tombol_nanti.theme_type_variation = &"TombolHijau"
		_selesai = true
		match mode:
			"sudah":
				_ket.text = tr("Hari ini sudah absen. Kembali besok untuk hari ke-%d.") % hari_ke
			"selesai":
				_ket.text = tr("Kalender hadiah selesai. Terima kasih sudah main setiap hari!")
			"offline":
				_ket.text = tr("Tidak ada internet. Sambungkan internet, lalu buka aplikasi Hadiah lagi untuk absen.")
				_ket.add_theme_color_override("font_color", MERAH)
			"tutorial":
				_ket.text = tr("Kalender hadiah mulai sesudah tutorial selesai.")
	modulate.a = 0.0
	kartu.pivot_offset = kartu.get_combined_minimum_size() / 2.0
	kartu.scale = Vector2(0.94, 0.94)
	var tw: = create_tween().set_parallel()
	tw.tween_property(self, "modulate:a", 1.0, 0.2)
	tw.tween_property(kartu, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _gaya_kotak(n: int, sudah: bool) -> StyleBoxFlat:
	var ada: = bool(GameState.login_harian.hadiah(n)["besar"])
	if sudah:
		return _kotak_gaya(HIJAU_MUDA, 12, 2, HIJAU, 2)
	if n == hari_ke:
		return _kotak_gaya(Color(1, 0.93, 0.7) if not ada else KUNING_CERAH, 12, 4, ORANYE, 3)
	if ada:
		return _kotak_gaya(KUNING_CERAH, 12, 2, Color(0.9, 0.62, 0.1), 3)
	return _kotak_gaya(Color.WHITE, 12, 2, Color(0.9, 0.82, 0.66), 2)


func _kotak_hari(n: int, sel: Vector2) -> Control:
	var h: Dictionary = GameState.login_harian.hadiah(n)
	var ada: = bool(h["besar"])
	var sudah: = n < hari_ke or mode == "selesai"
	var p: = PanelContainer.new()
	p.add_theme_stylebox_override("panel", _gaya_kotak(n, sudah))
	p.custom_minimum_size = sel
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var v: = VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", -2)
	p.add_child(v)
	v.add_child(_teks(str(n), 22, MERAH if ada else COKLAT, true))
	var isi: = _teks(String(h["teks"]), 14 if ada else 12, COKLAT if ada else COKLAT_REDUP)
	isi.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	isi.custom_minimum_size.x = sel.x - 8
	v.add_child(isi)
	if n == hari_ke and mode != "selesai":
		v.add_child(_teks("HARI INI" if mode == "ambil" else ("BESOK" if mode == "sudah" else "BERIKUTNYA"), 13, ORANYE, true))

	var centang: = Control.new()
	centang.mouse_filter = Control.MOUSE_FILTER_IGNORE
	centang.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	centang.draw.connect( func():
		var r: = minf(centang.size.x, centang.size.y) * 0.24
		var c: = Vector2(centang.size.x - r - 2, r + 2)
		centang.draw_circle(c, r, HIJAU)
		centang.draw_polyline(PackedVector2Array([c + Vector2( - r * 0.5, 0), c + Vector2( - r * 0.12, r * 0.4), c + Vector2(r * 0.55, - r * 0.42)]), Color.WHITE, maxf(2.5, r * 0.3), true))
	centang.visible = sudah
	p.add_child(centang)
	p.set_meta("centang", centang)
	return p


func _ambil() -> void :
	if _sedang or _selesai:
		return
	_sedang = true
	GameState.klik()
	_tombol_ambil.disabled = true
	_tombol_nanti.disabled = true
	_ket.text = tr("Memeriksa tanggal lewat internet...")
	_ket.add_theme_color_override("font_color", COKLAT_REDUP)
	var hasil: Dictionary = await GameState.login_harian.ambil(hari_ke)
	_sedang = false
	if not is_inside_tree():
		return
	if not bool(hasil.get("ok", false)):
		GameState.bunyi("salah")
		match String(hasil.get("alasan", "")):
			"internet":
				_ket.text = tr("Tidak ada internet. Sambungkan internet lalu ketuk lagi. Hadiahnya tetap menunggu hari ini.")
			"sudah":
				_ket.text = tr("Hari ini sudah absen. Kembali lagi besok, ya.")
				_tombol_ambil.hide()
			_:
				_ket.text = tr("Belum bisa absen sekarang. Coba lagi sebentar lagi.")
		_ket.add_theme_color_override("font_color", MERAH)
		_tombol_ambil.disabled = false
		_tombol_nanti.disabled = false
		return
	_selesai = true
	var teks: = String(hasil.get("teks", ""))
	GameState.bunyi("hadiah")
	var kotak: PanelContainer = _kotak[hari_ke]
	kotak.add_theme_stylebox_override("panel", _gaya_kotak(hari_ke, true))
	var centang: Control = kotak.get_meta("centang")
	centang.show()
	centang.pivot_offset = centang.size - Vector2(20, centang.size.y - 20)
	centang.scale = Vector2(0.3, 0.3)
	create_tween().tween_property(centang, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	var berikut: = 0
	for k in GameState.login_harian.HADIAH:
		if int(k) > hari_ke and (berikut == 0 or int(k) < berikut):
			berikut = int(k)
	var lagi: = (" " + tr("Hadiah besar berikutnya di hari ke-%d.") % berikut) if berikut > 0 else (" " + tr("Kalender hadiah selesai. Terima kasih sudah main setiap hari!"))
	if teks == tr("Tanpa Iklan 1 hari"):
		_ket.text = tr("Kamu dapat Tanpa Iklan 1 hari! Selama 24 jam, hadiah iklan langsung didapat tanpa menonton.") + lagi
	elif teks == tr("Baju Kaos & sarung"):
		_ket.text = tr("Kamu dapat baju Kaos & sarung! Pakai lewat lemari baju di kamar.") + lagi
	else:
		_ket.text = tr("Kamu dapat %s!") % teks + lagi
	_ket.add_theme_color_override("font_color", HIJAU)
	_tombol_ambil.hide()
	_tombol_nanti.text = "Oke"
	_tombol_nanti.theme_type_variation = &"TombolHijau"
	_tombol_nanti.disabled = false


func _unhandled_input(e: InputEvent) -> void :
	if e.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		if not _tombol_nanti.disabled:
			_tombol_nanti.pressed.emit()


func _tutup() -> void :
	GameState.klik()
	ditutup.emit()
	queue_free()
