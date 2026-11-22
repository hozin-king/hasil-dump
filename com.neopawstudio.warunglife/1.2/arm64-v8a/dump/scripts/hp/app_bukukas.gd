extends VBoxContainer




const UI: = preload("res://scripts/hp/hp_ui.gd")
const WARNA: = Color(0.3, 0.55, 0.3)
const SCRIPT_GRAFIK: = preload("res://scripts/grafik_riwayat.gd")

var hp: Control
var _label_hari_ini: Label
var _grafik: Control
var _laris: VBoxContainer


func _ready() -> void :
	add_theme_constant_override("separation", 0)
	add_child(UI.kepala("Buku Kas", WARNA))
	var g: Array = UI.gulir(8)
	var tepi: = MarginContainer.new()
	tepi.size_flags_vertical = Control.SIZE_EXPAND_FILL
	for sisi in ["left", "right", "top", "bottom"]:
		tepi.add_theme_constant_override("margin_" + sisi, 8)
	tepi.add_child(g[0])
	add_child(tepi)
	var isi: VBoxContainer = g[1]
	isi.add_child(UI.label("Hari ini", 17))
	var kartu: = UI.panel(Color.WHITE, 10, 10)
	isi.add_child(kartu)
	_label_hari_ini = UI.label("", 15, UI.WARNA_TEKS, true)
	kartu.add_child(_label_hari_ini)
	isi.add_child(UI.label("Omzet (oranye) dan laba (hijau) 7 hari", 17, UI.WARNA_TEKS, true))
	var kartu_grafik: = UI.panel(Color.WHITE, 10, 6)
	isi.add_child(kartu_grafik)
	_grafik = Control.new()
	_grafik.set_script(SCRIPT_GRAFIK)
	_grafik.custom_minimum_size = Vector2(340, 190)
	kartu_grafik.add_child(_grafik)
	isi.add_child(UI.label("Terlaris hari ini", 17))
	_laris = VBoxContainer.new()
	_laris.add_theme_constant_override("separation", 2)
	isi.add_child(_laris)


func tampil() -> void :
	var gs: = GameState
	_label_hari_ini.text = "%s, %s\nOmzet %s · laba %s\nBelanja & biaya %s\nPelanggan dilayani %d · batal %d" % [
		gs.nama_hari(), gs.teks_tanggal(), gs.format_rupiah(gs.omzet_hari), gs.format_rupiah(gs.laba_hari), 
		gs.format_rupiah(gs.belanja_hari), gs.pelanggan_dilayani_hari, gs.pelanggan_batal_hari]

	var data: Array = gs.riwayat.duplicate()
	if gs.status_hari != "tutup" and gs.omzet_hari > 0:
		data.append({"hari": gs.hari, "omzet": gs.omzet_hari, "laba": gs.laba_hari})
	_grafik.atur(data)
	for anak in _laris.get_children():
		anak.queue_free()
	var urut: = gs.penjualan_hari.keys()
	urut.sort_custom( func(a, b): return gs.penjualan_hari[a][0] > gs.penjualan_hari[b][0])
	if urut.is_empty():
		_laris.add_child(UI.label("Belum ada penjualan hari ini.", 14, UI.WARNA_REDUP))
	for id in urut.slice(0, 6):
		var r: Array = gs.penjualan_hari[id]
		var baris: = UI.panel(Color.WHITE, 6, 8)
		var h: = HBoxContainer.new()
		baris.add_child(h)
		h.add_child(UI.ikon(load("res://assets/barang/%s.png" % id), 30))
		var nama: = UI.label(String(gs.data_barang(id)["nama"]), 14)
		nama.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		nama.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		nama.custom_minimum_size.x = 60
		h.add_child(nama)
		h.add_child(UI.label("%d terjual · laba %s" % [r[0], gs.format_rupiah(r[2])], 13, UI.WARNA_REDUP))
		_laris.add_child(baris)
