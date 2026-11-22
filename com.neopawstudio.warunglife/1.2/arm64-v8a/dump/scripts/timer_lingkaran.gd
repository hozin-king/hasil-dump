extends Node2D




const JARI: = 15.0
const TEBAL: = 5.0

var sisa: = 1.0:
	set(nilai):
		sisa = clampf(nilai, 0.0, 1.0)
		queue_redraw()


func _ready() -> void :
	z_index = 20


func _draw() -> void :

	draw_circle(Vector2.ZERO, JARI + 2.5, Color(0.1, 0.06, 0.03, 0.75))
	var warna: = Color(0.9, 0.2, 0.15).lerp(Color(0.95, 0.8, 0.2), clampf(sisa * 2.0, 0.0, 1.0))
	if sisa > 0.5:
		warna = Color(0.95, 0.8, 0.2).lerp(Color(0.3, 0.8, 0.35), (sisa - 0.5) * 2.0)
	draw_arc(Vector2.ZERO, JARI - TEBAL / 2.0, - PI / 2.0, - PI / 2.0 + TAU * sisa, 40, warna, TEBAL, true)

	if sisa < 0.25 and int(Time.get_ticks_msec() / 250) % 2 == 0:
		draw_circle(Vector2.ZERO, 3.0, Color(0.95, 0.25, 0.2))
