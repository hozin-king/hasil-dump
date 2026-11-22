extends Control





@onready var geser_volume: HSlider = %GeserVolume
@onready var label_volume: Label = %LabelVolume
@onready var tombol_kecepatan: = {"lambat": %TombolLambat, "normal": %TombolNormal, "cepat": %TombolCepat}
@onready var keterangan_kecepatan: Label = %KeteranganKecepatan
@onready var tombol_kembali: Button = %TombolKembali

const TEMA: = preload("res://scripts/tema_tenang.gd")
const LEBAR_KOLOM: = 540.0
const PILIHAN_KUALITAS: = [["rendah", "Rendah"], ["sedang", "Sedang"], ["tinggi", "Tinggi"]]
var tombol_kualitas: = {}
var tombol_baterai: Button
var tombol_data: Button
var tombol_bahasa: = {}
var tombol_layani: = {}
var _ket_layani: Label
const URL_KEBIJAKAN_PRIVASI: = "https://neopawstudio.github.io/privasi.html"
var label_panduan: Label
var _geser_musik: HSlider
var _label_musik: Label
var _geser_sekitar: HSlider
var _label_sekitar: Label


var dalam_game: = false


var bisa_reset_posisi: = false
var minta_reset_posisi: = false
var tombol_reset_posisi: Button = null
signal ditutup


func _ready() -> void :


	theme = TEMA.tema_emas()
	if dalam_game:
		process_mode = Node.PROCESS_MODE_ALWAYS
		z_index = 120
	else:
		GameState.putar_musik("menu")
	var isi: VBoxContainer = tombol_kembali.get_parent()
	(isi.get_node("Judul") as Label).text = "Pengaturan"
	TEMA.GH.pita_emas(isi.get_node("Judul") as Label, 34)
	geser_volume.value = GameState.volume * 100.0
	geser_volume.value_changed.connect(_on_volume_berubah)


	isi.get_node("JudulVolume").hide()
	var baris_suara: HBoxContainer = geser_volume.get_parent()
	baris_suara.add_child(_nama_baris("Efek Suara"))
	baris_suara.move_child(baris_suara.get_child(baris_suara.get_child_count() - 1), 0)
	var baris_musik: = HBoxContainer.new()
	baris_musik.add_theme_constant_override("separation", baris_suara.get_theme_constant("separation"))
	isi.add_child(baris_musik)
	isi.move_child(baris_musik, baris_suara.get_index())
	baris_musik.add_child(_nama_baris("Musik"))
	_geser_musik = HSlider.new()
	_geser_musik.min_value = geser_volume.min_value
	_geser_musik.max_value = geser_volume.max_value
	_geser_musik.step = geser_volume.step
	_geser_musik.custom_minimum_size = geser_volume.custom_minimum_size
	_geser_musik.size_flags_horizontal = geser_volume.size_flags_horizontal
	_geser_musik.size_flags_vertical = geser_volume.size_flags_vertical
	baris_musik.add_child(_geser_musik)
	_label_musik = Label.new()
	for l in [label_volume, _label_musik]:
		l.custom_minimum_size.x = 80
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_label_musik.add_theme_font_size_override("font_size", label_volume.get_theme_font_size("font_size"))
	baris_musik.add_child(_label_musik)
	_geser_musik.value = GameState.volume_musik * 100.0
	_geser_musik.value_changed.connect( func(nilai: float):
		GameState.atur_volume_musik(nilai / 100.0)
		_perbarui())

	var baris_sekitar: = HBoxContainer.new()
	baris_sekitar.add_theme_constant_override("separation", baris_suara.get_theme_constant("separation"))
	isi.add_child(baris_sekitar)
	isi.move_child(baris_sekitar, baris_suara.get_index() + 1)
	baris_sekitar.add_child(_nama_baris("Suara Sekitar"))
	_geser_sekitar = HSlider.new()
	_geser_sekitar.min_value = geser_volume.min_value
	_geser_sekitar.max_value = geser_volume.max_value
	_geser_sekitar.step = geser_volume.step
	_geser_sekitar.custom_minimum_size = geser_volume.custom_minimum_size
	_geser_sekitar.size_flags_horizontal = geser_volume.size_flags_horizontal
	_geser_sekitar.size_flags_vertical = geser_volume.size_flags_vertical
	baris_sekitar.add_child(_geser_sekitar)
	_label_sekitar = Label.new()
	_label_sekitar.custom_minimum_size.x = 80
	_label_sekitar.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_label_sekitar.add_theme_font_size_override("font_size", label_volume.get_theme_font_size("font_size"))
	baris_sekitar.add_child(_label_sekitar)
	_geser_sekitar.value = GameState.volume_sekitar * 100.0
	_geser_sekitar.value_changed.connect( func(nilai: float):
		GameState.atur_volume_sekitar(nilai / 100.0)
		_perbarui())

	for b in [baris_musik, baris_suara, baris_sekitar]:
		var nama: Label = b.get_child(0)
		nama.custom_minimum_size.x = 150
		nama.add_theme_font_size_override("font_size", 20)

	isi.get_node("JudulKecepatan").hide()
	isi.get_node("BarisKecepatan").hide()
	keterangan_kecepatan.hide()
	var posisi: = tombol_kembali.get_index()

	var judul_kualitas: = _judul("Kualitas grafik")
	isi.add_child(judul_kualitas)
	var baris: = HBoxContainer.new()
	baris.add_theme_constant_override("separation", 12)
	isi.add_child(baris)
	for p in PILIHAN_KUALITAS:
		var b: = Button.new()
		b.text = p[1]
		b.custom_minimum_size = Vector2(140, 58)
		b.add_theme_font_size_override("font_size", 26)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.pressed.connect( func():
			GameState.atur_kualitas(p[0], true)
			_perbarui())
		baris.add_child(b)
		tombol_kualitas[p[0]] = b
	var ket: = Label.new()
	ket.text = "Rendah = paling ringan untuk HP lemah (30 FPS, warga & kendaraan lebih sedikit). Berlaku penuh setelah pindah layar."
	ket.add_theme_font_size_override("font_size", 14)
	ket.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ket.custom_minimum_size.x = 520
	ket.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	isi.add_child(ket)

	var baris_layani: = HBoxContainer.new()
	baris_layani.add_theme_constant_override("separation", 12)
	isi.add_child(baris_layani)
	var judul_layani: = _nama_baris("Cara\nmelayani")
	judul_layani.add_theme_font_size_override("font_size", 18)
	judul_layani.custom_minimum_size.x = 100
	baris_layani.add_child(judul_layani)
	for p in [["seret", "Seret"], ["ketuk", "Klik"]]:
		var b: = Button.new()
		b.text = p[1]
		b.custom_minimum_size = Vector2(150, 54)
		b.add_theme_font_size_override("font_size", 24)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var cara: String = p[0]
		b.pressed.connect( func():
			GameState.klik()
			GameState.atur_cara_layani(cara)
			_perbarui())
		baris_layani.add_child(b)
		tombol_layani[cara] = b
	_ket_layani = Label.new()
	_ket_layani.add_theme_font_size_override("font_size", 14)
	_ket_layani.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_ket_layani.custom_minimum_size.x = 520
	isi.add_child(_ket_layani)

	var tombol_ganti_nama: Button = null
	if dalam_game:
		var ganti_nama: = Button.new()
		tombol_ganti_nama = ganti_nama
		ganti_nama.theme_type_variation = &"TombolKayu"
		ganti_nama.custom_minimum_size = Vector2(0, 58)
		ganti_nama.add_theme_font_size_override("font_size", 22)
		ganti_nama.text = "Ganti nama warung" + (" (gratis 1x)" if GameState.ganti_nama_gratis() else " (tonton iklan)")
		ganti_nama.pressed.connect( func():
			GameState.klik()
			var j: CanvasLayer = load("res://scripts/ganti_nama_warung.gd").new()
			j.selesai.connect( func(_berhasil: bool):
				if is_instance_valid(ganti_nama):
					ganti_nama.text = "Ganti nama warung" + (" (gratis 1x)" if GameState.ganti_nama_gratis() else " (tonton iklan)"))
			get_tree().root.add_child(j))
		isi.add_child(ganti_nama)



		var reset_posisi: = Button.new()
		tombol_reset_posisi = reset_posisi
		reset_posisi.theme_type_variation = &"TombolKayu"
		reset_posisi.custom_minimum_size = Vector2(0, 58)
		reset_posisi.add_theme_font_size_override("font_size", 22)
		reset_posisi.text = "Pak Misran nyangkut? Pindahkan"
		reset_posisi.pressed.connect( func():
			GameState.klik()
			if not bisa_reset_posisi:
				label_panduan.text = "Di dalam warung Pak Misran tidak bisa nyangkut. Tombol ini dipakai saat jalan-jalan di luar."
				label_panduan.show()
				return
			minta_reset_posisi = true
			_on_kembali())
		isi.add_child(reset_posisi)


	var baris_bahasa: = HBoxContainer.new()
	baris_bahasa.add_theme_constant_override("separation", 12)
	isi.add_child(baris_bahasa)
	var judul_bahasa: = _nama_baris("Language")
	judul_bahasa.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	judul_bahasa.text = "Bahasa\nLanguage"
	judul_bahasa.add_theme_font_size_override("font_size", 18)
	judul_bahasa.custom_minimum_size.x = 100
	baris_bahasa.add_child(judul_bahasa)
	for p in [["id", "Indonesia"], ["en", "English"]]:
		var b: = Button.new()
		b.text = p[1]
		b.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
		b.custom_minimum_size = Vector2(150, 54)
		b.add_theme_font_size_override("font_size", 24)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var kode: String = p[0]
		b.pressed.connect( func():
			GameState.atur_bahasa(kode)
			_perbarui())
		baris_bahasa.add_child(b)
		tombol_bahasa[kode] = b

	tombol_baterai = Button.new()
	tombol_baterai.custom_minimum_size = Vector2(0, 52)
	tombol_baterai.add_theme_font_size_override("font_size", 24)
	tombol_baterai.pressed.connect( func():
		GameState.atur_hemat_baterai( not GameState.hemat_baterai)
		_perbarui())
	isi.add_child(tombol_baterai)

	var panduan: = Button.new()
	panduan.text = "Ulangi tutorial"
	panduan.theme_type_variation = &"TombolHijau"
	panduan.custom_minimum_size = Vector2(0, 48)
	panduan.add_theme_font_size_override("font_size", 19)
	label_panduan = Label.new()
	label_panduan.add_theme_font_size_override("font_size", 19)
	panduan.pressed.connect( func():
		GameState.tutorial_selesai = false
		label_panduan.text = "Tutorial lengkap akan diputar lagi saat memulai permainan baru."
		label_panduan.show()
		GameState.simpan_pengaturan())

	var privasi: = Button.new()
	privasi.text = "Kebijakan privasi"
	privasi.theme_type_variation = &"TombolHijau"
	privasi.custom_minimum_size = Vector2(0, 48)
	privasi.add_theme_font_size_override("font_size", 19)
	privasi.pressed.connect( func(): OS.shell_open(URL_KEBIJAKAN_PRIVASI))


	var pulihkan: = Button.new()
	pulihkan.text = "Pulihkan pembelian"
	pulihkan.theme_type_variation = &"TombolHijau"
	pulihkan.custom_minimum_size = Vector2(0, 48)
	pulihkan.add_theme_font_size_override("font_size", 19)
	pulihkan.pressed.connect( func():
		GameState.klik()
		label_panduan.show()
		GameState.pulihkan_pembelian(true))
	GameState.pesan_toko.connect(_on_pesan_toko)


	var masukan: = Button.new()
	masukan.text = "Kirim masukan"
	masukan.theme_type_variation = &"TombolHijau"
	masukan.custom_minimum_size = Vector2(0, 48)
	masukan.add_theme_font_size_override("font_size", 19)
	masukan.pressed.connect( func():
		GameState.klik()
		OS.shell_open(GameState.url_masukan()))
	var baris_toko: = HBoxContainer.new()
	baris_toko.add_theme_constant_override("separation", 12)
	pulihkan.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	masukan.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	baris_toko.add_child(masukan)
	baris_toko.add_child(pulihkan)
	isi.add_child(baris_toko)

	var promo: = Button.new()
	promo.text = "Kode promo"
	promo.theme_type_variation = &"TombolHijau"
	promo.custom_minimum_size = Vector2(0, 48)
	promo.add_theme_font_size_override("font_size", 19)
	promo.pressed.connect( func():
		GameState.klik()
		get_tree().root.add_child(load("res://scripts/kode_promo.gd").new()))



	var pakai_akun: bool = GameState.akun != null and (GameState.akun.tersedia() or GameState.akun.tertaut())
	var pindah: = Button.new()
	pindah.text = ("Akun tertaut ✓" if GameState.akun.tertaut() else "Tautkan akun") if pakai_akun else "Pindah HP"
	pindah.theme_type_variation = &"TombolHijau"
	pindah.custom_minimum_size = Vector2(0, 48)
	pindah.add_theme_font_size_override("font_size", 19)
	pindah.pressed.connect( func():
		GameState.klik()
		var jendela: CanvasLayer = load("res://scripts/akun_tautan.gd" if pakai_akun else "res://scripts/pindah_hp.gd").new()
		jendela.dalam_game = dalam_game
		get_tree().root.add_child(jendela))
	var baris_promo: = HBoxContainer.new()
	baris_promo.add_theme_constant_override("separation", 12)
	promo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pindah.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	baris_promo.add_child(pindah)
	baris_promo.add_child(promo)
	isi.add_child(baris_promo)
	var baris_bawah: = HBoxContainer.new()
	baris_bawah.add_theme_constant_override("separation", 12)
	panduan.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	privasi.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	baris_bawah.add_child(panduan)
	baris_bawah.add_child(privasi)

	tombol_data = Button.new()
	tombol_data.custom_minimum_size = Vector2(0, 48)
	tombol_data.add_theme_font_size_override("font_size", 20)
	tombol_data.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tombol_data.pressed.connect(_ubah_data_anonim)
	baris_bawah.add_child(tombol_data)
	isi.add_child(baris_bawah)
	panduan.visible = not dalam_game
	isi.add_child(label_panduan)
	label_panduan.hide()
	tombol_kembali.custom_minimum_size.y = 58
	tombol_kembali.add_theme_font_size_override("font_size", 24)
	tombol_kembali.theme_type_variation = &"TombolUtama"

	judul_kualitas.queue_free()
	for k in [ket, _ket_layani]:
		k.theme_type_variation = &"LabelRedup"
	var kelompok: = [
		["Suara", [baris_musik, baris_suara, baris_sekitar]], 
		["Tampilan", [baris, ket, tombol_baterai, baris_bahasa]], 
		["Permainan", [baris_layani, _ket_layani, tombol_ganti_nama, tombol_reset_posisi]], 
		["Lainnya", [baris_toko, baris_promo, baris_bawah]], 
	]

	var dua_kolom: = HBoxContainer.new()
	dua_kolom.add_theme_constant_override("separation", 14)
	isi.add_child(dua_kolom)
	isi.move_child(dua_kolom, (isi.get_node("Judul") as Control).get_index() + 1)
	var kolom: Array = []
	for i in 2:
		var v: = VBoxContainer.new()
		v.add_theme_constant_override("separation", 14)
		v.custom_minimum_size.x = LEBAR_KOLOM
		v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		dua_kolom.add_child(v)
		kolom.append(v)
	for k in [ket, _ket_layani]:
		k.custom_minimum_size.x = 0
	for gi in kelompok.size():
		var g: Array = kelompok[gi]
		var b: Array = TEMA.bagian(g[0])
		(kolom[0 if gi < 2 else 1] as VBoxContainer).add_child(b[0])
		for n in g[1]:
			if n == null:
				continue
			n.get_parent().remove_child(n)
			b[1].add_child(n)
	isi.add_theme_constant_override("separation", 14)
	isi.move_child(tombol_kembali, isi.get_child_count() - 1)
	tombol_kembali.pressed.connect(_on_kembali)
	_perbarui()
	_pasang_gulir.call_deferred()




func _pasang_gulir() -> void :
	var isi: VBoxContainer = tombol_kembali.get_parent()
	var panel: = isi.get_parent() as PanelContainer
	if panel == null:
		return
	isi.add_theme_constant_override("separation", 14)
	var luar: = VBoxContainer.new()
	luar.add_theme_constant_override("separation", 14)
	var gulir: ScrollContainer = load("res://scripts/hp/gulir_sentuh.gd").new()
	gulir.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	gulir.scroll_deadzone = 8
	panel.remove_child(isi)
	panel.add_child(luar)
	luar.add_child(gulir)
	gulir.add_child(isi)
	isi.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	isi.remove_child(tombol_kembali)
	luar.add_child(tombol_kembali)
	var gaya: = panel.get_theme_stylebox("panel")
	var tepi_panel: = gaya.get_margin(SIDE_TOP) + gaya.get_margin(SIDE_BOTTOM) if gaya != null else 40.0
	var maks: = get_viewport_rect().size.y - 24.0 - tepi_panel - tombol_kembali.get_combined_minimum_size().y - 14.0
	var tinggi_isi: = isi.get_combined_minimum_size().y
	gulir.custom_minimum_size = Vector2(isi.get_combined_minimum_size().x, minf(tinggi_isi, maxf(maks, 200.0)))


func _on_pesan_toko(teks: String) -> void :
	if is_instance_valid(label_panduan):
		label_panduan.text = teks
		label_panduan.show()


func _exit_tree() -> void :
	if GameState.pesan_toko.is_connected(_on_pesan_toko):
		GameState.pesan_toko.disconnect(_on_pesan_toko)


func _ubah_data_anonim() -> void :
	if not GameState.analitik.aktif:
		GameState.analitik.atur_aktif(true)
		label_panduan.text = "Terima kasih! Data anonim membantu kami membuat game lebih baik."
		label_panduan.show()
		_perbarui()
		return
	GameState.analitik.atur_aktif(false)
	_perbarui()
	label_panduan.text = "Menghapus data dari server..."
	label_panduan.show()
	var ok: bool = await GameState.analitik.hapus_data_server()
	if is_instance_valid(label_panduan):
		label_panduan.text = "Data anonim dimatikan dan data dari HP ini sudah dihapus." if ok else "Data anonim dimatikan. Penghapusan di server gagal (periksa internet), coba matikan lagi nanti."


func _nama_baris(teks: String) -> Label:
	var l: = Label.new()
	l.text = teks
	l.custom_minimum_size.x = 90
	l.add_theme_font_size_override("font_size", 24)
	return l


func _judul(teks: String) -> Label:
	var l: = Label.new()
	l.text = teks
	l.theme_type_variation = &"LabelKepala"
	l.add_theme_font_size_override("font_size", 28)
	return l


func _on_volume_berubah(nilai: float) -> void :
	GameState.atur_volume(nilai / 100.0)
	_perbarui()


func _perbarui() -> void :
	label_volume.text = "%d%%" % int(geser_volume.value)
	if _label_musik != null:
		_label_musik.text = "%d%%" % int(_geser_musik.value)
	if _label_sekitar != null:
		_label_sekitar.text = "%d%%" % int(_geser_sekitar.value)
	for k in tombol_kualitas:
		(tombol_kualitas[k] as Button).theme_type_variation = &"TombolHijau" if k == GameState.kualitas else &"TombolKayu"
	for k in tombol_bahasa:
		(tombol_bahasa[k] as Button).theme_type_variation = &"TombolHijau" if k == GameState.bahasa else &"TombolKayu"
	for k in tombol_layani:
		(tombol_layani[k] as Button).theme_type_variation = &"TombolHijau" if k == GameState.cara_layani else &"TombolKayu"
	if _ket_layani != null:
		_ket_layani.text = "Klik = klik barang di rak, langsung masuk kresek (cocok untuk layar kecil). Seret = tahan barang lalu seret ke kresek. Menyeret tetap bisa di kedua cara." if GameState.cara_layani == "ketuk"\
		else "Seret = tahan barang di rak lalu seret ke kresek. Klik = cukup klik barangnya, langsung masuk kresek."
	tombol_baterai.text = "Hemat baterai: aktif (30 FPS, lebih awet)" if GameState.hemat_baterai else "Hemat baterai: mati (60 FPS, lebih mulus)"
	tombol_baterai.theme_type_variation = &"TombolHijau" if GameState.hemat_baterai else &"TombolKayu"
	if tombol_data != null:
		tombol_data.text = "Data anonim: aktif" if GameState.analitik.aktif else "Data anonim: mati"
		tombol_data.theme_type_variation = &"TombolHijau" if GameState.analitik.aktif else &"TombolKayu"


func _on_kembali() -> void :
	GameState.simpan_pengaturan()
	if dalam_game:
		ditutup.emit()
		queue_free()
		return
	GameState.ganti_layar(self, "res://scenes/main_menu.tscn")
