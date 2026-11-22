extends Control





var nilai: = 0.0
var tingkat: = 0

const WARNA_TINGKAT: = [Color(0.62, 0.6, 0.56), Color(0.55, 0.72, 0.45), Color(0.3, 0.66, 0.42), Color(0.18, 0.56, 0.5), Color(0.86, 0.62, 0.16)]
const TINGGI_BAR: = 10.0
const LEBAR_IKON: = 30.0


func atur(n: float, t: int) -> void :
	nilai = n
	tingkat = t
	custom_minimum_size = Vector2(0, 24)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()


func _draw() -> void :
	_jabat_tangan(Vector2(13, size.y / 2.0), WARNA_TINGKAT[tingkat])
	var kotak: = Rect2(LEBAR_IKON, (size.y - TINGGI_BAR) / 2.0, size.x - LEBAR_IKON, TINGGI_BAR)
	draw_rect(kotak, Color(0.9, 0.88, 0.84))
	var isi: = kotak
	isi.size.x = kotak.size.x * clampf(nilai / 100.0, 0.0, 1.0)
	if isi.size.x > 0.5:
		draw_rect(isi, WARNA_TINGKAT[tingkat])

	for t in GameState.TINGKAT_AKRAB.size():
		if t == 0:
			continue
		var x: = kotak.position.x + kotak.size.x * float(GameState.TINGKAT_AKRAB[t][0]) / 100.0
		draw_line(Vector2(x, kotak.position.y - 2), Vector2(x, kotak.end.y + 2), Color(1, 1, 1, 0.95), 2.0)
	draw_rect(kotak, Color(0.55, 0.5, 0.44, 0.6), false, 1.0)



func _jabat_tangan(p: Vector2, warna: Color) -> void :
	var kulit: = Color(0.96, 0.78, 0.6)
	var garis: = Color(0.45, 0.32, 0.22)

	draw_colored_polygon(PackedVector2Array([p + Vector2(-13, 6), p + Vector2(-7, 0), p + Vector2(-4, 4), p + Vector2(-10, 10)]), warna.darkened(0.15))
	draw_colored_polygon(PackedVector2Array([p + Vector2(13, 6), p + Vector2(7, 0), p + Vector2(4, 4), p + Vector2(10, 10)]), warna)

	draw_colored_polygon(PackedVector2Array([p + Vector2(-7, 0), p + Vector2(-1, -5), p + Vector2(5, -3), p + Vector2(3, 3), p + Vector2(-4, 4)]), kulit)
	draw_colored_polygon(PackedVector2Array([p + Vector2(7, 0), p + Vector2(2, -4), p + Vector2(-4, -1), p + Vector2(-2, 4), p + Vector2(4, 4)]), kulit.darkened(0.08))
	draw_polyline(PackedVector2Array([p + Vector2(-4, -1), p + Vector2(-2, 4), p + Vector2(4, 4), p + Vector2(7, 0)]), garis, 1.2)
	draw_polyline(PackedVector2Array([p + Vector2(-7, 0), p + Vector2(-1, -5), p + Vector2(5, -3)]), garis, 1.2)
