extends "res://scripts/minigame/mg_dasar.gd"






const LAMA_LIHAT: = 4.5
const TAMBAH_LIHAT: = 0.5
const KOLOM: = 5
const SEL: = Vector2(176, 118)
const RAK: = Rect2(70, 168, 900, 250)
const TITIPAN: = ["Sekalian titipan Ibu, Pak!", "Oh iya, tetangga juga nitip!", "Satu lagi, buat di rumah!", "Eh, sama yang ini juga, Pak!"]

var _biasa: = []
var _rak: = []
var _lihat: = 0.0
var _ronde: = 0
var _ucapan: = ""
var _suka: = {}
var _goyang_sel: = {}


func _siapkan() -> void :
	cahaya_25d = {"dari": Vector2(520, -90), "warna": Color(1, 0.88, 0.6), "kuat": 1.0}
	judul = "Tebak pesanan langganan"
	petunjuk = "Ingat belanjaan biasanya, lalu klik barang yang sama di rak. Jangan salah pilih!"
	durasi = 34.0
	target = 14.0
	var semua: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/pelanggan.json"))
	for p in semua.get("pelanggan", []):
		if String(p["id"]) == npc:
			_suka = p.get("suka", {})
	_ronde_baru()
	contoh = {"jenis": "ketuk", "dari": _kotak_sel(0).get_center(), "ke": _kotak_sel(0).get_center(), "teks": "Hafalkan, lalu klik barangnya"}


func _barang_fisik() -> Array:
	return GameState.katalog.keys().filter( func(id): return not String(id).begins_with("data_") and not id in ["danda", "token_listrik"]\
	and ResourceLoader.exists("res://assets/barang/%s.png" % id))


func _ronde_baru() -> void :
	_ronde += 1
	var fisik: = _barang_fisik()

	var disukai: = fisik.filter( func(id): return float(_suka.get(id, 0.0)) >= 1.0)
	disukai.shuffle()
	var jumlah: = mini(2 + _ronde, 5)
	_biasa = disukai.slice(0, jumlah)
	var lain: = fisik.filter( func(id): return not id in _biasa)
	lain.shuffle()
	while _biasa.size() < jumlah:
		_biasa.append(lain.pop_back())
	var isi_rak: Array = _biasa.duplicate()

	var pengecoh: = lain.filter( func(id): return float(_suka.get(id, 0.0)) > 0.0)
	pengecoh.append_array(lain)
	for id in pengecoh:
		if isi_rak.size() >= KOLOM * 2:
			break
		if not id in isi_rak:
			isi_rak.append(id)
	isi_rak.shuffle()
	_rak.clear()
	for id in isi_rak:
		_rak.append({"id": id, "benar": id in _biasa, "status": ""})
	_lihat = LAMA_LIHAT + _ronde * TAMBAH_LIHAT
	_ucapan = "Yang biasa ya, Pak Misran!" if _ronde == 1 else String(TITIPAN[(_ronde - 2) % TITIPAN.size()])


func _kotak_sel(i: int) -> Rect2:
	return Rect2(RAK.position + Vector2((i % KOLOM) * SEL.x + 6, (i / KOLOM) * SEL.y + 6), SEL - Vector2(12, 12))


func _main(delta: float) -> void :
	if _lihat > 0.0:
		_lihat -= delta
	for k in _goyang_sel.keys():
		_goyang_sel[k] = maxf(float(_goyang_sel[k]) - delta * 3.0, 0.0)


func _masukan(e: InputEvent) -> void :
	if not tekan_awal(e) or _lihat > 0.0:
		return
	for i in _rak.size():
		if not _kotak_sel(i).has_point(e.position) or _rak[i]["status"] != "":
			continue
		var c: = _kotak_sel(i).get_center()
		if _rak[i]["benar"]:
			_rak[i]["status"] = "betul"
			tambah_skor(1, c)
		else:
			_rak[i]["status"] = "salah"
			_goyang_sel[i] = 1.0
			tambah_skor(-1, c)
			kilat(c + Vector2(0, -40), "Bukan itu, Pak!", Color(1, 0.4, 0.35))
		if _rak.all( func(r): return not r["benar"] or r["status"] == "betul"):
			kilat(RAK.get_center() + Vector2(0, -60), "Betul semua!", GH.KUNING)
			percik(RAK.get_center(), GH.KUNING, 22, 6.0)
			GameState.bunyi("koin")
			_ronde_baru()
		return




func _gambar() -> void :
	gradasi(Rect2(Vector2.ZERO, UKURAN), Color(0.36, 0.25, 0.16), Color(0.22, 0.14, 0.08))
	_rak_kayu()
	_gelembung()


func _gelembung() -> void :
	var r: = Rect2(70, 14, 900, 140)
	kotak_bulat(r, Color(1, 0.98, 0.93), 22, 12)
	kanvas.draw_colored_polygon(PackedVector2Array([r.position + Vector2(60, r.size.y - 2), r.position + Vector2(100, r.size.y - 2), r.position + Vector2(56, r.size.y + 24)]), Color(1, 0.98, 0.93))
	var nama: = String(GameState.daftar_warga().get(npc, "Warga"))
	kanvas.draw_string(GH.cetak(), r.position + Vector2(26, 38), GameState.tk(nama + ":"), HORIZONTAL_ALIGNMENT_LEFT, 300, 24, Color(0.2, 0.45, 0.75))
	kanvas.draw_string(GH.cetak(), r.position + Vector2(26, 72), GameState.tk(_ucapan), HORIZONTAL_ALIGNMENT_LEFT, 380, 26, Color(0.25, 0.18, 0.1))
	if _lihat > 0.0 or not main:

		for i in _biasa.size():
			var p: = r.position + Vector2(470 + i * 88, 62)
			kotak_bulat(Rect2(p - Vector2(40, 40), Vector2(80, 80)), Color(0.95, 0.9, 0.78), 12)
			gambar_tekstur("res://assets/barang/%s.png" % String(_biasa[i]), p, 70)
		var porsi: = clampf(_lihat / (LAMA_LIHAT + _ronde * TAMBAH_LIHAT), 0.0, 1.0) if main else 1.0
		kotak_bulat(Rect2(r.position + Vector2(26, 100), Vector2(380, 14)), Color(0, 0, 0, 0.12), 7)
		kotak_bulat(Rect2(r.position + Vector2(26, 100), Vector2(380 * porsi, 14)), Color(0.95, 0.6, 0.2), 7)
		kanvas.draw_string(GH.cetak(), r.position + Vector2(26, 134), GameState.tk("Hafalkan!"), HORIZONTAL_ALIGNMENT_LEFT, 380, 20, Color(0.6, 0.35, 0.1))
	else:
		for i in _biasa.size():
			var p: = r.position + Vector2(470 + i * 88, 62)
			var ketemu: = _rak.any( func(x): return x["id"] == _biasa[i] and x["status"] == "betul")
			kotak_bulat(Rect2(p - Vector2(40, 40), Vector2(80, 80)), Color(0.85, 0.8, 0.7) if not ketemu else Color(0.8, 0.95, 0.8), 12)
			if ketemu:
				gambar_tekstur("res://assets/barang/%s.png" % String(_biasa[i]), p, 70)
			else:
				teks(p, "?", 48, Color(0.55, 0.45, 0.35), 80)
		kanvas.draw_string(GH.cetak(), r.position + Vector2(26, 112), GameState.tk("Klik barangnya di rak"), HORIZONTAL_ALIGNMENT_LEFT, 400, 22, Color(0.3, 0.55, 0.3))


func _rak_kayu() -> void :
	kotak_bulat(RAK.grow(14), Color(0.5, 0.32, 0.17), 16, 14)
	kotak_bulat(RAK.grow(4), Color(0.36, 0.22, 0.11), 10)
	for baris in 2:
		var y: = RAK.position.y + (baris + 1) * SEL.y - 4
		kotak_bulat(Rect2(RAK.position.x - 8, y, RAK.size.x + 16, 14), Color(0.62, 0.42, 0.24), 4)
	for i in _rak.size():
		var k: = _kotak_sel(i)
		var g: = Vector2(sin(Time.get_ticks_msec() * 0.07) * 7.0 * float(_goyang_sel.get(i, 0.0)), 0)
		var st: = String(_rak[i]["status"])
		var latar: = Color(1, 1, 1, 0.08)
		if st == "betul":
			latar = Color(0.3, 0.8, 0.4, 0.45)
		elif st == "salah":
			latar = Color(0.9, 0.3, 0.25, 0.4)
		kotak_bulat(Rect2(k.position + g, k.size), latar, 12)
		bayangan(k.get_center() + g + Vector2(0, 42), 80, 0.3)
		gambar_tekstur("res://assets/barang/%s.png" % String(_rak[i]["id"]), k.get_center() + g + Vector2(0, -4), 92, Color(1, 1, 1, 0.45) if st == "salah" else Color.WHITE)
		if st == "betul":
			var c: = k.position + Vector2(k.size.x - 18, 18)
			kanvas.draw_circle(c, 15, Color(0.2, 0.65, 0.3))
			kanvas.draw_polyline(PackedVector2Array([c + Vector2(-7, 0), c + Vector2(-2, 6), c + Vector2(8, -6)]), Color.WHITE, 4)
