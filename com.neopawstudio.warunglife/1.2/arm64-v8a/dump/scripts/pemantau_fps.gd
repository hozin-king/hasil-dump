extends CanvasLayer







const JEDA_AWAL: = 4.0
const JUMLAH_SAMPEL: = 12
const BATAS: = 0.75

var _sampel: Array[float] = []
var _detik: = 0.0
var _jeda: = JEDA_AWAL
var _adegan_lalu: = 0
var _label_fps: Label
var _pesan: Label
var _sisa_pesan: = 0.0


func _ready() -> void :
	layer = 120
	process_mode = Node.PROCESS_MODE_ALWAYS
	_label_fps = Label.new()
	_label_fps.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_label_fps.position.y -= 34
	_label_fps.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_label_fps.add_theme_font_size_override("font_size", 18)
	_label_fps.add_theme_color_override("font_color", Color(1, 1, 0.6))
	_label_fps.add_theme_color_override("font_outline_color", Color.BLACK)
	_label_fps.add_theme_constant_override("outline_size", 5)
	_label_fps.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label_fps.visible = false
	add_child(_label_fps)
	_pesan = Label.new()
	_pesan.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_pesan.position.y = 90
	_pesan.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_pesan.add_theme_font_size_override("font_size", 20)
	_pesan.add_theme_color_override("font_color", Color.WHITE)
	_pesan.add_theme_color_override("font_outline_color", Color(0.1, 0.06, 0.02))
	_pesan.add_theme_constant_override("outline_size", 6)
	_pesan.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pesan.hide()
	add_child(_pesan)


func _process(delta: float) -> void :
	var fps: = Engine.get_frames_per_second()
	if _label_fps.visible:
		_label_fps.text = "FPS %d · Grafik %s" % [fps, GameState.kualitas.capitalize()]
	if _sisa_pesan > 0.0:
		_sisa_pesan -= delta
		if _sisa_pesan <= 0.0:
			_pesan.hide()

	var adegan: = get_tree().current_scene
	var id: = adegan.get_instance_id() if adegan != null else 0
	if id != _adegan_lalu:
		_adegan_lalu = id
		_jeda = JEDA_AWAL
		_sampel.clear()
	if not GameState.sedang_main or get_tree().paused or GameState.kualitas_manual or GameState.kualitas == "rendah":
		return
	if _jeda > 0.0:
		_jeda -= delta
		return
	_detik += delta
	if _detik < 1.0:
		return
	_detik = 0.0
	_sampel.append(float(fps))
	if _sampel.size() < JUMLAH_SAMPEL:
		return
	var rata: = 0.0
	for s in _sampel:
		rata += s
	rata /= _sampel.size()
	_sampel.clear()
	var target: = float(Engine.max_fps if Engine.max_fps > 0 else 60)
	if rata < target * BATAS and GameState.turunkan_kualitas_otomatis():
		if GameState.analitik != null:
			GameState.analitik.catat("grafik_turun", {"ke": GameState.kualitas, "fps": int(rata)})
		_pesan.text = "Grafik diturunkan otomatis ke %s supaya lebih lancar.\nBisa diubah di Pengaturan." % GameState.kualitas.capitalize()
		_pesan.show()
		_sisa_pesan = 5.0
		_jeda = JEDA_AWAL
