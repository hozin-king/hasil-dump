extends Control





var font: Font
var font_tebal: Font
var _hari_digambar: = -1
var _waktu: = 0.0


func _ready() -> void :
	font = load("res://assets/font/Nunito.ttf")
	font_tebal = load("res://assets/font/Fredoka.ttf")


func _process(delta: float) -> void :
	_waktu += delta

	if GameState.hari != _hari_digambar or fmod(_waktu, 0.25) < delta:
		_hari_digambar = GameState.hari
		queue_redraw()


func _draw() -> void :
	var w: = size.x
	var h: = size.y

	draw_rect(Rect2(Vector2.ZERO, size), Color(0.08, 0.2, 0.42))
	draw_rect(Rect2(0, 0, w, 34), Color(0.95, 0.62, 0.12))
	_teks_tengah(font_tebal, "PRAKIRAAN CUACA", Vector2(w / 2.0, 25), 19, Color(0.12, 0.08, 0.04))
	var kiri: = Rect2(8, 42, w / 2.0 - 12, h - 70)
	var kanan: = Rect2(w / 2.0 + 4, 42, w / 2.0 - 12, h - 70)
	_kartu(kiri, "HARI INI", GameState.nama_hari_ke(GameState.hari), GameState.cuaca)
	_kartu(kanan, "BESOK", GameState.nama_hari_ke(GameState.hari + 1), GameState.ramalan_besok())

	draw_rect(Rect2(0, h - 22, w, 22), Color(0.02, 0.06, 0.16))
	_teks_tengah(font, "NeoPaw TV  ·  Siaran Cuaca Cianjur", Vector2(w / 2.0, h - 6), 12, Color(1, 0.9, 0.6))


func _kartu(r: Rect2, judul: String, nama_hari: String, c: Dictionary) -> void :
	draw_rect(r, Color(1, 1, 1, 0.1))
	_teks_tengah(font_tebal, judul, Vector2(r.get_center().x, r.position.y + 16), 14, Color(1, 0.86, 0.3))
	_teks_tengah(font, nama_hari, Vector2(r.get_center().x, r.position.y + 31), 12, Color(0.85, 0.92, 1))
	var pusat: = Vector2(r.get_center().x, r.position.y + 66)
	var label: = "Cerah"
	if c.is_empty():
		_matahari(pusat, 17.0)
	elif bool(c.get("seharian", false)):
		_awan(pusat + Vector2(0, -4), 1.0, true)
		label = "Hujan seharian"
	else:
		_matahari(pusat + Vector2(13, -11), 11.0)
		_awan(pusat + Vector2(-4, 0), 0.85, true)
		label = "Hujan %02d-%02d" % [int(c["mulai"]) / 60, int(ceil((float(c["mulai"]) + float(c["lama"])) / 60.0))]
	_teks_tengah(font_tebal, label, Vector2(r.get_center().x, r.end.y - 9), 14, Color.WHITE)


func _matahari(p: Vector2, jari: float) -> void :
	var putar: = _waktu * 0.6
	for i in 8:
		var a: = putar + i * TAU / 8.0
		draw_line(p + Vector2.from_angle(a) * (jari + 3), p + Vector2.from_angle(a) * (jari + 9), Color(1, 0.8, 0.2), 3.0)
	draw_circle(p, jari, Color(1, 0.84, 0.25))
	draw_circle(p + Vector2( - jari * 0.25, - jari * 0.25), jari * 0.45, Color(1, 0.93, 0.55))


func _awan(p: Vector2, s: float, hujan: bool) -> void :
	if hujan:
		for i in 5:
			var x: = p.x - 20 * s + i * 10 * s
			var y0: = p.y + 12 * s + fmod(_waktu * 40.0 + i * 7.0, 14.0)
			draw_line(Vector2(x, y0), Vector2(x - 3, y0 + 7), Color(0.55, 0.78, 1), 2.0)
	var abu: = Color(0.82, 0.86, 0.92)
	draw_circle(p + Vector2(-14, 2) * s, 11 * s, abu)
	draw_circle(p + Vector2(0, -6) * s, 15 * s, abu)
	draw_circle(p + Vector2(15, 1) * s, 12 * s, abu)
	draw_rect(Rect2(p + Vector2(-25, 2) * s, Vector2(52, 11) * s), abu)


func _teks_tengah(f: Font, t: String, dasar_tengah: Vector2, u: int, warna: Color) -> void :
	var lebar: = f.get_string_size(GameState.tk(t), HORIZONTAL_ALIGNMENT_LEFT, -1, u).x
	draw_string(f, Vector2(dasar_tengah.x - lebar / 2.0, dasar_tengah.y), GameState.tk(t), HORIZONTAL_ALIGNMENT_LEFT, -1, u, warna)
