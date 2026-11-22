extends Node2D








const UKURAN: = Vector2(1536, 1024)

const GARIS_RENDAH: = [Vector2(0, 446), Vector2(1536, 1115)]
const GARIS_TINGGI: = [Vector2(0, 400), Vector2(267, 487), Vector2(573, 567), Vector2(1093, 813), Vector2(1333, 913), Vector2(1536, 993)]
const ARAH_ARUS: = Vector2(1.0, 0.45)

var tinggi: = 0.0:
	set(v):
		tinggi = clampf(v, 0.0, 1.0)
		_bangun_air()

var _air: Polygon2D
var _sampah: Node2D
var _benda: Array = []
var _waktu: = 0.0

const SHADER_AIR: = "\r\nshader_type canvas_item;\r\nuniform vec4 warna_dalam : source_color = vec4(0.45, 0.33, 0.17, 0.93);\r\nuniform vec4 warna_muka : source_color = vec4(0.66, 0.52, 0.31, 0.9);\r\nvarying vec2 p;\r\nvoid vertex() { p = VERTEX; }\r\nfloat hash(vec2 v) { return fract(sin(dot(v, vec2(127.1, 311.7))) * 43758.5453); }\r\nfloat noise(vec2 v) {\r\n\tvec2 i = floor(v); vec2 f = fract(v); f = f * f * (3.0 - 2.0 * f);\r\n\treturn mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);\r\n}\r\nvoid fragment() {\r\n\tfloat pudar = COLOR.a;   // 0 di tepi air -> 1 di dalam (warna titik sudut), supaya tepi air memudar lembut\r\n\tfloat t = TIME;\r\n\t// Ruang isometrik: arah arus sejajar jalan, sumbu y digepengkan.\r\n\tvec2 a = normalize(vec2(1.0, 0.45));\r\n\tvec2 q = vec2(dot(p, a), dot(p, vec2(-a.y, a.x)) * 2.2) * 0.0065;\r\n\tfloat n = noise(q + vec2(-t * 0.25, t * 0.03)) * 0.55 + noise(q * 2.1 + vec2(-t * 0.45, -t * 0.06)) * 0.3 + noise(q * 5.0 + vec2(-t * 0.9, 0.0)) * 0.15;\r\n\tn = smoothstep(0.2, 0.8, n);\r\n\tvec4 c = mix(warna_dalam, warna_muka, n);\r\n\t// Alur arus memanjang.\r\n\tfloat alur = noise(vec2(q.x * 0.6 - t * 0.9, q.y * 5.0));\r\n\tc.rgb += smoothstep(0.55, 0.95, alur) * 0.06;\r\n\t// Kilau langit di permukaan.\r\n\tfloat kilau = smoothstep(0.62, 0.95, noise(q * 2.6 + vec2(-t * 0.35, t * 0.15)));\r\n\tc.rgb += kilau * vec3(0.12, 0.13, 0.14);\r\n\t// Riak tetes hujan: lingkaran pipih yang membesar lalu hilang.\r\n\tvec2 g = vec2(p.x, p.y * 2.0) / 58.0;\r\n\tvec2 id = floor(g); vec2 f = fract(g) - 0.5;\r\n\tfloat r = hash(id);\r\n\tfloat fase = fract(t * 0.8 + r * 13.0);\r\n\tvec2 geser = vec2(hash(id + 3.1), hash(id + 7.7)) - 0.5;\r\n\tfloat d = length(f - geser * 0.5);\r\n\tfloat cincin = smoothstep(0.09, 0.0, abs(d - fase * 0.42)) * (1.0 - fase) * (1.0 - fase) * step(0.55, r);\r\n\tc.rgb += cincin * 0.07;\r\n\tc.a *= pudar;\r\n\tCOLOR = c;\r\n}\r\n"








































func _ready() -> void :
	position = - UKURAN / 2.0
	_air = Polygon2D.new()
	var bahan: = ShaderMaterial.new()
	var sh: = Shader.new()
	sh.code = SHADER_AIR
	bahan.shader = sh
	_air.material = bahan
	add_child(_air)
	_sampah = Node2D.new()
	_sampah.draw.connect(_gambar_sampah)
	add_child(_sampah)
	for i in 9:
		_benda.append(_benda_baru(randf() * 1.0))
	_bangun_air()


func naikkan_ke(target: float, detik: float) -> Tween:
	var tw: = create_tween()
	tw.tween_property(self, "tinggi", target, detik).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	return tw


static func _y_garis(garis: Array, x: float) -> float:
	for i in garis.size() - 1:
		var a: Vector2 = garis[i]
		var b: Vector2 = garis[i + 1]
		if x <= b.x:
			return lerpf(a.y, b.y, (x - a.x) / maxf(b.x - a.x, 1.0))
	return (garis[-1] as Vector2).y


func y_permukaan(x: float) -> float:
	return lerpf(_y_garis(GARIS_RENDAH, x), _y_garis(GARIS_TINGGI, x), tinggi)




const PUDAR: = 46.0

func _bangun_air() -> void :
	if _air == null:
		return
	var n: = 48
	var titik: = PackedVector2Array()
	var warna: = PackedColorArray()
	for i in n + 1:
		var x: = UKURAN.x * i / n
		var y: = y_permukaan(x) + sin(x * 0.03 + _waktu * 1.6) * 2.0
		titik.append(Vector2(x, y - 6.0))
		warna.append(Color(1, 1, 1, 0.0))
	for i in n + 1:
		var x: = UKURAN.x * i / n
		var y: = y_permukaan(x) + sin(x * 0.03 + _waktu * 1.6) * 2.0
		titik.append(Vector2(x, y + PUDAR))
		warna.append(Color(1, 1, 1, 1.0))
	titik.append(Vector2(UKURAN.x, UKURAN.y + 200))
	warna.append(Color(1, 1, 1, 1.0))
	titik.append(Vector2(0, UKURAN.y + 200))
	warna.append(Color(1, 1, 1, 1.0))
	var bagian: Array = []
	for i in n:
		bagian.append(PackedInt32Array([i, i + 1, n + 2 + i, n + 1 + i]))
	var badan: = PackedInt32Array()
	for i in n + 1:
		badan.append(n + 1 + i)
	badan.append(2 * n + 2)
	badan.append(2 * n + 3)
	bagian.append(badan)
	_air.polygon = titik
	_air.vertex_colors = warna
	_air.polygons = bagian
	_air.visible = tinggi > 0.001


func _benda_baru(sebar: = 0.0) -> Dictionary:
	var jenis: String = ["sandal", "botol", "daun", "daun", "kardus", "plastik", "botol", "daun"].pick_random()

	return {"jenis": jenis, "maju": -80.0 + sebar * 1700.0, "lajur": randf(), "putar": randf() * TAU, 
		"laju": randf_range(28, 55), "fase": randf() * TAU, 
		"warna": [Color(0.2, 0.45, 0.85), Color(0.9, 0.3, 0.3), Color(0.95, 0.85, 0.2), Color(0.25, 0.6, 0.35)].pick_random()}


func _process(delta: float) -> void :
	_waktu += delta
	_bangun_air()
	for i in _benda.size():
		var b: Dictionary = _benda[i]
		b["maju"] += float(b["laju"]) * delta
		b["putar"] += delta * 0.4
		if float(b["maju"]) > 1750.0:
			_benda[i] = _benda_baru()
	_sampah.queue_redraw()


func _posisi_benda(b: Dictionary) -> Vector2:
	var x: = float(b["maju"])

	var tepi: = y_permukaan(x)
	var y: = tepi + 18.0 + float(b["lajur"]) * 260.0
	return Vector2(x, y + sin(_waktu * 2.0 + float(b["fase"])) * 2.5)


func _gambar_sampah() -> void :
	if tinggi <= 0.05:
		return
	for b in _benda:
		var p: = _posisi_benda(b)
		if p.y > UKURAN.y + 20:
			continue
		var a: = float(b["putar"])
		_sampah.draw_set_transform(p, a, Vector2(1.0, 0.55))

		_sampah.draw_circle(Vector2.ZERO, 16.0, Color(0.15, 0.11, 0.06, 0.25))
		match String(b["jenis"]):
			"sandal":
				_sampah.draw_rect(Rect2(-16, -7, 32, 14), b["warna"])
				_sampah.draw_rect(Rect2(-6, -7, 3, 14), Color(1, 1, 1, 0.8))
			"botol":
				_sampah.draw_rect(Rect2(-14, -6, 24, 12), Color(0.75, 0.9, 0.95, 0.75))
				_sampah.draw_rect(Rect2(10, -3, 7, 6), b["warna"])
			"daun":
				_sampah.draw_colored_polygon(PackedVector2Array([Vector2(-14, 0), Vector2(0, -7), Vector2(14, 0), Vector2(0, 7)]), Color(0.3, 0.52, 0.18))
				_sampah.draw_line(Vector2(-14, 0), Vector2(14, 0), Color(0.2, 0.35, 0.1), 1.5)
			"kardus":
				_sampah.draw_rect(Rect2(-20, -16, 40, 32), Color(0.68, 0.5, 0.3))
				_sampah.draw_rect(Rect2(-20, -16, 40, 32), Color(0.45, 0.32, 0.18), false, 2.0)
			"plastik":
				_sampah.draw_circle(Vector2.ZERO, 11.0, Color(0.95, 0.95, 0.95, 0.7))
				_sampah.draw_circle(Vector2(5, -3), 6.0, Color(0.15, 0.15, 0.15, 0.8))
		_sampah.draw_set_transform(Vector2.ZERO)

		var r: = 22.0 + sin(_waktu * 3.0 + float(b["fase"])) * 3.0
		_sampah.draw_arc(p, r, 0, TAU, 20, Color(0.9, 0.85, 0.7, 0.1), 3.0)
