extends VBoxContainer







const UI: = preload("res://scripts/hp/hp_ui.gd")
const WARNA: = Color(0.26, 0.52, 0.96)
const LEBAR_PETA: = 370.0
const UKURAN_ASLI: = 1254.0
const METER_PER_TITIK: = 0.35
const JALAN_KAKI: = 70.0

const W_LATAR: = Color("#eef1e7")
const W_PEMUKIMAN: = Color("#e8e4dc")
const W_GEDUNG: = Color("#dcd7cd")
const W_HIJAU: = Color("#c8e6c0")
const W_LAPANGAN: = Color("#a9d89f")
const W_SAWAH: = Color("#d7ecc4")
const W_PEMATANG: = Color("#c2dba9")
const W_AIR: = Color("#a8d4fb")
const W_JALAN_RAYA: = Color("#fde293")
const W_TEPI_RAYA: = Color("#e9bf53")
const W_JALAN: = Color.WHITE
const W_TEPI_JALAN: = Color("#d6d2c8")
const W_TEKS: = Color("#3c4043")


const KAWASAN: = [
	["", W_PEMUKIMAN, [[0, 400], [630, 400], [630, 650], [0, 650]]], 
	["", W_GEDUNG, [[95, 60], [505, 60], [505, 390], [95, 390]]], 
	["", W_GEDUNG, [[790, 35], [1135, 35], [1135, 390], [790, 390]]], 
	["Masjid", Color("#d9eed6"), [[850, 455], [1180, 455], [1180, 720], [850, 720]]], 
	["", Color("#fbe3c8"), [[625, 550], [840, 550], [840, 655], [625, 655]]], 
	["", W_SAWAH, [[0, 880], [1254, 1045], [1254, 1254], [0, 1254]]], 
]

const JALAN: = [
	[34, false, [[60, 397], [1185, 418]]], 
	[58, false, [[1168, 0], [1200, 360], [1218, 720]]], 
	[22, false, [[675, 870], [675, 1010]]], 
	[100, true, [[0, 705], [1254, 865]]], 
]
const PEMATANG: = [[[0, 1060], [1254, 1180]], [[350, 930], [330, 1254]], [[660, 990], [640, 1254]], [[980, 1030], [960, 1254]]]
const SALURAN: = [[0, 895], [1254, 1055]]

const PIN: = {
	"Warung Pak Misran": [Color("#f28b30"), "W"], 
	"Masjid": [Color("#1e8e3e"), "M"], 
	"Rumah Warga": [Color("#7b8a9a"), "R"], 
	"Rumah Pak Misran": [Color("#ea4335"), "⌂"], 
	"Sawah": [Color("#34a853"), "S"], 
	"Sekolah Dasar": [Color("#4285f4"), "SD"], 
	"Lapangan Bola": [Color("#0f9d58"), "L"], 
	"Pesantren": [Color("#8d6e63"), "P"], 
	"Pasar": [Color("#e37400"), "Ps"], 
}


const UJUNG_ANGKOT: = Vector2(40, 397)

var hp: Control
var _tempat: Array = []
var _sini: Vector2 = Vector2(-1, -1)
var _nama_sini: = ""


func _ready() -> void :
	add_theme_constant_override("separation", 0)
	add_child(UI.kepala("Peta Desa", WARNA))
	var g: Array = UI.gulir(8)
	var tepi: = MarginContainer.new()
	tepi.size_flags_vertical = Control.SIZE_EXPAND_FILL
	for sisi in ["left", "right", "top", "bottom"]:
		tepi.add_theme_constant_override("margin_" + sisi, 10)
	tepi.add_child(g[0])
	add_child(tepi)
	var isi: VBoxContainer = g[1]
	_tempat = JSON.parse_string(FileAccess.get_file_as_string("res://data/peta.json"))["peta"]["tempat"]
	_cari_posisi_sini()

	var cari: = UI.panel(Color.WHITE, 22, 10)
	var baris_cari: = HBoxContainer.new()
	baris_cari.add_theme_constant_override("separation", 8)
	cari.add_child(baris_cari)
	var kaca: = Control.new()
	kaca.custom_minimum_size = Vector2(20, 20)
	kaca.draw.connect( func():
		kaca.draw_arc(Vector2(8, 8), 6, 0, TAU, 20, Color("#5f6368"), 2.0, true)
		kaca.draw_line(Vector2(12.5, 12.5), Vector2(18, 18), Color("#5f6368"), 2.5, true))
	baris_cari.add_child(kaca)
	baris_cari.add_child(UI.label("Cari tempat di kampung", 15, Color("#70757a")))
	isi.add_child(cari)

	var bingkai: = UI.panel(W_LATAR, 14, 0)
	bingkai.clip_contents = true
	bingkai.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	isi.add_child(bingkai)
	var peta: = Control.new()
	peta.custom_minimum_size = Vector2(LEBAR_PETA, LEBAR_PETA)
	peta.mouse_filter = Control.MOUSE_FILTER_IGNORE
	peta.draw.connect(_gambar_peta.bind(peta))
	bingkai.add_child(peta)

	isi.add_child(UI.label("Tempat di kampung", 17, Color.WHITE))
	for t in _urut_jarak():
		isi.add_child(_baris_tempat(t))
	isi.add_child(UI.label("Di luar kampung", 17, Color.WHITE))
	isi.add_child(_baris_tempat({"nama": "Pasar", "area": "pasar", "luar": true}))
	isi.add_child(UI.label("Pindah tempat dengan berjalan kaki lewat jalan kampung. Ikuti tanda panah di tepi layar untuk pindah ke area lain.", 14, UI.WARNA_REDUP, true))



func _cari_posisi_sini() -> void :
	var area: = "warung"
	if hp != null and hp.warung != null and "area_id" in hp.warung:
		area = String(hp.warung.area_id)
	if area == "kamar":
		area = "rumah_misran"
	for t in _tempat:
		var cocok: = String(t["area"]) == area or (area == "rumah_misran" and String(t.get("muncul", "")) == "rumah_misran")
		if area == "rumah" and String(t.get("muncul", "")) == "rumah_misran":
			cocok = false
		if cocok:
			_sini = _v(t["posisi"])
			_nama_sini = String(t["nama"])
			return


func _v(a: Array) -> Vector2:
	return Vector2(float(a[0]), float(a[1]))


func _urut_jarak() -> Array:
	var daftar: = _tempat.duplicate()
	if _sini.x >= 0.0:
		daftar.sort_custom( func(a, b): return _v(a["posisi"]).distance_to(_sini) < _v(b["posisi"]).distance_to(_sini))
	return daftar


func _baris_tempat(t: Dictionary) -> Control:
	var kartu: = UI.panel(Color(1, 1, 1, 0.1), 10, 8)
	var baris: = HBoxContainer.new()
	baris.add_theme_constant_override("separation", 10)
	kartu.add_child(baris)
	var pin: Array = PIN.get(String(t["nama"]), [Color("#ea4335"), "•"])
	var bulat: = UI.panel(pin[0], 14, 0)
	bulat.custom_minimum_size = Vector2(28, 28)
	var huruf: = UI.label(String(pin[1]), 13, Color.WHITE)
	huruf.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	huruf.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	bulat.add_child(huruf)
	baris.add_child(bulat)
	var kolom: = VBoxContainer.new()
	kolom.add_theme_constant_override("separation", 0)
	kolom.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	baris.add_child(kolom)
	kolom.add_child(UI.label(String(t["nama"]), 15, Color.WHITE))
	var keterangan: = "Belum bisa dikunjungi" if String(t["area"]) == "" else ""
	if t.has("luar"):
		keterangan = "Naik angkot dari pos ronda (Rumah Warga), Rp2.000 · ± 30 menit\nBuka 06.00-21.00, libur Selasa & Kamis"

		if hp != null and hp.warung != null and "area_id" in hp.warung and String(hp.warung.area_id) == "pasar":
			keterangan = "Anda di sini"
	elif String(t["nama"]) == _nama_sini:
		keterangan = "Anda di sini"
	elif _sini.x >= 0.0 and keterangan == "":
		var meter: = _v(t["posisi"]).distance_to(_sini) * METER_PER_TITIK
		keterangan = "± %d m · %d menit jalan kaki" % [int(round(meter / 10.0)) * 10, maxi(1, int(ceil(meter / JALAN_KAKI)))]
	kolom.add_child(UI.label(keterangan, 12, Color(0.55, 0.78, 1.0) if keterangan == "Anda di sini" else UI.WARNA_REDUP, t.has("luar")))
	return kartu


func _gambar_peta(c: Control) -> void :
	var s: = LEBAR_PETA / UKURAN_ASLI
	c.draw_rect(Rect2(Vector2.ZERO, c.size), W_HIJAU)
	for k in KAWASAN:
		c.draw_colored_polygon(_poli(k[2], s), k[1])

	var lap: = Rect2(Vector2(568, 108) * s, Vector2(200, 210) * s)
	c.draw_rect(lap, W_LAPANGAN)
	c.draw_rect(lap.grow(-3), Color(1, 1, 1, 0.7), false, 1.0)
	c.draw_line(Vector2(lap.position.x + 3, lap.get_center().y), Vector2(lap.end.x - 3, lap.get_center().y), Color(1, 1, 1, 0.7), 1.0)
	c.draw_arc(lap.get_center(), 8, 0, TAU, 20, Color(1, 1, 1, 0.7), 1.0)
	for p in PEMATANG:
		c.draw_line(_v(p[0]) * s, _v(p[1]) * s, W_PEMATANG, 3.0)
	c.draw_line(_v(SALURAN[0]) * s, _v(SALURAN[1]) * s, W_AIR, 22.0 * s * 1.6)

	for j in JALAN:
		var lebar: float = float(j[0]) * s
		var raya: bool = j[1]
		var titik: = _garis(j[2], s)
		c.draw_polyline(titik, W_TEPI_RAYA if raya else W_TEPI_JALAN, lebar + 3.0, true)
		c.draw_polyline(titik, W_JALAN_RAYA if raya else W_JALAN, lebar, true)

	var font: = UI.GH.font("Nunito", 700)
	var awal: = Vector2(380, 760) * s
	c.draw_set_transform(awal, atan2(160.0, 1254.0), Vector2.ONE)
	c.draw_string(font, Vector2.ZERO, GameState.tk("Jl. Raya Kampung"), HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("#8a6d1f"))
	c.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	for k in KAWASAN:
		if String(k[0]) != "" and String(k[0]) != "Masjid":
			var tengah: = Vector2.ZERO
			for p in k[2]:
				tengah += _v(p)
			tengah = tengah / (k[2] as Array).size() * s
			_tulis(c, font, tengah + Vector2(0, 16), String(k[0]), 10, Color("#80868b"))

	for t in _tempat:
		var pos: = _v(t["posisi"]) * s
		var pin: Array = PIN.get(String(t["nama"]), [Color("#ea4335"), "•"])
		_gambar_pin(c, font, pos, pin[0], String(pin[1]))
		_tulis(c, font, pos + Vector2(0, 14), String(t["nama"]), 11, W_TEKS)

	var ujung: = UJUNG_ANGKOT * s
	_gambar_pin(c, font, ujung + Vector2(0, -6), PIN["Pasar"][0], String(PIN["Pasar"][1]))
	_tulis(c, font, ujung + Vector2(20, 15), "Ke Pasar", 10, Color("#b35c00"))

	if _sini.x >= 0.0:
		var p: = _sini * s + Vector2(19, -24)
		c.draw_circle(p, 16, Color(0.26, 0.52, 0.96, 0.18))
		c.draw_circle(p, 8, Color.WHITE)
		c.draw_circle(p, 6, Color(0.26, 0.52, 0.96))


func _gambar_pin(c: Control, font: Font, ujung: Vector2, warna: Color, huruf: String) -> void :
	var pusat: = ujung - Vector2(0, 17)
	c.draw_colored_polygon(PackedVector2Array([ujung, pusat + Vector2(-8, 4), pusat + Vector2(8, 4)]), warna.darkened(0.15))
	c.draw_circle(pusat + Vector2(0, 1), 11, Color(0, 0, 0, 0.18))
	c.draw_circle(pusat, 11, warna)
	c.draw_circle(pusat, 11, warna.darkened(0.2), false, 1.0, true)
	var ukuran: = 9 if huruf.length() > 1 else 11
	var lebar: = font.get_string_size(GameState.tk(huruf), HORIZONTAL_ALIGNMENT_LEFT, -1, ukuran).x
	c.draw_string(font, pusat + Vector2( - lebar / 2.0, ukuran * 0.38), GameState.tk(huruf), HORIZONTAL_ALIGNMENT_LEFT, -1, ukuran, Color.WHITE)



func _tulis(c: Control, font: Font, tengah: Vector2, teks: String, ukuran: int, warna: Color) -> void :
	var lebar: = font.get_string_size(GameState.tk(teks), HORIZONTAL_ALIGNMENT_LEFT, -1, ukuran).x
	var pos: = tengah + Vector2( - lebar / 2.0, ukuran * 0.35)
	c.draw_string_outline(font, pos, GameState.tk(teks), HORIZONTAL_ALIGNMENT_LEFT, -1, ukuran, 3, Color(1, 1, 1, 0.9))
	c.draw_string(font, pos, GameState.tk(teks), HORIZONTAL_ALIGNMENT_LEFT, -1, ukuran, warna)


func _poli(titik: Array, s: float) -> PackedVector2Array:
	var hasil: = PackedVector2Array()
	for p in titik:
		hasil.append(_v(p) * s)
	return hasil


func _garis(titik: Array, s: float) -> PackedVector2Array:
	return _poli(titik, s)
