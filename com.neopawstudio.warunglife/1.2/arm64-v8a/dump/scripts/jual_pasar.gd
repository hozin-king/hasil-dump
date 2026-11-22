extends Control






signal selesai(total: int)

const GH: = preload("res://scripts/gaya_hud.gd")
const KREM: = Color(0.97, 0.92, 0.8)
const COKLAT: = Color(0.32, 0.2, 0.1)

const OBROLAN: = [
	"Ada ikan atau buah, Pak Misran? Sini, saya beli. Pasar tutup jam 7 malam, ya.", 
	"Wah, Pak Misran jauh-jauh naik angkot. Bawa apa hari ini?", 
	"Pembeli di pasar suka ikan sungai yang segar, Pak. Mana, saya lihat.", 
	"Buah dari kebun sawah itu manis-manis, Pak. Langganan saya suka.", 
	"Ingat ya, Pak, Selasa sama Kamis pasar libur. Saya di rumah.", 
	"Duduk dulu, Pak. Panas, ya? Sini, apa yang mau dijual?", 
]

var _daftar: VBoxContainer
var _label_total: Label
var _tombol_semua: Button
var _total: = 0


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
	kartu.custom_minimum_size = Vector2(760, 0)
	tengah.add_child(kartu)
	var kolom: = VBoxContainer.new()
	kolom.add_theme_constant_override("separation", 12)
	kartu.add_child(kolom)
	var judul: = GH.label("JUAL KE BU IDA", 38, GH.KUNING, true)
	GH.pita_emas(judul, 30)
	kolom.add_child(judul)
	var sapa: = GH.label("\"%s\"" % GameState.tk(OBROLAN.pick_random()), 20, Color.WHITE)
	sapa.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sapa.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	kolom.add_child(sapa)


	var gulir: ScrollContainer = load("res://scripts/hp/gulir_sentuh.gd").new()
	gulir.scroll_deadzone = 8
	gulir.custom_minimum_size = Vector2(0, clampf(get_viewport_rect().size.y - 330.0, 200.0, 420.0))
	gulir.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	kolom.add_child(gulir)
	_daftar = VBoxContainer.new()
	_daftar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_daftar.add_theme_constant_override("separation", 8)
	gulir.add_child(_daftar)
	_label_total = GH.label("", 24, GH.HIJAU_UANG, true)
	_label_total.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	kolom.add_child(_label_total)
	var bawah: = HBoxContainer.new()
	bawah.alignment = BoxContainer.ALIGNMENT_CENTER
	bawah.add_theme_constant_override("separation", 18)
	kolom.add_child(bawah)
	_tombol_semua = Button.new()
	GH.gaya_tombol_emas(_tombol_semua, true, 26)
	_tombol_semua.custom_minimum_size = Vector2(330, 62)
	_tombol_semua.pressed.connect( func(): _konfirmasi(_tombol_semua, _jual_semua))
	bawah.add_child(_tombol_semua)
	var tutup: = Button.new()
	tutup.text = "Tutup"
	GH.gaya_tombol_emas(tutup, false, 26)
	tutup.custom_minimum_size = Vector2(200, 62)
	tutup.pressed.connect( func():
		selesai.emit(_total)
		queue_free())
	bawah.add_child(tutup)
	_isi_daftar()
	kartu.pivot_offset = Vector2(380, 250)
	kartu.scale = Vector2.ONE * 0.9
	create_tween().tween_property(kartu, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _barang() -> Array:

	var ids: Array = GameState.hasil_alam.keys().filter( func(id): return GameState.jumlah_hasil_alam(String(id)) > 0)
	ids.sort_custom( func(a, b):
		var ia: = GameState.info_hasil_alam(String(a))
		var ib: = GameState.info_hasil_alam(String(b))
		if String(ia.get("kelompok", "")) != String(ib.get("kelompok", "")):
			return String(ia.get("kelompok", "")) == "ikan"
		return int(ia.get("harga", 0)) < int(ib.get("harga", 0)))
	return ids


func _isi_daftar() -> void :
	for anak in _daftar.get_children():
		anak.queue_free()
	var ids: = _barang()
	var nilai: = 0
	for id in ids:
		nilai += GameState.jumlah_hasil_alam(String(id)) * int(GameState.info_hasil_alam(String(id)).get("harga", 0))
		_daftar.add_child(_baris(String(id)))
	if ids.is_empty():
		var kosong: = GH.label("Tas kosong. Pancing ikan di sungai atau petik buah di kebun sawah dulu, lalu bawa ke sini.", 20, Color(0.9, 0.9, 0.9))
		kosong.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		kosong.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		kosong.custom_minimum_size = Vector2(680, 0)
		_daftar.add_child(kosong)
	if _tombol_semua.has_meta("teks_asli"):
		_tombol_semua.remove_meta("teks_asli")
	_tombol_semua.text = "Jual semua (%s)" % GameState.format_rupiah(nilai) if nilai > 0 else "Jual semua"
	_tombol_semua.disabled = nilai <= 0
	_label_total.text = ("Sudah terjual: %s" % GameState.format_rupiah(_total)) if _total > 0 else ""


func _baris(id: String) -> Control:
	var info: = GameState.info_hasil_alam(id)
	var n: = GameState.jumlah_hasil_alam(id)
	var harga: = int(info.get("harga", 0))
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
	baris.add_theme_constant_override("separation", 14)
	kotak.add_child(baris)
	var ikon: = TextureRect.new()
	var jalur: = String(info.get("ikon", ""))
	if ResourceLoader.exists(jalur):
		ikon.texture = load(jalur)
	ikon.custom_minimum_size = Vector2(58, 58)
	ikon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ikon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	baris.add_child(ikon)
	var teks: = VBoxContainer.new()
	teks.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	teks.alignment = BoxContainer.ALIGNMENT_CENTER
	teks.add_theme_constant_override("separation", 0)
	baris.add_child(teks)
	var nama: = GH.label("%s x%d" % [String(info.get("nama", id)), n], 24, COKLAT, true, 0)
	nama.add_theme_color_override("font_color", COKLAT)
	teks.add_child(nama)
	var ket: = GH.label(("%s / ekor" if String(info.get("satuan", "")) == "ekor" else "%s / buah") % GameState.format_rupiah(harga), 18, COKLAT, false, 0)
	ket.add_theme_color_override("font_color", COKLAT.lightened(0.2))
	teks.add_child(ket)
	var b: = Button.new()
	b.text = "Jual %s" % GameState.format_rupiah(harga * n)
	GH.gaya_tombol(b, true, 22)
	b.custom_minimum_size = Vector2(210, 52)
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	b.pressed.connect( func(): _konfirmasi(b, func(): _jual([id])))
	baris.add_child(b)
	return kotak




func _konfirmasi(tombol: Button, aksi: Callable) -> void :
	if tombol.has_meta("teks_asli"):
		tombol.remove_meta("teks_asli")
		aksi.call()
		return
	GameState.klik()
	tombol.set_meta("teks_asli", tombol.text)
	tombol.text = "Yakin? Ketuk lagi"
	GameState.get_tree().create_timer(3.0).timeout.connect( func():
		if is_instance_valid(tombol) and tombol.has_meta("teks_asli"):
			tombol.text = String(tombol.get_meta("teks_asli"))
			tombol.remove_meta("teks_asli"))


func _jual(ids: Array) -> void :
	var dapat: = 0
	for id in ids:
		dapat += GameState.jual_hasil_alam(String(id))
	if dapat <= 0:
		return
	_total += dapat
	GameState.bunyi("koin")
	_isi_daftar()


func _jual_semua() -> void :
	_jual(_barang())
