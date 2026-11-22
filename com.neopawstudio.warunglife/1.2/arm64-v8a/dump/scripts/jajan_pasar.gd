extends Control





signal selesai(id: String)

const GH: = preload("res://scripts/gaya_hud.gd")
const KB: = preload("res://scripts/konfirmasi_bayar.gd")
const KREM: = Color(0.97, 0.92, 0.8)
const COKLAT: = Color(0.32, 0.2, 0.1)
const OBROLAN: = [
	"Mau sarapan atau ngemil, Pak? Pecelnya baru dibuat, bumbu kacangnya masih hangat.", 
	"Capek habis keliling pasar, Pak? Makan dulu sini, biar tenaganya balik.", 
	"Kue lapisnya manis, Pak, cocok buat teman duduk. Murah kok.", 
	"Pak Misran yang punya warung itu, ya? Sama Bu Ida sering cerita. Jajan dulu, Pak.", 
]

var _nama: = ""
var _pesan: Label
var _daftar: VBoxContainer
var _terakhir: = ""


func _init(nama_penjual: = "Nini Onah") -> void :
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
	var kartu: = GH.panel_emas(Vector4(30, 22, 30, 22))
	kartu.custom_minimum_size = Vector2(700, 0)
	tengah.add_child(kartu)
	var kolom: = VBoxContainer.new()
	kolom.add_theme_constant_override("separation", 12)
	kartu.add_child(kolom)
	var judul: = GH.label("JAJAN DI %s" % GameState.tk(_nama).to_upper(), 36, GH.KUNING, true)
	GH.pita_emas(judul, 30)
	kolom.add_child(judul)
	var sapa: = GH.label("\"%s\"" % GameState.tk(OBROLAN.pick_random()), 20, Color.WHITE)
	sapa.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sapa.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	kolom.add_child(sapa)
	var gulir: ScrollContainer = load("res://scripts/hp/gulir_sentuh.gd").new()
	gulir.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	gulir.scroll_deadzone = 8

	gulir.custom_minimum_size = Vector2(0, clampf(get_viewport_rect().size.y - 330.0, 220.0, 5 * 72.0 + 4 * 8.0))
	kolom.add_child(gulir)
	_daftar = VBoxContainer.new()
	_daftar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_daftar.add_theme_constant_override("separation", 8)
	gulir.add_child(_daftar)
	_isi_daftar()
	_pesan = GH.label("", 20, GH.KUNING)
	_pesan.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_pesan.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_pesan.custom_minimum_size = Vector2(640, 0)
	var alasan: = GameState.alasan_tidak_bisa_jajan()
	_pesan.text = alasan if alasan != "" else "Tiap jajanan sekali sehari, ya. Energinya naik sedikit."
	kolom.add_child(_pesan)
	var tutup: = Button.new()
	tutup.text = "Tutup"
	GH.gaya_tombol_emas(tutup, false, 26)
	tutup.custom_minimum_size = Vector2(200, 62)
	tutup.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	tutup.pressed.connect( func():
		selesai.emit(_terakhir)
		queue_free())
	kolom.add_child(tutup)
	kartu.pivot_offset = Vector2(350, 250)
	kartu.scale = Vector2.ONE * 0.9
	create_tween().tween_property(kartu, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _isi_daftar() -> void :
	for anak in _daftar.get_children():
		anak.queue_free()
	for m in GameState.MENU_JAJAN:
		_daftar.add_child(_baris(m))


func _baris(m: Array) -> Control:
	var kotak: = PanelContainer.new()
	var g: = StyleBoxFlat.new()
	g.bg_color = KREM
	g.set_corner_radius_all(14)
	g.content_margin_left = 16
	g.content_margin_right = 12
	g.content_margin_top = 8
	g.content_margin_bottom = 8
	kotak.add_theme_stylebox_override("panel", g)
	var baris: = HBoxContainer.new()
	baris.add_theme_constant_override("separation", 14)
	kotak.add_child(baris)
	var teks: = VBoxContainer.new()
	teks.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	teks.alignment = BoxContainer.ALIGNMENT_CENTER
	teks.add_theme_constant_override("separation", 0)
	baris.add_child(teks)
	var nama: = GH.label(String(m[1]), 26, COKLAT, true, 0)
	nama.add_theme_color_override("font_color", COKLAT)
	teks.add_child(nama)
	var sudah: = not GameState.boleh_jajan(String(m[0]))
	var ket: = GH.label(("Energi +%d%% · sudah dibeli hari ini" if sudah else "Energi +%d%%") % int(m[3]), 18, COKLAT, false, 0)
	ket.add_theme_color_override("font_color", COKLAT.lightened(0.2))
	teks.add_child(ket)
	var b: = Button.new()
	b.text = "Sudah" if sudah else "Beli %s" % GameState.format_rupiah(int(m[2]))
	GH.gaya_tombol(b, true, 22)
	b.custom_minimum_size = Vector2(230, 56)
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	b.disabled = GameState.alasan_tidak_bisa_jajan(String(m[0])) != "" or GameState.uang < int(m[2])
	b.pressed.connect( func(): _beli(String(m[0])))
	baris.add_child(b)
	return kotak


func _beli(id: String) -> void :
	if GameState.alasan_tidak_bisa_jajan(id) == "":
		for m in GameState.MENU_JAJAN:
			if m[0] == id and GameState.uang >= int(m[2]):
				if not await KB.tanya(self, "Beli %s?" % String(m[1]), int(m[2]), "", "Ya, beli"):
					return
				break
	var alasan: = GameState.beli_jajan(id)
	if alasan != "":
		_pesan.text = alasan
		GameState.bunyi("salah")
		return
	GameState.bunyi("koin")
	_terakhir = id
	_pesan.text = "Nyam! Energi sekarang %d%%." % int(GameState.energi)
	var umum: = GameState.alasan_tidak_bisa_jajan()
	if umum != "":
		_pesan.text += "\n" + umum
	_isi_daftar()
