extends "res://scripts/minigame/mg_dasar.gd"












const LEBAR_SAK: = 150.0
const TINGGI_SAK: = 44.0
const DASAR_Y: = 360.0
const ATAS_Y: = 40.0
const PENUH: = 6
const GEROBAK_X: = 520.0

var _x: = 200.0
var _arah: = 1.0
var _jatuh: = false
var _y: = ATAS_Y
var _tumpukan: = []
var _sak_meleset: = []
var _geser_gerobak: = 0.0
var _sudut: = 0.0
var _kec_sudut: = 0.0
var _waktu_goyang: = 0.0


func _siapkan() -> void :
	judul = "Angkut material Mang Ujang"
	petunjuk = "Klik untuk menjatuhkan sak semen. Minimal setengah sak harus menapak, dan tumpukan yang terlalu miring bisa ambruk!"
	target = 10.0
	contoh = {"jenis": "ketuk", "dari": Vector2(GEROBAK_X, 230), "ke": Vector2.ZERO, "teks": "Klik saat sak tepat di atas tumpukan"}


const RATA: = 0.25
const MIRING_MAKS: = 0.5
const BAK_AMAN: = 95.0
const BAK_TEPI: = 135.0
const AMBRUK: = 0.42


func _kecepatan() -> float:
	return 600.0 + skor * 30.0



func _tidak_seimbang() -> float:
	if _tumpukan.is_empty():
		return 0.0
	var rata: = 0.0
	for x in _tumpukan:
		rata += float(x)
	return (rata / _tumpukan.size() - GEROBAK_X) / LEBAR_SAK


func _goyang(delta: float) -> void :
	_waktu_goyang += delta
	var berat: = _tidak_seimbang()
	var tinggi: = float(_tumpukan.size())
	var condong: = berat * 0.05 * tinggi
	var redam: = lerpf(5.0, 0.6, clampf(absf(berat) / AMBRUK, 0.0, 1.0))
	var kaku: = 38.0 / maxf(tinggi, 1.0)
	_kec_sudut += ( - kaku * (_sudut - condong) - redam * _kec_sudut) * delta

	_kec_sudut += sin(_waktu_goyang * 5.0) * absf(berat) * 0.5 * delta * tinggi
	_sudut = clampf(_sudut + _kec_sudut * delta, -0.35, 0.35)
	if _tumpukan.is_empty():
		_sudut = move_toward(_sudut, 0.0, delta)
		_kec_sudut = 0.0



func _pusat_sak(i: int, gx: float) -> Vector2:
	var lokal: = Vector2(float(_tumpukan[i]) - GEROBAK_X, - TINGGI_SAK * (i + 0.5))
	return Vector2(gx, DASAR_Y) + lokal.rotated(_sudut)


func _main(delta: float) -> void :
	_geser_gerobak = move_toward(_geser_gerobak, 0.0, delta * 1400.0)
	_goyang(delta)
	if not _jatuh:
		_x += _arah * _kecepatan() * delta
		if _x > UKURAN.x - 100 or _x < 100:
			_arah = - _arah
			_x = clampf(_x, 100, UKURAN.x - 100)
	else:
		_y += 1100.0 * delta
		var atas: = DASAR_Y - TINGGI_SAK * (_tumpukan.size() + 1)
		if _y >= atas:

			var acuan: float = _pusat_sak(_tumpukan.size() - 1, GEROBAK_X).x if not _tumpukan.is_empty() else GEROBAK_X
			var geser: = absf(_x - acuan) / LEBAR_SAK



			if _tumpukan.is_empty():
				var dx: = absf(_x - GEROBAK_X)
				geser = 0.0 if dx <= BAK_TEPI else MIRING_MAKS + 1.0

			var peluang_jatuh: = 0.0
			if geser <= MIRING_MAKS and randf() >= peluang_jatuh:

				var ly: = - TINGGI_SAK * (_tumpukan.size() + 0.5)
				var lx: = (_x - GEROBAK_X + ly * sin(_sudut)) / cos(_sudut)
				_tumpukan.append(GEROBAK_X + lx)

				_kec_sudut += (_x - acuan) / LEBAR_SAK * 0.9
				tambah_skor(1, Vector2(_x, atas))
				percik(Vector2(_x, atas + TINGGI_SAK), Color(0.85, 0.82, 0.75), 12, 6.0)
				if _ambruk():
					pass
				elif _tumpukan.size() >= PENUH:
					kilat(Vector2(GEROBAK_X, 90), "Gerobak penuh!", GH.KUNING)
					_tumpukan.clear()
					_geser_gerobak = -700.0
			else:

				_sak_meleset.append([_x, atas, 0.0, signf(_x - acuan)])
				tambah_skor(-1, Vector2(_x, atas + 40))
				kilat(Vector2(_x, atas), "Meleset", Color(1, 0.4, 0.35))
			_jatuh = false
			_y = ATAS_Y
	for s in _sak_meleset:
		s[0] += s[3] * 160.0 * delta
		s[1] += 650.0 * delta
		s[2] += s[3] * 5.0 * delta
	_sak_meleset = _sak_meleset.filter( func(s): return s[1] < UKURAN.y + 80)



func _ambruk() -> bool:
	if _tumpukan.size() < 3:
		return false
	var rata: = 0.0
	for x in _tumpukan:
		rata += float(x)
	rata /= _tumpukan.size()
	if absf(rata - GEROBAK_X) / LEBAR_SAK < AMBRUK:
		return false
	var arah: = signf(rata - GEROBAK_X)
	for i in _tumpukan.size():
		var p: = _pusat_sak(i, GEROBAK_X)
		_sak_meleset.append([p.x, p.y - TINGGI_SAK / 2.0, _sudut, arah * (0.6 + i * 0.25)])
	_tumpukan.clear()
	tambah_skor(-2, Vector2(GEROBAK_X, DASAR_Y - 120))
	kilat(Vector2(GEROBAK_X, 90), "Tumpukan ambruk!", Color(1, 0.4, 0.35))
	return true


func _masukan(e: InputEvent) -> void :
	if tekan_awal(e) and not _jatuh:
		_jatuh = true




const SURYA: = Vector2(110, 70)
const ARAH_BAYANG: = Vector2(1.0, 0.0)


func _gambar() -> void :
	var waktu: = Time.get_ticks_msec() / 1000.0
	kanvas.draw_polygon(PackedVector2Array([Vector2.ZERO, Vector2(UKURAN.x, 0), Vector2(UKURAN.x, DASAR_Y), Vector2(0, DASAR_Y)]), 
		PackedColorArray([Color(0.98, 0.88, 0.68), Color(0.42, 0.66, 0.92), Color(0.82, 0.9, 0.95), Color(1.0, 0.94, 0.82)]))
	for i in 6:
		kanvas.draw_circle(SURYA, 36.0 + i * 20.0, Color(1, 0.92, 0.7, 0.16 - i * 0.024))
	kanvas.draw_circle(SURYA, 32, Color(1, 0.97, 0.82))
	for a in [[330.0, 64.0, 1.0], [700.0, 46.0, 0.8], [520.0, 96.0, 0.6]]:
		_awan(Vector2(fposmod(a[0] + waktu * 6.0 * a[2], UKURAN.x + 240.0) - 120.0, a[1]), a[2])
	_kampung_jauh()
	_rumah_dibangun()

	kanvas.draw_polygon(PackedVector2Array([Vector2(0, DASAR_Y - 8), Vector2(UKURAN.x, DASAR_Y - 8), Vector2(UKURAN.x, UKURAN.y), Vector2(0, UKURAN.y)]), 
		PackedColorArray([Color(0.74, 0.63, 0.47), Color(0.7, 0.58, 0.43), Color(0.42, 0.32, 0.22), Color(0.48, 0.37, 0.25)]))
	kanvas.draw_colored_polygon(PackedVector2Array([Vector2(640, DASAR_Y - 8), Vector2(1000, DASAR_Y - 8), Vector2(UKURAN.x, DASAR_Y + 16), Vector2(700, DASAR_Y + 16)]), Color(0.2, 0.12, 0.06, 0.22))
	var acak: = RandomNumberGenerator.new()
	acak.seed = 7
	for i in 70:
		var y: = DASAR_Y + 4 + pow(acak.randf(), 0.8) * (UKURAN.y - DASAR_Y - 6)
		var dekat: = inverse_lerp(DASAR_Y, UKURAN.y, y)
		var p: = Vector2(acak.randf() * UKURAN.x, y)
		var r: = lerpf(1.2, 4.0, dekat) * acak.randf_range(0.7, 1.2)
		kanvas.draw_circle(p + Vector2(r * 0.6, r * 0.3), r, Color(0.2, 0.14, 0.08, 0.35))
		kanvas.draw_circle(p, r, Color(0.55, 0.46, 0.34).lerp(Color(0.38, 0.3, 0.2), dekat))
		kanvas.draw_circle(p - Vector2(r * 0.35, r * 0.35), r * 0.4, Color(1, 0.95, 0.85, 0.35))
	var gx: = GEROBAK_X + _geser_gerobak
	_gerobak(gx)
	for i in _tumpukan.size():
		_sak(_pusat_sak(i, gx) - Vector2(0, TINGGI_SAK / 2.0), _sudut)
	for sm in _sak_meleset:
		_sak(Vector2(sm[0], sm[1]), sm[2])
	if main:
		var puncak: = DASAR_Y - TINGGI_SAK * _tumpukan.size()
		if not _jatuh:
			kanvas.draw_dashed_line(Vector2(_x, _y + TINGGI_SAK), Vector2(_x, puncak), Color(1, 1, 1, 0.5), 2, 10)

			kanvas.draw_line(Vector2(_x, 0), Vector2(_x, _y + 4), Color(0.25, 0.2, 0.16), 4)
			kanvas.draw_line(Vector2(_x - 1, 0), Vector2(_x - 1, _y + 4), Color(0.6, 0.5, 0.4, 0.6), 1)

		var jarak: = clampf((puncak - (_y + TINGGI_SAK)) / 300.0, 0.0, 1.0)
		bayangan(Vector2(_x + 8, puncak + 2), LEBAR_SAK * lerpf(0.95, 0.6, jarak), lerpf(0.4, 0.12, jarak))
		_sak(Vector2(_x, _y), 0.0)

	for sisi in [0.0, 1.0]:
		var x0: float = sisi * (UKURAN.x - 80.0)
		var kiri: = Color(0, 0, 0, 0.18 if sisi == 0.0 else 0.0)
		var kanan: = Color(0, 0, 0, 0.0 if sisi == 0.0 else 0.18)
		kanvas.draw_polygon(PackedVector2Array([Vector2(x0, 0), Vector2(x0 + 80, 0), Vector2(x0 + 80, UKURAN.y), Vector2(x0, UKURAN.y)]), 
			PackedColorArray([kiri, kanan, kanan, kiri]))



func _awan(p: Vector2, s: float) -> void :
	for g in [[-34, 6, 22], [0, 0, 30], [34, 8, 20], [16, -12, 22], [-14, -8, 20]]:
		kanvas.draw_circle(p + Vector2(g[0], g[1] + 6) * s, g[2] * s, Color(0.78, 0.82, 0.88, 0.8))
	for g in [[-34, 6, 22], [0, 0, 30], [34, 8, 20], [16, -12, 22], [-14, -8, 20]]:
		kanvas.draw_circle(p + Vector2(g[0] - 3, g[1] - 2) * s, g[2] * s * 0.92, Color(1, 1, 1, 0.92))



var _titik_kampung: = []

func _kampung_jauh() -> void :
	if _titik_kampung.is_empty():
		var acak: = RandomNumberGenerator.new()
		acak.seed = 21
		var x: = -20.0
		while x < 640:
			var lebar: = acak.randf_range(40, 70)
			var tinggi: = acak.randf_range(20, 34)
			var dasar: = DASAR_Y - 6
			if acak.randf() < 0.45:

				for g in 3:
					_titik_kampung.append(["pohon", Vector2(x + lebar * (0.25 + g * 0.25), dasar - tinggi * acak.randf_range(0.55, 0.85)), acak.randf_range(10, 15)])
			else:
				_titik_kampung.append(["rumah", PackedVector2Array([Vector2(x, dasar), Vector2(x, dasar - tinggi * 0.55), Vector2(x + lebar / 2.0, dasar - tinggi), Vector2(x + lebar, dasar - tinggi * 0.55), Vector2(x + lebar, dasar)])])
			x += lebar * acak.randf_range(0.7, 1.0)
	for t in _titik_kampung:
		if t[0] == "pohon":
			kanvas.draw_rect(Rect2(t[1].x - t[2], t[1].y, t[2] * 2.0, DASAR_Y - 6 - t[1].y), Color(0.66, 0.74, 0.74))
			kanvas.draw_circle(t[1], t[2], Color(0.62, 0.72, 0.7))
		else:
			kanvas.draw_colored_polygon(t[1], Color(0.7, 0.72, 0.76))
	kanvas.draw_rect(Rect2(0, DASAR_Y - 40, UKURAN.x, 34), Color(1, 0.97, 0.92, 0.25))


func _rumah_dibangun() -> void :
	var dinding: = Rect2(640, 150, 360, DASAR_Y - 150)

	kanvas.draw_colored_polygon(PackedVector2Array([Vector2(dinding.end.x, dinding.position.y), Vector2(dinding.end.x + 26, dinding.position.y + 14), 
		Vector2(dinding.end.x + 26, DASAR_Y - 6), Vector2(dinding.end.x, DASAR_Y)]), Color(0.52, 0.28, 0.2))
	kanvas.draw_rect(dinding, Color(0.62, 0.36, 0.26))
	for b in 9:
		var y: = dinding.position.y + b * 23
		for k in 9:
			var x: = dinding.position.x + k * 42 + (21 if b % 2 == 1 else 0)
			if x < dinding.end.x - 10:
				var w: = Color(0.8, 0.48, 0.34) if (b + k) % 3 else Color(0.7, 0.38, 0.27)

				w = w.lightened(0.08 * (1.0 - (x - dinding.position.x) / dinding.size.x))
				kanvas.draw_rect(Rect2(x, y, 40, 21), w)
				kanvas.draw_line(Vector2(x, y + 1), Vector2(x + 40, y + 1), Color(1, 0.85, 0.7, 0.35), 1.0)

	kanvas.draw_rect(Rect2(734, 224, 82, DASAR_Y - 224), Color(0.82, 0.74, 0.62))
	gradasi(Rect2(740, 230, 70, DASAR_Y - 230), Color(0.12, 0.09, 0.08), Color(0.28, 0.22, 0.18))

	kanvas.draw_rect(Rect2(dinding.position.x, dinding.position.y, dinding.size.x, 12), Color(0, 0, 0, 0.2))

	for x in [630.0, 760.0, 890.0, 1010.0]:
		kanvas.draw_line(Vector2(x + 7, 116), Vector2(x + 7, DASAR_Y), Color(0, 0, 0, 0.18), 6)
		kanvas.draw_line(Vector2(x, 110), Vector2(x, DASAR_Y), Color(0.72, 0.58, 0.32), 7)
		kanvas.draw_line(Vector2(x - 2, 110), Vector2(x - 2, DASAR_Y), Color(0.95, 0.85, 0.6), 2)
		for ruas in 4:
			kanvas.draw_line(Vector2(x - 4, 140 + ruas * 60), Vector2(x + 4, 140 + ruas * 60), Color(0.5, 0.38, 0.2), 2)
	for y in [140.0, 240.0]:
		kanvas.draw_line(Vector2(620, y + 6), Vector2(1020, y + 6), Color(0, 0, 0, 0.15), 5)
		kanvas.draw_line(Vector2(620, y), Vector2(1020, y), Color(0.7, 0.57, 0.32), 6)
		kanvas.draw_line(Vector2(620, y - 2), Vector2(1020, y - 2), Color(0.95, 0.85, 0.6), 2)


func _gerobak(x: float) -> void :

	bayangan(Vector2(x + 24, DASAR_Y + 52), 300, 0.28)

	kanvas.draw_colored_polygon(PackedVector2Array([Vector2(x - 135, DASAR_Y - 4), Vector2(x + 135, DASAR_Y - 4), Vector2(x + 150, DASAR_Y - 14), Vector2(x - 120, DASAR_Y - 14)]), Color(0.72, 0.52, 0.3))
	kanvas.draw_colored_polygon(PackedVector2Array([Vector2(x + 135, DASAR_Y - 4), Vector2(x + 150, DASAR_Y - 14), Vector2(x + 150, DASAR_Y + 16), Vector2(x + 135, DASAR_Y + 26)]), Color(0.32, 0.2, 0.1))
	gradasi(Rect2(x - 135, DASAR_Y - 4, 270, 30), Color(0.6, 0.4, 0.22), Color(0.42, 0.27, 0.14))
	for i in 4:
		kanvas.draw_line(Vector2(x - 135, DASAR_Y + 3 + i * 6), Vector2(x + 135, DASAR_Y + 3 + i * 6), Color(0.3, 0.19, 0.09), 1)
		kanvas.draw_line(Vector2(x - 135, DASAR_Y + 4 + i * 6), Vector2(x + 135, DASAR_Y + 4 + i * 6), Color(0.85, 0.65, 0.42, 0.35), 1)
	kanvas.draw_line(Vector2(x - 135, DASAR_Y - 4), Vector2(x + 135, DASAR_Y - 4), Color(0.95, 0.78, 0.55), 2)

	kanvas.draw_line(Vector2(x + 140, DASAR_Y + 4), Vector2(x + 205, DASAR_Y - 30), Color(0.3, 0.18, 0.08), 7)
	kanvas.draw_line(Vector2(x + 139, DASAR_Y + 1), Vector2(x + 204, DASAR_Y - 33), Color(0.7, 0.5, 0.3), 2)

	for wx in [x - 85, x + 85]:
		var pusat: = Vector2(wx, DASAR_Y + 32)
		kanvas.draw_circle(pusat + Vector2(3, 2), 21, Color(0, 0, 0, 0.3))
		kanvas.draw_circle(pusat, 20, Color(0.12, 0.12, 0.13))
		kanvas.draw_arc(pusat, 17, PI * 1.05, PI * 1.6, 10, Color(0.55, 0.55, 0.58, 0.8), 3)
		kanvas.draw_circle(pusat, 10, Color(0.62, 0.62, 0.64))
		for sp in 6:
			kanvas.draw_line(pusat, pusat + Vector2.from_angle(sp * TAU / 6.0) * 16, Color(0.42, 0.42, 0.44), 2)
		kanvas.draw_circle(pusat, 4, Color(0.85, 0.85, 0.88))



func _sak(p: Vector2, putar: float) -> void :
	kanvas.draw_set_transform(p + Vector2(0, TINGGI_SAK / 2.0), putar)
	var kotak: = Rect2( - LEBAR_SAK / 2.0, - TINGGI_SAK / 2.0, LEBAR_SAK, TINGGI_SAK)
	kotak_bulat(kotak, Color(0.66, 0.63, 0.57), 14, 6.0)
	kotak_bulat(Rect2(kotak.position + Vector2(3, 2), kotak.size - Vector2(6, 12)), Color(0.86, 0.84, 0.78), 12)
	kotak_bulat(Rect2(kotak.position + Vector2(10, 5), Vector2(LEBAR_SAK * 0.55, 9)), Color(1, 1, 0.97, 0.55), 5)
	for ujung in [-1.0, 1.0]:
		var ex: float = ujung * (LEBAR_SAK / 2.0 - 9.0)
		for t in 4:
			kanvas.draw_line(Vector2(ex - 2, - TINGGI_SAK / 2.0 + 8 + t * 8), Vector2(ex + 2, - TINGGI_SAK / 2.0 + 12 + t * 8), Color(0.5, 0.47, 0.42), 1.5)
	kotak_bulat(Rect2(-46, -13, 92, 24), Color(0.16, 0.36, 0.64), 4)
	kotak_bulat(Rect2(-46, -13, 92, 9), Color(0.3, 0.52, 0.82), 4)
	kanvas.draw_string(GH.cetak(), Vector2(-46, 6), GameState.tk("SEMEN"), HORIZONTAL_ALIGNMENT_CENTER, 92, 20, Color.WHITE)
	kanvas.draw_set_transform(Vector2.ZERO)
