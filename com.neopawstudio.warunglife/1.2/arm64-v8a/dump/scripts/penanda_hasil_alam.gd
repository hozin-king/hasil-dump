extends Node2D










const GH: = preload("res://scripts/gaya_hud.gd")
const R: = 21.0
const TINGGI: = 58.0
const JARAK_REDUP: = 70.0

var jenis: = "mancing"
var judul: = ""
var _t: = 0.0
var _bisa: = true
var _matang: = 0
var _cek: = 0.0
var _redup: = 1.0


func _ready() -> void :
	_t = randf() * 3.0
	_perbarui()


func _perbarui() -> void :
	if jenis == "petik":
		_bisa = GameState.kebun_bisa_dikunjungi()
		_matang = GameState.jumlah_buah_matang()
	elif jenis == "mancing":
		_bisa = GameState.sungai_bisa_dipancing()
	elif jenis == "adu_laris":
		_bisa = preload("res://scripts/adu_laris.gd").boleh_latihan()
	else:
		_bisa = true


func _process(delta: float) -> void :
	_t += delta
	_cek -= delta
	if _cek <= 0.0:
		_cek = 1.0
		_perbarui()
	var kamera: = get_viewport().get_camera_2d()
	var s: = 1.0 / kamera.zoom.x if kamera != null else 1.0
	scale = Vector2(s, s)
	var bapak = get_tree().current_scene.get("bapak") if get_tree().current_scene != null else null
	var dekat: bool = bapak is Node2D and (bapak as Node2D).position.distance_to(position) < JARAK_REDUP
	_redup = move_toward(_redup, 0.3 if dekat else 1.0, delta * 3.0)
	modulate.a = _redup
	queue_redraw()


func _draw() -> void :
	var a: = 1.0 if _bisa else 0.55
	var naik: = sin(_t * 2.6) * 4.0
	var c: = Vector2(0, - TINGGI + naik)

	var bayang: = 1.0 - naik / 30.0
	_elips(Vector2.ZERO, 15 * bayang, 5.5 * bayang, Color(0, 0, 0, 0.35 * a))
	if _bisa:
		for k in 2:
			var w: = fmod(_t / 1.6 + k * 0.5, 1.0)
			_cincin(Vector2.ZERO, 12 + w * 20, (12 + w * 20) * 0.38, Color(1, 0.9, 0.35, (1.0 - w) * 0.8), 2.0)

	var warna: Color = {"mancing": Color(0.16, 0.55, 0.85), "petik": Color(0.92, 0.5, 0.16), "adu_laris": Color(0.85, 0.2, 0.2)}.get(jenis, Color(0.2, 0.62, 0.32))
	if not _bisa:
		warna = warna.lerp(Color(0.45, 0.45, 0.45), 0.6)
	var putar: = sin(_t * 1.3) * 0.75
	var lebar: = maxf(cos(putar), 0.2)
	var tebal: = 6.0 * sin(putar)
	var k: = R / 34.0

	for n in 6:
		var geser: = c + Vector2(tebal * (1.0 - n / 6.0), 0)
		draw_set_transform(geser, 0.0, Vector2(lebar, 1.0))
		draw_circle(Vector2.ZERO, R + 2.5, Color(warna.darkened(0.45), a))
	draw_set_transform(c, 0.0, Vector2(lebar, 1.0))
	draw_circle(Vector2.ZERO, R + 2.5, Color(1, 0.97, 0.88, a))
	for n in 7:
		var t: = n / 6.0
		draw_circle(Vector2(-3, -4) * t, R * (1.0 - t * 0.55), Color(warna.darkened(0.25).lerp(warna.lightened(0.28), t), a))
	draw_arc(Vector2.ZERO, R - 1.0, 0, TAU, 32, Color(warna.darkened(0.35), 0.6 * a), 1.5)
	draw_set_transform(c, 0.0, Vector2(lebar * k, k))
	if jenis == "mancing":
		_ikon_mancing(Vector2.ZERO, a)
	elif jenis == "petik":
		_ikon_petik(Vector2.ZERO, a)
	elif jenis == "adu_laris":
		_ikon_piala(Vector2.ZERO, a)
	else:
		_ikon_angkot(Vector2.ZERO, a)

	draw_set_transform(c, -0.5, Vector2(lebar, 1.0))
	_elips(Vector2( - R * 0.3, - R * 0.52), R * 0.42, R * 0.16, Color(1, 1, 1, 0.35 * a))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	if jenis == "petik" and _matang > 0 and _bisa:
		var p: = c + Vector2(R * 0.85, - R * 0.8)
		var besar: = 8.5 + sin(_t * 5.0) * 0.8
		draw_circle(p + Vector2(0, 1.5), besar + 2.0, Color(0, 0, 0, 0.3))
		draw_circle(p, besar + 1.8, Color.WHITE)
		draw_circle(p, besar, Color(0.88, 0.16, 0.2))
		var f: = GH.cetak()
		var t: = str(_matang)
		var lb: = f.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x
		draw_string(f, p + Vector2( - lb / 2.0, 4.6), t, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color.WHITE)

	if judul != "":
		var f: = GH.cetak()
		var t: = GameState.tk(judul)
		var lb: = f.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x
		var g: = StyleBoxFlat.new()
		g.bg_color = Color(0, 0, 0, 0.45 * a)
		g.set_corner_radius_all(10)
		draw_style_box(g, Rect2(Vector2( - lb / 2.0 - 7, 10), Vector2(lb + 14, 20)))
		draw_string(f, Vector2( - lb / 2.0, 25), t, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(1, 1, 1, a))



func _ikon_mancing(c: Vector2, a: float) -> void :
	var siklus: = fmod(_t, 2.6)
	var sambar: = clampf((siklus - 1.8) / 0.25, 0.0, 1.0) * clampf((2.5 - siklus) / 0.2, 0.0, 1.0)
	var ombak: = Color(0.75, 0.9, 1.0, 0.9 * a)

	var air: = c.y + 12
	for k in 3:
		var x: = -20.0 + k * 13.0
		draw_arc(Vector2(c.x + x, air + 4), 6.0, PI * 1.1, PI * 1.9, 6, ombak, 2.0)

	var pangkal: = c + Vector2(-20, 16)
	var ujung: = c + Vector2(10, -20) + Vector2(2, 9) * sambar
	var tengah: = pangkal.lerp(ujung, 0.5) + Vector2(-3, -3) * (1.0 - sambar) + Vector2(2, -6) * sambar
	draw_polyline(_kurva(pangkal, tengah, ujung), Color(0.55, 0.36, 0.2, a), 3.5)
	draw_circle(c + Vector2(-14, 9), 4.0, Color(0.25, 0.25, 0.28, a))
	draw_circle(c + Vector2(-14, 9), 1.6, Color(0.8, 0.8, 0.8, a))

	var pel: = c + Vector2(15, 5 + sin(_t * 3.0) * 1.5 + sambar * 7.0)
	draw_line(ujung, pel + Vector2(0, -5), Color(1, 1, 1, 0.85 * a), 1.2)
	draw_circle(pel + Vector2(0, -1), 5.0, Color(0.92, 0.18, 0.2, a))
	draw_circle(pel + Vector2(0, 2), 4.0, Color(1, 1, 1, a * (1.0 - sambar)))
	draw_line(pel + Vector2(0, -6), pel + Vector2(0, -10), Color(0.15, 0.15, 0.15, a), 1.5)

	if sambar > 0.0:
		_cincin(pel + Vector2(0, 4), 6 + sambar * 9, 2 + sambar * 3, Color(1, 1, 1, sambar * 0.9 * a), 1.5)
		draw_rect(Rect2(c + Vector2(23, -24), Vector2(3.5, 10)), Color(1, 0.9, 0.3, sambar * a))
		draw_circle(c + Vector2(24.7, -10), 2.0, Color(1, 0.9, 0.3, sambar * a))




func _ikon_petik(c: Vector2, a: float) -> void :
	var pantul: = absf(sin(_t * 3.2)) * -3.0
	var p: = c + Vector2(0, 3 + pantul)
	var merah: = Color(0.9, 0.16, 0.18, a)
	var gelap: = Color(0.6, 0.06, 0.1, a)

	draw_circle(p + Vector2(-6, 1.5), 13.5, gelap)
	draw_circle(p + Vector2(6, 1.5), 13.5, gelap)
	draw_circle(p + Vector2(0, 6), 13.0, gelap)
	draw_circle(p + Vector2(-6, 0), 12.5, merah)
	draw_circle(p + Vector2(5, 0), 12.5, merah)
	draw_circle(p + Vector2(0, 4), 12.0, merah)
	draw_circle(p + Vector2(-1, -10), 4.0, Color(0.7, 0.08, 0.12, a))

	_elips_putar(p + Vector2(-8, -3), 3.0, 6.0, -0.4, Color(1, 1, 1, 0.65 * a))
	draw_circle(p + Vector2(-4, 8), 1.6, Color(1, 1, 1, 0.3 * a))

	draw_line(p + Vector2(-1, -10), p + Vector2(1, -18), Color(0.4, 0.26, 0.12, a), 2.5)
	var goyang: = sin(_t * 2.4) * 0.25
	_daun(p + Vector2(1, -15), -0.5 + goyang, 13, Color(0.3, 0.7, 0.28, a))

	var kilau: = 0.5 + 0.5 * sin(_t * 4.0)
	_kilau(p + Vector2(13, -12), 2.5 + kilau * 3.0, _t * 2.0, a * (0.4 + kilau * 0.6))


func _elips_putar(p: Vector2, rx: float, ry: float, sudut: float, warna: Color) -> void :
	var titik: = PackedVector2Array()
	for k in 16:
		var t: = k * TAU / 16.0
		titik.append(p + Vector2(cos(t) * rx, sin(t) * ry).rotated(sudut))
	draw_colored_polygon(titik, warna)




func _ikon_piala(c: Vector2, a: float) -> void :
	var emas: = Color(1.0, 0.82, 0.25, a)
	var gelap: = Color(0.75, 0.52, 0.08, a)

	draw_arc(c + Vector2(-12, -6), 6.5, PI * 0.5, PI * 1.5, 10, gelap, 3.0)
	draw_arc(c + Vector2(12, -6), 6.5, - PI * 0.5, PI * 0.5, 10, gelap, 3.0)

	draw_colored_polygon(PackedVector2Array([c + Vector2(-13, -15), c + Vector2(13, -15), c + Vector2(9, 2), c + Vector2(0, 6), c + Vector2(-9, 2)]), emas)
	draw_rect(Rect2(c + Vector2(-13, -16), Vector2(26, 3)), gelap)

	draw_rect(Rect2(c + Vector2(-2.5, 5), Vector2(5, 7)), gelap)
	draw_rect(Rect2(c + Vector2(-9, 12), Vector2(18, 5)), emas)

	draw_circle(c + Vector2(0, -6), 3.2, Color(1, 1, 1, 0.85 * a))
	var kilau: = clampf(sin(_t * 2.2), 0.0, 1.0)
	draw_line(c + Vector2(-8, -12), c + Vector2(-5, -3), Color(1, 1, 1, 0.6 * kilau * a), 2.0)


func _ikon_angkot(c: Vector2, a: float) -> void :
	var goyang: = Vector2(0, sin(_t * 9.0) * 0.8)
	var b: = c + Vector2(0, 2) + goyang
	for k in 3:
		var y: = -6.0 + k * 6.0
		var geser: = fmod(_t * 30.0 + k * 9.0, 14.0)
		draw_line(c + Vector2(-26 - geser * 0.3, y), c + Vector2(-20 - geser * 0.3, y), Color(1, 1, 1, 0.6 * a), 1.5)
	var badan: = PackedVector2Array([b + Vector2(-19, 8), b + Vector2(-19, -8), b + Vector2(-12, -14), b + Vector2(16, -14), 
		b + Vector2(20, -6), b + Vector2(21, 8)])
	draw_colored_polygon(badan, Color(0.1, 0.45, 0.2, a))
	draw_colored_polygon(PackedVector2Array([b + Vector2(-18, 6), b + Vector2(-18, -7), b + Vector2(-11, -12.5), b + Vector2(15, -12.5), 
		b + Vector2(19, -5), b + Vector2(20, 6)]), Color(0.55, 0.85, 0.35, a))
	draw_rect(Rect2(b + Vector2(-18, -1), Vector2(38, 3)), Color(0.98, 0.85, 0.2, a))
	for k in 3:
		draw_rect(Rect2(b + Vector2(-13 + k * 9.5, -10.5), Vector2(7.5, 7)), Color(0.75, 0.92, 1.0, a))
	draw_circle(b + Vector2(19, 3), 1.6, Color(1, 0.95, 0.6, a))
	for x in [-11.0, 12.0]:
		var r: = b + Vector2(x, 9)
		draw_circle(r, 5.0, Color(0.15, 0.15, 0.17, a))
		draw_circle(r, 2.2, Color(0.75, 0.75, 0.78, a))
		var s: = Vector2.from_angle(_t * 10.0) * 2.2
		draw_line(r - s, r + s, Color(0.3, 0.3, 0.32, a), 1.0)


func _daun(p: Vector2, sudut: float, panjang: float, warna: Color) -> void :
	var arah: = Vector2.from_angle(sudut)
	var samping: = arah.orthogonal() * panjang * 0.32
	draw_colored_polygon(PackedVector2Array([p, p + arah * panjang * 0.45 + samping, p + arah * panjang, p + arah * panjang * 0.45 - samping]), warna)


func _kilau(p: Vector2, r: float, putar: float, a: float) -> void :
	var titik: = PackedVector2Array()
	for k in 8:
		titik.append(p + Vector2.from_angle(putar + k * TAU / 8.0) * (r if k % 2 == 0 else r * 0.3))
	draw_colored_polygon(titik, Color(1, 1, 0.8, a))


func _kurva(a: Vector2, b: Vector2, c: Vector2) -> PackedVector2Array:
	var titik: = PackedVector2Array()
	for k in 9:
		var t: = k / 8.0
		titik.append(a.lerp(b, t).lerp(b.lerp(c, t), t))
	return titik


func _elips(p: Vector2, rx: float, ry: float, warna: Color) -> void :
	var titik: = PackedVector2Array()
	for k in 24:
		var t: = k * TAU / 24.0
		titik.append(p + Vector2(cos(t) * rx, sin(t) * ry))
	draw_colored_polygon(titik, warna)


func _cincin(p: Vector2, rx: float, ry: float, warna: Color, tebal: float) -> void :
	var titik: = PackedVector2Array()
	for k in 33:
		var t: = k * TAU / 32.0
		titik.append(p + Vector2(cos(t) * rx, sin(t) * ry))
	draw_polyline(titik, warna, tebal, true)
