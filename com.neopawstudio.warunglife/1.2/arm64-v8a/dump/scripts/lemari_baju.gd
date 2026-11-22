extends Control




signal dipilih(id: String)
signal ditutup

const UKURAN: = Vector2(1100, 640)
const LEBAR_PINTU: = 104.0
const KAYU: = Color("#7a4a2a")
const KAYU_TERANG: = Color("#9a6238")
const KAYU_GELAP: = Color("#4f2d17")
const DALAM: = Color("#2f1d11")
const BESI: = Color("#d8d2c4")
const KREM: = Color("#f7ecd6")
const EMAS: = Color("#f2c14e")
const TINTA: = Color("#4a2a14")

const GAMBAR: = {"": "res://assets/ui/lemari/baju_bawaan.png", "sarung": "res://assets/ui/lemari/baju_sarung.png"}
const SILUET: = "res://assets/ui/lemari/siluet.png"

var _badan: Control
var _kartu: = {}


func _ready() -> void :
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var gelap: = ColorRect.new()
	gelap.color = Color(0.03, 0.02, 0.01, 0.62)
	gelap.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(gelap)
	var tengah: = CenterContainer.new()
	tengah.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(tengah)
	_badan = Control.new()
	_badan.custom_minimum_size = UKURAN
	_badan.draw.connect(_gambar_lemari)
	tengah.add_child(_badan)

	var papan: = Label.new()
	papan.text = "LEMARI BAJU"
	papan.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	papan.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	papan.position = Vector2(UKURAN.x / 2 - 150, 6)
	papan.size = Vector2(300, 44)
	papan.add_theme_font_size_override("font_size", 26)
	papan.add_theme_color_override("font_color", Color("#3a2010"))
	_badan.add_child(papan)

	var baris: = HBoxContainer.new()
	baris.add_theme_constant_override("separation", 14)
	baris.alignment = BoxContainer.ALIGNMENT_CENTER
	baris.position = Vector2(LEBAR_PINTU + 26, 128)
	baris.size = Vector2(UKURAN.x - 2 * LEBAR_PINTU - 52, 400)
	_badan.add_child(baris)
	for id in GameState.URUTAN_LEMARI:
		var k: = _buat_kartu(String(id))
		_kartu[String(id)] = k
		baris.add_child(k)

	var tutup: = Button.new()
	tutup.text = "Tutup"
	tutup.theme_type_variation = &"TombolKayu"
	tutup.custom_minimum_size = Vector2(200, 54)
	tutup.add_theme_font_size_override("font_size", 24)
	tutup.position = Vector2(UKURAN.x / 2 - 100, UKURAN.y - 96)
	tutup.pressed.connect( func():
		GameState.klik()
		ditutup.emit()
		queue_free())
	_badan.add_child(tutup)
	_badan.pivot_offset = UKURAN / 2
	_badan.scale = Vector2(0.94, 0.94)
	_badan.modulate.a = 0.0
	var muncul: = create_tween().set_parallel()
	muncul.tween_property(_badan, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	muncul.tween_property(_badan, "modulate:a", 1.0, 0.15)



func _bisa_dipakai(id: String) -> bool:
	return id == "" or (GameState.FILE_MODEL_BAJU.has(id) and GameState.baju_dimiliki.has(id))


func _rahasia(id: String) -> bool:
	return id != "" and not GameState.FILE_MODEL_BAJU.has(id)


func _buat_kartu(id: String) -> PanelContainer:
	var kartu: = PanelContainer.new()
	kartu.custom_minimum_size = Vector2(160, 392)
	kartu.mouse_filter = Control.MOUSE_FILTER_STOP
	var isi: = VBoxContainer.new()
	isi.add_theme_constant_override("separation", 4)
	kartu.add_child(isi)
	var bingkai: = Control.new()
	bingkai.custom_minimum_size = Vector2(140, 250)
	bingkai.clip_contents = true
	isi.add_child(bingkai)
	var gambar: = TextureRect.new()
	gambar.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	gambar.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	gambar.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	gambar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bingkai.add_child(gambar)
	var nama: = Label.new()
	nama.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nama.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	nama.custom_minimum_size = Vector2(140, 52)
	nama.add_theme_font_size_override("font_size", 19)
	nama.add_theme_color_override("font_color", TINTA)
	isi.add_child(nama)
	var tombol: = Button.new()
	tombol.custom_minimum_size = Vector2(140, 48)
	tombol.add_theme_font_size_override("font_size", 20)
	isi.add_child(tombol)
	if _rahasia(id):

		gambar.texture = load(SILUET)
		gambar.modulate = Color(1, 1, 1, 0.55)
		var tanya: = Label.new()
		tanya.text = "?"
		tanya.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		tanya.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tanya.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		tanya.add_theme_font_size_override("font_size", 110)
		tanya.add_theme_color_override("font_color", Color(1, 1, 1, 0.9))
		tanya.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.6))
		tanya.add_theme_constant_override("outline_size", 10)
		tanya.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bingkai.add_child(tanya)
		nama.text = "???"
		tombol.text = "Segera hadir"
		tombol.theme_type_variation = &"TombolKayu"
		tombol.disabled = true
	else:
		gambar.texture = load(String(GAMBAR[id]))
		nama.text = "Baju bawaan" if id == "" else tk_baju(id)
		if not _bisa_dipakai(id):

			gambar.modulate = Color(0.25, 0.25, 0.25, 0.9)
			tombol.text = "Hadiah tester"
			tombol.theme_type_variation = &"TombolKayu"
			tombol.disabled = true
		else:
			tombol.pressed.connect( func(): _pilih(id))
	_atur_gaya_kartu(kartu, tombol, id)
	return kartu


func tk_baju(id: String) -> String:
	return String(GameState.NAMA_BAJU.get(id, id))


func _atur_gaya_kartu(kartu: PanelContainer, tombol: Button, id: String) -> void :
	var dipakai: = id == GameState.baju_dipakai or (id == "" and not _bisa_dipakai(GameState.baju_dipakai))
	var gaya: = StyleBoxFlat.new()
	gaya.bg_color = KREM if not _rahasia(id) else Color("#d9cbb1")
	gaya.set_corner_radius_all(12)
	gaya.set_content_margin_all(10)
	gaya.border_color = EMAS if dipakai else Color("#b08a5c")
	gaya.set_border_width_all(5 if dipakai else 2)
	gaya.shadow_color = Color(0, 0, 0, 0.35)
	gaya.shadow_size = 6
	gaya.shadow_offset = Vector2(0, 3)
	kartu.add_theme_stylebox_override("panel", gaya)
	if _bisa_dipakai(id):
		tombol.text = "Dipakai" if dipakai else "Pakai"
		tombol.theme_type_variation = &"TombolHijau" if dipakai else &"TombolKayu"
		tombol.disabled = dipakai


func _pilih(id: String) -> void :
	if id == GameState.baju_dipakai:
		return
	GameState.klik()
	dipilih.emit(id)
	for k in _kartu:
		var kartu: PanelContainer = _kartu[k]
		var tombol: Button = kartu.get_child(0).get_child(2)
		_atur_gaya_kartu(kartu, tombol, String(k))
	_badan.queue_redraw()



func _gambar_lemari() -> void :
	var c: = _badan
	var w: = UKURAN.x
	var h: = UKURAN.y
	var x0: = LEBAR_PINTU
	var x1: = w - LEBAR_PINTU

	c.draw_rect(Rect2(x0 - 10, h - 22, x1 - x0 + 20, 18), Color(0, 0, 0, 0.35))

	for x in [x0 + 16, x1 - 46]:
		c.draw_rect(Rect2(x, h - 34, 30, 26), KAYU_GELAP)

	c.draw_rect(Rect2(x0, 40, x1 - x0, h - 74), KAYU)

	c.draw_rect(Rect2(x0 - 16, 0, x1 - x0 + 32, 56), KAYU_GELAP)
	c.draw_rect(Rect2(x0 - 10, 4, x1 - x0 + 20, 44), KAYU_TERANG)
	c.draw_rect(Rect2(w / 2 - 150, 8, 300, 36), Color("#e9c98f"))
	c.draw_rect(Rect2(w / 2 - 150, 8, 300, 36), KAYU_GELAP, false, 3.0)

	var dalam: = Rect2(x0 + 18, 70, x1 - x0 - 36, h - 190)
	c.draw_rect(dalam, DALAM)
	for i in 9:
		var gx: = dalam.position.x + 24 + i * (dalam.size.x - 48) / 8.0
		c.draw_line(Vector2(gx, dalam.position.y), Vector2(gx, dalam.end.y), Color(1, 1, 1, 0.03), 2.0)
	c.draw_rect(Rect2(dalam.position, Vector2(dalam.size.x, 16)), Color(0, 0, 0, 0.35))

	var laci: = Rect2(x0 + 18, dalam.end.y + 6, x1 - x0 - 36, h - 74 - dalam.end.y + 28)
	c.draw_rect(laci, KAYU_TERANG)
	c.draw_rect(laci, KAYU_GELAP, false, 3.0)

	var y_palang: = 100.0
	c.draw_line(Vector2(dalam.position.x + 6, y_palang), Vector2(dalam.end.x - 6, y_palang), Color(0, 0, 0, 0.4), 9.0)
	c.draw_line(Vector2(dalam.position.x + 6, y_palang - 2), Vector2(dalam.end.x - 6, y_palang - 2), BESI, 6.0)
	for x in [dalam.position.x + 4, dalam.end.x - 14]:
		c.draw_rect(Rect2(x, y_palang - 10, 10, 18), Color("#a59c8c"))

	for id in _kartu:
		var k: PanelContainer = _kartu[id]
		if not is_instance_valid(k) or k.size.x <= 0:
			continue
		var kiri: = k.get_global_rect().position - c.get_global_rect().position
		var tengah_x: = kiri.x + k.size.x / 2
		var y_kartu: = kiri.y + 4
		c.draw_arc(Vector2(tengah_x, y_palang + 2), 8, PI * 1.05, PI * 2.2, 10, BESI, 3.5, true)
		c.draw_line(Vector2(tengah_x, y_palang + 9), Vector2(tengah_x, y_palang + 16), BESI, 3.5, true)
		c.draw_polyline(PackedVector2Array([Vector2(kiri.x + 18, y_kartu), Vector2(tengah_x, y_palang + 16), Vector2(kiri.x + k.size.x - 18, y_kartu)]), Color("#c9a26b"), 4.0, true)

	for kiri_pintu in [true, false]:
		var a: = 0.0 if kiri_pintu else x1
		var b: = x0 if kiri_pintu else w
		var luar: = a if kiri_pintu else b
		var dalam_x: = b if kiri_pintu else a
		var pintu: = PackedVector2Array([Vector2(dalam_x, 40), Vector2(luar, 22), Vector2(luar, h - 40), Vector2(dalam_x, h - 34)])
		c.draw_colored_polygon(pintu, KAYU_TERANG)
		c.draw_polyline(pintu + PackedVector2Array([pintu[0]]), KAYU_GELAP, 3.0, true)

		var m: = 16.0
		var panel: = PackedVector2Array([
			Vector2(lerpf(dalam_x, luar, 0.18), 40 + (22 - 40) * 0.18 + m * 2), 
			Vector2(lerpf(dalam_x, luar, 0.82), 40 + (22 - 40) * 0.82 + m * 2), 
			Vector2(lerpf(dalam_x, luar, 0.82), h - 40 - m * 3), 
			Vector2(lerpf(dalam_x, luar, 0.18), h - 34 - m * 3)])
		c.draw_colored_polygon(panel, KAYU)
		c.draw_polyline(panel + PackedVector2Array([panel[0]]), KAYU_GELAP, 2.0, true)

		c.draw_circle(Vector2(lerpf(dalam_x, luar, 0.86), h / 2), 7, EMAS)
		c.draw_circle(Vector2(lerpf(dalam_x, luar, 0.86), h / 2), 7, KAYU_GELAP, false, 2.0)

	for x in [x0, x1]:
		for y in [120.0, h - 130.0]:
			c.draw_rect(Rect2(x - 4, y, 8, 22), Color("#b9b09d"))


func _process(_d: float) -> void :

	if _badan != null and get_meta("tergambar", false) == false and not _kartu.is_empty() and (_kartu.values()[0] as Control).size.x > 0:
		set_meta("tergambar", true)
		_badan.queue_redraw()
