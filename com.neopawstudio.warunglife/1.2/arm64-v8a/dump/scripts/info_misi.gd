extends Control





signal ditutup

const GH: = preload("res://scripts/gaya_hud.gd")
const UKURAN_PETA: = Vector2(470, 300)
const MERAH: = Color(0.93, 0.2, 0.17)
const BIRU: = Color(0.26, 0.56, 0.98)

var _peta: Control
var _tekstur: Texture2D
var _titik: Array = []
var _saya: = Vector2(-1, -1)
var _kelompok: Array = []
var _i: = 0
var _label_temui: Label
var _label_tempat: Label
var _label_bawah: Label
var _tombol_lain: Button
var _kotak_nama: Array = []
var _denyut: = 0.0
var _menutup: = false



func isi(d: Dictionary) -> void :
	theme = GH.tema_jendela_emas()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 200
	add_to_group("lapisan_atas")
	_kelompok = d.get("kelompok", [])
	var gelap: = ColorRect.new()
	gelap.color = Color(0.03, 0.02, 0.01, 0.62)
	gelap.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	gelap.gui_input.connect( func(e: InputEvent):
		if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT and not e.pressed:
			_tutup())
	add_child(gelap)
	var tengah: = CenterContainer.new()
	tengah.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tengah.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(tengah)
	var panel: = PanelContainer.new()
	tengah.add_child(panel)
	var kolom: = VBoxContainer.new()
	kolom.add_theme_constant_override("separation", 12)
	panel.add_child(kolom)
	var judul: = Label.new()
	judul.text = String(d.get("judul", ""))
	judul.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	GH.gaya_jendela(panel, judul)
	kolom.add_child(judul)
	var baris: = HBoxContainer.new()
	baris.add_theme_constant_override("separation", 18)
	kolom.add_child(baris)
	baris.add_child(_buat_peta())
	baris.add_child(_buat_keterangan(d))
	var bawah: = HBoxContainer.new()
	bawah.add_theme_constant_override("separation", 14)
	bawah.alignment = BoxContainer.ALIGNMENT_CENTER
	kolom.add_child(bawah)
	if _kelompok.size() > 1:
		_tombol_lain = Button.new()
		GH.gaya_tombol_emas(_tombol_lain, false, 22)
		_tombol_lain.custom_minimum_size = Vector2(260, 56)
		_tombol_lain.pressed.connect(_berikutnya)
		bawah.add_child(_tombol_lain)
	var tutup: = Button.new()
	tutup.text = "Tutup"
	GH.gaya_tombol_emas(tutup, true, 24)
	tutup.custom_minimum_size = Vector2(200, 56)
	tutup.pressed.connect(_tutup)
	bawah.add_child(tutup)
	_tampilkan(0)
	GameState.klik()


func _tampilkan(i: int) -> void :
	if _kelompok.is_empty():
		return
	_i = posmod(i, _kelompok.size())
	var k: Dictionary = _kelompok[_i]
	_titik = k.get("titik", [])
	_saya = k.get("saya", Vector2(-1, -1))
	var gambar: = String(k.get("gambar", ""))
	_tekstur = load(gambar) if gambar != "" and ResourceLoader.exists(gambar) else null
	_label_temui.text = ", ".join(k.get("nama", []))
	_label_tempat.text = String(k.get("tempat", ""))
	_label_bawah.text = String(k.get("tempat", ""))
	if _tombol_lain != null:
		_tombol_lain.text = "Tempat lain (%d/%d)" % [_i + 1, _kelompok.size()]


func _berikutnya() -> void :
	GameState.klik()
	_tampilkan(_i + 1)


func _buat_peta() -> Control:
	var kiri: = VBoxContainer.new()
	kiri.add_theme_constant_override("separation", 6)
	_peta = Control.new()
	_peta.custom_minimum_size = UKURAN_PETA
	_peta.clip_contents = true
	_peta.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_peta.draw.connect(_gambar_peta)
	kiri.add_child(_peta)
	_label_bawah = GH.label("", 18, GH.EMAS_MUDA, false, 2)
	_label_bawah.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label_bawah.custom_minimum_size.x = UKURAN_PETA.x
	kiri.add_child(_label_bawah)
	return kiri


func _buat_keterangan(d: Dictionary) -> Control:
	var kanan: = VBoxContainer.new()
	kanan.add_theme_constant_override("separation", 7)
	kanan.custom_minimum_size.x = 430
	kanan.alignment = BoxContainer.ALIGNMENT_CENTER
	_baris(kanan, "Tugas", String(d.get("tugas", "")))
	_label_temui = _baris(kanan, "Temui", "-")
	_label_tempat = _baris(kanan, "Tempat", "-")
	_baris(kanan, "Hari", String(d.get("hari", "")))
	_baris(kanan, "Jam", String(d.get("jam", "")))
	if String(d.get("syarat", "")) != "":
		kanan.add_child(_teks(String(d["syarat"]), 18, Color(1, 0.72, 0.5)))
	for c in d.get("catatan", []):
		kanan.add_child(_teks(String(c), 17, Color(0.78, 0.86, 0.95)))
	kanan.add_child(_chip(String(d.get("status", "")), String(d.get("keadaan", ""))))
	return kanan


func _baris(induk: Control, kunci: String, nilai: String) -> Label:
	var h: = HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	var k: = GH.label(kunci, 18, GH.EMAS, false, 2)
	k.custom_minimum_size.x = 76
	k.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	h.add_child(k)
	var n: = _teks(nilai, 20, Color.WHITE)
	n.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	n.custom_minimum_size.x = 340
	h.add_child(n)
	induk.add_child(h)
	return n


func _teks(teks: String, ukuran: int, warna: Color) -> Label:
	var l: = GH.label(teks, ukuran, warna, false, 2)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size.x = 420
	l.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	return l


func _chip(teks: String, keadaan: String) -> Control:
	var warna: = Color(0.62, 0.62, 0.66)
	match keadaan:
		"sekarang": warna = Color(0.35, 0.78, 0.42)
		"tunggu": warna = GH.EMAS
		"terkunci": warna = Color(1, 0.62, 0.42)
	var p: = PanelContainer.new()
	var g: = StyleBoxFlat.new()
	g.bg_color = Color(warna, 0.2)
	g.border_color = warna
	g.set_border_width_all(2)
	g.set_corner_radius_all(12)
	g.content_margin_left = 14
	g.content_margin_right = 14
	g.content_margin_top = 5
	g.content_margin_bottom = 5
	p.add_theme_stylebox_override("panel", g)
	p.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	p.add_child(GH.label(teks, 19, warna.lightened(0.25), false, 2))
	return p


func _process(delta: float) -> void :
	_denyut = fmod(_denyut + delta * 0.8, 1.0)
	if _peta != null:
		_peta.queue_redraw()


func _gambar_peta() -> void :
	var u: = _peta.size
	_kotak_nama.clear()
	_peta.draw_rect(Rect2(Vector2.ZERO, u), Color(0.07, 0.07, 0.1))
	if _tekstur == null:
		return
	var t: = _tekstur.get_size()
	var s: = minf(u.x / t.x, u.y / t.y)
	var o: = (u - t * s) / 2.0
	_peta.draw_texture_rect(_tekstur, Rect2(o, t * s), false)
	var font: Font = GH.font("Nunito", 800)
	for d in _titik:
		var ujung: Vector2 = o + (d["posisi"] as Vector2) * s
		var pusat: = ujung - Vector2(0, 24)
		_peta.draw_arc(ujung, 8.0 + 20.0 * _denyut, 0, TAU, 28, Color(MERAH, 1.0 - _denyut), 3.0, true)
		_peta.draw_colored_polygon(PackedVector2Array([ujung, pusat + Vector2(-11, 5), pusat + Vector2(11, 5)]), MERAH.darkened(0.15))
		_peta.draw_circle(pusat, 14, MERAH)
		_peta.draw_circle(pusat, 14, Color.WHITE, false, 2.0, true)
		_peta.draw_circle(pusat, 5, Color.WHITE)
		_tulis(font, pusat - Vector2(0, 28), String(d["nama"]), MERAH.darkened(0.3))
	if _saya.x >= 0.0:
		var p: = o + _saya * s
		_peta.draw_circle(p, 13, Color(BIRU, 0.25))
		_peta.draw_circle(p, 8, Color.WHITE)
		_peta.draw_circle(p, 6, BIRU)
		_tulis(font, p + Vector2(0, 26), tr("Kamu di sini"), BIRU.darkened(0.25))



func _tulis(font: Font, tengah: Vector2, teks: String, warna: Color) -> void :
	var ukuran: = 16
	var lebar: = font.get_string_size(teks, HORIZONTAL_ALIGNMENT_LEFT, -1, ukuran).x
	var kotak: = Rect2(tengah - Vector2(lebar / 2.0 + 7.0, 12.0), Vector2(lebar + 14.0, 24.0))
	kotak.position.x = clampf(kotak.position.x, 2.0, maxf(_peta.size.x - kotak.size.x - 2.0, 2.0))
	kotak.position.y = clampf(kotak.position.y, 2.0, maxf(_peta.size.y - kotak.size.y - 2.0, 2.0))
	var arah: = -26.0
	for i in 12:
		if not _kotak_nama.any( func(k): return (k as Rect2).intersects(kotak)):
			break
		kotak.position.y += arah
		if kotak.position.y < 2.0:
			arah = 26.0
			kotak.position.y = 2.0
	_kotak_nama.append(kotak)
	_peta.draw_rect(kotak, Color(1, 1, 1, 0.94))
	_peta.draw_string(font, kotak.position + Vector2(7, 18), teks, HORIZONTAL_ALIGNMENT_LEFT, -1, ukuran, warna)


func _tutup() -> void :
	if _menutup:
		return
	_menutup = true
	GameState.klik()
	ditutup.emit()
	queue_free()
