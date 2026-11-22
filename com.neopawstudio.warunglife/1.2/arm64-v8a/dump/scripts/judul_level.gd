extends Control






signal selesai

const GH: = preload("res://scripts/gaya_hud.gd")
const MASUK: = 0.5
const KELUAR: = 0.6
const DURASI_TOTAL: = 4.0
const EMAS: = Color(1.0, 0.77, 0.26)

var _nama: Label


func tampil(level: int, nama_level: String) -> void :
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	modulate.a = 0.0
	var pita: = ColorRect.new()
	pita.color = Color(0.035, 0.04, 0.07, 0.82)
	pita.anchor_left = 0.0
	pita.anchor_right = 1.0
	pita.anchor_top = 0.5
	pita.anchor_bottom = 0.5
	pita.offset_top = -135
	pita.offset_bottom = 135
	pita.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(pita)
	for atas in [true, false]:
		var garis: = ColorRect.new()
		garis.color = EMAS
		garis.anchor_left = 0.0
		garis.anchor_right = 1.0
		garis.anchor_top = 0.0 if atas else 1.0
		garis.anchor_bottom = garis.anchor_top
		garis.offset_top = 0.0 if atas else -4.0
		garis.offset_bottom = 4.0 if atas else 0.0
		garis.mouse_filter = Control.MOUSE_FILTER_IGNORE
		pita.add_child(garis)
	var kolom: = VBoxContainer.new()
	kolom.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	kolom.alignment = BoxContainer.ALIGNMENT_CENTER
	kolom.add_theme_constant_override("separation", -6)
	kolom.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pita.add_child(kolom)
	var label_level: = GH.label("LEVEL %d" % level, 50, EMAS, true, 6)
	label_level.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	kolom.add_child(label_level)
	_nama = GH.label(nama_level.to_upper(), 124 if nama_level.length() <= 16 else 96, Color(1.0, 0.93, 0.66), true, 8)
	_nama.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_nama.resized.connect( func(): _nama.pivot_offset = _nama.size / 2.0)
	kolom.add_child(_nama)


	GameState.bunyi("judul_level")

	var tw: = create_tween()
	tw.tween_property(self, "modulate:a", 1.0, MASUK)
	tw.tween_interval(DURASI_TOTAL - MASUK - KELUAR)
	tw.tween_property(self, "modulate:a", 0.0, KELUAR)
	tw.tween_callback(_beres)
	_nama.scale = Vector2(1.06, 1.06)
	create_tween().tween_property(_nama, "scale", Vector2.ONE, DURASI_TOTAL).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func _beres() -> void :
	selesai.emit()
	queue_free()
