extends VBoxContainer







const UI: = preload("res://scripts/hp/hp_ui.gd")
const KB: = preload("res://scripts/konfirmasi_bayar.gd")
const WARNA: = Color(0.95, 0.5, 0.15)
const WARNA_HIJAU: = Color(0.2, 0.62, 0.3)
const WARNA_KURANG: = Color(0.62, 0.5, 0.4)
const JUMLAH_ISI_SALDO: = 50000

var hp: Control
var _label_uang: Label
var _label_kurir: Label
var _bar_kurir: ProgressBar
var _kotak_kurir: PanelContainer
var _tab_tombol: = {}
var _halaman: = {}
var _grid: GridContainer
var _daftar_harga: VBoxContainer
var _label_saldo: Label
var _pesan: Label
var _kartu: = {}
var _stok: = {}
var _modal: = {}
var _promo: = {}
var _jumlah: = {}
var _tombol: = {}
var _baris_harga: = {}
var _harga: = {}
var _tombol_harga: = {}
var _keranjang: = {}
var _label_total: Label
var _tombol_beli: Button
var _tombol_kurir: = {}
var _ket_kurir: = {}
var _ikon_keranjang: Control
var tombol_lengkapi: Button
var _tombol_kosongkan: Button

const BATAS_FILTER_STOK: = 5
var _baris_filter: HBoxContainer
var _tombol_filter: = {}
var _filter: = {"stok": false, "diskon": false}
var _label_filter_kosong: Label


func _ready() -> void :
	add_theme_constant_override("separation", 0)

	var kepala: = UI.kepala("Belanja Online", WARNA)
	var gaya_kepala: = kepala.get_theme_stylebox("panel") as StyleBoxFlat
	gaya_kepala.content_margin_left = 10
	gaya_kepala.content_margin_right = 10
	gaya_kepala.content_margin_top = 3
	gaya_kepala.content_margin_bottom = 3
	var baris_kepala: = kepala.get_child(0) as HBoxContainer
	(baris_kepala.get_child(0) as Label).add_theme_font_size_override("font_size", 20)
	add_child(kepala)

	var atas: = UI.panel(Color(1, 0.93, 0.85), 0, 5)
	add_child(atas)
	var kolom_atas: = VBoxContainer.new()
	kolom_atas.add_theme_constant_override("separation", 4)
	atas.add_child(kolom_atas)
	_label_uang = UI.label("", 13)
	_label_uang.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	baris_kepala.add_child(_label_uang)
	_kotak_kurir = UI.panel(Color.WHITE, 6, 4)
	kolom_atas.add_child(_kotak_kurir)
	tombol_lengkapi = UI.tombol("Lengkapi stok (min. %d tiap barang)" % GameState.MIN_STOK_BUKA, Color(0.85, 0.45, 0.1), 13, 32)
	tombol_lengkapi.pressed.connect(_lengkapi_stok)
	kolom_atas.add_child(tombol_lengkapi)
	var kolom_kurir: = HBoxContainer.new()
	kolom_kurir.add_theme_constant_override("separation", 8)
	_kotak_kurir.add_child(kolom_kurir)
	_label_kurir = UI.label("", 11)
	_label_kurir.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_label_kurir.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_label_kurir.custom_minimum_size.x = 40
	kolom_kurir.add_child(_label_kurir)
	_bar_kurir = ProgressBar.new()
	_bar_kurir.show_percentage = false
	_bar_kurir.custom_minimum_size = Vector2(150, 6)
	_bar_kurir.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_bar_kurir.add_theme_stylebox_override("background", UI.kotak(Color(0.9, 0.87, 0.82), 4, 0))
	_bar_kurir.add_theme_stylebox_override("fill", UI.kotak(WARNA, 4, 0))
	kolom_kurir.add_child(_bar_kurir)

	var tab: = HBoxContainer.new()
	tab.add_theme_constant_override("separation", 6)
	kolom_atas.add_child(tab)
	for t in [["belanja", "Belanja"], ["harga", "Harga Jual"]]:
		var b: = UI.tombol(t[1], WARNA, 14, 30)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.pressed.connect(_pilih_tab.bind(t[0]))
		tab.add_child(b)
		_tab_tombol[t[0]] = b


	var g: Array = UI.gulir(6)
	_halaman["belanja"] = _bungkus(g[0])
	var isi_belanja: VBoxContainer = g[1]

	tombol_lengkapi.reparent(isi_belanja)
	isi_belanja.move_child(tombol_lengkapi, 0)
	_baris_filter = HBoxContainer.new()
	_baris_filter.add_theme_constant_override("separation", 6)
	_baris_filter.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tab.add_child(_baris_filter)
	for f in [["stok", "Stok di bawah %d" % BATAS_FILTER_STOK], ["diskon", "Diskon"]]:
		var tf: = UI.tombol(f[1], WARNA, 12, 30)
		tf.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tf.pressed.connect(_ubah_filter.bind(f[0]))
		_baris_filter.add_child(tf)
		_tombol_filter[f[0]] = tf
	_label_filter_kosong = UI.label("Tidak ada barang yang cocok dengan filter.", 14, UI.WARNA_REDUP, true)
	_label_filter_kosong.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label_filter_kosong.hide()
	isi_belanja.add_child(_label_filter_kosong)
	_grid = GridContainer.new()
	_grid.columns = 2
	_grid.add_theme_constant_override("h_separation", 6)
	_grid.add_theme_constant_override("v_separation", 6)
	_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	isi_belanja.add_child(_grid)
	for id in GameState.barang_belanja():
		_grid.add_child(_buat_kartu(id))
	var kartu_saldo: = UI.panel(Color.WHITE, 10, 6)
	var baris_saldo: = HBoxContainer.new()
	kartu_saldo.add_child(baris_saldo)
	_label_saldo = UI.label("", 13, UI.WARNA_TEKS, true)
	_label_saldo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	baris_saldo.add_child(_label_saldo)
	var isi_saldo: = UI.tombol("Isi +50rb", Color(0.2, 0.55, 0.85), 13, 34)
	isi_saldo.pressed.connect(_isi_saldo)
	baris_saldo.add_child(isi_saldo)
	isi_belanja.add_child(kartu_saldo)


	var h: Array = UI.gulir(6)
	_halaman["harga"] = _bungkus(h[0])
	_daftar_harga = h[1]
	_daftar_harga.add_child(UI.label("Di atas harga yang disarankan, pelanggan mulai mengeluh mahal. Makin mahal, makin banyak yang mengeluh dan memberi bintang rendah.", 13, UI.WARNA_REDUP, true))
	for id in GameState.barang_belanja():
		_daftar_harga.add_child(_buat_baris_harga(id))


	var bawah: = UI.panel(Color(1, 0.9, 0.5), 0, 4)
	add_child(bawah)
	var baris_beli: = HBoxContainer.new()
	baris_beli.add_theme_constant_override("separation", 6)
	bawah.add_child(baris_beli)
	_ikon_keranjang = load("res://scripts/hp/ikon_keranjang.gd").new()
	_ikon_keranjang.custom_minimum_size = Vector2(44, 36)
	baris_beli.add_child(_ikon_keranjang)
	_label_total = UI.label("", 12)
	_label_total.custom_minimum_size.x = 108
	_label_total.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	baris_beli.add_child(_label_total)
	_pesan = UI.label("", 12, UI.WARNA_BERHASIL, true)
	_pesan.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_pesan.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_pesan.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	baris_beli.add_child(_pesan)
	_tombol_kosongkan = UI.tombol("Kosongkan", WARNA_KURANG, 12, 36)
	_tombol_kosongkan.custom_minimum_size.x = 80
	_tombol_kosongkan.pressed.connect( func(): _keranjang.clear();_pesan.text = "";_perbarui())
	baris_beli.add_child(_tombol_kosongkan)
	_tombol_beli = UI.tombol("Checkout", WARNA_HIJAU, 14, 36)
	_tombol_beli.custom_minimum_size.x = 92
	_tombol_beli.pressed.connect(_mulai_beli)
	baris_beli.add_child(_tombol_beli)

	_buat_halaman_checkout()
	_bagian_utama = [kepala, atas, _halaman["belanja"], _halaman["harga"], bawah]
	_pilih_tab("belanja")
	GameState.data_berubah.connect(_perbarui)



func atur_orientasi(landscape: bool) -> void :
	if _grid != null:
		_grid.columns = 4 if landscape else 2


func _bungkus(gulir: Control) -> Control:
	var tepi: = MarginContainer.new()
	tepi.size_flags_vertical = Control.SIZE_EXPAND_FILL
	for sisi in ["left", "right", "top", "bottom"]:
		tepi.add_theme_constant_override("margin_" + sisi, 8)
	tepi.add_child(gulir)
	add_child(tepi)
	return tepi


func _pilih_tab(nama: String) -> void :
	_tab_sekarang = nama
	for n in _halaman:
		_halaman[n].visible = n == nama

		_tab_tombol[n].modulate = Color.WHITE if n == nama else Color(1, 1, 1, 0.55)
	_terapkan_filter()



func _buat_kartu(id: String) -> Control:
	var b: = GameState.data_barang(id)
	var kartu: = UI.panel(Color.WHITE, 12, 6)
	kartu.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var kolom: = VBoxContainer.new()
	kolom.add_theme_constant_override("separation", 4)
	kartu.add_child(kolom)

	var atas: = HBoxContainer.new()
	atas.add_theme_constant_override("separation", 6)
	kolom.add_child(atas)
	atas.add_child(UI.ikon(load("res://assets/barang/%s.png" % id), 52))
	var info: = VBoxContainer.new()
	info.add_theme_constant_override("separation", -2)
	info.alignment = BoxContainer.ALIGNMENT_CENTER
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	atas.add_child(info)
	var nama: = UI.label(b["nama"], 14)
	nama.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	nama.custom_minimum_size.x = 40
	info.add_child(nama)
	var modal: = UI.label("", 13, WARNA.darkened(0.25))
	modal.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	modal.custom_minimum_size.x = 40
	info.add_child(modal)
	_modal[id] = modal
	var promo: = UI.label("", 12, MERAH_PROMO)
	promo.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	promo.custom_minimum_size.x = 40
	promo.visible = false
	info.add_child(promo)
	_promo[id] = promo
	var stok: = UI.label("", 11, UI.WARNA_REDUP)
	stok.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	stok.custom_minimum_size.x = 40
	info.add_child(stok)
	_stok[id] = stok

	var langkah: = HBoxContainer.new()
	langkah.add_theme_constant_override("separation", 4)
	kolom.add_child(langkah)
	var kurang: = UI.tombol("−", WARNA_KURANG, 18, 34)
	kurang.custom_minimum_size.x = 36
	kurang.pressed.connect(_ubah_keranjang.bind(id, -1))
	langkah.add_child(kurang)
	var jumlah: = UI.label("0", 16)
	jumlah.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	jumlah.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	langkah.add_child(jumlah)
	_jumlah[id] = jumlah
	var tambah: = UI.tombol("+", WARNA_HIJAU, 18, 34)
	tambah.custom_minimum_size.x = 36
	tambah.pressed.connect(_ubah_keranjang.bind(id, 1))
	langkah.add_child(tambah)
	var tambah5: = UI.tombol("+5", WARNA_HIJAU.darkened(0.1), 14, 34)
	tambah5.custom_minimum_size.x = 40
	tambah5.pressed.connect(_ubah_keranjang.bind(id, 5))
	langkah.add_child(tambah5)
	_tombol[id] = [kurang, tambah, tambah5]
	_kartu[id] = kartu
	return kartu


func _buat_baris_harga(id: String) -> Control:
	var b: = GameState.data_barang(id)
	var p: = UI.panel(Color.WHITE, 12, 8)
	var baris: = HBoxContainer.new()
	baris.add_theme_constant_override("separation", 6)
	p.add_child(baris)
	baris.add_child(UI.ikon(load("res://assets/barang/%s.png" % id), 38))
	var nama: = UI.label(b["nama"], 14)
	nama.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nama.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	nama.custom_minimum_size.x = 40
	baris.add_child(nama)
	var turun: = UI.tombol("−", WARNA_KURANG, 18, 32)
	turun.custom_minimum_size.x = 34
	turun.pressed.connect( func(): GameState.ubah_harga_jual(id, -1))
	baris.add_child(turun)
	var harga: = UI.label("", 14)
	harga.custom_minimum_size.x = 84
	harga.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	baris.add_child(harga)
	_harga[id] = harga
	var naik: = UI.tombol("+", WARNA_KURANG, 18, 32)
	naik.custom_minimum_size.x = 34
	naik.pressed.connect( func(): GameState.ubah_harga_jual(id, 1))
	baris.add_child(naik)
	_tombol_harga[id] = [turun, naik]
	_baris_harga[id] = p
	return p


func tampil() -> void :
	_pesan.text = ""
	_tutup_checkout()
	_perbarui()


func _process(_delta: float) -> void :
	if visible:
		_perbarui_kurir()


func _perbarui_kurir() -> void :
	var ada_kiriman: = not GameState.kiriman_stok.is_empty()
	_kotak_kurir.visible = ada_kiriman
	if not ada_kiriman:
		return
	if GameState.kurir_dalam_perjalanan:
		_label_kurir.text = "Kurir sedang menuju warung..."
		_bar_kurir.value = _bar_kurir.max_value
	else:
		var total: = GameState.durasi_kirim()
		_bar_kurir.max_value = total
		_bar_kurir.value = total - GameState.detik_kiriman
		_label_kurir.text = "Paket diantar kurir, sekitar %d detik lagi (waktu berjalan saat HP ditutup)." % ceili(GameState.detik_kiriman)


func _perbarui() -> void :
	if not is_inside_tree():
		return
	_rapikan_keranjang()
	_label_uang.text = "Uang di laci: %s" % GameState.format_rupiah(GameState.uang)
	if GameState.saldo_digital > 0:
		_label_uang.text += "  ·  Saldo QRIS: %s" % GameState.format_rupiah(GameState.saldo_digital)
	_label_saldo.text = "Saldo layanan (e-wallet & paket data): %s" % GameState.format_rupiah(GameState.saldo_layanan)
	var menipis: = GameState.barang_menipis()
	for id in _kartu:
		var buka: = GameState.terbuka(id)
		var di_keranjang: = int(_keranjang.get(id, 0))
		if buka:
			var dikirim: = GameState.jumlah_kiriman(id)
			_modal[id].text = GameState.format_rupiah(GameState.harga_modal(id))
			var tanda: = []
			if GameState.ada_promo(id):
				tanda.append(tr("PROMO -%d%%") % roundi(GameState.diskon_promo(id) * 100))
			if GameState.lewat_agen(id):
				tanda.append(tr("via agen"))
			_promo[id].text = " · ".join(tanda)
			_promo[id].visible = not tanda.is_empty()
			_promo[id].add_theme_color_override("font_color", MERAH_PROMO if GameState.ada_promo(id) else UI.WARNA_REDUP)
			_stok[id].text = "Stok %d/%d%s" % [GameState.stok[id], GameState.MAKS_STOK_BARANG, (" (+%d dikirim)" % dikirim) if dikirim > 0 else ""]
			_stok[id].add_theme_color_override("font_color", UI.WARNA_GAGAL if id in menipis else UI.WARNA_REDUP)
			_harga[id].text = GameState.format_rupiah(GameState.harga_jual(id))
			_harga[id].add_theme_color_override("font_color", UI.WARNA_TEKS)
		else:
			_modal[id].text = "Terkunci"
			_promo[id].visible = false
			_stok[id].text = GameState.cara_buka_barang(id)
			_stok[id].add_theme_color_override("font_color", UI.WARNA_REDUP)
			_harga[id].text = "-"
		_jumlah[id].text = str(di_keranjang)
		_jumlah[id].add_theme_color_override("font_color", WARNA_HIJAU if di_keranjang > 0 else UI.WARNA_REDUP)
		_tombol[id][0].disabled = not buka or di_keranjang == 0
		_tombol[id][1].disabled = not buka
		_tombol[id][2].disabled = not buka
		for t in _tombol_harga[id]:
			t.disabled = not buka

		var gaya: = UI.kotak(Color.WHITE if di_keranjang == 0 else Color(0.92, 0.98, 0.92), 12, 6)
		if di_keranjang > 0:
			gaya.border_color = WARNA_HIJAU
			gaya.set_border_width_all(2)
		_kartu[id].add_theme_stylebox_override("panel", gaya)
		_kartu[id].modulate.a = 1.0 if buka else 0.5
		_baris_harga[id].visible = buka
	_perbarui_total()
	tombol_lengkapi.visible = not GameState.kekurangan_stok(_keranjang).is_empty()


	var buka_urut: Array = []
	var katalog: Array = GameState.barang_belanja()
	for id in katalog:
		if GameState.terbuka(id):
			buka_urut.append(id)
	buka_urut.sort_custom( func(a, b):
		var sa: = int(GameState.stok[a]) + GameState.jumlah_kiriman(a)
		var sb: = int(GameState.stok[b]) + GameState.jumlah_kiriman(b)
		return sa < sb if sa != sb else katalog.find(a) < katalog.find(b))
	var urut: Array = buka_urut
	for id in GameState.barang_belanja():
		if not id in urut:
			urut.append(id)
	for i in urut.size():
		_grid.move_child(_kartu[urut[i]], i)
	_terapkan_filter()
	_perbarui_kurir()


func _ubah_filter(nama: String) -> void :
	_filter[nama] = not bool(_filter[nama])
	GameState.klik()
	_perbarui()


func _cocok_filter(id: String) -> bool:
	if not bool(_filter["stok"]) and not bool(_filter["diskon"]):
		return true
	if not GameState.terbuka(id):
		return false
	if bool(_filter["stok"]) and int(GameState.stok[id]) + GameState.jumlah_kiriman(id) >= BATAS_FILTER_STOK:
		return false
	return not bool(_filter["diskon"]) or GameState.ada_promo(id)


func _terapkan_filter() -> void :

	var boleh: bool = GameState.tutorial_langkah == "" and not GameState.mode_latihan
	_baris_filter.visible = boleh and _tab_sekarang == "belanja"
	if not boleh:
		_filter = {"stok": false, "diskon": false}
	for nama in _tombol_filter:
		_tombol_filter[nama].modulate = Color.WHITE if _filter[nama] else Color(1, 1, 1, 0.55)
	var ada: = false
	for id in _kartu:
		var cocok: = _cocok_filter(id)
		_kartu[id].visible = cocok
		ada = ada or cocok
	_label_filter_kosong.visible = not ada






func _lengkapi_stok() -> void :
	var kurang: = GameState.kekurangan_stok(_keranjang)
	var urutan: = 0
	for id in kurang:
		_keranjang[id] = int(_keranjang.get(id, 0)) + int(kurang[id])

		if urutan < 8:
			_terbang(id, tombol_lengkapi.get_global_rect().get_center(), urutan * 0.07)
		urutan += 1
	_rapikan_keranjang()
	GameState.klik()
	_pesan.text = ""
	_perbarui()


func _total_keranjang() -> int:
	var total: = 0
	for id in _keranjang:
		total += GameState.harga_modal(id) * int(_keranjang[id])
	return total



func _rapikan_keranjang() -> void :
	for id in _keranjang.keys():
		var maks: = GameState.sisa_muat_stok(id)
		if maks <= 0:
			_keranjang.erase(id)
		elif int(_keranjang[id]) > maks:
			_keranjang[id] = maks


func _ubah_keranjang(id: String, selisih: int) -> void :
	var lama: = int(_keranjang.get(id, 0))
	var baru: = mini(lama + selisih, GameState.sisa_muat_stok(id))
	if selisih > 0 and baru <= lama:
		_tampilkan_pesan(GameState.alasan_stok_penuh(id) if lama == 0 else "Stok %s sudah penuh. Paling banyak %d per barang." % [String(GameState.data_barang(id)["nama"]), GameState.MAKS_STOK_BARANG], UI.WARNA_GAGAL)
		GameState.bunyi("salah")
		return
	if baru <= 0:
		_keranjang.erase(id)
	else:
		_keranjang[id] = baru

	if selisih > 0 and _tombol.has(id):
		_terbang(id, (_tombol[id][1] if selisih == 1 else _tombol[id][2]).get_global_rect().get_center(), 0.0)
	_pesan.text = ""
	_perbarui()



func _terbang(id: String, dari: Vector2, tunda: float) -> void :
	if not is_inside_tree() or not visible or _ikon_keranjang == null:
		return
	var ikon: = TextureRect.new()
	ikon.texture = load("res://assets/barang/%s.png" % id)
	ikon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ikon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ikon.custom_minimum_size = Vector2(44, 44)
	ikon.size = Vector2(44, 44)
	ikon.pivot_offset = Vector2(22, 22)
	ikon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ikon.top_level = true
	ikon.z_index = 60
	ikon.visible = false
	add_child(ikon)
	var awal: = dari - Vector2(22, 22)
	var tujuan: = _ikon_keranjang.get_global_rect().get_center() - Vector2(22, 22)
	var tengah: = (awal + tujuan) / 2.0 + Vector2(0, -80)
	ikon.global_position = awal
	var tw: = create_tween()
	if tunda > 0.0:
		tw.tween_interval(tunda)
	tw.tween_callback( func(): ikon.visible = true)
	tw.tween_method( func(t: float):
		var a: = awal.lerp(tengah, t)
		var b: = tengah.lerp(tujuan, t)
		ikon.global_position = a.lerp(b, t)
		ikon.scale = Vector2.ONE.lerp(Vector2(0.4, 0.4), t)
		ikon.modulate.a = 1.0 - maxf(t - 0.75, 0.0) * 4.0, 0.0, 1.0, 0.5).set_trans(Tween.TRANS_SINE)
	tw.tween_callback(ikon.queue_free)


func _perbarui_total() -> void :
	var jumlah: = 0
	for id in _keranjang:
		jumlah += int(_keranjang[id])
	var total: = _total_keranjang()
	if jumlah == 0:
		_label_total.text = "Keranjang kosong"
	else:
		_label_total.text = "%d barang\n%s" % [jumlah, GameState.format_rupiah(total)]
	(_ikon_keranjang as Control).set("jumlah", jumlah)
	_label_total.add_theme_color_override("font_color", UI.WARNA_GAGAL if total > GameState.uang + GameState.saldo_digital else UI.WARNA_TEKS)
	_tombol_beli.disabled = jumlah == 0
	_tombol_kosongkan.disabled = jumlah == 0







const MERAH_PROMO: = Color(0.85, 0.15, 0.1)

var _halaman_checkout: VBoxContainer
var _isi_checkout: VBoxContainer
var _label_ringkasan: Label
var _halaman_kurir: VBoxContainer
var _isi_kurir: VBoxContainer
var _label_total_checkout: Label
var _tombol_bayar: Button
var _kurir_pilih: = ""
var _teks_kurir: = {}
var _bagian_utama: Array = []
var _tab_sekarang: = "belanja"


func _buat_halaman_checkout() -> void :
	var ringkasan: = _buat_kerangka("Checkout", "Lanjut: Pilih Kurir", _buka_pilih_kurir, _tutup_checkout)
	_halaman_checkout = ringkasan["halaman"]
	_isi_checkout = ringkasan["isi"]
	_label_ringkasan = ringkasan["label"]
	var kurir: = _buat_kerangka("Pilih Kurir", "Bayar", _bayar_checkout, _kembali_ke_ringkasan)
	_halaman_kurir = kurir["halaman"]
	_isi_kurir = kurir["isi"]
	_label_total_checkout = kurir["label"]
	_tombol_bayar = kurir["utama"]



func _buat_kerangka(judul: String, teks_utama: String, saat_utama: Callable, saat_kembali: Callable) -> Dictionary:
	var halaman: = VBoxContainer.new()
	halaman.size_flags_vertical = Control.SIZE_EXPAND_FILL
	halaman.add_theme_constant_override("separation", 0)
	halaman.hide()
	add_child(halaman)
	halaman.add_child(UI.kepala(judul, WARNA))
	var g: Array = UI.gulir(8)
	var tepi: = MarginContainer.new()
	tepi.size_flags_vertical = Control.SIZE_EXPAND_FILL
	for sisi in ["left", "right", "top", "bottom"]:
		tepi.add_theme_constant_override("margin_" + sisi, 8)
	tepi.add_child(g[0])
	halaman.add_child(tepi)
	var bawah: = UI.panel(Color(1, 0.9, 0.5), 0, 8)
	halaman.add_child(bawah)
	var kolom: = VBoxContainer.new()
	kolom.add_theme_constant_override("separation", 6)
	bawah.add_child(kolom)
	var label: = UI.label("", 15, UI.WARNA_TEKS, true)
	kolom.add_child(label)
	var baris: = HBoxContainer.new()
	baris.add_theme_constant_override("separation", 6)
	kolom.add_child(baris)
	var kembali: = UI.tombol("Kembali", WARNA_KURANG, 15, 44)
	kembali.custom_minimum_size.x = 100
	kembali.pressed.connect(saat_kembali)
	baris.add_child(kembali)
	var utama: = UI.tombol(teks_utama, WARNA_HIJAU, 17, 44)
	utama.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	utama.pressed.connect(saat_utama)
	baris.add_child(utama)
	return {"halaman": halaman, "isi": g[1], "label": label, "utama": utama}



func _mulai_beli() -> void :
	if GameState.tutorial_langkah != "" or GameState.mode_latihan:
		_bayar()
		return
	_pesan.text = ""
	for b in _bagian_utama:
		b.hide()
	_kurir_pilih = GameState.kurir_hari_ini() if GameState.kurir_hari_ini() != "" else "reguler"
	_halaman_checkout.show()
	_susun_checkout()


func _tutup_checkout() -> void :
	if _halaman_checkout == null:
		return
	_halaman_checkout.hide()
	_halaman_kurir.hide()
	for b in _bagian_utama:
		b.show()
	_pilih_tab(_tab_sekarang)


func _buka_pilih_kurir() -> void :
	_halaman_checkout.hide()
	_halaman_kurir.show()
	_susun_pilih_kurir()


func _kembali_ke_ringkasan() -> void :
	_halaman_kurir.hide()
	_halaman_checkout.show()



func _susun_checkout() -> void :
	for anak in _isi_checkout.get_children():
		anak.queue_free()
	_label_ringkasan.text = "Subtotal barang %s\nOngkir dipilih di langkah berikutnya." % GameState.format_rupiah(_total_keranjang())
	var ringkas: = UI.panel(Color.WHITE, 12, 10)
	_isi_checkout.add_child(ringkas)
	var kr: = VBoxContainer.new()
	kr.add_theme_constant_override("separation", 3)
	ringkas.add_child(kr)
	kr.add_child(UI.label("Ringkasan belanja", 16, UI.WARNA_TEKS))
	for id in _keranjang:
		kr.add_child(UI.label("%s × %d · %s" % [String(GameState.data_barang(id)["nama"]), int(_keranjang[id]), GameState.format_rupiah(GameState.harga_modal(id) * int(_keranjang[id]))], 13, UI.WARNA_TEKS, true))
	kr.add_child(UI.label("Subtotal barang: %s" % GameState.format_rupiah(_total_keranjang()), 14, UI.WARNA_TEKS, true))



func _susun_pilih_kurir() -> void :
	for anak in _isi_kurir.get_children():
		anak.queue_free()

	var info: = UI.panel(Color(1, 0.96, 0.8), 12, 10)
	_isi_kurir.add_child(info)
	var ki: = VBoxContainer.new()
	ki.add_theme_constant_override("separation", 3)
	info.add_child(ki)
	ki.add_child(UI.label("Ongkir dibayar sekali dan berlaku untuk semua belanja hari ini. Kurir yang dipilih dipakai sampai besok.", 13, UI.WARNA_REDUP, true))

	var kurir: = UI.panel(Color.WHITE, 12, 10)
	_isi_kurir.add_child(kurir)
	var kk: = VBoxContainer.new()
	kk.add_theme_constant_override("separation", 6)
	kurir.add_child(kk)
	var berlaku: = GameState.kurir_hari_ini()
	_tombol_kurir.clear()
	_ket_kurir.clear()
	for jenis in ["reguler", "cepat", "instan"]:
		var nama: = String(GameState.KURIR[jenis]["nama"])
		var detik: = "langsung sampai" if jenis == "instan" else "±%d dtk" % ceili(GameState.detik_kurir(jenis))
		var baris: = VBoxContainer.new()
		baris.add_theme_constant_override("separation", 2)
		kk.add_child(baris)
		var tombol: = UI.tombol("", WARNA_HIJAU, 15, 44)
		baris.add_child(tombol)
		var ket: = UI.label("", 12, UI.WARNA_REDUP, true)
		baris.add_child(ket)
		_tombol_kurir[jenis] = tombol
		_ket_kurir[jenis] = ket
		if berlaku != "" and berlaku != jenis:

			tombol.disabled = true
			_teks_kurir[jenis] = "%s · %s" % [nama, detik]
			ket.text = "Tidak bisa dipilih: kurir instan masih berlaku." if berlaku == "instan" else "Tidak bisa dipilih: hari ini sudah memakai kurir %s, berlaku seharian." % String(GameState.KURIR[berlaku]["nama"]).to_lower()
		else:
			tombol.pressed.connect(_pilih_baris.bind(jenis))
			if berlaku == jenis:
				_teks_kurir[jenis] = "%s · %s · sedang berlaku" % [nama, detik]
				if jenis == "instan":
					ket.text = "Gratis sampai besok." if GameState.sisa_hari_instan() > 1 else "Gratis sampai hari ini."
				else:
					ket.text = "Belanja ini tanpa ongkir tambahan."
			elif jenis == "instan":
				_teks_kurir[jenis] = "%s · %s · gratis %d hari" % [nama, detik, GameState.LAMA_KURIR_INSTAN]
				ket.text = "Gratis (Tanpa Iklan), berlaku hari ini dan besok." if GameState.tanpa_iklan else "Tonton 1 iklan, gratis hari ini dan besok."
			else:
				var ongkir: = GameState.ongkir_kurir(jenis)
				if ongkir > 0:
					_teks_kurir[jenis] = "%s · %s · %s" % [nama, detik, GameState.format_rupiah(ongkir)]
					ket.text = "Ongkir %s dibayar sekali, berlaku seharian." % GameState.format_rupiah(ongkir)
				else:
					_teks_kurir[jenis] = "%s · %s · GRATIS ONGKIR" % [nama, detik]
					ket.text = "GRATIS ONGKIR sampai Level %d" % GameState.ONGKIR_REGULER_GRATIS_SAMPAI_LEVEL
					ket.add_theme_color_override("font_color", MERAH_PROMO)
	_segarkan_pilihan()


func _pilih_baris(jenis: String) -> void :
	_kurir_pilih = jenis
	GameState.klik()
	_segarkan_pilihan()



func _segarkan_pilihan() -> void :
	for jenis in _tombol_kurir:
		var tombol: Button = _tombol_kurir[jenis]
		var pilih: bool = jenis == _kurir_pilih
		tombol.text = ("✓ " if pilih else "") + String(_teks_kurir.get(jenis, ""))


		if not tombol.disabled:
			tombol.self_modulate = Color(0.55, 1.0, 0.6) if pilih else Color.WHITE
	var ongkir: = _ongkir_terpilih()
	var total: = _total_keranjang() + ongkir
	_label_total_checkout.text = "Barang %s + ongkir %s\nTotal bayar %s" % [GameState.format_rupiah(_total_keranjang()), GameState.format_rupiah(ongkir), GameState.format_rupiah(total)]
	var kurang: bool = GameState.uang + GameState.saldo_digital < total
	_label_total_checkout.add_theme_color_override("font_color", UI.WARNA_GAGAL if kurang else UI.WARNA_TEKS)
	_tombol_bayar.disabled = _kurir_pilih == "" or kurang


func _ongkir_terpilih() -> int:
	if _kurir_pilih == "" or GameState.kurir_hari_ini() == _kurir_pilih:
		return 0
	return GameState.ongkir_kurir(_kurir_pilih)



func _bayar_checkout() -> void :
	var jenis: = _kurir_pilih
	if jenis == "":
		return
	if GameState.uang + GameState.saldo_digital < _total_keranjang() + _ongkir_terpilih():
		_tampilkan_pesan("Uang tidak cukup untuk belanja + ongkir (%s)." % GameState.format_rupiah(_total_keranjang() + _ongkir_terpilih()), UI.WARNA_GAGAL)
		GameState.bunyi("salah")
		return
	if jenis == "instan" and GameState.kurir_hari_ini() != "instan":
		var akar: Node = hp.get_parent() if hp != null else get_tree().root
		if not await GameState.tonton_iklan(akar):
			_label_total_checkout.text = "Iklan belum selesai, kurir instan belum aktif."
			return
	var alasan: = GameState.pilih_kurir(jenis)
	_tutup_checkout()
	if alasan != "":
		_tampilkan_pesan(alasan, UI.WARNA_GAGAL)
		GameState.bunyi("salah")
		return
	_bayar()



func _bayar() -> void :
	var total: = _total_keranjang()

	if not GameState.bayar_campur(total):
		_tampilkan_pesan("Uang tidak cukup. Total %s, uang di laci + saldo digital %s." % [GameState.format_rupiah(total), GameState.format_rupiah(GameState.uang + GameState.saldo_digital)], UI.WARNA_GAGAL)
		GameState.bunyi("salah")
		return
	for id in _keranjang.keys():
		var alasan: = GameState.beli_stok(id, int(_keranjang[id]))
		if alasan != "":
			_tampilkan_pesan(alasan, UI.WARNA_GAGAL)
			GameState.bunyi("salah")
			_perbarui()
			return
		_keranjang.erase(id)
	GameState.bunyi("koin")
	_tampilkan_pesan("Pesanan dibayar %s. Kurir segera mengantar." % GameState.format_rupiah(total), UI.WARNA_BERHASIL)

	if GameState.tutorial_langkah == "belanja":
		GameState.tutorial_langkah = "buka"
	elif GameState.tutorial_langkah == "asli_belanja" and GameState.kekurangan_stok().is_empty():
		GameState.tutorial_langkah = "asli_kurir"
	_perbarui()


func _isi_saldo() -> void :
	if GameState.uang >= JUMLAH_ISI_SALDO and not await KB.tanya(self, "Isi saldo layanan?", JUMLAH_ISI_SALDO, "", "Ya, isi"):
		return
	var alasan: = GameState.isi_saldo_layanan(JUMLAH_ISI_SALDO)
	if alasan != "":
		_tampilkan_pesan(alasan, UI.WARNA_GAGAL)
	else:
		_tampilkan_pesan("Saldo layanan bertambah %s." % GameState.format_rupiah(JUMLAH_ISI_SALDO), UI.WARNA_BERHASIL)


func _tampilkan_pesan(teks: String, warna: Color) -> void :
	_pesan.text = teks
	_pesan.add_theme_color_override("font_color", warna)
