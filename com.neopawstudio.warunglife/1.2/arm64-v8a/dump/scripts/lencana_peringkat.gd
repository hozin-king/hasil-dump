extends VBoxContainer





const GH: = preload("res://scripts/gaya_hud.gd")
const PP: = preload("res://scripts/papan_peringkat.gd")

var saat_diketuk: Callable
var _angka: Label
var _tekan: = false


func _ready() -> void :
	add_theme_constant_override("separation", 2)
	size_flags_vertical = Control.SIZE_SHRINK_CENTER
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	add_child(GH.tebal(GH.label("PERINGKAT", GH.UKURAN_JUDUL_HUD, GH.KUNING, true)))
	var baris: = HBoxContainer.new()
	baris.add_theme_constant_override("separation", 6)
	baris.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(baris)
	var piala: = TextureRect.new()
	piala.texture = load("res://assets/ikon/papan.svg")
	piala.custom_minimum_size = Vector2.ONE * GH.UKURAN_BINTANG_HUD
	piala.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	piala.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	piala.mouse_filter = Control.MOUSE_FILTER_IGNORE
	baris.add_child(piala)
	_angka = GH.tebal(GH.label("", 34, Color.WHITE, true))
	baris.add_child(_angka)
	GameState.data_berubah.connect(perbarui)
	GameState.papan.diperbarui.connect(perbarui)
	perbarui()



func perbarui() -> void :
	var n: = PP.peringkat("semua")
	_angka.text = "#" + (PP.angka(n) if n > 0 else "-")



func _gui_input(e: InputEvent) -> void :
	if not (e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT):
		return
	pivot_offset = size / 2
	if e.pressed:
		_tekan = true
		scale = Vector2.ONE * 0.92
		accept_event()
	elif _tekan:
		_tekan = false
		create_tween().tween_property(self, "scale", Vector2.ONE, 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		accept_event()
		if get_global_rect().has_point(get_global_mouse_position()):
			GameState.klik()
			if saat_diketuk.is_valid():
				saat_diketuk.call()
