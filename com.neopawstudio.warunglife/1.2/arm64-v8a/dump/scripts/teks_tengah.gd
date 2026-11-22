extends Control






const TINGGI_KAPITAL: = 0.7

var font: Font
var baris: Array = []
var jarak_baris: = 0.35
var tepi: = 6.0
var warna_garis: = Color(0, 0, 0, 0)
var tebal_garis: = 0


func atur(f: Font, isi: Array, ukuran: Vector2) -> void :
	font = f
	baris = isi
	size = ukuran
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()



func _ukuran(b: Array) -> int:
	var u: = int(b[2])
	while u > 6 and font.get_string_size(GameState.tk(String(b[0])), HORIZONTAL_ALIGNMENT_LEFT, -1, u).x > size.x - tepi * 2.0:
		u -= 1
	return u


func _draw() -> void :
	if font == null or baris.is_empty():
		return
	var ukuran: Array = []
	var total: = 0.0
	for i in baris.size():
		var u: = _ukuran(baris[i])
		ukuran.append(u)
		total += u * TINGGI_KAPITAL
		if i > 0:
			total += u * jarak_baris
	var y: = (size.y - total) / 2.0
	for i in baris.size():
		var u: int = ukuran[i]
		if i > 0:
			y += u * jarak_baris
		y += u * TINGGI_KAPITAL
		var teks: = String(baris[i][0])
		var lebar: = font.get_string_size(GameState.tk(teks), HORIZONTAL_ALIGNMENT_LEFT, -1, u).x
		var titik: = Vector2((size.x - lebar) / 2.0, y)
		if tebal_garis > 0:
			draw_string_outline(font, titik, GameState.tk(teks), HORIZONTAL_ALIGNMENT_LEFT, -1, u, tebal_garis, warna_garis)
		draw_string(font, titik, GameState.tk(teks), HORIZONTAL_ALIGNMENT_LEFT, -1, u, baris[i][1])
