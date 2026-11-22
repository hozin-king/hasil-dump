extends Node2D




const JARAK: = 70.0
const KUNING: = Color(1.0, 0.82, 0.2)

var dari: = Vector2.ZERO
var ke: = Vector2.ZERO
var skala: = 1.0
var _waktu: = 0.0


func _process(delta: float) -> void :
	_waktu += delta
	queue_redraw()


func _draw() -> void :
	var arah: = ke - dari
	var panjang: = arah.length()
	if panjang < JARAK * skala * 1.5:
		return
	arah /= panjang
	var samping: = Vector2( - arah.y, arah.x)
	var jarak: = JARAK * skala
	var geser: = fmod(_waktu * 60.0 * skala, jarak)
	var t: = jarak * 0.8 + geser
	while t < panjang - jarak * 0.5:
		var p: = dari + arah * t

		var a: = clampf(minf(t / (jarak * 2.0), (panjang - t) / (jarak * 1.5)), 0.0, 1.0)
		var ujung: = p + arah * 14.0 * skala
		var sayap: = 16.0 * skala
		var titik: = PackedVector2Array([ujung - arah * sayap + samping * sayap, ujung, ujung - arah * sayap - samping * sayap])
		draw_polyline(titik, Color(0.25, 0.15, 0.0, 0.55 * a), 11.0 * skala, true)
		draw_polyline(titik, Color(KUNING, 0.95 * a), 6.0 * skala, true)
		t += jarak
