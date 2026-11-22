extends "res://scripts/minigame/mg_dasar.gd"









const JARI_KETUK: = 44.0
const TANAH: = 360.0
const KERANJANG: = Vector2(522, 380)
const LEBAR_KERANJANG: = 62.0
const LAMA_JATUH: = 0.6
const LAMA_KEMBALI: = 0.35
const UKURAN_SERET: = 62.0

const TEMPAT_KERANJANG: = [Vector2(-30, 6), Vector2(0, 8), Vector2(30, 6), Vector2(-15, -4), Vector2(15, -4), 
	Vector2(-38, -8), Vector2(38, -8), Vector2(0, -12), Vector2(-24, -18), Vector2(24, -18), Vector2(-8, -24), Vector2(10, -26)]



const GAYA: = {
	"kelapa": {"cy": 34, "rx": 112, "ry": 58, "palem": true, "daun": [Color(0.13, 0.36, 0.14), Color(0.22, 0.52, 0.2), Color(0.4, 0.68, 0.28)], 
		"batang": Color(0.56, 0.45, 0.33), "bentuk": "bulat", "muda": Color(0.5, 0.68, 0.3), "matang": Color(0.93, 0.6, 0.18), "r": 14.0}, 
	"jambu": {"cy": 172, "rx": 104, "ry": 80, "daun": [Color(0.12, 0.31, 0.15), Color(0.19, 0.44, 0.2), Color(0.32, 0.6, 0.27)], 
		"batang": Color(0.45, 0.32, 0.23), "bentuk": "lonceng", "muda": Color(0.82, 0.92, 0.72), "matang": Color(0.92, 0.15, 0.27), "r": 13.0}, 
	"sawo": {"cy": 168, "rx": 92, "ry": 94, "daun": [Color(0.19, 0.3, 0.13), Color(0.28, 0.41, 0.17), Color(0.43, 0.55, 0.25)], 
		"batang": Color(0.4, 0.35, 0.3), "bentuk": "bulat", "muda": Color(0.55, 0.62, 0.36), "matang": Color(0.58, 0.38, 0.22), "r": 13.0}, 
	"mangga": {"cy": 176, "rx": 118, "ry": 78, "daun": [Color(0.14, 0.36, 0.15), Color(0.23, 0.5, 0.22), Color(0.4, 0.67, 0.3)], 
		"batang": Color(0.36, 0.25, 0.18), "bentuk": "lonjong", "muda": Color(0.36, 0.6, 0.24), "matang": Color(0.98, 0.7, 0.16), "r": 12.0}, 
	"alpukat": {"cy": 168, "rx": 96, "ry": 94, "daun": [Color(0.17, 0.38, 0.19), Color(0.27, 0.53, 0.25), Color(0.45, 0.69, 0.33)], 
		"batang": Color(0.42, 0.31, 0.25), "bentuk": "pir", "muda": Color(0.6, 0.78, 0.36), "matang": Color(0.2, 0.33, 0.12), "r": 13.0}, 
}

var _pohon: = []
var _jatuh: = []
var _kembali: = []
var _di_keranjang: = []
var _seret: = {}
var _info: = {}
var _pantul_keranjang: = 0.0
var _waktu: = 0.0
var _matang_awal: = 0


func _siapkan() -> void :
	judul = "Kebun buah"
	petunjuk = "Buah yang sudah MATANG berwarna dan berkilau: tarik ke keranjang di bawah. Buah hijau belum matang, biarkan tumbuh. Pohon berbuah lagi beberapa hari sesudah dipetik."
	latar = "res://assets/peta/area_sawah.png"
	var data: = GameState.data_pohon()
	var ids: Array = data.keys().filter( func(id): return GAYA.has(String(id)))
	for k in ids.size():
		var id: = String(ids[k])
		var g: Dictionary = GAYA[id]
		var x: = UKURAN.x * (k + 0.5) / ids.size()
		var acak: = RandomNumberGenerator.new()
		acak.seed = hash("kebun_" + id)
		var pusat: = Vector2(x, float(g["cy"]))
		var rx: = float(g["rx"])
		var ry: = float(g["ry"])
		var daun: = []
		for i in 26:
			var a: = acak.randf() * TAU
			var r: = sqrt(acak.randf()) * 0.78
			daun.append([pusat + Vector2(cos(a) * r * rx, sin(a) * r * ry), rx * acak.randf_range(0.28, 0.42), 1])
		daun.sort_custom( func(a, b): return a[0].y < b[0].y)

		var tepi: = []
		for i in 22:
			var a: = TAU * i / 22.0 + acak.randf_range(-0.1, 0.1)
			tepi.append([pusat + Vector2(cos(a) * rx * 0.8, sin(a) * ry * 0.78), a, acak.randf_range(18, 26)])

		var n: = int(data[id].get("jumlah", 4))
		var buah: Array[Vector2] = []
		var coba: = 0
		if g.has("palem"):

			for kk in n:
				var a: = lerpf(-0.9, 0.9, float(kk) / maxf(n - 1, 1))
				buah.append(pusat + Vector2(sin(a) * 46.0, 30.0 + cos(a * 1.6) * 10.0))
			coba = 99999
		while buah.size() < n and coba < 2000:
			coba += 1
			var a: = acak.randf() * TAU
			var r: = sqrt(acak.randf())
			var p: = pusat + Vector2(cos(a) * r * rx * 0.78, sin(a) * r * ry * 0.62 + ry * 0.16)
			if buah.any( func(q): return q.distance_to(p) < (50.0 if coba < 1200 else 40.0)):
				continue
			buah.append(p)
		_pohon.append({"id": id, "x": x, "gaya": g, "daun": daun, "tepi": tepi, "buah": buah, "fase": acak.randf() * TAU})
	_matang_awal = GameState.jumlah_buah_matang()
	target = maxf(_matang_awal, 0)



func _mulai() -> void :
	_bar.get_parent().hide()
	sisa = 1000000000.0
	main = true
	_sudah_mulai = true
	var b: = Button.new()
	b.text = "Selesai"
	GH.gaya_tombol(b, true, 26)
	b.custom_minimum_size = Vector2(170, 56)
	b.position = Vector2(UKURAN.x - 184, 12)
	b.pressed.connect( func():
		if not main:
			return
		main = false
		b.hide()
		_akhiri())
	kanvas.get_parent().add_child(b)


func hasil() -> float:
	return 1.0 if target <= 0.0 else clampf(skor / target, 0.0, 1.0)



func _boleh_bonus_ganda() -> bool:
	return false


func _perbarui_skor() -> void :
	_label_skor.text = "%d/%d" % [int(skor), int(target)]


func _main(delta: float) -> void :
	_waktu += delta
	_pantul_keranjang = maxf(_pantul_keranjang - delta * 2.5, 0.0)
	for f in _jatuh:
		f[2] += delta
		if f[2] >= LAMA_JATUH:
			_di_keranjang.append([f[0], f[3]])
			_pantul_keranjang = 1.0
			percik(KERANJANG + Vector2(0, -6), GH.KUNING, 7, 4.0)
	_jatuh = _jatuh.filter( func(f): return f[2] < LAMA_JATUH)
	for f in _kembali:
		f[3] += delta
	_kembali = _kembali.filter( func(f): return f[3] < LAMA_KEMBALI)
	if not _info.is_empty():
		_info["umur"] = float(_info["umur"]) + delta
		if float(_info["umur"]) > 2.2:
			_info = {}


func _goyang(p: Dictionary) -> Vector2:
	return Vector2(sin(_waktu * 1.1 + float(p["fase"])) * 2.5, 0)


func _masukan(e: InputEvent) -> void :

	if not _seret.is_empty():
		if e is InputEventMouseMotion or e is InputEventScreenDrag:
			_seret["p"] = e.position
		elif lepas(e):
			_lepas_buah(e.position)
		return
	if not tekan_awal(e):
		return
	var ketuk: Vector2 = e.position
	var terdekat: = []
	var jarak: = JARI_KETUK
	for p in _pohon:
		var geser: = _goyang(p)
		var daftar: Array = p["buah"]
		for i in daftar.size():
			if _sedang_bergerak(p, i):
				continue
			var d: float = (daftar[i] + geser).distance_to(ketuk)
			if d < jarak:
				jarak = d
				terdekat = [p, i]
	if terdekat.is_empty():
		return
	var pohon: Dictionary = terdekat[0]
	var i: int = terdekat[1]
	var id: = String(pohon["id"])
	var titik: Vector2 = pohon["buah"][i] + _goyang(pohon)
	if GameState.buah_matang(id, i):

		_seret = {"pohon": pohon, "i": i, "id": String(GameState.data_pohon()[id].get("buah", id)), "p": ketuk}
		_info = {}
		GameState.klik()
		return

	var hari: = GameState.sisa_hari_buah(id, i)
	var kapan: = "Matang hari ini" if hari <= 0 else ("Matang besok" if hari == 1 else "Matang %d hari lagi" % hari)
	if GameState.tumbuh_buah(id, i) < 0.2:
		kapan = "Baru berbunga. " + kapan
	_info = {"p": titik, "baris1": "Belum matang", "baris2": kapan, "umur": 0.0}
	GameState.klik()



func _lepas_buah(p: Vector2) -> void :
	var pohon: Dictionary = _seret["pohon"]
	var i: int = _seret["i"]
	_seret = {}
	if Rect2(KERANJANG + Vector2( - LEBAR_KERANJANG - 50, -170), Vector2(LEBAR_KERANJANG * 2 + 100, 230)).has_point(p):

		var jenis_buah: = String(GameState.data_pohon()[String(pohon["id"])].get("buah", pohon["id"]))
		if GameState.sisa_muat_alam(jenis_buah, tangkapan) <= 0:
			_info = {"p": p, "baris1": "Tas penuh", "baris2": "Jual dulu ke Bu Ida di Pasar", "umur": 0.0}
			_kembali.append([pohon, i, p, 0.0])
			return
		var buah: = GameState.petik_buah_kebun(String(pohon["id"]), i)
		if buah != "":
			tangkapan.append(buah)
			GameState.tangkapan_tertunda = Array(tangkapan)
			var tempat: Vector2 = TEMPAT_KERANJANG[(_di_keranjang.size() + _jatuh.size()) % TEMPAT_KERANJANG.size()]
			_jatuh.append([buah, p, 0.0, tempat])
			tambah_skor(1, KERANJANG + Vector2(0, -60))
			return
	_kembali.append([pohon, i, p, 0.0])


func _sedang_bergerak(pohon: Dictionary, i: int) -> bool:
	if not _seret.is_empty() and _seret["pohon"] == pohon and int(_seret["i"]) == i:
		return true
	for f in _kembali:
		if f[0] == pohon and int(f[1]) == i:
			return true
	return false


func _isi_hasil_khusus(kolom: VBoxContainer, t: Label) -> bool:
	kolom.get_child(0).hide()
	kartu_hasil_alam(kolom, t, false, "Buah disimpan di Tas (buka HP). Jual ke Bu Ida di Pasar.", "Tidak ada buah yang dipetik. Buah yang sudah dipetik tumbuh lagi beberapa hari kemudian.")
	return true



func _gambar() -> void :

	gradasi(Rect2(0, 0, UKURAN.x, TANAH), Color(0.55, 0.78, 0.95), Color(0.85, 0.93, 0.9))
	for i in 7:
		kanvas.draw_circle(Vector2(i * 180 - 20, TANAH + 30), 150, Color(0.5, 0.7, 0.45, 0.55))
	gradasi(Rect2(0, TANAH - 6, UKURAN.x, UKURAN.y - TANAH + 6), Color(0.42, 0.66, 0.28), Color(0.3, 0.5, 0.2))
	for i in 60:
		var x: = fmod(i * 97.3, UKURAN.x)
		var y: = TANAH + fmod(i * 37.1, UKURAN.y - TANAH)
		kanvas.draw_line(Vector2(x, y), Vector2(x - 3, y - 9), Color(0.25, 0.48, 0.18), 2)
	for p in _pohon:
		_gambar_pohon(p)
	_gambar_keranjang()
	for f in _kembali:
		var pohon: Dictionary = f[0]
		var ke: Vector2 = pohon["buah"][int(f[1])] + _goyang(pohon)
		var t: = ease(float(f[3]) / LAMA_KEMBALI, -2.0)
		_buah_lukis(String(GameState.data_pohon()[String(pohon["id"])].get("buah", "")), (f[2] as Vector2).lerp(ke, t), lerpf(UKURAN_SERET, _ukuran_buah(pohon["gaya"]), t))
	if not _seret.is_empty():
		var q: Vector2 = _seret["p"] + Vector2(0, -10)
		bayangan(q + Vector2(6, 46), 44, 0.25)
		_buah_lukis(String(_seret["id"]), q, UKURAN_SERET * (1.0 + sin(_waktu * 9.0) * 0.03))

	var sisa_matang: = GameState.jumlah_buah_matang()
	var pesan: = ""
	if _matang_awal == 0:
		pesan = "Belum ada buah yang matang."
	elif sisa_matang == 0:
		pesan = "Semua buah yang matang sudah dipetik!"
	elif skor == 0:
		pesan = "Tarik buah yang berkilau ke keranjang"
	if pesan != "":
		teks(Vector2(UKURAN.x / 2.0 + 40, 34), pesan, 26, Color.WHITE, 620, 7)

	if skor == 0 and _waktu < 8.0 and _seret.is_empty():
		for p in _pohon:
			var ketemu: = false
			for i in (p["buah"] as Array).size():
				if GameState.buah_matang(String(p["id"]), i):
					var titik: Vector2 = p["buah"][i] + _goyang(p)
					var w: = fmod(_waktu, 1.8) / 1.8
					var ke: = KERANJANG + Vector2(0, -40)
					var q: = titik.lerp(ke, ease(clampf((w - 0.15) * 1.4, 0.0, 1.0), -2.0))
					kanvas.draw_dashed_line(titik, ke, Color(1, 1, 1, 0.45), 3, 10)
					if w > 0.15:
						_buah_lukis(String(GameState.data_pohon()[String(p["id"])].get("buah", "")), q, UKURAN_SERET * 0.8, Color(1, 1, 1, 0.75))
					_tangan(q + Vector2(6, 10))
					ketemu = true
					break
			if ketemu:
				break
	if not _info.is_empty():
		var a: = clampf((2.2 - float(_info["umur"])) * 3.0, 0.0, 1.0)
		var p: Vector2 = _info["p"] + Vector2(0, -52)
		p.x = clampf(p.x, 130, UKURAN.x - 130)
		kotak_bulat(Rect2(p - Vector2(120, 30), Vector2(240, 60)), Color(0, 0, 0, 0.72 * a), 12)
		teks(p + Vector2(0, -12), String(_info["baris1"]), 22, Color(1, 0.85, 0.4, a), 230)
		teks(p + Vector2(0, 12), String(_info["baris2"]), 18, Color(1, 1, 1, a), 230)


func _gambar_pohon(p: Dictionary) -> void :
	if p["gaya"].has("palem"):
		_gambar_kelapa(p)
		return
	var g: Dictionary = p["gaya"]
	var id: = String(p["id"])
	var x: = float(p["x"])
	var cy: = float(g["cy"])
	var rx: = float(g["rx"])
	var ry: = float(g["ry"])
	var geser: = _goyang(p)
	var warna: Array = g["daun"]
	var batang: Color = g["batang"]
	bayangan(Vector2(x, TANAH + 4), rx * 1.7, 0.28)

	var bawah: = TANAH + 6
	var atas: = cy + ry * 0.35
	kanvas.draw_colored_polygon(PackedVector2Array([Vector2(x - 22, bawah), Vector2(x - 12, bawah - 18), Vector2(x - 9, atas), Vector2(x + 9, atas), 
		Vector2(x + 12, bawah - 18), Vector2(x + 22, bawah)]), batang)
	kanvas.draw_line(Vector2(x - 5, bawah - 10), Vector2(x - 3, atas + 10), batang.darkened(0.25), 3)
	kanvas.draw_line(Vector2(x + 2, atas + 30), Vector2(x - rx * 0.45, cy + 6) + geser, batang, 8)
	kanvas.draw_line(Vector2(x, atas + 20), Vector2(x + rx * 0.4, cy) + geser, batang, 7)

	var pusat: = Vector2(x, cy) + geser
	for d in p["tepi"]:
		_daun(d[0] + geser + Vector2(0, 6), float(d[1]), float(d[2]), warna[0])
	for d in p["daun"]:
		kanvas.draw_circle(d[0] + geser + Vector2(0, 6), float(d[1]), warna[0])
	for d in p["tepi"]:
		_daun(d[0] + geser, float(d[1]), float(d[2]), warna[1])
	for d in p["daun"]:
		kanvas.draw_circle(d[0] + geser, float(d[1]) * 0.94, warna[1])
	for d in p["daun"]:
		var q: Vector2 = d[0] + geser
		if q.y < pusat.y + ry * 0.1 and q.x < pusat.x + rx * 0.3:
			kanvas.draw_circle(q + Vector2(-6, -8), float(d[1]) * 0.45, Color(warna[2], 0.4))

	var daftar: Array = p["buah"]
	for i in daftar.size():
		if not _sedang_bergerak(p, i):
			_gambar_buah(id, g, daftar[i] + geser, GameState.tumbuh_buah(id, i), GameState.buah_matang(id, i), i)

	var n_matang: = GameState.jumlah_buah_matang(id)
	var nama: = String(GameState.data_pohon()[id].get("nama", id))
	kotak_bulat(Rect2(x - 76, TANAH + 18, 152, 52), Color(0, 0, 0, 0.45), 12)
	teks(Vector2(x, TANAH + 32), nama, 22, Color.WHITE, 150)
	teks(Vector2(x, TANAH + 56), "%d/%d matang" % [n_matang, daftar.size()], 18, GH.KUNING if n_matang > 0 else Color(0.85, 0.85, 0.85), 150)



func _gambar_kelapa(p: Dictionary) -> void :
	var g: Dictionary = p["gaya"]
	var id: = String(p["id"])
	var x: = float(p["x"])
	var cy: = float(g["cy"])
	var geser: = _goyang(p)
	var warna: Array = g["daun"]
	var batang: Color = g["batang"]
	var puncak: = Vector2(x - 6, cy + 14) + geser * 1.6
	bayangan(Vector2(x + 6, TANAH + 4), 120, 0.25)

	var bawah: = Vector2(x + 14, TANAH + 6)
	var kendali: = Vector2(x + 30, (TANAH + cy) * 0.55)
	var n: = 16
	for k in n:
		var t0: = float(k) / n
		var t1: = float(k + 1) / n
		var a: = bawah.lerp(kendali, t0).lerp(kendali.lerp(puncak, t0), t0)
		var b: = bawah.lerp(kendali, t1).lerp(kendali.lerp(puncak, t1), t1)
		var tebal: = lerpf(24.0, 13.0, t0)
		kanvas.draw_line(a, b, batang.darkened(0.2), tebal + 4)
		kanvas.draw_line(a, b, batang, tebal)
		var arah: = (b - a).normalized().orthogonal()
		kanvas.draw_line(a - arah * tebal * 0.5, a + arah * tebal * 0.5, batang.darkened(0.3), 2)

	var sudut: = [-2.9, -2.4, -1.95, -1.2, -0.75, -0.25, 0.25, 2.65, 3.3]
	for lapis in 2:
		for i in sudut.size():
			if (i % 2) != lapis:
				continue
			_pelepah(puncak, float(sudut[i]) + sin(_waktu * 1.3 + i) * 0.04, 150.0 - absf(sin(float(sudut[i]))) * 40.0, warna[lapis], warna[2])
	kanvas.draw_circle(puncak, 16, batang.darkened(0.15))

	var daftar: Array = p["buah"]
	for i in daftar.size():
		if not _sedang_bergerak(p, i):
			_gambar_buah(id, g, daftar[i] + geser, GameState.tumbuh_buah(id, i), GameState.buah_matang(id, i), i)
	_label_pohon(p, x)



func _pelepah(pangkal: Vector2, sudut: float, panjang: float, warna: Color, terang: Color) -> void :
	var titik: = PackedVector2Array()
	var arah: = Vector2.from_angle(sudut)
	for k in 11:
		var t: = k / 10.0
		titik.append(pangkal + arah * panjang * t + Vector2(0, t * t * 55.0))
	for k in range(1, titik.size()):
		var a: Vector2 = titik[k - 1]
		var b: Vector2 = titik[k]
		var tegak: = (b - a).normalized().orthogonal()
		var lebar: = lerpf(24.0, 7.0, k / 10.0)
		kanvas.draw_colored_polygon(PackedVector2Array([a, a + tegak * lebar + Vector2(0, 10), b]), warna)
		kanvas.draw_colored_polygon(PackedVector2Array([a, a - tegak * lebar + Vector2(0, 10), b]), warna.darkened(0.12))
	kanvas.draw_polyline(titik, terang.darkened(0.35), 3)


func _label_pohon(p: Dictionary, x: float) -> void :
	var id: = String(p["id"])
	var n_matang: = GameState.jumlah_buah_matang(id)
	var nama: = String(GameState.data_pohon()[id].get("nama", id))
	var daftar: Array = p["buah"]
	kotak_bulat(Rect2(x - 76, TANAH + 18, 152, 52), Color(0, 0, 0, 0.45), 12)
	teks(Vector2(x, TANAH + 32), nama, 22, Color.WHITE, 150)
	teks(Vector2(x, TANAH + 56), "%d/%d matang" % [n_matang, daftar.size()], 18, GH.KUNING if n_matang > 0 else Color(0.85, 0.85, 0.85), 150)



func _daun(p: Vector2, sudut: float, panjang: float, warna: Color) -> void :
	var arah: = Vector2.from_angle(sudut)
	var samping: = arah.orthogonal() * panjang * 0.32
	var ujung: = p + arah * panjang
	var tengah: = p + arah * panjang * 0.45
	kanvas.draw_colored_polygon(PackedVector2Array([p - arah * 4, tengah + samping, ujung, tengah - samping]), warna)


func _gambar_buah(id: String, g: Dictionary, p: Vector2, tumbuh: float, matang: bool, i: int) -> void :

	if tumbuh < 0.2 and not matang:
		for k in 5:
			kanvas.draw_circle(p + Vector2.from_angle(k * TAU / 5.0) * 4.0, 3.2, Color(1, 0.97, 0.92))
		kanvas.draw_circle(p, 2.4, Color(0.98, 0.82, 0.25))
		return
	var r: float = float(g["r"]) * (lerpf(0.42, 0.82, (tumbuh - 0.2) / 0.8) if not matang else 1.0)

	var lukis: = String(GameState.info_hasil_alam(String(GameState.data_pohon()[id].get("buah", id))).get("ikon", ""))
	if tekstur(lukis) != null:
		var besar: = _ukuran_buah(g) * (lerpf(0.45, 0.8, (tumbuh - 0.2) / 0.8) if not matang else 1.0)
		if matang:
			besar *= 1.0 + sin(_waktu * 4.0 + i) * 0.04
			kanvas.draw_circle(p, besar * 0.62, Color(1, 0.95, 0.55, 0.2 + sin(_waktu * 3.0 + i) * 0.08))
		gambar_tekstur(lukis, p + Vector2(3, 4), besar, Color(0, 0, 0, 0.3))
		gambar_tekstur(lukis, p, besar, Color.WHITE if matang else Color(0.62, 0.86, 0.5).lerp(Color.WHITE, tumbuh * 0.3))
		if matang:
			_kilau(p + Vector2(besar * 0.32, - besar * 0.32), 7.0 + sin(_waktu * 5.0 + i * 1.7) * 2.5, _waktu * 1.5 + i)
		return
	var muda: Color = g["muda"]
	var warna: Color = muda.lerp(g["matang"], 0.35 * tumbuh) if not matang else g["matang"]
	if matang:

		r *= 1.0 + sin(_waktu * 4.0 + i) * 0.05
		kanvas.draw_circle(p + Vector2(0, r * 0.1), r * 1.35, Color(1, 0.95, 0.55, 0.18 + sin(_waktu * 3.0 + i) * 0.07))
	var tangkai: = 14.0 if String(g["bentuk"]) == "lonjong" else 7.0
	kanvas.draw_line(p + Vector2(0, - r * 0.8 - tangkai), p + Vector2(0, - r * 0.7), Color(0.32, 0.3, 0.15), 2)
	var gelap: = warna.darkened(0.3)
	match String(g["bentuk"]):
		"lonceng":
			var titik: = PackedVector2Array([p + Vector2( - r * 0.45, - r * 0.9), p + Vector2(r * 0.45, - r * 0.9), p + Vector2(r * 0.95, r * 0.55), 
				p + Vector2(r * 0.6, r * 0.95), p + Vector2(0, r * 0.75), p + Vector2( - r * 0.6, r * 0.95), p + Vector2( - r * 0.95, r * 0.55)])
			kanvas.draw_colored_polygon(_geser(titik, Vector2(1.5, 1.5)), gelap)
			kanvas.draw_colored_polygon(titik, warna)
		"bulat":
			kanvas.draw_circle(p + Vector2(1.5, 1.5), r, gelap)
			kanvas.draw_circle(p, r, warna)
			if matang:
				for k in 5:
					kanvas.draw_circle(p + Vector2.from_angle(k * 1.9 + i) * r * 0.55, 1.2, warna.darkened(0.35))
		"lonjong":
			_elips(p + Vector2(1.5, 1.5), r * 0.8, r * 1.3, gelap)
			_elips(p, r * 0.8, r * 1.3, warna)
			if matang:
				_elips(p + Vector2(r * 0.25, - r * 0.45), r * 0.45, r * 0.6, Color(0.93, 0.36, 0.2, 0.75))
		"pir":
			kanvas.draw_circle(p + Vector2(1.5, r * 0.35 + 1.5), r * 0.85, gelap)
			kanvas.draw_circle(p + Vector2(0, - r * 0.45), r * 0.55, warna)
			kanvas.draw_circle(p + Vector2(0, r * 0.35), r * 0.85, warna)
	if matang:
		_elips(p + Vector2( - r * 0.35, - r * 0.3), r * 0.22, r * 0.34, Color(1, 1, 1, 0.55))
		_kilau(p + Vector2(r * 0.9, - r * 0.9), 7.0 + sin(_waktu * 5.0 + i * 1.7) * 2.5, _waktu * 1.5 + i)


func _elips(p: Vector2, rx: float, ry: float, warna: Color) -> void :
	var titik: = PackedVector2Array()
	for k in 20:
		var a: = k * TAU / 20.0
		titik.append(p + Vector2(cos(a) * rx, sin(a) * ry))
	kanvas.draw_colored_polygon(titik, warna)


func _geser(titik: PackedVector2Array, d: Vector2) -> PackedVector2Array:
	var hasil_geser: = PackedVector2Array()
	for t in titik:
		hasil_geser.append(t + d)
	return hasil_geser



func _kilau(p: Vector2, r: float, putar: float) -> void :
	var titik: = PackedVector2Array()
	for k in 8:
		var a: = putar + k * TAU / 8.0
		titik.append(p + Vector2.from_angle(a) * (r if k % 2 == 0 else r * 0.3))
	kanvas.draw_colored_polygon(titik, Color(1, 1, 0.85, 0.95))


func _buah_ikon(id: String, p: Vector2, ukuran: float) -> void :
	gambar_tekstur(String(GameState.info_hasil_alam(id).get("ikon", "")), p, ukuran)



func _buah_lukis(id: String, p: Vector2, ukuran: float, warna: = Color.WHITE) -> void :
	var jalur: = String(GameState.info_hasil_alam(id).get("ikon", ""))
	gambar_tekstur(jalur, p + Vector2(3, 5), ukuran, Color(0, 0, 0, 0.3 * warna.a))
	gambar_tekstur(jalur, p, ukuran, warna)


func _ukuran_buah(g: Dictionary) -> float:
	return float(g["r"]) * 3.3





func _gambar_keranjang() -> void :
	var tekan: = sin(_pantul_keranjang * PI) * _pantul_keranjang
	var k: = KERANJANG
	var lebar: = LEBAR_KERANJANG * (1.0 + tekan * 0.06)
	var tinggi: = 46.0 * (1.0 - tekan * 0.08)
	var coklat: = Color(0.7, 0.48, 0.25)
	var gelap: = coklat.darkened(0.35)
	bayangan(k + Vector2(0, tinggi + 4), lebar * 2.6, 0.32)

	kanvas.draw_arc(k + Vector2(0, 2), lebar * 0.82, PI * 1.08, PI * 1.92, 20, coklat.darkened(0.1), 6)
	_elips(k, lebar, 13, gelap.darkened(0.2))
	_elips(k + Vector2(0, 2), lebar - 6, 9, Color(0.22, 0.13, 0.06))

	for b in _di_keranjang.slice(maxi(_di_keranjang.size() - TEMPAT_KERANJANG.size(), 0)):
		_buah_lukis(String(b[0]), k + (b[1] as Vector2), 40)
	for f in _jatuh:
		var t: float = f[2] / LAMA_JATUH
		var dari: Vector2 = f[1]
		var ke: Vector2 = k + (f[3] as Vector2)

		var u0: = clampf(t / 0.55, 0.0, 1.0)
		var x: = lerpf(dari.x, ke.x, u0)
		var y: = lerpf(dari.y, ke.y, u0 * u0)
		if t > 0.55:
			var u: = (t - 0.55) / 0.45
			y = ke.y - absf(sin(u * PI * 2.0)) * 18.0 * (1.0 - u)
		_buah_lukis(String(f[0]), Vector2(x, y), lerpf(UKURAN_SERET, 40, u0))

	var badan: = PackedVector2Array([k + Vector2(lebar, 0)])
	for j in range(1, 12):
		var a: = PI * j / 12.0
		badan.append(k + Vector2(cos(a) * lebar, sin(a) * 13))
	badan.append(k + Vector2( - lebar, 0))
	badan.append(k + Vector2( - lebar * 0.78, tinggi))
	badan.append(k + Vector2(lebar * 0.78, tinggi))
	kanvas.draw_colored_polygon(badan, coklat)

	for j in 4:
		var yy: = 14.0 + j * (tinggi - 16.0) / 3.0
		var w: = lerpf(lebar, lebar * 0.78, yy / tinggi)
		kanvas.draw_line(k + Vector2( - w + 3, yy), k + Vector2(w - 3, yy), gelap, 2.5)
	for j in 9:
		var xx: = - lebar * 0.85 + j * lebar * 0.85 / 4.0
		kanvas.draw_line(k + Vector2(xx, 11), k + Vector2(xx * 0.78, tinggi), coklat.darkened(0.2), 2)
	kanvas.draw_colored_polygon(PackedVector2Array([k + Vector2(lebar * 0.35, 12), k + Vector2(lebar, 0), k + Vector2(lebar * 0.78, tinggi), k + Vector2(lebar * 0.3, tinggi)]), Color(0, 0, 0, 0.16))

	kanvas.draw_arc(k, lebar, 0.0, PI, 24, coklat.lightened(0.12), 6)
	kanvas.draw_arc(k + Vector2(0, 1), lebar - 3, PI * 0.55, PI * 0.9, 10, Color(1, 0.9, 0.7, 0.5), 2)
