extends "res://scripts/minigame/mg_dasar.gd"















const AduLaris: = preload("res://scripts/adu_laris.gd")
const FP: = preload("res://scripts/foto_profil.gd")
const SCRIPT_KRESEK: = preload("res://scripts/kresek.gd")
const PRATINJAU: = preload("res://scripts/pratinjau_seret.gd")

const LAYAR: = Vector2(1280, 720)
const SEL: = Vector2(128, 96)
const UKURAN_KRESEK: = 270.0
const POTRET: = Vector2(640, 238)
const JARI: = 74.0

var lawan: = {}
var latihan: = false
var _rak_acak: Array = [[], []]
var _arena: Control
var _kresek: Control
var _potret: Control
var _nama_pembeli: Label
var _ucapan: Label
var _nota_baris: VBoxContainer
var _nota: PanelContainer
var _tombol: = {}
var _pembeli: Array = []
var _ke: = 0
var _sabar: = 0.0
var _sabar_penuh: = 1.0
var _masuk: = 0.0
var _isi: = {}
var omzet: = 0
var _beruntun_jual: = 0
var _dilayani: = 0
var _kabur: = 0
var _rekaman_saya: Array = [0]
var _detik_rekam: = 1
var _foto_saya: = 0


func _siapkan() -> void :
	judul = "Latihan Adu Laris" if latihan else "Adu Laris"
	petunjuk = ""
	durasi = AduLaris.DURASI
	target = 0.0
	if lawan.is_empty():
		lawan = AduLaris.pilih_lawan()
	_foto_saya = FP.pilihan()

	var benih: = AduLaris.benih_baru()
	_pembeli = AduLaris.buat_pembeli(benih)
	_rak_acak = AduLaris.acak_rak(benih)


func _boleh_bonus_ganda() -> bool:
	return false


func _perbarui_skor() -> void :
	if _label_skor != null:
		_label_skor.text = GameState.format_rupiah(omzet)




func _ready() -> void :
	process_mode = Node.PROCESS_MODE_ALWAYS
	theme = GH.tema_jendela()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 160
	add_to_group("lapisan_atas")
	_siapkan()
	_pasang_latar_warung()
	_arena = Control.new()
	_arena.size = LAYAR
	_arena.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_arena)
	_atur_skala()
	get_viewport().size_changed.connect(_atur_skala)
	_pasang_pita_atas()
	_pasang_rak(_rak_acak[0], "DAPUR", Vector2(18, 140), Color(0.78, 0.22, 0.18))
	_pasang_rak(_rak_acak[1], "MINUMAN & JAJAN", Vector2(LAYAR.x - 18 - SEL.x * 2 - 32, 140), Color(0.16, 0.48, 0.66))
	_pasang_pembeli()
	_pasang_meja()

	kanvas = Control.new()
	kanvas.size = LAYAR
	kanvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	kanvas.draw.connect(_gambar_semua)
	_arena.add_child(kanvas)
	_label_tengah = GH.label("", 120, GH.KUNING, true, 8)
	_label_tengah.size = LAYAR
	_label_tengah.pivot_offset = LAYAR / 2.0
	_label_tengah.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label_tengah.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label_tengah.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_arena.add_child(_label_tengah)
	if latihan:
		var pita_latihan: = GH.label("LATIHAN · tidak masuk papan, bebas diulang", 17, GH.KUNING, true, 4)
		pita_latihan.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		pita_latihan.position = Vector2(LAYAR.x / 2.0 - 260, 144)
		pita_latihan.size = Vector2(520, 22)
		pita_latihan.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_arena.add_child(pita_latihan)
	_pembeli_baru(0)
	var pertama: = String((_pembeli[0]["pesanan"] as Dictionary).keys()[0])
	contoh = {"jenis": "seret", "id": pertama, "benda": "res://assets/barang/%s.png" % pertama, "teks": "Seret atau klik barang ke kresek"}
	_perbarui_skor()
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.25)
	_mulai.call_deferred()


func _atur_skala() -> void :
	if not is_inside_tree():
		return
	var vp: = get_viewport_rect().size
	var s: = minf(vp.x / LAYAR.x, vp.y / LAYAR.y)
	_arena.scale = Vector2.ONE * s
	_arena.position = (vp - LAYAR * s) / 2.0


func _pasang_latar_warung() -> void :
	var gelap: = ColorRect.new()
	gelap.color = Color(0.05, 0.04, 0.03)
	gelap.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	gelap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(gelap)

	for jalur in ["res://assets/latar/latar_warung_kosong_malam_basah.png", "res://assets/latar/latar_warung_penuh_malam.png"]:
		if ResourceLoader.exists(jalur):
			var foto: = TextureRect.new()
			foto.texture = load(jalur)
			foto.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			foto.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			foto.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
			foto.modulate = Color(0.55, 0.52, 0.5)
			foto.mouse_filter = Control.MOUSE_FILTER_IGNORE
			add_child(foto)
			break





const HIJAU_TIM: = Color(0.17, 0.52, 0.26)
const JINGGA_TIM: = Color(0.86, 0.43, 0.13)
var _tarik: ProgressBar
var _omzet_lawan: Label
var _status_adu: Label
var _label_detik: Label
var _lingkar_detik: Panel
var _label_combo: Label

func _kotak_timbul(warna: Color, tepi: Color, radius: = 18, bawah: = 6) -> StyleBoxFlat:
	var g: = StyleBoxFlat.new()
	g.bg_color = warna
	g.border_color = tepi
	g.set_border_width_all(3)
	g.border_width_bottom = bawah
	g.set_corner_radius_all(radius)
	g.shadow_color = Color(0, 0, 0, 0.45)
	g.shadow_size = 8
	g.shadow_offset = Vector2(0, 4)
	g.content_margin_left = 12
	g.content_margin_right = 14
	g.content_margin_top = 6
	g.content_margin_bottom = 8
	return g





func _atur_jeda(ya: bool) -> void :
	var sudah_jeda: = _dijeda or not main
	super (ya)
	if not ya or sudah_jeda or not is_instance_valid(_lapis_jeda):
		return
	var kolom: VBoxContainer = _lapis_jeda.find_children("*", "VBoxContainer", true, false)[0]
	var ket: = GH.label("" if latihan else "Keluar dari duel resmi = dihitung kalah.", 20, Color(1, 1, 1, 0.75))
	ket.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ket.visible = not latihan
	kolom.add_child(ket)
	var keluar: = Button.new()
	keluar.text = "Keluar latihan" if latihan else "Keluar"
	keluar.theme_type_variation = &"TombolKayu"
	keluar.custom_minimum_size = Vector2(280, 66)
	keluar.add_theme_font_size_override("font_size", 26)
	kolom.add_child(keluar)
	var yakin: = [latihan]
	keluar.pressed.connect( func():
		GameState.klik()
		if not yakin[0]:
			yakin[0] = true
			keluar.text = "Ya, keluar (kalah)"
			ket.text = "Ketuk sekali lagi untuk keluar. Duel dihitung kalah."
			return
		_keluar_adu())


func _keluar_adu() -> void :
	main = false
	if not latihan:
		while _rekaman_saya.size() <= int(durasi):
			_rekaman_saya.append(omzet)
		AduLaris.catat_hasil("kalah", omzet, _rekaman_saya, String(lawan.get("nama", "")))
	selesai.emit(0.0)
	queue_free()


func _kartu_tim(foto: int, nama: String, warna: Color, kanan: bool) -> Array:
	var kartu: = PanelContainer.new()
	kartu.add_theme_stylebox_override("panel", _kotak_timbul(warna, warna.lightened(0.45), 18, 7))
	kartu.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var h: = HBoxContainer.new()
	h.add_theme_constant_override("separation", 12)
	h.alignment = BoxContainer.ALIGNMENT_END if kanan else BoxContainer.ALIGNMENT_BEGIN
	kartu.add_child(h)
	var f: = FP.bulat(foto, 74, Color.WHITE, nama)
	var kolom: = VBoxContainer.new()
	kolom.add_theme_constant_override("separation", -4)
	kolom.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var l_nama: = GH.label(nama, 18, Color(1, 1, 1, 0.95), true, 4)
	l_nama.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	l_nama.clip_text = true
	l_nama.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	var l_omzet: = GH.label("Rp0", 36, Color.WHITE, true, 7)
	var l_bawah: = GH.label("", 15, GH.KUNING, true, 4)
	for l: Label in [l_nama, l_omzet, l_bawah]:
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT if kanan else HORIZONTAL_ALIGNMENT_LEFT
		kolom.add_child(l)
	if kanan:
		h.add_child(kolom)
		h.add_child(f)
	else:
		h.add_child(f)
		h.add_child(kolom)
	return [kartu, l_omzet, l_bawah]


func _pasang_pita_atas() -> void :
	var baris: = HBoxContainer.new()
	baris.add_theme_constant_override("separation", 10)
	baris.position = Vector2(16, 8)
	baris.size = Vector2(LAYAR.x - 32, 96)
	baris.custom_minimum_size = baris.size
	_arena.add_child(baris)
	var nama_saya: String = GameState.nama_warung_lengkap() if GameState.nama_warung != "" else "Warungmu"
	var kiri: = _kartu_tim(_foto_saya, nama_saya, HIJAU_TIM, false)
	baris.add_child(kiri[0])
	_label_skor = kiri[1]
	_label_combo = kiri[2]

	var tengah: = Control.new()
	tengah.custom_minimum_size = Vector2(118, 96)
	baris.add_child(tengah)
	_lingkar_detik = Panel.new()
	var gl: = StyleBoxFlat.new()
	gl.bg_color = Color(0.09, 0.1, 0.2)
	gl.border_color = GH.KUNING
	gl.set_border_width_all(5)
	gl.set_corner_radius_all(48)
	gl.shadow_color = Color(0, 0, 0, 0.5)
	gl.shadow_size = 10
	_lingkar_detik.add_theme_stylebox_override("panel", gl)
	_lingkar_detik.size = Vector2(96, 96)
	_lingkar_detik.position = Vector2(11, 0)
	_lingkar_detik.pivot_offset = Vector2(48, 48)
	tengah.add_child(_lingkar_detik)
	_label_detik = GH.label("60", 44, Color.WHITE, true, 6)
	_label_detik.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label_detik.position = Vector2(0, 8)
	_label_detik.size = Vector2(96, 52)
	_lingkar_detik.add_child(_label_detik)
	var l_detik: = GH.label("DETIK", 13, GH.KUNING, true, 3)
	l_detik.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l_detik.position = Vector2(0, 60)
	l_detik.size = Vector2(96, 18)
	_lingkar_detik.add_child(l_detik)
	var kanan: = _kartu_tim(int(lawan.get("foto", 0)), "%s · Lv %d" % [String(lawan.get("nama", "Lawan")), int(lawan.get("level", 1))], JINGGA_TIM, true)
	baris.add_child(kanan[0])
	_omzet_lawan = kanan[1]
	(kanan[2] as Label).text = "Rekaman warung"
	(kanan[2] as Label).add_theme_color_override("font_color", Color(1, 0.95, 0.85))
	var jeda: = Button.new()
	jeda.text = "II"
	jeda.tooltip_text = "Jeda"
	jeda.theme_type_variation = &"TombolKayu"
	jeda.custom_minimum_size = Vector2(70, 70)
	jeda.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	jeda.add_theme_font_size_override("font_size", 28)
	jeda.pressed.connect(_atur_jeda.bind(true))
	baris.add_child(jeda)

	_tarik = ProgressBar.new()
	_tarik.show_percentage = false
	_tarik.max_value = 1.0
	_tarik.value = 0.5
	_tarik.position = Vector2(110, 112)
	_tarik.size = Vector2(LAYAR.x - 300, 16)
	var isi: = StyleBoxFlat.new()
	isi.bg_color = Color(0.42, 0.85, 0.42)
	isi.set_corner_radius_all(8)
	var dasar: = StyleBoxFlat.new()
	dasar.bg_color = Color(1, 0.6, 0.25)
	dasar.set_corner_radius_all(8)
	dasar.border_color = Color(0, 0, 0, 0.5)
	dasar.set_border_width_all(2)
	_tarik.add_theme_stylebox_override("fill", isi)
	_tarik.add_theme_stylebox_override("background", dasar)
	_arena.add_child(_tarik)
	_status_adu = GH.label("", 16, Color.WHITE, true, 4)
	_status_adu.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status_adu.position = Vector2(LAYAR.x / 2.0 - 150, 126)
	_status_adu.size = Vector2(300, 22)
	_arena.add_child(_status_adu)

	_bar = ProgressBar.new()
	_bar.visible = false
	_bar.max_value = durasi
	_bar.add_theme_stylebox_override("fill", StyleBoxFlat.new())
	_arena.add_child(_bar)




func _pasang_rak(daftar: Array, judul_rak: String, pos: Vector2, warna_pita: Color) -> void :
	var rak: = PanelContainer.new()
	var g: = _kotak_timbul(Color(0.36, 0.21, 0.1, 0.96), Color(0.7, 0.47, 0.25), 18, 8)
	g.content_margin_left = 10
	g.content_margin_right = 10
	g.content_margin_top = 8
	g.content_margin_bottom = 8
	rak.add_theme_stylebox_override("panel", g)
	rak.position = pos
	_arena.add_child(rak)
	var v: = VBoxContainer.new()
	v.add_theme_constant_override("separation", 0)
	rak.add_child(v)
	var pita: = PanelContainer.new()
	pita.add_theme_stylebox_override("panel", _kotak_timbul(warna_pita, warna_pita.lightened(0.4), 10, 4))
	pita.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var j: = GH.label(judul_rak, 17, Color.WHITE, true, 4)
	j.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pita.add_child(j)
	v.add_child(pita)
	var n: = 0
	for t in 5:
		var baris: = HBoxContainer.new()
		baris.add_theme_constant_override("separation", 6)
		baris.alignment = BoxContainer.ALIGNMENT_CENTER
		v.add_child(baris)
		for k in 2:
			if n < daftar.size():
				baris.add_child(_buat_barang(String(daftar[n])))
			n += 1

		var papan: = Panel.new()
		var gp: = StyleBoxFlat.new()
		gp.bg_color = Color(0.74, 0.5, 0.27)
		gp.border_color = Color(0.3, 0.17, 0.07)
		gp.border_width_bottom = 3
		gp.set_corner_radius_all(3)
		papan.add_theme_stylebox_override("panel", gp)
		papan.custom_minimum_size = Vector2(0, 9)
		papan.mouse_filter = Control.MOUSE_FILTER_IGNORE
		v.add_child(papan)


func _buat_barang(id: String) -> Button:
	var b: = GameState.data_barang(id)
	var tombol: = Button.new()
	tombol.flat = true
	tombol.focus_mode = Control.FOCUS_NONE
	tombol.custom_minimum_size = SEL
	tombol.pivot_offset = SEL / 2.0
	var tex: Texture2D = load("res://assets/barang/%s.png" % id)
	var gambar: = TextureRect.new()
	gambar.texture = tex
	gambar.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	gambar.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	gambar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	gambar.size = Vector2(SEL.x - 16, SEL.y - 40)
	gambar.position = Vector2(8, 2)
	tombol.add_child(gambar)
	var nama: = GH.label(String(b.get("sebutan", b["nama"])).capitalize(), 13, Color.WHITE, true, 4)
	nama.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nama.mouse_filter = Control.MOUSE_FILTER_IGNORE
	nama.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	nama.clip_text = true
	nama.position = Vector2(0, SEL.y - 40)
	nama.size = Vector2(SEL.x, 18)
	tombol.add_child(nama)

	var label_harga: = PanelContainer.new()
	var gh: = StyleBoxFlat.new()
	gh.bg_color = Color(1.0, 0.84, 0.3)
	gh.border_color = Color(0.55, 0.32, 0.05)
	gh.border_width_bottom = 2
	gh.set_corner_radius_all(7)
	gh.content_margin_left = 8
	gh.content_margin_right = 8
	label_harga.add_theme_stylebox_override("panel", gh)
	label_harga.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var harga: = Label.new()
	harga.text = GameState.format_rupiah(AduLaris.harga(id))
	harga.add_theme_font_override("font", GH.cetak())
	harga.add_theme_font_size_override("font_size", 14)
	harga.add_theme_color_override("font_color", Color(0.3, 0.16, 0.02))
	harga.add_theme_constant_override("outline_size", 0)
	harga.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label_harga.add_child(harga)
	tombol.add_child(label_harga)
	label_harga.reset_size()
	label_harga.position = Vector2((SEL.x - label_harga.size.x) / 2.0, SEL.y - 21)
	tombol.set_drag_forwarding( func(_p: Vector2) -> Variant:
		if not main or _dijeda:
			return null
		tombol.set_drag_preview(PRATINJAU.buat(tex, String(b.get("sebutan", b["nama"])).capitalize(), _kresek))
		GameState.klik()
		return {"barang": id}, Callable(), Callable())
	tombol.pressed.connect( func():
		if main and not _dijeda:
			_masuk_kresek(id, tombol))

	tombol.button_down.connect( func():
		tombol.create_tween().tween_property(tombol, "scale", Vector2.ONE * 0.9, 0.06))
	tombol.button_up.connect( func():
		tombol.create_tween().tween_property(tombol, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT))
	_tombol[id] = tombol
	return tombol


func _pasang_pembeli() -> void :

	_potret = Control.new()
	_potret.size = Vector2(JARI * 2, JARI * 2)
	_potret.position = POTRET - _potret.size / 2.0
	_potret.pivot_offset = _potret.size / 2.0
	_potret.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_arena.add_child(_potret)
	_nama_pembeli = GH.label("", 20, Color.WHITE, true, 4)
	_nama_pembeli.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_nama_pembeli.position = Vector2(POTRET.x - 150, POTRET.y + JARI + 22)
	_nama_pembeli.size = Vector2(300, 26)
	_nama_pembeli.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_arena.add_child(_nama_pembeli)

	var gelembung: = PanelContainer.new()
	var g: = StyleBoxFlat.new()
	g.bg_color = Color(1, 1, 1, 0.95)
	g.set_corner_radius_all(16)
	g.content_margin_left = 14
	g.content_margin_right = 14
	g.content_margin_top = 8
	g.content_margin_bottom = 8
	gelembung.add_theme_stylebox_override("panel", g)
	gelembung.position = Vector2(POTRET.x + JARI + 4, POTRET.y - JARI - 4)
	gelembung.custom_minimum_size = Vector2(196, 0)
	gelembung.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_arena.add_child(gelembung)
	_ucapan = Label.new()
	_ucapan.add_theme_font_override("font", GH.cetak())
	_ucapan.add_theme_font_size_override("font_size", 20)
	_ucapan.add_theme_color_override("font_color", Color(0.08, 0.05, 0.02))
	_ucapan.add_theme_constant_override("outline_size", 0)
	_ucapan.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_ucapan.custom_minimum_size.x = 168
	gelembung.add_child(_ucapan)



func _pasang_meja() -> void :
	var meja: = Panel.new()
	var gm: = StyleBoxFlat.new()
	gm.bg_color = Color(0.44, 0.27, 0.13)
	gm.border_color = Color(0.78, 0.55, 0.3)
	gm.border_width_top = 12
	gm.border_width_left = 3
	gm.border_width_right = 3
	gm.set_corner_radius_all(16)
	gm.shadow_color = Color(0, 0, 0, 0.5)
	gm.shadow_size = 12
	meja.add_theme_stylebox_override("panel", gm)
	meja.position = Vector2(372, 566)
	meja.size = Vector2(536, 144)
	meja.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_arena.add_child(meja)

	_nota = PanelContainer.new()
	var gk: = StyleBoxFlat.new()
	gk.bg_color = Color(1.0, 0.93, 0.52)
	gk.set_corner_radius_all(3)
	gk.shadow_color = Color(0, 0, 0, 0.35)
	gk.shadow_size = 6
	gk.shadow_offset = Vector2(3, 5)
	gk.content_margin_left = 14
	gk.content_margin_right = 14
	gk.content_margin_top = 22
	gk.content_margin_bottom = 12
	_nota.add_theme_stylebox_override("panel", gk)
	_nota.position = Vector2(384, 372)
	_nota.custom_minimum_size = Vector2(262, 0)
	_nota.rotation_degrees = -3.0
	_nota.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_arena.add_child(_nota)
	var isi_nota: = VBoxContainer.new()
	isi_nota.add_theme_constant_override("separation", 4)
	_nota.add_child(isi_nota)
	var jn: = Label.new()
	jn.text = "PESANAN"
	jn.add_theme_font_override("font", GH.cetak())
	jn.add_theme_font_size_override("font_size", 22)
	jn.add_theme_color_override("font_color", Color(0.55, 0.12, 0.08))
	jn.add_theme_constant_override("outline_size", 0)
	jn.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	isi_nota.add_child(jn)
	_nota_baris = VBoxContainer.new()
	_nota_baris.add_theme_constant_override("separation", 2)
	isi_nota.add_child(_nota_baris)
	var paku: = Panel.new()
	var gp: = StyleBoxFlat.new()
	gp.bg_color = Color(0.85, 0.18, 0.15)
	gp.set_corner_radius_all(9)
	paku.add_theme_stylebox_override("panel", gp)
	paku.size = Vector2(18, 18)
	paku.position = _nota.position + Vector2(116, 2)
	paku.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_arena.add_child(paku)

	var zona: = Control.new()
	zona.position = Vector2(640, 330)
	zona.size = Vector2(280, 380)
	zona.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_arena.add_child(zona)
	_kresek = SCRIPT_KRESEK.new()
	_kresek.custom_minimum_size = Vector2.ONE * UKURAN_KRESEK
	_kresek.size = _kresek.custom_minimum_size
	_kresek.position = Vector2(648, 420)
	_kresek.pivot_offset = _kresek.size * Vector2(0.5, 0.85)
	_arena.add_child(_kresek)
	zona.set_drag_forwarding(Callable(), 
		func(posisi: Vector2, data: Variant) -> bool: return _kresek._can_drop_data(posisi, data), 
		func(posisi: Vector2, data: Variant) -> void : _kresek._drop_data(posisi, data))
	_kresek.dijatuhi.connect( func(id: String):
		if main and not _dijeda:
			_masuk_kresek(id, null))
	_kresek.diketuk.connect( func():
		if not main or _dijeda or _isi.is_empty():
			return
		GameState.klik()
		_isi.clear()
		_kresek.atur_isi(_isi)
		_perbarui_nota())
	var ket: = GH.label("Ketuk kresek untuk mengosongkan", 14, Color(1, 1, 1, 0.75), false, 3)
	ket.position = Vector2(640, 686)
	ket.size = Vector2(280, 20)
	ket.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ket.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_arena.add_child(ket)


func _process(delta: float) -> void :
	super (delta)

	var seret: = get_viewport().gui_is_dragging()
	_kresek.siap = seret and main
	_perbarui_pita()


func _perbarui_pita() -> void :
	var dia: = _lawan_omzet()

	var tujuan: = float(omzet + 5000) / float(omzet + dia + 10000)
	_tarik.value = lerpf(_tarik.value, tujuan, 0.12)
	_omzet_lawan.text = GameState.format_rupiah(dia)

	var detik: = int(ceil(sisa)) if _sudah_mulai else int(durasi)
	detik = clampi(detik, 0, int(durasi))
	if _label_detik.text != str(detik):
		_label_detik.text = str(detik)
		if detik <= 10 and _sudah_mulai and main:
			_lingkar_detik.scale = Vector2.ONE * 1.15
			_lingkar_detik.create_tween().tween_property(_lingkar_detik, "scale", Vector2.ONE, 0.25)
	_label_detik.add_theme_color_override("font_color", Color(1, 0.4, 0.35) if detik <= 10 else Color.WHITE)

	if _beruntun_jual >= 3:
		_label_combo.text = tr("Beruntun x%d · omzet +%d%%") % [_beruntun_jual, 20 if _beruntun_jual >= 6 else 10]
	elif _beruntun_jual > 0:
		_label_combo.text = tr("Beruntun x%d") % _beruntun_jual
	else:
		_label_combo.text = "Layani 3x berturut = bonus!"
	_status_adu.text = GameState.tk("Kamu memimpin!") if omzet > dia else (GameState.tk("Kejar!") if omzet < dia else GameState.tk("Imbang"))
	_status_adu.add_theme_color_override("font_color", GH.HIJAU_UANG if omzet > dia else (Color(1, 0.68, 0.35) if omzet < dia else Color.WHITE))


func _lawan_omzet() -> int:
	var r: Array = lawan.get("rekaman", [0])
	var detik: = clampi(int(durasi - sisa) if _sudah_mulai else 0, 0, r.size() - 1)
	return int(r[detik])




func _sekarang() -> Dictionary:
	return _pembeli[mini(_ke, _pembeli.size() - 1)]


func _pembeli_baru(i: int) -> void :
	_ke = i
	_isi.clear()
	if _kresek != null:
		_kresek.atur_isi(_isi)
	var p: = _sekarang()
	_sabar_penuh = AduLaris.sabar(durasi - sisa if main else 0.0, bool(p["borong"]), AduLaris.jumlah_barang(p["pesanan"]))
	_sabar = _sabar_penuh
	_masuk = 1.0
	for anak in _potret.get_children():
		anak.queue_free()
	var tx: Texture2D = load("res://assets/potret/warga_%s.png" % String(p["npc"])) if ResourceLoader.exists("res://assets/potret/warga_%s.png" % String(p["npc"])) else null
	var foto: = _bulat(tx, JARI * 2)
	foto.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_potret.add_child(foto)
	_potret.scale = Vector2(0.6, 0.6)
	_potret.modulate.a = 0.0
	var tw: = _potret.create_tween().set_parallel()
	tw.tween_property(_potret, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(_potret, "modulate:a", 1.0, 0.2)
	_nama_pembeli.text = _nama_warga(String(p["npc"])) + ("  ·  BORONGAN" if bool(p["borong"]) else "")
	_nama_pembeli.add_theme_color_override("font_color", GH.KUNING if bool(p["borong"]) else Color.WHITE)
	var pesanan: Array = []
	for id in p["pesanan"]:
		pesanan.append([id, int(p["pesanan"][id])])
	_ucapan.text = GameState.kalimat_pesanan(pesanan)
	_perbarui_nota()


func _nama_warga(npc: String) -> String:
	var n: = FP.DAFTAR.map( func(x): return String(x[0])).find("warga_" + npc)
	return FP.nama(n) if n > 0 else npc.capitalize()


func _perbarui_nota() -> void :
	for anak in _nota_baris.get_children():
		anak.queue_free()
	var pesanan: Dictionary = _sekarang()["pesanan"]
	for id in pesanan:
		var perlu: = int(pesanan[id])
		var ada: = int(_isi.get(id, 0))
		var h: = HBoxContainer.new()
		h.add_theme_constant_override("separation", 6)
		_nota_baris.add_child(h)
		var ikon: = TextureRect.new()
		ikon.texture = load("res://assets/barang/%s.png" % id)
		ikon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ikon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		ikon.custom_minimum_size = Vector2(34, 34)
		h.add_child(ikon)
		var b: Dictionary = GameState.katalog[id]
		var selesai_ini: = ada >= perlu
		var warna: = Color(0.05, 0.42, 0.1) if selesai_ini else Color(0.12, 0.07, 0.03)
		var nama: = Label.new()
		nama.text = ("✔ " if selesai_ini else "") + GameState.tk(String(b.get("sebutan", b["nama"]))).capitalize()
		nama.add_theme_font_override("font", GH.cetak())
		nama.add_theme_font_size_override("font_size", 20)
		nama.add_theme_color_override("font_color", warna)
		nama.add_theme_constant_override("outline_size", 0)
		nama.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(nama)
		var jml: = Label.new()
		jml.text = "%d/%d" % [ada, perlu]
		jml.add_theme_font_override("font", GH.cetak())
		jml.add_theme_font_size_override("font_size", 22)
		jml.add_theme_color_override("font_color", warna)
		jml.add_theme_constant_override("outline_size", 0)
		h.add_child(jml)



func _masuk_kresek(id: String, tombol: Button) -> void :
	if _masuk > 0.0:
		return
	GameState.klik()
	if tombol != null:
		_terbang(tombol, id)
	var pesanan: Dictionary = _sekarang()["pesanan"]

	if not pesanan.has(id) or int(_isi.get(id, 0)) + 1 > int(pesanan[id]):
		_salah()
		return
	_isi[id] = int(_isi.get(id, 0)) + 1
	_kresek.atur_isi(_isi)
	_kresek.pantul()
	GameState.bunyi("kresek", -2.0)
	_perbarui_nota()
	if _isi == pesanan:
		_terlayani()


func _terbang(tombol: Button, id: String) -> void :
	var g: = TextureRect.new()
	g.texture = load("res://assets/barang/%s.png" % id)
	g.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	g.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	g.size = Vector2(80, 80)
	g.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_arena.add_child(g)
	var balik: = _arena.get_global_transform().affine_inverse()
	var dari: Vector2 = balik * tombol.get_global_rect().get_center() - g.size / 2.0
	var ke: = _kresek.position + _kresek.size * Vector2(0.5, 0.45) - g.size / 2.0
	g.position = dari
	var tw: = g.create_tween().set_parallel()
	tw.tween_property(g, "position", ke, 0.22).set_ease(Tween.EASE_IN)
	tw.tween_property(g, "scale", Vector2(0.6, 0.6), 0.22)
	tw.chain().tween_callback(g.queue_free)


func _salah() -> void :
	_beruntun_jual = 0
	_beruntun = 0
	_guncang = 0.8
	_sabar = maxf(_sabar - 2.0, 0.3)
	GameState.bunyi("salah")
	kilat(POTRET + Vector2(0, - JARI - 30), "Bukan itu, Pak!", Color(1, 0.45, 0.35))
	if OS.has_feature("mobile"):
		Input.vibrate_handheld(60)


func _terlayani() -> void :
	var pesanan: Dictionary = _sekarang()["pesanan"]
	_beruntun_jual += 1
	_beruntun += 1
	var tip: = AduLaris.tip_cepat(_sabar)
	var dapat: = int(round(AduLaris.nilai_pesanan(pesanan) * AduLaris.pengali_beruntun(_beruntun_jual))) + tip
	omzet += dapat
	_dilayani += 1
	GameState.bunyi("koin")
	var tengah_kresek: = _kresek.position + _kresek.size * Vector2(0.5, 0.4)
	kilat(tengah_kresek, "+" + GameState.format_rupiah(dapat), GH.HIJAU_UANG)
	if tip >= 300:
		kilat(tengah_kresek + Vector2(0, 46), "Tip cepat +%s" % GameState.format_rupiah(tip), GH.KUNING)
	percik(tengah_kresek, GH.KUNING, 16, 6.0)
	if _beruntun_jual == 3 or _beruntun_jual == 6:
		kilat(Vector2(LAYAR.x / 2.0, 150), "Beruntun %d! Omzet +%d%%" % [_beruntun_jual, 10 if _beruntun_jual == 3 else 20], GH.KUNING)
	_perbarui_skor()
	_label_skor.pivot_offset = _label_skor.size / 2.0
	_label_skor.scale = Vector2.ONE * 1.25
	create_tween().tween_property(_label_skor, "scale", Vector2.ONE, 0.2)
	_pembeli_berikut()



func _pembeli_berikut() -> void :
	if _ke + 1 >= _pembeli.size():
		kilat(Vector2(LAYAR.x / 2.0, 300), "Semua pembeli terlayani!", GH.KUNING)
		sisa = 0.0
		return
	_pembeli_baru(_ke + 1)




func _main(delta: float) -> void :
	_masuk = maxf(_masuk - delta * 3.5, 0.0)
	while _detik_rekam <= int(durasi - sisa) and _detik_rekam <= int(durasi):
		_rekaman_saya.append(omzet)
		_detik_rekam += 1
	if _masuk > 0.0:
		return
	_sabar -= delta
	if _sabar <= 0.0:
		_kabur += 1
		_beruntun_jual = 0
		_beruntun = 0
		kilat(POTRET + Vector2(0, - JARI - 30), "Kelamaan, Pak!", Color(1, 0.45, 0.35))
		GameState.bunyi("salah")
		_pembeli_berikut()



func _gambar() -> void :
	var r: = Rect2(POTRET.x - 90, POTRET.y + JARI + 6, 180, 12)
	kotak_bulat(r, Color(0, 0, 0, 0.5), 6)
	var f: = clampf(_sabar / _sabar_penuh, 0.0, 1.0)
	var w: = GH.HIJAU_UANG if f > 0.5 else (GH.KUNING if f > 0.25 else GH.MERAH)
	if f > 0.03:
		kotak_bulat(Rect2(r.position, Vector2(r.size.x * f, r.size.y)), w, 6)


func _gambar_semua() -> void :
	_arena.position += Vector2(randf_range(-1, 1), randf_range(-1, 1)) * 6.0 * _guncang if _guncang > 0.01 else Vector2.ZERO
	if _guncang <= 0.01:
		_atur_skala()
	_gambar()
	if not _sudah_mulai:
		_gambar_contoh()
	for p in _partikel:
		var a: = 1.0 - float(p[3]) / 0.7
		kanvas.draw_circle(p[0], float(p[4]) * (0.5 + a * 0.5), Color(p[2], a))
	var f: = GH.cetak()
	for k in _kilat:
		var a: = 1.0 - float(k[3]) / 0.8
		var p: Vector2 = k[0] + Vector2(0, -40 * float(k[3]))
		kanvas.draw_string_outline(f, p + Vector2(-210, 0), GameState.tk(String(k[1])), HORIZONTAL_ALIGNMENT_CENTER, 420, 38, 8, Color(0, 0, 0, a * 0.8))
		kanvas.draw_string(f, p + Vector2(-210, 0), GameState.tk(String(k[1])), HORIZONTAL_ALIGNMENT_CENTER, 420, 38, Color(k[2], a))


func _gambar_contoh() -> void :
	var w: = fmod(Time.get_ticks_msec() / 1000.0, 1.4) / 1.4
	var tombol: Button = _tombol[String(contoh["id"])]
	var balik: = _arena.get_global_transform().affine_inverse()
	var dari: Vector2 = balik * tombol.get_global_rect().get_center()
	var ke: Vector2 = _kresek.position + _kresek.size * Vector2(0.5, 0.6)
	var p: = dari.lerp(ke, ease(clampf(w * 1.3, 0.0, 1.0), -2.0))
	gambar_tekstur(String(contoh.get("benda", "")), p + Vector2(-30, -40), 70)
	kanvas.draw_dashed_line(dari, ke, Color(1, 1, 1, 0.5), 3, 10)
	kanvas.draw_circle(p, 26, Color(1, 1, 1, 0.25))
	_tangan(p + Vector2(10, 14))
	teks(Vector2(LAYAR.x / 2.0, 545), String(contoh.get("teks", "")), 30, Color.WHITE, 900, 8)




func _akhiri() -> void :
	while _rekaman_saya.size() <= int(durasi):
		_rekaman_saya.append(omzet)
	var dia: = _lawan_omzet()
	var hasil: = "menang" if omzet > dia else ("kalah" if omzet < dia else "seri")
	var trofi: = 0
	if not latihan:
		trofi = AduLaris.catat_hasil(hasil, omzet, _rekaman_saya, String(lawan.get("nama", "")))
		AduLaris.kirim_ke_server(omzet, _dilayani, hasil, _rekaman_saya)
	var data: = AduLaris.data_pemain()
	_kresek.siap = false
	_pantul("WAKTU HABIS!")
	GameState.bunyi("koin")
	await GameState.get_tree().create_timer(0.9, true, false, true).timeout
	_label_tengah.text = ""
	var lapis: = ColorRect.new()
	lapis.color = Color(0, 0, 0, 0.0)
	lapis.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(lapis)
	create_tween().tween_property(lapis, "color:a", 0.7, 0.25)
	var tengah: = CenterContainer.new()
	tengah.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	lapis.add_child(tengah)
	var kartu: = GH.panel_emas(Vector4(44, 26, 44, 26))
	lapis.theme = GH.tema_jendela_emas()
	tengah.add_child(kartu)
	var kolom: = VBoxContainer.new()
	kolom.add_theme_constant_override("separation", 12)
	kartu.add_child(kolom)
	var judul_hasil: = {"menang": "MENANG!", "kalah": "KALAH...", "seri": "SERI!"}[hasil] as String
	var warna_judul: = GH.KUNING if hasil == "menang" else (Color.WHITE if hasil == "seri" else Color(1, 0.6, 0.5))
	var j: = GH.label(judul_hasil, 64, warna_judul, true, 8)
	j.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	kolom.add_child(j)
	var adu: = HBoxContainer.new()
	adu.alignment = BoxContainer.ALIGNMENT_CENTER
	adu.add_theme_constant_override("separation", 36)
	kolom.add_child(adu)
	adu.add_child(_kolom_skor(_foto_saya, "Kamu", omzet, GH.HIJAU_UANG, tr("%d pembeli dilayani") % _dilayani))
	adu.add_child(GH.label("VS", 40, GH.KUNING, true))
	adu.add_child(_kolom_skor(int(lawan.get("foto", 0)), "%s (Lv %d)" % [String(lawan.get("nama", "Lawan")), int(lawan.get("level", 1))], dia, Color(1, 0.7, 0.4), "rekaman warung"))
	var t: = GH.label((tr("+%d trofi") % trofi) if trofi > 0 else "Belum dapat trofi kali ini", 30, GH.KUNING if trofi > 0 else Color.WHITE, true)
	if latihan:
		t.text = tr("Latihan: %d pembeli dilayani") % _dilayani
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	kolom.add_child(t)
	if latihan:
		var ket_latihan: = GH.label("Hasil latihan tidak masuk papan dan tidak memakai kesempatan duel.", 18, Color(1, 1, 1, 0.75))
		ket_latihan.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		kolom.add_child(ket_latihan)
		var baris_tombol: = HBoxContainer.new()
		baris_tombol.alignment = BoxContainer.ALIGNMENT_CENTER
		baris_tombol.add_theme_constant_override("separation", 18)
		kolom.add_child(baris_tombol)
		for pilihan in [["Latihan lagi", &"TombolHijau", 2.0], ["Selesai", &"TombolKayu", 0.0]]:
			var b: = Button.new()
			b.text = pilihan[0]
			b.theme_type_variation = pilihan[1]
			b.custom_minimum_size = Vector2(240, 62)
			b.add_theme_font_size_override("font_size", 26)
			var nilai_tombol: float = pilihan[2]
			b.pressed.connect( func():
				selesai.emit(nilai_tombol)
				queue_free())
			baris_tombol.add_child(b)
		kartu.pivot_offset = kartu.size / 2.0
		kartu.scale = Vector2.ONE * 0.85
		create_tween().tween_property(kartu, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		return
	var ringkas: = tr("Trofi kamu: %d  ·  Menang %d, Kalah %d") % [int(data["trofi"]), int(data["menang"]), int(data["kalah"])]
	if int(data["beruntun"]) >= 2:
		ringkas += tr("  ·  Menang %dx beruntun!") % int(data["beruntun"])
	var r: = GH.label(ringkas, 20, Color(1, 1, 1, 0.85))
	r.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	kolom.add_child(r)
	var k: = GH.label((tr("Sisa kesempatan hari ini: %d dari %d") % [AduLaris.sisa_kesempatan(), AduLaris.MAKS_MAIN]) + tr("  ·  Waktu berjalan 1 jam"), 18, Color(1, 1, 1, 0.7))
	k.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	kolom.add_child(k)
	var tombol: = Button.new()
	tombol.text = "Lanjut"
	tombol.theme_type_variation = &"TombolHijau"
	tombol.custom_minimum_size = Vector2(280, 66)
	tombol.add_theme_font_size_override("font_size", 30)
	tombol.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var nilai: = 1.0 if hasil == "menang" else (0.5 if hasil == "seri" else 0.0)
	tombol.pressed.connect( func():
		selesai.emit(nilai)
		queue_free())
	kolom.add_child(tombol)
	kartu.pivot_offset = kartu.size / 2.0
	kartu.scale = Vector2.ONE * 0.85
	create_tween().tween_property(kartu, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _kolom_skor(foto: int, nama: String, nilai: int, warna: Color, ket: String) -> VBoxContainer:
	var v: = VBoxContainer.new()
	v.add_theme_constant_override("separation", 2)
	var f: = FP.bulat(foto, 84, warna, GameState.nama_warung_lengkap() if nama == "Kamu" else nama)
	f.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(f)
	for isi in [[nama, 22, Color.WHITE], [GameState.format_rupiah(nilai), 40, warna], [ket, 16, Color(1, 1, 1, 0.65)]]:
		var l: = GH.label(String(isi[0]), int(isi[1]), isi[2], int(isi[1]) >= 40)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED if isi[0] == nama else Node.AUTO_TRANSLATE_MODE_INHERIT
		v.add_child(l)
	return v
