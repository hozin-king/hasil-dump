extends "res://scripts/minigame/mg_dasar.gd"





const KOLOM: = 9
const BARIS: = 3
const JARAK_TEBAS: = 36.0
const TUMBUH: = 2.2
const Y_BARIS: = [190.0, 290.0, 395.0]

var _rumpun: = []
var _jejak: = []
var _tekan: = false
var _titik_akhir: = Vector2.ZERO


func _siapkan() -> void :
	judul = "Panen padi Abah Karta"
	petunjuk = "Geser jari di atas padi KUNING untuk menebas. Padi HIJAU jangan ikut ditebas!"
	target = 34.0
	contoh = {"jenis": "geser", "dari": Vector2(80, 245), "ke": Vector2(620, 245), "teks": "Geser menebas padi kuning"}
	for b in BARIS:
		var skala: float = [0.78, 0.9, 1.05][b]
		for k in KOLOM:
			var p: = Vector2(70 + k * 112 + (56 if b % 2 == 1 else 0) + randf_range(-8, 8), Y_BARIS[b])
			if p.x < UKURAN.x - 30:
				_rumpun.append({"p": p, "matang": randf() < 0.68, "tebas": 0.0, "goyang": randf() * TAU, "skala": skala, 
					"hijau": 0.0, "batas": randf_range(HIJAU_MENGUNING.x, HIJAU_MENGUNING.y)})





const MIN_KUNING: = 8
const HIJAU_MENGUNING: = Vector2(3.0, 6.0)


func _main(delta: float) -> void :
	var kuning: = 0
	var hijau_tertua: Dictionary = {}
	for r in _rumpun:
		if float(r["tebas"]) > 0.0:
			r["tebas"] = float(r["tebas"]) + delta
			if float(r["tebas"]) > TUMBUH:
				r["tebas"] = 0.0
				r["matang"] = randf() < 0.68
				r["hijau"] = 0.0
				r["batas"] = randf_range(HIJAU_MENGUNING.x, HIJAU_MENGUNING.y)
		elif not r["matang"]:
			r["hijau"] = float(r.get("hijau", 0.0)) + delta
			if float(r["hijau"]) >= float(r.get("batas", HIJAU_MENGUNING.y)):
				r["matang"] = true
			elif hijau_tertua.is_empty() or float(r["hijau"]) > float(hijau_tertua["hijau"]):
				hijau_tertua = r
		if float(r["tebas"]) == 0.0 and r["matang"]:
			kuning += 1

	if kuning < MIN_KUNING and not hijau_tertua.is_empty():
		hijau_tertua["matang"] = true
	for j in _jejak:
		j[1] += delta
	_jejak = _jejak.filter( func(j): return j[1] < 0.22)


func _masukan(e: InputEvent) -> void :
	if tekan_awal(e):
		_tekan = true
		_titik_akhir = e.position
	elif lepas(e):
		_tekan = false
	elif e is InputEventMouseMotion and _tekan:
		_tebas(_titik_akhir, e.position)
		_titik_akhir = e.position
		_jejak.append([e.position, 0.0])


func _tebas(a: Vector2, b: Vector2) -> void :
	for r in _rumpun:
		if float(r["tebas"]) > 0.0:
			continue
		var p: Vector2 = r["p"] + Vector2(0, -40 * float(r["skala"]))
		if Geometry2D.get_closest_point_to_segment(p, a, b).distance_to(p) < JARAK_TEBAS * float(r["skala"]):
			r["tebas"] = 0.001
			if r["matang"]:
				percik(p, Color(0.98, 0.82, 0.3), 14, 4.0)
			else:
				percik(p, Color(0.45, 0.78, 0.3), 10, 4.0)
			tambah_skor(1 if r["matang"] else -1, p)


func _gambar() -> void :
	var waktu: = Time.get_ticks_msec() / 1000.0


	kanvas.draw_polygon(PackedVector2Array([Vector2.ZERO, Vector2(UKURAN.x, 0), Vector2(UKURAN.x, 150), Vector2(0, 150)]), 
		PackedColorArray([Color(0.42, 0.66, 0.9), Color(0.62, 0.8, 0.95), Color(1.0, 0.9, 0.72), Color(0.86, 0.88, 0.85)]))

	for i in 6:
		kanvas.draw_circle(MATAHARI, 40.0 + i * 22.0, Color(1, 0.93, 0.7, 0.16 - i * 0.022))
	kanvas.draw_circle(MATAHARI, 34, Color(1, 0.96, 0.8))
	for i in 4:
		var a: = 2.35 + i * 0.16 + sin(waktu * 0.3 + i) * 0.02
		var ujung: = MATAHARI + Vector2(cos(a), sin(a)) * 900.0
		var samping: = Vector2(cos(a), sin(a)).orthogonal() * (26.0 + i * 8.0)
		kanvas.draw_colored_polygon(PackedVector2Array([MATAHARI, ujung + samping, ujung - samping]), Color(1, 0.95, 0.75, 0.05))

	_bukit(118.0, 58.0, Color(0.58, 0.72, 0.68), 0.004, 1.0)
	_bukit(136.0, 42.0, Color(0.42, 0.6, 0.45), 0.007, 2.0)
	_pohon_jauh()
	kanvas.draw_polygon(PackedVector2Array([Vector2(0, 104), Vector2(UKURAN.x, 104), Vector2(UKURAN.x, 150), Vector2(0, 150)]), 
		PackedColorArray([Color(1, 1, 1, 0.0), Color(1, 0.97, 0.9, 0.0), Color(1, 0.97, 0.9, 0.35), Color(1, 1, 1, 0.35)]))

	gradasi(Rect2(0, 145, UKURAN.x, UKURAN.y - 145), Color(0.62, 0.72, 0.5), Color(0.33, 0.44, 0.22))
	for b in Y_BARIS.size():
		var y: float = Y_BARIS[b]
		var tebal: float = [10.0, 13.0, 16.0][b]

		kanvas.draw_polygon(PackedVector2Array([Vector2(0, y - 30), Vector2(UKURAN.x, y - 30), Vector2(UKURAN.x, y + 4), Vector2(0, y + 4)]), 
			PackedColorArray([Color(0.62, 0.78, 0.86, 0.35), Color(0.95, 0.9, 0.75, 0.55), Color(0.55, 0.7, 0.75, 0.55), Color(0.45, 0.6, 0.62, 0.45)]))
		for k in 7:
			var kx: = fposmod(k * 157.0 + waktu * (14.0 + b * 4.0), UKURAN.x + 80.0) - 40.0
			kanvas.draw_line(Vector2(kx, y - 12 + k % 3 * 6), Vector2(kx + 26 + b * 6, y - 12 + k % 3 * 6), Color(1, 1, 0.92, 0.35), 2.0)

		kanvas.draw_rect(Rect2(0, y + 4, UKURAN.x, tebal * 0.45), Color(0.66, 0.54, 0.34))
		kanvas.draw_rect(Rect2(0, y + 4 + tebal * 0.45, UKURAN.x, tebal * 0.55), Color(0.4, 0.29, 0.16))
		kanvas.draw_rect(Rect2(0, y + 4 + tebal, UKURAN.x, 5), Color(0, 0, 0, 0.18))
		kanvas.draw_line(Vector2(0, y + 5), Vector2(UKURAN.x, y + 5), Color(0.86, 0.74, 0.5, 0.8), 2.0)
	for r in _rumpun:
		_gambar_rumpun(r, waktu)

	_rumput_depan(waktu)
	kanvas.draw_polygon(PackedVector2Array([Vector2(UKURAN.x * 0.55, 0), Vector2(UKURAN.x, 0), Vector2(UKURAN.x, UKURAN.y), Vector2(UKURAN.x * 0.55, UKURAN.y)]), 
		PackedColorArray([Color(1, 0.9, 0.6, 0.0), Color(1, 0.9, 0.6, 0.12), Color(1, 0.9, 0.6, 0.05), Color(1, 0.9, 0.6, 0.0)]))
	for sisi in [0.0, 1.0]:
		var x0: float = sisi * (UKURAN.x - 90.0)
		var gelap_kiri: = Color(0, 0, 0, 0.22 if sisi == 0.0 else 0.0)
		var gelap_kanan: = Color(0, 0, 0, 0.0 if sisi == 0.0 else 0.12)
		kanvas.draw_polygon(PackedVector2Array([Vector2(x0, 0), Vector2(x0 + 90, 0), Vector2(x0 + 90, UKURAN.y), Vector2(x0, UKURAN.y)]), 
			PackedColorArray([gelap_kiri, gelap_kanan, gelap_kanan, gelap_kiri]))

	for i in range(1, _jejak.size()):
		var a: = 1.0 - float(_jejak[i][1]) / 0.22
		kanvas.draw_line(_jejak[i - 1][0], _jejak[i][0], Color(1, 1, 0.85, a * 0.45), 16)
		kanvas.draw_line(_jejak[i - 1][0], _jejak[i][0], Color(1, 1, 1, a), 5)


const MATAHARI: = Vector2(880, 62)
var _mesh_pohon: ArrayMesh
var _mesh_rumput: ArrayMesh



func _pohon_jauh() -> void :
	if _mesh_pohon == null:
		var v: = PackedVector2Array()
		var c: = PackedColorArray()
		var warna: = Color(0.36, 0.5, 0.44, 0.85)
		var x: = 20.0
		while x < UKURAN.x:
			var y: = 140.0 + sin(x * 0.03) * 3.0
			if int(x) % 3 == 0:
				var t: = 28.0 + fmod(x * 7.3, 14.0)
				_garis(v, c, Vector2(x, y), Vector2(x + 4, y - t), 2.2, warna)
				for d in 5:
					var a: = - PI + d * PI / 4.0
					_garis(v, c, Vector2(x + 4, y - t), Vector2(x + 4, y - t) + Vector2(cos(a) * 13, sin(a) * 6 + 4), 2.6, warna)
			else:
				_elips(v, c, Vector2(x, y - 6), 16.0, 8.0, warna.darkened(0.05), 10)
			x += 23.0 + fmod(x * 3.1, 17.0)
		_mesh_pohon = _jadi_mesh(v, c)
	kanvas.draw_mesh(_mesh_pohon, null)



func _rumput_depan(waktu: float) -> void :
	if _mesh_rumput == null:
		var v: = PackedVector2Array()
		var c: = PackedColorArray()
		var x: = -10.0
		while x < UKURAN.x + 10:
			var tinggi: = 26.0 + fmod(x * 5.7, 22.0)
			var miring: = fmod(x * 1.3, 14.0) - 7.0
			v.append_array([Vector2(x - 5, 0), Vector2(x + 5, 0), Vector2(x + miring, - tinggi)])
			c.append_array([Color(0.12, 0.2, 0.08, 0.95), Color(0.12, 0.2, 0.08, 0.95), Color(0.3, 0.45, 0.16, 0.9)])
			x += 9.0 + fmod(x * 2.3, 6.0)
		_mesh_rumput = _jadi_mesh(v, c)
	var goyang: = sin(waktu * 1.4) * 0.05
	kanvas.draw_mesh(_mesh_rumput, null, Transform2D(Vector2(1, 0), Vector2(goyang, 1), Vector2(0, UKURAN.y + 2)))





var _mesh_matang: ArrayMesh
var _mesh_hijau: ArrayMesh
var _mesh_tebas: ArrayMesh
var _mesh_bayang: ArrayMesh
var _titik_bukit: = []


func _bukit(dasar: float, tinggi: float, warna: Color, rapat: float, geser: float) -> void :
	var kunci: = int(dasar)
	for b in _titik_bukit:
		if b[0] == kunci:
			kanvas.draw_colored_polygon(b[1], warna)
			return
	var titik: = PackedVector2Array([Vector2(0, 150)])
	for i in 41:
		var x: = UKURAN.x * i / 40.0
		titik.append(Vector2(x, dasar - tinggi * (0.5 + 0.5 * sin(x * rapat + geser) * cos(x * rapat * 0.37))))
	titik.append(Vector2(UKURAN.x, 150))
	_titik_bukit.append([kunci, titik])
	kanvas.draw_colored_polygon(titik, warna)


func _gambar_rumpun(r: Dictionary, waktu: float) -> void :
	if _mesh_matang == null:
		_mesh_bayang = _buat_mesh_bayang()
		_mesh_matang = _buat_mesh(true)
		_mesh_hijau = _buat_mesh(false)
		_mesh_tebas = _buat_mesh_tebas()
	var p: Vector2 = r["p"]
	var s: = float(r["skala"])
	if float(r["tebas"]) > 0.0:
		kanvas.draw_mesh(_mesh_tebas, null, Transform2D(Vector2(s, 0), Vector2(0, s), p))
		return
	var miring: = sin(waktu * 1.8 + float(r["goyang"])) * 5.0 / 110.0

	kanvas.draw_mesh(_mesh_bayang, null, Transform2D(Vector2(s, 0), Vector2((0.95 + miring * 0.6) * s, 0.3 * s), p + Vector2(0, 2)))
	var kabut: = lerpf(0.78, 1.0, inverse_lerp(0.78, 1.05, s))
	kanvas.draw_mesh(_mesh_matang if r["matang"] else _mesh_hijau, null, Transform2D(Vector2(s, 0), Vector2( - miring * s, s), p), 
		Color(kabut, kabut, kabut * 1.02, 1.0).lerp(Color(0.86, 0.9, 0.95), 1.0 - kabut))


func _buat_mesh(matang: bool) -> ArrayMesh:
	var v: = PackedVector2Array()
	var c: = PackedColorArray()
	_elips(v, c, Vector2(0, 2), 26.0, 8.0, Color(0, 0, 0, 0.28), 16)

	var batang_bawah: = Color(0.18, 0.3, 0.1) if not matang else Color(0.42, 0.36, 0.14)
	var batang_atas: = Color(0.5, 0.78, 0.32) if not matang else Color(0.92, 0.78, 0.34)
	var bulir: = Color(1.0, 0.82, 0.3) if matang else Color(0.58, 0.88, 0.38)
	var bulir_gelap: = bulir.darkened(0.35)
	for urut in [0, 6, 1, 5, 2, 4, 3]:
		var i: int = urut
		var arah: = (i - 3) * 0.13
		var terang: = 1.0 + (i - 3) * 0.05
		var bawah: = Vector2((i - 3) * 4, 0)
		var tengah: = bawah + Vector2(arah * 40, -55)
		var atas: = tengah + Vector2(arah * 30 + (18 if matang else 6) * signf(arah + 0.01), -30 + (14 if matang else 0))
		var w_tengah: = batang_bawah.lerp(batang_atas, 0.65) * terang
		_garis2(v, c, bawah, tengah, 3.4, 2.8, batang_bawah, w_tengah)
		_garis2(v, c, tengah, atas, 2.8, 2.0, w_tengah, batang_atas * terang)
		for g in 6:
			var t: = 0.35 + g * 0.13
			var b: = tengah.lerp(atas, t) if t <= 1.0 else atas
			_elips(v, c, b + Vector2(-1.6, 1.6), 4.4, 4.0, bulir_gelap, 8)
			_elips(v, c, b, 3.7, 3.5, bulir * terang, 8)
			_elips(v, c, b + Vector2(1.1, -1.1), 1.4, 1.2, Color(1, 1, 0.92, 0.75), 6)
	return _jadi_mesh(v, c)



func _buat_mesh_bayang() -> ArrayMesh:

	var v: = PackedVector2Array()
	var c: = PackedColorArray()
	var pekat: = Color(0.04, 0.07, 0.02, 0.38)
	var pudar: = Color(0.04, 0.07, 0.02, 0.16)
	var n: = 14
	for i in n:
		var a1: = lerpf(-0.55, 0.55, float(i) / n)
		var a2: = lerpf(-0.55, 0.55, float(i + 1) / n)
		v.append_array([Vector2.ZERO, Vector2(sin(a1) * 70, - cos(a1) * 80), Vector2(sin(a2) * 70, - cos(a2) * 80)])
		c.append_array([pekat, pudar, pudar])
	return _jadi_mesh(v, c)



func _garis2(v: PackedVector2Array, c: PackedColorArray, a: Vector2, b: Vector2, tebal_a: float, tebal_b: float, warna_a: Color, warna_b: Color) -> void :
	var n: = (b - a).normalized().orthogonal()
	var na: = n * tebal_a * 0.5
	var nb: = n * tebal_b * 0.5
	v.append_array([a + na, b + nb, b - nb, a + na, b - nb, a - na])
	c.append_array([warna_a, warna_b, warna_b, warna_a, warna_b, warna_a])


func _buat_mesh_tebas() -> ArrayMesh:
	var v: = PackedVector2Array()
	var c: = PackedColorArray()
	_elips(v, c, Vector2(0, 2), 28.0, 9.8, Color(0, 0, 0, 0.25), 16)
	for i in 7:
		var x: = (i - 3) * 6.0
		_garis(v, c, Vector2(x, 0), Vector2(x + (i - 3) * 1.5, -12), 3.0, Color(0.62, 0.5, 0.28))
	return _jadi_mesh(v, c)


func _jadi_mesh(v: PackedVector2Array, c: PackedColorArray) -> ArrayMesh:
	var data: = []
	data.resize(Mesh.ARRAY_MAX)
	data[Mesh.ARRAY_VERTEX] = v
	data[Mesh.ARRAY_COLOR] = c
	var m: = ArrayMesh.new()
	m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, data)
	return m


func _elips(v: PackedVector2Array, c: PackedColorArray, pusat: Vector2, rx: float, ry: float, warna: Color, sisi: int) -> void :
	for i in sisi:
		var a1: = i * TAU / sisi
		var a2: = (i + 1) * TAU / sisi
		v.append_array([pusat, pusat + Vector2(cos(a1) * rx, sin(a1) * ry), pusat + Vector2(cos(a2) * rx, sin(a2) * ry)])
		c.append_array([warna, warna, warna])


func _garis(v: PackedVector2Array, c: PackedColorArray, a: Vector2, b: Vector2, tebal: float, warna: Color) -> void :
	var n: = (b - a).normalized().orthogonal() * tebal * 0.5
	v.append_array([a + n, b + n, b - n, a + n, b - n, a - n])
	c.append_array([warna, warna, warna, warna, warna, warna])
