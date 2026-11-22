extends Node2D









@export var tinggi_penjaga: = 185.0



@export var cahaya_karakter: = Color(1.0, 0.88, 0.76)



const PILIHAN_KECEPATAN: = [1, 5, 20]

const BATAS_STOK_MENIPIS: = 2

var indeks_kecepatan: = 0

var dialog_aktif: = false

var nomor_rak: = {}
var bahan_rak: Array[ShaderMaterial] = []
const GAMBAR_RAK_KOSONG: = preload("res://assets/latar/latar_kosong_cocok.png")
const BukuHutang: = preload("res://scripts/buku_hutang.gd")
const PETA_RAK: = preload("res://assets/latar/peta_rak.png")
const SHADER_RAK: = preload("res://shader/rak.gdshader")

const FILE_KASIR: = "res://data/kasir.json"
var label_jumlah_stok: = {}



const LATAR_LUAS: = true
const GAMBAR_LATAR_LUAS: = preload("res://assets/latar/latar_warung_kosong.png")

const GAMBAR_LATAR_MALAM: = preload("res://assets/latar/latar_warung_kosong_malam.png")
var latar_malam: = false

const FOKUS_WARUNG: = Rect2(300, 175, 1150, 650)


var lebar_pandang: = FOKUS_WARUNG.size.x


const PAPAN_NAMA: = Rect2(557, 355, 109, 52)


const KEMIRINGAN_PAPAN: = 0.31


const TINGGI_DEWASA_LATAR_LUAS: = 235.0


const TITIK_LATAR: = {
	"PosisiBapak": Vector2(930, 585), 
	"TitikPelanggan": Vector2(850, 690), 
	"JalurAtas": Vector2(745, 655), 
	"JalurTangga": Vector2(625, 600), 
	"JalurJalan": Vector2(455, 522), 
	"JalurMulai": Vector2(-60, 355), 
	"JalurPulang": Vector2(-60, 355), 
}



const PAKAI_LAPISAN_RAK: = false
const POSISI_RAK: = Vector2(650, 238)
const RAK_SETENGAH: = preload("res://assets/latar/rak_setengah.png")
const RAK_PENUH: = preload("res://assets/latar/rak_penuh.png")
const RAK_SETENGAH_MALAM: = preload("res://assets/latar/rak_setengah_malam.png")
const RAK_PENUH_MALAM: = preload("res://assets/latar/rak_penuh_malam.png")
const STOK_RAK_PENUH: = 12

const BATAS_RAK_SETENGAH: = 0.0001
const BATAS_RAK_PENUH: = 0.65
var lapisan_rak: = {}
var tingkat_rak: = ""
const SCRIPT_PELANGGAN: = preload("res://scripts/pelanggan.gd")

const ANIM_BAPAK_MELAYANI: = "Talk_with_Right_Hand_Open"
var font_papan: FontVariation
signal intro_selesai
var zoom_kamera: = 1.0

var geser_kamera: = Vector2.ZERO
const GESER_MAKS: = Vector2(320, 180)

const JAM_SHOLAT: = 11 * 60 + 30
const JAM_SELESAI_SHOLAT: = 13 * 60



const JALUR_MASJID: = [Vector2(1015, 560), Vector2(1050, 600), Vector2(1050, 700), Vector2(1030, 820), Vector2(1300, 940), Vector2(1400, 962), Vector2(1465, 915)]
const TITIK_TUNGGU_HAJI: = 3
const GESER_TUNGGU_HAJI: = Vector2(-10, 30)
var sedang_sholat: = false
var sholat_hari_ini: = false
var bapak_3d: Sprite2D = null
var label_nama_warung: Control = null
var label_nama_stok: = {}
var baris_tugas: Array = []

var tugas_terbuka: = false
var petunjuk_tugas: Label = null
var bintang_hud: Array[TextureRect] = []
const IKON_BINTANG: = preload("res://assets/ikon/bintang.svg")
const IKON_BINTANG_KOSONG: = preload("res://assets/ikon/bintang_kosong.svg")
const SCRIPT_GRAFIK_LABA: = preload("res://scripts/grafik_laba.gd")
var rekap_isi: VBoxContainer = null

const GH: = preload("res://scripts/gaya_hud.gd")
const KB: = preload("res://scripts/konfirmasi_bayar.gd")
var _label_jam_besar: Label = null
var _label_tanggal: Label = null
var _angka_level: Label = null
var _bar_level: Control = null
var _teks_bar_level: Label = null
var _dock: HBoxContainer = null
var lencana_stok: PanelContainer = null
var lencana_hutang: PanelContainer = null
var tombol_promosi: Button = null
var lencana_promosi: PanelContainer = null
const SCRIPT_HP: = preload("res://scripts/hp/hp.gd")
const UI_HP: = preload("res://scripts/hp/hp_ui.gd")
var hp: Control = null
var lencana_hp: PanelContainer = null
var tombol_hp: Button = null
var _notif_lalu: = 0
var tombol_jalan: Button = null
var tombol_hutang: Button = null

var kurir: Sprite2D = null
var bar_kiriman: PanelContainer = null
var progres_kiriman: ProgressBar = null
var label_kiriman: Label = null
var label_detik_kiriman: Label = null

const TITIK_KURIR: = Vector2(1010, 690)

@onready var suasana: CanvasModulate = %Suasana
@onready var latar: Sprite2D = %Latar
@onready var rak_belakang: Node2D = %RakBelakang
@onready var meja_depan: Polygon2D = %MejaDepan
@onready var rak_depan: Node2D = %RakDepan
@onready var penjaga: Sprite2D = %Penjaga
@onready var kasir: Sprite2D = %Kasir
@onready var label_hari: Label = %LabelHari
@onready var label_jam: Label = %LabelJam
@onready var label_uang: Label = %LabelUang
@onready var label_tugas: Label = %LabelTugas
@onready var judul_tugas: Label = %JudulTugas
@onready var grid_stok: GridContainer = %GridStok
@onready var label_saldo: Label = %LabelSaldo
@onready var pesan: Label = %Pesan
@onready var tombol_menu: Button = %TombolMenu
@onready var tombol_buka: Button = %TombolBuka
var _teks_tombol_buka: = ""
var _teks_buka_lalu: = ""
@onready var tombol_tutup: Button = %TombolTutup
@onready var tombol_kecepatan: Button = %TombolKecepatan
@onready var tombol_belanja: Button = %TombolBelanja
@onready var panel_belanja: PanelContainer = %PanelBelanja
@onready var panel_tutup: PanelContainer = %PanelTutup
@onready var judul_tutup: Label = %Judul
@onready var keterangan_tutup: Label = %Keterangan
@onready var tombol_lanjut: Button = %TombolLanjut
@onready var tombol_stok: Button = %TombolStok
@onready var panel_stok_hud: PanelContainer = $UI / Akar / PanelStok
@onready var isi_stok: VBoxContainer = %IsiStok
@onready var redup: ColorRect = %Redup
@onready var akar_ui: Control = $UI / Akar


func _ready() -> void :
	GameState.volume_takbir_db = -6.0
	GameState.get_tree().create_timer(1.5).timeout.connect(_kabari_utang_ikhlas)



	if GameState.kurir_dalam_perjalanan and not GameState.kiriman_stok.is_empty():
		GameState.kurir_dalam_perjalanan = false
		GameState.detik_kiriman = 1.0
	elif GameState.kurir_dalam_perjalanan:
		GameState.kurir_dalam_perjalanan = false


	process_mode = Node.PROCESS_MODE_ALWAYS
	latar.process_mode = Node.PROCESS_MODE_PAUSABLE
	$Layanan.process_mode = Node.PROCESS_MODE_PAUSABLE
	font_papan = FontVariation.new()

	font_papan.base_font = load("res://assets/font/BebasNeue.ttf")
	font_papan.spacing_glyph = 1
	if LATAR_LUAS:

		latar.texture = GAMBAR_LATAR_LUAS
		penjaga.hide()
		kasir.hide()
		meja_depan.hide()
		for nama in TITIK_LATAR:
			latar.get_node(nama).position = _ke_lokal(TITIK_LATAR[nama])

		if PAKAI_LAPISAN_RAK:
			_pasang_rak_isi()
		_pasang_bapak_3d()
		_pasang_nama_warung()
	else:
		var gambar_penjaga: = load("res://assets/karakter/penjaga_%s_diam.png" % GameState.penjaga) as Texture2D
		_pasang_karakter(penjaga, gambar_penjaga, tinggi_penjaga)
		penjaga.modulate = cahaya_karakter




	var pojok_kiri_atas: = - latar.texture.get_size() / 2.0
	meja_depan.texture = latar.texture
	meja_depan.position = pojok_kiri_atas
	rak_belakang.position = pojok_kiri_atas
	rak_depan.position = pojok_kiri_atas
	if not LATAR_LUAS:
		atur_pose_kasir("diam")
		_bangun_rak()
	_bangun_daftar_stok()
	_buat_bintang_hud()
	_pasang_info_hud()
	_gaya_hud()
	GameState.reputasi_berubah.connect(_on_reputasi_berubah)

	if FileAccess.file_exists("res://data/tata_rak.json"):
		var tata: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/tata_rak.json"))
		if typeof(tata) == TYPE_DICTIONARY and (tata as Dictionary).has("lebar_pandang_warung"):
			lebar_pandang = clampf(float(tata["lebar_pandang_warung"]), 700.0, 1536.0)

	zoom_kamera = 0.0 if (LATAR_LUAS and GameState.putar_intro) else 1.0
	_sesuaikan_latar()
	get_viewport().size_changed.connect(_sesuaikan_latar)

	if zoom_kamera < 1.0:
		intro_selesai.connect( func(): GameState.putar_musik(GameState.musik_suasana()), CONNECT_ONE_SHOT)
		_putar_intro()
	else:
		GameState.putar_musik(GameState.musik_suasana())

	GameState.sedang_main = true
	GameState.tampak_malam = false
	_tabir_gelap(false)
	GameState.tugas_selesai.connect(_on_tugas_selesai)

	if not GameState.naik_level_tertunda.is_empty():
		tampilkan_naik_level.call_deferred()
	if GameState.status_hari == "tutup":
		_isi_ringkasan()
	pesan.text = ""


	_pulihkan_preman.call_deferred()


	var energi: = preload("res://scripts/bar_energi.gd").new()
	bar_energi = energi
	energi.adegan = self
	energi.akar = akar_ui

	_slot_energi.add_child(energi)
	if GameState.god_aktif():
		var god = load(GameState.JALUR_GOD).new()
		god.adegan = self
		god.akar = akar_ui
		$UI / Akar / BarKanan.add_child(god)
		$UI / Akar / BarKanan.move_child(god, tombol_menu.get_index())

	tombol_menu.pressed.connect(_on_menu_ditekan)
	_teks_tombol_buka = tombol_buka.text
	tombol_buka.pressed.connect(_on_buka_ditekan)
	tombol_tutup.pressed.connect(_on_tutup_ditekan)
	tombol_kecepatan.pressed.connect(_on_kecepatan_ditekan)
	panel_belanja.visibility_changed.connect(_perbarui_tampilan)
	_pasang_hp()
	_pasang_tombol_jalan()

	GH.jaga_tepi.call_deferred(akar_ui)

	sorot = preload("res://scripts/sorot_tutorial.gd").new()
	sorot.process_mode = Node.PROCESS_MODE_ALWAYS
	akar_ui.add_child(sorot)


	tombol_tutup.text = "Tutup\nWarung"
	tombol_tutup.add_theme_font_size_override("font_size", 22)
	tombol_tutup.icon = null
	_pasang_zebra()
	_pasang_spanduk()
	GameState.dukungan_diterima.connect(_pasang_spanduk)
	tombol_stok.pressed.connect(_on_stok_ditekan)
	panel_stok_hud.theme = GH.tema_jendela_emas()
	tombol_lanjut.pressed.connect(_on_lanjut_ditekan)
	GH.gaya_tombol(tombol_buka, true, 34)
	GH.gaya_tombol(tombol_tutup, true, 26)
	tombol_buka.icon = null
	tombol_buka.custom_minimum_size = Vector2(0, 0)

	tombol_buka.anchor_top = 0.5
	tombol_buka.anchor_bottom = 0.5


	tombol_buka.offset_left = -200.0
	tombol_buka.offset_right = 200.0
	tombol_buka.offset_top = -36.0
	tombol_buka.offset_bottom = 36.0
	_gaya_tombol_buka()

	GameState.data_berubah.connect(_on_data_berubah)
	GameState.akrab_naik.connect(_on_akrab_naik)


	var dari_tas: = GameState.bongkar_tas_grosir()
	if not dari_tas.is_empty():
		var n: = 0
		for id in dari_tas:
			n += int(dari_tas[id])
		GameState.simpan()
		tampilkan_pesan.call_deferred("Belanjaan grosir dari pasar (%d barang) sudah ditata di rak." % n, 5.0)
	if GameState.basi_baru > 0:
		tampilkan_pesan.call_deferred("%d roti titipan sudah basi (lebih dari %d hari), disisihkan untuk dikembalikan ke Kang Dede." % [GameState.basi_baru, GameState.HARI_BASI_ROTI], 5.0)
		GameState.basi_baru = 0
	_on_data_berubah()
	_perbarui_hujan()
	GameState.hujan_berubah.connect(_on_hujan_berubah)




func _unhandled_input(event: InputEvent) -> void :

	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F9 and OS.is_debug_build():
		ganti_pratinjau_upgrade()
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed or Time.get_ticks_usec() - _waktu_geser_lalu > 80000:
			_kec_kamera = Vector2.ZERO
		return
	if not (event is InputEventMouseMotion) or not (event.button_mask & MOUSE_BUTTON_MASK_LEFT):
		return
	if dialog_aktif or panel_terbuka() or zoom_kamera < 1.0 or not LATAR_LUAS:
		return

	if get_viewport().gui_is_dragging():
		return
	var geser: Vector2 = event.relative / latar.scale.x
	geser_kamera -= geser
	_sesuaikan_latar()

	var sekarang: = Time.get_ticks_usec()
	var dt: = maxf((sekarang - _waktu_geser_lalu) / 1000000.0, 0.001)
	_waktu_geser_lalu = sekarang
	_kec_kamera = _kec_kamera.lerp( - geser / dt, 0.4).limit_length(KEC_KAMERA_MAKS)




const GESEKAN_KAMERA: = 3.5
const KEC_KAMERA_MAKS: = 2500.0
var _kec_kamera: = Vector2.ZERO
var _waktu_geser_lalu: = 0

func _luncur_kamera(delta: float) -> void :
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) or dialog_aktif or panel_terbuka():
		return
	if _kec_kamera.length() < 15.0:
		_kec_kamera = Vector2.ZERO
		return
	var mau: = geser_kamera + _kec_kamera * delta
	geser_kamera = mau
	_sesuaikan_latar()

	if absf(geser_kamera.x - mau.x) > 0.5:
		_kec_kamera.x = 0.0
	if absf(geser_kamera.y - mau.y) > 0.5:
		_kec_kamera.y = 0.0
	_kec_kamera *= exp( - GESEKAN_KAMERA * delta)



func _exit_tree() -> void :
	get_tree().paused = false




func _process(delta: float) -> void :



	if $Layanan.tahan_depan and _serah_terima == 0 and not dialog_aktif\
	and (preman == null or not is_instance_valid(preman) or GameState.preman_di_depan()):
		$Layanan.tahan_depan = false

	if is_instance_valid(bapak_3d) and is_instance_valid(bapak_3d.karakter):
		bapak_3d.karakter.atur_perban(GameState.perban_tampil())
	var jeda: = panel_terbuka() or dialog_aktif
	if get_tree().paused != jeda:
		get_tree().paused = jeda
	if jeda:
		_tutup_panel_lipat()
	_perbarui_latar_malam()
	_luncur_kamera(delta)
	_cek_kelelahan()
	_atur_duduk(delta)
	_cek_wajib_tutup()
	_perbarui_gelap_kios(delta)
	_cek_kabar_kerja()
	if not jeda:
		_gerak_lalu_lintas(delta)
	_perbarui_banjir()

	if tombol_upgrade != null:
		var denyut: = GameState.wajib_etalase and not GameState.punya_upgrade("etalase")
		if denyut:
			tombol_upgrade.pivot_offset = tombol_upgrade.size / 2.0
			tombol_upgrade.scale = Vector2.ONE * (1.0 + 0.06 * sin(Time.get_ticks_msec() / 180.0))

	if tombol_promosi != null:
		var promosi_siap: = tombol_promosi.visible and GameState.alasan_tidak_bisa_promosi() == ""
		tombol_promosi.pivot_offset = tombol_promosi.size / 2.0
		tombol_promosi.scale = Vector2.ONE * (1.0 + 0.05 * sin(Time.get_ticks_msec() / 200.0)) if promosi_siap else Vector2.ONE


	var siap_buka: = GameState.status_hari == "persiapan" and (GameState.warung_libur()\
	or (GameState.menit >= GameState.jam_buka() and GameState.menit < GameState.jam_wajib_tutup()))
	_pantul_tombol_buka(siap_buka)
	_perbarui_sorot_etalase()
	_cek_tip_warung()
	_perbarui_kotak_pesan()
	_perbarui_hujan()
	_proses_kiriman(delta)

	if GameState.status_hari == "persiapan" and not dialog_aktif and not panel_terbuka():
		_cek_sholat_jumat()
		if sedang_sholat:
			GameState.majukan_waktu(delta * GameState.kecepatan_waktu)
			_perbarui_tampilan()
			return


		GameState.majukan_waktu(delta * GameState.kecepatan_waktu)
		_cek_kabar_kerja()
		_perbarui_tampilan()
		return

	if GameState.status_hari != "buka" or dialog_aktif or panel_terbuka():
		return
	_cek_sholat_jumat()
	var pengali: int = PILIHAN_KECEPATAN[indeks_kecepatan]
	GameState.majukan_waktu(delta * GameState.kecepatan_waktu * pengali)
	if not GameState.sedang_banjir():
		_proses_kejadian()
		_cek_kiriman_warga()
	_perbarui_tampilan()


var _label_qris: Label = null

func _perbarui_tampilan() -> void :
	var status: = GameState.status_hari
	label_hari.text = "%s, %s" % [GameState.nama_hari(), GameState.teks_tanggal(-1, true)]
	label_jam.text = GameState.teks_jam()
	if _label_jam_besar != null:
		_label_jam_besar.text = label_jam.text.replace(" WIB", "")
		_label_tanggal.text = label_hari.text.to_upper()
	GH.hitung_uang(label_uang, GameState.uang, GameState.format_rupiah)
	if _label_qris != null:
		_label_qris.visible = GameState.punya_upgrade("qris") or GameState.saldo_digital > 0
		_label_qris.text = "QRIS %s" % GameState.format_rupiah(GameState.saldo_digital)

	tombol_buka.visible = status == "persiapan" and not sedang_sholat
	tombol_buka.disabled = false
	tombol_buka.text = ("Libur %s · Keluar Warung" % GameState.nama_hari()) if GameState.warung_libur() else _teks_tombol_buka

	if not GameState.warung_libur() and status == "persiapan":
		if GameState.menit < GameState.jam_buka():
			tombol_buka.text = "Buka 09.00 (%s lagi)" % GameState.teks_durasi(GameState.jam_buka() - GameState.menit)
		elif GameState.menit >= GameState.jam_wajib_tutup():
			tombol_buka.text = "Sudah tutup (lewat %s)" % GameState.teks_jam_tutup()
			tombol_buka.disabled = true
	if tombol_buka.visible and tombol_buka.text != _teks_buka_lalu:
		_teks_buka_lalu = tombol_buka.text
		_muatkan_teks_buka()

	tombol_tutup.visible = status == "buka" and GameState.boleh_tutup()
	panel_tutup.visible = status == "tutup"
	perbarui_redup()

	tombol_kecepatan.visible = false
	tombol_tutup.visible = tombol_tutup.visible and not sedang_sholat
	if tombol_hp != null:
		tombol_hp.visible = status != "tutup"
	if tombol_jalan != null:
		tombol_jalan.visible = status != "tutup" and not sedang_sholat
		_atur_tombol_bawah()
	if tombol_hutang != null:
		tombol_hutang.visible = status != "tutup" and not sedang_sholat and not GameState.mode_latihan
		if lencana_hutang != null:
			UI_HP.atur_lencana(lencana_hutang, GameState.hutang_aktif().size())
	if tombol_upgrade != null:
		tombol_upgrade.visible = status != "tutup" and not sedang_sholat
	if tombol_promosi != null:

		tombol_promosi.visible = status != "tutup" and not sedang_sholat and GameState.tutorial_langkah == "" and not GameState.mode_latihan\
		and (GameState.kios_milik or not tombol_tutup.visible)
		_perbarui_promosi()
	if _dock != null:
		tombol_stok.visible = status != "tutup" and not sedang_sholat
		if not tombol_stok.visible:
			panel_stok_hud.hide()

	suasana.color = _warna_suasana()



func _on_data_berubah() -> void :
	_perbarui_rak_isi()
	var isi: = PackedFloat32Array()
	isi.resize(16)
	for id in nomor_rak:
		isi[nomor_rak[id]] = _batas_isi(id)
	for bahan in bahan_rak:
		bahan.set_shader_parameter("isi", isi)
	for id in label_jumlah_stok:
		var label: Label = label_jumlah_stok[id]
		label.text = str(GameState.stok[id]) if GameState.terbuka(id) else "-"

		if label_nama_stok.has(id):
			var ada: = GameState.terbuka(id)
			label.visible = ada
			label_nama_stok[id].visible = ada
		label.add_theme_color_override("font_color", Color(1, 0.5, 0.45) if GameState.stok[id] <= BATAS_STOK_MENIPIS else Color(1, 0.86, 0.45))
	label_saldo.text = "Saldo layanan %s" % GameState.format_rupiah(GameState.saldo_layanan)
	_perbarui_tombol_stok()
	_perbarui_tugas()
	_perbarui_tampilan()




func _batas_isi(id: String) -> float:
	var rak: Dictionary = GameState.data_barang(id)["rak"]
	var stok: int = GameState.stok[id]
	if rak.get("semua_atau_kosong", false):


		if rak.has("tampil_bersama"):
			stok += GameState.stok[rak["tampil_bersama"]]
		return 99.0 if stok > 0 else -99.0
	var jumlah_slot: int = rak.get("kotak", []).size()
	for baris in rak.get("baris", []):
		jumlah_slot += int(baris[8])

	var terisi: int = clamp(ceili(stok / float(rak["penuh_pada"]) * jumlah_slot), 0, jumlah_slot)
	if terisi >= jumlah_slot:
		return 99.0
	if terisi <= 0:
		return -99.0
	return float(terisi)






func _bangun_rak() -> void :
	var nomor: = 0
	for id in GameState.barang_fisik():
		if GameState.data_barang(id).has("rak"):
			nomor += 1
			nomor_rak[id] = nomor
	for lapisan in 2:
		var gambar: = Sprite2D.new()
		gambar.texture = GAMBAR_RAK_KOSONG
		gambar.centered = false
		var bahan: = ShaderMaterial.new()
		bahan.shader = SHADER_RAK
		bahan.set_shader_parameter("peta", PETA_RAK)
		bahan.set_shader_parameter("lapisan", float(lapisan))
		gambar.material = bahan
		(rak_belakang if lapisan == 0 else rak_depan).add_child(gambar)
		bahan_rak.append(bahan)


func _bangun_daftar_stok() -> void :

	grid_stok.columns = 2
	grid_stok.get_parent().get_parent().get_parent().custom_minimum_size.x = 300
	for id in GameState.barang_fisik():
		var nama: = Label.new()
		nama.text = GameState.data_barang(id)["nama"]
		nama.theme_type_variation = &"LabelHud"
		nama.add_theme_font_size_override("font_size", 17)
		nama.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var jumlah: = Label.new()
		jumlah.theme_type_variation = &"LabelHud"
		jumlah.add_theme_font_size_override("font_size", 17)
		jumlah.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		grid_stok.add_child(nama)
		grid_stok.add_child(jumlah)
		label_jumlah_stok[id] = jumlah
		label_nama_stok[id] = nama
	var ke_hp: = Button.new()
	ke_hp.text = "Belanja lewat HP"
	ke_hp.theme_type_variation = &"TombolHijau"
	ke_hp.add_theme_font_size_override("font_size", 17)
	ke_hp.custom_minimum_size.y = 40
	ke_hp.pressed.connect( func(): buka_hp("belanja"))
	isi_stok.add_child(ke_hp)



const KREM_EMAS: = Color(1.0, 0.86, 0.45)
const EMAS_TUA: = Color(0.55, 0.33, 0.07)
const COKELAT_TULISAN: = Color(0.29, 0.16, 0.04)

func _gaya_tombol_buka() -> void :
	for k in [["normal", KREM_EMAS, 7, 0], ["hover", KREM_EMAS.lightened(0.12), 7, 0], ["pressed", KREM_EMAS.darkened(0.06), 3, 4], 
			["hover_pressed", KREM_EMAS.darkened(0.06), 3, 4], ["focus", KREM_EMAS, 7, 0], 
			["disabled", Color(0.72, 0.69, 0.62), 5, 0]]:
		var sb: = StyleBoxFlat.new()
		sb.bg_color = k[1]
		sb.set_corner_radius_all(24)
		sb.border_color = EMAS_TUA if k[0] != "disabled" else Color(0.45, 0.43, 0.4)
		sb.border_width_left = 3
		sb.border_width_right = 3
		sb.border_width_top = 3
		sb.border_width_bottom = k[2]
		sb.content_margin_left = 34
		sb.content_margin_right = 34
		sb.content_margin_top = 6 + k[3]
		sb.content_margin_bottom = 6
		sb.shadow_color = Color(0, 0, 0, 0.32)
		sb.shadow_size = 10
		sb.shadow_offset = Vector2(0, 5)
		sb.anti_aliasing = true
		tombol_buka.add_theme_stylebox_override(k[0], sb)
	tombol_buka.add_theme_font_override("font", GH.cetak())
	tombol_buka.add_theme_font_size_override("font_size", GH.ukuran_cetak(32))
	for k in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color", "font_focus_color"]:
		tombol_buka.add_theme_color_override(k, COKELAT_TULISAN)
	tombol_buka.add_theme_color_override("font_disabled_color", Color(0.35, 0.33, 0.3))
	tombol_buka.add_theme_constant_override("outline_size", 0)

	var kilau: = Control.new()
	kilau.mouse_filter = Control.MOUSE_FILTER_IGNORE
	kilau.set_anchors_preset(Control.PRESET_FULL_RECT)
	kilau.draw.connect( func():
		var w: = kilau.size.x
		kilau.draw_line(Vector2(26, 9), Vector2(w - 26, 9), Color(1, 1, 1, 0.55), 3.0, true)
		kilau.draw_circle(Vector2(20, 12), 2.5, Color(1, 1, 1, 0.5)))
	tombol_buka.add_child(kilau)



func _muatkan_teks_buka() -> void :
	var teks: = TranslationServer.translate(tombol_buka.text)
	var f: Font = tombol_buka.get_theme_font("font")
	var u: = GH.ukuran_cetak(32)
	while u > 16 and f.get_string_size(teks, HORIZONTAL_ALIGNMENT_LEFT, -1, u).x > 400.0 - 76.0:
		u -= 1
	tombol_buka.add_theme_font_size_override("font_size", u)



func _pantul_tombol_buka(siap: bool) -> void :
	tombol_buka.pivot_offset = Vector2(tombol_buka.size.x / 2.0, tombol_buka.size.y)
	if not siap:
		tombol_buka.scale = Vector2.ONE
		return
	var t: = fmod(Time.get_ticks_msec() / 1000.0, 1.8)
	var k: = 0.0
	if t < 0.7:
		k = sin(t / 0.7 * TAU * 1.5) * (1.0 - t / 0.7)
	tombol_buka.scale = Vector2(1.0 - 0.06 * k, 1.0 + 0.09 * k)


func _on_buka_ditekan(paksa: = false) -> void :


	if GameState.warung_libur():
		tampilkan_pesan("Hari %s warung libur. Jalan-jalan keliling kampung dulu, besok buka lagi." % GameState.nama_hari(), 3.0)
		_jalan_jalan()
		return


	if GameState.menit < GameState.jam_buka():
		GameState.bunyi("salah")
		var sisa: = GameState.teks_durasi(GameState.jam_buka() - GameState.menit)
		notifikasi("Warung belum bisa dibuka", "Warung baru boleh buka pukul 09.00 (%s lagi). Sambil menunggu, siapkan stok, atur harga, atau keliling kampung." % sisa, "", WARNA_NOTIF_BIASA)
		return
	if GameState.menit >= GameState.jam_wajib_tutup():
		GameState.bunyi("salah")
		if GameState.kios_milik:
			tampilkan_pesan("Sudah lewat pukul %s. Warung tutup hari ini, besok buka lagi." % GameState.teks_jam_tutup(), 4.0)
		else:
			tampilkan_pesan("Sudah lewat pukul %s. Warung tutup hari ini" % GameState.teks_jam_tutup() + ", besok buka lagi pukul 09.00.", 4.0)
		return

	if GameState.wajib_etalase and not GameState.punya_upgrade("etalase"):
		GameState.bunyi("salah")
		tampilkan_pesan("Beli etalase kaca dulu lewat tombol Upgrade warung (kiri atas). Modal awal sudah termasuk Rp500.000 untuk etalase.", 5.0)
		buka_hp("upgrade")
		return

	if GameState.energi < GameState.ENERGI_MIN_BUKA:
		GameState.bunyi("salah")
		tampilkan_pesan("Pak Misran terlalu lelah untuk buka warung (energi di bawah %d%%). Ngopi atau makan dulu, atau tidur." % int(GameState.ENERGI_MIN_BUKA), 5.0)
		return

	if not GameState.mode_latihan:
		var kurang: = GameState.barang_kurang_stok()
		if not kurang.is_empty() and not paksa:
			_tampilkan_stok_kurang(kurang)
			return
	GameState.status_hari = "buka"
	if GameState.tutorial_langkah == "buka":
		GameState.tutorial_langkah = "layani"
	var pertama_asli: = GameState.tutorial_langkah.begins_with("asli_")
	if pertama_asli:

		GameState.tutorial_langkah = "asli_layani" if GameState.tutorial_awal else ""
	GameState.bunyi("buka")

	var curi: = GameState.cek_pencurian()
	GameState.simpan()
	if pertama_asli and GameState.tutorial_awal:
		tampilkan_pesan("Warung resmi dibuka! Pembeli pertama sebentar lagi datang. Ikuti petunjuk di layar.", 6.0)
	elif pertama_asli:
		tampilkan_pesan("Warung resmi dibuka. Layani pembeli dengan cepat dan benar, dan kumpulkan uang untuk Agus.", 7.0)
	else:
		tampilkan_pesan("Bismillah, warung dibuka! Tunggu pelanggan datang.")
	_perbarui_tampilan()
	if not curi.is_empty():
		_tampilkan_pencurian(curi)


func _on_tutup_ditekan() -> void :
	if GameState.tutorial_langkah in ["layani", "tunggu_tutup"]:
		GameState.tutorial_langkah = "keluar"
	GameState.status_hari = "tutup"

	if not GameState.kiriman_stok.is_empty():
		GameState.terima_kiriman()
		if kurir != null and is_instance_valid(kurir):
			kurir.queue_free()
		_truk_pergi()
	$Layanan.warung_tutup()


	_tutup_panel_lipat()
	pesan.text = ""
	panel_belanja.hide()
	hp.tutup()
	GameState.tutup_hari()
	GameState.bunyi("tutup")

	if GameState.uang_palsu_hari > 0:
		var aman: = " Pembayaran QRIS aman dari uang palsu." if GameState.punya_upgrade("qris") else ""
		notifikasi("Uang palsu!", "Saat menghitung uang laci, selembar %s ternyata palsu. Uangnya hilang.%s" % [GameState.format_rupiah(GameState.uang_palsu_hari), aman], "", WARNA_NOTIF_BURUK)
	_isi_ringkasan()
	GameState.simpan()
	_perbarui_tampilan()

	panel_tutup.modulate.a = 0.0
	redup.modulate.a = 0.0
	panel_tutup.pivot_offset = panel_tutup.size / 2.0
	panel_tutup.scale = Vector2(0.94, 0.94)
	var tw: = create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_property(redup, "modulate:a", 1.0, 0.6)
	tw.tween_property(panel_tutup, "modulate:a", 1.0, 0.7).set_delay(0.35)
	tw.tween_property(panel_tutup, "scale", Vector2.ONE, 0.7).set_delay(0.35)
	if GameState.tip_baru("rekap"):
		_tip_rekap()




func _isi_ringkasan() -> void :
	GameState.catat_riwayat_hari()
	_gaya_rekap()
	judul_tutup.text = "Rekap %s, %s" % [GameState.nama_hari(), GameState.teks_tanggal()]
	panel_tutup.offset_left = -520
	panel_tutup.offset_right = 520
	panel_tutup.offset_top = -330
	panel_tutup.offset_bottom = 330
	keterangan_tutup.text = ""
	keterangan_tutup.add_theme_color_override("font_color", GH.KUNING)
	var catatan: Array = []
	if GameState.bangkrut:
		judul_tutup.text = "Warung Bangkrut…"
		catatan.append("Uang Pak Misran minus terlalu lama. Warung terpaksa ditutup. Coba lagi dari awal, ya.")
		if GameState.diusir:
			catatan[0] = "Sewa kios menunggak tiga minggu berturut-turut. Pemilik kios mengambil kembali kiosnya. Coba lagi dari awal, ya."
		keterangan_tutup.add_theme_color_override("font_color", Color(1, 0.5, 0.45))
	elif GameState.uang < 0:
		var sisa: = int(GameState.BATAS_HARI_MINUS.get(GameState.mode, 3)) - GameState.hari_minus
		catatan.append("Awas! Uang minus %s. Kalau %d hari lagi masih minus, warung bangkrut." % [GameState.format_rupiah( - GameState.uang), sisa])
		keterangan_tutup.add_theme_color_override("font_color", Color(1, 0.5, 0.45))


	if GameState.hari_sewa() and GameState.sewa_selesai_hari != GameState.hari:
		catatan.append("Pukul 18.00 nanti Pak Haji Rasyid menagih sewa kios (%s)." % GameState.format_rupiah(GameState.tagihan_sewa()))
	if _tutup_jam_lima:
		_tutup_jam_lima = false
		catatan.append("Sudah %s: warung tutup %s." % [GameState.teks_jam_tutup(true), GameState.alasan_wajib_tutup()])
	if not GameState.bangkrut:
		catatan.append("Pulang ke rumah (sebelah kiri warung) lalu tidur, atau keliling kampung dulu (paling lambat pukul 02.00).")
	keterangan_tutup.text = "\n".join(catatan)
	keterangan_tutup.add_theme_font_size_override("font_size", 18)
	if rekap_isi != null:
		rekap_isi.queue_free()
	rekap_isi = VBoxContainer.new()
	rekap_isi.add_theme_constant_override("separation", 10)
	keterangan_tutup.get_parent().add_child(rekap_isi)
	keterangan_tutup.get_parent().move_child(rekap_isi, keterangan_tutup.get_index())


	var terjual: = 0
	var terlaris: = ""
	for id in GameState.penjualan_hari:
		terjual += int(GameState.penjualan_hari[id][0])
		if terlaris == "" or int(GameState.penjualan_hari[id][0]) > int(GameState.penjualan_hari[terlaris][0]):
			terlaris = id
	var kemarin: Dictionary = GameState.riwayat[-2] if GameState.riwayat.size() >= 2 else {}


	var utama: = Label.new()
	GH.gaya_label(utama, 34, Color.WHITE, true)
	utama.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	utama.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var persen: = _persen_beda(terjual, int(kemarin.get("barang", -1)))
	if kemarin.is_empty() or int(kemarin.get("barang", -1)) < 0:
		utama.text = "Hari pertama berjualan. Semangat, Pak Misran!" if GameState.riwayat.size() <= 1 else "Hari ini terjual %d barang." % terjual
	elif persen >= 5:
		utama.text = "Hari ini lebih laris %d%% dari kemarin!" % persen
		utama.add_theme_color_override("font_color", GH.HIJAU_UANG)
	elif persen <= -5:
		utama.text = "Hari ini lebih sepi %d%% dari kemarin." % - persen
		utama.add_theme_color_override("font_color", Color(1, 0.62, 0.25))
	else:
		utama.text = "Hari ini sama larisnya dengan kemarin."
	rekap_isi.add_child(utama)

	var kartu: = HBoxContainer.new()
	kartu.add_theme_constant_override("separation", 12)
	rekap_isi.add_child(kartu)
	_kartu_rekap(kartu, "Barang terjual", str(terjual), ("dari %d pembeli" % GameState.pelanggan_dilayani_hari) + (("\nTerlaris: %s" % String(GameState.data_barang(terlaris)["nama"])) if terlaris != "" else ""), Color(0.25, 0.45, 0.7))
	_kartu_rekap(kartu, "Omzet hari ini", GameState.format_rupiah(GameState.omzet_hari), "uang masuk dari penjualan", Color(0.96, 0.56, 0.16))
	var bersih: = GameState.profit_bersih_hari()
	var beda: = _persen_beda(bersih, int(kemarin.get("bersih", -1)))
	var sub: = "sesudah modal & biaya harian"
	if not kemarin.is_empty() and int(kemarin.get("bersih", 0)) > 0:
		sub = ("▲ %d%% dari kemarin" % beda) if beda >= 0 else ("▼ %d%% dari kemarin" % - beda)
	_kartu_rekap(kartu, "Profit bersih hari ini", GameState.format_rupiah(bersih), sub, Color(0.27, 0.7, 0.33) if bersih >= 0 else Color(0.75, 0.2, 0.15))


	var tabel: = GridContainer.new()
	tabel.columns = 5
	tabel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	tabel.add_theme_constant_override("h_separation", 44)
	tabel.add_theme_constant_override("v_separation", 4)
	rekap_isi.add_child(tabel)
	var isi_tabel: = [["", "Hari ini", "7 hari", "30 hari", "Total"], 
		["Omzet", GameState.format_rupiah(GameState.omzet_hari), GameState.format_rupiah(GameState.total_riwayat("omzet", 7)), GameState.format_rupiah(GameState.total_riwayat("omzet", 30)), GameState.format_rupiah(GameState.total_riwayat("omzet", 100000))], 
		["Profit bersih", GameState.format_rupiah(bersih), GameState.format_rupiah(GameState.total_riwayat("bersih", 7)), GameState.format_rupiah(GameState.total_riwayat("bersih", 30)), GameState.format_rupiah(GameState.total_riwayat("bersih", 100000))]]
	for b in isi_tabel.size():
		for k in 5:
			var l: = Label.new()
			l.text = isi_tabel[b][k]
			GH.gaya_label(l, 20 if b == 0 else 22, GH.KUNING if b == 0 or k == 0 else Color.WHITE, b == 0)
			if k > 0:
				l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			tabel.add_child(l)

	rekap_isi.add_child(_judul_kecil("Profit bersih 7 hari terakhir"))
	var grafik: = Control.new()
	grafik.set_script(SCRIPT_GRAFIK_LABA)
	grafik.custom_minimum_size = Vector2(900, 120)
	rekap_isi.add_child(grafik)
	grafik.atur(GameState.riwayat)
	tombol_lanjut.text = "Kembali ke Menu" if GameState.bangkrut else "Keluar warung ▶"



func _persen_beda(sekarang: int, sebelumnya: int) -> int:
	if sebelumnya <= 0:
		return 0
	return roundi(100.0 * (sekarang - sebelumnya) / sebelumnya)



func _kartu_rekap(wadah: Container, judul: String, nilai: String, sub: String, warna: Color) -> void :
	var kartu: = PanelContainer.new()
	kartu.add_theme_stylebox_override("panel", GH.kaca(0.45, 12, Vector4(14, 10, 14, 10)))
	kartu.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	kartu.size_flags_stretch_ratio = 1.0
	wadah.add_child(kartu)
	var isi: = VBoxContainer.new()
	kartu.add_child(isi)
	for baris in [[judul, 20, GH.KUNING], [nilai, 40 if nilai.length() < 14 else 30, (GH.HIJAU_UANG if warna == Color(0.27, 0.7, 0.33) else (Color(1, 0.5, 0.45) if warna == Color(0.75, 0.2, 0.15) else Color.WHITE))], [sub, 17, Color(1, 1, 1, 0.85)]]:
		if String(baris[0]) == "":
			continue
		var l: = Label.new()
		l.text = baris[0]
		GH.gaya_label(l, baris[1], baris[2], baris[1] >= 20 and baris[2] != Color(1, 1, 1, 0.85))
		isi.add_child(l)


func _judul_kecil(teks: String) -> Label:
	var l: = Label.new()
	l.text = teks
	GH.gaya_label(l, 26, GH.KUNING, true)
	return l



func _gaya_rekap() -> void :
	panel_tutup.add_theme_stylebox_override("panel", GH.bingkai_emas(Vector4(28, 20, 28, 22)))
	GH.pasang_muncul(panel_tutup, 0.95, 0.4)
	GH.gaya_label(judul_tutup, 48, GH.KUNING, true)
	GH.gaya_label(keterangan_tutup, 20, GH.KUNING)
	keterangan_tutup.add_theme_font_size_override("font_size", 20)
	(panel_tutup.get_node("Isi/Garis") as Control).hide()
	GH.gaya_tombol_emas(tombol_lanjut, true, 38)


func _on_lanjut_ditekan() -> void :
	if GameState.sedang_banjir() and not GameState.bangkrut:
		_kabari_banjir()
		return
	if GameState.bangkrut:

		if GameState.akun != null:
			GameState.akun.lupakan_kemajuan()
		GameState.arsipkan_slot_bangkrut(GameState.slot_aktif)
		GameState.sedang_main = false
		GameState.ganti_layar(self, "res://scenes/main_menu.tscn")
		return



	if GameState.tutorial_langkah == "keluar":
		GameState.tutorial_langkah = "pulang"

	var id: = GameState.kerja_hari_ini()
	if not GameState.mode_latihan and id != "" and GameState.kerja_tersedia(id) and not _kerja_dikabari.has("%s:%d" % [id, GameState.hari]):
		_kerja_dikabari["%s:%d" % [id, GameState.hari]] = true
		var k: Dictionary = GameState.data_kerja(id)
		var isi: = _buka_jendela("Kerja sampingan tersedia", 560)
		_teks_jendela(isi, "%s butuh bantuan sekarang. %s\nReward %s, sampai pukul %02d.%02d." % [String(k["nama"]), String(k["teks"]), 
			GameState.format_rupiah(GameState.upah_kerja(id)), int(k["jam"][1]), int(fmod(float(k["jam"][1]), 1.0) * 60.0)])
		_tombol_kejadian(isi, [
			["Pergi ke sana", &"TombolHijau", func(): _pergi_kerja(id)], 
			["Nanti", &"TombolKayu", _on_lanjut_ditekan], 
		])
		return
	GameState.simpan()
	GameState.tujuan_jelajah = {"area": "warung", "muncul": "depan_warung"}
	GameState.ganti_layar(self, "res://scenes/jelajah.tscn")


func _on_kecepatan_ditekan() -> void :
	indeks_kecepatan = (indeks_kecepatan + 1) % PILIHAN_KECEPATAN.size()
	tombol_kecepatan.text = "x%d" % PILIHAN_KECEPATAN[indeks_kecepatan]



func _on_menu_ditekan() -> void :
	if dialog_aktif:
		return
	var isi: = _buka_jendela("Permainan dijeda", 460)
	var lapisan: Control = isi.get_meta("lapisan")
	var tutup: = func():
		dialog_aktif = false
		lapisan.queue_free()
	for t in [["Lanjutkan", &"TombolHijau", tutup], 
			["Simpan", &"TombolKayu", func():
				tutup.call()
				GameState.simpan()
				tampilkan_pesan("Tersimpan: %s, %s, di warung." % [GameState.nama_hari(), GameState.teks_jam()])], 
			["Panduan", &"TombolKayu", func(): tutup.call();buka_hp("panduan")], 
			["Pengaturan", &"TombolKayu", func(): tutup.call();_buka_pengaturan()], 
			["Dukung Kami", &"TombolKayu", func(): tutup.call();_buka_dukungan()], 
			["Simpan & ke Menu Utama", &"TombolKayu", _ke_menu_utama]]:
		var b: = Button.new()
		b.text = t[0]
		b.theme_type_variation = t[1]
		b.custom_minimum_size = Vector2(0, 70)
		b.add_theme_font_size_override("font_size", 26)
		b.pressed.connect(t[2])
		isi.add_child(b)
	var catatan: = Label.new()
	catatan.text = GameState.teks_simpan_terakhir()
	catatan.add_theme_font_size_override("font_size", 16)
	catatan.add_theme_color_override("font_color", Color(GH.KREM, 0.75))
	catatan.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	isi.add_child(catatan)
	var kode_w: = GameState.tombol_kode_warung()
	if kode_w != null:
		isi.add_child(kode_w)



func _buka_dukungan() -> void :
	dialog_aktif = true
	var d: = preload("res://scripts/dukungan.gd").new()
	akar_ui.add_child(d)
	await d.ditutup
	dialog_aktif = false



func _buka_papan_besar() -> void :
	dialog_aktif = true
	var d: = preload("res://scripts/papan_besar.gd").new()
	akar_ui.add_child(d)
	await d.ditutup
	dialog_aktif = false


func _ke_menu_utama() -> void :
	GameState.simpan()
	GameState.sedang_main = false
	GameState.ganti_layar(self, "res://scenes/main_menu.tscn")




var kotak_pesan: PanelContainer
var _teks_pesan_lalu: = ""
const LEBAR_PESAN: = 600.0



const BAWAH_PESAN: = -248.0
var _tw_pesan: Tween = null

func _bawah_pesan(tinggi: float) -> float:
	var g: Control = $Layanan.gelembung if has_node("Layanan") else null
	if g == null or not g.is_visible_in_tree():
		return BAWAH_PESAN
	var h: float = get_viewport().get_visible_rect().size.y
	var r: Rect2 = g.get_global_rect()
	var bawah_kotak: = h + BAWAH_PESAN
	if r.end.y > bawah_kotak - tinggi - 8.0 and r.position.y < bawah_kotak + 8.0:
		return minf(BAWAH_PESAN, r.position.y - 10.0 - h)
	return BAWAH_PESAN


func _jauhkan_pesan_dari_gelembung() -> void :
	if kotak_pesan == null or not kotak_pesan.visible or (_tw_pesan != null and _tw_pesan.is_running()):
		return
	var tinggi: = kotak_pesan.offset_bottom - kotak_pesan.offset_top
	var tujuan: = _bawah_pesan(tinggi)
	if absf(kotak_pesan.offset_bottom - tujuan) < 0.5:
		return
	kotak_pesan.offset_bottom = lerpf(kotak_pesan.offset_bottom, tujuan, 0.3)
	kotak_pesan.offset_top = kotak_pesan.offset_bottom - tinggi


func _perbarui_kotak_pesan() -> void :
	if kotak_pesan == null:
		kotak_pesan = PanelContainer.new()
		kotak_pesan.add_theme_stylebox_override("panel", GH.kartu_notif(0.78, Vector4(28, 10, 26, 12)))
		kotak_pesan.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var induk: = pesan.get_parent()
		induk.add_child(kotak_pesan)
		induk.move_child(kotak_pesan, pesan.get_index())
		pesan.reparent(kotak_pesan, false)
		GH.gaya_label(pesan, 18, GH.KUNING)
		kotak_pesan.hide()
	if pesan.text == _teks_pesan_lalu:
		_jauhkan_pesan_dari_gelembung()
		return
	_teks_pesan_lalu = pesan.text
	kotak_pesan.visible = pesan.text != ""
	if pesan.text == "":
		return

	var lebar: = pesan.get_theme_font("font").get_string_size(pesan.text, HORIZONTAL_ALIGNMENT_LEFT, -1, pesan.get_theme_font_size("font_size")).x
	pesan.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART if lebar > LEBAR_PESAN else TextServer.AUTOWRAP_OFF
	pesan.custom_minimum_size = Vector2(LEBAR_PESAN if lebar > LEBAR_PESAN else 0.0, 0)
	pesan.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	kotak_pesan.reset_size()
	var ukuran: = kotak_pesan.get_combined_minimum_size()
	kotak_pesan.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	kotak_pesan.offset_left = - ukuran.x / 2.0
	kotak_pesan.offset_right = ukuran.x / 2.0
	var bawah: = _bawah_pesan(ukuran.y)
	kotak_pesan.offset_bottom = bawah
	kotak_pesan.offset_top = bawah - ukuran.y

	kotak_pesan.pivot_offset = ukuran / 2.0
	kotak_pesan.scale = Vector2(0.55, 0.55)
	kotak_pesan.modulate.a = 0.0
	kotak_pesan.offset_top += 14.0
	kotak_pesan.offset_bottom += 14.0
	var tw: = kotak_pesan.create_tween().set_parallel(true)
	_tw_pesan = tw
	tw.tween_property(kotak_pesan, "scale", Vector2.ONE, 0.32).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(kotak_pesan, "modulate:a", 1.0, 0.25).set_trans(Tween.TRANS_SINE)
	tw.tween_property(kotak_pesan, "offset_top", bawah - ukuran.y, 0.38).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(kotak_pesan, "offset_bottom", bawah, 0.38).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)



func tampilkan_pesan(teks: String, lama: = 3.0) -> void :
	pesan.text = teks
	await GameState.get_tree().create_timer(lama).timeout
	if pesan.text == teks:
		pesan.text = ""



func _perbarui_tugas() -> void :
	var t: = GameState.tugas_sekarang()
	var isi: = GameState.baris_tugas()
	var beres: = 0
	for baris in isi:
		if baris[1] >= baris[2]:
			beres += 1
	judul_tugas.text = "LEVEL WARUNG   %s" % ("▴" if tugas_terbuka else "▾")
	if _angka_level != null:
		_angka_level.text = str(GameState.tingkat + 1)
		_bar_level.set_meta("isi", beres / float(maxi(isi.size(), 1)))
		_bar_level.queue_redraw()
		_teks_bar_level.text = "%d/%d TUGAS" % [beres, isi.size()]
	if baris_tugas.size() != isi.size():
		_buat_baris_tugas(isi.size())
	for i in isi.size():
		var b: Dictionary = baris_tugas[i]
		var selesai: bool = isi[i][1] >= isi[i][2]
		b["nama"].text = isi[i][0]
		b["misi_utama"].visible = i == 0 and GameState.misi_status in ["menunggu", "aktif", "lunas"]

		if i == 0:
			b["nama"].custom_minimum_size.x = ceilf(b["nama"].get_theme_font("font").get_string_size(isi[i][0], HORIZONTAL_ALIGNMENT_LEFT, -1, b["nama"].get_theme_font_size("font_size")).x) + 2.0
		b["angka"].text = "selesai" if selesai else isi[i][3]
		b["bar"].max_value = isi[i][2]
		b["bar"].value = mini(isi[i][1], isi[i][2])
		b["isi"].bg_color = Color(0.27, 0.7, 0.33) if selesai else Color(0.96, 0.62, 0.18)
	label_tugas.text = "Hadiah: %s" % GameState.format_rupiah(t["hadiah"])
	if GameState.kekurangan_kiriman() > 0:
		label_tugas.text += "\nCara kirim: buka HP, Warga Bank, kirim ke %s" % GameState.nama_penerima()
	if GameState.segera_hadir():
		label_tugas.text = "Segera hadir!\nLevel %d sedang disiapkan." % GameState.level()
	_terapkan_tugas_ringkas()


func _terapkan_tugas_ringkas() -> void :
	for b in baris_tugas:
		b["kolom"].visible = tugas_terbuka
	label_tugas.visible = tugas_terbuka
	if petunjuk_tugas != null:
		petunjuk_tugas.visible = tugas_terbuka
	var panel: Control = label_tugas.get_parent().get_parent()


	panel.self_modulate.a = 1.0
	if _angka_level != null:

		panel.add_theme_stylebox_override("panel", GH.kaca(0.95 if tugas_terbuka else 0.6, 8, Vector4(10, 8, 16, 10)))
		panel.z_index = 2 if tugas_terbuka else 0

	panel.offset_right = _kanan_panel_level()
	panel.offset_left = panel.offset_right - 1.0
	panel.offset_bottom = panel.offset_top + 1.0




func _buat_baris_tugas(jumlah: int) -> void :
	for b in baris_tugas:
		b["kolom"].queue_free()
	baris_tugas.clear()
	var wadah: = label_tugas.get_parent()
	for i in jumlah:
		var kolom: = VBoxContainer.new()
		kolom.add_theme_constant_override("separation", 3)
		wadah.add_child(kolom)
		wadah.move_child(kolom, label_tugas.get_index())

		var misi_utama: = GH.label("MISI UTAMA", 22, GH.KUNING, true)
		misi_utama.hide()
		kolom.add_child(misi_utama)
		var atas: = HBoxContainer.new()
		kolom.add_child(atas)
		var nama: = Label.new()
		GH.gaya_label(nama, 20, Color.WHITE)
		GH.tebal(nama)
		nama.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		nama.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		nama.custom_minimum_size.x = 60
		atas.add_child(nama)
		var angka: = Label.new()
		angka.add_theme_font_size_override("font_size", 16)
		GH.gaya_label(angka, 21, GH.KUNING, true)
		GH.tebal(angka)
		atas.add_child(angka)
		var bar: = ProgressBar.new()
		bar.show_percentage = false
		bar.custom_minimum_size = Vector2(0, 16)
		bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var latar_bar: = StyleBoxFlat.new()
		latar_bar.bg_color = Color(1, 1, 1, 0.22)
		latar_bar.border_color = Color(1, 1, 1, 0.35)
		latar_bar.set_border_width_all(1)
		latar_bar.set_corner_radius_all(7)
		var isi_bar: = StyleBoxFlat.new()
		isi_bar.set_corner_radius_all(7)
		bar.add_theme_stylebox_override("background", latar_bar)
		bar.add_theme_stylebox_override("fill", isi_bar)
		kolom.add_child(bar)
		baris_tugas.append({"nama": nama, "angka": angka, "bar": bar, "isi": isi_bar, "kolom": kolom, "misi_utama": misi_utama})
	label_tugas.add_theme_font_size_override("font_size", 18)


func _on_tugas_selesai(hadiah: int, _tingkat_baru: int) -> void :
	uang_melayang("Hadiah +" + GameState.format_rupiah(hadiah), true)
	var panel: Control = label_tugas.get_parent().get_parent()
	panel.pivot_offset = panel.size / 2.0
	var tween: = panel.create_tween()
	tween.tween_property(panel, "scale", Vector2(1.08, 1.08), 0.15)
	tween.tween_property(panel, "scale", Vector2.ONE, 0.25)
	tampilkan_naik_level()





var _popup_naik_tampil: = false

func tampilkan_naik_level() -> void :
	if _popup_naik_tampil:
		return
	_popup_naik_tampil = true
	await get_tree().process_frame
	var tunggu: = 0
	while not GameState.naik_level_tertunda.is_empty():

		if dialog_aktif or not GameState.dialog_tertunda.is_empty():
			tunggu += 1
			if not dialog_aktif and tunggu > 6 and GameState.nama_warung != "":
				$UI / Akar / CeritaUI.tampilkan_dialog_tertunda()
			await GameState.get_tree().create_timer(0.3).timeout
			continue
		var naik: Dictionary = GameState.naik_level_tertunda.pop_front()


		dialog_aktif = true
		var isi: Array = GameState.isi_popup_naik(naik)
		var popup: = preload("res://scripts/popup_hadiah.gd").new()
		akar_ui.add_child(popup)
		popup.isi(isi[0], isi[1], isi[2])
		await popup.ditutup

		await GameState.tampilkan_iklan_selingan(akar_ui)

		var level_baru: = int(naik["level"])
		if not GameState.data_tingkat(level_baru - 1).get("segera_hadir", false):
			var kartu: = preload("res://scripts/judul_level.gd").new()
			akar_ui.add_child(kartu)
			kartu.tampil(level_baru, String(GameState.data_tingkat(level_baru - 1).get("nama", "")))
			await kartu.selesai
		dialog_aktif = false
	_popup_naik_tampil = false


	var cv: = preload("res://scripts/cek_versi.gd")
	if cv.di_ios() and not cv.toko_ios_siap():
		return
	if GameState.level() >= 2 and not GameState.ajak_rating_sudah:
		GameState.ajak_rating_sudah = true
		_ajak_rating()



const URL_PLAY_STORE: = "market://details?id=com.neopawstudio.warunglife"
const URL_PLAY_STORE_WEB: = "https://play.google.com/store/apps/details?id=com.neopawstudio.warunglife"

func _ajak_rating() -> void :
	var isi: = _buka_jendela("Suka dengan Warung Life?", 600)
	_teks_jendela(isi, "Terima kasih sudah membantu Pak Misran sampai sejauh ini! Kalau kamu menikmati permainannya, bantu kami dengan memberi rating dan ulasan di Play Store. Itu sangat berarti untuk tim kecil kami.")
	_tombol_kejadian(isi, [
		["Beri rating", &"TombolHijau", func():
			preload("res://scripts/cek_versi.gd").buka_play_store()], 
		["Nanti saja", &"TombolKayu", func(): pass], 
	])
	GameState.simpan()






func _sesuaikan_latar() -> void :
	var layar: = get_viewport_rect().size
	var ukuran: = latar.texture.get_size()
	var rasio: = layar.x / layar.y

	var penuh: = Rect2(Vector2.ZERO, ukuran)
	if ukuran.x / ukuran.y > rasio:
		penuh = Rect2((ukuran.x - ukuran.y * rasio) / 2.0, 0, ukuran.y * rasio, ukuran.y)
	else:
		penuh = Rect2(0, (ukuran.y - ukuran.x / rasio) / 2.0, ukuran.x, ukuran.x / rasio)
	var fokus: = penuh
	if LATAR_LUAS:

		var tengah: = FOKUS_WARUNG.get_center()
		var lebar: = minf(lebar_pandang, minf(ukuran.x, ukuran.y * rasio))
		fokus = Rect2(tengah.x - lebar / 2.0, tengah.y - lebar / rasio / 2.0, lebar, lebar / rasio)

		geser_kamera = geser_kamera.clamp( - GESER_MAKS, GESER_MAKS)
		var pos: = fokus.position + geser_kamera
		pos.x = clampf(pos.x, 0.0, ukuran.x - fokus.size.x)
		pos.y = clampf(pos.y, 0.0, ukuran.y - fokus.size.y)
		geser_kamera = pos - fokus.position
		fokus.position = pos
	var t: = ease(zoom_kamera, -2.2)
	var lihat: = Rect2(penuh.position.lerp(fokus.position, t), penuh.size.lerp(fokus.size, t))
	var skala: = layar.x / lihat.size.x
	latar.scale = Vector2(skala, skala)
	latar.position = layar / 2.0 - (lihat.get_center() - ukuran / 2.0) * skala



func _putar_intro() -> void :
	GameState.putar_intro = false
	akar_ui.modulate.a = 0.0
	dialog_aktif = true
	var tween: = create_tween()
	tween.tween_interval(0.8)
	tween.tween_method( func(t: float): zoom_kamera = t;_sesuaikan_latar(), 0.0, 1.0, 3.2)
	tween.tween_property(akar_ui, "modulate:a", 1.0, 0.5)
	await tween.finished
	dialog_aktif = false
	intro_selesai.emit()



const POSISI_AGUS: = Vector2(95, -30)


func _pasang_bapak_3d() -> void :
	bapak_3d = Sprite2D.new()
	bapak_3d.set_script(SCRIPT_PELANGGAN)
	bapak_3d.tinggi_dewasa_latar = TINGGI_DEWASA_LATAR_LUAS
	%WadahPelanggan.add_child(bapak_3d)
	bapak_3d.position = %PosisiBapak.position
	bapak_3d.atur_3d(GameState.cfg_penjaga({"file": GameState.file_model_penjaga(), "skala": GameState.skala_penjaga(), "anim_jalan": "Walking", "anim_diam": "Idle_11"}), %TitikPelanggan.position.y)
	bapak_3d.modulate = cahaya_karakter
	bapak_3d.hadap( %TitikPelanggan.position - %PosisiBapak.position)


	bapak_3d.karakter.process_mode = Node.PROCESS_MODE_ALWAYS

	bapak_3d.karakter.boleh_payung = false

	if GameState.agus_membantu():
		var agus: = _buat_tokoh("agus", %PosisiBapak.position + POSISI_AGUS)
		if agus != null:
			agus.hadap( %TitikPelanggan.position - agus.position)
			agus.karakter.process_mode = Node.PROCESS_MODE_ALWAYS
			agus.karakter.boleh_payung = false



func _pasang_nama_warung() -> void :

	label_nama_warung = SCRIPT_TEKS_TENGAH.new()
	label_nama_warung.size = PAPAN_NAMA.size

	var papan: = Node2D.new()
	papan.transform = Transform2D(Vector2(1, KEMIRINGAN_PAPAN), Vector2(0, 1), PAPAN_NAMA.position - latar.texture.get_size() / 2.0)
	latar.add_child(papan)
	papan.add_child(label_nama_warung)
	perbarui_nama_warung()



func perbarui_nama_warung() -> void :
	if label_nama_warung == null:
		return
	label_nama_warung.atur(font_papan, [[GameState.nama_warung.to_upper(), WARNA_NAMA_PAPAN, ukuran_nama_papan(PAPAN_NAMA.size)]], PAPAN_NAMA.size)


const SCRIPT_TEKS_TENGAH: = preload("res://scripts/teks_tengah.gd")
const WARNA_NAMA_PAPAN: = Color(0.72, 0.13, 0.13)


static func ukuran_nama_papan(papan: Vector2) -> int:
	return int(papan.y * 0.5 / SCRIPT_TEKS_TENGAH.TINGGI_KAPITAL)




func _pasang_karakter(sprite: Sprite2D, gambar: Texture2D, tinggi: float) -> void :
	sprite.texture = gambar
	sprite.offset = Vector2(0, - gambar.get_height() / 2.0)
	var skala: = tinggi / gambar.get_height()
	sprite.scale = Vector2(skala, skala)



func _on_stok_ditekan() -> void :
	panel_stok_hud.visible = not panel_stok_hud.visible
	_atur_kolom_stok()
	_perbarui_tombol_stok()




func _atur_kolom_stok() -> void :
	if not panel_stok_hud.visible:
		return
	var jumlah: = 0
	var tinggi_baris: = 0.0
	for id in label_nama_stok:
		var nama: Label = label_nama_stok[id]
		if nama.visible:
			jumlah += 1
			tinggi_baris = maxf(tinggi_baris, nama.get_combined_minimum_size().y)
	var tinggi_maks: float = get_viewport().get_visible_rect().size.y + panel_stok_hud.offset_bottom - BATAS_ATAS_PANEL_STOK
	var tinggi_lain: float = panel_stok_hud.get_combined_minimum_size().y - grid_stok.get_combined_minimum_size().y
	var kolom: = 1
	while kolom < MAKS_KOLOM_STOK and tinggi_lain + ceili(float(jumlah) / kolom) * tinggi_baris > tinggi_maks:
		kolom += 1
	grid_stok.columns = kolom * 2
	grid_stok.add_theme_constant_override("h_separation", 12 if kolom == 1 else 26)
	panel_stok_hud.offset_left = panel_stok_hud.offset_right - 1.0
	panel_stok_hud.offset_top = panel_stok_hud.offset_bottom - 1.0



func _perbarui_tombol_stok() -> void :
	var menipis: = 0
	for id in GameState.barang_belanja().filter(GameState.terbuka):
		if GameState.stok[id] <= BATAS_STOK_MENIPIS:
			menipis += 1
	if lencana_stok != null:
		UI_HP.atur_lencana(lencana_stok, menipis)




func _tutup_panel_lipat() -> void :
	if panel_stok_hud.visible and _dock != null:
		panel_stok_hud.hide()
	if tugas_terbuka:
		tugas_terbuka = false
		_perbarui_tugas()
	var lay: = $Layanan
	for k in lay._rak:
		if lay._rak[k].get("terbuka", false):
			lay._lipat_rak(k, false)





func atur_pose_kasir(pose: String) -> void :
	if LATAR_LUAS:

		if pose == "melayani" and bapak_3d != null and bapak_3d.karakter != null:
			bapak_3d.karakter.mainkan_sekali(ANIM_BAPAK_MELAYANI)
		return
	var nama: = "%s_%s" % [GameState.penjaga, pose]
	var posisi_kasir: = {}
	if FileAccess.file_exists(FILE_KASIR):
		posisi_kasir = JSON.parse_string(FileAccess.get_file_as_string(FILE_KASIR))
	var file_gambar: = "res://assets/karakter/kasir_%s.png" % nama
	var pakai_kasir: = posisi_kasir.has(nama) and ResourceLoader.exists(file_gambar)
	kasir.visible = pakai_kasir
	penjaga.visible = not pakai_kasir
	meja_depan.visible = not pakai_kasir
	if pakai_kasir:
		kasir.texture = load(file_gambar)
		var p: Array = posisi_kasir[nama]
		kasir.position = - latar.texture.get_size() / 2.0 + Vector2(p[0], p[1])
	else:
		var file_lama: = "res://assets/karakter/penjaga_%s_%s.png" % [GameState.penjaga, pose]
		if not ResourceLoader.exists(file_lama):
			file_lama = "res://assets/karakter/penjaga_%s_diam.png" % GameState.penjaga
		_pasang_karakter(penjaga, load(file_lama), tinggi_penjaga)



var _waktu_melayang: = -100000
var _tumpuk_melayang: = 0

func uang_melayang(teks: String, di_tengah: = false) -> void :
	var label: = Label.new()
	label.text = teks
	label.theme_type_variation = &"LabelUang"
	label.add_theme_font_size_override("font_size", 40)
	akar_ui.add_child(label)

	if bapak_3d != null:
		label.position = bapak_3d.global_position + Vector2(30, -150)
	else:
		label.position = kasir.get_global_transform() * (kasir.get_rect().get_center()) + Vector2(50, -30)
	if di_tengah:
		label.add_theme_font_size_override("font_size", 56)
		label.position = Vector2(get_viewport_rect().size.x / 2.0 - 230.0, 330.0)

	var sekarang: = Time.get_ticks_msec()
	_tumpuk_melayang = _tumpuk_melayang + 1 if sekarang - _waktu_melayang < 900 else 0
	_waktu_melayang = sekarang
	label.position.y -= 58.0 * (_tumpuk_melayang % 3)
	var tween: = label.create_tween().set_parallel()
	tween.tween_property(label, "position:y", label.position.y - 90, 1.2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(label, "modulate:a", 0.0, 0.5).set_delay(0.8)
	await tween.finished
	label.queue_free()

	var pil: Control = label_uang.get_parent().get_parent()
	pil.pivot_offset = pil.size / 2.0
	var denyut: = pil.create_tween()
	denyut.tween_property(pil, "scale", Vector2(1.12, 1.12), 0.1)
	denyut.tween_property(pil, "scale", Vector2.ONE, 0.15)



func perbarui_redup() -> void :
	var panel_kirim_terbuka: bool = has_node("UI/Akar/CeritaUI") and $UI / Akar / CeritaUI._panel_kirim != null and $UI / Akar / CeritaUI._panel_kirim.visible
	redup.visible = panel_terbuka() or panel_tutup.visible or panel_kirim_terbuka

	if has_node("UI/Akar/CeritaUI"):
		$UI / Akar / CeritaUI.atur_tampil_target( not (panel_terbuka() or panel_tutup.visible))


func _cek_sholat_jumat() -> void :
	if not LATAR_LUAS or bapak_3d == null or GameState.nama_hari() != "Jumat" or not GameState.ikut_ronda_jumatan():
		return

	if GameState.sedang_banjir() and not sedang_sholat:
		return
	if not sedang_sholat and not sholat_hari_ini and GameState.jumatan_hari != GameState.hari and GameState.menit >= JAM_SHOLAT and GameState.menit < JAM_SELESAI_SHOLAT:
		_mulai_sholat()
	elif sedang_sholat and GameState.menit >= JAM_SELESAI_SHOLAT:
		_selesai_sholat()


func _ke_lokal(titik_latar: Vector2) -> Vector2:
	return titik_latar - latar.texture.get_size() / 2.0



signal jumatan_dipilih(ikut: bool)

func _mulai_sholat() -> void :
	sedang_sholat = true
	sholat_hari_ini = true
	GameState.putar_adzan()
	panel_belanja.hide()
	hp.tutup()
	tampilkan_pesan("Pukul 11.30, Haji Doni datang mengajak Sholat Jumat.", 5.0)
	var jalur: Array = []
	for t in JALUR_MASJID:
		jalur.append(_ke_lokal(t))

	var haji: = _buat_haji_doni(jalur[-1])
	if haji != null:
		var jalur_datang: Array = jalur.duplicate()
		jalur_datang.reverse()
		jalur_datang.pop_front()
		jalur_datang = jalur_datang.slice(0, jalur_datang.size() - TITIK_TUNGGU_HAJI)
		jalur_datang[-1] += GESER_TUNGGU_HAJI
		haji.jalan(jalur_datang, 120.0)
		await haji.sampai
		haji.hadap(bapak_3d.position - haji.position)
		haji.aksi("bicara")
		await _ucap(haji, "Assalamualaikum! Ayo, Pak Misran, Jumatan dulu, sudah adzan.", 2.6)
		bapak_3d.hadap(haji.position - bapak_3d.position)

	var isi: = _buka_jendela("Ajakan Sholat Jumat", 640)
	_teks_jendela(isi, "Haji Doni mengajak Pak Misran Sholat Jumat ke masjid." if GameState.warung_libur() else "Haji Doni mengajak Pak Misran Sholat Jumat ke masjid. Kalau ikut, warung tutup sampai pukul 13.00.")
	_tombol_kejadian(isi, [
		["Nanti saja" if GameState.warung_libur() else "Tetap jaga warung", &"TombolKayu", func(): jumatan_dipilih.emit(false)], 
		["Ikut Jumatan", &"TombolHijau", func(): jumatan_dipilih.emit(true)], 
	])
	var ikut: bool = await jumatan_dipilih
	GameState.jumatan_hari = GameState.hari
	if not ikut:
		sedang_sholat = false
		GameState.ulasan_warga(1, "Pas Jumatan warungnya malah tetap buka. Pak Misran nggak ke masjid.", "Haji Doni", 2)
		GameState.data_berubah.emit()
		if haji != null:
			await _ucap(bapak_3d, "Maaf, Haji Doni. Hari ini saya jaga warung dulu.", 2.2, 118.0)
			haji.aksi("bicara")
			await _ucap(haji, "Astaghfirullah... Ya sudah, Pak. Semoga Allah memudahkan.", 2.6)
			var jalur_pulang: Array = []
			for i in range(TITIK_TUNGGU_HAJI + 1, jalur.size()):
				jalur_pulang.append(jalur[i] + Vector2(18, 10))
			haji.pergi_pelan(jalur_pulang, 118.0)
		tampilkan_pesan("Pak Misran tidak ikut Jumatan. Warga yang tahu jadi kecewa: reputasi turun.", 5.0)
		return
	GameState.ulasan_warga(5, "Pak Misran rajin Jumatan, warungnya ditutup dulu. Salut!")
	GameState.data_berubah.emit()
	if not GameState.warung_libur():
		$Layanan.bubarkan_semua("Oh, Bapak mau Jumatan ya. Nanti saya balik lagi, Pak.")
		tampilkan_pesan("Warung tutup sampai 13.00.", 4.0)
	if haji != null:

		await _ucap(bapak_3d, "Waalaikumsalam, Haji Doni. Ayo, saya tutup warung dulu.", 2.2, 118.0)

		var jalur_haji: Array = []
		for i in range(TITIK_TUNGGU_HAJI + 1, jalur.size()):
			jalur_haji.append(jalur[i] + Vector2(18, 10))
		haji.pergi_pelan(jalur_haji, 118.0)
		await GameState.get_tree().create_timer(0.5).timeout
	else:
		await GameState.get_tree().create_timer(1.2).timeout
	bapak_3d.jalan(jalur, 120.0)
	await bapak_3d.sampai
	var tween: = bapak_3d.create_tween()
	tween.tween_property(bapak_3d, "modulate:a", 0.0, 0.6)
	await tween.finished

	var tabir: = ColorRect.new()
	tabir.color = Color(0.04, 0.03, 0.02)
	tabir.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tabir.mouse_filter = Control.MOUSE_FILTER_STOP
	tabir.modulate.a = 0.0
	akar_ui.add_child(tabir)
	var tulisan: = Label.new()
	tulisan.text = "Pak Misran sedang Sholat Jumat...\n\nKembali ke warung pukul 13.00"
	tulisan.theme_type_variation = &"LabelKepala"
	tulisan.add_theme_font_size_override("font_size", 38)
	tulisan.add_theme_color_override("font_color", Color(1, 0.92, 0.75))
	tulisan.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tulisan.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	tulisan.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tabir.add_child(tulisan)
	var gelap: = tabir.create_tween()
	gelap.tween_property(tabir, "modulate:a", 1.0, 0.8)
	gelap.tween_interval(2.4)
	await gelap.finished
	if GameState.menit < JAM_SELESAI_SHOLAT:
		GameState.majukan_waktu(JAM_SELESAI_SHOLAT - GameState.menit)
	_cek_sholat_jumat()
	var terang: = tabir.create_tween()
	terang.tween_property(tabir, "modulate:a", 0.0, 0.8)
	terang.tween_callback(tabir.queue_free)



func _buat_haji_doni(posisi: Vector2) -> Sprite2D:
	return _buat_tokoh("haji_doni", posisi)


func _buat_tokoh(id: String, posisi: Vector2) -> Sprite2D:
	var data = JSON.parse_string(FileAccess.get_file_as_string("res://data/pelanggan.json"))
	var tokoh: Dictionary = data.get("tokoh", {}).get(id, {})
	if tokoh.is_empty():
		return null
	var orang: = Sprite2D.new()
	orang.set_script(SCRIPT_PELANGGAN)
	orang.modulate = cahaya_karakter
	orang.tinggi_dewasa_latar = TINGGI_DEWASA_LATAR_LUAS
	%WadahPelanggan.add_child(orang)
	orang.position = posisi
	orang.atur_3d(tokoh["model3d"], %TitikPelanggan.position.y)
	return orang




func _ucap(orang: Sprite2D, teks: String, detik: float, tinggi_kepala: = -1.0) -> void :
	if tinggi_kepala < 0.0:
		tinggi_kepala = orang.tinggi_badan()
	var kotak: = PanelContainer.new()
	var gaya: = StyleBoxFlat.new()
	gaya.bg_color = Color(1, 0.98, 0.93)
	gaya.set_corner_radius_all(12)
	gaya.set_content_margin_all(10)
	gaya.border_color = Color(0.4, 0.28, 0.16)
	gaya.set_border_width_all(2)
	kotak.add_theme_stylebox_override("panel", gaya)
	kotak.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var label: = Label.new()
	label.text = teks
	label.add_theme_font_size_override("font_size", 19)
	label.add_theme_color_override("font_color", Color(0.25, 0.15, 0.08))
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size.x = 300
	kotak.add_child(label)
	akar_ui.add_child(kotak)
	var sisa: = detik
	while sisa > 0.0 and is_instance_valid(orang):
		var kepala: = latar.get_global_transform() * (orang.position - Vector2(0, tinggi_kepala + 12))
		kotak.position = kepala - Vector2(kotak.size.x / 2.0, kotak.size.y)
		await get_tree().process_frame
		sisa -= get_process_delta_time()
	kotak.queue_free()


func _selesai_sholat() -> void :
	sedang_sholat = false
	var tween: = bapak_3d.create_tween()
	tween.tween_property(bapak_3d, "modulate:a", 1.0, 0.5)
	var jalur: Array = []
	for i in range(JALUR_MASJID.size() - 2, -1, -1):
		jalur.append(_ke_lokal(JALUR_MASJID[i]))
	jalur.append( %PosisiBapak.position)
	bapak_3d.jalan(jalur, 120.0)
	tampilkan_pesan("Pak Misran sudah kembali. Warung buka lagi!" if GameState.status_hari == "buka" else "Pak Misran sudah kembali dari masjid.", 3.0)
	await bapak_3d.sampai
	bapak_3d.hadap( %TitikPelanggan.position - %PosisiBapak.position)








const TAHAN_KIRIMAN_MAKS: = 6.0
var _kiriman_tertahan: = 0.0


var _kiriman_macet: = 0.0
const KIRIMAN_MACET_MAKS: = 20.0

func _proses_kiriman(delta: float) -> void :
	_perbarui_bar_kiriman()
	if truk != null and not is_instance_valid(truk):
		truk = null
	if kurir != null and not is_instance_valid(kurir):
		kurir = null
	if tamu_kiriman != null and not is_instance_valid(tamu_kiriman):
		tamu_kiriman = null

	if GameState.kurir_dalam_perjalanan and truk == null and kurir == null and not GameState.kiriman_stok.is_empty()\
	and GameState.detik_kiriman <= 0.0 and not dialog_aktif and not panel_terbuka():
		_kiriman_tertahan += delta
		if _kiriman_tertahan > TAHAN_KIRIMAN_MAKS * 2.0:
			_kiriman_tertahan = 0.0
			var kiriman_tadi: Dictionary = GameState.kiriman_stok.duplicate()
			GameState.terima_kiriman()
			_lajur_kurir_ditahan = false
			notifikasi_stok(kiriman_tadi)
		return
	if GameState.kurir_dalam_perjalanan or GameState.detik_kiriman <= 0.0:
		_kiriman_tertahan = 0.0
		return

	if dialog_aktif or panel_terbuka():
		return


	if GameState.status_hari == "tutup":
		GameState.detik_kiriman -= delta
		if GameState.detik_kiriman <= 0.0:
			var kiriman_tadi: Dictionary = GameState.kiriman_stok.duplicate()
			GameState.terima_kiriman()
			notifikasi_stok(kiriman_tadi)
		return
	var aset_siap: = _muat_aset_kurir()

	if GameState.detik_kiriman <= delta and (tamu_kiriman != null or truk != null or not aset_siap) and not _jalan_ditutup_banjir():
		_kiriman_macet += delta
		if _kiriman_macet > KIRIMAN_MACET_MAKS:
			_kiriman_macet = 0.0
			var kiriman_tadi: Dictionary = GameState.kiriman_stok.duplicate()
			GameState.detik_kiriman = 0.0
			GameState.terima_kiriman()
			notifikasi_stok(kiriman_tadi)
			return
	else:
		_kiriman_macet = 0.0

	if tamu_kiriman != null and GameState.detik_kiriman <= delta:
		return




	if truk != null and GameState.detik_kiriman <= delta:
		_kiriman_tertahan = 0.0
		GameState.detik_kiriman = 0.0
		var kiriman_ikut: Dictionary = GameState.kiriman_stok.duplicate()
		GameState.terima_kiriman()
		GameState.bunyi("kurir")
		notifikasi_stok(kiriman_ikut)
		return

	if not aset_siap and GameState.detik_kiriman <= delta:
		return
	_kiriman_tertahan = 0.0

	if _jalan_ditutup_banjir() and GameState.detik_kiriman <= 60.0:
		return
	GameState.detik_kiriman -= delta
	if GameState.detik_kiriman <= 0.0:
		GameState.detik_kiriman = 0.0
		_kurir_datang()





const ASET_KURIR: = ["res://assets/kendaraan/mobil_bak.glb", "res://assets/karakter3d/meshy_kurir.glb", "res://assets/upgrade/kardus_bawa.glb"]
var _aset_kurir: = {}


func _muat_aset_kurir() -> bool:
	var siap: = true
	for file: String in ASET_KURIR:
		if _aset_kurir.has(file):
			continue
		match ResourceLoader.load_threaded_get_status(file):
			ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
				if ResourceLoader.load_threaded_request(file) != OK:
					_aset_kurir[file] = null
				else:
					siap = false
			ResourceLoader.THREAD_LOAD_IN_PROGRESS:
				siap = false
			ResourceLoader.THREAD_LOAD_LOADED:
				_aset_kurir[file] = ResourceLoader.load_threaded_get(file)
			_:
				_aset_kurir[file] = null
	return siap


func _perbarui_bar_kiriman() -> void :
	var ada: bool = not GameState.kiriman_stok.is_empty()
	if bar_kiriman == null:
		if not ada:
			return
		_buat_bar_kiriman()
	bar_kiriman.visible = ada
	if not ada:
		return

	var y: = get_viewport_rect().size.y - 182
	if %BarLayani.visible:
		y = minf(y, %BarLayani.global_position.y - bar_kiriman.size.y - 10)
	bar_kiriman.position.y = y
	if GameState.kurir_dalam_perjalanan:
		label_kiriman.text = "Kurir sedang menuju warung…"
		label_detik_kiriman.text = ""
		progres_kiriman.value = 100
	else:
		var sisa: = ceili(GameState.detik_kiriman)
		label_kiriman.text = "Menunggu barang dikirim kurir…"
		label_detik_kiriman.text = "%d detik" % sisa
		progres_kiriman.value = 100.0 * (1.0 - GameState.detik_kiriman / maxf(GameState.durasi_kirim(), 1.0))


func _buat_bar_kiriman() -> void :
	bar_kiriman = PanelContainer.new()
	bar_kiriman.theme_type_variation = &"PanelHud"
	bar_kiriman.position = Vector2(16, get_viewport_rect().size.y - 182)
	bar_kiriman.custom_minimum_size = Vector2(330, 0)
	bar_kiriman.mouse_filter = Control.MOUSE_FILTER_IGNORE
	akar_ui.add_child(bar_kiriman)
	akar_ui.move_child(bar_kiriman, redup.get_index())
	var isi: = VBoxContainer.new()
	isi.add_theme_constant_override("separation", 6)
	bar_kiriman.add_child(isi)
	label_kiriman = Label.new()
	label_kiriman.theme_type_variation = &"LabelHud"
	label_kiriman.add_theme_font_size_override("font_size", 18)
	isi.add_child(label_kiriman)
	progres_kiriman = ProgressBar.new()
	progres_kiriman.show_percentage = false
	progres_kiriman.custom_minimum_size = Vector2(0, 26)
	var latar_bar: = StyleBoxFlat.new()
	latar_bar.bg_color = Color(0.1, 0.06, 0.03, 0.8)
	latar_bar.set_corner_radius_all(8)
	var isi_bar: = StyleBoxFlat.new()
	isi_bar.bg_color = Color(0.96, 0.66, 0.2)
	isi_bar.set_corner_radius_all(8)
	progres_kiriman.add_theme_stylebox_override("background", latar_bar)
	progres_kiriman.add_theme_stylebox_override("fill", isi_bar)
	isi.add_child(progres_kiriman)
	label_detik_kiriman = Label.new()
	label_detik_kiriman.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	label_detik_kiriman.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label_detik_kiriman.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label_detik_kiriman.add_theme_font_size_override("font_size", 16)
	label_detik_kiriman.add_theme_color_override("font_color", Color.WHITE)
	label_detik_kiriman.add_theme_color_override("font_outline_color", Color(0.2, 0.1, 0.02))
	label_detik_kiriman.add_theme_constant_override("outline_size", 5)
	progres_kiriman.add_child(label_detik_kiriman)




const SCRIPT_KENDARAAN: = preload("res://scripts/kendaraan.gd")

const LAJUR_TRUK: Array[Vector2] = [Vector2(-700, 150), Vector2(2300, 1680)]
const X_TRUK_BERHENTI: = 420.0
const TITIK_TURUN: = Vector2(455, 608)
const TITIK_TROTOAR_KURIR: = Vector2(760, 705)
var truk: Sprite2D = null





const LAJUR_KANAN: Array[Vector2] = [Vector2(-700, 150), Vector2(2300, 1680)]
const LAJUR_KIRI: Array[Vector2] = [Vector2(2300, 2078), Vector2(-700, 206)]
const JEDA_KENDARAAN: = 10.0
const URUTAN_KENDARAAN: = ["angkot", "motor", "mobil", "motor", "bak", "motor", "mobil"]
const SUARA_LEWAT: = {"motor": ["res://assets/suara/motor_lewat.ogg", 2.7], "mobil": ["res://assets/suara/mobil_lewat.ogg", 3.75]}
var lalu_lintas: Node2D
var _waktu_kendaraan: = 3.0
var _giliran_kendaraan: = 0
var _lajur_kurir_ditahan: = false


func _gerak_lalu_lintas(delta: float) -> void :
	if lalu_lintas == null:
		lalu_lintas = Node2D.new()
		latar.add_child(lalu_lintas)
		latar.move_child(lalu_lintas, %WadahPelanggan.get_index() + 1)
	_waktu_kendaraan -= delta

	if _jalan_ditutup_banjir():
		for k in lalu_lintas.get_children():
			if GameState.sedang_banjir() and not k.is_queued_for_deletion():
				k.queue_free()
		_waktu_kendaraan = maxf(_waktu_kendaraan, 2.0)
	var jam: = GameState.menit / 60.0
	var kosong: = true
	for k in lalu_lintas.get_children():
		if not k.is_queued_for_deletion():
			kosong = false
	if _waktu_kendaraan <= 0.0 and kosong and not (jam >= 23.0 or jam < 4.0) and not _jalan_ditutup_banjir():
		_waktu_kendaraan = JEDA_KENDARAAN * randf_range(0.8, 1.3) * (1.6 if GameState.grafik_rendah() else 1.0)
		_tambah_kendaraan()
	for k in lalu_lintas.get_children():
		if k.is_queued_for_deletion():
			continue
		k.jarak += k.kecepatan * delta
		k.position = k.titik_lajur(k.jarak)
		_bunyi_kendaraan_lewat(k)
		if k.jarak > k.panjang_lajur():
			k.queue_free()


func _tambah_kendaraan() -> void :


	var ke_kanan: = randf() < 0.5 and not _lajur_kurir_ditahan
	var jenis: String = URUTAN_KENDARAAN[_giliran_kendaraan % URUTAN_KENDARAAN.size()]
	_giliran_kendaraan += 1
	var ppm: = TINGGI_DEWASA_LATAR_LUAS / SCRIPT_PELANGGAN.TINGGI_DEWASA_METER * 0.9
	var k: = SCRIPT_KENDARAAN.new()
	k.lajur.clear()
	for t in (LAJUR_KANAN if ke_kanan else LAJUR_KIRI):
		k.lajur.append(_ke_lokal(t))
	k.position = k.lajur[0]
	k.modulate = cahaya_karakter
	lalu_lintas.add_child(k)
	if not k.siapkan(jenis, ppm, ke_kanan):
		k.queue_free()
		return
	k.kecepatan = (randf_range(7.0, 9.5) if jenis == "motor" else randf_range(5.0, 7.5)) * ppm


func _bunyi_kendaraan_lewat(k) -> void :
	if k.has_meta("bunyi") or k.kecepatan <= 0.0:
		return
	var data_suara: Array = SUARA_LEWAT["motor" if k.jenis == "motor" else "mobil"]
	if not ResourceLoader.exists(data_suara[0]):
		k.set_meta("bunyi", true)
		return
	var bapak_di: Vector2 = %PosisiBapak.position
	var a: Vector2 = k.lajur[0]
	var titik: = Geometry2D.get_closest_point_to_segment(bapak_di, a, k.lajur[1])
	var detik_sampai: float = (a.distance_to(titik) - k.jarak) / k.kecepatan
	var puncak: = float(data_suara[1])
	if detik_sampai > puncak:
		return
	k.set_meta("bunyi", true)
	var p: = AudioStreamPlayer.new()
	p.stream = load(data_suara[0])

	p.volume_db = -4.0 if k.ke_kanan else -8.0
	p.pitch_scale = randf_range(0.95, 1.05)
	p.bus = "Sekitar"
	add_child(p)
	p.finished.connect(p.queue_free)
	p.play(maxf(puncak - detik_sampai, 0.0))


func _titik_lajur_truk(x: float) -> Vector2:
	var t: = (x - LAJUR_TRUK[0].x) / (LAJUR_TRUK[1].x - LAJUR_TRUK[0].x)
	return LAJUR_TRUK[0].lerp(LAJUR_TRUK[1], t)


func _kurir_datang() -> void :
	GameState.kurir_dalam_perjalanan = true
	var lay: = $Layanan

	var data: Dictionary = lay.daftar_pelanggan[0]
	for d in lay.daftar_pelanggan:
		if d["id"] == "tukang":
			data = d
	var tokoh: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/pelanggan.json")).get("tokoh", {})
	if tokoh.has("kurir"):
		data = tokoh["kurir"].duplicate()
		data["id"] = "kurir"
		data["gambar"] = "pelanggan_kantoran.png"
		data["tinggi"] = 285

	var instan: = GameState.kurir_hari_ini() == "instan"

	_lajur_kurir_ditahan = true
	var tunggu_jalan: = 0.0



	while _ada_kendaraan_ke_kanan() and tunggu_jalan < (1.2 if instan else 6.0):
		await GameState.get_tree().create_timer(0.4, false).timeout
		tunggu_jalan += 0.4

	if not GameState.kurir_dalam_perjalanan:
		_lajur_kurir_ditahan = false
		return

	var ppm: = TINGGI_DEWASA_LATAR_LUAS / SCRIPT_PELANGGAN.TINGGI_DEWASA_METER * 0.9
	truk = SCRIPT_KENDARAAN.new()
	truk.position = _ke_lokal(_titik_lajur_truk(X_TRUK_BERHENTI if instan else -400.0))
	latar.add_child(truk)
	latar.move_child(truk, %WadahPelanggan.get_index() + 1)
	truk.siapkan("bak", ppm, true)
	truk.modulate = cahaya_karakter
	if instan:

		var warna_akhir: = truk.modulate
		truk.modulate.a = 0.0
		_suara_truk("mobil_datang", 13.4)
		var muncul: = truk.create_tween()
		muncul.tween_property(truk, "modulate:a", warna_akhir.a, 0.18)
		await muncul.finished
	else:

		_suara_truk("mobil_datang", 14.5 - 3.2)
		var datang: = truk.create_tween()
		datang.tween_property(truk, "position", _ke_lokal(_titik_lajur_truk(X_TRUK_BERHENTI)), 3.2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
		await datang.finished
	if truk == null or not is_instance_valid(truk):
		return
	await GameState.get_tree().create_timer(0.2 if instan else 0.5, false).timeout

	if truk == null or not is_instance_valid(truk):
		return

	kurir = Sprite2D.new()
	kurir.set_script(SCRIPT_PELANGGAN)
	kurir.modulate = cahaya_karakter
	%WadahPelanggan.add_child(kurir)
	kurir.set_meta("tipe", data["id"])
	var tujuan: = _ke_lokal(TITIK_KURIR)
	var jalur_datang: Array = [_ke_lokal(TITIK_TROTOAR_KURIR), tujuan]
	kurir.position = _ke_lokal(TITIK_TURUN)
	kurir.tinggi_dewasa_latar = TINGGI_DEWASA_LATAR_LUAS
	if lay.pakai_3d and data.has("model3d"):
		kurir.atur_3d(data["model3d"], %TitikPelanggan.position.y)

		if kurir.karakter != null and kurir.karakter.has_method("bawa_barang"):
			kurir.karakter.bawa_barang("res://assets/upgrade/kardus_bawa.glb")
	else:
		kurir.atur(load("res://assets/karakter/" + data["gambar"]), float(data["tinggi"]) * TINGGI_DEWASA_LATAR_LUAS / 285.0, %TitikPelanggan.position.y)
	kurir.modulate.a = 0.0
	kurir.create_tween().tween_property(kurir, "modulate:a", 1.0, 0.3)
	var kecepatan: = 230.0 * TINGGI_DEWASA_LATAR_LUAS / 285.0
	kurir.jalan(jalur_datang, kecepatan)
	await kurir.sampai
	if kurir == null or not is_instance_valid(kurir):
		return


	kurir.hadap(bapak_3d.position - kurir.position if bapak_3d != null else Vector2(0.4, -1))
	var sedang_melayani: bool = $Layanan.sedang_transaksi()
	if not sedang_melayani and bapak_3d != null and not bapak_3d.sedang_jalan:
		bapak_3d.hadap(kurir.position - bapak_3d.position)
	if kurir.karakter != null and kurir.karakter.has_method("lepas_barang"):
		await GameState.get_tree().create_timer(0.4).timeout
		if kurir == null or not is_instance_valid(kurir):
			return
		kurir.karakter.lepas_barang()
	kurir.aksi("bicara")
	GameState.bunyi("kurir")
	if not sedang_melayani:
		atur_pose_kasir("melayani")
	var kiriman_tadi: Dictionary = GameState.kiriman_stok.duplicate()
	GameState.terima_kiriman()
	notifikasi_stok(kiriman_tadi)
	await GameState.get_tree().create_timer(1.0).timeout

	if not sedang_melayani and bapak_3d != null and not bapak_3d.sedang_jalan:
		bapak_3d.hadap( %TitikPelanggan.position - %PosisiBapak.position)
	if kurir == null or not is_instance_valid(kurir):
		return

	var sopir: = kurir
	kurir = null
	sopir.jalan([_ke_lokal(TITIK_TROTOAR_KURIR), _ke_lokal(TITIK_TURUN)], kecepatan)
	await sopir.sampai
	if not is_instance_valid(sopir):
		return
	var naik: = sopir.create_tween()
	naik.tween_property(sopir, "modulate:a", 0.0, 0.3)
	await naik.finished
	sopir.queue_free()
	if truk == null or not is_instance_valid(truk):
		return
	_truk_pergi(true)





var _serah_terima: = 0

func _mulai_serah_terima() -> void :
	_serah_terima += 1
	$Layanan.tahan_depan = true
	while $Layanan.sedang_transaksi() and GameState.status_hari == "buka":
		await GameState.get_tree().create_timer(0.25, false).timeout


func _selesai_serah_terima() -> void :
	_serah_terima = maxi(_serah_terima - 1, 0)
	if _serah_terima == 0:
		$Layanan.tahan_depan = false






const FILE_RANTANG: = "res://assets/upgrade/rantang.glb"
const LEBAR_WADAH_MAKANAN: = 0.3
var tamu_kiriman: Sprite2D = null


func _cek_kiriman_warga() -> void :
	if tamu_kiriman != null or kurir != null or truk != null or preman != null or sedang_sholat or dialog_aktif or panel_terbuka():
		return

	var i_utang: = GameState.hutang_dibayar_sekarang()
	if i_utang >= 0:
		_kiriman_warga_datang(String(GameState.hutang[i_utang]["tipe"]), i_utang)
		return
	var id_sales: = GameState.sales_titipan_sekarang()
	if id_sales != "":
		_sales_titipan_datang(id_sales)
		return
	var tipe: = GameState.kiriman_warga_sekarang()
	if tipe == "":
		return
	_kiriman_warga_datang(tipe)



func _kiriman_warga_datang(tipe: String, i_utang: = -1) -> void :
	var bayar: = i_utang >= 0
	var data: = {}
	for d in $Layanan.daftar_pelanggan:
		if d["id"] == tipe:
			data = d
	if data.is_empty() or not data.has("model3d"):
		if bayar:
			GameState.lunasi_hutang(i_utang)
		else:
			GameState.jadwal_kiriman["selesai"] = true
		return
	var tamu: = Sprite2D.new()
	tamu_kiriman = tamu
	tamu.set_script(SCRIPT_PELANGGAN)
	tamu.modulate = cahaya_karakter
	%WadahPelanggan.add_child(tamu)
	tamu.set_meta("tipe", tipe)
	tamu.tinggi_dewasa_latar = TINGGI_DEWASA_LATAR_LUAS
	tamu.position = _ke_lokal(Vector2(-90, 345))
	tamu.atur_3d(data["model3d"], %TitikPelanggan.position.y)
	if not bayar and tamu.karakter != null and tamu.karakter.has_method("bawa_barang"):
		tamu.karakter.bawa_barang(FILE_RANTANG if ResourceLoader.exists(FILE_RANTANG) else "res://assets/upgrade/kardus_bawa.glb", LEBAR_WADAH_MAKANAN)
	var jalur_datang: Array = [_ke_lokal(Vector2(300, 470)), _ke_lokal(Vector2(600, 597)), _ke_lokal(TITIK_TROTOAR_KURIR), _ke_lokal(TITIK_KURIR)]
	var kecepatan: = 200.0 * TINGGI_DEWASA_LATAR_LUAS / 285.0 * float(tamu.faktor_kecepatan)
	tamu.jalan(jalur_datang, kecepatan)
	await tamu.sampai
	if not is_instance_valid(tamu):
		tamu_kiriman = null
		return
	tamu.hadap(bapak_3d.position - tamu.position if bapak_3d != null else Vector2(0.4, -1))

	await _mulai_serah_terima()
	if not is_instance_valid(tamu):
		_selesai_serah_terima()
		tamu_kiriman = null
		return
	if bapak_3d != null and not bapak_3d.sedang_jalan:
		bapak_3d.hadap(tamu.position - bapak_3d.position)
	var kiriman: Array = GameState.KIRIMAN_WARGA.get(tipe, ["Pak, ini ada sedikit makanan buat Bapak.", "makanan", 15])

	var ditagih: bool = bayar and bool(GameState.hutang[i_utang].get("datang_tagih", false))
	if bayar:
		kiriman = [String((GameState.ALASAN_DATANG_TAGIH if ditagih else GameState.BAYAR_UTANG).pick_random()), "", 0]
	var nama: = String(GameState.daftar_warga().get(tipe, "Warga"))


	if bayar and i_utang >= 0 and i_utang < GameState.hutang.size():
		nama = String(GameState.hutang[i_utang].get("nama", nama))
	elif VarianBaju.ada(tipe):
		nama = VarianBaju.nama_catatan(tipe)
	if nama.begins_with("Warga ("):
		nama = "Warga"
	tamu.aksi("bicara")
	await _ucap(tamu, String(kiriman[0]), clampf(1.2 + String(kiriman[0]).length() * 0.04, 2.4, 4.2))
	if not is_instance_valid(tamu):
		_selesai_serah_terima()
		tamu_kiriman = null
		return
	atur_pose_kasir("melayani")
	if ditagih:
		var pilihan: String = await _tanya_tagihan(i_utang, nama)
		var jml_awal: = int(GameState.hutang[i_utang]["jumlah"])
		var dapat: = GameState.selesaikan_tagihan(i_utang, pilihan)
		match pilihan:
			"cicil":
				await _ucap(bapak_3d, "Nggak apa-apa, %s. Separuh dulu, sisanya nanti, ya." % nama, 2.4, 118.0)
				uang_melayang("+" + GameState.format_rupiah(dapat))
				notifikasi("Utang dicicil", "%s membayar %s · sisa %s menyusul" % [nama, GameState.format_rupiah(dapat), GameState.format_rupiah(jml_awal - dapat)], "", WARNA_NOTIF_BAIK)
			"ikhlas":
				await _ucap(bapak_3d, "Sudah, %s. Saya ikhlaskan. Semoga cepat lapang rezekinya." % nama, 2.6, 118.0)
				notifikasi("Utang diikhlaskan", "Utang %s %s dicoret dari buku hutang" % [nama, GameState.format_rupiah(jml_awal)], "", WARNA_NOTIF_BAIK)
			_:
				await _ucap(bapak_3d, "Hatur nuhun, %s. Lain kali jangan telat lagi, ya." % nama, 2.4, 118.0)
				uang_melayang("+" + GameState.format_rupiah(dapat))
				notifikasi("Utang dibayar", "%s melunasi utang %s · dicoret dari buku hutang" % [nama, GameState.format_rupiah(dapat)], "", WARNA_NOTIF_BAIK)
	elif bayar:

		await _ucap(bapak_3d, "Alhamdulillah. Hatur nuhun, %s. Saya coret di buku hutang, ya." % nama, 2.4, 118.0)
		var jumlah: = GameState.lunasi_hutang(i_utang)
		uang_melayang("+" + GameState.format_rupiah(jumlah))
		notifikasi("Utang dibayar", "%s melunasi utang %s · dicoret dari buku hutang" % [nama, GameState.format_rupiah(jumlah)], "", WARNA_NOTIF_BAIK)
	else:

		if tamu.karakter != null and tamu.karakter.has_method("lepas_barang"):
			tamu.karakter.lepas_barang()
		await _ucap(bapak_3d, "Wah, jadi repot-repot. Hatur nuhun pisan, %s!" % nama, 2.2, 118.0)
		var energi: = GameState.terima_kiriman_warga(tipe)
		GameState.bunyi("hadiah")
		notifikasi("Kiriman dari %s" % nama, "%s untuk Pak Misran · Energi +%d" % [String(kiriman[1]).capitalize(), energi], "", WARNA_NOTIF_BAIK)
	if bapak_3d != null and not bapak_3d.sedang_jalan:
		bapak_3d.hadap( %TitikPelanggan.position - %PosisiBapak.position)
	_selesai_serah_terima()
	if not is_instance_valid(tamu):
		tamu_kiriman = null
		return

	var pulang: Array = jalur_datang.slice(0, jalur_datang.size() - 1)
	pulang.reverse()
	pulang.append(_ke_lokal(Vector2(-90, 345)))
	tamu.jalan(pulang, kecepatan)
	tamu_kiriman = null
	await tamu.sampai
	if not is_instance_valid(tamu):
		return
	var hilang: = tamu.create_tween()
	hilang.tween_property(tamu, "modulate:a", 0.0, 0.4)
	hilang.tween_callback(tamu.queue_free)





func _sales_titipan_datang(id: String) -> void :
	var s: Dictionary = GameState.SALES_TITIPAN[id]
	var tipe: = String(s["tipe"])
	var data: = {}
	for d in $Layanan.daftar_pelanggan:
		if d["id"] == tipe:
			data = d
	if data.is_empty() or not data.has("model3d"):
		GameState.kunjungan_titipan(id)
		return
	var tamu: = Sprite2D.new()
	tamu_kiriman = tamu
	tamu.set_script(SCRIPT_PELANGGAN)
	tamu.modulate = cahaya_karakter
	%WadahPelanggan.add_child(tamu)
	tamu.set_meta("tipe", tipe)
	tamu.tinggi_dewasa_latar = TINGGI_DEWASA_LATAR_LUAS
	tamu.position = _ke_lokal(Vector2(-90, 345))
	tamu.atur_3d(data["model3d"], %TitikPelanggan.position.y)
	if tamu.karakter != null and tamu.karakter.has_method("bawa_barang"):
		tamu.karakter.bawa_barang("res://assets/upgrade/kardus_bawa.glb", LEBAR_WADAH_MAKANAN)
	var jalur_datang: Array = [_ke_lokal(Vector2(300, 470)), _ke_lokal(Vector2(600, 597)), _ke_lokal(TITIK_TROTOAR_KURIR), _ke_lokal(TITIK_KURIR)]
	var kecepatan: = 200.0 * TINGGI_DEWASA_LATAR_LUAS / 285.0 * float(tamu.faktor_kecepatan)
	tamu.jalan(jalur_datang, kecepatan)
	await tamu.sampai
	if not is_instance_valid(tamu):
		tamu_kiriman = null
		return
	tamu.hadap(bapak_3d.position - tamu.position if bapak_3d != null else Vector2(0.4, -1))
	await _mulai_serah_terima()
	if not is_instance_valid(tamu):
		_selesai_serah_terima()
		tamu_kiriman = null
		return
	if bapak_3d != null and not bapak_3d.sedang_jalan:
		bapak_3d.hadap(tamu.position - bapak_3d.position)
	var nama: = String(s["nama"])
	var nama_b: = String(GameState.data_barang(id)["nama"]).to_lower()
	var sebut: = String(GameState.data_barang(id).get("sebutan", nama_b))
	var harga: = GameState.format_rupiah(GameState.harga_titip(id))
	var basi_roti: = bool(s["basi"])
	var pertama: = int(GameState.titipan[id]["kunjungan"]) == 0
	tamu.aksi("bicara")
	if pertama:
		var kenal: = "Assalamualaikum, Pak Misran. Saya %s, %s. Warung Bapak di pinggir jalan, boleh saya titip %d %s? Bayarnya nanti pas saya datang lagi, yang laku saja, %s per %s." % [nama, String(s["sebutan_sales"]), GameState.jumlah_titip(), sebut, harga, sebut]
		await _ucap(tamu, kenal, 4.6)
	else:
		await _ucap(tamu, "Punten, Pak Misran. Saya mau hitung titipan %s dulu, ya." % sebut, 2.6)
	if not is_instance_valid(tamu):
		_selesai_serah_terima()
		tamu_kiriman = null
		return
	atur_pose_kasir("melayani")
	if tamu.karakter != null and tamu.karakter.has_method("lepas_barang"):
		tamu.karakter.lepas_barang()
	var h: = GameState.kunjungan_titipan(id)
	if pertama:
		await _ucap(bapak_3d, "Boleh, %s. Saya pajang di rak kanan, ya." % nama, 2.4, 118.0)
		if basi_roti:
			await _ucap(tamu, "Roti tahan %d hari, Pak. Yang basi nanti saya bawa pulang, nggak usah dibayar." % GameState.HARI_BASI_ROTI, 3.0)
		GameState.bunyi("hadiah")
		notifikasi("Titipan baru: %s" % String(GameState.data_barang(id)["nama"]), "%d %s di rak kanan · bayar %s per %s yang laku saat %s datang lagi" % [int(h["tambah"]), sebut, harga, sebut, nama], "", WARNA_NOTIF_BAIK)
	else:
		var kalimat: = "Laku %d, jadi %s." % [int(h["terjual"]), GameState.format_rupiah(int(h["tagihan"]))] if int(h["terjual"]) > 0 or int(h["tagihan"]) > 0 else "Belum ada yang laku, Pak. Nggak apa-apa."
		if int(h["basi"]) > 0:
			kalimat += " Yang basi %d saya bawa pulang." % int(h["basi"])
		kalimat += " Saya isi lagi jadi %d, ya." % int(h["stok"]) if int(h["tambah"]) > 0 or int(h["kurang"]) <= 0 else " Belum saya isi lagi sampai tagihannya lunas, ya."
		if int(h["kurang"]) > 0:
			kalimat += " Sisanya %s dibayar nanti saja, Pak." % GameState.format_rupiah(int(h["kurang"]))
		await _ucap(tamu, kalimat, clampf(1.4 + kalimat.length() * 0.04, 2.6, 4.6))
		await _ucap(bapak_3d, "Hatur nuhun, %s." % nama, 1.8, 118.0)
		if int(h["bayar"]) > 0:
			uang_melayang("-" + GameState.format_rupiah(int(h["bayar"])))
		var isi: = "Laku %d · dibayar %s · diisi lagi jadi %d" % [int(h["terjual"]), GameState.format_rupiah(int(h["bayar"])), int(h["stok"])] if int(h["kurang"]) <= 0\
		else "Laku %d · dibayar %s · belum diisi lagi" % [int(h["terjual"]), GameState.format_rupiah(int(h["bayar"]))]
		if int(h["basi"]) > 0:
			isi += " · %d basi dibawa pulang" % int(h["basi"])
		notifikasi("Titipan %s" % nama_b, isi, "", WARNA_NOTIF_BAIK)
	GameState.simpan()
	if bapak_3d != null and not bapak_3d.sedang_jalan:
		bapak_3d.hadap( %TitikPelanggan.position - %PosisiBapak.position)
	_selesai_serah_terima()
	if not is_instance_valid(tamu):
		tamu_kiriman = null
		return
	var pulang: Array = jalur_datang.slice(0, jalur_datang.size() - 1)
	pulang.reverse()
	pulang.append(_ke_lokal(Vector2(-90, 345)))
	tamu.jalan(pulang, kecepatan)
	tamu_kiriman = null
	await tamu.sampai
	if not is_instance_valid(tamu):
		return
	var hilang: = tamu.create_tween()
	hilang.tween_property(tamu, "modulate:a", 0.0, 0.4)
	hilang.tween_callback(tamu.queue_free)




func _truk_pergi(pakai_jeda: = false) -> void :
	if truk == null or not is_instance_valid(truk):
		_lajur_kurir_ditahan = false
		return
	var t: = truk
	truk = null
	_suara_truk("mobil_pergi", 0.0, t)
	var pergi: = t.create_tween()
	if pakai_jeda:
		pergi.tween_interval(1.2)
	pergi.tween_property(t, "position", _ke_lokal(_titik_lajur_truk(1900.0)), 4.0).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	pergi.tween_callback( func(): _lajur_kurir_ditahan = truk != null)
	pergi.tween_interval(3.0)
	pergi.tween_callback(t.queue_free)


func _ada_kendaraan_ke_kanan() -> bool:
	if lalu_lintas == null:
		return false
	for k in lalu_lintas.get_children():
		if not k.is_queued_for_deletion() and k.ke_kanan:
			return true
	return false



func _suara_truk(nama: String, mulai: float, t: Node = null) -> void :
	if t == null:
		t = truk
	var file: = "res://assets/suara/%s.wav" % nama
	if t == null or not ResourceLoader.exists(file):
		return
	var p: = AudioStreamPlayer.new()
	p.stream = load(file)
	p.volume_db = 2.5
	t.add_child(p)
	p.play(maxf(mulai, 0.0))




func _pasang_rak_isi() -> void :
	for nama in ["setengah", "penuh"]:
		var s: = Sprite2D.new()
		s.texture = RAK_SETENGAH if nama == "setengah" else RAK_PENUH
		s.centered = false
		s.position = _ke_lokal(POSISI_RAK)
		s.modulate.a = 0.0
		latar.add_child(s)
		latar.move_child(s, %WadahPelanggan.get_index())
		lapisan_rak[nama] = s
	_perbarui_rak_isi(true)





const DURASI_TRANSISI: = 3.0
var campur_malam: = 0.0
var latar_sudah_diatur: = false


const FILE_LATAR_BASAH: = "res://assets/latar/latar_warung_kosong_basah.png"
const FILE_LATAR_MALAM_BASAH: = "res://assets/latar/latar_warung_kosong_malam_basah.png"
var latar_basah: = false

func _perbarui_latar_malam() -> void :
	if not LATAR_LUAS:
		return
	var delta: = get_process_delta_time()
	campur_malam = move_toward(campur_malam, 1.0 if latar_malam else 0.0, delta / DURASI_TRANSISI)
	if GameState.malam_hari() == latar_malam and GameState.tanah_basah() == latar_basah and latar_sudah_diatur:
		return
	var rak_berganti: = GameState.malam_hari() != latar_malam or not latar_sudah_diatur
	latar_malam = GameState.malam_hari()
	latar_basah = GameState.tanah_basah()
	if not latar_sudah_diatur:

		latar_sudah_diatur = true
		campur_malam = 1.0 if latar_malam else 0.0
	else:

		_pudarkan_salinan(latar)
		if rak_berganti:
			for nama in ["setengah", "penuh"]:
				if lapisan_rak.has(nama):
					_pudarkan_salinan(lapisan_rak[nama])
	if latar_basah:
		latar.texture = load(FILE_LATAR_MALAM_BASAH if latar_malam else FILE_LATAR_BASAH)
	else:
		latar.texture = GAMBAR_LATAR_MALAM if latar_malam else GAMBAR_LATAR_LUAS
	if lapisan_rak.has("setengah"):
		lapisan_rak["setengah"].texture = RAK_SETENGAH_MALAM if latar_malam else RAK_SETENGAH
		lapisan_rak["penuh"].texture = RAK_PENUH_MALAM if latar_malam else RAK_PENUH



func _pudarkan_salinan(sprite: Sprite2D) -> void :
	var s: = Sprite2D.new()
	s.texture = sprite.texture
	s.centered = sprite.centered
	s.offset = sprite.offset
	sprite.add_child(s)
	sprite.move_child(s, 0)
	var tw: = create_tween()
	tw.tween_property(s, "modulate:a", 0.0, DURASI_TRANSISI)
	tw.tween_callback(s.queue_free)



func _perbarui_rak_isi(langsung: = false) -> void :
	if lapisan_rak.is_empty():
		return


	var tingkat: = "penuh"
	if tingkat == tingkat_rak:
		return
	tingkat_rak = tingkat


	for nama in lapisan_rak:
		var mau: = 1.0 if tingkat == "penuh" or (tingkat == "setengah" and nama == "setengah") else 0.0
		if langsung:
			lapisan_rak[nama].modulate.a = mau
		else:
			create_tween().tween_property(lapisan_rak[nama], "modulate:a", mau, 0.6)




const WARNA_NOTIF_BAIK: = Color(0.16, 0.5, 0.26)
const WARNA_NOTIF_BURUK: = Color(0.62, 0.2, 0.16)
const WARNA_NOTIF_BIASA: = Color(0.22, 0.38, 0.55)


func notifikasi(judul: String, isi: String, ikon: = "", warna: = WARNA_NOTIF_BAIK) -> void :
	GameState.bunyi("salah" if warna == WARNA_NOTIF_BURUK else "hadiah")
	var kotak: = PanelContainer.new()

	kotak.add_theme_stylebox_override("panel", GH.kartu_notif(0.82, Vector4(26, 14, 22, 14)))
	kotak.mouse_filter = Control.MOUSE_FILTER_IGNORE
	kotak.z_index = 6
	akar_ui.add_child(kotak)
	var baris: = HBoxContainer.new()
	baris.add_theme_constant_override("separation", 14)
	kotak.add_child(baris)
	if ikon != "":
		var gambar: = TextureRect.new()
		gambar.texture = load(ikon)
		gambar.custom_minimum_size = Vector2(42, 42)
		gambar.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		gambar.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		baris.add_child(gambar)
	var kolom: = VBoxContainer.new()
	kolom.add_theme_constant_override("separation", 2)
	baris.add_child(kolom)
	var l_judul: = Label.new()
	l_judul.text = judul
	GH.gaya_label(l_judul, 26, GH.KUNING, true)
	kolom.add_child(l_judul)
	var l_isi: = Label.new()
	l_isi.text = isi
	GH.gaya_label(l_isi, 15, Color.WHITE)
	l_isi.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l_isi.custom_minimum_size.x = 340
	kolom.add_child(l_isi)
	_luncurkan_notif(kotak, 3.2)
	if tombol_hp != null:
		var getar: = tombol_hp.create_tween()
		for sudut in [-14.0, -2.0, -14.0, -2.0, 0.0]:
			getar.tween_property(tombol_hp, "rotation_degrees", sudut, 0.06)






func _luncurkan_notif(kotak: Control, lama: float, tunggu_nota: = true, gerak: = 0.35) -> void :
	kotak.modulate.a = 0.0
	await get_tree().process_frame
	var tunggu: = 0.0
	while is_instance_valid(kotak) and tunggu_nota and $Layanan.nota_dipakai() and tunggu < 20.0:
		await GameState.get_tree().create_timer(0.25).timeout
		tunggu += 0.25
	if not is_instance_valid(kotak):
		return

	kotak.position = Vector2((get_viewport_rect().size.x - kotak.size.x) / 2.0, 150.0)
	GH.pop_masuk(kotak, 0.55, maxf(gerak, 0.28))
	var sisa: = lama + gerak
	var nota_tadi: bool = $Layanan.nota_dipakai()
	while sisa > 0.0 and is_instance_valid(kotak):
		await GameState.get_tree().create_timer(0.1).timeout
		sisa -= 0.1
		var nota: bool = $Layanan.nota_dipakai()
		if nota and not nota_tadi and tunggu_nota:
			break
		nota_tadi = nota
	if not is_instance_valid(kotak):
		return
	var keluar: = kotak.create_tween().set_parallel(true)
	keluar.tween_property(kotak, "scale", Vector2(0.85, 0.85), 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	keluar.tween_property(kotak, "modulate:a", 0.0, 0.2)
	keluar.chain().tween_callback(kotak.queue_free)




func _buat_bintang_hud() -> void :
	var panel: = PanelContainer.new()
	panel.theme_type_variation = &"PanelHud"
	panel.tooltip_text = "Reputasi warung"
	var label_rep: = Label.new()
	label_rep.text = "Reputasi "
	label_rep.theme_type_variation = &"LabelHud"
	label_rep.add_theme_font_size_override("font_size", 16)
	$UI / Akar / BarKiri.add_child(panel)
	var baris: = HBoxContainer.new()
	baris.add_theme_constant_override("separation", 2)
	panel.add_child(baris)
	baris.add_child(label_rep)
	for i in 5:
		var b: = TextureRect.new()
		b.custom_minimum_size = Vector2(26, 26)
		b.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		b.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		baris.add_child(b)
		bintang_hud.append(b)
	_perbarui_bintang()

	var panel_ulasan: = PanelContainer.new()
	panel_ulasan.theme_type_variation = &"PanelHud"
	$UI / Akar / BarKiri.add_child(panel_ulasan)
	var tombol_ulasan: = Button.new()
	tombol_ulasan.flat = true
	tombol_ulasan.focus_mode = Control.FOCUS_NONE
	tombol_ulasan.tooltip_text = "Ulasan pelanggan"
	tombol_ulasan.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	tombol_ulasan.icon = load("res://assets/ikon/ulasan.svg")
	tombol_ulasan.expand_icon = true
	tombol_ulasan.custom_minimum_size = Vector2(30, 30)
	for gaya in ["normal", "hover", "pressed", "focus"]:
		tombol_ulasan.add_theme_stylebox_override(gaya, StyleBoxEmpty.new())
	tombol_ulasan.pressed.connect( func():
		if not dialog_aktif:
			buka_hp("ulasan"))
	panel_ulasan.add_child(tombol_ulasan)

	titik_ulasan = UI_HP.lencana()
	titik_ulasan.position = Vector2(20, -10)
	tombol_ulasan.add_child(titik_ulasan)

	titik_tugas = UI_HP.lencana()
	titik_tugas.position = Vector2(-26, -12)
	judul_tugas.add_child(titik_tugas)
	GameState.data_berubah.connect(_perbarui_titik_layar)
	_perbarui_titik_layar()


var titik_ulasan: PanelContainer = null
var titik_tugas: PanelContainer = null

func _perbarui_titik_layar() -> void :
	if titik_ulasan != null:
		UI_HP.atur_lencana(titik_ulasan, GameState.ulasan_buruk_baru())
	if titik_tugas != null:
		titik_tugas.visible = GameState.jumlah_notif_baru("misi") > 0
		(titik_tugas.get_node("Angka") as Label).text = "!"


func _perbarui_bintang() -> void :
	for i in bintang_hud.size():
		bintang_hud[i].texture = IKON_BINTANG if i < GameState.bintang() else IKON_BINTANG_KOSONG


func _on_reputasi_berubah(selisih: float) -> void :
	var lama: = 0
	for b in bintang_hud:
		if b.texture == IKON_BINTANG:
			lama += 1
	_perbarui_bintang()
	if GameState.bintang() != lama and not GameState.mode_latihan:
		tampilkan_pesan("Reputasi warung %s: %d bintang!" % ["naik" if selisih > 0 else "turun", GameState.bintang()], 3.0)
		GameState.bunyi("hadiah" if selisih > 0 else "salah")

	var panel: Control = bintang_hud[0].get_parent().get_parent()
	panel.pivot_offset = panel.size / 2.0
	var t: = panel.create_tween()
	t.tween_property(panel, "scale", Vector2(1.1, 1.1) if selisih > 0 else Vector2(0.92, 0.92), 0.1)
	t.tween_property(panel, "scale", Vector2.ONE, 0.15)





func panel_terbuka() -> bool:
	return panel_belanja.visible or (hp != null and hp.visible)


func _pasang_hp() -> void :
	hp = SCRIPT_HP.new()
	hp.warung = self
	akar_ui.add_child(hp)

	akar_ui.move_child(hp, $UI / Akar / CeritaUI.get_index())
	hp.visibility_changed.connect(_perbarui_tampilan)


	tombol_belanja.hide()

	tombol_hp = GH.tombol_ikon(GameState.ikon_hp(), "HP", UKURAN_IKON_HP)
	_tempel_bawah(tombol_hp, false, 10.0)
	tombol_hp.pressed.connect( func(): buka_hp())
	akar_ui.add_child(tombol_hp)
	akar_ui.move_child(tombol_hp, tombol_belanja.get_index())
	lencana_hp = UI_HP.lencana()
	GH.gaya_lencana(lencana_hp)
	lencana_hp.position = GH.letak_lencana_hp(tombol_hp)
	tombol_hp.add_child(lencana_hp)
	GameState.data_berubah.connect( func(): (tombol_hp.get_node("Ikon") as TextureRect).texture = load(GameState.ikon_hp()))


	var panel_tugas: Control = label_tugas.get_parent().get_parent()
	panel_tugas.mouse_filter = Control.MOUSE_FILTER_STOP
	panel_tugas.gui_input.connect(_on_panel_tugas_input)
	var petunjuk: = Label.new()
	petunjuk.text = "Klik untuk menutup · detail di HP → Misi"
	petunjuk.add_theme_font_size_override("font_size", 14)
	GH.gaya_label(petunjuk, 14, GH.KUNING)
	petunjuk.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	label_tugas.get_parent().add_child(petunjuk)
	petunjuk_tugas = petunjuk
	_terapkan_tugas_ringkas()

	GameState.upgrade_dibeli.connect(_on_upgrade_dibeli)
	GameState.data_berubah.connect(_perbarui_lencana_hp)
	_perbarui_lencana_hp()
	if LATAR_LUAS:
		_perbarui_visual_upgrade()

		GameState.data_berubah.connect(_perbarui_visual_upgrade)






const UKURAN_IKON_HP: = 96.0
const UKURAN_IKON_DOCK: = 96.0
const BATAS_ATAS_PANEL_STOK: = 84.0
const MAKS_KOLOM_STOK: = 4

func _tempel_bawah(c: Control, kanan: bool, jarak_tepi: float) -> void :
	c.anchor_top = 1.0
	c.anchor_bottom = 1.0
	c.offset_bottom = -6.0
	c.offset_top = -6.0 - c.custom_minimum_size.y
	if kanan:
		c.anchor_left = 1.0
		c.anchor_right = 1.0
		c.offset_right = - jarak_tepi
		c.offset_left = - jarak_tepi - c.custom_minimum_size.x
	else:
		c.offset_left = jarak_tepi
		c.offset_right = jarak_tepi + c.custom_minimum_size.x




const JARAK_DOCK: = 14.0
const SISI_KRESEK: = 95.0

func _pasang_tombol_jalan() -> void :
	_dock = HBoxContainer.new()
	_dock.add_theme_constant_override("separation", int(JARAK_DOCK))
	_dock.alignment = BoxContainer.ALIGNMENT_BEGIN
	_dock.mouse_filter = Control.MOUSE_FILTER_IGNORE

	_dock.anchor_left = 1.0
	_dock.anchor_right = 1.0
	_dock.anchor_top = 1.0
	_dock.anchor_bottom = 1.0
	_dock.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_dock.offset_right = - tombol_hp.offset_left
	_dock.offset_left = _dock.offset_right
	_dock.offset_bottom = -6
	_dock.offset_top = -6 - (UKURAN_IKON_DOCK + 18.0)
	akar_ui.add_child(_dock)
	akar_ui.move_child(_dock, tombol_hp.get_index())
	_dock.resized.connect(_atur_skala_dock)
	get_viewport().size_changed.connect(_atur_skala_dock)
	get_viewport().size_changed.connect(_atur_kolom_stok)
	var t: = GH.tombol_ikon("res://assets/ikon_hud/keluar_warung.png", "KELUAR WARUNG", UKURAN_IKON_DOCK)
	t.pressed.connect(_jalan_jalan)
	_dock.add_child(t)
	tombol_jalan = t
	var ikon_promosi: = "res://assets/ikon_hud/promosi.png"
	if not ResourceLoader.exists(ikon_promosi):
		ikon_promosi = "res://assets/ikon_hud/promosi.svg"
	tombol_promosi = GH.tombol_ikon(ikon_promosi, "PROMOSI", UKURAN_IKON_DOCK)
	tombol_promosi.pressed.connect(_buka_promosi)
	_dock.add_child(tombol_promosi)

	tombol_tutup.get_parent().remove_child(tombol_tutup)
	tombol_tutup.set_anchors_preset(Control.PRESET_TOP_LEFT)
	tombol_tutup.custom_minimum_size = Vector2(124, UKURAN_IKON_DOCK)
	tombol_tutup.size_flags_vertical = Control.SIZE_SHRINK_END
	_dock.add_child(tombol_tutup)
	lencana_promosi = UI_HP.lencana()
	GH.gaya_lencana(lencana_promosi)
	lencana_promosi.position = Vector2(tombol_promosi.custom_minimum_size.x - 30, 4)
	tombol_promosi.add_child(lencana_promosi)

	var tombol_stok_lama: = tombol_stok
	tombol_stok = GH.tombol_ikon("res://assets/ikon_hud/stok.png", "STOK", UKURAN_IKON_DOCK)
	_dock.add_child(tombol_stok)
	lencana_stok = UI_HP.lencana()
	GH.gaya_lencana(lencana_stok)
	lencana_stok.position = Vector2(tombol_stok.custom_minimum_size.x - 30, 4)
	tombol_stok.add_child(lencana_stok)
	tombol_stok_lama.hide()
	var u: = GH.tombol_ikon("res://assets/ikon_hud/upgrade.png", "UPGRADE", UKURAN_IKON_DOCK)
	u.pressed.connect( func(): buka_hp("upgrade"))
	_dock.add_child(u)
	tombol_upgrade = u
	var bh: = GH.tombol_ikon("res://assets/ikon_hud/buku_hutang.png", "BUKU HUTANG", UKURAN_IKON_DOCK)
	bh.pressed.connect(_buka_buku_hutang)
	_dock.add_child(bh)
	tombol_hutang = bh
	lencana_hutang = UI_HP.lencana()
	GH.gaya_lencana(lencana_hutang)
	lencana_hutang.position = Vector2(bh.custom_minimum_size.x - 30, 4)
	bh.add_child(lencana_hutang)

	panel_stok_hud.add_theme_stylebox_override("panel", GH.bingkai_emas(Vector4(16, 12, 16, 12)))
	isi_stok.show()
	panel_stok_hud.hide()
	panel_stok_hud.z_index = 3

	panel_stok_hud.anchor_left = 1.0
	panel_stok_hud.anchor_right = 1.0
	panel_stok_hud.anchor_top = 1.0
	panel_stok_hud.anchor_bottom = 1.0
	panel_stok_hud.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	panel_stok_hud.grow_vertical = Control.GROW_DIRECTION_BEGIN
	panel_stok_hud.offset_right = - maxf(GH.tepi_kiri_kanan(get_viewport()).y, 16.0)
	panel_stok_hud.offset_left = panel_stok_hud.offset_right - 1.0
	panel_stok_hud.offset_bottom = - UKURAN_IKON_DOCK - 30.0
	panel_stok_hud.offset_top = panel_stok_hud.offset_bottom - 1.0







func lebar_sisi_bawah() -> float:
	var tepi: float = tombol_hp.offset_left if tombol_hp != null else 10.0
	return get_viewport().get_visible_rect().size.x / 2.0 - SISI_KRESEK - tepi


func _atur_skala_dock() -> void :
	if _dock == null:
		return
	var lebar: float = _dock.get_combined_minimum_size().x
	var tepi: float = tombol_hp.offset_left
	if not is_equal_approx(_dock.offset_right, - tepi) or not is_equal_approx(_dock.offset_left, - tepi - lebar):
		_dock.offset_right = - tepi
		_dock.offset_left = - tepi - lebar
	var s: = clampf(lebar_sisi_bawah() / maxf(lebar, 1.0), 0.55, 1.3)
	_dock.pivot_offset = Vector2(lebar, _dock.size.y)
	_dock.scale = Vector2(s, s)
	if has_node("Layanan"):
		$Layanan._atur_skala_rak.call_deferred()


var tombol_upgrade: Button = null
var sorot: Control = null




func _perbarui_sorot_etalase() -> void :
	if sorot == null:
		return
	var bebas: = not dialog_aktif and not sedang_sholat and not panel_belanja.visible
	var perlu: = GameState.wajib_etalase and not GameState.punya_upgrade("etalase") and GameState.status_hari != "tutup" and bebas


	if GameState.tutorial_langkah != "" and GameState.punya_upgrade("etalase"):
		if bebas:
			_sorot_tutorial_hari_pertama()
		elif sorot.visible:
			sorot.lepas()
		return
	if not perlu:
		if sorot.visible:
			sorot.lepas()
		return
	if hp != null and hp.visible:
		var app: Control = hp.aplikasi("upgrade") if hp.aplikasi_aktif() == "upgrade" else null
		var beli: Control = app._tombol.get("etalase") if app != null else null
		if beli == null:
			if sorot.visible:
				sorot.lepas()
			return
		if sorot.sasaran != beli:
			app._gulir.ensure_control_visible(app._kartu["etalase"])
			sorot.sorot(beli, "Klik Beli untuk memasang etalase kaca. Uangnya sudah disiapkan di modal awal.")
		return
	if tombol_upgrade != null and tombol_upgrade.visible and sorot.sasaran != tombol_upgrade:
		sorot.sorot(tombol_upgrade, "Sebelum buka warung, beli etalase kaca dulu. Klik Upgrade warung!")



func _sorot_ke(sasaran: Control, teks: String, tujuan: Control = null) -> void :
	if sasaran == null or not sasaran.is_visible_in_tree():
		if sorot.visible:
			sorot.lepas()
		return
	if sorot.sasaran != sasaran or sorot.sasaran2 != tujuan or sorot._teks != teks or not sorot.visible:
		sorot.sorot(sasaran, teks, tujuan)



func _sorot_ringan_ke(asal: Control, tujuan: Control, teks: String) -> void :
	if asal == null or not asal.is_visible_in_tree():
		if sorot.visible:
			sorot.lepas()
		return
	if not sorot.ringan or sorot.sasaran != asal or sorot.sasaran2 != tujuan or sorot._teks != teks or not sorot.visible:
		sorot.sorot_ringan(asal, tujuan, teks)




func selesaikan_tutorial_pertama() -> void :
	await GameState.get_tree().create_timer(1.6).timeout
	if GameState.tutorial_langkah != "asli_layani":
		return
	if sorot != null and sorot.visible:
		sorot.lepas()


	var tugas: Control = label_tugas.get_parent().get_parent() if label_tugas != null else null
	await _jelaskan([
		[bintang_hud[0].get_parent().get_parent() if not bintang_hud.is_empty() else null, 
			"Ini reputasi warung. Layani pembeli dengan cepat dan benar supaya bintang naik. Makin banyak bintang, makin ramai pembeli."], 
		[tugas, "Ini Level Warung: tugas untuk naik level, termasuk kiriman uang untuk Agus dan batas waktunya. Klik untuk melihat daftarnya."], 
		[bar_energi, "Ini energi Pak Misran, berkurang seiring waktu. Di bawah %d%% Pak Misran terlalu lelah menjaga warung. Klik bar ini untuk ngopi, atau tidur supaya penuh lagi." % int(GameState.ENERGI_MIN_BUKA)], 
		[tombol_hp, "HP Pak Misran: belanja stok, kirim uang ke Agus lewat Warga Bank, lihat misi dan peta, dan buka Panduan kalau bingung."], 
	], "layar_warung")
	GameState.selesai_tutorial_awal()
	_judul_besar("SELAMAT BERMAIN!")



var _tip_jalan: = false


func _jelaskan(daftar: Array, id: = "") -> void :
	if _tip_jalan:
		return
	_tip_jalan = true
	if id != "":
		GameState.tandai_tip(id)
	if sorot != null and sorot.visible:
		sorot.lepas()
	var dialog_sebelum: = dialog_aktif
	dialog_aktif = true
	var s: Control = preload("res://scripts/sorot_tutorial.gd").new()
	s.process_mode = Node.PROCESS_MODE_ALWAYS
	akar_ui.add_child(s)
	await s.jelaskan_urut(daftar)
	s.queue_free()
	dialog_aktif = dialog_sebelum
	_tip_jalan = false


func _cek_tip_warung() -> void :
	if _tip_jalan or dialog_aktif or panel_terbuka() or sedang_sholat or GameState.status_hari != "buka":
		return
	if GameState.tip_baru("stok") and tombol_stok.is_visible_in_tree():
		var menipis: Array = GameState.barang_menipis()
		if not menipis.is_empty():
			_jelaskan([[tombol_stok, "Stok %s menipis (angka merah). Sisa stok semua barang bisa dilihat di sini. Belanja lagi lewat HP, Belanja Online." % String(GameState.data_barang(menipis[0])["nama"]).to_lower()]], "stok")


func _tip_rekap() -> void :
	await GameState.get_tree().create_timer(1.3).timeout
	if not panel_tutup.visible or _tip_jalan:
		return
	_jelaskan([[panel_tutup, "Ini rekap hari ini. Biaya harian (listrik, iuran, perlengkapan) sudah dipotong otomatis, dan sewa ditagih setiap Minggu pukul 18.00. Kalau uang minus terlalu lama, warung bisa bangkrut."]], "rekap")


var bar_energi: Control = null
var _tut_marah_dijelaskan: = false
var tut_tutup_mulai: = 0
var _tut_kurir_dijelaskan: = false
var _tut_tunggu_buka_dijelaskan: = false

func _sorot_tutorial_hari_pertama() -> void :
	match GameState.tutorial_langkah:
		"belanja":

			var app: Control = hp.aplikasi("belanja") if hp != null and hp.aplikasi_aktif() == "belanja" else null
			if app != null:
				if not app._keranjang.is_empty():
					_sorot_ke(app._tombol_beli, "Bagus! Sekarang klik Checkout. Kurir akan mengantar barangnya ke warung.")
					return
				var menipis: Array = GameState.barang_menipis()
				var id: String = menipis[0] if not menipis.is_empty() else GameState.barang_fisik().filter(GameState.terbuka)[0]
				if app._kartu.has(id):
					var gulir: Node = app._kartu[id]
					while gulir != null and not gulir is ScrollContainer:
						gulir = gulir.get_parent()
					if gulir != null:
						gulir.ensure_control_visible(app._kartu[id])
				_sorot_ke(app._tombol[id][2], "%s hampir habis. Klik +5 untuk memasukkan 5 buah ke keranjang." % String(GameState.data_barang(id)["nama"]))
			elif hp != null and hp.visible:
				if hp.aplikasi_aktif() == "":
					_sorot_ke(hp.tombol_ikon.get("belanja"), "Klik Belanja Online untuk membeli stok dari supplier.")
				else:
					_sorot_ke(hp.tombol_tutup, "Klik Tutup HP dulu.")
			else:
				_sorot_ke(tombol_hp, "Etalase sudah terpasang! Stok di rak mulai menipis. Klik HP untuk belanja stok.")
		"buka":
			if hp != null and hp.visible:
				_sorot_ke(hp.tombol_tutup, "Pesanan sedang diantar kurir. Klik Tutup HP untuk kembali ke warung.")
			elif GameState.status_hari == "buka":
				GameState.tutorial_langkah = "layani"
			else:
				_sorot_ke(tombol_buka, "Siap berjualan! Klik Buka Warung untuk mulai melayani pembeli.")
		"layani":

			var lay: = $Layanan
			var depan: Dictionary = lay._depan()
			if depan.is_empty() or depan["status"] != "depan":
				if sorot.visible:
					sorot.lepas()
				return
			var diminta: Dictionary = lay._diminta(depan)
			for id in diminta:
				if int(lay.keranjang.get(id, 0)) < int(diminta[id]) and lay.tombol_barang.has(id):
					var sisa: = int(diminta[id]) - int(lay.keranjang.get(id, 0))
					_sorot_ke(lay.tombol_barang[id], "Pembeli minta %s. Tahan barangnya di rak, lalu seret ke kresek hitam%s." % [
						String(GameState.data_barang(id)["nama"]).to_lower(), (" (%d kali lagi)" % sisa) if sisa > 1 else ""], lay.kresek)
					return
		"asli_layani":


			var lay_a: = $Layanan
			var depan_a: Dictionary = lay_a._depan()
			if depan_a.is_empty() or depan_a["status"] != "depan":
				if sorot.visible:
					sorot.lepas()
				return
			var diminta_a: Dictionary = lay_a._diminta(depan_a)
			for id in diminta_a:
				if int(lay_a.keranjang.get(id, 0)) < int(diminta_a[id]) and lay_a.tombol_barang.has(id):
					var sisa_a: = int(diminta_a[id]) - int(lay_a.keranjang.get(id, 0))
					_sorot_ringan_ke(lay_a.tombol_barang[id], lay_a.kresek, "Pembeli minta %s. Tahan barangnya di rak, lalu seret ke kresek hitam%s. Lingkaran di atas kepala pembeli adalah sisa kesabarannya." % [
						String(GameState.data_barang(id)["nama"]).to_lower(), (" (%d kali lagi)" % sisa_a) if sisa_a > 1 else ""])
					return
			if sorot.visible:
				sorot.lepas()
		"marah":

			if sorot.visible:
				sorot.lepas()
			var depan_marah: Dictionary = $Layanan._depan()
			if not depan_marah.is_empty() and depan_marah["status"] in ["antre", "depan"] and not _tut_marah_dijelaskan:
				_tut_marah_dijelaskan = true
				tampilkan_pesan("Pembeli ini sengaja tidak dilayani dulu. Lihat lingkaran kesabaran di atas kepalanya berkurang...", 6.0)
		"habis":

			var lay_h: = $Layanan
			var depan_h: Dictionary = lay_h._depan()
			if depan_h.is_empty() or depan_h["status"] != "depan":
				if sorot.visible:
					sorot.lepas()
				return
			for id in lay_h._diminta(depan_h):
				if int(lay_h.keranjang.get(id, 0)) < 1 and lay_h.tombol_barang.has(id):
					_sorot_ke(lay_h.tombol_barang[id], "Pembeli minta %s, padahal stoknya habis (0). Coba seret ke kresek dan lihat reaksinya." % String(GameState.data_barang(id)["nama"]).to_lower(), lay_h.kresek)
					return
		"asli_belanja":

			if not GameState.kiriman_stok.is_empty() and GameState.kekurangan_stok().is_empty():
				GameState.tutorial_langkah = "asli_kurir"
				return
			var app_a: Control = hp.aplikasi("belanja") if hp != null and hp.aplikasi_aktif() == "belanja" else null
			if app_a != null:
				if GameState.kekurangan_stok(app_a._keranjang).is_empty() and not app_a._keranjang.is_empty():
					_sorot_ke(app_a._tombol_beli, "Semua barang sudah masuk keranjang. Klik Checkout untuk membayar. Kurir akan mengantar ke warung.")
				else:
					_sorot_ke(app_a.tombol_lengkapi, "Rak masih kosong. Setiap barang minimal %d stok sebelum warung dibuka. Klik Lengkapi stok." % GameState.MIN_STOK_BUKA)
			elif hp != null and hp.visible:
				if hp.aplikasi_aktif() == "":
					_sorot_ke(hp.tombol_ikon.get("belanja"), "Klik Belanja Online untuk membeli stok dari supplier.")
				else:
					_sorot_ke(hp.tombol_kembali, "Etalase sudah terpasang! Klik Kembali.")
			else:
				_sorot_ke(tombol_hp, "Rak masih kosong. Klik HP untuk belanja stok.")
		"asli_kurir":
			if GameState.kiriman_stok.is_empty():
				GameState.tutorial_langkah = "asli_buka" if GameState.kekurangan_stok().is_empty() else "asli_belanja"
				pesan.text = ""
				return
			if hp != null and hp.visible:
				_sorot_ke(hp.tombol_tutup, "Pesanan dibayar! Klik Tutup HP, lalu tunggu kurir mengantar barangnya ke warung.")
			else:
				if sorot.visible:
					sorot.lepas()
				if not _tut_kurir_dijelaskan:
					_tut_kurir_dijelaskan = true
					tampilkan_pesan("Tunggu sebentar, kurir sedang mengantar stok ke warung...", 30.0)
		"asli_buka":
			if hp != null and hp.visible:
				_sorot_ke(hp.tombol_tutup, "Stok sudah datang! Klik Tutup HP.")
			elif not GameState.kekurangan_stok().is_empty():
				GameState.tutorial_langkah = "asli_belanja"
			elif GameState.menit < GameState.jam_buka():

				if sorot.visible:
					sorot.lepas()
				if not _tut_tunggu_buka_dijelaskan:
					_tut_tunggu_buka_dijelaskan = true
					tampilkan_pesan("Stok lengkap! Warung buka pukul 09.00.", 5.0)
			else:
				_sorot_ke(tombol_buka, "Stok sudah lengkap. Klik Buka Warung untuk mulai berjualan!")
		"tunggu_tutup":

			if GameState.mode_latihan and Time.get_ticks_msec() - tut_tutup_mulai < 3000:
				if sorot.visible:
					sorot.lepas()
				return
			if tombol_tutup.visible:
				_sorot_ke(tombol_tutup, "Sudah sore. Klik Tutup Warung untuk mengakhiri jualan hari ini.")
			elif sorot.visible:
				sorot.lepas()
		"keluar":
			if panel_tutup.visible:
				_sorot_ke(tombol_lanjut, "Ini rekap hari ini. Klik Keluar warung, lalu jalan pulang ke rumah untuk tidur.")
		_:
			if sorot.visible:
				sorot.lepas()


func _jalan_jalan(area: = "warung", muncul: = "depan_warung") -> void :
	if dialog_aktif or sedang_sholat or GameState.status_hari == "tutup":
		return
	if GameState.sedang_banjir():
		_kabari_banjir()
		return
	if GameState.status_hari == "buka":
		await $Layanan.bubarkan_semua("Bapak mau keluar sebentar ya? Nanti saya balik lagi, Pak.")
	GameState.tujuan_jelajah = {"area": area, "muncul": muncul}
	GameState.simpan()
	await _tabir_gelap(true)
	GameState.ganti_layar(self, "res://scenes/jelajah.tscn")




var _kerja_dikabari: = {}

func _cek_kabar_kerja() -> void :
	var id: = GameState.kerja_hari_ini()

	if GameState.mode_latihan or GameState.tutorial_langkah.begins_with("asli_") or id == "" or not GameState.kerja_tersedia(id) or dialog_aktif or panel_terbuka() or sedang_sholat or panel_tutup.visible:
		return
	var k: Dictionary = GameState.data_kerja(id)
	var kunci: = "%s:%d" % [id, GameState.hari]
	if not _kerja_dikabari.has(kunci):
		_kerja_dikabari[kunci] = true
		var isi: = _buka_jendela("Kerja sampingan tersedia", 560)
		_teks_jendela(isi, "%s butuh bantuan sekarang. %s\nReward %s, sampai pukul %s." % [String(k["nama"]), String(k["teks"]), 
			GameState.format_rupiah(GameState.upah_kerja(id)), "%02d.%02d" % [int(k["jam"][1]), int(fmod(float(k["jam"][1]), 1.0) * 60.0)]])
		_tombol_kejadian(isi, [
			["Pergi ke sana", &"TombolHijau", func(): _pergi_kerja(id)], 
			["Nanti", &"TombolKayu", func(): pass], 
		])
		return
	var akhir: = "%s:akhir" % kunci
	if not _kerja_dikabari.has(akhir) and GameState.menit >= float(k["jam"][1]) * 60.0 - 30.0:
		_kerja_dikabari[akhir] = true
		pass


func _pergi_kerja(id: String) -> void :
	if GameState.sedang_banjir():
		_kabari_banjir()
		return
	GameState.kerja_tujuan = id
	if GameState.status_hari == "tutup":

		GameState.tujuan_jelajah = {"area": "warung", "muncul": "depan_warung"}
		GameState.simpan()
		await _tabir_gelap(true)
		GameState.ganti_layar(self, "res://scenes/jelajah.tscn")
		return
	_jalan_jalan()



var _tutup_jam_lima: = false




const JAM_PAKSA_TUTUP: = 18 * 60



var _banjir: Node2D = null
var _tombol_lewati_banjir: Button = null
var _banjir_dikabari_hari: = -1



func _jalan_ditutup_banjir() -> bool:
	if not GameState.banjir_hari_ini():
		return false
	return GameState.sedang_banjir() or (GameState.menit >= float(GameState.cuaca["banjir"]) - 20.0 and GameState.menit < float(GameState.cuaca["banjir"]))


func _kabari_banjir() -> void :
	notifikasi("Jalanan banjir!", "Tidak bisa lewat, tunggu surut.", "", WARNA_NOTIF_BURUK)


func _perbarui_banjir() -> void :
	GameState.cek_mulai_banjir(true)
	var mau: = GameState.sedang_banjir()
	if mau and _banjir == null:
		_banjir = preload("res://scripts/banjir.gd").new()
		latar.add_child(_banjir)
		latar.move_child(_banjir, %WadahPelanggan.get_index())

		if GameState.menit - float(GameState.cuaca["banjir"]) < 20.0:
			_banjir.naikkan_ke(1.0, 8.0)
		else:
			_banjir.tinggi = 1.0
		$Layanan.kabur_semua()
		for k in (lalu_lintas.get_children() if lalu_lintas != null else []):
			k.queue_free()
		if _banjir_dikabari_hari != GameState.hari:
			_banjir_dikabari_hari = GameState.hari
			_kabari_banjir()
	elif not mau and _banjir != null:
		var b: = _banjir
		_banjir = null
		b.naikkan_ke(0.0, 5.0).tween_callback(b.queue_free)
		if GameState.banjir_hari_ini() and GameState.menit >= GameState.BANJIR_SURUT:
			notifikasi("Banjir sudah surut", "Jalanan bisa dilewati lagi.", "", WARNA_NOTIF_BIASA)
	_atur_tombol_lewati_banjir(mau)


func _atur_tombol_lewati_banjir(tampil: bool) -> void :
	if tampil and _tombol_lewati_banjir == null:
		var b: = Button.new()
		b.text = "Lewati sampai surut (17.00)"
		GH.gaya_tombol(b, true, 26)
		b.custom_minimum_size = Vector2(420, 70)
		b.anchor_left = 0.5
		b.anchor_right = 0.5
		b.anchor_top = 1.0
		b.anchor_bottom = 1.0
		b.grow_horizontal = Control.GROW_DIRECTION_BOTH
		b.offset_left = -210
		b.offset_right = 210
		b.offset_top = - (UKURAN_IKON_DOCK + 110.0)
		b.offset_bottom = - (UKURAN_IKON_DOCK + 40.0)
		b.pressed.connect(_lewati_banjir)
		akar_ui.add_child(b)
		_tombol_lewati_banjir = b
	if _tombol_lewati_banjir != null:
		_tombol_lewati_banjir.visible = tampil and not dialog_aktif and not panel_terbuka()


func _lewati_banjir() -> void :
	if not GameState.sedang_banjir() or dialog_aktif:
		return
	var tabir_lewat: = ColorRect.new()
	tabir_lewat.color = Color(0, 0, 0, 0)
	tabir_lewat.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tabir_lewat.mouse_filter = Control.MOUSE_FILTER_STOP
	akar_ui.add_child(tabir_lewat)
	var tw: = tabir_lewat.create_tween()
	tw.tween_property(tabir_lewat, "color:a", 0.85, 0.5)
	await tw.finished
	GameState.majukan_waktu(GameState.BANJIR_SURUT - GameState.menit)
	_perbarui_banjir()
	_perbarui_tampilan()
	tampilkan_pesan("Menunggu air surut... Sekarang sudah %s." % GameState.teks_jam(), 2.5)
	var tw2: = tabir_lewat.create_tween()
	tw2.tween_property(tabir_lewat, "color:a", 0.0, 0.6)
	tw2.tween_callback(tabir_lewat.queue_free)


var _peringatan_tutup_hari: = -1
var _sedang_menutup: = false

func _cek_wajib_tutup() -> void :
	if GameState.status_hari != "buka" or GameState.menit < GameState.jam_wajib_tutup() or dialog_aktif or panel_terbuka() or _sedang_menutup:
		return
	if _peringatan_tutup_hari != GameState.hari:
		_peringatan_tutup_hari = GameState.hari
		if GameState.kios_milik:
			notifikasi("Warung harus tutup sekarang", "Sudah %s. Layani pembeli yang masih antre, lalu tutup warung: %s." % [GameState.teks_jam_tutup(true), GameState.alasan_wajib_tutup()], "", WARNA_NOTIF_BIASA)
		else:
			notifikasi("Warung harus tutup sekarang", "Sudah %s. Layani" % GameState.teks_jam_tutup(true) + " pembeli yang masih antre, lalu tutup sebelum Pak Haji Rasyid mendatangi warung.", "", WARNA_NOTIF_BIASA)
	var masih_antre: bool = not $Layanan.antrean.is_empty()

	if masih_antre and GameState.menit < maxi(JAM_PAKSA_TUTUP, GameState.jam_wajib_tutup() + 60):
		return

	if $Layanan.sedang_transaksi():
		return
	_tutup_jam_lima = true
	_sedang_menutup = true
	if not masih_antre:
		tampilkan_pesan("Alhamdulillah, pembeli terakhir sudah dilayani. Saatnya tutup warung.", 2.5)
		await GameState.get_tree().create_timer(1.8, false).timeout
	_sedang_menutup = false
	if GameState.status_hari == "buka":
		_on_tutup_ditekan()



var _gelap_kios: Sprite2D = null



func _kios_kosong_gelap() -> bool:
	return GameState.kios_tampak_tutup() and (bapak_3d == null or not bapak_3d.visible)


func _perbarui_gelap_kios(delta: float) -> void :
	if not LATAR_LUAS:
		return
	if _gelap_kios == null:
		_gelap_kios = GameState.buat_gelap_kios()
		_gelap_kios.position = _ke_lokal(Vector2.ZERO)
		latar.add_child(_gelap_kios)

		latar.move_child(_gelap_kios, %WadahPelanggan.get_index() + 1)
		_gelap_kios.modulate.a = 1.0 if _kios_kosong_gelap() else 0.0
	_gelap_kios.modulate.a = move_toward(_gelap_kios.modulate.a, 1.0 if _kios_kosong_gelap() else 0.0, delta * 1.5)




const DETIK_SEBELUM_DUDUK: = 6.0
var _sepi_detik: = 0.0



func _ada_pembeli_di_meja() -> bool:
	for p in $Layanan.antrean:
		if p["status"] in ["menyapa", "depan", "dilayani"]:
			return true
	return false


func _atur_duduk(delta: float) -> void :
	if bapak_3d == null or bapak_3d.karakter == null or not bapak_3d.karakter.has_method("bisa_duduk"):
		return
	var k = bapak_3d.karakter
	var sibuk_layani: bool = _ada_pembeli_di_meja() or kurir != null or truk != null or preman != null or tamu_kiriman != null or sedang_sholat\
	or bapak_3d.sedang_jalan or GameState.status_hari != "buka"
	if sibuk_layani:
		_sepi_detik = 0.0
		if k.duduk:
			k.berdiri_dari_duduk()
		return
	_sepi_detik += delta
	if _sepi_detik >= DETIK_SEBELUM_DUDUK and not k.duduk:
		k.mulai_duduk()
		_emot_detik = randf_range(4.0, 7.0)

	if k.duduk:
		_emot_detik -= delta
		if _emot_detik <= 0.0:
			_emot_detik = randf_range(9.0, 16.0)
			if GameState.energi < 40.0 or GameState.malam_hari():
				emot(bapak_3d, "Zzz", Color(0.55, 0.7, 1.0))
			else:
				emot(bapak_3d, ["♪", "♫", "♪♫"].pick_random(), Color(1.0, 0.85, 0.35))




var _emot_detik: = 0.0

const EMOT_SENYUM: = ":senyum"

func emot(orang: Sprite2D, teks: String, warna: = Color.WHITE) -> void :
	if orang == null or not is_instance_valid(orang):
		return
	var kotak: = PanelContainer.new()
	var gaya: = StyleBoxFlat.new()
	gaya.bg_color = Color(1, 1, 1, 0.92)
	gaya.set_corner_radius_all(16)
	gaya.content_margin_left = 10
	gaya.content_margin_right = 10
	gaya.content_margin_top = 2
	gaya.content_margin_bottom = 2
	gaya.shadow_color = Color(0, 0, 0, 0.25)
	gaya.shadow_size = 4
	kotak.add_theme_stylebox_override("panel", gaya)
	kotak.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if teks == EMOT_SENYUM:

		var wajah: = Control.new()
		wajah.custom_minimum_size = Vector2(32, 34)
		wajah.mouse_filter = Control.MOUSE_FILTER_IGNORE
		wajah.draw.connect( func():
			var c: = Vector2(16, 17)
			wajah.draw_circle(c, 13.0, Color(1.0, 0.82, 0.22))
			wajah.draw_arc(c, 13.0, 0.0, TAU, 32, Color(0.75, 0.5, 0.1), 1.5, true)
			wajah.draw_circle(c + Vector2(-4.5, -3.5), 1.9, Color(0.3, 0.18, 0.08))
			wajah.draw_circle(c + Vector2(4.5, -3.5), 1.9, Color(0.3, 0.18, 0.08))
			wajah.draw_arc(c + Vector2(0, 0.5), 7.0, deg_to_rad(20), deg_to_rad(160), 12, Color(0.3, 0.18, 0.08), 2.0, true))
		kotak.add_child(wajah)
	else:
		var l: = Label.new()
		l.text = teks
		l.add_theme_font_size_override("font_size", 26)
		l.add_theme_color_override("font_color", warna.darkened(0.25))
		kotak.add_child(l)
	akar_ui.add_child(kotak)
	akar_ui.move_child(kotak, 0)

	var tinggi: float = orang.tinggi_badan() * (0.7 if orang.karakter != null and orang.karakter.get("duduk") == true else 1.0)
	kotak.reset_size()
	kotak.pivot_offset = kotak.size / 2.0
	kotak.scale = Vector2(0.4, 0.4)


	var ikut: = func(t: float):
		if not is_instance_valid(orang) or not orang.is_inside_tree():
			kotak.queue_free()
			return
		var kepala: Vector2 = orang.get_parent().get_global_transform_with_canvas() * (orang.position - Vector2(0, tinggi + 30.0))
		var naik: = 30.0 * clampf((t - 1.15) / 0.6, 0.0, 1.0)
		kotak.position = kepala - Vector2(kotak.size.x / 2.0, kotak.size.y + naik)
	ikut.call(0.0)
	var tw: = kotak.create_tween()
	tw.tween_method(ikut, 0.0, 1.75, 1.75)
	tw.parallel().tween_property(kotak, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(kotak, "modulate:a", 0.0, 0.6).set_delay(1.15)
	tw.tween_callback(kotak.queue_free)




var _terpental: = false

func _cek_kelelahan() -> void :
	if _terpental or GameState.energi >= GameState.ENERGI_MIN_BUKA or dialog_aktif or panel_terbuka()\
	or sedang_sholat or GameState.status_hari == "tutup" or GameState.sedang_banjir():
		return
	_terpental = true
	GameState.tujuan_jelajah = {"area": "warung", "muncul": "depan_warung", "alasan": "lelah"}
	if GameState.status_hari == "buka":
		await $Layanan.bubarkan_semua("Pak Misran kelihatan capek sekali. Saya balik lagi nanti saja, Pak.")
	tampilkan_pesan("Pak Misran kelelahan dan tidak kuat jaga warung...", 3.0)
	GameState.simpan()
	await _tabir_gelap(true)
	GameState.ganti_layar(self, "res://scenes/jelajah.tscn")



func tombol_kembali() -> void :
	if not dialog_aktif and not panel_terbuka():
		_on_menu_ditekan()



func lokasi_simpan() -> Dictionary:
	return {"adegan": "warung"}





var _tabir: ColorRect

func _tabir_gelap(gelap: bool) -> void :
	if _tabir == null:
		var lapis: = CanvasLayer.new()
		lapis.layer = 120
		add_child(lapis)
		_tabir = ColorRect.new()
		_tabir.color = Color(0.06, 0.04, 0.02)
		_tabir.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		_tabir.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_tabir.modulate.a = 0.0 if gelap else 1.0
		lapis.add_child(_tabir)
	if not gelap:

		for i in 3:
			await get_tree().process_frame
	var tw: = create_tween()
	tw.tween_property(_tabir, "modulate:a", 1.0 if gelap else 0.0, 0.25 if gelap else 0.4)
	await tw.finished



func pergi_ke(area: String, muncul: String) -> void :
	if area == "warung" and muncul == "depan_warung":
		return
	_jalan_jalan(area, muncul)


func buka_hp(aplikasi: = "") -> void :
	if dialog_aktif or GameState.status_hari == "tutup":
		return
	hp.buka(aplikasi)


func buka_chat_agus() -> void :
	buka_hp("mbanking")


func _on_panel_tugas_input(e: InputEvent) -> void :


	var ketuk: bool = (e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT)
	if ketuk:
		GameState.klik()
		tugas_terbuka = not tugas_terbuka
		GameState.tandai_dilihat("misi")
		_perbarui_tugas()



func _perbarui_lencana_hp() -> void :
	if lencana_hp == null:
		return
	var total: int = SCRIPT_HP.total_notif()
	UI_HP.atur_lencana(lencana_hp, total)

	if total > _notif_lalu and tombol_hp.is_visible_in_tree():
		var getar: = tombol_hp.create_tween()
		for sudut in [-14.0, -2.0, -14.0, -2.0, 0.0]:
			getar.tween_property(tombol_hp, "rotation_degrees", sudut, 0.06)
	_notif_lalu = total


func _on_upgrade_dibeli(id: String) -> void :
	var u: = GameState.data_upgrade(id)
	uang_melayang("-" + GameState.format_rupiah(GameState.harga_upgrade(id)))
	_perbarui_visual_upgrade()
	_perbarui_tampilan()
	for b in u.get("efek", {}).get("buka_barang", []):
		tampilkan_pesan("%s terpasang! Sekarang bisa jual %s." % [u["nama"], String(GameState.data_barang(b)["nama"]).to_lower()], 5.0)


const SCRIPT_OBJEK3D: = preload("res://scripts/objek3d.gd")
const FOLDER_MODEL_UPGRADE: = "res://assets/upgrade/"

const PIKSEL_PER_METER_OBJEK: = 100.0

const POSISI_SPANDUK: = Vector2(563, 420)
const UKURAN_SPANDUK: = Vector2(103, 40)
const BATAS_PITA_SPANDUK: = 4


const KEMIRINGAN_SPANDUK: = 0.31


static func tulisan_spanduk() -> Array:
	for id in GameState.urutan_barang:
		if GameState.data_barang(id)["jenis"] == "layanan" and GameState.terbuka(id):
			return ["SEDIA TOP-UP E-WALLET", "DAN PAKET DATA"]

	if GameState.terbuka("lpg") or GameState.terbuka("galon"):
		return ["SEDIA SEMBAKO", "GAS & AIR GALON"]
	return ["SEDIA SEMBAKO", "& JAJANAN"]

const TITIK_BOHLAM: = Vector2(900, 330)
var visual_upgrade: = {}

var pratinjau_upgrade: = false
var lampu_terang: = false
var cahaya_lampu: Sprite2D = null




func _perbarui_visual_upgrade() -> void :
	var ppm: = PIKSEL_PER_METER_OBJEK
	for u in GameState.daftar_upgrade + GameState.daftar_dekorasi:
		var id: String = u["id"]
		var v: Dictionary = u.get("visual", {})

		var tampil: = GameState.terbuka(String(u["barang"])) if u.has("barang") else GameState.punya_upgrade(id)

		if u.has("wishlist"):
			tampil = GameState.punya_wishlist(String(u["wishlist"]))

		if u.has("ikut"):
			tampil = GameState.punya_upgrade(String(u["ikut"]))

		for lain in GameState.upgrade_dimiliki:
			if GameState.data_upgrade(lain).get("visual", {}).get("ganti", "") == id:
				tampil = false
		if pratinjau_upgrade:
			tampil = true
		if v.get("cahaya", false):
			lampu_terang = tampil
			continue

		if tampil and v.get("spanduk", false) and visual_upgrade.has(id) and visual_upgrade[id].get_meta("tulisan", []) != tulisan_spanduk():
			visual_upgrade[id].queue_free()
			visual_upgrade.erase(id)
		if tampil == visual_upgrade.has(id):
			continue
		if not tampil:
			visual_upgrade[id].queue_free()
			visual_upgrade.erase(id)
			continue
		if v.get("spanduk", false):
			visual_upgrade[id] = _buat_spanduk()
		elif v.has("model"):
			var obj: Sprite2D = SCRIPT_OBJEK3D.new()
			%WadahPelanggan.add_child(obj)
			if v.has("di_atas"):
				v = posisi_di_atas(v, ppm)
			obj.position = _ke_lokal(Vector2(v["posisi"][0], v["posisi"][1]))
			obj.modulate = cahaya_karakter
			if obj.pasang(FOLDER_MODEL_UPGRADE + String(v["model"]), float(v.get("tinggi_m", 1.0)), ppm, v):

				if v.has("potong"):
					var g: Array = v["potong"]["garis"]
					obj.potong(_ke_lokal(Vector2(g[0][0], g[0][1])), _ke_lokal(Vector2(g[1][0], g[1][1])), float(v["potong"].get("sisi", 1.0)))
				visual_upgrade[id] = obj
			else:
				obj.queue_free()
	if lampu_terang and cahaya_lampu == null:
		cahaya_lampu = _buat_cahaya_lampu()






static func posisi_di_atas(v: Dictionary, ppm: float) -> Dictionary:
	var d: Dictionary = v["di_atas"]
	var induk: Dictionary = GameState.data_upgrade(String(d["induk"])).get("visual", {})
	var hasil: = v.duplicate()
	if induk.is_empty():
		return hasil
	var sudut: = deg_to_rad(SCRIPT_OBJEK3D.SUDUT_KAMERA)
	var putar: = deg_to_rad(float(induk.get("hadap", 0.0)))
	var x: = float(d.get("x", 0.0))
	var z: = float(d.get("z", 0.0))
	var geser: = Vector2(x * cos(putar) + z * sin(putar), ( - x * sin(putar) + z * cos(putar)) * sin(sudut)) * ppm
	var dasar: = Vector2(induk["posisi"][0], induk["posisi"][1])
	var titik: = dasar + geser
	var turun: = maxf(dasar.y + 2.0 - titik.y, 0.0)
	hasil["posisi"] = [titik.x, titik.y + turun]
	hasil["angkat"] = float(induk.get("tinggi_m", 1.0)) * cos(sudut) * ppm + turun
	return hasil




static func jejak_upgrade(v: Dictionary, ppm: float) -> PackedVector2Array:
	var j: Array = v.get("jejak", [0.5, 0.5])
	var sudut: = deg_to_rad(SCRIPT_OBJEK3D.SUDUT_KAMERA)
	var putar: = deg_to_rad(float(v.get("hadap", 0.0)))
	var sb_x: = Vector2(cos(putar), - sin(putar) * sin(sudut)) * ppm * float(j[0]) / 2.0
	var sb_z: = Vector2(sin(putar), cos(putar) * sin(sudut)) * ppm * float(j[1]) / 2.0
	var p: = Vector2(v["posisi"][0], v["posisi"][1])
	return PackedVector2Array([p - sb_x - sb_z, p + sb_x - sb_z, p + sb_x + sb_z, p - sb_x + sb_z])


func ganti_pratinjau_upgrade() -> void :
	pratinjau_upgrade = not pratinjau_upgrade
	_perbarui_visual_upgrade()
	tampilkan_pesan("Pratinjau: semua upgrade tampil (F9 lagi = kembali normal)" if pratinjau_upgrade else "Pratinjau upgrade mati")


func _buat_spanduk() -> Node2D:
	var akar: = rakit_spanduk(_ke_lokal(POSISI_SPANDUK), font_papan)
	latar.add_child(akar)
	latar.move_child(akar, %WadahPelanggan.get_index())
	return akar



static func rakit_spanduk(pos: Vector2, font: Font) -> Node2D:
	var akar: = Node2D.new()
	var papan: = Node2D.new()
	papan.transform = Transform2D(Vector2(1, KEMIRINGAN_SPANDUK), Vector2(0, 1), pos)
	akar.add_child(papan)

	var papan_teks: = Node2D.new()
	var geser: = Vector2(0, (KEMIRINGAN_SPANDUK - KEMIRINGAN_PAPAN) * UKURAN_SPANDUK.x / 2.0)
	papan_teks.transform = Transform2D(Vector2(1, KEMIRINGAN_PAPAN), Vector2(0, 1), pos + geser)
	akar.add_child(papan_teks)

	var kain: = PanelContainer.new()
	var gaya: = StyleBoxFlat.new()
	gaya.bg_color = Color(0.09, 0.33, 0.72)
	gaya.border_color = Color(1.0, 0.8, 0.12)
	gaya.border_width_top = BATAS_PITA_SPANDUK
	gaya.border_width_bottom = BATAS_PITA_SPANDUK
	gaya.border_width_left = 1
	gaya.border_width_right = 1
	gaya.set_corner_radius_all(2)
	gaya.set_content_margin_all(1)
	gaya.shadow_color = Color(0, 0, 0, 0.35)
	gaya.shadow_size = 2
	gaya.shadow_offset = Vector2(1, 2)
	kain.add_theme_stylebox_override("panel", gaya)
	kain.custom_minimum_size = UKURAN_SPANDUK
	kain.size = UKURAN_SPANDUK
	kain.mouse_filter = Control.MOUSE_FILTER_IGNORE
	papan.add_child(kain)


	var tulisan: = tulisan_spanduk()
	akar.set_meta("tulisan", tulisan)
	var teks: Control = SCRIPT_TEKS_TENGAH.new()
	teks.tepi = 5.0
	teks.jarak_baris = 0.4
	teks.warna_garis = Color(0.03, 0.12, 0.35)
	teks.tebal_garis = 2
	teks.position = Vector2(0, BATAS_PITA_SPANDUK)
	teks.atur(font, [[tulisan[0], Color(1.0, 0.86, 0.2), 15], [tulisan[1], Color.WHITE, 12]], 
		UKURAN_SPANDUK - Vector2(0, BATAS_PITA_SPANDUK * 2))
	papan_teks.add_child(teks)
	return akar



func _buat_cahaya_lampu() -> Sprite2D:
	var g: = Gradient.new()
	g.set_color(0, Color(1.0, 0.85, 0.55, 0.55))
	g.set_color(1, Color(1.0, 0.85, 0.55, 0.0))
	var tekstur: = GradientTexture2D.new()
	tekstur.gradient = g
	tekstur.fill = GradientTexture2D.FILL_RADIAL
	tekstur.fill_from = Vector2(0.5, 0.5)
	tekstur.fill_to = Vector2(1.0, 0.5)
	tekstur.width = 256
	tekstur.height = 256
	var s: = Sprite2D.new()
	s.texture = tekstur
	s.scale = Vector2(2.6, 1.9)
	s.position = _ke_lokal(TITIK_BOHLAM + Vector2(0, 90))
	var bahan: = CanvasItemMaterial.new()
	bahan.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	s.material = bahan
	latar.add_child(s)
	latar.move_child(s, %WadahPelanggan.get_index())
	return s



func _warna_suasana() -> Color:
	var c: = GameState.warna_suasana()
	var gelap: = clampf(1.0 - c.get_luminance(), 0.0, 1.0)

	var lampu_nyala: = lampu_terang and not GameState.listrik_padam()
	if lampu_nyala:
		c = c.lerp(Color(1.0, 0.95, 0.85), 0.5 * gelap)
	if cahaya_lampu != null:
		cahaya_lampu.modulate.a = clampf(gelap * 1.6, 0.0, 1.0) if lampu_nyala else 0.0

	c = c.lerp(Color.WHITE, 0.75 * campur_malam)

	return c * GameState.warna_kejadian()







func _tampilkan_stok_kurang(kurang: Array) -> void :
	GameState.bunyi("salah")
	var lapisan: = ColorRect.new()
	lapisan.color = Color(0.03, 0.02, 0.01, 0.6)
	lapisan.set_anchors_preset(Control.PRESET_FULL_RECT)
	akar_ui.add_child(lapisan)
	var tengah: = CenterContainer.new()
	tengah.set_anchors_preset(Control.PRESET_FULL_RECT)
	lapisan.add_child(tengah)
	var panel: = PanelContainer.new()
	panel.custom_minimum_size = Vector2(700, 0)
	tengah.add_child(panel)
	var isi: = VBoxContainer.new()
	isi.add_theme_constant_override("separation", 14)
	panel.add_child(isi)

	var semua_diantar: = true
	for k in kurang:
		if GameState.stok[k[0]] + k[2] < GameState.MIN_STOK_BUKA:
			semua_diantar = false
	var biaya: = GameState.biaya_lengkapi_stok()
	var uang_cukup: = GameState.uang >= biaya
	var warna_aksen: = Color(0.24, 0.62, 0.86) if semua_diantar else Color(0.89, 0.36, 0.25)


	var kepala: = HBoxContainer.new()
	kepala.add_theme_constant_override("separation", 16)
	isi.add_child(kepala)
	var bulat: = PanelContainer.new()
	var gaya_bulat: = StyleBoxFlat.new()
	gaya_bulat.bg_color = warna_aksen
	gaya_bulat.set_corner_radius_all(40)
	gaya_bulat.set_content_margin_all(14)
	bulat.add_theme_stylebox_override("panel", gaya_bulat)
	bulat.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	kepala.add_child(bulat)
	var ikon: = TextureRect.new()
	ikon.texture = load("res://assets/ikon/kotak.svg" if semua_diantar else "res://assets/ikon/keranjang.svg")
	ikon.custom_minimum_size = Vector2(52, 52)
	ikon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ikon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	bulat.add_child(ikon)
	var teks_kepala: = VBoxContainer.new()
	teks_kepala.add_theme_constant_override("separation", 2)
	teks_kepala.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	kepala.add_child(teks_kepala)
	var judul: = Label.new()
	judul.theme_type_variation = &"LabelKepala"
	judul.add_theme_font_size_override("font_size", 34)
	judul.text = "Tunggu kurir dulu" if semua_diantar else "Stok belum cukup"
	teks_kepala.add_child(judul)
	var ket: = Label.new()
	ket.add_theme_font_size_override("font_size", 19)
	ket.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if semua_diantar:
		ket.text = "Barangnya sudah dibayar. Buka warung setelah kurir datang."
	else:
		ket.text = "Setiap barang minimal %d stok sebelum warung dibuka." % GameState.MIN_STOK_BUKA
		if not uang_cukup:
			ket.text += " Uangmu kurang (butuh %s), boleh tetap buka." % GameState.format_rupiah(biaya)
	teks_kepala.add_child(ket)


	var kisi: = GridContainer.new()
	kisi.columns = 4 if kurang.size() > 9 else (3 if kurang.size() > 4 else maxi(kurang.size(), 2))
	kisi.add_theme_constant_override("h_separation", 10)
	kisi.add_theme_constant_override("v_separation", 10)
	kisi.size_flags_horizontal = Control.SIZE_SHRINK_CENTER

	var baris_kartu: = ceili(kurang.size() / float(kisi.columns))
	var tinggi_maks: = maxf(get_viewport().get_visible_rect().size.y - 330.0, 140.0)
	if baris_kartu * 76.0 > tinggi_maks:
		var gulir: ScrollContainer = load("res://scripts/hp/gulir_sentuh.gd").new()
		gulir.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		gulir.custom_minimum_size = Vector2(0, tinggi_maks)
		isi.add_child(gulir)
		gulir.add_child(kisi)
	else:
		isi.add_child(kisi)
	for k in kurang:
		var id: String = k[0]
		var kartu: = PanelContainer.new()
		kartu.custom_minimum_size = Vector2(200 if kisi.columns == 4 else 212, 0)
		var gaya: = StyleBoxFlat.new()
		gaya.bg_color = Color(1, 1, 1, 0.7)
		gaya.border_color = Color(0.82, 0.7, 0.52)
		gaya.set_border_width_all(2)
		gaya.set_corner_radius_all(14)
		gaya.content_margin_left = 10
		gaya.content_margin_right = 10
		gaya.content_margin_top = 8
		gaya.content_margin_bottom = 8
		kartu.add_theme_stylebox_override("panel", gaya)
		kisi.add_child(kartu)
		var baris: = HBoxContainer.new()
		baris.add_theme_constant_override("separation", 8)
		kartu.add_child(baris)
		var gambar: = TextureRect.new()
		var file: = "res://assets/barang/%s.png" % id
		if ResourceLoader.exists(file):
			gambar.texture = load(file)
		gambar.custom_minimum_size = Vector2(54, 54)
		gambar.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		gambar.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		baris.add_child(gambar)
		var kanan: = VBoxContainer.new()
		kanan.add_theme_constant_override("separation", 4)
		kanan.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		kanan.alignment = BoxContainer.ALIGNMENT_CENTER
		baris.add_child(kanan)
		var nama: = Label.new()
		nama.text = String(GameState.data_barang(id)["nama"])
		nama.add_theme_font_size_override("font_size", 17)
		nama.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		nama.custom_minimum_size.x = 120
		kanan.add_child(nama)
		var cukup_nanti: bool = GameState.stok[id] + k[2] >= GameState.MIN_STOK_BUKA
		var pil: = Label.new()
		pil.text = ("+%d dikirim" % k[2]) if k[2] > 0 else "stok %d / %d" % [GameState.stok[id], GameState.MIN_STOK_BUKA]
		pil.add_theme_font_size_override("font_size", 15)
		pil.add_theme_color_override("font_color", Color.WHITE)
		pil.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		pil.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		var gaya_pil: = StyleBoxFlat.new()
		gaya_pil.bg_color = Color(0.24, 0.62, 0.86) if cukup_nanti else Color(0.89, 0.36, 0.25)
		gaya_pil.set_corner_radius_all(10)
		gaya_pil.content_margin_left = 10
		gaya_pil.content_margin_right = 10
		gaya_pil.content_margin_top = 1
		gaya_pil.content_margin_bottom = 2
		pil.add_theme_stylebox_override("normal", gaya_pil)
		kanan.add_child(pil)


	if semua_diantar:
		var bar: = ProgressBar.new()
		bar.show_percentage = false
		bar.custom_minimum_size = Vector2(0, 22)
		bar.max_value = 1.0
		var latar_bar: = StyleBoxFlat.new()
		latar_bar.bg_color = Color(0.83, 0.74, 0.55)
		latar_bar.set_corner_radius_all(11)
		var isi_bar: = StyleBoxFlat.new()
		isi_bar.bg_color = warna_aksen
		isi_bar.set_corner_radius_all(11)
		bar.add_theme_stylebox_override("background", latar_bar)
		bar.add_theme_stylebox_override("fill", isi_bar)
		isi.add_child(bar)
		var label_kurir: = Label.new()
		label_kurir.add_theme_font_size_override("font_size", 18)
		label_kurir.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		isi.add_child(label_kurir)
		var total: = maxf(GameState.durasi_kirim(), 1.0)
		var perbarui: = func() -> void :
			if GameState.kurir_dalam_perjalanan or GameState.detik_kiriman <= 0.0:
				bar.value = 1.0
				label_kurir.text = "Kurir sudah di jalan menuju warung!"
			else:
				bar.value = 1.0 - GameState.detik_kiriman / maxf(total, GameState.detik_kiriman)
				label_kurir.text = "Kurir datang sekitar %d detik lagi" % (ceili(GameState.detik_kiriman) + 5)
		perbarui.call()
		var detak: = Timer.new()
		detak.wait_time = 0.25
		detak.autostart = true
		detak.timeout.connect(perbarui)
		lapisan.add_child(detak)

	var bawah: = HBoxContainer.new()
	bawah.add_theme_constant_override("separation", 12)
	bawah.alignment = BoxContainer.ALIGNMENT_CENTER
	isi.add_child(bawah)
	var tombol: = func(teks: String, gaya: StringName, aksi: Callable) -> void :
		var t: = Button.new()
		t.text = teks
		t.theme_type_variation = gaya
		t.custom_minimum_size = Vector2(190, 64)
		t.add_theme_font_size_override("font_size", 24)
		t.pressed.connect( func():
			lapisan.queue_free()
			aksi.call())
		bawah.add_child(t)
	if semua_diantar:
		tombol.call("Oke", &"TombolHijau", func(): pass)
	else:
		tombol.call("Nanti", &"TombolKayu", func(): pass)
		if not uang_cukup:
			tombol.call("Buka saja", &"TombolKayu", func(): _on_buka_ditekan(true))
		tombol.call("Belanja di HP", &"TombolHijau", func(): buka_hp("belanja"))


	lapisan.modulate.a = 0.0
	panel.scale = Vector2(0.88, 0.88)
	panel.resized.connect( func(): panel.pivot_offset = panel.size / 2.0)
	var muncul: = lapisan.create_tween().set_parallel()
	muncul.tween_property(lapisan, "modulate:a", 1.0, 0.18)
	muncul.tween_property(panel, "scale", Vector2.ONE, 0.32).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)




func _pasang_info_hud() -> void :



	var panel_hari: Control = $UI / Akar / BarKiri.get_node("PanelHari")
	var panel_bintang: Control = bintang_hud[0].get_parent().get_parent()
	panel_bintang.tooltip_text = ""
	for pasangan in [[panel_hari, func(): buka_hp("kalender")], [panel_bintang, _info_reputasi]]:
		var t: = Button.new()
		t.flat = true
		t.focus_mode = Control.FOCUS_NONE
		t.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		t.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
		t.add_theme_stylebox_override("hover", StyleBoxEmpty.new())
		t.add_theme_stylebox_override("pressed", StyleBoxEmpty.new())
		var aksi: Callable = pasangan[1]
		t.pressed.connect( func():
			if not dialog_aktif:
				aksi.call())
		pasangan[0].add_child(t)





var _kolom_kiri: VBoxContainer
var _slot_energi: VBoxContainer
var lencana_peringkat: Control

func _gaya_hud() -> void :
	var kiri: HBoxContainer = $UI / Akar / BarKiri
	kiri.hide()
	_kolom_kiri = VBoxContainer.new()
	_kolom_kiri.add_theme_constant_override("separation", -2)
	_kolom_kiri.position = Vector2(16, 6)
	_kolom_kiri.mouse_filter = Control.MOUSE_FILTER_IGNORE
	akar_ui.add_child(_kolom_kiri)
	akar_ui.move_child(_kolom_kiri, kiri.get_index())


	var baris_atas: = HBoxContainer.new()
	baris_atas.add_theme_constant_override("separation", 26)
	baris_atas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_kolom_kiri.add_child(baris_atas)
	var kolom_jam: = VBoxContainer.new()
	kolom_jam.add_theme_constant_override("separation", -4)
	kolom_jam.mouse_filter = Control.MOUSE_FILTER_IGNORE
	baris_atas.add_child(kolom_jam)
	_label_jam_besar = GH.tebal(GH.label("07.00", GH.UKURAN_JAM_HUD, Color.WHITE, true))
	kolom_jam.add_child(_label_jam_besar)
	_label_tanggal = GH.tebal(GH.label("", GH.UKURAN_TANGGAL_HUD, Color.WHITE, true))
	_label_tanggal.mouse_filter = Control.MOUSE_FILTER_STOP
	_label_tanggal.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_label_tanggal.gui_input.connect( func(e: InputEvent):
		if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT and not dialog_aktif:
			GameState.klik()
			buka_hp("kalender"))
	kolom_jam.add_child(_label_tanggal)
	GH.kunci_lebar_jam(kolom_jam, _label_jam_besar, _label_tanggal)
	var kolom_rep: = VBoxContainer.new()
	kolom_rep.add_theme_constant_override("separation", 2)
	kolom_rep.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	kolom_rep.mouse_filter = Control.MOUSE_FILTER_IGNORE
	baris_atas.add_child(kolom_rep)
	kolom_rep.add_child(GH.tebal(GH.label("REPUTASI WARUNG", GH.UKURAN_JUDUL_HUD, GH.KUNING, true)))


	var panel_bintang: PanelContainer = bintang_hud[0].get_parent().get_parent()
	var panel_ulasan: PanelContainer = titik_ulasan.get_parent().get_parent()
	var baris: = HBoxContainer.new()
	baris.add_theme_constant_override("separation", 6)
	kolom_rep.add_child(baris)
	for p in [panel_bintang, panel_ulasan]:
		p.reparent(baris)
		p.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	bintang_hud[0].get_parent().get_child(0).hide()
	for b in bintang_hud:
		b.custom_minimum_size = Vector2.ONE * GH.UKURAN_BINTANG_HUD

	_slot_energi = VBoxContainer.new()
	_slot_energi.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_slot_energi.mouse_filter = Control.MOUSE_FILTER_IGNORE
	baris_atas.add_child(_slot_energi)

	var peringkat: = preload("res://scripts/lencana_peringkat.gd").new()
	peringkat.saat_diketuk = func(): if not dialog_aktif: _buka_papan_besar()
	baris_atas.add_child(peringkat)
	lencana_peringkat = peringkat
	GH.gaya_lencana(titik_ulasan)
	GH.gaya_lencana(titik_tugas)


	var panel_uang: PanelContainer = $UI / Akar / BarKanan / PanelUang
	panel_uang.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	panel_uang.get_node("Isi/Ikon").hide()
	GH.tebal(label_uang)
	GH.gaya_label(label_uang, 52, GH.HIJAU_UANG, true, 7)
	GH.tebal(label_uang)

	label_uang.add_theme_color_override("font_color", Color(0.6, 1.0, 0.32))
	label_uang.add_theme_color_override("font_outline_color", Color(0.04, 0.22, 0.04))
	label_uang.add_theme_constant_override("outline_size", 14)
	label_uang.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.6))
	label_uang.add_theme_constant_override("shadow_offset_y", 4)

	_label_qris = Label.new()
	GH.gaya_label(_label_qris, 26, Color(0.72, 0.9, 1.0), true, 6)
	_label_qris.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_label_qris.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label_qris.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_label_qris.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_label_qris.offset_top = -10
	_label_qris.offset_bottom = 24
	label_uang.add_child(_label_qris)
	for k in ["normal", "hover", "pressed", "hover_pressed", "focus"]:
		tombol_menu.add_theme_stylebox_override(k, StyleBoxEmpty.new())
	tombol_menu.custom_minimum_size = Vector2(50, 50)
	tombol_menu.add_theme_constant_override("icon_max_width", 36)
	tombol_menu.add_theme_color_override("icon_normal_color", Color.WHITE)
	GH.latar_kolom(_kolom_kiri, 0.5)
	_gaya_panel_level()





func _kanan_panel_level() -> float:
	var bar_kanan: Control = $UI / Akar / BarKanan
	return bar_kanan.offset_right - bar_kanan.size.x - 14.0


func _gaya_panel_level() -> void :
	var panel: PanelContainer = $UI / Akar / PanelTugas


	panel.offset_top = 7.0
	var bar_kanan: Control = $UI / Akar / BarKanan


	var tempel: = func():
		panel.offset_right = _kanan_panel_level()
		panel.offset_left = panel.offset_right - 1.0
		panel.offset_bottom = panel.offset_top + 1.0
	bar_kanan.resized.connect(tempel)
	tempel.call_deferred()
	get_tree().process_frame.connect(tempel, CONNECT_ONE_SHOT)


	var muat: = func():
		var kiri: Control = _kolom_kiri if _kolom_kiri != null else $UI / Akar / BarKiri as Control

		var kanan_panel: float = panel.get_global_rect().end.x
		var ruang: float = kanan_panel - kiri.get_global_rect().end.x - 12.0
		var s: float = clampf(ruang / maxf(panel.size.x, 1.0), 0.6, 1.0)
		panel.pivot_offset = Vector2(panel.size.x, 0.0)
		panel.scale = Vector2(s, s)
	panel.resized.connect(muat)
	bar_kanan.resized.connect( func(): muat.call_deferred())
	if _kolom_kiri != null:
		_kolom_kiri.resized.connect( func(): muat.call_deferred())
	muat.call_deferred()
	panel.add_theme_stylebox_override("panel", GH.kaca(0.6, 8, Vector4(10, 8, 16, 10)))
	var kepala: HBoxContainer = panel.get_node("Isi/Kepala")
	kepala.get_node("Ikon").hide()
	kepala.add_theme_constant_override("separation", 12)
	var kotak: = PanelContainer.new()
	kotak.add_theme_stylebox_override("panel", GH.kotak(GH.KUNING, 8, Vector4(12, 0, 12, 0)))
	kotak.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_angka_level = GH.label("1", 50, GH.TEKS_GELAP, true, 0)
	kotak.add_child(_angka_level)
	kepala.add_child(kotak)
	kepala.move_child(kotak, 0)
	var kolom: = VBoxContainer.new()
	kolom.add_theme_constant_override("separation", 2)
	kolom.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	kolom.mouse_filter = Control.MOUSE_FILTER_IGNORE
	kepala.add_child(kolom)
	judul_tugas.reparent(kolom)
	GH.gaya_label(judul_tugas, 24, Color.WHITE, true)
	var baris: = HBoxContainer.new()
	baris.add_theme_constant_override("separation", 8)
	baris.mouse_filter = Control.MOUSE_FILTER_IGNORE
	kolom.add_child(baris)
	_bar_level = Control.new()
	_bar_level.custom_minimum_size = Vector2(150, 9)
	_bar_level.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_bar_level.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bar_level.set_meta("isi", 0.0)
	_bar_level.draw.connect( func():
		_bar_level.draw_rect(Rect2(Vector2.ZERO, _bar_level.size), Color(1, 1, 1, 0.18))
		GH.gambar_bar(_bar_level, float(_bar_level.get_meta("isi")), GH.KUNING))
	baris.add_child(_bar_level)
	_teks_bar_level = GH.label("", 17, GH.KUNING, true)
	baris.add_child(_teks_bar_level)
	GH.gaya_label(label_tugas, 18, GH.KUNING)
	GH.tebal(label_tugas)



func _info_reputasi() -> void :
	var gs: = GameState
	var b: = gs.bintang()
	var isi: = _buka_jendela("Reputasi Warung", 760)
	var atas: = Label.new()
	atas.add_theme_font_size_override("font_size", 20)

	var r: = func(nilai: float) -> String: return String.num(nilai, 1).replace(".", ",")
	atas.text = "%d bintang · rating ulasan %s dari 5" % [b, gs.rating_teks()] + ("" if b >= 5 else "   (bintang %d di rating %s)" % [b + 1, r.call(1.0 + gs.BATAS_BINTANG[b] / 25.0)])
	if gs.ulasan.is_empty():
		atas.text = "Belum ada ulasan. Bintang muncul setelah pembeli mulai menulis ulasan."
	atas.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	isi.add_child(atas)

	var bar: = ProgressBar.new()
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(0, 26)
	bar.max_value = 100
	bar.value = gs.reputasi
	var latar_bar: = StyleBoxFlat.new()
	latar_bar.bg_color = Color(0.83, 0.74, 0.55)
	latar_bar.set_corner_radius_all(8)
	var isi_bar: = StyleBoxFlat.new()
	isi_bar.bg_color = Color(0.96, 0.62, 0.18)
	isi_bar.set_corner_radius_all(8)
	bar.add_theme_stylebox_override("background", latar_bar)
	bar.add_theme_stylebox_override("fill", isi_bar)
	isi.add_child(bar)
	bar.resized.connect( func():
		for anak in bar.get_children():
			anak.queue_free()
		for i in range(1, gs.BATAS_BINTANG.size()):
			var garis: = ColorRect.new()
			garis.color = Color(0.35, 0.22, 0.1)
			garis.size = Vector2(3, bar.size.y)
			garis.position = Vector2(bar.size.x * gs.BATAS_BINTANG[i] / 100.0 - 1.5, 0)
			bar.add_child(garis))

	var tabel: = GridContainer.new()
	tabel.columns = 2
	tabel.add_theme_constant_override("h_separation", 18)
	tabel.add_theme_constant_override("v_separation", 6)
	isi.add_child(tabel)
	for kepala in ["Bintang", "Keramaian pembeli"]:
		var l: = Label.new()
		l.text = kepala
		l.add_theme_font_size_override("font_size", 17)
		l.add_theme_color_override("font_color", Color(0.55, 0.38, 0.2))
		tabel.add_child(l)
	for n in range(1, 6):
		var e: = gs.efek_reputasi_bintang(n)

		var warna: = GH.KUNING if n == b else Color(GH.KUNING, 0.7)
		var bintang_kolom: = HBoxContainer.new()
		bintang_kolom.add_theme_constant_override("separation", 0)
		for i in n:
			var ikon: = TextureRect.new()
			ikon.texture = IKON_BINTANG
			ikon.custom_minimum_size = Vector2(18, 18)
			ikon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			ikon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			ikon.modulate.a = 1.0 if n == b else 0.55
			bintang_kolom.add_child(ikon)
		tabel.add_child(bintang_kolom)
		var sel: = ["%d%%" % int(round(100.0 / float(e["datang"])))]
		for teks in sel:
			var l: = Label.new()
			l.text = teks
			l.add_theme_font_size_override("font_size", 18)
			l.add_theme_color_override("font_color", warna)
			tabel.add_child(l)
	var catatan: = Label.new()
	catatan.text = "Cara menaikkan reputasi dan penjelasan lainnya ada di HP → Panduan."
	catatan.add_theme_font_size_override("font_size", 16)
	catatan.add_theme_color_override("font_color", Color(GH.KREM, 0.75))
	catatan.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	isi.add_child(catatan)
	_tombol_tutup_jendela(isi)




func _buka_jendela(judul: String, lebar: float) -> VBoxContainer:
	var lapisan: = ColorRect.new()
	lapisan.color = Color(0.03, 0.02, 0.01, 0.6)
	lapisan.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	akar_ui.add_child(lapisan)
	dialog_aktif = true
	var tengah: = CenterContainer.new()
	tengah.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	lapisan.add_child(tengah)
	var panel: = PanelContainer.new()
	panel.custom_minimum_size = Vector2(lebar, 0)
	tengah.add_child(panel)
	var isi: = VBoxContainer.new()
	isi.add_theme_constant_override("separation", 12)
	panel.add_child(isi)
	isi.set_meta("lapisan", lapisan)
	var label_judul: = Label.new()
	label_judul.text = judul.to_upper()
	GH.gaya_jendela(panel, label_judul)
	isi.add_child(label_judul)
	return isi



func _atur_tombol_bawah() -> void :
	pass



func _perbarui_promosi() -> void :
	var siap: = GameState.alasan_tidak_bisa_promosi() == ""
	lencana_promosi.visible = siap
	(lencana_promosi.get_node("Angka") as Label).text = "!"
	var label: Label = tombol_promosi.get_node("Label")
	label.text = "%d HARI" % GameState.sisa_hari_promosi() if GameState.promosi_aktif() else "PROMOSI"
	tombol_promosi.modulate.a = 1.0 if siap or GameState.promosi_aktif() else 0.6


func _buka_promosi() -> void :
	if dialog_aktif or panel_terbuka():
		return
	var isi: = _buka_jendela("Promosi Warung", 620)
	_teks_jendela(isi, "Sebar brosur dan pengumuman di grup warga: pembeli lebih ramai selama %d hari berturut-turut. Bisa diulang %d hari sesudah dimulai." % [GameState.LAMA_PROMOSI, GameState.JEDA_PROMOSI])
	var alasan: = GameState.alasan_tidak_bisa_promosi()
	if alasan != "":
		_teks_jendela(isi, alasan)
		_tombol_tutup_jendela(isi)
		return
	_tombol_kejadian(isi, [
		["Mulai promosi" if GameState.tanpa_iklan else "Tonton iklan", &"TombolHijau", _mulai_promosi], 
		["Nanti saja", &"TombolKayu", func(): pass], 
	])


func _mulai_promosi() -> void :
	dialog_aktif = true
	var berhasil: = await GameState.tonton_iklan(akar_ui)
	dialog_aktif = false
	if berhasil:
		GameState.mulai_promosi()
		GameState.bunyi("hadiah")
		tampilkan_pesan("Promosi dimulai selama %d hari!" % GameState.LAMA_PROMOSI, 4.0)




func _kabari_utang_ikhlas() -> void :

	if GameState.akun != null and GameState.akun.ambil_kabar_sesi_berakhir():
		notifikasi("Akun keluar", "Warung belum tersimpan ke cloud. Tautkan lagi di Pengaturan.", "", WARNA_NOTIF_BURUK)
	var daftar: Array = GameState.ambil_kabar_utang_ikhlas()
	if daftar.is_empty():
		return
	if daftar.size() == 1:
		notifikasi("Utang diikhlaskan", "Utang %s %s diikhlaskan karena sudah lama tidak ditagih." % [String(daftar[0]["nama"]), GameState.format_rupiah(int(daftar[0]["jumlah"]))], "", WARNA_NOTIF_BURUK)
	else:
		notifikasi("Utang diikhlaskan", "%d utang diikhlaskan karena sudah lama tidak ditagih. Lihat Buku Hutang." % daftar.size(), "", WARNA_NOTIF_BURUK)


func _buka_buku_hutang() -> void :
	if dialog_aktif or panel_terbuka():
		return
	var isi: = _buka_jendela("Buku Hutang", 700)
	BukuHutang.isi(isi)
	_tombol_tutup_jendela(isi)




signal _jawab_hutang(kasih: bool)





const AJAKAN_TIP: = {
	"kembalian": "\"Pak, uang saya besar nih. Coba hitung kembaliannya cepat-cepat. Kalau pas terus, sisanya buat Bapak!\"", 
	"bungkus": "\"Belanjaan saya banyak, Pak. Tolong dibungkus yang rapi ya, yang berat di bawah. Nanti ada tip!\"", 
	"langganan": "\"Pak Misran masih ingat belanjaan saya yang biasa? Kalau betul semua, ada tip buat Bapak!\"", 
	"qris": "\"Pak, kami bayar pakai QRIS, ya. Banyak yang suka pura-pura bayar, lho. Coba cek teliti, nanti ada tip!\"", 
}
signal _jawab_tip(main: bool)

func tawarkan_minigame_tip(tipe: String, qris: = false, belanja: = 0) -> void :
	var id: = "qris" if qris else GameState.minigame_tip_hari_ini()
	var d: Dictionary = GameState.MINIGAME_QRIS if qris else GameState.MINIGAME_TIP[id]

	var tip_maks: = int(d["tip"])
	if belanja > 0:
		tip_maks = mini(maxi(int(belanja / 500) * 500, 500), tip_maks)
	var nama: = String(GameState.daftar_warga().get(tipe, "Warga"))
	GameState.bunyi("notif")
	var isi: = _buka_jendela("%s mau kasih tip" % nama, 680)
	_teks_jendela(isi, String(AJAKAN_TIP[id]), 24)
	_teks_jendela(isi, "Mini-game singkat. Tip sampai %s kalau hasilnya bagus." % GameState.format_rupiah(tip_maks), 22)
	_tombol_kejadian(isi, [["Nanti saja", &"TombolKayu", func(): _jawab_tip.emit(false)], 
		["Main!", &"TombolHijau", func(): _jawab_tip.emit(true)]])
	if not await _jawab_tip:
		return
	dialog_aktif = true
	var mg: Control = load(String(d["file"])).new()
	mg.npc = tipe
	mg.tip_maks = tip_maks
	if latar != null and latar.texture != null:
		mg.latar = latar.texture.resource_path
	akar_ui.add_child(mg)
	var hasil: float = await mg.selesai
	dialog_aktif = false
	var tip: = GameState.tip_minigame(tip_maks, hasil)
	if tip > 0:
		GameState.uang += tip
		GameState.data_berubah.emit()
		GameState.bunyi("koin")
		uang_melayang("Tip +" + GameState.format_rupiah(tip), true)
	GameState.tambah_akrab(tipe, GameState.AKRAB_LAYANI)

func tanya_hutang(tipe: String, total: int, kalimat: String) -> bool:
	var nama: = String(GameState.daftar_warga().get(tipe, VarianBaju.nama_catatan(tipe) if VarianBaju.ada(tipe) else "Pembeli"))
	GameState.bunyi("notif")
	var isi: = _buka_jendela("%s minta ngutang" % nama, 660)
	_teks_jendela(isi, "\"%s\"" % kalimat, 24)

	_teks_jendela(isi, "Belanjaannya %s." % GameState.format_rupiah(total), 22)
	_tombol_kejadian(isi, [["Tolak", &"TombolHijau", func(): _jawab_hutang.emit(false)], 
		["Kasih utang", &"TombolHijau", func(): _jawab_hutang.emit(true)]])
	return await _jawab_hutang



signal _jawab_tagihan(pilihan: String)

func _tanya_tagihan(i_utang: int, nama: String) -> String:
	var h: Dictionary = GameState.hutang[i_utang]
	var jumlah: = int(h["jumlah"])
	var separuh: = GameState.cicilan_utang(jumlah)
	var bisa_cicil: = GameState.bisa_cicil_utang(jumlah)
	GameState.bunyi("notif")
	var isi: = _buka_jendela("%s datang soal utang" % nama, 700)
	_teks_jendela(isi, "Utangnya %s. Bagaimana, Pak Misran?" % GameState.format_rupiah(jumlah), 23)
	var bernama: = GameState.daftar_warga().has(String(h["tipe"]))
	if bisa_cicil:
		_teks_jendela(isi, ("Tagih penuh: uang kembali, tapi ia agak sungkan. Cicil: separuh dulu (%s), sisanya hari buka berikutnya. Ikhlaskan: uangnya relakan, ia sangat berterima kasih." if bernama
			else "Tagih penuh: uang kembali. Cicil: separuh dulu (%s), sisanya hari buka berikutnya. Ikhlaskan: uangnya relakan, nama warung jadi harum.") % GameState.format_rupiah(separuh), 19)
	else:
		_teks_jendela(isi, "Tagih penuh: uang kembali, tapi ia agak sungkan. Ikhlaskan: uangnya relakan, ia sangat berterima kasih." if bernama
			else "Tagih penuh: uang kembali. Ikhlaskan: uangnya relakan, nama warung jadi harum.", 19)
	var pilihan: = [["Ikhlaskan", &"TombolKayu", func(): _jawab_tagihan.emit("ikhlas")]]
	if bisa_cicil:
		pilihan.append(["Boleh dicicil", &"TombolHijau", func(): _jawab_tagihan.emit("cicil")])
	pilihan.append(["Tagih penuh", &"TombolHijau", func(): _jawab_tagihan.emit("penuh")])
	_tombol_kejadian(isi, pilihan)
	return await _jawab_tagihan


func _tombol_tutup_jendela(isi: VBoxContainer) -> void :
	var tutup: = Button.new()
	tutup.text = "Tutup"
	tutup.theme_type_variation = &"TombolKayu"
	tutup.custom_minimum_size = Vector2(200, 58)
	tutup.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	tutup.add_theme_font_size_override("font_size", 24)
	tutup.pressed.connect( func():
		dialog_aktif = false
		isi.get_meta("lapisan").queue_free())
	isi.add_child(tutup)





var hujan: Node2D = null


var pengajian_diumumkan: = false

func _proses_kejadian() -> void :
	_cek_matel()
	if GameState.pengajian_bubar() and not pengajian_diumumkan:
		pengajian_diumumkan = true
		tampilkan_pesan("Pengajian di masjid sudah selesai. Jamaah mulai mampir ke warung!", 5.0)
	var hasil: = GameState.cek_kejadian()
	if hasil == "":
		return
	var k: = GameState.kejadian
	var info: = GameState.info_kejadian(String(k.get("id", "")))
	match hasil:
		"mulai":
			if k.get("tangkal", false):
				notifikasi(info.get("judul_tangkal", "Kejadian"), info.get("isi_tangkal", ""), "", WARNA_NOTIF_BAIK)
			else:
				var baik: = GameState.pengali_jeda_kejadian() < 1.0

				GameState.bunyi({"mati_listrik": "listrik_padam", "hujan_deras": "petir"}.get(String(k.get("id", "")), ""))
				notifikasi(info.get("judul_mulai", "Kejadian"), info.get("isi_mulai", ""), "", WARNA_NOTIF_BAIK if baik else WARNA_NOTIF_BURUK)

				if baik:
					$Layanan.detik_datang_berikutnya = minf($Layanan.detik_datang_berikutnya, randf_range(0.5, 1.5))
		"selesai":
			if not k.get("tangkal", false):
				if String(k.get("id", "")) == "mati_listrik":
					GameState.bunyi("listrik_nyala")
				if k.has("diusir_warga"):

					notifikasi("Warga datang membantu", "%s datang mengusir preman. Pembeli berani mampir lagi." % String(k["diusir_warga"]), "", WARNA_NOTIF_BAIK)
				else:
					notifikasi(info.get("judul_selesai", "Selesai"), info.get("isi_selesai", ""), "", WARNA_NOTIF_BIASA)
				if String(k.get("id", "")) == "preman_nongkrong":
					_preman_pergi()
		"palak":
			_tampilkan_palak(k.get("tangkal", false))
		"borongan":
			var b: = GameState.buat_borongan()
			if not b.is_empty():
				_tampilkan_borongan(b)
		"arisan":
			if not GameState.pesanan_arisan().is_empty():
				_tampilkan_arisan()
	_perbarui_hujan()


func _on_hujan_berubah(turun: bool) -> void :

	if not is_inside_tree():
		return
	if turun:
		notifikasi("Hujan turun", "Pak RT mengabari di Grup Warga. Mie rebus dan kopi lebih dicari.", "", WARNA_NOTIF_BIASA)
	else:
		notifikasi("Hujan reda", "Langit cerah lagi, warga keluar rumah lagi.", "", WARNA_NOTIF_BIASA)



func _perbarui_hujan() -> void :
	var mau: bool = GameState.sedang_hujan()
	if mau and hujan == null:
		hujan = preload("res://scripts/hujan.gd").new()
		hujan.ukuran = latar.texture.get_size()

		var kios: = PackedVector2Array()
		for t in GameState.POLIGON_KIOS:
			kios.append(_ke_lokal(Vector2(t[0], t[1])))
		hujan.larangan = [kios]
		hujan.induk_percik = latar
		hujan.urutan_percik = %WadahPelanggan.get_index()
		latar.add_child(hujan)
	elif not mau and hujan != null:
		hujan.berhenti()
		hujan = null



func _teks_jendela(isi: VBoxContainer, teks: String, ukuran: = 22) -> void :
	var l: = Label.new()
	l.text = teks
	l.add_theme_font_size_override("font_size", ukuran)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size.x = 560
	isi.add_child(l)



func _tombol_kejadian(isi: VBoxContainer, daftar: Array) -> void :
	var bawah: = HBoxContainer.new()
	bawah.add_theme_constant_override("separation", 14)
	bawah.alignment = BoxContainer.ALIGNMENT_CENTER
	isi.add_child(bawah)
	for t in daftar:
		var b: = Button.new()
		b.text = t[0]
		b.theme_type_variation = t[1]
		b.custom_minimum_size = Vector2(220, 64)
		b.add_theme_font_size_override("font_size", 23)
		b.disabled = t.size() > 3 and not t[3]
		var aksi: Callable = t[2]

		var tanya: Array = t[4] if t.size() > 4 else []
		b.pressed.connect( func():
			if not tanya.is_empty():
				if not await KB.tanya(self, String(tanya[0]), int(tanya[1]), "", String(tanya[2]), bool(tanya[3])):
					return
				if not is_instance_valid(isi) or isi.is_queued_for_deletion():
					return
			dialog_aktif = false
			isi.get_meta("lapisan").queue_free()
			aksi.call())
		bawah.add_child(b)





const TITIK_PREMAN: = Vector2(700, 650)
const TITIK_NONGKRONG: = Vector2(560, 610)
var preman: Sprite2D = null


func _tampilkan_palak(ada_cctv: bool) -> void :
	panel_belanja.hide()
	var jalur_datang: Array = [_ke_lokal(TITIK_LATAR["JalurMulai"]), _ke_lokal(TITIK_LATAR["JalurJalan"]), _ke_lokal(TITIK_PREMAN)]


	$Layanan.tahan_depan = true
	preman = _buat_tokoh("preman", jalur_datang[0])
	if preman != null:
		preman.jalan(jalur_datang.slice(1), 150.0)
		await preman.sampai
		preman.hadap(bapak_3d.position - preman.position)
		if ada_cctv:
			await _ucap(preman, "Pak, uang kea... eh, ada CCTV-nya.", 2.2)
			$Layanan.tahan_depan = false
			_preman_pergi()
			tampilkan_pesan("Preman melirik kamera CCTV, lalu buru-buru pergi. CCTV-nya berguna juga.", 4.0)
			return
		preman.aksi("bicara")
	var setoran: = GameState.setoran_palak()
	var isi: = _buka_jendela("Uang keamanan", 640)
	GameState.bunyi("salah")
	if ada_cctv:
		$Layanan.tahan_depan = false
		_teks_jendela(isi, "Seorang pria berjaket kulit mendekat dan bersandar di meja. Ia melirik kamera CCTV di atas warung... lalu batal bicara dan buru-buru pergi.")
		_tombol_kejadian(isi, [["Alhamdulillah", &"TombolHijau", func(): tampilkan_pesan("CCTV-nya berguna juga.")]])
		return
	_teks_jendela(isi, "Seorang pria berjaket kulit bersandar di meja.\n\"Pak, uang keamanan. %s aja, biar warungnya aman.\"" % GameState.format_rupiah(setoran))
	var cukup: = GameState.uang >= setoran
	if not cukup:
		_teks_jendela(isi, "Uang di laci tidak cukup.", 18)
	var kasih: = func():
		GameState.bayar_palak(setoran)
		$Layanan.tahan_depan = false
		uang_melayang("-" + GameState.format_rupiah(setoran))
		tampilkan_pesan("Preman pergi sambil menghitung uang.")
		_preman_pergi()
	var tolak: = func():
		if preman != null:
			preman.aksi("marah")


		GameState.mulai_preman_nongkrong()
		$Layanan.tahan_depan = false
		$Layanan.kabur_semua()
		notifikasi("Preman nongkrong di depan", "Pembeli kabur dan tidak berani mampir. Preman baru pergi beberapa jam lagi.", "", WARNA_NOTIF_BURUK)
		if preman != null:
			await GameState.get_tree().create_timer(1.6, false).timeout
			if preman != null:
				preman.jalan([_ke_lokal(TITIK_NONGKRONG)], 110.0)
				await preman.sampai
				if preman != null:
					preman.hadap(Vector2(1, 0.4))
	_tombol_kejadian(isi, [
		["Kasih " + GameState.format_rupiah(setoran), &"TombolHijau", kasih, cukup, ["Kasih uang keamanan ke preman?", setoran, "Ya, kasih", false]], 
		["Tolak", &"TombolHijau", tolak], 
	])


func _pulihkan_preman() -> void :
	if not GameState.preman_di_depan() or preman != null:
		return
	preman = _buat_tokoh("preman", _ke_lokal(TITIK_NONGKRONG))
	if preman != null:
		preman.hadap(Vector2(1, 0.4))
	$Layanan.detik_datang_berikutnya = randf_range(40.0, 70.0)





var matel: Sprite2D = null


func _cek_matel() -> void :
	if matel != null or not GameState.matel_perlu_datang():
		return
	if kurir != null or truk != null or preman != null or tamu_kiriman != null or sedang_sholat or dialog_aktif or panel_terbuka():
		return
	GameState.matel_datang_hari = GameState.hari
	_tampilkan_matel()


func _tampilkan_matel() -> void :
	panel_belanja.hide()
	$Layanan.tahan_depan = true
	var jalur_datang: Array = [_ke_lokal(TITIK_LATAR["JalurMulai"]), _ke_lokal(TITIK_LATAR["JalurJalan"]), _ke_lokal(TITIK_PREMAN)]
	matel = _buat_tokoh("preman", jalur_datang[0])
	if matel != null:
		matel.jalan(jalur_datang.slice(1), 160.0)
		await matel.sampai
		if matel == null:
			return
		matel.hadap(bapak_3d.position - matel.position)
		matel.aksi("bicara")
	var angsuran: = mini(int(GameState.motor_cicil.get("angsuran", GameState.motor_angsuran())), GameState.motor_sisa_cicilan())
	var isi: = _buka_jendela("Matel datang", 660)
	GameState.bunyi("salah")
	_teks_jendela(isi, """Dua pria berjaket kulit berhenti di depan warung, satu memegang map leasing.
\"Pak Misran? Kami dari leasing. Cicilan motor bulan ini %s, jatuh tempo hari ini. Bayar sekarang, atau motornya kami bawa.\"""" %GameState.format_rupiah(angsuran))
	var cukup: = GameState.uang >= angsuran
	if not cukup:
		_teks_jendela(isi, "Uang di laci tidak cukup.", 18)
	var bayar: = func():
		if GameState.bayar_cicilan_motor() == "":
			uang_melayang("-" + GameState.format_rupiah(angsuran))
			if GameState.motor_sisa_cicilan() > 0:
				tampilkan_pesan("Cicilan dibayar. Matel pergi. Jatuh tempo berikutnya %s." % GameState.nama_tanggal_hari(GameState.motor_tempo()), 5.0)
			else:
				tampilkan_pesan("Cicilan terakhir dibayar. Motor LUNAS!", 5.0)
		$Layanan.tahan_depan = false
		_matel_pergi(false)
	var sita: = func():
		GameState.sita_motor("Motornya dibawa matel leasing tadi siang, Pak. Uang yang sudah dibayar hangus. Kalau mau, bisa cicil motor lagi dari awal di Wishlist.")
		if matel != null:
			matel.aksi("marah")
		notifikasi("Motor disita", "Matel membawa motor Pak Misran. OjekKampung tidak bisa dipakai sampai punya motor lagi.", "", WARNA_NOTIF_BURUK)
		$Layanan.tahan_depan = false
		await GameState.get_tree().create_timer(1.4, false).timeout
		_matel_pergi(true)
	_tombol_kejadian(isi, [
		["Bayar " + GameState.format_rupiah(angsuran), &"TombolHijau", bayar, cukup, ["Bayar cicilan motor?", angsuran, "Ya, bayar", false]], 
		["Tidak ada uang", &"TombolKayu", sita, true, ["Motor akan dibawa matel. Yakin?", 0, "Ya, biarkan", true]], 
	])


func _matel_pergi(bawa_motor: bool) -> void :
	if matel == null or not is_instance_valid(matel):
		matel = null
		return
	var p: = matel
	matel = null
	if bawa_motor:
		tampilkan_pesan("Matel pergi membawa motor...", 4.0)
	p.jalan([_ke_lokal(TITIK_LATAR["JalurJalan"]), _ke_lokal(TITIK_LATAR["JalurPulang"])], 160.0)
	await p.sampai
	p.queue_free()



func _preman_pergi() -> void :
	if preman == null or not is_instance_valid(preman):
		return
	var p: = preman
	preman = null
	p.jalan([_ke_lokal(TITIK_LATAR["JalurJalan"]), _ke_lokal(TITIK_LATAR["JalurPulang"])], 150.0)
	await p.sampai
	p.queue_free()




func _tampilkan_arisan() -> void :
	panel_belanja.hide()
	var p: = GameState.pesanan_arisan()
	var isi: = _buka_jendela("Pesanan arisan diambil", 640)
	GameState.bunyi("hadiah")
	_teks_jendela(isi, "%s datang mengambil pesanan untuk %s:\n%s." % [p["nama"], p["acara"], GameState.kalimat_daftar_barang(p["daftar"])])
	var kurang: = []
	for baris in p["daftar"]:
		if int(GameState.stok.get(String(baris[0]), 0)) < int(baris[1]):
			kurang.append(GameState.tk(String(GameState.data_barang(String(baris[0])).get("sebutan", GameState.data_barang(String(baris[0]))["nama"]))))
	if not kurang.is_empty():
		_teks_jendela(isi, "Stok kurang: %s. Yang ada saja yang diserahkan." % ", ".join(kurang), 19)
	var serah: = func():
		var h: = GameState.ambil_arisan()
		if h.is_empty():
			return
		if int(h["masuk"]) > 0:
			GameState.bunyi("koin")
			uang_melayang("+" + GameState.format_rupiah(int(h["masuk"]) + int(h["tip"])), true)
		if bool(h["lengkap"]):
			var teks: = "Pesanan arisan lengkap, dibayar lunas %s." % GameState.format_rupiah(int(h["masuk"]))
			if int(h["tip"]) > 0:
				teks += " Ada tip %s!" % GameState.format_rupiah(int(h["tip"]))
			notifikasi("Arisan beres", teks, "", WARNA_NOTIF_BAIK)
		else:
			notifikasi("Pesanan arisan kurang", "Dibayar %s untuk yang ada. Kurang: %s" % [GameState.format_rupiah(int(h["masuk"])), GameState.kalimat_daftar_barang(h["kurang"])], "", WARNA_NOTIF_BIASA)
		GameState.simpan()
	_tombol_kejadian(isi, [["Serahkan pesanan", &"TombolHijau", serah]])


func _tampilkan_borongan(b: Dictionary) -> void :
	panel_belanja.hide()
	var isi: = _buka_jendela("Pesanan borongan", 640)
	GameState.bunyi("hadiah")
	GameState.tambah_chat(String(b["nama"]), "Pak Misran, buat %s saya mau borong: %s. Bisa, Pak?" % [b["acara"], GameState.kalimat_daftar_barang(b["daftar"])], false, "teks", "rt")
	_teks_jendela(isi, "%s datang membawa kantong besar:\n\"Pak, buat %s saya mau borong %s.\"" % [b["nama"], b["acara"], GameState.kalimat_daftar_barang(b["daftar"])])
	_teks_jendela(isi, "Total %s dengan harga jual sekarang. Stok tiap barang tetap tersisa minimal %d." % [GameState.format_rupiah(int(b["total"])), GameState.MIN_STOK_BUKA], 19)
	var terima: = func():
		var masuk: = GameState.terima_borongan(b)
		GameState.bunyi("koin")
		uang_melayang("+" + GameState.format_rupiah(masuk), true)
		tampilkan_pesan("Borongan beres! Reputasi warung naik.")
	_tombol_kejadian(isi, [
		["Tolak halus", &"TombolHijau", func(): tampilkan_pesan("\"Ya sudah, Pak, lain kali saja.\"")], 
		["Terima", &"TombolHijau", terima], 
	])



func _tampilkan_pencurian(c: Dictionary) -> void :
	var daftar: = GameState.kalimat_daftar_barang(c["hilang"])

	if c.get("tikus", false):
		var jendela: = _buka_jendela("Ada tikus di warung!", 620)
		GameState.bunyi("salah")
		var saran: = "Neo sudah menjaga warung, tapi tikusnya lolos juga kali ini." if c.get("neo", false) else "Kalau Neo sudah akrab dengan Pak Misran, ia sering menjaga warung dari tikus."
		_teks_jendela(jendela, "Saat membuka warung, Pak Misran menemukan bekas gigitan tikus: %s rusak dan dibuang (senilai %s modal).\n%s" % [daftar, GameState.format_rupiah(int(c["nilai"])), saran])
		_tombol_kejadian(jendela, [["Waduh...", &"TombolKayu", func(): pass]])
		return
	var isi: = _buka_jendela("Semalam ada maling!", 620)
	GameState.bunyi("salah")
	if c.get("cctv", false):
		_teks_jendela(isi, "Ada yang mencoba mencuri %s, tapi wajahnya terekam CCTV. Pak RT sudah mengamankan pelakunya. Tidak ada barang yang hilang." % daftar)
		_tombol_kejadian(isi, [["Alhamdulillah", &"TombolHijau", func(): pass]])
	else:
		_teks_jendela(isi, "Saat membuka warung, Pak Misran sadar ada barang yang hilang: %s (senilai %s modal).\nCCTV bisa mencegah kejadian ini terulang." % [daftar, GameState.format_rupiah(int(c["nilai"]))])
		_tombol_kejadian(isi, [["Astaghfirullah...", &"TombolKayu", func(): pass]])




var spanduk_atap: Node2D = null

func _pasang_spanduk() -> void :
	if is_instance_valid(spanduk_atap):
		spanduk_atap.queue_free()
	spanduk_atap = null
	if not GameState.pendukung or GameState.nama_warung == "":
		return
	var peta: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/peta.json"))
	var a: Dictionary = peta["area"].get("warung", {})
	if not a.has("tulisan_atap"):
		return
	spanduk_atap = preload("res://scripts/spanduk_atap.gd").buat(a["tulisan_atap"]["sudut"], load(String(a["gambar"])))
	spanduk_atap.position = _ke_lokal(Vector2.ZERO)
	latar.add_child(spanduk_atap)
	latar.move_child(spanduk_atap, 0)




func _pasang_zebra() -> void :
	var peta: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/peta.json"))
	var a: Dictionary = peta["area"].get("warung", {})
	if not a.has("zebra"):
		return
	var zebra: Node2D = preload("res://scripts/jelajah.gd").buat_zebra(a["zebra"], load(String(a["gambar"])))
	zebra.position = _ke_lokal(Vector2.ZERO)
	latar.add_child(zebra)
	latar.move_child(zebra, 0)



func _judul_besar(teks: String) -> void :
	var l: = Label.new()
	l.text = teks
	l.set_anchors_preset(Control.PRESET_FULL_RECT)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", 72)
	l.add_theme_color_override("font_color", Color(1.0, 0.86, 0.3))
	l.add_theme_color_override("font_outline_color", Color(0.25, 0.12, 0.02))
	l.add_theme_constant_override("outline_size", 14)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.pivot_offset = get_viewport().get_visible_rect().size / 2.0
	akar_ui.add_child(l)
	l.modulate.a = 0.0
	l.scale = Vector2(0.7, 0.7)
	var tw: = create_tween()
	tw.tween_property(l, "modulate:a", 1.0, 0.3)
	tw.parallel().tween_property(l, "scale", Vector2.ONE, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_interval(2.2)
	tw.tween_property(l, "modulate:a", 0.0, 0.6)
	tw.tween_callback(l.queue_free)




func notifikasi_stok(kiriman: Dictionary) -> void :
	GameState.bunyi("hadiah")
	if tombol_stok == null or not tombol_stok.is_visible_in_tree():
		tampilkan_pesan("Stok masuk!", 2.0)
		return
	var kotak: = PanelContainer.new()
	kotak.add_theme_stylebox_override("panel", GH.kartu_notif(0.82, Vector4(10, 6, 10, 6)))
	kotak.mouse_filter = Control.MOUSE_FILTER_IGNORE
	kotak.z_index = 6
	kotak.modulate.a = 0.0
	akar_ui.add_child(kotak)
	var kolom: = VBoxContainer.new()
	kolom.add_theme_constant_override("separation", 2)
	kolom.mouse_filter = Control.MOUSE_FILTER_IGNORE
	kotak.add_child(kolom)
	var l_judul: = Label.new()
	l_judul.text = "Stok masuk"
	l_judul.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	GH.gaya_label(l_judul, 13, GH.KUNING, true)
	kolom.add_child(l_judul)
	var grid: = GridContainer.new()
	grid.columns = mini(kiriman.size(), 5)
	grid.add_theme_constant_override("h_separation", 4)
	grid.add_theme_constant_override("v_separation", 2)
	grid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	kolom.add_child(grid)
	var n_ikon: = 0
	for id in kiriman:
		if n_ikon >= 10:
			break
		n_ikon += 1
		var sel: = HBoxContainer.new()
		sel.add_theme_constant_override("separation", 1)
		sel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var g: = TextureRect.new()
		var jalur: = "res://assets/barang/%s.png" % id
		if ResourceLoader.exists(jalur):
			g.texture = load(jalur)
		g.custom_minimum_size = Vector2(22, 22)
		g.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		g.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		g.mouse_filter = Control.MOUSE_FILTER_IGNORE
		sel.add_child(g)
		var n: = Label.new()
		n.text = "+%d" % int(kiriman[id])
		GH.gaya_label(n, 12, GH.HIJAU_UANG, true)
		sel.add_child(n)
		grid.add_child(sel)
	if kiriman.size() > n_ikon:
		var lebih: = Label.new()
		lebih.text = "+%d jenis lagi" % (kiriman.size() - n_ikon)
		lebih.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		GH.gaya_label(lebih, 11, Color.WHITE)
		kolom.add_child(lebih)
	await get_tree().process_frame

	if not is_instance_valid(kotak) or not is_instance_valid(tombol_stok) or not is_inside_tree():
		return
	kotak.reset_size()
	var r: = tombol_stok.get_global_rect()
	var layar: = get_viewport().get_visible_rect().size
	var x: = clampf(r.get_center().x - kotak.size.x / 2.0, 8.0, layar.x - kotak.size.x - 8.0)
	kotak.global_position = Vector2(x, maxf(r.position.y - kotak.size.y - 6.0, 8.0))
	var tw: = kotak.create_tween()
	tw.tween_property(kotak, "modulate:a", 1.0, 0.2)
	tw.tween_interval(2.6)
	tw.tween_property(kotak, "modulate:a", 0.0, 0.5)
	tw.tween_callback(kotak.queue_free)







func kabari_keluhan_mahal(id: String) -> void :
	if id == "" or GameState.mode_latihan or GameState.tutorial_langkah != "":
		return


	if GameState.keluh_mati_hari == GameState.hari:
		return
	var catat: Array = GameState.keluh_dikabari.get(id, [])
	if not catat.is_empty() and int(catat[0]) == GameState.hari and int(catat[1]) == GameState.harga_jual(id):
		return

	await GameState.get_tree().create_timer(1.6, false).timeout
	if dialog_aktif or panel_terbuka() or sedang_sholat or GameState.status_hari != "buka" or GameState.keluh_mati_hari == GameState.hari:
		return
	GameState.keluh_dikabari[id] = [GameState.hari, GameState.harga_jual(id)]
	var nama: = String(GameState.data_barang(id).get("sebutan", GameState.data_barang(id)["nama"])).to_lower()
	var isi: = _buka_jendela("Pembeli mengeluh", 600)
	_teks_jendela(isi, "Pembeli mengeluh karena %s kemahalan. Kamu jual %s, harga pasarannya %s.\nSegera cek harga jualmu!" % [
		nama, GameState.format_rupiah(GameState.harga_jual(id)), GameState.format_rupiah(GameState.harga_pasar(id))])
	_tombol_kejadian(isi, [
		["Nanti saja", &"TombolKayu", func(): pass], 
		["Oke, aku cek", &"TombolHijau", func():
			buka_hp("harga")
			await GameState.get_tree().create_timer(0.5).timeout
			var app: Control = hp.aplikasi("harga") if hp != null else null
			if app != null and app.has_method("sorot_barang"):
				app.sorot_barang(id)], 
	])
	_tombol_kejadian(isi, [["Jangan ingatkan lagi hari ini", &"TombolKayu", func(): GameState.keluh_mati_hari = GameState.hari]])
	var bawah_akhir: Control = isi.get_child(isi.get_child_count() - 1)
	(bawah_akhir.get_child(0) as Button).custom_minimum_size = Vector2(454, 52)
	(bawah_akhir.get_child(0) as Button).add_theme_font_size_override("font_size", 19)



const PANAH_AKRAB: = preload("res://scripts/panah_akrab.gd")

func _on_akrab_naik(tipe: String, naik_tingkat: bool) -> void :
	for anak in %WadahPelanggan.get_children():
		if anak is Sprite2D and String(anak.get_meta("tipe", "")) == tipe and anak.has_method("tinggi_badan"):
			PANAH_AKRAB.tampilkan(anak, naik_tingkat)
			return
	GameState.bunyi("akrab_naik")



func _buka_pengaturan() -> void :
	var p: Control = load("res://scenes/pengaturan.tscn").instantiate()
	p.dalam_game = true
	dialog_aktif = true
	akar_ui.add_child(p)
	await p.ditutup
	dialog_aktif = false
