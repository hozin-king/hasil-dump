extends RefCounted









const KUNING: = Color(1.0, 0.8, 0.42)
const HIJAU_UANG: = Color(0.66, 0.9, 0.48)
const BIRU_NAMA: = Color(0.64, 0.87, 0.96)
const MERAH: = Color(0.86, 0.38, 0.32)
const TEKS_GELAP: = Color(0.29, 0.2, 0.15)
const KREM: = Color(1.0, 0.965, 0.9)
const GARIS: = Color(0.2, 0.12, 0.07)
const TEPI_KREM: = Color(1.0, 0.92, 0.78)


const UKURAN_JAM_HUD: = 66
const UKURAN_TANGGAL_HUD: = 25
const UKURAN_JUDUL_HUD: = 20
const UKURAN_BINTANG_HUD: = 30
const UKURAN_ENERGI_HUD: = 22
const LEBAR_BAR_ENERGI: = 190.0


const TEPI_SAMPING: = 30.0
const TEPI_ATAS: = 14.0
const TEPI_BAWAH: = 14.0

static var _fn: = {}



static func tepi_kiri_kanan(vp: Viewport) -> Vector2:
	var kiri: = TEPI_SAMPING
	var kanan: = TEPI_SAMPING
	if DisplayServer.get_name() != "headless":
		var aman: = DisplayServer.get_display_safe_area()
		var layar: = DisplayServer.screen_get_size()
		var skala: = vp.get_visible_rect().size.x / maxf(float(layar.x), 1.0)

		if aman.size.x > 0 and layar.x > 0:
			kiri = maxf(kiri, maxf(aman.position.x, 0) * skala + 10.0)
			kanan = maxf(kanan, maxf(layar.x - aman.end.x, 0) * skala + 10.0)
	return Vector2(kiri, kanan)





static func jaga_tepi(akar: Control, kecuali: Array = []) -> void :
	var t: = tepi_kiri_kanan(akar.get_viewport())
	for c in akar.get_children():
		if not c is Control or c in kecuali or c.has_meta("tepi_dijaga"):
			continue
		var k: = c as Control
		k.set_meta("tepi_dijaga", true)
		var geser: = Vector2.ZERO
		if k.anchor_left == 0.0 and k.anchor_right == 0.0:
			geser.x = t.x - 16.0
		elif k.anchor_left == 1.0 and k.anchor_right == 1.0:
			geser.x = - (t.y - 16.0)
		if k.anchor_top == 0.0 and k.anchor_bottom == 0.0 and k.offset_top < 120.0:
			geser.y = TEPI_ATAS - 6.0
		elif k.anchor_top == 1.0 and k.anchor_bottom == 1.0:
			geser.y = - (TEPI_BAWAH - 6.0)
		k.offset_left += geser.x
		k.offset_right += geser.x
		k.offset_top += geser.y
		k.offset_bottom += geser.y


static func font(berkas: String, tebal: = 800, lebar: = 100) -> FontVariation:
	var kunci: = "%s%d_%d" % [berkas, tebal, lebar]
	if not _fn.has(kunci):
		var f: = FontVariation.new()
		f.base_font = load("res://assets/font/%s.ttf" % berkas)
		if berkas != "BebasNeue":
			var ts: = TextServerManager.get_primary_interface()
			var v: = {ts.name_to_tag("wght"): tebal}
			if lebar != 100:
				v[ts.name_to_tag("wdth")] = lebar
			f.variation_opentype = v
		_fn[kunci] = f
	return _fn[kunci]




const SKALA_CETAK: = 0.86

static func cetak() -> FontVariation:
	return font("Fredoka", 600, 75)


static func ukuran_cetak(ukuran: int) -> int:
	return maxi(int(round(ukuran * SKALA_CETAK)), 10)



static func hangat(c: Color) -> Color:
	if c.r > 0.97 and c.g > 0.97 and c.b > 0.97:
		return Color(KREM, c.a)
	return c



static func label(teks: String, ukuran: int, warna: = Color.WHITE, besar: = false, garis: = 3) -> Label:
	var l: = Label.new()
	l.text = teks
	gaya_label(l, ukuran, warna, besar, garis)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return l


static func gaya_label(l: Label, ukuran: int, warna: = Color.WHITE, besar: = false, garis: = 3) -> void :
	l.theme_type_variation = &""
	l.add_theme_font_override("font", cetak() if besar else font("Nunito", 800))
	l.add_theme_font_size_override("font_size", ukuran_cetak(ukuran) if besar else ukuran)
	l.add_theme_color_override("font_color", hangat(warna))
	l.add_theme_color_override("font_outline_color", Color(GARIS, 0.85))
	l.add_theme_constant_override("outline_size", garis)
	l.add_theme_color_override("font_shadow_color", Color(GARIS, 0.45 if garis > 0 else 0.0))
	l.add_theme_constant_override("shadow_offset_x", 0)
	l.add_theme_constant_override("shadow_offset_y", 2)



static func tebal(l: Label) -> Label:
	l.add_theme_constant_override("outline_size", 7)
	l.add_theme_color_override("font_outline_color", Color(GARIS, 0.9))
	l.add_theme_color_override("font_shadow_color", Color(GARIS, 0.55))
	l.add_theme_constant_override("shadow_offset_x", 0)
	l.add_theme_constant_override("shadow_offset_y", 3)
	return l


static func kotak(warna: Color, radius: = 10, pinggir: = Vector4(12, 8, 12, 8)) -> StyleBoxFlat:
	var s: = StyleBoxFlat.new()
	s.bg_color = warna
	s.set_corner_radius_all(radius)
	s.content_margin_left = pinggir.x
	s.content_margin_top = pinggir.y
	s.content_margin_right = pinggir.z
	s.content_margin_bottom = pinggir.w
	s.anti_aliasing = true
	return s




static func kotak_lencana(dasar: Color, pinggir: = Vector4(18, 8, 18, 8), tekan: = false) -> StyleBoxFlat:
	var s: = kotak(dasar, 18, pinggir)
	s.set_border_width_all(3)
	s.border_color = Color(1.0, 0.95, 0.82)
	s.shadow_color = Color(0.55, 0.33, 0.16)
	s.shadow_size = 1
	s.shadow_offset = Vector2(0, 3 if tekan else 10)
	if tekan:
		s.content_margin_top += 4.0
		s.content_margin_bottom = maxf(s.content_margin_bottom - 4.0, 0.0)
	return s






static func kunci_lebar_jam(kolom: Control, jam: Label, tanggal: Label) -> void :
	var f: Font = jam.get_theme_font("font")
	var u: int = jam.get_theme_font_size("font_size")
	var digit: = 0.0
	for d in "0123456789":
		digit = maxf(digit, f.get_string_size(d, HORIZONTAL_ALIGNMENT_LEFT, -1, u).x)
	var lebar: = digit * 4.0 + f.get_string_size(".", HORIZONTAL_ALIGNMENT_LEFT, -1, u).x
	var ft: Font = tanggal.get_theme_font("font")
	var ut: int = tanggal.get_theme_font_size("font_size")
	var digit_t: = 0.0
	for d in "0123456789":
		digit_t = maxf(digit_t, ft.get_string_size(d, HORIZONTAL_ALIGNMENT_LEFT, -1, ut).x)
	var hari: Array = GameState.NAMA_HARI + ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
	var bulan: Array = GameState.NAMA_BULAN + ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
	var lebar_bulan: = 0.0
	for b in bulan:
		lebar_bulan = maxf(lebar_bulan, ft.get_string_size(String(b).left(3).to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, ut).x)
	for h in hari:
		var w: = ft.get_string_size(TranslationServer.translate(String(h)).to_upper() + ",  ", HORIZONTAL_ALIGNMENT_LEFT, -1, ut).x
		lebar = maxf(lebar, w + digit_t * 2.0 + lebar_bulan)
	kolom.custom_minimum_size.x = ceilf(lebar + 6.0)
	jam.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	tanggal.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT




static func tanpa_lebar(l: Label) -> Control:
	var wadah: = Control.new()
	wadah.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wadah.add_child(l)
	var atur: = func():
		var m: = l.get_combined_minimum_size()
		wadah.custom_minimum_size = Vector2(0, m.y)
		l.position = Vector2.ZERO
		l.size = m
	l.minimum_size_changed.connect(atur)
	atur.call_deferred()
	return wadah


static func latar_kolom(kolom: Control, alpha: = 0.4) -> Panel:
	var p: = Panel.new()
	p.add_theme_stylebox_override("panel", kaca(alpha, 14, Vector4(0, 0, 0, 0)))
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var induk: = kolom.get_parent()
	induk.add_child(p)
	induk.move_child(p, kolom.get_index())
	var atur: = func():
		p.position = kolom.position - Vector2(12, 2)
		p.size = kolom.size + Vector2(28, 8)
		p.visible = kolom.visible
	kolom.resized.connect(atur)
	kolom.item_rect_changed.connect(atur)
	kolom.visibility_changed.connect(atur)
	atur.call_deferred()
	return p




const KUNING_NOTIF: = Color(1.0, 0.8, 0.2)

static func kartu_notif(alpha: = 0.8, pinggir: = Vector4(24, 12, 22, 13)) -> StyleBoxFlat:
	var s: = kotak(Color(0.05, 0.045, 0.04, alpha), 12, pinggir)
	s.border_color = KUNING_NOTIF
	s.border_width_left = 6

	s.corner_radius_top_left = 5
	s.corner_radius_bottom_left = 5
	s.corner_radius_top_right = 16
	s.corner_radius_bottom_right = 16
	s.shadow_color = Color(0, 0, 0, 0.35)
	s.shadow_size = 8
	s.shadow_offset = Vector2(0, 3)
	return s



static func pop_masuk(c: Control, dari: = 0.55, lama: = 0.32) -> Tween:
	c.pivot_offset = c.size / 2.0
	c.scale = Vector2(dari, dari)
	c.modulate.a = 0.0
	var tw: = c.create_tween().set_parallel(true)
	tw.tween_property(c, "scale", Vector2.ONE, lama).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(c, "modulate:a", 1.0, lama * 0.6)
	return tw




const HITAM: = Color(0, 0, 0)

static func kaca(alpha: = 0.6, radius: = 8, pinggir: = Vector4(12, 8, 14, 8)) -> StyleBoxFlat:
	return kotak(Color(HITAM, alpha), maxi(radius + 4, 12), pinggir)


static func panel_kaca(alpha: = 0.6, radius: = 8, pinggir: = Vector4(12, 8, 14, 8)) -> PanelContainer:
	var p: = PanelContainer.new()
	p.add_theme_stylebox_override("panel", kaca(alpha, radius, pinggir))
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return p



static func gaya_tombol(b: Button, utama: = false, ukuran: = 24) -> void :
	b.focus_mode = Control.FOCUS_NONE
	ukuran = ukuran_cetak(ukuran)
	var dasar: = KUNING if utama else Color(HITAM, 0.62)
	if utama:
		var pinggir: = Vector4(18, 6, 18, 6)
		b.add_theme_stylebox_override("normal", kotak_lencana(dasar, pinggir))
		b.add_theme_stylebox_override("hover", kotak_lencana(dasar.lightened(0.08), pinggir))
		var tekan_lencana: = kotak_lencana(dasar.darkened(0.08), pinggir, true)
		b.add_theme_stylebox_override("pressed", tekan_lencana)
		b.add_theme_stylebox_override("hover_pressed", tekan_lencana)
		b.add_theme_stylebox_override("disabled", kotak(Color(0.3, 0.3, 0.3, 0.6), 10, pinggir))
		b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		b.add_theme_font_override("font", cetak())
		b.add_theme_font_size_override("font_size", ukuran)
		for k in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color", "font_focus_color"]:
			b.add_theme_color_override(k, TEKS_GELAP)
		b.add_theme_color_override("font_disabled_color", Color(1, 1, 1, 0.6))
		b.add_theme_constant_override("outline_size", 0)
		return
	b.add_theme_stylebox_override("normal", kaca(0.62, 10, Vector4(18, 6, 18, 6)))
	b.add_theme_stylebox_override("hover", kaca(0.7, 10, Vector4(18, 6, 18, 6)))
	var tekan: = kaca(0.82, 10, Vector4(18, 8, 18, 4))
	b.add_theme_stylebox_override("pressed", tekan)
	b.add_theme_stylebox_override("hover_pressed", tekan)
	b.add_theme_stylebox_override("disabled", kotak(Color(0.3, 0.3, 0.3, 0.6), 10, Vector4(18, 6, 18, 6)))
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	b.add_theme_font_override("font", cetak())
	b.add_theme_font_size_override("font_size", ukuran)
	var warna: = TEKS_GELAP if utama else KREM
	for k in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color", "font_focus_color"]:
		b.add_theme_color_override(k, warna)
	b.add_theme_color_override("font_disabled_color", Color(KREM, 0.6))
	b.add_theme_constant_override("outline_size", 0)




static func tombol_ikon(ikon: String, teks: String, ukuran: = 96.0, warna_teks: = Color.WHITE, jarak_teks: = -10.0) -> Button:
	var b: = Button.new()
	b.flat = true
	b.focus_mode = Control.FOCUS_NONE
	for k in ["normal", "hover", "pressed", "hover_pressed", "focus", "disabled"]:
		b.add_theme_stylebox_override(k, StyleBoxEmpty.new())
	var lebar: = maxf(ukuran + 14.0, 92.0)
	b.custom_minimum_size = Vector2(lebar, ukuran + 18.0 + maxf(jarak_teks + 10.0, 0.0))
	b.size = b.custom_minimum_size
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var g: = TextureRect.new()
	g.texture = load(ikon)
	g.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	g.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	g.mouse_filter = Control.MOUSE_FILTER_IGNORE
	g.position = Vector2((lebar - ukuran) / 2.0, 0)
	g.size = Vector2(ukuran, ukuran)
	g.name = "Ikon"
	b.add_child(g)
	var l: = tebal(label(teks, 20, warna_teks, true))
	l.add_theme_constant_override("outline_size", 5)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.position = Vector2(-30, ukuran + jarak_teks)
	l.size = Vector2(lebar + 60.0, 28)
	l.name = "Label"
	b.add_child(l)
	return b




static var _tema_jendela: Theme = null

static func tema_jendela() -> Theme:
	if _tema_jendela != null:
		return _tema_jendela
	var t: = Theme.new()
	t.set_font("font", "Label", font("Nunito", 800))
	t.set_color("font_color", "Label", KUNING)
	t.set_color("font_outline_color", "Label", Color(GARIS, 0.85))
	t.set_constant("outline_size", "Label", 4)
	for varian in [["TombolHijau", true], ["TombolKayu", false]]:
		var nama: String = varian[0]
		var utama: bool = varian[1]
		t.set_type_variation(nama, "Button")
		var dasar: = KUNING if utama else Color(1, 1, 1, 0.14)
		var pinggir: = Vector4(18, 8, 18, 8)
		if utama:
			t.set_stylebox("normal", nama, kotak_lencana(dasar, pinggir))
			t.set_stylebox("hover", nama, kotak_lencana(dasar.lightened(0.08), pinggir))
			t.set_stylebox("pressed", nama, kotak_lencana(dasar.darkened(0.08), pinggir, true))
			t.set_stylebox("hover_pressed", nama, kotak_lencana(dasar.darkened(0.08), pinggir, true))
		else:
			t.set_stylebox("normal", nama, kotak(dasar, 16, pinggir))
			t.set_stylebox("hover", nama, kotak(dasar.lightened(0.1), 16, pinggir))
			t.set_stylebox("pressed", nama, kotak(dasar.darkened(0.12), 16, pinggir))
			t.set_stylebox("hover_pressed", nama, kotak(dasar.darkened(0.12), 16, pinggir))
		t.set_stylebox("disabled", nama, kotak(Color(1, 1, 1, 0.08), 16, Vector4(18, 8, 18, 8)))
		t.set_stylebox("focus", nama, StyleBoxEmpty.new())
		t.set_font("font", nama, font("Nunito", 800))
		var teks: = TEKS_GELAP if utama else KREM
		for k in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color", "font_focus_color"]:
			t.set_color(k, nama, teks)
		t.set_color("font_disabled_color", nama, Color(KREM, 0.45))
		t.set_constant("outline_size", nama, 0)


	t.set_stylebox("panel", "PanelContainer", kaca(0.94, 16, Vector4(24, 18, 24, 20)))
	t.set_stylebox("panel", "Panel", kaca(0.94, 16, Vector4(0, 0, 0, 0)))
	for panel_tipe in ["KartuBarang", "PanelHud", "PanelKertas"]:
		t.set_type_variation(panel_tipe, "PanelContainer")
		t.set_stylebox("panel", panel_tipe, kaca(0.5 if panel_tipe == "KartuBarang" else 0.94, 12, Vector4(14, 10, 14, 12)))
	for judul_tipe in ["LabelKepala", "LabelHud", "LabelJudul", "LabelSubjudul", "LabelUang"]:
		t.set_type_variation(judul_tipe, "Label")
		t.set_font("font", judul_tipe, cetak())
		t.set_color("font_color", judul_tipe, KUNING)
		t.set_constant("outline_size", judul_tipe, 5)
		t.set_color("font_outline_color", judul_tipe, Color(GARIS, 0.85))
	for k in ["normal", "hover", "pressed", "hover_pressed", "disabled", "focus"]:
		var sb: StyleBox = t.get_stylebox(k, "TombolKayu")
		t.set_stylebox(k, "Button", sb)
		t.set_stylebox(k, "TombolDatar", sb)
	for k in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color", "font_focus_color", "font_disabled_color"]:
		t.set_color(k, "Button", t.get_color(k, "TombolKayu"))
	t.set_font("font", "Button", font("Nunito", 800))
	t.set_constant("outline_size", "Button", 0)
	t.set_type_variation("TombolMerah", "Button")
	t.set_stylebox("normal", "TombolMerah", kotak(MERAH, 12, Vector4(18, 8, 18, 8)))
	t.set_stylebox("hover", "TombolMerah", kotak(MERAH.lightened(0.1), 12, Vector4(18, 8, 18, 8)))
	t.set_stylebox("pressed", "TombolMerah", kotak(MERAH.darkened(0.12), 12, Vector4(18, 8, 18, 8)))
	for k in ["font_color", "font_hover_color", "font_pressed_color"]:
		t.set_color(k, "TombolMerah", KREM)
	var jalur: = StyleBoxFlat.new()
	jalur.bg_color = Color(1, 1, 1, 0.22)
	jalur.set_corner_radius_all(6)
	jalur.content_margin_top = 6
	jalur.content_margin_bottom = 6
	var isi_jalur: = StyleBoxFlat.new()
	isi_jalur.bg_color = KUNING
	isi_jalur.set_corner_radius_all(6)
	isi_jalur.content_margin_top = 6
	isi_jalur.content_margin_bottom = 6
	t.set_stylebox("slider", "HSlider", jalur)
	t.set_stylebox("grabber_area", "HSlider", isi_jalur)
	t.set_stylebox("grabber_area_highlight", "HSlider", isi_jalur)
	var ketik: = kotak(Color(1, 1, 1, 0.12), 14, Vector4(14, 8, 14, 8))
	t.set_stylebox("normal", "LineEdit", ketik)
	t.set_stylebox("focus", "LineEdit", ketik)
	t.set_color("font_color", "LineEdit", KREM)
	t.set_color("font_placeholder_color", "LineEdit", Color(KREM, 0.45))
	t.set_color("caret_color", "LineEdit", KUNING)
	t.set_font("font", "LineEdit", font("Nunito", 800))
	_tema_jendela = t
	return t


static func gaya_jendela(panel: PanelContainer, judul: Label = null) -> void :
	panel.add_theme_stylebox_override("panel", bingkai_emas(Vector4(32, 22, 32, 28)))
	panel.theme = tema_jendela_emas()
	pasang_muncul(panel)
	if judul != null:
		pita_emas(judul)




const EMAS: = Color(1.0, 0.77, 0.26)
const EMAS_MUDA: = Color(1.0, 0.93, 0.66)
const EMAS_TUA: = Color(0.66, 0.33, 0.04)
const MALAM: = Color(0.035, 0.04, 0.07)


static func bingkai_emas(pinggir: = Vector4(32, 22, 32, 28)) -> StyleBoxFlat:
	var s: = kotak(Color(MALAM, 0.96), 20, pinggir)
	s.border_color = EMAS
	s.set_border_width_all(4)
	s.shadow_color = Color(1.0, 0.72, 0.2, 0.3)
	s.shadow_size = 26
	return s



static func tombol_emas(pinggir: = Vector4(18, 8, 18, 8), tekan: = false) -> StyleBoxFlat:
	var s: = kotak(EMAS, 20, pinggir)
	s.set_border_width_all(3)
	s.border_color = EMAS_MUDA
	s.shadow_color = EMAS_TUA
	s.shadow_size = 1
	s.shadow_offset = Vector2(0, 3 if tekan else 9)
	if tekan:
		s.content_margin_top += 4.0
		s.content_margin_bottom = maxf(s.content_margin_bottom - 4.0, 0.0)
	return s



static func tombol_emas_gelap(pinggir: = Vector4(18, 8, 18, 8), tekan: = false) -> StyleBoxFlat:
	var s: = kotak(Color(0.09, 0.1, 0.15), 18, pinggir)
	s.border_color = EMAS
	s.set_border_width_all(2)
	s.shadow_color = Color(0.3, 0.19, 0.04)
	s.shadow_size = 1
	s.shadow_offset = Vector2(0, 2 if tekan else 6)
	if tekan:
		s.content_margin_top += 3.0
		s.content_margin_bottom = maxf(s.content_margin_bottom - 3.0, 0.0)
	return s



static func pita_emas(judul: Label, ukuran: = 36) -> void :
	gaya_label(judul, ukuran, TEKS_GELAP, true, 0)
	judul.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	judul.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	judul.add_theme_stylebox_override("normal", tombol_emas(Vector4(34, 4, 34, 6)))




static func gaya_tombol_emas(b: Button, utama: = false, ukuran: = 24) -> void :
	gaya_tombol(b, utama, ukuran)
	var p: = Vector4(18, 6, 18, 6)
	b.add_theme_stylebox_override("normal", tombol_emas(p) if utama else tombol_emas_gelap(p))
	b.add_theme_stylebox_override("hover", tombol_emas(p) if utama else tombol_emas_gelap(p))
	b.add_theme_stylebox_override("pressed", tombol_emas(p, true) if utama else tombol_emas_gelap(p, true))
	b.add_theme_stylebox_override("hover_pressed", tombol_emas(p, true) if utama else tombol_emas_gelap(p, true))
	for k in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color", "font_focus_color"]:
		b.add_theme_color_override(k, TEKS_GELAP if utama else EMAS_MUDA)



static func pasang_emas(akar: Control, kartu: PanelContainer = null) -> void :
	akar.theme = tema_jendela_emas()
	if kartu == null and akar is PanelContainer:
		kartu = akar
	if kartu != null:
		var lama: StyleBox = kartu.get_theme_stylebox("panel")
		var p: = Vector4(32, 22, 32, 28)
		if lama != null:
			p = Vector4(maxf(lama.content_margin_left, 24), maxf(lama.content_margin_top, 18), maxf(lama.content_margin_right, 24), maxf(lama.content_margin_bottom, 20))
		kartu.add_theme_stylebox_override("panel", bingkai_emas(p))



static func panel_emas(pinggir: = Vector4(32, 22, 32, 28)) -> PanelContainer:
	var p: = PanelContainer.new()
	p.add_theme_stylebox_override("panel", bingkai_emas(pinggir))
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return p


static var _tema_emas: Theme = null

static func tema_jendela_emas() -> Theme:
	if _tema_emas != null:
		return _tema_emas
	var t: Theme = tema_jendela().duplicate(true)
	var pinggir: = Vector4(18, 8, 18, 8)
	t.set_stylebox("normal", "TombolHijau", tombol_emas(pinggir))
	t.set_stylebox("hover", "TombolHijau", tombol_emas(pinggir))
	t.set_stylebox("pressed", "TombolHijau", tombol_emas(pinggir, true))
	t.set_stylebox("hover_pressed", "TombolHijau", tombol_emas(pinggir, true))
	for nama in ["TombolKayu", "Button", "TombolDatar"]:
		t.set_stylebox("normal", nama, tombol_emas_gelap(pinggir))
		t.set_stylebox("hover", nama, tombol_emas_gelap(pinggir))
		t.set_stylebox("pressed", nama, tombol_emas_gelap(pinggir, true))
		t.set_stylebox("hover_pressed", nama, tombol_emas_gelap(pinggir, true))
		for k in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color", "font_focus_color"]:
			t.set_color(k, nama, EMAS_MUDA)
	_tema_emas = t
	return t




static func pasang_muncul(panel: Control, dari_skala: = 0.92, lama: = 0.26) -> void :
	if panel.has_meta("muncul_lembut"):
		return
	panel.set_meta("muncul_lembut", true)
	var mainkan: = func() -> void :
		if not is_instance_valid(panel) or not panel.is_visible_in_tree():
			return
		var lalu: Variant = panel.get_meta("_tw_muncul") if panel.has_meta("_tw_muncul") else null
		if lalu is Tween and (lalu as Tween).is_valid():
			(lalu as Tween).kill()
		panel.pivot_offset = panel.size / 2.0
		panel.scale = Vector2.ONE * dari_skala
		panel.modulate.a = 0.0
		var tw: = panel.create_tween().set_parallel(true)
		tw.tween_property(panel, "scale", Vector2.ONE, lama).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(panel, "modulate:a", 1.0, lama * 0.7).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		panel.set_meta("_tw_muncul", tw)
	panel.visibility_changed.connect( func() -> void :
		if panel.visible:
			mainkan.call_deferred())
	if panel.visible:
		mainkan.call_deferred()




static func hitung_uang(l: Label, nilai: int, format: Callable, lama: = 0.6) -> void :
	if not l.has_meta("uang_tampil") or not l.is_visible_in_tree():
		l.set_meta("uang_tampil", nilai)
		l.text = format.call(nilai)
		return
	var awal: = int(l.get_meta("uang_tampil"))
	if awal == nilai:
		l.text = format.call(nilai)
		return
	var lalu: Variant = l.get_meta("_tw_uang") if l.has_meta("_tw_uang") else null
	if lalu is Tween and (lalu as Tween).is_valid():
		(lalu as Tween).kill()
	l.set_meta("uang_tampil", nilai)
	var tw: = l.create_tween()
	tw.tween_method( func(v: float) -> void : l.text = format.call(int(round(v))), float(awal), float(nilai), lama)\
	.set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	if nilai > awal:
		l.pivot_offset = l.size / 2.0
		var tw2: = l.create_tween()
		tw2.tween_property(l, "scale", Vector2.ONE * 1.08, 0.12).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tw2.tween_property(l, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	l.set_meta("_tw_uang", tw)




static func pesan_kotak(akar: Control, teks: String, lama: = 5.0) -> void :
	for lama_kotak in akar.get_children():
		if lama_kotak.has_meta("pesan_kotak"):
			lama_kotak.queue_free()
	var kotak: = PanelContainer.new()
	kotak.set_meta("pesan_kotak", true)
	kotak.add_theme_stylebox_override("panel", kaca(0.62, 14, Vector4(26, 14, 26, 16)))
	kotak.mouse_filter = Control.MOUSE_FILTER_IGNORE
	kotak.z_index = 6
	var l: = label(teks, 23, KUNING, false, 4)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.custom_minimum_size.x = 600
	kotak.add_child(l)
	akar.add_child(kotak)
	kotak.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM, Control.PRESET_MODE_MINSIZE)
	kotak.grow_vertical = Control.GROW_DIRECTION_BEGIN
	kotak.grow_horizontal = Control.GROW_DIRECTION_BOTH
	kotak.offset_bottom = -34.0
	kotak.modulate.a = 0.0

	var naik: = 22.0
	kotak.offset_top += naik
	kotak.offset_bottom += naik
	var tw: = kotak.create_tween()
	tw.set_parallel(true)
	tw.tween_property(kotak, "modulate:a", 1.0, 0.35).set_trans(Tween.TRANS_SINE)
	tw.tween_property(kotak, "offset_top", kotak.offset_top - naik, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(kotak, "offset_bottom", kotak.offset_bottom - naik, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.chain().tween_interval(lama)
	tw.chain().tween_property(kotak, "modulate:a", 0.0, 0.6).set_trans(Tween.TRANS_SINE)
	tw.chain().tween_callback(kotak.queue_free)




static func letak_lencana_hp(tombol: Control) -> Vector2:
	var ikon: = tombol.get_node("Ikon") as Control
	return Vector2(ikon.position.x + ikon.size.x * 0.73 - 16.0, ikon.position.y + ikon.size.y * 0.02 - 6.0)



static func gaya_lencana(p: PanelContainer) -> void :
	var s: = kotak(MERAH, 13, Vector4(5, 0, 5, 0))
	s.border_color = KREM
	s.set_border_width_all(2)
	p.add_theme_stylebox_override("panel", s)
	p.custom_minimum_size = Vector2(26, 26)
	var l: = p.get_node_or_null("Angka") as Label
	if l != null:
		gaya_label(l, 15, KREM, false, 0)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER



static func gambar_bar(c: Control, isi: float, warna: Color) -> void :

	var r: = int(c.size.y / 2.0)
	var jalur: = kotak(Color(0, 0, 0, 0.5), r, Vector4.ZERO)
	c.draw_style_box(jalur, Rect2(Vector2.ZERO, c.size))
	if isi > 0.0:
		var lebar: = maxf(c.size.x * clampf(isi, 0.0, 1.0), c.size.y)
		c.draw_style_box(kotak(warna, r, Vector4.ZERO), Rect2(Vector2.ZERO, Vector2(lebar, c.size.y)))
		c.draw_style_box(kotak(Color(1, 1, 1, 0.2), r, Vector4.ZERO), Rect2(Vector2(r * 0.5, 1), Vector2(maxf(lebar - r, 1.0), c.size.y * 0.35)))



static func bahan_bulat() -> ShaderMaterial:
	var sh: = Shader.new()
	sh.code = "shader_type canvas_item;\nvoid fragment(){ vec4 c = texture(TEXTURE, UV); COLOR = vec4(c.rgb, c.a * (1.0 - smoothstep(0.47, 0.5, distance(UV, vec2(0.5))))); }"
	var m: = ShaderMaterial.new()
	m.shader = sh
	return m




static func gaya_kotak_dialog(kotak_dialog: PanelContainer, bingkai: PanelContainer, gambar: TextureRect, kotak_nama: PanelContainer, nama: Label, teks: Label, petunjuk: Label) -> void :
	kotak_dialog.add_theme_stylebox_override("panel", kaca(0.7, 12, Vector4(22, 14, 28, 12)))
	var bulat: = kotak(Color(0, 0, 0, 0.35), 90, Vector4(4, 4, 4, 4))
	bingkai.add_theme_stylebox_override("panel", bulat)
	gambar.material = bahan_bulat()
	kotak_nama.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	gaya_label(nama, 36, BIRU_NAMA, true, 3)
	gaya_label(teks, 26, Color.WHITE, false, 3)
	if petunjuk != null:
		gaya_label(petunjuk, 18, KUNING, true, 3)
		petunjuk.text = "KLIK UNTUK LANJUT  ▸"



static var _bunyi_hp: AudioStreamWAV = null

static func bunyi_buka_kunci() -> AudioStreamWAV:
	if _bunyi_hp != null:
		return _bunyi_hp
	var laju: = 44100
	var jumlah: = int(laju * 0.32)
	var data: = PackedByteArray()
	data.resize(jumlah * 2)
	var acak: = RandomNumberGenerator.new()
	acak.seed = 7
	var desir: = 0.0
	for i in jumlah:
		var t: = float(i) / laju
		var s: = 0.0
		if t < 0.03:
			s += sin(TAU * 3400.0 * t) * exp( - t * 260.0) * 0.55
			s += acak.randf_range(-1, 1) * exp( - t * 900.0) * 0.25
		var t2: = t - 0.055
		if t2 >= 0.0:
			s += (sin(TAU * 1180.0 * t2) * 0.5 + sin(TAU * 2360.0 * t2) * 0.18) * exp( - t2 * 75.0)
			s += sin(TAU * 190.0 * t2) * exp( - t2 * 45.0) * 0.35
		var t3: = t - 0.07
		if t3 >= 0.0:
			desir = lerpf(desir, acak.randf_range(-1, 1), 0.35)
			s += desir * sin(PI * clampf(t3 / 0.22, 0.0, 1.0)) * 0.12
		s *= minf(1.0, t * 4000.0)
		data.encode_s16(i * 2, int(clampf(s, -1.0, 1.0) * 26000.0))
	_bunyi_hp = AudioStreamWAV.new()
	_bunyi_hp.format = AudioStreamWAV.FORMAT_16_BITS
	_bunyi_hp.mix_rate = laju
	_bunyi_hp.data = data
	return _bunyi_hp
