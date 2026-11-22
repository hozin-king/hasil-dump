extends PanelContainer





const WARNA_TEKS: = Color(0.23, 0.14, 0.08)
const WARNA_GAGAL: = Color(0.7, 0.15, 0.12)
const WARNA_BERHASIL: = Color(0.15, 0.45, 0.2)
const JUMLAH_ISI_SALDO: = 50000
const PILIHAN_JUMLAH: = [1, 5]

var label_info: = {}
var kartu_barang: = {}
var tombol_beli: Array = []
var label_harga: = {}

@onready var grid: GridContainer = %GridBelanja
@onready var label_uang: Label = %LabelUangBelanja
@onready var label_saldo: Label = %LabelSaldoBelanja
@onready var pesan: Label = %PesanBelanja
@onready var tombol_isi_saldo: Button = %TombolIsiSaldo
@onready var tombol_selesai: Button = %TombolSelesaiBelanja


func _ready() -> void :

	var gulir: ScrollContainer = load("res://scripts/hp/gulir_sentuh.gd").new()
	gulir.custom_minimum_size = Vector2(0, 400)
	gulir.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var induk: = grid.get_parent()
	induk.add_child(gulir)
	induk.move_child(gulir, grid.get_index())
	grid.reparent(gulir)
	for id in GameState.barang_belanja():
		grid.add_child(_buat_kartu(id))
	tombol_isi_saldo.text = "Isi saldo +%s" % GameState.format_rupiah(JUMLAH_ISI_SALDO)
	tombol_isi_saldo.pressed.connect(_on_isi_saldo_ditekan)
	tombol_selesai.pressed.connect(hide)
	GameState.data_berubah.connect(_perbarui)
	visibility_changed.connect(_on_visibility_changed)
	_perbarui()


func _buat_kartu(id: String) -> Control:
	var b: = GameState.data_barang(id)

	var bingkai: = PanelContainer.new()
	bingkai.theme_type_variation = &"KartuBarang"
	bingkai.custom_minimum_size = Vector2(570, 0)
	var kartu: = HBoxContainer.new()
	kartu.add_theme_constant_override("separation", 10)
	bingkai.add_child(kartu)

	var ikon: = TextureRect.new()
	ikon.texture = load("res://assets/barang/%s.png" % id)
	ikon.custom_minimum_size = Vector2(62, 62)
	ikon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ikon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	kartu.add_child(ikon)

	var teks: = VBoxContainer.new()
	teks.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	teks.alignment = BoxContainer.ALIGNMENT_CENTER


	var nama: = _label(b["nama"], 22)
	nama.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	teks.add_child(nama)
	var info: = _label("", 18)
	info.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	teks.add_child(info)
	label_info[id] = info

	var baris_harga: = HBoxContainer.new()
	baris_harga.add_theme_constant_override("separation", 6)
	teks.add_child(baris_harga)
	for arah in [-1, 1]:
		var t: = Button.new()
		t.text = "−" if arah < 0 else "+"
		t.theme_type_variation = &"TombolKayu"
		t.custom_minimum_size = Vector2(40, 34)
		t.add_theme_font_size_override("font_size", 20)
		t.pressed.connect( func(): GameState.ubah_harga_jual(id, arah))
		if arah < 0:
			baris_harga.add_child(t)
			var l: = _label("", 18)
			l.custom_minimum_size.x = 210
			l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			baris_harga.add_child(l)
			label_harga[id] = l
		else:
			baris_harga.add_child(t)
	kartu.add_child(teks)

	for jumlah in PILIHAN_JUMLAH:
		var tombol: = Button.new()
		tombol.text = "+%d" % jumlah
		tombol.custom_minimum_size = Vector2(78, 58)
		tombol.theme_type_variation = &"TombolHijau"
		tombol.add_theme_font_size_override("font_size", 26)

		tombol.pressed.connect(_on_beli_ditekan.bind(id, jumlah))
		kartu.add_child(tombol)
		tombol_beli.append([id, tombol])
	kartu_barang[id] = bingkai
	return bingkai


func _label(teks: String, ukuran: int) -> Label:
	var label: = Label.new()
	label.text = teks
	label.add_theme_font_size_override("font_size", ukuran)
	label.add_theme_color_override("font_color", WARNA_TEKS)
	return label


func _perbarui() -> void :
	label_uang.text = GameState.format_rupiah(GameState.uang)
	label_saldo.text = "Saldo layanan (e-wallet dan paket data): %s" % GameState.format_rupiah(GameState.saldo_layanan)
	for id in label_info:
		var b: = GameState.data_barang(id)
		if GameState.terbuka(id):
			var dikirim: = GameState.jumlah_kiriman(id)
			label_info[id].text = "Stok %d%s  ·  modal %s" % [GameState.stok[id], ("  (+%d dikirim)" % dikirim) if dikirim > 0 else "", GameState.format_rupiah(GameState.harga_modal(id))]
			var rasio: = GameState.rasio_harga(id)
			label_harga[id].text = "Jual %s%s" % [GameState.format_rupiah(GameState.harga_jual(id)), "" if is_equal_approx(rasio, 1.0) else ("  (%s%d%%)" % ["+" if rasio > 1.0 else "", int(round((rasio - 1.0) * 100))])]
			label_harga[id].add_theme_color_override("font_color", WARNA_TEKS)
		else:
			label_info[id].text = "Terkunci · " + GameState.cara_buka_barang(id)
		kartu_barang[id].modulate.a = 1.0 if GameState.terbuka(id) else 0.5
	for pasangan in tombol_beli:
		pasangan[1].disabled = not GameState.terbuka(pasangan[0])

	var urut: = GameState.barang_belanja().filter(GameState.terbuka) + GameState.barang_belanja().filter( func(id): return not GameState.terbuka(id))
	for i in urut.size():
		grid.move_child(kartu_barang[urut[i]], i)


func _on_beli_ditekan(id: String, jumlah: int) -> void :
	var alasan: = GameState.beli_stok(id, jumlah)
	if alasan != "":
		_tampilkan_pesan(alasan, WARNA_GAGAL)
	else:
		var b: = GameState.data_barang(id)
		_tampilkan_pesan("Dipesan %d %s (−%s). Barang diantar kurir sekitar 20 detik lagi." % [jumlah, b["nama"].to_lower(), GameState.format_rupiah(GameState.harga_modal(id) * jumlah)], WARNA_BERHASIL)


func _on_isi_saldo_ditekan() -> void :
	var alasan: = GameState.isi_saldo_layanan(JUMLAH_ISI_SALDO)
	if alasan != "":
		_tampilkan_pesan(alasan, WARNA_GAGAL)
	else:
		_tampilkan_pesan("Saldo layanan bertambah %s." % GameState.format_rupiah(JUMLAH_ISI_SALDO), WARNA_BERHASIL)


func _tampilkan_pesan(teks: String, warna: Color) -> void :
	pesan.text = teks
	pesan.add_theme_color_override("font_color", warna)


func _on_visibility_changed() -> void :
	if visible:
		pesan.text = ""
		_perbarui()
