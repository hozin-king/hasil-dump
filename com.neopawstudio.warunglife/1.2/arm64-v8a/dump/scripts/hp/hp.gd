extends Control












const UI: = preload("res://scripts/hp/hp_ui.gd")
const UKURAN_HP: = Vector2(410, 700)


const DAFTAR_APLIKASI: = {
	"wasap": ["Wasap", Color(0.18, 0.62, 0.35), "res://assets/ikon/chat.svg", "res://scripts/hp/app_wasap.gd"], 
	"mbanking": ["Warga Bank", Color(0.04, 0.37, 0.69), "res://assets/ikon/warga_bank.svg", "res://scripts/hp/app_mbanking.gd"], 
	"belanja": ["Belanja Online", Color(0.95, 0.5, 0.15), "res://assets/ikon/keranjang.svg", "res://scripts/hp/app_belanja.gd"], 
	"hadiah": ["Hadiah", Color(0.92, 0.36, 0.5), "res://assets/ikon/hadiah.svg", ""], 
	"harga": ["Harga Jual", Color(0.75, 0.25, 0.2), "res://assets/ikon/harga.svg", "res://scripts/hp/app_harga.gd"], 
	"upgrade": ["Upgrade Warung", Color(0.45, 0.3, 0.18), "res://assets/ikon/toko.svg", "res://scripts/hp/app_upgrade.gd"], 
	"bukukas": ["Buku Kas", Color(0.3, 0.55, 0.3), "res://assets/ikon/bukukas.svg", "res://scripts/hp/app_bukukas.gd"], 
	"misi": ["Misi", Color(0.75, 0.25, 0.25), "res://assets/ikon/misi.svg", "res://scripts/hp/app_misi.gd"], 
	"kontak": ["Kontak", Color(0.2, 0.55, 0.5), "res://assets/ikon/kontak.svg", "res://scripts/hp/app_kontak.gd"], 
	"ulasan": ["Ulasan", Color(0.85, 0.6, 0.1), "res://assets/ikon/ulasan.svg", "res://scripts/hp/app_ulasan.gd"], 
	"papan": ["Peringkat Warung", Color(0.55, 0.38, 0.78), "res://assets/ikon/papan.svg", "res://scripts/hp/app_papan.gd"], 
	"kalender": ["Kalender", Color(0.85, 0.3, 0.25), "res://assets/ikon/kalender.svg", "res://scripts/hp/app_kalender.gd"], 
	"peta": ["Peta Desa", Color(0.3, 0.55, 0.32), "res://assets/ikon/peta.svg", "res://scripts/hp/app_peta.gd"], 
	"wishlist": ["Wishlist", Color(0.9, 0.35, 0.5), "res://assets/ikon/wishlist.svg", "res://scripts/hp/app_wishlist.gd"], 
	"tas": ["Tas", Color(0.3, 0.5, 0.65), "res://assets/ikon/tas.svg", "res://scripts/hp/app_tas.gd"], 
	"ojol": ["OjekKampung", Color(0.12, 0.42, 0.85), "res://assets/ikon/ojek.svg", "res://scripts/hp/app_ojol.gd"], 
	"kalkulator": ["Kalkulator", Color(0.36, 0.42, 0.38), "res://assets/ikon/kalkulator.svg", "res://scripts/hp/app_kalkulator.gd"], 
	"panduan": ["Panduan", Color(0.23, 0.48, 0.65), "res://assets/ikon/panduan.svg", "res://scripts/hp/app_panduan.gd"], 
}

signal ditutup

var warung: Node
var _layar: Control
var _beranda: Control
var _label_jam: Label
var _label_tanggal: Label
var _aplikasi: = {}
var _lencana_ikon: = {}
var tombol_ikon: = {}
var _aktif: = ""
var tombol_tutup: Button
var tombol_kembali: Button
var _badan: Control
var _redup: ColorRect
var _layar_mati: ColorRect
var _tween: Tween
var _menutup: = false


const APLIKASI_LANDSCAPE: = ["belanja"]
const UKURAN_LANDSCAPE: = Vector2(920, 580)
const SKALA_LANDSCAPE: = 1.18
var _pegangan: Control
var _landscape: = false
var _tween_putar: Tween

var _gaya_badan: StyleBoxFlat
var _pulau: Panel
var _status: PanelContainer
var _label_kanan: Label
var _skin_mewah: = false
var _gloss: = {}


func _ready() -> void :
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	hide()
	var redup: = ColorRect.new()
	redup.color = Color(0.03, 0.02, 0.01, 0.55)
	redup.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(redup)

	redup.gui_input.connect( func(e: InputEvent):
		if (e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT):
			tutup())



	var tengah: = CenterContainer.new()
	tengah.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tengah.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(tengah)
	var pegangan: = Control.new()
	pegangan.custom_minimum_size = UKURAN_HP
	pegangan.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tengah.add_child(pegangan)

	var badan: = UI.panel(Color(0.06, 0.06, 0.07), 52, 12)
	var gaya_badan: = badan.get_theme_stylebox("panel") as StyleBoxFlat
	_gaya_badan = gaya_badan
	gaya_badan.border_color = Color(0.58, 0.59, 0.63)
	gaya_badan.set_border_width_all(4)
	gaya_badan.shadow_color = Color(0, 0, 0, 0.5)
	gaya_badan.shadow_size = 18
	gaya_badan.shadow_offset = Vector2(0, 8)
	badan.mouse_filter = Control.MOUSE_FILTER_STOP

	var tema_hp: = Theme.new()
	tema_hp.set_color("font_color", "Label", Color.WHITE)
	tema_hp.set_font("font", "Label", UI.GH.font("Nunito", 800))

	var tema_tombol: = UI.GH.tema_jendela()
	for nama in ["TombolHijau", "TombolKayu"]:
		tema_hp.set_type_variation(nama, "Button")
		for k in ["normal", "hover", "pressed", "hover_pressed", "disabled", "focus"]:
			tema_hp.set_stylebox(k, nama, tema_tombol.get_stylebox(k, nama))
		tema_hp.set_font("font", nama, tema_tombol.get_font("font", nama))
		for k in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color", "font_focus_color", "font_disabled_color"]:
			tema_hp.set_color(k, nama, tema_tombol.get_color(k, nama))
		tema_hp.set_constant("outline_size", nama, 0)
	badan.theme = tema_hp
	badan.size = UKURAN_HP
	badan.pivot_offset = UKURAN_HP / 2.0
	pegangan.add_child(badan)
	_badan = badan
	_pegangan = pegangan
	_redup = redup
	var susun: = VBoxContainer.new()
	susun.add_theme_constant_override("separation", 0)
	badan.add_child(susun)



	var status: = UI.panel(Color(0.06, 0.06, 0.07), 0, 6)
	_status = status
	susun.add_child(status)
	var baris_status: = HBoxContainer.new()
	status.add_child(baris_status)
	_label_jam = UI.label("07.00", 16, Color(0.95, 0.95, 0.95))
	_label_jam.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	baris_status.add_child(_label_jam)
	_pulau = Panel.new()
	_pulau.mouse_filter = Control.MOUSE_FILTER_IGNORE
	baris_status.add_child(_pulau)
	_label_kanan = UI.label("4G", 14, Color(0.95, 0.95, 0.95))
	_label_kanan.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_label_kanan.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	baris_status.add_child(_label_kanan)


	var bingkai_layar: = UI.panel(UI.WARNA_LAYAR, 34, 0)
	bingkai_layar.size_flags_vertical = Control.SIZE_EXPAND_FILL
	bingkai_layar.clip_contents = true
	susun.add_child(bingkai_layar)
	_layar = Control.new()
	_layar.clip_contents = true
	bingkai_layar.add_child(_layar)
	_buat_beranda()
	_layar_mati = ColorRect.new()
	_layar_mati.color = Color(0.02, 0.02, 0.03)
	_layar_mati.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_layar_mati.modulate.a = 0.0
	bingkai_layar.add_child(_layar_mati)


	var bawah: = HBoxContainer.new()
	bawah.add_theme_constant_override("separation", 8)
	var tepi: = MarginContainer.new()

	tepi.add_theme_constant_override("margin_top", 8)
	tepi.add_theme_constant_override("margin_left", 26)
	tepi.add_theme_constant_override("margin_right", 26)
	tepi.add_theme_constant_override("margin_bottom", 14)
	tepi.add_child(bawah)
	susun.add_child(tepi)
	for t in [["Kembali", _kembali], ["Beranda", func(): buka_aplikasi("")], ["Tutup HP", tutup]]:
		var b: = UI.tombol(t[0], Color(1, 1, 1, 0.12), 17, 40)
		b.add_theme_font_override("font", UI.GH.cetak())
		b.add_theme_font_size_override("font_size", 20)
		b.text = String(t[0]).to_upper()
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.pressed.connect(t[1])
		if t[0] == "Kembali":
			tombol_kembali = b
		if t[0] == "Tutup HP":
			tombol_tutup = b
		bawah.add_child(b)

	_bunyi_buka = AudioStreamPlayer.new()
	_bunyi_buka.stream = UI.GH.bunyi_buka_kunci()
	_bunyi_buka.volume_db = -4.0
	_bunyi_buka.bus = "Suara"
	_bunyi_buka.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_bunyi_buka)
	GameState.data_berubah.connect(_perbarui)
	_terapkan_skin()
	_perbarui()




var _baterai: = -1
var _baterai_dicek_ms: = -100000

func _baca_baterai() -> int:
	var sekarang: = Time.get_ticks_msec()
	if sekarang - _baterai_dicek_ms < 30000:
		return _baterai
	_baterai_dicek_ms = sekarang
	_baterai = -1
	if OS.get_name() != "Android" or not Engine.has_singleton("AndroidRuntime"):
		return _baterai
	var runtime = Engine.get_singleton("AndroidRuntime")
	var aktivitas = runtime.getActivity()
	var kelas = JavaClassWrapper.wrap("android.content.IntentFilter")
	if aktivitas == null or kelas == null:
		return _baterai
	var saring = kelas.IntentFilter("android.intent.action.BATTERY_CHANGED")
	var intent = aktivitas.registerReceiver(null, saring)
	if intent == null:
		return _baterai
	var level: int = intent.getIntExtra("level", -1)
	var skala: int = intent.getIntExtra("scale", 100)
	if level >= 0 and skala > 0:
		_baterai = clampi(roundi(100.0 * level / skala), 0, 100)
	return _baterai


func _teks_baterai() -> String:
	var persen: = _baca_baterai()
	return "4G" if persen < 0 else "4G  %d%%" % persen


func _terapkan_skin() -> void :
	_skin_mewah = GameState.hape_mewah
	var mewah: = _skin_mewah
	_gaya_badan.border_color = Color(0.72, 0.72, 0.76) if mewah else Color(0.24, 0.25, 0.28)
	_gaya_badan.set_corner_radius_all(58 if mewah else 44)
	var gaya_status: = _status.get_theme_stylebox("panel") as StyleBoxFlat


	var radius_badan: = 58 if mewah else 44
	gaya_status.corner_radius_top_left = radius_badan - 14
	gaya_status.corner_radius_top_right = radius_badan - 14
	gaya_status.content_margin_left = 44
	gaya_status.content_margin_right = 44
	gaya_status.content_margin_top = 14
	gaya_status.content_margin_bottom = 6

	_pulau.add_theme_stylebox_override("panel", UI.GH.kotak(Color(0.01, 0.01, 0.01), 13 if mewah else 8))
	_pulau.custom_minimum_size = Vector2(104, 26) if mewah else Vector2(16, 16)
	_pulau.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	for id in _gloss:


		_gloss[id].visible = ikon_cerah(id) and not mewah
		_gaya_ikon(id)
	_terapkan_ios(mewah)



static func ikon_cerah(id: String) -> bool:
	return true


func _gaya_ikon(id: String) -> void :
	var tombol: Button = tombol_ikon[id]
	if not _skin_mewah and ikon_cerah(id):
		for keadaan in ["normal", "hover", "pressed", "focus"]:
			var st: = StyleBoxFlat.new()
			st.bg_color = Color(0, 0, 0, 0)
			st.set_corner_radius_all(18)
			if keadaan != "pressed" and keadaan != "focus":
				st.shadow_color = Color(0, 0, 0, 0.4)
				st.shadow_size = 6
				st.shadow_offset = Vector2(0, 3)
			tombol.add_theme_stylebox_override(keadaan, st)
		return

	if _skin_mewah:
		for keadaan in ["normal", "hover", "pressed", "focus"]:
			tombol.add_theme_stylebox_override(keadaan, StyleBoxEmpty.new())
		return
	var warna: Color = DAFTAR_APLIKASI[id][1]
	for keadaan in ["normal", "hover", "pressed", "focus"]:
		var w: = warna if keadaan != "pressed" else warna.darkened(0.15)
		if _skin_mewah:
			w = w.lightened(0.04)
		var st: = UI.kotak(w, 20 if _skin_mewah else 16, 8)
		if _skin_mewah:
			st.border_color = Color(1, 1, 1, 0.35)
			st.set_border_width_all(2)
			st.shadow_color = Color(0, 0, 0, 0.45)
			st.shadow_size = 6
			st.shadow_offset = Vector2(0, 3)
		if keadaan == "focus":
			st.draw_center = false
		tombol.add_theme_stylebox_override(keadaan, st)





const APLIKASI_DOCK: = ["wasap", "belanja", "peta", "kalender"]
const WARNA_IOS: = {
	"wasap": [Color(0.4, 0.88, 0.45), Color(0.1, 0.65, 0.25)], 
	"mbanking": [Color(0.2, 0.55, 0.92), Color(0.03, 0.28, 0.6)], 
	"belanja": [Color(1.0, 0.68, 0.25), Color(0.95, 0.4, 0.1)], 
	"harga": [Color(1.0, 0.42, 0.4), Color(0.85, 0.15, 0.2)], 
	"upgrade": [Color(0.75, 0.55, 0.35), Color(0.48, 0.3, 0.16)], 
	"bukukas": [Color(0.35, 0.8, 0.6), Color(0.1, 0.55, 0.4)], 
	"misi": [Color(1.0, 0.55, 0.3), Color(0.9, 0.25, 0.3)], 
	"kontak": [Color(0.7, 0.72, 0.76), Color(0.45, 0.47, 0.52)], 
	"ulasan": [Color(1.0, 0.85, 0.3), Color(1.0, 0.6, 0.05)], 
	"kalender": [Color(1.0, 0.42, 0.38), Color(0.92, 0.2, 0.2)], 
	"peta": [Color(0.45, 0.8, 1.0), Color(0.15, 0.5, 0.95)], 
	"wishlist": [Color(1.0, 0.5, 0.7), Color(0.9, 0.2, 0.5)], 
	"tas": [Color(0.45, 0.72, 0.9), Color(0.2, 0.42, 0.62)], 
	"ojol": [Color(0.35, 0.65, 1.0), Color(0.08, 0.33, 0.82)], 
	"kalkulator": [Color(0.62, 0.7, 0.64), Color(0.32, 0.4, 0.35)], 
	"panduan": [Color(0.5, 0.65, 1.0), Color(0.3, 0.35, 0.9)], 
	"hadiah": [Color(1.0, 0.55, 0.65), Color(0.88, 0.25, 0.45)], 
}
const KODE_SHADER_IOS: = "\r\nshader_type canvas_item;\r\nuniform vec4 atas : source_color;\r\nuniform vec4 bawah : source_color;\r\nuniform float gelap = 0.0;\r\nfloat kotak(vec2 p, vec2 b, float r) { vec2 q = abs(p) - b + r; return length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - r; }\r\nvoid fragment() {\r\n\tvec2 p = UV * 2.0 - 1.0;\r\n\tfloat d = kotak(p, vec2(1.0), 0.46);\r\n\tfloat a = 1.0 - smoothstep(-0.03, 0.01, d);\r\n\tvec3 w = mix(atas.rgb, bawah.rgb, UV.y);\r\n\tw += 0.08 * (1.0 - smoothstep(0.0, 0.45, UV.y));\r\n\tw *= 1.0 - gelap;\r\n\tCOLOR = vec4(w, a);\r\n}\r\n"















static var _shader_ios: Shader = null
var _latar_ios: = {}
var _kolom_ikon: = {}
var _label_ikon: = {}
var _dock: Control
var _lencana_dock: = {}
var _titik_halaman: Control
const WALLPAPER: = "res://assets/latar/latar_warung_kosong_basah.png"
var _wallpaper_ios: Texture2D = null
var _widget_atas: PanelContainer


func _latar_ikon_ios(id: String, ukuran: float) -> ColorRect:
	if _shader_ios == null:
		_shader_ios = Shader.new()
		_shader_ios.code = KODE_SHADER_IOS
	var r: = ColorRect.new()
	var m: = ShaderMaterial.new()
	m.shader = _shader_ios
	m.set_shader_parameter("atas", WARNA_IOS.get(id, [Color.GRAY, Color.DIM_GRAY])[0])
	m.set_shader_parameter("bawah", WARNA_IOS.get(id, [Color.GRAY, Color.DIM_GRAY])[1])
	r.material = m
	r.size = Vector2.ONE * ukuran
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r



func _tombol_ios(id: String, ukuran: float) -> Button:
	var t: = Button.new()
	t.custom_minimum_size = Vector2.ONE * ukuran
	t.focus_mode = Control.FOCUS_NONE
	for k in ["normal", "hover", "pressed", "hover_pressed", "focus"]:
		t.add_theme_stylebox_override(k, StyleBoxEmpty.new())
	var latar: = _latar_ikon_ios(id, ukuran)
	t.add_child(latar)
	var glyph: = UI.ikon(load(DAFTAR_APLIKASI[id][2]), ukuran * 0.62)
	glyph.position = Vector2.ONE * ukuran * 0.19
	t.add_child(glyph)
	t.button_down.connect( func(): (latar.material as ShaderMaterial).set_shader_parameter("gelap", 0.18))
	t.button_up.connect( func(): (latar.material as ShaderMaterial).set_shader_parameter("gelap", 0.0))
	t.pressed.connect(buka_aplikasi.bind(id))
	return t


func _buat_dock() -> void :
	var tepi: = MarginContainer.new()
	for k in ["margin_left", "margin_right"]:
		tepi.add_theme_constant_override(k, 12)
	tepi.add_theme_constant_override("margin_bottom", 10)
	_beranda.add_child(tepi)
	var kolom: = VBoxContainer.new()
	kolom.add_theme_constant_override("separation", 8)
	tepi.add_child(kolom)

	_titik_halaman = HBoxContainer.new()
	_titik_halaman.alignment = BoxContainer.ALIGNMENT_CENTER
	_titik_halaman.add_theme_constant_override("separation", 8)
	for i in 2:
		var titik: = Panel.new()
		titik.custom_minimum_size = Vector2(7, 7)
		titik.add_theme_stylebox_override("panel", UI.kotak(Color(1, 1, 1, 0.95 if i == 0 else 0.4), 4, 0))
		_titik_halaman.add_child(titik)
	kolom.add_child(_titik_halaman)
	var dock: = PanelContainer.new()
	var gaya: = UI.kotak(Color(1, 1, 1, 0.22), 30, 12)
	dock.add_theme_stylebox_override("panel", gaya)
	kolom.add_child(dock)
	var baris: = HBoxContainer.new()
	baris.alignment = BoxContainer.ALIGNMENT_CENTER
	baris.add_theme_constant_override("separation", 22)
	dock.add_child(baris)
	for id in APLIKASI_DOCK:
		var t: = _tombol_ios(id, 60)
		var lencana: = UI.lencana()
		UI.GH.gaya_lencana(lencana)
		lencana.position = Vector2(44, -8)
		t.add_child(lencana)
		_lencana_dock[id] = lencana
		baris.add_child(t)
	_dock = tepi



func _terapkan_ios(mewah: bool) -> void :
	if _dock == null:
		return
	_dock.visible = mewah
	for id in _kolom_ikon:
		(_kolom_ikon[id] as Control).visible = not (mewah and id in APLIKASI_DOCK)
		(_latar_ios[id] as Control).visible = mewah or ikon_cerah(id)
		var nama: Label = _label_ikon[id]
		if mewah:
			UI.GH.gaya_label(nama, 13, Color.WHITE, false, 0)
			nama.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.6))
			nama.add_theme_constant_override("shadow_offset_y", 1)
		else:
			UI.GH.gaya_label(nama, 12, Color.WHITE, false, 2)

	if mewah:
		if _wallpaper_ios == null:
			var g: = Gradient.new()
			g.offsets = PackedFloat32Array([0.0, 0.5, 1.0])
			g.colors = PackedColorArray([Color(0.16, 0.2, 0.55), Color(0.55, 0.3, 0.6), Color(0.98, 0.55, 0.4)])
			var tex: = GradientTexture2D.new()
			tex.gradient = g
			tex.fill_from = Vector2(0.2, 0.0)
			tex.fill_to = Vector2(0.8, 1.0)
			tex.width = 256
			tex.height = 512
			_wallpaper_ios = tex
		_wallpaper.texture = _wallpaper_ios
		_wallpaper.modulate = Color.WHITE
	else:
		_wallpaper.texture = load(WALLPAPER)
		_wallpaper.modulate = Color(0.75, 0.75, 0.75)

	if _widget_atas != null:
		_widget_atas.add_theme_stylebox_override("panel", UI.GH.kaca(0.5, 22, Vector4(18, 8, 18, 10)) if not mewah else UI.kotak(Color(1, 1, 1, 0.2), 28, 16))
		var jam: Label = _beranda.find_child("JamBesar", true, false)
		jam.visible = mewah
		UI.GH.gaya_label(jam, 58 if mewah else 20, Color.WHITE, true)


var _wallpaper: TextureRect
var _label_uang: Label
var _label_qris: Label
var _label_level: Label
var _bunyi_buka: AudioStreamPlayer


func _buat_beranda() -> void :

	_wallpaper = TextureRect.new()
	_wallpaper.texture = load(WALLPAPER)
	_wallpaper.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_wallpaper.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_wallpaper.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_wallpaper.modulate = Color(0.75, 0.75, 0.75)
	_wallpaper.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_layar.add_child(_wallpaper)
	_beranda = VBoxContainer.new()
	_beranda.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_beranda.add_theme_constant_override("separation", 10)
	_layar.add_child(_beranda)

	var tepi: = MarginContainer.new()
	for k in ["margin_left", "margin_right", "margin_top"]:
		tepi.add_theme_constant_override(k, 14)
	_beranda.add_child(tepi)
	var atas: = PanelContainer.new()
	atas.add_theme_stylebox_override("panel", UI.GH.kaca(0.5, 22, Vector4(18, 8, 18, 10)))
	_widget_atas = atas
	tepi.add_child(atas)
	var kolom: = VBoxContainer.new()
	kolom.add_theme_constant_override("separation", -4)
	atas.add_child(kolom)
	_label_tanggal = UI.GH.label("", 18, Color(1, 1, 1, 0.85), true)
	kolom.add_child(_label_tanggal)
	var jam_besar: = UI.GH.label("", 20, Color.WHITE, true)
	jam_besar.name = "JamBesar"
	jam_besar.hide()
	kolom.add_child(jam_besar)
	_label_uang = UI.GH.label("", 42, UI.GH.HIJAU_UANG, true)
	kolom.add_child(_label_uang)
	_label_qris = UI.GH.label("", 18, Color(0.72, 0.9, 1.0), true)
	kolom.add_child(_label_qris)
	_label_level = UI.GH.label("", 18, UI.GH.KUNING, true)
	kolom.add_child(_label_level)

	var grid: = GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 4)
	grid.add_theme_constant_override("v_separation", 6)
	var tengah: = CenterContainer.new()
	tengah.add_child(grid)

	var g: Array = UI.gulir(0)

	var jarak_atas: = Control.new()
	jarak_atas.custom_minimum_size.y = 14
	g[1].add_child(jarak_atas)
	g[1].add_child(tengah)
	_beranda.add_child(g[0])
	for id in DAFTAR_APLIKASI:
		grid.add_child(_buat_ikon_aplikasi(id))
	_buat_dock()


func _buat_ikon_aplikasi(id: String) -> Control:
	var data: Array = DAFTAR_APLIKASI[id]
	var kolom: = VBoxContainer.new()
	kolom.add_theme_constant_override("separation", 4)
	kolom.custom_minimum_size.x = 84
	var tombol: = Button.new()
	tombol.custom_minimum_size = Vector2(62, 62)
	tombol.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	tombol.pressed.connect(buka_aplikasi.bind(id))
	var gambar: = UI.ikon(load(data[2]), 40)
	gambar.position = Vector2(11, 11)
	tombol.add_child(gambar)
	var lencana: = UI.lencana()
	UI.GH.gaya_lencana(lencana)
	lencana.position = Vector2(46, -8)
	tombol.add_child(lencana)
	_lencana_ikon[id] = lencana
	tombol_ikon[id] = tombol

	var latar_ios: = _latar_ikon_ios(id, 62)
	latar_ios.visible = false
	tombol.add_child(latar_ios)
	tombol.move_child(latar_ios, 0)
	_latar_ios[id] = latar_ios
	tombol.button_down.connect( func(): (latar_ios.material as ShaderMaterial).set_shader_parameter("gelap", 0.18))
	tombol.button_up.connect( func(): (latar_ios.material as ShaderMaterial).set_shader_parameter("gelap", 0.0))

	var kilap: = Panel.new()
	var gk: = StyleBoxFlat.new()
	gk.bg_color = Color(1, 1, 1, 0.2)
	gk.corner_radius_top_left = 20
	gk.corner_radius_top_right = 20
	kilap.add_theme_stylebox_override("panel", gk)
	kilap.position = Vector2(2, 2)
	kilap.size = Vector2(58, 26)
	kilap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	kilap.visible = false
	tombol.add_child(kilap)
	tombol.move_child(kilap, 1)
	_gloss[id] = kilap
	_gaya_ikon(id)
	kolom.add_child(tombol)

	var nama: = UI.GH.label(String(data[0]).replace(" Online", "").replace(" Warung", "").replace(" Rumah", ""), 12, Color.WHITE, false, 2)
	nama.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	kolom.add_child(nama)
	_label_ikon[id] = nama
	_kolom_ikon[id] = kolom
	return kolom





func _papan_besar_dari_hp() -> bool:
	var adegan: = get_tree().current_scene
	if adegan == null or not adegan.has_method("_buka_papan_besar"):
		return false
	GameState.tandai_dilihat("papan")
	tutup()
	adegan.call_deferred("_buka_papan_besar")
	return true


func buka(id: = "") -> void :

	if id == "papan" and not visible and _papan_besar_dari_hp():
		return
	if visible:
		buka_aplikasi(id)
		return
	show()

	_atur_orientasi(id in APLIKASI_LANDSCAPE, false)
	buka_aplikasi(id)
	_bunyi_buka.play()

	if _tween != null:
		_tween.kill()
	_badan.position = Vector2(0, UKURAN_HP.y + 120)
	_badan.rotation_degrees = -10
	_badan.scale = Vector2(0.92, 0.92) * _skala()
	_redup.modulate.a = 0.0
	_layar_mati.modulate.a = 1.0
	_tween = create_tween().set_parallel(true)
	_tween.tween_property(_redup, "modulate:a", 1.0, 0.25)
	_tween.tween_property(_badan, "position", Vector2.ZERO, 0.38).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tween.tween_property(_badan, "rotation_degrees", 0.0, 0.38).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tween.tween_property(_badan, "scale", Vector2.ONE * _skala(), 0.38).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tween.tween_property(_layar_mati, "modulate:a", 0.0, 0.25).set_delay(0.3)


func tutup() -> void :
	if not visible or _menutup:
		return
	_menutup = true
	if _tween != null:
		_tween.kill()

	_tween = create_tween().set_parallel(true)
	_tween.tween_property(_layar_mati, "modulate:a", 1.0, 0.12)
	_tween.tween_property(_badan, "position", Vector2(0, UKURAN_HP.y + 120), 0.28).set_delay(0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_tween.tween_property(_badan, "rotation_degrees", 8.0, 0.28).set_delay(0.08)
	_tween.tween_property(_redup, "modulate:a", 0.0, 0.25).set_delay(0.1)
	_tween.chain().tween_callback( func():
		hide()
		_menutup = false
		_atur_orientasi(false, false)
		ditutup.emit())


func _skala() -> float:
	return SKALA_LANDSCAPE if _landscape else 1.0





func _atur_orientasi(landscape: bool, animasi: = true) -> void :
	if landscape == _landscape:
		return
	_landscape = landscape
	if _tween_putar != null:
		_tween_putar.kill()
	var ukuran: = UKURAN_LANDSCAPE if landscape else UKURAN_HP
	var terapkan: = func():
		_badan.rotation_degrees = 0.0
		_badan.size = ukuran
		_badan.pivot_offset = ukuran / 2.0
		_pegangan.custom_minimum_size = ukuran
		_badan.scale = Vector2.ONE * _skala()
		for app in _aplikasi.values():
			if app.has_method("atur_orientasi"):
				app.atur_orientasi(landscape)
	if not animasi or not visible:
		terapkan.call()
		return

	var lama: Vector2 = _badan.size * _badan.scale.x
	var tujuan_tampak: = ukuran * (SKALA_LANDSCAPE if landscape else 1.0)
	var skala_putar: = minf(tujuan_tampak.x / lama.y, tujuan_tampak.y / lama.x) * _badan.scale.x
	_tween_putar = create_tween().set_parallel(true)
	_tween_putar.tween_property(_layar_mati, "modulate:a", 1.0, 0.12)
	_tween_putar.tween_property(_badan, "rotation_degrees", -90.0 if landscape else 90.0, 0.35).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	_tween_putar.tween_property(_badan, "scale", Vector2.ONE * skala_putar, 0.35).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	_tween_putar.chain().tween_callback(terapkan)
	_tween_putar.chain().tween_property(_layar_mati, "modulate:a", 0.0, 0.2)


func buka_aplikasi(id: String) -> void :



	if id == "papan" and _papan_besar_dari_hp():
		return

	if id == "hadiah":
		tutup()
		GameState.login_harian.call_deferred("buka_dari_hp", get_tree().current_scene)
		return
	if _aktif != "" and _aplikasi.has(_aktif):
		_aplikasi[_aktif].hide()
	_aktif = id
	_atur_orientasi(id in APLIKASI_LANDSCAPE)
	_beranda.visible = id == ""
	_wallpaper.visible = id == ""
	if id == "":
		_perbarui()
		return
	if not _aplikasi.has(id):
		var app: Control = load(DAFTAR_APLIKASI[id][3]).new()
		app.set("hp", self)
		app.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		_layar.add_child(app)
		_aplikasi[id] = app
		if app.has_method("atur_orientasi"):
			app.atur_orientasi(_landscape)
	_aplikasi[id].show()
	if _aplikasi[id].has_method("tampil"):
		_aplikasi[id].tampil()

	GameState.tandai_dilihat(id)


func _kembali() -> void :

	if _aktif != "" and _aplikasi[_aktif].has_method("kembali") and _aplikasi[_aktif].kembali():
		return
	buka_aplikasi("")


func aplikasi_aktif() -> String:
	return _aktif if visible else ""


func aplikasi(id: String) -> Control:
	return _aplikasi.get(id)





static func jumlah_notif(id: String) -> int:
	match id:
		"wasap":
			return GameState.belum_dibaca()
		"mbanking":

			return GameState.jumlah_notif_baru("mbanking")
		"ojol":

			return GameState.ngojol_order_tampil().size() if GameState.punya_motor_ngojol() and GameState.alasan_tidak_bisa_ngojol() == "" else 0
		"hadiah":
			return 1 if GameState.login_harian != null and GameState.login_harian.ada_hadiah_hari_ini() else 0
		"upgrade", "belanja":

			return GameState.jumlah_notif_tetap(id)

	return GameState.jumlah_notif_baru(id)


static func total_notif() -> int:
	var n: = 0
	for id in DAFTAR_APLIKASI:
		n += jumlah_notif(id)
	return n


func _perbarui() -> void :
	if _label_jam == null:
		return
	if GameState.hape_mewah != _skin_mewah:
		_terapkan_skin()
	_label_kanan.text = _teks_baterai()
	_label_jam.text = GameState.teks_jam().replace(" WIB", "")
	(_beranda.find_child("JamBesar", true, false) as Label).text = _label_jam.text
	_label_tanggal.text = ("%s, %s · %s" % [GameState.nama_hari(), GameState.teks_tanggal(), _label_jam.text]).to_upper()
	_label_uang.text = GameState.format_rupiah(GameState.uang)
	_label_qris.visible = GameState.punya_upgrade("qris") or GameState.saldo_digital > 0
	_label_qris.text = "Saldo QRIS: %s" % GameState.format_rupiah(GameState.saldo_digital)
	_label_level.text = "LEVEL WARUNG %d" % (GameState.tingkat + 1)
	for id in _lencana_ikon:
		UI.atur_lencana(_lencana_ikon[id], jumlah_notif(id))
	for id in _lencana_dock:
		UI.atur_lencana(_lencana_dock[id], jumlah_notif(id))
