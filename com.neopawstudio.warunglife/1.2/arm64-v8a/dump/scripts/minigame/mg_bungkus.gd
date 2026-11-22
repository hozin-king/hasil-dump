extends "res://scripts/minigame/mg_dasar.gd"





const BERAT: = ["beras", "minyak_goreng", "gula", "deterjen", "lpg"]
const BIASA: = ["mi_goreng", "mi_rebus", "sabun", "biskuit", "susu_kotak", "kopi_bubuk", "sachet", "teh_botol", "air_mineral", "sirup"]
const RAPUH: = ["telur", "kerupuk", "ciki", "rengginang", "es_krim"]
const SEKAT: = ["atas", "tengah", "bawah"]
const NAMA_SEKAT: = {"atas": "ATAS · mudah pecah", "tengah": "TENGAH · biasa", "bawah": "BAWAH · berat"}
const WARNA_SEKAT: = {"atas": Color(0.95, 0.55, 0.6), "tengah": Color(0.98, 0.82, 0.4), "bawah": Color(0.55, 0.75, 0.95)}
const KARDUS: = Rect2(470, 20, 540, 392)
const MEJA_BARANG: = [Vector2(110, 120), Vector2(290, 120), Vector2(110, 300), Vector2(290, 300)]
const UKURAN_BARANG: = 92.0

var _isi: = {"atas": [], "tengah": [], "bawah": []}
var _meja: = []
var _pegang: = -1
var _kardus_baru: = 0.0
var _goyang: = {}


func _siapkan() -> void :
	cahaya_25d = {"dari": Vector2(300, -60), "warna": Color(1, 0.88, 0.6), "kuat": 1.0}
	judul = "Bungkus rapi"
	petunjuk = "Seret belanjaan ke kardus: yang BERAT di bawah, yang MUDAH PECAH di atas!"
	durasi = 22.0
	target = 18.0
	for p in MEJA_BARANG:
		_meja.append(_barang_baru(p))
	contoh = {"jenis": "seret", "dari": MEJA_BARANG[0], "ke": _kotak_sekat(_jenis_ke_sekat(String(_meja[0]["jenis"]))).get_center(), 
		"benda": "res://assets/barang/%s.png" % String(_meja[0]["id"]), "teks": "Seret ke sekat yang cocok"}


func _ada_ikon(daftar: Array) -> Array:
	return daftar.filter( func(id): return ResourceLoader.exists("res://assets/barang/%s.png" % id))


func _jenis_ke_sekat(jenis: String) -> String:
	return {"berat": "bawah", "biasa": "tengah", "rapuh": "atas"}[jenis]




func _barang_baru(p: Vector2) -> Dictionary:
	var sisa: = {}
	for s in SEKAT:
		sisa[s] = 3 - (_isi[s] as Array).size()
	for b in _meja:
		if not b.is_empty():
			sisa[_jenis_ke_sekat(String(b["jenis"]))] -= 1
	var jenis_boleh: = []
	for j in ["berat", "biasa", "rapuh"]:
		if int(sisa[_jenis_ke_sekat(j)]) > 0:
			jenis_boleh.append(j)
	if jenis_boleh.is_empty():
		jenis_boleh = ["berat", "biasa", "rapuh"]
	var jenis: String = jenis_boleh.pick_random()
	var daftar: Array = _ada_ikon({"berat": BERAT, "biasa": BIASA, "rapuh": RAPUH}[jenis])
	return {"id": String(daftar.pick_random()), "jenis": jenis, "p": p, "asal": p}


func _kotak_sekat(s: String) -> Rect2:
	var i: = SEKAT.find(s)
	var tinggi: = (KARDUS.size.y - 40) / 3.0
	return Rect2(KARDUS.position + Vector2(20, 30 + i * tinggi), Vector2(KARDUS.size.x - 40, tinggi - 8))


func _titik_slot(s: String, n: int) -> Vector2:
	var r: = _kotak_sekat(s)
	return r.position + Vector2(200 + n * 105, r.size.y / 2.0 + 4)


func _main(delta: float) -> void :
	_kardus_baru = maxf(_kardus_baru - delta * 2.5, 0.0)
	for s in _goyang.keys():
		_goyang[s] = maxf(float(_goyang[s]) - delta * 3.0, 0.0)


func _masukan(e: InputEvent) -> void :
	if tekan_awal(e):
		for i in range(_meja.size() - 1, -1, -1):
			if (_meja[i]["p"] as Vector2).distance_to(e.position) < UKURAN_BARANG * 0.55:
				_pegang = i
				GameState.klik()
				return
	elif e is InputEventMouseMotion and _pegang >= 0:
		_meja[_pegang]["p"] = e.position
	elif lepas(e) and _pegang >= 0:
		var b: Dictionary = _meja[_pegang]
		var p: Vector2 = b["p"]
		var masuk: = ""
		for s in SEKAT:
			if _kotak_sekat(s).grow(10).has_point(p):
				masuk = s
		if masuk == "" or (_isi[masuk] as Array).size() >= 3:
			if masuk != "":
				kilat(_kotak_sekat(masuk).get_center(), "Penuh!", Color.WHITE)
			b["p"] = b["asal"]
			_pegang = -1
			return
		var benar: = _jenis_ke_sekat(String(b["jenis"])) == masuk
		if benar:
			(_isi[masuk] as Array).append(String(b["id"]))
			tambah_skor(1, _titik_slot(masuk, (_isi[masuk] as Array).size() - 1))
			GameState.bunyi("kresek", -4.0)
		else:
			tambah_skor(-1, p)
			_goyang[masuk] = 1.0
			var kata: = "Pecah!" if b["jenis"] == "rapuh" else ("Menindih!" if b["jenis"] == "berat" else "Salah tempat!")
			kilat(p + Vector2(0, -50), kata, Color(1, 0.4, 0.35))
			percik(p, Color(1, 0.95, 0.8) if b["jenis"] == "rapuh" else Color(0.6, 0.5, 0.4), 12, 5.0)
		_meja[_pegang] = {}
		_meja[_pegang] = _barang_baru(b["asal"])
		_pegang = -1
		if SEKAT.all( func(s): return (_isi[s] as Array).size() >= 3):
			kilat(KARDUS.get_center() + Vector2(0, -40), "Kardus penuh!", GH.KUNING)
			percik(KARDUS.get_center(), GH.KUNING, 24, 6.0)
			_isi = {"atas": [], "tengah": [], "bawah": []}
			_kardus_baru = 1.0

			for i in _meja.size():
				_meja[i] = {}
			for i in MEJA_BARANG.size():
				_meja[i] = _barang_baru(MEJA_BARANG[i])




func _gambar() -> void :
	gradasi(Rect2(Vector2.ZERO, UKURAN), Color(0.42, 0.28, 0.17), Color(0.3, 0.19, 0.1))

	kotak_bulat(Rect2(20, 30, 410, 380), Color(0.62, 0.45, 0.28), 18, 14)
	for i in 5:
		kanvas.draw_line(Vector2(30, 70 + i * 72), Vector2(420, 70 + i * 72), Color(0.4, 0.27, 0.15, 0.4), 3)
	teks(Vector2(225, 46), "BELANJAAN", 22, Color(1, 0.95, 0.85), 300, 4)
	_kardus()
	for i in _meja.size():
		if i != _pegang and not _meja[i].is_empty():
			_barang(_meja[i], 1.0, false)
	if _pegang >= 0 and not _meja[_pegang].is_empty():
		_barang(_meja[_pegang], 1.15, true)


func _kardus() -> void :
	var geser: = Vector2(_kardus_baru * 600.0, 0)
	var r: = Rect2(KARDUS.position + geser, KARDUS.size)
	bayangan(r.get_center() + Vector2(0, r.size.y / 2.0), r.size.x * 1.05, 0.35)

	kanvas.draw_colored_polygon(PackedVector2Array([r.position + Vector2(-30, -8), r.position + Vector2(10, 18), r.position + Vector2(10, 40), r.position + Vector2(-40, 10)]), Color(0.72, 0.52, 0.3))
	kanvas.draw_colored_polygon(PackedVector2Array([r.position + Vector2(r.size.x + 30, -8), r.position + Vector2(r.size.x - 10, 18), r.position + Vector2(r.size.x - 10, 40), r.position + Vector2(r.size.x + 40, 10)]), Color(0.72, 0.52, 0.3))
	kotak_bulat(r, Color(0.78, 0.58, 0.35), 10, 10)
	kotak_bulat(r.grow(-10), Color(0.6, 0.42, 0.24), 8)
	kanvas.draw_rect(Rect2(r.position + Vector2(r.size.x / 2.0 - 30, 0), Vector2(60, 14)), Color(0.85, 0.75, 0.55, 0.7))
	for s in SEKAT:
		var k: = _kotak_sekat(s)
		k.position += geser
		var goyang: = Vector2(sin(Time.get_ticks_msec() * 0.07) * 8.0 * float(_goyang.get(s, 0.0)), 0)
		k.position += goyang
		var w: Color = WARNA_SEKAT[s]
		kotak_bulat(k, Color(w, 0.22), 10)
		garis_bulat(k, Color(w, 0.8), 10, 3)
		kanvas.draw_string(GH.cetak(), k.position + Vector2(14, 34), GameState.tk(NAMA_SEKAT[s].split(" · ")[0]), HORIZONTAL_ALIGNMENT_LEFT, 170, 28, w.lightened(0.3))
		kanvas.draw_string(GH.cetak(), k.position + Vector2(14, 62), GameState.tk(NAMA_SEKAT[s].split(" · ")[1]), HORIZONTAL_ALIGNMENT_LEFT, 170, 20, Color(1, 1, 1, 0.85))
		var isi: Array = _isi[s]
		for n in 3:
			var p: = _titik_slot(s, n) + geser + goyang
			if n < isi.size():
				bayangan(p + Vector2(0, 34), 70, 0.3)
				gambar_tekstur("res://assets/barang/%s.png" % String(isi[n]), p, 84)
			else:
				kanvas.draw_arc(p, 34, 0, TAU, 28, Color(1, 1, 1, 0.3), 2)


func _barang(b: Dictionary, skala: float, diangkat: bool) -> void :
	var p: Vector2 = b["p"]
	bayangan(p + Vector2(4, UKURAN_BARANG * (0.55 if diangkat else 0.42)), UKURAN_BARANG * 0.9 * skala, 0.4 if diangkat else 0.3)
	gambar_tekstur("res://assets/barang/%s.png" % String(b["id"]), p, UKURAN_BARANG * skala)

	var label: String = {"berat": "BERAT", "biasa": "", "rapuh": "MUDAH PECAH"}[String(b["jenis"])]
	if label != "":
		teks(p + Vector2(0, UKURAN_BARANG * 0.55 * skala), label, 16, WARNA_SEKAT[_jenis_ke_sekat(String(b["jenis"]))], 160, 4)
