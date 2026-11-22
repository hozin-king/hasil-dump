extends Node2D





const GH: = preload("res://scripts/gaya_hud.gd")
const JARI: = 38.0
const JARAK_CHEVRON: = 62.0

var arah: = Vector2.LEFT
var genting: = false
var _waktu: = 0.0
var _tulisan: Label


func _ready() -> void :
	_tulisan = GH.label("", 30, GH.KUNING, true, 6)

	_tulisan.add_theme_stylebox_override("normal", GH.kaca(0.72, 8, Vector4(14, 2, 14, 2)))
	_tulisan.position.y = JARI + 6.0
	add_child(_tulisan)


func tampil(teks: String, arah_baru: Vector2, genting_baru: bool) -> void :
	_tulisan.text = teks
	_tulisan.add_theme_color_override("font_color", Color(1.0, 0.42, 0.34) if genting_baru else GH.KUNING)
	_tulisan.size = _tulisan.get_minimum_size()
	_tulisan.position.x = - _tulisan.size.x / 2.0
	arah = arah_baru
	genting = genting_baru
	show()


func _process(delta: float) -> void :
	if visible:
		_waktu += delta
		queue_redraw()


func _draw() -> void :
	var denyut: = 1.0 + 0.1 * absf(sin(_waktu * (9.0 if genting else 5.0)))
	var warna: = Color(0.92, 0.2, 0.16) if genting else Color(1.0, 0.78, 0.12)
	var tanda: = Color.WHITE if genting else GH.TEKS_GELAP
	var j: = JARI * denyut
	var sudut: = PackedVector2Array([Vector2(0, - j), Vector2(j * 0.95, j * 0.72), Vector2( - j * 0.95, j * 0.72)])
	var tutup: = PackedVector2Array([sudut[0], sudut[1], sudut[2], sudut[0]])
	draw_polyline(tutup, Color(0, 0, 0, 0.7), 11.0, true)
	draw_colored_polygon(sudut, warna)
	draw_polyline(tutup, Color.WHITE, 3.0, true)

	draw_line(Vector2(0, - j * 0.42), Vector2(0, j * 0.22), tanda, j * 0.17)
	draw_circle(Vector2(0, j * 0.47), j * 0.1, tanda)

	var samping: = Vector2( - arah.y, arah.x)
	var fase: = fmod(_waktu * 2.5, 1.0)
	for i in 3:
		var p: = arah * (JARAK_CHEVRON + i * 24.0)
		var nyala: = 0.35 + 0.65 * clampf(1.0 - absf(fase * 3.0 - i - 0.5), 0.0, 1.0)
		var titik: = PackedVector2Array([p - arah * 13.0 + samping * 17.0, p + arah * 3.0, p - arah * 13.0 - samping * 17.0])
		draw_polyline(titik, Color(0, 0, 0, 0.6 * nyala), 12.0, true)
		draw_polyline(titik, Color(warna, nyala), 7.0, true)
