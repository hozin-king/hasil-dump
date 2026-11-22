extends CanvasLayer






const GH: = preload("res://scripts/gaya_hud.gd")

signal _jawab(ya: bool)

var dalam_game: = false
var mulai_masuk: = false

var _isi: VBoxContainer
var _pesan: Label
var _sibuk: = false
var _pilih_cloud: = false
var _tanya_lapisan: Control = null


func _ready() -> void :
	layer = 96
	process_mode = Node.PROCESS_MODE_ALWAYS
	var lapisan: = ColorRect.new()
	lapisan.color = Color(0.03, 0.02, 0.01, 0.78)
	lapisan.set_anchors_preset(Control.PRESET_FULL_RECT)
	lapisan.mouse_filter = Control.MOUSE_FILTER_STOP
	lapisan.theme = GH.tema_jendela_emas()
	lapisan.add_to_group("lapisan_atas")
	add_child(lapisan)
	var tengah: = CenterContainer.new()
	tengah.set_anchors_preset(Control.PRESET_FULL_RECT)
	lapisan.add_child(tengah)
	var kartu: PanelContainer = GH.panel_emas(Vector4(30, 24, 30, 24))
	kartu.custom_minimum_size = Vector2(620, 0)
	tengah.add_child(kartu)
	_isi = VBoxContainer.new()
	_isi.add_theme_constant_override("separation", 12)
	kartu.add_child(_isi)
	GameState.akun.berubah.connect(_bangun)
	_bangun()

	if mulai_masuk and not GameState.akun.tertaut() and OS.get_name() != "iOS":
		_masuk.call_deferred(null)


func _label(teks: String, ukuran: int, warna: Color) -> Label:
	var l: = Label.new()
	l.text = teks
	l.add_theme_font_size_override("font_size", ukuran)
	l.add_theme_color_override("font_color", warna)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.custom_minimum_size.x = 560
	return l


func _tombol(teks: String, gaya: StringName, ukuran: = 22, tinggi: = 58) -> Button:
	var b: = Button.new()
	b.text = teks
	b.theme_type_variation = gaya
	b.custom_minimum_size = Vector2(0, tinggi)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.add_theme_font_size_override("font_size", ukuran)
	return b


func _bangun() -> void :
	if not is_instance_valid(_isi) or _sibuk:
		return
	for c in _isi.get_children():
		c.queue_free()
	var akun: Node = GameState.akun
	var judul: = _label(_tk_akun("Akun Google") if akun.tertaut() else "Tautkan akun", 30, GH.KUNING)
	judul.theme_type_variation = &"LabelKepala"
	_isi.add_child(judul)
	if not akun.tertaut():
		_bangun_belum_tertaut()
	elif _pilih_cloud or akun.bentrok or akun.mundur:
		_bangun_pilih()
	else:
		_bangun_tertaut()
	_pesan = _label("", 18, Color(0.9, 0.9, 0.9))
	_isi.add_child(_pesan)
	var tutup: = _tombol("Tutup", &"TombolKayu", 20, 50)
	tutup.pressed.connect(_tutup)
	_isi.add_child(tutup)


func _baris_kecil(tombol: Array) -> void :
	var baris: = HBoxContainer.new()
	baris.add_theme_constant_override("separation", 10)
	_isi.add_child(baris)
	for b in tombol:
		baris.add_child(b)


func _bangun_belum_tertaut() -> void :

	if GameState.akun.sesi_berakhir():
		_isi.add_child(_label("Akunmu keluar dengan sendirinya, jadi warung belum tersimpan ke cloud. Tautkan lagi dengan akun yang sama.", 18, GH.KUNING))
	if OS.get_name() == "iOS":

		_isi.add_child(_label("Tautkan akun supaya warungmu tidak hilang walau ganti HP.", 20, Color.WHITE))
		for p in GameState.akun.penyedia_tersedia():
			var b: = _tombol("Masuk dengan Apple" if p == "apple" else "Masuk dengan Google", &"TombolHijau", 24, 66)
			b.pressed.connect(_masuk.bind(b, p))
			_isi.add_child(b)

		_isi.add_child(_label("Pernah main di HP lain? Pilih Google dengan akun yang sama seperti di HP itu, supaya warung, Tanpa Iklan, dan dukungan ikut.", 16, GH.KUNING))
	else:
		_isi.add_child(_label("Tautkan akun Google supaya warungmu tidak hilang walau ganti HP.", 20, Color.WHITE))
		var masuk: = _tombol("Tautkan akun Google", &"TombolHijau", 24, 66)
		masuk.pressed.connect(_masuk.bind(masuk))
		_isi.add_child(masuk)
	_isi.add_child(_label("Bonus Rp100.000 untuk pertama kali. Tidak wajib.", 18, GH.HIJAU_UANG))


	_isi.add_child(_tombol_kode_kecil())


func _bangun_tertaut() -> void :
	var akun: Node = GameState.akun

	if akun.kirim_otomatis_gagal():
		_isi.add_child(_label("Simpanan terakhir belum terkirim ke cloud. Cek internet, lalu tekan Simpan sekarang.", 21, GH.KUNING))

	elif akun.cloud_kosong or akun.versi_cloud() == 0:
		_isi.add_child(_label("Warungmu BELUM tersimpan di cloud. Tekan Simpan sekarang.", 21, GH.KUNING))
	else:
		_isi.add_child(_label("✓ Warungmu tersimpan aman di cloud", 23, GH.HIJAU_UANG))
	var jam: String = akun.jam_disimpan()
	_isi.add_child(_label(akun.email() + ("  ·  " + GameState.tk("terakhir disimpan %s") % jam if jam != "" else ""), 17, Color(0.85, 0.85, 0.85)))
	if akun.bonus_menunggu():
		_isi.add_child(_label("Bonus Rp100.000 masuk begitu kamu membuka permainan.", 18, GH.KUNING))
	var simpan: = _tombol("Simpan sekarang", &"TombolHijau", 24, 66)
	simpan.pressed.connect(_simpan_sekarang.bind(simpan))
	_isi.add_child(simpan)
	var ambil: = _tombol("Ambil dari cloud", &"TombolKayu", 17, 48)
	ambil.pressed.connect(_ambil_cloud.bind(ambil))
	var keluar: = _tombol("Keluar", &"TombolKayu", 17, 48)
	keluar.pressed.connect(_keluar)
	var hapus: = _tombol("Hapus akun", &"TombolKayu", 17, 48)
	hapus.pressed.connect(_hapus.bind(hapus))
	_baris_kecil([ambil, keluar, hapus])

	_isi.add_child(_tombol_kode_kecil())


func _bangun_pilih() -> void :
	var akun: Node = GameState.akun
	_isi.add_child(_label("Pilih simpanan yang mau dipakai", 23, GH.KUNING))
	var teks: = "HP lain sudah menyimpan versi yang lebih baru ke akun ini." if akun.bentrok and not _pilih_cloud\
	else "Akun ini sudah punya simpanan di cloud (mungkin dari HP lain)."
	if akun.mundur and not akun.bentrok and not _pilih_cloud:
		teks = "Warung di HP ini lebih kecil dari warung yang tersimpan di cloud. Simpanan cloud TIDAK ditimpa sampai kamu memilih."
	_isi.add_child(_label(teks, 18, Color.WHITE))


	var wadah_kotak: = CenterContainer.new()
	wadah_kotak.add_child(_label(GameState.tk("Memeriksa simpanan cloud..."), 18, GH.HIJAU_UANG))
	_isi.add_child(wadah_kotak)
	_isi_kotak_pilih(wadah_kotak)
	var cloud: = _tombol("Pakai simpanan cloud", &"TombolHijau", 22, 60)
	cloud.pressed.connect(_ambil_cloud.bind(cloud))
	_isi.add_child(cloud)
	var hp: = _tombol("Pakai simpanan HP ini", &"TombolKayu", 22, 60)
	hp.pressed.connect(_pakai_hp_ini.bind(hp))
	_isi.add_child(hp)
	_isi.add_child(_label("Yang tidak dipilih tetap dicadangkan di HP ini.", 16, Color(0.8, 0.8, 0.8)))


var _cloud_terbaca: = {}


func _isi_kotak_pilih(wadah: Control) -> void :
	if _cloud_terbaca.is_empty():
		_cloud_terbaca = await GameState.akun.kemajuan_cloud()
	if not is_instance_valid(wadah):
		return
	var cloud: Dictionary = _cloud_terbaca if not _cloud_terbaca.is_empty() else GameState.akun.kemajuan_tersimpan()
	for c in wadah.get_children():
		c.queue_free()
	wadah.add_child(_kotak_dua(cloud, GameState.akun.kemajuan_hp()))




func _kotak_dua(cloud: Dictionary, hp: Dictionary) -> Control:
	var baris: = HBoxContainer.new()
	baris.add_theme_constant_override("separation", 14)
	baris.alignment = BoxContainer.ALIGNMENT_CENTER
	var cloud_jauh: bool = not cloud.is_empty() and GameState.akun._lebih_jauh(cloud, hp)
	var hp_jauh: bool = not hp.is_empty() and not cloud_jauh and GameState.akun._lebih_jauh(hp, cloud)
	baris.add_child(_kotak_warung(_tk_akun("Di akun Google"), cloud, cloud_jauh, GH.HIJAU_UANG))
	baris.add_child(_kotak_warung("Di HP ini", hp, hp_jauh, Color(0.75, 0.85, 1.0)))
	return baris


func _kotak_warung(judul: String, k: Dictionary, lebih_jauh: bool, warna: Color) -> Control:
	var kotak: = PanelContainer.new()
	var gaya: = StyleBoxFlat.new()
	gaya.bg_color = Color(1, 1, 1, 0.07)
	gaya.border_color = Color(warna, 0.9 if lebih_jauh else 0.45)
	gaya.set_border_width_all(3 if lebih_jauh else 2)
	gaya.set_corner_radius_all(14)
	gaya.content_margin_left = 16
	gaya.content_margin_right = 16
	gaya.content_margin_top = 10
	gaya.content_margin_bottom = 12
	kotak.add_theme_stylebox_override("panel", gaya)
	kotak.custom_minimum_size = Vector2(250, 0)
	var isi: = VBoxContainer.new()
	isi.add_theme_constant_override("separation", 2)
	kotak.add_child(isi)
	var kecil: = func(teks: String, ukuran: int, w: Color) -> Label:
		var l: = Label.new()
		l.text = teks
		l.add_theme_font_size_override("font_size", ukuran)
		l.add_theme_color_override("font_color", w)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size.x = 218
		isi.add_child(l)
		return l
	kecil.call(judul, 16, warna)
	if k.is_empty():
		kecil.call("Belum ada warung", 20, Color(0.8, 0.8, 0.8))
		return kotak
	var nama: Label = kecil.call(GameState.tk("Warung %s") % String(k["nama"]), 23, Color.WHITE)
	nama.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	var lv: = GameState.tk("Tamat") if int(k["level"]) > 10 else GameState.tk("Level %d") % int(k["level"])
	kecil.call(lv, 19, GH.KUNING)
	kecil.call(GameState.tk("Hari ke-%d") % int(k["hari"]), 18, Color(0.9, 0.9, 0.9))
	if k.has("uang"):
		kecil.call(GameState.format_rupiah(int(k["uang"])), 18, GH.HIJAU_UANG)

	if int(k.get("qris", 0)) > 0:
		kecil.call(GameState.tk("QRIS %s") % GameState.format_rupiah(int(k["qris"])), 16, GH.HIJAU_UANG)
	var jam: = _teks_disimpan(String(k.get("disimpan", "")))
	if jam != "":
		kecil.call(GameState.tk("Disimpan %s") % jam, 15, Color(0.8, 0.8, 0.8))
	if lebih_jauh:
		kecil.call("★ Lebih jauh", 15, warna)
	return kotak



func _teks_disimpan(s: String) -> String:
	var m: = RegEx.create_from_string("^\\d{4}-(\\d{2})-(\\d{2})[ T](\\d{2}):(\\d{2})").search(s)
	if m == null:
		return ""
	return "%s/%s %s.%s" % [m.get_string(2), m.get_string(1), m.get_string(3), m.get_string(4)]


func _teks_kemajuan(k: Dictionary) -> String:
	if k.is_empty():
		return GameState.tk("belum ada warung")
	var lv: = GameState.tk("tamat") if int(k["level"]) > 10 else GameState.tk("Level %d") % int(k["level"])
	var teks: String = GameState.tk("Warung %s, %s, hari %d") % [String(k["nama"]), lv, int(k["hari"])]
	if k.has("uang"):
		teks += ", " + GameState.format_rupiah(int(k["uang"]))
	if int(k.get("qris", 0)) > 0:
		teks += " + " + GameState.tk("QRIS %s") % GameState.format_rupiah(int(k["qris"]))
	return teks


func _isi_baris_cloud(baris: Label) -> void :
	if _cloud_terbaca.is_empty():
		_cloud_terbaca = await GameState.akun.kemajuan_cloud()
	if not is_instance_valid(baris):
		return
	if _cloud_terbaca.is_empty():
		var k: Dictionary = GameState.akun.kemajuan_tersimpan()
		baris.text = GameState.tk("Cloud: %s") % (_teks_kemajuan(k) if not k.is_empty() else GameState.tk("belum bisa diperiksa"))
	else:
		baris.text = GameState.tk("Cloud: %s") % _teks_kemajuan(_cloud_terbaca)




func _tombol_kode_kecil() -> Button:
	var b: = _tombol_pindah_hp()
	b.text = "Pindah HP / kode pemulihan (PH- / W-)"
	b.add_theme_font_size_override("font_size", 15)
	b.custom_minimum_size.y = 40
	return b


func _tombol_pindah_hp() -> Button:
	var b: = _tombol("Pindah HP pakai kode", &"TombolKayu", 17, 48)
	b.pressed.connect( func():
		GameState.klik()
		var jendela: CanvasLayer = load("res://scripts/pindah_hp.gd").new()
		jendela.dalam_game = dalam_game
		get_tree().root.add_child(jendela))
	return b


func _info(teks: String, baik: = false) -> void :
	if not is_instance_valid(_pesan):
		return
	_pesan.text = teks
	_pesan.add_theme_color_override("font_color", GH.HIJAU_UANG if baik else Color(1, 0.7, 0.45))




func _tanya(judul: String, teks: String, teks_ya: String, tambahan: Control = null, teks_tidak: = "Batal") -> bool:
	if is_instance_valid(_tanya_lapisan):
		return false
	var lapisan: = ColorRect.new()
	lapisan.color = Color(0, 0, 0, 0.6)
	lapisan.set_anchors_preset(Control.PRESET_FULL_RECT)
	lapisan.mouse_filter = Control.MOUSE_FILTER_STOP
	lapisan.theme = GH.tema_jendela_emas()
	add_child(lapisan)
	_tanya_lapisan = lapisan
	var tengah: = CenterContainer.new()
	tengah.set_anchors_preset(Control.PRESET_FULL_RECT)
	lapisan.add_child(tengah)
	var kartu: PanelContainer = GH.panel_emas(Vector4(28, 22, 28, 22))
	kartu.custom_minimum_size = Vector2(540, 0)
	tengah.add_child(kartu)
	var isi: = VBoxContainer.new()
	isi.add_theme_constant_override("separation", 14)
	kartu.add_child(isi)
	var j: = _label(judul, 26, GH.KUNING)
	j.custom_minimum_size.x = 480
	isi.add_child(j)
	var t: = _label(teks, 19, Color.WHITE)
	t.custom_minimum_size.x = 480
	isi.add_child(t)
	if tambahan != null:
		isi.add_child(tambahan)
	var baris: = HBoxContainer.new()
	baris.add_theme_constant_override("separation", 12)
	isi.add_child(baris)
	var batal: = _tombol(teks_tidak, &"TombolKayu", 21, 56)
	batal.pressed.connect( func(): _jawab.emit(false))
	baris.add_child(batal)
	var ya: = _tombol(teks_ya, &"TombolHijau", 21, 56)
	ya.pressed.connect( func(): _jawab.emit(true))
	baris.add_child(ya)
	var hasil: bool = await _jawab
	GameState.klik()
	lapisan.queue_free()
	_tanya_lapisan = null
	return hasil




func _masuk(tombol: Button, lewat: = "google") -> void :
	GameState.klik()
	if _sibuk:
		return
	_sibuk = true
	if tombol != null:
		tombol.disabled = true
	_info("Membuka login Apple..." if lewat == "apple" else "Membuka pilihan akun Google...", true)
	var h: Dictionary = await GameState.akun.masuk(lewat)
	if not is_instance_valid(_isi):
		return
	if not bool(h.get("ok", false)):
		_sibuk = false
		if is_instance_valid(tombol):
			tombol.disabled = false
		match String(h.get("alasan", "")):
			"BATAL":
				_info("Dibatalkan.")
			"TIDAK_ADA_AKUN":
				_info("Tidak ada akun Google di HP ini. Tambahkan akun Google di pengaturan HP, lalu coba lagi.")
			"server":
				_info("Belum bisa masuk. Cek internet lalu coba lagi.")

			"waktu":
				_info("Jendela akun Google tidak muncul. Tutup game sebentar, buka lagi, lalu coba lagi.")
			"GAGAL", "TOKEN_RUSAK":
				_info("Belum bisa masuk dengan Google. Pastikan Google Play di HP sudah versi terbaru, lalu coba lagi.")
			"sibuk":
				_info("Masih membuka akun Google. Tunggu sebentar, ya.")
			_:
				_info("Belum bisa masuk. Coba lagi nanti.")
		GameState.bunyi("salah")
		return
	_info("Memeriksa simpanan cloud...", true)
	var r: Dictionary = await GameState.akun.selesaikan_tautan()
	_sibuk = false
	if not is_instance_valid(_isi):
		return
	match String(r.get("kasus", "gagal")):
		"baru":
			GameState.bunyi("hadiah")
			_bangun()
			_info("Akun tertaut dan simpanan sudah aman di cloud.", true)

			await _beri_tahu("Berhasil ditautkan!", _tk_akun("Akun Google %s sudah tertaut. Warungmu sekarang tersimpan otomatis di cloud.") % GameState.akun.email())
			return
		"ada_cloud":

			GameState.bunyi("hadiah")
			await _beri_tahu("Berhasil ditautkan!", _tk_akun("Akun Google %s sudah tertaut.") % GameState.akun.email())
			if not is_instance_valid(_isi):
				return
			_info("Memeriksa simpanan cloud...", true)
			_cloud_terbaca = await GameState.akun.kemajuan_cloud()
			if not is_instance_valid(_isi):
				return
			var cloud: Dictionary = _cloud_terbaca if not _cloud_terbaca.is_empty() else GameState.akun.kemajuan_tersimpan()
			var hp: Dictionary = GameState.akun.kemajuan_hp()
			_info("")

			var mau_cloud: bool = not dalam_game and await _tanya("Pakai simpanan terakhir?", _tk_akun("Akun Google ini sudah punya simpanan warung. Mau dipakai di HP ini?"), 
				"Ya, pakai", _kotak_dua(cloud, hp), "Nanti saja")

			if mau_cloud and _hp_lebih_jauh(cloud, hp):
				mau_cloud = await _tanya("Warung di HP ini lebih jauh", _teks_hp_lebih_jauh(cloud, hp), "Tetap pakai cloud", null, "Jangan")
			if mau_cloud:
				if GameState.jumlah_slot_terisi() == 0:
					var alasan: String = await GameState.akun.pakai_cloud()
					if alasan == "":
						_selesai_muat_ulang()
						return
					_pilih_cloud = true
					_bangun()
					_info(alasan)
					return

				_pilih_cloud = true
				_bangun()
				_ambil_cloud_langsung()
				return
			_pilih_cloud = true
			_bangun()
			if dalam_game:
				_info("Untuk memakai simpanan cloud, keluar ke menu utama dulu lalu buka Pengaturan.")
		_:
			_bangun()
			_info("Akun tertaut, tapi simpanan belum bisa diperiksa. Kamu bisa coba lagi dari sini nanti.")



func _hp_lebih_jauh(cloud: Dictionary, hp: Dictionary) -> bool:
	return not cloud.is_empty() and not hp.is_empty() and GameState.akun._lebih_jauh(hp, cloud)


func _teks_hp_lebih_jauh(cloud: Dictionary, hp: Dictionary) -> String:
	return GameState.tk("Warung di HP ini (%s) lebih jauh dari simpanan cloud (%s). Kalau lanjut, kamu bermain dari simpanan cloud yang lebih lama. Salinan HP ini tetap dicadangkan.")\
	%[_teks_kemajuan(hp), _teks_kemajuan(cloud)]



func _tk_akun(teks: String) -> String:
	var t: = GameState.tk(teks)
	return t.replace("Google", "Apple") if GameState.akun.penyedia() == "apple" else t


func _simpan_sekarang(tombol: Button) -> void :
	GameState.klik()
	if _sibuk:
		return
	_sibuk = true
	tombol.disabled = true
	_info("Mengirim simpanan...", true)
	var h: Dictionary = await GameState.akun.kirim()
	_sibuk = false
	if not is_instance_valid(tombol):
		return
	tombol.disabled = false
	if bool(h.get("ok", false)):
		_bangun()
		_info("Sudah tersimpan di cloud.", true)
		GameState.bunyi("koin")
		return
	match String(h.get("alasan", "")):
		"bentrok":
			_bangun()
		"sering":
			_info("Terlalu sering. Coba lagi sebentar lagi.")
		"kosong":
			_info("Belum ada simpanan di HP ini untuk dikirim.")
		_:
			_info("Belum bisa mengirim. Cek internet lalu coba lagi.")


func _pakai_hp_ini(tombol: Button) -> void :
	GameState.klik()
	if _sibuk:
		return
	var akun: Node = GameState.akun
	var awas: = "Simpanan di cloud akan diganti simpanan HP ini."
	var cloud: Dictionary = _cloud_terbaca if not _cloud_terbaca.is_empty() else akun.kemajuan_tersimpan()
	if not cloud.is_empty() and akun._mundur_dari(cloud, akun.kemajuan_hp()):
		awas = GameState.tk("Hati-hati: warung di cloud (%s) LEBIH BESAR dari warung di HP ini (%s). Kalau lanjut, warung di cloud diganti warung HP ini.")\
		%[_teks_kemajuan(cloud), _teks_kemajuan(akun.kemajuan_hp())]
	if not await _tanya("Pakai simpanan HP ini?", awas, "Ya, pakai HP ini"):
		return
	_sibuk = true
	tombol.disabled = true
	_info("Mengirim simpanan HP ini...", true)
	var h: Dictionary = await GameState.akun.kirim(true)
	_sibuk = false
	if not is_instance_valid(_isi):
		return
	if bool(h.get("ok", false)):
		_pilih_cloud = false
		GameState.akun.bentrok = false
		_bangun()
		_info("Simpanan HP ini sudah menjadi simpanan cloud.", true)
		GameState.bunyi("koin")
	else:
		tombol.disabled = false
		_info("Belum bisa mengirim. Cek internet lalu coba lagi.")


func _ambil_cloud(tombol: Button) -> void :
	GameState.klik()
	if _sibuk:
		return
	if dalam_game:
		_info("Ambil simpanan dari cloud hanya bisa dari menu utama. Keluar ke menu utama dulu, lalu buka Pengaturan.")
		return
	if GameState.jumlah_slot_terisi() > 0:
		var cloud: Dictionary = _cloud_terbaca if not _cloud_terbaca.is_empty() else GameState.akun.kemajuan_tersimpan()
		var hp: Dictionary = GameState.akun.kemajuan_hp()
		var teks: = _teks_hp_lebih_jauh(cloud, hp) if _hp_lebih_jauh(cloud, hp)\
		else "Simpanan di HP ini akan diganti simpanan dari cloud. Salinan HP ini tetap dicadangkan."
		if not await _tanya("Ambil simpanan dari cloud?", teks, "Ya, ambil"):
			return
	_sibuk = true
	tombol.disabled = true
	_info("Mengambil simpanan cloud...", true)
	var alasan: String = await GameState.akun.pakai_cloud()
	_sibuk = false
	if not is_instance_valid(tombol):
		return
	if alasan != "":
		tombol.disabled = false
		_info(alasan)
		GameState.bunyi("salah")
		return
	_selesai_muat_ulang()




func _ambil_cloud_langsung() -> void :
	_sibuk = true
	_info("Mengambil simpanan cloud...", true)
	var alasan: String = await GameState.akun.pakai_cloud()
	_sibuk = false
	if alasan == "":
		_selesai_muat_ulang()
		return
	if is_instance_valid(_isi):
		_info(alasan)
		GameState.bunyi("salah")



func _beri_tahu(judul: String, teks: String) -> void :
	if is_instance_valid(_tanya_lapisan):
		return
	var lapisan: = ColorRect.new()
	lapisan.color = Color(0, 0, 0, 0.6)
	lapisan.set_anchors_preset(Control.PRESET_FULL_RECT)
	lapisan.mouse_filter = Control.MOUSE_FILTER_STOP
	lapisan.theme = GH.tema_jendela_emas()
	add_child(lapisan)
	_tanya_lapisan = lapisan
	var tengah: = CenterContainer.new()
	tengah.set_anchors_preset(Control.PRESET_FULL_RECT)
	lapisan.add_child(tengah)
	var kartu: PanelContainer = GH.panel_emas(Vector4(28, 22, 28, 22))
	kartu.custom_minimum_size = Vector2(540, 0)
	tengah.add_child(kartu)
	var isi: = VBoxContainer.new()
	isi.add_theme_constant_override("separation", 14)
	kartu.add_child(isi)
	var j: = _label("✓ " + GameState.tk(judul), 28, GH.HIJAU_UANG)
	j.custom_minimum_size.x = 480
	isi.add_child(j)
	var t: = _label(teks, 19, Color.WHITE)
	t.custom_minimum_size.x = 480
	isi.add_child(t)
	var ok: = _tombol("OK", &"TombolHijau", 22, 56)
	ok.pressed.connect( func(): _jawab.emit(true))
	isi.add_child(ok)
	await _jawab
	GameState.klik()
	lapisan.queue_free()
	_tanya_lapisan = null


func _selesai_muat_ulang() -> void :
	GameState.bunyi("hadiah")
	queue_free()
	GameState._tampilkan_info_hadiah("Simpanan cloud terpasang", "Simpanan dari akunmu sudah dipasang di HP ini. Silakan pilih Lanjutkan di menu utama.")
	if GameState.get_tree().current_scene != null:
		GameState.get_tree().reload_current_scene()


func _keluar() -> void :
	GameState.klik()
	if _sibuk:
		return
	if not await _tanya("Keluar dari akun?", "Simpanan di HP ini tetap ada. Simpanan tidak dikirim ke cloud lagi sampai kamu masuk kembali.", "Ya, keluar"):
		return
	_sibuk = true
	_info("Menyimpan lalu keluar...", true)
	await GameState.akun.kirim()
	GameState.akun.keluar()
	_sibuk = false
	_pilih_cloud = false
	if is_instance_valid(_isi):
		_bangun()
		_info("Sudah keluar. Simpanan di HP ini tetap ada.", true)


func _hapus(tombol: Button) -> void :
	GameState.klik()
	if _sibuk:
		return
	if not await _tanya("Hapus akun?", "Akun dan simpanan cloud akan DIHAPUS PERMANEN dari server. Simpanan di HP ini tetap ada.", "Ya, hapus"):
		return
	_sibuk = true
	tombol.disabled = true
	_info("Menghapus akun...", true)
	var ok: bool = await GameState.akun.hapus_akun()
	_sibuk = false
	if not is_instance_valid(_isi):
		return
	if ok:
		_pilih_cloud = false
		_bangun()
		_info("Akun dan simpanan cloud sudah dihapus.", true)
	else:
		tombol.disabled = false
		_info("Belum bisa menghapus. Cek internet lalu coba lagi.")
		GameState.bunyi("salah")


func _tutup() -> void :
	GameState.klik()
	if is_instance_valid(_tanya_lapisan):
		_jawab.emit(false)
	queue_free()
