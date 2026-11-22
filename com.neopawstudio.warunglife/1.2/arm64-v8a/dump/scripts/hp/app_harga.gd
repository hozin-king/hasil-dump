extends VBoxContainer





const UI: = preload("res://scripts/hp/hp_ui.gd")
const WARNA: = Color(0.75, 0.25, 0.2)

var hp: Control
var _isi: VBoxContainer
var _harga: = {}
var _untung: = {}
var _acuan: = {}
var _efek_murah: Label


func _ready() -> void :
	add_theme_constant_override("separation", 0)
	add_child(UI.kepala("Harga Jual", WARNA))
	var g: Array = UI.gulir(8)
	var tepi: = MarginContainer.new()
	tepi.size_flags_vertical = Control.SIZE_EXPAND_FILL
	for sisi in ["left", "right", "top", "bottom"]:
		tepi.add_theme_constant_override("margin_" + sisi, 10)
	tepi.add_child(g[0])
	add_child(tepi)
	_isi = g[1]
	GameState.data_berubah.connect(_perbarui)


func tampil() -> void :
	for anak in _isi.get_children():
		anak.queue_free()
	_harga.clear()
	_untung.clear()
	var info: = UI.panel(Color(1, 0.97, 0.9), 12, 10)

	var isi_info: = VBoxContainer.new()
	isi_info.add_theme_constant_override("separation", 6)
	info.add_child(isi_info)
	isi_info.add_child(UI.label("Atur harga jual sesukamu. Di atas harga yang disarankan, untung per barang lebih besar, tapi makin banyak pembeli mengeluh, sebagian batal beli, dan memberi bintang rendah. Di bawah harga yang disarankan, untung lebih kecil, tapi warung lebih ramai dan pembeli lebih sabar.", 14, UI.WARNA_REDUP, true))
	_efek_murah = UI.label("", 14, Color(0.2, 0.55, 0.2), true)
	isi_info.add_child(_efek_murah)
	_isi.add_child(info)
	for id in GameState.barang_fisik():
		if GameState.terbuka(id):
			_isi.add_child(_baris(id))

	_perbarui()


func _baris(id: String) -> Control:
	var b: = GameState.data_barang(id)
	var p: = UI.panel(Color.WHITE, 12, 8)
	var baris: = HBoxContainer.new()
	baris.add_theme_constant_override("separation", 5)
	p.add_child(baris)
	baris.add_child(UI.ikon(load("res://assets/barang/%s.png" % id), 36))
	var teks: = VBoxContainer.new()
	teks.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	teks.add_theme_constant_override("separation", 0)
	var nama: = UI.label(b["nama"], 16)
	nama.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	nama.custom_minimum_size.x = 40
	teks.add_child(nama)


	var acuan: = UI.label("", 14, UI.WARNA_REDUP)
	acuan.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	acuan.custom_minimum_size.x = 40
	teks.add_child(acuan)
	_acuan[id] = acuan
	var untung: = UI.label("", 13, UI.WARNA_REDUP)
	untung.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	untung.custom_minimum_size.x = 40
	teks.add_child(untung)
	_untung[id] = untung
	baris.add_child(teks)
	var turun: = UI.tombol("−", WARNA, 20, 36)
	turun.custom_minimum_size.x = 34
	turun.pressed.connect( func(): GameState.ubah_harga_jual(id, -1))
	baris.add_child(turun)
	var harga: = UI.label("", 15)
	harga.custom_minimum_size.x = 70
	harga.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	baris.add_child(harga)
	_harga[id] = harga
	var naik: = UI.tombol("+", WARNA, 20, 36)
	naik.custom_minimum_size.x = 34
	naik.pressed.connect( func(): GameState.ubah_harga_jual(id, 1))
	baris.add_child(naik)
	return p


func _perbarui() -> void :
	if not is_visible_in_tree():
		return
	if _efek_murah != null:
		var m: = GameState.efek_harga_murah()
		_efek_murah.text = "Harga rata-rata %d%% lebih murah dari pasaran: warung %d%% lebih ramai, pembeli %d%% lebih sabar." % [roundi(m * 100.0), roundi(m * GameState.PENGALI_RAMAI_MURAH * 100.0), roundi(m * GameState.PENGALI_SABAR_MURAH * 100.0)] if m > 0.004 else ""
		_efek_murah.visible = m > 0.004
	for id in _harga:
		_harga[id].text = GameState.format_rupiah(GameState.harga_jual(id))
		var selisih: = roundi((GameState.rasio_harga(id) - 1.0) * 100.0)
		var pasar: = GameState.harga_pasar(id)
		var normal: = int(GameState.data_barang(id)["jual"])
		var patokan: = "harga pasaran" if pasar != normal else "harga disarankan"
		_acuan[id].text = ("Disarankan %s" % GameState.format_rupiah(normal)) if pasar == normal else ("Pasaran %s (%s)" % [GameState.format_rupiah(pasar), "naik" if pasar > normal else "turun"])
		_acuan[id].add_theme_color_override("font_color", UI.WARNA_REDUP if pasar == normal else Color(0.1, 0.45, 0.55))
		_untung[id].text = "Untung %s" % GameState.format_rupiah(GameState.harga_jual(id) - GameState.harga_modal(id)) + ("" if selisih == 0 else ("""
%d%% lebih %s dari %s""" %[absi(selisih), "mahal" if selisih > 0 else "murah", patokan]))
		_untung[id].add_theme_color_override("font_color", Color(0.75, 0.35, 0.1) if selisih > 0 else UI.WARNA_REDUP)



func sorot_barang(id: String) -> void :
	if not _harga.has(id):
		return
	var baris: Control = _harga[id]
	while baris != null and not baris is PanelContainer:
		baris = baris.get_parent()
	if baris == null:
		return
	var gulir: Node = baris.get_parent()
	while gulir != null and not gulir is ScrollContainer:
		gulir = gulir.get_parent()
	if gulir != null:
		await get_tree().process_frame
		gulir.ensure_control_visible(baris)
	var tw: = baris.create_tween().set_loops(3)
	tw.tween_property(baris, "modulate", Color(1.0, 0.75, 0.45), 0.25)
	tw.tween_property(baris, "modulate", Color.WHITE, 0.25)
