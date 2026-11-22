extends Node2D





const WARNA: = Color(0.36, 0.82, 0.3)
const WARNA_TEPI: = Color(0.12, 0.42, 0.12)
const LAMA: = 1.6

var orang: Sprite2D
var tinggi: = 200.0
var besar: = 1.0
var _t: = 0.0


static func tampilkan(o: Sprite2D, naik_tingkat: = false) -> void :
	if o == null or not is_instance_valid(o) or o.get_parent() == null:
		return
	var p: Node2D = load("res://scripts/panah_akrab.gd").new()
	p.orang = o
	p.tinggi = o.tinggi_badan() if o.has_method("tinggi_badan") else 200.0
	p.besar = 1.2 if naik_tingkat else 1.0
	p.z_index = 50
	o.get_parent().add_child(p)
	GameState.bunyi("akrab_naik")


func _process(delta: float) -> void :
	_t += delta
	if _t >= LAMA or not is_instance_valid(orang):
		queue_free()
		return
	var naik: = 14.0 * (_t / LAMA)
	position = orang.position - Vector2(0, tinggi + 26.0 + naik)
	modulate.a = 1.0 if _t < LAMA * 0.6 else 1.0 - (_t - LAMA * 0.6) / (LAMA * 0.4)


	scale = Vector2.ONE * besar * minf(1.0, 0.4 + _t * 4.0)
	queue_redraw()


func _draw() -> void :

	var titik: = PackedVector2Array([Vector2(0, -11), Vector2(9, -1), Vector2(3.5, -1), Vector2(3.5, 10), Vector2(-3.5, 10), Vector2(-3.5, -1), Vector2(-9, -1)])
	for i in titik.size():
		titik[i] *= 1.5
	var tepi: = titik.duplicate()
	tepi.append(titik[0])
	var bayang: = PackedVector2Array()
	for t in tepi:
		bayang.append(t + Vector2(2, 3))
	draw_polyline(bayang, Color(0, 0, 0, 0.45), 4.0, true)
	draw_colored_polygon(titik, WARNA)
	draw_polyline(tepi, WARNA_TEPI, 3.0, true)
