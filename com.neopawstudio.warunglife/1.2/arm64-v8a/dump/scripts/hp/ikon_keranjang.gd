extends Control





const KUNING: = Color(1.0, 0.82, 0.25)
const TEPI: = Color(0.45, 0.3, 0.05)

var jumlah: = 0:
	set(v):
		jumlah = v
		queue_redraw()


func _init() -> void :
	custom_minimum_size = Vector2(60, 52)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void :
	var s: = minf(size.x, size.y) / 52.0
	var o: = Vector2((size.x - 52.0 * s) / 2.0, (size.y - 52.0 * s) / 2.0)

	draw_polyline(PackedVector2Array([o + Vector2(2, 8) * s, o + Vector2(10, 8) * s, o + Vector2(17, 34) * s]), TEPI, 5.0 * s, true)
	draw_polyline(PackedVector2Array([o + Vector2(2, 8) * s, o + Vector2(10, 8) * s, o + Vector2(17, 34) * s]), KUNING, 3.0 * s, true)

	var badan: = PackedVector2Array([o + Vector2(12, 15) * s, o + Vector2(48, 15) * s, o + Vector2(42, 34) * s, o + Vector2(17, 34) * s])
	draw_colored_polygon(badan, KUNING)
	draw_polyline(PackedVector2Array([badan[0], badan[1], badan[2], badan[3], badan[0]]), TEPI, 2.0 * s, true)

	for x in [24.0, 32.0, 40.0]:
		draw_line(o + Vector2(x, 17) * s, o + Vector2(x - 2.0, 32) * s, TEPI.lightened(0.2), 1.5 * s)
	draw_line(o + Vector2(14, 24) * s, o + Vector2(46, 24) * s, TEPI.lightened(0.2), 1.5 * s)

	for x in [22.0, 38.0]:
		draw_circle(o + Vector2(x, 42) * s, 4.0 * s, TEPI)
		draw_circle(o + Vector2(x, 42) * s, 2.0 * s, KUNING)

	if jumlah > 0:
		var pusat: = o + Vector2(46, 8) * s
		draw_circle(pusat, 9.0 * s, Color(0.85, 0.15, 0.1))
		var teks: = str(jumlah) if jumlah < 100 else "99+"
		var fon: = ThemeDB.fallback_font
		var ukuran: = int(12.0 * s)
		var lebar: = fon.get_string_size(GameState.tk(teks), HORIZONTAL_ALIGNMENT_LEFT, -1, ukuran).x
		draw_string(fon, pusat + Vector2( - lebar / 2.0, 4.5 * s), GameState.tk(teks), HORIZONTAL_ALIGNMENT_LEFT, -1, ukuran, Color.WHITE)
