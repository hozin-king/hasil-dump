extends ColorRect







signal ditutup


const PRODUK: = [
	["dukung_esteh", "Segelas kopi", "Kopi untuk tim NeoPaw Studio yang begadang", "Rp15.000"], 
	["dukung_nasipadang", "Makan siang tim", "Sebungkus nasi padang dan es teh untuk tim", "Rp35.000"], 
	["dukung_game_45", "Dukung update berikutnya", "Bantu kami menambah cerita dan fitur baru. Bonus: bebas iklan", "Rp60.000"], 
	["dukung_game_100", "Dukungan besar", "Bantu kami membuat game berikutnya. Bonus: bebas iklan", "Rp99.000"], 
]

const HARGA_CADANGAN_IOS: = {"dukung_esteh": "Rp19.000", "dukung_nasipadang": "Rp49.000", 
	"dukung_game_45": "Rp79.000", "dukung_game_100": "Rp129.000"}
const TEMA: = preload("res://ui/tema.tres")
const PP: = preload("res://scripts/papan_peringkat.gd")

var _label_harga: = {}
var _pesan: Label
var _kotak_kode: VBoxContainer


const TENANG: = preload("res://scripts/tema_tenang.gd")


const GH: = preload("res://scripts/gaya_hud.gd")
const BIRU_BANK: = Color(1.0, 0.77, 0.26)
const BIRU_TERANG: = Color(1.0, 0.77, 0.26)
const NAVY: = Color(0.035, 0.04, 0.07)
const NAVY_KARTU: = Color(0.075, 0.08, 0.115)
const EMAS: = Color(1.0, 0.84, 0.4)
const WARNA_TINGKAT: = [BIRU_TERANG, BIRU_TERANG, BIRU_TERANG, BIRU_TERANG]
const IKON_TINGKAT: = ["kopi", "makan", "roket", "bintang"]


func _ready() -> void :

	theme = TENANG.tema_emas()
	process_mode = Node.PROCESS_MODE_ALWAYS
	color = Color(0.02, 0.03, 0.06, 0.78)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 120
	var tengah: = CenterContainer.new()
	tengah.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(tengah)
	var kartu: = PanelContainer.new()
	kartu.add_theme_stylebox_override("panel", GH.bingkai_emas(Vector4(24, 18, 24, 20)))

	kartu.custom_minimum_size = Vector2(minf(1120.0, get_viewport_rect().size.x - 40.0), 0)
	tengah.add_child(kartu)
	var isi: = VBoxContainer.new()
	isi.add_theme_constant_override("separation", 12)
	kartu.add_child(isi)

	var kepala: = HBoxContainer.new()
	kepala.add_theme_constant_override("separation", 14)
	isi.add_child(kepala)
	kepala.add_child(_ikon("hati", BIRU_TERANG, 56))
	var kolom_kepala: = VBoxContainer.new()
	kolom_kepala.add_theme_constant_override("separation", 2)
	kolom_kepala.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	kepala.add_child(kolom_kepala)
	var judul: = Label.new()
	judul.text = "Dukung Kami"
	judul.theme_type_variation = &"LabelKepala"
	judul.add_theme_font_size_override("font_size", 34)
	judul.add_theme_color_override("font_color", GH.EMAS)
	kolom_kepala.add_child(judul)
	var ket: = Label.new()
	ket.text = "Warung Life dibuat oleh tim kecil NeoPaw Studio. Dukungan ini sukarela dan sangat berarti untuk kami."
	ket.theme_type_variation = &"LabelRedup"
	ket.add_theme_font_size_override("font_size", 16)
	ket.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ket.custom_minimum_size.x = 0
	kolom_kepala.add_child(ket)

	var hadiah: = _pita("Hadiah untuk pendukung: ucapan terima kasih dari kami di genteng warungmu + gelar ★ Warga Baik Hati atau ★ Warga Peduli di papan peringkat", EMAS)
	isi.add_child(hadiah)

	if not GameState.aturan_rilis_aktif():
		isi.add_child(_pita("Khusus masa uji coba: pendukung tetap melanjutkan progres simpanannya saat game rilis. Pemain lain mulai lagi dari awal.", Color(0.5, 0.9, 0.6)))

	var grid: = GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	isi.add_child(grid)
	for i in PRODUK.size():
		grid.add_child(_kartu_produk(i))
	isi.add_child(_contoh_gelar())

	if OS.get_name() != "iOS":
		var tips: = Label.new()
		tips.text = "Tips: bayar pakai pulsa, e-wallet (GoPay/DANA/OVO/ShopeePay), atau kartu supaya langsung aktif. Kalau memilih QRIS, transfer bank, atau bayar di minimarket, selesaikan pembayarannya dulu sebelum batas waktu, kalau tidak Google membatalkannya otomatis."
		tips.add_theme_font_size_override("font_size", 15)
		tips.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		tips.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tips.custom_minimum_size.x = 600
		isi.add_child(tips)
	_pesan = Label.new()
	_pesan.add_theme_font_size_override("font_size", 17)
	_pesan.add_theme_color_override("font_color", EMAS)
	_pesan.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_pesan.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_pesan.custom_minimum_size.x = 600
	isi.add_child(_pesan)
	var b: Array = TENANG.bagian("Kode pendukung")
	(b[0] as PanelContainer).add_theme_stylebox_override("panel", TENANG.kotak(NAVY_KARTU, 16, Vector4(16, 12, 16, 14), 1, BIRU_BANK))
	isi.add_child(b[0])
	_kotak_kode = VBoxContainer.new()
	_kotak_kode.add_theme_constant_override("separation", 8)
	b[1].add_child(_kotak_kode)
	_perbarui_kode()
	var tutup: = Button.new()
	tutup.text = "Tutup"
	tutup.theme_type_variation = &"TombolUtama"
	tutup.custom_minimum_size = Vector2(0, 56)
	tutup.add_theme_font_size_override("font_size", 22)
	tutup.pressed.connect( func():
		ditutup.emit()
		queue_free())
	isi.add_child(tutup)
	GameState.pesan_toko.connect(_tampilkan)
	GameState.harga_produk_berubah.connect(_perbarui_harga)
	GameState.dukungan_diterima.connect(_on_dukungan_diterima)
	GameState.kode_pendukung_berubah.connect(_perbarui_kode)
	_perbarui_harga()
	_pasang_gulir.call_deferred(kartu, isi, tutup)



func _kartu_produk(i: int) -> Button:
	var p: Array = PRODUK[i]
	var warna: Color = WARNA_TINGKAT[i]
	var b: = Button.new()
	b.custom_minimum_size = Vector2(240, 262)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var dasar: = NAVY_KARTU
	b.add_theme_stylebox_override("normal", TENANG.kotak(dasar, 16, Vector4(0, 0, 0, 0), 2, warna, 5))
	b.add_theme_stylebox_override("hover", TENANG.kotak(dasar.lightened(0.06), 16, Vector4(0, 0, 0, 0), 2, warna.lightened(0.1), 5))
	b.add_theme_stylebox_override("pressed", TENANG.kotak(dasar.darkened(0.1), 16, Vector4(0, 0, 0, 0), 2, warna, 2))
	b.add_theme_stylebox_override("hover_pressed", b.get_theme_stylebox("pressed"))
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	var tepi: = MarginContainer.new()
	tepi.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tepi.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for sisi in ["left", "right"]:
		tepi.add_theme_constant_override("margin_" + sisi, 14)
	tepi.add_theme_constant_override("margin_top", 10)
	tepi.add_theme_constant_override("margin_bottom", 14)
	b.add_child(tepi)
	var v: = VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tepi.add_child(v)
	var ikon: = _ikon_gambar(i, warna, 80)
	ikon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(ikon)
	var j: = Label.new()
	j.text = p[1]
	j.add_theme_font_size_override("font_size", 18)
	j.add_theme_color_override("font_color", Color.WHITE)
	j.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(j)
	var k: = Label.new()
	k.text = String(p[2]).replace(". Bonus: bebas iklan", "")
	k.theme_type_variation = &"LabelRedup"
	k.add_theme_font_size_override("font_size", 13)
	k.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	k.custom_minimum_size.x = 200
	k.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(k)
	var bawah: = VBoxContainer.new()
	bawah.add_theme_constant_override("separation", 4)
	bawah.alignment = BoxContainer.ALIGNMENT_CENTER
	bawah.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(bawah)
	var harga: = Label.new()
	harga.text = String(HARGA_CADANGAN_IOS.get(p[0], p[3])) if OS.get_name() == "iOS" else p[3]
	harga.add_theme_font_size_override("font_size", 20)
	harga.add_theme_font_override("font", load("res://scripts/gaya_hud.gd").cetak())
	harga.add_theme_color_override("font_color", EMAS)
	harga.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bawah.add_child(harga)
	_label_harga[p[0]] = harga

	var gelar: = PP.pita_gelar(13, p[0] == "dukung_game_100")
	gelar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	bawah.add_child(gelar)
	if p[0] in GameState.PRODUK_DUKUNGAN_BEBAS_IKLAN:
		var bonus: = _pita("BONUS BEBAS IKLAN", Color(0.5, 0.9, 0.6), 12)
		bonus.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		bawah.add_child(bonus)
	var id: String = p[0]
	b.pressed.connect( func(): _beli(id))
	return b



func _contoh_gelar() -> Control:
	var kotak: = PanelContainer.new()
	kotak.mouse_filter = Control.MOUSE_FILTER_IGNORE
	kotak.add_theme_stylebox_override("panel", TENANG.kotak(NAVY_KARTU, 16, Vector4(16, 12, 16, 12), 1, BIRU_BANK))
	var v: = VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	kotak.add_child(v)
	var judul: = Label.new()
	judul.text = "Gelar di papan peringkat untuk yang mendukung (termasuk pembeli Tanpa Iklan):"
	judul.add_theme_font_size_override("font_size", 15)
	judul.add_theme_color_override("font_color", Color.WHITE)
	judul.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	judul.custom_minimum_size.x = 400
	v.add_child(judul)
	for peduli in [false, true]:
		var baris: = HBoxContainer.new()
		baris.add_theme_constant_override("separation", 10)
		v.add_child(baris)
		var nama: = Label.new()
		nama.text = GameState.nama_warung_lengkap() if GameState.nama_warung != "" else "Warung Kamu"
		nama.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
		nama.add_theme_font_override("font", load("res://scripts/gaya_hud.gd").cetak())
		nama.add_theme_font_size_override("font_size", 20)
		nama.add_theme_color_override("font_color", Color.WHITE if peduli else PP.WARNA_NAMA_PENDUKUNG)
		nama.add_theme_color_override("font_outline_color", Color(0.02, 0.05, 0.12, 0.9))
		nama.add_theme_constant_override("outline_size", 6)
		if peduli:
			nama.material = PP.bahan_platinum(260.0)
		baris.add_child(nama)
		baris.add_child(PP.pita_gelar(13, peduli))
		var ket: = Label.new()
		ket.text = "Dukungan besar: nama platinum berkilau." if peduli else "Semua dukungan: nama warung berwarna emas."
		ket.theme_type_variation = &"LabelRedup"
		ket.add_theme_font_size_override("font_size", 13)
		ket.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		ket.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		ket.custom_minimum_size.x = 120
		baris.add_child(ket)
	return kotak



func _pita(teks: String, warna: Color, ukuran: = 15) -> PanelContainer:
	var p: = PanelContainer.new()
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_theme_stylebox_override("panel", TENANG.kotak(Color(warna, 0.14), 10, Vector4(12, 5, 12, 6), 1, Color(warna, 0.45)))
	var l: = Label.new()
	l.text = teks
	l.add_theme_font_size_override("font_size", ukuran)
	l.add_theme_color_override("font_color", warna.lightened(0.15))
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART if ukuran > 13 else TextServer.AUTOWRAP_OFF
	l.custom_minimum_size.x = 0
	p.add_child(l)
	return p






const GAMBAR_TINGKAT: = [
	["res://assets/ui/dukung_kopi.png"], 
	["res://assets/ui/dukung_makan.png"], 
	["res://assets/ui/dukung_bintang.png"], 
	["res://assets/ui/logo_studio.png"], 
]

func _ikon_gambar(i: int, warna: Color, ukuran: float) -> Control:
	var c: = Control.new()
	c.custom_minimum_size = Vector2(ukuran, ukuran)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.draw.connect( func():
		var pusat: = c.size / 2.0
		c.draw_circle(pusat, ukuran * 0.5, Color(warna, 0.16))
		c.draw_circle(pusat, ukuran * 0.42, Color(warna, 0.3))
		c.draw_arc(pusat, ukuran * 0.42, 0.0, TAU, 40, Color(warna.lightened(0.3), 0.7), 2.0, true))
	var berkas: Array = GAMBAR_TINGKAT[i]
	for n in berkas.size():
		if not ResourceLoader.exists(berkas[n]):
			continue
		var g: = TextureRect.new()
		g.texture = load(berkas[n])
		g.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		g.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		g.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var besar: = ukuran * (1.08 if berkas.size() == 1 else 0.72)
		g.size = Vector2(besar, besar)
		g.pivot_offset = g.size / 2.0
		var geser: = Vector2.ZERO if berkas.size() == 1 else Vector2((n - 0.5) * ukuran * 0.36, (0.5 - n) * ukuran * 0.08)
		g.position = (Vector2(ukuran, ukuran) - g.size) / 2.0 + geser
		g.rotation_degrees = 0.0 if berkas.size() == 1 else (-10.0 if n == 0 else 10.0)
		c.add_child(g)
	return c



func _ikon(jenis: String, warna: Color, ukuran: float) -> Control:
	var c: = Control.new()
	c.custom_minimum_size = Vector2(ukuran, ukuran)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.draw.connect(_gambar_ikon.bind(c, jenis, warna))
	return c


func _gambar_ikon(c: Control, jenis: String, warna: Color) -> void :
	var u: = c.size.x
	var pusat: = c.size / 2.0
	c.draw_circle(pusat, u / 2.0, Color(warna, 0.22))
	c.draw_circle(pusat, u / 2.0 - 3.0, Color(warna, 0.35))
	var putih: = Color(1, 1, 1, 0.95)
	match jenis:
		"hati":
			var r: = u * 0.15
			c.draw_circle(pusat + Vector2( - r * 0.95, - r * 0.4), r, putih)
			c.draw_circle(pusat + Vector2(r * 0.95, - r * 0.4), r, putih)
			c.draw_colored_polygon(PackedVector2Array([pusat + Vector2( - r * 2.0, - r * 0.1), pusat + Vector2(r * 2.0, - r * 0.1), pusat + Vector2(0, r * 2.2)]), putih)
		"kopi":
			c.draw_rect(Rect2(pusat + Vector2( - u * 0.18, - u * 0.12), Vector2(u * 0.3, u * 0.3)), putih)
			c.draw_arc(pusat + Vector2(u * 0.14, u * 0.03), u * 0.08, - PI / 2, PI / 2, 8, putih, 3.0)
			for x in [-0.08, 0.02]:
				c.draw_line(pusat + Vector2(u * x, - u * 0.2), pusat + Vector2(u * (x + 0.03), - u * 0.3), putih, 2.0)
		"makan":
			c.draw_arc(pusat + Vector2(0, - u * 0.02), u * 0.24, 0, PI, 16, putih, 4.0)
			c.draw_line(pusat + Vector2( - u * 0.28, - u * 0.02), pusat + Vector2(u * 0.28, - u * 0.02), putih, 4.0)
			c.draw_circle(pusat + Vector2(0, - u * 0.1), u * 0.06, putih)
		"roket":
			c.draw_colored_polygon(PackedVector2Array([pusat + Vector2(0, - u * 0.3), pusat + Vector2(u * 0.12, - u * 0.05), pusat + Vector2(u * 0.12, u * 0.18), pusat + Vector2( - u * 0.12, u * 0.18), pusat + Vector2( - u * 0.12, - u * 0.05)]), putih)
			c.draw_colored_polygon(PackedVector2Array([pusat + Vector2( - u * 0.12, u * 0.05), pusat + Vector2( - u * 0.22, u * 0.22), pusat + Vector2( - u * 0.12, u * 0.18)]), putih)
			c.draw_colored_polygon(PackedVector2Array([pusat + Vector2(u * 0.12, u * 0.05), pusat + Vector2(u * 0.22, u * 0.22), pusat + Vector2(u * 0.12, u * 0.18)]), putih)
			c.draw_circle(pusat + Vector2(0, - u * 0.04), u * 0.05, Color(warna, 0.9))
		"bintang":
			var titik: = PackedVector2Array()
			for n in 10:
				var sudut: = - PI / 2 + n * PI / 5
				var rr: = u * (0.3 if n % 2 == 0 else 0.13)
				titik.append(pusat + Vector2(cos(sudut), sin(sudut)) * rr)
			c.draw_colored_polygon(titik, putih)



func _pasang_gulir(kartu: PanelContainer, isi: VBoxContainer, tutup: Button) -> void :
	var gaya: = kartu.get_theme_stylebox("panel")
	var tepi: = gaya.get_margin(SIDE_TOP) + gaya.get_margin(SIDE_BOTTOM) if gaya != null else 40.0
	var maks: = get_viewport_rect().size.y - 24.0 - tepi - tutup.get_combined_minimum_size().y - 10.0
	isi.remove_child(tutup)
	var tinggi: = isi.get_combined_minimum_size().y
	var luar: = VBoxContainer.new()
	luar.add_theme_constant_override("separation", 10)
	var gulir: ScrollContainer = load("res://scripts/hp/gulir_sentuh.gd").new()
	gulir.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	gulir.scroll_deadzone = 8
	kartu.remove_child(isi)
	kartu.add_child(luar)
	luar.add_child(gulir)
	gulir.add_child(isi)
	isi.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	luar.add_child(tutup)
	gulir.custom_minimum_size = Vector2(isi.get_combined_minimum_size().x, minf(tinggi, maxf(maks, 200.0)))


func _perbarui_harga() -> void :
	for id in _label_harga:
		if String(GameState.harga_produk.get(id, "")) != "":
			_label_harga[id].text = GameState.harga_produk[id]


func _beli(id: String) -> void :
	GameState.klik()
	GameState.beli_dukungan(id)


func _on_dukungan_diterima() -> void :
	GameState.bunyi("hadiah")
	_tampilkan("Terima kasih banyak atas dukunganmu! Lihat genteng warungmu: ada ucapan terima kasih dari tim NeoPaw Studio.")



func _perbarui_kode() -> void :
	if not is_instance_valid(_kotak_kode):
		return
	for anak in _kotak_kode.get_children():
		anak.queue_free()
	var ket: = Label.new()
	ket.add_theme_font_size_override("font_size", 16)
	ket.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ket.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ket.custom_minimum_size.x = 580
	_kotak_kode.add_child(ket)
	if GameState.kode_pendukung != "":
		ket.text = "Kode pendukungmu: %s\nSimpan kode ini. Kalau game dipasang ulang atau pindah HP, ketik di sini supaya ucapan di genteng kembali dan progres uji coba bisa dilanjutkan saat rilis." % GameState.kode_pendukung
		if GameState.aturan_rilis_aktif():
			ket.text = "Kode pendukungmu: %s\nSimpan kode ini. Kalau game dipasang ulang atau pindah HP, ketik di sini supaya ucapan di genteng kembali." % GameState.kode_pendukung
		var salin: = Button.new()
		salin.text = "Salin kode"
		salin.theme_type_variation = &"TombolKayu"
		salin.custom_minimum_size = Vector2(0, 50)
		salin.add_theme_font_size_override("font_size", 20)
		salin.pressed.connect( func():
			GameState.klik()
			DisplayServer.clipboard_set(GameState.kode_pendukung)
			_tampilkan("Kode pendukung sudah disalin."))
		_kotak_kode.add_child(salin)
		if GameState.ada_arsip_uji():
			var pulih: = Button.new()
			pulih.text = "Lanjutkan progres uji coba"
			pulih.theme_type_variation = &"TombolHijau"
			pulih.custom_minimum_size = Vector2(0, 54)
			pulih.add_theme_font_size_override("font_size", 20)
			pulih.pressed.connect( func():
				GameState.klik()
				if GameState.pulihkan_arsip_uji():
					_tampilkan("Progres uji coba sudah dikembalikan. Buka dari menu utama (Lanjutkan / Load Save).")
					_perbarui_kode())
			_kotak_kode.add_child(pulih)
		return
	if GameState.pendukung:
		ket.text = "Kode pendukungmu sedang dibuat. Pastikan internet menyala, lalu buka jendela ini lagi."
		return
	ket.text = "Sudah pernah mendukung? Ketik kode pendukungmu:"
	var baris: = HBoxContainer.new()
	baris.add_theme_constant_override("separation", 8)
	_kotak_kode.add_child(baris)
	var kolom: = LineEdit.new()
	kolom.placeholder_text = "NPW-XXXX-XXXX"
	kolom.max_length = 16
	kolom.custom_minimum_size = Vector2(0, 50)
	kolom.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	kolom.add_theme_font_size_override("font_size", 20)
	baris.add_child(kolom)
	var pakai: = Button.new()
	pakai.text = "Pakai kode"
	pakai.theme_type_variation = &"TombolKayu"
	pakai.custom_minimum_size = Vector2(170, 50)
	pakai.add_theme_font_size_override("font_size", 20)
	pakai.pressed.connect( func():
		GameState.klik()
		pakai.disabled = true
		_tampilkan("Memeriksa kode...")
		var alasan: String = await GameState.pakai_kode_pendukung(kolom.text)
		if not is_instance_valid(pakai):
			return
		pakai.disabled = false
		if alasan != "":
			_tampilkan(alasan))
	baris.add_child(pakai)


func _tampilkan(teks: String) -> void :
	_pesan.text = teks


func _exit_tree() -> void :
	GameState.pesan_toko.disconnect(_tampilkan)
	GameState.harga_produk_berubah.disconnect(_perbarui_harga)
	GameState.dukungan_diterima.disconnect(_on_dukungan_diterima)
	if GameState.kode_pendukung_berubah.is_connected(_perbarui_kode):
		GameState.kode_pendukung_berubah.disconnect(_perbarui_kode)
