extends VBoxContainer




const UI: = preload("res://scripts/hp/hp_ui.gd")
const WARNA: = Color(0.85, 0.3, 0.25)
const WARNA_HARI_INI: = Color(0.95, 0.5, 0.15)
const WARNA_BATAS: = Color(0.85, 0.2, 0.18)
const WARNA_JUMAT: = Color(0.18, 0.55, 0.3)
const WARNA_SEWA: = Color(0.5, 0.33, 0.68)
const WARNA_RONDA: = Color(0.2, 0.32, 0.6)
const SINGKATAN: = ["Sen", "Sel", "Rab", "Kam", "Jum", "Sab", "Min"]

var hp: Control
var _label_bulan: Label
var _grid: GridContainer
var _agenda: VBoxContainer
var _geser_bulan: = 0


func _ready() -> void :
	add_theme_constant_override("separation", 0)
	add_child(UI.kepala("Kalender", WARNA))
	var g: Array = UI.gulir(10)
	var tepi: = MarginContainer.new()
	tepi.size_flags_vertical = Control.SIZE_EXPAND_FILL
	for sisi in ["left", "right", "top", "bottom"]:
		tepi.add_theme_constant_override("margin_" + sisi, 10)
	tepi.add_child(g[0])
	add_child(tepi)
	var isi: VBoxContainer = g[1]

	var baris_bulan: = HBoxContainer.new()
	isi.add_child(baris_bulan)
	var kiri: = UI.tombol("‹", WARNA, 22, 36)
	kiri.custom_minimum_size.x = 44
	kiri.pressed.connect( func(): _geser_bulan -= 1;_perbarui())
	baris_bulan.add_child(kiri)
	_label_bulan = UI.label("", 20)
	_label_bulan.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_label_bulan.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	baris_bulan.add_child(_label_bulan)
	var kanan: = UI.tombol("›", WARNA, 22, 36)
	kanan.custom_minimum_size.x = 44
	kanan.pressed.connect( func(): _geser_bulan += 1;_perbarui())
	baris_bulan.add_child(kanan)
	var kartu: = UI.panel(Color.WHITE, 12, 8)
	isi.add_child(kartu)
	_grid = GridContainer.new()
	_grid.columns = 7
	_grid.add_theme_constant_override("h_separation", 2)
	_grid.add_theme_constant_override("v_separation", 2)
	kartu.add_child(_grid)

	var legenda: = HFlowContainer.new()
	legenda.add_theme_constant_override("separation", 6)
	isi.add_child(legenda)
	var keterangan: = [["Hari ini", WARNA_HARI_INI], ["Batas misi", WARNA_BATAS], ["Bayar sewa", WARNA_SEWA]]
	if GameState.ikut_ronda_jumatan():
		keterangan += [["Jumat", WARNA_JUMAT], ["Ronda", WARNA_RONDA]]
	for pasangan in keterangan:
		var kotak: = ColorRect.new()
		kotak.color = pasangan[1]
		kotak.custom_minimum_size = Vector2(14, 14)
		kotak.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		legenda.add_child(kotak)
		legenda.add_child(UI.label(pasangan[0], 13, UI.WARNA_REDUP))
	isi.add_child(UI.label("Agenda", 19))
	_agenda = VBoxContainer.new()
	_agenda.add_theme_constant_override("separation", 6)
	isi.add_child(_agenda)
	GameState.data_berubah.connect(_perbarui)


func tampil() -> void :
	_geser_bulan = 0
	_perbarui()


func _perbarui() -> void :
	if not is_inside_tree():
		return
	var sekarang: = GameState.tanggal()
	var bulan: = int(sekarang["month"]) - 1 + _geser_bulan
	var tahun: = int(sekarang["year"]) + floori(bulan / 12.0)
	bulan = posmod(bulan, 12) + 1
	_label_bulan.text = GameState.NAMA_BULAN[bulan - 1]
	for anak in _grid.get_children():
		anak.queue_free()
	for s in SINGKATAN:
		var l: = UI.label(s, 13, WARNA_JUMAT if s == "Jum" else UI.WARNA_REDUP)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.custom_minimum_size.x = 46
		_grid.add_child(l)

	var awal: = Time.get_unix_time_from_datetime_dict({"year": tahun, "month": bulan, "day": 1, "hour": 0, "minute": 0, "second": 0})
	var hari_pertama: = posmod(int(Time.get_datetime_dict_from_unix_time(awal)["weekday"]) - 1, 7)
	for i in hari_pertama:
		_grid.add_child(Control.new())
	var mulai: = Time.get_unix_time_from_datetime_string(GameState.TANGGAL_MULAI)
	for tgl in range(1, 32):
		var unix: = awal + (tgl - 1) * 86400
		if int(Time.get_datetime_dict_from_unix_time(unix)["month"]) != bulan:
			break

		var hari_ke: = int(round((unix - mulai) / 86400.0)) + 1
		_grid.add_child(_sel(tgl, hari_ke))
	_isi_agenda()


func _sel(tgl: int, hari_ke: int) -> Control:
	var warna: = Color(0, 0, 0, 0)
	var warna_teks: = UI.WARNA_TEKS
	if hari_ke == GameState.hari:
		warna = WARNA_HARI_INI
		warna_teks = Color.WHITE
	elif GameState.misi_status == "aktif" and hari_ke == GameState.batas_hari:
		warna = WARNA_BATAS
		warna_teks = Color.WHITE
	elif hari_ke == GameState.hari_jatuh_tempo_sewa():
		warna = WARNA_SEWA
		warna_teks = Color.WHITE
	elif GameState.nama_hari_ke(hari_ke) == "Jumat" and GameState.ikut_ronda_jumatan():
		warna_teks = WARNA_JUMAT
	elif GameState.nama_hari_ke(hari_ke) == "Kamis" and GameState.ikut_ronda_jumatan():
		warna_teks = WARNA_RONDA
	if hari_ke < GameState.hari and not (GameState.misi_status == "aktif" and hari_ke == GameState.batas_hari):
		warna_teks.a = 0.45
	var p: = UI.panel(warna, 18, 0)
	p.custom_minimum_size = Vector2(46, 38)
	var l: = UI.label(str(tgl), 16, warna_teks)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	p.add_child(l)
	return p


func _isi_agenda() -> void :
	for anak in _agenda.get_children():
		anak.queue_free()
	var baris: Array[String] = []
	baris.append("Hari ini: %s, %s (hari ke-%d warung buka)." % [GameState.nama_hari(), GameState.teks_tanggal(), GameState.hari])
	if GameState.misi_status == "aktif":
		baris.append("Batas kiriman untuk %s (%s): %s, %d hari lagi. Kurang %s." % [GameState.nama_penerima(), GameState.data_bab()["kebutuhan"], GameState.teks_tanggal(GameState.batas_hari), GameState.sisa_hari(), GameState.format_rupiah(GameState.kekurangan_kiriman())])
	elif GameState.misi_status == "menunggu":
		baris.append("%s (Level Warung %d)." % [GameState.teks_tunggu_agus(), GameState.level()])

	if GameState.ramadan():
		baris.append("Ramadan hari ke-%d. Warung boleh buka sampai 19.00, buka puasa sesudah Maghrib (18.00), tarawih 19.30. Lebaran %s." % [GameState.hari - GameState.RAMADAN_MULAI + 1, GameState.teks_tanggal(GameState.HARI_LEBARAN)])
	elif GameState.hari < GameState.RAMADAN_MULAI and GameState.RAMADAN_MULAI - GameState.hari <= 7:
		baris.append("Ramadan mulai %s (%d hari lagi). Siapkan stok bahan masak dan takjil." % [GameState.teks_tanggal(GameState.RAMADAN_MULAI), GameState.RAMADAN_MULAI - GameState.hari])

	for i in (7 if GameState.ikut_ronda_jumatan() else 0):
		if GameState.nama_hari_ke(GameState.hari + i) == "Jumat":
			baris.append("Sholat Jumat %s pukul 11.30–13.00, warung tutup sebentar." % ("hari ini" if i == 0 else "tanggal " + GameState.teks_tanggal(GameState.hari + i)))
			break

	for j in GameState.daftar_janji_hari_ini():
		baris.append("Janji: %s." % j)


	for id_kerja in GameState.kerja_daftar_hari():
		var k: Dictionary = GameState.data_kerja(id_kerja)
		var sudah: = int(GameState.kerja_hari.get(id_kerja, 0)) == GameState.hari
		baris.append("Kerja sampingan: %s, %s (%s)%s." % [k["judul"], GameState.teks_jam_rentang(k["jam"]), GameState.format_rupiah(GameState.upah_kerja(id_kerja)), " ✓ sudah dikerjakan" if sudah else ""])
	if GameState.pengajian_hari == GameState.hari:
		baris.append("Sore ini pengajian di masjid. Pukul 16.00–17.00 jamaah ramai mampir ke warung, jangan tutup dulu!")

	for i in (7 if GameState.ikut_ronda_jumatan() else 0):
		if GameState.nama_hari_ke(GameState.hari + i) == "Kamis":
			var sudah: = i == 0 and GameState.ronda_terakhir == GameState.hari
			baris.append("Ronda malam Jumat %s: kumpul di pos ronda (Rumah Warga) mulai 21.00, keliling pukul 22.00. Besoknya bangun kesiangan.%s" % [
				"malam ini" if i == 0 else "Kamis " + GameState.teks_tanggal(GameState.hari + i), " (sudah ikut)" if sudah else ""])
			break
	var tempo: = GameState.hari_jatuh_tempo_sewa()
	if GameState.kios_milik:
		baris.append("Kios milik sendiri: tidak ada sewa lagi.")
	else:
		baris.append("Sewa kios %s dibayar %s malam (%s)%s." % [GameState.format_rupiah(GameState.sewa_per_minggu()), "hari ini" if tempo == GameState.hari else "Minggu", GameState.teks_tanggal(tempo), (", ditambah tunggakan %s" % GameState.format_rupiah(GameState.tunggakan_sewa)) if GameState.tunggakan_sewa > 0 else ""])
	baris.append("Biaya harian %s dipotong setiap warung tutup." % GameState.format_rupiah(int(GameState.BIAYA_HARIAN.get(GameState.mode, 10000))))
	for teks in baris:
		var kartu: = UI.panel(Color.WHITE, 8, 8)
		kartu.add_child(UI.label(teks, 14, UI.WARNA_TEKS, true))
		_agenda.add_child(kartu)
