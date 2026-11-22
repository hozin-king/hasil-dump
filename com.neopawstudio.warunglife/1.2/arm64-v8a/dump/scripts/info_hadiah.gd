extends CanvasLayer




const GH: = preload("res://scripts/gaya_hud.gd")

var judul: = ""
var teks: = ""


func _ready() -> void :
	layer = 95
	process_mode = Node.PROCESS_MODE_ALWAYS
	var lapisan: = ColorRect.new()
	lapisan.color = Color(0.03, 0.02, 0.01, 0.7)
	lapisan.set_anchors_preset(Control.PRESET_FULL_RECT)
	lapisan.mouse_filter = Control.MOUSE_FILTER_STOP
	lapisan.theme = GH.tema_jendela_emas()
	add_child(lapisan)
	var tengah: = CenterContainer.new()
	tengah.set_anchors_preset(Control.PRESET_FULL_RECT)
	lapisan.add_child(tengah)

	var kartu: PanelContainer = GH.panel_emas(Vector4(30, 24, 30, 24))
	kartu.custom_minimum_size = Vector2(600, 0)
	tengah.add_child(kartu)
	var isi: = VBoxContainer.new()
	isi.add_theme_constant_override("separation", 14)
	kartu.add_child(isi)
	var l_judul: = Label.new()
	l_judul.text = judul
	l_judul.theme_type_variation = &"LabelKepala"
	l_judul.add_theme_font_size_override("font_size", 30)
	l_judul.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	isi.add_child(l_judul)
	var ket: = Label.new()
	ket.text = teks
	ket.add_theme_font_size_override("font_size", 20)
	ket.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ket.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ket.custom_minimum_size.x = 560
	isi.add_child(ket)
	var oke: = Button.new()
	oke.text = "Oke"
	oke.theme_type_variation = &"TombolHijau"
	oke.custom_minimum_size = Vector2(0, 58)
	oke.add_theme_font_size_override("font_size", 22)
	oke.pressed.connect( func():
		GameState.klik()
		queue_free())
	isi.add_child(oke)
