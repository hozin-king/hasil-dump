extends Control





signal ditutup

const GH: = preload("res://scripts/gaya_hud.gd")
const WARNA_BAIK: = Color(1.0, 0.77, 0.26)
const WARNA_BURUK: = Color(0.55, 0.6, 0.7)

var _kartu: PanelContainer
var _sinar: Control
var _baik: = true
var _isi_daftar: VBoxContainer = null



func _wadah_daftar(kolom: VBoxContainer, warna: Color) -> VBoxContainer:
	if _isi_daftar == null:
		var kotak: = PanelContainer.new()
		var g: = StyleBoxFlat.new()
		g.bg_color = Color(0, 0, 0, 0.28)
		g.border_color = Color(warna, 0.4)
		g.set_border_width_all(2)
		g.set_corner_radius_all(12)
		for sisi in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
			g.set_content_margin(sisi, 14)
		kotak.add_theme_stylebox_override("panel", g)
		kotak.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		kolom.add_child(kotak)
		_isi_daftar = VBoxContainer.new()
		_isi_daftar.add_theme_constant_override("separation", 8)
		kotak.add_child(_isi_daftar)
	return _isi_daftar


func isi(judul: String, teks: String, daftar: Array = [], gambar: = "", baik: = true) -> void :
	_baik = baik
	theme = load("res://scripts/gaya_hud.gd").tema_jendela_emas()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 200
	var gelap: = ColorRect.new()
	gelap.color = Color(0.03, 0.02, 0.01, 0.6)
	gelap.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	gelap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(gelap)

	_sinar = Control.new()
	_sinar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_sinar.draw.connect(_gambar_sinar)
	add_child(_sinar)




	var warna_tepi: = GH.EMAS
	_kartu = PanelContainer.new()
	_kartu.custom_minimum_size = Vector2(600, 0)
	var luar: = StyleBoxFlat.new()
	luar.bg_color = Color(GH.MALAM, 0.97)
	luar.border_color = warna_tepi
	luar.set_border_width_all(4)
	luar.set_corner_radius_all(22)
	luar.shadow_color = Color(1.0, 0.72, 0.2, 0.3) if baik else Color(0, 0, 0, 0.55)
	luar.shadow_size = 26 if baik else 16
	luar.shadow_offset = Vector2.ZERO
	for sisi in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		luar.set_content_margin(sisi, 10)
	_kartu.add_theme_stylebox_override("panel", luar)
	add_child(_kartu)
	var dalam: = PanelContainer.new()
	var gaya_dalam: = StyleBoxFlat.new()
	gaya_dalam.bg_color = Color(1, 1, 1, 0.02)
	gaya_dalam.border_color = Color(warna_tepi, 0.35)
	gaya_dalam.set_border_width_all(2)
	gaya_dalam.set_corner_radius_all(15)
	gaya_dalam.set_content_margin(SIDE_LEFT, 26)
	gaya_dalam.set_content_margin(SIDE_RIGHT, 26)
	gaya_dalam.set_content_margin(SIDE_TOP, 20)
	gaya_dalam.set_content_margin(SIDE_BOTTOM, 22)
	dalam.add_theme_stylebox_override("panel", gaya_dalam)
	_kartu.add_child(dalam)
	var kolom: = VBoxContainer.new()
	kolom.add_theme_constant_override("separation", 14)
	kolom.alignment = BoxContainer.ALIGNMENT_CENTER
	dalam.add_child(kolom)

	var pita: = PanelContainer.new()
	var gaya_pita: = StyleBoxFlat.new()
	gaya_pita.bg_color = GH.EMAS
	gaya_pita.set_corner_radius_all(16)
	gaya_pita.border_color = GH.EMAS_MUDA
	gaya_pita.set_border_width_all(3)
	gaya_pita.set_content_margin(SIDE_LEFT, 28)
	gaya_pita.set_content_margin(SIDE_RIGHT, 28)
	gaya_pita.set_content_margin(SIDE_TOP, 4)
	gaya_pita.set_content_margin(SIDE_BOTTOM, 4)
	gaya_pita.shadow_color = GH.EMAS_TUA
	gaya_pita.shadow_size = 1
	gaya_pita.shadow_offset = Vector2(0, 6)
	pita.add_theme_stylebox_override("panel", gaya_pita)
	pita.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	kolom.add_child(pita)
	var label_judul: = Label.new()
	label_judul.text = judul.to_upper()
	label_judul.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	GH.gaya_label(label_judul, 46 if judul.length() <= 20 else 36, GH.TEKS_GELAP, true, 0)
	pita.add_child(label_judul)
	if gambar != "" and ResourceLoader.exists(gambar):
		var g: = TextureRect.new()
		g.texture = load(gambar)
		g.custom_minimum_size = Vector2(120, 120)
		g.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		g.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		kolom.add_child(g)
	elif baik and not daftar.any( func(d): return d is Dictionary):
		var bintang: = Label.new()
		bintang.text = "★ ★ ★"
		bintang.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		bintang.add_theme_font_size_override("font_size", 44)
		bintang.add_theme_color_override("font_color", WARNA_BAIK)
		kolom.add_child(bintang)
	if teks != "":
		var label_isi: = Label.new()
		label_isi.text = teks
		label_isi.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label_isi.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label_isi.custom_minimum_size = Vector2(500, 0)
		GH.gaya_label(label_isi, 24, GH.EMAS_MUDA)
		kolom.add_child(label_isi)


	var kisi: GridContainer = null
	var jumlah_ikon: = daftar.filter( func(d): return d is Dictionary).size()
	for d in daftar:
		if d is Dictionary:
			if kisi == null:
				kisi = GridContainer.new()
				kisi.columns = 3 if jumlah_ikon >= 5 else 2
				kisi.add_theme_constant_override("h_separation", 10)
				kisi.add_theme_constant_override("v_separation", 8)
				kisi.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
				_wadah_daftar(kolom, warna_tepi).add_child(kisi)
			kisi.add_child(_kotak_ikon(String(d.get("teks", "")), String(d.get("ikon", ""))))
			continue
		var baris: = Label.new()
		baris.text = ("✔  " if baik else "•  ") + String(d)
		baris.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		baris.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		baris.custom_minimum_size = Vector2(500, 0)
		GH.gaya_label(baris, 22, GH.HIJAU_UANG if baik else Color(1.0, 0.62, 0.5))
		_wadah_daftar(kolom, warna_tepi).add_child(baris)
	var tombol: = Button.new()
	tombol.text = "Mantap!" if baik else "Oke"
	tombol.theme_type_variation = &"TombolHijau"
	tombol.custom_minimum_size = Vector2(240, 66)
	tombol.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	tombol.pressed.connect(_tutup)
	kolom.add_child(tombol)

	GameState.bunyi("hadiah" if baik else "klik")

	_kartu.scale = Vector2(0.3, 0.3)
	_kartu.modulate.a = 0.0
	await get_tree().process_frame
	_letakkan()
	var tw: = create_tween().set_parallel()
	tw.tween_property(_kartu, "scale", Vector2.ONE, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(_kartu, "modulate:a", 1.0, 0.2)
	if baik:
		_konfeti()



func _kotak_ikon(teks: String, ikon: String) -> Control:
	var kotak: = PanelContainer.new()
	var gaya: = StyleBoxFlat.new()
	gaya.bg_color = Color(0.09, 0.1, 0.15)
	gaya.border_color = Color(GH.EMAS, 0.55)
	gaya.set_border_width_all(2)
	gaya.set_corner_radius_all(12)
	gaya.content_margin_left = 8
	gaya.content_margin_right = 12
	gaya.content_margin_top = 6
	gaya.content_margin_bottom = 6
	kotak.add_theme_stylebox_override("panel", gaya)
	kotak.custom_minimum_size = Vector2(250, 0)
	var h: = HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	kotak.add_child(h)
	var g: = TextureRect.new()
	g.custom_minimum_size = Vector2(48, 48)
	g.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	g.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if ikon != "" and ResourceLoader.exists(ikon):
		g.texture = load(ikon)
	h.add_child(g)
	var label: = Label.new()
	label.text = teks
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size = Vector2(170, 0)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 19)
	label.add_theme_color_override("font_color", Color(0.72, 0.95, 0.55) if _baik else Color(1.0, 0.72, 0.6))
	h.add_child(label)
	return kotak


func _letakkan() -> void :
	var layar: = get_viewport_rect().size
	_kartu.size = _kartu.get_combined_minimum_size()
	_kartu.position = (layar - _kartu.size) / 2.0
	_kartu.pivot_offset = _kartu.size / 2.0
	_sinar.position = layar / 2.0


func _process(delta: float) -> void :
	if _sinar != null:
		_sinar.rotation += delta * 0.35
		_sinar.queue_redraw()


func _gambar_sinar() -> void :
	var warna: = WARNA_BAIK if _baik else WARNA_BURUK
	for i in 12:
		var a: = TAU * i / 12.0
		var titik: = PackedVector2Array([Vector2.ZERO, Vector2.from_angle(a - 0.09) * 700.0, Vector2.from_angle(a + 0.09) * 700.0])
		_sinar.draw_colored_polygon(titik, Color(warna, 0.16))
	_sinar.draw_circle(Vector2.ZERO, 260.0, Color(warna, 0.12))


func _konfeti() -> void :
	var p: = CPUParticles2D.new()
	p.position = Vector2(get_viewport_rect().size.x / 2.0, -20)
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = Vector2(get_viewport_rect().size.x / 2.0, 10)
	p.amount = 90
	p.lifetime = 3.0
	p.one_shot = true
	p.explosiveness = 0.7
	p.direction = Vector2(0, 1)
	p.spread = 30.0
	p.initial_velocity_min = 120.0
	p.initial_velocity_max = 260.0
	p.gravity = Vector2(0, 220)
	p.angular_velocity_min = -300.0
	p.angular_velocity_max = 300.0
	p.scale_amount_min = 6.0
	p.scale_amount_max = 11.0
	var warna: = Gradient.new()
	warna.offsets = PackedFloat32Array([0.0, 0.25, 0.5, 0.75, 1.0])
	warna.colors = PackedColorArray([Color(0.95, 0.3, 0.3), Color(0.98, 0.8, 0.2), Color(0.3, 0.75, 0.4), Color(0.3, 0.6, 0.95), Color(0.9, 0.45, 0.85)])
	p.color_initial_ramp = warna
	add_child(p)
	move_child(p, 1)
	p.emitting = true


func _tutup() -> void :
	GameState.klik()
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tw: = create_tween().set_parallel()
	tw.tween_property(_kartu, "scale", Vector2(0.8, 0.8), 0.15)
	tw.tween_property(self, "modulate:a", 0.0, 0.2)
	await tw.finished
	ditutup.emit()
	queue_free()
