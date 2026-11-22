extends VBoxContainer








const UI: = preload("res://scripts/hp/hp_ui.gd")
const GH: = preload("res://scripts/gaya_hud.gd")

const WARNA: = Color(0.12, 0.42, 0.85)
const ORANYE: = Color(0.16, 0.5, 0.92)
const ORANYE_GELAP: = Color(0.07, 0.3, 0.68)
const PUTIH: = Color(1, 1, 1)
const TEKS: = Color(0.16, 0.14, 0.13)
const TEKS_REDUP: = Color(0.45, 0.42, 0.4)
const HIJAU: = Color(0.16, 0.66, 0.36)
const GARIS: = Color(0.88, 0.86, 0.83)

var hp: Control
var _isi: VBoxContainer


func _ready() -> void :
	add_theme_constant_override("separation", 0)
	add_child(UI.kepala("OjekKampung", WARNA))
	var g: Array = UI.gulir(12)
	var tepi: = MarginContainer.new()
	tepi.size_flags_vertical = Control.SIZE_EXPAND_FILL
	for sisi in ["left", "right", "top", "bottom"]:
		tepi.add_theme_constant_override("margin_" + sisi, 12)
	tepi.add_child(g[0])
	add_child(tepi)
	_isi = g[1]


func _label(teks: String, ukuran: int, warna: Color, tebal: = 800, bungkus: = false) -> Label:
	var l: = UI.label(teks, ukuran, warna, bungkus)
	l.add_theme_color_override("font_color", warna)
	l.add_theme_font_override("font", GH.font("Nunito", tebal))
	return l


func _kotak(warna: Color, sudut: = 16, isi: = 14, bayangan: = false) -> StyleBoxFlat:
	var s: = StyleBoxFlat.new()
	s.bg_color = warna
	s.set_corner_radius_all(sudut)
	s.set_content_margin_all(isi)
	if bayangan:
		s.shadow_color = Color(0, 0, 0, 0.3)
		s.shadow_size = 6
		s.shadow_offset = Vector2(0, 3)
	return s


func _panel(warna: Color, sudut: = 16, isi: = 14, bayangan: = false) -> PanelContainer:
	var p: = PanelContainer.new()
	p.mouse_filter = Control.MOUSE_FILTER_PASS
	p.add_theme_stylebox_override("panel", _kotak(warna, sudut, isi, bayangan))
	return p



func _chip(teks: String, latar: Color, warna: Color) -> PanelContainer:
	var p: = _panel(latar, 10, 0)
	var g: = p.get_theme_stylebox("panel") as StyleBoxFlat
	g.content_margin_left = 10
	g.content_margin_right = 10
	g.content_margin_top = 3
	g.content_margin_bottom = 3
	p.add_child(_label(teks, 14, warna, 800))
	return p


func _tombol(teks: String, aktif: bool) -> Button:
	var b: = Button.new()
	b.text = teks
	b.mouse_filter = Control.MOUSE_FILTER_PASS
	b.custom_minimum_size = Vector2(0, 50)
	b.add_theme_font_size_override("font_size", 20)
	b.add_theme_font_override("font", GH.font("Nunito", 900))
	for k in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		b.add_theme_color_override(k, PUTIH)
	b.add_theme_color_override("font_disabled_color", Color(1, 1, 1, 0.8))
	b.add_theme_constant_override("outline_size", 0)
	for keadaan in ["normal", "hover", "pressed", "disabled", "focus"]:
		var w: = ORANYE
		match keadaan:
			"hover": w = ORANYE.lightened(0.08)
			"pressed": w = ORANYE_GELAP
			"disabled": w = Color(0.75, 0.72, 0.68)
		var s: = _kotak(w, 12, 8)
		if keadaan == "focus":
			s.draw_center = false
		b.add_theme_stylebox_override(keadaan, s)
	b.disabled = not aktif
	return b


func tampil() -> void :
	var gs: = GameState
	for anak in _isi.get_children():
		anak.queue_free()
	var alasan: = gs.alasan_tidak_bisa_ngojol()
	var aktif: = alasan == ""
	_isi.add_child(_kartu_driver(aktif))
	if not aktif:
		var info: = _panel(Color(1, 1, 1, 0.08), 14, 14)
		var ket: = _label(alasan, 17, PUTIH, 700, true)
		info.add_child(ket)
		_isi.add_child(info)
		if not gs.punya_motor_ngojol():
			if ResourceLoader.exists("res://assets/wishlist/motor.jpg"):
				var gambar: = TextureRect.new()
				gambar.texture = load("res://assets/wishlist/motor.jpg")
				gambar.custom_minimum_size = Vector2(0, 150)
				gambar.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
				gambar.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
				_isi.add_child(gambar)
			var b: = _tombol("Buka Wishlist", true)
			b.pressed.connect( func():
				if hp != null:
					hp.buka_aplikasi("wishlist"))
			_isi.add_child(b)
			return
	var daftar: = gs.ngojol_order_tampil()
	if daftar.is_empty():
		return
	_isi.add_child(_label("Order masuk", 18, PUTIH, 900))
	for o in daftar:
		_isi.add_child(_kartu_order(o, aktif))



func _kartu_driver(aktif: bool) -> Control:
	var gs: = GameState
	var kartu: = _panel(ORANYE if aktif else Color(0.32, 0.29, 0.27), 18, 14, true)
	var kolom: = VBoxContainer.new()
	kolom.add_theme_constant_override("separation", 8)
	kartu.add_child(kolom)
	var atas: = HBoxContainer.new()
	atas.add_theme_constant_override("separation", 10)
	kolom.add_child(atas)
	var helm: = TextureRect.new()
	helm.texture = load("res://assets/ikon/ojek.svg")
	helm.custom_minimum_size = Vector2(40, 40)
	helm.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	helm.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	atas.add_child(helm)
	var nama: = VBoxContainer.new()
	nama.add_theme_constant_override("separation", -2)
	nama.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	atas.add_child(nama)
	nama.add_child(_label("Pak Misran", 19, PUTIH, 900))
	nama.add_child(_label("Driver OjekKampung", 14, Color(1, 1, 1, 0.85), 700))
	atas.add_child(_chip("ONLINE" if aktif else "OFFLINE", HIJAU if aktif else Color(0.5, 0.47, 0.45), PUTIH))
	if not gs.punya_motor_ngojol():
		return kartu
	var garis: = ColorRect.new()
	garis.color = Color(1, 1, 1, 0.25)
	garis.custom_minimum_size = Vector2(0, 1)
	kolom.add_child(garis)
	var bawah: = HBoxContainer.new()
	bawah.add_theme_constant_override("separation", 8)
	kolom.add_child(bawah)
	for isi in [["Pendapatan hari ini" if gs.hari_libur() else "Pendapatan malam ini", gs.format_rupiah(gs.ngojol_uang_malam_ini())], 
			["Order tersisa", "%d dari %d" % [gs.ngojol_sisa(), gs.ngojol_maks_order()]], 
			["Energi", "%d%%" % int(gs.energi)]]:
		var k: = VBoxContainer.new()
		k.add_theme_constant_override("separation", -2)
		k.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		k.add_child(_label(String(isi[0]), 13, Color(1, 1, 1, 0.85), 700))
		k.add_child(_label(String(isi[1]), 20, PUTIH, 900))
		bawah.add_child(k)

	var kuat: = gs.ngojol_order_kuat()
	if aktif and kuat < gs.ngojol_sisa():
		var awas: = _panel(Color(1, 0.95, 0.85), 10, 8)
		awas.add_child(_label("Energi cukup untuk %d order lagi. Ngopi atau tonton iklan energi supaya bisa ambil semua." % kuat, 14, Color(0.6, 0.25, 0.05), 800, true))
		kolom.add_child(awas)
	kolom.add_child(_label("Jam narik %s - %s · tiap order = sekali antar, ongkos langsung masuk" % [_jam(gs.ngojol_jam_mulai()), _jam(gs.ngojol_jam_akhir())], 
		13, Color(1, 1, 1, 0.85), 700, true))
	return kartu


func _jam(j: float) -> String:
	return "%02d.%02d" % [int(j), int(round(fmod(j, 1.0) * 60))]


func _kartu_order(o: Dictionary, aktif: bool) -> Control:
	var kartu: = _panel(PUTIH, 18, 14, true)
	var kolom: = VBoxContainer.new()
	kolom.add_theme_constant_override("separation", 10)
	kartu.add_child(kolom)

	var atas: = HBoxContainer.new()
	atas.add_theme_constant_override("separation", 10)
	kolom.add_child(atas)
	var potret: = "res://assets/potret/warga_%s.png" % String(o["npc"])
	if ResourceLoader.exists(potret):
		var t: = TextureRect.new()
		t.texture = load(potret)
		t.custom_minimum_size = Vector2(50, 50)
		t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		t.material = GH.bahan_bulat()
		t.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		atas.add_child(t)
	var nama: = VBoxContainer.new()
	nama.add_theme_constant_override("separation", -2)
	nama.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	atas.add_child(nama)
	var barang: bool = String(o.get("jenis", "orang")) == "barang"

	nama.add_child(_label(String(o["barang"]) if barang else String(o["nama"]), 18, TEKS, 900, true))
	nama.add_child(_label(("Antar barang untuk %s" % String(o["nama"])) if barang else "Penumpang", 13, TEKS_REDUP, 700, true))
	var ongkos: = _label(GameState.format_rupiah(int(o["ongkos"])), 22, ORANYE_GELAP, 900)
	ongkos.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	atas.add_child(ongkos)
	var garis: = ColorRect.new()
	garis.color = GARIS
	garis.custom_minimum_size = Vector2(0, 1)
	kolom.add_child(garis)

	var rute: = HBoxContainer.new()
	rute.add_theme_constant_override("separation", 10)
	kolom.add_child(rute)
	var gambar_rute: = Control.new()
	gambar_rute.custom_minimum_size = Vector2(16, 0)

	gambar_rute.draw.connect( func():
		var y1: = 28.0
		var y2: = gambar_rute.size.y - 12.0
		gambar_rute.draw_circle(Vector2(8, y1), 7, HIJAU)
		gambar_rute.draw_circle(Vector2(8, y1), 3, PUTIH)
		var y: = y1 + 11.0
		while y < y2 - 11.0:
			gambar_rute.draw_line(Vector2(8, y), Vector2(8, minf(y + 4.0, y2 - 11.0)), Color(0.7, 0.68, 0.65), 2)
			y += 8.0
		gambar_rute.draw_circle(Vector2(8, y2), 7, ORANYE)
		gambar_rute.draw_circle(Vector2(8, y2), 3, PUTIH))
	rute.add_child(gambar_rute)
	var tempat: = VBoxContainer.new()
	tempat.add_theme_constant_override("separation", 6)
	tempat.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rute.add_child(tempat)
	tempat.add_child(_baris_tempat("Ambil barang" if barang else "Jemput", String(o.get("jemput", "Rumah %s" % String(o["nama"])))))
	tempat.add_child(_baris_tempat("Antar", String(o["tujuan"])))
	if String(o.get("catatan", "")) != "":
		kolom.add_child(_label("\"%s\"" % String(o["catatan"]), 14, TEKS_REDUP, 700, true))

	var chips: = HFlowContainer.new()
	chips.add_theme_constant_override("h_separation", 6)
	chips.add_theme_constant_override("v_separation", 6)
	kolom.add_child(chips)
	chips.add_child(_chip("%s km" % String.num(float(o.get("km", 1.0)), 1).replace(".", ","), Color(0.95, 0.93, 0.9), TEKS))
	chips.add_child(_chip("± 30 menit", Color(0.95, 0.93, 0.9), TEKS))
	chips.add_child(_chip("Energi -%d" % int(GameState.NGOJOL_ENERGI), Color(0.88, 0.95, 0.88), Color(0.12, 0.45, 0.2)))
	match String(o.get("sifat", "santai")):
		"buru":
			chips.add_child(_chip("Buru-buru", Color(1.0, 0.88, 0.85), Color(0.7, 0.2, 0.15)))
		"rapuh":
			chips.add_child(_chip("Hati-hati", Color(1.0, 0.95, 0.8), Color(0.6, 0.4, 0.05)))
	var b: = _tombol("Terima order", aktif)
	b.pressed.connect(_ambil.bind(o))
	kolom.add_child(b)
	return kartu


func _baris_tempat(jenis: String, nama: String) -> Control:
	var k: = VBoxContainer.new()
	k.add_theme_constant_override("separation", -3)
	k.add_child(_label(jenis, 12, TEKS_REDUP, 700))
	k.add_child(_label(nama, 16, TEKS, 900, true))
	return k


func _ambil(o: Dictionary) -> void :
	var alasan: = GameState.alasan_tidak_bisa_ngojol()
	if alasan != "":
		tampil()
		return
	if hp == null or hp.warung == null or not hp.warung.has_method("mulai_ngojol"):

		var ket: = _label("Keluar dari warung dulu, motornya di luar.", 17, Color(0.85, 0.93, 1.0), 800, true)
		_isi.add_child(ket)
		_isi.move_child(ket, 1)
		return
	var tujuan: Node = hp.warung
	hp.tutup()
	await hp.ditutup
	tujuan.mulai_ngojol(o)
