extends Control





const UKURAN: = 72.0
const SKALA_PEGANG: = 1.35
const SKALA_DI_KRESEK: = 2.3

var kresek: Control = null
var _isi: Control


static func buat(gambar: Texture2D, nama: String, kresek_tujuan: Control) -> Control:
	var p: Control = load("res://scripts/pratinjau_seret.gd").new()
	p.kresek = kresek_tujuan
	p._rakit(gambar, nama)
	return p


func _rakit(gambar: Texture2D, nama: String) -> void :
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	_isi = Control.new()
	_isi.position = Vector2(0, - UKURAN * 1.2)
	_isi.scale = Vector2(0.6, 0.6)
	add_child(_isi)
	var tex: = TextureRect.new()
	tex.texture = gambar
	tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tex.size = Vector2(UKURAN, UKURAN)
	tex.position = - tex.size / 2.0
	_isi.add_child(tex)
	var label: = Label.new()
	label.text = nama
	label.add_theme_font_size_override("font_size", 15)
	label.add_theme_color_override("font_color", Color.WHITE)
	label.add_theme_color_override("font_outline_color", Color(0.15, 0.08, 0.02))
	label.add_theme_constant_override("outline_size", 6)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.size = Vector2(160, 22)
	label.position = Vector2(-80, UKURAN / 2.0 - 2.0)
	_isi.add_child(label)


func _process(delta: float) -> void :
	var di_kresek: = kresek != null and kresek.get_global_rect().has_point(get_global_mouse_position())
	var tujuan: = SKALA_DI_KRESEK if di_kresek else SKALA_PEGANG
	_isi.scale = _isi.scale.lerp(Vector2(tujuan, tujuan), minf(delta * 14.0, 1.0))
