extends Control







const IKON_HP: = preload("res://assets/ikon/hp.svg")
const GH: = preload("res://scripts/gaya_hud.gd")
const KB: = preload("res://scripts/konfirmasi_bayar.gd")
const LANGKAH_KIRIM: = [10000, 50000]
const KECEPATAN_KETIK: = 45.0

var _warung: Node
var _label_target: Label
var _tombol_kirim: Button
var _kotak_target: PanelContainer

var _panel_kirim: PanelContainer
var _jumlah_kirim: = 0
var _label_jumlah: Label
var _label_info_kirim: Label
var _pesan_kirim: Label

var _lapisan_dialog: Control
var _nama_dialog: Label
var _kotak_nama: PanelContainer
var _teks_dialog: Label
var _antrean: Array = []
var _tween_ketik: Tween


var _siap_lanjut: = false

signal dialog_selesai

const NAMA_TAMPIL: = {"Bapak": "Pak Misran", "Agus": "Agus (lewat telepon)", "AgusDatang": "Agus"}
var _bingkai_potret: PanelContainer
var _gambar_potret: TextureRect
var _potret_telepon: Control = null
var _potret_kontak: Control = null
var _potret_bapak: SubViewport
var _animasi_potret: AnimationPlayer


func _ready() -> void :
	_warung = owner
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_buat_kotak_target()
	_buat_panel_kirim()
	_buat_dialog()
	GameState.data_berubah.connect(_perbarui)
	_perbarui()

	_mulai.call_deferred()


func _perbarui() -> void :
	if GameState.cerita_tamat:
		_label_target.text = "Cerita selesai · semua barang terbuka"
		_tombol_kirim.hide()
		return
	var sisa: = GameState.sisa_hari()
	var teks_sisa: = "hari terakhir!" if sisa <= 1 else "%d hari lagi" % sisa
	_label_target.text = "Misi utama · %s\n%s / %s  ·  %s" % [
		GameState.data_bab()["kebutuhan"], 
		GameState.format_rupiah(GameState.kiriman_bab), GameState.format_rupiah(GameState.target_bab), teks_sisa]
	_label_target.add_theme_color_override("font_color", Color(1, 0.55, 0.45) if sisa <= 1 else Color(1, 0.94, 0.82))

	_tombol_kirim.hide()
	if _panel_kirim.visible:
		_perbarui_panel_kirim()




func _buat_kotak_target() -> void :
	_kotak_target = PanelContainer.new()
	_kotak_target.theme_type_variation = &"PanelHud"
	_kotak_target.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_kotak_target.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_kotak_target.position.y = 84
	_kotak_target.visible = false
	add_child(_kotak_target)
	var baris: = HBoxContainer.new()
	baris.add_theme_constant_override("separation", 10)
	_kotak_target.add_child(baris)
	var ikon: = TextureRect.new()
	ikon.texture = IKON_HP
	ikon.custom_minimum_size = Vector2(40, 40)
	ikon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ikon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	baris.add_child(ikon)
	_label_target = Label.new()
	_label_target.theme_type_variation = &"LabelHud"
	_label_target.add_theme_font_size_override("font_size", 19)
	_label_target.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	baris.add_child(_label_target)
	_tombol_kirim = Button.new()
	_tombol_kirim.theme_type_variation = &"TombolHijau"
	_tombol_kirim.text = "Kirim"
	_tombol_kirim.add_theme_font_size_override("font_size", 24)
	_tombol_kirim.custom_minimum_size = Vector2(110, 0)

	_tombol_kirim.pressed.connect( func(): _warung.buka_chat_agus())
	baris.add_child(_tombol_kirim)

	_kotak_target.resized.connect( func(): _kotak_target.position.x = (size.x - _kotak_target.size.x) / 2.0)




func _buat_panel_kirim() -> void :
	_panel_kirim = PanelContainer.new()
	_panel_kirim.hide()
	_panel_kirim.set_anchors_preset(Control.PRESET_CENTER)
	_panel_kirim.custom_minimum_size = Vector2(620, 0)
	add_child(_panel_kirim)
	var isi: = VBoxContainer.new()
	isi.add_theme_constant_override("separation", 14)
	_panel_kirim.add_child(isi)
	var judul: = Label.new()
	judul.theme_type_variation = &"LabelKepala"
	judul.text = "Kirim uang untuk Agus"
	judul.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	isi.add_child(judul)
	_label_info_kirim = Label.new()
	_label_info_kirim.add_theme_font_size_override("font_size", 21)
	_label_info_kirim.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	isi.add_child(_label_info_kirim)
	_label_jumlah = Label.new()
	_label_jumlah.theme_type_variation = &"LabelKepala"
	_label_jumlah.add_theme_font_size_override("font_size", 46)
	_label_jumlah.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	isi.add_child(_label_jumlah)
	var tombol_jumlah: = HBoxContainer.new()
	tombol_jumlah.add_theme_constant_override("separation", 10)
	isi.add_child(tombol_jumlah)
	_tambah_tombol(tombol_jumlah, "−10rb", &"TombolKayu", func(): _ubah_jumlah(-10000))
	for langkah in LANGKAH_KIRIM:
		_tambah_tombol(tombol_jumlah, "+%drb" % (langkah / 1000), &"", _ubah_jumlah.bind(langkah))
	_tambah_tombol(tombol_jumlah, "Sisanya", &"", func(): _jumlah_kirim = mini(GameState.kekurangan_kiriman(), GameState.uang);_perbarui_panel_kirim())
	_pesan_kirim = Label.new()
	_pesan_kirim.add_theme_font_size_override("font_size", 19)
	_pesan_kirim.add_theme_color_override("font_color", Color(0.7, 0.2, 0.15))
	_pesan_kirim.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_pesan_kirim.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	isi.add_child(_pesan_kirim)
	var bawah: = HBoxContainer.new()
	bawah.add_theme_constant_override("separation", 12)
	isi.add_child(bawah)
	_tambah_tombol(bawah, "Batal", &"TombolKayu", func(): _panel_kirim.hide();_warung.perbarui_redup())
	_tambah_tombol(bawah, "Kirim", &"TombolHijau", _kirim)


func _tambah_tombol(wadah: Container, teks: String, gaya: StringName, aksi: Callable) -> void :
	var t: = Button.new()
	t.text = teks
	if gaya != &"":
		t.theme_type_variation = gaya
	t.custom_minimum_size = Vector2(0, 70)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	t.add_theme_font_size_override("font_size", 26)
	t.pressed.connect(aksi)
	wadah.add_child(t)


func _buka_panel_kirim() -> void :
	_jumlah_kirim = GameState.kekurangan_kiriman()
	_pesan_kirim.text = ""
	_perbarui_panel_kirim()
	_panel_kirim.show()
	_panel_kirim.reset_size()
	_panel_kirim.position = (size - _panel_kirim.size) / 2.0
	_warung.perbarui_redup()


func _ubah_jumlah(selisih: int) -> void :
	_jumlah_kirim = clampi(_jumlah_kirim + selisih, 0, mini(GameState.uang, GameState.kekurangan_kiriman()))
	_perbarui_panel_kirim()


func _perbarui_panel_kirim() -> void :
	_label_info_kirim.text = "Kebutuhan: %s\nSudah dikirim %s · kurang %s\nUang di laci: %s" % [
		GameState.data_bab()["kebutuhan"], GameState.format_rupiah(GameState.kiriman_bab), 
		GameState.format_rupiah(GameState.kekurangan_kiriman()), GameState.format_rupiah(GameState.uang)]
	_label_jumlah.text = GameState.format_rupiah(_jumlah_kirim)

	var awas: = GameState.peringatan_kirim(_jumlah_kirim)
	_pesan_kirim.add_theme_color_override("font_color", Color(0.75, 0.15, 0.1) if awas.begins_with("Awas") else Color(0.4, 0.25, 0.1))
	if awas != "":
		_pesan_kirim.text = awas
	else:
		_pesan_kirim.text = ""


func _kirim() -> void :

	if GameState.kirim_akan_berhasil(_jumlah_kirim):
		var bab: = GameState.bab
		if not await KB.tanya(self, "Kirim uang ke %s?" % GameState.nama_penerima(), mini(_jumlah_kirim, GameState.kekurangan_kiriman()), "", "Ya, kirim"):
			return
		if bab != GameState.bab:
			return
	var alasan: = GameState.kirim_uang(_jumlah_kirim)
	if alasan != "":
		_pesan_kirim.text = alasan
		return
	_panel_kirim.hide()
	_warung.perbarui_redup()
	if GameState.dialog_tertunda.is_empty():
		_warung.tampilkan_pesan("Agus: \"%s\"" % GameState.cerita["balasan_kirim"].pick_random(), 4.0)
	tampilkan_dialog_tertunda()




func _buat_dialog() -> void :
	_lapisan_dialog = Control.new()
	_lapisan_dialog.set_anchors_preset(Control.PRESET_FULL_RECT)
	_lapisan_dialog.mouse_filter = Control.MOUSE_FILTER_STOP
	_lapisan_dialog.hide()
	add_child(_lapisan_dialog)
	var gelap: = ColorRect.new()
	gelap.color = Color(0.03, 0.02, 0.01, 0.55)
	gelap.set_anchors_preset(Control.PRESET_FULL_RECT)
	gelap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_lapisan_dialog.add_child(gelap)

	var kotak: = PanelContainer.new()
	kotak.mouse_filter = Control.MOUSE_FILTER_IGNORE
	kotak.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	kotak.offset_left = 60
	kotak.offset_right = -60
	kotak.offset_top = -250
	kotak.offset_bottom = -30
	_lapisan_dialog.add_child(kotak)

	var baris_dialog: = HBoxContainer.new()
	baris_dialog.add_theme_constant_override("separation", 18)
	kotak.add_child(baris_dialog)
	_bingkai_potret = PanelContainer.new()
	_bingkai_potret.theme_type_variation = &"KartuBarang"
	_bingkai_potret.custom_minimum_size = Vector2(176, 176)
	_bingkai_potret.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	baris_dialog.add_child(_bingkai_potret)
	_gambar_potret = TextureRect.new()
	_gambar_potret.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_gambar_potret.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_bingkai_potret.add_child(_gambar_potret)
	var isi: = VBoxContainer.new()
	isi.add_theme_constant_override("separation", 8)
	isi.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	baris_dialog.add_child(isi)
	_kotak_nama = PanelContainer.new()
	_kotak_nama.theme_type_variation = &"PanelHud"
	_kotak_nama.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	isi.add_child(_kotak_nama)
	_nama_dialog = Label.new()
	_nama_dialog.theme_type_variation = &"LabelHud"
	_kotak_nama.add_child(_nama_dialog)
	_teks_dialog = Label.new()
	_teks_dialog.add_theme_font_size_override("font_size", 30)
	_teks_dialog.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_teks_dialog.size_flags_vertical = Control.SIZE_EXPAND_FILL
	isi.add_child(_teks_dialog)
	var petunjuk: = Label.new()
	petunjuk.text = "Klik untuk lanjut  ▸"
	petunjuk.add_theme_font_size_override("font_size", 18)
	petunjuk.add_theme_color_override("font_color", Color(0.55, 0.4, 0.25))
	petunjuk.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	isi.add_child(petunjuk)
	GH.gaya_kotak_dialog(kotak, _bingkai_potret, _gambar_potret, _kotak_nama, _nama_dialog, _teks_dialog, petunjuk)
	_lapisan_dialog.gui_input.connect(_on_dialog_disentuh)



func tampilkan_dialog_tertunda() -> void :
	if _lapisan_dialog.visible or GameState.dialog_tertunda.is_empty():
		return
	for kunci in GameState.dialog_tertunda:
		var baris_dialog: = GameState.isi_dialog(kunci)
		_antrean.append_array(baris_dialog)
		GameState.simpan_dialog_ke_chat(kunci, baris_dialog)
	GameState.dialog_tertunda.clear()
	GameState.simpan()
	_warung.dialog_aktif = true
	_lapisan_dialog.show()
	_tampilkan_baris_berikut()


func _tampilkan_baris_berikut() -> void :
	if _antrean.is_empty():
		_lapisan_dialog.hide()
		_warung.dialog_aktif = false
		_perbarui()
		dialog_selesai.emit()
		return
	var baris: Array = _antrean.pop_front()
	var pembicara: String = baris[0]


	var potongan: = _pecah_teks(GameState.tk(String(baris[1])))
	if potongan.size() > 1:
		for k in range(potongan.size() - 1, 0, -1):
			_antrean.push_front([pembicara, potongan[k]])
		baris = [pembicara, potongan[0]]
	_kotak_nama.visible = pembicara != ""
	_nama_dialog.text = ("%s (lewat telepon)" % pembicara.split("|")[1]) if pembicara.begins_with("Kontak|") else NAMA_TAMPIL.get(pembicara, pembicara)
	_tampilkan_potret(pembicara)
	_teks_dialog.text = baris[1]

	_teks_dialog.add_theme_color_override("font_color", Color(1, 1, 1, 0.75) if pembicara == "" else Color.WHITE)
	_siap_lanjut = false
	_teks_dialog.visible_ratio = 0.0
	if _tween_ketik:
		_tween_ketik.kill()
	_tween_ketik = create_tween()
	_tween_ketik.tween_property(_teks_dialog, "visible_ratio", 1.0, _teks_dialog.text.length() / KECEPATAN_KETIK)


const MAKS_BARIS_DIALOG: = 3



func _pecah_teks(teks: String) -> Array:
	var font: = _teks_dialog.get_theme_font("font")
	var ukuran: = _teks_dialog.get_theme_font_size("font_size")
	var lebar: = _teks_dialog.size.x
	if lebar < 200.0:
		lebar = get_viewport().get_visible_rect().size.x - 120.0 - 176.0 - 18.0 - 60.0
	var muat: = func(t: String) -> bool:
		var tinggi: = font.get_multiline_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, lebar, ukuran).y
		return tinggi <= font.get_height(ukuran) * (MAKS_BARIS_DIALOG + 0.4)
	if font == null or muat.call(teks):
		return [teks]

	var kalimat: Array = []
	var awal: = 0
	for i in teks.length():
		if teks[i] in [".", "?", "!"] and i + 1 < teks.length() and teks[i + 1] == " ":
			kalimat.append(teks.substr(awal, i + 1 - awal).strip_edges())
			awal = i + 1
	kalimat.append(teks.substr(awal).strip_edges())
	var hasil: Array = []
	var kini: = ""
	for k in kalimat:
		if k == "":
			continue
		var coba: String = k if kini == "" else kini + " " + k
		if muat.call(coba):
			kini = coba
			continue
		if kini != "":
			hasil.append(kini)
		kini = k

		while not muat.call(kini):
			var kata: PackedStringArray = kini.split(" ")
			var depan: = ""
			var j: = 0
			while j < kata.size() and muat.call((depan + " " + kata[j]).strip_edges()):
				depan = (depan + " " + kata[j]).strip_edges()
				j += 1
			if j == 0:
				break
			hasil.append(depan + " …")
			kini = "… " + " ".join(kata.slice(j))
	if kini != "":
		hasil.append(kini)
	return hasil


func _on_dialog_disentuh(event: InputEvent) -> void :
	var ditekan: bool = (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT)
	if not ditekan:
		return
	GameState.klik()

	if not _siap_lanjut:
		_siap_lanjut = true
		if _tween_ketik:
			_tween_ketik.kill()
		_teks_dialog.visible_ratio = 1.0
	else:
		_tampilkan_baris_berikut()



func lewati_baris() -> void :
	_on_dialog_disentuh(_klik_palsu())


func _klik_palsu() -> InputEventMouseButton:
	var e: = InputEventMouseButton.new()
	e.pressed = true
	e.button_index = MOUSE_BUTTON_LEFT
	return e




func _mulai() -> void :
	if _warung.dialog_aktif:
		await _warung.intro_selesai


	if GameState.tutorial_awal and GameState.nama_warung == "":
		await _tampilkan_tutorial()
	if GameState.nama_warung == "":
		await _minta_nama_warung()
	if not GameState.dialog_tertunda.is_empty():
		tampilkan_dialog_tertunda()
		await dialog_selesai



signal _nama_disimpan

func _minta_nama_warung() -> void :
	_warung.dialog_aktif = true
	var lapisan: = ColorRect.new()
	lapisan.color = Color(0.03, 0.02, 0.01, 0.45)
	lapisan.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(lapisan)
	var panel: = PanelContainer.new()
	panel.custom_minimum_size = Vector2(360, 0)
	lapisan.add_child(panel)
	var isi: = VBoxContainer.new()
	isi.add_theme_constant_override("separation", 8)
	panel.add_child(isi)
	var judul: = Label.new()
	judul.text = "BERI NAMA WARUNGMU"
	GH.gaya_jendela(panel, judul)
	isi.add_child(judul)
	var ket: = Label.new()
	ket.text = "Ditulis di papan WARUNG (maks. %d huruf)." % GameState.MAKS_NAMA_WARUNG
	ket.add_theme_font_size_override("font_size", 17)
	ket.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	isi.add_child(ket)
	var kolom: = LineEdit.new()
	kolom.max_length = GameState.MAKS_NAMA_WARUNG
	kolom.placeholder_text = "contoh: Berkah"
	kolom.alignment = HORIZONTAL_ALIGNMENT_CENTER
	kolom.custom_minimum_size = Vector2(0, 58)
	kolom.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	kolom.add_theme_font_size_override("font_size", 28)
	var baris: = HBoxContainer.new()
	baris.add_theme_constant_override("separation", 8)
	isi.add_child(baris)
	baris.add_child(kolom)
	var pesan: = Label.new()
	pesan.add_theme_font_size_override("font_size", 19)
	pesan.add_theme_color_override("font_color", Color(1, 0.5, 0.45))
	pesan.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	isi.add_child(pesan)
	var tombol: = Button.new()
	tombol.theme_type_variation = &"TombolHijau"
	tombol.text = "Simpan"
	tombol.custom_minimum_size = Vector2(120, 58)
	baris.add_child(tombol)
	panel.reset_size()

	panel.position = Vector2((size.x - panel.size.x) / 2.0, 10)


	kolom.text_changed.connect( func(t: String):
		var rapi: = GameState.rapikan_nama_warung(t)
		GameState.nama_warung = rapi
		_warung.perbarui_nama_warung()
		pesan.text = "")
	var simpan: = func():
		var rapi: = GameState.rapikan_nama_warung(kolom.text)
		if rapi == "":
			pesan.text = "Tulis nama warungnya dulu, ya."
			return
		if not GameState.papan.nama_pantas(rapi):
			pesan.text = "Nama ini kurang pantas. Coba nama lain, ya."
			return
		GameState.nama_warung = rapi
		_warung.perbarui_nama_warung()
		GameState.simpan()
		_nama_disimpan.emit()
	tombol.pressed.connect(simpan)
	kolom.text_submitted.connect( func(_t): simpan.call())
	kolom.grab_focus()

	var sorot_nama: Control = null
	if GameState.tutorial_awal:
		sorot_nama = load("res://scripts/sorot_tutorial.gd").new()
		add_child(sorot_nama)
		sorot_nama.sorot(panel, "Beri nama warungmu di sini, lalu klik Simpan. Nama ini tampil di papan WARUNG.")
	await _nama_disimpan
	if sorot_nama != null:
		sorot_nama.queue_free()
	lapisan.queue_free()
	_warung.dialog_aktif = false




func _tampilkan_potret(pembicara: String) -> void :
	var kontak: = pembicara.begins_with("Kontak|")
	_bingkai_potret.visible = pembicara != ""
	_gambar_potret.visible = pembicara != "Agus" and not kontak
	if _potret_telepon != null:
		_potret_telepon.visible = pembicara == "Agus"
	if _potret_kontak != null:
		_potret_kontak.queue_free()
		_potret_kontak = null
	if kontak:

		_potret_kontak = _buat_potret_telepon(pembicara.split("|")[1])
		_bingkai_potret.add_child(_potret_kontak)
	if pembicara == "Bapak":
		if _potret_bapak == null:
			_buat_potret_bapak()
		_gambar_potret.texture = _potret_bapak.get_texture()

		if _animasi_potret != null and is_instance_valid(_animasi_potret) and _animasi_potret.has_animation("Talk_with_Right_Hand_Open"):
			_animasi_potret.play("Talk_with_Right_Hand_Open", 0.2)
			_animasi_potret.queue("Idle_11")
	elif pembicara == "Agus":
		if _potret_telepon == null:
			_potret_telepon = _buat_potret_telepon()
			_bingkai_potret.add_child(_potret_telepon)
		_potret_telepon.visible = true
	elif pembicara == "AgusDatang":

		_gambar_potret.texture = load("res://assets/potret/agus.png")




func _buat_potret_telepon(nama_kontak: = "Agus") -> Control:
	var wadah: = Control.new()
	wadah.custom_minimum_size = Vector2(176, 176)
	wadah.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var ponsel: = Panel.new()
	var gaya: = StyleBoxFlat.new()
	gaya.bg_color = Color("2b2f36")
	gaya.border_color = Color("fff4e0")
	gaya.set_border_width_all(3)
	gaya.set_corner_radius_all(16)
	ponsel.add_theme_stylebox_override("panel", gaya)
	ponsel.position = Vector2(33, 2)
	ponsel.size = Vector2(110, 172)
	ponsel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wadah.add_child(ponsel)
	var layar: = Panel.new()
	var gaya_layar: = StyleBoxFlat.new()
	gaya_layar.bg_color = Color("075e54")
	gaya_layar.set_corner_radius_all(6)
	layar.add_theme_stylebox_override("panel", gaya_layar)
	layar.position = Vector2(8, 12)
	layar.size = Vector2(94, 138)
	layar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ponsel.add_child(layar)
	var foto: = TextureRect.new()
	foto.texture = load("res://assets/potret/agus.png")
	foto.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	foto.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	foto.position = Vector2(14, 14)
	foto.size = Vector2(66, 66)
	var bulat: = ShaderMaterial.new()
	bulat.shader = Shader.new()
	bulat.shader.code = "shader_type canvas_item;\nvoid fragment() {\n\tvec4 c = texture(TEXTURE, UV);\n\tfloat d = distance(UV, vec2(0.5));\n\tc.a *= 1.0 - smoothstep(0.47, 0.5, d);\n\tCOLOR = mix(vec4(0.86, 0.91, 0.88, 1.0), c, c.a) * vec4(1.0, 1.0, 1.0, 1.0 - smoothstep(0.47, 0.5, d));\n}"
	foto.material = bulat
	if nama_kontak == "Agus":
		layar.add_child(foto)
	else:

		var lingkaran: = Panel.new()
		var gaya_lingkaran: = StyleBoxFlat.new()
		gaya_lingkaran.bg_color = Color("a8754b")
		gaya_lingkaran.set_corner_radius_all(33)
		lingkaran.add_theme_stylebox_override("panel", gaya_lingkaran)
		lingkaran.position = Vector2(14, 14)
		lingkaran.size = Vector2(66, 66)
		lingkaran.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var huruf: = Label.new()
		huruf.text = nama_kontak.replace("Pak ", "").replace("Klinik ", "").left(1).to_upper()
		huruf.add_theme_font_size_override("font_size", 36)
		huruf.add_theme_color_override("font_color", Color.WHITE)
		huruf.set_anchors_preset(Control.PRESET_FULL_RECT)
		huruf.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		huruf.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lingkaran.add_child(huruf)
		layar.add_child(lingkaran)
	var nama: = Label.new()
	nama.text = nama_kontak
	nama.add_theme_font_size_override("font_size", 16 if nama_kontak.length() <= 8 else 11)
	nama.add_theme_color_override("font_color", Color.WHITE)
	nama.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nama.position = Vector2(0, 84)
	nama.size = Vector2(94, 22)
	layar.add_child(nama)
	var status: = Label.new()
	status.text = "Telepon"
	status.add_theme_font_size_override("font_size", 10)
	status.add_theme_color_override("font_color", Color(0.85, 0.95, 0.9))
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status.position = Vector2(0, 106)
	status.size = Vector2(94, 16)
	layar.add_child(status)
	var tombol_rumah: = Panel.new()
	var gaya_rumah: = StyleBoxFlat.new()
	gaya_rumah.bg_color = Color("fff4e0")
	gaya_rumah.set_corner_radius_all(4)
	tombol_rumah.add_theme_stylebox_override("panel", gaya_rumah)
	tombol_rumah.position = Vector2(48, 156)
	tombol_rumah.size = Vector2(14, 8)
	tombol_rumah.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ponsel.add_child(tombol_rumah)
	return wadah




func _buat_potret_bapak() -> void :
	_potret_bapak = SubViewport.new()
	_potret_bapak.size = Vector2i(352, 352)
	_potret_bapak.transparent_bg = true
	_potret_bapak.own_world_3d = true
	_potret_bapak.msaa_3d = GameState.msaa_3d()
	_potret_bapak.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(_potret_bapak)
	var lingkungan: = Environment.new()
	lingkungan.background_mode = Environment.BG_CLEAR_COLOR
	lingkungan.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	lingkungan.ambient_light_color = Color(1.0, 0.85, 0.7)
	lingkungan.ambient_light_energy = 0.55
	lingkungan.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	var dunia: = WorldEnvironment.new()
	dunia.environment = lingkungan
	_potret_bapak.add_child(dunia)
	var lampu: = DirectionalLight3D.new()
	lampu.light_color = Color(1.0, 0.85, 0.65)
	lampu.light_energy = 1.3
	lampu.rotation = Vector3(deg_to_rad(-25), deg_to_rad(30), 0)
	_potret_bapak.add_child(lampu)
	var model: Node3D = GameState.muat_model("res://assets/karakter3d/" + GameState.file_model_penjaga())
	_potret_bapak.add_child(model)

	var tinggi: = 0.0
	for mi: MeshInstance3D in GameState.cari_anak(model, "MeshInstance3D"):
		tinggi = maxf(tinggi, (mi.global_transform * mi.get_aabb()).size.y)
	if tinggi > 0.0:
		var s: = 1.72 / tinggi
		model.scale = Vector3(s, s, s)
	var pemutar_ada: Array = GameState.cari_anak(model, "AnimationPlayer")
	if pemutar_ada.is_empty():
		return
	_animasi_potret = pemutar_ada[0]
	GameState.siapkan_animasi_penjaga(_animasi_potret)
	if _animasi_potret.has_animation("Idle_11"):
		_animasi_potret.get_animation("Idle_11").loop_mode = Animation.LOOP_LINEAR
		_animasi_potret.play("Idle_11")
	var kamera: = Camera3D.new()
	kamera.fov = 26.0
	kamera.position = Vector3(0.25, 1.55, 1.35)
	_potret_bapak.add_child(kamera)
	kamera.look_at(Vector3(0, 1.47, 0))
	kamera.current = true





func atur_tampil_target(_tampil: bool) -> void :
	if _kotak_target != null:
		_kotak_target.visible = false








const GAMBAR_TUTORIAL: = ["res://assets/tutorial/kartu_agus.png", "res://assets/tutorial/kartu_seret.png"]

signal _langkah_tutorial(lanjut: bool)

func _tampilkan_tutorial() -> void :
	var langkah: = [
		["Selamat datang di Warung Life Simulator! Pak Misran membuka warung di kampung kecil di Cianjur. Agus, anak satu-satunya, baru diterima kuliah di kota dan butuh biaya. Kumpulkan uang dari warung, lalu kirim ke Agus lewat HP, aplikasi Warga Bank, sebelum batas waktunya.", null], 
		["Cara melayani: lihat kertas pesanan, TAHAN barang di rak lalu SERET ke kresek hitam. Warung buka 09.00-17.00, libur hari Jumat. Biaya harian dipotong saat tutup, sewa ditagih tiap Minggu. Bagian lain dijelaskan sambil bermain.", null], 
	]
	_warung.dialog_aktif = true
	var lapisan: = Control.new()
	lapisan.set_anchors_preset(Control.PRESET_FULL_RECT)
	lapisan.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(lapisan)

	var gelap: Array[ColorRect] = []
	for i in 4:
		var r: = ColorRect.new()
		r.color = Color(0.03, 0.02, 0.01, 0.6)
		r.mouse_filter = Control.MOUSE_FILTER_IGNORE
		lapisan.add_child(r)
		gelap.append(r)
	var sorot: = Panel.new()
	var gaya: = StyleBoxFlat.new()
	gaya.draw_center = false
	gaya.set_border_width_all(5)
	gaya.border_color = Color(1, 0.84, 0.3)
	gaya.set_corner_radius_all(18)
	sorot.add_theme_stylebox_override("panel", gaya)
	sorot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lapisan.add_child(sorot)
	var kartu: = PanelContainer.new()
	kartu.custom_minimum_size = Vector2(620, 0)

	kartu.theme = preload("res://scripts/tema_tenang.gd").tema_emas()
	lapisan.add_child(kartu)
	var isi: = VBoxContainer.new()
	isi.add_theme_constant_override("separation", 12)
	kartu.add_child(isi)
	var nomor: = Label.new()
	nomor.theme_type_variation = &"LabelKepala"
	nomor.add_theme_font_size_override("font_size", 22)
	isi.add_child(nomor)

	var gambar: = TextureRect.new()
	gambar.custom_minimum_size = Vector2(580, 290)
	gambar.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	gambar.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	gambar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	isi.add_child(gambar)
	var teks: = Label.new()
	teks.add_theme_font_size_override("font_size", 24)
	teks.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	teks.custom_minimum_size = Vector2(580, 0)
	isi.add_child(teks)
	var tombol: = HBoxContainer.new()
	tombol.add_theme_constant_override("separation", 12)
	isi.add_child(tombol)
	_tambah_tombol(tombol, "Lanjut", &"TombolHijau", func(): _langkah_tutorial.emit(true))

	for i in langkah.size():
		nomor.text = "Panduan %d / %d" % [i + 1, langkah.size()]
		teks.text = langkah[i][0]
		var jalur: String = GAMBAR_TUTORIAL[i] if i < GAMBAR_TUTORIAL.size() else ""
		gambar.visible = jalur != "" and ResourceLoader.exists(jalur)
		if gambar.visible:
			gambar.texture = load(jalur)
		teks.add_theme_font_size_override("font_size", 20 if gambar.visible else 24)
		var sasaran: Control = langkah[i][1]
		var layar: = size
		var r: = Rect2(layar / 2.0, Vector2.ZERO)
		var ada_sasaran: bool = sasaran != null and sasaran.is_visible_in_tree()
		if ada_sasaran:
			r = sasaran.get_global_rect().grow(8)
		sorot.visible = ada_sasaran
		sorot.position = r.position
		sorot.size = r.size
		gelap[0].position = Vector2.ZERO;gelap[0].size = Vector2(layar.x, r.position.y)
		gelap[1].position = Vector2(0, r.end.y);gelap[1].size = Vector2(layar.x, layar.y - r.end.y)
		gelap[2].position = Vector2(0, r.position.y);gelap[2].size = Vector2(r.position.x, r.size.y)
		gelap[3].position = Vector2(r.end.x, r.position.y);gelap[3].size = Vector2(layar.x - r.end.x, r.size.y)
		kartu.reset_size()

		var y: = (layar.y - kartu.size.y) / 2.0
		if ada_sasaran:
			y = r.position.y - kartu.size.y - 20.0 if r.get_center().y > layar.y / 2.0 else r.end.y + 20.0
		kartu.position = Vector2((layar.x - kartu.size.x) / 2.0, clampf(y, 10.0, layar.y - kartu.size.y - 10.0))
		var lanjut: bool = await _langkah_tutorial
		if not lanjut:
			break
	lapisan.queue_free()
	_warung.dialog_aktif = false
