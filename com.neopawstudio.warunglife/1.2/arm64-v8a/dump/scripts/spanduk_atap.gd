extends Node2D










const UKURAN_KAIN: = Vector2i(940, 210)
const WARNA_KAIN: = Color(0.98, 0.95, 0.87)
const WARNA_MERAH_SPANDUK: = Color(0.77, 0.12, 0.1)
const WARNA_EMAS_SPANDUK: = Color(0.9, 0.7, 0.22)
const WARNA_COKLAT_SPANDUK: = Color(0.27, 0.16, 0.08)
const KOTAK_SPANDUK: = 24
const BARIS_SPANDUK: = 6
var sudut: Array = []
var _kain: SubViewport = null



static func buat(data_sudut: Array, gambar_latar: Texture2D) -> Node2D:
	var n: Node2D = load("res://scripts/spanduk_atap.gd").new()
	for p in data_sudut:
		n.sudut.append(Vector2(float(p[0]), float(p[1])))
	n._kain = n._buat_kain()
	n.add_child(n._kain)
	var bahan: = ShaderMaterial.new()
	bahan.shader = load("res://shader/spanduk_atap.gdshader")
	bahan.set_shader_parameter("latar", gambar_latar)
	bahan.set_shader_parameter("ukuran_latar", gambar_latar.get_size())
	n.material = bahan
	return n


func _buat_kain() -> SubViewport:
	var vp: = SubViewport.new()
	vp.size = UKURAN_KAIN
	vp.transparent_bg = true
	vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	var w: = float(UKURAN_KAIN.x)
	var h: = float(UKURAN_KAIN.y)
	var dasar: = ColorRect.new()
	dasar.color = WARNA_KAIN
	dasar.size = Vector2(w, h)
	vp.add_child(dasar)
	for y in [0.0, h - 18.0]:
		var pita: = ColorRect.new()
		pita.color = WARNA_MERAH_SPANDUK
		pita.position = Vector2(0, y)
		pita.size = Vector2(w, 18)
		vp.add_child(pita)
	for y in [25.0, h - 28.0]:
		var emas: = ColorRect.new()
		emas.color = WARNA_EMAS_SPANDUK
		emas.position = Vector2(14, y)
		emas.size = Vector2(w - 28, 3)
		vp.add_child(emas)

	var lencana: = Panel.new()
	var gaya: = StyleBoxFlat.new()
	gaya.bg_color = WARNA_COKLAT_SPANDUK
	gaya.set_corner_radius_all(16)
	gaya.border_color = WARNA_EMAS_SPANDUK
	gaya.set_border_width_all(3)
	lencana.add_theme_stylebox_override("panel", gaya)
	lencana.position = Vector2(26, 42)
	lencana.size = Vector2(196, h - 84)
	vp.add_child(lencana)
	var logo: = TextureRect.new()
	logo.texture = load("res://assets/ui/logo_studio.png")
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	logo.position = lencana.position + Vector2(8, 6)
	logo.size = lencana.size - Vector2(16, 12)
	vp.add_child(logo)

	var font: Font = load("res://assets/font/BebasNeue.ttf")
	var teks: = [
		(GameState.tk("Terima kasih, Warung %s,") % GameState.nama_warung_tanpa_awalan()).to_upper(), 
		GameState.tk("atas dukungannya!").to_upper(), 
	]
	var kiri: = lencana.position.x + lencana.size.x + 18.0
	var lebar: = w - kiri - 26.0
	var ukuran: = [66, 60]
	var warna: = [WARNA_MERAH_SPANDUK, WARNA_COKLAT_SPANDUK]
	var atas: = [34.0, 104.0]
	for i in 2:
		var lebar_teks: = font.get_string_size(teks[i], HORIZONTAL_ALIGNMENT_LEFT, -1, ukuran[i]).x
		if lebar_teks > lebar:
			ukuran[i] = int(floor(ukuran[i] * lebar / lebar_teks))
		var l: = Label.new()
		l.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
		l.text = teks[i]
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		l.position = Vector2(kiri, atas[i])
		l.size = Vector2(lebar, 72)
		l.add_theme_font_override("font", font)
		l.add_theme_font_size_override("font_size", ukuran[i])
		l.add_theme_color_override("font_color", warna[i])
		vp.add_child(l)
	return vp



func titik(u: float, v: float) -> Vector2:
	var p0: Vector2 = sudut[0]
	var p1: Vector2 = sudut[1]
	var p2: Vector2 = sudut[2]
	var p3: Vector2 = sudut[3]
	var s: = p0 - p1 + p2 - p3
	var d1: = p1 - p2
	var d2: = p3 - p2
	var pembagi: = d1.x * d2.y - d2.x * d1.y
	var g: = 0.0
	var h: = 0.0
	if absf(pembagi) > 0.0001:
		g = (s.x * d2.y - d2.x * s.y) / pembagi
		h = (d1.x * s.y - s.x * d1.y) / pembagi
	var a: = p1 - p0 + g * p1
	var b: = p3 - p0 + h * p3
	var w: = g * u + h * v + 1.0
	return (a * u + b * v + p0) / w


func _draw() -> void :
	if sudut.size() != 4 or not is_instance_valid(_kain):
		return
	var c: = self

	var bayang: = PackedVector2Array()
	for p in sudut:
		bayang.append(p + Vector2(-1.5, 3.5))
	c.draw_colored_polygon(bayang, Color(0, 0, 0, 0.35))
	var kain: = _kain.get_texture()
	var putih: = PackedColorArray([Color.WHITE, Color.WHITE, Color.WHITE, Color.WHITE])
	for j in BARIS_SPANDUK:
		for i in KOTAK_SPANDUK:
			var u0: = float(i) / KOTAK_SPANDUK
			var u1: = float(i + 1) / KOTAK_SPANDUK
			var v0: = float(j) / BARIS_SPANDUK
			var v1: = float(j + 1) / BARIS_SPANDUK
			var titik: = PackedVector2Array([titik(u0, v0), titik(u1, v0), titik(u1, v1), titik(u0, v1)])
			var uv: = PackedVector2Array([Vector2(u0, v0), Vector2(u1, v0), Vector2(u1, v1), Vector2(u0, v1)])
			c.draw_polygon(titik, putih, uv, kain)
