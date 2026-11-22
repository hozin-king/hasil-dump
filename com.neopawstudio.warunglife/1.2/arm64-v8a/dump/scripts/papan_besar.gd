extends ColorRect







signal ditutup

const FP: = preload("res://scripts/foto_profil.gd")
const GH: = preload("res://scripts/gaya_hud.gd")
const PP: = preload("res://scripts/papan_peringkat.gd")
const TENANG: = preload("res://scripts/tema_tenang.gd")


const NAVY: = Color(0.035, 0.04, 0.07)
const NAVY_KARTU: = Color(0.075, 0.08, 0.115)
const NAVY_BARIS_2: = Color(0.105, 0.11, 0.15)
const BIRU_TERANG: = Color(0.85, 0.6, 0.12)
const EMAS: = Color(1.0, 0.8, 0.18)
const EMAS_GELAP: = Color(0.72, 0.45, 0.05)
static var BAHAN_PLATINUM: ShaderMaterial = _bahan_platinum(260.0)


static func _bahan_platinum(lebar: float) -> ShaderMaterial:
	var m: = ShaderMaterial.new()
	m.shader = preload("res://shader/nama_platinum.gdshader")
	m.set_shader_parameter("lebar", lebar)
	return m
const JINGGA_SAYA: = Color(0.96, 0.55, 0.12)
const WARNA_MEDALI: = [Color(1.0, 0.78, 0.15), Color(0.78, 0.82, 0.88), Color(0.85, 0.5, 0.22)]
const TAB: = [["semua", "Sepanjang Masa"], ["minggu", "Mingguan"], ["bulan", "Bulanan"], ["adu", "Adu Laris"]]

const KOLOM_LEBAR: = {"no": 64.0, "level": 86.0, "bintang": 150.0, "pembeli": 150.0, "omzet": 150.0, "jempol": 116.0, "lapor": 46.0}

const KOLOM_SEMPIT: = {"no": 52.0, "level": 62.0, "bintang": 108.0, "pembeli": 104.0, "omzet": 116.0, "jempol": 92.0, "lapor": 40.0}
const BATAS_SEMPIT: = 1150.0

var _tab: = "semua"
var _isi: VBoxContainer
var _tombol_tab: = {}
var _kartu_saya: PanelContainer
var _pesan: Label
var _gulir: ScrollContainer
var _terbuka_lapor: = ""
var KOLOM: Dictionary = KOLOM_LEBAR
var _sempit: = false
var _wadah_kepala: VBoxContainer


func _ready() -> void :
	theme = TENANG.tema_emas()
	_sempit = get_viewport().get_visible_rect().size.x < BATAS_SEMPIT
	KOLOM = KOLOM_SEMPIT if _sempit else KOLOM_LEBAR
	process_mode = Node.PROCESS_MODE_ALWAYS
	color = Color(0.02, 0.03, 0.06, 0.82)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 120
	add_to_group("lapisan_atas")
	var tepi: = MarginContainer.new()
	tepi.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var aman: = GH.tepi_kiri_kanan(get_viewport())
	tepi.add_theme_constant_override("margin_left", int(maxf(aman.x, 20.0)))
	tepi.add_theme_constant_override("margin_right", int(maxf(aman.y, 20.0)))
	tepi.add_theme_constant_override("margin_top", 14)
	tepi.add_theme_constant_override("margin_bottom", 14)
	add_child(tepi)
	var kartu: = PanelContainer.new()
	kartu.add_theme_stylebox_override("panel", GH.bingkai_emas(Vector4(20, 14, 20, 14)))
	tepi.add_child(kartu)
	var kolom: = VBoxContainer.new()
	kolom.add_theme_constant_override("separation", 10)
	kartu.add_child(kolom)


	var kepala: = HBoxContainer.new()
	kepala.add_theme_constant_override("separation", 12)
	kolom.add_child(kepala)
	kepala.add_child(_ikon_piala(40))
	var judul_kol: = VBoxContainer.new()
	judul_kol.add_theme_constant_override("separation", -2)
	judul_kol.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	kepala.add_child(judul_kol)
	judul_kol.add_child(_teks("PERINGKAT WARUNG", 30, Color.WHITE, 6))
	var sub: = _teks("Diurutkan dari jumlah pembeli yang dilayani. Beri jempol untuk warung yang kamu kagumi!", 15, Color(0.75, 0.84, 0.97), 0, false)
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sub.custom_minimum_size.x = 150 if _sempit else 200
	judul_kol.add_child(sub)
	for t in TAB:
		var b: = Button.new()
		b.text = t[1]
		b.focus_mode = Control.FOCUS_NONE
		b.custom_minimum_size = Vector2(118 if _sempit else 140, 48)
		b.add_theme_font_size_override("font_size", 16 if _sempit else 19)
		var id: String = t[0]
		b.pressed.connect( func():
			GameState.klik()
			_pilih_tab(id))
		kepala.add_child(b)
		_tombol_tab[id] = b
	var tutup: = Button.new()
	tutup.text = "Tutup"
	tutup.theme_type_variation = &"TombolUtama"
	tutup.focus_mode = Control.FOCUS_NONE
	tutup.custom_minimum_size = Vector2(92 if _sempit else 110, 48)
	tutup.add_theme_font_size_override("font_size", 19)
	tutup.pressed.connect( func():
		GameState.klik()
		_tutup())
	kepala.add_child(tutup)


	_kartu_saya = PanelContainer.new()
	kolom.add_child(_kartu_saya)


	_wadah_kepala = VBoxContainer.new()
	kolom.add_child(_wadah_kepala)


	_gulir = load("res://scripts/hp/gulir_sentuh.gd").new()
	_gulir.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_gulir.size_flags_vertical = Control.SIZE_EXPAND_FILL
	kolom.add_child(_gulir)
	_isi = VBoxContainer.new()
	_isi.add_theme_constant_override("separation", 4)
	_isi.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_gulir.add_child(_isi)

	_pesan = _teks("", 14, Color(0.75, 0.84, 0.97), 0, false)
	_pesan.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	kolom.add_child(_pesan)

	GameState.papan.diperbarui.connect(_gambar)
	GameState.papan.segarkan(true)
	_pilih_tab("semua")
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.18)


func _unhandled_input(e: InputEvent) -> void :
	if e.is_action_pressed("ui_cancel"):
		_tutup()
		get_viewport().set_input_as_handled()


func _tutup() -> void :
	if GameState.papan.diperbarui.is_connected(_gambar):
		GameState.papan.diperbarui.disconnect(_gambar)
	ditutup.emit()
	queue_free()


func _pilih_tab(id: String) -> void :
	_tab = id
	_terbuka_lapor = ""
	for k in _tombol_tab:
		(_tombol_tab[k] as Button).theme_type_variation = &"TombolHijau" if k == id else &"TombolKayu"
	for anak in _wadah_kepala.get_children():
		anak.queue_free()
	_wadah_kepala.add_child(_baris_kepala_adu() if id == "adu" else _baris_kepala())
	if id == "adu":
		GameState.papan.ambil_papan_adu()
	_gambar()
	_gulir.scroll_vertical = 0


func _gambar() -> void :
	if not is_inside_tree():
		return
	if _tab == "adu":
		_gambar_adu()
		return
	var p: Dictionary = PP.papan_besar(_tab)
	for anak in _isi.get_children():
		anak.queue_free()
	_isi_kartu_saya(p)
	var baris: Array = p["baris"]
	for i in baris.size():
		_isi.add_child(_baris(i + 1, baris[i], p))
	var papan: Node = GameState.papan
	if papan.sedang_memuat():
		_pesan.text = "Memuat papan terbaru..."
	elif not p["online"]:
		_pesan.text = "Papan online muncul saat HP tersambung ke internet."
	elif not papan.ada_jempol():
		_pesan.text = "Jempol & omzet aktif sebentar lagi (server sedang diperbarui)."
	else:
		_pesan.text = "Jempol: 1 kali per warung per hari, paling banyak 10 jempol sehari. Klik ⚑ untuk melaporkan nama yang tidak pantas."

		var jam: String = papan.jam_diperbarui()
		if jam != "":
			_pesan.text = (tr("Papan diperbarui tiap 30 menit (terakhir pukul %s WIB).") % jam) + " " + tr(_pesan.text)


func _isi_kartu_saya(p: Dictionary) -> void :
	for anak in _kartu_saya.get_children():
		anak.queue_free()
	_kartu_saya.add_theme_stylebox_override("panel", TENANG.kotak(JINGGA_SAYA, 14, Vector4(14, 8, 14, 10), 2, JINGGA_SAYA.darkened(0.4), 5))
	var h: = HBoxContainer.new()
	h.add_theme_constant_override("separation", 18)
	_kartu_saya.add_child(h)
	var peringkat: = int(p["peringkat"])
	h.add_child(_lencana(peringkat, 46))

	var tombol_foto: = Button.new()
	tombol_foto.flat = true
	tombol_foto.focus_mode = Control.FOCUS_NONE
	tombol_foto.custom_minimum_size = Vector2(54, 54)
	tombol_foto.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	tombol_foto.tooltip_text = "Ganti foto profil"
	tombol_foto.add_child(FP.bulat(FP.pilihan(), 54, Color.WHITE, GameState.nama_warung_lengkap()))
	tombol_foto.pressed.connect( func():
		GameState.klik()
		FP.buka_pemilih(self, func(_n: int):
			if is_instance_valid(self):
				_gambar()))
	h.add_child(tombol_foto)
	var nama: = _teks(GameState.nama_warung_lengkap(), 24, Color.WHITE, 6)
	nama.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	nama.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nama.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	nama.clip_text = true
	var kiri: = VBoxContainer.new()
	kiri.add_theme_constant_override("separation", -2)
	kiri.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if GameState.papan.pendukung_saya():
		var baris_nama: = HBoxContainer.new()
		baris_nama.add_theme_constant_override("separation", 8)
		baris_nama.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		baris_nama.add_child(nama)
		baris_nama.add_child(_lencana_pendukung(14, GameState.papan.peduli_saya()))
		kiri.add_child(baris_nama)
	else:
		kiri.add_child(nama)
	var keterangan: = (tr("Peringkat #%s dari %s warung") % [PP.angka(peringkat), PP.angka(maxi(int(p["jumlah_warung"]), peringkat))]) if peringkat > 0 else "Peringkat belum tersedia"
	kiri.add_child(_teks(keterangan, 15, Color(1, 0.97, 0.88), 3, false))
	h.add_child(kiri)
	var saya: Dictionary = {}
	for b in p["baris"]:
		if b["saya"]:
			saya = b
	h.add_child(_angka_kolom("PEMBELI", PP.angka(int(saya.get("pembeli", 0)))))
	h.add_child(_angka_kolom("OMZET", PP.rupiah_ringkas(int(saya.get("omzet", 0)))))
	h.add_child(_angka_kolom("JEMPOL", PP.angka_ringkas(GameState.papan.jempol_saya())))




const KOLOM_ADU: = {"no": 64.0, "level": 80.0, "bar": 360.0, "trofi": 96.0, "mk": 110.0}

func _baris_kepala_adu() -> Control:
	var p: = PanelContainer.new()
	p.add_theme_stylebox_override("panel", TENANG.kotak(Color(0, 0, 0, 0.25), 10, Vector4(10, 4, 10, 4)))
	var h: = HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	p.add_child(h)
	for k in [["no", "#"], ["nama", "WARUNG"], ["level", "LEVEL"], ["bar", "OMZET TERBAIK 1 MENIT"], ["trofi", "TROFI"], ["mk", "MENANG-KALAH"]]:
		var l: = _teks(k[1], 14, Color(1.0, 0.84, 0.45), 0)
		if k[0] == "nama":
			l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		else:
			l.custom_minimum_size.x = KOLOM_ADU[k[0]] * (0.8 if _sempit and k[0] == "bar" else 1.0)
			l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		h.add_child(l)
	return p


func _gambar_adu() -> void :
	for anak in _isi.get_children():
		anak.queue_free()
	var papan: Node = GameState.papan
	var data: Dictionary = papan.papan_adu()
	var daftar: Array = data.get("daftar", [])
	var saya = data.get("saya")
	var kode_saya: String = papan.kode(GameState.id_papan) if GameState.id_papan != "" else ""

	for anak in _kartu_saya.get_children():
		anak.queue_free()
	_kartu_saya.add_theme_stylebox_override("panel", TENANG.kotak(JINGGA_SAYA, 14, Vector4(14, 8, 14, 10), 2, JINGGA_SAYA.darkened(0.4), 5))
	var h: = HBoxContainer.new()
	h.add_theme_constant_override("separation", 18)
	_kartu_saya.add_child(h)
	var peringkat: = int(saya.get("peringkat")) if saya is Dictionary and saya.get("peringkat") != null else 0
	h.add_child(_lencana(peringkat, 46))
	h.add_child(FP.bulat(FP.pilihan(), 54, Color.WHITE, GameState.nama_warung_lengkap()))
	var kiri: = VBoxContainer.new()
	kiri.add_theme_constant_override("separation", -2)
	kiri.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(kiri)
	var nama: = _teks(GameState.nama_warung_lengkap(), 24, Color.WHITE, 6)
	nama.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	nama.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	nama.clip_text = true
	kiri.add_child(nama)
	var ket: = "Belum ikut Adu Laris minggu ini. Main di depan warung sesudah warung tutup!"
	if saya is Dictionary:
		ket = (tr("Peringkat #%s dari %s warung") % [PP.angka(peringkat), PP.angka(maxi(int(data.get("jumlah_warung", 0)), peringkat))]) if peringkat > 0 else tr("Hasilmu sedang diperiksa")
		var urut: = -1
		for i in daftar.size():
			if String(daftar[i][2]) == kode_saya:
				urut = i
		if peringkat > 1 and urut != 0 and not daftar.is_empty():
			var di_atas: Array = daftar[clampi((urut if urut > 0 else mini(peringkat - 1, daftar.size())) - 1, 0, daftar.size() - 1)]
			var selisih: = _aman(di_atas[1]) - _aman(saya.get("omzet")) + 1
			if selisih > 0:
				ket += "  ·  " + tr("Kurang %s lagi untuk menyalip %s") % [GameState.format_rupiah(selisih), String(di_atas[0])]
	var l_ket: = _teks(ket, 15, Color(1, 0.97, 0.88), 3, false)
	l_ket.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	l_ket.clip_text = true
	kiri.add_child(l_ket)
	h.add_child(_angka_kolom("OMZET TERBAIK", GameState.format_rupiah(_aman(saya.get("omzet"))) if saya is Dictionary else "-"))
	h.add_child(_angka_kolom("TROFI", str(_aman(saya.get("trofi"))) if saya is Dictionary else "0"))

	var juara: = float(int(daftar[0][1])) if not daftar.is_empty() else 1.0
	for i in daftar.size():
		_isi.add_child(_baris_adu(i + 1, daftar[i], juara, String(daftar[i][2]) == kode_saya))
	if papan.status_adu == "memuat" and daftar.is_empty():
		_pesan.text = "Memuat papan Adu Laris..."
	elif papan.status_adu == "gagal" and daftar.is_empty():
		_pesan.text = "Papan Adu Laris belum bisa dimuat. Periksa internet, lalu buka lagi."
	elif daftar.is_empty():
		_pesan.text = "Belum ada warung di papan Adu Laris minggu ini. Jadilah yang pertama!"
	else:
		var jam: = String(data.get("jam", ""))
		_pesan.text = "Pembeli Adu Laris acak tiap duel tapi seimbang untuk semua warung. Papan mulai lagi tiap Senin." + ((" " + tr("Papan diperbarui tiap 30 menit (terakhir pukul %s WIB).") % jam) if jam != "" else "")


func _baris_adu(nomor: int, b: Array, juara: float, saya: bool) -> Control:
	var warna: Color = JINGGA_SAYA if saya else (NAVY_KARTU if nomor % 2 == 1 else NAVY_BARIS_2)
	var p: = PanelContainer.new()
	var tepi: Color = WARNA_MEDALI[nomor - 1] if nomor <= 3 and not saya else warna.darkened(0.4)
	p.add_theme_stylebox_override("panel", TENANG.kotak(warna, 12, Vector4(10, 4, 10, 6), 2 if nomor <= 3 else 1, tepi, 3))
	var h: = HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	p.add_child(h)
	var wadah_no: = CenterContainer.new()
	wadah_no.custom_minimum_size.x = KOLOM_ADU["no"]
	wadah_no.add_child(_lencana(nomor, 38))
	h.add_child(wadah_no)
	var nama_baris: = HBoxContainer.new()
	nama_baris.add_theme_constant_override("separation", 6)
	nama_baris.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(nama_baris)
	var foto: = FP.pilihan() if saya else (int(b[7]) if b.size() > 7 and b[7] != null else 0)
	nama_baris.add_child(FP.bulat(foto, 40 if _sempit else 46, WARNA_MEDALI[nomor - 1] if nomor <= 3 else Color(1, 1, 1, 0.85), String(b[0])))
	if nomor == 1:
		nama_baris.add_child(_ikon_mahkota(30))
	var nama: = _teks(String(b[0]), 19 if _sempit else 22, Color.WHITE, 6)
	nama.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	nama.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	nama.clip_text = true
	nama.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nama_baris.add_child(nama)
	var lv: = _teks((tr("Lv %d") % int(b[6])) if b.size() > 6 and b[6] != null and int(b[6]) > 0 else "-", 18, Color.WHITE, 4)
	lv.custom_minimum_size.x = KOLOM_ADU["level"]
	lv.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	h.add_child(lv)

	var wadah_bar: = Control.new()
	wadah_bar.custom_minimum_size = Vector2(KOLOM_ADU["bar"] * (0.8 if _sempit else 1.0), 34)
	wadah_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(wadah_bar)
	var bar: = ProgressBar.new()
	bar.show_percentage = false
	bar.max_value = 1.0
	bar.value = clampf(float(int(b[1])) / maxf(juara, 1.0), 0.03, 1.0)
	bar.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var isi: = StyleBoxFlat.new()
	isi.bg_color = WARNA_MEDALI[nomor - 1] if nomor <= 3 else (Color(0.42, 0.85, 0.42) if not saya else Color(1, 1, 1, 0.9))
	isi.set_corner_radius_all(9)
	var dasar: = StyleBoxFlat.new()
	dasar.bg_color = Color(0, 0, 0, 0.35)
	dasar.set_corner_radius_all(9)
	bar.add_theme_stylebox_override("fill", isi)
	bar.add_theme_stylebox_override("background", dasar)
	wadah_bar.add_child(bar)
	var angka: = _teks(GameState.format_rupiah(int(b[1])), 19, Color.WHITE, 6)
	angka.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	angka.offset_left = 12
	angka.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	wadah_bar.add_child(angka)
	var trofi: = _teks(str(int(b[3])) if b.size() > 3 else "0", 20, EMAS, 5)
	trofi.custom_minimum_size.x = KOLOM_ADU["trofi"]
	trofi.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	h.add_child(trofi)
	var mk: = _teks("%d-%d" % [int(b[4]) if b.size() > 4 else 0, int(b[5]) if b.size() > 5 else 0], 18, Color.WHITE, 4)
	mk.custom_minimum_size.x = KOLOM_ADU["mk"]
	mk.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	h.add_child(mk)
	return p


func _angka_kolom(judul: String, nilai: String) -> VBoxContainer:
	var v: = VBoxContainer.new()
	v.add_theme_constant_override("separation", -2)
	var j: = _teks(judul, 13, Color(1, 0.95, 0.8), 3, false)
	j.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	v.add_child(j)
	var n: = _teks(nilai, 24, Color.WHITE, 6)
	n.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	v.add_child(n)
	return v


func _baris_kepala() -> Control:
	var p: = PanelContainer.new()
	p.add_theme_stylebox_override("panel", TENANG.kotak(Color(0, 0, 0, 0.25), 10, Vector4(10, 4, 10, 4)))
	var h: = HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	p.add_child(h)
	for k in [["no", "#"], ["nama", "WARUNG"], ["level", "LEVEL"], ["bintang", "REPUTASI"], ["pembeli", "PEMBELI"], 
			["omzet", "OMZET"], ["jempol", "JEMPOL"], ["lapor", ""]]:
		var l: = _teks(k[1], 14, Color(1.0, 0.84, 0.45), 0)
		if k[0] == "nama":
			l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		else:
			l.custom_minimum_size.x = KOLOM[k[0]]
			l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER if k[0] in ["no", "level", "bintang", "jempol"] else HORIZONTAL_ALIGNMENT_RIGHT
		h.add_child(l)
	return p


func _baris(nomor: int, b: Dictionary, papan_data: Dictionary) -> Control:
	var saya: bool = b["saya"]
	var warna: Color = JINGGA_SAYA if saya else (NAVY_KARTU if nomor % 2 == 1 else NAVY_BARIS_2)
	var p: = PanelContainer.new()
	var tepi: Color = WARNA_MEDALI[nomor - 1] if nomor <= 3 and not saya else warna.darkened(0.4)
	p.add_theme_stylebox_override("panel", TENANG.kotak(warna, 12, Vector4(10, 4, 10, 6), 2 if nomor <= 3 else 1, tepi, 3))
	var v: = VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	p.add_child(v)
	var h: = HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	v.add_child(h)

	var lencana: = _lencana(nomor, 38)
	var wadah_no: = CenterContainer.new()
	wadah_no.custom_minimum_size.x = KOLOM["no"]
	wadah_no.add_child(lencana)
	h.add_child(wadah_no)

	var nama_baris: = HBoxContainer.new()
	nama_baris.add_theme_constant_override("separation", 6)
	nama_baris.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(nama_baris)

	nama_baris.add_child(FP.bulat(int(b.get("foto", 0)), 40 if _sempit else 46, WARNA_MEDALI[nomor - 1] if nomor <= 3 else Color(1, 1, 1, 0.85), String(b["nama"])))
	if nomor == 1:
		nama_baris.add_child(_ikon_mahkota(30))
	var pendukung: = bool(b.get("pendukung", false)) or bool(b.get("peduli", false))
	var peduli: = bool(b.get("peduli", false))
	var nama: = _teks(String(b["nama"]), 19 if _sempit else 22, PP.WARNA_NAMA_PENDUKUNG if pendukung and not peduli and not saya else Color.WHITE, 6)
	if peduli and not saya:
		nama.material = BAHAN_PLATINUM
	nama.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	nama.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	nama.clip_text = true
	nama.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nama_baris.add_child(nama)
	if pendukung:
		nama_baris.add_child(_lencana_pendukung(12 if _sempit else 13, peduli))

	var lv: = _teks((tr("Lv %d") % int(b["level"])) if int(b["level"]) > 0 else "-", 18, Color.WHITE, 4)
	lv.custom_minimum_size.x = KOLOM["level"]
	lv.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	h.add_child(lv)

	var wadah_bintang: = CenterContainer.new()
	wadah_bintang.custom_minimum_size.x = KOLOM["bintang"]
	wadah_bintang.add_child(_bintang(int(b["bintang"]), 17.0 if _sempit else 22.0))
	h.add_child(wadah_bintang)

	var pb: = _teks(PP.angka(int(b["pembeli"])), 19 if _sempit else 22, EMAS, 6)
	pb.custom_minimum_size.x = KOLOM["pembeli"]
	pb.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	h.add_child(pb)

	var om: = _teks(PP.rupiah_ringkas(int(b["omzet"])), 17 if _sempit else 19, Color(0.6, 1.0, 0.45), 5)
	om.custom_minimum_size.x = KOLOM["omzet"]
	om.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	h.add_child(om)

	h.add_child(_tombol_jempol(b))

	var lapor: = Button.new()
	lapor.custom_minimum_size = Vector2(KOLOM["lapor"], 36)
	lapor.focus_mode = Control.FOCUS_NONE
	lapor.text = "⚑"
	lapor.tooltip_text = "Laporkan nama ini"
	lapor.add_theme_font_size_override("font_size", 18)
	lapor.visible = not saya and String(b["kode"]) != ""
	lapor.modulate.a = 0.7
	lapor.pressed.connect( func():
		GameState.klik()
		_terbuka_lapor = "" if _terbuka_lapor == String(b["kode"]) else String(b["kode"])
		_gambar())
	if saya:
		var kosong: = Control.new()
		kosong.custom_minimum_size.x = KOLOM["lapor"]
		h.add_child(kosong)
	else:
		h.add_child(lapor)

	if _terbuka_lapor != "" and _terbuka_lapor == String(b["kode"]):
		var konfirmasi: = HBoxContainer.new()
		konfirmasi.alignment = BoxContainer.ALIGNMENT_END
		konfirmasi.add_theme_constant_override("separation", 10)
		v.add_child(konfirmasi)
		if GameState.papan.sudah_dilaporkan(String(b["kode"])):
			konfirmasi.add_child(_teks("Laporan terkirim. Terima kasih!", 15, Color(0.6, 1.0, 0.6), 3, false))
		else:
			konfirmasi.add_child(_teks("Nama ini tidak pantas?", 15, Color.WHITE, 3, false))
			var kirim: = Button.new()
			kirim.text = "Laporkan nama ini"
			kirim.theme_type_variation = &"TombolMerah"
			kirim.focus_mode = Control.FOCUS_NONE
			kirim.add_theme_font_size_override("font_size", 16)
			kirim.pressed.connect( func():
				kirim.disabled = true
				kirim.text = "Mengirim..."
				var ok: bool = await GameState.papan.laporkan(String(b["kode"]))
				if not is_instance_valid(kirim):
					return
				if not ok:
					kirim.disabled = false
					kirim.text = "Gagal, coba lagi"
					return
				_gambar())
			konfirmasi.add_child(kirim)
	return p


func _tombol_jempol(b: Dictionary) -> Control:
	var tombol: = Button.new()
	tombol.custom_minimum_size = Vector2(KOLOM["jempol"], 38)
	tombol.focus_mode = Control.FOCUS_NONE
	var saya: bool = b["saya"]
	var sudah: bool = b["sudah"]
	var aktif: bool = not saya and not sudah and String(b["kode"]) != "" and GameState.papan.ada_jempol()
	var warna: = Color(0.18, 0.62, 0.3) if sudah else (BIRU_TERANG if aktif else Color(1, 1, 1, 0.1))
	for k in [["normal", warna], ["hover", warna.lightened(0.1)], ["pressed", warna.darkened(0.15)], ["disabled", warna]]:
		tombol.add_theme_stylebox_override(k[0], TENANG.kotak(k[1], 12, Vector4(8, 2, 10, 2)))
	tombol.disabled = not aktif
	tombol.tooltip_text = "Warungmu sendiri" if saya else ("Sudah kamu beri jempol hari ini" if sudah else "Beri jempol")
	var isi: = HBoxContainer.new()
	isi.alignment = BoxContainer.ALIGNMENT_CENTER
	isi.add_theme_constant_override("separation", 6)
	isi.mouse_filter = Control.MOUSE_FILTER_IGNORE
	isi.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tombol.add_child(isi)
	isi.add_child(_ikon_jempol(24, Color.WHITE if (aktif or sudah) else Color(1, 1, 1, 0.6)))
	isi.add_child(_teks(PP.angka_ringkas(int(b["jempol"])), 19, Color.WHITE, 3))
	tombol.pressed.connect( func():
		tombol.disabled = true
		GameState.bunyi("koin")
		var hasil: Dictionary = await GameState.papan.beri_jempol(String(b["kode"]))
		if not is_inside_tree():
			return
		if not hasil.get("ok", false):
			var alasan: = String(hasil.get("alasan", ""))
			_pesan.text = "Jatah jempol hari ini sudah habis (10). Besok bisa lagi, ya." if alasan == "habis"\
			else ("Belum tersambung ke internet. Coba lagi." if alasan == "offline" else "Jempol belum bisa dikirim. Coba lagi nanti.")
			tombol.disabled = false
			return

		_pesan.text = "Jempol terkirim! Terima kasih sudah menyemangati warung lain.")
	return tombol







func _lencana_pendukung(ukuran: int, peduli: = false) -> Control:
	return PP.pita_gelar(ukuran, peduli)


func _teks(teks: String, ukuran: int, warna: Color, garis: = 5, cetak: = true) -> Label:
	var l: = Label.new()
	l.text = teks
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.add_theme_font_override("font", GH.cetak() if cetak else GH.font("Nunito", 800))
	l.add_theme_font_size_override("font_size", ukuran)
	l.add_theme_color_override("font_color", warna)
	l.add_theme_color_override("font_outline_color", Color(0.02, 0.05, 0.12, 0.9))
	l.add_theme_constant_override("outline_size", garis)
	return l


func _lencana(nomor: int, ukuran: float) -> Control:
	var c: = Control.new()
	c.custom_minimum_size = Vector2(ukuran, ukuran)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var warna: Color = WARNA_MEDALI[nomor - 1] if nomor >= 1 and nomor <= 3 else Color(0.08, 0.16, 0.34)
	c.draw.connect( func():
		var pusat: = c.size / 2.0
		var r: = minf(c.size.x, c.size.y) / 2.0
		c.draw_circle(pusat + Vector2(0, 2), r, warna.darkened(0.5))
		c.draw_circle(pusat, r - 1, warna.darkened(0.25))
		c.draw_circle(pusat - Vector2(0, 1.5), r - 4, warna))
	var l: = _teks(PP.angka(nomor) if nomor > 0 else "-", int(ukuran * (0.46 if nomor < 100 else 0.34)), Color.WHITE, 6)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.set_anchors_preset(Control.PRESET_FULL_RECT)
	c.add_child(l)
	return c


func _bintang(n: int, ukuran: float) -> Control:
	var c: = Control.new()
	var jarak: = ukuran * 0.12
	c.custom_minimum_size = Vector2(ukuran * 5 + jarak * 4, ukuran)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.draw.connect( func():
		for i in 5:
			var pusat: = Vector2(ukuran / 2.0 + i * (ukuran + jarak), ukuran / 2.0 + 0.5)
			var titik: = PackedVector2Array()
			for k in 10:
				var r: = ukuran * (0.52 if k % 2 == 0 else 0.23)
				var sudut: = - PI / 2.0 + k * PI / 5.0
				titik.append(pusat + Vector2(cos(sudut), sin(sudut)) * r)
			var nyala: = i < n
			c.draw_colored_polygon(titik, EMAS if nyala else Color(0.02, 0.06, 0.16, 0.6))
			c.draw_polyline(titik + PackedVector2Array([titik[0]]), EMAS_GELAP if nyala else Color(1, 1, 1, 0.3), maxf(1.5, ukuran * 0.08), true))
	return c



func _ikon_jempol(ukuran: float, warna: Color) -> Control:
	var c: = Control.new()
	c.custom_minimum_size = Vector2(ukuran, ukuran)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	c.draw.connect( func():
		var u: = c.size.x
		var sb: = StyleBoxFlat.new()
		sb.bg_color = warna
		sb.set_corner_radius_all(int(u * 0.18))
		c.draw_style_box(sb, Rect2(Vector2(0.3, 0.42) * u, Vector2(0.62, 0.52) * u))
		var ibu: = StyleBoxFlat.new()
		ibu.bg_color = warna
		ibu.set_corner_radius_all(int(u * 0.12))
		c.draw_style_box(ibu, Rect2(Vector2(0.38, 0.06) * u, Vector2(0.24, 0.48) * u))
		c.draw_rect(Rect2(Vector2(0.04, 0.44) * u, Vector2(0.2, 0.5) * u), warna)
		for y in [0.56, 0.69, 0.82]:
			c.draw_line(Vector2(0.62, y) * u, Vector2(0.9, y) * u, Color(0.02, 0.1, 0.25, 0.45), maxf(1.0, u * 0.05)))
	return c


func _ikon_piala(ukuran: float) -> Control:
	var c: = Control.new()
	c.custom_minimum_size = Vector2(ukuran, ukuran)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	c.draw.connect( func():
		var u: = c.size.x
		var cawan: = PackedVector2Array([Vector2(0.2, 0.12), Vector2(0.8, 0.12), Vector2(0.74, 0.42), Vector2(0.58, 0.58), Vector2(0.42, 0.58), Vector2(0.26, 0.42)])
		for i in cawan.size():
			cawan[i] *= u
		c.draw_arc(Vector2(0.2, 0.27) * u, 0.13 * u, PI * 0.5, PI * 1.5, 10, EMAS_GELAP, 0.07 * u)
		c.draw_arc(Vector2(0.8, 0.27) * u, 0.13 * u, - PI * 0.5, PI * 0.5, 10, EMAS_GELAP, 0.07 * u)
		c.draw_colored_polygon(cawan, EMAS)
		c.draw_rect(Rect2(Vector2(0.45, 0.58) * u, Vector2(0.1, 0.14) * u), EMAS_GELAP)
		c.draw_rect(Rect2(Vector2(0.3, 0.72) * u, Vector2(0.4, 0.14) * u), EMAS))
	return c


func _ikon_mahkota(ukuran: float) -> Control:
	var c: = Control.new()
	c.custom_minimum_size = Vector2(ukuran, ukuran * 0.7)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	c.draw.connect( func():
		var u: = c.size.x
		var t: = c.size.y
		var titik: = PackedVector2Array([Vector2(0.08 * u, 0.9 * t), Vector2(0.05 * u, 0.25 * t), Vector2(0.3 * u, 0.55 * t), 
			Vector2(0.5 * u, 0.08 * t), Vector2(0.7 * u, 0.55 * t), Vector2(0.95 * u, 0.25 * t), Vector2(0.92 * u, 0.9 * t)])
		c.draw_colored_polygon(titik, EMAS)
		c.draw_polyline(titik + PackedVector2Array([titik[0]]), EMAS_GELAP, 0.06 * u)
		for x in [0.05, 0.5, 0.95]:
			c.draw_circle(Vector2(x * u, (0.08 if x == 0.5 else 0.25) * t), 0.07 * u, Color(0.95, 0.25, 0.3)))
	return c



static func _aman(v) -> int:
	return int(v) if v is int or v is float or (v is String and v.is_valid_float()) else 0
