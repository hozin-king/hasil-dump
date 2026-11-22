extends Control









const DAFTAR: = [
	{"file": "res://assets/video/logo_studio.ogv", "latar": Color(0, 0, 0), "boleh_lewat": 8.0}, 
	{"file": "res://assets/video/intro_warung.ogv", "latar": Color8(253, 253, 253), "boleh_lewat": 0.3}, 
]
const RASIO_VIDEO: = 1280.0 / 720.0

var video: VideoStreamPlayer
var latar: ColorRect
var bingkai: AspectRatioContainer
var label_lewati: Label
var selesai: = false
var boleh_lewat: = false
var _urutan: = -1
var _baur: Array[GradientTexture2D] = []


func _ready() -> void :
	mouse_filter = Control.MOUSE_FILTER_STOP
	latar = ColorRect.new()
	latar.color = Color.BLACK
	latar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	latar.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(latar)

	bingkai = AspectRatioContainer.new()
	bingkai.ratio = RASIO_VIDEO
	bingkai.stretch_mode = AspectRatioContainer.STRETCH_FIT
	bingkai.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bingkai.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bingkai)
	video = VideoStreamPlayer.new()
	video.expand = true
	video.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bingkai.add_child(video)
	video.finished.connect(_berikutnya)

	for kanan in [false, true]:
		var g: = TextureRect.new()
		var grad: = GradientTexture2D.new()
		grad.gradient = Gradient.new()
		grad.width = 64
		grad.height = 4
		g.texture = grad
		g.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		g.stretch_mode = TextureRect.STRETCH_SCALE
		g.flip_h = kanan
		g.mouse_filter = Control.MOUSE_FILTER_IGNORE
		g.anchor_left = 0.94 if kanan else 0.0
		g.anchor_right = 1.0 if kanan else 0.06
		g.anchor_bottom = 1.0
		video.add_child(g)
		_baur.append(grad)

	label_lewati = Label.new()
	label_lewati.text = "Klik untuk melewati"
	label_lewati.add_theme_font_size_override("font_size", 24)
	label_lewati.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.6))
	label_lewati.add_theme_constant_override("outline_size", 5)
	label_lewati.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label_lewati.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label_lewati.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	label_lewati.offset_left = -300
	label_lewati.offset_right = 300
	label_lewati.offset_top = -90
	label_lewati.offset_bottom = -50
	label_lewati.modulate.a = 0.0
	add_child(label_lewati)

	GameState.hentikan_musik()
	_berikutnya()



func _berikutnya() -> void :
	if selesai:
		return
	_urutan += 1
	while _urutan < DAFTAR.size() and not ResourceLoader.exists(String(DAFTAR[_urutan]["file"])):
		_urutan += 1
	if _urutan >= DAFTAR.size():
		_ke_menu()
		return
	var d: Dictionary = DAFTAR[_urutan]
	latar.color = d["latar"]
	var c: Color = d["latar"]
	for grad in _baur:
		grad.gradient.colors = PackedColorArray([c, Color(c, 0.0)])

	var terang: bool = (d["latar"] as Color).get_luminance() > 0.5
	label_lewati.add_theme_color_override("font_color", Color(0.25, 0.17, 0.1, 0.85) if terang else Color(1, 1, 1, 0.85))
	label_lewati.add_theme_color_override("font_outline_color", Color(1, 1, 1, 0.6) if terang else Color(0, 0, 0, 0.6))
	label_lewati.modulate.a = 0.0
	boleh_lewat = false
	video.stop()
	video.stream = load(String(d["file"]))
	video.play()
	var urutan_ini: = _urutan
	GameState.get_tree().create_timer(float(d["boleh_lewat"])).timeout.connect( func():
		if urutan_ini != _urutan or selesai:
			return
		boleh_lewat = true
		var muncul: = label_lewati.create_tween()
		muncul.tween_property(label_lewati, "modulate:a", 1.0, 0.4))


func _lewati() -> void :
	if boleh_lewat:
		_berikutnya()


func _gui_input(event: InputEvent) -> void :
	if event is InputEventMouseButton and event.pressed:
		_lewati()


func _unhandled_input(event: InputEvent) -> void :
	if event is InputEventKey and event.pressed:
		_lewati()


func _ke_menu() -> void :
	if selesai:
		return
	selesai = true
	if video != null:
		video.stop()
	GameState.putar_musik("menu")

	if GameState.bahasa == "":
		var layar = load("res://scripts/pilih_bahasa.gd").new()
		add_child(layar)
		layar.dipilih.connect( func(_kode): GameState.ganti_layar(self, "res://scenes/main_menu.tscn"))
		return
	GameState.ganti_layar(self, "res://scenes/main_menu.tscn")
