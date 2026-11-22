extends Node2D






const KUNING: = Color(1.0, 0.82, 0.25)
const GELAP: = Color(0.13, 0.08, 0.04, 0.88)

var arah: = Vector2.DOWN
var samping_jalan: = Vector2.ZERO
var tujuan: = ""
var skala: = 1.0
var tinggi: = 100.0
var angkat: = 1.15
var _waktu: = 0.0
var _papan: PanelContainer


var _alas: Node2D


func _ready() -> void :
	z_index = 30
	_papan = PanelContainer.new()
	var gaya: = StyleBoxFlat.new()
	gaya.bg_color = GELAP
	gaya.set_corner_radius_all(20)
	gaya.border_color = KUNING
	gaya.set_border_width_all(3)
	gaya.content_margin_left = 16
	gaya.content_margin_right = 16
	gaya.content_margin_top = 6
	gaya.content_margin_bottom = 6
	gaya.shadow_color = Color(0, 0, 0, 0.35)
	gaya.shadow_size = 6
	_papan.add_theme_stylebox_override("panel", gaya)
	_papan.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var t: = Label.new()
	t.text = tujuan
	t.add_theme_font_override("font", load("res://assets/font/BebasNeue.ttf"))
	t.add_theme_font_size_override("font_size", 30)
	t.add_theme_color_override("font_color", Color(1, 0.97, 0.88))
	t.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.6))
	t.add_theme_constant_override("outline_size", 4)
	_papan.add_child(t)
	add_child(_papan)
	_papan.scale = Vector2(skala, skala)
	_alas = Node2D.new()
	_alas.draw.connect(_gambar_chevron)
	_pasang_alas.call_deferred()



func _pasang_alas() -> void :
	var dunia: = get_parent()
	if dunia == null or not is_instance_valid(_alas):
		return
	dunia.add_child(_alas)
	dunia.move_child(_alas, mini(1, dunia.get_child_count() - 1))


func _exit_tree() -> void :
	if is_instance_valid(_alas):
		_alas.queue_free()


func _process(delta: float) -> void :
	_waktu += delta

	var ukuran: = _papan.size * skala
	_papan.position = Vector2( - ukuran.x / 2.0, - ukuran.y - tinggi * angkat + sin(_waktu * 2.0) * 3.0 * skala)
	if is_instance_valid(_alas):
		_alas.global_position = global_position
		_alas.visible = is_visible_in_tree()
		_alas.modulate = modulate
		_alas.queue_redraw()


func _gambar_chevron() -> void :


	var maju: = arah * (sin(_waktu * 4.0) * 8.0) * skala

	var samping: = Vector2( - arah.y, arah.x) if samping_jalan == Vector2.ZERO else samping_jalan
	for i in 3:
		var nyala: = 0.35 + 0.65 * clampf(1.0 - absf(fmod(_waktu * 2.2, 3.0) - i), 0.0, 1.0)
		var pusat: = maju + arah * (i * 22.0 - 22.0) * skala
		var ujung: = pusat + arah * 14.0 * skala
		var kiri: = pusat - arah * 6.0 * skala + samping * 20.0 * skala
		var kanan: = pusat - arah * 6.0 * skala - samping * 20.0 * skala
		var garis: = PackedVector2Array([kiri, ujung, kanan])
		_alas.draw_polyline(garis, Color(0, 0, 0, 0.5 * nyala), 14.0 * skala, true)
		_alas.draw_polyline(garis, Color(KUNING, nyala), 8.0 * skala, true)
