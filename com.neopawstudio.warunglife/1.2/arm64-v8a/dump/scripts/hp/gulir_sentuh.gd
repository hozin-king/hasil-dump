extends ScrollContainer







const AMBANG: = 12.0
const GESEKAN: = 3.2
const KECEPATAN_MIN: = 30.0
const KECEPATAN_MAKS: = 6000.0

var _tekan: = false
var _geser: = false
var _awal: = Vector2.ZERO
var _gulir_awal: = 0.0
var _y_lalu: = 0.0
var _waktu_lalu: = 0
var _kecepatan: = 0.0
var _posisi: = 0.0


func _input(event: InputEvent) -> void :
	if not is_visible_in_tree():
		return


	for lapisan in get_tree().get_nodes_in_group("lapisan_atas"):
		if lapisan != self and is_instance_valid(lapisan) and lapisan.is_visible_in_tree() and not lapisan.is_ancestor_of(self):
			_tekan = false
			_geser = false
			_kecepatan = 0.0
			return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_tekan = get_global_rect().has_point(event.position)


			var meluncur: = absf(_kecepatan) >= KECEPATAN_MIN
			if _tekan:
				_kecepatan = 0.0
			_geser = _tekan and meluncur
			_awal = event.position
			_gulir_awal = scroll_vertical
			_y_lalu = event.position.y
			_waktu_lalu = Time.get_ticks_usec()
		elif _tekan:
			_tekan = false
			if _geser:
				_geser = false

				if Time.get_ticks_usec() - _waktu_lalu > 80000:
					_kecepatan = 0.0
				_posisi = scroll_vertical


				get_viewport().set_input_as_handled()
				var lepas: = InputEventMouseButton.new()
				lepas.button_index = MOUSE_BUTTON_LEFT
				lepas.pressed = false
				lepas.position = Vector2(-9999, -9999)
				lepas.global_position = lepas.position
				Input.parse_input_event(lepas)
	elif event is InputEventMouseMotion and _tekan:
		var jarak: float = event.position.y - _awal.y
		if not _geser and absf(jarak) > AMBANG:
			_geser = true

		var sekarang: = Time.get_ticks_usec()
		var dt: = maxf((sekarang - _waktu_lalu) / 1000000.0, 0.001)
		var v: float = - (event.position.y - _y_lalu) / dt
		_kecepatan = clampf(lerpf(_kecepatan, v, 0.4), - KECEPATAN_MAKS, KECEPATAN_MAKS)
		_y_lalu = event.position.y
		_waktu_lalu = sekarang
		if _geser:
			scroll_vertical = int(_gulir_awal - jarak)
			get_viewport().set_input_as_handled()


func _process(delta: float) -> void :
	if _tekan or absf(_kecepatan) < KECEPATAN_MIN:
		return
	_posisi += _kecepatan * delta
	_kecepatan *= exp( - GESEKAN * delta)
	var batas: = get_v_scroll_bar().max_value - get_v_scroll_bar().page
	if _posisi <= 0.0 or _posisi >= batas:
		_posisi = clampf(_posisi, 0.0, maxf(batas, 0.0))
		_kecepatan = 0.0
	scroll_vertical = int(_posisi)
