extends RefCounted






const GH: = preload("res://scripts/gaya_hud.gd")
const WARNA_TEKS: = Color(1, 1, 1)
const WARNA_REDUP: = Color(1, 1, 1, 0.6)
const WARNA_LAYAR: = Color(0.09, 0.08, 0.07)
const WARNA_GAGAL: = Color(1, 0.5, 0.45)
const WARNA_BERHASIL: = Color(0.5, 0.85, 0.5)



static func _gelapkan(w: Color) -> Color:
	if w.a > 0.5 and w.get_luminance() > 0.7:
		return Color(1, 1, 1, 0.1 if w.s > 0.06 else 0.07)
	return w



static func _terangkan(w: Color) -> Color:
	if w.get_luminance() >= 0.45:
		return w
	if w.s < 0.35:
		return Color(1, 1, 1, w.a)
	return w.lightened(0.45)


static func label(teks: String, ukuran: int, warna: Color = WARNA_TEKS, bungkus: = false) -> Label:
	var l: = Label.new()
	l.text = teks
	l.add_theme_font_override("font", GH.font("Nunito", 800))
	l.add_theme_font_size_override("font_size", ukuran)
	l.add_theme_color_override("font_color", _terangkan(warna))
	if bungkus:
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size.x = 40
	return l


static func kotak(warna: Color, sudut: = 12, tepi: = 10) -> StyleBoxFlat:
	var s: = StyleBoxFlat.new()
	s.bg_color = _gelapkan(warna)
	s.set_corner_radius_all(sudut)
	s.set_content_margin_all(tepi)
	return s


static func panel(warna: Color, sudut: = 12, tepi: = 10) -> PanelContainer:
	var p: = PanelContainer.new()

	p.mouse_filter = Control.MOUSE_FILTER_PASS
	p.add_theme_stylebox_override("panel", kotak(warna, sudut, tepi))
	return p



static func tombol(teks: String, warna: Color, ukuran: = 18, tinggi: = 42) -> Button:


	var aksen: = warna.a > 0.5 and warna.s > 0.25 and warna.get_luminance() < 0.8
	if aksen:
		warna = GH.KUNING
	var t: = Button.new()
	t.mouse_filter = Control.MOUSE_FILTER_PASS
	t.text = teks
	t.custom_minimum_size = Vector2(0, tinggi)
	t.add_theme_font_size_override("font_size", ukuran)
	t.add_theme_font_override("font", GH.font("Nunito", 800))
	var warna_teks: = GH.TEKS_GELAP if aksen else Color.WHITE
	t.add_theme_color_override("font_color", warna_teks)
	t.add_theme_color_override("font_hover_color", warna_teks)
	t.add_theme_color_override("font_pressed_color", warna_teks)
	t.add_theme_color_override("font_disabled_color", Color(1, 1, 1, 0.7))
	t.add_theme_constant_override("outline_size", 0)
	for keadaan in ["normal", "hover", "pressed", "disabled", "focus"]:
		var w: = warna
		match keadaan:
			"hover": w = warna.lightened(0.08)
			"pressed": w = warna.darkened(0.15)
			"disabled": w = Color(0.72, 0.7, 0.67)
		var s: = kotak(w, 10, 6)
		if aksen and keadaan != "disabled":
			s.bg_color = w
		if keadaan == "focus":
			s.draw_center = false
		t.add_theme_stylebox_override(keadaan, s)
	return t



static func kepala(judul: String, warna: Color, aksi_kembali: Callable = Callable()) -> PanelContainer:

	var p: = panel(Color(0.06, 0.05, 0.05), 0, 12)
	var gaya: = p.get_theme_stylebox("panel") as StyleBoxFlat
	gaya.border_color = warna
	gaya.border_width_bottom = 3
	var baris: = HBoxContainer.new()
	baris.add_theme_constant_override("separation", 8)
	p.add_child(baris)
	if aksi_kembali.is_valid():
		var k: = tombol("‹", Color(1, 1, 1, 0.12), 26, 36)
		k.custom_minimum_size.x = 40
		k.pressed.connect(aksi_kembali)
		baris.add_child(k)
	var l: = label(judul.to_upper(), 30, Color.WHITE)
	l.add_theme_font_override("font", GH.cetak())
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	baris.add_child(l)
	return p


static func ikon(tekstur: Texture2D, ukuran: float) -> TextureRect:
	var r: = TextureRect.new()
	r.texture = tekstur
	r.custom_minimum_size = Vector2(ukuran, ukuran)
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r



static func gulir(jarak: = 8) -> Array:
	var g: ScrollContainer = load("res://scripts/hp/gulir_sentuh.gd").new()
	g.scroll_deadzone = 8
	g.size_flags_vertical = Control.SIZE_EXPAND_FILL
	g.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var isi: = VBoxContainer.new()
	isi.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	isi.add_theme_constant_override("separation", jarak)
	g.add_child(isi)
	return [g, isi]



static func lencana() -> PanelContainer:
	var p: = panel(Color(0.88, 0.18, 0.15), 11, 2)
	p.custom_minimum_size = Vector2(22, 22)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var l: = label("", 13, Color.WHITE)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.name = "Angka"
	p.add_child(l)
	return p


static func atur_lencana(p: PanelContainer, jumlah: int) -> void :
	p.visible = jumlah > 0
	(p.get_node("Angka") as Label).text = str(jumlah) if jumlah < 10 else "9+"
