extends Control






signal selesai(total: int)

const GH: = preload("res://scripts/gaya_hud.gd")
const KREM: = Color(0.97, 0.92, 0.8)
const COKLAT: = Color(0.32, 0.2, 0.1)
const OBROLAN: = [
	"Mangga, Pak Misran. Harga grosir hari ini sudah saya tulis, silakan dibandingkan sendiri.", 
	"Barang saya ambil langsung dari gudang kota, Pak. Ada yang murah, ada yang lagi naik.", 
	"Belanja di sini tidak usah nunggu kurir, Pak. Masukkan tas, bawa pulang, langsung dipajang.", 
	"Harga tiap hari lain-lain, Pak. Rajin-rajin cek ke pasar, kadang dapat murah.", 
	"Barang yang lagi promo sales, saya tidak jual dulu, Pak. Kalah murah, hehe.", 
	"Tasnya jangan dipenuhi ikan semua, Pak. Nanti belanjaan grosirnya tidak muat.", 
]

var _nama: = ""
var _daftar: VBoxContainer
var _label_tas: Label
var _pesan: Label
var _total: = 0

var _dibeli: = {}


func _init(nama_penjual: = "Haji Maman") -> void :
	_nama = nama_penjual


func _ready() -> void :
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 150
	var gelap: = ColorRect.new()
	gelap.color = Color(0, 0, 0, 0.55)
	gelap.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(gelap)
	var tengah: = CenterContainer.new()
	tengah.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(tengah)
	var kartu: = GH.panel_emas(Vector4(30, 20, 30, 20))
	kartu.custom_minimum_size = Vector2(860, 0)
	tengah.add_child(kartu)
	var kolom: = VBoxContainer.new()
	kolom.add_theme_constant_override("separation", 10)
	kartu.add_child(kolom)
	var judul: = GH.label("GROSIR %s" % GameState.tk(_nama).to_upper(), 36, GH.KUNING, true)
	GH.pita_emas(judul, 30)
	kolom.add_child(judul)
	var sapa: = GH.label("\"%s\"" % GameState.tk(OBROLAN.pick_random()), 19, Color.WHITE)
	sapa.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sapa.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sapa.custom_minimum_size = Vector2(800, 0)
	kolom.add_child(sapa)
	_label_tas = GH.label("", 20, Color(1, 0.93, 0.78))
	_label_tas.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	kolom.add_child(_label_tas)
	var gulir: ScrollContainer = load("res://scripts/hp/gulir_sentuh.gd").new()
	gulir.scroll_deadzone = 8
	gulir.custom_minimum_size = Vector2(0, clampf(get_viewport_rect().size.y - 360.0, 200.0, 420.0))
	gulir.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	kolom.add_child(gulir)
	_daftar = VBoxContainer.new()
	_daftar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_daftar.add_theme_constant_override("separation", 8)
	gulir.add_child(_daftar)
	_pesan = GH.label("", 19, GH.KUNING)
	_pesan.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_pesan.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_pesan.custom_minimum_size = Vector2(800, 0)
	_pesan.text = "Barang masuk Tas (1 kotak = 10 barang). Begitu masuk warung, langsung jadi stok."
	kolom.add_child(_pesan)
	var tutup: = Button.new()
	tutup.text = "Tutup"
	GH.gaya_tombol_emas(tutup, false, 26)
	tutup.custom_minimum_size = Vector2(200, 60)
	tutup.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	tutup.pressed.connect( func():
		selesai.emit(_total)
		queue_free())
	kolom.add_child(tutup)
	_isi_daftar()
	kartu.pivot_offset = Vector2(430, 260)
	kartu.scale = Vector2.ONE * 0.9
	create_tween().tween_property(kartu, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _isi_daftar() -> void :
	for anak in _daftar.get_children():
		anak.queue_free()
	var gs: = GameState
	_label_tas.text = "Tas: %d/%d kotak terisi · Uang: %s" % [gs.kotak_tas_terpakai(), gs.KOTAK_TAS, gs.format_rupiah(gs.uang)]
	var barang: Array = gs.barang_grosir()
	if barang.is_empty():
		var kosong: = GH.label("Belum ada barang grosir untuk warung Bapak hari ini.", 20, Color(0.9, 0.9, 0.9))
		kosong.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_daftar.add_child(kosong)
	for b in barang:
		_daftar.add_child(_baris(String(b["id"]), int(b["harga"])))


func _baris(id: String, harga: int) -> Control:
	var gs: = GameState
	var kotak: = PanelContainer.new()
	var g: = StyleBoxFlat.new()
	g.bg_color = KREM
	g.set_corner_radius_all(14)
	g.content_margin_left = 12
	g.content_margin_right = 12
	g.content_margin_top = 6
	g.content_margin_bottom = 6
	kotak.add_theme_stylebox_override("panel", g)
	var baris: = HBoxContainer.new()
	baris.add_theme_constant_override("separation", 12)
	kotak.add_child(baris)
	var ikon: = TextureRect.new()
	var jalur: = "res://assets/barang/%s.png" % id
	if ResourceLoader.exists(jalur):
		ikon.texture = load(jalur)
	ikon.custom_minimum_size = Vector2(56, 56)
	ikon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ikon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	baris.add_child(ikon)
	var teks: = VBoxContainer.new()
	teks.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	teks.alignment = BoxContainer.ALIGNMENT_CENTER
	teks.add_theme_constant_override("separation", 0)
	baris.add_child(teks)
	var nama: = GH.label("%s · %s" % [String(gs.data_barang(id)["nama"]), gs.format_rupiah(harga)], 23, COKLAT, true, 0)
	nama.add_theme_color_override("font_color", COKLAT)
	teks.add_child(nama)
	var ket: = GH.label("Stok warung %d/%d · di Tas %d" % [int(gs.stok.get(id, 0)), gs.MAKS_STOK_BARANG, int(gs.tas_grosir.get(id, 0))], 17, COKLAT, false, 0)
	ket.add_theme_color_override("font_color", COKLAT.lightened(0.2))
	teks.add_child(ket)

	var sudah: = int((_dibeli.get(id, [0, 0]) as Array)[0])
	if sudah > 0:
		var bt: = Button.new()
		bt.text = "Batal 1"
		GH.gaya_tombol(bt, false, 20)
		bt.custom_minimum_size = Vector2(110, 52)
		bt.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		bt.pressed.connect( func(): _batal(id))
		baris.add_child(bt)
	for n in [1, 5]:
		var b: = Button.new()
		b.text = "+%d" % n
		GH.gaya_tombol(b, n == 5, 24)
		b.custom_minimum_size = Vector2(96, 52)
		b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		b.disabled = gs.alasan_tidak_bisa_grosir(id, n) != ""
		b.pressed.connect( func(): _beli(id, n))
		baris.add_child(b)
	return kotak


func _beli(id: String, n: int) -> void :
	var biaya: = GameState.harga_grosir(id) * n
	var alasan: = GameState.beli_grosir(id, n)
	if alasan != "":
		_pesan.text = alasan
		GameState.bunyi("salah")
		return
	_total += biaya
	var catat: Array = _dibeli.get(id, [0, GameState.harga_grosir(id)])
	_dibeli[id] = [int(catat[0]) + n, GameState.harga_grosir(id)]
	GameState.bunyi("koin")
	_pesan.text = "Masuk Tas: %d %s (%s). Total belanja grosir: %s." % [n, String(GameState.data_barang(id)["nama"]).to_lower(), GameState.format_rupiah(biaya), GameState.format_rupiah(_total)]
	_isi_daftar()


func _batal(id: String) -> void :
	var catat: Array = _dibeli.get(id, [0, 0])
	if int(catat[0]) <= 0:
		return
	var alasan: = GameState.batal_grosir(id, 1, int(catat[1]))
	if alasan != "":
		_pesan.text = alasan
		GameState.bunyi("salah")
		return
	_dibeli[id] = [int(catat[0]) - 1, int(catat[1])]
	_total -= int(catat[1])
	GameState.klik()
	_pesan.text = "Dikembalikan ke %s: 1 %s (%s kembali). Total belanja grosir: %s." % [GameState.tk(_nama), String(GameState.data_barang(id)["nama"]).to_lower(), GameState.format_rupiah(int(catat[1])), GameState.format_rupiah(_total)]
	_isi_daftar()
