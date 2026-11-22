extends VBoxContainer








const UI: = preload("res://scripts/hp/hp_ui.gd")
const GH: = preload("res://scripts/gaya_hud.gd")
const PP: = preload("res://scripts/papan_peringkat.gd")
const BAGIKAN: = preload("res://scripts/bagikan.gd")
const WARNA: = Color(0.55, 0.38, 0.78)
const TAMPIL_MAKS: = 100
const FP: = preload("res://scripts/foto_profil.gd")


const BIRU_LATAR: = Color(0.1, 0.2, 0.42)
const BIRU_KARTU: = Color(0.22, 0.45, 0.82)
const BIRU_KARTU_2: = Color(0.18, 0.39, 0.74)
const BIRU_GELAP: = Color(0.07, 0.14, 0.33)
const EMAS: = Color(1.0, 0.8, 0.18)
const EMAS_GELAP: = Color(0.72, 0.45, 0.05)
const PERAK: = Color(0.82, 0.86, 0.92)
const PERUNGGU: = Color(0.88, 0.55, 0.28)
const WARNA_MEDALI: = [EMAS, PERAK, PERUNGGU]
const JINGGA_KAMU: = Color(1.0, 0.62, 0.15)
const HIJAU_TOMBOL: = Color(0.36, 0.78, 0.25)
const GARIS_HITAM: = Color(0.04, 0.05, 0.12)

var hp: Control
var _isi: VBoxContainer
var _tab: = "semua"
var _tombol_tab: = {}
var _terbuka: = ""
var _pesan_bagikan: = ""


func _ready() -> void :
	add_theme_constant_override("separation", 0)
	resized.connect(queue_redraw)
	add_child(_kepala())
	var baris_tab: = HBoxContainer.new()
	baris_tab.add_theme_constant_override("separation", 8)
	var tepi_tab: = MarginContainer.new()
	for sisi in ["left", "right", "top"]:
		tepi_tab.add_theme_constant_override("margin_" + sisi, 10)
	tepi_tab.add_child(baris_tab)
	add_child(tepi_tab)
	for t in [["semua", "Sepanjang Masa"], ["bulan", "Bulan Ini"]]:
		var b: = Button.new()
		b.text = t[1]
		b.custom_minimum_size = Vector2(0, 44)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.add_theme_font_override("font", GH.cetak())
		b.add_theme_font_size_override("font_size", 20)
		b.add_theme_constant_override("outline_size", 6)
		b.add_theme_color_override("font_outline_color", GARIS_HITAM)
		b.pressed.connect(_pilih_tab.bind(t[0]))
		baris_tab.add_child(b)
		_tombol_tab[t[0]] = b
	var g: Array = UI.gulir(8)
	var tepi: = MarginContainer.new()
	tepi.size_flags_vertical = Control.SIZE_EXPAND_FILL
	for sisi in ["left", "right", "top", "bottom"]:
		tepi.add_theme_constant_override("margin_" + sisi, 10)
	tepi.add_child(g[0])
	add_child(tepi)
	_isi = g[1]
	GameState.papan.diperbarui.connect( func(): if is_visible_in_tree(): _gambar())



func _draw() -> void :
	draw_rect(Rect2(Vector2.ZERO, size), BIRU_LATAR)



func _kepala() -> PanelContainer:
	var p: = PanelContainer.new()
	p.add_theme_stylebox_override("panel", _kotak(BIRU_KARTU, 0, 6, Vector4(12, 10, 12, 10)))
	var h: = HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	p.add_child(h)
	h.add_child(_ikon_piala(40))
	var l: = _teks("PERINGKAT WARUNG", 30, Color.WHITE, 8)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	h.add_child(l)
	return p


func _pilih_tab(id: String) -> void :
	GameState.klik()
	_tab = id
	_terbuka = ""
	_gambar()



func tampil() -> void :
	_terbuka = ""
	_pesan_bagikan = ""
	_gambar()
	GameState.papan.segarkan(GameState.papan.status != "ok", 60.0)


func _gambar() -> void :
	for id in _tombol_tab:
		var b: Button = _tombol_tab[id]
		var pilih: bool = id == _tab
		var w: = EMAS if pilih else BIRU_KARTU_2
		for keadaan in ["normal", "hover", "pressed", "focus"]:
			b.add_theme_stylebox_override(keadaan, _kotak(w, 12, 5, Vector4(8, 4, 8, 4)))
		b.add_theme_color_override("font_color", Color.WHITE)
		b.add_theme_color_override("font_hover_color", Color.WHITE)
		b.add_theme_color_override("font_pressed_color", Color.WHITE)
	for anak in _isi.get_children():
		anak.queue_free()
	var p: = PP.papan(_tab)
	var daftar: Array = p["daftar"]
	var kamu: int = p["kamu"]
	var peringkat: int = p["peringkat"]
	_isi.add_child(_kartu_kamu(p, daftar, kamu, peringkat))
	if GameState.papan.nama_ditolak:
		_kartu_ganti_nama()
	var ket: = _keterangan(p["online"])
	if ket != null:
		_isi.add_child(ket)
	if _tab == "bulan":
		_isi.add_child(_catatan("Papan Bulan Ini mulai dari nol setiap tanggal 1."))

	if daftar.size() >= 3:
		_isi.add_child(_podium(daftar))
	for i in range(3 if daftar.size() >= 3 else 0, mini(TAMPIL_MAKS, daftar.size())):
		_isi.add_child(_baris(i + 1, daftar[i]))
	if kamu >= TAMPIL_MAKS:
		_isi.add_child(_catatan("· · ·"))
		_isi.add_child(_baris(peringkat, daftar[kamu]))
	if p["online"]:
		_isi.add_child(_catatan("Klik warung lain untuk melaporkan nama yang tidak pantas."))




func _kartu_kamu(p: Dictionary, daftar: Array, kamu: int, peringkat: int) -> PanelContainer:
	var kartu: = PanelContainer.new()
	kartu.mouse_filter = Control.MOUSE_FILTER_PASS
	kartu.add_theme_stylebox_override("panel", _kotak(JINGGA_KAMU, 16, 7, Vector4(12, 10, 12, 12)))
	var v: = VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	kartu.add_child(v)
	var h: = HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	v.add_child(h)
	h.add_child(_lencana(peringkat, 58))

	var tombol_foto: = Button.new()
	tombol_foto.flat = true
	tombol_foto.focus_mode = Control.FOCUS_NONE
	tombol_foto.custom_minimum_size = Vector2(64, 64)
	tombol_foto.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	tombol_foto.add_child(FP.bulat(FP.pilihan(), 64, Color.WHITE, GameState.nama_warung_lengkap()))
	tombol_foto.pressed.connect(_pilih_foto)
	h.add_child(tombol_foto)
	var kiri: = VBoxContainer.new()
	kiri.add_theme_constant_override("separation", 0)
	kiri.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(kiri)
	var nama: = _tanpa_saring(_teks(GameState.nama_warung_lengkap(), 24, Color.WHITE, 7))
	nama.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	nama.clip_text = true
	kiri.add_child(nama)
	if GameState.papan.pendukung_saya():
		var pil: = _pil_pendukung()
		pil.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		kiri.add_child(pil)
	kiri.add_child(_teks(("PERINGKAT #%s dari %s" % [PP.angka(peringkat), PP.angka(p["jumlah_warung"])]) if peringkat > 0 else "Peringkat belum tersedia", 15, Color(1, 0.97, 0.85), 5))
	if daftar[kamu].size() > 3:
		kiri.add_child(_bintang(int(daftar[kamu][3]), 18.0))
	var jumlah: = HBoxContainer.new()
	jumlah.add_theme_constant_override("separation", 4)
	jumlah.add_child(_ikon_piala(24))
	jumlah.add_child(_teks(PP.angka(int(daftar[kamu][1])), 26, EMAS, 7))
	h.add_child(jumlah)
	var teks_jumlah: = "pembeli dilayani %s" % ("sejak warung dibuka" if _tab == "semua" else "bulan ini")
	v.add_child(_teks(teks_jumlah, 14, Color(1, 0.97, 0.88), 4))
	if kamu > 0:
		var selisih: = int(daftar[kamu - 1][1]) - int(daftar[kamu][1]) + 1
		var kejar: = _tanpa_saring(_teks("%s pembeli lagi untuk menyalip %s!" % [PP.angka(selisih), daftar[kamu - 1][0]], 14, Color.WHITE, 4))
		kejar.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		v.add_child(kejar)

	var tombol: = HBoxContainer.new()
	tombol.add_theme_constant_override("separation", 8)
	v.add_child(tombol)
	var ada_hadiah: = GameState.hadiah_bagikan_tersedia()
	var bagi: = _tombol_timbul("Bagikan (+%s)" % GameState.format_rupiah(GameState.HADIAH_BAGIKAN) if ada_hadiah else "Bagikan", HIJAU_TOMBOL)
	var ket_bagi: = _teks("", 13, Color.WHITE, 4)
	ket_bagi.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ket_bagi.visible = _pesan_bagikan != ""
	ket_bagi.text = _pesan_bagikan
	bagi.pressed.connect( func():
		GameState.klik()
		bagi.disabled = true
		bagi.text = "Membuat gambar..."
		var data: = BAGIKAN.data_pemain()
		var path: String = await BAGIKAN.buat_gambar(self, data)
		if path != "":
			BAGIKAN.bagikan(path, BAGIKAN.teks_ajakan(data))
			var dapat: = GameState.ambil_hadiah_bagikan()
			if dapat > 0:
				_pesan_bagikan = "Terima kasih sudah membagikan! Pak Misran dapat %s." % GameState.format_rupiah(dapat)
				_gambar()
		if is_instance_valid(bagi):
			bagi.disabled = false
			bagi.text = "Bagikan")
	tombol.add_child(bagi)
	var ganti: = _tombol_timbul("Ganti nama" + (" (gratis)" if GameState.ganti_nama_gratis() else ""), BIRU_KARTU)
	ganti.pressed.connect( func():
		GameState.klik()
		var j: CanvasLayer = load("res://scripts/ganti_nama_warung.gd").new()
		j.selesai.connect( func(berhasil: bool):
			if berhasil and is_instance_valid(self):
				_gambar())
		get_tree().root.add_child(j))
	tombol.add_child(ganti)
	var foto: = _tombol_timbul("Foto", BIRU_KARTU)
	foto.pressed.connect(_pilih_foto)
	tombol.add_child(foto)
	v.add_child(ket_bagi)
	return kartu


func _pilih_foto() -> void :
	GameState.klik()
	FP.buka_pemilih(self, func(_n: int):
		if is_instance_valid(self):
			_gambar())




func _podium(daftar: Array) -> HBoxContainer:
	var h: = HBoxContainer.new()
	h.add_theme_constant_override("separation", 6)
	h.alignment = BoxContainer.ALIGNMENT_CENTER

	for nomor in [2, 1, 3]:
		h.add_child(_tiang(nomor, daftar[nomor - 1]))
	return h


func _tiang(nomor: int, data: Array) -> VBoxContainer:
	var milik_kamu: bool = data.size() > 5
	var v: = VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.size_flags_vertical = Control.SIZE_SHRINK_END
	v.add_theme_constant_override("separation", 2)
	v.alignment = BoxContainer.ALIGNMENT_END
	if nomor == 1:
		var mahkota: = _ikon_mahkota(40)
		mahkota.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		v.add_child(mahkota)

	var foto: = FP.bulat(PP.foto(String(data[2]), _tab, milik_kamu), 58 if nomor == 1 else 48, WARNA_MEDALI[nomor - 1], String(data[0]))
	foto.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(foto)
	var lencana: = _lencana(nomor, 50 if nomor == 1 else 42)
	lencana.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(lencana)

	var pendukung: = PP.pendukung_awal(String(data[2]), _tab, milik_kamu)
	var nama: = _tanpa_saring(_teks(("★ " if pendukung else "") + String(data[0]), 18, 
		PP.WARNA_NAMA_PENDUKUNG if pendukung and not milik_kamu else Color.WHITE, 6))
	nama.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nama.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	nama.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	nama.max_lines_visible = 2
	nama.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	nama.custom_minimum_size.x = 60
	v.add_child(nama)

	var tiang: = PanelContainer.new()
	tiang.mouse_filter = Control.MOUSE_FILTER_PASS
	tiang.custom_minimum_size.y = [0, 104, 82, 70][nomor]
	var warna: Color = JINGGA_KAMU if milik_kamu else WARNA_MEDALI[nomor - 1]
	tiang.add_theme_stylebox_override("panel", _kotak(warna, 10, 6, Vector4(4, 6, 4, 6)))
	var isi: = VBoxContainer.new()
	isi.alignment = BoxContainer.ALIGNMENT_CENTER
	isi.add_theme_constant_override("separation", 0)
	tiang.add_child(isi)
	var jumlah: = HBoxContainer.new()
	jumlah.alignment = BoxContainer.ALIGNMENT_CENTER
	jumlah.add_theme_constant_override("separation", 2)
	jumlah.add_child(_ikon_piala(16))
	jumlah.add_child(_teks(PP.angka(int(data[1])), 16 if nomor == 1 else 14, Color.WHITE, 5))
	isi.add_child(jumlah)

	var pita: = PanelContainer.new()
	pita.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pita.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var sb: = StyleBoxFlat.new()
	sb.bg_color = Color(0.06, 0.1, 0.24, 0.75)
	sb.set_corner_radius_all(9)
	sb.content_margin_left = 5
	sb.content_margin_right = 5
	sb.content_margin_top = 3
	sb.content_margin_bottom = 3
	pita.add_theme_stylebox_override("panel", sb)
	pita.add_child(_bintang(int(data[3]) if data.size() > 3 else -1, 14.0))
	isi.add_child(pita)
	var info: = _teks("Lv %d" % int(data[4]) if data.size() > 4 and int(data[4]) > 0 else "", 14, Color(1, 1, 1, 0.95), 4)
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	isi.add_child(info)
	v.add_child(tiang)
	_bisa_dilaporkan(tiang, data, v)
	return v




func _baris(nomor_urut: int, data: Array) -> PanelContainer:
	var milik_kamu: bool = data.size() > 5
	var warna: = JINGGA_KAMU if milik_kamu else (BIRU_KARTU if nomor_urut % 2 == 0 else BIRU_KARTU_2)
	var p: = PanelContainer.new()
	p.mouse_filter = Control.MOUSE_FILTER_PASS
	p.add_theme_stylebox_override("panel", _kotak(warna, 12, 5, Vector4(8, 6, 10, 6)))
	var v: = VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	p.add_child(v)
	var h: = HBoxContainer.new()
	h.add_theme_constant_override("separation", 8)
	v.add_child(h)
	h.add_child(_lencana(nomor_urut, 44))
	h.add_child(FP.bulat(PP.foto(String(data[2]), _tab, milik_kamu), 44, Color.WHITE, String(data[0])))
	var kolom: = VBoxContainer.new()
	kolom.add_theme_constant_override("separation", 1)
	kolom.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(kolom)
	var pendukung: = PP.pendukung_awal(String(data[2]), _tab, milik_kamu)
	var nama: = _tanpa_saring(_teks(String(data[0]), 22, PP.WARNA_NAMA_PENDUKUNG if pendukung and not milik_kamu else Color.WHITE, 6))
	nama.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	nama.clip_text = true
	kolom.add_child(nama)
	var info: = HBoxContainer.new()
	info.add_theme_constant_override("separation", 6)
	kolom.add_child(info)
	info.add_child(_pil("Lv %d" % int(data[4]) if data.size() > 4 and int(data[4]) > 0 else "Lv -", BIRU_GELAP))
	var bintang: = _bintang(int(data[3]) if data.size() > 3 else -1, 18.0)
	bintang.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	info.add_child(bintang)
	if pendukung:
		info.add_child(_pil_pendukung())
	var jumlah: = HBoxContainer.new()
	jumlah.add_theme_constant_override("separation", 3)
	jumlah.add_child(_ikon_piala(22))
	var angka: = _teks(PP.angka(int(data[1])), 20, EMAS, 6)
	angka.custom_minimum_size.x = 56
	angka.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	jumlah.add_child(angka)
	h.add_child(jumlah)
	_bisa_dilaporkan(p, data, v)
	return p



func _bisa_dilaporkan(sasaran: Control, data: Array, wadah: VBoxContainer) -> void :
	var milik_kamu: bool = data.size() > 5
	var kode: = String(data[2]) if data.size() > 2 else ""
	if milik_kamu or kode == "":
		return
	sasaran.mouse_filter = Control.MOUSE_FILTER_STOP
	sasaran.gui_input.connect( func(e: InputEvent):
		if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT and not e.pressed\
		and sasaran.get_global_rect().has_point(sasaran.get_global_mouse_position()):
			_terbuka = "" if _terbuka == kode else kode
			GameState.klik()
			_gambar())
	if _terbuka != kode:
		return
	if GameState.papan.sudah_dilaporkan(kode):
		wadah.add_child(_teks("Laporan terkirim. Terima kasih!", 13, UI.WARNA_BERHASIL, 4))
		return
	var lapor: = _tombol_timbul("Laporkan nama ini", Color(0.85, 0.25, 0.2))
	lapor.pressed.connect( func():
		lapor.disabled = true
		lapor.text = "Mengirim..."
		var ok: bool = await GameState.papan.laporkan(kode)
		if not ok:
			lapor.disabled = false
			lapor.text = "Gagal, coba lagi"
			return
		_gambar())
	wadah.add_child(lapor)


func _keterangan(online: bool) -> Label:
	var teks: = ""
	var papan: Node = GameState.papan
	if papan.sedang_memuat():
		teks = "Memuat papan terbaru..."
	elif papan.status == "gagal":
		teks = "Belum tersambung ke internet. Papan diperbarui lagi saat online." if not online\
		else "Tidak tersambung. Menampilkan papan terakhir yang tersimpan."
	elif not online:
		teks = "Papan online muncul saat HP tersambung ke internet."
	if teks == "":
		return null
	return _catatan(teks)



func _kartu_ganti_nama() -> void :
	var kartu: = PanelContainer.new()
	kartu.add_theme_stylebox_override("panel", _kotak(Color(0.8, 0.22, 0.18), 12, 5, Vector4(12, 10, 12, 10)))
	_isi.add_child(kartu)
	var v: = VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	kartu.add_child(v)
	var l: = _teks("Nama warungmu belum bisa tampil di papan karena mengandung kata yang kurang pantas. Ganti namanya, ya (gratis).", 14, Color.WHITE, 4)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(l)
	var baris: = HBoxContainer.new()
	baris.add_theme_constant_override("separation", 6)
	v.add_child(baris)
	var kolom: = LineEdit.new()
	kolom.max_length = GameState.MAKS_NAMA_WARUNG
	kolom.placeholder_text = "nama baru"
	kolom.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	kolom.add_theme_font_size_override("font_size", 18)
	baris.add_child(kolom)
	var simpan: = _tombol_timbul("Ganti", HIJAU_TOMBOL)
	baris.add_child(simpan)
	var pesan: = _teks("", 13, Color(1, 0.85, 0.8), 4)
	v.add_child(pesan)
	simpan.pressed.connect( func():
		var rapi: = GameState.rapikan_nama_warung(kolom.text)
		if rapi == "" or not GameState.papan.nama_pantas(rapi):
			pesan.text = "Coba nama lain, ya."
			return

		GameState.nama_warung = rapi
		GameState.simpan()
		GameState.data_berubah.emit()
		GameState.papan.nama_ditolak = false
		GameState.papan.segarkan(true)
		_gambar())





func _kotak(warna: Color, sudut: int, bawah: int, tepi: Vector4 = Vector4(10, 8, 10, 8)) -> StyleBoxFlat:
	var s: = StyleBoxFlat.new()
	s.bg_color = warna
	s.set_corner_radius_all(sudut)
	s.border_color = warna.darkened(0.42)
	s.border_width_left = 2
	s.border_width_right = 2
	s.border_width_top = 2
	s.border_width_bottom = bawah
	s.content_margin_left = tepi.x
	s.content_margin_top = tepi.y
	s.content_margin_right = tepi.z
	s.content_margin_bottom = tepi.w + bawah
	s.shadow_color = Color(0, 0, 0, 0.25)
	s.shadow_size = 2
	s.shadow_offset = Vector2(0, 2)
	return s



func _teks(teks: String, ukuran: int, warna: Color, garis: = 5) -> Label:
	var l: = Label.new()
	l.text = teks
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.add_theme_font_override("font", GH.cetak())
	l.add_theme_font_size_override("font_size", ukuran)
	l.add_theme_color_override("font_color", warna)
	l.add_theme_color_override("font_outline_color", GARIS_HITAM)
	l.add_theme_constant_override("outline_size", garis)
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.5))
	l.add_theme_constant_override("shadow_offset_x", 0)
	l.add_theme_constant_override("shadow_offset_y", 2)
	return l


func _catatan(teks: String) -> Label:
	var l: = _teks(teks, 13, Color(1, 1, 1, 0.8), 3)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return l



func _pil_pendukung() -> PanelContainer:
	var p: = _pil("★ " + tr(PP.NAMA_LENCANA_PENDUKUNG), Color(1.0, 0.78, 0.15), Color(0.3, 0.17, 0.0))
	(p.get_theme_stylebox("panel") as StyleBoxFlat).bg_color = Color(1.0, 0.8, 0.2)
	return p


func _pil(teks: String, warna: Color, warna_teks: Color = Color.WHITE) -> PanelContainer:
	var p: = PanelContainer.new()
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var s: = StyleBoxFlat.new()
	s.bg_color = Color(warna, 0.65)
	s.set_corner_radius_all(8)
	s.content_margin_left = 6
	s.content_margin_right = 6
	s.content_margin_top = 0
	s.content_margin_bottom = 1
	p.add_theme_stylebox_override("panel", s)
	p.add_child(_teks(teks, 15, warna_teks, 4))
	return p


func _tombol_timbul(teks: String, warna: Color) -> Button:
	var b: = Button.new()
	b.text = teks
	b.custom_minimum_size = Vector2(0, 44)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.add_theme_font_override("font", GH.cetak())
	b.add_theme_font_size_override("font_size", 17)
	b.add_theme_color_override("font_color", Color.WHITE)
	b.add_theme_color_override("font_hover_color", Color.WHITE)
	b.add_theme_color_override("font_pressed_color", Color.WHITE)
	b.add_theme_color_override("font_disabled_color", Color(1, 1, 1, 0.6))
	b.add_theme_color_override("font_outline_color", GARIS_HITAM)
	b.add_theme_constant_override("outline_size", 5)
	b.add_theme_stylebox_override("normal", _kotak(warna, 12, 5, Vector4(8, 2, 8, 2)))
	b.add_theme_stylebox_override("hover", _kotak(warna.lightened(0.08), 12, 5, Vector4(8, 2, 8, 2)))
	b.add_theme_stylebox_override("pressed", _kotak(warna.darkened(0.1), 12, 2, Vector4(8, 5, 8, 2)))
	b.add_theme_stylebox_override("disabled", _kotak(warna.darkened(0.3), 12, 3, Vector4(8, 2, 8, 2)))
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	return b



func _lencana(nomor: int, ukuran: float) -> Control:
	var c: = Control.new()
	c.custom_minimum_size = Vector2(ukuran, ukuran)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var warna: Color = WARNA_MEDALI[nomor - 1] if nomor >= 1 and nomor <= 3 else BIRU_GELAP
	c.draw.connect( func():
		var pusat: = c.size / 2.0
		var r: = minf(c.size.x, c.size.y) / 2.0
		c.draw_circle(pusat + Vector2(0, 2), r, warna.darkened(0.5))
		c.draw_circle(pusat, r - 1, warna.darkened(0.25))
		c.draw_circle(pusat - Vector2(0, 1.5), r - 4, warna)
		c.draw_arc(pusat - Vector2(0, 1.5), r - 7, PI * 1.15, PI * 1.6, 10, Color(1, 1, 1, 0.45), 2.5))
	var l: = _teks(PP.angka(nomor) if nomor > 0 else "-", int(ukuran * (0.46 if nomor < 100 else 0.34)), Color.WHITE, 6)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.set_anchors_preset(Control.PRESET_FULL_RECT)
	c.add_child(l)
	return c



func _bintang(n: int, ukuran: float) -> Control:
	var c: = Control.new()
	var jarak: = ukuran * 0.12
	c.custom_minimum_size = Vector2(ukuran * 5 + jarak * 4, ukuran)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.draw.connect( func():
		for i in 5:
			var pusat: = Vector2(ukuran / 2.0 + i * (ukuran + jarak), ukuran / 2.0 + 0.5)
			var titik: = PackedVector2Array()
			for k in 10:
				var r: = ukuran * (0.52 if k % 2 == 0 else 0.23)
				var sudut: = - PI / 2.0 + k * PI / 5.0
				titik.append(pusat + Vector2(cos(sudut), sin(sudut)) * r)
			var nyala: = i < n
			c.draw_colored_polygon(titik, EMAS if nyala else Color(0.08, 0.12, 0.25, 0.55))
			c.draw_polyline(titik + PackedVector2Array([titik[0]]), EMAS_GELAP if nyala else Color(1, 1, 1, 0.35), maxf(1.5, ukuran * 0.08), true))
	return c



func _ikon_piala(ukuran: float) -> Control:
	var c: = Control.new()
	c.custom_minimum_size = Vector2(ukuran, ukuran)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	c.draw.connect( func():
		var u: = c.size.x
		var gelap: = EMAS_GELAP

		var cawan: = PackedVector2Array([Vector2(0.2, 0.12), Vector2(0.8, 0.12), Vector2(0.74, 0.42), Vector2(0.58, 0.58), Vector2(0.42, 0.58), Vector2(0.26, 0.42)])
		for i in cawan.size():
			cawan[i] *= u

		c.draw_arc(Vector2(0.2, 0.27) * u, 0.13 * u, PI * 0.5, PI * 1.5, 10, gelap, 0.07 * u)
		c.draw_arc(Vector2(0.8, 0.27) * u, 0.13 * u, - PI * 0.5, PI * 0.5, 10, gelap, 0.07 * u)
		c.draw_colored_polygon(cawan, EMAS)
		c.draw_polyline(cawan + PackedVector2Array([cawan[0]]), gelap, 0.05 * u)

		c.draw_rect(Rect2(Vector2(0.45, 0.58) * u, Vector2(0.1, 0.14) * u), gelap)
		c.draw_rect(Rect2(Vector2(0.3, 0.72) * u, Vector2(0.4, 0.14) * u), EMAS)
		c.draw_rect(Rect2(Vector2(0.3, 0.72) * u, Vector2(0.4, 0.14) * u), gelap, false, 0.05 * u)

		c.draw_line(Vector2(0.33, 0.18) * u, Vector2(0.38, 0.4) * u, Color(1, 1, 1, 0.7), 0.05 * u))
	return c



func _ikon_mahkota(ukuran: float) -> Control:
	var c: = Control.new()
	c.custom_minimum_size = Vector2(ukuran, ukuran * 0.7)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.draw.connect( func():
		var u: = c.size.x
		var t: = c.size.y
		var titik: = PackedVector2Array([Vector2(0.08 * u, 0.9 * t), Vector2(0.05 * u, 0.25 * t), Vector2(0.3 * u, 0.55 * t), 
			Vector2(0.5 * u, 0.08 * t), Vector2(0.7 * u, 0.55 * t), Vector2(0.95 * u, 0.25 * t), Vector2(0.92 * u, 0.9 * t)])
		c.draw_colored_polygon(titik, EMAS)
		c.draw_polyline(titik + PackedVector2Array([titik[0]]), EMAS_GELAP, 0.06 * u)
		for x in [0.05, 0.5, 0.95]:
			var y: = 0.08 if x == 0.5 else 0.25
			c.draw_circle(Vector2(x * u, y * t), 0.07 * u, Color(0.95, 0.25, 0.3))
		c.draw_rect(Rect2(Vector2(0.08 * u, 0.74 * t), Vector2(0.84 * u, 0.16 * t)), EMAS_GELAP))
	return c



func _tanpa_saring(l: Label) -> Label:
	l.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	return l
