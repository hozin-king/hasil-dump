extends Control











const GELAP: = Color(0, 0, 0, 0.6)
const KUNING: = Color(1.0, 0.82, 0.25)
const JARAK: = 10.0
const SUDUT: = 16.0

var sasaran: Control = null
var sasaran2: Control = null
var _teks: = ""
var _waktu: = 0.0
var _lubang: = Rect2()
var _asal: = Vector2.ZERO
var _tujuan: = Vector2.ZERO
var _penghalang: Array[Control] = []
var _kotak: PanelContainer
var _label: Label


var ringan: = false
var _rect_asal: = Rect2()
var _rect_tujuan: = Rect2()
signal dimengerti
var _jelaskan: = false
var _tombol_oke: Button


func _ready() -> void :
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	for i in 4:
		var p: = Control.new()
		p.mouse_filter = Control.MOUSE_FILTER_STOP
		add_child(p)
		_penghalang.append(p)
	_kotak = PanelContainer.new()
	var gaya: = StyleBoxFlat.new()
	gaya.bg_color = Color(0.13, 0.08, 0.04, 0.95)
	gaya.border_color = KUNING
	gaya.set_border_width_all(3)
	gaya.set_corner_radius_all(14)
	gaya.content_margin_left = 16
	gaya.content_margin_right = 16
	gaya.content_margin_top = 10
	gaya.content_margin_bottom = 10
	_kotak.add_theme_stylebox_override("panel", gaya)
	_kotak.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label = Label.new()
	_label.add_theme_font_size_override("font_size", 20)
	_label.add_theme_color_override("font_color", Color(1, 0.97, 0.88))
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.custom_minimum_size.x = 300
	var susun: = VBoxContainer.new()
	susun.add_theme_constant_override("separation", 8)
	susun.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_kotak.add_child(susun)
	susun.add_child(_label)
	_tombol_oke = Button.new()
	_tombol_oke.text = "Mengerti"
	_tombol_oke.theme_type_variation = &"TombolHijau"
	_tombol_oke.custom_minimum_size = Vector2(170, 52)
	_tombol_oke.add_theme_font_size_override("font_size", 21)
	_tombol_oke.size_flags_horizontal = Control.SIZE_SHRINK_END
	_tombol_oke.pressed.connect(_selesai_jelaskan)
	_tombol_oke.hide()
	susun.add_child(_tombol_oke)
	add_child(_kotak)
	hide()


func sorot(target: Control, teks: String, tujuan: Control = null) -> void :
	ringan = false
	_jelaskan = false
	_tombol_oke.hide()
	_label.custom_minimum_size.x = 300
	sasaran = target
	sasaran2 = tujuan
	_teks = teks
	_label.text = teks
	_kotak.reset_size()
	show()



func sorot_ringan(asal: Control, tujuan: Control, teks: String) -> void :
	sorot(asal, teks, tujuan)
	ringan = true



func jelaskan(target: Control, teks: String) -> void :
	sorot(target, teks)
	_jelaskan = true
	_label.custom_minimum_size.x = 420
	_tombol_oke.show()
	_kotak.reset_size()
	await dimengerti


func jelaskan_urut(daftar: Array) -> void :
	for d in daftar:
		var t: Control = d[0]
		if t == null or (is_instance_valid(t) and t.is_visible_in_tree()):
			await jelaskan(t, String(d[1]))
	lepas()


func _selesai_jelaskan() -> void :
	if not _jelaskan:
		return
	_jelaskan = false
	_tombol_oke.hide()
	dimengerti.emit()


func lepas() -> void :
	ringan = false
	if _jelaskan:
		_selesai_jelaskan()
	sasaran2 = null
	sasaran = null
	hide()


func _process(delta: float) -> void :
	if not visible:
		return
	if _jelaskan and sasaran == null:
		_proses_tengah(delta)
		return
	if sasaran == null or not is_instance_valid(sasaran) or not sasaran.is_visible_in_tree():
		if _jelaskan:
			_selesai_jelaskan()
			return

		_lubang = Rect2()
		modulate.a = 0.0
		for p in _penghalang:
			p.mouse_filter = Control.MOUSE_FILTER_IGNORE
		return
	modulate.a = 1.0
	_waktu += delta

	var r: = Rect2(sasaran.get_global_transform() * Vector2.ZERO, sasaran.size * sasaran.get_global_transform().get_scale())
	if ringan:
		_proses_ringan(r)
		return
	_lubang = r.grow(JARAK)
	_tujuan = Vector2.ZERO

	if sasaran2 != null and is_instance_valid(sasaran2) and sasaran2.is_visible_in_tree():
		var r2: = Rect2(sasaran2.get_global_transform() * Vector2.ZERO, sasaran2.size * sasaran2.get_global_transform().get_scale())
		_lubang = _lubang.merge(r2.grow(JARAK))
		_asal = r.get_center()
		_tujuan = r2.get_center()
	var layar: = get_viewport_rect().size

	var rects: = [
		Rect2(0, 0, layar.x, _lubang.position.y), 
		Rect2(0, _lubang.end.y, layar.x, layar.y - _lubang.end.y), 
		Rect2(0, _lubang.position.y, _lubang.position.x, _lubang.size.y), 
		Rect2(_lubang.end.x, _lubang.position.y, layar.x - _lubang.end.x, _lubang.size.y)]
	for i in 4:
		_penghalang[i].mouse_filter = Control.MOUSE_FILTER_STOP
		_penghalang[i].position = rects[i].position
		_penghalang[i].size = rects[i].size

	if _jelaskan:
		_kotak.reset_size()
	var k: = _kotak.size
	var pos: = Vector2(_lubang.get_center().x - k.x / 2.0, _lubang.position.y - k.y - 70.0)
	if pos.y < 10.0:
		pos.y = _lubang.end.y + 70.0
		if pos.y + k.y > layar.y - 10.0:

			pos.y = layar.y - k.y - 10.0
	pos.x = clampf(pos.x, 10.0, layar.x - k.x - 10.0)
	_kotak.position = pos
	if _jelaskan:

		_penghalang[0].position = Vector2.ZERO
		_penghalang[0].size = layar
	queue_redraw()



func _proses_tengah(delta: float) -> void :
	modulate.a = 1.0
	_waktu += delta
	var layar: = get_viewport_rect().size
	_lubang = Rect2()
	_tujuan = Vector2.ZERO
	for p in _penghalang:
		p.mouse_filter = Control.MOUSE_FILTER_STOP
		p.size = Vector2.ZERO
	_penghalang[0].position = Vector2.ZERO
	_penghalang[0].size = layar
	_kotak.reset_size()
	_kotak.position = (layar - _kotak.size) / 2.0
	queue_redraw()


func _proses_ringan(r: Rect2) -> void :
	_rect_asal = r
	_rect_tujuan = Rect2()
	_tujuan = Vector2.ZERO
	if sasaran2 != null and is_instance_valid(sasaran2) and sasaran2.is_visible_in_tree():
		_rect_tujuan = Rect2(sasaran2.get_global_transform() * Vector2.ZERO, sasaran2.size * sasaran2.get_global_transform().get_scale())
		_asal = r.get_center()
		_tujuan = _rect_tujuan.get_center()

	for p in _penghalang:
		p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_lubang = Rect2()

	var layar: = get_viewport_rect().size
	var k: = _kotak.size
	var pos: = Vector2(r.get_center().x - k.x / 2.0, r.position.y - k.y - 40.0)
	if pos.y < 10.0:
		pos.y = r.end.y + 40.0
	pos.x = clampf(pos.x, 10.0, layar.x - k.x - 10.0)
	_kotak.position = pos
	queue_redraw()


func _draw_ringan() -> void :
	var denyut: = 0.5 + 0.5 * sin(_waktu * 5.0)
	var warna: = Color(KUNING, 0.55 + 0.45 * denyut)
	_kotak_bulat(_rect_asal.grow(3.0 + denyut * 3.0), warna, 4.0)
	if _tujuan != Vector2.ZERO:
		_kotak_bulat(_rect_tujuan.grow(3.0 + denyut * 3.0), warna, 4.0)
		var jarak: = _asal.distance_to(_tujuan)
		var ruas: = int(jarak / 24.0)
		for i in ruas:
			if i % 2 == 0:
				draw_line(_asal.lerp(_tujuan, i / float(ruas)), _asal.lerp(_tujuan, (i + 1) / float(ruas)), Color(1, 1, 1, 0.7), 4.0, true)
		var t: = fmod(_waktu * 0.6, 1.0)
		_gambar_tangan(_asal.lerp(_tujuan, smoothstep(0.15, 0.85, t)))


func _draw() -> void :
	if ringan:
		_draw_ringan()
		return
	if _lubang.size == Vector2.ZERO:
		if _jelaskan and sasaran == null:
			draw_rect(get_viewport_rect(), GELAP)
		return
	var layar: = get_viewport_rect().size

	draw_rect(Rect2(0, 0, layar.x, _lubang.position.y), GELAP)
	draw_rect(Rect2(0, _lubang.end.y, layar.x, layar.y - _lubang.end.y), GELAP)
	draw_rect(Rect2(0, _lubang.position.y, _lubang.position.x, _lubang.size.y), GELAP)
	draw_rect(Rect2(_lubang.end.x, _lubang.position.y, layar.x - _lubang.end.x, _lubang.size.y), GELAP)
	for s in [[_lubang.position, Vector2(1, 1)], [Vector2(_lubang.end.x, _lubang.position.y), Vector2(-1, 1)], 
			[Vector2(_lubang.position.x, _lubang.end.y), Vector2(1, -1)], [_lubang.end, Vector2(-1, -1)]]:
		var titik: Vector2 = s[0]
		var arah: Vector2 = s[1]
		var pusat: Vector2 = titik + arah * SUDUT
		var poli: = PackedVector2Array([titik])
		for i in 9:
			var a: = (arah * -1.0).angle() + (i / 8.0 - 0.5) * PI / 2.0
			poli.append(pusat + Vector2.from_angle(a) * SUDUT)
		draw_colored_polygon(poli, GELAP)

	var denyut: = 0.5 + 0.5 * sin(_waktu * 5.0)
	var bingkai: = _lubang.grow(2.0 + denyut * 4.0)
	_kotak_bulat(bingkai, Color(KUNING, 0.55 + 0.45 * denyut), 4.0)

	if _tujuan != Vector2.ZERO:
		var jarak: = _asal.distance_to(_tujuan)
		var ruas: = int(jarak / 24.0)
		for i in ruas:
			if i % 2 == 0:
				draw_line(_asal.lerp(_tujuan, i / float(ruas)), _asal.lerp(_tujuan, (i + 1) / float(ruas)), Color(1, 1, 1, 0.7), 4.0, true)
		var t: = fmod(_waktu * 0.6, 1.0)
		var gerak: = smoothstep(0.15, 0.85, t)
		_gambar_tangan(_asal.lerp(_tujuan, gerak))
		return
	if _jelaskan:
		return

	var ujung: = _lubang.get_center() + Vector2(_lubang.size.x * 0.18, _lubang.size.y * 0.15)
	var ketuk: = absf(sin(_waktu * 4.0)) * 14.0
	_gambar_tangan(ujung + Vector2(ketuk, ketuk))
	if ketuk < 2.0:
		draw_arc(ujung, 10.0 + (2.0 - ketuk) * 8.0, 0.0, TAU, 24, Color(1, 1, 1, 0.6), 3.0, true)


func _kotak_bulat(r: Rect2, warna: Color, tebal: float) -> void :
	var gaya: = StyleBoxFlat.new()
	gaya.draw_center = false
	gaya.border_color = warna
	gaya.set_border_width_all(int(tebal))
	gaya.set_corner_radius_all(int(SUDUT + 4.0))
	draw_style_box(gaya, r)




const TANGAN_TUNJUK: = preload("res://assets/ikon/tangan_tunjuk.svg")
const UKURAN_TANGAN: = Vector2(72, 90)
const UJUNG_TELUNJUK: = Vector2(52.0 / 120.0, 26.0 / 150.0)

func _gambar_tangan(ujung: Vector2) -> void :
	var uj: = UKURAN_TANGAN * UJUNG_TELUNJUK
	draw_set_transform_matrix(Transform2D(deg_to_rad(-40.0), ujung))
	draw_texture_rect(TANGAN_TUNJUK, Rect2( - uj + Vector2(4, 6), UKURAN_TANGAN), false, Color(0, 0, 0, 0.3))
	draw_texture_rect(TANGAN_TUNJUK, Rect2( - uj, UKURAN_TANGAN), false)
	draw_set_transform_matrix(Transform2D.IDENTITY)
