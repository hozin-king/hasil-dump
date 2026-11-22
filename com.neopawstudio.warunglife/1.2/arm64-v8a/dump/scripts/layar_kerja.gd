extends ColorRect






signal selesai(gandakan: bool)
signal memudar

const GH: = preload("res://scripts/gaya_hud.gd")
const WARNA_BINGKAI: = Color(0.55, 0.34, 0.15)
const WARNA_BINGKAI_TERANG: = Color(0.86, 0.66, 0.36)
const LAMA_KERJA: = 3.0

var _kartu: Control
var _bar: ProgressBar
var _ket_waktu: Label
var _tombol: Button
var _tombol_ganda: Button


var _id_kerja: = ""
var _mundur: = false
var _gelap: = false





func isi_cerita(judul: String, foto: String, teks: String, menit: float, mundur: = false, gelap: = false) -> void :
	_id_kerja = ""
	_mundur = mundur
	_gelap = gelap
	_bangun({"judul": judul, "foto": foto, "teks": teks, "menit": menit})


func isi(id: String) -> void :
	var k: Dictionary = GameState.KERJA_SAMPINGAN[id].duplicate()
	k["judul"] = "Pak Misran sedang membantu %s" % String(k.get("nama", ""))
	_id_kerja = id
	_bangun(k)


func _bangun(k: Dictionary) -> void :
	var id: = _id_kerja
	theme = GH.tema_jendela()
	process_mode = Node.PROCESS_MODE_ALWAYS
	color = Color(0, 0, 0, 1) if _gelap else Color(0.02, 0.02, 0.02, 0.9)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 150
	modulate.a = 0.0
	var tengah: = CenterContainer.new()
	tengah.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(tengah)
	var kolom: = VBoxContainer.new()
	kolom.add_theme_constant_override("separation", 10)
	tengah.add_child(kolom)
	_kartu = kolom

	var judul: = Label.new()
	judul.text = String(k["judul"]).to_upper()
	GH.gaya_label(judul, 46, GH.KUNING, true)
	judul.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	kolom.add_child(judul)


	var bingkai: = PanelContainer.new()
	var gaya: = StyleBoxFlat.new()
	gaya.bg_color = Color(0.05, 0.05, 0.05, 0.85)
	gaya.border_color = GH.KUNING
	gaya.set_border_width_all(4)
	gaya.set_corner_radius_all(14)
	gaya.shadow_color = Color(0, 0, 0, 0.55)
	gaya.shadow_size = 18
	gaya.shadow_offset = Vector2(0, 8)
	gaya.set_content_margin_all(12)
	bingkai.add_theme_stylebox_override("panel", gaya)
	bingkai.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	kolom.add_child(bingkai)
	var foto: = TextureRect.new()


	var jalur: = String(k.get("foto", ""))
	if GameState.adalah_ibu() and jalur != "":
		jalur = jalur.get_basename() + "_ibu." + jalur.get_extension()
		bingkai.visible = ResourceLoader.exists(jalur)
	if ResourceLoader.exists(jalur):
		foto.texture = load(jalur)
	foto.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	foto.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	var tinggi_layar: = get_viewport_rect().size.y
	var tinggi_foto: = clampf(tinggi_layar * 0.52, 240.0, 420.0)
	foto.custom_minimum_size = Vector2(tinggi_foto * 16.0 / 9.0, tinggi_foto)
	bingkai.add_child(foto)


	var langsung: = id != "" and not GameState.minigame_kerja(id).is_empty()
	if langsung or jalur == "":
		bingkai.hide()

	var ket: = Label.new()
	ket.text = String(k.get("teks", ""))
	ket.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	GH.gaya_label(ket, 24, GH.KUNING)
	kolom.add_child(ket)


	var baris: = HBoxContainer.new()
	baris.alignment = BoxContainer.ALIGNMENT_CENTER
	baris.add_theme_constant_override("separation", 12)
	kolom.add_child(baris)
	_bar = ProgressBar.new()
	_bar.show_percentage = false
	_bar.custom_minimum_size = Vector2(420, 16)
	_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var latar: = StyleBoxFlat.new()
	latar.bg_color = Color(1, 1, 1, 0.22)
	latar.set_corner_radius_all(8)
	var isi_bar: = StyleBoxFlat.new()
	isi_bar.bg_color = GH.KUNING
	isi_bar.set_corner_radius_all(8)
	_bar.add_theme_stylebox_override("background", latar)
	_bar.add_theme_stylebox_override("fill", isi_bar)
	baris.add_child(_bar)
	_ket_waktu = Label.new()
	GH.gaya_label(_ket_waktu, 24, GH.KUNING, true)
	_ket_waktu.custom_minimum_size.x = 170
	baris.add_child(_ket_waktu)

	var baris_tombol: = HBoxContainer.new()
	baris_tombol.alignment = BoxContainer.ALIGNMENT_CENTER
	baris_tombol.add_theme_constant_override("separation", 16)
	baris_tombol.modulate.a = 0.0
	kolom.add_child(baris_tombol)
	_tombol = Button.new()
	_tombol.theme_type_variation = &"TombolKayu"
	_tombol.custom_minimum_size = Vector2(300, 62)
	_tombol.add_theme_font_size_override("font_size", 22)
	_tombol.disabled = true
	_tombol.pressed.connect(_tutup.bind(false))
	baris_tombol.add_child(_tombol)
	_tombol_ganda = Button.new()
	_tombol_ganda.theme_type_variation = &"TombolHijau"
	_tombol_ganda.custom_minimum_size = Vector2(360, 62)
	_tombol_ganda.add_theme_font_size_override("font_size", 22)
	_tombol_ganda.disabled = true
	_tombol_ganda.pressed.connect(_pilih_ganda)
	baris_tombol.add_child(_tombol_ganda)

	_pesan_iklan = Label.new()
	GH.gaya_label(_pesan_iklan, 19, Color(1, 0.72, 0.55), true)
	_pesan_iklan.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_pesan_iklan.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_pesan_iklan.custom_minimum_size.x = 640
	_pesan_iklan.hide()
	kolom.add_child(_pesan_iklan)

	var muncul: = create_tween()
	muncul.tween_property(self, "modulate:a", 1.0, 1.0 if _gelap else 0.4)
	await muncul.finished

	var menit: = float(k["menit"])
	var tw: = create_tween()
	tw.tween_method( func(t: float):
		_bar.value = t * 100.0
		_ket_waktu.text = GameState.teks_durasi(menit * ((1.0 - t) if _mundur else t)), 0.0, 1.0, 0.4 if langsung else LAMA_KERJA)
	await tw.finished
	if id != "":
		GameState.bunyi("koin")
	_ket_waktu.text = "Selesai!"
	if id == "":

		_tombol.text = "Lanjut"
		_tombol.theme_type_variation = &"TombolHijau"
		_tombol_ganda.hide()
		_tombol.disabled = false
		create_tween().tween_property(_tombol.get_parent(), "modulate:a", 1.0, 0.25)
		return
	_tombol.text = "Terima upah %s" % GameState.format_rupiah(GameState.upah_diterima(id))
	var total: = GameState.upah_diterima(id) + GameState.bonus_iklan_kerja(id)
	_tombol_ganda.text = ("Ambil upah 2x (%s)" if GameState.tanpa_iklan else "Tonton iklan: upah 2x (%s)") % GameState.format_rupiah(total)
	_tombol.disabled = false
	_tombol_ganda.disabled = false
	create_tween().tween_property(_tombol.get_parent(), "modulate:a", 1.0, 0.25)




var _pesan_iklan: Label
var iklan_ditonton: = false

func _pilih_ganda() -> void :
	GameState.klik()
	_tombol.disabled = true
	_tombol_ganda.disabled = true
	_pesan_iklan.hide()
	if await GameState.tonton_iklan(self):
		iklan_ditonton = true
		_tutup(true, false)
		return
	_pesan_iklan.text = "Iklan belum selesai atau gagal dimuat, jadi upah 2x belum didapat. Coba lagi, atau terima upah biasa."
	_pesan_iklan.show()
	_tombol.disabled = false
	_tombol_ganda.disabled = false


func _tutup(gandakan: bool, klik: = true) -> void :
	if klik:
		GameState.klik()
	_tombol.disabled = true
	_tombol_ganda.disabled = true
	memudar.emit()
	var tw: = create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.9 if _gelap else 0.3)
	await tw.finished
	selesai.emit(gandakan)
	queue_free()
