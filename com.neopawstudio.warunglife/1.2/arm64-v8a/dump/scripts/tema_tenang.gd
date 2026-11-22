extends RefCounted







const GH: = preload("res://scripts/gaya_hud.gd")



const LATAR: = Color(0.03, 0.12, 0.26)
const KARTU: = Color(0.05, 0.19, 0.38)
const TEPI: = Color(0.2, 0.55, 0.92)
const TEKS: = Color(0.95, 0.97, 1.0)
const TEKS_REDUP: = Color(0.7, 0.79, 0.92)
const JUDUL: = Color(0.62, 0.86, 1.0)
const TOSKA: = Color(0.2, 0.55, 0.92)
const SLATE: = Color(0.1, 0.25, 0.46)
const HIJAU: = Color(0.04, 0.37, 0.69)
const MERAH: = Color(0.8, 0.33, 0.3)
const AKSEN: = Color(1.0, 0.78, 0.35)

static var _tema: Theme = null


static func kotak(warna: Color, radius: = 14, pinggir: = Vector4(16, 8, 16, 8), tepi: = 0, warna_tepi: = TEPI, bawah: = 0) -> StyleBoxFlat:
	var s: = StyleBoxFlat.new()
	s.bg_color = warna
	s.set_corner_radius_all(radius)
	s.content_margin_left = pinggir.x
	s.content_margin_top = pinggir.y
	s.content_margin_right = pinggir.z
	s.content_margin_bottom = pinggir.w + bawah
	if tepi > 0 or bawah > 0:
		s.border_color = warna_tepi
		s.border_width_left = tepi
		s.border_width_right = tepi
		s.border_width_top = tepi
		s.border_width_bottom = maxi(tepi, bawah)
	return s



static func _tombol(t: Theme, nama: String, warna: Color, teks: Color) -> void :
	t.set_type_variation(nama, "Button")
	var p: = Vector4(18, 8, 18, 8)
	t.set_stylebox("normal", nama, kotak(warna, 14, p, 0, warna.darkened(0.35), 4))
	t.set_stylebox("hover", nama, kotak(warna.lightened(0.07), 14, p, 0, warna.darkened(0.3), 4))
	t.set_stylebox("pressed", nama, kotak(warna.darkened(0.1), 14, Vector4(18, 10, 18, 6), 0, warna.darkened(0.4), 2))
	t.set_stylebox("hover_pressed", nama, t.get_stylebox("pressed", nama))
	t.set_stylebox("disabled", nama, kotak(Color(warna, 0.4), 14, p))
	t.set_stylebox("focus", nama, StyleBoxEmpty.new())
	t.set_font("font", nama, GH.font("Nunito", 800))
	for k in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color", "font_focus_color"]:
		t.set_color(k, nama, teks)
	t.set_color("font_disabled_color", nama, Color(teks, 0.5))
	t.set_constant("outline_size", nama, 0)


static func tema() -> Theme:
	if _tema != null:
		return _tema
	var t: = Theme.new()
	t.set_font("font", "Label", GH.font("Nunito", 700))
	t.set_color("font_color", "Label", TEKS)
	t.set_constant("outline_size", "Label", 0)
	t.set_color("font_shadow_color", "Label", Color(0, 0, 0, 0))
	for judul in ["LabelKepala", "LabelHud", "LabelJudul", "LabelSubjudul", "LabelUang"]:
		t.set_type_variation(judul, "Label")
		t.set_font("font", judul, GH.cetak())
		t.set_color("font_color", judul, JUDUL)
		t.set_constant("outline_size", judul, 0)
	t.set_type_variation("LabelRedup", "Label")
	t.set_color("font_color", "LabelRedup", TEKS_REDUP)
	_tombol(t, "TombolHijau", TOSKA, Color.WHITE)
	_tombol(t, "TombolKayu", SLATE, TEKS)
	_tombol(t, "TombolUtama", HIJAU, Color.WHITE)
	_tombol(t, "TombolMerah", MERAH, Color.WHITE)
	for k in ["normal", "hover", "pressed", "hover_pressed", "disabled", "focus"]:
		t.set_stylebox(k, "Button", t.get_stylebox(k, "TombolKayu"))
	for k in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color", "font_focus_color", "font_disabled_color"]:
		t.set_color(k, "Button", t.get_color(k, "TombolKayu"))
	t.set_font("font", "Button", GH.font("Nunito", 800))
	t.set_constant("outline_size", "Button", 0)

	t.set_stylebox("panel", "PanelContainer", kotak(LATAR, 20, Vector4(24, 18, 24, 20), 2, Color(0.12, 0.38, 0.72)))
	t.set_stylebox("panel", "Panel", kotak(LATAR, 20, Vector4(0, 0, 0, 0), 2))
	for kartu in ["KartuBagian", "KartuBarang", "PanelHud", "PanelKertas"]:
		t.set_type_variation(kartu, "PanelContainer")
		t.set_stylebox("panel", kartu, kotak(KARTU, 16, Vector4(16, 12, 16, 14), 2, TEPI, 5))

	var jalur: = StyleBoxFlat.new()
	jalur.bg_color = Color(1, 1, 1, 0.14)
	jalur.set_corner_radius_all(6)
	jalur.content_margin_top = 5
	jalur.content_margin_bottom = 5
	var isi_jalur: = jalur.duplicate()
	isi_jalur.bg_color = TOSKA.lightened(0.15)
	t.set_stylebox("slider", "HSlider", jalur)
	t.set_stylebox("grabber_area", "HSlider", isi_jalur)
	t.set_stylebox("grabber_area_highlight", "HSlider", isi_jalur)

	var ketik: = kotak(Color(0.06, 0.08, 0.12), 12, Vector4(14, 8, 14, 8), 1)
	var ketik_fokus: = kotak(Color(0.06, 0.08, 0.12), 12, Vector4(14, 8, 14, 8), 2, TOSKA)
	t.set_stylebox("normal", "LineEdit", ketik)
	t.set_stylebox("focus", "LineEdit", ketik_fokus)
	t.set_color("font_color", "LineEdit", TEKS)
	t.set_color("font_placeholder_color", "LineEdit", Color(TEKS, 0.4))
	t.set_color("caret_color", "LineEdit", AKSEN)
	t.set_font("font", "LineEdit", GH.font("Nunito", 800))
	_tema = t
	return t





const KARTU_EMAS: = Color(0.075, 0.08, 0.115)
const TEKS_REDUP_EMAS: = Color(0.86, 0.8, 0.66)
static var _tema_emas: Theme = null

static func tema_emas() -> Theme:
	if _tema_emas != null:
		return _tema_emas
	var t: Theme = tema().duplicate(true)
	var p: = Vector4(18, 8, 18, 8)
	for nama in ["TombolHijau", "TombolUtama"]:
		t.set_stylebox("normal", nama, GH.tombol_emas(p))
		t.set_stylebox("hover", nama, GH.tombol_emas(p))
		t.set_stylebox("pressed", nama, GH.tombol_emas(p, true))
		t.set_stylebox("hover_pressed", nama, GH.tombol_emas(p, true))
		for k in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color", "font_focus_color"]:
			t.set_color(k, nama, GH.TEKS_GELAP)
	for nama in ["TombolKayu", "Button"]:
		t.set_stylebox("normal", nama, GH.tombol_emas_gelap(p))
		t.set_stylebox("hover", nama, GH.tombol_emas_gelap(p))
		t.set_stylebox("pressed", nama, GH.tombol_emas_gelap(p, true))
		t.set_stylebox("hover_pressed", nama, GH.tombol_emas_gelap(p, true))
		for k in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color", "font_focus_color"]:
			t.set_color(k, nama, GH.EMAS_MUDA)
	for judul in ["LabelKepala", "LabelHud", "LabelJudul", "LabelSubjudul", "LabelUang"]:
		t.set_color("font_color", judul, GH.EMAS)
	t.set_color("font_color", "LabelRedup", TEKS_REDUP_EMAS)
	t.set_stylebox("panel", "PanelContainer", GH.bingkai_emas(Vector4(24, 18, 24, 20)))
	for kartu in ["KartuBagian", "KartuBarang", "PanelHud", "PanelKertas"]:
		t.set_stylebox("panel", kartu, kotak(KARTU_EMAS, 16, Vector4(16, 12, 16, 14), 2, Color(GH.EMAS, 0.6), 5))
	var isi_jalur: StyleBoxFlat = (t.get_stylebox("grabber_area", "HSlider") as StyleBoxFlat).duplicate()
	isi_jalur.bg_color = GH.EMAS
	t.set_stylebox("grabber_area", "HSlider", isi_jalur)
	t.set_stylebox("grabber_area_highlight", "HSlider", isi_jalur)
	t.set_stylebox("normal", "LineEdit", kotak(Color(0.06, 0.08, 0.12), 12, Vector4(14, 8, 14, 8), 1, Color(GH.EMAS, 0.55)))
	t.set_stylebox("focus", "LineEdit", kotak(Color(0.06, 0.08, 0.12), 12, Vector4(14, 8, 14, 8), 2, GH.EMAS))
	_tema_emas = t
	return t



static func bagian(judul: String, ikon: = "") -> Array:
	var kartu: = PanelContainer.new()
	kartu.theme_type_variation = &"KartuBagian"
	var v: = VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	kartu.add_child(v)
	var l: = Label.new()
	l.text = (ikon + "  " if ikon != "" else "") + judul.to_upper()
	l.theme_type_variation = &"LabelKepala"
	l.add_theme_font_size_override("font_size", 22)
	v.add_child(l)
	return [kartu, v]
