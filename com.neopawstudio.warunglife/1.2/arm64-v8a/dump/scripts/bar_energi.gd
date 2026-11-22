extends PanelContainer







var adegan: Node
var akar: Control
var _baterai: Control
var _label: Label

const GH: = preload("res://scripts/gaya_hud.gd")
const UKURAN_BATERAI: = Vector2(GH.LEBAR_BAR_ENERGI, 12)



func _ready() -> void :
	add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	var baris: = VBoxContainer.new()
	baris.add_theme_constant_override("separation", 6)
	baris.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(baris)
	_label = GH.tebal(GH.label("", GH.UKURAN_ENERGI_HUD, Color.WHITE, true))
	_label.add_theme_constant_override("outline_size", 5)
	baris.add_child(_label)
	_baterai = Control.new()
	_baterai.custom_minimum_size = UKURAN_BATERAI
	_baterai.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_baterai.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_baterai.draw.connect(_gambar_baterai)
	baris.add_child(_baterai)
	gui_input.connect( func(e: InputEvent):
		if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
			_buka_istirahat())


func _process(_delta: float) -> void :


	_label.text = "ENERGI %d%%" % int(floor(GameState.energi))
	_baterai.queue_redraw()
	if adegan != null and GameState.perlu_ingatkan_lelah() and adegan.has_method("tampilkan_pesan"):
		adegan.tampilkan_pesan("Pak Misran mulai ngantuk... Klik bar Energi untuk ngopi atau makan, atau segera tidur.", 5.0)

	if adegan != null and adegan.has_method("tampilkan_pesan") and adegan.get("dialog_aktif") != true and adegan.get("sibuk") != true\
	and adegan.get("hp") != null and not adegan.hp.visible and GameState.perlu_ingatkan_kirim():
		GameState.kabari_uang_cukup()
		adegan.tampilkan_pesan("Uang sudah cukup untuk %s. %s." % [GameState.nama_penerima(), GameState.teks_cara_kirim()], 7.0)


func _warna(e: float) -> Color:
	if e >= 60.0:
		return Color(0.35, 0.82, 0.38)
	if e >= GameState.BATAS_LELAH:
		return Color(0.98, 0.76, 0.2)
	return Color(0.93, 0.3, 0.22)




func _gambar_baterai() -> void :
	var warna: = _warna(GameState.energi)
	if GameState.lelah():
		warna.a = 0.45 + 0.55 * absf(sin(Time.get_ticks_msec() / 350.0))
	GH.gambar_bar(_baterai, GameState.energi / 100.0, warna)


func _jeda(nyala: bool) -> void :
	if adegan == null:
		return
	if "dialog_aktif" in adegan:
		adegan.dialog_aktif = nyala
	elif "sibuk" in adegan:
		adegan.sibuk = nyala


func _sedang_sibuk() -> bool:
	if adegan == null:
		return true
	if "dialog_aktif" in adegan and adegan.dialog_aktif:
		return true
	if "sibuk" in adegan and adegan.sibuk:
		return true
	return false


func _buka_istirahat() -> void :
	if _sedang_sibuk() or akar == null:
		return
	GameState.klik()
	_jeda(true)
	var lapisan: = ColorRect.new()
	lapisan.color = Color(0.03, 0.02, 0.01, 0.6)
	lapisan.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	akar.add_child(lapisan)
	var tengah: = CenterContainer.new()
	tengah.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	lapisan.add_child(tengah)
	var panel: = PanelContainer.new()
	panel.custom_minimum_size = Vector2(560, 0)
	tengah.add_child(panel)
	var isi: = VBoxContainer.new()
	isi.add_theme_constant_override("separation", 12)
	panel.add_child(isi)
	var judul: = Label.new()
	judul.text = "ENERGI PAK MISRAN: %d%%" % int(GameState.energi)
	GH.gaya_jendela(panel, judul)
	isi.add_child(judul)
	var ket: = Label.new()
	ket.text = "Ngopi (+%d%%) dan makan mi rebus (+%d%%) pakai stok warung sendiri, masing-masing %d kali sehari. Masih kurang? Tonton iklan untuk energi penuh (%d kali sehari). Di bawah %d%% Pak Misran tidak kuat membuka warung." % [
		int(GameState.ENERGI_KOPI), int(GameState.ENERGI_MAKAN), GameState.MAKS_ISTIRAHAT_HARIAN, GameState.MAKS_IKLAN_ENERGI, int(GameState.ENERGI_MIN_BUKA)]
	if GameState.ramadan():
		ket.text = "Bulan puasa: Pak Misran berpuasa, jadi tidak ngopi atau makan di siang hari. Sesudah adzan Maghrib (18.00) bisa buka puasa sekali sehari. Masih kurang? Tonton iklan untuk energi penuh (%d kali sehari)." % GameState.MAKS_IKLAN_ENERGI
	ket.add_theme_font_size_override("font_size", 18)
	ket.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ket.custom_minimum_size.x = 520

	var k: = GameState.PENGALI_ENERGI_RUMAH_BARU if GameState.rumah_renovasi else 1.0
	var laju: = Label.new()
	laju.text = "Energi berkurang seiring waktu: sekitar %d%% per jam sampai pukul 21.00, lalu sekitar %d%% per jam sesudahnya. Banyak atau sedikitnya pembeli tidak berpengaruh. Berlari dan kerja sampingan memakai energi tambahan." % [
		maxi(1, roundi(GameState.ENERGI_PER_MENIT_SIANG * 60.0 * k)), maxi(1, roundi(GameState.ENERGI_PER_MENIT_MALAM * 60.0 * k))]
	laju.add_theme_font_size_override("font_size", 17)
	laju.add_theme_color_override("font_color", Color(1, 1, 1, 0.75))
	laju.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	laju.custom_minimum_size.x = 520
	isi.add_child(laju)
	isi.add_child(ket)
	var pesan: = Label.new()
	pesan.add_theme_font_size_override("font_size", 18)
	pesan.add_theme_color_override("font_color", Color(1, 0.5, 0.45))
	pesan.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	pesan.custom_minimum_size.x = 520
	var tutup: = func():
		lapisan.queue_free()
		_jeda(false)
	var tombol_pilihan: Array = []
	for p in GameState.pilihan_istirahat():
		var b: = Button.new()
		b.custom_minimum_size = Vector2(0, 64)
		b.add_theme_font_size_override("font_size", 21)
		var id: String = p[0]
		b.pressed.connect( func():
			var alasan: = GameState.istirahat(id)
			if alasan != "":
				pesan.text = alasan
				return
			GameState.bunyi("koin")
			tutup.call()
			if adegan.has_method("tampilkan_pesan"):
				adegan.tampilkan_pesan("Pak Misran %s. Energi sekarang %d%%." % [{"ngopi": "ngopi sebentar", "makan": "makan mi dulu", "buka": "berbuka puasa"}.get(id, "istirahat"), int(GameState.energi)], 4.0))
		isi.add_child(b)
		tombol_pilihan.append([b, p])

	var tombol_iklan: = Button.new()
	tombol_iklan.custom_minimum_size = Vector2(0, 64)
	tombol_iklan.add_theme_font_size_override("font_size", 21)
	tombol_iklan.pressed.connect( func():
		var alasan: = GameState.alasan_tidak_bisa_iklan_energi()
		if alasan != "":
			pesan.text = alasan
			return

		lapisan.hide()
		var berhasil: bool = await GameState.tonton_iklan(akar)
		tutup.call()
		if not berhasil:
			if adegan.has_method("tampilkan_pesan"):
				adegan.tampilkan_pesan("Iklan tidak selesai, energi tidak bertambah.", 3.0)
			return
		GameState.isi_energi_iklan()
		GameState.bunyi("hadiah")
		if adegan.has_method("tampilkan_pesan"):
			adegan.tampilkan_pesan("Pak Misran segar kembali! Energi 100%.", 4.0))
	isi.add_child(tombol_iklan)
	isi.add_child(pesan)
	var batal: = Button.new()
	batal.text = "Nanti saja"
	batal.theme_type_variation = &"TombolKayu"
	batal.custom_minimum_size = Vector2(0, 58)
	batal.add_theme_font_size_override("font_size", 22)
	batal.pressed.connect(tutup)
	isi.add_child(batal)

	while is_instance_valid(lapisan) and not lapisan.is_queued_for_deletion():
		for tp in tombol_pilihan:
			_isi_tombol(tp[0], tp[1])
		var bisa_iklan: = GameState.sisa_iklan_energi() > 0
		tombol_iklan.disabled = not bisa_iklan
		tombol_iklan.theme_type_variation = &"TombolHijau" if bisa_iklan else &"TombolKayu"
		tombol_iklan.text = ("Bebas iklan · energi penuh 100%" if GameState.tanpa_iklan else "Tonton iklan · energi penuh 100%") if bisa_iklan else "Energi penuh · sudah dipakai hari ini"
		await GameState.get_tree().create_timer(0.5, true, false, true).timeout


func _isi_tombol(b: Button, p: Array) -> void :
	var id: String = p[0]
	var barang: = GameState.barang_istirahat(p)
	var sisa: = GameState.sisa_istirahat(id)
	var tunggu: = GameState.tunggu_istirahat(id)
	var belum_maghrib: = id == "buka" and GameState.menit < GameState.JAM_MAGHRIB
	var bisa: = not barang.is_empty() and sisa > 0 and tunggu <= 0.0
	bisa = bisa and not belum_maghrib
	b.disabled = not bisa
	b.theme_type_variation = &"TombolHijau" if bisa else &"TombolKayu"
	if belum_maghrib and sisa > 0:
		b.text = "%s · mulai 18.00 (sesudah Maghrib)" % p[1]
	elif sisa <= 0:
		b.text = "%s · sudah %d kali hari ini" % [p[1], GameState.maks_istirahat(id)]
	elif tunggu > 0.0:
		b.text = "%s · bisa lagi dalam %s" % [p[1], GameState.teks_durasi(tunggu)]
	elif barang.is_empty():
		b.text = "%s · stok habis" % p[1]
	else:
		var nama: = "teh manis buatan sendiri" if String(barang[0]) == "" else String(GameState.data_barang(barang[0]).get("sebutan", GameState.data_barang(barang[0])["nama"])).to_lower()
		b.text = "%s (1 %s) · +%d energi · sisa %dx" % [p[1], nama, int(barang[1]), sisa]
