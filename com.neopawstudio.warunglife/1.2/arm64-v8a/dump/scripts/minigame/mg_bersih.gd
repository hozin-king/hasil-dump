extends "res://scripts/minigame/mg_dasar.gd"






const SAJADAH: = Rect2(170, 45, 700, 340)



const JARAK_SIKAT: = 44.0
const GOSOK_PENUH: = 380.0
const GOSOK_MAKS_PER_GERAK: = 34.0
const NODA_PER_SAJADAH: = 5
const WARNA_SAJADAH: = [[Color(0.62, 0.12, 0.14), Color(0.85, 0.65, 0.3)], [Color(0.1, 0.38, 0.3), Color(0.9, 0.78, 0.4)], 
	[Color(0.15, 0.25, 0.5), Color(0.85, 0.75, 0.45)]]

var _noda: = []
var _tekan: = false
var _sikat: = Vector2(-200, -200)
var _sikat_lama: = Vector2.ZERO
var _geser: = 0.0
var _nomor: = 0
var _serpih: = []


func _siapkan() -> void :
	judul = "Bersih-bersih masjid"
	petunjuk = "Tahan & gosok noda di sajadah dengan sikat sampai bersih!"
	if varian == "ibu":
		petunjuk = "Tahan & gosok noda di sajadah saf perempuan sampai bersih!"
	target = 18.0
	contoh = {"jenis": "gosok", "dari": SAJADAH.get_center() + Vector2(-120, 0), "ke": Vector2.ZERO, "teks": "Tahan lalu gosok bolak-balik"}
	_sajadah_baru(false)


func _sajadah_baru(geser: = true) -> void :
	_noda.clear()
	for i in NODA_PER_SAJADAH:
		var p: = Vector2.ZERO
		for coba in 20:
			p = Vector2(randf_range(SAJADAH.position.x + 70, SAJADAH.end.x - 70), randf_range(SAJADAH.position.y + 60, SAJADAH.end.y - 60))
			if _noda.all( func(n): return (n["p"] as Vector2).distance_to(p) > 110):
				break
		var bentuk: = []
		for b in 6:
			bentuk.append([Vector2.from_angle(randf() * TAU) * randf_range(8, 26), randf_range(16, 30)])
		_noda.append({"p": p, "kotor": 1.0, "bentuk": bentuk, 
			"warna": [Color(0.35, 0.25, 0.15), Color(0.28, 0.22, 0.18), Color(0.45, 0.32, 0.18)].pick_random()})
	if geser:
		_geser = UKURAN.x
		_nomor += 1


func _main(delta: float) -> void :
	_geser = move_toward(_geser, 0.0, delta * 2600.0)
	for s in _serpih:
		s[1] += delta
	_serpih = _serpih.filter( func(s): return s[1] < 0.4)


func _masukan(e: InputEvent) -> void :
	if tekan_awal(e):
		_tekan = true
		_sikat = e.position
		_sikat_lama = e.position
	elif lepas(e):
		_tekan = false
	elif e is InputEventMouseMotion:
		_sikat = e.position
		if _tekan and _geser < 1.0:
			_gosok(_sikat_lama, e.position)
		_sikat_lama = e.position


func _gosok(a: Vector2, b: Vector2) -> void :
	var jarak: = a.distance_to(b)
	if jarak < 1.0:
		return
	for n in _noda:
		if float(n["kotor"]) <= 0.0:
			continue
		var p: Vector2 = n["p"]
		var kena: = _panjang_dalam_lingkaran(a, b, p, JARAK_SIKAT)
		if kena > 0.0:
			n["kotor"] = float(n["kotor"]) - minf(kena, GOSOK_MAKS_PER_GERAK) / GOSOK_PENUH
			if randf() < 0.5:
				_serpih.append([b + Vector2(randf_range(-20, 20), randf_range(-10, 10)), 0.0])
			if float(n["kotor"]) <= 0.0:
				n["kotor"] = 0.0
				percik(p, Color(1, 1, 0.85), 12, 4.0)
				tambah_skor(1, p)
	if _noda.all( func(n): return float(n["kotor"]) <= 0.0):
		kilat(SAJADAH.get_center() + Vector2(0, -60), "Sajadah bersih!", GH.KUNING)
		_sajadah_baru()



func _panjang_dalam_lingkaran(a: Vector2, b: Vector2, pusat: Vector2, jari: float) -> float:
	var d: = b - a
	var f: = a - pusat
	var aa: = d.dot(d)
	if aa < 0.0001:
		return 0.0
	var bb: = 2.0 * f.dot(d)
	var cc: = f.dot(f) - jari * jari
	var disk: = bb * bb - 4.0 * aa * cc
	if disk <= 0.0:
		return 0.0
	var akar: = sqrt(disk)
	var t1: = clampf(( - bb - akar) / (2.0 * aa), 0.0, 1.0)
	var t2: = clampf(( - bb + akar) / (2.0 * aa), 0.0, 1.0)
	return (t2 - t1) * sqrt(aa)


func _gambar() -> void :
	_lantai()
	kanvas.draw_set_transform(Vector2(_geser, 0))
	_sajadah()
	for n in _noda:
		_gambar_noda(n)
	kanvas.draw_set_transform(Vector2.ZERO)
	_cahaya_jendela()
	for s in _serpih:
		kanvas.draw_circle(s[0] + Vector2(0, -20 * float(s[1])), 3.0, Color(0.85, 0.8, 0.7, 1.0 - float(s[1]) / 0.4))
	if main and _tekan:
		_gambar_sikat(_sikat)




func _lantai() -> void :
	gradasi(Rect2(Vector2.ZERO, UKURAN), Color(0.84, 0.82, 0.77), Color(0.66, 0.63, 0.58))

	for x in range(0, int(UKURAN.x) + 1, 130):
		kanvas.draw_line(Vector2(x, 0), Vector2(x, UKURAN.y), Color(0.5, 0.48, 0.44, 0.55), 2)
		kanvas.draw_line(Vector2(x + 2, 0), Vector2(x + 2, UKURAN.y), Color(1, 1, 1, 0.25), 1)
	for y in range(0, int(UKURAN.y) + 1, 130):
		kanvas.draw_line(Vector2(0, y), Vector2(UKURAN.x, y), Color(0.5, 0.48, 0.44, 0.55), 2)
		kanvas.draw_line(Vector2(0, y + 2), Vector2(UKURAN.x, y + 2), Color(1, 1, 1, 0.25), 1)

	for i in 5:
		kanvas.draw_circle(Vector2(UKURAN.x / 2.0, -80), 240 + i * 80, Color(1, 0.96, 0.8, 0.04))
	for i in 3:
		bayangan(Vector2(UKURAN.x * 0.5, 30), 520 - i * 140, 0.0)
	kanvas.draw_colored_polygon(_elips_titik(Vector2(UKURAN.x * 0.12, UKURAN.y * 0.8), 70, 18), Color(1, 1, 1, 0.12))



func _cahaya_jendela() -> void :
	var waktu: = Time.get_ticks_msec() / 1000.0
	var redup: = 0.9 + sin(waktu * 0.7) * 0.1
	for j in 3:
		var kiri: = 60.0 + j * 300.0
		var bawah: = UKURAN.y - 10.0
		var atas: = 30.0
		var lebar: = 120.0
		var miring: = 110.0
		var titik: = PackedVector2Array()
		titik.append(Vector2(kiri + miring, bawah))
		titik.append(Vector2(kiri + miring + lebar, bawah))
		for sgm in 11:
			var a: = float(sgm) / 10.0 * PI
			titik.append(Vector2(kiri + lebar / 2.0 + cos(a) * lebar / 2.0, atas + 50 - sin(a) * 50))
		kanvas.draw_colored_polygon(titik, Color(1, 0.94, 0.72, 0.13 * redup))

		kanvas.draw_line(Vector2(kiri + lebar / 2.0, atas), Vector2(kiri + miring + lebar / 2.0, bawah), Color(0.3, 0.25, 0.15, 0.08), 6)

	for d in 14:
		var x: = fposmod(d * 83.0 + waktu * 9.0, UKURAN.x)
		var y: = fposmod(d * 47.0 - waktu * 6.0, UKURAN.y)
		kanvas.draw_circle(Vector2(x, y), 1.6, Color(1, 0.97, 0.85, 0.35))


func _elips_titik(p: Vector2, rx: float, ry: float) -> PackedVector2Array:
	var t: = PackedVector2Array()
	for i in 24:
		var a: = i * TAU / 24.0
		t.append(p + Vector2(cos(a) * rx, sin(a) * ry))
	return t


func _sajadah() -> void :
	var w: Array = WARNA_SAJADAH[_nomor % WARNA_SAJADAH.size()]
	var dasar: Color = w[0]
	var emas: Color = w[1]
	var r: = SAJADAH

	kotak_bulat(Rect2(r.position + Vector2(14, 16), r.size), Color(0, 0, 0, 0.18), 10)
	kotak_bulat(Rect2(r.position + Vector2(5, 7), r.size), dasar.darkened(0.55), 6)
	kotak_bulat(r, dasar.darkened(0.25), 6, 14.0)

	for y in range(int(r.position.y) + 6, int(r.end.y) - 4, 9):
		kanvas.draw_line(Vector2(r.position.x, y), Vector2(r.position.x - 16, y), emas.lightened(0.3), 3)
		kanvas.draw_line(Vector2(r.end.x, y), Vector2(r.end.x + 16, y), emas.lightened(0.3), 3)
	var dalam: = r.grow(-14)

	kanvas.draw_polygon(PackedVector2Array([dalam.position, Vector2(dalam.end.x, dalam.position.y), dalam.end, Vector2(dalam.position.x, dalam.end.y)]), 
		PackedColorArray([dasar.lightened(0.12), dasar, dasar.darkened(0.18), dasar.darkened(0.04)]))
	for x in range(int(dalam.position.x) + 4, int(dalam.end.x), 7):
		kanvas.draw_line(Vector2(x, dalam.position.y + 2), Vector2(x, dalam.end.y - 2), Color(0, 0, 0, 0.05), 1)

	kanvas.draw_rect(dalam.grow(-1), Color(0, 0, 0, 0.35), false, 4)
	kanvas.draw_rect(Rect2(dalam.position - Vector2(1, 1), dalam.size), emas, false, 4)
	kanvas.draw_line(dalam.position + Vector2(0, -2), Vector2(dalam.end.x, dalam.position.y - 2), emas.lightened(0.45), 1)
	kanvas.draw_rect(dalam.grow(-12), emas.darkened(0.15), false, 2)

	for x in range(int(dalam.position.x) + 30, int(dalam.end.x) - 20, 34):
		for y in [dalam.position.y + 6.0, dalam.end.y - 6.0]:
			kanvas.draw_colored_polygon(PackedVector2Array([Vector2(x, y - 5), Vector2(x + 6, y), Vector2(x, y + 5), Vector2(x - 6, y)]), emas)

	var dasar_mihrab: = Vector2(dalam.end.x - 40, dalam.get_center().y)
	var lengkung: = PackedVector2Array()
	for s in 21:
		var a: = - PI / 2.0 + PI * s / 20.0
		lengkung.append(dasar_mihrab + Vector2(cos(a) * 120 - 120, sin(a) * 110))
	lengkung.append(dasar_mihrab + Vector2(-330, 110))
	lengkung.append(dasar_mihrab + Vector2(-330, -110))
	kanvas.draw_colored_polygon(lengkung, dasar.lightened(0.12))
	lengkung.append(lengkung[0])
	var bayang: = PackedVector2Array()
	for t in lengkung:
		bayang.append(t + Vector2(2, 3))
	kanvas.draw_polyline(bayang, Color(0, 0, 0, 0.35), 4)
	kanvas.draw_polyline(lengkung, emas, 4)
	var lampu: = dasar_mihrab + Vector2(-110, 0)
	kanvas.draw_line(lampu + Vector2(60, 0), lampu + Vector2(20, 0), emas, 2)
	kanvas.draw_colored_polygon(PackedVector2Array([lampu + Vector2(20, -16), lampu + Vector2(-20, -10), lampu + Vector2(-20, 10), lampu + Vector2(20, 16)]), emas)
	for i in 3:
		kanvas.draw_circle(dalam.position + Vector2(90, 80 + i * 90), 18, emas.darkened(0.1))
		kanvas.draw_circle(dalam.position + Vector2(90, 80 + i * 90), 8, dasar)


func _gambar_noda(n: Dictionary) -> void :
	var k: = float(n["kotor"])
	if k <= 0.0:
		return
	var c: Color = n["warna"]
	c.a = 0.25 + 0.65 * k
	var p: Vector2 = n["p"]
	for b in n["bentuk"]:
		kanvas.draw_circle(p + (b[0] as Vector2) + Vector2(1.5, 2), float(b[1]) * (0.7 + 0.3 * k) + 2.0, Color(c.darkened(0.35), c.a * 0.6))
	for b in n["bentuk"]:
		kanvas.draw_circle(p + (b[0] as Vector2), float(b[1]) * (0.7 + 0.3 * k), c)

	kanvas.draw_circle(p + Vector2(-10, -10), 7.0 * k, Color(1, 1, 1, 0.22 * k))

	for b in n["bentuk"]:
		kanvas.draw_circle(p + (b[0] as Vector2) * 2.2, 4.0, Color(c, c.a * 0.8))


func _gambar_sikat(p: Vector2) -> void :
	var goyang: = sin(Time.get_ticks_msec() / 40.0) * 6.0 if _tekan else 0.0
	kanvas.draw_set_transform(p + Vector2(goyang, 0), -0.35)
	bayangan(Vector2(16, 34), 130, 0.3)

	for i in 14:
		kanvas.draw_line(Vector2(-52 + i * 8, 10), Vector2(-52 + i * 8, 26), Color(0.78, 0.68, 0.38), 4)
		kanvas.draw_line(Vector2(-53 + i * 8, 10), Vector2(-53 + i * 8, 22), Color(1, 0.94, 0.66), 1.5)
	kotak_bulat(Rect2(-60, -10, 120, 24), Color(0.42, 0.25, 0.12), 10, 4.0)
	kotak_bulat(Rect2(-60, -14, 120, 22), Color(0.62, 0.4, 0.21), 10)
	kotak_bulat(Rect2(-56, -13, 112, 7), Color(0.82, 0.6, 0.38), 6)
	for serat in 3:
		kanvas.draw_line(Vector2(-48 + serat * 6, -3 + serat * 3), Vector2(44 - serat * 8, -3 + serat * 3), Color(0.45, 0.27, 0.12, 0.35), 1)
	kotak_bulat(Rect2(-22, -40, 44, 30), Color(0.44, 0.26, 0.12), 12)
	kotak_bulat(Rect2(-18, -38, 22, 24), Color(0.62, 0.4, 0.22), 10)
	kanvas.draw_set_transform(Vector2.ZERO)
