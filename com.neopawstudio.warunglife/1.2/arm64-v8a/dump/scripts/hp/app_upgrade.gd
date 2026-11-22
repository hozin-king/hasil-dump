extends VBoxContainer





const UI: = preload("res://scripts/hp/hp_ui.gd")
const GH: = preload("res://scripts/gaya_hud.gd")
const WARNA: = Color(0.45, 0.3, 0.18)
const FOLDER_IKON: = "res://assets/upgrade/ikon/"

var hp: Control
var _gulir: ScrollContainer
var _daftar: VBoxContainer
var _label_atas: Label
var _pesan: Label
var _kepala_level: = {}
var _tombol: = {}
var _kartu: = {}
var _label_harga: = {}
var _tombol_iklan: = {}


func _ready() -> void :
	add_theme_constant_override("separation", 0)
	add_child(UI.kepala("Upgrade Warung", WARNA))
	var info: = UI.panel(Color(0.97, 0.92, 0.84), 0, 10)
	add_child(info)
	_label_atas = UI.label("", 15, UI.WARNA_TEKS, true)
	info.add_child(_label_atas)
	var g: Array = UI.gulir(8)
	_gulir = g[0]
	_daftar = g[1]
	var tepi: = MarginContainer.new()
	tepi.size_flags_vertical = Control.SIZE_EXPAND_FILL
	for sisi in ["left", "right", "top"]:
		tepi.add_theme_constant_override("margin_" + sisi, 8)
	tepi.add_child(_gulir)
	add_child(tepi)
	_pesan = UI.label("", 15, UI.WARNA_BERHASIL, true)
	_pesan.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_pesan.custom_minimum_size.y = 40
	add_child(_pesan)

	var per_level: = {}
	for u in GameState.daftar_upgrade:
		if not per_level.has(u["level"]):
			per_level[u["level"]] = []
		per_level[u["level"]].append(u)
	var daftar_lv: = per_level.keys()
	daftar_lv.sort()
	for lv in daftar_lv:
		var kepala: = UI.panel(WARNA, 8, 8)
		kepala.name = "Level%d" % lv
		var baris: = HBoxContainer.new()
		kepala.add_child(baris)
		var nama: = UI.label("Level %d" % lv, 19, Color.WHITE)
		nama.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		baris.add_child(nama)
		var status: = UI.label("", 14, Color(1, 0.92, 0.75))
		baris.add_child(status)
		_kepala_level[lv] = status
		_daftar.add_child(kepala)
		for u in per_level[lv]:
			_daftar.add_child(_buat_kartu(u))
	GameState.data_berubah.connect(_perbarui)


func _buat_kartu(u: Dictionary) -> Control:
	var id: String = u["id"]
	var kartu: = UI.panel(Color.WHITE, 10, 10)
	var kolom: = VBoxContainer.new()
	kolom.add_theme_constant_override("separation", 6)
	kartu.add_child(kolom)
	var atas: = HBoxContainer.new()
	atas.add_theme_constant_override("separation", 10)
	kolom.add_child(atas)

	var file_ikon: = FOLDER_IKON + id + ".png"
	if not ResourceLoader.exists(file_ikon):
		file_ikon = FOLDER_IKON + id + ".svg"
	if ResourceLoader.exists(file_ikon):
		atas.add_child(UI.ikon(load(file_ikon), 64))
	var teks: = VBoxContainer.new()
	teks.add_theme_constant_override("separation", 0)
	teks.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	atas.add_child(teks)
	teks.add_child(UI.label(u["nama"], 18))
	var harga: = UI.label("", 22, Color(0.55, 0.25, 0.05))
	var tebal: = FontVariation.new()
	tebal.base_font = load("res://assets/font/Fredoka.ttf")
	tebal.variation_embolden = 0.5
	harga.add_theme_font_override("font", tebal)
	teks.add_child(harga)
	_label_harga[id] = harga
	kolom.add_child(UI.label(u["deskripsi"], 14, UI.WARNA_TEKS, true))
	var baris: = HBoxContainer.new()
	baris.add_theme_constant_override("separation", 6)
	kolom.add_child(baris)
	var tombol: = UI.tombol("", Color(0.2, 0.62, 0.3), 16, 40)
	tombol.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tombol.pressed.connect(_tanya_beli.bind(id))
	baris.add_child(tombol)

	var iklan: = UI.tombol("", Color(0.85, 0.55, 0.1), 14, 40)
	iklan.custom_minimum_size.x = 150
	iklan.pressed.connect(_iklan.bind(id))
	baris.add_child(iklan)
	_tombol_iklan[id] = iklan
	_tombol[id] = tombol
	_kartu[id] = kartu
	return kartu


func _iklan(id: String) -> void :
	if not GameState.boleh_iklan_upgrade(id):
		return
	var akar: Node = hp.get_parent() if hp != null else get_tree().root
	var harga_lama: = GameState.harga_upgrade(id)
	var persen: = roundi(GameState.potongan_iklan_untuk(id) * 100.0)
	if await GameState.tonton_iklan(akar):
		GameState.tambah_iklan_upgrade(id)
		_notif_harga(String(GameState.data_upgrade(id)["nama"]), harga_lama, GameState.harga_upgrade(id), persen)
		_pesan.text = "Harga %s sekarang %s." % [String(GameState.data_upgrade(id)["nama"]).to_lower(), GameState.format_rupiah(GameState.harga_upgrade(id))]
		_pesan.add_theme_color_override("font_color", UI.WARNA_BERHASIL)


func tampil() -> void :
	_pesan.text = ""
	_perbarui()

	await get_tree().process_frame
	var kepala: = _daftar.get_node_or_null("Level%d" % clampi(GameState.level(), 1, _kepala_level.size()))
	if kepala != null:
		_gulir.scroll_vertical = int(maxf(kepala.position.y - 4.0, 0.0))


func _perbarui() -> void :
	if not is_inside_tree():
		return
	_label_atas.text = "Kamu di Level %d · uang %s\nSelesaikan tugas level untuk membuka upgrade berikutnya." % [GameState.level(), GameState.format_rupiah(GameState.uang)]
	for lv in _kepala_level:
		_kepala_level[lv].text = "Kamu di sini" if GameState.level() == lv else ("Tercapai" if GameState.level() > lv else "Terkunci")
	for id in _tombol:
		var u: = GameState.data_upgrade(id)
		var t: Button = _tombol[id]
		var status: = GameState.status_upgrade(id)
		t.disabled = status != "bisa"
		match status:
			"dimiliki": t.text = "Sudah dimiliki"
			"terkunci": t.text = "Terkunci · Level %d" % u["level"]
			"butuh": t.text = "Butuh %s dulu" % String(GameState.data_upgrade(u["butuh"])["nama"]).to_lower()
			"kurang_uang": t.text = "Uang belum cukup"
			_: t.text = "Beli"
		_kartu[id].modulate.a = 0.55 if status == "terkunci" else 1.0
		var harga_asli: = int(u["harga"])
		var harga: = GameState.harga_upgrade(id)
		_label_harga[id].text = GameState.format_rupiah(harga) if harga == harga_asli else "%s  (hemat %d%%)" % [GameState.format_rupiah(harga), roundi(100.0 - 100.0 * harga / harga_asli)]
		var ti: Button = _tombol_iklan[id]
		ti.visible = id != "etalase" and status != "dimiliki" and status != "terkunci"
		ti.disabled = not GameState.boleh_iklan_upgrade(id)
		ti.text = "Potongan harga %d%%" % roundi(GameState.potongan_iklan_untuk(id) * 100.0)
		ti.visible = ti.visible and GameState.boleh_iklan_upgrade(id)



var _jendela_yakin: Control

func _tanya_beli(id: String) -> void :
	if _jendela_yakin != null and is_instance_valid(_jendela_yakin):
		return
	GameState.klik()
	var u: = GameState.data_upgrade(id)
	var r: = get_global_rect()
	var lapisan: = ColorRect.new()
	lapisan.color = Color(0, 0, 0, 0.6)
	lapisan.mouse_filter = Control.MOUSE_FILTER_STOP
	lapisan.top_level = true
	lapisan.position = r.position
	lapisan.size = r.size
	add_child(lapisan)
	_jendela_yakin = lapisan
	var tengah: = CenterContainer.new()
	tengah.set_anchors_preset(Control.PRESET_FULL_RECT)
	lapisan.add_child(tengah)
	var kotak: = UI.panel(Color(0.13, 0.11, 0.09), 16, 16)
	kotak.custom_minimum_size.x = minf(r.size.x - 40.0, 420.0)
	tengah.add_child(kotak)
	var kolom: = VBoxContainer.new()
	kolom.add_theme_constant_override("separation", 10)
	kotak.add_child(kolom)
	var judul: = UI.label("Beli upgrade ini?", 20, Color.WHITE)
	judul.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	kolom.add_child(judul)
	var nama: = UI.label(String(u["nama"]), 18, Color(1, 0.92, 0.6), true)
	nama.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	kolom.add_child(nama)
	var label_bayar: = UI.label("Uang yang harus dibayar:", 15, UI.WARNA_REDUP)
	label_bayar.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	kolom.add_child(label_bayar)
	var harga: = UI.label(GameState.format_rupiah(GameState.harga_upgrade(id)), 28, Color(1, 0.85, 0.35))
	harga.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	kolom.add_child(harga)
	var sisa: = UI.label(GameState.tk("Sisa uang sesudah beli: %s") % GameState.format_rupiah(GameState.uang - GameState.harga_upgrade(id)), 14, UI.WARNA_REDUP, true)
	sisa.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	kolom.add_child(sisa)
	var baris: = HBoxContainer.new()
	baris.add_theme_constant_override("separation", 10)
	kolom.add_child(baris)
	var batal: = UI.tombol("Batal", Color(1, 1, 1, 0.15), 18, 48)
	batal.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	batal.pressed.connect( func():
		GameState.klik()
		lapisan.queue_free())
	baris.add_child(batal)
	var ya: = UI.tombol("Ya, beli", Color(0.2, 0.62, 0.3), 18, 48)
	ya.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ya.pressed.connect( func():
		lapisan.queue_free()
		_beli(id))
	baris.add_child(ya)


func _exit_tree() -> void :
	if _jendela_yakin != null and is_instance_valid(_jendela_yakin):
		_jendela_yakin.queue_free()


func _beli(id: String) -> void :
	var alasan: = GameState.beli_upgrade(id)
	if alasan == "":
		_pesan.text = "%s terpasang di warung!" % GameState.data_upgrade(id)["nama"]
		_pesan.add_theme_color_override("font_color", UI.WARNA_BERHASIL)
	else:
		GameState.bunyi("salah")
		_pesan.text = alasan
		_pesan.add_theme_color_override("font_color", UI.WARNA_GAGAL)



func _notif_harga(nama: String, lama: int, baru: int, persen: = 10) -> void :
	GameState.bunyi("koin")
	var kotak: = PanelContainer.new()
	kotak.add_theme_stylebox_override("panel", GH.kartu_notif(0.88, Vector4(24, 14, 18, 14)))
	kotak.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var kolom: = VBoxContainer.new()
	kolom.add_theme_constant_override("separation", 2)
	kotak.add_child(kolom)
	var judul: = UI.label("Harga turun %d%%!" % persen, 17, Color.WHITE)
	judul.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	kolom.add_child(judul)
	var l_nama: = UI.label(nama, 12, Color(1, 0.95, 0.8))
	l_nama.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	kolom.add_child(l_nama)
	var l_lama: = UI.label(GameState.format_rupiah(lama), 12, Color(1, 0.85, 0.75))
	l_lama.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l_lama.draw.connect( func():
		var lebar: = l_lama.get_theme_font("font").get_string_size(l_lama.text, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
		var tengah: = l_lama.size / 2.0
		l_lama.draw_line(Vector2(tengah.x - lebar / 2.0 - 2, tengah.y), Vector2(tengah.x + lebar / 2.0 + 2, tengah.y), Color(1, 0.85, 0.75), 2.0))
	kolom.add_child(l_lama)
	var l_baru: = UI.label(GameState.format_rupiah(baru), 23, Color(1, 0.92, 0.35))
	l_baru.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var tebal: = FontVariation.new()
	tebal.base_font = load("res://assets/font/Fredoka.ttf")
	tebal.variation_embolden = 0.5
	l_baru.add_theme_font_override("font", tebal)
	kolom.add_child(l_baru)
	add_child(kotak)
	kotak.top_level = true
	await get_tree().process_frame
	var r: = get_global_rect()
	kotak.global_position = Vector2(r.position.x + (r.size.x - kotak.size.x) / 2.0, r.position.y + r.size.y * 0.3)
	kotak.pivot_offset = kotak.size / 2.0
	kotak.scale = Vector2(0.6, 0.6)
	var tw: = kotak.create_tween()
	tw.tween_property(kotak, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_interval(2.0)
	tw.tween_property(kotak, "modulate:a", 0.0, 0.4)
	tw.tween_callback(kotak.queue_free)
