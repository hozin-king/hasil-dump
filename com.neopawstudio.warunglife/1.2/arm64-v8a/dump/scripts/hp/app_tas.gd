extends VBoxContainer






const UI: = preload("res://scripts/hp/hp_ui.gd")
const GH: = preload("res://scripts/gaya_hud.gd")
const WARNA: = Color(0.3, 0.5, 0.65)
const KOLOM: = 4
const UKURAN_KOTAK: = 80.0
const KAYU: = Color(0.5, 0.33, 0.19)
const KAYU_GELAP: = Color(0.33, 0.2, 0.11)
const KOTAK_ISI: = Color(0.95, 0.88, 0.7)
const KOTAK_KOSONG: = Color(0.8, 0.69, 0.5)
const KOTAK_TEPI: = Color(0.55, 0.38, 0.22)
const PILIH: = Color(1.0, 0.82, 0.2)
const TEKS_COKLAT: = Color(0.3, 0.18, 0.09)

var hp: Control
var _isi: VBoxContainer
var _pilih: = ""
var _jumlah_buang: = 1
var _yakin_buang: = false
var _pesan: = ""


func _ready() -> void :
	add_theme_constant_override("separation", 0)
	add_child(UI.kepala("Tas", WARNA))
	var g: Array = UI.gulir(10)
	var tepi: = MarginContainer.new()
	tepi.size_flags_vertical = Control.SIZE_EXPAND_FILL
	for sisi in ["left", "right", "top", "bottom"]:
		tepi.add_theme_constant_override("margin_" + sisi, 10)
	tepi.add_child(g[0])
	add_child(tepi)
	_isi = g[1]


func _gaya(warna: Color, sudut: int, tepi_garis: int, warna_tepi: Color, isi: = 6) -> StyleBoxFlat:
	var s: = StyleBoxFlat.new()
	s.bg_color = warna
	s.set_corner_radius_all(sudut)
	s.set_border_width_all(tepi_garis)
	s.border_color = warna_tepi
	s.set_content_margin_all(isi)
	return s


func _label(teks: String, ukuran: int, warna: Color, bungkus: = false) -> Label:
	var l: = UI.label(teks, ukuran, warna, bungkus)
	l.add_theme_color_override("font_color", warna)
	return l




func _milik() -> Array:
	var gs: = GameState
	var data: = gs.data_hasil_alam()
	var hasil: = []
	for kelompok in ["ikan", "buah"]:
		for id in data.get(kelompok, {}):
			var sisa: = gs.jumlah_hasil_alam(String(id))
			while sisa > 0:
				hasil.append([String(id), mini(sisa, gs.ISI_KOTAK_ALAM), false])
				sisa -= gs.ISI_KOTAK_ALAM
	for id in gs.barang_fisik():
		var n: = int(gs.tas_grosir.get(id, 0))
		while n > 0:
			hasil.append([id, mini(n, gs.ISI_KOTAK_GROSIR), true])
			n -= gs.ISI_KOTAK_GROSIR
	return hasil


func tampil() -> void :
	var gs: = GameState
	for anak in _isi.get_children():
		anak.queue_free()
	var milik: = _milik()
	if not milik.any( func(k): return k[0] == _pilih):
		_pilih = String(milik[0][0]) if not milik.is_empty() else ""
		_jumlah_buang = 1
		_yakin_buang = false

	var bingkai: = PanelContainer.new()
	bingkai.mouse_filter = Control.MOUSE_FILTER_PASS
	bingkai.add_theme_stylebox_override("panel", _gaya(KAYU, 14, 4, KAYU_GELAP, 10))
	_isi.add_child(bingkai)
	var kolom: = VBoxContainer.new()
	kolom.add_theme_constant_override("separation", 8)
	bingkai.add_child(kolom)
	var atas: = HBoxContainer.new()
	kolom.add_child(atas)
	var judul: = _label("Isi Tas", 18, Color(1, 0.93, 0.78))
	judul.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	atas.add_child(judul)
	var jumlah_kotak: = maxi(GameState.KOTAK_TAS, ceili(milik.size() / float(KOLOM)) * KOLOM)
	atas.add_child(_label("%d/%d kotak" % [milik.size(), jumlah_kotak], 14, Color(1, 0.93, 0.78, 0.75)))
	var grid: = GridContainer.new()
	grid.columns = KOLOM
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	kolom.add_child(grid)
	for i in jumlah_kotak:
		grid.add_child(_kotak(milik[i] if i < milik.size() else ["", 0, false]))
	if _pesan != "":
		_isi.add_child(UI.label(_pesan, 15, UI.WARNA_BERHASIL, true))

	_isi.add_child(_detail())

	var ket: = UI.panel(Color(0.93, 0.96, 0.98), 12, 10)
	var baris_ket: = VBoxContainer.new()
	baris_ket.add_theme_constant_override("separation", 2)
	ket.add_child(baris_ket)
	baris_ket.add_child(UI.label("Memancing di sungai bawah jembatan: energi -%d%% tiap lemparan, berhenti kapan saja." % int(gs.aturan_hasil_alam("energi_per_lempar", 3)), 14, UI.WARNA_REDUP, true))
	baris_ket.add_child(UI.label("Kebun buah di tepi jalan dekat pohon pisang: buah tumbuh lagi beberapa hari sesudah dipetik, memetik tidak menguras energi.", 14, UI.WARNA_REDUP, true))
	baris_ket.add_child(UI.label("Jual ikan & buah ke Bu Ida di Pasar: naik angkot dari ujung jalan dekat pos ronda, pasar buka 06.00-21.00, libur Selasa & Kamis.", 14, UI.WARNA_REDUP, true))
	baris_ket.add_child(UI.label("Belanja grosir di Haji Maman (Pasar): 1 kotak muat 10 barang sejenis. Begitu masuk warung, barangnya langsung jadi stok.", 14, UI.WARNA_REDUP, true))
	_isi.add_child(ket)
	if not gs.hasil_alam.is_empty():
		_isi.add_child(UI.label("Perkiraan nilai isi tas: %s" % gs.format_rupiah(gs.nilai_tas()), 16, UI.WARNA_BERHASIL, true))


func _kotak(k: Array) -> Control:
	var id: = String(k[0])
	var grosir: = bool(k[2])
	var b: = Button.new()
	b.mouse_filter = Control.MOUSE_FILTER_PASS
	b.custom_minimum_size = Vector2(UKURAN_KOTAK, UKURAN_KOTAK)
	b.focus_mode = Control.FOCUS_NONE
	var dipilih: = id != "" and id == _pilih
	var leg: = id != "" and not grosir and GameState.legendaris(id)
	var warna: = (Color(1.0, 0.92, 0.55) if leg else KOTAK_ISI) if id != "" else KOTAK_KOSONG
	var gaya: = _gaya(warna, 10, 4 if dipilih else 3, PILIH if dipilih else (Color(0.85, 0.6, 0.1) if leg else KOTAK_TEPI), 4)

	gaya.shadow_color = Color(0, 0, 0, 0.25)
	gaya.shadow_size = 2 if id != "" else 0
	gaya.shadow_offset = Vector2(0, 2)
	for keadaan in ["normal", "hover", "pressed", "focus"]:
		b.add_theme_stylebox_override(keadaan, gaya)
	if id == "":
		return b
	var jalur: = ("res://assets/barang/%s.png" % id) if grosir else String(GameState.info_hasil_alam(id).get("ikon", ""))
	var ikon: = UI.ikon(load(jalur), UKURAN_KOTAK - 18)
	ikon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for sisi in [SIDE_LEFT, SIDE_TOP]:
		ikon.set_offset(sisi, 9)
	for sisi in [SIDE_RIGHT, SIDE_BOTTOM]:
		ikon.set_offset(sisi, -9)
	b.add_child(ikon)
	var n: = UI.label("%d" % int(k[1]), 20, Color.WHITE)
	n.add_theme_color_override("font_outline_color", KAYU_GELAP)
	n.add_theme_constant_override("outline_size", 7)
	n.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	n.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	n.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	n.set_offset(SIDE_RIGHT, -7)
	n.set_offset(SIDE_BOTTOM, -2)
	n.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(n)
	b.pressed.connect( func():
		_pilih = id
		_jumlah_buang = 1
		_yakin_buang = false
		_pesan = ""
		tampil())
	return b



func _kontrol_buang(ada: int, nama: String) -> Control:
	_jumlah_buang = clampi(_jumlah_buang, 1, ada)
	var kolom: = VBoxContainer.new()
	kolom.add_theme_constant_override("separation", 6)
	var baris: = HBoxContainer.new()
	baris.add_theme_constant_override("separation", 6)
	kolom.add_child(baris)
	var judul: = _label("Jumlah", 15, TEKS_COKLAT)
	judul.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	baris.add_child(judul)
	for t in [["−", -1], ["+", 1]]:
		var ubah: = UI.tombol(String(t[0]), KAYU, 20, 38)
		ubah.custom_minimum_size.x = 42
		ubah.disabled = _jumlah_buang + int(t[1]) < 1 or _jumlah_buang + int(t[1]) > ada
		ubah.pressed.connect(_atur_jumlah_buang.bind(_jumlah_buang + int(t[1])))
		baris.add_child(ubah)
		if int(t[1]) < 0:
			var angka: = _label("%d" % _jumlah_buang, 18, TEKS_COKLAT)
			angka.custom_minimum_size.x = 34
			angka.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			baris.add_child(angka)
	var semua: = UI.tombol("Semua", KAYU, 14, 38)
	semua.disabled = _jumlah_buang == ada
	semua.pressed.connect(_atur_jumlah_buang.bind(ada))
	baris.add_child(semua)
	var buang: = UI.tombol(("Yakin? Ketuk lagi untuk buang %d" % _jumlah_buang) if _yakin_buang else ("Buang %d %s" % [_jumlah_buang, nama]), KAYU, 15, 42)
	if _yakin_buang:
		buang.modulate = Color(1.0, 0.6, 0.55)
	buang.pressed.connect(_tekan_buang.bind(nama))
	kolom.add_child(buang)
	return kolom


func _atur_jumlah_buang(n: int) -> void :
	_jumlah_buang = n
	_yakin_buang = false
	_pesan = ""
	GameState.klik()
	tampil()


func _tekan_buang(nama: String) -> void :
	GameState.klik()
	if not _yakin_buang:
		_yakin_buang = true
		_pesan = ""
		tampil()
		return
	var n: = GameState.buang_isi_tas(_pilih, _jumlah_buang)
	_yakin_buang = false
	_jumlah_buang = 1
	_pesan = "%d %s dibuang." % [n, nama]
	tampil()


func _detail() -> Control:
	var p: = PanelContainer.new()
	p.mouse_filter = Control.MOUSE_FILTER_PASS
	p.add_theme_stylebox_override("panel", _gaya(KOTAK_ISI, 12, 3, KOTAK_TEPI, 10))
	if _pilih == "":
		var kosong: = _label("Tas masih kosong. Pergi ke sawah: memancing di sungai bawah jembatan atau petik buah di kebun.", 15, TEKS_COKLAT, true)
		kosong.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		p.add_child(kosong)
		return p
	var gs: = GameState
	var wadah: = VBoxContainer.new()
	wadah.add_theme_constant_override("separation", 10)
	p.add_child(wadah)
	if gs.tas_grosir.has(_pilih):
		var bg: = HBoxContainer.new()
		bg.add_theme_constant_override("separation", 12)
		wadah.add_child(bg)
		bg.add_child(UI.ikon(load("res://assets/barang/%s.png" % _pilih), 64))
		var kg: = VBoxContainer.new()
		kg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		kg.add_theme_constant_override("separation", 0)
		bg.add_child(kg)
		kg.add_child(_label("%s x%d" % [String(gs.data_barang(_pilih)["nama"]), int(gs.tas_grosir[_pilih])], 19, TEKS_COKLAT, true))
		kg.add_child(_label("Belanjaan grosir pasar. Masuk warung = langsung jadi stok.", 14, TEKS_COKLAT.lightened(0.25), true))
		wadah.add_child(_kontrol_buang(int(gs.tas_grosir[_pilih]), String(gs.data_barang(_pilih)["nama"])))
		return p
	var d: = gs.info_hasil_alam(_pilih)
	var n: = gs.jumlah_hasil_alam(_pilih)
	var harga: = int(d.get("harga", 0))
	var baris: = HBoxContainer.new()
	baris.add_theme_constant_override("separation", 12)
	wadah.add_child(baris)
	baris.add_child(UI.ikon(load(String(d.get("ikon", ""))), 64))
	var kolom: = VBoxContainer.new()
	kolom.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	kolom.add_theme_constant_override("separation", 0)
	baris.add_child(kolom)
	kolom.add_child(_label("%s x%d" % [String(d.get("nama", _pilih)), n], 19, TEKS_COKLAT, true))
	kolom.add_child(_label(("%s / ekor di pasar" if String(d.get("satuan", "")) == "ekor" else "%s / buah di pasar") % gs.format_rupiah(harga), 14, TEKS_COKLAT.lightened(0.25), true))
	kolom.add_child(_label("Nilai: %s" % gs.format_rupiah(harga * n), 15, Color(0.2, 0.45, 0.15), true))
	if gs.legendaris(_pilih):
		kolom.add_child(_label("Ikan legendaris! Sangat langka.", 14, Color(0.7, 0.42, 0.0), true))
	wadah.add_child(_kontrol_buang(n, String(d.get("nama", _pilih))))
	return p
