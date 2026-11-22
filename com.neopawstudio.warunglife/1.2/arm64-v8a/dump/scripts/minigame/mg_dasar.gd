extends Control








signal selesai(hasil: float)

const GH: = preload("res://scripts/gaya_hud.gd")
const UKURAN: = Vector2(1040, 430)
const HITUNG_MUNDUR: = 3
const TERIMA_KASIH_TIP: = ["Hehe, lain kali ya, Pak.", "Makasih, Pak. Ini sedikit buat Bapak.", "Wah, cekatan! Ambil kembaliannya, Pak.", "Mantap, Pak Misran! Ini buat jajan."]
const TERIMA_KASIH: = ["Hatur nuhun pisan!", "Wah, cepat sekali kerjanya!", "Terima kasih banyak, ya!", "Mantap, beres semua!"]

var judul: = "Mini-game"
var petunjuk: = ""
var durasi: = 20.0
var target: = 10.0
var skor: = 0.0
var varian: = ""
var id_kerja: = ""


var npc: = ""
var latar: = ""
var tip_maks: = 0
var kanvas: Control
var main: = false
var _dijeda: = false
var _bonus_ganda: = false
var _kabar_ganda: = false
var _lapis_jeda: Control = null
var sisa: = 0.0
var _label_skor: Label
var _bar: ProgressBar
var _label_tengah: Label
var _kilat: = []
var _partikel: = []


var contoh: = {"jenis": "ketuk", "dari": UKURAN / 2.0, "ke": UKURAN / 2.0}
var _beruntun: = 0
var _guncang: = 0.0
var _detik_terakhir: = -1
var _sudah_mulai: = false
var tangkapan: Array[String] = []


func atur(v: String, id: = "") -> void :
	varian = v
	id_kerja = id


func _ready() -> void :
	process_mode = Node.PROCESS_MODE_ALWAYS
	theme = GH.tema_jendela()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 160


	add_to_group("lapisan_atas")
	_siapkan()
	_pasang_latar()
	var tengah: = CenterContainer.new()
	tengah.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(tengah)
	var kolom: = VBoxContainer.new()
	kolom.add_theme_constant_override("separation", 10)
	tengah.add_child(kolom)
	kolom.add_child(_kartu_kepala())
	var bingkai: = Panel.new()
	var gaya: = StyleBoxFlat.new()
	gaya.bg_color = Color(0.1, 0.09, 0.08)
	gaya.border_color = GH.KUNING
	gaya.set_border_width_all(4)
	gaya.set_corner_radius_all(18)
	gaya.shadow_color = Color(0, 0, 0, 0.6)
	gaya.shadow_size = 22
	gaya.shadow_offset = Vector2(0, 8)
	bingkai.add_theme_stylebox_override("panel", gaya)
	bingkai.custom_minimum_size = UKURAN + Vector2(16, 16)
	kolom.add_child(bingkai)
	var potong: = Control.new()
	potong.position = Vector2(8, 8)
	potong.size = UKURAN
	potong.clip_contents = true
	bingkai.add_child(potong)
	kanvas = Control.new()
	kanvas.size = UKURAN
	kanvas.mouse_filter = Control.MOUSE_FILTER_STOP
	kanvas.draw.connect(_gambar_semua)
	kanvas.gui_input.connect( func(e: InputEvent):
		if main and not _dijeda:
			_masukan(e))
	potong.add_child(kanvas)
	_label_tengah = GH.label("", 120, GH.KUNING, true, 8)
	_label_tengah.size = UKURAN
	_label_tengah.position = Vector2(8, 8)
	_label_tengah.pivot_offset = UKURAN / 2.0
	_label_tengah.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label_tengah.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label_tengah.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bingkai.add_child(_label_tengah)
	_perbarui_skor()
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.25)
	_mulai.call_deferred()



func _pasang_latar() -> void :
	var gelap: = ColorRect.new()
	gelap.color = Color(0.03, 0.03, 0.03)
	gelap.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(gelap)
	var jalur: = _foto_kerja()
	if jalur != "":
		var foto: = TextureRect.new()
		foto.texture = load(jalur)
		foto.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		foto.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		foto.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		foto.modulate = Color(0.42, 0.4, 0.38)
		add_child(foto)
	var gradasi: = TextureRect.new()
	var g: = GradientTexture2D.new()
	g.fill_from = Vector2(0.5, 0.0)
	g.fill_to = Vector2(0.5, 1.0)
	var warna: = Gradient.new()
	warna.set_color(0, Color(0, 0, 0, 0.75))
	warna.set_color(1, Color(0, 0, 0, 0.75))
	warna.add_point(0.5, Color(0, 0, 0, 0.25))
	g.gradient = warna
	gradasi.texture = g
	gradasi.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	gradasi.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	add_child(gradasi)


func _foto_kerja() -> String:
	if latar != "":
		return latar if ResourceLoader.exists(latar) else ""
	var jalur: = String(GameState.KERJA_SAMPINGAN.get(id_kerja, {}).get("foto", ""))
	if jalur == "":
		return ""
	var ibu: = jalur.get_basename() + "_ibu." + jalur.get_extension()
	if GameState.adalah_ibu() and ResourceLoader.exists(ibu):
		return ibu

	return "" if GameState.adalah_ibu() or not ResourceLoader.exists(jalur) else jalur


func potret_warga() -> Texture2D:
	var siapa: = npc if npc != "" else String(GameState.KERJA_SAMPINGAN.get(id_kerja, {}).get("npc", ""))
	var jalur: = "res://assets/potret/warga_%s.png" % siapa
	return load(jalur) if siapa != "" and ResourceLoader.exists(jalur) else null


func _kartu_kepala() -> PanelContainer:
	var kartu: = GH.panel_kaca(0.72, 16, Vector4(16, 12, 20, 12))
	kartu.custom_minimum_size.x = UKURAN.x + 16
	var baris: = HBoxContainer.new()
	baris.add_theme_constant_override("separation", 16)
	kartu.add_child(baris)
	var p: = potret_warga()
	if p != null:
		baris.add_child(_bulat(p, 92))
	var tengah: = VBoxContainer.new()
	tengah.add_theme_constant_override("separation", 4)
	tengah.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	baris.add_child(tengah)
	tengah.add_child(GH.label(judul.to_upper(), 36, GH.KUNING, true))
	var pt: = GH.label(petunjuk, 19, Color.WHITE)
	pt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tengah.add_child(pt)
	var waktu: = HBoxContainer.new()
	waktu.add_theme_constant_override("separation", 8)
	tengah.add_child(waktu)
	waktu.add_child(_ikon("res://assets/ikon/jam.svg", 26))
	_bar = ProgressBar.new()
	_bar.show_percentage = false
	_bar.custom_minimum_size = Vector2(0, 16)
	_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_bar.max_value = durasi
	_bar.value = durasi
	var isi: = StyleBoxFlat.new()
	isi.bg_color = GH.KUNING
	isi.set_corner_radius_all(8)
	var dasar: = StyleBoxFlat.new()
	dasar.bg_color = Color(1, 1, 1, 0.15)
	dasar.set_corner_radius_all(8)
	_bar.add_theme_stylebox_override("fill", isi)
	_bar.add_theme_stylebox_override("background", dasar)
	waktu.add_child(_bar)
	var skor_kotak: = GH.panel_kaca(0.5, 12, Vector4(14, 8, 16, 8))
	skor_kotak.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	baris.add_child(skor_kotak)
	var sk: = HBoxContainer.new()
	sk.add_theme_constant_override("separation", 8)
	skor_kotak.add_child(sk)
	sk.add_child(_ikon("res://assets/ikon/koin.svg", 40))
	_label_skor = GH.label("", 40, GH.KUNING, true)
	_label_skor.custom_minimum_size.x = 120
	sk.add_child(_label_skor)
	var jeda: = Button.new()
	jeda.text = "Jeda"
	jeda.theme_type_variation = &"TombolKayu"
	jeda.custom_minimum_size = Vector2(96, 64)
	jeda.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	jeda.add_theme_font_size_override("font_size", 22)
	jeda.pressed.connect(_atur_jeda.bind(true))
	baris.add_child(jeda)
	return kartu



func _atur_jeda(ya: bool) -> void :
	if ya and ( not main or _dijeda):
		return
	GameState.klik()
	_dijeda = ya
	if not ya:
		if is_instance_valid(_lapis_jeda):
			_lapis_jeda.queue_free()
		return
	var lapis: = ColorRect.new()
	lapis.color = Color(0.03, 0.03, 0.03, 0.97)
	lapis.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	lapis.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(lapis)
	_lapis_jeda = lapis
	var tengah: = CenterContainer.new()
	tengah.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	lapis.add_child(tengah)
	var kolom: = VBoxContainer.new()
	kolom.add_theme_constant_override("separation", 22)
	tengah.add_child(kolom)
	var teks: = GH.label("Dijeda", 56, GH.KUNING, true)
	teks.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	kolom.add_child(teks)
	var lanjut: = Button.new()
	lanjut.text = "Lanjutkan"
	lanjut.theme_type_variation = &"TombolHijau"
	lanjut.custom_minimum_size = Vector2(280, 76)
	lanjut.add_theme_font_size_override("font_size", 28)
	lanjut.pressed.connect(_atur_jeda.bind(false))
	kolom.add_child(lanjut)







func _notification(what: int) -> void :
	if what == NOTIFICATION_APPLICATION_PAUSED and is_inside_tree():
		_atur_jeda.call_deferred(true)


func _ikon(jalur: String, ukuran: float) -> TextureRect:
	var t: = TextureRect.new()
	t.texture = load(jalur)
	t.custom_minimum_size = Vector2(ukuran, ukuran)
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return t



func _bulat(tekstur: Texture2D, ukuran: float) -> Control:
	var wadah: = Panel.new()
	wadah.custom_minimum_size = Vector2(ukuran, ukuran)
	wadah.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var g: = StyleBoxFlat.new()
	g.bg_color = GH.KUNING
	g.set_corner_radius_all(int(ukuran / 2.0))
	wadah.add_theme_stylebox_override("panel", g)
	var t: = TextureRect.new()
	t.texture = tekstur
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	t.position = Vector2(4, 4)
	t.size = Vector2(ukuran - 8, ukuran - 8)
	t.material = GH.bahan_bulat()
	wadah.add_child(t)
	return wadah


func _mulai() -> void :
	for n in range(HITUNG_MUNDUR, 0, -1):
		_pantul(str(n))
		GameState.klik()
		await GameState.get_tree().create_timer(0.7, true, false, true).timeout
	_pantul("MULAI!")
	GameState.bunyi("koin")
	sisa = durasi
	main = true
	_sudah_mulai = true
	await GameState.get_tree().create_timer(0.55, true, false, true).timeout
	_label_tengah.text = ""


func _pantul(t: String) -> void :
	_label_tengah.text = t
	_label_tengah.scale = Vector2.ONE * 1.8
	_label_tengah.modulate.a = 0.0
	var tw: = create_tween().set_parallel()
	tw.tween_property(_label_tengah, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(_label_tengah, "modulate:a", 1.0, 0.15)


func _process(delta: float) -> void :
	for k in _kilat:
		k[3] += delta
	_kilat = _kilat.filter( func(k): return k[3] < 0.8)
	for p in _partikel:
		p[0] += p[1] * delta
		p[1].y += 900.0 * delta
		p[3] += delta
	_partikel = _partikel.filter( func(p): return p[3] < 0.7)
	_guncang = maxf(_guncang - delta * 2.5, 0.0)
	if main and not _dijeda:
		sisa -= delta
		_bar.value = maxf(sisa, 0.0)
		if sisa < 5.0:
			(_bar.get_theme_stylebox("fill") as StyleBoxFlat).bg_color = GH.MERAH if fmod(sisa, 0.5) < 0.25 else GH.KUNING
			if int(ceil(sisa)) != _detik_terakhir:
				_detik_terakhir = int(ceil(sisa))
				GameState.klik()
		_main(delta)
		_cek_skor_ganda()
		if main and sisa <= 0.0:
			main = false
			_akhiri()
	kanvas.queue_redraw()



func _boleh_bonus_ganda() -> bool:
	return target > 0.0 and not GameState.mode_latihan


func _saat_bonus_ganda() -> void :
	pass


func _cek_skor_ganda() -> void :
	if not _boleh_bonus_ganda():
		return
	if not _kabar_ganda and skor >= target:
		_kabar_ganda = true
		kilat(UKURAN / 2.0 + Vector2(0, -90), "Kejar 2x lipat, ada bonus!", GH.KUNING)



	if skor >= target * 2.0 and not _bonus_ganda:
		_bonus_ganda = true
		_saat_bonus_ganda()
		kilat(UKURAN / 2.0 + Vector2(0, -90), "Bonus %s! Terus kejar skor" % GameState.format_rupiah(GameState.BONUS_SKOR_GANDA), GH.KUNING)
		percik(UKURAN / 2.0, GH.KUNING, 24, 6.0)
		GameState.bunyi("koin")


func _gambar_semua() -> void :
	kanvas.position = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * 10.0 * _guncang
	_gambar()
	if not cahaya_25d.is_empty():
		_gambar_cahaya_25d()
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



func kilat(p: Vector2, isi: String, warna: Color) -> void :
	_kilat.append([p, isi, warna, 0.0])



func percik(p: Vector2, warna: Color, jumlah: = 10, besar: = 5.0) -> void :
	for i in jumlah:
		_partikel.append([p, Vector2.from_angle(randf_range( - PI, 0)) * randf_range(120, 380), warna, randf() * 0.2, besar * randf_range(0.6, 1.3)])


func tambah_skor(n: float, p: Vector2) -> void :
	skor = maxf(skor + n, 0.0)
	kilat(p, ("+%d" if n > 0 else "%d") % int(n), GH.HIJAU_UANG if n > 0 else Color(1, 0.4, 0.35))
	if n > 0:
		GameState.klik()
		percik(p, GH.KUNING, 8, 5.0)
		_beruntun += 1
		if _beruntun % 5 == 0:
			kilat(UKURAN / 2.0 + Vector2(0, -40), ["Mantap!", "Lancar!", "Jago!", "Cepat sekali!"][(_beruntun / 5 - 1) % 4], GH.KUNING)
	else:

		_beruntun = 0
		_guncang = 1.0
		if OS.has_feature("mobile"):
			Input.vibrate_handheld(60)
	_perbarui_skor()
	_label_skor.pivot_offset = _label_skor.size / 2.0
	_label_skor.scale = Vector2.ONE * (1.3 if n > 0 else 0.8)
	create_tween().tween_property(_label_skor, "scale", Vector2.ONE, 0.2)


func _perbarui_skor() -> void :
	_label_skor.text = "%d/%d" % [int(skor), int(target)]


func hasil() -> float:
	return clampf(skor / target, 0.0, 1.0)


func _akhiri() -> void :
	_kirim_papan_kerja()
	var h: = hasil()
	var bintang: = 3 if h >= 0.9 else (2 if h >= 0.6 else (1 if h >= 0.3 else 0))
	_pantul("SELESAI!")
	GameState.bunyi("koin")
	await GameState.get_tree().create_timer(0.9, true, false, true).timeout
	_label_tengah.text = ""
	var lapis: = ColorRect.new()
	lapis.color = Color(0, 0, 0, 0.0)
	lapis.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(lapis)
	create_tween().tween_property(lapis, "color:a", 0.65, 0.25)
	var tengah: = CenterContainer.new()
	tengah.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	lapis.add_child(tengah)

	var kartu: = GH.panel_emas(Vector4(40, 26, 40, 26))
	lapis.theme = GH.tema_jendela_emas()
	tengah.add_child(kartu)
	var kolom: = VBoxContainer.new()
	kolom.add_theme_constant_override("separation", 14)
	kartu.add_child(kolom)
	var baris_bintang: = HBoxContainer.new()
	baris_bintang.alignment = BoxContainer.ALIGNMENT_CENTER
	baris_bintang.add_theme_constant_override("separation", 12)
	kolom.add_child(baris_bintang)
	var ikon_bintang: = []
	for i in 3:
		var ikon: = _ikon("res://assets/ikon/bintang_kosong.svg", 86)
		ikon.pivot_offset = Vector2(43, 43)
		baris_bintang.add_child(ikon)
		ikon_bintang.append(ikon)
	var kata: String = ["Belum berhasil...", "Lumayan!", "Bagus!", "Hebat sekali!"][bintang]
	var t: = GH.label(("%s  Hasil %d%%" if tip_maks > 0 else "%s  Hasil kerja %d%%") % [kata, int(round(h * 100))], 32, Color.WHITE, true)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	kolom.add_child(t)

	var khusus: = _isi_hasil_khusus(kolom, t)

	var p: = potret_warga() if not khusus else null
	if p != null:
		var ucap: = HBoxContainer.new()
		ucap.alignment = BoxContainer.ALIGNMENT_CENTER
		ucap.add_theme_constant_override("separation", 12)
		kolom.add_child(ucap)
		ucap.add_child(_bulat(p, 64))
		var kalimat: String = TERIMA_KASIH[mini(bintang, 3)] if bintang > 0 else "Nggak apa-apa, makasih sudah bantu."
		if tip_maks > 0:
			kalimat = TERIMA_KASIH_TIP[mini(bintang, 3)]
		ucap.add_child(GH.label("\"%s\"" % kalimat, 22, Color.WHITE))
	var u: = GH.label("Upah %d%% dari penuh" % int(round(GameState.pengali_hasil_kerja(h) * 100)), 24, GH.HIJAU_UANG, true)
	if tip_maks > 0:
		var tip: = GameState.tip_minigame(tip_maks, h)
		u.text = ("Tip %s untuk Pak Misran!" % GameState.format_rupiah(tip)) if tip > 0 else "Kali ini belum dapat tip."
		u.add_theme_font_size_override("font_size", 30)
	u.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if not khusus:
		kolom.add_child(u)
	else:
		u.free()
	if _bonus_ganda:
		var teks_bonus: = GH.label("Bonus skor 2x lipat: +%s" % GameState.format_rupiah(GameState.BONUS_SKOR_GANDA), 28, GH.KUNING, true)
		teks_bonus.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		kolom.add_child(teks_bonus)
	var tombol: = Button.new()
	tombol.text = "Lanjut"
	tombol.theme_type_variation = &"TombolHijau"
	tombol.custom_minimum_size = Vector2(280, 66)
	tombol.add_theme_font_size_override("font_size", 30)
	tombol.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	tombol.pressed.connect( func():
		if _bonus_ganda:
			_bonus_ganda = false
			GameState.beri_bonus_skor_ganda()
		selesai.emit(h)
		queue_free())
	kolom.add_child(tombol)
	kartu.pivot_offset = kartu.size / 2.0
	kartu.scale = Vector2.ONE * 0.85
	create_tween().tween_property(kartu, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	for i in bintang:
		await GameState.get_tree().create_timer(0.3, true, false, true).timeout
		var ikon: TextureRect = ikon_bintang[i]
		ikon.texture = load("res://assets/ikon/bintang.svg")
		ikon.scale = Vector2.ONE * 1.6
		create_tween().tween_property(ikon, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		GameState.klik()





func _kirim_papan_kerja() -> void :
	if id_kerja == "" or tip_maks > 0 or not GameState.KERJA_SAMPINGAN.has(id_kerja) or GameState.mode_latihan or GameState.adalah_ibu():
		return
	if GameState.papan != null:
		GameState.papan.kirim_skor_kerja(id_kerja, int(skor), clampf(durasi - maxf(sisa, 0.0), 0.0, durasi))



func _gambar_contoh() -> void :
	var w: = fmod(Time.get_ticks_msec() / 1000.0, 1.4) / 1.4
	var dari: Vector2 = contoh["dari"]
	var ke: Vector2 = contoh["ke"]
	var p: = dari
	var tekan: = true
	match String(contoh["jenis"]):
		"ketuk":
			tekan = w > 0.5
		"geser", "seret":
			p = dari.lerp(ke, ease(clampf(w * 1.3, 0.0, 1.0), -2.0))
			if contoh["jenis"] == "seret":
				gambar_tekstur(String(contoh.get("benda", "")), p + Vector2(-30, -40), 70)
			kanvas.draw_dashed_line(dari, ke, Color(1, 1, 1, 0.5), 3, 10)
		"gosok":
			p = dari + Vector2(sin(w * TAU * 2.0) * 50.0, 0)
	if tekan:
		kanvas.draw_circle(p, 26, Color(1, 1, 1, 0.25))
	_tangan(p + Vector2(10, 14))
	teks(Vector2(UKURAN.x / 2.0, UKURAN.y - 30), String(contoh.get("teks", "")), 30, Color.WHITE, 900, 8)




const TANGAN_TUNJUK: = preload("res://assets/ikon/tangan_tunjuk.svg")
const UKURAN_TANGAN: = Vector2(84, 105)
const UJUNG_TELUNJUK: = Vector2(52.0 / 120.0, 26.0 / 150.0)

func _tangan(p: Vector2) -> void :
	var ujung: = Vector2(UKURAN_TANGAN.x * UJUNG_TELUNJUK.x, UKURAN_TANGAN.y * UJUNG_TELUNJUK.y)
	var kiri_atas: = p + Vector2(0, -6) - ujung

	kanvas.draw_texture_rect(TANGAN_TUNJUK, Rect2(kiri_atas + Vector2(5, 7), UKURAN_TANGAN), false, Color(0, 0, 0, 0.28))
	kanvas.draw_texture_rect(TANGAN_TUNJUK, Rect2(kiri_atas, UKURAN_TANGAN), false)



func _siapkan() -> void :
	pass



func _isi_hasil_khusus(_kolom: VBoxContainer, _t: Label) -> bool:
	return false






func kartu_hasil_alam(kolom: VBoxContainer, t: Label, ikan: bool, ket_dapat: String, ket_kosong: String) -> void :
	var judul_hasil: = func():
		if tangkapan.is_empty():
			return "Belum dapat ikan kali ini..." if ikan else "Belum dapat buah kali ini..."
		return ("Dapat %d ekor ikan" if ikan else "Dapat %d buah") % tangkapan.size()
	t.text = judul_hasil.call()
	if tangkapan.any( func(id): return GameState.legendaris(String(id))):
		var leg: = GH.label("IKAN LEGENDARIS!", 40, GH.KUNING, true)
		leg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		kolom.add_child(leg)
	var tempat: = VBoxContainer.new()
	kolom.add_child(tempat)
	tempat.add_child(baris_hasil(tangkapan))
	var ket: = GH.label(ket_dapat if not tangkapan.is_empty() else ket_kosong, 22, GH.HIJAU_UANG if not tangkapan.is_empty() else Color.WHITE, true)
	ket.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	kolom.add_child(ket)
	var biasa: = tangkapan.filter( func(id): return not GameState.legendaris(String(id)))

	biasa = GameState.muat_berurutan(biasa, tangkapan)
	if biasa.is_empty():
		return
	var b: = Button.new()
	b.text = "Ambil hasil x2" if GameState.tanpa_iklan else "Tonton iklan: hasil x2"
	GH.gaya_tombol(b, true, 26)
	b.custom_minimum_size = Vector2(360, 60)
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	kolom.add_child(b)
	b.pressed.connect( func():
		b.disabled = true
		if not await GameState.tonton_iklan(get_parent() if get_parent() != null else self):
			b.disabled = false
			return
		for id in biasa:
			tangkapan.append(String(id))
		t.text = judul_hasil.call()
		for anak in tempat.get_children():
			anak.queue_free()
		tempat.add_child(baris_hasil(tangkapan))
		b.text = "Hasil sudah x2!"
		GameState.bunyi("koin"))


func baris_hasil(daftar: Array) -> HBoxContainer:
	var baris: = HBoxContainer.new()
	baris.alignment = BoxContainer.ALIGNMENT_CENTER
	baris.add_theme_constant_override("separation", 24)
	var hitung: = {}
	for id in daftar:
		hitung[id] = int(hitung.get(id, 0)) + 1
	for id in hitung:
		var info: = GameState.info_hasil_alam(String(id))
		var kotak: = VBoxContainer.new()
		kotak.add_theme_constant_override("separation", 2)
		kotak.add_child(_ikon(String(info.get("ikon", "")), 84))
		var l: = GH.label("%s x%d" % [String(info.get("nama", id)), int(hitung[id])], 22, Color.WHITE, true)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		kotak.add_child(l)
		baris.add_child(kotak)
	return baris


func _main(_delta: float) -> void :
	pass


func _masukan(_e: InputEvent) -> void :
	pass


func _gambar() -> void :
	pass






var cahaya_25d: = {}

const JARI_PENDAR: = 770.0
static var _pendar: Texture2D = null



static func _tekstur_pendar() -> Texture2D:
	if _pendar != null:
		return _pendar
	var g: = Gradient.new()
	var titik: = PackedFloat32Array()
	var warna: = PackedColorArray()
	for k in 17:
		var lapis: = 16 - k
		titik.append(0.0 if k == 0 else (140.0 + (k - 1) * 42.0) / JARI_PENDAR)
		warna.append(Color(1, 1, 1, 1.0 - pow(1.0 - 0.018, lapis)))
	titik.append(1.0)
	warna.append(Color(1, 1, 1, 0))
	g.offsets = titik
	g.colors = warna
	var t: = GradientTexture2D.new()
	t.gradient = g
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.5)
	t.fill_to = Vector2(1.0, 0.5)
	t.width = 256
	t.height = 256
	_pendar = t
	return _pendar

func _gambar_cahaya_25d() -> void :
	var dari: Vector2 = cahaya_25d.get("dari", Vector2(UKURAN.x * 0.5, -60))
	var warna: Color = cahaya_25d.get("warna", Color(1, 0.9, 0.65))
	var kuat: = float(cahaya_25d.get("kuat", 1.0))


	var r: = JARI_PENDAR
	kanvas.draw_texture_rect(_tekstur_pendar(), Rect2(dari - Vector2(r, r), Vector2(r, r) * 2.0), false, 
		Color(warna.r, warna.g, warna.b, kuat))

	var g: = Color(0, 0, 0, 0.26 * kuat)
	var b: = Color(0, 0, 0, 0.0)
	kanvas.draw_polygon(PackedVector2Array([Vector2.ZERO, Vector2(110, 0), Vector2(110, UKURAN.y), Vector2(0, UKURAN.y)]), PackedColorArray([g, b, b, g]))
	kanvas.draw_polygon(PackedVector2Array([Vector2(UKURAN.x - 110, 0), Vector2(UKURAN.x, 0), Vector2(UKURAN.x, UKURAN.y), Vector2(UKURAN.x - 110, UKURAN.y)]), PackedColorArray([b, g, g, b]))
	kanvas.draw_polygon(PackedVector2Array([Vector2(0, UKURAN.y - 80), Vector2(UKURAN.x, UKURAN.y - 80), Vector2(UKURAN.x, UKURAN.y), Vector2(0, UKURAN.y)]), PackedColorArray([b, b, g, g]))



func panel_timbul(r: Rect2, warna: Color, radius: = 14.0, tebal: = 6.0) -> void :
	kotak_bulat(Rect2(r.position + Vector2(6, tebal + 6), r.size), Color(0, 0, 0, 0.22), radius)
	kotak_bulat(Rect2(r.position + Vector2(0, tebal), r.size), warna.darkened(0.4), radius)
	kotak_bulat(r, warna, radius)
	kotak_bulat(Rect2(r.position + Vector2(4, 3), Vector2(r.size.x - 8, minf(r.size.y * 0.45, 40.0))), Color(1, 1, 1, 0.08), radius * 0.8)
	kanvas.draw_line(r.position + Vector2(radius, 1.5), r.position + Vector2(r.size.x - radius, 1.5), Color(1, 1, 1, 0.35), 1.5)



func teks(p: Vector2, s: String, ukuran: int, warna: = Color.WHITE, lebar: = 300.0, garis: = 0) -> void :
	var titik: = p - Vector2(lebar / 2.0, - ukuran * 0.35)
	if garis > 0:
		kanvas.draw_string_outline(GH.cetak(), titik, GameState.tk(s), HORIZONTAL_ALIGNMENT_CENTER, lebar, ukuran, garis, Color(0, 0, 0, 0.7))
	kanvas.draw_string(GH.cetak(), titik, GameState.tk(s), HORIZONTAL_ALIGNMENT_CENTER, lebar, ukuran, warna)




var _gaya_kotak: = {}

func _gaya_tersimpan(kunci: String, buat: Callable) -> StyleBoxFlat:
	var g: StyleBoxFlat = _gaya_kotak.get(kunci)
	if g == null:
		if _gaya_kotak.size() > 400:
			_gaya_kotak.clear()
		g = buat.call()
		_gaya_kotak[kunci] = g
	return g


func kotak_bulat(r: Rect2, warna: Color, radius: = 14.0, bayangan: = 0.0) -> void :
	var g: = _gaya_tersimpan("k%s|%d|%d" % [warna.to_html(), int(radius), int(bayangan)], func():
		var b: = StyleBoxFlat.new()
		b.bg_color = warna
		b.set_corner_radius_all(int(radius))
		if bayangan > 0.0:
			b.shadow_color = Color(0, 0, 0, 0.35)
			b.shadow_size = int(bayangan)
			b.shadow_offset = Vector2(0, bayangan * 0.4)
		return b)
	kanvas.draw_style_box(g, r)


func garis_bulat(r: Rect2, warna: Color, radius: = 14.0, tebal: = 3) -> void :
	var g: = _gaya_tersimpan("g%s|%d|%d" % [warna.to_html(), int(radius), tebal], func():
		var b: = StyleBoxFlat.new()
		b.draw_center = false
		b.border_color = warna
		b.set_border_width_all(tebal)
		b.set_corner_radius_all(int(radius))
		return b)
	kanvas.draw_style_box(g, r)



func gradasi(r: Rect2, atas: Color, bawah: Color) -> void :
	kanvas.draw_polygon(PackedVector2Array([r.position, r.position + Vector2(r.size.x, 0), r.end, r.position + Vector2(0, r.size.y)]), 
		PackedColorArray([atas, atas, bawah, bawah]))




func bayangan(p: Vector2, lebar: float, alpha: = 0.3) -> void :
	var titik: = PackedVector2Array()
	for i in 24:
		var a: = i * TAU / 24.0
		titik.append(p + Vector2(cos(a) * lebar / 2.0, sin(a) * lebar * 0.175))
	kanvas.draw_colored_polygon(titik, Color(0, 0, 0, alpha))



var _tekstur: = {}

func tekstur(jalur: String) -> Texture2D:
	if not _tekstur.has(jalur):
		_tekstur[jalur] = load(jalur) if ResourceLoader.exists(jalur) else null
	return _tekstur[jalur]


func gambar_tekstur(jalur: String, tengah: Vector2, ukuran: float, warna: = Color.WHITE) -> void :
	var t: = tekstur(jalur)
	if t != null:
		kanvas.draw_texture_rect(t, Rect2(tengah - Vector2(ukuran, ukuran) / 2.0, Vector2(ukuran, ukuran)), false, warna)


func tekan_awal(e: InputEvent) -> bool:
	return e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT and e.pressed


func lepas(e: InputEvent) -> bool:
	return e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT and not e.pressed
