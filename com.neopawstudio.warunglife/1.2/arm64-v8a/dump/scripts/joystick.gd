extends Control






const JARI_JARI: = 90.0
const KENOP: = 42.0

const AREA_LEBAR: = 0.45
const AREA_TINGGI: = 0.6

const JARAK_PETUNJUK: = Vector2(40, 40)

var arah: = Vector2.ZERO
var _sentuh: = -2
var _pusat: = Vector2.ZERO


func _ready() -> void :
	mouse_filter = Control.MOUSE_FILTER_STOP
	get_viewport().size_changed.connect(atur_area)
	atur_area()



func atur_area() -> void :
	var layar: = get_viewport_rect().size
	size = Vector2(layar.x * AREA_LEBAR, layar.y * AREA_TINGGI)
	position = Vector2(0, layar.y - size.y)
	queue_redraw()


func _titik_petunjuk() -> Vector2:
	return Vector2(JARAK_PETUNJUK.x + JARI_JARI, size.y - JARAK_PETUNJUK.y - JARI_JARI)


func _draw() -> void :
	if _sentuh == -2:

		var c: = _titik_petunjuk()
		draw_circle(c, JARI_JARI, Color(0.1, 0.07, 0.04, 0.12))
		draw_arc(c, JARI_JARI, 0, TAU, 48, Color(1, 0.95, 0.85, 0.22), 3.0, true)
		draw_circle(c, KENOP, Color(1, 0.93, 0.78, 0.22))
		return
	var kenop: = _pusat + arah * (JARI_JARI - KENOP * 0.6)
	draw_circle(_pusat, JARI_JARI, Color(0.1, 0.07, 0.04, 0.3))
	draw_arc(_pusat, JARI_JARI, 0, TAU, 48, Color(1, 0.95, 0.85, 0.6), 4.0, true)
	draw_circle(kenop, KENOP, Color(1, 0.93, 0.78, 0.85))
	draw_arc(kenop, KENOP, 0, TAU, 32, Color(0.45, 0.3, 0.15), 3.0, true)


func _gui_input(event: InputEvent) -> void :
	if event is InputEventScreenTouch:
		if event.pressed and _sentuh == -2:
			_mulai(event.index, event.position)
		elif not event.pressed and event.index == _sentuh:
			_lepas()
		accept_event()
	elif event is InputEventScreenDrag and event.index == _sentuh:
		_ubah(event.position)
		accept_event()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and _sentuh == -2:
			_mulai(-1, event.position)
		elif not event.pressed and _sentuh == -1:
			_lepas()
	elif event is InputEventMouseMotion and _sentuh == -1:
		_ubah(event.position)





func _input(event: InputEvent) -> void :
	if _sentuh == -2:
		return
	if event is InputEventScreenTouch and not event.pressed and event.index == _sentuh:
		_lepas()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed and _sentuh == -1:
		_lepas()
	elif event is InputEventScreenDrag and event.index == _sentuh:
		_ubah(get_global_transform_with_canvas().affine_inverse() * event.position)



func lepas() -> void :
	if _sentuh != -2:
		_lepas()


func _notification(what: int) -> void :
	if what == NOTIFICATION_VISIBILITY_CHANGED and not is_visible_in_tree():
		lepas()
	elif what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		lepas()



func _mulai(indeks: int, titik: Vector2) -> void :
	_sentuh = indeks
	_pusat = titik.clamp(Vector2(JARI_JARI, JARI_JARI), Vector2(size.x - JARI_JARI, size.y - JARI_JARI))
	_ubah(titik)


func _ubah(titik: Vector2) -> void :
	var v: = (titik - _pusat) / (JARI_JARI - KENOP * 0.6)
	arah = v.limit_length(1.0)
	queue_redraw()


func _lepas() -> void :
	_sentuh = -2
	arah = Vector2.ZERO
	queue_redraw()



func baca() -> Vector2:
	var k: = Vector2(Input.get_axis("ui_left", "ui_right"), Input.get_axis("ui_up", "ui_down"))
	for pasangan in [[KEY_A, Vector2.LEFT], [KEY_D, Vector2.RIGHT], [KEY_W, Vector2.UP], [KEY_S, Vector2.DOWN]]:
		if Input.is_key_pressed(pasangan[0]):
			k += pasangan[1]
	if k == Vector2.ZERO:
		return arah

	return k.normalized() * (1.0 if Input.is_key_pressed(KEY_SHIFT) else 0.75)
