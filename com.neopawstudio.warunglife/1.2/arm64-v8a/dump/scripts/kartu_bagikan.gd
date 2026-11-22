extends Control






const GH: = preload("res://scripts/gaya_hud.gd")
const UKURAN: = Vector2(1080, 1350)
const KREM: = Color(1.0, 0.96, 0.87)
const COKLAT: = Color(0.29, 0.2, 0.15)
const OREN: = Color(0.95, 0.52, 0.16)


func isi(data: Dictionary) -> void :
	for anak in get_children():
		anak.queue_free()
	size = UKURAN
	custom_minimum_size = UKURAN

	var latar: = TextureRect.new()
	latar.texture = _latar_malam_basah()
	latar.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	latar.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	latar.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(latar)
	var gradasi: = TextureRect.new()
	var g: = Gradient.new()
	g.set_color(0, Color(0.08, 0.05, 0.03, 0.0))
	g.set_color(1, Color(0.08, 0.05, 0.03, 0.55))
	var tg: = GradientTexture2D.new()
	tg.gradient = g
	tg.fill_from = Vector2(0.5, 0.0)
	tg.fill_to = Vector2(0.5, 1.0)
	gradasi.texture = tg
	gradasi.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	gradasi.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(gradasi)

	var kolom: = VBoxContainer.new()
	kolom.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	kolom.offset_left = 70
	kolom.offset_right = -70
	kolom.offset_top = 50
	kolom.offset_bottom = -50
	kolom.add_theme_constant_override("separation", 24)
	add_child(kolom)
	var logo: = TextureRect.new()
	logo.texture = load("res://assets/ui/logo_game.png")
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	logo.custom_minimum_size = Vector2(0, 300)
	kolom.add_child(logo)
	var jarak: = Control.new()
	jarak.size_flags_vertical = Control.SIZE_EXPAND_FILL
	kolom.add_child(jarak)


	var kartu: = PanelContainer.new()
	var sk: = StyleBoxFlat.new()
	sk.bg_color = Color(0.1, 0.07, 0.05, 0.42)
	sk.set_corner_radius_all(44)
	sk.set_content_margin_all(40)
	sk.border_color = Color(1, 1, 1, 0.35)
	sk.set_border_width_all(3)
	kartu.add_theme_stylebox_override("panel", sk)
	kolom.add_child(kartu)
	var dalam: = VBoxContainer.new()
	dalam.add_theme_constant_override("separation", 22)
	kartu.add_child(dalam)
	var pita: = _label(GameState.tk("WARUNGKU HARI KE-%d") % int(data.get("hari", 1)), 30, GH.KUNING, true)
	_bayang(pita)
	dalam.add_child(pita)
	var nama: = _label(String(data.get("nama", "Warung")).to_upper(), 76, Color.WHITE, true)
	_bayang(nama)
	nama.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dalam.add_child(nama)
	var kisi: = GridContainer.new()
	kisi.columns = 2
	kisi.add_theme_constant_override("h_separation", 22)
	kisi.add_theme_constant_override("v_separation", 22)
	dalam.add_child(kisi)
	kisi.add_child(_kotak("LEVEL", str(int(data.get("level", 1))), Color(0.98, 0.84, 0.45)))
	kisi.add_child(_kotak("PEMBELI", _ribuan(int(data.get("pembeli", 0))), Color(0.72, 0.9, 0.6)))
	var bintang: = int(data.get("bintang", 0))
	kisi.add_child(_kotak("REPUTASI", ("★".repeat(bintang) + "☆".repeat(5 - bintang)) if bintang > 0 else "-", Color(1.0, 0.75, 0.55)))
	var peringkat: = int(data.get("peringkat", 0))
	kisi.add_child(_kotak("PERINGKAT", ("#%d" % peringkat) if peringkat > 0 else "-", Color(0.78, 0.74, 0.95), 
		(GameState.tk("dari %s warung") % _ribuan(int(data.get("jumlah_warung", 0)))) if peringkat > 0 else ""))


	var bawah: = HBoxContainer.new()
	bawah.add_theme_constant_override("separation", 24)
	bawah.alignment = BoxContainer.ALIGNMENT_CENTER
	kolom.add_child(bawah)
	var studio: = TextureRect.new()
	studio.texture = load("res://assets/ui/logo_studio.png")
	studio.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	studio.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	studio.custom_minimum_size = Vector2(170, 125)
	bawah.add_child(studio)
	var ajak: = VBoxContainer.new()
	ajak.alignment = BoxContainer.ALIGNMENT_CENTER
	ajak.add_theme_constant_override("separation", 2)
	bawah.add_child(ajak)
	var a1: = _label(GameState.tk("Main Warung Life Simulator"), 40, Color.WHITE, true)
	a1.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	ajak.add_child(a1)
	var a2: = _label(GameState.tk("Gratis di Google Play · @neopawstudio"), 30, GH.KUNING, false)
	a2.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	ajak.add_child(a2)



const FILE_LATAR: = "res://assets/latar/latar_warung_kosong_malam_basah.png"

static func _latar_malam_basah() -> Texture2D:
	return load(FILE_LATAR)


func _kotak(judul: String, angka: String, warna: Color, catatan: = "") -> PanelContainer:
	var p: = PanelContainer.new()
	var s: = StyleBoxFlat.new()
	s.bg_color = Color(warna.r, warna.g, warna.b, 0.38)
	s.border_color = Color(warna.r, warna.g, warna.b, 0.9)
	s.set_border_width_all(3)
	s.set_corner_radius_all(28)
	s.content_margin_top = 18
	s.content_margin_bottom = 18
	p.add_theme_stylebox_override("panel", s)
	p.custom_minimum_size = Vector2(430, 190)
	var v: = VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 0)
	p.add_child(v)
	v.add_child(_bayang(_label(GameState.tk(judul), 28, warna.lightened(0.45), false)))
	v.add_child(_bayang(_label(angka, 76, Color.WHITE, true)))
	if catatan != "":
		v.add_child(_bayang(_label(catatan, 24, Color(1, 1, 1, 0.9), false)))
	return p


func _label(teks: String, ukuran: int, warna: Color, besar: bool) -> Label:
	var l: = Label.new()
	l.text = teks
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_override("font", GH.cetak() if besar else GH.font("Nunito", 800))
	l.add_theme_font_size_override("font_size", ukuran)
	l.add_theme_color_override("font_color", warna)
	l.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	return l



func _bayang(l: Label) -> Label:
	l.add_theme_color_override("font_outline_color", Color(0.1, 0.06, 0.03, 0.85))
	l.add_theme_constant_override("outline_size", 10)
	return l


func _ribuan(n: int) -> String:
	var s: = str(n)
	var hasil: = ""
	while s.length() > 3:
		hasil = "." + s.right(3) + hasil
		s = s.left(s.length() - 3)
	return s + hasil
