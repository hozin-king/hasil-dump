extends "res://scripts/minigame/mg_dasar.gd"












const PECAHAN: = [5000, 10000, 20000, 50000]
const BULAT: = 5000
const BAYAR: = [10000, 20000, 50000, 100000]
const BARANG_STRUK: = ["mi_goreng", "telur", "gula", "beras", "minyak_goreng", "kopi_susu", "teh_botol", "sabun", "deterjen", "biskuit", "air_mineral", "kerupuk", "susu_kotak", "sachet", "ciki", "roti"]
const STRUK: = Rect2(18, 16, 330, 398)
const LACI: = Rect2(372, 16, 650, 196)
const BAKI: = Rect2(372, 228, 650, 186)
const TOMBOL_KOSONG: = Rect2(860, 362, 150, 42)

var _belanja: = []
var _total: = 0
var _bayar: = 0
var _baki: = []
var _terbang: = []
var _guncang_baki: = 0.0
var _nomor: = 0
var _lembar: = {}
var _hemat: = 0
const LEBIH_LEMBAR: = 1


func _siapkan() -> void :
	cahaya_25d = {"dari": Vector2(560, -80), "warna": Color(1, 0.9, 0.62), "kuat": 1.0}
	judul = "Hitung kembalian kilat"
	petunjuk = "Klik uang di laci sampai isi baki sama dengan KEMBALIAN, pakai lembar sesedikit mungkin. Isi laci terbatas!"
	durasi = 24.0
	target = 7.0
	contoh = {"jenis": "ketuk", "dari": _kotak_pecahan(1).get_center(), "ke": _kotak_pecahan(1).get_center(), "teks": "Klik uang untuk kembalian"}
	_pembeli_baru()


func _pembeli_baru() -> void :
	_nomor += 1
	_belanja.clear()
	_baki.clear()
	var pilihan: = BARANG_STRUK.filter( func(id): return GameState.katalog.has(id) and ResourceLoader.exists("res://assets/barang/%s.png" % id))

	for coba in 20:
		pilihan.shuffle()
		_belanja.clear()
		_total = 0
		for i in randi_range(2, 3):
			var id: String = pilihan[i]
			var n: = randi_range(1, 3)
			_belanja.append([id, n])
			_total += _harga(id) * n
		_total = maxi(int(round(_total / float(BULAT))) * BULAT, BULAT)
		if _total < BAYAR[-1]:
			break
	_total = mini(_total, BAYAR[-1] - BULAT)
	var cukup: = BAYAR.filter( func(b): return b > _total)

	_bayar = cukup[0] if randf() < 0.6 or cukup.size() == 1 else cukup[1]
	_isi_laci()




func _isi_laci() -> void :
	var sisa: = _kembalian()
	var hemat: = {}
	_hemat = 0
	for i in range(PECAHAN.size() - 1, -1, -1):
		var p: int = PECAHAN[i]
		hemat[p] = sisa / p
		sisa -= hemat[p] * p
		_hemat += hemat[p]
	_lembar = {
		5000: mini(int(hemat[5000]) + randi_range(0, 1), 2), 
		10000: int(hemat[10000]) + randi_range(0, 2), 
		20000: int(hemat[20000]) + randi_range(1, 2), 
		50000: int(hemat[50000]) + randi_range(0, 1), 
	}


func _harga(id: String) -> int:
	var h: = GameState.harga_jual(id) if GameState.katalog.has(id) else 0
	return h if h > 0 else 3000


func _kembalian() -> int:
	return _bayar - _total


func _isi_baki() -> int:
	var n: = 0
	for p in _baki:
		n += int(p)
	return n


func _kotak_pecahan(i: int) -> Rect2:

	return Rect2(LACI.position + Vector2(16 + i * 156, 44), Vector2(146, 136))


func _main(delta: float) -> void :
	for t in _terbang:
		t[2] += delta * 3.5
	_terbang = _terbang.filter( func(t): return t[2] < 1.0)
	_guncang_baki = maxf(_guncang_baki - delta * 3.0, 0.0)


func _masukan(e: InputEvent) -> void :
	if not tekan_awal(e):
		return
	var p: Vector2 = e.position
	if TOMBOL_KOSONG.has_point(p):
		if not _baki.is_empty():
			_kembalikan_baki()
			GameState.klik()
		return
	for i in PECAHAN.size():
		var r: = _kotak_pecahan(i)
		if not r.has_point(p):
			continue
		var nilai: int = PECAHAN[i]
		if int(_lembar.get(nilai, 0)) <= 0:
			kilat(r.get_center() + Vector2(0, -50), "Habis!", Color(1, 0.75, 0.4))
			return
		_lembar[nilai] = int(_lembar[nilai]) - 1
		_baki.append(nilai)
		_terbang.append([nilai, r.get_center(), 0.0])
		GameState.klik()
		var isi: = _isi_baki()
		if isi == _kembalian():
			if _baki.size() <= _hemat + LEBIH_LEMBAR:
				tambah_skor(1, BAKI.get_center() + Vector2(0, -30))
				kilat(BAKI.get_center() + Vector2(0, -80), "Pas!", GH.HIJAU_UANG)
			else:

				skor += 0.5
				_perbarui_skor()
				kilat(BAKI.get_center() + Vector2(0, -80), "Kok receh semua, Pak?", GH.KUNING)
			percik(BAKI.get_center(), GH.HIJAU_UANG, 18, 6.0)
			GameState.bunyi("koin")
			_pembeli_baru()
		elif isi > _kembalian():
			tambah_skor(-1, BAKI.get_center())
			kilat(BAKI.get_center() + Vector2(0, -70), "Kelebihan!", Color(1, 0.4, 0.35))
			_guncang_baki = 1.0
			_kembalikan_baki()
		return


func _kembalikan_baki() -> void :
	for p in _baki:
		_lembar[int(p)] = int(_lembar.get(int(p), 0)) + 1
	_baki.clear()




func _gambar() -> void :
	_meja_kasir()
	_struk()
	_laci()
	_baki_kembalian()
	for t in _terbang:
		var w: float = ease(float(t[2]), -2.0)
		var tujuan: = BAKI.get_center() + Vector2(-120 + (_baki.size() - 1) * 26, 10)
		var p: Vector2 = (t[1] as Vector2).lerp(tujuan, w) + Vector2(0, - sin(w * PI) * 60)
		_uang(int(t[0]), p, 0.75 + 0.25 * (1.0 - w), 1.0)


func _meja_kasir() -> void :
	gradasi(Rect2(Vector2.ZERO, UKURAN), Color(0.45, 0.3, 0.18), Color(0.32, 0.2, 0.11))
	var acak: = RandomNumberGenerator.new()
	acak.seed = 7
	for i in 9:
		var y: = 20.0 + i * 48.0
		var titik: = PackedVector2Array()
		for x in range(0, int(UKURAN.x) + 40, 40):
			titik.append(Vector2(x, y + sin(x * 0.015 + i) * 4.0 + acak.randf_range(-1, 1)))
		kanvas.draw_polyline(titik, Color(0.22, 0.13, 0.06, 0.25), 2)


func _struk() -> void :

	kanvas.draw_set_transform(STRUK.get_center(), -0.025, Vector2.ONE)
	var r: = Rect2( - STRUK.size / 2.0, STRUK.size)
	kotak_bulat(r.grow(2), Color(0, 0, 0, 0.25), 6, 14)
	kotak_bulat(r, Color(0.99, 0.97, 0.9), 6)
	var gerigi: = PackedVector2Array([r.position + Vector2(0, r.size.y)])
	for i in 23:
		gerigi.append(r.position + Vector2(i * r.size.x / 22.0, r.size.y + (8.0 if i % 2 == 0 else 0.0)))
	kanvas.draw_polyline(gerigi, Color(0.85, 0.82, 0.74), 2)
	var x0: = r.position.x + 20
	var y: = r.position.y + 34
	teks(Vector2(0, y), ("WARUNG %s" % GameState.nama_warung.to_upper()).left(22) if GameState.nama_warung != "" else "STRUK BELANJA", 22, Color(0.25, 0.2, 0.15), r.size.x - 20)
	y += 22
	kanvas.draw_dashed_line(Vector2(x0, y), Vector2( - x0, y), Color(0.4, 0.35, 0.3, 0.6), 2, 6)
	y += 16
	for b in _belanja:
		gambar_tekstur("res://assets/barang/%s.png" % String(b[0]), Vector2(x0 + 26, y + 26), 50)
		var nama: = String(GameState.data_barang(String(b[0])).get("sebutan", GameState.data_barang(String(b[0]))["nama"]))
		nama = GameState.tk(nama)
		nama = nama.left(1).to_upper() + nama.substr(1)
		kanvas.draw_string(GH.cetak(), Vector2(x0 + 62, y + 22), nama if nama.length() <= 18 else nama.left(16) + ".", HORIZONTAL_ALIGNMENT_LEFT, 200, 20, Color(0.25, 0.2, 0.15))
		kanvas.draw_string(GH.cetak(), Vector2(x0 + 62, y + 46), GameState.tk("x%d" % int(b[1])), HORIZONTAL_ALIGNMENT_LEFT, 200, 22, Color(0.55, 0.4, 0.25))
		y += 60
	y = r.position.y + 250
	kanvas.draw_dashed_line(Vector2(x0, y), Vector2( - x0, y), Color(0.4, 0.35, 0.3, 0.6), 2, 6)
	kanvas.draw_string(GH.cetak(), Vector2(x0, y + 34), GameState.tk("TOTAL"), HORIZONTAL_ALIGNMENT_LEFT, 140, 26, Color(0.25, 0.2, 0.15))
	kanvas.draw_string(GH.cetak(), Vector2(x0, y + 34), GameState.tk(GameState.format_rupiah(_total)), HORIZONTAL_ALIGNMENT_RIGHT, r.size.x - 40, 30, Color(0.7, 0.15, 0.1))
	kanvas.draw_string(GH.cetak(), Vector2(x0, y + 72), GameState.tk("DIBAYAR"), HORIZONTAL_ALIGNMENT_LEFT, 140, 22, Color(0.25, 0.2, 0.15))
	kanvas.draw_string(GH.cetak(), Vector2(x0, y + 72), GameState.tk(GameState.format_rupiah(_bayar)), HORIZONTAL_ALIGNMENT_RIGHT, r.size.x - 40, 26, Color(0.15, 0.4, 0.2))
	kotak_bulat(Rect2(x0 - 6, y + 90, r.size.x - 28, 44), Color(1, 0.86, 0.3), 10)

	teks(Vector2(0, y + 112), "KEMBALIAN %s" % GameState.format_rupiah(_kembalian()), 26, Color(0.3, 0.18, 0.05), r.size.x - 40)
	kanvas.draw_set_transform(Vector2.ZERO)


func _laci() -> void :
	kotak_bulat(LACI, Color(0.16, 0.16, 0.18), 16, 16)
	kotak_bulat(LACI.grow(-6), Color(0.24, 0.24, 0.27), 12)
	teks(LACI.position + Vector2(LACI.size.x / 2.0, 18), "LACI KAS  ·  klik uangnya", 20, GH.KUNING, LACI.size.x)
	for i in PECAHAN.size():
		var r: = _kotak_pecahan(i)
		kotak_bulat(r, Color(0.1, 0.1, 0.11), 10)
		var n: = int(_lembar.get(int(PECAHAN[i]), 0))

		for k in mini(n, 3):
			_uang(int(PECAHAN[i]), r.get_center() + Vector2(0, 14 - k * 10), 0.92, 1.0)
		if n <= 0:
			teks(r.get_center() + Vector2(0, 6), "habis", 20, Color(1, 1, 1, 0.35), r.size.x)

		kotak_bulat(Rect2(r.position + Vector2(r.size.x - 50, 6), Vector2(44, 28)), Color(0, 0, 0, 0.6) if n > 0 else Color(0.6, 0.15, 0.1, 0.8), 8)
		teks(r.position + Vector2(r.size.x - 28, 20), "x%d" % n, 18, GH.KUNING if n > 0 else Color.WHITE, 44)


func _baki_kembalian() -> void :
	var geser: = Vector2(sin(Time.get_ticks_msec() * 0.06) * 10.0 * _guncang_baki, 0)
	var r: = Rect2(BAKI.position + geser, BAKI.size)
	kotak_bulat(r, Color(0.55, 0.62, 0.66), 22, 16)
	kotak_bulat(r.grow(-10), Color(0.72, 0.79, 0.82), 16)
	kotak_bulat(r.grow(-18), Color(0.64, 0.71, 0.75), 12)
	teks(r.position + Vector2(150, 26), "BAKI KEMBALIAN", 20, Color(0.2, 0.25, 0.3), 260)
	for i in _baki.size():
		var tiba: = i < _baki.size() - _terbang.size()
		if tiba:
			_uang(int(_baki[i]), r.get_center() + Vector2(-120 + i * 26, 10 + (i % 2) * 6), 0.75, 1.0)
	var isi: = _isi_baki()
	kotak_bulat(Rect2(r.position + Vector2(r.size.x - 270, 14), Vector2(256, 46)), Color(0.12, 0.12, 0.14, 0.9), 12)
	kanvas.draw_string(GH.cetak(), r.position + Vector2(r.size.x - 260, 48), GameState.tk("Isi:"), HORIZONTAL_ALIGNMENT_LEFT, 80, 24, Color(1, 1, 1, 0.8))
	kanvas.draw_string(GH.cetak(), r.position + Vector2(r.size.x - 200, 48), GameState.tk(GameState.format_rupiah(isi)), HORIZONTAL_ALIGNMENT_RIGHT, 180, 28, GH.KUNING)
	kotak_bulat(TOMBOL_KOSONG, Color(0.75, 0.25, 0.2) if not _baki.is_empty() else Color(0.4, 0.35, 0.35), 12)
	teks(TOMBOL_KOSONG.get_center(), "Kosongkan", 20, Color.WHITE, TOMBOL_KOSONG.size.x)






const WARNA_UANG: = {2000: Color(0.56, 0.6, 0.62), 5000: Color(0.6, 0.47, 0.28), 10000: Color(0.55, 0.33, 0.58), 
	20000: Color(0.33, 0.58, 0.38), 50000: Color(0.25, 0.45, 0.72)}


func _uang(nilai: int, p: Vector2, skala: float, alfa: float) -> void :
	if nilai <= 1000:
		_koin(nilai, p, skala, alfa)
		return
	var warna: Color = WARNA_UANG[nilai]
	var ukuran: = Vector2(150, 64) * skala
	var r: = Rect2(p - ukuran / 2.0, ukuran)
	kotak_bulat(Rect2(r.position + Vector2(3, 4), r.size), Color(0, 0, 0, 0.3 * alfa), 5)
	kotak_bulat(r, Color(warna.lightened(0.35), alfa), 5)

	var garis: = Color(warna.darkened(0.1), 0.35 * alfa)
	for k in 5:
		var titik: = PackedVector2Array()
		for x in range(0, int(ukuran.x) + 1, 6):
			var y: = ukuran.y * (0.15 + k * 0.18) + sin(x * 0.12 + k) * 3.0 * skala
			titik.append(r.position + Vector2(x, y))
		kanvas.draw_polyline(titik, garis, maxf(1.0, 1.2 * skala))

	var pita: = Rect2(r.position + Vector2(ukuran.x * 0.56, 0), Vector2(ukuran.x * 0.44, ukuran.y))
	kotak_bulat(pita, Color(warna, 0.85 * alfa), 5)

	var m: = r.position + Vector2(ukuran.x * 0.24, ukuran.y * 0.5)
	var jari: = ukuran.y * 0.3
	kanvas.draw_circle(m, jari * 1.18, Color(warna.lightened(0.15), 0.9 * alfa))
	kanvas.draw_arc(m, jari * 1.18, 0, TAU, 32, Color(warna.darkened(0.25), alfa), maxf(1.0, 1.6 * skala))
	for a in 4:
		var arah: = Vector2.from_angle(a * PI / 2.0 + PI / 4.0)
		var kelopak: = PackedVector2Array()
		for t in 16:
			var sudut: = t * TAU / 16.0
			var lokal: = Vector2(cos(sudut) * jari * 0.48, sin(sudut) * jari * 0.26)
			kelopak.append(m + arah * jari * 0.5 + lokal.rotated(arah.angle()))
		kanvas.draw_colored_polygon(kelopak, Color(warna.darkened(0.3), 0.85 * alfa))
	kanvas.draw_circle(m, jari * 0.14, Color(1, 1, 1, 0.8 * alfa))

	var angka: = "%d.000" % int(nilai / 1000)
	teks(pita.get_center() + Vector2(0, 3 * skala), angka, int(21 * skala), Color(1, 1, 1, alfa), pita.size.x, 4)
	teks(pita.position + Vector2(pita.size.x / 2.0, 9 * skala), "RUPIAH", int(10 * skala), Color(1, 1, 1, 0.85 * alfa), pita.size.x)
	teks(r.position + Vector2(ukuran.x * 0.24, ukuran.y - 8 * skala), str(nilai / 1000), int(11 * skala), Color(warna.darkened(0.4), alfa), 40)
	garis_bulat(r, Color(warna.darkened(0.35), alfa), 5, 2)



func _koin(nilai: int, p: Vector2, skala: float, alfa: float) -> void :
	var jari: = 27.0 * skala
	var perak: = Color(0.83, 0.85, 0.87, alfa)
	kanvas.draw_circle(p + Vector2(2, 3), jari, Color(0, 0, 0, 0.3 * alfa))
	kanvas.draw_circle(p, jari, perak.darkened(0.3))
	kanvas.draw_circle(p, jari - 2.5 * skala, perak)
	if nilai == 1000:
		var emas: = Color(0.88, 0.74, 0.38, alfa)
		kanvas.draw_circle(p, jari * 0.66, emas.darkened(0.25))
		kanvas.draw_circle(p, jari * 0.62, emas)
		teks(p + Vector2(0, -1), "1000", int(15 * skala), Color(0.35, 0.25, 0.08, alfa), 60)
	else:
		for a in 5:
			kanvas.draw_circle(p + Vector2.from_angle(a * TAU / 5.0 - PI / 2.0) * jari * 0.42, jari * 0.2, Color(perak.darkened(0.12), alfa))
		kanvas.draw_circle(p, jari * 0.16, Color(perak.darkened(0.2), alfa))
		teks(p + Vector2(0, jari * 0.62), "500", int(12 * skala), Color(0.3, 0.3, 0.32, alfa), 60)
	kanvas.draw_arc(p, jari - 5 * skala, 0, TAU, 32, Color(perak.darkened(0.2), alfa), maxf(1.0, 1.4 * skala))
	kanvas.draw_arc(p + Vector2(-2, -2), jari - 3 * skala, deg_to_rad(200), deg_to_rad(280), 12, Color(1, 1, 1, 0.6 * alfa), 2)
