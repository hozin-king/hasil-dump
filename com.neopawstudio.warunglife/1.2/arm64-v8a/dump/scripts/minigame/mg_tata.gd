extends "res://scripts/minigame/mg_dasar.gd"









const TAMPAH: = Vector2(760, 215)
const RADIUS_TAMPAH: = 185.0
const RADIUS_RENGGINANG: = 38.0
const SAMPAH: = Vector2(95, 360)
const BASKOM: = Vector2(235, 165)
const WAJAN: = Vector2(470, 330)
const RADIUS_WAJAN: = 88.0
const SLOT_WAJAN: = [Vector2(-38, -6), Vector2(38, 6)]
const TUMPUKAN: = [Vector2(175, 110), Vector2(300, 110), Vector2(175, 220), Vector2(300, 220)]
const PELUANG: = {"matang": 0.5, "setengah": 0.3, "gosong": 0.2}
const MATANG_MULAI: = 2.2
const GOSONG_MULAI: = 4.6

var _lubang: = []
var _tumpukan: = []
var _wajan: = [null, null]
var _pegang: = -1
var _pegang_p: = Vector2.ZERO
var _putar_tampah: = 0.0
var _waktu: = 0.0


func _siapkan() -> void :
	cahaya_25d = {"dari": Vector2(240, -40), "warna": Color(1, 0.85, 0.55), "kuat": 1.0}
	judul = "Bikin rengginang Nenek Sumi"
	petunjuk = "MATANG ke tampah. SETENGAH MATANG goreng lagi di wajan, angkat sebelum gosong. GOSONG buang ke ember!"
	target = 12.0
	contoh = {"jenis": "seret", "dari": TUMPUKAN[0], "ke": TAMPAH + Vector2(0, -110), "teks": "Seret ke tampah"}
	_tampah_baru()
	for p in TUMPUKAN:
		_tumpukan.append(_rengginang_baru(p))


func _tampah_baru() -> void :
	_lubang.clear()
	_lubang.append({"p": TAMPAH, "isi": false})
	for i in 6:
		_lubang.append({"p": TAMPAH + Vector2.from_angle(i * TAU / 6.0 - PI / 2.0) * 105.0, "isi": false})
	_putar_tampah = 1.0


func _rengginang_baru(p: Vector2) -> Dictionary:
	var r: = randf()
	var keadaan: = "matang"
	if r < PELUANG["gosong"]:
		keadaan = "gosong"
	elif r < PELUANG["gosong"] + PELUANG["setengah"]:
		keadaan = "setengah"
	return {"p": p, "asal": p, "keadaan": keadaan, "acak": randi()}


func _keadaan_wajan(masak: float) -> String:
	if masak >= GOSONG_MULAI:
		return "gosong"
	if masak >= MATANG_MULAI:
		return "matang"
	return "setengah"


func _main(delta: float) -> void :
	_waktu += delta
	_putar_tampah = maxf(_putar_tampah - delta * 3.0, 0.0)
	for i in _wajan.size():
		if _wajan[i] != null and _pegang != 100 + i:
			_wajan[i]["masak"] += delta


func _masukan(e: InputEvent) -> void :
	if tekan_awal(e):

		for i in _wajan.size():
			if _wajan[i] != null and (WAJAN + SLOT_WAJAN[i]).distance_to(e.position) < RADIUS_RENGGINANG + 8:
				_pegang = 100 + i
				_pegang_p = e.position
				GameState.klik()
				return
		for i in range(_tumpukan.size() - 1, -1, -1):
			if (_tumpukan[i]["p"] as Vector2).distance_to(e.position) < RADIUS_RENGGINANG + 10:
				_pegang = i
				GameState.klik()
				return
	elif e is InputEventMouseMotion and _pegang >= 0:
		if _pegang >= 100:
			_pegang_p = e.position
		else:
			_tumpukan[_pegang]["p"] = e.position
	elif lepas(e) and _pegang >= 0:
		if _pegang >= 100:
			_lepas_dari_wajan(_pegang - 100, _pegang_p)
		else:
			_lepas_dari_tumpukan(_pegang)
		_pegang = -1



func _taruh(keadaan: String, p: Vector2, boleh_wajan: bool) -> String:
	if p.distance_to(SAMPAH) < 75:
		if keadaan == "gosong":
			kilat(SAMPAH + Vector2(0, -50), "Buang!", Color.WHITE)
			percik(SAMPAH, Color(0.3, 0.2, 0.1), 8, 4.0)
		else:
			kilat(SAMPAH + Vector2(0, -50), "Sayang!", Color(1, 0.4, 0.35))
		return "sampah"
	if boleh_wajan and p.distance_to(WAJAN) < RADIUS_WAJAN + 10:
		var kosong: = _wajan.find(null)
		if kosong >= 0:
			return "wajan"
		kilat(WAJAN + Vector2(0, -70), "Wajan penuh!", Color(1, 0.75, 0.4))
		return ""
	for l in _lubang:
		if not l["isi"] and (l["p"] as Vector2).distance_to(p) < 55:
			match keadaan:
				"matang":
					l["isi"] = true
					tambah_skor(1, l["p"])
				"setengah":
					kilat(l["p"] + Vector2(0, -50), "Belum matang!", Color(1, 0.55, 0.45))
					tambah_skor(-1, l["p"])
				_:
					tambah_skor(-1, l["p"])
			if _lubang.all( func(x): return x["isi"]):
				kilat(TAMPAH + Vector2(0, -60), "Tampah penuh!", GH.KUNING)
				percik(TAMPAH, GH.KUNING, 20, 6.0)
				_tampah_baru()
			return "tampah"
	return ""


func _lepas_dari_tumpukan(i: int) -> void :
	var r: Dictionary = _tumpukan[i]
	var hasil: = _taruh(String(r["keadaan"]), r["p"], true)
	if hasil == "wajan":
		var kosong: = _wajan.find(null)

		var awal: = 0.0 if r["keadaan"] == "setengah" else (MATANG_MULAI if r["keadaan"] == "matang" else GOSONG_MULAI)
		_wajan[kosong] = {"masak": awal, "acak": r["acak"]}
		kilat(WAJAN + Vector2(0, -70), "Goreng lagi", Color(1, 0.85, 0.5))
	if hasil != "":
		_tumpukan[i] = _rengginang_baru(r["asal"])
	else:
		r["p"] = r["asal"]


func _lepas_dari_wajan(slot: int, p: Vector2) -> void :
	var w: Dictionary = _wajan[slot]
	var hasil: = _taruh(_keadaan_wajan(float(w["masak"])), p, false)
	if hasil != "":
		_wajan[slot] = null


func _gambar() -> void :
	_meja()

	bayangan(BASKOM + Vector2(0, 145), 320, 0.35)
	kanvas.draw_circle(BASKOM, 160, Color(0.18, 0.38, 0.62))
	kanvas.draw_circle(BASKOM, 148, Color(0.3, 0.55, 0.82))
	kanvas.draw_circle(BASKOM + Vector2(8, 10), 128, Color(0.25, 0.48, 0.74))
	kanvas.draw_arc(BASKOM, 154, deg_to_rad(200), deg_to_rad(290), 24, Color(1, 1, 1, 0.35), 5)

	bayangan(SAMPAH + Vector2(0, 58), 120, 0.35)
	kanvas.draw_colored_polygon(PackedVector2Array([SAMPAH + Vector2(-52, -45), SAMPAH + Vector2(52, -45), SAMPAH + Vector2(40, 55), SAMPAH + Vector2(-40, 55)]), Color(0.28, 0.33, 0.3))
	kanvas.draw_rect(Rect2(SAMPAH + Vector2(-58, -55), Vector2(116, 16)), Color(0.36, 0.42, 0.38))
	for i in 3:
		kanvas.draw_line(SAMPAH + Vector2(-25 + i * 25, -30), SAMPAH + Vector2(-20 + i * 20, 45), Color(0, 0, 0, 0.25), 3)
	teks(SAMPAH + Vector2(0, 5), "GOSONG", 22, Color(1, 1, 1, 0.85), 110)
	_gambar_wajan()

	var skala: = 1.0 - _putar_tampah * 0.15
	kanvas.draw_set_transform(TAMPAH, _putar_tampah * 0.8, Vector2.ONE * skala)
	bayangan(Vector2(0, RADIUS_TAMPAH - 10), RADIUS_TAMPAH * 2.1, 0.35)
	kanvas.draw_circle(Vector2.ZERO, RADIUS_TAMPAH, Color(0.72, 0.55, 0.3))
	for i in 10:
		kanvas.draw_arc(Vector2.ZERO, 22 + i * 16, 0, TAU, 56, Color(0.58, 0.42, 0.2) if i % 2 == 0 else Color(0.82, 0.66, 0.4), 6)
	for i in 24:
		var a: = i * TAU / 24.0
		kanvas.draw_line(Vector2.from_angle(a) * 20, Vector2.from_angle(a) * (RADIUS_TAMPAH - 8), Color(0.5, 0.36, 0.16, 0.35), 2)
	kanvas.draw_arc(Vector2.ZERO, RADIUS_TAMPAH, 0, TAU, 72, Color(0.45, 0.3, 0.12), 12)
	kanvas.draw_arc(Vector2.ZERO, RADIUS_TAMPAH - 4, deg_to_rad(200), deg_to_rad(300), 24, Color(1, 0.9, 0.7, 0.4), 4)
	kanvas.draw_set_transform(Vector2.ZERO)
	for l in _lubang:
		if l["isi"]:
			_rengginang(l["p"], _warna("matang"), hash(l["p"]), 1.0, false)
		else:
			kanvas.draw_circle(l["p"], RADIUS_RENGGINANG, Color(0, 0, 0, 0.12))
			kanvas.draw_arc(l["p"], RADIUS_RENGGINANG, 0, TAU, 32, Color(1, 1, 1, 0.6), 3)
	for i in _tumpukan.size():
		if i != _pegang:
			_rengginang(_tumpukan[i]["p"], _warna(String(_tumpukan[i]["keadaan"])), int(_tumpukan[i]["acak"]), 1.0, false)
	if _pegang >= 0 and _pegang < 100:
		_rengginang(_tumpukan[_pegang]["p"], _warna(String(_tumpukan[_pegang]["keadaan"])), int(_tumpukan[_pegang]["acak"]), 1.12, true)
	elif _pegang >= 100 and _wajan[_pegang - 100] != null:
		var w: Dictionary = _wajan[_pegang - 100]
		_rengginang(_pegang_p, _warna_masak(float(w["masak"])), int(w["acak"]), 1.12, true)


func _gambar_wajan() -> void :

	bayangan(WAJAN + Vector2(0, 70), 230, 0.35)
	kotak_bulat(Rect2(WAJAN + Vector2(-95, 40), Vector2(190, 46)), Color(0.32, 0.33, 0.36), 10.0)
	for i in 5:
		var x: = -40.0 + i * 20.0
		var tinggi_api: = 10.0 + sin(_waktu * 18.0 + i) * 4.0
		kanvas.draw_colored_polygon(PackedVector2Array([WAJAN + Vector2(x - 6, 42), WAJAN + Vector2(x, 42 - tinggi_api), WAJAN + Vector2(x + 6, 42)]), Color(0.35, 0.6, 1.0, 0.85))
		kanvas.draw_circle(WAJAN + Vector2(x, 38), 12, Color(0.4, 0.65, 1.0, 0.12))
	kanvas.draw_circle(WAJAN, RADIUS_WAJAN + 6, Color(0.12, 0.12, 0.13))
	kanvas.draw_circle(WAJAN, RADIUS_WAJAN, Color(0.22, 0.2, 0.18))
	kanvas.draw_circle(WAJAN + Vector2(4, 6), RADIUS_WAJAN - 14, Color(0.55, 0.42, 0.15, 0.55))

	kanvas.draw_arc(WAJAN, RADIUS_WAJAN + 3, deg_to_rad(200), deg_to_rad(290), 20, Color(1, 1, 1, 0.3), 3)
	kanvas.draw_arc(WAJAN + Vector2(4, 6), RADIUS_WAJAN - 24, deg_to_rad(205), deg_to_rad(260), 16, Color(1, 0.9, 0.6, 0.45), 4)
	for i in 6:
		var a: = i * 1.1 + _waktu * 0.6
		var r: = fposmod(i * 23.0 + _waktu * 18.0, RADIUS_WAJAN - 24)
		kanvas.draw_arc(WAJAN + Vector2(4, 6) + Vector2.from_angle(a) * r, 3.0 + i % 3, 0, TAU, 10, Color(1, 0.92, 0.7, 0.5), 1.5)
	kanvas.draw_line(WAJAN + Vector2(RADIUS_WAJAN, -6), WAJAN + Vector2(RADIUS_WAJAN + 70, -26), Color(0.15, 0.1, 0.06), 12)
	for u in 5:
		var t: = fposmod(_waktu * 0.5 + u * 0.2, 1.0)
		var up: = WAJAN + Vector2(-50 + u * 25 + sin(_waktu * 2.0 + u) * 10.0, -10 - t * 110.0)
		kanvas.draw_circle(up, 14.0 + t * 18.0, Color(1, 1, 1, 0.13 * (1.0 - t)))
	teks(WAJAN + Vector2(0, - RADIUS_WAJAN - 14), "WAJAN · goreng lagi", 18, Color(1, 0.92, 0.75), 240)
	for i in _wajan.size():
		var p: Vector2 = WAJAN + SLOT_WAJAN[i]
		if _wajan[i] == null or _pegang == 100 + i:
			kanvas.draw_arc(p, RADIUS_RENGGINANG - 4, 0, TAU, 28, Color(1, 1, 1, 0.25), 2)
			continue
		var masak: = float(_wajan[i]["masak"])
		_rengginang(p, _warna_masak(masak), int(_wajan[i]["acak"]), 0.92, false)

		for g in 4:
			var a: = _waktu * 3.0 + g * 1.7 + i
			kanvas.draw_circle(p + Vector2.from_angle(a) * (RADIUS_RENGGINANG - 2), 3.0, Color(1, 0.95, 0.7, 0.55))
		if masak > MATANG_MULAI + 1.2:
			var asap: = clampf((masak - MATANG_MULAI - 1.2) / (GOSONG_MULAI - MATANG_MULAI - 1.2), 0.0, 1.0)
			for s in 3:
				var naik: = fmod(_waktu * 40.0 + s * 20.0, 60.0)
				kanvas.draw_circle(p + Vector2(-12 + s * 12, -30 - naik), 8.0 + naik * 0.15, Color(0.4, 0.4, 0.4, 0.35 * asap * (1.0 - naik / 60.0)))


func _warna(keadaan: String) -> Color:
	match keadaan:
		"gosong":
			return Color(0.36, 0.22, 0.11)
		"setengah":
			return Color(0.97, 0.96, 0.9)
	return Color(0.95, 0.76, 0.38)



func _warna_masak(masak: float) -> Color:
	if masak < MATANG_MULAI:
		return _warna("setengah").lerp(_warna("matang"), clampf(masak / MATANG_MULAI, 0.0, 1.0) * 0.6)
	if masak < GOSONG_MULAI:
		return _warna("matang").lerp(Color(0.72, 0.46, 0.2), clampf((masak - MATANG_MULAI) / (GOSONG_MULAI - MATANG_MULAI), 0.0, 1.0) * 0.6)
	return _warna("gosong")


func _meja() -> void :
	gradasi(Rect2(Vector2.ZERO, UKURAN), Color(0.66, 0.46, 0.28), Color(0.52, 0.34, 0.2))
	var acak: = RandomNumberGenerator.new()
	acak.seed = 42
	for i in 6:
		var y: = i * 72.0
		kanvas.draw_line(Vector2(0, y), Vector2(UKURAN.x, y), Color(0.35, 0.22, 0.12, 0.6), 3)
		for g in 5:
			var gy: = y + acak.randf_range(10, 62)
			var titik: = PackedVector2Array()
			for x in range(0, int(UKURAN.x) + 40, 40):
				titik.append(Vector2(x, gy + sin(x * 0.02 + g) * 3.0))
			kanvas.draw_polyline(titik, Color(0.4, 0.25, 0.12, 0.18), 2)


func _rengginang(p: Vector2, dasar: Color, benih: int, skala: float, diangkat: bool) -> void :
	bayangan(p + Vector2(6, RADIUS_RENGGINANG * skala * (1.1 if diangkat else 0.7)), RADIUS_RENGGINANG * 2.0 * skala, 0.4 if diangkat else 0.28)
	var tepi: = dasar.darkened(0.25)
	var gelap: = dasar.get_luminance() < 0.35
	var r: = RADIUS_RENGGINANG * skala
	kanvas.draw_circle(p, r, tepi)
	kanvas.draw_circle(p + Vector2(-1, -1), r - 3, dasar)
	var acak: = RandomNumberGenerator.new()
	acak.seed = benih
	for i in 26:
		var b: = p + Vector2.from_angle(acak.randf() * TAU) * acak.randf() * (r - 7)
		var w: = dasar.lightened(0.12).lerp(tepi, acak.randf() * 0.4)
		kanvas.draw_circle(b + Vector2(1, 1.5), 4.6 * skala, tepi)
		kanvas.draw_circle(b, 4.2 * skala, w)
		kanvas.draw_circle(b + Vector2(-1.2, -1.2), 1.4 * skala, Color(1, 1, 1, 0.15 if gelap else 0.5))
