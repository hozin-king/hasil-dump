extends Node







signal data_berubah

signal tugas_selesai(hadiah: int, tingkat_baru: int)

signal upgrade_dibeli(id: String)


const JAM_MULAI: = 7 * 60
const JAM_BUKA: = 9 * 60
const JAM_BOLEH_TUTUP: = 16 * 60
const JAM_BOLEH_TIDUR: = 21 * 60
const JAM_MALAM: = 18 * 60
const JAM_BATAS: = 26 * 60


const GOD_MODE: = false
const JALUR_GOD: = "res://scripts/god_mode.gd"


static func god_aktif() -> bool:
	return GOD_MODE and ResourceLoader.exists(JALUR_GOD)
const UJI_PEMAIN_BARU: = true
var god_paksa_event: = ""
const UANG_AWAL: = 630000
const MIN_STOK_BUKA: = 2
const MAKS_STOK_BARANG: = 100


const BARANG_TITIPAN: = {"lpg": 2, "galon": 3}
const SALDO_LAYANAN_AWAL: = 50000
const NAMA_HARI: = ["Senin", "Selasa", "Rabu", "Kamis", "Jumat", "Sabtu", "Minggu"]
const FILE_BARANG: = "res://data/barang.json"
const FILE_TUGAS: = "res://data/tugas.json"
const FILE_CERITA: = "res://data/cerita.json"
const FILE_UPGRADE: = "res://data/upgrade.json"
const FILE_SIMPAN: = "user://simpanan.json"
const FILE_PENGATURAN: = "user://pengaturan.cfg"


const KECEPATAN: = {"lambat": 1.04, "normal": 1.52, "cepat": 2.4}


const PENGALI_JEDA_PEMBELI: = 1.4



var penjaga: String = "bapak"
var nama_pemain: = "Misran"
var teks_tokoh: Translation

var bahasa: = ""
const MAKS_NAMA_PEMAIN: = 12
const FILE_MODEL_PENJAGA: = {"bapak": "meshy_bapak.glb", "ibu": "meshy_ibu_penjaga.glb"}

const ALIAS_ANIM_IBU: = {"Idle_11": "Idle_12", "Walking": "Walking_Woman", "Walk_with_Umbrella": "Walking_Woman", 
	"Walk_with_Umbrella_inplace": "Walking_Woman", "Step_to_Sit_Transition": "Sit_Cross_Legged", 
	"Sit_to_standTransition_Female_2": "Sit_Cross_Legged", "Chair_Sit_Idle_M": "Sit_Cross_Legged", 
	"Seated_Fist_Pump": "Sit_Cross_Legged"}

var hari: = 1
var menit: = float(JAM_MULAI)
var uang: = UANG_AWAL

var status_hari: = "persiapan"


var kecepatan_waktu: = 1.52


var katalog: = {}
var urutan_barang: Array[String] = []
var stok: = {}
var saldo_layanan: = SALDO_LAYANAN_AWAL
const JUMLAH_ISI_OTOMATIS: = 50000


var saldo_digital: = 0
const PELUANG_BAYAR_QRIS: = 0.35


var omzet_hari: = 0
var laba_hari: = 0
var barang_terjual_hari: = 0
var belanja_hari: = 0
var pelanggan_dilayani_hari: = 0




var total_pembeli: = 0
var pembeli_bulan: = 0


var omzet_bulan: = 0
var minggu_pembeli: = ""
var pembeli_minggu: = 0
var omzet_minggu: = 0
var bulan_pembeli: = ""

var id_papan: = ""
var papan: Node
var akun: Node
var cadangan: Node
var analitik: Node
var pelanggan_batal_hari: = 0
var hadiah_hari: = 0

var penjualan_hari: = {}

var riwayat: Array = []

var kiriman_stok: = {}
const DURASI_KIRIM: = 30.0
const DURASI_KIRIM_LAMA: = 20.0
var detik_kiriman: = 0.0
var kurir_dalam_perjalanan: = false


signal reputasi_berubah(selisih: float)
const REPUTASI_AWAL: = 0.0
var reputasi: = REPUTASI_AWAL
var reputasi_awal_hari: = REPUTASI_AWAL



const BIAYA_HARIAN: = {"casual": 10000, "hard": 20000}

const BATAS_HARI_MINUS: = {"casual": 3, "hard": 1}
var biaya_harian_hari: = 0
var hari_minus: = 0
var bangkrut: = false


var harga_jual_khusus: = {}


var daftar_tingkat: Array = []
var tingkat: = 0
var progres: = {"pelanggan": 0, "barang": 0, "omzet": 0, "khusus": 0}
var beruntun_sekarang: = 0


var volume: = 0.8
var pilihan_kecepatan: = "normal"

var sedang_main: = false

var putar_intro: = false

var nama_warung: = ""

var mode: = "casual"
const ATURAN_MODE: = {
	"casual": {"sabar_antre": 16.0, "sabar_respon": 6.5, "respon_per_barang": 2.5, "jeda_datang": Vector2(5, 11), "maks_antre": 4, "peluang_banyak": 0.35}, 
	"hard": {"sabar_antre": 8.0, "sabar_respon": 4.0, "respon_per_barang": 1.6, "jeda_datang": Vector2(3, 8), "maks_antre": 5, "peluang_banyak": 0.6}, 
}

var tutorial_selesai: = false

var tujuan_jelajah: = {"area": "warung", "muncul": "depan_warung"}
const MAKS_NAMA_WARUNG: = 12




var cerita: = {}
var bab: = 0


var misi_status: = ""
var misi_mulai_hari: = 0
const JEDA_AGUS: = 2

var naik_level_tertunda: Array = []
var kiriman_bab: = 0
var target_bab: = 0
var batas_hari: = 7
var barang_terbuka: Array = []
var cerita_tamat: = false
var denda_bab: = 0

var tunggakan_sewa: = 0
var sewa_dibayar_hari: = 0
var kios_milik: = false
var denda_sewa_hari: = 0

var transaksi: Array = []
const MAKS_TRANSAKSI: = 80

var ulasan: Array = []
const MAKS_ULASAN: = 60

var cerita_warga: = {}
var _data_event: = {}

var promo: = {}
var promo_hari_ke: = -1
const PILIHAN_DISKON_PROMO: = [0.1, 0.15, 0.2]
const MAKS_DENDA_PER_BAB: = 1

var daftar_upgrade: Array = []
var batas_efek: = {}
var daftar_dekorasi: Array = []
var upgrade_dimiliki: Array = []


var dialog_tertunda: Array = []


func _ready() -> void :

	process_mode = Node.PROCESS_MODE_ALWAYS
	_muat_katalog()
	_isi_stok_awal()
	_muat_tugas()
	_siapkan_bus()
	_siapkan_suara()
	cerita = JSON.parse_string(FileAccess.get_file_as_string(FILE_CERITA))
	_muat_upgrade()
	_muat_kejadian()
	_notif = load("res://scripts/notif_wasap.gd").new()
	add_child(_notif)
	teks_tokoh = load("res://scripts/teks_tokoh.gd").new()
	TranslationServer.add_translation(teks_tokoh)
	TranslationServer.set_locale("id")
	_perbarui_teks_tokoh()
	login_harian = load("res://scripts/login_harian.gd").new()
	add_child(login_harian)
	papan = load("res://scripts/papan_online.gd").new()
	add_child(papan)
	akun = load("res://scripts/akun_online.gd").new()
	add_child(akun)
	cadangan = load("res://scripts/cadangan_warung.gd").new()
	add_child(cadangan)
	barang_terbuka = urutan_barang.duplicate()
	var build_lama: = _baca_build_terakhir()
	muat_pengaturan()
	_cadangkan_saat_ganti_versi(build_lama)
	add_child(load("res://scripts/pemantau_fps.gd").new())
	analitik = load("res://scripts/analitik.gd").new()
	add_child(analitik)
	_lanjutkan_kode_pendukung.call_deferred()
	_cek_dukungan_bebas_iklan.call_deferred()
	_lanjutkan_bukti_iklan.call_deferred()
	get_tree().create_timer(15.0, true, false, true).timeout.connect(_kirim_jejak_grafis)
	var t_simpan: = Timer.new()
	t_simpan.wait_time = 5.0
	t_simpan.autostart = true
	t_simpan.timeout.connect(_cek_simpan_otomatis)
	add_child(t_simpan)










var _gpu_powervr: = -1

func gpu_powervr() -> bool:
	if _gpu_powervr < 0:
		var n: = (RenderingServer.get_video_adapter_name() + " " + RenderingServer.get_video_adapter_vendor()).to_lower()
		_gpu_powervr = 1 if (n.contains("powervr") or n.contains("imagination")) else 0

		if FileAccess.file_exists("user://paksa_powervr"):
			_gpu_powervr = 1
	return _gpu_powervr == 1





var _google_play_pc: = -1

func google_play_pc() -> bool:
	if _google_play_pc < 0:
		_google_play_pc = 0
		if OS.get_name() == "Android" and Engine.has_singleton("AndroidRuntime"):
			var akt = Engine.get_singleton("AndroidRuntime").getActivity()
			if akt != null:
				var pm = akt.getPackageManager()
				if pm != null and pm.hasSystemFeature("com.google.android.play.feature.HPE_EXPERIENCE"):
					_google_play_pc = 1
		if FileAccess.file_exists("user://paksa_pc"):
			_google_play_pc = 1
		print("[grafis] google_play_pc=%d gpu=%s" % [_google_play_pc, RenderingServer.get_video_adapter_name()])
	return _google_play_pc == 1


const SHADER_PARTIKEL: = preload("res://shader/partikel_warna.gdshader")


func bahan_partikel(warna: Color) -> ShaderMaterial:
	var b: = ShaderMaterial.new()
	b.shader = SHADER_PARTIKEL
	b.set_shader_parameter("warna", warna)
	return b


const FILE_JEJAK_GRAFIS: = "user://jejak_grafis.txt"
var _jejak_terakhir: = ""


func jejak_grafis(teks: String) -> void :
	if not gpu_powervr() or teks == _jejak_terakhir:
		return
	_jejak_terakhir = teks
	_tulis_jejak(teks)
	_tandai_jejak_selesai(teks)


func _tulis_jejak(teks: String) -> void :
	var f: = FileAccess.open(FILE_JEJAK_GRAFIS, FileAccess.WRITE)
	if f != null:
		var layar: = get_tree().current_scene.scene_file_path.get_file() if get_tree().current_scene != null else ""
		f.store_string("%s|%s|jam %d|%s" % [Time.get_datetime_string_from_system(), layar, int(menit / 60), teks])
		f.close()



func _tandai_jejak_selesai(teks: String) -> void :
	for i in 5:
		await get_tree().process_frame
	if _jejak_terakhir == teks:
		_tulis_jejak("selesai: " + teks)



func _hapus_jejak_grafis() -> void :
	_jejak_terakhir = ""
	if FileAccess.file_exists(FILE_JEJAK_GRAFIS):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(FILE_JEJAK_GRAFIS))



func _kirim_jejak_grafis() -> void :
	if not FileAccess.file_exists(FILE_JEJAK_GRAFIS):
		return
	var isi: = FileAccess.get_file_as_string(FILE_JEJAK_GRAFIS).left(400)
	_hapus_jejak_grafis()
	if isi == "" or OS.has_feature("editor"):
		return
	var req: = HTTPRequest.new()
	req.timeout = 15.0
	add_child(req)
	req.request_completed.connect( func(_a, _b, _c, _d): req.queue_free())
	var badan: = {"p_id": String(analitik.id_perangkat) if analitik != null else "", "p_versi": "%s (%s)" % [
		String(ProjectSettings.get_setting("application/config/version", "")), String(ProjectSettings.get_setting("application/config/build", ""))], 
		"p_gpu": (RenderingServer.get_video_adapter_name() + " | " + RenderingServer.get_video_adapter_api_version()).left(120), 
		"p_model": OS.get_model_name().left(60), "p_jejak": isi}
	req.request(papan.URL + "lapor_crash_grafis", PackedStringArray(["apikey: " + papan.KUNCI_PUBLIK, 
		"Authorization: Bearer " + papan.KUNCI_PUBLIK, "Content-Type: application/json"]), HTTPClient.METHOD_POST, JSON.stringify(badan))




func _sederhanakan_bahan(akar: Node) -> void :
	for mi: MeshInstance3D in cari_anak(akar, "MeshInstance3D"):
		var mesh: = mi.mesh
		if mesh == null or mesh.has_meta("bahan_sederhana"):
			continue
		mesh.set_meta("bahan_sederhana", true)
		for i in mesh.get_surface_count():
			var asli: = mesh.surface_get_material(i)
			if asli is BaseMaterial3D:
				mesh.surface_set_material(i, _bahan_sederhana(asli as BaseMaterial3D))


func _bahan_sederhana(asli: BaseMaterial3D) -> BaseMaterial3D:
	var b: BaseMaterial3D = asli.duplicate()
	b.normal_enabled = false
	b.ao_enabled = false
	b.heightmap_enabled = false
	b.rim_enabled = false
	b.clearcoat_enabled = false
	b.anisotropy_enabled = false
	b.subsurf_scatter_enabled = false
	b.backlight_enabled = false
	b.refraction_enabled = false
	b.detail_enabled = false
	b.emission_enabled = false
	b.metallic_texture = null
	b.roughness_texture = null
	b.metallic = 0.0
	b.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	return b








var _frame_ganti_layar: = -1

func ganti_layar(dari: Variant, jalur: String) -> Error:


	if typeof(dari) == TYPE_OBJECT and ( not is_instance_valid(dari) or not (dari is Node) or not (dari as Node).is_inside_tree()):
		push_warning("ganti_layar diabaikan (pemanggil sudah tidak aktif): " + jalur)
		return ERR_UNAVAILABLE
	if _frame_ganti_layar == Engine.get_process_frames():
		return ERR_BUSY
	_frame_ganti_layar = Engine.get_process_frames()
	jejak_grafis("layar " + jalur.get_file())
	cek_bayar_menunggu()
	return get_tree().change_scene_to_file(jalur)


func mulai_game_baru() -> void :
	hari = 1
	menit = JAM_BUKA
	uang = UANG_AWAL
	saldo_layanan = SALDO_LAYANAN_AWAL
	saldo_digital = 0
	status_hari = "persiapan"
	ronda_terakhir = 0
	bangun_kesiangan = false
	jumatan_hari = 0
	pengajian_hari = 0
	kabar_hari = {}
	minggu_tunggak = 0
	diusir = false
	sewa_selesai_hari = 0
	sewa_cicil = 0
	sewa_kunci = {}
	infak_hari = 0
	infak_jumlah = 0
	jajan_hari = 0
	jajan_dibeli = {}
	balas_budi_hari = {}
	bagikan_hari = -99
	bonus_mancing_hari = -1
	kerja_berjalan = ""
	matel_datang_hari = -1
	tangkapan_tertunda = []
	bonus_tautan_diambil = false
	energi = 100.0
	lelah_diingatkan = false
	alasan_bangun = ""
	hari_sembuh = -1
	tabrakan_tertunda = false
	perban_letak = []
	hari_tertabrak = -99
	utang_dokter = 0
	iklan_upgrade = {}
	pengali_harga_upgrade = {}
	wajib_etalase = true
	tutorial_langkah = ""
	mode_latihan = false
	tutorial_awal = false
	tutorial_penutup = false
	istirahat_hari = {}
	kerja_hari = {}
	hasil_alam = {}
	tas_grosir = {}
	titipan = {}
	basi_baru = 0
	mancing_hari = {}
	kebun_petik_hari = -99
	kebun = {}
	kebun_buah()
	_isi_stok_awal()
	_kosongkan_catatan_hari()
	riwayat = []
	kiriman_stok = {}
	detik_kiriman = 0.0
	kurir_dalam_perjalanan = false
	tingkat = 0
	_kosongkan_progres()


	barang_terbuka = cerita["terbuka_awal"].duplicate()
	for id in stok:
		stok[id] = 0
	for id in BARANG_TITIPAN:
		stok[id] = BARANG_TITIPAN[id]
	cerita_tamat = false
	dialog_tertunda.clear()
	reputasi = REPUTASI_AWAL
	reputasi_awal_hari = REPUTASI_AWAL
	harga_jual_khusus = {}
	harga_pasaran = {}
	agen_kenalan = false
	hari_minus = 0
	bangkrut = false
	nama_warung = ""
	nama_diganti = 0
	id_papan = _id_papan_baru()
	total_pembeli = 0
	pembeli_bulan = 0
	bulan_pembeli = ""
	omzet_bulan = 0
	minggu_pembeli = ""
	pembeli_minggu = 0
	omzet_minggu = 0
	upgrade_dimiliki = []
	tunggakan_sewa = 0
	kios_milik = false
	transaksi = []
	ulasan = []
	cerita_warga = {}
	keakraban = {}
	kiriman_warga = {}
	hutang = []
	hutang_ditolak = {}
	upah_harian = {}
	jadwal_kiriman = {}
	ulasan_langganan_hari = {}
	sapa_hari = {}
	akrab_naik_hari = {}
	promo = {}
	promo_hari_ke = -1
	chat = {}
	chat_belum = {}
	kontak_warga = {}
	kejadian = {}
	cuaca = {}
	_hujan_lalu = false
	hari_hujan_seharian = -99
	hari_banjir_terakhir = -99
	neo_dikabari = false
	jadwal_hujan = {}
	cuaca_besok = {}
	naik_level_tertunda = []
	riwayat_layan = []
	notif_dilihat = {}
	agus_bantu_sampai = 0
	adzan_maghrib_hari = 0
	zakat_dibayar = false
	tarawih_hari = 0
	thr_agus = 0
	neo_makan_hari = 0
	promosi_mulai = 0
	ajak_rating_sudah = false
	rumah_renovasi = false
	motor_baru = false
	motor_cicil = {}
	motor_disita = false
	matel_datang_hari = -1
	ngojol = {"hari": -1, "selesai": []}
	hape_mewah = false
	kerja_gratis_hari = -1
	kerja_gratis_jml = 0
	janji = {}
	janji_lewat = {}
	janji_dijadwal = {}
	tip_mg_hari = -1
	qris_mg = {"hari": -1, "n": 0}
	kurir_pilihan = ""
	kurir_hari = -1
	instan_mulai = 0
	kerja_tujuan = ""
	peta_ditunjukkan = false
	_mulai_bab(0)

	tambah_chat(nama_pemilik_kios(), "Assalamualaikum, Pak Misran. Selamat buka warung! Sewa kios %s per minggu, dibayar setiap Minggu malam ya. Harganya tetap, kalau suatu saat harus naik nanti saya kabari dulu alasannya. Satu lagi, Pak: warungnya buka jam 9 pagi dan tutup paling lambat jam 5 sore, biar tidak mengganggu tetangga. Setiap Jumat libur saja, Pak, karena Kamis malamnya Bapak ronda dan siangnya Jumatan. Dari dulu kios ini memang tidak buka hari Jumat. Nanti kalau kios ini sudah Bapak beli sendiri, baru jam bukanya terserah Bapak. Rezeki tidak akan ke mana." % format_rupiah(sewa_per_minggu()), true, "teks", "juragan")
	if pesan_kerja_sampingan() != "":
		tambah_chat("Pak RT", pesan_kerja_sampingan(), true, "teks", "rt")
	analitik.catat("game_baru", {"tutorial": not tutorial_selesai})
	data_berubah.emit()





var notif_dilihat: = {}


func penanda_notif(id: String) -> Variant:
	match id:
		"ulasan":
			return ulasan.size()
		"harga":
			return barang_terbuka.size()
		"kontak":
			var total: = 0
			for tipe in daftar_warga():
				total += tingkat_akrab(tipe)
			return total
		"misi":
			var selesai: = baris_tugas().filter( func(b): return b[1] >= b[2]).size()
			return "%d|%d|%s|%d" % [tingkat, bab, misi_status, selesai]
		"kalender":
			return hari if hari_spesial() else 0
		"mbanking":



			var cukup: = uang_cukup_kirim()
			var tunggak: = tunggakan_sewa > 0
			if not cukup and not tunggak:
				return ""
			return "%d|%d|%d|%d" % [bab, int(cukup), int(tunggak), minggu_tunggak]
	return null





static func _penanda_normal(v: Variant) -> Variant:
	if typeof(v) == TYPE_FLOAT and is_equal_approx(v, roundf(v)):
		return int(v)
	return v




func jumlah_notif_baru(id: String) -> int:
	var sekarang = penanda_notif(id)
	if sekarang == null:
		return 0
	if not notif_dilihat.has(id):
		notif_dilihat[id] = sekarang
		return 0
	if typeof(sekarang) == TYPE_STRING and String(sekarang) == "":
		return 0
	var lama = _penanda_normal(notif_dilihat[id])
	if typeof(sekarang) == TYPE_INT and typeof(lama) == TYPE_INT:
		if id == "kalender":
			return 1 if sekarang != 0 and sekarang != lama else 0
		return maxi(0, sekarang - lama)
	return 1 if str(sekarang) != str(lama) else 0



func ulasan_buruk_baru() -> int:
	var baru: = jumlah_notif_baru("ulasan")
	if baru <= 0:
		return 0
	return ulasan.slice(maxi(ulasan.size() - baru, 0)).filter( func(u): return int(u["bintang"]) <= 2).size()


func tandai_dilihat(id: String) -> void :
	var sekarang = penanda_notif(id)
	if sekarang != null and (typeof(notif_dilihat.get(id)) != typeof(sekarang) or notif_dilihat.get(id) != sekarang):
		notif_dilihat[id] = sekarang
		data_berubah.emit()
	var daftar = daftar_notif_tetap(id)
	if daftar != null and notif_dilihat.get(id + "_tetap") != daftar:
		notif_dilihat[id + "_tetap"] = daftar
		data_berubah.emit()







func daftar_notif_tetap(id: String) -> Variant:
	match id:
		"upgrade":
			var hasil: Array = []
			for u in daftar_upgrade:
				if status_upgrade(u["id"]) == "bisa":
					hasil.append(String(u["id"]))
			return hasil
		"belanja":
			var hasil: Array = []
			for b in barang_menipis():
				hasil.append(String(b))
			return hasil
	return null


func jumlah_notif_tetap(id: String) -> int:
	var daftar = daftar_notif_tetap(id)
	if daftar == null:
		return 0
	var lama = notif_dilihat.get(id + "_tetap", [])
	if typeof(lama) != TYPE_ARRAY:
		lama = []

	var sisa: Array = (lama as Array).filter( func(x): return String(x) in daftar)
	if sisa.size() != (lama as Array).size():
		notif_dilihat[id + "_tetap"] = sisa
	var n: = 0
	for x in daftar:
		if not String(x) in sisa:
			n += 1
	return n



func hari_spesial() -> bool:
	return pengajian_hari == hari or (ikut_ronda_jumatan() and nama_hari() in ["Kamis", "Jumat"]) or hari_libur()






const TIPE_TANPA_PAYUNG: = ["preman", "fariz"]

func di_rumah_saat_hujan(tipe: String) -> bool:
	return tipe in TIPE_TANPA_PAYUNG and sedang_hujan()





const HARI_LIBUR: = ["Jumat"]

func hari_libur(h: int = -1) -> bool:
	if h < 1:
		h = hari
	return h > 1 and nama_hari_ke(h) in HARI_LIBUR





func warung_libur(h: int = -1) -> bool:
	return hari_libur(h) and not kios_milik



func jam_buka() -> int:
	return 0 if kios_milik else JAM_BUKA








const JANJI_PER_LIBUR: = 3
const NAMA_TEMPAT_JANJI: = {"warung": "depan warung", "masjid": "masjid", "rumah": "Rumah Warga", "sawah": "sawah", 
	"sd": "SD", "pesantren": "pesantren", "pasar": "Pasar (lapak Bu Ida)"}
const DATA_TOKOH_JANJI: = {"haji_doni": "Haji Doni", "fariz": "Mas Fariz", "kurir": "Kang Dadan"}
const TEKS_JANJI_BESOK: = "Assalamualaikum, Pak Misran. Besok hari %s warung libur, kan? Saya mau minta tolong. Kita ketemu di %s antara pukul %s dan %s, ya."
const TEKS_JANJI_HARI_INI: = "Assalamualaikum, Pak Misran. Hari ini warung libur, kan? Saya mau minta tolong. Kita ketemu di %s antara pukul %s dan %s, ya."
const TEKS_JANJI_LEWAT: = "Pak Misran, kemarin saya tunggu di %s, tapi Bapak belum sempat datang. Tidak apa-apa, libur berikutnya saja, ya."

const TIPE_ANAK_JANJI: = ["anak", "siswi"]
const TEKS_JANJI_BESOK_ANAK: = "Pak Misran, ini %s, pinjam HP di rumah. Besok hari %s warung libur, kan? Aku mau minta tolong. Ketemu di %s antara pukul %s dan %s, ya, Pak."
const TEKS_JANJI_HARI_INI_ANAK: = "Pak Misran, ini %s, pinjam HP di rumah. Hari ini warung libur, kan? Aku mau minta tolong. Ketemu di %s antara pukul %s dan %s, ya, Pak."
const TEKS_JANJI_LEWAT_ANAK: = "Pak Misran, ini %s. Kemarin aku tunggu di %s. Nggak apa-apa, libur berikutnya aja ya, Pak."

const JANJI_MAKS_WASAP: = 3
var janji: = {}
var janji_lewat: = {}
var janji_dijadwal: = {}


func event_janji(id: String) -> bool:
	return bool(data_event().get(id, {}).get("janji", false))



func event_bisa_mulai(id: String, h: int) -> bool:
	var ev: Dictionary = data_event().get(id, {})
	if ev.is_empty() or hasil_event(id) != "" or tahap_event(id) > 0:
		return false
	if h < int(ev.get("hari_min", 1)) or not cerita_terbuka(id) or event_kedaluwarsa(ev, h):
		return false
	if ev.has("setelah") and hasil_event(String(ev["setelah"])) == "":
		return false
	if not cerita_cocok_hasil(ev) or cerita_menunggu(ev):
		return false
	if bool(ev.get("hari_sekolah", false)) and nama_hari_ke(h) == "Minggu":
		return false

	if bool(ev.get("hari_pasar", false)) and nama_hari_ke(h) in HARI_PASAR_LIBUR:
		return false
	if bool(ev.get("bukan_ramadan", false)) and ramadan(h):
		return false
	return true



func janji_hari_ini(id: String) -> bool:
	return int(janji.get(id, -1)) == hari




func _atur_janji() -> void :
	for id in janji.keys():
		if int(janji[id]) >= hari:
			continue
		janji.erase(id)
		if hasil_event(id) == "" and tahap_event(id) == 0:
			janji_lewat[id] = int(janji_lewat.get(id, 0)) + 1
			var t: = _tempat_janji(id)
			if not t.is_empty() and int(janji_lewat[id]) <= JANJI_MAKS_WASAP:
				if bool(t["anak"]):
					tambah_chat(String(t["nama"]), TEKS_JANJI_LEWAT_ANAK % [String(t["nama"]), String(t["tempat"])], true, "teks", "rt")
				else:
					tambah_chat(String(t["nama"]), TEKS_JANJI_LEWAT % String(t["tempat"]), true, "teks", "rt")
	for target in [hari, hari + 1]:
		if hari_libur(target) and not janji_dijadwal.has(str(target)):
			_jadwalkan_janji(target)
	for k in janji_dijadwal.keys():
		if int(k) < hari - 14:
			janji_dijadwal.erase(k)


func _jadwalkan_janji(target: int) -> void :
	janji_dijadwal[str(target)] = true
	var calon: Array = []
	for id in data_event():
		if event_janji(id) and not janji.has(id) and event_bisa_mulai(id, target):
			calon.append(id)

	var urutan: = data_event().keys()
	calon.sort_custom( func(a, b):
		var la: = int(janji_lewat.get(a, 0))
		var lb: = int(janji_lewat.get(b, 0))
		return la > lb if la != lb else urutan.find(a) < urutan.find(b))
	var nama_dipakai: Array = []
	for id in calon:
		if janji.values().count(target) >= JANJI_PER_LIBUR:
			break
		var t: = _tempat_janji(id)
		if t.is_empty() or String(t["nama"]) in nama_dipakai:
			continue
		nama_dipakai.append(String(t["nama"]))
		janji[id] = target
		if int(janji_lewat.get(id, 0)) >= JANJI_MAKS_WASAP:
			continue
		var j: Array = t["jam"]
		var dari: = _jam_titik(float(j[0]))
		var sampai: = _jam_titik(float(j[1]))
		var nama: = String(t["nama"])
		if bool(t["anak"]):
			if target == hari:
				tambah_chat(nama, TEKS_JANJI_HARI_INI_ANAK % [nama, String(t["tempat"]), dari, sampai], true, "teks", "rt")
			else:
				tambah_chat(nama, TEKS_JANJI_BESOK_ANAK % [nama, nama_hari_ke(target), String(t["tempat"]), dari, sampai], true, "teks", "rt")
		elif target == hari:
			tambah_chat(nama, TEKS_JANJI_HARI_INI % [String(t["tempat"]), dari, sampai], true, "teks", "rt")
		else:
			tambah_chat(nama, TEKS_JANJI_BESOK % [nama_hari_ke(target), String(t["tempat"]), dari, sampai], true, "teks", "rt")



func _tempat_janji(id: String) -> Dictionary:
	var ev: Dictionary = data_event().get(id, {})
	if ev.is_empty():
		return {}
	var t: Dictionary = ev["tahap"][0]
	if t.has("temui") or not t.has("npc"):
		return {}
	var nama: = String(daftar_warga().get(String(t["npc"]), ""))
	if nama == "":
		nama = String(DATA_TOKOH_JANJI.get(String(t["npc"]), ""))
	if nama == "":
		return {}
	return {"nama": nama, "tempat": String(NAMA_TEMPAT_JANJI.get(String(t["area"]), String(t["area"]))), "jam": t.get("jam", [7, 21]), "area": String(t["area"]), 
		"anak": String(t["npc"]) in TIPE_ANAK_JANJI}



func daftar_janji_hari_ini() -> Array:
	var hasil: Array = []
	for id in janji:
		if int(janji[id]) == hari and hasil_event(id) == "" and tahap_event(id) == 0:
			var t: = _tempat_janji(id)
			if not t.is_empty():
				hasil.append("%s di %s (%s-%s)" % [t["nama"], t["tempat"], _jam_titik(float(t["jam"][0])), _jam_titik(float(t["jam"][1]))])
	return hasil


func mulai_hari_berikutnya() -> void :
	hari += 1

	reputasi_awal_hari = reputasi

	if misi_status == "menunggu" and hari >= misi_mulai_hari:
		_mulai_bab(bab)
	_cek_batas_waktu()
	menit = JAM_MULAI
	_cek_barang_ramadan(true)
	_cek_zakat_terlewat()
	status_hari = "persiapan"
	_kosongkan_catatan_hari()
	_ingatkan_batas_lewat_chat()


	_undi_hujan()
	_undi_kejadian()
	_jadwalkan_kiriman_warga()
	_atur_hutang_pagi()
	_atur_titipan_pagi()
	_kabar_pagi()
	_kabari_tempat_neo()
	_atur_janji()
	_cek_cicilan_motor()
	data_berubah.emit()


func majukan_waktu(tambahan_menit: float) -> void :
	var lama: = menit
	menit = min(menit + tambahan_menit, JAM_BATAS)
	_kurangi_energi(lama, menit)







const ENERGI_PER_MENIT_SIANG: = 0.039
const ENERGI_PER_MENIT_MALAM: = 0.099


const ENERGI_PER_PELANGGAN: = 0.0



const ENERGI_LARI_PER_DETIK: = 0.42
const ENERGI_PER_JENIS_TAMBAHAN: = 0.0
const JAM_MALAM_LELAH: = 21 * 60
const BATAS_LELAH: = 30.0

const JAM_BANGUN_MENURUT_TIDUR: = [[22 * 60, 7 * 60], [24 * 60, 8 * 60], [25 * 60, 9 * 60], [99 * 60, 10 * 60]]






const ENERGI_KOPI: = 30.0
const ENERGI_MAKAN: = 30.0
const ISTIRAHAT: = [
	["ngopi", "Ngopi", [["sachet", ENERGI_KOPI], ["kopi_susu", ENERGI_KOPI], ["minuman_energi", ENERGI_KOPI]], 10.0], 
	["makan", "Makan mi rebus", [["mi_rebus", ENERGI_MAKAN]], 20.0], 
]
const MAKS_ISTIRAHAT_HARIAN: = 1
const MAKS_IKLAN_ENERGI: = 1
const JEDA_ISTIRAHAT: = 120.0
const ENERGI_MIN_BUKA: = 20.0
var istirahat_hari: = {}
var energi: = 100.0
var lelah_diingatkan: = false
var alasan_bangun: = ""
var jam_bangun_tadi: = 7 * 60

func _kurangi_energi(dari: float, sampai: float) -> void :
	if sampai <= dari:
		return
	var siang: = clampf(minf(sampai, JAM_MALAM_LELAH) - dari, 0.0, sampai - dari)
	var malam: = (sampai - dari) - siang

	var k: = PENGALI_ENERGI_RUMAH_BARU if rumah_renovasi else 1.0
	energi = clampf(energi - (siang * ENERGI_PER_MENIT_SIANG + malam * ENERGI_PER_MENIT_MALAM) * k, 0.0, 100.0)







const HARGA_WISHLIST: = {"rumah": 18000000, "motor": 12000000, "hape": 6000000}
const LEVEL_WISHLIST: = {"rumah": 6, "motor": 3, "hape": 1}
const PENGALI_ENERGI_RUMAH_BARU: = 0.85
const PENGALI_WAKTU_KIRIM_MOTOR: = 0.6
var rumah_renovasi: = false
var motor_baru: = false




const MOTOR_DP: = 2000000
const MOTOR_TENOR: = 10
const MOTOR_HARI_BULAN: = 30
const MATEL_JAM: = 11 * 60
var motor_cicil: = {}
var matel_datang_hari: = -1
var motor_disita: = false
var hape_mewah: = false







const NGOJOL_JAM_AKHIR: = 22.0
const NGOJOL_MAKS_ORDER: = 5
const NGOJOL_TAMPIL: = 3
const NGOJOL_ENERGI: = 10.0
const NGOJOL_MENIT: = 30.0

const NGOJOL_ONGKOS: = [[5000, 10000], [12000, 20000], [22000, 30000]]
const NGOJOL_BONUS_HUJAN: = 1.25
const NGOJOL_TIP_MAKS: = 5000
const NGOJOL_MAKS_ORDER_RP: = 35000
const NGOJOL_MAKS_MALAM: = 100000


const NGOJOL_BATAS_MIN: = 50000
const NGOJOL_BATAS_CONDONG: = 2.2




const NGOJOL_PENGALI_JUMAT: = 2


func ngojol_pengali_hari() -> int:
	return NGOJOL_PENGALI_JUMAT if hari_libur() else 1


func ngojol_maks_order() -> int:
	return NGOJOL_MAKS_ORDER * ngojol_pengali_hari()






const NGOJOL_TOTAL_MIN: = 75000
const NGOJOL_TOTAL_MAKS: = 100000


func ngojol_total_hari() -> int:
	var r: = RandomNumberGenerator.new()
	r.seed = hash("ojoltotal:%d:%d:%s" % [hari, slot_aktif, nama_warung])
	return r.randi_range(NGOJOL_TOTAL_MIN / 5000, NGOJOL_TOTAL_MAKS / 5000) * 5000 * ngojol_pengali_hari()



func ngojol_batas_malam() -> int:
	return ngojol_total_hari()

const NGOJOL_TUJUAN: = [["Masjid", 0], ["Pos ronda", 0], ["Rumah Pak RT", 0], ["Pasar", 1], ["SD", 1], ["Sawah Abah Karta", 1], 
	["Pesantren", 2], ["Terminal kecamatan", 2], ["Puskesmas", 2]]
var ngojol: = {"hari": -1, "selesai": [], "uang": 0}




const NGOJOL_JAM_MULAI_LIBUR: = 7.0


const NGOJOL_JAM_MULAI_KIOS_MILIK: = 17.0

func ngojol_jam_mulai() -> float:
	if hari_libur():
		return NGOJOL_JAM_MULAI_LIBUR
	if kios_milik:
		return NGOJOL_JAM_MULAI_KIOS_MILIK
	return jam_wajib_tutup() / 60.0




const NGOJOL_JAM_AKHIR_KIOS_MILIK: = 23.5

func ngojol_jam_akhir() -> float:
	if nama_hari() == "Kamis":
		return 21.5
	return NGOJOL_JAM_AKHIR_KIOS_MILIK if kios_milik else NGOJOL_JAM_AKHIR


func _ngojol_selesai() -> Array:
	if int(ngojol.get("hari", -1)) != hari:
		ngojol = {"hari": hari, "selesai": [], "uang": 0}
	return ngojol["selesai"]


func ngojol_uang_malam_ini() -> int:
	_ngojol_selesai()
	return int(ngojol.get("uang", 0))





const NGOJOL_BARANG: = [["Galon air", "Toko Haji Maman"], ["Paket online", "Rumah Kang Dadan"], ["Nasi bungkus", "Warung Bu Enok"], 
	["Obat", "Apotek desa"], ["Kue pesanan", "Rumah Bu Ida"], ["Telur 2 kg", "Pasar"], ["Gas melon", "Toko Haji Maman"]]
const NGOJOL_KEPERLUAN: = {
	"santai": ["Mau main ke rumah saudara", "Pulang, capek seharian", "Mau beli martabak", "Jalan-jalan sore, santai saja"], 
	"buru": ["Telat, ditunggu orang! Cepat ya, Pak", "Buru-buru, takut ketinggalan", "Sudah ditelepon terus, Pak"], 
	"rapuh": ["Bawa belanjaan banyak, pelan-pelan ya", "Habis jatuh, pinggangnya sakit", "Bawa kue, jangan sampai hancur"], 
}
const NGOJOL_ONGKOS_BURU: = 5000




func ngojol_order_hari() -> Array:
	var r: = RandomNumberGenerator.new()
	r.seed = hash("ojol2:%d:%d:%s" % [hari, slot_aktif, nama_warung])
	var warga: = WARGA_TIP.filter( func(t): return t != "ojek")
	var hasil: = []
	var selesai: = _ngojol_selesai()
	var maks_order: = ngojol_maks_order()
	var urutan: = range(maks_order)
	var acak_urut: Array = urutan.duplicate()
	for i in range(acak_urut.size() - 1, 0, -1):
		var j: = r.randi_range(0, i)
		var t = acak_urut[i]
		acak_urut[i] = acak_urut[j]
		acak_urut[j] = t
	var no_barang: Array = acak_urut.slice(0, r.randi_range(1, 3) * ngojol_pengali_hari())
	for i in maks_order:
		var npc: = String(warga[r.randi_range(0, warga.size() - 1)])
		var nama: = String(daftar_warga().get(npc, npc.capitalize()))
		var tj: Array = NGOJOL_TUJUAN[r.randi_range(0, NGOJOL_TUJUAN.size() - 1)]
		var jarak: = int(tj[1])
		var rentang: Array = NGOJOL_ONGKOS[jarak]
		var ongkos: = r.randi_range(int(rentang[0]) / 1000, int(rentang[1]) / 1000) * 1000
		var o: = {"no": i, "npc": npc, "nama": nama, "jarak": jarak, "selesai": i in selesai}
		if i in no_barang:
			var b: Array = NGOJOL_BARANG[r.randi_range(0, NGOJOL_BARANG.size() - 1)]
			o["jenis"] = "barang"
			o["barang"] = String(b[0])
			o["jemput"] = String(b[1])
			o["tujuan"] = "Rumah %s" % nama
			o["sifat"] = "rapuh" if String(b[0]) in ["Telur 2 kg", "Kue pesanan", "Nasi bungkus"] else "santai"
			o["catatan"] = "Titipan %s untuk %s" % [String(b[0]).to_lower(), nama]
		else:
			var sifat: String = "rapuh" if npc == "nenek" else ["santai", "santai", "buru", "rapuh"][r.randi_range(0, 3)]
			o["jenis"] = "orang"
			o["barang"] = ""
			o["jemput"] = "Rumah %s" % nama
			o["tujuan"] = String(tj[0])
			o["sifat"] = sifat
			var daftar: Array = NGOJOL_KEPERLUAN[sifat]
			o["catatan"] = String(daftar[r.randi_range(0, daftar.size() - 1)])
			if sifat == "buru":
				ongkos += NGOJOL_ONGKOS_BURU

		o["ongkos"] = ongkos
		o["km"] = snappedf(r.randf_range([0.6, 1.4, 2.6][jarak], [1.1, 2.0, 3.4][jarak]), 0.1)
		hasil.append(o)


	var total: = ngojol_total_hari()
	var bobot: = 0
	for o in hasil:
		bobot += int(o["ongkos"])
	var sisa_ribu: = (total - 5000 * hasil.size()) / 1000
	var bagian: = []
	var terbagi: = 0
	for o in hasil:
		var b: = int(floor(float(sisa_ribu) * int(o["ongkos"]) / maxf(bobot, 1.0)))
		bagian.append(b)
		terbagi += b
	var urut_bobot: = range(hasil.size())
	urut_bobot.sort_custom( func(x, y): return int(hasil[x]["ongkos"]) > int(hasil[y]["ongkos"]))
	for k in sisa_ribu - terbagi:
		bagian[urut_bobot[k % hasil.size()]] += 1
	for i in hasil.size():
		hasil[i]["ongkos"] = 5000 + int(bagian[i]) * 1000
	return hasil



func ngojol_order_tampil() -> Array:
	return ngojol_order_hari().filter( func(o): return not o["selesai"]).slice(0, NGOJOL_TAMPIL)


func ngojol_sisa() -> int:
	return ngojol_maks_order() - _ngojol_selesai().size()




func uji_ngojol() -> bool:
	return OS.has_feature("uji")


func punya_motor_ngojol() -> bool:
	return motor_baru or (uji_ngojol() and not motor_disita)



func alasan_tidak_bisa_ngojol() -> String:
	if uji_ngojol() and not motor_disita:
		if mode_latihan or tutorial_langkah != "":
			return "Belum bisa ngojol sekarang."
		if ngojol_sisa() <= 0:
			ngojol = {"hari": hari, "selesai": [], "uang": 0}
		return ""
	if not motor_baru and motor_disita:
		return "Motor sudah disita matel leasing. Beli atau cicil motor lagi di aplikasi Wishlist untuk narik ojek."
	if not motor_baru:
		return "Butuh motor sendiri. Beli Upgrade Motor di aplikasi Wishlist (terbuka di Level Warung %d)." % int(LEVEL_WISHLIST["motor"])
	if mode_latihan or tutorial_langkah != "":
		return "Belum bisa ngojol sekarang."
	var jam: = menit / 60.0
	if jam < ngojol_jam_mulai():
		var mulai: = "%02d.%02d" % [int(ngojol_jam_mulai()), int(round(fmod(ngojol_jam_mulai(), 1.0) * 60))]
		if hari_libur():
			return "Hari libur warung: order ojek dibuka mulai %s." % mulai
		if kios_milik:
			return "Order ojek dibuka mulai %s." % mulai
		return "Order ojek dibuka mulai %s, sesudah warung tutup." % mulai
	if jam >= ngojol_jam_akhir():
		return "Sudah terlalu malam. Order ojek dibuka lagi besok sore."
	if ngojol_sisa() <= 0:
		return "Order hari ini sudah habis. Besok sore ada order baru." if hari_libur() else "Order malam ini sudah habis. Besok sore ada order baru."
	if energi < NGOJOL_ENERGI + 5.0:

		return "%s terlalu lelah untuk ngojol: butuh energi %d, sekarang %d. Ngopi atau tonton iklan energi dulu." % ["Pak Misran", int(NGOJOL_ENERGI + 5.0), int(energi)]
	return ""



func ngojol_order_kuat() -> int:
	var e: = energi
	var n: = 0
	var biaya: = NGOJOL_ENERGI + NGOJOL_MENIT * ENERGI_PER_MENIT_SIANG
	while e >= NGOJOL_ENERGI + 5.0 and n < 10:
		e -= biaya
		n += 1
	return n


func ngojol_tip(hasil: float) -> int:
	return tip_minigame(NGOJOL_TIP_MAKS, hasil)






func ngojol_bayaran(order: Dictionary, hasil: float) -> Dictionary:
	var tarif: = int(order.get("ongkos", 0))
	var minta: = 2000 if hasil < 0.3 else (1000 if hasil < 0.6 else 0)
	var total: = ngojol_total_hari()
	var lo: = NGOJOL_TOTAL_MIN * ngojol_pengali_hari()
	var jatah: = int(floor(float(tarif) * (1.0 - float(lo) / maxf(total, 1.0)) / 500.0)) * 500
	var potong: = clampi(mini(minta, jatah), 0, tarif)
	return {"ongkos": tarif - potong, "tip": 0, "potong": potong, "tarif": tarif}



func selesaikan_ngojol(no: int, hasil: float) -> int:
	var order: = {}
	for o in ngojol_order_hari():
		if int(o["no"]) == no:
			order = o
	if order.is_empty() or order["selesai"]:
		return 0
	var bayar: = ngojol_bayaran(order, hasil)
	var ongkos: = int(bayar["ongkos"])
	var tip: = int(bayar["tip"])
	_ngojol_selesai().append(no)
	energi = maxf(energi - NGOJOL_ENERGI, 0.0)
	majukan_waktu(NGOJOL_MENIT)
	uang += ongkos + tip
	ngojol["uang"] = int(ngojol.get("uang", 0)) + ongkos + tip
	if String(order.get("jenis", "orang")) == "barang":
		catat_transaksi("Ongkos antar %s ke %s" % [String(order["barang"]).to_lower(), String(order["tujuan"]).to_lower()], ongkos)
	else:
		catat_transaksi("Ongkos ojek: %s ke %s" % [String(order["nama"]), String(order["tujuan"]).to_lower()], ongkos)
	if tip > 0:
		catat_transaksi("Tip penumpang ojek", tip)
	tambah_akrab(String(order["npc"]), AKRAB_KERJA * 0.5)
	analitik.catat("ngojol", {"uang": ongkos + tip, "hasil": snapped(hasil, 0.01)})
	bunyi("koin")
	data_berubah.emit()
	simpan()
	return ongkos + tip



func ikon_hp() -> String:
	return "res://assets/ikon_hud/hp_iphone.png" if hape_mewah else "res://assets/ikon_hud/hp_android.png"


func punya_wishlist(id: String) -> bool:
	match id:
		"rumah":
			return rumah_renovasi
		"motor":
			return motor_baru
		"hape":
			return hape_mewah
	return false


func alasan_tidak_bisa_wishlist(id: String) -> String:
	if punya_wishlist(id):
		return "Sudah terbeli."
	if level() < int(LEVEL_WISHLIST[id]):
		return "Terbuka di Level Warung %d." % int(LEVEL_WISHLIST[id])
	var harga: int = HARGA_WISHLIST[id]
	if uang < harga:
		return "Uangnya belum cukup. Kurang %s." % format_rupiah(harga - uang)
	return ""



func motor_dp() -> int:
	return mini(MOTOR_DP, int(HARGA_WISHLIST["motor"]))


func motor_angsuran() -> int:
	return ceili((int(HARGA_WISHLIST["motor"]) - motor_dp()) / float(MOTOR_TENOR) / 1000.0) * 1000


func motor_sisa_cicilan() -> int:
	return int(motor_cicil.get("sisa", 0))


func motor_tempo() -> int:
	return int(motor_cicil.get("tempo", -1))



func _hari_tempo(h: int) -> int:
	var n: = 0
	while hari_libur(h) and n < 7:
		h += 1
		n += 1
	return h


func alasan_tidak_bisa_cicil_motor() -> String:
	if motor_baru:
		return "Sudah terbeli."
	if level() < int(LEVEL_WISHLIST["motor"]):
		return "Terbuka di Level Warung %d." % int(LEVEL_WISHLIST["motor"])
	if uang < motor_dp():
		return "Uang muka belum cukup. Kurang %s." % format_rupiah(motor_dp() - uang)
	return ""


func cicil_motor() -> String:
	var alasan: = alasan_tidak_bisa_cicil_motor()
	if alasan != "":
		return alasan
	var dp: = motor_dp()
	uang -= dp
	motor_baru = true
	motor_disita = false
	motor_cicil = {"sisa": int(HARGA_WISHLIST["motor"]) - dp, "angsuran": motor_angsuran(), "tempo": _hari_tempo(hari + MOTOR_HARI_BULAN), "ke": 1}
	catat_transaksi("Uang muka motor (cicilan)", - dp)
	tambah_chat("Kang Asep", "Wih, motor baru! Hati-hati, Pak: cicilannya %s tiap bulan, jatuh tempo pertama %s. Telat bayar, matel dari leasing langsung tarik motornya. Sekarang %s bisa narik ojek sore-malam: buka aplikasi OjekKampung di HP." % [format_rupiah(motor_angsuran()), nama_tanggal_hari(motor_tempo()), "Pak Misran"], true, "teks", "rt")
	bunyi("hadiah")
	data_berubah.emit()
	simpan()
	return ""



func bayar_cicilan_motor() -> String:
	var sisa: = motor_sisa_cicilan()
	if sisa <= 0:
		return "Cicilan motor sudah lunas."
	var bayar: = mini(int(motor_cicil.get("angsuran", motor_angsuran())), sisa)
	if uang < bayar:
		return "Uang belum cukup. Kurang %s." % format_rupiah(bayar - uang)
	uang -= bayar
	sisa -= bayar
	catat_transaksi("Cicilan motor ke-%d" % int(motor_cicil.get("ke", 1)), - bayar)
	if sisa <= 0:
		motor_cicil = {}
		tambah_chat("Kang Asep", "Cicilan motor sudah LUNAS, Pak! Selamat, motornya sekarang milik sendiri. Tidak ada lagi matel.", true, "teks", "rt")
	else:
		motor_cicil["sisa"] = sisa
		motor_cicil.erase("ditunda")
		motor_cicil["ke"] = int(motor_cicil.get("ke", 1)) + 1
		motor_cicil["tempo"] = _hari_tempo(motor_tempo() + MOTOR_HARI_BULAN)
	bunyi("koin")
	data_berubah.emit()
	simpan()
	return ""


func lunasi_motor() -> String:
	var sisa: = motor_sisa_cicilan()
	if sisa <= 0:
		return "Cicilan motor sudah lunas."
	if uang < sisa:
		return "Uang belum cukup untuk melunasi. Kurang %s." % format_rupiah(sisa - uang)
	uang -= sisa
	motor_cicil = {}
	catat_transaksi("Pelunasan cicilan motor", - sisa)
	bunyi("koin")
	data_berubah.emit()
	simpan()
	return ""



func sita_motor(alasan: String) -> void :
	if not motor_baru:
		return
	motor_baru = false
	motor_disita = true
	motor_cicil = {}
	catat_transaksi("Motor disita leasing", 0)
	tambah_chat("Kang Asep", alasan, true, "teks", "rt")
	data_berubah.emit()
	simpan()






func matel_perlu_datang() -> bool:
	return motor_sisa_cicilan() > 0 and hari >= motor_tempo() and matel_datang_hari != hari and not mode_latihan and (uji_ngojol() or (menit >= MATEL_JAM and not sedang_hujan()))



func uji_matel_sekarang() -> void :
	if not uji_ngojol():
		return
	motor_baru = true
	motor_disita = false
	if motor_sisa_cicilan() <= 0:
		motor_cicil = {"sisa": int(HARGA_WISHLIST["motor"]) - motor_dp(), "angsuran": motor_angsuran(), "ke": 1}
	motor_cicil["tempo"] = hari
	matel_datang_hari = -1
	data_berubah.emit()
	simpan()



const MAKS_TUNDA_MOTOR: = 3

func _cek_cicilan_motor() -> void :
	if motor_sisa_cicilan() <= 0 or mode_latihan:
		return
	var tempo: = motor_tempo()




	if hari > tempo and matel_datang_hari < tempo and (int(motor_cicil.get("ditunda", 0)) < MAKS_TUNDA_MOTOR or uang + saldo_digital >= mini(int(motor_cicil.get("angsuran", motor_angsuran())), motor_sisa_cicilan())):
		var tagihan_motor: = mini(int(motor_cicil.get("angsuran", motor_angsuran())), motor_sisa_cicilan())
		if uang + saldo_digital >= tagihan_motor:
			_tarik_qris_untuk(tagihan_motor, "Ambil saldo QRIS untuk cicilan motor")
			bayar_cicilan_motor()
			tambah_chat("Kang Asep", "Pak Misran, matel kemarin belum sempat menagih, jadi cicilan motor %s dipotong otomatis dari uang warung. Motornya aman." % format_rupiah(tagihan_motor), true, "teks", "rt")
		else:
			motor_cicil["tempo"] = _hari_tempo(hari)
			motor_cicil["ditunda"] = int(motor_cicil.get("ditunda", 0)) + 1
			tambah_chat("Kang Asep", "Pak Misran, matel kemarin belum sempat menagih cicilan motor %s. Ia datang lagi pada hari jatuh tempo baru, tolong siapkan uangnya." % format_rupiah(tagihan_motor), true, "teks", "rt")
		return
	if hari > tempo:
		sita_motor("Pak Misran, semalam matel dari leasing datang ke rumah. Cicilan motor kemarin tidak dibayar, jadi motornya ditarik. Uang yang sudah dibayar hangus. Kalau mau, bisa cicil motor lagi dari awal di Wishlist.")
		return
	var angsuran: = int(motor_cicil.get("angsuran", motor_angsuran()))
	if hari == tempo - 3:
		tambah_chat("Kang Asep", "Pak, ingat: cicilan motor %s jatuh tempo %s. Siapkan uangnya, matel leasing tidak kenal kompromi." % [format_rupiah(angsuran), nama_tanggal_hari(tempo)], true, "teks", "rt")
	elif hari == tempo:
		tambah_chat("Kang Asep", "Pak, HARI INI cicilan motor %s jatuh tempo. Siang nanti matel datang ke warung. Kalau uangnya kurang, motornya langsung dibawa!" % format_rupiah(angsuran), true, "teks", "rt")


func beli_wishlist(id: String) -> String:
	var alasan: = alasan_tidak_bisa_wishlist(id)
	if alasan != "":
		return alasan
	var harga: int = HARGA_WISHLIST[id]
	uang -= harga
	match id:
		"rumah":
			rumah_renovasi = true
			catat_transaksi("Upgrade rumah", - harga)
			tambah_chat("Agus", "Pak! Rumahnya jadi bagus banget! Nanti pas libur aku betah di rumah. Makasih ya, Pak, sudah kerja keras.", true)
		"motor":
			motor_baru = true
			motor_disita = false
			catat_transaksi("Upgrade motor", - harga)
			tambah_chat("Kang Asep", "Wih, motor baru! Sekarang %s bisa ikut narik ojek sore-malam sesudah warung tutup. Buka aplikasi OjekKampung di HP, ambil order warga, lumayan buat tambahan." % "Pak Misran", true, "teks", "rt")
		"hape":
			hape_mewah = true
			catat_transaksi("Upgrade hape", - harga)
	bunyi("hadiah")
	data_berubah.emit()
	simpan()
	return ""


func lelah() -> bool:
	return energi < BATAS_LELAH



func perlu_ingatkan_lelah() -> bool:
	if lelah() and not lelah_diingatkan:
		lelah_diingatkan = true
		return true
	return false


func pengali_jalan_lelah() -> float:
	return 0.75 if lelah() else 1.0


func pengali_respon_lelah() -> float:
	return 0.85 if lelah() else 1.0


func jam_bangun_setelah_tidur(menit_tidur: float) -> int:
	for p in JAM_BANGUN_MENURUT_TIDUR:
		if menit_tidur < float(p[0]):
			return int(p[1])
	return 10 * 60



func barang_istirahat(pilihan: Array) -> Array:
	for b in pilihan[2]:
		if String(b[0]) == "":
			return b
		if terbuka(b[0]) and stok.has(b[0]) and int(stok[b[0]]) > 0:
			return b
	return []


func _catatan_istirahat() -> Dictionary:
	if int(istirahat_hari.get("hari", 0)) != hari:
		istirahat_hari = {"hari": hari}
	return istirahat_hari


func maks_istirahat(id_pilihan: String) -> int:
	return 1 if id_pilihan == "buka" else MAKS_ISTIRAHAT_HARIAN


func sisa_istirahat(id_pilihan: String) -> int:
	return maks_istirahat(id_pilihan) - int(_catatan_istirahat().get(id_pilihan, 0))



func tunggu_istirahat(id_pilihan: String) -> float:
	var c: = _catatan_istirahat()
	if not c.has(id_pilihan + "_menit"):
		return 0.0
	return maxf(float(c[id_pilihan + "_menit"]) + JEDA_ISTIRAHAT - menit, 0.0)



func istirahat(id_pilihan: String) -> String:
	if ramadan() and id_pilihan in ["ngopi", "makan"]:
		return "Pak Misran sedang puasa. Sesudah adzan Maghrib (18.00) bisa buka puasa."
	for p in pilihan_istirahat():
		if p[0] != id_pilihan:
			continue
		if id_pilihan == "buka" and menit < JAM_MAGHRIB:
			return "Pak Misran sedang puasa. Buka puasa baru bisa sesudah adzan Maghrib (18.00)."
		if sisa_istirahat(id_pilihan) <= 0:
			return "Hari ini sudah %d kali %s. Besok lagi, ya." % [maks_istirahat(id_pilihan), String(p[1]).to_lower()]
		if tunggu_istirahat(id_pilihan) > 0.0:
			return "Belum bisa %s lagi. Tunggu %s." % [String(p[1]).to_lower(), teks_durasi(tunggu_istirahat(id_pilihan))]
		var barang: = barang_istirahat(p)
		if barang.is_empty():
			return "Stok %s habis." % " / ".join((p[2] as Array).map( func(b): return String(data_barang(b[0]).get("sebutan", data_barang(b[0])["nama"])).to_lower()))
		if energi >= 99.0:
			return "Pak Misran masih segar, belum perlu istirahat."
		if String(barang[0]) != "":
			stok[barang[0]] -= 1
		energi = minf(energi + float(barang[1]), 100.0)
		var c: = _catatan_istirahat()
		c[id_pilihan] = int(c.get(id_pilihan, 0)) + 1
		majukan_waktu(float(p[3]))
		c[id_pilihan + "_menit"] = menit
		if not lelah():
			lelah_diingatkan = false
		data_berubah.emit()
		return ""
	return "Pilihan tidak dikenal."




func sisa_iklan_energi() -> int:
	return MAKS_IKLAN_ENERGI - int(_catatan_istirahat().get("iklan", 0))



func alasan_tidak_bisa_iklan_energi() -> String:
	if sisa_iklan_energi() <= 0:
		return "Iklan energi sudah dipakai hari ini. Besok bisa lagi."
	if energi >= 99.0:
		return "Pak Misran masih segar, belum perlu istirahat."
	return ""


func isi_energi_iklan() -> void :
	var c: = _catatan_istirahat()
	c["iklan"] = int(c.get("iklan", 0)) + 1
	energi = 100.0
	lelah_diingatkan = false
	data_berubah.emit()










const KERJA_SAMPINGAN: = {
	"panen": {"judul": "Bantu panen Abah Karta", "tombol": "Bantu panen", "npc": "petani", "nama": "Abah Karta", "area": "sawah", "posisi": [380, 512], "hadap": [1, 0.4], 
		"waktu": "pagi", "jam": [7.0, 9.0], "menit": 75, "syarat_event": "beras_abah_karta", "energi": 10, 
		"foto": "res://assets/kerja/kerja_panen.png", 
		"ajak": ["Pak Misran! Kebetulan, padi sebelah sini sudah kuning. Mau bantu panen sebentar? Upahnya {upah}.", 
			"Wilujeng enjing, Pak! Gabahnya harus diangkut sebelum panas. Bantu Abah sebentar, ya? Abah kasih {upah}.", 
			"Pak Misran, tangan Abah sudah tidak sekuat dulu. Bantu potong padi sebentar? Ada {upah} buat Bapak."], 
		"teks": "Memanen padi dan mengangkut karung gabah ke saung."}, 
	"rengginang": {"judul": "Bantu Nenek Sumi bikin rengginang", "tombol": "Bantu Nenek", "npc": "nenek", "nama": "Nenek Sumi", "area": "rumah", "posisi": [600, 482], "hadap": [1, 0.4], 
		"waktu": "pagi", "jam": [7.0, 9.0], "menit": 75, "syarat_event": "surat_nenek_sumi", "energi": 10, 
		"foto": "res://assets/kerja/kerja_rengginang.png", 
		"ajak": ["Nak Misran, pagi-pagi begini Nenek mau jemur rengginang. Bantu angkat tampahnya, ya? Nenek kasih {upah}.", 
			"Nak, minyaknya sudah panas, tapi rengginangnya banyak sekali. Mau bantu Nenek menggoreng? Ada {upah}.", 
			"Pagi ini Nenek sendirian. Bantu Nenek sebentar, Nak? Upahnya {upah}, sama rengginang buat cemilan."], 
		"teks": "Menjemur dan menggoreng rengginang bersama Nenek Sumi dan Ucup."}, 
	"angkut": {"judul": "Bantu angkut material Mang Ujang", "tombol": "Angkut material", "npc": "tukang", "nama": "Mang Ujang", "area": "rumah", "posisi": [1290, 785], "hadap": [-0.6, 1], 
		"waktu": "pagi", "jam": [7.0, 9.0], "menit": 75, "energi": 10, 
		"foto": "res://assets/kerja/kerja_angkut.png", 
		"ajak": ["Pak Misran, bantu saya angkut semen sama pasir ke rumah Pak Haji Rasyid, yuk. Saya kasih {upah}.", 
			"Pagi, Pak! Truk material baru datang, saya kewalahan. Bantu angkut sebentar? Upahnya {upah}.", 
			"Pak, mumpung belum panas, bantu saya pindahkan bata, ya. Ada {upah} buat Bapak."], 
		"teks": "Mengangkut sak semen dan ember pasir ke rumah Pak Haji Rasyid."}, 
	"antar": {"judul": "Antar pesanan bareng Kang Asep", "tombol": "Antar pesanan", "npc": "ojek", "nama": "Kang Asep", "area": "warung", "posisi": [540, 585], "hadap": [1, 0.4], 
		"waktu": "malam", "jam": [19.0, 21.5], "menit": 90, "energi": 10, 
		"foto": "res://assets/kerja/kerja_antar.png", 
		"ajak": ["Pak, malam ini orderan antar barang numpuk. Mau ikut bantu antar? Upahnya {upah}.", 
			"Kang Misran, saya kebanjiran order makanan malam ini. Bantu antar, yuk? Saya bagi {upah}.", 
			"Pak, motor saya cuma satu, pesanannya banyak. Bapak bonceng sambil bawa barang, ya? Ada {upah}."], 
		"teks": "Membonceng motor dan mengantar belanjaan ke rumah-rumah warga."}, 
	"masjid": {"judul": "Bersih-bersih masjid bareng Kang Fadil", "tombol": "Bantu bersih-bersih", "npc": "santri_putih", "nama": "Kang Fadil", "area": "masjid", "posisi": [420, 650], "hadap": [-1, -0.3], 
		"waktu": "malam", "jam": [19.0, 21.5], "menit": 90, "energi": 10, 
		"foto": "res://assets/kerja/kerja_masjid.png", 
		"ajak": ["Assalamualaikum, Pak Misran. Habis Isya karpet masjid harus digulung dan lantainya dipel. Bantu, Pak? Ada {upah} dari kas DKM.", 
			"Pak, besok ada pengajian besar, masjid harus bersih malam ini. Mau bantu? Upahnya {upah}.", 
			"Pak Misran, sandal jamaah berantakan dan karpet belum dijemur. Bantu sebentar, insyaallah berkah. Ada {upah}."], 
		"teks": "Menggulung karpet, mengepel lantai, dan merapikan sandal jamaah."}, 
	"packing": {"judul": "Bantu Mba Giska packing pesanan", "tombol": "Bantu packing", "npc": "giska", "nama": "Mba Giska", "area": "rumah", "posisi": [470, 432], "hadap": [1, 0.4], 
		"waktu": "malam", "jam": [19.0, 21.5], "menit": 90, "energi": 10, 
		"foto": "res://assets/kerja/kerja_packing.png", 
		"ajak": ["Pak Misran! Pesanan online saya lagi banjir, besok pagi harus dikirim semua. Bantu bungkus, ya? Saya bayar {upah}.", 
			"Pak, tolong saya dong, kardus sama lakbannya numpuk. Bantu packing sebentar? Ada {upah}.", 
			"Malam, Pak. Di kota dulu saya punya tim, di sini sendirian. Bantu packing pesanan, ya? Upahnya {upah}."], 
		"teks": "Membungkus pesanan online Mba Giska dan menempel label alamat."}, 
	"sembako": {"judul": "Bagi sembako bareng Pak RT", "tombol": "Bantu bagi sembako", "npc": "pak_rt", "nama": "Pak RT", "area": "rumah", "posisi": [300, 380], "hadap": [1, 0.3], 


		"waktu": "jumat", "jam": [16.0, 17.0], "menit": 180, "pengali_upah": 1.5, "energi": 10, 
		"foto": "res://assets/kerja/kerja_sembako.png", 
		"ajak": ["Pak Misran, sore ini bantu saya bagi sembako ke warga, ya. Lumayan lama, upahnya {upah}.", 
			"Pak, bantuan sembako dari kecamatan sudah datang. Bantu saya bagikan? Ada {upah} buat Bapak.", 
			"Hari Jumat begini Bapak libur, kan? Sore nanti bantu saya catat dan bagi sembako, yuk. Upahnya {upah}."], 
		"teks": "Membagikan paket sembako ke warga dan mencatat nama penerimanya."}, 

	"kenduri": {"judul": "Siapkan nasi kotak Jumat berkah", "tombol": "Bantu nasi kotak", "npc": "haji_doni", "nama": "Haji Doni", "area": "masjid", "posisi": [690, 590], "hadap": [-1, 0.3], 
		"waktu": "jumat", "jam": [13.0, 16.0], "menit": 120, "pengali_upah": 1.25, "energi": 10, 
		"ajak": ["Pak Misran, sesudah Jumatan kita bagi nasi kotak Jumat berkah. Bantu isi kotaknya, ya? Ada {upah} buat Bapak.", 
			"Mumpung warung libur, Pak, bantu saya siapkan nasi kotak buat jamaah dan anak yatim. Upahnya {upah}.", 
			"Pak Misran, ibu-ibu sudah masak banyak, tinggal dikemas. Bantu sebentar, insyaallah berkah. Ada {upah}."], 
		"teks": "Mengisi nasi kotak Jumat berkah untuk jamaah dan anak yatim."}, 
}
var kerja_hari: = {}





const UPAH_KERJA_TINGKAT: = [[7, 50000], [4, 40000], [1, 35000]]

func upah_kerja(id: = "") -> int:
	var dasar: = 35000
	for t in UPAH_KERJA_TINGKAT:
		if level() >= int(t[0]):
			dasar = int(t[1])
			break
	var pengali: = float(KERJA_SAMPINGAN.get(id, {}).get("pengali_upah", 1.0))
	return int(round(dasar * pengali / 1000.0)) * 1000






const MINIGAME_KERJA: = {
	"panen": ["mg_panen.gd", ""], "rengginang": ["mg_tata.gd", ""], "angkut": ["mg_tumpuk.gd", ""], 
	"antar": ["mg_cocok.gd", "antar"], "masjid": ["mg_bersih.gd", ""], "packing": ["mg_cocok.gd", "kardus"], 
	"sembako": ["mg_cocok.gd", "sembako"], "kenduri": ["mg_cocok.gd", "kenduri"], 
}
const MINIGAME_KERJA_IBU: = {"angkut": ["mg_cocok.gd", "tukang"], "antar": ["mg_cocok.gd", "pesanan"], "masjid": ["mg_bersih.gd", "ibu"]}
const PAKAI_MINIGAME_KERJA: = true
var pengali_kerja: = 1.0



func minigame_kerja(id: String) -> Array:
	if not PAKAI_MINIGAME_KERJA:
		return []
	var m: Array = (MINIGAME_KERJA_IBU if adalah_ibu() and MINIGAME_KERJA_IBU.has(id) else MINIGAME_KERJA).get(id, [])
	return [] if m.is_empty() else ["res://scripts/minigame/" + String(m[0]), String(m[1])]


func pengali_hasil_kerja(hasil: float) -> float:
	return clampf(0.25 + 0.75 * hasil / 0.9, 0.25, 1.0)



func upah_diterima(id: = "") -> int:
	return int(round(upah_kerja(id) * pengali_kerja / 1000.0)) * 1000



func ajakan_kerja(id: String) -> String:
	var ajak = KERJA_SAMPINGAN[id]["ajak"]

	if ajak is Array and tanah_basah():
		var cocok: Array = ajak.filter( func(k): return not (k.contains("panas") or k.contains("jemur")))
		if not cocok.is_empty():
			ajak = cocok
	var kalimat: = String(ajak.pick_random() if ajak is Array else ajak)

	if ramadan():
		kalimat = kalimat.replace("Habis Isya", "Habis tarawih")
	return kalimat.replace("{upah}", format_rupiah(upah_kerja(id)))





var kerja_gratis_hari: = -1
var kerja_gratis_jml: = 0
const KERJA_GRATIS_PER_HARI: = 2




const MINIGAME_TIP: = {
	"kembalian": {"file": "res://scripts/minigame/mg_kembalian.gd", "tip": 6000}, 
	"bungkus": {"file": "res://scripts/minigame/mg_bungkus.gd", "tip": 5000}, 
	"langganan": {"file": "res://scripts/minigame/mg_langganan.gd", "tip": 6000}, 
}


const MINIGAME_QRIS: = {"file": "res://scripts/minigame/mg_qris.gd", "tip": 6000}
const MAKS_QRIS_HARI: = 1

const WARGA_TIP: = ["pelajar", "kantoran", "ojek", "ibu_rumah_tangga", "anak", "nenek", "siswi", "santri_putih", "santri_hitam", "tukang", "petani", "giska", "pak_rt"]
var tip_mg_hari: = -1

func _acak_hari_tip() -> RandomNumberGenerator:
	var r: = RandomNumberGenerator.new()
	r.seed = hash("tip:%d:%d:%s" % [hari, slot_aktif, nama_warung])
	return r



func jam_minigame_tip() -> int:
	return 9 * 60 + _acak_hari_tip().randi_range(0, 7 * 60 + 30)


func minigame_tip_hari_ini() -> String:
	var r: = _acak_hari_tip()
	r.randi()
	var semua: = MINIGAME_TIP.keys()
	return String(semua[r.randi_range(0, semua.size() - 1)])



var qris_mg: = {"hari": -1, "n": 0}

func jam_minigame_qris() -> Array:
	var r: = RandomNumberGenerator.new()
	r.seed = hash("qris:%d:%d:%s" % [hari, slot_aktif, nama_warung])
	var hasil: = []
	for i in MAKS_QRIS_HARI:
		hasil.append(r.randi_range(10 * 60, 16 * 60))
	return hasil


func waktunya_minigame_qris() -> bool:
	if not punya_upgrade("qris") or mode_latihan or tutorial_langkah != "" or status_hari != "buka" or menit >= 17 * 60:
		return false
	var n: = int(qris_mg.get("n", 0)) if int(qris_mg.get("hari", -1)) == hari else 0
	return n < MAKS_QRIS_HARI and menit >= float(jam_minigame_qris()[n])


func catat_minigame_qris() -> void :
	if int(qris_mg.get("hari", -1)) != hari:
		qris_mg = {"hari": hari, "n": 0}
	qris_mg["n"] = int(qris_mg["n"]) + 1


func waktunya_minigame_tip() -> bool:
	return tip_mg_hari != hari and not mode_latihan and tutorial_langkah == "" and status_hari == "buka" and menit >= jam_minigame_tip() and menit < 17 * 60



func tip_minigame(maks: int, hasil: float) -> int:
	if hasil < 0.3:
		return 0
	return int(round(maks * clampf(hasil, 0.0, 1.0) / 500.0)) * 500

var kerja_tujuan: = ""

var peta_ditunjukkan: = false

func kerja_perlu_iklan() -> bool:
	return kerja_gratis_hari == hari and kerja_gratis_jml >= KERJA_GRATIS_PER_HARI



const BONUS_IKLAN_KERJA: = 1.0

func bonus_iklan_kerja(id: = "") -> int:
	return int(round(upah_diterima(id) * BONUS_IKLAN_KERJA / 1000.0)) * 1000


func gandakan_upah_kerja(id: String) -> void :
	var bonus: = bonus_iklan_kerja(id)
	uang += bonus


	catat_transaksi("Bonus iklan: %s" % String(KERJA_SAMPINGAN[id]["judul"]).to_lower(), bonus)
	bunyi("koin")
	data_berubah.emit()




func kerja_daftar_hari(h: int = -1) -> Array:
	if h < 1:
		h = hari

	if h == 1:
		return []
	var hasil: Array = []
	for waktu in ["pagi", "malam"]:
		var calon: Array = []
		for id in KERJA_SAMPINGAN:
			var k: Dictionary = KERJA_SAMPINGAN[id]
			var syarat: = String(k.get("syarat_event", ""))
			if String(k["waktu"]) == waktu and (syarat == "" or hasil_event(syarat) != ""):
				calon.append(id)
		if not calon.is_empty():
			hasil.append(calon[h % calon.size()])

	if hari_libur(h):
		for id in KERJA_SAMPINGAN:
			if String(KERJA_SAMPINGAN[id]["waktu"]) == "jumat":
				hasil.append(id)

	if ramadan(h) and nama_hari_ke(h) == "Kamis":
		hasil = hasil.filter( func(id): return String(KERJA_SAMPINGAN[id]["waktu"]) != "malam")
	return hasil





const JAM_KERJA_MALAM_RAMADAN: = [21.0, 22.0]
const JAM_KERJA_MALAM_KAMIS_AKHIR: = 20.5

func data_kerja(id: String) -> Dictionary:
	var k: Dictionary = KERJA_SAMPINGAN[id]
	if String(k["waktu"]) != "malam":
		return k
	var jam: Array = k["jam"]
	if ramadan():
		jam = JAM_KERJA_MALAM_RAMADAN
	elif nama_hari() == "Kamis":
		jam = [float(jam[0]), minf(float(jam[1]), JAM_KERJA_MALAM_KAMIS_AKHIR)]
	if jam == k["jam"]:
		return k
	var salin: = k.duplicate()
	salin["jam"] = jam
	return salin



func kerja_hari_ini(h: int = -1) -> String:
	var jam: = menit / 60.0
	var berikut: = ""
	for id in kerja_daftar_hari(h):
		if int(kerja_hari.get(id, 0)) == hari:
			continue
		var r: Array = data_kerja(id)["jam"]
		if jam >= float(r[0]) and jam < float(r[1]):
			return id
		if jam < float(r[0]) and (berikut == "" or float(r[0]) < float(data_kerja(berikut)["jam"][0])):
			berikut = id
	return berikut


func kerja_tersedia(id: String) -> bool:
	var k: Dictionary = data_kerja(id)
	var jam: = menit / 60.0
	return id in kerja_daftar_hari() and int(kerja_hari.get(id, 0)) != hari and jam >= float(k["jam"][0]) and jam < float(k["jam"][1])\
	and not di_rumah_saat_hujan(String(k["npc"]))



func alasan_tidak_bisa_kerja(id: String) -> String:
	var k: Dictionary = KERJA_SAMPINGAN[id]
	if not kerja_tersedia(id):
		return "Kerjaan ini sudah tidak tersedia hari ini."
	if energi < float(k["energi"]) + 5.0:
		return "Pak Misran terlalu lelah untuk kerja ini. Istirahat dulu."
	return ""


func kerjakan(id: String) -> String:
	var k: Dictionary = KERJA_SAMPINGAN[id]
	var alasan: = alasan_tidak_bisa_kerja(id)
	if alasan != "":
		return alasan
	kerja_hari[id] = hari
	if kerja_gratis_hari != hari:
		kerja_gratis_hari = hari
		kerja_gratis_jml = 0
	kerja_gratis_jml += 1
	energi = maxf(energi - float(k["energi"]), 0.0)
	majukan_waktu(float(k["menit"]))
	uang += upah_diterima(id)
	catat_upah(upah_diterima(id))
	tambah_akrab(String(k["npc"]), AKRAB_KERJA)
	catat_transaksi("Upah: %s" % String(k["judul"]).to_lower(), upah_diterima(id))
	bunyi("koin")
	data_berubah.emit()
	return ""



func pesan_kerja_sampingan() -> String:
	var daftar: = kerja_daftar_hari()
	if daftar.is_empty():
		return ""
	var baris: Array = []
	for id in daftar:
		var k: Dictionary = data_kerja(id)
		var judul: = String(k["judul"])
		baris.append("• %s\n   %s, upah %s" % [judul.left(1).to_upper() + judul.substr(1), teks_jam_rentang(k["jam"]), format_rupiah(upah_kerja(id))])
	return "Info kerja sampingan hari ini:\n\n%s\n\nYang mau, datangi orangnya (ada tanda Rp hijau di atas kepala)." % "\n\n".join(baris)


func teks_jam_rentang(r: Array) -> String:
	return "%02d.%02d–%02d.%02d" % [int(r[0]), int(fmod(float(r[0]), 1.0) * 60.0), int(r[1]), int(fmod(float(r[1]), 1.0) * 60.0)]



func teks_durasi(m: float) -> String:
	var j: = int(m) / 60
	var s: = int(ceil(m)) % 60
	if j > 0 and s > 0:
		return "%d jam %d menit" % [j, s]
	if j > 0:
		return "%d jam" % j
	return "%d menit" % maxi(s, 1)


func boleh_tutup() -> bool:
	return kios_milik or menit >= JAM_BOLEH_TUTUP




const JAM_WAJIB_TUTUP: = 17 * 60




const POLIGON_KIOS: = [[676, 292], [950, 312], [1200, 325], [1277, 366], [1277, 482], [1176, 586], [1126, 640], [1100, 800], 
	[580, 572], [555, 515], [555, 412], [668, 447]]
const TOPENG_KIOS: = "res://assets/latar/kios_gelap.png"
const WARNA_KIOS_TUTUP: = Color(0.03, 0.03, 0.08, 0.55)


func buat_gelap_kios() -> Sprite2D:
	var s: = Sprite2D.new()
	s.texture = load(TOPENG_KIOS)
	s.centered = false
	s.scale = Vector2(2, 2)
	s.self_modulate = WARNA_KIOS_TUTUP
	return s


func kios_tampak_tutup() -> bool:

	return status_hari == "tutup"




func tutup_otomatis() -> bool:
	if status_hari != "buka" or menit < jam_wajib_tutup():
		return false
	if not kiriman_stok.is_empty():
		terima_kiriman()
	status_hari = "tutup"
	tutup_hari()
	catat_riwayat_hari()
	simpan()
	data_berubah.emit()
	return true




const WARNA_SUASANA: = {
	0: Color(0.36, 0.38, 0.6), 
	5: Color(0.4, 0.42, 0.64), 
	6: Color(0.78, 0.8, 0.93), 
	9: Color(1.0, 0.98, 0.95), 
	13: Color(1.0, 1.0, 1.0), 
	16: Color(1.0, 0.93, 0.84), 
	17.5: Color(1.0, 0.82, 0.68), 
	18.5: Color(0.72, 0.62, 0.7), 
	19.5: Color(0.48, 0.48, 0.7), 
	24: Color(0.36, 0.38, 0.6), 
}
var _gradasi_suasana: Gradient = null


func warna_suasana(menit_ke: float = -1.0) -> Color:
	if _gradasi_suasana == null:
		_gradasi_suasana = Gradient.new()
		var titik: = PackedFloat32Array()
		var warna: = PackedColorArray()
		for jam in WARNA_SUASANA:
			titik.append(float(jam) / 24.0)
			warna.append(WARNA_SUASANA[jam])
		_gradasi_suasana.offsets = titik
		_gradasi_suasana.colors = warna
	return _gradasi_suasana.sample(fmod(menit if menit_ke < 0.0 else menit_ke, 24.0 * 60.0) / (24.0 * 60.0))


func malam_hari() -> bool:
	return menit >= JAM_MALAM or menit < JAM_MULAI - 60




var tampak_malam: = false

func musik_suasana() -> String:
	return "malam" if malam_hari() or tampak_malam else "latar"






func tidur(kesiangan: = false, alasan: = "") -> bool:


	if not kiriman_stok.is_empty():
		terima_kiriman()
	if status_hari != "tutup":
		status_hari = "tutup"
		tutup_hari()
		catat_riwayat_hari()

	if hari_sewa() and sewa_selesai_hari != hari:
		_bayar_sewa()
		bangkrut = bangkrut or diusir
	var r: Dictionary = riwayat[-1] if not riwayat.is_empty() and int(riwayat[-1]["hari"]) == hari else {}
	analitik.catat("hari_selesai", {"hari": hari, "omzet": int(r.get("omzet", 0)), "laba": int(r.get("laba", 0)), 
		"dilayani": int(r.get("dilayani", 0)), "batal": int(r.get("batal", 0)), "uang": uang, "jam_tidur": int(menit / 60), 
		"bab": bab})
	if bangkrut:
		analitik.catat("bangkrut", {"diusir": diusir, "uang": uang})
		simpan()
		return false
	var menit_tidur: = menit
	mulai_hari_berikutnya()

	menit = JAM_BANGUN_RONDA if kesiangan else jam_bangun_setelah_tidur(menit_tidur)
	jam_bangun_tadi = int(menit)
	energi = 100.0
	lelah_diingatkan = false
	alasan_bangun = alasan if alasan != "" else ("ronda" if kesiangan else ("begadang" if menit > JAM_MULAI else ""))
	bangun_kesiangan = alasan_bangun != ""
	simpan()
	return true






const BIAYA_TERTABRAK: = 100000
var hari_sembuh: = -1


const LETAK_PERBAN: = ["kaki_kiri", "kaki_kanan", "lengan_kiri", "lengan_kanan", "kepala"]
var perban_letak: Array = []
var hari_tertabrak: = -99
var utang_dokter: = 0
var pejalan_lintas: Array = []
var sedang_sakit: = false
var lindungi_hari_minus: = false




func _acak_perban(pertama: bool) -> Array:
	if pertama:
		return ["kaki_kanan"]
	var lama: = perban_letak.duplicate()
	lama.sort()
	for coba in 20:
		var pilihan: Array = LETAK_PERBAN.duplicate()
		pilihan.shuffle()
		var hasil: Array = pilihan.slice(0, 1 + randi() % 3)
		hasil.sort()
		if hasil != lama:
			return hasil
	return ["kepala"]


func pernah_tertabrak() -> bool:
	return hari_tertabrak >= 0



func bayar_dokter_sendiri() -> int:
	return mini(BIAYA_TERTABRAK, maxi(uang, 0)) if pernah_tertabrak() else 0



func teks_biaya_tertabrak() -> String:
	var biaya: = format_rupiah(BIAYA_TERTABRAK)
	if not pernah_tertabrak():
		return """Biaya dokter %s.
Kali ini warga patungan membantu.""" %biaya
	var sisa: = BIAYA_TERTABRAK - bayar_dokter_sendiri()
	if sisa <= 0:
		return "Biaya dokter %s." % biaya
	return """Biaya dokter %s.
Uang kurang, sisa %s jadi utang.""" %[biaya, format_rupiah(sisa)]


func _potong_utang_dokter() -> void :
	var bayar: = mini(utang_dokter, maxi(uang, 0))
	if bayar <= 0:
		return
	uang -= bayar
	utang_dokter -= bayar
	catat_transaksi("Cicilan utang dokter", - bayar)




var tabrakan_tertunda: = false

func tertabrak() -> bool:
	tabrakan_tertunda = false
	var dibantu: = not pernah_tertabrak()
	var bayar: = bayar_dokter_sendiri()
	if bayar > 0:
		uang -= bayar
		catat_transaksi("Biaya dokter (kaki Pak Misran terkilir)", - bayar)
	hari_tertabrak = hari
	perban_letak = _acak_perban(dibantu)
	if dibantu:
		tambah_chat("Pak RT", "Bapak-Ibu, alhamdulillah patungan untuk biaya dokter Pak Misran sudah terkumpul %s. Terima kasih semuanya. Semoga Pak Misran cepat sembuh." % format_rupiah(BIAYA_TERTABRAK), true, "teks", "rt")
	elif bayar < BIAYA_TERTABRAK:
		utang_dokter += BIAYA_TERTABRAK - bayar
		tambah_chat("Pak RT", "Pak Misran, maaf, warga belum bisa patungan lagi. Sisa biaya dokter %s dicatat sebagai utang dan dipotong dari uang warung. Hati-hati menyeberang, Pak." % format_rupiah(BIAYA_TERTABRAK - bayar), true, "teks", "rt")

	tambah_chat("Agus", "Pak!! Kata Pak RT Bapak hampir ketabrak di depan warung sampai jatuh? Bapak gimana keadaannya? Aku khawatir banget.", true)
	tambah_chat("Bapak", "Tenang, Gus. Bapak baik-baik saja, cuma lecet sama kaki agak pegal. Kata dokter cukup istirahat dua hari.")
	tambah_chat("Agus", "Alhamdulillah... Bapak istirahat yang benar ya, jangan dipaksa jaga warung dulu. Lain kali hati-hati nyeberang, Pak.", true)
	tambah_chat("Bapak", "Iya, Gus. Bapak kapok, sekarang lihat kiri-kanan dulu. Kamu fokus kuliah saja, jangan khawatir.")


	lindungi_hari_minus = true
	var lanjut: = tidur(false, "tertabrak")
	sedang_sakit = true
	lanjut = lanjut and tidur(false, "tertabrak")
	sedang_sakit = false
	lindungi_hari_minus = false
	if not lanjut:
		return false
	menit = JAM_MULAI
	jam_bangun_tadi = int(menit)
	hari_sembuh = hari
	simpan()
	return true




const JAM_KUMPUL_RONDA: = 21 * 60
const JAM_MULAI_RONDA: = 22 * 60
const JAM_BANGUN_RONDA: = 10 * 60
var ronda_terakhir: = 0
var bangun_kesiangan: = false
var jumatan_hari: = 0


func waktunya_ronda() -> bool:
	return ikut_ronda_jumatan() and nama_hari() == "Kamis" and menit >= JAM_KUMPUL_RONDA and ronda_terakhir != hari


func ikut_ronda_jumatan() -> bool:
	return not adalah_ibu()


func _process(_delta: float) -> void :
	if sedang_main:
		_cek_cuaca()
		_cek_maghrib()
		_cek_tagihan_sewa()
	_perbarui_takbiran()

	if sedang_main and (_musik_sekarang == "latar" or _musik_sekarang == "malam"):
		var mau: = musik_suasana()
		if mau != _musik_sekarang:
			putar_musik(mau, 5.0)






const FILE_TAKBIRAN: = "res://assets/suara/takbiran.mp3"
var volume_takbir_db: = -8.0
var _takbir: AudioStreamPlayer = null
var _takbir_nyala: = false

func waktu_takbiran() -> bool:
	return (hari == HARI_LEBARAN - 1 and menit >= 19 * 60) or (hari == HARI_LEBARAN and menit >= 6 * 60 and menit < 9 * 60)


func _perbarui_takbiran() -> void :
	var mau: = sedang_main and waktu_takbiran()
	if mau and _takbir == null:
		if not ResourceLoader.exists(FILE_TAKBIRAN):
			return
		var s: AudioStreamMP3 = (load(FILE_TAKBIRAN) as AudioStreamMP3).duplicate()
		s.loop = true
		_takbir = AudioStreamPlayer.new()
		_takbir.stream = s
		_takbir.bus = "Sekitar"
		_takbir.volume_db = -50.0
		_takbir.process_mode = Node.PROCESS_MODE_ALWAYS
		add_child(_takbir)
	if _takbir == null:
		return
	if mau and not _takbir_nyala:
		_takbir_nyala = true
		_takbir.play()
	elif not mau and _takbir_nyala:
		_takbir_nyala = false

	var tujuan: = volume_takbir_db if _takbir_nyala else -50.0
	_takbir.volume_db = move_toward(_takbir.volume_db, tujuan, get_process_delta_time() * 12.0)
	if not _takbir_nyala and _takbir.volume_db <= -49.0 and _takbir.playing:
		_takbir.stop()


func teks_jam() -> String:
	var m: = int(menit) % (24 * 60)
	return "%02d.%02d WIB" % [m / 60, m % 60]


func nama_hari() -> String:
	return NAMA_HARI[(hari - 1) % 7]



const TANGGAL_MULAI: = "2025-01-06T00:00:00"
const NAMA_BULAN: = ["Januari", "Februari", "Maret", "April", "Mei", "Juni", "Juli", "Agustus", "September", "Oktober", "November", "Desember"]



func tanggal(h: int = -1) -> Dictionary:
	if h < 1:
		h = hari
	var awal: = Time.get_unix_time_from_datetime_string(TANGGAL_MULAI)
	return Time.get_datetime_dict_from_unix_time(awal + (h - 1) * 86400)



func teks_tanggal(h: int = -1, pendek: = false) -> String:
	var t: = tanggal(h)
	var bulan: String = NAMA_BULAN[int(t["month"]) - 1]
	return "%d %s" % [int(t["day"]), bulan.left(3) if pendek else bulan]


func nama_hari_ke(h: int) -> String:
	return NAMA_HARI[posmod(h - 1, 7)]



func nama_tanggal_hari(h: int) -> String:
	return "%s, %s" % [nama_hari_ke(h), teks_tanggal(h)]




func data_barang(id: String) -> Dictionary:
	return katalog[id]


func barang_fisik() -> Array[String]:
	var hasil: Array[String] = []
	for id in urutan_barang:
		if katalog[id]["jenis"] == "fisik":
			hasil.append(id)
	return hasil




func barang_belanja() -> Array[String]:
	var hasil: Array[String] = []
	for id in barang_fisik():
		if not titipan_sales(id):
			hasil.append(id)
	return hasil





func isi_otomatis_layanan(id: String, jumlah: = 1) -> int:
	var perlu: = int(data_barang(id)["modal"]) * jumlah
	var diisi: = 0
	while saldo_layanan < perlu and uang >= JUMLAH_ISI_OTOMATIS:
		isi_saldo_layanan(JUMLAH_ISI_OTOMATIS)
		diisi += JUMLAH_ISI_OTOMATIS
	return diisi


func alasan_tidak_bisa_jual(id: String) -> String:
	var b: = data_barang(id)
	if status_hari != "buka":
		return "Maaf, warung sedang tutup."
	if not terbuka(id):
		return "Maaf, warung belum menjual barang itu."
	if b["jenis"] == "fisik" and stok[id] <= 0:
		return "Maaf, %s habis." % b["nama"].to_lower()
	if b["jenis"] == "layanan" and saldo_layanan < b["modal"]:
		return "Maaf, saldo layanan tidak cukup."
	return ""



func jual(id: String) -> String:
	var alasan: = alasan_tidak_bisa_jual(id)
	if alasan != "":
		return alasan
	var b: = data_barang(id)
	var harga: = harga_jual(id)

	var modal: = int(b["modal"])
	if b["jenis"] == "fisik":
		stok[id] -= 1
		modal = harga_modal(id)
	else:
		saldo_layanan -= b["modal"]
	uang += harga
	omzet_hari += harga
	if not mode_latihan:
		_ganti_periode_papan()
		omzet_bulan += harga
		omzet_minggu += harga
	laba_hari += harga - modal
	barang_terjual_hari += 1
	var r: Array = penjualan_hari.get(id, [0, 0, 0])
	penjualan_hari[id] = [r[0] + 1, r[1] + harga, r[2] + harga - modal]
	progres["barang"] += 1
	progres["omzet"] += harga
	match jenis_khusus():
		"minuman":
			if b.get("kategori", "") == "minuman":
				progres["khusus"] += 1
		"laba_hari":
			progres["khusus"] = maxi(progres["khusus"], laba_hari)
	_cek_tugas()
	data_berubah.emit()
	return ""



func beli_stok(id: String, jumlah: int) -> String:
	var b: = data_barang(id)
	if wajib_etalase and not punya_upgrade("etalase"):
		return "Beli etalase kaca dulu lewat tombol Upgrade warung di kiri atas (modal awal sudah termasuk Rp500.000 untuk etalase)."
	if not terbuka(id):
		return "%s belum bisa dijual (%s)." % [b["nama"], cara_buka_barang(id)]
	if titipan_sales(id):
		return "%s titipan sales, tidak dibeli sendiri." % b["nama"]
	if jumlah > sisa_muat_stok(id):
		return alasan_stok_penuh(id)
	var biaya: int = harga_modal(id) * jumlah
	if uang < biaya:
		return "Uang tidak cukup untuk membeli %d %s (%s)." % [jumlah, b["nama"].to_lower(), format_rupiah(biaya)]
	uang -= biaya

	kiriman_stok[id] = int(kiriman_stok.get(id, 0)) + jumlah
	if detik_kiriman <= 0.0 and not kurir_dalam_perjalanan:
		detik_kiriman = durasi_kirim()
	belanja_hari += biaya
	catat_transaksi("Belanja %d %s" % [jumlah, String(b["nama"]).to_lower()], - biaya)
	data_berubah.emit()
	return ""



func pakai_qris() -> bool:
	return punya_upgrade("qris") and randf() < PELUANG_BAYAR_QRIS



func terima_qris(jumlah: int) -> void :
	jumlah = mini(jumlah, uang)
	qris_hari += jumlah
	uang -= jumlah
	saldo_digital += jumlah
	data_berubah.emit()



const PILIHAN_TARIK_DIGITAL: = [50000, 100000]

func tarik_saldo_digital(jumlah: = 0) -> String:
	if saldo_digital <= 0:
		return "Saldo digital masih kosong."
	var n: = saldo_digital if jumlah <= 0 else jumlah
	if n > saldo_digital:
		return "Saldo digital hanya %s." % format_rupiah(saldo_digital)
	uang += n
	catat_transaksi("Tarik saldo digital (QRIS) ke laci", n)
	saldo_digital -= n
	data_berubah.emit()
	return ""




func _tarik_qris_untuk(jumlah: int, teks: String) -> void :
	var kurang: = mini(jumlah - uang, saldo_digital)
	if kurang <= 0:
		return
	saldo_digital -= kurang
	uang += kurang
	catat_transaksi(teks, kurang)



func bayar_campur(jumlah: int) -> bool:
	if uang + saldo_digital < jumlah:
		return false
	var dari_digital: = maxi(jumlah - uang, 0)
	saldo_digital -= dari_digital
	uang += dari_digital
	return true


func isi_saldo_layanan(jumlah: int) -> String:
	if uang < jumlah:
		return "Uang tidak cukup untuk isi saldo %s." % format_rupiah(jumlah)
	uang -= jumlah
	saldo_layanan += jumlah
	belanja_hari += jumlah
	catat_transaksi("Isi saldo layanan", - jumlah)
	data_berubah.emit()
	return ""


func _muat_katalog() -> void :
	var data = JSON.parse_string(FileAccess.get_file_as_string(FILE_BARANG))
	if data == null:
		push_error("Gagal membaca %s. Periksa penulisan file JSON-nya." % FILE_BARANG)
		return
	for b in data["barang"]:

		for kunci in ["modal", "jual", "stok_awal", "tampil_maks"]:
			if b.has(kunci):
				b[kunci] = int(b[kunci])
		katalog[b["id"]] = b
		urutan_barang.append(b["id"])


func _isi_stok_awal() -> void :
	stok.clear()
	for id in barang_fisik():
		stok[id] = katalog[id]["stok_awal"]


func _kosongkan_catatan_hari() -> void :
	biaya_harian_hari = 0
	sewa_dibayar_hari = 0
	denda_sewa_hari = 0
	penjualan_hari = {}
	omzet_hari = 0
	laba_hari = 0
	barang_terjual_hari = 0
	belanja_hari = 0
	pelanggan_dilayani_hari = 0
	pelanggan_batal_hari = 0
	hadiah_hari = 0
	qris_hari = 0
	uang_palsu_hari = 0



func format_rupiah(angka: int) -> String:
	var teks: = str(abs(angka))
	var hasil: = ""
	while teks.length() > 3:
		hasil = "." + teks.right(3) + hasil
		teks = teks.left(teks.length() - 3)
	return ("-" if angka < 0 else "") + "Rp" + teks + hasil



func rupiah_singkat(angka: int) -> String:

	var en: = bahasa == "en"
	if angka >= 1000000:
		if en:
			return ("%.1fM" % (angka / 1000000.0)).replace(".0M", "M")
		return ("%.1fjt" % (angka / 1000000.0)).replace(".0jt", "jt").replace(".", ",")
	if angka >= 1000:
		return ("%dk" if en else "%drb") % (angka / 1000)
	return str(angka)


func pilih_penjaga(pilihan: String, nama: = "") -> void :
	penjaga = pilihan
	if nama != "":
		nama_pemain = nama
	_perbarui_teks_tokoh()


func adalah_ibu() -> bool:
	return penjaga == "ibu"



func panggilan() -> String:
	return ("Bu " if adalah_ibu() else "Pak ") + nama_pemain



func tk(teks: String) -> String:
	return teks_tokoh.ubah(teks) if teks_tokoh != null else teks



func bahasa_perangkat() -> String:
	var l: = OS.get_locale_language()
	return "id" if l in ["id", "in", "ms", "jv", "su"] else "en"


func atur_bahasa(kode: String) -> void :
	bahasa = kode
	if teks_tokoh != null:
		teks_tokoh.atur_bahasa(kode)
	simpan_pengaturan()
	if is_inside_tree():
		get_tree().root.propagate_notification(NOTIFICATION_TRANSLATION_CHANGED)


func _perbarui_teks_tokoh() -> void :
	if teks_tokoh == null:
		return
	teks_tokoh.atur(nama_pemain, adalah_ibu())
	if is_inside_tree():
		get_tree().root.propagate_notification(NOTIFICATION_TRANSLATION_CHANGED)



func _lepas_teks_tokoh() -> void :
	if teks_tokoh != null:
		TranslationServer.remove_translation(teks_tokoh)
		teks_tokoh = null





func perban_tampil() -> Array:
	if hari != hari_sembuh:
		return []
	if file_model_penjaga() != String(FILE_MODEL_BAJU.get("sarung", "")):
		return perban_letak
	var hasil: Array = []
	for l in perban_letak:
		var ganti: String = {"kaki_kiri": "lengan_kiri", "kaki_kanan": "lengan_kanan"}.get(String(l), String(l))
		if not hasil.has(ganti):
			hasil.append(ganti)
	return hasil


func file_model_penjaga() -> String:


	if penjaga == "bapak" and FILE_MODEL_BAJU.has(baju_dipakai) and baju_dimiliki.has(baju_dipakai) and baju_penjaga().is_empty():
		return String(FILE_MODEL_BAJU[baju_dipakai])
	return FILE_MODEL_PENJAGA.get(penjaga, "meshy_bapak.glb")




const BAJU_PUTIH_BAPAK: = {"id": "bapak_putih", "bagian": [
	{"y": [0.5, 0.87], "pilih": [0.63, 0.14, 0.1, 1], "v": [0, 0.7], "warna": "#f2f0ea", "atur": [0.22, 0.5, 1], "mode": 0}, 
	{"y": [0.5, 0.87], "pilih": [0.97, 0.09, 0.28, 1], "v": [0.12, 1.01], "warna": "#f2f0ea", "atur": [0.62, 0.5, 1], "mode": 0}, 
	{"y": [0.02, 0.53], "pilih": [0, 1, 0, 0.2], "v": [0.16, 0.8], "warna": "#efede6", "atur": [0.4, 0.55, 1], "mode": 0}]}

func baju_penjaga() -> Dictionary:
	if penjaga == "bapak" and tahap_event("wisuda_fadil") == 2 and hasil_event("wisuda_fadil") == "":
		return BAJU_PUTIH_BAPAK
	return {}



func cfg_penjaga(cfg: Dictionary) -> Dictionary:
	var baju: = baju_penjaga()
	if not baju.is_empty():
		cfg["varian_baju"] = baju
	return cfg



func skala_penjaga() -> float:
	return 0.94 if adalah_ibu() else 1.0




static func siapkan_animasi_penjaga(pemutar: AnimationPlayer) -> void :
	if pemutar == null or not pemutar.has_animation("Walking_Woman"):
		return
	var pustaka: = pemutar.get_animation_library("")
	if pustaka == null:
		return
	for nama_anim in ALIAS_ANIM_IBU:
		var asal: String = ALIAS_ANIM_IBU[nama_anim]
		if pustaka.has_animation(asal) and (nama_anim == "Walking" or not pustaka.has_animation(nama_anim)):
			if pustaka.has_animation(nama_anim):
				pustaka.remove_animation(nama_anim)
			pustaka.add_animation(nama_anim, pustaka.get_animation(asal))




func rapikan_nama_pemain(teks: String) -> String:
	var hasil: = ""
	for c in teks.strip_edges():
		if c == " " or (c.to_lower() != c.to_upper()):
			hasil += c
	while hasil.contains("  "):
		hasil = hasil.replace("  ", " ")
	var kata: = Array(hasil.strip_edges().split(" ", false))
	while kata.size() > 1 and String(kata[0]).to_lower() in ["pak", "bu", "bapak", "ibu", "mas", "mbak", "kang", "ceu", "teh"]:
		kata.pop_front()
	if kata.size() == 1 and String(kata[0]).to_lower() in ["pak", "bu", "bapak", "ibu", "mas", "mbak", "kang", "ceu", "teh"]:
		return ""
	for i in kata.size():
		kata[i] = String(kata[i]).left(1).to_upper() + String(kata[i]).substr(1).to_lower()
	return " ".join(kata).left(MAKS_NAMA_PEMAIN).strip_edges()


func nama_penjaga() -> String:
	if penjaga == "ibu":
		return "Ibu"
	return "Bapak"




const SAPAAN_PAGI: = ["Pagi, Pak Misran!", "Assalamualaikum, Pak.", "Punten, Pak, beli...", "Pak, beli dong...", 
	"Pagi, Pak. Sudah buka ya?", "Wilujeng enjing, Pak!", "Pak Misran, mau belanja nih..."]
const SAPAAN_SIANG: = ["Punten, Pak...", "Siang, Pak! Panas pisan, ya.", "Pak, beli...", "Assalamualaikum, Pak Misran.", 
	"Pak, numpang beli, ya...", "Permisi, Pak...", "Pak Misran, ada nggak ya..."]
const SAPAAN_SORE: = ["Sore, Pak Misran!", "Punten, Pak, mampir dulu...", "Pak, beli buat di rumah...", 
	"Sore, Pak. Masih ada stok?", "Pak, sekalian pulang, beli dulu..."]
const SAPAAN_MAGHRIB: = ["Pak Misran, udah mau Maghrib kok masih buka?", "Wah, untung masih buka, Pak!", 
	"Belum tutup, Pak? Alhamdulillah.", "Pak, buru-buru, keburu adzan Maghrib...", "Masih buka, Pak? Sekalian beli ah."]
const SAPAAN_MALAM: = ["Malam, Pak Misran!", "Masih buka ya, Pak? Syukurlah.", "Pak, untung warungnya masih nyala lampunya.", 
	"Punten, Pak, malam-malam ganggu...", 
	["Malam, Pak. Anak saya minta jajan, nih.", "orang_tua", "jajan_anak"], 
	["Malam, Nak Misran. Cucu Nenek minta jajan, nih.", "nenek", "jajan_anak"]]
const SAPAAN_LARUT: = ["Pak, belum tidur? Sudah malam, lho.", "Wah, Pak Misran buka sampai larut. Mantap!", 
	"Punten, Pak, malam-malam begini masih bisa beli?", "Pak, tadi kirain sudah tutup...", 
	["Malam, Pak. Habis ronda, lapar nih.", "bapak_bapak", "makanan"]]






const KELOMPOK_PEMBELI: = {
	"orang_tua": ["ibu_rumah_tangga", "kantoran", "ojek", "tukang", "petani", "pak_rt"], 
	"bapak_bapak": ["kantoran", "ojek", "tukang", "petani", "pak_rt"], 
	"anak_sekolah": ["anak", "pelajar", "siswi"], 
	"masak": ["ibu_rumah_tangga", "nenek", "giska"], 
	"pekerja": ["kantoran", "ojek", "tukang", "petani", "pak_rt", "giska"], 
	"dewasa": ["kantoran", "ojek", "ibu_rumah_tangga", "nenek", "tukang", "petani", "giska", "pak_rt", "santri_putih", "santri_hitam"], 
	"nenek": ["nenek"], 
	"semua": [], 
}
const KELOMPOK_BARANG: = {
	"jajan_anak": ["ciki", "permen", "biskuit", "teh_botol", "soda", "kerupuk", "rengginang", "air_mineral", "susu_kotak", "es_krim"], 
	"makanan": ["mi_goreng", "mi_rebus", "biskuit", "kerupuk", "ciki", "rengginang", "telur", "sachet", "kopi_susu", "teh_botol"], 
	"masak": ["beras", "telur", "minyak_goreng", "sayur", "lpg", "mi_rebus", "mi_goreng", "gula"], 
	"kopi": ["sachet", "kopi_susu", "minuman_energi"], 
	"minum_dingin": ["air_mineral", "teh_botol", "soda", "susu_kotak", "es_krim"], 
	"hangat": ["mi_rebus", "mi_goreng", "sachet", "kopi_susu", "kopi_bubuk"], 
	"pulsa": ["danda", "data_2gb", "data_5gb", "data_10gb", "token_listrik"], 
	"sekolah": ["buku_tulis"], 
}

const SAPAAN_KONTEKS: = [
	["Pak Misran, disuruh Ibu beli...", "anak_sekolah", "masak"], 
	["Pak, mau masak nih, ada yang kurang...", "masak", "masak"], 
	["Pak, ngopi dulu biar melek...", "pekerja", "kopi"], 
	["Aduh, haus banget, Pak...", "semua", "minum_dingin"], 
	["Pak, kuota saya habis, nih...", "dewasa", "pulsa"], 
	["Pak, besok ada tugas, beli buku dulu...", "anak_sekolah", "sekolah"], 
]
const PELUANG_SAPAAN_KONTEKS: = 0.35


func _kalimat_cocok(k, tipe: String, pesanan: Array) -> bool:
	if typeof(k) == TYPE_STRING:
		return true
	if tipe == "":
		return false
	var siapa: Array = KELOMPOK_PEMBELI.get(String(k[1]), [])
	if not siapa.is_empty() and not VarianBaju.sifat(tipe) in siapa:
		return false
	var barang: Array = KELOMPOK_BARANG.get(String(k[2]), [])
	var ids: Array = pesanan.map( func(p): return String(p[0]))
	if ids.is_empty():
		return false
	if String(k[2]) == "jajan_anak":
		return ids.all( func(id): return id in barang)
	return ids.any( func(id): return id in barang)



func _saring_kalimat(daftar: Array, tipe: String, pesanan: Array) -> Array:
	var hasil: Array = []
	for k in daftar:
		if _kalimat_cocok(k, tipe, pesanan):
			hasil.append(k if typeof(k) == TYPE_STRING else String(k[0]))
	return hasil
const TERIMA_KASIH: = ["Makasih, Pak!", "Hatur nuhun, Pak!", "Nuhun pisan, Pak Misran.", "Matur nuwun, Pak.", 
	"Terima kasih banyak, Pak!", "Sip, makasih ya, Pak. Laris manis!", "Makasih, Pak. Semoga berkah!", 
	"Hatur nuhun, Pak. Mangga, permisi.", "Makasih, Pak Misran. Besok ke sini lagi."]
const TERIMA_KASIH_MALAM: = ["Makasih, Pak. Jangan malam-malam tutupnya.", "Hatur nuhun, Pak. Istirahat, ya.", 
	"Makasih, Pak. Selamat malam!"]
var _kalimat_terakhir: = {}

func _pilih_kalimat(jenis: String, daftar: Array) -> String:
	var pilihan: = daftar.filter( func(k): return k != _kalimat_terakhir.get(jenis, ""))
	var k: String = (pilihan if not pilihan.is_empty() else daftar).pick_random()
	_kalimat_terakhir[jenis] = k
	return k


const SAPAAN_HUJAN: = ["Punten, Pak, numpang neduh sambil beli...", "Aduh, hujannya deras, Pak. Beli dulu, ah.", 
	"Pak Misran, untung warungnya buka, hujan-hujan begini...", "Brrr, dingin, Pak. Mau beli...", 
	"Hujan terus dari tadi, Pak. Mampir sekalian beli...", "Permisi, Pak, basah kuyup nih. Mau beli..."]
const SAPAAN_REDA: = ["Alhamdulillah sudah reda, Pak. Beli dulu...", "Pak, mumpung hujannya berhenti, mau beli...", 
	"Jalannya masih becek, Pak. Mampir beli dulu..."]
const TERIMA_KASIH_HUJAN: = ["Makasih, Pak. Nerobos hujan dulu, ya!", "Hatur nuhun, Pak. Mangga, permisi, mumpung agak reda.", 
	"Makasih, Pak. Hati-hati, lantainya licin.", ["Nuhun, Pak. Lumayan, buat hangat-hangat di rumah.", "semua", "hangat"]]


func sapaan_pelanggan(tipe: = "", pesanan: Array = []) -> String:
	var jam: = menit / 60.0

	var konteks: = _saring_kalimat(SAPAAN_KONTEKS, tipe, pesanan)
	if not konteks.is_empty() and randf() < PELUANG_SAPAAN_KONTEKS:
		return _pilih_kalimat("sapa", konteks)

	if sedang_hujan() and randf() < 0.6:
		return _pilih_kalimat("sapa", SAPAAN_HUJAN)
	if tanah_basah() and not sedang_hujan() and jam < 18.0 and randf() < 0.3:
		return _pilih_kalimat("sapa", SAPAAN_REDA)
	var daftar: Array = SAPAAN_LARUT
	if jam < 11.0:
		daftar = SAPAAN_PAGI
	elif jam < 15.0:
		daftar = SAPAAN_SIANG.filter( func(k): return not k.contains("Panas")) if tanah_basah() else SAPAAN_SIANG
	elif jam < 17.0:
		daftar = SAPAAN_SORE
	elif jam < 18.5:
		daftar = SAPAAN_MAGHRIB
	elif jam < 21.0:
		daftar = SAPAAN_MALAM
	return _pilih_kalimat("sapa", _saring_kalimat(daftar, tipe, pesanan))


func ucapan_terima_kasih(tipe: = "", pesanan: Array = []) -> String:
	if sedang_hujan() and randf() < 0.4:
		return _pilih_kalimat("makasih", _saring_kalimat(TERIMA_KASIH_HUJAN, tipe, pesanan))
	if menit >= 19 * 60 and randf() < 0.4:
		return _pilih_kalimat("makasih", TERIMA_KASIH_MALAM)
	return _pilih_kalimat("makasih", TERIMA_KASIH)




func barang_acak(dilarang: Array = [], suka: Dictionary = {}) -> String:
	var total: = 0.0
	var pilihan: = urutan_barang.filter( func(id): return bisa_diminta(id) and not id in dilarang)
	if pilihan.is_empty():
		pilihan = urutan_barang.filter( func(id): return terbuka(id) and not id in dilarang)
	for id in pilihan:
		total += peluang_barang(id) * float(suka.get(id, 1.0))
	var r: = randf() * total
	for id in pilihan:
		r -= peluang_barang(id) * float(suka.get(id, 1.0))
		if r <= 0.0:
			return id
	return pilihan[0]




func bisa_diminta(id: String) -> bool:
	return terbuka(id) and not (titipan_sales(id) and int(stok.get(id, 0)) <= 0)




func peluang_barang(id: String) -> float:
	var b: Dictionary = katalog[id]
	var p: = float(b.get("peluang", 1))
	var jam: = menit / 60.0
	for rentang in b.get("jam_laris", []):
		if jam >= float(rentang[0]) and jam < float(rentang[1]):
			p *= float(rentang[2])
	if b.get("kategori", "") == "minuman":
		p *= 1.0 + efek_upgrade("minuman")
	return p * pengali_barang_kejadian(id) * pengali_barang_ramadan(id)





func catat_pelanggan_dilayani(jumlah_jenis: int = 1) -> void :
	_catat_hasil_layan(true)
	var capek: = (ENERGI_PER_PELANGGAN + ENERGI_PER_JENIS_TAMBAHAN * maxi(jumlah_jenis - 1, 0)) * (PENGALI_ENERGI_RUMAH_BARU if rumah_renovasi else 1.0)
	energi = maxf(energi - capek, 0.0)
	pelanggan_dilayani_hari += 1
	_catat_pembeli_papan()
	progres["pelanggan"] += 1
	beruntun_sekarang += 1
	match jenis_khusus():
		"beruntun":
			progres["khusus"] = maxi(progres["khusus"], beruntun_sekarang)
		"multi":
			if jumlah_jenis >= 2:
				progres["khusus"] += 1
	_cek_tugas()
	data_berubah.emit()



func catat_pelanggan_batal() -> void :
	_catat_hasil_layan(false)
	pelanggan_batal_hari += 1
	beruntun_sekarang = 0
	data_berubah.emit()






const BANTUAN_JENDELA: = 20
const BANTUAN_SABAR: = 0.3
var riwayat_layan: Array = []


func bulan_sekarang() -> String:
	var t: = Time.get_datetime_dict_from_system()
	return "%04d-%02d" % [int(t["year"]), int(t["month"])]



func pembeli_bulan_ini() -> int:
	return pembeli_bulan if bulan_pembeli == bulan_sekarang() else 0



func minggu_sekarang() -> String:
	var t: = Time.get_datetime_dict_from_system()
	var hari_ini: = int(Time.get_unix_time_from_datetime_dict({"year": t["year"], "month": t["month"], "day": t["day"]}))
	var ke: = (int(t["weekday"]) + 6) % 7
	var senin: = Time.get_datetime_dict_from_unix_time(hari_ini - ke * 86400)
	return "%04d-%02d-%02d" % [int(senin["year"]), int(senin["month"]), int(senin["day"])]


func pembeli_minggu_ini() -> int:
	return pembeli_minggu if minggu_pembeli == minggu_sekarang() else 0


func omzet_minggu_ini() -> int:
	return omzet_minggu if minggu_pembeli == minggu_sekarang() else 0


func omzet_bulan_ini() -> int:
	return omzet_bulan if bulan_pembeli == bulan_sekarang() else 0



func omzet_semua() -> int:
	return total_riwayat("omzet", 1000000) + omzet_hari


func _ganti_periode_papan() -> void :
	var b: = bulan_sekarang()
	if bulan_pembeli != b:
		bulan_pembeli = b
		pembeli_bulan = 0
		omzet_bulan = 0
	var m: = minggu_sekarang()
	if minggu_pembeli != m:
		minggu_pembeli = m
		pembeli_minggu = 0
		omzet_minggu = 0



func nama_warung_lengkap() -> String:
	var n: = nama_warung if nama_warung != "" else "Pak Misran"
	return n if n.to_lower().begins_with("warung") else "Warung " + n


func _id_papan_baru() -> String:
	return Crypto.new().generate_random_bytes(16).hex_encode()


func _catat_pembeli_papan() -> void :
	if mode_latihan:
		return
	_ganti_periode_papan()
	total_pembeli += 1
	pembeli_bulan += 1
	pembeli_minggu += 1


func _catat_hasil_layan(berhasil: bool) -> void :
	riwayat_layan.append(berhasil)
	while riwayat_layan.size() > BANTUAN_JENDELA:
		riwayat_layan.pop_front()



func tingkat_bantuan() -> float:
	if mode != "casual" or riwayat_layan.size() < 8:
		return 0.0
	var batal: = riwayat_layan.count(false)
	return clampf((float(batal) / riwayat_layan.size() - 0.12) / 0.25, 0.0, 1.0)


func pengali_bantuan() -> float:
	return 1.0 + BANTUAN_SABAR * tingkat_bantuan()




func baris_tugas() -> Array:
	if segera_hadir():
		return []
	var t: = tugas_sekarang()
	var p: = progres
	var isi: = []

	match misi_status:
		"menunggu":
			isi.append([teks_tunggu_agus(), 0, 1, "…"])
		"aktif":
			var sisa: = sisa_hari()
			isi.append(["Kirim %s via Wasap · %s" % [nama_penerima(), "hari ini!" if sisa <= 1 else "%d hari" % sisa], kiriman_bab, target_bab, 
				"%s/%s" % [rupiah_singkat(kiriman_bab), rupiah_singkat(target_bab)]])
		"lunas":
			if String(data_bab().get("jenis", "kirim")) == "hadiah":
				isi.append(["%s mengirim %s" % [nama_penerima(), rupiah_singkat(target_bab)], 1, 1, ""])
			else:
				isi.append(["Kirim %s ke %s" % [rupiah_singkat(target_bab), nama_penerima()], 1, 1, ""])
	isi.append_array([
		["Layani %d pelanggan" % target_inti(t, "pelanggan"), p["pelanggan"], target_inti(t, "pelanggan"), "%d/%d" % [p["pelanggan"], target_inti(t, "pelanggan")]], 
		["Jual %d barang" % target_inti(t, "barang"), p["barang"], target_inti(t, "barang"), "%d/%d" % [p["barang"], target_inti(t, "barang")]], 
		["Omzet %s" % format_rupiah(target_inti(t, "omzet")), p["omzet"], target_inti(t, "omzet"), "%d%%" % int(100.0 * mini(p["omzet"], target_inti(t, "omzet")) / maxi(target_inti(t, "omzet"), 1))], 
	])

	if t.has("khusus"):
		var n: = target_khusus(t)
		var angka: = "%d/%d" % [mini(p["khusus"], n), n]
		if t["khusus"]["jenis"] == "laba_hari":
			angka = "%d%%" % int(100.0 * mini(p["khusus"], n) / n)
		elif t["khusus"]["jenis"] == "beruntun" and p["khusus"] < n:
			angka = "%d/%d" % [beruntun_sekarang, n]
		isi.append([teks_khusus(t), p["khusus"], n, angka])
	var bt: = target_bintang(t)
	if bt > 0:
		isi.append(["Reputasi min. %d bintang" % bt, bintang(), bt, "%d/%d" % [bintang(), bt]])

	if not t.get("upgrade", []).is_empty():
		var beres: = syarat_upgrade_beres(t)
		isi.append([teks_syarat_upgrade(t), 1 if beres else 0, 1, "✓" if beres else "belum"])
	return isi




func hadiah_level(lv: int) -> Dictionary:
	var barang: Array = []
	if lv == 1:
		barang = barang_awal()
	else:
		for i in cerita["bab"].size():
			if level_bab(i) == lv - 1:
				barang.append_array(cerita["bab"][i]["buka"])
		barang.append_array(data_tingkat(lv - 1).get("buka", []))
	var upg: Array = []
	for u in daftar_upgrade:
		if int(u["level"]) == lv:
			upg.append(String(u["id"]))
	return {"barang": barang, "upgrade": upg}



func barang_awal() -> Array:
	var lain: Array = []
	for b in cerita["bab"]:
		lain.append_array(b["buka"])
	for t in daftar_tingkat:
		lain.append_array(t.get("buka", []))
	for ev in data_event():
		lain.append_array(data_event()[ev].get("hasil", {}).get("tolong", {}).get("buka", []))
	for u in daftar_upgrade:
		lain.append_array(u.get("efek", {}).get("buka_barang", []))
	lain.append_array(BARANG_RAMADAN)
	return urutan_barang.filter( func(id): return not id in lain)


func syarat_upgrade_beres(t: Dictionary) -> bool:
	var daftar: Array = t.get("upgrade", [])
	return daftar.is_empty() or daftar.any( func(id): return punya_upgrade(String(id)))



func teks_syarat_upgrade(t: Dictionary) -> String:
	var nama: Array = (t.get("upgrade", []) as Array).map( func(id): return String(data_upgrade(String(id)).get("nama", id)))
	return "Upgrade: " + " / ".join(nama)







const KERINGANAN_MULAI_HARI: = 5
var hari_inti_beres: = 0


func hari_keringanan() -> int:
	if mode != "casual" or hari_inti_beres <= 0:
		return 0
	return maxi(0, hari - hari_inti_beres - KERINGANAN_MULAI_HARI + 1)


func faktor_keringanan() -> float:
	return maxf(0.4, 1.0 - 0.1 * hari_keringanan())


func target_khusus(t: Dictionary) -> int:
	var n: = int(t.get("khusus", {}).get("target", 0))
	return maxi(1, ceili(n * faktor_keringanan())) if n > 0 else 0


func target_bintang(t: Dictionary) -> int:
	var b: = int(t.get("bintang", 0))
	if b > 2:
		b = maxi(2, b - hari_keringanan() / 4)
	return b






const MACET_MULAI_HARI: = 45
var hari_level_mulai: = 1

func hari_di_level() -> int:
	return hari - hari_level_mulai


func faktor_macet() -> float:
	if mode != "casual":
		return 1.0
	return clampf(1.0 - 0.02 * (hari_di_level() - MACET_MULAI_HARI), 0.5, 1.0)


func macet() -> bool:
	return faktor_macet() < 1.0



func target_inti(t: Dictionary, kunci: String) -> int:
	var n: = int(t.get(kunci, 0))
	if kunci == "omzet":
		return int(ceil(n * faktor_macet() / 1000.0)) * 1000
	return ceili(n * faktor_macet())


func jenis_khusus() -> String:
	return String(tugas_sekarang().get("khusus", {}).get("jenis", ""))



func teks_khusus(t: Dictionary) -> String:
	var k: Dictionary = t.get("khusus", {})
	var n: = target_khusus(t)
	match String(k.get("jenis", "")):
		"beruntun": return "Layani %dx beruntun" % n
		"multi": return "%d pesanan campuran" % n
		"laba_hari": return "Laba %s sehari" % format_rupiah(n)
		"minuman": return "Jual %d minuman" % n
		"hari_sempurna": return "Sehari tanpa batal (min. %d)" % n
	return ""



func data_tingkat(i: int) -> Dictionary:
	if i < daftar_tingkat.size():
		return daftar_tingkat[i]
	return {"nama": "Segera Hadir", "segera_hadir": true, "pelanggan": 0, "barang": 0, "omzet": 0, "hadiah": 0, "bintang": 0}



func segera_hadir() -> bool:
	return tugas_sekarang().get("segera_hadir", false)


func tugas_sekarang() -> Dictionary:
	return data_tingkat(tingkat)


func _cek_tugas() -> void :
	if segera_hadir():
		return
	var t: = tugas_sekarang()
	var khusus_selesai: bool = progres["khusus"] >= target_khusus(t)
	var bintang_cukup: = bintang() >= target_bintang(t)

	var agus_beres: = misi_status == "" or misi_status == "lunas" or cerita_tamat
	var inti_beres: bool = progres["pelanggan"] >= target_inti(t, "pelanggan") and progres["barang"] >= target_inti(t, "barang") and progres["omzet"] >= target_inti(t, "omzet") and agus_beres
	if inti_beres and hari_inti_beres <= 0:
		hari_inti_beres = hari
	if inti_beres and khusus_selesai and bintang_cukup and syarat_upgrade_beres(t):
		var hadiah: int = t["hadiah"]
		uang += hadiah
		hadiah_hari += hadiah
		catat_transaksi("Hadiah Level Warung %d" % (tingkat + 1), hadiah)

		var bab_lunas: = bab if misi_status == "lunas" and not cerita_tamat else -1
		var cerita_naik: = ""
		var buka: Array = []
		if bab_lunas >= 0:
			buka.append_array(cerita["bab"][bab_lunas]["buka"])
			cerita_naik = String(cerita["bab"][bab_lunas].get("cerita_naik", ""))
		sewa_per_minggu()
		tingkat += 1
		for id in barang_level_ini():
			if not id in buka:
				buka.append(id)
		buka = buka.filter( func(id): return not terbuka(id))
		_buka_barang(buka)
		_kosongkan_progres()
		if bab_lunas == cerita["bab"].size() - 1:

			cerita_tamat = true
			misi_status = ""
			barang_terbuka = _semua_barang_cerita()
			_buka_barang_upgrade()
			dialog_tertunda.append("tamat")
		elif not cerita_tamat:
			_siapkan_misi_level()

		var alasan_sewa: = String(cerita["sewa"].get("alasan_naik", {}).get(str(tingkat), ""))
		if not kios_milik and alasan_sewa != "" and sewa_per_minggu(tingkat) > sewa_per_minggu(tingkat - 1):
			tambah_chat(nama_pemilik_kios(), alasan_sewa % format_rupiah(sewa_per_minggu(tingkat)), true, "teks", "juragan")
		naik_level_tertunda.append({"hadiah": hadiah, "level": tingkat + 1, "buka": buka, "cerita": cerita_naik})
		analitik.catat("naik_level", {"level": tingkat + 1, "uang": uang})
		if cerita_tamat and bab_lunas == cerita["bab"].size() - 1:
			analitik.catat("tamat")
		tugas_selesai.emit(hadiah, tingkat + 1)
		data_berubah.emit()




func isi_popup_naik(n: Dictionary) -> Array:
	var lv: = int(n["level"])
	var daftar: Array = [{"teks": "Hadiah uang %s" % format_rupiah(int(n["hadiah"])), "ikon": "res://assets/ikon/koin.svg"}]
	for id in n["buka"]:
		daftar.append({"teks": "%s terbuka" % String(data_barang(id)["nama"]), "ikon": "res://assets/barang/%s.png" % id})
	for u in daftar_upgrade:
		if int(u["level"]) == lv:
			daftar.append({"teks": "Upgrade %s terbuka" % String(u["nama"]), "ikon": ikon_upgrade(String(u["id"]))})

	var cerita_baru: Array = cerita_level(lv)
	if not cerita_baru.is_empty():
		daftar.append({"teks": "%d cerita warga baru: %s" % [cerita_baru.size(), ", ".join(cerita_baru)], "ikon": "res://assets/ikon/chat.svg"})
	var keterangan: = String(n.get("cerita", ""))
	if keterangan == "":
		keterangan = "Warung Pak Misran kini \"%s\". Terus layani pelanggan dengan baik!" % String(data_tingkat(lv - 1).get("nama", ""))
	if data_tingkat(lv - 1).get("segera_hadir", false):
		keterangan = "Semua level sudah tamat! Level %d segera hadir, nantikan pembaruan berikutnya." % lv
	return ["Selamat! Naik ke Level Warung %d" % lv, keterangan, daftar]


func _kosongkan_progres() -> void :
	progres = {"pelanggan": 0, "barang": 0, "omzet": 0, "khusus": 0}
	hari_inti_beres = 0
	hari_level_mulai = hari
	beruntun_sekarang = 0


func _muat_tugas() -> void :
	var data = JSON.parse_string(FileAccess.get_file_as_string(FILE_TUGAS))
	for t in data["tingkat"]:
		for kunci in ["pelanggan", "barang", "omzet", "hadiah"]:
			t[kunci] = int(t[kunci])
		t["bintang"] = int(t.get("bintang", 0))
		if t.has("khusus"):
			t["khusus"]["target"] = int(t["khusus"]["target"])
		daftar_tingkat.append(t)







const JUMLAH_SLOT: = 6
var slot_aktif: = 1
var slot_terakhir: = 0

func file_slot(n: int) -> String:
	return "user://simpanan_%d.json" % n


func ada_slot(n: int) -> bool:
	return FileAccess.file_exists(file_slot(n))


func ada_simpanan() -> bool:
	return slot_terakhir > 0 and ada_slot(slot_terakhir)



func info_slot(n: int) -> Dictionary:
	var data: = _baca_slot(n)
	if data.is_empty():
		return {}
	var h: = int(data.get("hari", 1))
	return {"nama_warung": String(data.get("nama_warung", "")), "hari": h, "hari_teks": "%s, %s" % [nama_hari_ke(h), teks_tanggal(h)], 
		"uang": int(data.get("uang", 0)), "qris": int(data.get("saldo_digital", 0)), "level": int(data.get("tingkat", 0)) + 1, "disimpan": String(data.get("disimpan", "")), 
		"panggilan": ("Bu " if data.get("penjaga", "bapak") == "ibu" else "Pak ") + String(data.get("nama_pemain", "Misran"))}


func hapus_slot(n: int) -> void :
	if slot_rusak(n):
		_sisihkan_slot_rusak(n)
	elif ada_slot(n):
		var data = JSON.parse_string(FileAccess.get_file_as_string(file_slot(n)))
		if typeof(data) == TYPE_DICTIONARY:
			papan.hapus(String(data.get("id_papan", "")))
		DirAccess.remove_absolute(ProjectSettings.globalize_path(file_slot(n)))
	_hapus_cadangan_slot(n)
	if slot_terakhir == n:
		slot_terakhir = 0
		simpan_pengaturan()





const FOLDER_SIMPANAN_BANGKRUT: = "user://simpanan_bangkrut"

func arsipkan_slot_bangkrut(n: int) -> void :
	if not ada_slot(n) or slot_rusak(n):
		hapus_slot(n)
		return
	var data = JSON.parse_string(FileAccess.get_file_as_string(file_slot(n)))
	if typeof(data) == TYPE_DICTIONARY:
		papan.hapus(String(data.get("id_papan", "")))
	DirAccess.make_dir_recursive_absolute(FOLDER_SIMPANAN_BANGKRUT)
	var tujuan: = "%s/simpanan_%d_%d.json" % [FOLDER_SIMPANAN_BANGKRUT, n, int(Time.get_unix_time_from_system())]
	if DirAccess.rename_absolute(ProjectSettings.globalize_path(file_slot(n)), ProjectSettings.globalize_path(tujuan)) != OK:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(file_slot(n)))
	_hapus_cadangan_slot(n)
	if slot_terakhir == n:
		slot_terakhir = 0
		simpan_pengaturan()



func _slot_terbaru() -> int:
	var terbaik: = 0
	var waktu: = -1
	for n in range(1, JUMLAH_SLOT + 1):
		if ada_slot(n):
			var w: = int(FileAccess.get_modified_time(file_slot(n)))
			if w > waktu:
				waktu = w
				terbaik = n
	return terbaik


func _pindahkan_simpanan_lama() -> void :
	if FileAccess.file_exists(FILE_SIMPAN) and not ada_slot(1):
		DirAccess.rename_absolute(ProjectSettings.globalize_path(FILE_SIMPAN), ProjectSettings.globalize_path(file_slot(1)))
		if slot_terakhir == 0:
			slot_terakhir = 1





var lokasi: = {}

func simpan() -> void :
	if mode_latihan:
		return
	if slot_terakhir != slot_aktif:
		slot_terakhir = slot_aktif
		simpan_pengaturan()
	var adegan: = get_tree().current_scene if is_inside_tree() else null
	if adegan != null and adegan.has_method("lokasi_simpan"):
		lokasi = adegan.lokasi_simpan()
	var data: = {
		"lokasi": lokasi, 
		"versi": 1, 
		"disimpan": Time.get_datetime_string_from_system(false, true), 
		"nama_warung": nama_warung, "nama_diganti": nama_diganti, 
		"id_papan": id_papan, "total_pembeli": total_pembeli, "pembeli_bulan": pembeli_bulan, "bulan_pembeli": bulan_pembeli, 
		"omzet_bulan": omzet_bulan, "minggu_pembeli": minggu_pembeli, "pembeli_minggu": pembeli_minggu, "omzet_minggu": omzet_minggu, 
		"mode": mode, 
		"reputasi": reputasi, "reputasi_awal_hari": reputasi_awal_hari, 
		"harga_jual_khusus": harga_jual_khusus, "harga_pasaran": harga_pasaran, "agen_kenalan": agen_kenalan, "hari_minus": hari_minus, "bangkrut": bangkrut, 
		"biaya_harian_hari": biaya_harian_hari, 
		"penjaga": penjaga, "nama_pemain": nama_pemain, "hari": hari, "menit": menit, "uang": uang, 
		"status_hari": status_hari, "stok": stok, "saldo_layanan": saldo_layanan, "saldo_digital": saldo_digital, 
		"tingkat": tingkat, "progres": progres, "beruntun_sekarang": beruntun_sekarang, "hari_inti_beres": hari_inti_beres, "hari_level_mulai": hari_level_mulai, 
		"denda_bab": denda_bab, 
		"upgrade": upgrade_dimiliki, 
		"kejadian": kejadian, "cuaca": cuaca, "hari_hujan_seharian": hari_hujan_seharian, "hari_banjir_terakhir": hari_banjir_terakhir, "neo_dikabari": neo_dikabari, "jadwal_hujan": jadwal_hujan, "cuaca_besok": cuaca_besok, 
		"chat": chat, "chat_belum": chat_belum, "kontak_warga": kontak_warga, 
		"tunggakan_sewa": tunggakan_sewa, "sewa_cicil": sewa_cicil, "sewa_kunci": sewa_kunci, "sewa_selesai_hari": sewa_selesai_hari, "sewa_dibayar_hari": sewa_dibayar_hari, "denda_sewa_hari": denda_sewa_hari, "kios_milik": kios_milik, 
		"transaksi": transaksi, "ulasan": ulasan, "promo": promo, "promo_hari_ke": promo_hari_ke, 
		"cerita_warga": cerita_warga, "keakraban": keakraban, "kiriman_warga": kiriman_warga, "jadwal_kiriman": jadwal_kiriman, "hutang": hutang, "hutang_ditolak": hutang_ditolak, "upah_harian": upah_harian, "ulasan_langganan_hari": ulasan_langganan_hari, "sapa_hari": sapa_hari, "akrab_naik_hari": akrab_naik_hari, 
		"ronda_terakhir": ronda_terakhir, "bangun_kesiangan": bangun_kesiangan, 
		"minggu_tunggak": minggu_tunggak, "diusir": diusir, "infak_hari": infak_hari, "infak_jumlah": infak_jumlah, "jajan_hari": jajan_hari, "jajan_dibeli": jajan_dibeli, "balas_budi_hari": balas_budi_hari, "bagikan_hari": bagikan_hari, 
		"energi": energi, "alasan_bangun": alasan_bangun, "jam_bangun_tadi": jam_bangun_tadi, "hari_sembuh": hari_sembuh, "tabrakan_tertunda": tabrakan_tertunda, "perban_letak": perban_letak, 
		"hari_tertabrak": hari_tertabrak, "utang_dokter": utang_dokter, 
		"iklan_upgrade": iklan_upgrade, "pengali_harga_upgrade": pengali_harga_upgrade, "wajib_etalase": wajib_etalase, "istirahat_hari": istirahat_hari, 
		"kerja_hari": kerja_hari, "kerja_berjalan": kerja_berjalan, "matel_datang_hari": matel_datang_hari, "bonus_mancing_hari": bonus_mancing_hari, 
		"tangkapan_tertunda": tangkapan_tertunda, "bonus_tautan_diambil": bonus_tautan_diambil, 
		"hasil_alam": hasil_alam, "tas_grosir": tas_grosir, "titipan": titipan, "mancing_hari": mancing_hari, "kebun_petik_hari": kebun_petik_hari, "kebun": kebun, 
		"versi_cerita": VERSI_CERITA, "bab": bab, "kiriman_bab": kiriman_bab, "target_bab": target_bab, "batas_hari": batas_hari, 
		"misi_status": misi_status, "misi_mulai_hari": misi_mulai_hari, "naik_level_tertunda": naik_level_tertunda, 
		"riwayat_layan": riwayat_layan, "kabar_hari": kabar_hari, "pengajian_hari": pengajian_hari, "jumatan_hari": jumatan_hari, "rumah_renovasi": rumah_renovasi, "motor_baru": motor_baru, "motor_cicil": motor_cicil, "motor_disita": motor_disita, "ngojol": ngojol, "hape_mewah": hape_mewah, "notif_dilihat": notif_dilihat, "agus_bantu_sampai": agus_bantu_sampai, "adzan_maghrib_hari": adzan_maghrib_hari, "zakat_dibayar": zakat_dibayar, "tarawih_hari": tarawih_hari, "thr_agus": thr_agus, "neo_makan_hari": neo_makan_hari, "promosi_mulai": promosi_mulai, "ajak_rating_sudah": ajak_rating_sudah, "tutorial_langkah": tutorial_langkah, "tutorial_awal": tutorial_awal, "tutorial_penutup": tutorial_penutup, 
		"kerja_gratis_hari": kerja_gratis_hari, "janji": janji, "janji_lewat": janji_lewat, "janji_dijadwal": janji_dijadwal, "kerja_gratis_jml": kerja_gratis_jml, "tip_mg_hari": tip_mg_hari, "qris_mg": qris_mg, "peta_ditunjukkan": peta_ditunjukkan, 
		"barang_terbuka": barang_terbuka, "cerita_tamat": cerita_tamat, "dialog_tertunda": dialog_tertunda, 
		"riwayat": riwayat, 
		"kiriman_stok": kiriman_stok, "kurir_pilihan": kurir_pilihan, "kurir_hari": kurir_hari, "instan_mulai": instan_mulai, 
		"penjualan_hari": penjualan_hari, 
		"catatan_hari": {
			"omzet": omzet_hari, "laba": laba_hari, "terjual": barang_terjual_hari, 
			"belanja": belanja_hari, "dilayani": pelanggan_dilayani_hari, 
			"batal": pelanggan_batal_hari, "hadiah": hadiah_hari, 
		}, 
	}
	if _tulis_slot_aman(slot_aktif, JSON.stringify(data, "\t")):
		_simpan_terakhir_ms = Time.get_ticks_msec()
		_dilayani_saat_simpan = pelanggan_dilayani_hari
		jam_simpan_terakhir = Time.get_time_string_from_system().left(5).replace(":", ".")










const SELANG_SIMPAN_OTOMATIS: = 45000
const SELANG_SIMPAN_MIN: = 10000
var _simpan_terakhir_ms: = 0
var _dilayani_saat_simpan: = 0
var jam_simpan_terakhir: = ""

func _cek_simpan_otomatis() -> void :
	if not sedang_main or mode_latihan or not is_inside_tree():
		return
	var adegan: = get_tree().current_scene
	if adegan == null or not adegan.has_method("lokasi_simpan"):
		return
	if adegan.has_method("boleh_simpan_otomatis") and not adegan.boleh_simpan_otomatis():
		return
	var lewat: = Time.get_ticks_msec() - _simpan_terakhir_ms
	if lewat >= SELANG_SIMPAN_OTOMATIS or (lewat >= SELANG_SIMPAN_MIN and pelanggan_dilayani_hari - _dilayani_saat_simpan >= 3):
		simpan()



func teks_simpan_terakhir() -> String:
	if jam_simpan_terakhir == "":
		return tk("Permainan tersimpan otomatis selama bermain. Dimuat lagi di tempat yang sama.")
	return tk("Tersimpan otomatis · terakhir pukul %s. Dimuat lagi di tempat yang sama.") % jam_simpan_terakhir




func tombol_kode_warung() -> Button:
	if cadangan == null or (akun != null and akun.tertaut()):
		return null
	var b: = Button.new()
	b.theme_type_variation = &"TombolKayu"
	b.custom_minimum_size = Vector2(0, 52)
	b.add_theme_font_size_override("font_size", 18)
	if String(cadangan.kode) == "":
		b.text = tk("Kode Warung muncul di sini sesudah tersambung internet")
		b.disabled = true
		return b
	var k: = String(cadangan.kode)
	b.text = tk("Kode Warung: %s (ketuk untuk salin)") % k
	b.pressed.connect( func():
		klik()
		DisplayServer.clipboard_set(k)
		b.text = tk("Kode %s disalin. Simpan di catatan atau WhatsApp sendiri.") % k)
	return b






func _tulis_slot_aman(n: int, teks: String) -> bool:
	var jalur: = ProjectSettings.globalize_path(file_slot(n))
	var tmp: = jalur + ".tmp"
	var bak: = jalur + ".bak"
	var f: = FileAccess.open(tmp, FileAccess.WRITE)
	if f == null:
		push_error("Gagal menyimpan game.")
		analitik.catat("simpan_gagal", {"alasan": "buka", "kode": FileAccess.get_open_error()})
		return false
	f.store_string(teks)
	f.close()
	var cek: = FileAccess.open(tmp, FileAccess.READ)
	var ukuran: = cek.get_length() if cek != null else -1
	if cek != null:
		cek.close()
	if ukuran != teks.to_utf8_buffer().size():
		push_error("Simpanan sementara tidak lengkap, simpanan lama dipertahankan.")
		analitik.catat("simpan_gagal", {"alasan": "tidak_lengkap", "ukuran": ukuran, "harus": teks.to_utf8_buffer().size()})
		DirAccess.remove_absolute(tmp)
		return false
	if FileAccess.file_exists(jalur):
		var lama: = FileAccess.open(jalur, FileAccess.READ)
		var ukuran_lama: = lama.get_length() if lama != null else 0
		if lama != null:
			lama.close()
		if ukuran_lama > 0:
			if FileAccess.file_exists(bak):
				DirAccess.remove_absolute(bak)
			DirAccess.rename_absolute(jalur, bak)
		else:
			DirAccess.remove_absolute(jalur)
	if DirAccess.rename_absolute(tmp, jalur) != OK:

		if not FileAccess.file_exists(jalur) and FileAccess.file_exists(bak):
			DirAccess.copy_absolute(bak, jalur)
		push_error("Gagal mengganti berkas simpanan.")
		analitik.catat("simpan_gagal", {"alasan": "ganti_nama"})
		return false
	return true



func _baca_slot(n: int) -> Dictionary:
	if not ada_slot(n):
		return {}
	var data = JSON.parse_string(FileAccess.get_file_as_string(file_slot(n)))
	if typeof(data) == TYPE_DICTIONARY:
		return data
	var bak: = file_slot(n) + ".bak"
	if FileAccess.file_exists(bak):
		data = JSON.parse_string(FileAccess.get_file_as_string(bak))
		if typeof(data) == TYPE_DICTIONARY:
			push_warning("Simpanan slot %d rusak, memakai cadangan." % n)
			analitik.catat("muat_cadangan", {"slot": n})
			return data
	return {}





func slot_rusak(n: int) -> bool:
	return ada_slot(n) and _baca_slot(n).is_empty()



func _sisihkan_slot_rusak(n: int) -> void :
	DirAccess.make_dir_recursive_absolute("user://simpanan_rusak")
	var ukuran: = 0
	var f: = FileAccess.open(file_slot(n), FileAccess.READ)
	if f != null:
		ukuran = f.get_length()
		f.close()
	var tujuan: = "user://simpanan_rusak/simpanan_%d_%d.json" % [n, int(Time.get_unix_time_from_system())]
	DirAccess.rename_absolute(ProjectSettings.globalize_path(file_slot(n)), ProjectSettings.globalize_path(tujuan))
	analitik.catat("simpanan_rusak", {"slot": n, "ukuran": ukuran})



func _hapus_cadangan_slot(n: int) -> void :
	for akhiran in [".bak", ".tmp"]:
		if FileAccess.file_exists(file_slot(n) + akhiran):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(file_slot(n) + akhiran))










const FOLDER_SIMPANAN_DIGANTI: = "user://simpanan_diganti"


func _folder_simpanan_lama() -> Array:
	var hasil: Array = [FOLDER_ARSIP_UJI, "user://simpanan_rusak", FOLDER_SIMPANAN_DIGANTI]
	var akar: = DirAccess.open(FOLDER_CADANGAN_VERSI)
	if akar != null:
		for sub in akar.get_directories():
			hasil.append(FOLDER_CADANGAN_VERSI + "/" + sub)
	return hasil




func daftar_simpanan_lama() -> Array:
	var di_slot: = {}
	for n in range(1, JUMLAH_SLOT + 1):
		var s: = _baca_slot(n)
		if not s.is_empty():
			var id_s: = String(s.get("id_papan", ""))
			di_slot[id_s] = maxi(int(di_slot.get(id_s, 0)), int(s.get("hari", 1)))
	var hasil: Array = []
	var sudah: = {}
	for folder in _folder_simpanan_lama():
		var d: = DirAccess.open(folder)
		if d == null:
			continue
		for f in d.get_files():
			if not (f.begins_with("simpanan") and f.ends_with(".json")):
				continue
			var jalur: = "%s/%s" % [folder, f]
			var pembaca: = JSON.new()
			if pembaca.parse(FileAccess.get_file_as_string(jalur)) != OK:
				continue
			var data = pembaca.data
			if typeof(data) != TYPE_DICTIONARY or not data.has("tingkat") or not data.has("hari"):
				continue
			var id_p: = String(data.get("id_papan", ""))
			var h: = int(data.get("hari", 1))
			if id_p != "" and di_slot.has(id_p) and int(di_slot[id_p]) >= h:
				continue
			var kunci: = "%s|%d|%s" % [id_p, h, String(data.get("nama_warung", ""))]
			if sudah.has(kunci):
				continue
			sudah[kunci] = true
			hasil.append({"jalur": jalur, "nama_warung": String(data.get("nama_warung", "")), "hari": h, 
				"hari_teks": "%s, %s" % [nama_hari_ke(h), teks_tanggal(h)], "uang": int(data.get("uang", 0)), 
				"level": int(data.get("tingkat", 0)) + 1, "disimpan": String(data.get("disimpan", "")), 
				"panggilan": ("Bu " if data.get("penjaga", "bapak") == "ibu" else "Pak ") + String(data.get("nama_pemain", "Misran"))})
	hasil.sort_custom( func(a, b): return a["level"] > b["level"] or (a["level"] == b["level"] and a["hari"] > b["hari"]))
	return hasil



func slot_untuk_pulihkan() -> int:
	for n in range(1, JUMLAH_SLOT + 1):
		if not ada_slot(n):
			return n
	return slot_terakhir if slot_terakhir > 0 else 1



func _sisihkan_slot_diganti(n: int) -> void :
	if not ada_slot(n):
		_hapus_cadangan_slot(n)
		return
	if slot_rusak(n):
		_sisihkan_slot_rusak(n)
	else:
		DirAccess.make_dir_recursive_absolute(FOLDER_SIMPANAN_DIGANTI)
		var tujuan: = "%s/simpanan_%d_%d.json" % [FOLDER_SIMPANAN_DIGANTI, n, int(Time.get_unix_time_from_system())]
		DirAccess.rename_absolute(ProjectSettings.globalize_path(file_slot(n)), ProjectSettings.globalize_path(tujuan))
	_hapus_cadangan_slot(n)




func pulihkan_simpanan_lama(jalur: String, n: int) -> bool:
	var teks: = FileAccess.get_file_as_string(jalur)
	var data = JSON.parse_string(teks)
	if typeof(data) != TYPE_DICTIONARY or n < 1 or n > JUMLAH_SLOT:
		return false
	_sisihkan_slot_diganti(n)
	if not _tulis_slot_aman(n, teks):
		return false
	if not jalur.begins_with(FOLDER_CADANGAN_VERSI):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(jalur))
	slot_terakhir = n
	simpan_pengaturan()
	analitik.catat("pulihkan_lama", {"slot": n, "level": int(data.get("tingkat", 0)) + 1, "hari": int(data.get("hari", 1)), 
		"sumber": jalur.get_base_dir().get_file()})
	return true



func muat(n: = 0) -> bool:
	if n <= 0:
		n = slot_terakhir
	if n <= 0 or not ada_slot(n):
		return false
	var data: = _baca_slot(n)
	if data.is_empty():
		return false
	slot_aktif = n
	slot_terakhir = n
	simpan_pengaturan()
	penjaga = data.get("penjaga", "bapak")
	nama_pemain = String(data.get("nama_pemain", "Misran"))
	_perbarui_teks_tokoh()
	nama_warung = data.get("nama_warung", "Berkah")
	nama_diganti = int(data.get("nama_diganti", 0))



	total_pembeli = int(data.get("total_pembeli", _pembeli_dari_riwayat(data)))
	pembeli_bulan = int(data.get("pembeli_bulan", 0))
	bulan_pembeli = String(data.get("bulan_pembeli", ""))
	omzet_bulan = int(data.get("omzet_bulan", 0))
	minggu_pembeli = String(data.get("minggu_pembeli", ""))
	pembeli_minggu = int(data.get("pembeli_minggu", 0))
	omzet_minggu = int(data.get("omzet_minggu", 0))
	id_papan = String(data.get("id_papan", ""))
	if id_papan == "":
		id_papan = _id_papan_baru()
	cek_hak_bebas_iklan.call_deferred()
	mode = data.get("mode", "casual")
	reputasi = float(data.get("reputasi", REPUTASI_AWAL))
	reputasi_awal_hari = float(data.get("reputasi_awal_hari", reputasi))
	harga_jual_khusus = {}
	var hk: Dictionary = data.get("harga_jual_khusus", {})
	for id in hk:
		harga_jual_khusus[id] = int(hk[id])
	harga_pasaran = data.get("harga_pasaran", {})
	agen_kenalan = bool(data.get("agen_kenalan", false))
	hari_minus = int(data.get("hari_minus", 0))
	bangkrut = bool(data.get("bangkrut", false))
	biaya_harian_hari = int(data.get("biaya_harian_hari", 0))
	hari = int(data["hari"])
	menit = float(data["menit"])
	lokasi = data.get("lokasi", {})
	uang = int(data["uang"])
	status_hari = data["status_hari"]
	saldo_layanan = int(data["saldo_layanan"])
	saldo_digital = int(data.get("saldo_digital", 0))
	_isi_stok_awal()
	for id in data["stok"]:
		if stok.has(id):
			stok[id] = int(data["stok"][id])
	tingkat = int(data.get("tingkat", 0))
	upgrade_dimiliki = data.get("upgrade", [])

	if upgrade_dimiliki.has("meja_kayu"):
		upgrade_dimiliki.erase("meja_kayu")
		if not upgrade_dimiliki.has("etalase"):
			upgrade_dimiliki.append("etalase")

	upgrade_dimiliki.erase("kulkas")
	kejadian = data.get("kejadian", {})
	cuaca = data.get("cuaca", {})
	hari_hujan_seharian = int(data.get("hari_hujan_seharian", -99))
	hari_banjir_terakhir = int(data.get("hari_banjir_terakhir", -99))
	neo_dikabari = bool(data.get("neo_dikabari", false))
	jadwal_hujan = data.get("jadwal_hujan", {})
	cuaca_besok = data.get("cuaca_besok", {})
	_hujan_lalu = sedang_hujan()

	var c_lama = data.get("chat", {})
	chat = {"agus": c_lama} if typeof(c_lama) == TYPE_ARRAY else c_lama
	chat_belum = data.get("chat_belum", {})
	kontak_warga = data.get("kontak_warga", {})
	tunggakan_sewa = int(data.get("tunggakan_sewa", 0))
	sewa_selesai_hari = int(data.get("sewa_selesai_hari", 0))
	sewa_cicil = int(data.get("sewa_cicil", 0))
	sewa_kunci = data.get("sewa_kunci", {})
	kios_milik = bool(data.get("kios_milik", false))
	sewa_dibayar_hari = int(data.get("sewa_dibayar_hari", 0))
	denda_sewa_hari = int(data.get("denda_sewa_hari", 0))
	transaksi = data.get("transaksi", [])
	ulasan = data.get("ulasan", [])

	reputasi = clampf((rating() - 1.0) * 25.0, 0.0, 100.0)
	cerita_warga = data.get("cerita_warga", {})
	keakraban = data.get("keakraban", {})
	kiriman_warga = data.get("kiriman_warga", {})
	hutang = data.get("hutang", [])
	hutang_ditolak = data.get("hutang_ditolak", {})
	upah_harian = data.get("upah_harian", {})
	jadwal_kiriman = data.get("jadwal_kiriman", {})
	ulasan_langganan_hari = data.get("ulasan_langganan_hari", {})
	sapa_hari = data.get("sapa_hari", {})
	akrab_naik_hari = data.get("akrab_naik_hari", {})
	ronda_terakhir = int(data.get("ronda_terakhir", 0))
	bangun_kesiangan = bool(data.get("bangun_kesiangan", false))
	minggu_tunggak = int(data.get("minggu_tunggak", 0))
	diusir = bool(data.get("diusir", false))
	infak_hari = int(data.get("infak_hari", 0))
	infak_jumlah = int(data.get("infak_jumlah", 0))
	jajan_hari = int(data.get("jajan_hari", 0))
	jajan_dibeli = {}
	var jd = data.get("jajan_dibeli", {})
	if typeof(jd) == TYPE_DICTIONARY:
		for k in jd:
			jajan_dibeli[String(k)] = int(jd[k])
	balas_budi_hari = data.get("balas_budi_hari", {})
	bagikan_hari = int(data.get("bagikan_hari", -99))
	kerja_berjalan = String(data.get("kerja_berjalan", ""))
	bonus_mancing_hari = int(data.get("bonus_mancing_hari", -1))
	matel_datang_hari = int(data.get("matel_datang_hari", -1))
	tangkapan_tertunda = data.get("tangkapan_tertunda", [])
	bonus_tautan_diambil = bool(data.get("bonus_tautan_diambil", false))
	energi = float(data.get("energi", 100.0))
	alasan_bangun = String(data.get("alasan_bangun", "ronda" if bangun_kesiangan else ""))
	hari_sembuh = int(data.get("hari_sembuh", -1))
	tabrakan_tertunda = bool(data.get("tabrakan_tertunda", false))
	perban_letak = Array(data.get("perban_letak", ["kaki_kiri"]))
	hari_tertabrak = int(data.get("hari_tertabrak", -99))
	utang_dokter = int(data.get("utang_dokter", 0))
	jam_bangun_tadi = int(data.get("jam_bangun_tadi", JAM_MULAI))
	iklan_upgrade = data.get("iklan_upgrade", {})
	pengali_harga_upgrade = data.get("pengali_harga_upgrade", {})
	wajib_etalase = bool(data.get("wajib_etalase", false))
	istirahat_hari = data.get("istirahat_hari", {})
	kerja_hari = data.get("kerja_hari", {})
	hasil_alam = {}
	var ha: Dictionary = data.get("hasil_alam", {})
	for id in ha:
		if int(ha[id]) > 0 and not info_hasil_alam(String(id)).is_empty():
			hasil_alam[String(id)] = int(ha[id])
	titipan = data.get("titipan", {})
	tas_grosir = {}
	var tg: Dictionary = data.get("tas_grosir", {})
	for id in tg:
		if int(tg[id]) > 0 and katalog.has(String(id)):
			tas_grosir[String(id)] = int(tg[id])
	mancing_hari = data.get("mancing_hari", {})
	kebun_petik_hari = int(data.get("kebun_petik_hari", -99))
	kebun = {}
	var kb: Dictionary = data.get("kebun", {})
	for id in kb:
		if typeof(kb[id]) == TYPE_ARRAY:
			kebun[String(id)] = (kb[id] as Array).map( func(x): return float(x))
	promo = data.get("promo", {})
	promo_hari_ke = int(data.get("promo_hari_ke", -1))
	_kosongkan_progres()
	for kunci in progres:
		progres[kunci] = int(data.get("progres", {}).get(kunci, 0))
	beruntun_sekarang = int(data.get("beruntun_sekarang", 0))
	hari_inti_beres = int(data.get("hari_inti_beres", 0))
	hari_level_mulai = int(data.get("hari_level_mulai", hari))
	var c: Dictionary = data.get("catatan_hari", {})
	omzet_hari = int(c.get("omzet", 0))
	laba_hari = int(c.get("laba", 0))
	barang_terjual_hari = int(c.get("terjual", 0))
	belanja_hari = int(c.get("belanja", 0))
	pelanggan_dilayani_hari = int(c.get("dilayani", 0))
	pelanggan_batal_hari = int(c.get("batal", 0))
	hadiah_hari = int(c.get("hadiah", 0))
	riwayat = data.get("riwayat", [])

	kiriman_stok = {}
	var ks: Dictionary = data.get("kiriman_stok", {})
	for id in ks:
		if stok.has(id):
			kiriman_stok[id] = int(ks[id])
	kurir_dalam_perjalanan = false
	detik_kiriman = durasi_kirim() if not kiriman_stok.is_empty() else 0.0
	kurir_pilihan = String(data.get("kurir_pilihan", ""))
	kurir_hari = int(data.get("kurir_hari", -1))
	instan_mulai = int(data.get("instan_mulai", 0))
	penjualan_hari = {}
	var pj: Dictionary = data.get("penjualan_hari", {})
	for id in pj:
		penjualan_hari[id] = [int(pj[id][0]), int(pj[id][1]), int(pj[id][2])]

	if data.has("bab"):
		bab = int(data["bab"])
		denda_bab = int(data.get("denda_bab", 0))
		kiriman_bab = int(data["kiriman_bab"])
		target_bab = int(data["target_bab"])
		batas_hari = int(data["batas_hari"])
		barang_terbuka = data["barang_terbuka"]
		cerita_tamat = data["cerita_tamat"]

		misi_status = String(data.get("misi_status", "" if cerita_tamat else "aktif"))
		misi_mulai_hari = int(data.get("misi_mulai_hari", 0))
		naik_level_tertunda = data.get("naik_level_tertunda", [])
		riwayat_layan = data.get("riwayat_layan", [])
		notif_dilihat = data.get("notif_dilihat", {})
		for k in notif_dilihat.keys():
			notif_dilihat[k] = _penanda_normal(notif_dilihat[k])
		agus_bantu_sampai = int(data.get("agus_bantu_sampai", 0))
		adzan_maghrib_hari = int(data.get("adzan_maghrib_hari", 0))
		zakat_dibayar = bool(data.get("zakat_dibayar", false))
		tarawih_hari = int(data.get("tarawih_hari", 0))
		thr_agus = int(data.get("thr_agus", 0))
		neo_makan_hari = int(data.get("neo_makan_hari", 0))
		promosi_mulai = int(data.get("promosi_mulai", 0))
		ajak_rating_sudah = bool(data.get("ajak_rating_sudah", false))
		tutorial_langkah = String(data.get("tutorial_langkah", ""))
		tutorial_awal = bool(data.get("tutorial_awal", false))
		tutorial_penutup = bool(data.get("tutorial_penutup", false))
		kabar_hari = data.get("kabar_hari", {})
		pengajian_hari = int(data.get("pengajian_hari", 0))
		jumatan_hari = int(data.get("jumatan_hari", 0))
		rumah_renovasi = bool(data.get("rumah_renovasi", false))
		motor_baru = bool(data.get("motor_baru", false))
		var mc = data.get("motor_cicil", {})
		motor_cicil = mc if typeof(mc) == TYPE_DICTIONARY else {}
		motor_disita = bool(data.get("motor_disita", false))
		ngojol = {"hari": -1, "selesai": []}
		if data.get("ngojol") is Dictionary:
			ngojol = {"hari": int(data["ngojol"].get("hari", -1)), "selesai": Array(data["ngojol"].get("selesai", [])).map( func(x): return int(x)), 
				"uang": int(data["ngojol"].get("uang", 0))}
		hape_mewah = bool(data.get("hape_mewah", false))

		kerja_gratis_hari = int(data.get("kerja_gratis_hari", -1))
		janji = data.get("janji", {})
		janji_lewat = data.get("janji_lewat", {})
		janji_dijadwal = data.get("janji_dijadwal", {})

		kerja_gratis_jml = int(data.get("kerja_gratis_jml", 1 if kerja_gratis_hari >= 0 else 0))
		tip_mg_hari = int(data.get("tip_mg_hari", -1))
		qris_mg = data.get("qris_mg", {"hari": -1, "n": 0})
		peta_ditunjukkan = bool(data.get("peta_ditunjukkan", hari > 1))
		dialog_tertunda = data.get("dialog_tertunda", [])

		if int(data.get("versi_cerita", 1)) < VERSI_CERITA:
			_migrasi_cerita_lama()
		if bab >= cerita["bab"].size():
			misi_status = ""
			bab = cerita["bab"].size() - 1

		var harus_terbuka: Array = cerita["terbuka_awal"].duplicate()
		for i in mini(bab, cerita["bab"].size()):
			harus_terbuka.append_array(cerita["bab"][i]["buka"])
		for i in mini(tingkat + 1, daftar_tingkat.size()):
			harus_terbuka.append_array(daftar_tingkat[i].get("buka", []))
		for id in harus_terbuka:
			if not barang_terbuka.has(id):
				barang_terbuka.append(id)
	else:
		cerita_tamat = true
		barang_terbuka = _semua_barang_cerita()
		dialog_tertunda = []
	_buka_barang_upgrade()
	_buka_barang_agen()
	_cek_barang_ramadan(false)
	data_berubah.emit()
	papan.segarkan.call_deferred(true)
	analitik.catat("lanjut_game", {"hari": hari, "uang": uang})


	if tabrakan_tertunda:
		tertabrak()
	_bereskan_mini_game_tertunda()
	return true





func cari_anak(n: Variant, kelas: String) -> Array:
	if n == null or not is_instance_valid(n) or not (n is Node) or (n as Node).is_queued_for_deletion():
		return []
	return (n as Node).find_children("*", kelas, true, false)








var model_gagal: = 0




var _cache_model: Array = []

func _ingat_model(file: String, r: PackedScene) -> void :
	for i in _cache_model.size():
		if _cache_model[i][0] == file:
			_cache_model.remove_at(i)
			break
	_cache_model.append([file, r])
	var batas: = 4 if kualitas == "rendah" else 8
	while _cache_model.size() > batas:
		_cache_model.pop_front()


func muat_model(file: String) -> Node3D:
	jejak_grafis("model " + file.get_file())
	for coba in 2:
		var r: Resource = ResourceLoader.load(file, "", ResourceLoader.CACHE_MODE_REUSE if coba == 0 else ResourceLoader.CACHE_MODE_REPLACE)
		if r is PackedScene:
			_ingat_model(file, r as PackedScene)
			var isi: Node = (r as PackedScene).instantiate()
			if isi is Node3D:
				if gpu_powervr():
					_sederhanakan_bahan(isi)
				return isi as Node3D
			if isi != null:
				isi.free()
	model_gagal += 1
	push_warning("Model gagal dimuat: " + file)
	var kosong: = Node3D.new()
	kosong.name = "ModelGagal"
	return kosong



func _notification(what: int) -> void :




	if what == NOTIFICATION_EXIT_TREE or what == NOTIFICATION_PREDELETE:
		_lepas_teks_tokoh()
	if sedang_main and (what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_APPLICATION_PAUSED):
		simpan()

	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_APPLICATION_PAUSED:
		_hapus_jejak_grafis()

	if what == NOTIFICATION_APPLICATION_RESUMED:
		cek_bayar_menunggu(true)


	if what == NOTIFICATION_WM_GO_BACK_REQUEST and is_inside_tree():
		var adegan: = get_tree().current_scene
		if adegan != null and adegan.has_method("tombol_kembali") and not get_viewport().gui_is_dragging():
			adegan.tombol_kembali()







var volume_musik: = 0.8
var volume_sekitar: = 0.8
const BUNYI_SEKITAR: = ["ayam_berkokok", "adzan", "petir", "petir_2", "petir_3"]

func _siapkan_bus() -> void :
	for nama in ["Musik", "Suara", "Sekitar"]:
		if AudioServer.get_bus_index(nama) < 0:
			AudioServer.add_bus()
			var i: = AudioServer.bus_count - 1
			AudioServer.set_bus_name(i, nama)
			AudioServer.set_bus_send(i, "Master")
	get_tree().node_added.connect(_pemutar_baru)


func _pemutar_baru(n: Node) -> void :
	if (n is AudioStreamPlayer or n is AudioStreamPlayer2D or n is AudioStreamPlayer3D) and n != _musik and String(n.bus) == "Master":
		n.bus = "Suara"


func _atur_bus(nama: String, nilai: float) -> void :
	var i: = AudioServer.get_bus_index(nama)
	if i < 0:
		return
	AudioServer.set_bus_volume_db(i, linear_to_db(maxf(nilai, 0.0001)))
	AudioServer.set_bus_mute(i, nilai <= 0.001)



func atur_volume(nilai: float) -> void :
	volume = clampf(nilai, 0.0, 1.0)
	_atur_bus("Suara", volume)


func atur_volume_musik(nilai: float) -> void :
	volume_musik = clampf(nilai, 0.0, 1.0)
	_atur_bus("Musik", volume_musik)



func atur_volume_sekitar(nilai: float) -> void :
	volume_sekitar = clampf(nilai, 0.0, 1.0)
	_atur_bus("Sekitar", volume_sekitar)


func atur_kecepatan(pilihan: String) -> void :
	pilihan_kecepatan = pilihan if KECEPATAN.has(pilihan) else "normal"
	kecepatan_waktu = KECEPATAN[pilihan_kecepatan]




const KUALITAS: = {"rendah": Viewport.MSAA_DISABLED, "sedang": Viewport.MSAA_2X, "tinggi": Viewport.MSAA_4X}
const URUTAN_KUALITAS: = ["rendah", "sedang", "tinggi"]
var kualitas: = "tinggi"
var kualitas_manual: = false
var hemat_baterai: = false

var panel_misi_kecil: = false
var panel_kerja_kecil: = false






const MSAA_MATI_DI_ANDROID: = true

func msaa_3d() -> Viewport.MSAA:
	if MSAA_MATI_DI_ANDROID and OS.get_name() == "Android":
		return Viewport.MSAA_DISABLED
	return KUALITAS.get(kualitas, Viewport.MSAA_2X)





const PAKAI_SKALA_LAYAR_3D: = false
const SKALA_LAYAR_3D: = 0.62
func skala_viewport_3d() -> float:
	var tinggi_layar: = float(DisplayServer.window_get_size().y) if DisplayServer.get_name() != "headless" else 1080.0


	var s: = 1.0 if PAKAI_SKALA_LAYAR_3D == false else clampf(tinggi_layar * SKALA_LAYAR_3D / 812.0, 0.45, 1.0)
	return s * (0.6 if kualitas == "rendah" else 1.0)


func atur_kualitas(pilihan: String, manual: = false) -> void :
	kualitas = pilihan if KUALITAS.has(pilihan) else "sedang"
	if manual:
		kualitas_manual = true
	_atur_fps()

	if is_inside_tree():
		for vp in get_tree().root.find_children("*", "SubViewport", true, false):

			(vp as SubViewport).msaa_3d = vp.msaa_sendiri() if vp.has_method("msaa_sendiri") else msaa_3d()




func turunkan_kualitas_otomatis() -> bool:
	var i: = URUTAN_KUALITAS.find(kualitas)
	if true or kualitas_manual or i <= 0:
		return false
	atur_kualitas(URUTAN_KUALITAS[i - 1])
	simpan_pengaturan()
	return true


func atur_hemat_baterai(nyala: bool) -> void :
	hemat_baterai = nyala
	_atur_fps()



func _atur_fps() -> void :
	Engine.max_fps = 30 if hemat_baterai or kualitas == "rendah" else 60








const RAM_RENDAH: = 3300000000
const RAM_SEDANG: = 4600000000

func renderer_ringan() -> bool:
	return RenderingServer.get_current_rendering_method() == "gl_compatibility"


func kualitas_bawaan() -> String:
	var ram: = int(OS.get_memory_info().get("physical", -1))
	if ram > 0 and ram < RAM_RENDAH:
		return "rendah"
	if ram > 0 and ram < RAM_SEDANG:
		return "sedang"
	return "tinggi"


func grafik_rendah() -> bool:
	return kualitas == "rendah"


func simpan_pengaturan() -> void :
	var cfg: = ConfigFile.new()
	cfg.set_value("suara", "volume", volume)
	cfg.set_value("suara", "volume_musik", volume_musik)
	cfg.set_value("suara", "volume_sekitar", volume_sekitar)
	cfg.set_value("grafik", "kualitas", kualitas)
	cfg.set_value("grafik", "manual", kualitas_manual)
	cfg.set_value("grafik", "hemat_baterai", hemat_baterai)
	cfg.set_value("tutorial", "selesai", tutorial_selesai)
	cfg.set_value("tutorial", "tip", tip_dilihat.keys())
	cfg.set_value("simpanan", "slot_terakhir", slot_terakhir)
	cfg.set_value("toko", "tanpa_iklan", tanpa_iklan)
	cfg.set_value("toko", "pendukung", pendukung)
	cfg.set_value("toko", "kode_pendukung", kode_pendukung)
	cfg.set_value("toko", "token_pendukung", _token_pendukung)
	cfg.set_value("toko", "kode_iklan", kode_iklan)
	cfg.set_value("toko", "token_iklan", _token_iklan)
	cfg.set_value("toko", "beli_tercatat", _beli_tercatat)
	cfg.set_value("toko", "bayar_menunggu", bayar_menunggu)
	cfg.set_value("toko", "iklan_pindah_tunggu", _iklan_pindah_tunggu)
	cfg.set_value("toko", "kode_diumumkan", kode_diumumkan)
	cfg.set_value("toko", "dukungan_iklan_dicek", dukungan_iklan_dicek)
	cfg.set_value("toko", "hp_pengembang", hp_pengembang)
	cfg.set_value("tester", "tester", tester)
	cfg.set_value("tester", "dicek_rilis", tester_dicek_rilis)
	cfg.set_value("tester", "diumumkan", tester_diumumkan)
	cfg.set_value("lemari", "baju", baju_dimiliki.keys())
	cfg.set_value("lemari", "dipakai", baju_dipakai)
	cfg.set_value("login", "hari_ke", login_hari_ke)
	cfg.set_value("login", "tanggal", login_tanggal)
	cfg.set_value("login", "siklus", login_siklus)
	cfg.set_value("login", "bebas_iklan_dari", bebas_iklan_dari)
	cfg.set_value("login", "bebas_iklan_sampai", bebas_iklan_sampai)
	cfg.set_value("login", "tanda", login_harian.tanda_catatan() if login_harian != null else "")
	cfg.set_value("toko", "promo_dipakai", promo_dipakai.keys())
	cfg.set_value("rilis", "reset_dicek", reset_rilis_dicek)
	cfg.set_value("rilis", "build_terakhir", load("res://scripts/cek_versi.gd").kode_sekarang())
	cfg.set_value("tampilan", "bahasa", bahasa)
	cfg.set_value("tampilan", "misi_kecil", panel_misi_kecil)
	cfg.set_value("tampilan", "kerja_kecil", panel_kerja_kecil)
	cfg.set_value("tampilan", "cara_layani", cara_layani)
	cfg.set_value("tampilan", "yang_baru_dilihat", yang_baru_dilihat)


	var jalur: = ProjectSettings.globalize_path(FILE_PENGATURAN)
	if cfg.save(jalur + ".tmp") != OK:
		return
	if FileAccess.file_exists(jalur):
		if FileAccess.file_exists(jalur + ".bak"):
			DirAccess.remove_absolute(jalur + ".bak")
		DirAccess.rename_absolute(jalur, jalur + ".bak")
	if DirAccess.rename_absolute(jalur + ".tmp", jalur) != OK and FileAccess.file_exists(jalur + ".bak"):
		DirAccess.copy_absolute(jalur + ".bak", jalur)


func muat_pengaturan() -> void :
	var cfg: = ConfigFile.new()
	if cfg.load(FILE_PENGATURAN) != OK and FileAccess.file_exists(FILE_PENGATURAN + ".bak"):
		cfg = ConfigFile.new()
		cfg.load(FILE_PENGATURAN + ".bak")
	atur_volume(cfg.get_value("suara", "volume", 0.8))
	atur_volume_musik(cfg.get_value("suara", "volume_musik", cfg.get_value("suara", "volume", 0.8)))

	atur_volume_sekitar(cfg.get_value("suara", "volume_sekitar", cfg.get_value("suara", "volume", 0.8)))

	atur_kecepatan("normal")
	kualitas_manual = bool(cfg.get_value("grafik", "manual", false))

	atur_kualitas(cfg.get_value("grafik", "kualitas", "tinggi") if kualitas_manual else kualitas_bawaan())
	atur_hemat_baterai(cfg.get_value("grafik", "hemat_baterai", false))
	tutorial_selesai = cfg.get_value("tutorial", "selesai", false)
	tip_dilihat.clear()
	for id in cfg.get_value("tutorial", "tip", []):
		tip_dilihat[String(id)] = true

	if bool(cfg.get_value("tutorial", "selesai", false)) and not cfg.has_section_key("tutorial", "tip"):
		for id in TIP_DASAR:
			tip_dilihat[id] = true
	if UJI_PEMAIN_BARU and OS.has_feature("editor"):
		tutorial_selesai = false
	slot_terakhir = int(cfg.get_value("simpanan", "slot_terakhir", 0))


	if slot_terakhir <= 0 or not ada_slot(slot_terakhir):
		slot_terakhir = _slot_terbaru()
	tanpa_iklan = bool(cfg.get_value("toko", "tanpa_iklan", false))
	pendukung = bool(cfg.get_value("toko", "pendukung", false))
	kode_pendukung = String(cfg.get_value("toko", "kode_pendukung", ""))
	_token_pendukung = String(cfg.get_value("toko", "token_pendukung", ""))
	kode_iklan = String(cfg.get_value("toko", "kode_iklan", ""))
	_token_iklan = String(cfg.get_value("toko", "token_iklan", ""))
	var bm = cfg.get_value("toko", "bayar_menunggu", {})
	bayar_menunggu = bm if typeof(bm) == TYPE_DICTIONARY else {}
	var bt = cfg.get_value("toko", "beli_tercatat", [])
	_beli_tercatat = bt if typeof(bt) == TYPE_ARRAY else []
	_iklan_pindah_tunggu = bool(cfg.get_value("toko", "iklan_pindah_tunggu", false))
	kode_diumumkan = bool(cfg.get_value("toko", "kode_diumumkan", false))
	hp_pengembang = bool(cfg.get_value("toko", "hp_pengembang", false))
	reset_rilis_dicek = bool(cfg.get_value("rilis", "reset_dicek", false))
	bahasa = String(cfg.get_value("tampilan", "bahasa", ""))
	panel_misi_kecil = bool(cfg.get_value("tampilan", "misi_kecil", false))
	panel_kerja_kecil = bool(cfg.get_value("tampilan", "kerja_kecil", false))
	cara_layani = "ketuk" if String(cfg.get_value("tampilan", "cara_layani", "seret")) == "ketuk" else "seret"
	yang_baru_dilihat = String(cfg.get_value("tampilan", "yang_baru_dilihat", ""))
	dukungan_iklan_dicek = bool(cfg.get_value("toko", "dukungan_iklan_dicek", false))
	tester = bool(cfg.get_value("tester", "tester", false))
	tester_dicek_rilis = bool(cfg.get_value("tester", "dicek_rilis", false))
	tester_diumumkan = bool(cfg.get_value("tester", "diumumkan", false))
	baju_dimiliki.clear()
	for b in cfg.get_value("lemari", "baju", []):
		baju_dimiliki[String(b)] = true
	baju_dipakai = String(cfg.get_value("lemari", "dipakai", ""))
	login_hari_ke = int(cfg.get_value("login", "hari_ke", 0))
	login_tanggal = String(cfg.get_value("login", "tanggal", ""))
	login_siklus = int(cfg.get_value("login", "siklus", 0))
	bebas_iklan_dari = int(cfg.get_value("login", "bebas_iklan_dari", 0))
	bebas_iklan_sampai = int(cfg.get_value("login", "bebas_iklan_sampai", 0))

	login_tanda_sah = true
	if login_harian != null and (login_hari_ke > 0 or bebas_iklan_sampai > 0) and String(cfg.get_value("login", "tanda", "")) != login_harian.tanda_catatan():
		login_tanda_sah = false
		login_hari_ke = 0
		login_tanggal = ""
		bebas_iklan_dari = 0
		bebas_iklan_sampai = 0
		push_warning("Catatan kalender hadiah tidak sah, diulang dari awal.")
	promo_dipakai.clear()
	for k in cfg.get_value("toko", "promo_dipakai", []):
		promo_dipakai[String(k)] = true
	if teks_tokoh != null:
		teks_tokoh.atur_bahasa(bahasa)
	_pindahkan_simpanan_lama()
	_cek_tester()
	_cek_reset_rilis()
	_siapkan_billing()
	_siapkan_iklan()




func terbuka(id: String) -> bool:
	return id in barang_terbuka


func data_bab() -> Dictionary:
	return cerita["bab"][mini(bab, cerita["bab"].size() - 1)]




func kontak_bab() -> String:
	return String(data_bab().get("kontak", "agus"))


func nama_penerima() -> String:
	return String(data_bab().get("nama_penerima", "Agus"))


func sisa_hari() -> int:
	return batas_hari - hari + 1


func kekurangan_kiriman() -> int:
	if misi_status != "aktif":
		return 0
	return maxi(target_bab - kiriman_bab, 0)




func teks_cara_kirim() -> String:
	return "Kirim %s untuk %s: buka HP, aplikasi Warga Bank, Kirim uang" % [format_rupiah(kekurangan_kiriman()), nama_penerima()]



func uang_cukup_kirim() -> bool:
	if wajib_etalase and not punya_upgrade("etalase"):
		return false
	return kekurangan_kiriman() > 0 and uang >= kekurangan_kiriman() and not cerita_tamat



var kirim_diingatkan_hari: = -1

func perlu_ingatkan_kirim() -> bool:
	if kirim_diingatkan_hari == hari or tutorial_langkah != "" or mode_latihan or not uang_cukup_kirim():
		return false
	kirim_diingatkan_hari = hari
	return true


func kabari_uang_cukup() -> void :
	if _notif != null:
		_notif.kabari(kontak_bab(), "Uang sudah cukup", "Klik untuk kirim %s ke %s" % [format_rupiah(kekurangan_kiriman()), nama_penerima()], true)



func level_bab(i: int) -> int:
	return int(cerita["bab"][i].get("level", i + 1))



func bab_pembuka(id: String) -> int:
	for i in cerita["bab"].size():
		if id in cerita["bab"][i]["buka"]:
			return i + 1
	return 0



func teks_tunggu_agus() -> String:
	var n: = misi_mulai_hari - hari
	var nama: = nama_penerima()
	return "%s menghubungi besok" % nama if n <= 1 else ("%s menghubungi lusa" % nama if n == 2 else "%s menghubungi %d hari lagi" % [nama, n])





func kirim_akan_berhasil(jumlah: int) -> bool:
	return not cerita_tamat and misi_status == "aktif" and uang >= kekurangan_kiriman() and jumlah >= kekurangan_kiriman() and kekurangan_kiriman() > 0


func kirim_uang(jumlah: int) -> String:
	if cerita_tamat:
		return "Cerita sudah selesai."
	var nama: = nama_penerima()
	if misi_status == "lunas":
		return "Kebutuhan ini sudah terpenuhi. Selesaikan tugas Level Warung lainnya."
	if misi_status != "aktif":
		return "%s sedang tidak minta kiriman." % nama

	if uang < kekurangan_kiriman():
		return "Uangnya belum cukup. %s butuh %s sekaligus, uang di laci baru %s." % [nama, format_rupiah(kekurangan_kiriman()), format_rupiah(uang)]
	if jumlah < kekurangan_kiriman():
		return "Kiriman untuk %s harus langsung %s, tidak bisa dicicil." % [nama, format_rupiah(kekurangan_kiriman())]

	jumlah = mini(jumlah, kekurangan_kiriman())
	uang -= jumlah
	kiriman_bab += jumlah
	catat_transaksi("Kirim uang untuk %s" % nama, - jumlah)
	if kiriman_bab >= target_bab:
		_selesaikan_bab()
	data_berubah.emit()
	simpan()
	return ""



func _selesaikan_bab() -> void :

	if bool(data_bab().get("kios", false)):
		kios_milik = true

		tambah_chat(nama_pemilik_kios(), "Pak Misran, sekarang kios itu sudah milik Bapak sendiri. Mau buka jam berapa, tutup jam berapa, termasuk hari Jumat, terserah Bapak. Jangan lupa istirahat, ya. Semoga makin berkah.", true, "teks", "juragan")

		if tunggakan_sewa > 0:
			_tarik_qris_untuk(tunggakan_sewa, "Ambil saldo QRIS untuk tunggakan sewa")
			var bayar_tunggakan: = clampi(uang, 0, tunggakan_sewa)
			uang -= bayar_tunggakan
			if bayar_tunggakan > 0:
				catat_transaksi("Bayar tunggakan sewa saat membeli kios", - bayar_tunggakan)
		tunggakan_sewa = 0
		minggu_tunggak = 0
		if sewa_cicil > 0:
			uang += sewa_cicil
			catat_transaksi("Cicilan sewa dikembalikan (kios sudah milik sendiri)", sewa_cicil)
			sewa_cicil = 0
	sewa_kunci = {}

	misi_status = "lunas"
	analitik.catat("bab_selesai", {"bab": bab + 1})
	dialog_tertunda.append("selesai:%d" % bab)
	_cek_tugas()



func _mulai_bab(i: int) -> void :
	bab = i
	kiriman_bab = 0
	denda_bab = 0
	misi_status = "aktif"
	var b: Dictionary = cerita["bab"][i]
	target_bab = int(b["target"])
	batas_hari = hari + int(b["durasi"]) - 1
	dialog_tertunda.append("awal:%d" % i)

	if String(b.get("jenis", "kirim")) == "hadiah":
		uang += target_bab
		catat_transaksi("Kiriman dari %s" % String(b.get("nama_penerima", "Agus")), target_bab)
		kiriman_bab = target_bab
		bunyi("koin")
		_selesaikan_bab()



const VERSI_CERITA: = 2

const PETA_BAB_LAMA: = [0, 1, 3, 4, 6]




func _migrasi_cerita_lama() -> void :
	var lama: = bab
	if bab >= 0 and bab < PETA_BAB_LAMA.size():
		bab = int(PETA_BAB_LAMA[bab])

	var baru: Array = []
	for kunci in dialog_tertunda:
		var bagian: = String(kunci).split(":")
		if bagian.size() == 2 and bagian[0] in ["awal", "selesai"] and int(bagian[1]) < PETA_BAB_LAMA.size():
			baru.append("%s:%d" % [bagian[0], int(PETA_BAB_LAMA[int(bagian[1])])])
		else:
			baru.append(kunci)
	dialog_tertunda = baru

	if cerita_tamat:
		cerita_tamat = false
		bab = int(PETA_BAB_LAMA[PETA_BAB_LAMA.size() - 1])
		misi_status = "lunas"
		if level() >= level_bab(bab + 1):
			_siapkan_misi_level()
	elif misi_status in ["", "lunas"] and level() >= level_bab(mini(bab + 1, cerita["bab"].size() - 1)) and bab + 1 < cerita["bab"].size():

		_siapkan_misi_level()
	print("Migrasi cerita: bab lama %d -> baru %d (status %s)" % [lama, bab, misi_status])



func _siapkan_misi_level() -> void :
	var calon: = bab if misi_status in ["menunggu", "aktif"] else bab + 1

	while calon < cerita["bab"].size() and misi_status not in ["menunggu", "aktif"] and level_bab(calon) < level():
		calon += 1
	if misi_status in ["menunggu", "aktif"] or calon >= cerita["bab"].size() or level_bab(calon) > level():
		if not misi_status in ["menunggu", "aktif"]:
			misi_status = ""
		return
	bab = calon
	kiriman_bab = 0
	target_bab = int(cerita["bab"][calon]["target"])
	misi_status = "menunggu"
	misi_mulai_hari = hari + JEDA_AGUS


const KIOS_TURUN_PER_BATAS: = 0.06
const KIOS_PENGALI_MIN: = 0.4


func _cek_batas_waktu() -> void :
	if cerita_tamat or misi_status != "aktif" or hari <= batas_hari:
		return


	if macet():

		if uang + saldo_digital >= kekurangan_kiriman():
			batas_hari = hari + int(cerita["tambahan_hari"]) - 1
			return
		var potong: = int(round(kekurangan_kiriman() * 0.25 / 5000.0)) * 5000
		if not bool(data_bab().get("kios", false)):
			potong = clampi(potong, 0, maxi(target_bab - int(int(data_bab()["target"]) * 0.5), 0))


		if bool(data_bab().get("kios", false)):
			var harga_kios: = int(data_bab()["target"])
			potong = mini(potong, int(harga_kios * KIOS_TURUN_PER_BATAS))
			potong = clampi(potong, 0, maxi(target_bab - int(harga_kios * KIOS_PENGALI_MIN), 0))
		if potong > 0:
			target_bab -= potong
			if kontak_bab() == "agus":
				tambah_chat("Agus", "Pak, Agus juga kerja paruh waktu di kafe dekat kampus. Kekurangannya Agus tutup sebagian, jadi tinggal %s ya. Bapak jangan terlalu dipikirkan." % format_rupiah(kekurangan_kiriman()), true)
			else:
				var alasan_ringan: = {
					"juragan": "Pak Misran, Bapak sudah lama jadi penyewa yang baik. Sisanya saya potong, jadi tinggal %s. Tidak perlu terburu-buru.", 
					"rt": "Pak Misran, warga lain ikut menambah patungan. Kekurangan dari Bapak tinggal %s saja.", 
					"klinik": "Pak Misran, klinik memberi keringanan biaya. Sisanya tinggal %s.", 
				}
				tambah_chat(nama_penerima(), String(alasan_ringan.get(kontak_bab(), "Pak Misran, kekurangannya kami ringankan, jadi tinggal %s ya. Tidak perlu terburu-buru.")) % format_rupiah(kekurangan_kiriman()), true, "teks", kontak_bab())
		batas_hari = hari + int(cerita["tambahan_hari"]) - 1
		return



	if denda_bab < MAKS_DENDA_PER_BAB and kontak_bab() == "agus":
		target_bab += int(round(target_bab * float(cerita["denda_persen"]) / 100.0 / 5000.0) * 5000)
		denda_bab += 1
	batas_hari = hari + int(cerita["tambahan_hari"]) - 1
	dialog_tertunda.append("terlambat")



func isi_dialog(kunci: String) -> Array:
	var baris: Array = []
	var bagian: = kunci.split(":")
	match bagian[0]:
		"awal": baris = cerita["bab"][int(bagian[1])]["dialog_awal"]
		"selesai": baris = cerita["bab"][int(bagian[1])]["dialog_selesai"]
		"terlambat": baris = cerita["dialog_terlambat"] if kontak_bab() == "agus" else cerita.get("dialog_terlambat_kontak", cerita["dialog_terlambat"])
		"tamat": baris = cerita["dialog_tamat"]
	var hasil: Array = []
	var nilai: = {"target": format_rupiah(target_bab), "batas": teks_tanggal(batas_hari), "kebutuhan": data_bab()["kebutuhan"]}

	var bab_dialog: Dictionary = cerita["bab"][int(bagian[1])] if bagian[0] in ["awal", "selesai"] else data_bab()
	var nama_kontak: = String(bab_dialog.get("nama_penerima", "Agus"))
	for b in baris:
		var siapa: = String(b[0])
		if siapa == "Kontak":
			siapa = "Kontak|%s|%s" % [nama_kontak, String(bab_dialog.get("kontak", "agus"))]
		hasil.append([siapa, String(b[1]).format(nilai)])

	var minta_baru: bool = bagian[0] == "awal" and int(bagian[1]) > 0 and String(bab_dialog.get("jenis", "kirim")) != "hadiah"
	if minta_baru or bagian[0] == "terlambat":
		hasil.append(["", "Ini misi utama, dahulukan. Uangnya dikirim lewat HP: buka aplikasi Warga Bank (m-banking), lalu tekan Kirim uang untuk %s." % nama_kontak])
	return hasil







func simpan_dialog_ke_chat(kunci: String, baris_dialog: Array) -> void :
	if kunci == "tamat":
		return
	var kontak_chat: = kontak_dialog(kunci)
	var tujuan: = kontak_chat
	for b in baris_dialog:
		if b[0] == "Agus":
			tujuan = "agus"
			tambah_chat(b[0], b[1], false, "teks", tujuan)
		elif b[0] == "Bapak":
			tambah_chat(b[0], b[1], false, "teks", tujuan)
		elif String(b[0]).begins_with("Kontak|"):
			tujuan = kontak_chat
			tambah_chat(String(b[0]).split("|")[1], b[1], false, "teks", tujuan)



func kontak_dialog(kunci: String) -> String:
	var bagian: = kunci.split(":")
	if bagian[0] in ["awal", "selesai"]:
		return String(cerita["bab"][int(bagian[1])].get("kontak", "agus"))
	if bagian[0] == "terlambat":
		return kontak_bab()
	return "agus"



func rapikan_nama_warung(teks: String) -> String:
	var hasil: = ""
	for c in teks.strip_edges():
		if c == " " or c.is_valid_identifier() or c.is_valid_int():
			hasil += c
	while hasil.contains("  "):
		hasil = hasil.replace("  ", " ")
	return hasil.left(MAKS_NAMA_WARUNG).strip_edges()


func aturan() -> Dictionary:
	return ATURAN_MODE.get(mode, ATURAN_MODE["casual"])





func pesanan_acak(dilarang: Array = [], suka: Dictionary = {}) -> Array:


	if tutorial_langkah in ["layani", "marah", "habis", "asli_layani"]:
		var ada: = barang_fisik().filter( func(id): return terbuka(id) and int(stok.get(id, 0)) > 0 and not id in dilarang)
		if tutorial_langkah == "habis":
			var kosong: = barang_belanja().filter( func(id): return terbuka(id) and int(stok.get(id, 0)) == 0 and jumlah_kiriman(id) == 0 and not BARANG_TITIPAN.has(id) and not id in dilarang)
			if not kosong.is_empty():
				return [[kosong[randi() % kosong.size()], 1]]
		if not ada.is_empty():
			return [[ada[randi() % ada.size()], 1]]
	var banyak_jenis: = 1
	var bantuan: = tingkat_bantuan()
	var panjang: = randf() < peluang_pesanan_panjang()
	if panjang:

		var fisik: = barang_fisik().filter( func(id): return bisa_diminta(id) and not id in dilarang)
		var r: = randf()
		banyak_jenis = mini(4 if r < 0.35 else (5 if r < 0.65 else (6 if r < 0.85 else 7)), fisik.size())
		dilarang = dilarang + urutan_barang.filter( func(id): return not id in fisik)
	elif randf() < (aturan()["peluang_banyak"] + efek_reputasi()["banyak"] + efek_upgrade("banyak") + float(efek_kejadian().get("banyak", 0.0))) * (1.0 - 0.5 * bantuan):
		banyak_jenis = 2 if randf() < 0.7 + 0.3 * bantuan else 3
	var hasil: Array = []
	var dipakai: = {}
	for i in banyak_jenis * 6:
		if hasil.size() >= banyak_jenis:
			break
		var id: = barang_acak(dilarang, suka)
		if dipakai.has(id):
			continue
		dipakai[id] = true
		var jumlah: = 1
		if katalog[id]["jenis"] == "fisik":
			var r: = randf()
			if panjang:
				jumlah = 1 if r < 0.85 else 2
			elif borong_takjil(id):
				jumlah = 2 + randi() % 2
			else:
				jumlah = 1 if r < 0.65 else (2 if r < 0.92 else 3)
		hasil.append([id, jumlah])
	return hasil





const PESANAN_PANJANG_JENIS: = Vector2i(4, 7)
const PESANAN_PANJANG_MULAI: = 2

func peluang_pesanan_panjang() -> float:
	if level() < PESANAN_PANJANG_MULAI or tingkat_bantuan() > 0.3:
		return 0.0
	return minf(0.04 + 0.015 * (level() - PESANAN_PANJANG_MULAI), 0.1)



func kalimat_pesanan(pesanan: Array) -> String:
	if pesanan.size() == 1 and pesanan[0][1] == 1:
		return String(katalog[pesanan[0][0]]["permintaan"]) + "."

	if pesanan.size() >= PESANAN_PANJANG_JENIS.x:
		return "Sesuai catatan ini ya, Pak. Ada %d macam." % pesanan.size()
	var bagian: Array = []
	for p in pesanan:

		var b: Dictionary = katalog[p[0]]
		var nama: = String(b["sebutan"]) if b.has("sebutan") else String(b["nama"]).to_lower()
		bagian.append("%s %d" % [nama, int(p[1])])
	var teks: = ", ".join(bagian)
	return teks.left(1).to_upper() + teks.substr(1) + "."



func _pembeli_dari_riwayat(data: Dictionary) -> int:
	var n: = 0
	var hari_terakhir: = -1
	for r in data.get("riwayat", []):
		n += int(r.get("dilayani", 0))
		hari_terakhir = int(r.get("hari", -1))
	if hari_terakhir != int(data.get("hari", -1)):
		n += int(data.get("catatan_hari", {}).get("dilayani", 0))
	return n


func catat_riwayat_hari() -> void :
	var barang: = 0
	for id in penjualan_hari:
		barang += int(penjualan_hari[id][0])
	var catatan: = {"hari": hari, "omzet": omzet_hari, "laba": laba_hari, "bersih": profit_bersih_hari(), "belanja": belanja_hari, "barang": barang, 
		"dilayani": pelanggan_dilayani_hari, "batal": pelanggan_batal_hari}
	if not riwayat.is_empty() and int(riwayat[-1]["hari"]) == hari:
		riwayat[-1] = catatan
	else:
		riwayat.append(catatan)



func terima_kiriman() -> void :
	for id in kiriman_stok:
		stok[id] += kiriman_stok[id]
	kiriman_stok = {}
	detik_kiriman = 0.0
	kurir_dalam_perjalanan = false
	data_berubah.emit()


func jumlah_kiriman(id: String) -> int:
	return int(kiriman_stok.get(id, 0))




func sisa_muat_stok(id: String) -> int:
	return maxi(MAKS_STOK_BARANG - int(stok.get(id, 0)) - jumlah_kiriman(id) - int(tas_grosir.get(id, 0)), 0)


func alasan_stok_penuh(id: String) -> String:
	var nama: = String(data_barang(id)["nama"])
	var sisa: = sisa_muat_stok(id)
	if sisa <= 0:
		return "Stok %s sudah penuh. Paling banyak %d per barang." % [nama, MAKS_STOK_BARANG]
	return "Stok %s hanya muat %d lagi. Paling banyak %d per barang." % [nama, sisa, MAKS_STOK_BARANG]











const ULASAN_DIHITUNG: = 80
const ULASAN_BAYANGAN: = 10.0
const NILAI_BAYANGAN: = 3.0
const RATING_KOSONG: = 0.0

const BATAS_BINTANG: = [0.0, 25.0, 50.0, 75.0, 90.0]


func rating() -> float:
	var akhir: = ulasan.slice(maxi(ulasan.size() - ULASAN_DIHITUNG, 0))
	if akhir.is_empty():
		return RATING_KOSONG
	var total: = 0.0
	for u in akhir:
		total += float(u["bintang"])
	var bayangan: = ULASAN_BAYANGAN * maxf(0.0, 1.0 - float(ulasan.size()) / ULASAN_DIHITUNG)
	return (total + bayangan * NILAI_BAYANGAN) / (akhir.size() + bayangan)




func rating_teks() -> String:
	return String.num(floorf(rating() * 10.0 + 0.0001) / 10.0, 1).replace(".", ",")


func bintang() -> int:

	if ulasan.is_empty():
		return 0
	return _bintang_dari(reputasi)


func _bintang_dari(nilai: float) -> int:
	var b: = 1
	for i in BATAS_BINTANG.size():
		if nilai >= BATAS_BINTANG[i] - 0.001:
			b = i + 1
	return b



func _hitung_reputasi() -> void :
	var lama: = reputasi
	reputasi = clampf((rating() - 1.0) * 25.0, 0.0, 100.0)
	if absf(reputasi - lama) > 0.001:
		var bintang_lama: = _bintang_dari(lama)
		reputasi_berubah.emit(reputasi - lama)

		if bintang() > bintang_lama:
			_cek_tugas()
		data_berubah.emit()




func ulasan_warga(nilai_bintang: int, teks: String, nama: = "", jumlah: = 1) -> void :
	for i in jumlah:
		_tambah_ulasan(nilai_bintang, teks if i == 0 else _kalimat_warga(nilai_bintang >= 4), nama if i == 0 else "")
	_hitung_reputasi()


const ULASAN_WARGA_BAIK: = ["Pak Misran orangnya baik, suka bantu warga.", "Warungnya berkah, bapaknya peduli sama tetangga.", 
	"Belanja di sini sekalian silaturahmi. Bapaknya baik pisan.", "Pak Misran selalu ada kalau warga butuh bantuan.", 
	"Bapaknya ramah, kalau ada warga susah pasti dibantu.", "Warung tetangga yang paling bisa diandalkan.", 
	"Salut sama Pak Misran, peduli banget sama kampung.", "Pelayanannya dari hati. Semoga warungnya makin laris.", 
	"Saya jadi langganan gara-gara kebaikan Pak Misran.", "Orangnya amanah, belanja di sini tenang."]
const ULASAN_WARGA_BURUK: = ["Bapaknya kurang peduli sama warga sekitar.", "Kecewa sama sikap Pak Misran kemarin.", 
	"Dengar-dengar warungnya lagi ada masalah. Jadi ragu belanja di sini."]




func geser_reputasi(poin: float) -> void :
	if absf(poin) < 0.01:
		return
	var jumlah: = maxi(1, roundi(absf(poin)))
	ulasan_warga(5 if poin > 0.0 else 1, _kalimat_warga(poin > 0.0), "", jumlah)



func naikkan_bintang(n: = 1) -> void :
	var tujuan: = mini(bintang() + n, BATAS_BINTANG.size())
	for i in ULASAN_DIHITUNG:
		if bintang() >= tujuan:
			break
		ulasan_warga(5, _kalimat_warga(true))







func data_event() -> Dictionary:
	if _data_event.is_empty():
		var d: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/event.json"))
		_data_event = d["event"]
	if _susulan_hari != hari:
		_susulan_hari = hari
		_terapkan_susulan()
	return _data_event




var _susulan_hari: = -1

func _terapkan_susulan() -> void :
	for id in _data_event:
		var ev: Dictionary = _data_event[id]
		if not ev.has("susulan"):
			continue
		if not ev.has("_asli"):
			ev["_asli"] = {"tahap": ev["tahap"], "hasil": ev["hasil"], "obrolan": ev.get("obrolan", {})}
		var sumber: Dictionary = ev["susulan"] if hari > int(ev["hari_maks"]) else ev["_asli"]
		for k in ["tahap", "hasil", "obrolan"]:
			if sumber.has(k):
				ev[k] = sumber[k]



func event_kedaluwarsa(ev: Dictionary, h: int) -> bool:
	return ev.has("hari_maks") and h > int(ev["hari_maks"]) and not ev.has("susulan")



func _kabari_susulan() -> void :
	for id in data_event():
		var ev: Dictionary = data_event()[id]
		if not ev.has("susulan") or hari <= int(ev["hari_maks"]) or hasil_event(id) != "" or not cerita_terbuka(id):
			continue
		var cw: Dictionary = cerita_warga.get(id, {"tahap": tahap_event(id), "hasil": ""}).duplicate(true)
		if bool(cw.get("kabar_susulan", false)):
			continue
		cw["kabar_susulan"] = true
		cerita_warga[id] = cw
		var kabar: Array = ev["susulan"].get("kabar", [])
		if kabar.size() >= 3:
			tambah_chat(String(kabar[0]), String(kabar[1]), true, "teks", String(kabar[2]))



const OPSI_TUNDA_UANG: = {"teks": "Nanti dulu, uang belum cukup", "aksi": "tunda", 
	"dialog": [{"siapa": "bapak", "teks": "Maaf, uang saya belum cukup. Nanti saya kembali lagi, ya."}]}

func opsi_cerita_lengkap(opsi: Array) -> Array:
	var berbayar: = opsi.filter( func(o): return String(o.get("aksi", "")) in ["tolong", "lanjut"] and int(o.get("biaya", 0)) > 0)
	var bisa_maju: = opsi.any( func(o): return String(o.get("aksi", "")) in ["tolong", "lanjut"] and int(o.get("biaya", 0)) <= uang)
	var ada_tunda: = opsi.any( func(o): return String(o.get("aksi", "")) == "tunda")
	if berbayar.is_empty() or bisa_maju or ada_tunda:
		return opsi
	return opsi + [OPSI_TUNDA_UANG]


func tahap_event(id: String) -> int:
	return int(cerita_warga.get(id, {}).get("tahap", 0))


func hasil_event(id: String) -> String:
	return String(cerita_warga.get(id, {}).get("hasil", ""))


func majukan_event(id: String) -> void :
	cerita_warga[id] = {"tahap": tahap_event(id) + 1, "hasil": ""}
	simpan()




func npc_tahap(t: Dictionary) -> Array:
	if t.has("temui"):
		return (t["temui"] as Array).map( func(s): return String(s["npc"]))
	return [String(t["npc"])] if t.has("npc") else []


func temui_sudah(id: String) -> Array:
	return cerita_warga.get(id, {}).get("sudah", [])



func temui_sisa(id: String) -> Array:
	var semua: Array = data_event()[id]["tahap"]
	var t: Dictionary = semua[mini(tahap_event(id), semua.size() - 1)]
	var sudah: = temui_sudah(id)
	return (t.get("temui", []) as Array).filter( func(s): return not String(s["npc"]) in sudah)


func temui_tandai(id: String, npc: String) -> void :
	var cw: Dictionary = cerita_warga.get(id, {"tahap": tahap_event(id), "hasil": ""}).duplicate(true)
	var sudah: Array = cw.get("sudah", [])
	if not npc in sudah:
		sudah.append(npc)
	cw["sudah"] = sudah
	cerita_warga[id] = cw
	simpan()




func _jam_titik(jam: float) -> String:
	return "%02d.%02d" % [int(jam), roundi((jam - int(jam)) * 60.0)]


func selesaikan_event(id: String, hasil: String) -> Dictionary:
	cerita_warga[id] = {"tahap": tahap_event(id), "hasil": hasil}
	var h: Dictionary = data_event()[id].get("hasil", {}).get(hasil, {})
	if h.has("bintang"):
		naikkan_bintang(int(h["bintang"]))
	if h.has("reputasi"):
		geser_reputasi(float(h["reputasi"]))
	_buka_barang(h.get("buka", []))


	var terlibat: = {}
	for t in data_event()[id]["tahap"]:
		for npc in npc_tahap(t):
			if data_warga_tipe(npc) and data_event()[id].get("akrab", true):
				terlibat[npc] = true

	if h.has("agus_bantu"):
		agus_bantu_sampai = hari + int(h["agus_bantu"]) + (2 if thr_agus > 0 else 0)

	if h.has("uang"):
		uang += int(h["uang"])
		catat_transaksi("Cerita warga: %s" % String(data_event()[id]["judul"]), int(h["uang"]))

	if h.has("hutang"):
		var u: Dictionary = h["hutang"]
		var tipe_u: = String(u["tipe"])
		hutang.append({"tipe": tipe_u, "nama": String(daftar_warga().get(tipe_u, _nama_tokoh(tipe_u))), "jumlah": int(u["jumlah"]), "hari": hari, 
			"tempo": hari + int(u.get("tempo", 3)), "tak_bayar": false, "status": "belum", "hari_selesai": -1, "menit_bayar": -1})

	for c in h.get("chat", []):
		tambah_chat(String(c[0]), String(c[1]), true, "teks", String(c[2]) if c.size() > 2 else "rt")
	for tipe in terlibat:
		tambah_akrab(tipe, AKRAB_TOLONG if hasil == "tolong" else AKRAB_TOLAK)

	if hasil == "tolak":
		var lewat_agen: = _buka_barang_agen()
		if not lewat_agen.is_empty():
			var nama: Array = []
			for b in lewat_agen:
				nama.append(String(katalog[b]["nama"]).to_lower())
			tambah_chat("Sales Grosir", "Pak Misran, sekarang %s sudah bisa dipesan lewat agen di Belanja Online. Harganya memang sedikit lebih mahal ya, Pak, karena lewat agen." % " dan ".join(nama), true, "teks", "sales")
	bunyi("hadiah" if hasil == "tolong" else "klik")

	for k in KERJA_SAMPINGAN:
		if String(KERJA_SAMPINGAN[k].get("syarat_event", "")) == id:
			var kerja: Dictionary = KERJA_SAMPINGAN[k]
			var sapa: = "Pak Misran, hatur nuhun pisan soal tadi. " if hasil == "tolong" else "Pak Misran, "
			tambah_chat(String(kerja["nama"]), sapa + "Kalau mau tambah penghasilan, sekarang Bapak bisa %s di %s, pagi jam %s-%s. Ada upahnya. Nanti saya kabari di grup kalau ada kerjaan." % [
				String(kerja["tombol"]).to_lower(), String(kerja["area"]), _jam_titik(float(kerja["jam"][0])), _jam_titik(float(kerja["jam"][1]))], true, "teks", "rt")
	data_berubah.emit()
	simpan()
	return h






func efek_cerita(kunci: String) -> float:
	var jumlah: = kunci == "ramai"
	var k: = 0.0 if jumlah else 1.0
	for ev in cerita_warga:
		var hasil: = hasil_event(ev)
		if hasil == "" or not data_event().has(ev):
			continue
		var h: Dictionary = data_event()[ev].get("hasil", {}).get(hasil, {})
		if h.has(kunci):
			k = k + float(h[kunci]) if jumlah else k * float(h[kunci])
	return k


func pengali_ramai_cerita() -> float:
	return 1.0 / (1.0 + maxf(efek_cerita("ramai"), -0.5))


func _nama_tokoh(tipe: String) -> String:
	var d: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/pelanggan.json"))
	return String(d.get("tokoh", {}).get(tipe, {}).get("nama", "Warga"))



func event_pembuka(id_barang: String) -> String:


	var cadangan: = ""
	for ev in data_event():
		if id_barang in data_event()[ev].get("hasil", {}).get("tolong", {}).get("buka", []):
			if cerita_tampil_di_daftar(ev):
				return ev
			if cadangan == "":
				cadangan = ev
	return cadangan




func pengali_tipe(tipe: String) -> float:
	var k: = 1.0
	for ev in cerita_warga:
		var hasil: = hasil_event(ev)
		if hasil != "" and data_event().has(ev):
			k *= float(data_event()[ev].get("hasil", {}).get(hasil, {}).get("pelanggan", {}).get(tipe, 1.0))
	return k * pengali_akrab(tipe) * pengali_hutang_ditolak(tipe)






const AKRAB_SAPA: = 3.0
const AKRAB_KERJA: = 8.0
const AKRAB_TOLONG: = 20.0
const AKRAB_TOLAK: = -8.0
const AKRAB_LAYANI: = 1.0
const AKRAB_KESAL: = -2.0
const AKRAB_BONUS_MAKS: = 0.6


const TINGKAT_AKRAB: = [[0.0, "Baru kenal"], [15.0, "Kenal"], [35.0, "Tetangga akrab"], [60.0, "Langganan setia"], [85.0, "Sudah seperti keluarga"]]
const TINGKAT_LANGGANAN: = 3
const TINGKAT_KELUARGA: = 4
var keakraban: = {}
var sapa_hari: = {}


var _nama_warga: = {}







const PROMOSI_RAMAI: = 0.2
const LAMA_PROMOSI: = 2
const JEDA_PROMOSI: = LAMA_PROMOSI
var promosi_mulai: = 0

func promosi_aktif() -> bool:
	return promosi_mulai > 0 and hari >= promosi_mulai and hari < promosi_mulai + LAMA_PROMOSI


func sisa_hari_promosi() -> int:
	return promosi_mulai + LAMA_PROMOSI - hari if promosi_aktif() else 0


func alasan_tidak_bisa_promosi() -> String:
	if promosi_aktif():
		return "Promosi sedang berjalan (%s)." % ("hari terakhir" if sisa_hari_promosi() <= 1 else "%d hari lagi" % sisa_hari_promosi())
	if promosi_mulai > 0 and hari < promosi_mulai + JEDA_PROMOSI:
		return "Promosi berikutnya bisa mulai %s." % teks_tanggal(promosi_mulai + JEDA_PROMOSI)
	return ""


func mulai_promosi() -> void :
	promosi_mulai = hari
	tambah_chat("Pak RT", "Bapak-Ibu, warung %s lagi promo 2 hari ini! Mampir, ya." % (nama_warung if nama_warung != "" else "Pak Misran"), true, "teks", "rt")
	data_berubah.emit()
	simpan()



func pengali_ramai_promosi() -> float:
	return 1.0 / (1.0 + PROMOSI_RAMAI) if promosi_aktif() else 1.0





const TIPE_NEO: = "kucing"
const AKRAB_NEO_MAKAN: = 12.0
var neo_makan_hari: = 0


var neo_dikabari: = false
const KABAR_TEMPAT_NEO: = "Bapak-Ibu, makasih sudah bantu cari Neo. Sekarang Neo suka main di sekitar Rumah Warga dari pagi sampai malam. Kalau hujan dia di rumah saja. Kalau ketemu, boleh dielus, ya."


func _kabari_tempat_neo() -> void :
	if neo_dikabari or not neo_bisa_disapa():
		return
	neo_dikabari = true
	tambah_chat("Mba Giska", KABAR_TEMPAT_NEO, true, "teks", "rt")

func neo_bisa_disapa() -> bool:
	return hasil_event("kucing_bu_ida") == "tolong"


func alasan_tidak_bisa_kasih_makan_neo() -> String:
	if neo_makan_hari == hari:
		return "Neo sudah makan hari ini. Besok lagi, ya."
	if not terbuka("makanan_kucing"):
		return "Warung belum menjual makanan kucing."
	if int(stok.get("makanan_kucing", 0)) <= 0:
		return "Stok makanan kucing di warung habis. Belanja dulu lewat HP."
	return ""


func kasih_makan_neo() -> String:
	var alasan: = alasan_tidak_bisa_kasih_makan_neo()
	if alasan != "":
		return alasan
	stok["makanan_kucing"] = int(stok["makanan_kucing"]) - 1
	neo_makan_hari = hari
	var lama: = tingkat_akrab(TIPE_NEO)
	var poin_lama: = akrab(TIPE_NEO)
	keakraban[TIPE_NEO] = clampf(akrab(TIPE_NEO) + AKRAB_NEO_MAKAN, 0.0, 100.0)
	if akrab(TIPE_NEO) > poin_lama:
		akrab_naik.emit(TIPE_NEO, tingkat_akrab(TIPE_NEO) > lama)
	data_berubah.emit()
	return ""


func daftar_warga() -> Dictionary:
	if _nama_warga.is_empty():
		var d: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/warga.json"))
		for tipe in d["warga"]:
			_nama_warga[tipe] = String(d["warga"][tipe]["nama"])
	return _nama_warga


func data_warga_tipe(tipe: String) -> bool:
	return daftar_warga().has(tipe)


func akrab(tipe: String) -> float:
	return float(keakraban.get(tipe, 0.0))






signal akrab_naik(tipe: String, naik_tingkat: bool)
var akrab_naik_hari: = {}

func tambah_akrab(tipe: String, poin: float) -> bool:
	if tipe == "" or VarianBaju.tanpa_akrab(tipe):
		return false
	if poin > 0.0 and poin < AKRAB_TOLONG:
		if int(akrab_naik_hari.get(tipe, 0)) == hari:
			return false
		akrab_naik_hari[tipe] = hari
	var lama: = tingkat_akrab(tipe)
	var poin_lama: = akrab(tipe)
	keakraban[tipe] = clampf(akrab(tipe) + poin, 0.0, 100.0)
	var naik_tingkat: = tingkat_akrab(tipe) > lama
	if akrab(tipe) > poin_lama:
		akrab_naik.emit(tipe, naik_tingkat)
	return naik_tingkat


func tingkat_akrab(tipe: String) -> int:
	var t: = 0
	for i in TINGKAT_AKRAB.size():
		if akrab(tipe) >= float(TINGKAT_AKRAB[i][0]):
			t = i
	return t


func nama_tingkat_akrab(tipe: String) -> String:
	return String(TINGKAT_AKRAB[tingkat_akrab(tipe)][1])


func pengali_akrab(tipe: String) -> float:
	return 1.0 + AKRAB_BONUS_MAKS * akrab(tipe) / 100.0



func sapa_warga(tipe: String, nama: String) -> String:
	if VarianBaju.tanpa_akrab(tipe):
		return ""
	if int(sapa_hari.get(tipe, 0)) == hari or int(akrab_naik_hari.get(tipe, 0)) == hari:

		return "Keakraban dengan %s sudah naik hari ini. Sapa lagi besok, ya." % nama
	sapa_hari[tipe] = hari
	var naik: = tambah_akrab(tipe, AKRAB_SAPA)
	return teks_naik_akrab(tipe, nama) if naik else "Keakraban dengan %s naik." % nama



func teks_naik_akrab(tipe: String, nama: String) -> String:
	var t: = tingkat_akrab(tipe)
	var manfaat: = "Ia akan lebih sering mampir ke warung."
	if t == TINGKAT_LANGGANAN:
		manfaat = "Sekarang ia langganan setia: kadang memberi tip dan ulasan bagus."
	elif t == TINGKAT_KELUARGA:
		manfaat = "Sesekali ia akan datang ke warung membawakan makanan untuk Pak Misran."
	return "%s sekarang \"%s\"! %s" % [nama, nama_tingkat_akrab(tipe), manfaat]




const PELUANG_TIP_LANGGANAN: = 0.2
const PELUANG_ULASAN_LANGGANAN: = 0.25
const ULASAN_LANGGANAN: = ["Langganan dari dulu di sini. Pak Misran sudah hafal pesanan saya.", 
	"Belanja di warung tetangga sendiri, enak, akrab, harganya jujur.", "Pak Misran ramah, tiap lewat pasti saya mampir.", 
	"Sudah kayak warung keluarga sendiri. Laris terus, Pak!", "Pelayanannya dari hati, makanya saya langganan."]
var ulasan_langganan_hari: = {}




const KIRIMAN_WARGA: = {
	"nenek": ["Nak Misran, ini Nenek bawakan rengginang sama teh hangat. Jangan lupa makan, ya.", "rengginang & teh hangat", 20], 
	"ibu_rumah_tangga": ["Pak, tadi masak lebih, ini nasi uduk buat Bapak. Masih hangat.", "nasi uduk", 25], 
	"petani": ["Pak Misran, ini ubi rebus dari kebun Abah. Lumayan buat ganjal perut.", "ubi rebus", 20], 
	"pak_rt": ["Pak, ini nasi kotak sisa rapat RT. Daripada mubazir, buat Bapak saja.", "nasi kotak", 25], 
	"giska": ["Pak, saya bikin brownies kebanyakan. Cobain ya, Pak!", "brownies", 15], 
	"tukang": ["Pak, ini gorengan dari bedeng proyek. Masih anget, Pak.", "gorengan", 15], 
	"ojek": ["Pak, tadi orderan makanannya batal, buat Bapak aja. Rezeki!", "nasi goreng", 20], 
	"kantoran": ["Pak, ada kue dari acara kantor. Saya bawakan buat Bapak.", "kue", 15], 
	"santri_putih": ["Assalamualaikum, Pak. Ada titipan nasi berkat dari pesantren.", "nasi berkat", 25], 
	"santri_hitam": ["Pak, ini kurma titipan Kiai. Katanya buat Pak Misran.", "kurma", 15], 
	"pelajar": ["Pak, Ibu titip pisang goreng buat Bapak. Masih anget!", "pisang goreng", 15], 
	"siswi": ["Pak Misran, ini kue bolu buatan Ibu saya. Katanya buat Bapak.", "kue bolu", 15], 
	"anak": ["Pak Misran! Nenek nyuruh Ucup kasih ini. Jagung rebus!", "jagung rebus", 15], 
}
const PELUANG_KIRIMAN_HARIAN: = 1.0 / 7.0
const JEDA_KIRIMAN_WARGA: = 5
var kiriman_warga: = {}
var jadwal_kiriman: = {}



func _jadwalkan_kiriman_warga() -> void :
	jadwal_kiriman = {}

	if hari_libur() or ramadan():
		return
	var calon: Array = daftar_warga().keys().filter( func(t): return KIRIMAN_WARGA.has(t) and tingkat_akrab(t) >= TINGKAT_KELUARGA\
	and hari - int(kiriman_warga.get(t, -99)) >= JEDA_KIRIMAN_WARGA)
	calon.shuffle()
	for t in calon:
		if randf() < PELUANG_KIRIMAN_HARIAN:
			jadwal_kiriman = {"hari": hari, "tipe": t, "menit": randi_range(10 * 60, 15 * 60 + 30), "selesai": false}
			return



func kiriman_warga_sekarang() -> String:
	if jadwal_kiriman.is_empty() or int(jadwal_kiriman.get("hari", -1)) != hari or bool(jadwal_kiriman.get("selesai", false)):
		return ""
	if status_hari != "buka" or menit < float(jadwal_kiriman["menit"]):
		return ""
	return String(jadwal_kiriman["tipe"])



func terima_kiriman_warga(tipe: String) -> int:
	jadwal_kiriman["selesai"] = true
	kiriman_warga[tipe] = hari
	var tambah: = int(KIRIMAN_WARGA.get(tipe, ["", "", 15])[2])
	energi = minf(energi + tambah, 100.0)
	if not lelah():
		lelah_diingatkan = false
	data_berubah.emit()
	return tambah








const PELUANG_NGUTANG: = 0.1
const PELUANG_NGUTANG_SIANG: = 0.35
const HARI_MIN_NGUTANG: = 2
const MAKS_MINTA_UTANG_HARI: = 2
var _minta_utang_hari: = -1
var _minta_utang_jumlah: = 0
const PELUANG_TIDAK_BAYAR: = 0.1
const TIPE_BOLEH_NGUTANG: = ["kantoran", "ojek", "ibu_rumah_tangga", "nenek", "tukang", "petani", "giska", "pak_rt"]
const MAKS_HUTANG_AKTIF: = 4
const MIN_UTANG_ULASAN: = 5000


const MIN_UTANG: = 10000
const MIN_UTANG_CICIL: = 20000


func bisa_cicil_utang(jumlah: int) -> bool:
	return jumlah >= MIN_UTANG_CICIL


func cicilan_utang(jumlah: int) -> int:
	return clampi(int(ceil(jumlah / 2.0 / 1000.0)) * 1000, MIN_UTANG, maxi(jumlah, MIN_UTANG))
const HARI_IKHLAS: = 3
const HARI_JARANG_DITOLAK: = 7
const PENGALI_DITOLAK: = 0.35
const AKRAB_DIKASIH_UTANG: = 4.0
const AKRAB_DITOLAK_UTANG: = -6.0
const MINTA_UTANG: = ["Aduh Pak, dompet saya ketinggalan. Boleh ngutang dulu? Besok saya bayar.", 
	"Pak Misran, belum gajian nih... Boleh dicatat dulu? Lusa saya lunasi.", 
	"Pak, uangnya kurang. Ngutang dulu boleh? Nanti saya antar ke sini.", 
	"Maaf Pak, boleh kasbon dulu? Insyaallah besok saya bayar."]
const MARAH_DITOLAK_UTANG: = ["Masa nggak boleh sih, Pak? Ya sudah, nggak jadi beli!", 
	"Sama tetangga kok begitu, Pak. Nggak jadi deh!", 
	"Oh, jadi nggak percaya sama saya? Ya sudah, saya beli di tempat lain!"]
const BAYAR_UTANG: = ["Pak Misran, ini mau bayar utang yang kemarin. Hatur nuhun sudah dipercaya.", 
	"Pak, saya lunasi utang yang kemarin, ya. Makasih banyak, Pak.", 
	"Assalamualaikum, Pak. Ini uang yang kemarin saya utang. Pas, ya."]
const ULASAN_UTANG: = ["Pak Misran baik banget, boleh ngutang dulu waktu dompet ketinggalan.", 
	"Warung paling pengertian sekampung. Lagi susah dibolehin kasbon.", 
	"Pak Misran percaya sama warga. Pasti saya balik belanja di sini."]
var hutang: Array = []
var hutang_ditolak: = {}


func pengali_hutang_ditolak(tipe: String) -> float:
	return PENGALI_DITOLAK if hari < int(hutang_ditolak.get(tipe, -1)) else 1.0


func hutang_aktif() -> Array:
	return hutang.filter( func(h): return String(h["status"]) == "belum")






func tawar_hutang(tipe: String, total: int) -> bool:
	if mode_latihan or tutorial_langkah != "" or hari < HARI_MIN_NGUTANG or total < MIN_UTANG or not VarianBaju.sifat(tipe) in TIPE_BOLEH_NGUTANG:
		return false
	var aktif: = hutang_aktif()
	if aktif.size() >= MAKS_HUTANG_AKTIF or aktif.any( func(h): return String(h["tipe"]) == tipe):
		return false
	if _minta_utang_hari != hari:
		_minta_utang_hari = hari
		_minta_utang_jumlah = 0
	if _minta_utang_jumlah >= MAKS_MINTA_UTANG_HARI:
		return false
	var peluang: = PELUANG_NGUTANG_SIANG if (_minta_utang_jumlah == 0 and menit >= 12 * 60) else PELUANG_NGUTANG
	if randf() >= peluang:
		return false
	_minta_utang_jumlah += 1
	return true


func kasih_hutang(tipe: String, jumlah: int) -> void :
	var nama: = String(daftar_warga().get(tipe, "Warga"))
	if not daftar_warga().has(tipe) and VarianBaju.ada(tipe):
		nama = VarianBaju.nama_catatan(tipe)

	uang -= jumlah
	hutang.append({"tipe": tipe, "nama": nama, "jumlah": jumlah, "hari": hari, "tempo": hari + randi_range(1, 2), 
		"tak_bayar": randf() < PELUANG_TIDAK_BAYAR * pengali_sial(), "status": "belum", "hari_selesai": -1, "menit_bayar": -1})
	if jumlah >= MIN_UTANG_ULASAN:
		ulasan_warga(5, ULASAN_UTANG.pick_random(), nama)
	tambah_akrab(tipe, AKRAB_DIKASIH_UTANG)
	data_berubah.emit()


func tolak_hutang(tipe: String) -> void :
	hutang_ditolak[tipe] = hari + HARI_JARANG_DITOLAK
	tambah_akrab(tipe, AKRAB_DITOLAK_UTANG)
	data_berubah.emit()



func _atur_hutang_pagi() -> void :
	for h in hutang:
		if String(h["status"]) != "belum":
			continue
		h["menit_bayar"] = -1
		if bool(h["tak_bayar"]):

			if hari > int(h["tempo"]) + HARI_IKHLAS and int(h.get("tagih_hari", -99)) < hari - 1:
				h["status"] = "ikhlas"
				h["hari_selesai"] = hari

				h["kabar_ikhlas"] = true
		elif hari >= int(h["tempo"]) and not hari_libur():
			h["menit_bayar"] = randi_range(10 * 60, 15 * 60 + 30)



func ambil_kabar_utang_ikhlas() -> Array:
	var hasil: = []
	for h in hutang:
		if bool(h.get("kabar_ikhlas", false)):
			h.erase("kabar_ikhlas")
			hasil.append(h)
	return hasil



func hutang_dibayar_sekarang() -> int:
	if status_hari != "buka":
		return -1
	for i in hutang.size():
		var h: Dictionary = hutang[i]
		if String(h["status"]) == "belum" and int(h["menit_bayar"]) >= 0 and menit >= float(h["menit_bayar"]):
			return i
	return -1







const PELUANG_TAGIH_HALUS: = 0.45
const PELUANG_TAGIH_TEGAS: = 0.8
const TAMBAH_PELUANG_TAGIH: = 0.15
const TAGIH_PASTI: = 3
const AKRAB_TAGIH_TEGAS: = -3.0
const PELUANG_ULASAN_TEGAS: = 0.3
const AKRAB_TAGIH_PENUH: = -2.0
const AKRAB_CICIL: = 2.0
const AKRAB_IKHLAS: = 6.0
const BALAS_TAGIH_BERHASIL: = ["Aduh, maaf Pak, saya lupa! Nanti saya mampir ke warung, ya.", 
	"Iya Pak, maaf telat. Hari warung buka nanti saya datang bawa uangnya.", 
	"Punten Pak, kemarin lagi repot. Insyaallah saya datang ke warung."]
const BALAS_TAGIH_GAGAL: = ["Maaf Pak, belum ada uangnya. Kasih waktu sebentar lagi, ya.", 
	"Aduh Pak, gajian masih minggu depan... Sabar sedikit, ya.", 
	"Iya Pak, saya ingat kok. Tapi sekarang lagi seret. Nanti saya kabari."]
const BALAS_TAGIH_TEGAS_KESAL: = "Iya, iya, Pak. Nggak usah begitu juga, saya pasti bayar."
const ULASAN_TAGIH_TEGAS: = ["Pak Misran nagih utangnya galak juga, ya. Kaget saya.", 
	"Ditagih kayak debt collector, padahal cuma telat sedikit."]

const ALASAN_DATANG_TAGIH: = ["Pak, maaf banget utangnya telat. Kemarin anak saya sakit, uangnya kepakai berobat.", 
	"Pak Misran, maaf ya baru datang. Kerjaan lagi sepi, uangnya baru ada sedikit.", 
	"Punten Pak, saya malu sebenarnya. Uangnya cuma cukup buat separuh dulu...", 
	"Pak, maaf lama. Motor saya rusak, uangnya kepakai ke bengkel."]
const ULASAN_IKHLAS: = ["Pak Misran baik pisan, utang saya diikhlaskan waktu lagi susah. Semoga warungnya berkah.", 
	"Saya lagi kesulitan, Pak Misran malah mengikhlaskan utang saya. Orang baik."]


func utang_telat(h: Dictionary) -> bool:
	return String(h["status"]) == "belum" and hari > int(h["tempo"]) and not bool(h.get("datang_tagih", false))


func hari_telat(h: Dictionary) -> int:
	return maxi(0, hari - int(h["tempo"]))



func hari_buka_berikut() -> int:
	var h: = hari + 1
	while hari_libur(h):
		h += 1
	return h



func teks_hari_datang(h: int, terjemah: = true) -> String:
	var t: = "besok" if h == hari + 1 else "hari %s" % nama_hari_ke(h)
	return tk(t) if terjemah else t


func boleh_tagih(h: Dictionary) -> bool:
	return utang_telat(h) and int(h.get("tagih_hari", -99)) != hari



func tagih_hutang(i: int, tegas: bool) -> Dictionary:
	if i < 0 or i >= hutang.size() or not boleh_tagih(hutang[i]):
		return {"berhasil": false, "balasan": ""}
	var h: Dictionary = hutang[i]
	var ke: = int(h.get("ditagih", 0)) + 1
	h["ditagih"] = ke
	h["tagih_hari"] = hari
	var tipe: = String(h["tipe"])
	var bernama: = daftar_warga().has(tipe)
	var peluang: = (PELUANG_TAGIH_TEGAS if tegas else PELUANG_TAGIH_HALUS) + TAMBAH_PELUANG_TAGIH * (ke - 1)



	if not bernama and bool(h["tak_bayar"]) and int(h["jumlah"]) >= MIN_UTANG_PINDAH and not bool(h.get("cek_pindah", false)):
		h["cek_pindah"] = true
		if randf() < PELUANG_PINDAH_RUMAH:
			h["status"] = "pindah"
			h["hari_selesai"] = hari
			h["menit_bayar"] = -1
			data_berubah.emit()
			return {"berhasil": false, "blokir": true, "balasan": ""}
	var berhasil: bool = not bool(h["tak_bayar"]) or ke >= TAGIH_PASTI or randf() < peluang
	var balasan: = ""
	if tegas:
		if bernama:
			tambah_akrab(tipe, AKRAB_TAGIH_TEGAS)
		if randf() < PELUANG_ULASAN_TEGAS:
			ulasan_warga(2, ULASAN_TAGIH_TEGAS.pick_random(), String(h["nama"]))
	if berhasil:
		h["tak_bayar"] = false
		h["datang_tagih"] = true
		h["menit_bayar"] = -1
		h["tempo"] = hari_buka_berikut()
		balasan = BALAS_TAGIH_TEGAS_KESAL if tegas and bernama and randf() < 0.5 else String(BALAS_TAGIH_BERHASIL.pick_random())
	else:
		balasan = String(BALAS_TAGIH_GAGAL.pick_random())
	data_berubah.emit()
	return {"berhasil": berhasil, "balasan": balasan, "hari_datang": int(h["tempo"])}



func selesaikan_tagihan(i: int, pilihan: String) -> int:
	if i < 0 or i >= hutang.size():
		return 0
	var h: Dictionary = hutang[i]
	var tipe: = String(h["tipe"])
	var bernama: = daftar_warga().has(tipe)
	h["datang_tagih"] = false
	match pilihan:
		"cicil":
			var jumlah: = int(h["jumlah"])
			var bayar: = cicilan_utang(jumlah)
			if not bisa_cicil_utang(jumlah) or bayar >= jumlah:
				return lunasi_hutang(i)
			h["jumlah"] = jumlah - bayar
			h["menit_bayar"] = -1
			h["tempo"] = hari_buka_berikut()
			h["tak_bayar"] = false
			uang += bayar
			catat_transaksi("Utang dicicil: %s" % String(h["nama"]), bayar)
			if bernama:
				tambah_akrab(tipe, AKRAB_CICIL)
			bunyi("koin")
			data_berubah.emit()
			return bayar
		"ikhlas":
			h["status"] = "ikhlas"
			h["hari_selesai"] = hari
			h["menit_bayar"] = -1
			if bernama:
				tambah_akrab(tipe, AKRAB_IKHLAS)
			if int(h["jumlah"]) >= MIN_UTANG_ULASAN:
				ulasan_warga(5, ULASAN_IKHLAS.pick_random(), String(h["nama"]))
			data_berubah.emit()
			return 0
	if bernama:
		tambah_akrab(tipe, AKRAB_TAGIH_PENUH)
	return lunasi_hutang(i)


func lunasi_hutang(i: int) -> int:
	var h: Dictionary = hutang[i]
	if String(h["status"]) != "belum":
		return 0
	h["status"] = "lunas"
	h["hari_selesai"] = hari
	h["menit_bayar"] = -1
	uang += int(h["jumlah"])
	catat_transaksi("Utang dibayar: %s" % String(h["nama"]), int(h["jumlah"]))
	bunyi("koin")
	data_berubah.emit()
	return int(h["jumlah"])









func efek_reputasi() -> Dictionary:
	return efek_reputasi_bintang(bintang())



func efek_reputasi_bintang(b: int) -> Dictionary:



	var datang: = 1.0
	match b:
		3: datang = 0.95
		4: datang = 0.9
		5: datang = 0.85
	return {"datang": datang, "sabar": 1.0, "banyak": 0.0, "supplier": 1.0, "tip": 0.0, "kurir": 20.0}


func durasi_kirim() -> float:
	var pilihan: = kurir_hari_ini()
	return detik_kurir(pilihan if pilihan != "" else "reguler")




func detik_kurir(jenis: String) -> float:
	var d: = float(efek_reputasi()["kurir"])
	if punya_upgrade_efek("kurir"):
		d = minf(d, efek_upgrade("kurir", d))
	d *= efek_cerita("kurir") * (PENGALI_WAKTU_KIRIM_MOTOR if motor_baru else 1.0)
	var dasar: = DURASI_KIRIM if tutorial_langkah != "" or mode_latihan else float(KURIR[jenis]["detik"])
	return maxf(dasar * d / DURASI_KIRIM_LAMA, 1.0)





const KURIR: = {
	"reguler": {"nama": "Reguler", "detik": 30.0, "ongkir": 10000, "urut": 1}, 
	"cepat": {"nama": "Cepat", "detik": 20.0, "ongkir": 20000, "urut": 2}, 
	"instan": {"nama": "Instan", "detik": 1.0, "ongkir": 0, "urut": 3}, 
}
const ONGKIR_REGULER_GRATIS_SAMPAI_LEVEL: = 2
const LAMA_KURIR_INSTAN: = 2
var kurir_pilihan: = ""
var kurir_hari: = -1
var instan_mulai: = 0


func sisa_hari_instan() -> int:
	if instan_mulai <= 0 or hari < instan_mulai:
		return 0
	return maxi(instan_mulai + LAMA_KURIR_INSTAN - hari, 0)



func kurir_hari_ini() -> String:
	if sisa_hari_instan() > 0:
		return "instan"
	return kurir_pilihan if kurir_hari == hari else ""


func urutan_kurir(jenis: String) -> int:
	return int(KURIR[jenis]["urut"]) if KURIR.has(jenis) else 0



func ongkir_kurir(jenis: String) -> int:
	if tutorial_langkah != "" or mode_latihan or jenis == "instan":
		return 0
	if jenis == "reguler" and level() <= ONGKIR_REGULER_GRATIS_SAMPAI_LEVEL:
		return 0
	return int(KURIR[jenis]["ongkir"])




func pilih_kurir(jenis: String) -> String:
	if not KURIR.has(jenis):
		return "Kurir tidak dikenal."

	var sudah: = kurir_hari_ini()
	if sudah == jenis:
		return ""
	if sudah != "":
		return "Hari ini sudah memakai kurir %s. Ongkir berlaku seharian, jadi belanja berikutnya tetap %s." % [String(KURIR[sudah]["nama"]).to_lower(), String(KURIR[sudah]["nama"]).to_lower()]
	var ongkir: = ongkir_kurir(jenis)
	if ongkir > 0:
		if not bayar_campur(ongkir):
			return "Uang tidak cukup untuk ongkir %s (%s)." % [String(KURIR[jenis]["nama"]).to_lower(), format_rupiah(ongkir)]
		uang -= ongkir
		belanja_hari += ongkir
		catat_transaksi("Ongkir kurir %s" % String(KURIR[jenis]["nama"]).to_lower(), - ongkir)
	kurir_pilihan = jenis
	kurir_hari = hari
	if jenis == "instan":
		instan_mulai = hari
	data_berubah.emit()
	return ""





const HARGA_JUAL_MAKS: = 1.3

func batas_harga_jual(id: String) -> int:
	var normal: = int(katalog[id]["jual"])
	return maxi(int(normal * HARGA_JUAL_MAKS) / langkah_harga(id) * langkah_harga(id), harga_pasar(id))


func harga_jual(id: String) -> int:
	return mini(int(harga_jual_khusus.get(id, katalog[id]["jual"])), batas_harga_jual(id))



func harga_modal(id: String) -> int:
	var pengali: = float(efek_reputasi()["supplier"]) * (1.0 + efek_upgrade("supplier"))
	if lewat_agen(id):
		pengali *= 1.0 + TAMBAHAN_AGEN
	if ada_promo(id):
		pengali *= 1.0 - diskon_promo(id)
	return int(round(float(katalog[id]["modal"]) * pengali / 100.0) * 100)



func langkah_harga(id: String) -> int:
	return 100 if int(katalog[id]["jual"]) < 10000 else 500


func ubah_harga_jual(id: String, arah: int) -> void :
	var normal: = int(katalog[id]["jual"])
	var lama: = harga_jual(id)
	var baru: = lama + arah * langkah_harga(id)


	var pasar: = harga_pasar(id)
	for patokan in [pasar, normal]:
		if (lama < patokan and patokan < baru) or (baru < patokan and patokan < lama):
			baru = patokan

	var bawah: = mini(maxi(int(katalog[id]["modal"]), harga_modal(id)) + 100, pasar)


	baru = clampi(baru, bawah, batas_harga_jual(id))
	if baru == normal:
		harga_jual_khusus.erase(id)
	else:
		harga_jual_khusus[id] = baru
	data_berubah.emit()



func rasio_harga(id: String) -> float:
	return float(harga_jual(id)) / float(harga_pasar(id))






const KONTAK_CHAT: = {
	"agus": "Agus", 
	"juragan": "Pak Haji Rasyid", 
	"rt": "Grup Warga RT 05", 
	"sales": "Sales Grosir", 
	"agen": "Info Harga Pasaran", 
	"klinik": "Klinik Sehat Kampung", 
}
var chat: = {}
var chat_belum: = {}
const MAKS_CHAT: = 120
var _notif: CanvasLayer = null





var kontak_warga: = {}

func nama_kontak(kontak: String) -> String:
	return String(KONTAK_CHAT.get(kontak, kontak_warga.get(kontak, kontak)))


func daftar_kontak() -> Array:
	return KONTAK_CHAT.keys() + kontak_warga.keys()


func kontak_utang(i: int) -> String:
	var h: Dictionary = hutang[i]
	var k: = "utang:%s" % String(h["tipe"])
	kontak_warga[k] = String(h["nama"])
	return k



func utang_kontak(kontak: String) -> int:
	if not kontak.begins_with("utang:"):
		return -1
	var tipe: = kontak.substr(6)
	for i in hutang.size():
		if String(hutang[i]["tipe"]) == tipe and String(hutang[i]["status"]) == "belum":
			return i
	return -1


const PESAN_TAGIH_HALUS: = "Assalamualaikum, %s. Punten, utang di warung %s sudah lewat janji. Kira-kira kapan bisa dibayar, ya?"
const PESAN_TAGIH_TEGAS: = "%s, utang %s di warung sudah lewat janji %d hari. Tolong segera dibayar, ya."


func tagih_lewat_chat(i: int, tegas: bool) -> Dictionary:
	if i < 0 or i >= hutang.size() or not boleh_tagih(hutang[i]):
		return {}
	var h: Dictionary = hutang[i]
	var k: = kontak_utang(i)
	var nama: = String(h["nama"])
	var pesan: = (PESAN_TAGIH_TEGAS % [nama, format_rupiah(int(h["jumlah"])), hari_telat(h)]) if tegas\
	else (PESAN_TAGIH_HALUS % [nama, format_rupiah(int(h["jumlah"]))])
	tambah_chat("Bapak", pesan, false, "teks", k)
	var hasil: = tagih_hutang(i, tegas)
	_balas_tagih(k, nama, hasil)
	return hasil


signal sedang_mengetik(kontak: String, aktif: bool)

func _balas_tagih(k: String, nama: String, hasil: Dictionary) -> void :
	if bool(hasil.get("blokir", false)):

		await get_tree().create_timer(1.6, true, false, true).timeout
		tambah_chat("", "Pesan tidak terkirim. Anda telah diblokir.", not _chat_sedang_dibuka(k), "sistem", k)
		kontak_warga[k] = "+62 8%02d-%04d-%04d" % [randi_range(11, 99), randi_range(1000, 9999), randi_range(1000, 9999)]
		data_berubah.emit()
		return
	sedang_mengetik.emit(k, true)
	await get_tree().create_timer(2.2, true, false, true).timeout
	sedang_mengetik.emit(k, false)
	var balas: = String(hasil.get("balasan", ""))
	if bool(hasil.get("berhasil", false)):

		balas += " (Datang ke warung %s.)" % teks_hari_datang(int(hasil.get("hari_datang", hari + 1)), false)
	tambah_chat(nama, balas, not _chat_sedang_dibuka(k), "teks", k)



func _chat_sedang_dibuka(k: String) -> bool:
	var adegan: = get_tree().current_scene
	if adegan == null or adegan.get("hp") == null or not adegan.hp.visible:
		return false
	var app = adegan.hp.aplikasi("wasap")
	return app != null and app.is_visible_in_tree() and app._ruang.visible and app._kontak == k


func tambah_chat(dari: String, teks: String, belum_dibaca: = false, jenis: = "teks", kontak: = "agus") -> void :
	if not chat.has(kontak):
		chat[kontak] = []
	var daftar: Array = chat[kontak]
	daftar.append({"dari": dari, "teks": teks, "hari": hari, "jam": teks_jam().replace(" WIB", ""), "jenis": jenis})
	if daftar.size() > MAKS_CHAT:
		chat[kontak] = daftar.slice(daftar.size() - MAKS_CHAT)
	if belum_dibaca:
		chat_belum[kontak] = int(chat_belum.get(kontak, 0)) + 1

		if sedang_main and _notif != null and dari != "Bapak":
			var judul: = nama_kontak(kontak) if kontak != "rt" else "%s · %s" % [KONTAK_CHAT["rt"], dari]
			_notif.kabari(kontak, judul, teks if jenis == "teks" else "Mengirim transfer")
	data_berubah.emit()


func baca_chat(kontak: = "agus") -> void :
	if int(chat_belum.get(kontak, 0)) > 0:
		chat_belum[kontak] = 0
		data_berubah.emit()


func pesan_chat(kontak: String) -> Array:
	return chat.get(kontak, [])




func catat_transaksi(teks: String, jumlah: int) -> void :
	transaksi.append({"hari": hari, "jam": teks_jam().replace(" WIB", ""), "teks": teks, "jumlah": jumlah})
	if transaksi.size() > MAKS_TRANSAKSI:
		transaksi = transaksi.slice(transaksi.size() - MAKS_TRANSAKSI)




const NAMA_PENGULAS: = ["Bu Sri", "Mas Dimas", "Pak Joko", "Mbak Rina", "Bu Yati", "Mas Fajar", "Dek Nisa", "Pak Slamet", "Mbak Ayu", "Bu Ningsih", 
	"Mas Rizal", "Pak Darto", "Mbak Dewi", "Cak Imron", "Bu Halimah", "Kang Ujang", "Teh Euis", "Mang Dadang", "Neng Sari", "Pak Asep", 
	"Bu Entin", "Kang Dedi", "Teh Lilis", "Aa Rizky", "Bu Popon"]
const ULASAN: = {
	"cepat": [5, 0.12, ["Pak Misran cekatan, nggak pakai lama.", "Pelayanannya cepat, mantap!", "Baru nyebut pesanan langsung dikasih. Top.", 
		"Warung langganan, selalu cepat.", "Gercep pisan si Bapak, hatur nuhun!", "Belum selesai ngomong udah disiapin. Keren.", 
		"Pas buru-buru mau kerja, dilayani kilat. Makasih, Pak!", "Cepat, ramah, nggak bikin nunggu. Bintang lima.", 
		"Anak saya disuruh beli, pulangnya cepat. Mantap warungnya.", "Sat set sat set, Pak Misran memang jago.", "Datang, pesan, bayar, beres. Nggak sampai semenit!", "Pak Misran gesit pisan, kayak pembalap.", "Antre panjang tapi cepat habisnya. Salut.", "Pelayanan secepat kilat, belanja jadi nggak ribet.", "Saya telat berangkat, untung dilayani cepat. Hatur nuhun!"]], 
	"banyak": [5, 0.12, ["Belanja banyak sekaligus, semua ada. Lengkap!", "Satu warung, semua kebutuhan ada.", "Lengkap dan ramah, Pak Misran juara.", 
		"Belanja bulanan cukup di sini, nggak usah ke pasar.", "Mau masak tinggal ke warung Pak Misran, semua ada.", 
		"Beli macam-macam, nggak ada yang ketinggalan.", "Lengkap pisan! Dari mie sampai pulsa ada.", "Borong banyak, dilayani sabar. Nuhun, Pak.", "Beli buat arisan, semua ada di sini. Nuhun, Pak!", "Daftar belanjaan panjang, satu warung beres semua.", "Dari sabun sampai pulsa, lengkap. Hemat ongkos.", "Belanja banyak tapi dihitung teliti, nggak ada yang kelewat."]], 
	"layani": [4, 0.05, ["Warungnya enak, bapaknya ramah.", "Lumayan lengkap untuk warung kampung.", "Harga wajar, pelayanan baik.", 
		"Pak Misran selalu senyum, betah belanja di sini.", "Warungnya bersih, barangnya rapi.", "Dekat rumah dan bapaknya baik. Langganan!", 
		"Belanja sambil ngobrol, enak suasananya.", "Recommended buat warga sekitar.", "Nggak pernah kecewa belanja di sini.", 
		"Bapaknya inget pesanan saya yang biasa. Hehe.", "Pak Misran sopan, belanja jadi nyaman.", "Warung favorit sekampung. Bapaknya ramah ke anak-anak.", "Sering dikasih tahu barang baru. Perhatian sekali.", "Warungnya adem, enak buat mampir.", "Pelayanan tulus, kayak belanja di rumah sendiri.", "Bapaknya selalu nanya kabar. Hangat sekali."]], 
	"kesal": [1, 0.45, ["Nunggu kelamaan, akhirnya pulang.", "Antrenya lama banget, nggak jadi beli.", "Lama, Pak. Saya buru-buru.", 
		"Udah nunggu lama, nggak dilayani-layani.", "Kesel, antre lama banget tadi.", "Mending jalan ke warung sebelah, lebih cepat.", 
		"Bapaknya kayak bingung, saya ditinggal lama.", "Saya nunggu sampai es teh saya mencair. Pulang saja.", "Antre kayak di bank. Lain kali cepat, ya, Pak.", "Anak saya nangis kelamaan nunggu. Nggak jadi beli.", "Ditinggal lama di depan, kayak nggak kelihatan."]], 
	"habis": [2, 0.45, ["Barang yang saya cari habis terus.", "Mau beli malah habis. Kecewa.", "Stoknya sering kosong, Pak.", 
		"Jauh-jauh datang, barangnya kosong.", "Tolong stoknya ditambah, Pak, sering habis.", "Sudah dua kali ke sini, habis terus.", 
		"Habis lagi, habis lagi... duh.", "Cari minyak goreng, kosong. Cari gula, kosong juga.", "Tolong rak yang kosong diisi, Pak. Sayang pembelinya.", "Sudah semangat datang, pulang tangan kosong.", "Barangnya habis, terpaksa ke warung sebelah."]], 
	"mahal": [1, 0.5, ["Mahal banget, mending di tempat lain.", "Harganya kok naik terus?", "Kemahalan untuk warung kampung.", 
		"Harganya nggak masuk akal, Pak.", "Di warung lain lebih murah, lho.", "Mahal pisan, teu jadi meser.", "Kaget lihat harganya. Nggak jadi.", "Harganya bikin kaget, mending hemat dulu.", "Uang belanja saya nggak cukup di sini. Mahal.", "Warung kampung tapi harga kota. Hmm.", "Tolong harganya dicek lagi, Pak. Kemahalan."]], 
	"mahal_beli": [2, 0.4, ["Terpaksa beli, tapi harganya mahal.", "Barangnya ada, tapi mahal ya.", "Butuh, jadi beli juga. Tapi mahal.", 
		"Lumayan nguras dompet belanja di sini.", "Kalau harganya turun dikit, saya langganan deh.", "Terpaksa beli karena darurat. Semoga harganya turun.", "Mahal sedikit, tapi untung barangnya ada.", "Dompet menangis, tapi kebutuhan terpenuhi."]], 
	"murah": [5, 0.25, ["Harganya murah, cocok buat kantong warga.", "Lebih murah dari warung lain. Langganan!", 
		"Murah meriah, bapaknya ramah.", "Harga bersahabat, belanja jadi tenang.", "Murah dan ramah, kombinasi sempurna.", "Uang jajan anak saya cukup di sini. Terima kasih, Pak!", "Harga pas di kantong, kualitas tetap bagus.", "Akhir bulan aman belanja di warung Pak Misran."]], 
	"salah": [3, 0.3, ["Pesanan sempat salah, tapi akhirnya beres.", "Bapaknya agak bingung tadi, salah ambil.", 
		"Salah kasih barang, untung cepat diganti.", "Tadi sempat keliru, tapi bapaknya minta maaf. Oke lah.", 
		"Pesanan saya ketuker, tapi akhirnya benar.", "Sempat salah ambil, tapi bapaknya sigap memperbaiki.", "Barangnya keliru sedikit, tapi dilayani dengan sabar.", "Salah kasih, tapi minta maafnya tulus. Oke, Pak."]], 
}



const PUJIAN_SINGKAT: = {"cepat": ["Pelayanannya cepat", "Bapaknya cekatan", "Nggak pakai lama", "Gesit pisan", "Pelayanannya kilat"], 
	"banyak": ["Barangnya lengkap", "Belanja banyak semua ada", "Semua kebutuhan ada"], "murah": ["Harganya murah", "Harganya bersahabat", "Harganya pas di kantong"], 
	"layani": ["Bapaknya ramah", "Warungnya enak", "Pelayanannya baik", "Bapaknya sopan", "Suasananya nyaman"]}



const KELUHAN_FASILITAS: = [
	["kipas", "tapi nggak ada kipas angin, jadi agak gerah", ""], 
	["bangku", "tapi nggak ada bangku tunggu, jadi ngantre sambil berdiri", ""], 
	["lampu", "tapi lampunya redup, barangnya susah dilihat", "malam"], 
	["radio", "tapi warungnya sepi, nggak ada musik", "level:5"], 
	["qris", "tapi belum bisa bayar QRIS, repot kalau nggak bawa uang tunai", "level:6"], 
	["", "tapi barangnya masih sedikit, belum lengkap", "sampai_level:2"], 
	["", "tapi warungnya masih sederhana, kayak baru buka", "sampai_level:1"], 
]
const BINTANG_KELUHAN: = 3

const PELUANG_ULAS: = {"cepat": 0.3, "banyak": 0.3, "murah": 0.25, "layani": 0.2, "kesal": 0.55, "habis": 0.5, 
	"mahal": 0.9, "mahal_beli": 0.8, "salah": 0.35}




func keluhan_fasilitas() -> Array:
	var hasil: Array = []
	for k in KELUHAN_FASILITAS:
		if punya_upgrade(String(k[0])):
			continue

		if String(k[0]) == "kipas" and sedang_hujan():
			continue
		var u: = data_upgrade(String(k[0]))
		if not u.is_empty() and level() < int(u["level"]):
			continue
		var syarat: = String(k[2])
		if syarat == "malam" and menit < 15 * 60:
			continue
		if syarat.begins_with("sampai_level:") and level() > int(syarat.split(":")[1]):
			continue
		if syarat.begins_with("level:") and level() < int(syarat.split(":")[1]):
			continue
		hasil.append(k)
	return hasil



func ulas(kejadian: String, tipe: = "") -> void :
	var nama: = VarianBaju.nama_ulasan(tipe)
	var muda: bool = nama != "" and VarianBaju.sifat(tipe) in KELOMPOK_PEMBELI["anak_sekolah"]
	if not ULASAN.has(kejadian):
		return
	var u: Array = ULASAN[kejadian]
	var peluang: = float(PELUANG_ULAS.get(kejadian, u[1]))
	var puas: = int(u[0]) >= 4

	if puas:
		peluang *= 1.0 + efek_upgrade("ulasan_baik")
	if randf() >= peluang:
		return
	var nilai: = int(u[0])
	var teks: = ""

	var keluhan: = keluhan_fasilitas() if puas else []

	var peluang_keluh: = minf(0.7, 0.15 + 0.12 * keluhan.size())
	if level() <= 2:
		peluang_keluh = maxf(peluang_keluh, 0.55)
	if not keluhan.is_empty() and randf() < peluang_keluh:
		var k: Array = keluhan.pick_random()
		teks = "%s, %s." % [String(PUJIAN_SINGKAT.get(kejadian, PUJIAN_SINGKAT["layani"]).pick_random()), String(k[1])]
		nilai = BINTANG_KELUHAN
	else:

		if nilai == 5 and randf() >= peluang_bintang_lima():
			nilai = 4

		var teks_lama: = ulasan.slice(maxi(ulasan.size() - 10, 0)).map( func(x): return x["teks"])
		var calon: = (u[2] as Array).filter( func(t): return not t in teks_lama and (nilai == 5 or not "lima" in t.to_lower()) and not (muda and _kalimat_orang_tua(t)))
		teks = (calon if not calon.is_empty() else u[2]).pick_random()
	_tambah_ulasan(nilai, teks, nama)
	_hitung_reputasi()



func _kalimat_orang_tua(teks: String) -> bool:
	var t: = teks.to_lower()
	for kata in ["anak saya", "suami", "istri", "cucu", "kerja", "belanja bulanan", "masak", "kantong warga"]:
		if t.contains(kata):
			return true
	return false




const FASILITAS_NYAMAN: = ["kipas", "bangku", "lampu", "radio", "qris"]

func peluang_bintang_lima() -> float:
	var punya: = FASILITAS_NYAMAN.filter( func(id): return punya_upgrade(id)).size()
	return 0.3 + 0.6 * float(punya) / FASILITAS_NYAMAN.size()


func _tambah_ulasan(nilai: int, teks: String, nama: = "") -> void :
	if nama == "":
		var nama_lama: = ulasan.slice(maxi(ulasan.size() - 10, 0)).map( func(x): return x["nama"])
		var calon_nama: = NAMA_PENGULAS.filter( func(n): return not n in nama_lama)

		var t: = teks.to_lower()
		if t.contains("anak saya") or t.contains("suami") or t.contains("istri") or t.contains("cucu"):
			calon_nama = calon_nama.filter( func(n): return not n.begins_with("Dek ") and n != "Mas Dimas")
		nama = (calon_nama if not calon_nama.is_empty() else NAMA_PENGULAS).pick_random()
	ulasan.append({"hari": hari, "nama": nama, "bintang": nilai, "teks": teks})
	if ulasan.size() > MAKS_ULASAN:
		ulasan = ulasan.slice(ulasan.size() - MAKS_ULASAN)




func minggu_ke(h: int = -1) -> int:
	if h < 1:
		h = hari
	return (h - 1) / 7


func ada_promo(id: String) -> bool:
	return promo_hari_ke == hari and promo.has(id)


func diskon_promo(id: String) -> float:
	return float(promo.get(id, 0.0)) if ada_promo(id) else 0.0






const PESAN_RT: = [
	{"dari": "Pak Slamet", "teks": "Nanti habis Ashar ada pengajian di masjid, selesai sekitar jam 4. Habis itu biasanya jamaah mampir ke warung.", "pengajian": true}, 
	{"dari": "Bu Yati", "teks": "Sandal jepit hijau saya ketuker di masjid habis Subuh. Yang merasa, tolong dikembalikan, ya."}, 
	{"dari": "Mas Fajar", "teks": "Warung Pak Misran ada minuman dingin lho, enak buat siang-siang.", "syarat": "cerah", 
		"efek": {"jam": [11.0, 15.0], "kategori": {"minuman": 1.8}}}, 
	{"dari": "Bu Ningsih", "teks": "Anak-anak sekolah pulang jam 1, biasanya pada jajan ciki.", "butuh": ["ciki"], 
		"efek": {"jam": [13.0, 14.5], "jeda": 0.7, "barang": {"ciki": 3.0, "permen": 2.5, "teh_botol": 1.5}, "tipe": {"anak": 3.0, "siswi": 2.0, "pelajar": 2.0}}}, 
	{"dari": "Cak Imron", "teks": "Hari ini panas banget. Air mineral pasti laris.", "syarat": "cerah", 
		"efek": {"jam": [10.0, 16.0], "barang": {"air_mineral": 3.0, "teh_botol": 1.5}, "kategori": {"minuman": 1.3}}}, 
	{"dari": "Bu Halimah", "teks": "Harga telur di pasar naik. Untung warung Pak Misran masih wajar, pada belanja di situ aja.", 
		"efek": {"jam": [7.0, 21.0], "barang": {"telur": 2.5}, "tipe": {"ibu_rumah_tangga": 2.0}}}, 
]

var kabar_hari: = {}



func efek_kabar() -> Dictionary:
	if int(kabar_hari.get("hari", 0)) != hari or status_hari != "buka":
		return {}
	var e: Dictionary = kabar_hari.get("efek", {})
	var jam: = menit / 60.0
	var r: Array = e.get("jam", [0.0, 24.0])
	return e if jam >= float(r[0]) and jam < float(r[1]) else {}



func tipe_ramai() -> Dictionary:
	var hasil: = {}
	for efek in [efek_kejadian(), efek_kabar()]:
		for t in efek.get("tipe", {}):
			hasil[t] = float(hasil.get(t, 1.0)) * float(efek["tipe"][t])
	return hasil


func _kabar_pagi() -> void :
	_kabar_ramadan()
	_kabari_susulan()

	if hari == HARI_LEBARAN - 1:

		tambah_chat("Pak RT", "Bapak-bapak, Ibu-ibu, malam ini malam takbiran. Suara takbir dari masjid mulai terdengar pukul 19.00. Besok sudah Lebaran!", true, "teks", "rt")
	elif hari == HARI_LEBARAN:
		tambah_chat("Pak RT", "Selamat Hari Raya Idulfitri. Taqabbalallahu minna wa minkum, mohon maaf lahir dan batin, Bapak-Ibu sekalian.", true, "teks", "rt")

		if hasil_event("agus_mudik") == "":
			tambah_chat("Pak RT", "Pak Misran, tadi ada pemuda bawa ransel nanyain Bapak di depan warung. Coba ke warung, Pak.", true, "teks", "rt")
	if agus_bantu_sampai > 0 and hari == agus_bantu_sampai + 1:
		tambah_chat("Agus", "Pak, Agus sudah sampai lagi di kota. Makasih ya, Pak, beberapa hari kemarin rasanya kayak dulu lagi. Bapak jaga kesehatan, jangan kerja terlalu capek.", true)

	var pilihan: = barang_belanja().filter(terbuka)
	pilihan.shuffle()
	promo = {}
	promo_hari_ke = hari
	var kalimat: Array = []
	for id in pilihan.slice(0, randi_range(1, 3)):
		promo[id] = PILIHAN_DISKON_PROMO.pick_random()
		kalimat.append("%s diskon %d%%" % [String(data_barang(id)["nama"]).to_lower(), roundi(float(promo[id]) * 100)])
	if not kalimat.is_empty():
		tambah_chat("Sales Grosir", "Selamat pagi, Pak Misran! Promo khusus hari ini di Belanja Online: %s. Besok ganti promo lagi ya, Pak." % ", ".join(kalimat), true, "teks", "sales")

	_kabar_agen()

	if pesan_kerja_sampingan() != "":
		tambah_chat("Pak RT", pesan_kerja_sampingan(), true, "teks", "rt")

	if hari_libur():
		return
	if nama_hari() == "Kamis" and ikut_ronda_jumatan():
		tambah_chat("Pak RT", "Bapak-bapak, nanti malam Jumat giliran ronda. Kumpul di pos ronda jam 10 malam, ya. Kopi dan kacang dari warung Pak Misran, hehe.", true, "teks", "rt")
		tambah_chat("Pak Darto", "Besok Jumat, jangan lupa Jumatan, Bapak-bapak.", true, "teks", "rt")

	elif randf() < 0.35:
		var cocok: = PESAN_RT.filter(_kabar_cocok)
		if not cocok.is_empty():
			var p: Dictionary = cocok.pick_random()
			tambah_chat(String(p["dari"]), String(p["teks"]), true, "teks", "rt")

			if p.get("pengajian", false):
				pengajian_hari = hari
			if p.has("efek"):
				kabar_hari = {"hari": hari, "efek": p["efek"]}


func _kabar_cocok(p: Dictionary) -> bool:
	for id in p.get("butuh", []):
		if not terbuka(id):
			return false
	if String(p.get("syarat", "")) == "cerah":

		if not cuaca.is_empty() or String(kejadian.get("id", "")) == "mati_listrik":
			return false
	return true



const JAM_PENGAJIAN: = [16 * 60, 17 * 60]
var pengajian_hari: = 0

func pengajian_bubar() -> bool:
	return pengajian_hari == hari and menit >= JAM_PENGAJIAN[0] and menit < JAM_PENGAJIAN[1]


func pengali_pengajian() -> float:
	return 0.4 if pengajian_bubar() else 1.0


func belum_dibaca(kontak: = "") -> int:
	if kontak != "":
		return int(chat_belum.get(kontak, 0))
	var n: = 0
	for k in chat_belum:
		n += int(chat_belum[k])
	return n



func _ingatkan_batas_lewat_chat() -> void :
	if cerita_tamat or kekurangan_kiriman() <= 0:
		return
	match sisa_hari():
		3:
			tambah_chat(nama_penerima(), "Pak, batas %s tinggal 3 hari lagi ya, tanggal %s. Masih kurang %s." % [data_bab()["kebutuhan"], teks_tanggal(batas_hari), format_rupiah(kekurangan_kiriman())], true, "teks", kontak_bab())
		1:
			tambah_chat(nama_penerima(), "Pak, hari ini batas terakhir buat %s. Kurang %s lagi, Pak." % [data_bab()["kebutuhan"], format_rupiah(kekurangan_kiriman())], true, "teks", kontak_bab())



const BATAS_STOK_MENIPIS: = 5

var keluh_dikabari: = {}
var keluh_mati_hari: = -1


func barang_menipis() -> Array:
	var hasil: Array = []
	for id in barang_belanja():
		if terbuka(id) and stok[id] + jumlah_kiriman(id) <= BATAS_STOK_MENIPIS:
			hasil.append(id)
	return hasil




func barang_kurang_stok() -> Array:
	var hasil: Array = []
	for id in barang_belanja():
		if terbuka(id) and stok[id] < MIN_STOK_BUKA and not BARANG_TITIPAN.has(id):
			hasil.append([id, MIN_STOK_BUKA - stok[id], jumlah_kiriman(id)])
	return hasil




func kekurangan_stok(keranjang: Dictionary = {}) -> Dictionary:
	var hasil: = {}
	for k in barang_kurang_stok():
		var perlu: int = int(k[1]) - int(k[2]) - int(keranjang.get(k[0], 0))
		if perlu > 0:
			hasil[k[0]] = perlu
	return hasil




func biaya_lengkapi_stok() -> int:
	var biaya: = 0
	for k in barang_kurang_stok():
		biaya += maxi(k[1] - k[2], 0) * harga_modal(k[0])
	return biaya




func nama_pemilik_kios() -> String:
	return String(cerita.get("sewa", {}).get("pemilik", "Pemilik kios"))




func sewa_per_minggu(i: int = -1) -> int:
	if kios_milik and i < 0:
		return 0
	var daftar: Array = cerita.get("sewa", {}).get("per_minggu", [0])
	var sekarang: = i < 0
	if sekarang:
		i = tingkat
	var sewa: = int(daftar[clampi(i, 0, daftar.size() - 1)])

	if sekarang:


		var minggu: = minggu_sewa_berjalan()
		if int(sewa_kunci.get("minggu", -1)) == minggu:
			return mini(int(sewa_kunci["jumlah"]), sewa)
		sewa_kunci = {"minggu": minggu, "jumlah": sewa}
	return sewa



var sewa_kunci: = {}

func minggu_sewa_berjalan() -> int:
	return int((hari - 1) / 7) + (1 if sewa_selesai_hari == hari and hari_sewa() else 0)

var upah_harian: = {}


func catat_upah(n: int) -> void :
	analitik.catat("kerja", {"upah": n})
	var k: = str(hari)
	upah_harian[k] = int(upah_harian.get(k, 0)) + n
	for h in upah_harian.keys():
		if int(h) <= hari - 7:
			upah_harian.erase(h)


func upah_seminggu() -> int:
	var total: = 0
	for h in upah_harian:
		if int(h) > hari - 7:
			total += int(upah_harian[h])
	return total



func hari_sewa(h: int = -1) -> bool:
	if kios_milik:
		return false
	if h < 1:
		h = hari
	return h % 7 == 0



func hari_jatuh_tempo_sewa() -> int:



	if hari % 7 == 0 and sewa_selesai_hari == hari:
		return hari + 7
	return hari + (7 - hari % 7) % 7



func sewa_hari_ini_selesai() -> bool:
	return hari_sewa() and sewa_selesai_hari == hari



func bayar_tunggakan_sewa() -> String:
	if tunggakan_sewa <= 0:
		return "Tidak ada tunggakan sewa."
	if uang + saldo_digital < tunggakan_sewa:
		return "Uang tidak cukup untuk melunasi tunggakan %s." % format_rupiah(tunggakan_sewa)
	_tarik_qris_untuk(tunggakan_sewa, "Ambil saldo QRIS untuk tunggakan sewa")
	uang -= tunggakan_sewa
	catat_transaksi("Bayar tunggakan sewa", - tunggakan_sewa)
	tambah_chat(nama_pemilik_kios(), "Tunggakan sewa sudah saya terima, Pak Misran. Terima kasih.", false, "teks", "juragan")
	tunggakan_sewa = 0
	minggu_tunggak = 0
	data_berubah.emit()
	simpan()
	return ""








const MAKS_DENDA_SEWA: = 0
const MINGGU_DIUSIR: = 3
var minggu_tunggak: = 0
var diusir: = false





const JAM_TAGIH_SEWA: = 18 * 60
var sewa_selesai_hari: = 0

func perlu_tagih_sewa() -> bool:
	return hari_sewa() and sewa_selesai_hari != hari and menit >= JAM_TAGIH_SEWA


var _jendela_sewa: Node = null


func _cek_tagihan_sewa() -> void :
	if _jendela_sewa != null and is_instance_valid(_jendela_sewa):
		return
	if not perlu_tagih_sewa() or get_tree().paused:
		return
	if tagihan_sewa() <= 0:
		_bayar_sewa()
		data_berubah.emit()
		return
	var adegan: = get_tree().current_scene
	if adegan == null or not (adegan.has_method("tampilkan_pesan")):
		return

	if ("dialog_aktif" in adegan and adegan.dialog_aktif) or ("sibuk" in adegan and adegan.sibuk):
		return
	var j: CanvasLayer = preload("res://scripts/tagihan_sewa.gd").new()
	j.adegan = adegan
	_jendela_sewa = j
	adegan.add_child(j)


func tagihan_sewa() -> int:
	return sisa_sewa_minggu_ini() + tunggakan_sewa






const PILIHAN_CICIL_SEWA: = [25000, 50000]
var sewa_cicil: = 0


func sisa_sewa_minggu_ini() -> int:
	return maxi(sewa_per_minggu() - sewa_cicil, 0)



func sisa_cicil_sewa() -> int:
	return tunggakan_sewa + sisa_sewa_minggu_ini()


func cicil_sewa(jumlah: int) -> String:
	if kios_milik:
		return "Kios sudah milik sendiri, tidak ada sewa lagi."
	var sisa: = sisa_cicil_sewa()
	if sisa <= 0:
		return "Sewa minggu ini sudah lunas dicicil."
	jumlah = mini(jumlah, sisa)
	if uang + saldo_digital < jumlah:
		return "Uang tidak cukup untuk mencicil %s." % format_rupiah(jumlah)
	_tarik_qris_untuk(jumlah, "Ambil saldo QRIS untuk cicil sewa")
	uang -= jumlah
	var ke_tunggakan: = mini(jumlah, tunggakan_sewa)
	if ke_tunggakan > 0:
		tunggakan_sewa -= ke_tunggakan
		catat_transaksi("Cicil tunggakan sewa", - ke_tunggakan)
		if tunggakan_sewa <= 0:
			tunggakan_sewa = 0
			minggu_tunggak = 0
			tambah_chat(nama_pemilik_kios(), "Tunggakan sewa sudah lunas, Pak Misran. Terima kasih.", false, "teks", "juragan")
	var ke_minggu_ini: = jumlah - ke_tunggakan
	if ke_minggu_ini > 0:
		sewa_cicil += ke_minggu_ini
		catat_transaksi("Cicil sewa kios", - ke_minggu_ini)
	if ke_minggu_ini > 0 and sisa_sewa_minggu_ini() <= 0:
		tambah_chat(nama_pemilik_kios(), "Sewa minggu ini sudah lunas dicicil, Pak Misran. Terima kasih, rajin sekali.", false, "teks", "juragan")
	data_berubah.emit()
	simpan()
	return ""


func bayar_sewa_sekarang() -> String:

	if uang + saldo_digital < tagihan_sewa():
		return "Uang di laci dan saldo QRIS baru %s, kurang %s." % [format_rupiah(uang + saldo_digital), format_rupiah(tagihan_sewa() - uang - saldo_digital)]
	_bayar_sewa()
	data_berubah.emit()
	simpan()
	return ""


func tunda_sewa() -> void :
	_bayar_sewa(true)
	bangkrut = bangkrut or diusir
	data_berubah.emit()
	simpan()



func denda_jika_tunda() -> int:
	if minggu_tunggak + 1 > MAKS_DENDA_SEWA:
		return 0
	return int(ceil(tagihan_sewa() * float(cerita["sewa"].get("denda_persen", 10)) / 100.0 / 1000.0)) * 1000


func _bayar_sewa(tunda: = false) -> void :
	if not hari_sewa() or sewa_selesai_hari == hari:
		return

	var tagihan: = sisa_sewa_minggu_ini() + tunggakan_sewa
	var dicicil: = mini(sewa_cicil, sewa_per_minggu())
	sewa_selesai_hari = hari
	sewa_dibayar_hari = 0
	denda_sewa_hari = 0
	if sewa_cicil > dicicil:
		uang += sewa_cicil - dicicil
		catat_transaksi("Kelebihan cicilan sewa dikembalikan", sewa_cicil - dicicil)
	sewa_cicil = 0
	sewa_kunci = {}
	if not tunda:
		_tarik_qris_untuk(tagihan, "Ambil saldo QRIS untuk sewa kios")
	var bayar: = 0 if tunda else clampi(uang, 0, tagihan)
	uang -= bayar
	sewa_dibayar_hari = bayar
	var sisa: = tagihan - bayar
	if bayar > 0:
		catat_transaksi("Sewa kios minggu ini", - bayar)
	if sisa > 0:
		minggu_tunggak += 1
		if minggu_tunggak <= MAKS_DENDA_SEWA:
			denda_sewa_hari = int(ceil(sisa * float(cerita["sewa"].get("denda_persen", 10)) / 100.0 / 1000.0)) * 1000
		tunggakan_sewa = sisa + denda_sewa_hari
		if minggu_tunggak >= MINGGU_DIUSIR:
			diusir = true
			tambah_chat(nama_pemilik_kios(), "Pak Misran, sudah tiga minggu sewa tidak dibayar. Mohon maaf, kiosnya saya ambil kembali.", true, "teks", "juragan")
		elif minggu_tunggak == MINGGU_DIUSIR - 1 and _balas_budi_sewa():
			pass
		elif minggu_tunggak == MINGGU_DIUSIR - 1:
			tambah_chat(nama_pemilik_kios(), "Pak Misran, sewa sudah dua minggu menunggak (%s). Kalau Minggu depan belum lunas, dengan berat hati kiosnya saya ambil kembali." % format_rupiah(tunggakan_sewa), true, "teks", "juragan")
		elif tunda:
			tambah_chat(nama_pemilik_kios(), "Baik, Pak Misran. Sewa %s saya catat dulu, tanpa denda. Minggu depan saya tagih lagi bersama sewa minggu depan. Kalau ada rezeki, bisa dicicil atau dilunasi lewat Warga Bank." % format_rupiah(sisa), true, "teks", "juragan")
		else:
			tambah_chat(nama_pemilik_kios(), "Pak Misran, sewa minggu ini kurang %s. Saya catat dulu, tanpa denda, Minggu depan saya tagih lagi. Tolong dilunasi ya, Pak." % format_rupiah(sisa), true, "teks", "juragan")
	else:
		tunggakan_sewa = 0
		minggu_tunggak = 0
		if bayar > 0:
			tambah_chat(nama_pemilik_kios(), "Sewa minggu ini %s sudah saya terima. Terima kasih, Pak Misran." % format_rupiah(bayar + dicicil), false, "teks", "juragan")



func perkiraan_biaya_harian() -> int:
	var n: = int(BIAYA_HARIAN.get(mode, 10000))
	for id in upgrade_dimiliki:
		n += int(data_upgrade(id).get("biaya_hari", 0))
	return n



func uang_wajib_sisa() -> int:
	var n: = perkiraan_biaya_harian()
	if hari_sewa() and sewa_selesai_hari != hari:
		n += tagihan_sewa()
	return n



func peringatan_kirim(jumlah: int) -> String:
	var sisa: = uang - jumlah
	var wajib: = uang_wajib_sisa()
	if jumlah > 0 and sisa < wajib:
		return "Awas! Sisakan minimal %s untuk biaya harian%s. Uang minus 3 hari berturut-turut = warung bangkrut." % [
			format_rupiah(wajib), " dan sewa malam ini" if hari_sewa() else ""]
	if jumlah > 0 and sisa < wajib + 20000:
		return "Hati-hati: sisa uang untuk belanja stok tinggal %s." % format_rupiah(sisa - wajib)
	return ""




const PILIHAN_INFAK: = [20000, 50000, 100000]


const BERKAH_INFAK: = {20000: 0.05, 50000: 0.1, 100000: 0.15}
var infak_hari: = 0
var infak_jumlah: = 0



func pengali_sial() -> float:
	if infak_jumlah <= 0 or hari < infak_hari or hari - infak_hari > 1:
		return 1.0
	return 1.0 - float(BERKAH_INFAK.get(infak_jumlah, 0.0))


func boleh_infak() -> bool:
	return infak_hari != hari


func infak(jumlah: int) -> String:
	if not boleh_infak():
		return "Hari ini Pak Misran sudah berinfak. Besok lagi, ya."
	if uang < jumlah:
		return "Uang di laci tidak cukup."
	uang -= jumlah
	infak_hari = hari
	infak_jumlah = jumlah
	catat_transaksi("Infak ke masjid", - jumlah)
	ulasan_warga(5, "Pak Misran rajin infak ke masjid. Semoga warungnya makin berkah.", "Haji Doni")
	tambah_chat("Haji Doni", "Jazakallah khair, Pak Misran. Infak %s sudah kami terima untuk masjid. Semoga warungnya makin berkah." % format_rupiah(jumlah), true, "teks", "rt")
	data_berubah.emit()
	return ""





const MENU_JAJAN: = [
	["gorengan", "Gorengan", 2000, 4.0, 5.0], 
	["teh_manis", "Teh manis hangat", 3000, 6.0, 5.0], 
	["kue", "Kue lapis", 5000, 9.0, 5.0], 
	["lontong", "Lontong sayur", 7500, 12.0, 10.0], 
	["pecel", "Nasi pecel", 10000, 16.0, 15.0], 
]
var jajan_hari: = 0
var jajan_dibeli: = {}

func boleh_jajan(id: = "") -> bool:
	if id == "":
		for m in MENU_JAJAN:
			if int(jajan_dibeli.get(String(m[0]), -1)) != hari:
				return true
		return false
	return int(jajan_dibeli.get(id, -1)) != hari



func alasan_tidak_bisa_jajan(id: = "") -> String:
	if ramadan() and menit < JAM_MAGHRIB:
		return "Pak Misran sedang puasa. Jajannya nanti sesudah adzan Maghrib (18.00)."
	if not boleh_jajan(id):
		return "Sudah dibeli hari ini. Besok lagi, ya." if id != "" else "Pak Misran sudah jajan semuanya hari ini. Besok lagi, ya."
	if energi >= 99.0:
		return "Pak Misran masih segar, belum perlu jajan."
	return ""


func beli_jajan(id: String) -> String:
	var alasan: = alasan_tidak_bisa_jajan(id)
	if alasan != "":
		return alasan
	for m in MENU_JAJAN:
		if m[0] != id:
			continue
		if uang < int(m[2]):
			return "Uang tidak cukup untuk beli %s." % String(m[1]).to_lower()
		uang -= int(m[2])
		catat_transaksi("Jajan %s di pasar" % String(m[1]).to_lower(), - int(m[2]))
		jajan_dibeli[id] = hari
		jajan_hari = hari
		energi = minf(energi + float(m[3]), 100.0)
		if not lelah():
			lelah_diingatkan = false
		majukan_waktu(float(m[4]))
		data_berubah.emit()
		return ""
	return "Menu tidak dikenal."









const JEDA_BALAS_BUDI: = 14
const PATUNGAN_PER_ORANG: = 0.15
const PREMAN_PER_ORANG: = 0.15
const PREMAN_MIN_MENIT: = 40
const BUKAN_PENOLONG: = ["fariz", "agus", "preman"]
var balas_budi_hari: = {}



func warga_penolong() -> Array:
	var hasil: Array = []
	var ev: = data_event()
	for id in cerita_warga:
		if hasil_event(String(id)) != "tolong" or not ev.has(id):
			continue
		var tahap: Array = ev[id].get("tahap", [])
		if tahap.is_empty():
			continue
		var tipe: = String((tahap[0] as Dictionary).get("npc", ""))
		if tipe == "" or tipe in BUKAN_PENOLONG or tipe in hasil or not daftar_warga().has(tipe):
			continue
		hasil.append(tipe)
	return hasil


func _boleh_balas_budi(momen: String) -> bool:
	return hari - int(balas_budi_hari.get(momen, -999)) >= JEDA_BALAS_BUDI




func _nama_penolong(daftar: Array, maks: = 3, pembicara: = "") -> String:
	var acak: = daftar.duplicate()
	acak.shuffle()
	if pembicara != "" and pembicara in acak:
		acak.erase(pembicara)
		acak.push_front(pembicara)
	var nama: Array = acak.slice(0, maks).map( func(t): return "saya" if t == pembicara else String(daftar_warga()[t]))
	var teks: = String(nama[0])
	if nama.size() == 2:
		teks = "%s dan %s" % [nama[0], nama[1]]
	elif nama.size() >= 3:
		teks = "%s, %s, dan %s" % [nama[0], nama[1], nama[2]]
	if daftar.size() > maks:
		teks += " (dan warga lainnya)"
	return teks





const MAKS_BANTU_SEWA: = 2
const JEDA_BANTU_SEWA: = 60
const BAGIAN_MAKS_BANTU_SEWA: = 0.5

func sisa_bantuan_sewa() -> int:
	return maxi(MAKS_BANTU_SEWA - int(balas_budi_hari.get("sewa_kali", 0)), 0)



func _balas_budi_sewa() -> bool:
	var penolong: = warga_penolong()
	if penolong.is_empty() or tunggakan_sewa <= 0 or sisa_bantuan_sewa() <= 0\
	or hari - int(balas_budi_hari.get("sewa", -999)) < JEDA_BANTU_SEWA:
		return false
	balas_budi_hari["sewa"] = hari
	balas_budi_hari["sewa_kali"] = int(balas_budi_hari.get("sewa_kali", 0)) + 1
	var bagian: = minf(BAGIAN_MAKS_BANTU_SEWA, PATUNGAN_PER_ORANG * penolong.size())
	var patungan: = mini(tunggakan_sewa, int(ceil(tunggakan_sewa * bagian / 1000.0)) * 1000)
	tunggakan_sewa -= patungan
	var nama: = _nama_penolong(penolong, 3, "pak_rt")
	if tunggakan_sewa <= 0:
		tunggakan_sewa = 0
		minggu_tunggak = 0
		tambah_chat("Pak RT", "Pak Misran, kami dengar sewa kiosnya menunggak. %s ikut patungan, %s sudah kami serahkan ke %s. Lunas, Pak. Dulu Bapak menolong kami, sekarang gantian." % [nama, format_rupiah(patungan), nama_pemilik_kios()], true, "teks", "rt")
		tambah_chat(nama_pemilik_kios(), "Pak Misran, tunggakan sewa sudah dilunasi warga lewat Pak RT. Banyak yang sayang sama Bapak. Kiosnya aman.", true, "teks", "juragan")
	else:
		minggu_tunggak = MINGGU_DIUSIR - 2
		tambah_chat("Pak RT", "Pak Misran, %s ikut patungan %s untuk tunggakan sewa kios. Belum lunas, tapi %s mau memberi waktu seminggu lagi. Semangat, Pak!" % [nama, format_rupiah(patungan), nama_pemilik_kios()], true, "teks", "rt")
		if sisa_bantuan_sewa() <= 0:
			tambah_chat("Pak RT", "Tapi maaf, Pak, ini terakhir kali warga bisa patungan. Warga juga sedang susah. Mulai sekarang sewanya harus Bapak usahakan sendiri, ya.", true, "teks", "rt")
		tambah_chat(nama_pemilik_kios(), "Pak Misran, warga sudah patungan %s. Sisa tunggakan %s, saya tunggu sampai Minggu depan lagi." % [format_rupiah(patungan), format_rupiah(tunggakan_sewa)], true, "teks", "juragan")
	return true



func _balas_budi_preman() -> void :
	var penolong: = warga_penolong()
	if penolong.is_empty() or not _boleh_balas_budi("preman"):
		return
	balas_budi_hari["preman"] = hari
	var lama: = int(kejadian.get("lama", 180))
	kejadian["lama"] = maxi(PREMAN_MIN_MENIT, int(lama * maxf(0.0, 1.0 - PREMAN_PER_ORANG * penolong.size())))
	kejadian["diusir_warga"] = _nama_penolong(penolong)
	tambah_chat("Pak RT", "Pak Misran, ada preman nongkrong di depan warung? Tunggu, kami ke sana sebentar lagi.", true, "teks", "rt")




func tutup_hari() -> void :
	papan.segarkan()

	if not kejadian.is_empty():
		kejadian["status"] = "selesai"


	biaya_harian_hari = 0 if sedang_sakit else perkiraan_biaya_harian()
	uang -= biaya_harian_hari
	if biaya_harian_hari > 0:
		catat_transaksi("Biaya harian (listrik, iuran, perlengkapan)", - biaya_harian_hari)
	if omzet_hari > 0:
		catat_transaksi("Penjualan hari ini", omzet_hari)
	uang_palsu_hari = _cek_uang_palsu()
	_potong_utang_dokter()

	if uang < 0:


		if not lindungi_hari_minus:
			hari_minus += 1
	else:
		hari_minus = 0
	bangkrut = hari_minus >= int(BATAS_HARI_MINUS.get(mode, 3)) or diusir

	if jenis_khusus() == "hari_sempurna" and pelanggan_batal_hari == 0:
		progres["khusus"] = maxi(progres["khusus"], pelanggan_dilayani_hari)
	_cek_tugas()
	data_berubah.emit()






const FOLDER_SUARA: = "res://assets/suara/"
const VOLUME_MUSIK_DB: = -6.0

const MULAI_MUSIK: = {}


const VOLUME_MUSIK: = {"latar": -8.0}


const VOLUME_AMBIENCE_DB: = 4.0
var _ambience: AudioStreamPlayer
var _tween_ambience: Tween
var _ambience_nyala: = false


const VOLUME_AMBIENCE_SIANG_DB: = 0.0
var _ambience_siang: AudioStreamPlayer
var _tween_ambience_siang: Tween
var _ambience_siang_nyala: = false
var _bunyi: = {}
var _pemutar: Array[AudioStreamPlayer] = []
var _musik: AudioStreamPlayer
var _pemutar_klik: AudioStreamPlayer
var _pemutar_langkah: AudioStreamPlayer
var _suara_langkah: Array = []
const VOLUME_LANGKAH_JALAN: = -14.0
const VOLUME_LANGKAH_LARI: = -9.0
var _suara_langkah_basah: Array = []
const VOLUME_LANGKAH_BASAH: = 5.0


func _siapkan_suara() -> void :



	_bunyi["koin"] = _buat_denting_kecil()

	_bunyi["kresek"] = _buat_kresek()
	for ext in ["ogg", "wav", "mp3"]:
		if ResourceLoader.exists(FOLDER_SUARA + "kresek." + ext):
			_bunyi["kresek"] = load(FOLDER_SUARA + "kresek." + ext)
			break


	_bunyi["klik"] = _buat_tuk()

	_bunyi["akrab_naik"] = _buat_nada([[659, 0.0, 0.1, 0.3], [784, 0.07, 0.1, 0.3], [988, 0.14, 0.1, 0.3], [1319, 0.21, 0.35, 0.35]])
	_bunyi["bel"] = _buat_nada([[988, 0.0, 0.35, 0.3], [1245, 0.12, 0.4, 0.25]])
	_bunyi["salah"] = _buat_nada([[220, 0.0, 0.18, 0.4], [185, 0.12, 0.22, 0.4]])
	_bunyi["kesal"] = _buat_nada([[330, 0.0, 0.15, 0.35], [262, 0.13, 0.15, 0.35], [196, 0.26, 0.3, 0.35]])
	_bunyi["kurir"] = _buat_nada([[523, 0.0, 0.12, 0.35], [659, 0.15, 0.12, 0.35]])


	_bunyi["notif"] = _buat_nada([[988, 0.0, 0.12, 0.2], [1319, 0.11, 0.22, 0.18]])
	_bunyi["hadiah"] = _buat_nada([[523, 0.0, 0.14, 0.35], [659, 0.1, 0.14, 0.35], [784, 0.2, 0.14, 0.35], [1047, 0.3, 0.4, 0.4]])
	_bunyi["buka"] = _buat_nada([[659, 0.0, 0.2, 0.3], [880, 0.15, 0.35, 0.3]])
	_bunyi["tutup"] = _buat_nada([[880, 0.0, 0.2, 0.3], [659, 0.15, 0.2, 0.3], [523, 0.3, 0.45, 0.3]])

	_bunyi["langkah"] = _buat_langkah()

	_bunyi["listrik_padam"] = _buat_dengung(true)
	_bunyi["listrik_nyala"] = _buat_dengung(false)
	_bunyi["petir"] = _buat_petir()

	_bunyi["ambulans"] = _buat_sirene()
	for nama in _bunyi.keys():
		for ext in ["ogg", "wav", "mp3"]:
			if ResourceLoader.exists(FOLDER_SUARA + nama + "." + ext):
				_bunyi[nama] = load(FOLDER_SUARA + nama + "." + ext)
				break
	for i in 6:
		var p: = AudioStreamPlayer.new()
		add_child(p)
		_pemutar.append(p)
	_musik = AudioStreamPlayer.new()
	_musik.volume_db = VOLUME_MUSIK_DB
	_musik.bus = "Musik"
	add_child(_musik)
	_ambience = AudioStreamPlayer.new()
	_ambience.bus = "Sekitar"
	add_child(_ambience)
	for ext in ["ogg", "mp3", "wav"]:
		if ResourceLoader.exists(FOLDER_SUARA + "ambience_malam." + ext):
			_ambience.stream = load(FOLDER_SUARA + "ambience_malam." + ext)
			if "loop" in _ambience.stream:
				_ambience.stream.loop = true
			break
	_ambience_siang = AudioStreamPlayer.new()
	_ambience_siang.bus = "Sekitar"
	add_child(_ambience_siang)

	for ext in ["ogg", "mp3", "wav"]:
		if ResourceLoader.exists(FOLDER_SUARA + "ambience_siang." + ext):
			_ambience_siang.stream = load(FOLDER_SUARA + "ambience_siang." + ext)
			if "loop" in _ambience_siang.stream:
				_ambience_siang.stream.loop = true
			break

	putar_musik("menu")

	_pemutar_klik = AudioStreamPlayer.new()
	_pemutar_klik.stream = _bunyi["klik"]
	_pemutar_klik.max_polyphony = 3
	add_child(_pemutar_klik)
	_pemutar_langkah = AudioStreamPlayer.new()
	_pemutar_langkah.stream = _bunyi["langkah"]
	_pemutar_langkah.volume_db = -15.0
	_pemutar_langkah.max_polyphony = 2
	add_child(_pemutar_langkah)

	for i in range(1, 10):
		var file: = FOLDER_SUARA + "langkah_%d.wav" % i
		if ResourceLoader.exists(file):
			_suara_langkah.append(load(file))

		var basah: = FOLDER_SUARA + "langkah_basah_%d.wav" % i
		if ResourceLoader.exists(basah):
			_suara_langkah_basah.append(load(basah))

	get_tree().node_added.connect(_pasang_klik)


func _pasang_klik(n: Node) -> void :

	if n is BaseButton and not n.has_meta("klik"):
		n.set_meta("klik", true)


		var b: = n as BaseButton
		b.button_down.connect( func() -> void :
			if b.disabled or _dalam_gulir(b):
				return
			klik()
			_tekan_tombol(b, true))
		b.button_up.connect( func() -> void : _tekan_tombol(b, false))
		b.pressed.connect( func() -> void :
			if _dalam_gulir(b):
				klik())
	elif n is Slider and not n.has_meta("klik"):
		n.set_meta("klik", true)
		n.drag_ended.connect( func(_berubah: bool): klik())


const SKALA_TEKAN: = 0.92


func _dalam_gulir(c: Node) -> bool:
	var p: = c.get_parent()
	while p != null:
		if p is ScrollContainer:
			return true
		p = p.get_parent()
	return false




func _tekan_tombol(b: BaseButton, ditekan: bool) -> void :
	if not is_instance_valid(b) or not b.is_inside_tree() or b.has_meta("tanpa_pantul"):
		return
	var lama: Variant = b.get_meta("_tw_tekan") if b.has_meta("_tw_tekan") else null
	if lama is Tween and (lama as Tween).is_valid():
		(lama as Tween).kill()
	b.pivot_offset = b.size / 2.0
	var tw: = b.create_tween()
	if ditekan:
		tw.tween_property(b, "scale", Vector2.ONE * SKALA_TEKAN, 0.06).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	else:
		tw.tween_property(b, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	b.set_meta("_tw_tekan", tw)




func langkah_kaki(lari: = false, luar: = true) -> void :
	if _pemutar_langkah == null:
		return
	if luar and tanah_basah() and not _suara_langkah_basah.is_empty():
		_pemutar_langkah.stream = _suara_langkah_basah.pick_random()
		_pemutar_langkah.pitch_scale = randf_range(0.95, 1.05) * (1.0 if lari else 0.92)
		_pemutar_langkah.volume_db = (VOLUME_LANGKAH_LARI if lari else VOLUME_LANGKAH_JALAN) + VOLUME_LANGKAH_BASAH
	elif not _suara_langkah.is_empty():

		_pemutar_langkah.stream = _suara_langkah.pick_random()
		_pemutar_langkah.pitch_scale = randf_range(0.95, 1.05) * (1.0 if lari else 0.9)
		_pemutar_langkah.volume_db = VOLUME_LANGKAH_LARI if lari else VOLUME_LANGKAH_JALAN
	else:
		_pemutar_langkah.pitch_scale = randf_range(0.88, 1.08) * (1.08 if lari else 1.0)
		_pemutar_langkah.volume_db = -12.5 if lari else -15.0
	_pemutar_langkah.play()


func _buat_langkah() -> AudioStreamWAV:
	var laju: = 22050
	var jumlah: = int(0.12 * laju)
	var sampel: = PackedFloat32Array()
	sampel.resize(jumlah)
	var desis: = 0.0
	for i in jumlah:
		var t: = float(i) / laju

		var dentum: = sin(TAU * (95.0 - t * 300.0) * t) * exp( - t * 45.0)

		desis = desis * 0.82 + randf_range(-1.0, 1.0) * 0.18
		sampel[i] = (dentum * 0.8 + desis * 0.9 * exp( - t * 60.0)) * minf(1.0, t * 800.0)
	var data: = PackedByteArray()
	data.resize(jumlah * 2)
	for i in jumlah:
		data.encode_s16(i * 2, int(clampf(sampel[i], -1.0, 1.0) * 32767.0 * 0.7))
	var wav: = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = laju
	wav.data = data
	return wav



func _buat_dengung(padam: bool) -> AudioStreamWAV:
	var laju: = 22050
	var panjang: = 0.9
	var jumlah: = int(panjang * laju)
	var sampel: = PackedFloat32Array()
	sampel.resize(jumlah)
	for i in jumlah:
		var t: = float(i) / laju
		var k: = t / panjang
		var turun: = 1.0 - k if padam else k
		var frek: = 50.0 + 70.0 * turun
		var amp: = (1.0 - k) * 0.5 if padam else minf(1.0, k * 3.0) * (1.0 - k * 0.6) * 0.45
		sampel[i] = (sin(TAU * frek * t) + 0.5 * sin(TAU * frek * 2.0 * t) + 0.25 * sin(TAU * frek * 3.0 * t)) * amp * 0.6

	for i in int(0.015 * laju):
		sampel[i] += randf_range(-1.0, 1.0) * 0.7 * (1.0 - float(i) / (0.015 * laju))
	var data: = PackedByteArray()
	data.resize(jumlah * 2)
	for i in jumlah:
		data.encode_s16(i * 2, int(clampf(sampel[i], -1.0, 1.0) * 30000.0))
	var wav: = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = laju
	wav.data = data
	return wav



func _buat_petir() -> AudioStreamWAV:
	var laju: = 22050
	var panjang: = 2.4
	var jumlah: = int(panjang * laju)
	var sampel: = PackedFloat32Array()
	sampel.resize(jumlah)
	var rendah: = 0.0
	var lebih_rendah: = 0.0
	for i in jumlah:
		var t: = float(i) / laju
		var desis: = randf_range(-1.0, 1.0)

		rendah = rendah * 0.97 + desis * 0.03
		lebih_rendah = lebih_rendah * 0.95 + rendah * 0.05
		var retak: = desis * exp( - t * 18.0) * 0.6
		var gemuruh: = lebih_rendah * 28.0 * minf(1.0, t * 6.0) * exp( - t * 1.6) * (0.7 + 0.3 * sin(TAU * 3.0 * t))
		sampel[i] = retak + gemuruh
	var data: = PackedByteArray()
	data.resize(jumlah * 2)
	for i in jumlah:
		data.encode_s16(i * 2, int(clampf(sampel[i], -1.0, 1.0) * 30000.0))
	var wav: = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = laju
	wav.data = data
	return wav





func _buat_sirene() -> AudioStreamWAV:
	var laju: = 22050
	var panjang: = 4.5
	var jumlah: = int(panjang * laju)
	var sampel: = PackedFloat32Array()
	sampel.resize(jumlah)
	var fase: = 0.0
	for i in jumlah:
		var t: = float(i) / laju
		var frek: = 960.0 if fmod(t, 0.9) < 0.45 else 760.0
		fase += TAU * frek / laju
		var keras: = minf(1.0, 0.25 + t / panjang) * minf(1.0, (panjang - t) * 3.0)
		sampel[i] = (sin(fase) * 0.7 + sin(fase * 2.0) * 0.2) * keras * 0.5
	return _wav_dari(sampel, laju)


func _wav_dari(sampel: PackedFloat32Array, laju: int) -> AudioStreamWAV:
	var data: = PackedByteArray()
	data.resize(sampel.size() * 2)
	for i in sampel.size():
		data.encode_s16(i * 2, int(clampf(sampel[i], -1.0, 1.0) * 30000.0))
	var wav: = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = laju
	wav.data = data
	return wav
func klik() -> void :
	if _pemutar_klik != null:

		_pemutar_klik.pitch_scale = randf_range(0.9, 1.1)
		_pemutar_klik.volume_db = randf_range(-3.0, -1.0)
		_pemutar_klik.play()




func putar_adzan() -> void :
	bunyi("adzan", -2.0)
	if _musik == null or not _musik.playing:
		return
	var normal: = _musik.volume_db
	var tw: = create_tween()
	tw.tween_property(_musik, "volume_db", normal - 15.0, 1.0)
	tw.tween_interval(9.0)
	tw.tween_property(_musik, "volume_db", normal, 1.5)




func bunyi(nama: String, keras_db: = 0.0) -> void :
	if not _bunyi.has(nama):
		for ext in ["ogg", "wav", "mp3"]:
			if ResourceLoader.exists(FOLDER_SUARA + nama + "." + ext):
				_bunyi[nama] = load(FOLDER_SUARA + nama + "." + ext)
				break
	if not _bunyi.has(nama):
		return
	var jalur_bus: StringName = &"Sekitar" if nama in BUNYI_SEKITAR else &"Suara"
	for p in _pemutar:
		if not p.playing:
			p.stream = _bunyi[nama]
			p.bus = jalur_bus
			p.volume_db = keras_db
			p.play()
			return

	var tertua: = _pemutar[0]
	for p in _pemutar:
		if p.get_playback_position() > tertua.get_playback_position():
			tertua = p
	tertua.stream = _bunyi[nama]
	tertua.bus = jalur_bus
	tertua.volume_db = keras_db
	tertua.play()







var _musik_sekarang: = ""
var _tween_musik: Tween
var _daftar_lagu: Array[AudioStream] = []
var _lagu_ke: = 0


func putar_musik(jenis: String, lama_pudar: = 0.6) -> void :
	if jenis == _musik_sekarang or _musik == null:
		return
	_atur_ambience(jenis == "malam", lama_pudar)
	_atur_ambience_siang(jenis == "latar", lama_pudar)
	var daftar: = _cari_lagu(jenis)
	if daftar.is_empty():

		if jenis == "malam":
			_musik_sekarang = jenis
			if _tween_musik != null:
				_tween_musik.kill()
			_tween_musik = create_tween()
			_tween_musik.tween_property(_musik, "volume_db", -60.0, lama_pudar)
			_tween_musik.tween_callback(_musik.stop)
		return

	for lagu in daftar:
		if "loop" in lagu:
			lagu.loop = daftar.size() == 1
		if "loop_offset" in lagu:
			lagu.loop_offset = float(MULAI_MUSIK.get(jenis, 0.0))
	if not _musik.finished.is_connected(_lagu_berikutnya):
		_musik.finished.connect(_lagu_berikutnya)
	_musik_sekarang = jenis
	_daftar_lagu = daftar
	_lagu_ke = 0
	if _tween_musik != null:
		_tween_musik.kill()
	_tween_musik = create_tween()
	if _musik.playing:
		_tween_musik.tween_property(_musik, "volume_db", -40.0, lama_pudar)
	_tween_musik.tween_callback( func():
		_musik.stream = _daftar_lagu[0]
		_musik.volume_db = -40.0
		_musik.play(float(MULAI_MUSIK.get(jenis, 0.0))))
	_tween_musik.tween_property(_musik, "volume_db", float(VOLUME_MUSIK.get(jenis, VOLUME_MUSIK_DB)), maxf(0.8, lama_pudar * 0.6))


func hentikan_musik() -> void :
	if _tween_musik != null:
		_tween_musik.kill()
	if _musik != null:
		_musik.stop()
	_atur_ambience(false, 0.3)
	_atur_ambience_siang(false, 0.3)
	_musik_sekarang = ""



func _atur_ambience(nyala: bool, lama_pudar: float) -> void :
	if _ambience == null or _ambience.stream == null or nyala == _ambience_nyala:
		return
	_ambience_nyala = nyala
	if _tween_ambience != null:
		_tween_ambience.kill()
	_tween_ambience = create_tween()
	if nyala:
		if not _ambience.playing:
			_ambience.volume_db = -40.0
			_ambience.play()
		_tween_ambience.tween_property(_ambience, "volume_db", VOLUME_AMBIENCE_DB, maxf(1.0, lama_pudar))
	else:
		_tween_ambience.tween_property(_ambience, "volume_db", -60.0, maxf(0.3, lama_pudar))
		_tween_ambience.tween_callback(_ambience.stop)



func _atur_ambience_siang(nyala: bool, lama_pudar: float) -> void :
	if _ambience_siang == null or _ambience_siang.stream == null or nyala == _ambience_siang_nyala:
		return
	_ambience_siang_nyala = nyala
	if _tween_ambience_siang != null:
		_tween_ambience_siang.kill()
	_tween_ambience_siang = create_tween()
	if nyala:
		if not _ambience_siang.playing:
			_ambience_siang.volume_db = -40.0
			_ambience_siang.play()
		_tween_ambience_siang.tween_property(_ambience_siang, "volume_db", VOLUME_AMBIENCE_SIANG_DB, maxf(1.0, lama_pudar))
	else:
		_tween_ambience_siang.tween_property(_ambience_siang, "volume_db", -60.0, maxf(0.3, lama_pudar))
		_tween_ambience_siang.tween_callback(_ambience_siang.stop)


func _cari_lagu(jenis: String) -> Array[AudioStream]:
	var hasil: Array[AudioStream] = []
	for nama in ["musik_" + jenis] + range(1, 10).map( func(i): return "musik_%s_%d" % [jenis, i]):
		for ext in ["ogg", "mp3", "wav"]:
			if ResourceLoader.exists(FOLDER_SUARA + nama + "." + ext):
				hasil.append(load(FOLDER_SUARA + nama + "." + ext))
				break
	return hasil


func _lagu_berikutnya() -> void :
	if _daftar_lagu.size() <= 1:
		return
	_lagu_ke = (_lagu_ke + 1) % _daftar_lagu.size()
	_musik.stream = _daftar_lagu[_lagu_ke]
	_musik.play()






func _buat_kresek() -> AudioStreamWAV:
	var laju: = 22050
	var jumlah: = int(0.42 * laju)
	var sampel: = PackedFloat32Array()
	sampel.resize(jumlah)

	for i in int(0.12 * laju):
		var t: = float(i) / laju
		sampel[i] += sin(TAU * (140.0 - t * 400.0) * t) * exp( - t * 38.0) * 0.55

	var lalu: = 0.0
	var amp: = 0.0
	for i in jumlah:
		var t: = float(i) / laju
		if randf() < 0.012 * exp( - t * 7.0) + 0.0015:
			amp = randf_range(0.35, 0.8) * exp( - t * 5.0)
		amp *= 0.985
		var putih: = randf_range(-1.0, 1.0)
		var tinggi: = putih - lalu
		lalu = putih
		sampel[i] += tinggi * amp * 0.45 * minf(1.0, t * 300.0)
	var data: = PackedByteArray()
	data.resize(jumlah * 2)
	for i in jumlah:
		data.encode_s16(i * 2, int(clampf(sampel[i], -1.0, 1.0) * 30000.0))
	var wav: = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = laju
	wav.data = data
	return wav







func _buat_tuk() -> AudioStreamWAV:
	var laju: = 44100
	var jumlah: = int(0.06 * laju)
	var sampel: = PackedFloat32Array()
	sampel.resize(jumlah)
	var acak: = RandomNumberGenerator.new()
	acak.seed = 11
	var rendah: = 0.0
	var rendah2: = 0.0
	var lalu: = 0.0
	for i in jumlah:
		var t: = float(i) / laju
		var putih: = acak.randf_range(-1.0, 1.0)

		rendah = rendah * 0.55 + putih * 0.45
		rendah2 = rendah2 * 0.93 + putih * 0.07
		var pita: = rendah - rendah2
		var ketuk: = pita * exp( - t * 320.0) * 0.55

		var dentum: = sin(TAU * (260.0 - t * 1500.0) * t) * exp( - t * 90.0) * 0.18
		var s: = (ketuk + dentum) * minf(1.0, t * 8000.0)

		lalu = lalu * 0.35 + s * 0.65
		sampel[i] = lalu
	return _wav_dari(sampel, laju)



func _buat_denting_kecil() -> AudioStreamWAV:
	var laju: = 22050
	var panjang: = 0.6
	var jumlah: = int(panjang * laju)
	var sampel: = PackedFloat32Array()
	sampel.resize(jumlah)
	for denting in [[0.0, 1760.0, 0.26, 7.0], [0.07, 2349.0, 0.16, 8.5]]:
		var mulai: = int(denting[0] * laju)
		for i in jumlah - mulai:
			var t: = float(i) / laju
			var amp: float = denting[2] * minf(1.0, t * 600.0) * exp( - t * denting[3])
			sampel[mulai + i] += (sin(TAU * denting[1] * t) + 0.25 * sin(TAU * denting[1] * 2.76 * t) * exp( - t * 14.0)) * amp
	return _wav_dari(sampel, laju)


func _buat_cring() -> AudioStreamWAV:
	var laju: = 22050
	var panjang: = 0.95
	var jumlah: = int(panjang * laju)
	var sampel: = PackedFloat32Array()
	sampel.resize(jumlah)

	for denting in [[0.03, 2093.0, 0.45, 9.0], [0.13, 2637.0, 0.55, 5.0]]:
		var mulai: = int(denting[0] * laju)
		for i in jumlah - mulai:
			var t: = float(i) / laju
			var amp: float = denting[2] * minf(1.0, t * 400.0) * exp( - t * denting[3])
			var nilai: = sin(TAU * denting[1] * t) + 0.5 * sin(TAU * denting[1] * 2.76 * t) * exp( - t * 6.0)\
			+ 0.25 * sin(TAU * denting[1] * 5.4 * t) * exp( - t * 12.0)
			sampel[mulai + i] += nilai * amp * 0.6

	for i in int(0.025 * laju):
		sampel[i] += randf_range(-1.0, 1.0) * 0.35 * (1.0 - float(i) / (0.025 * laju))
	var data: = PackedByteArray()
	data.resize(jumlah * 2)
	for i in jumlah:
		data.encode_s16(i * 2, int(clampf(sampel[i], -1.0, 1.0) * 30000.0))
	var wav: = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = laju
	wav.data = data
	return wav


func _buat_nada(nada: Array) -> AudioStreamWAV:
	var laju: = 22050
	var panjang: = 0.0
	for n in nada:
		panjang = maxf(panjang, n[1] + n[2])
	var jumlah: = int(panjang * laju) + 1
	var sampel: = PackedFloat32Array()
	sampel.resize(jumlah)
	for n in nada:
		var mulai: = int(n[1] * laju)
		var lama: = int(n[2] * laju)
		for i in lama:
			var t: = float(i) / laju

			var amp: float = n[3] * minf(1.0, t * 200.0) * exp( - t * 7.0 / n[2] * 0.35)
			sampel[mulai + i] += sin(TAU * n[0] * t) * amp + sin(TAU * n[0] * 2.0 * t) * amp * 0.15
	var data: = PackedByteArray()
	data.resize(jumlah * 2)
	for i in jumlah:
		data.encode_s16(i * 2, int(clampf(sampel[i], -1.0, 1.0) * 30000.0))
	var wav: = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = laju
	wav.data = data
	return wav





func pengali_keramaian() -> float:
	var ramai: = clampf(0.4 + 0.06 * (hari - 1), 0.4, 1.0)
	return 1.0 / ramai





const KERINGANAN_AWAL: = {1: Vector2(4.0, 2.0), 2: Vector2(4.0, 2.0), 3: Vector2(2.0, 1.0)}

func keringanan_awal() -> Vector2:
	if mode != "casual" or mode_latihan:
		return Vector2.ZERO
	return KERINGANAN_AWAL.get(level(), Vector2.ZERO)



func sabar_antre_dasar() -> float:
	return float(aturan()["sabar_antre"]) + keringanan_awal().x



func batas_respon(jumlah_jenis: int) -> float:
	var a: = aturan()
	return (float(a["sabar_respon"]) + keringanan_awal().y + float(a.get("respon_per_barang", 0.0)) * maxi(jumlah_jenis - 1, 0) + efek_upgrade("respon")) * pengali_respon_lelah()




func _muat_upgrade() -> void :
	var data = JSON.parse_string(FileAccess.get_file_as_string(FILE_UPGRADE))
	if typeof(data) != TYPE_DICTIONARY:
		push_error("Gagal membaca %s. Periksa penulisan file JSON-nya." % FILE_UPGRADE)
		return
	batas_efek = data.get("batas", {})
	daftar_dekorasi = data.get("dekorasi", [])
	for u in data["upgrade"]:
		u["level"] = int(u["level"])
		u["harga"] = int(u["harga"])
		daftar_upgrade.append(u)



func level() -> int:
	return tingkat + 1


func data_upgrade(id: String) -> Dictionary:
	for u in daftar_upgrade:
		if u["id"] == id:
			return u

	for u in daftar_dekorasi:
		if u["id"] == id:
			return u
	return {}


func punya_upgrade(id: String) -> bool:
	return id in upgrade_dimiliki




func status_upgrade(id: String) -> String:
	var u: = data_upgrade(id)
	if punya_upgrade(id):
		return "dimiliki"
	if level() < int(u["level"]):
		return "terkunci"
	if u.has("butuh") and not punya_upgrade(u["butuh"]):
		return "butuh"
	if uang < harga_upgrade(id):
		return "kurang_uang"
	return "bisa"




const POTONGAN_PER_IKLAN: = 0.1
const MAKS_IKLAN_UPGRADE: = 6
var iklan_upgrade: = {}
var pengali_harga_upgrade: = {}



const HARI_POTONGAN_BESAR: = 30
func potongan_iklan_upgrade() -> float:
	var d: = hari_di_level()
	if d >= MACET_MULAI_HARI:
		return 0.4
	if d >= HARI_POTONGAN_BESAR:
		return 0.3
	return POTONGAN_PER_IKLAN



const PENGALI_HARGA_UPGRADE_MIN: = 0.4

func _pengali_iklan_upgrade(id: String) -> float:
	var n: = mini(int(iklan_upgrade.get(id, 0)), MAKS_IKLAN_UPGRADE)
	return maxf(float(pengali_harga_upgrade.get(id, pow(1.0 - POTONGAN_PER_IKLAN, n))), PENGALI_HARGA_UPGRADE_MIN)


func _pengali_iklan_berikutnya(id: String) -> float:
	return maxf(_pengali_iklan_upgrade(id) * (1.0 - potongan_iklan_upgrade()), PENGALI_HARGA_UPGRADE_MIN)


func _pengali_total_upgrade(id: String, pengali_iklan: float) -> float:
	var total: = pengali_iklan


	if id in tugas_sekarang().get("upgrade", []):
		total *= faktor_macet()
	return maxf(total, PENGALI_HARGA_UPGRADE_MIN)



func potongan_iklan_untuk(id: String) -> float:
	var sekarang: = _pengali_total_upgrade(id, _pengali_iklan_upgrade(id))
	if sekarang <= 0.0:
		return 0.0
	return maxf(1.0 - _pengali_total_upgrade(id, _pengali_iklan_berikutnya(id)) / sekarang, 0.0)


func harga_upgrade(id: String) -> int:
	var dasar: = int(data_upgrade(id).get("harga", 0))
	return int(round(dasar * _pengali_total_upgrade(id, _pengali_iklan_upgrade(id)) / 1000.0)) * 1000


func boleh_iklan_upgrade(id: String) -> bool:
	var s: = status_upgrade(id)
	return (s == "bisa" or s == "kurang_uang") and int(iklan_upgrade.get(id, 0)) < MAKS_IKLAN_UPGRADE and id != "etalase" and potongan_iklan_untuk(id) > 0.001


func tambah_iklan_upgrade(id: String) -> void :
	var n: = mini(int(iklan_upgrade.get(id, 0)), MAKS_IKLAN_UPGRADE)
	pengali_harga_upgrade[id] = _pengali_iklan_berikutnya(id)
	iklan_upgrade[id] = mini(n + 1, MAKS_IKLAN_UPGRADE)
	data_berubah.emit()
	simpan()




signal iklan_selesai(berhasil: bool)
const IKLAN_CONTOH: = preload("res://scripts/iklan_contoh.gd")
var _iklan: Node = null


func _siapkan_iklan() -> void :
	if not OS.get_name() in ["Android", "iOS"]:
		return
	_iklan = load("res://scripts/iklan_unity.gd").new()
	add_child(_iklan)
	if not tanpa_iklan:
		_iklan.siapkan()




func tampilkan_iklan_selingan(akar: Node) -> void :
	if tanpa_iklan_aktif():
		return
	analitik.catat("iklan_selingan")
	if _iklan != null:
		await _iklan.tampilkan_selingan()
		return
	var layar: = IKLAN_CONTOH.new()
	layar.selingan = true
	akar.add_child(layar)
	await layar.selesai


func tonton_iklan(akar: Node) -> bool:


	if tanpa_iklan_aktif():
		await get_tree().process_frame
		iklan_selesai.emit(true)
		return true
	var berhasil: bool
	if _iklan != null:
		berhasil = await _iklan.tonton(akar)
	else:
		var layar: = IKLAN_CONTOH.new()
		akar.add_child(layar)
		berhasil = await layar.selesai
	var adegan: = get_tree().current_scene
	analitik.catat("iklan", {"ok": berhasil, "dari": String(akar.name).left(30), 
		"layar": String(adegan.name).left(30) if adegan != null else ""})
	iklan_selesai.emit(berhasil)
	return berhasil




var wajib_etalase: = false


var tutorial_langkah: = ""

var mode_latihan: = false
var sambut_asli: = false



var tutorial_awal: = false
var tutorial_penutup: = false




const TIP_DASAR: = ["layar_warung", "rekap", "stok", "misi", "kerja", "energi"]
var tip_dilihat: = {}

func tip_baru(id: String) -> bool:
	return not tip_dilihat.has(id) and not tutorial_awal and tutorial_langkah == "" and not mode_latihan


func tandai_tip(id: String) -> void :
	tip_dilihat[id] = true
	simpan_pengaturan()


func ulang_tip() -> void :
	tip_dilihat.clear()
	simpan_pengaturan()



func selesai_tutorial_awal() -> void :
	tutorial_awal = false
	tutorial_langkah = ""
	tutorial_penutup = true
	tutorial_selesai = true
	analitik.catat("tutorial_selesai")
	simpan_pengaturan()
	simpan()



func beli_upgrade(id: String) -> String:
	var u: = data_upgrade(id)
	if u.is_empty():
		return "Upgrade tidak dikenal."
	match status_upgrade(id):
		"dimiliki": return "%s sudah dimiliki." % u["nama"]
		"terkunci": return "%s terbuka di Level %d." % [u["nama"], u["level"]]
		"butuh": return "Beli %s dulu." % String(data_upgrade(u["butuh"])["nama"]).to_lower()
		"kurang_uang": return "Uang tidak cukup untuk %s (%s)." % [String(u["nama"]).to_lower(), format_rupiah(harga_upgrade(id))]
	var harga: = harga_upgrade(id)
	uang -= harga
	belanja_hari += harga
	catat_transaksi("Beli %s" % String(u["nama"]).to_lower(), - harga)
	if id == "etalase":
		var pertama: = wajib_etalase
		wajib_etalase = false
		if tutorial_langkah == "etalase":
			tutorial_langkah = "belanja"
		elif pertama and not mode_latihan:

			tutorial_langkah = "asli_belanja"
	upgrade_dimiliki.append(id)

	for b in u.get("efek", {}).get("buka_barang", []):
		if not terbuka(b):
			barang_terbuka.append(b)
			if stok.has(b):
				stok[b] += int(katalog[b]["stok_awal"])
	bunyi("hadiah")
	analitik.catat("upgrade", {"id": id, "harga": harga})
	upgrade_dibeli.emit(id)

	_cek_tugas()
	data_berubah.emit()
	simpan()
	return ""




func efek_upgrade(kunci: String, bawaan: float = 0.0) -> float:
	var hasil: = bawaan
	var ada: = false
	for id in upgrade_dimiliki:
		var efek: Dictionary = data_upgrade(id).get("efek", {})
		if not efek.has(kunci) or typeof(efek[kunci]) == TYPE_ARRAY:
			continue
		var nilai: = float(efek[kunci])
		match kunci:
			"reputasi_turun": hasil *= nilai
			"kurir": hasil = nilai if not ada else minf(hasil, nilai)
			_: hasil += nilai
		ada = true
	if batas_efek.has(kunci):
		hasil = minf(hasil, float(batas_efek[kunci]))
	return hasil




func pengali_ramai_upgrade(menit_ini: float) -> float:


	var bonus: = efek_upgrade("ramai")
	if menit_ini >= 15 * 60:
		bonus += efek_upgrade("malam")
	return 1.0 / (1.0 + bonus)


func maks_antre() -> int:
	return int(aturan()["maks_antre"]) + int(efek_upgrade("maks_antre"))






const HARI_LEBARAN: = 85
const AGUS_BONUS_SABAR: = 0.25
var agus_bantu_sampai: = 0
var ajak_rating_sudah: = false

func agus_membantu() -> bool:
	return agus_bantu_sampai > 0 and hari <= agus_bantu_sampai









const RAMADAN_MULAI: = HARI_LEBARAN - 30
const JAM_MAGHRIB: = 18 * 60
const JAM_TUTUP_RAMADAN: = 19 * 60
const BARANG_RAMADAN: = ["kurma", "sirup"]

const BARANG_TAKJIL: = ["kurma", "sirup", "teh_botol", "air_mineral", "kerupuk", "soda", "susu_kotak", "es_krim", "biskuit"]

const BARANG_MASAK: = ["sayur", "gula", "minyak_goreng", "telur", "beras", "kopi_bubuk", "mi_rebus"]

const BARANG_JAJAN_SIANG: = ["ciki", "permen", "es_krim", "air_mineral", "teh_botol", "kopi_susu", "soda", "minuman_energi", "susu_kotak", "mi_goreng", "biskuit", "kerupuk", "sachet"]
const ZAKAT_FITRAH: = 45000
const HARI_ZAKAT: = HARI_LEBARAN - 4
const PILIHAN_THR: = [100000, 200000, 300000]
const JAM_TARAWIH: = [19.5, 21.0]
var adzan_maghrib_hari: = 0
var zakat_dibayar: = false
var tarawih_hari: = 0
var thr_agus: = 0


func ramadan(h: int = -1) -> bool:
	if h < 1:
		h = hari
	return h >= RAMADAN_MULAI and h < HARI_LEBARAN



const JAM_TUTUP_KIOS_MILIK: = 24 * 60
const JAM_TUTUP_KIOS_MILIK_RONDA: = 22 * 60

func jam_wajib_tutup() -> int:
	if kios_milik:
		return JAM_TUTUP_KIOS_MILIK_RONDA if (nama_hari() == "Kamis" and ikut_ronda_jumatan()) else JAM_TUTUP_KIOS_MILIK
	return JAM_TUTUP_RAMADAN if ramadan() else JAM_WAJIB_TUTUP



func teks_jam_tutup(sebutan: = false) -> String:
	if sebutan:
		if kios_milik:
			return "jam 10 malam" if jam_wajib_tutup() == JAM_TUTUP_KIOS_MILIK_RONDA else "jam 12 malam"
		return "jam 7 malam" if ramadan() else "jam 5 sore"
	return "%02d.00" % (jam_wajib_tutup() / 60)



func alasan_wajib_tutup() -> String:
	if not kios_milik:
		return "sesuai pesan Pak Haji Rasyid"
	return "karena malam ini Pak Misran ronda" if jam_wajib_tutup() == JAM_TUTUP_KIOS_MILIK_RONDA else "sudah larut, saatnya Pak Misran istirahat"



func sedang_puasa() -> bool:
	return ramadan() and menit < JAM_MAGHRIB




func pengali_barang_ramadan(id: String) -> float:
	if not ramadan():
		return 0.25 if id in BARANG_RAMADAN else 1.0
	var jam: = menit / 60.0
	var p: = 1.0
	if jam < 11.0 and id in BARANG_MASAK:
		p *= 1.8
	if jam < 15.0 and id in BARANG_JAJAN_SIANG:
		p *= 0.3
	if jam >= 15.0 and id in BARANG_TAKJIL:
		p *= 1.6
	return p



func borong_takjil(id: String) -> bool:
	return ramadan() and menit >= 15 * 60 and id in BARANG_TAKJIL and randf() < 0.3




const ISTIRAHAT_PUASA: = ["buka", "Buka puasa", [["kurma", 30.0], ["sirup", 26.0], ["teh_botol", 24.0], ["air_mineral", 20.0], ["", 16.0]], 20.0]

func pilihan_istirahat() -> Array:
	return [ISTIRAHAT_PUASA] if ramadan() else ISTIRAHAT




func _cek_barang_ramadan(kabari: bool) -> void :
	if hari < RAMADAN_MULAI:
		return
	var baru: Array = BARANG_RAMADAN.filter( func(id): return katalog.has(id) and not terbuka(id))
	if baru.is_empty():
		return
	_buka_barang(baru)
	if kabari:
		tambah_chat("Sales Grosir", "Marhaban ya Ramadan, Pak Misran! Mulai hari ini saya titipkan sirup dan kurma, barang yang paling dicari buat buka puasa. Stok awalnya sudah saya kirim ke warung ya, Pak.", true, "teks", "sales")



func _cek_maghrib() -> void :
	if not ramadan() or adzan_maghrib_hari == hari or menit < JAM_MAGHRIB or menit >= JAM_MALAM_LELAH:
		return
	adzan_maghrib_hari = hari
	putar_adzan()
	var adegan: = get_tree().current_scene
	if adegan != null and adegan.has_method("tampilkan_pesan"):
		adegan.tampilkan_pesan("Adzan Maghrib berkumandang. Waktunya berbuka puasa! Klik bar energi untuk buka puasa.", 6.0)



func _kabar_ramadan() -> void :
	if hari == RAMADAN_MULAI - 1:
		tambah_chat("Pak RT", "Bapak-Ibu, menurut pengumuman pemerintah besok sudah 1 Ramadan. Malam ini tarawih pertama di masjid. Selamat menunaikan ibadah puasa!", true, "teks", "rt")
	elif hari == RAMADAN_MULAI:
		tambah_chat("Pak Haji Rasyid", "Pak Misran, selama bulan puasa warung boleh buka sampai jam 7 malam, biar warga gampang beli takjil. Setelah Lebaran kembali tutup jam 5 sore, ya.", true, "teks", "juragan")
		tambah_chat("Agus", "Pak, puasa pertama di kota nih. Kangen sahur bareng Bapak. Bapak jaga kesehatan ya, jangan lupa sahur.", true)
	elif hari == HARI_ZAKAT and not zakat_dibayar:
		tambah_chat("Pak RT", "Bapak-Ibu, panitia zakat fitrah sudah buka di masjid sampai malam takbiran. Zakat fitrah tahun ini %s per orang. Bisa juga lewat saya (bayar di HP, aplikasi Warga Bank)." % format_rupiah(ZAKAT_FITRAH), true, "teks", "rt")
	elif hari == HARI_LEBARAN - 7 and thr_agus == 0:
		tambah_chat("Agus", "Pak, Lebaran sebentar lagi. Agus belum bisa beli baju Lebaran buat Ibu, tabungan kepakai buat buku. Nggak apa-apa kok, Pak.", true)
		tambah_chat("Pak RT", "Bapak-Ibu, yang mau kirim THR buat anak-cucu di rantau, bisa transfer lewat HP (aplikasi Warga Bank). Seminggu lagi Lebaran!", true, "teks", "rt")



func boleh_zakat() -> bool:
	return not zakat_dibayar and hari >= HARI_ZAKAT and hari < HARI_LEBARAN


func bayar_zakat() -> String:
	if not boleh_zakat():
		return "Belum waktunya zakat fitrah." if not zakat_dibayar else "Zakat fitrah sudah dibayar."
	if uang < ZAKAT_FITRAH:
		return "Uang di laci tidak cukup untuk zakat fitrah %s." % format_rupiah(ZAKAT_FITRAH)
	uang -= ZAKAT_FITRAH
	zakat_dibayar = true
	catat_transaksi("Zakat fitrah", - ZAKAT_FITRAH)
	ulasan_warga(5, "Pak Misran sudah bayar zakat fitrah lebih awal. Contoh yang baik buat warga.", "Haji Doni")
	tambah_chat("Pak RT", "Zakat fitrah dari Pak Misran sudah diterima panitia. Terima kasih, Pak, semoga berkah.", true, "teks", "rt")
	data_berubah.emit()
	simpan()
	return ""



func _cek_zakat_terlewat() -> void :
	if hari == HARI_LEBARAN and not zakat_dibayar and HARI_LEBARAN >= RAMADAN_MULAI:
		zakat_dibayar = true
		ulasan_warga(2, "Kok Pak Misran nggak kelihatan bayar zakat fitrah ya kemarin...", "Warga")
		tambah_chat("Pak RT", "Bapak-Ibu, panitia zakat sudah menyalurkan zakat fitrah ke yang berhak. Yang belum sempat, semoga tahun depan tidak terlewat.", true, "teks", "rt")



func boleh_thr() -> bool:
	return thr_agus == 0 and hari >= HARI_LEBARAN - 7 and hari < HARI_LEBARAN


func kirim_thr(jumlah: int) -> String:
	if not boleh_thr():
		return "THR hanya bisa dikirim seminggu sebelum Lebaran (sekali)."
	if uang < jumlah:
		return "Uang di laci tidak cukup."
	uang -= jumlah
	thr_agus = jumlah
	catat_transaksi("THR untuk Agus", - jumlah)
	tambah_chat("Bapak", "Transfer %s" % format_rupiah(jumlah), false, "transfer", "agus")
	tambah_chat("Agus", "Ya Allah, Pak... makasih banyak. Aku belikan baju Lebaran buat Ibu ya. Nanti pas mudik aku bantu jaga warung lebih lama!", true)
	data_berubah.emit()
	simpan()
	return ""




func boleh_tarawih() -> bool:
	var jam: = menit / 60.0
	return hari >= RAMADAN_MULAI - 1 and hari < HARI_LEBARAN - 1 and tarawih_hari != hari and jam >= JAM_TARAWIH[0] and jam < JAM_TARAWIH[1]


func ikut_tarawih() -> String:
	if not boleh_tarawih():
		return "Tarawih hanya selama Ramadan, pukul 19.30-21.00."
	tarawih_hari = hari
	majukan_waktu(60.0)
	energi = maxf(energi - 4.0, 0.0)
	tambah_akrab("haji_doni", AKRAB_KERJA)
	tambah_akrab("santri_putih", AKRAB_KERJA)
	if randf() < 0.5:
		ulasan_warga(5, "Pak Misran rajin tarawih di masjid. Warungnya juga ramah.", "Jamaah masjid")
	data_berubah.emit()
	return ""







const PENGALI_RAMAI_MURAH: = 1.5
const BATAS_RAMAI_MURAH: = 0.3
const PENGALI_SABAR_MURAH: = 1.0

func efek_harga_murah() -> float:
	var total: = 0.0
	var n: = 0
	for id in barang_fisik():
		if not terbuka(id):
			continue
		total += maxf(0.0, 1.0 - rasio_harga(id))
		n += 1
	return minf(total / n, BATAS_RAMAI_MURAH / PENGALI_RAMAI_MURAH) if n > 0 else 0.0



func pengali_ramai_murah() -> float:
	return 1.0 / (1.0 + efek_harga_murah() * PENGALI_RAMAI_MURAH)


func pengali_sabar(saat_antre: bool) -> float:
	var bonus: = efek_upgrade("sabar") + (efek_upgrade("sabar_antre") if saat_antre else 0.0)
	bonus = minf(bonus, float(batas_efek.get("sabar", 0.35)))



	if agus_membantu():
		bonus += AGUS_BONUS_SABAR

	bonus += efek_harga_murah() * PENGALI_SABAR_MURAH
	return float(efek_reputasi()["sabar"]) * (1.0 + bonus) * pengali_bantuan()


func punya_upgrade_efek(kunci: String) -> bool:
	for id in upgrade_dimiliki:
		if data_upgrade(id).get("efek", {}).has(kunci):
			return true
	return false




func cara_buka_barang(id: String) -> String:
	if titipan_sales(id):
		return "titipan %s, mulai Level %d" % [String(SALES_TITIPAN[id]["sebutan_sales"]), LEVEL_TITIPAN]
	if id in BARANG_RAMADAN:
		return "barang musiman, terbuka saat bulan Ramadan (%s)" % teks_tanggal(RAMADAN_MULAI)
	for u in daftar_upgrade:
		if id in u.get("efek", {}).get("buka_barang", []):
			return "upgrade %s (Lv %d)" % [u["nama"], u["level"]]
	if level_pembuka(id) > 0:
		return "terbuka saat naik ke level %d" % level_pembuka(id)
	var ev: = event_pembuka(id)
	if ev != "":
		return "dari cerita warga: %s (mulai Level %d)" % [String(data_event()[ev]["judul"]), level_cerita(ev)]
	if bab_pembuka(id) > 0:
		return "terbuka saat naik ke level %d" % (level_bab(bab_pembuka(id) - 1) + 1)
	return "belum tersedia"



func level_buka_barang(id: String) -> int:
	if titipan_sales(id):
		return LEVEL_TITIPAN
	if id in BARANG_RAMADAN:
		return 98
	if id in cerita.get("terbuka_awal", []):
		return 0
	for u in daftar_upgrade:
		if id in u.get("efek", {}).get("buka_barang", []):
			return int(u["level"])
	if level_pembuka(id) > 0:
		return level_pembuka(id)
	var ev: = event_pembuka(id)
	if ev != "":
		return level_cerita(ev)
	if bab_pembuka(id) > 0:
		return level_bab(bab_pembuka(id) - 1) + 1
	return 99



func level_pembuka(id: String) -> int:
	for i in daftar_tingkat.size():
		if id in daftar_tingkat[i].get("buka", []):
			return i + 1
	return 0


func barang_level_ini() -> Array:
	return daftar_tingkat[tingkat].get("buka", []) if tingkat < daftar_tingkat.size() else []



func _buka_barang(daftar: Array) -> void :
	for id in daftar:
		if not terbuka(id):
			barang_terbuka.append(id)
			if stok.has(id):
				stok[id] += int(katalog[id]["stok_awal"])



func _barang_dari_upgrade() -> Array:
	var hasil: Array = []
	for u in daftar_upgrade:
		hasil.append_array(u.get("efek", {}).get("buka_barang", []))
	return hasil


func _semua_barang_cerita() -> Array:

	var kunci: = _barang_dari_upgrade()
	var dari_event: = {}
	for ev in data_event():
		for id in data_event()[ev].get("hasil", {}).get("tolong", {}).get("buka", []):
			dari_event[id] = true
	var hasil: Array = []
	for id in urutan_barang:
		if id in kunci or (dari_event.has(id) and not id in barang_terbuka):
			continue
		if titipan_sales(id) and not id in barang_terbuka:
			continue
		if level_pembuka(id) == 0 or tingkat + 1 >= level_pembuka(id):
			hasil.append(id)
	return hasil




const TAMBAHAN_AGEN: = 0.1


func lewat_agen(id: String) -> bool:
	for ev in cerita_warga:
		if hasil_event(ev) == "tolak" and data_event().has(ev)\
		and id in data_event()[ev].get("hasil", {}).get("tolong", {}).get("buka", []):
			return true
	return false



func _buka_barang_agen() -> Array:
	var baru: Array = []
	for ev in cerita_warga:
		if hasil_event(ev) != "tolak" or not data_event().has(ev):
			continue
		for id in data_event()[ev].get("hasil", {}).get("tolong", {}).get("buka", []):
			if katalog.has(id) and not terbuka(id):
				barang_terbuka.append(id)
				baru.append(id)
	return baru


func _buka_barang_upgrade() -> void :
	for id in upgrade_dimiliki:
		for b in data_upgrade(id).get("efek", {}).get("buka_barang", []):
			if not terbuka(b):
				barang_terbuka.append(b)







const FILE_KEJADIAN: = "res://data/kejadian.json"
var data_kejadian: = {}

var kejadian: = {}


func _muat_kejadian() -> void :
	var data = JSON.parse_string(FileAccess.get_file_as_string(FILE_KEJADIAN))
	if typeof(data) != TYPE_DICTIONARY:
		push_error("Gagal membaca %s. Periksa penulisan file JSON-nya." % FILE_KEJADIAN)
		return
	data_kejadian = data


func info_kejadian(id: String) -> Dictionary:
	if id == "preman_nongkrong":
		return data_kejadian.get("preman_nongkrong", {})
	for k in data_kejadian.get("siang", []):
		if k["id"] == id:
			return k
	return {}



func _undi_kejadian() -> void :

	kejadian = {}
	if data_kejadian.is_empty() or hari < int(data_kejadian.get("mulai_hari", 3)) or hari_libur():
		return
	if randf() >= float(data_kejadian.get("peluang_harian", 0.45)):
		return
	var daftar: Array = data_kejadian["siang"]
	var total: = 0.0
	for k in daftar:
		total += _bobot_kejadian(k)
	var r: = randf() * total
	var pilih: Dictionary = daftar[0]
	for k in daftar:
		r -= _bobot_kejadian(k)
		if r <= 0.0:
			pilih = k
			break
	var jam: = randf_range(float(pilih["jam"][0]), float(pilih["jam"][1]))

	if nama_hari() == "Jumat" and jam >= 11.0 and jam < 13.0:
		jam += 2.0
	var lama: = randi_range(int(pilih["lama"][0]), int(pilih["lama"][1]))
	kejadian = {"id": pilih["id"], "mulai": int(jam * 60.0), "lama": lama, "status": "menunggu", 
		"tangkal": pilih.has("penangkal") and punya_upgrade_efek(String(pilih["penangkal"]))}
	if pilih["id"] == "arisan":
		_pesan_arisan(int(jam))

	var pagi: Array = pilih.get("pagi", [])
	if not pagi.is_empty() and randf() < float(pagi[0]):
		tambah_chat(pagi[1], String(pagi[2]).replace("{jam}", "%02d.00" % int(jam)), true, "teks", "rt")


func _bobot_kejadian(k: Dictionary) -> float:
	var b: = float(k.get("bobot", 1.0))

	if k["id"] == "palak" and punya_upgrade_efek("cctv"):
		b *= 0.3
	if k["id"] in ["palak", "mati_listrik"]:
		b *= pengali_sial()

	if k["id"] == "gajian":
		var tgl: = int(tanggal()["day"])
		if tgl < 25 and tgl > 3:
			b = 0.0
	if k["id"] == "arisan":
		var bisa: = (data_kejadian.get("arisan", {}).get("barang", []) as Array).filter( func(id): return katalog.has(id) and terbuka(id))
		if bisa.size() < 2:
			b = 0.0
	return b



func cek_kejadian() -> String:
	if kejadian.is_empty():
		return ""
	match kejadian["status"]:
		"menunggu":
			if menit < float(kejadian["mulai"]):
				return ""

			if String(kejadian["id"]) == "palak" and sedang_hujan():
				return ""
			if int(kejadian["lama"]) <= 0:
				kejadian["status"] = "selesai"
				return String(kejadian["id"])
			kejadian["status"] = "aktif"
			kejadian["mulai"] = int(menit)
			return "mulai"
		"aktif":

			if String(kejadian["id"]) == "preman_nongkrong" and sedang_hujan():
				kejadian["lama"] = int(menit) - int(kejadian["mulai"])
			if menit >= float(kejadian["mulai"]) + float(kejadian["lama"]):
				kejadian["status"] = "selesai"
				return "selesai"
	return ""



func efek_kejadian() -> Dictionary:
	if kejadian.get("status", "") != "aktif" or kejadian.get("tangkal", false) or status_hari != "buka":
		return {}
	return info_kejadian(String(kejadian["id"])).get("efek", {})


func listrik_padam() -> bool:
	return kejadian.get("id", "") == "mati_listrik" and not efek_kejadian().is_empty()



func pengali_jeda_kejadian() -> float:
	return float(efek_kejadian().get("jeda", 1.0)) * float(efek_cuaca().get("jeda", 1.0)) * float(efek_kabar().get("jeda", 1.0))




func pengali_barang_kejadian(id: String) -> float:
	var p: = 1.0
	for efek in [efek_kejadian(), efek_cuaca(), efek_kabar()]:
		if efek.is_empty():
			continue
		p *= float(efek.get("barang", {}).get(id, 1.0))
		var kat: = String(katalog[id].get("kategori", ""))
		if kat != "":
			p *= float(efek.get("kategori", {}).get(kat, 1.0))
	return p


func warna_kejadian() -> Color:
	var c: = Color.WHITE
	for efek in [efek_kejadian(), efek_cuaca()]:
		var r: Array = efek.get("redup", [])
		if r.size() == 3:
			c *= Color(r[0], r[1], r[2])
	return c







const JAM_HUJAN: = [9.0, 16.0]
const LAMA_HUJAN: = [150, 210]
const EFEK_HUJAN: = {"jeda": 1.2, "kategori": {"minuman": 0.5}, "barang": {"mi_rebus": 4.0, "kopi_susu": 2.5, "sachet": 2.5, "obat": 1.5}, 
	"redup": [0.72, 0.76, 0.86]}
const PESAN_HUJAN: = [
	"Bapak-Ibu, hujan turun cukup deras. Jemurannya diangkat dulu, ya. Hati-hati jalan licin.", 
	"Info warga: hujan deras mulai turun. Anak-anak jangan main di selokan, ya. Kalau ada genangan tolong kabari.", 
	"Hujan, Bapak-Ibu. Yang naik motor pelan-pelan, jalan depan masjid licin. Jangan lupa jas hujan.", 
	"Alhamdulillah hujan turun, sawah nggak kering lagi. Tapi jemuran tolong diangkat dulu, ya.", 
]
const PESAN_MENDUNG: = [
	["Cak Imron", "Langit mendung dari subuh. Kayaknya nanti siang hujan deras nih."], 
	["Bu RT", "Ibu-ibu, kata ramalan cuaca hari ini bakal hujan. Jemurannya jangan ditinggal lama-lama, ya."], 
]




const PELUANG_SEHARIAN: = 1.0 / 3.0
const JEDA_SEHARIAN: = 2
const PESAN_HUJAN_SEHARIAN: = [
	"Bapak-Ibu, hujan dari subuh belum berhenti. Kata ramalan cuaca bakal hujan seharian sampai malam. Hati-hati jalan licin, ya.", 
	"Info warga: hujan awet dari pagi, kayaknya seharian nggak reda. Jemuran jangan dijemur dulu. Yang ke sawah hati-hati.", 
	"Hujan terus dari subuh, Bapak-Ibu. Kata BMKG sampai malam. Selokan depan masjid tolong dicek kalau mampet.", 
]
signal hujan_berubah(turun: bool)
var cuaca: = {}
var _hujan_lalu: = false
var hari_hujan_seharian: = -99


var cuaca_besok: = {}






const BANJIR_MULAI_HARI: = 10
const BANJIR_JEDA: = 14
const PELUANG_BANJIR: = 0.4
const BANJIR_JAM_NAIK: = [10 * 60, 13 * 60]
const BANJIR_SURUT: = 17 * 60
const PESAN_BANJIR: = [
	"Bapak-Ibu, air kali naik terus dari subuh. Kalau hujan begini, siang nanti jalan depan bisa banjir. Barang-barang diamankan, ya.", 
	"Info warga: selokan sudah penuh, air kali hampir meluap. Siang nanti jalan kampung kemungkinan banjir. Hati-hati, Bapak-Ibu.", 
]
var hari_banjir_terakhir: = -99




func sedang_banjir() -> bool:
	if mode_latihan or not cuaca.has("banjir") or not bool(cuaca.get("banjir_jalan", false)):
		return false
	return menit < BANJIR_SURUT



func banjir_hari_ini() -> bool:
	return not mode_latihan and cuaca.has("banjir") and not bool(cuaca.get("banjir_batal", false))




func cek_mulai_banjir(di_warung: bool) -> void :
	if not banjir_hari_ini() or bool(cuaca.get("banjir_jalan", false)) or menit < float(cuaca["banjir"]):
		return
	if di_warung and menit < BANJIR_SURUT:
		cuaca["banjir_jalan"] = true
	else:
		cuaca["banjir_batal"] = true





const PELUANG_JUMLAH_HUJAN: = [[1, 0.3], [2, 0.45], [3, 0.25]]
const PELUANG_SEHARIAN_HUJAN: = 0.35
var jadwal_hujan: = {}

func hari_hujan_minggu(h: int) -> Array:
	var minggu: = str((h - 1) / 7)
	if not jadwal_hujan.has(minggu):
		var r: = randf()
		var jumlah: = 1
		for p in PELUANG_JUMLAH_HUJAN:
			r -= float(p[1])
			if r <= 0.0:
				jumlah = int(p[0])
				break
		var calon: Array = []
		var awal: = ((h - 1) / 7) * 7 + 1
		for d in range(awal, awal + 7):
			if d >= 2:
				calon.append(d)
		calon.shuffle()
		jadwal_hujan[minggu] = calon.slice(0, jumlah)
	return jadwal_hujan[minggu]


func _undi_cuaca_untuk(h: int) -> Dictionary:
	if h < 2 or not h in hari_hujan_minggu(h).map( func(x): return int(x)):
		return {}
	if h - hari_hujan_seharian > JEDA_SEHARIAN and randf() < PELUANG_SEHARIAN_HUJAN:
		hari_hujan_seharian = h
		var c: = {"mulai": 0, "lama": JAM_BATAS, "dikabari": false, "seharian": true}
		if h >= BANJIR_MULAI_HARI and h - hari_banjir_terakhir >= BANJIR_JEDA and randf() < PELUANG_BANJIR:
			hari_banjir_terakhir = h
			c["banjir"] = randi_range(BANJIR_JAM_NAIK[0], BANJIR_JAM_NAIK[1])
		return c
	var jam: = randf_range(float(JAM_HUJAN[0]), float(JAM_HUJAN[1]))
	return {"mulai": int(jam * 60.0), "lama": randi_range(int(LAMA_HUJAN[0]), int(LAMA_HUJAN[1])), "dikabari": false}



func ramalan_besok() -> Dictionary:
	if int(cuaca_besok.get("hari", -1)) != hari + 1:
		cuaca_besok = {"hari": hari + 1, "cuaca": _undi_cuaca_untuk(hari + 1)}
	return cuaca_besok["cuaca"]



func teks_ramalan(c: Dictionary) -> String:
	if c.is_empty():
		return "Cerah sepanjang hari"
	if c.has("banjir"):
		return "Hujan seharian, waspada banjir siang hari"
	if bool(c.get("seharian", false)):
		return "Hujan seharian, dari pagi sampai malam"
	var mulai: = int(c["mulai"]) / 60
	var selesai: = int(ceil((float(c["mulai"]) + float(c["lama"])) / 60.0))
	return "Hujan sekitar pukul %02d.00-%02d.00" % [mulai, selesai]


func _undi_hujan() -> void :

	if int(cuaca_besok.get("hari", -1)) == hari:
		cuaca = (cuaca_besok["cuaca"] as Dictionary).duplicate()
	else:
		cuaca = _undi_cuaca_untuk(hari)
	ramalan_besok()
	if banjir_hari_ini():
		tambah_chat("Pak RT", String(PESAN_BANJIR.pick_random()), true, "teks", "rt")
	if cuaca.is_empty() or bool(cuaca.get("seharian", false)):
		return

	if randf() < 0.4:
		var p: Array = PESAN_MENDUNG.pick_random()
		tambah_chat(p[0], p[1], true, "teks", "rt")


func sedang_hujan() -> bool:
	if efek_kejadian().get("hujan", false):
		return true
	if cuaca.is_empty():
		return false
	return menit >= float(cuaca["mulai"]) and menit < float(cuaca["mulai"]) + float(cuaca["lama"])




func tanah_basah() -> bool:
	return not cuaca.is_empty() and menit >= float(cuaca["mulai"])


func efek_cuaca() -> Dictionary:
	return EFEK_HUJAN if not cuaca.is_empty() and sedang_hujan() else {}



func _cek_cuaca() -> void :
	var h: = sedang_hujan()
	if h == _hujan_lalu:
		return
	_hujan_lalu = h
	if h and not cuaca.is_empty() and not bool(cuaca.get("dikabari", false)):
		cuaca["dikabari"] = true
		var pesan: Array = PESAN_HUJAN_SEHARIAN if bool(cuaca.get("seharian", false)) else PESAN_HUJAN
		tambah_chat("Pak RT", pesan.pick_random(), true, "teks", "rt")
	hujan_berubah.emit(h)



func preman_di_depan() -> bool:
	return kejadian.get("id", "") == "preman_nongkrong" and kejadian.get("status", "") == "aktif"



func mulai_preman_nongkrong() -> void :
	var d: Dictionary = data_kejadian.get("preman_nongkrong", {})
	var lama: Array = d.get("lama", [60, 60])
	kejadian = {"id": "preman_nongkrong", "mulai": int(menit), "lama": randi_range(int(lama[0]), int(lama[1])), "status": "aktif", "tangkal": false}
	_balas_budi_preman()
	_tambah_ulasan(1, "Ada preman nongkrong di depan warung, saya nggak jadi beli. Serem.")
	_tambah_ulasan(2, "Mau jajan tapi depan warungnya ada preman. Takut, Pak.")
	_hitung_reputasi()
	data_berubah.emit()


func setoran_palak() -> int:
	var n: = 10000
	for baris in data_kejadian.get("palak", {}).get("setoran", []):
		if level() >= int(baris[0]):
			n = int(baris[1])
	return n


func bayar_palak(jumlah: int) -> void :
	uang -= jumlah
	catat_transaksi("Uang keamanan (preman)", - jumlah)
	data_berubah.emit()




func buat_borongan() -> Dictionary:
	var d: Dictionary = data_kejadian.get("borongan", {})
	var calon: Array = []
	for id in d.get("barang", []):
		if katalog.has(id) and terbuka(id) and int(stok.get(id, 0)) >= int(d["unit"][0]) + MIN_STOK_BUKA:
			calon.append(id)
	if calon.is_empty():
		return {}
	calon.shuffle()
	var jenis: = mini(randi_range(int(d["jenis"][0]), int(d["jenis"][1])), calon.size())
	var daftar: Array = []
	var total: = 0
	for i in jenis:
		var id: String = calon[i]
		var n: = mini(randi_range(int(d["unit"][0]), int(d["unit"][1])), int(stok[id]) - MIN_STOK_BUKA)
		daftar.append([id, n])
		total += harga_jual(id) * n
	var p: Array = (d["pemesan"] as Array).pick_random()
	return {"nama": p[0], "acara": p[1], "daftar": daftar, "total": total}


func terima_borongan(b: Dictionary) -> int:
	var masuk: = 0
	for baris in b["daftar"]:
		for i in int(baris[1]):
			var uang_lalu: = uang
			if jual(String(baris[0])) == "":
				masuk += uang - uang_lalu
	ulasan_warga(5, "Pesanan borongan buat acara dikerjakan rapi dan lengkap. Mantap, Pak Misran!", String(b["nama"]))
	tambah_chat(String(b["nama"]), "Makasih, Pak Misran! Barangnya sudah saya ambil semua.", false, "teks", "rt")
	return masuk



func kalimat_daftar_barang(daftar: Array) -> String:
	var bagian: PackedStringArray = []
	for baris in daftar:
		var b: = data_barang(String(baris[0]))
		bagian.append("%d %s" % [int(baris[1]), tk(String(b.get("sebutan", b["nama"])).to_lower())])
	return ", ".join(bagian)



const PELUANG_PINDAH_RUMAH: = 0.5
const MIN_UTANG_PINDAH: = 50000
var qris_hari: = 0
var uang_palsu_hari: = 0



func _pesan_arisan(jam: int) -> void :
	var d: Dictionary = data_kejadian.get("arisan", {})
	var calon: Array = (d.get("barang", []) as Array).filter( func(id): return katalog.has(id) and terbuka(id))
	calon.shuffle()
	var daftar: Array = []
	for id in calon.slice(0, mini(randi_range(int(d["jenis"][0]), int(d["jenis"][1])), calon.size())):
		daftar.append([id, randi_range(int(d["unit"][0]), int(d["unit"][1]))])
	var p: Array = (d["pemesan"] as Array).pick_random()
	kejadian["pesanan"] = {"nama": p[0], "acara": p[1], "daftar": daftar}
	tambah_chat(String(p[0]), "Pak Misran, buat %s nanti sore sekitar jam %02d.00 saya ambil pesanan: %s. Dibayar lunas, ya. Tolong disiapkan stoknya, Pak." % [p[1], jam, kalimat_daftar_barang(daftar)], true, "teks", "rt")


func pesanan_arisan() -> Dictionary:
	return kejadian.get("pesanan", {})



func ambil_arisan() -> Dictionary:
	var p: = pesanan_arisan()
	if p.is_empty():
		return {}
	var d: Dictionary = data_kejadian.get("arisan", {})
	var masuk: = 0
	var kurang: Array = []
	for baris in p["daftar"]:
		var id: = String(baris[0])
		var n: = int(baris[1])
		var dapat: = 0
		for i in n:
			var uang_lalu: = uang
			if jual(id) != "":
				break
			masuk += uang - uang_lalu
			dapat += 1
		if dapat < n:
			kurang.append([id, n - dapat])
	var lengkap: = kurang.is_empty()
	var tip: = 0
	if lengkap and randf() < float(d.get("peluang_tip", 0.5)):
		tip = int((d.get("tip", [5000]) as Array).pick_random())
		uang += tip
		hadiah_hari += tip
		catat_transaksi("Tip dari %s (arisan)" % String(p["nama"]), tip)
	if lengkap:
		ulasan_warga(5, "Pesanan buat arisan lengkap dan rapi. Ibu-ibu senang, Pak Misran!", String(p["nama"]))
		tambah_chat(String(p["nama"]), "Makasih, Pak Misran! Pesanan arisannya lengkap, ibu-ibu senang.", false, "teks", "rt")
	elif masuk > 0:
		tambah_chat(String(p["nama"]), "Makasih, Pak. Sayang %s kurang, saya cari di tempat lain saja." % kalimat_daftar_barang(kurang), false, "teks", "rt")
	else:
		tambah_chat(String(p["nama"]), "Yah, Pak Misran, stoknya habis semua. Ya sudah, saya beli di tempat lain.", false, "teks", "rt")
	kejadian.erase("pesanan")
	data_berubah.emit()
	return {"nama": p["nama"], "acara": p["acara"], "daftar": p["daftar"], "masuk": masuk, "tip": tip, "kurang": kurang, "lengkap": lengkap}



func _cek_uang_palsu() -> int:
	var d: Dictionary = data_kejadian.get("uang_palsu", {})
	if d.is_empty() or hari < int(d.get("mulai_hari", 8)) or mode_latihan or tutorial_langkah != "":
		return 0
	var tunai: = omzet_hari - qris_hari
	if tunai < int(d.get("min_tunai", 50000)):
		return 0
	var peluang: = float(d.get("peluang", 0.05)) * (float(d.get("pengali_qris", 0.7)) if punya_upgrade("qris") else 1.0) * pengali_sial()
	if randf() >= peluang:
		return 0
	var nominal: = 50000 if tunai >= 150000 and randf() < 0.5 else 20000
	uang -= nominal
	catat_transaksi("Uang palsu ketahuan saat tutup", - nominal)
	tambah_chat("Pak RT", "Bapak-Ibu, hati-hati, sedang beredar uang palsu di kampung kita. Raba, lihat, terawang dulu sebelum diterima, ya.", true, "teks", "rt")
	return nominal



func _cek_tikus() -> Dictionary:
	var d: Dictionary = data_kejadian.get("tikus", {})
	if d.is_empty() or hari < int(d.get("mulai_hari", 6)):
		return {}
	var peluang: = float(d.get("peluang", 0.07))
	var neo_akrab: = neo_bisa_disapa() and tingkat_akrab(TIPE_NEO) >= int(d.get("tingkat_neo", 2))
	if neo_akrab:
		peluang *= float(d.get("pengali_neo", 0.2))
	peluang *= pengali_sial()
	if randf() >= peluang:
		return {}
	var ada: Array = (d.get("barang", []) as Array).filter( func(id): return katalog.has(id) and terbuka(id) and int(stok.get(id, 0)) > 0)
	if ada.is_empty():
		return {}
	ada.shuffle()
	var hilang: Array = []
	var nilai: = 0
	for id in ada.slice(0, randi_range(1, int(d.get("maks_jenis", 2)))):
		var n: = mini(randi_range(1, int(d.get("maks_unit", 2))), int(stok[id]))
		stok[id] = int(stok[id]) - n
		hilang.append([id, n])
		nilai += harga_modal(id) * n
	data_berubah.emit()
	return {"tikus": true, "hilang": hilang, "nilai": nilai, "neo": neo_akrab}




func cek_pencurian() -> Dictionary:
	var d: Dictionary = data_kejadian.get("pencurian", {})
	if d.is_empty() or hari < int(d.get("mulai_hari", 5)):
		return {}
	var cctv: = punya_upgrade_efek("cctv")
	var peluang: = float(d.get("peluang", 0.1)) * (float(d.get("pengali_cctv", 0.25)) if cctv else 1.0) * pengali_sial()
	if randf() >= peluang:
		return _cek_tikus()
	var ada: Array = barang_fisik().filter( func(id): return terbuka(id) and stok[id] > 0)
	if ada.is_empty():
		return {}
	ada.shuffle()
	var batas: = int(d.get("maks_nilai", 40000))
	var hilang: Array = []
	var nilai: = 0
	for id in ada.slice(0, randi_range(1, int(d.get("maks_jenis", 2)))):
		var n: = mini(randi_range(1, int(d.get("maks_unit", 3))), int(stok[id]))

		while n > 1 and nilai + harga_modal(id) * n > batas:
			n -= 1
		if nilai + harga_modal(id) * n > batas and not hilang.is_empty():
			continue
		hilang.append([id, n])
		nilai += harga_modal(id) * n
	if cctv:
		tambah_chat("Pak RT", "Semalam ada yang mau mencuri di warung Pak Misran, tapi terekam CCTV. Pelakunya sudah kami amankan.", true, "teks", "rt")
		return {"hilang": hilang, "nilai": nilai, "cctv": true}
	for baris in hilang:
		stok[baris[0]] -= int(baris[1])
	tambah_chat("Pak RT", "Hati-hati, Bapak-Ibu. Semalam warung Pak Misran kemalingan. Pintu dan gembok tolong dicek lagi.", true, "teks", "rt")
	data_berubah.emit()
	return {"hilang": hilang, "nilai": nilai, "cctv": false}




func mulai_latihan() -> void :
	mulai_game_baru()
	mode_latihan = true
	tutorial_langkah = "etalase"
	nama_warung = "Warung Pak Misran"
	dialog_tertunda.clear()



	for id in STOK_LATIHAN:
		stok[id] = int(STOK_LATIHAN[id])


const STOK_LATIHAN: = {"mi_goreng": 2, "mi_rebus": 6, "telur": 6, "biskuit": 6, "air_mineral": 6}



func selesai_latihan() -> void :
	var p: = penjaga
	sambut_asli = true
	mode_latihan = false
	tutorial_selesai = true
	simpan_pengaturan()
	mulai_game_baru()
	penjaga = p
	putar_intro = true




func level_cerita(id: String) -> int:
	return int(data_event().get(id, {}).get("level_min", 1))


func cerita_terbuka(id: String) -> bool:
	return level() >= level_cerita(id)






func cerita_tampil_di_daftar(id: String) -> bool:
	if hasil_event(id) != "" or tahap_event(id) > 0:
		return true
	var ev: Dictionary = data_event().get(id, {})
	if not ev.has("setelah_hasil"):
		return true
	return hasil_event(String(ev.get("setelah", ""))) == String(ev["setelah_hasil"])


func cerita_cocok_hasil(ev: Dictionary) -> bool:
	return not ev.has("setelah_hasil") or hasil_event(String(ev.get("setelah", ""))) in ["", String(ev["setelah_hasil"])]




func cerita_menunggu(ev: Dictionary) -> bool:
	for lain in ev.get("tunggu", []):
		if hasil_event(String(lain)) == "":
			return true
	return false



func cerita_level(lv: int) -> Array:
	var hasil: Array = []
	for id in data_event():
		if level_cerita(id) == lv and lv > 1 and cerita_tampil_di_daftar(id):
			hasil.append(String(data_event()[id]["judul"]))
	return hasil





func cerita_ditunda(id: String) -> bool:
	return bool(cerita_warga.get(id, {}).get("ditunda", false)) and hasil_event(id) == ""




func jam_cerita(id: String, t: Dictionary) -> Array:
	var j: Array = t.get("jam", [7, 22])
	if tahap_event(id) > 0 and not bool(t.get("jam_ketat", false)):
		return [7.0, 22.0]
	return [float(j[0]), minf(float(j[1]), 22.0)]




func jadwal_cerita(id: String) -> Dictionary:
	var ev: Dictionary = data_event()[id]
	var kini: = mini(tahap_event(id), (ev["tahap"] as Array).size() - 1)
	var t: Dictionary = ev["tahap"][kini]
	var j: = jam_cerita(id, t)
	var hasil: = {"tahap": t, "hari": _hari_cerita(ev, kini), "jam": "%s-%s" % [_jam_titik(float(j[0])), _jam_titik(float(j[1]))], 
		"jam_mulai": _jam_titik(float(j[0])), "catatan": _catatan_cerita(id, ev, kini, t), "syarat": _syarat_cerita(id, ev, kini)}
	var npc: = String(t.get("npc", ""))
	var jam: = menit / 60.0
	var hari_cocok: bool = kini > 0 or cerita_ditunda(id) or event_bisa_mulai(id, hari)
	if kini == 0 and hari_libur() and event_janji(id) and not janji_hari_ini(id) and not cerita_ditunda(id):
		hari_cocok = false
	if hasil_event(id) != "":
		hasil["keadaan"] = "selesai"
		hasil["status"] = "Cerita ini sudah selesai"
	elif String(hasil["syarat"]) != "":
		hasil["keadaan"] = "terkunci"
		hasil["status"] = "Belum terbuka"
	elif not hari_cocok:
		hasil["keadaan"] = "tunggu"
		hasil["status"] = "Tidak ada hari ini, coba hari lain"
	elif jam >= float(j[1]) or jam < 5.0:
		hasil["keadaan"] = "tunggu"
		hasil["status"] = "Jamnya sudah lewat, datang lagi besok"
	elif jam < float(j[0]):
		hasil["keadaan"] = "tunggu"
		hasil["status"] = "Belum waktunya, datang pukul %s" % hasil["jam_mulai"]
	elif npc != "" and di_rumah_saat_hujan(npc) and not janji_hari_ini(id) and not cerita_ditunda(id):
		hasil["keadaan"] = "tunggu"
		hasil["status"] = "Sedang hujan, tunggu reda"
	else:
		hasil["keadaan"] = "sekarang"
		hasil["status"] = "Bisa ditemui sekarang"
	return hasil


func _hari_cerita(ev: Dictionary, kini: int) -> String:
	if kini > 0:
		return "Setiap hari"
	if ev.has("hari_maks") and hari <= int(ev["hari_maks"]):
		if int(ev.get("hari_min", 1)) == int(ev["hari_maks"]):
			return "Hanya tanggal %s" % teks_tanggal(int(ev["hari_maks"]))
		return "Sampai tanggal %s" % teks_tanggal(int(ev["hari_maks"]))
	if bool(ev.get("hari_sekolah", false)):
		return "Setiap hari kecuali Minggu"
	if bool(ev.get("hari_pasar", false)):
		return "Setiap hari kecuali Selasa dan Kamis"
	return "Setiap hari"


func _catatan_cerita(id: String, ev: Dictionary, kini: int, t: Dictionary) -> Array:
	var hasil: Array = []
	if janji_hari_ini(id):
		hasil.append("Sudah janjian hari ini.")
	elif kini == 0 and event_janji(id) and not cerita_ditunda(id):
		hasil.append("Hari Jumat hanya kalau sudah janjian lewat Wasap.")
	if kini == 0 and bool(ev.get("bukan_ramadan", false)) and ramadan():
		hasil.append("Mulai lagi sesudah Ramadan.")
	if String(t.get("npc", "")) in TIPE_TANPA_PAYUNG:
		hasil.append("Tidak keluar saat hujan.")
	if String(t.get("area", "")) == "pasar":
		hasil.append("Ke Pasar naik angkot dari pos ronda di Rumah Warga.")
	return hasil


func _syarat_cerita(id: String, ev: Dictionary, kini: int) -> String:
	if hasil_event(id) != "" or kini > 0:
		return ""
	if not cerita_terbuka(id):
		return "Terbuka di Level %d" % level_cerita(id)
	if hari < int(ev.get("hari_min", 1)):
		return "Mulai tanggal %s" % teks_tanggal(int(ev["hari_min"]))
	var syarat: Array = ev.get("tunggu", []).duplicate()
	if ev.has("setelah"):
		syarat.push_front(String(ev["setelah"]))
	for lain in syarat:
		if hasil_event(String(lain)) == "" and data_event().has(String(lain)):
			return "Selesaikan dulu cerita: %s" % String(data_event()[String(lain)]["judul"])
	return ""


func misi_warga_aktif() -> Array:
	var hasil: Array = []
	for id in data_event():
		var cw: Dictionary = cerita_warga.get(id, {})
		if cw.is_empty() or String(cw.get("hasil", "")) != "":
			continue
		if int(cw.get("tahap", 0)) <= 0 and not bool(cw.get("ditunda", false)):
			continue
		var semua: Array = data_event()[id]["tahap"]
		hasil.append([id, semua[mini(int(cw.get("tahap", 0)), semua.size() - 1)]])
	return hasil





func tipe_cerita_aktif() -> Dictionary:
	var hasil: = {}
	for m in misi_warga_aktif():
		for t in data_event()[String(m[0])]["tahap"]:
			for npc in npc_tahap(t):
				hasil[npc] = true

	if nama_hari() == "Jumat" and menit >= 11 * 60 and menit < 13 * 60 + 30:
		hasil["haji_doni"] = true
	return hasil



func _kalimat_warga(baik: bool) -> String:
	var kolam: Array = ULASAN_WARGA_BAIK if baik else ULASAN_WARGA_BURUK
	var lama: = ulasan.slice(maxi(ulasan.size() - 6, 0)).map( func(x): return x["teks"])
	var calon: = kolam.filter( func(t): return not t in lama)
	return String((calon if not calon.is_empty() else kolam).pick_random())



func ikon_upgrade(id: String) -> String:
	var png: = "res://assets/upgrade/ikon/%s.png" % id
	return png if ResourceLoader.exists(png) else "res://assets/upgrade/ikon/%s.svg" % id







const LEVEL_AGEN: = 2
const PERUBAHAN_PASARAN: = [-0.15, -0.1, -0.05, 0.05, 0.1, 0.15, 0.2]
var harga_pasaran: = {}
var agen_kenalan: = false

func agen_aktif() -> bool:
	return level() >= LEVEL_AGEN


func harga_pasar(id: String) -> int:
	var dasar: = int(katalog[id]["jual"])
	if not agen_aktif() or not harga_pasaran.has(id):
		return dasar
	var pasar: = maxi(100, int(round(dasar * float(harga_pasaran[id]) / 100.0)) * 100)

	return maxi(pasar, mini(dasar, maxi(int(katalog[id]["modal"]), harga_modal(id)) + 100))



func _kabar_agen() -> void :
	if not agen_aktif():
		return
	var pertama: = not agen_kenalan
	if not pertama and nama_hari() != "Senin":
		return
	if pertama:
		agen_kenalan = true
		tambah_chat("Info Harga Pasaran", "Selamat datang di Info Harga Pasaran, Pak Misran! Tiap Senin kami kabari harga rata-rata warung lain minggu ini. Kalau pasaran naik, Bapak boleh ikut naikkan harga tanpa pembeli protes. Kalau pasaran turun, sebaiknya ikut turunkan, biar pembeli tidak merasa kemahalan.", true, "teks", "agen")
	_perbarui_pasaran()
	var naik: Array = []
	var turun: Array = []
	for id in harga_pasaran:
		var nama_b: = tk(String(data_barang(id).get("sebutan", data_barang(id)["nama"])))
		var teks: = "%s %s" % [nama_b.left(1).to_upper() + nama_b.substr(1), format_rupiah(harga_pasar(id))]
		if float(harga_pasaran[id]) > 1.0:
			naik.append(teks)
		else:
			turun.append(teks)
	var isi: = "Harga pasaran minggu ini:"
	if not naik.is_empty():
		isi += "\n\nNaik:\n• " + "\n• ".join(naik)
	if not turun.is_empty():
		isi += "\n\nTurun:\n• " + "\n• ".join(turun)
	isi += "\n\nBarang lain sesuai harga disarankan. Atur di aplikasi Harga Jual ya."

	if not naik.is_empty() and kondisi_pemain() < 0:
		isi += "\n\nLagi bagus nih. Harga barang yang naik bisa ikut dinaikkan, pembeli tidak akan protes."
	tambah_chat("Info Harga Pasaran", isi, true, "teks", "agen")






const PASARAN_SUSAH_HARI_DI_LEVEL: = 25
const PASARAN_SUSAH_HARI_PER_LEVEL: = 35.0
const PASARAN_LANCAR_HARI_PER_LEVEL: = 12.0
const PASARAN_LANCAR_UANG: = 1500000

func kondisi_pemain() -> int:
	if mode != "casual":
		return 0
	var hari_per_level: = float(hari) / maxf(level() - 1, 1)
	if hari_di_level() >= PASARAN_SUSAH_HARI_DI_LEVEL or tingkat_bantuan() > 0.3\
	or (level() >= 3 and hari_per_level >= PASARAN_SUSAH_HARI_PER_LEVEL):
		return -1
	if level() >= 3 and (hari_per_level <= PASARAN_LANCAR_HARI_PER_LEVEL or uang >= PASARAN_LANCAR_UANG):
		return 1
	return 0







func _perbarui_pasaran() -> void :
	var kondisi: = kondisi_pemain()
	for id in harga_pasaran.keys():
		var lama: = float(harga_pasaran[id])
		var p: = snappedf(1.0 + (lama - 1.0) * 0.5, 0.05)
		if kondisi < 0 and lama < 1.0:
			p = 1.0
		if absf(p - 1.0) < 0.01:
			harga_pasaran.erase(id)
		else:
			harga_pasaran[id] = p
	var calon: = barang_belanja().filter(terbuka)
	calon.shuffle()
	var jumlah: = randi_range(3, 5)
	var jumlah_naik: = randi_range(1, 2)
	for i in mini(jumlah, calon.size()):
		var id: String = calon[i]
		var ubah: float
		match kondisi:
			-1:
				ubah = [0.05, 0.1, 0.15, 0.2].pick_random()
			1:

				ubah = [0.05, 0.1].pick_random() if i < jumlah_naik else [-0.05, -0.1, -0.15].pick_random()
			_:
				ubah = float(PERUBAHAN_PASARAN.pick_random())
		var p: = snappedf(clampf(float(harga_pasaran.get(id, 1.0)) + ubah, 0.8, 1.25), 0.05)
		if absf(p - 1.0) < 0.01:
			harga_pasaran.erase(id)
		else:
			harga_pasaran[id] = p
	data_berubah.emit()




func profit_bersih_hari() -> int:
	return laba_hari - biaya_harian_hari



func total_riwayat(kunci: String, n: int) -> int:
	var total: = 0
	for r in riwayat:
		if int(r["hari"]) > hari - n:
			total += int(r.get(kunci, r.get("laba", 0) if kunci == "bersih" else 0))
	return total










const PRODUK_TANPA_IKLAN: = "tanpa_iklan"

const PRODUK_DUKUNGAN: = ["dukung_esteh", "dukung_nasipadang", "dukung_game_45", "dukung_game_100"]
const PRODUK_DUKUNGAN_BEBAS_IKLAN: = ["dukung_game_45", "dukung_game_100"]
const HARGA_TANPA_IKLAN: = "Rp29.000"
const KODE_OK: = 0
const KODE_BATAL: = 1
const KODE_SUDAH_DIMILIKI: = 7
const STATUS_DIBAYAR: = 1
const STATUS_TERTUNDA: = 2
signal tanpa_iklan_berubah(aktif: bool)
signal pesan_toko(teks: String)
signal harga_produk_berubah
signal dukungan_diterima
var tanpa_iklan: = false


var pendukung: = false
var harga_tanpa_iklan: = HARGA_TANPA_IKLAN
var harga_produk: = {}
var _billing: Node = null


func billing_tersedia() -> bool:
	return _billing != null or _storekit != null


func _siapkan_billing() -> void :
	if OS.get_name() == "iOS":
		_siapkan_storekit()
		return
	if _billing != null or OS.get_name() != "Android" or not Engine.has_singleton("GodotGooglePlayBilling"):
		return
	_billing = load("res://addons/GodotGooglePlayBilling/BillingClient.gd").new()
	add_child(_billing)
	_billing.connected.connect(_on_billing_tersambung)


	_billing.disconnected.connect( func(): _sambung_ulang_billing("putus"))
	_billing.connect_error.connect( func(kode: int, _pesan: String): _sambung_ulang_billing("gagal_%d" % kode))
	_billing.acknowledge_purchase_response.connect(_on_konfirmasi_pembelian)
	_billing.on_purchase_updated.connect(_on_pembelian_diperbarui)
	_billing.query_purchases_response.connect( func(hasil: Dictionary):
		var manual: = _pulihkan_manual
		_pulihkan_manual = false
		if int(hasil.get("response_code", -1)) == KODE_OK:
			var sudah_aktif: = tanpa_iklan
			_proses_pembelian(hasil.get("purchases", []))
			_cek_bayar_dibatalkan(hasil.get("purchases", []))

			if manual and sudah_aktif and tanpa_iklan:
				pesan_toko.emit("Tanpa Iklan sudah aktif di akun Google Play ini. Terima kasih!")
			elif manual and not tanpa_iklan:
				pesan_toko.emit("Tidak ada pembelian Tanpa Iklan di akun Google Play ini. Kalau baru saja membeli, tunggu beberapa menit lalu coba lagi.")
		elif manual:
			pesan_toko.emit("Belum bisa memeriksa pembelian. Cek internet lalu coba lagi."))
	_billing.query_product_details_response.connect(_on_detail_produk)
	_billing.consume_purchase_response.connect( func(hasil: Dictionary):
		if int(hasil.get("response_code", -1)) == KODE_OK:
			aktifkan_pendukung())
	_billing.start_connection()


func _on_billing_tersambung() -> void :
	_jeda_sambung_billing = 2.0
	var id: = PackedStringArray([PRODUK_TANPA_IKLAN])
	id.append_array(PackedStringArray(PRODUK_DUKUNGAN))
	_billing.query_product_details(id, _billing.ProductType.INAPP)
	var menunggu: = _pulihkan_menunggu
	_pulihkan_menunggu = false
	pulihkan_pembelian(menunggu)


func _on_detail_produk(hasil: Dictionary) -> void :
	if int(hasil.get("response_code", -1)) != KODE_OK:
		return
	for d in hasil.get("product_details", []):
		var penawaran: Array = d.get("one_time_purchase_offer_details_list", [])
		if penawaran.is_empty():
			continue
		var id: = String(d.get("product_id", ""))
		harga_produk[id] = String(penawaran[0].get("formatted_price", ""))
		if id == PRODUK_TANPA_IKLAN and harga_produk[id] != "":
			harga_tanpa_iklan = harga_produk[id]
	harga_produk_berubah.emit()

	if _beli_antre != "" and harga_produk.has(_beli_antre):
		var id_antre: = _beli_antre
		_beli_antre = ""
		_mulai_beli(id_antre)


func beli_tanpa_iklan() -> void :
	if tanpa_iklan:
		pesan_toko.emit("Tanpa Iklan sudah aktif. Terima kasih!")
		return
	if _storekit != null:
		_beli_ios(PRODUK_TANPA_IKLAN)
		return
	if _billing == null:
		pesan_toko.emit("Pembelian lewat Google Play bisa dilakukan setelah Warung Life rilis di Play Store.")
		return
	_mulai_beli(PRODUK_TANPA_IKLAN)


func beli_dukungan(id: String) -> void :
	if _storekit != null:
		_beli_ios(id)
		return
	if _billing == null:
		pesan_toko.emit("Dukungan lewat Google Play bisa diberikan setelah Warung Life rilis di Play Store. Terima kasih sudah mau mendukung!")
		return
	_mulai_beli(id)





var _beli_antre: = ""


func _mulai_beli(id: String) -> void :
	_id_dibeli = id
	if not _billing.is_ready():
		_beli_antre = id
		_billing.start_connection()
		pesan_toko.emit("Menyambung ke Google Play... Halaman pembayaran terbuka sebentar lagi.")
		return
	if not harga_produk.has(id):
		_beli_antre = id
		_on_billing_tersambung()
		pesan_toko.emit("Membaca harga dari Google Play... Halaman pembayaran terbuka sebentar lagi.")
		return
	pesan_toko.emit("Membuka Google Play...")



	if id_papan != "":
		_billing.set_obfuscated_account_id(id_papan)
	_cek_hak_sesudah_beli = true
	var hasil: Dictionary = _billing.purchase(id)
	var kode: = int(hasil.get("response_code", -1))
	if kode == -1:

		_beli_antre = id
		_billing.start_connection()
		pesan_toko.emit("Menyambung ulang ke Google Play... Halaman pembayaran terbuka sebentar lagi.")
		return
	if kode != KODE_OK:
		_catat_beli("buka_gagal", id, kode)
		pesan_toko.emit(_pesan_gagal_billing(kode))


var _id_dibeli: = ""
var _jeda_sambung_billing: = 2.0
var _sambung_dijadwalkan: = false


func _sambung_ulang_billing(alasan: String) -> void :
	if _billing == null or _sambung_dijadwalkan:
		return
	_sambung_dijadwalkan = true
	_catat_beli("putus", alasan, 0)
	await get_tree().create_timer(_jeda_sambung_billing, true, false, true).timeout
	_sambung_dijadwalkan = false
	_jeda_sambung_billing = minf(_jeda_sambung_billing * 2.0, 60.0)
	if _billing != null and not _billing.is_ready():
		_billing.start_connection()



func _pesan_gagal_billing(kode: int) -> String:
	match kode:
		2, 12, -3:
			return "Koneksi ke Google Play terputus. Cek internet (matikan VPN / DNS pribadi kalau ada), lalu coba lagi."
		3:
			return "Pembayaran Google Play belum bisa dipakai di HP ini. Pastikan sudah masuk akun Google di Play Store dan Play Store sudah diperbarui."
		4:
			return "Produk ini belum tersedia untuk akun Google Play-mu. Coba lagi nanti."
		7:
			return "Pembelian ini sudah kamu miliki. Memulihkan..."
		-2:
			return "Play Store di HP ini terlalu lama. Perbarui Google Play Store dulu, lalu coba lagi."
		_:
			return "Google Play sedang bermasalah (kode %d). Coba lagi beberapa saat lagi." % kode


func _catat_beli(tahap: String, id: String, kode: int) -> void :
	if analitik != null:
		analitik.catat("beli", {"tahap": tahap, "id": id.left(30), "kode": kode})






var _beli_tercatat: Array = []

func _catat_beli_lunas(token: String, id: String) -> void :
	var tanda: = token.sha256_text().left(16) if token != "" else ""
	if tanda != "":
		if tanda in _beli_tercatat:
			return
		_beli_tercatat.append(tanda)
		if _beli_tercatat.size() > 40:
			_beli_tercatat = _beli_tercatat.slice(_beli_tercatat.size() - 40)
		simpan_pengaturan()
	if analitik != null:
		analitik.catat("beli", {"tahap": "lunas", "id": id.left(30), "kode": 0, 
			"os": "ios" if OS.get_name() == "iOS" else "android"})
		analitik.kirim()




var _pulihkan_manual: = false
var _pulihkan_menunggu: = false

func pulihkan_pembelian(manual: = false) -> void :
	if _storekit != null:

		_pulihkan_manual = manual
		if manual:
			pesan_toko.emit("Memeriksa pembelian di Google Play...")
			_storekit.request("appStoreSync", {})
		else:
			_storekit.request("transactionCurrentEntitlements", {})
		return
	if _billing == null:
		if manual:
			pesan_toko.emit("Pemulihan pembelian bisa dilakukan setelah Warung Life rilis di Play Store.")
		return
	if not _billing.is_ready():
		if manual:
			_pulihkan_menunggu = true
			pesan_toko.emit("Menyambung ke Google Play. Hasilnya muncul sebentar lagi.")
		_billing.start_connection()
		return
	_pulihkan_manual = manual
	if manual:
		pesan_toko.emit("Memeriksa pembelian di Google Play...")
	_billing.query_purchases(_billing.ProductType.INAPP)


func _on_pembelian_diperbarui(hasil: Dictionary) -> void :
	var kode: = int(hasil.get("response_code", -1))
	_catat_beli("hasil", _id_dibeli, kode)
	match kode:
		KODE_OK:
			_proses_pembelian(hasil.get("purchases", []))
		KODE_BATAL:
			pesan_toko.emit("Pembelian dibatalkan.")
		KODE_SUDAH_DIMILIKI:
			pesan_toko.emit(_pesan_gagal_billing(kode))
			pulihkan_pembelian()
		-1:
			pesan_toko.emit("Koneksi ke Google Play terputus saat membayar. Kalau saldomu sudah terpotong, pembelian aktif otomatis begitu tersambung lagi.")
			_sambung_ulang_billing("saat_bayar")
			_periksa_lagi(20.0)
		_:
			pesan_toko.emit(_pesan_gagal_billing(kode))

			_periksa_lagi(15.0)




func _on_konfirmasi_pembelian(hasil: Dictionary) -> void :
	var kode: = int(hasil.get("response_code", -1))
	if kode != KODE_OK:
		_catat_beli("konfirmasi_gagal", PRODUK_TANPA_IKLAN, kode)
		_periksa_lagi(30.0)


var _periksa_dijadwalkan: = false
var _tertunda_dikabari: = {}





var bayar_menunggu: = {}




var _cek_bayar_terakhir: = -100.0

func cek_bayar_menunggu(kembali_ke_game: = false) -> void :
	if not kembali_ke_game and bayar_menunggu.is_empty():
		return
	if _billing == null and _storekit == null:
		return
	var sekarang: = Time.get_ticks_msec() / 1000.0
	if sekarang - _cek_bayar_terakhir < 8.0:
		return
	_cek_bayar_terakhir = sekarang
	pulihkan_pembelian()
	if _cek_hak_sesudah_beli or not bayar_menunggu.is_empty():
		cek_hak_bebas_iklan(60.0)







var _cek_hak_sesudah_beli: = false
var _hak_dicek_terakhir: = -100000.0
var _hak_sedang_dicek: = false
var _hak_id_terakhir: = ""

func cek_hak_bebas_iklan(jeda: = 3600.0) -> void :
	if tanpa_iklan or _hak_sedang_dicek or papan == null or id_papan == "" or OS.get_name() != "Android":
		return
	var sekarang: = Time.get_ticks_msec() / 1000.0
	if id_papan == _hak_id_terakhir and sekarang - _hak_dicek_terakhir < jeda:
		return
	_hak_dicek_terakhir = sekarang
	_hak_id_terakhir = id_papan
	_hak_sedang_dicek = true
	var id_ditanya: = id_papan
	var ada: int = await papan.cek_hak_bebas_iklan(id_ditanya)
	_hak_sedang_dicek = false
	if ada != 1 or tanpa_iklan or id_ditanya != id_papan:
		return
	aktifkan_tanpa_iklan()
	for tanda in bayar_menunggu.keys():
		var produk: = String(bayar_menunggu[tanda].get("produk", ""))
		if produk == PRODUK_TANPA_IKLAN or produk in PRODUK_DUKUNGAN_BEBAS_IKLAN:
			bayar_menunggu.erase(tanda)
	simpan_pengaturan()
	tampilkan_pengingat_bayar("Pembayaran lunas!", "Terima kasih! %s sudah aktif." % _nama_produk_bayar(PRODUK_TANPA_IKLAN), Color(0.6, 0.95, 0.6))


func _tanda_bayar(token: String) -> String:
	return token.sha256_text().left(16)


func _nama_produk_bayar(id: String) -> String:
	return "Tanpa Iklan" if id == PRODUK_TANPA_IKLAN else "Dukung Kami"


func tampilkan_pengingat_bayar(judul: String, teks: String, warna: = Color(1.0, 0.82, 0.4)) -> void :
	var tree: = get_tree()
	if tree == null or tree.root == null:
		return
	var kartu = load("res://scripts/pengingat_bayar.gd").new()
	kartu.isi(judul, teks, warna)

	tree.root.add_child.call_deferred(kartu)


func _catat_bayar_menunggu(token: String, ids: Array) -> void :
	var tanda: = _tanda_bayar(token)
	var produk: = String(ids[0]) if not ids.is_empty() else ""
	if not bayar_menunggu.has(tanda):
		bayar_menunggu[tanda] = {"produk": produk, "sejak": Time.get_unix_time_from_system()}
		simpan_pengaturan()
	tampilkan_pengingat_bayar("Pembayaran %s belum dilunasi" % _nama_produk_bayar(produk), 
		"Selesaikan pembayaran di aplikasi bank / e-wallet / minimarket sesuai petunjuk dari Google Play (cek email), sebelum batas waktunya. Begitu lunas, pembelian aktif otomatis. Kalau tidak dilunasi, Google membatalkannya dan uangmu tidak terpotong.")


func _bayar_menunggu_lunas(token: String) -> void :
	var tanda: = _tanda_bayar(token)
	if not bayar_menunggu.has(tanda):
		return
	var produk: = String(bayar_menunggu[tanda].get("produk", ""))
	bayar_menunggu.erase(tanda)
	simpan_pengaturan()
	tampilkan_pengingat_bayar("Pembayaran lunas!", "Terima kasih! %s sudah aktif." % _nama_produk_bayar(produk), Color(0.6, 0.95, 0.6))




func _cek_bayar_dibatalkan(daftar: Array) -> void :
	if bayar_menunggu.is_empty():
		return
	var ada: = {}
	for p in daftar:
		ada[_tanda_bayar(String(p.get("purchase_token", "")))] = true
	var batal: Array = []
	var sekarang: = Time.get_unix_time_from_system()
	for tanda in bayar_menunggu.keys():
		if not ada.has(tanda) and sekarang - float(bayar_menunggu[tanda].get("sejak", sekarang)) > 300.0:
			batal.append(tanda)
	if batal.is_empty():
		return
	var produk: = String(bayar_menunggu[batal[0]].get("produk", ""))
	for tanda in batal:
		bayar_menunggu.erase(tanda)
	simpan_pengaturan()
	_catat_beli("dibatalkan", produk, batal.size())

	if not tanpa_iklan or produk != PRODUK_TANPA_IKLAN:
		tampilkan_pengingat_bayar("Pembayaran %s dibatalkan" % _nama_produk_bayar(produk), 
			"Google membatalkan pembayaran ini (belum dilunasi, lewat batas waktu, atau ditolak). Kalau saldomu sudah terpotong, bank / e-wallet mengembalikannya otomatis. Kalau mau coba lagi, bayar pakai pulsa, e-wallet (GoPay/DANA/OVO/ShopeePay), atau kartu supaya langsung aktif.", 
			Color(1.0, 0.6, 0.55))

func _periksa_lagi(detik: float) -> void :
	if _periksa_dijadwalkan or _billing == null:
		return
	_periksa_dijadwalkan = true
	await get_tree().create_timer(detik, true, false, true).timeout
	_periksa_dijadwalkan = false
	pulihkan_pembelian()


func _id_produk(p: Dictionary) -> Array:
	var ids: Array = []
	for id in p.get("product_ids", []):
		ids.append(String(id))
	return ids



func _proses_pembelian(daftar: Array) -> void :
	for p in daftar:
		var ids: = _id_produk(p)
		var token: = String(p.get("purchase_token", ""))
		var tanpa_iklan_ini: bool = PRODUK_TANPA_IKLAN in ids
		var dukungan_ini: = false
		for id in ids:
			if id in PRODUK_DUKUNGAN:
				dukungan_ini = true
		if not tanpa_iklan_ini and not dukungan_ini:
			continue


		if int(p.get("purchase_state", 0)) == STATUS_TERTUNDA:
			if _tertunda_dikabari.has(token):
				_periksa_lagi(120.0)
				continue
			_tertunda_dikabari[token] = true
			_catat_bayar_menunggu(token, ids)
			pesan_toko.emit("Pembayaran menunggu dilunasi. Selesaikan pembayaran sesuai petunjuk dari Google Play (cek email/aplikasi bank). Begitu lunas, pembelian aktif otomatis. Kalau tidak dilunasi tepat waktu, Google membatalkannya dan uang tidak terpotong.")
			_catat_beli("tertunda", ", ".join(ids), 0)
			_periksa_lagi(120.0)
			continue
		if int(p.get("purchase_state", 0)) != STATUS_DIBAYAR:
			continue
		_bayar_menunggu_lunas(token)
		if dukungan_ini:


			_daftarkan_pendukung(token, String(ids[0]) if not ids.is_empty() else "")
			_catat_beli_lunas(token, String(ids[0]) if not ids.is_empty() else "")
			_billing.consume_purchase(token)

			for id in ids:
				if id in PRODUK_DUKUNGAN_BEBAS_IKLAN:
					aktifkan_tanpa_iklan()
			continue
		if not bool(p.get("is_acknowledged", false)):
			_catat_beli_lunas(token, PRODUK_TANPA_IKLAN)
			_billing.acknowledge_purchase(token)
		aktifkan_tanpa_iklan()


		if kode_iklan == "" and token != "":
			_token_iklan = token
			simpan_pengaturan()
			_coba_daftarkan_tanpa_iklan()








var _storekit: Object = null
var _storekit_coba_produk: = 0
var _transaksi_ios: = {}


func _siapkan_storekit() -> void :
	if _storekit != null or not Engine.has_singleton("IOSInAppPurchase"):
		return
	_storekit = Engine.get_singleton("IOSInAppPurchase")

	_storekit.response.connect(_on_storekit, CONNECT_DEFERRED)
	_storekit.request("startUpdateTask", {})
	_storekit.request("proceedUnfinishedTransactions", {})
	_minta_produk_ios()
	pulihkan_pembelian(false)


func _minta_produk_ios() -> void :
	var id: Array = [PRODUK_TANPA_IKLAN]
	id.append_array(PRODUK_DUKUNGAN)
	_storekit.request("products", {"productIDs": id})


func _beli_ios(id: String) -> void :
	if not harga_produk.has(id):
		_minta_produk_ios()
		pesan_toko.emit("Produk belum terbaca dari Google Play. Coba lagi sebentar.")
		return
	pesan_toko.emit("Membuka Google Play...")
	if int(_storekit.request("purchase", {"productID": id})) != 0:
		pesan_toko.emit("Google Play belum bisa dibuka. Coba lagi nanti.")


func _on_storekit(nama: String, data: Dictionary) -> void :
	var hasil: = String(data.get("result", ""))
	match nama:
		"products":
			if hasil != "success":
				_storekit_coba_produk += 1
				if _storekit_coba_produk <= 3:
					get_tree().create_timer(10.0 * _storekit_coba_produk, true, false, true).timeout.connect(_minta_produk_ios)
				return
			_storekit_coba_produk = 0
			for p in data.get("products", []):
				var id: = String(p.get("id", ""))
				harga_produk[id] = String(p.get("displayPrice", ""))
				if id == PRODUK_TANPA_IKLAN and harga_produk[id] != "":
					harga_tanpa_iklan = harga_produk[id]
			harga_produk_berubah.emit()
		"purchase":
			_pembelian_ios(hasil, data)
		"transactionCurrentEntitlements":
			var manual: = _pulihkan_manual
			_pulihkan_manual = false
			if hasil != "success":
				if manual:
					pesan_toko.emit("Belum bisa memeriksa pembelian. Cek internet lalu coba lagi.")
				return
			var sudah_aktif: = tanpa_iklan
			for t in data.get("transactions", []):

				if String(t.get("productID", "")) == PRODUK_TANPA_IKLAN and t.has("jwsRepresentation")\
				and not t.has("error") and String(t.get("revocationDate", "")) == "":
					aktifkan_tanpa_iklan()
			if manual and sudah_aktif and tanpa_iklan:
				pesan_toko.emit("Tanpa Iklan sudah aktif di akun Google Play ini. Terima kasih!")
			elif manual and not tanpa_iklan:
				pesan_toko.emit("Tidak ada pembelian Tanpa Iklan di akun Google Play ini. Kalau baru saja membeli, tunggu beberapa menit lalu coba lagi.")
		"appStoreSync":

			_storekit.request("transactionCurrentEntitlements", {})


func _pembelian_ios(hasil: String, data: Dictionary) -> void :
	var id: = String(data.get("productID", ""))
	match hasil:
		"success":
			var trx: = String(data.get("transactionID", ""))
			if trx != "":
				if _transaksi_ios.has(trx):
					return
				_transaksi_ios[trx] = true
			if id in PRODUK_DUKUNGAN or id == PRODUK_TANPA_IKLAN:
				_catat_beli_lunas("ios:" + trx if trx != "" else "", id)
			if id in PRODUK_DUKUNGAN:

				_daftarkan_pendukung("ios:" + trx, id)
				aktifkan_pendukung()
				if id in PRODUK_DUKUNGAN_BEBAS_IKLAN:
					aktifkan_tanpa_iklan()
			elif id == PRODUK_TANPA_IKLAN:
				aktifkan_tanpa_iklan()
		"revoked":
			pass
		"pending":
			pesan_toko.emit("Pembayaran sedang diproses. Pembelian aktif begitu pembayaran selesai.")
		"userCancelled":
			pesan_toko.emit("Pembelian dibatalkan.")
		_:
			pesan_toko.emit("Pembayaran gagal. Coba lagi nanti.")






const HADIAH_BAGIKAN: = 100000

const BONUS_SKOR_GANDA: = 3000
var bonus_mancing_hari: = -1


func beri_bonus_skor_ganda() -> void :
	if mode_latihan:
		return
	uang += BONUS_SKOR_GANDA
	hadiah_hari += BONUS_SKOR_GANDA
	catat_transaksi("Bonus skor 2x lipat mini-game", BONUS_SKOR_GANDA)
	bunyi("koin")
	data_berubah.emit()
	simpan()


var bagikan_hari: = -99

var bonus_tautan_diambil: = false

var tangkapan_tertunda: Array = []
var kerja_berjalan: = ""


func mulai_kerja_berjalan(id: String) -> void :
	kerja_berjalan = id
	simpan()



func _bereskan_mini_game_tertunda() -> void :
	for id in tangkapan_tertunda:
		tambah_hasil_alam(String(id))
	tangkapan_tertunda = []
	if kerja_berjalan == "":
		return
	var id: = kerja_berjalan
	kerja_berjalan = ""
	if KERJA_SAMPINGAN.has(id) and alasan_tidak_bisa_kerja(id) == "":
		pengali_kerja = 0.5
		kerjakan(id)
		pengali_kerja = 1.0

func hadiah_bagikan_tersedia() -> bool:
	return bagikan_hari < 0



func ambil_hadiah_bagikan() -> int:
	if mode_latihan or not sedang_main or not hadiah_bagikan_tersedia():
		return 0
	bagikan_hari = hari
	uang += HADIAH_BAGIKAN
	catat_transaksi("Hadiah bagikan capaian", HADIAH_BAGIKAN)
	bunyi("koin")
	data_berubah.emit()
	simpan()
	return HADIAH_BAGIKAN




const URL_FORM_MASUKAN: = "https://docs.google.com/forms/d/e/1FAIpQLScFfEgTcr6XJrau99IIHINKYlDNaCHc2M-jh2lxIwxDJaMy6A/viewform"
const ISIAN_FORM: = {"versi": "entry.493854180", "hp": "entry.1476883015", "level": "entry.521552096"}

func url_masukan() -> String:
	var versi: = String(ProjectSettings.get_setting("application/config/version", ""))
	var hp: = "%s, %s %s" % [OS.get_model_name(), OS.get_name(), OS.get_version()]
	var url: = "%s?usp=pp_url&%s=%s&%s=%s" % [URL_FORM_MASUKAN, ISIAN_FORM["versi"], versi.uri_encode(), ISIAN_FORM["hp"], hp.uri_encode()]
	if sedang_main:
		url += "&%s=%s" % [ISIAN_FORM["level"], ("Level %d, hari %d" % [level(), hari]).uri_encode()]
	return url







signal kode_pendukung_berubah
var kode_pendukung: = ""
var _token_pendukung: = ""
var kode_diumumkan: = false


func _daftarkan_pendukung(token: String, produk: String) -> void :
	if kode_pendukung != "":
		return
	_token_pendukung = "%s|%s" % [token, produk]
	simpan_pengaturan()
	await _coba_buat_kode_pendukung()


func _lanjutkan_kode_pendukung() -> void :
	if not pendukung or kode_pendukung != "":
		return
	if _token_pendukung == "":
		var acak: = PackedByteArray()
		for i in 12:
			acak.append(randi() % 256)
		_token_pendukung = "lama:%s|lama" % acak.hex_encode()
		simpan_pengaturan()
	await _coba_buat_kode_pendukung()


func _coba_buat_kode_pendukung() -> void :
	if papan == null or _token_pendukung == "":
		return
	var bagian: = _token_pendukung.split("|")
	var token: = String(bagian[0])
	var produk: = String(bagian[1]) if bagian.size() > 1 else ""
	var kode: = ""


	if OS.get_name() == "Android" and not token.begins_with("lama:"):
		var hasil: Dictionary = await papan.verifikasi_pembelian(token, produk)
		if hasil.is_empty() or String(hasil.get("alasan", "")) in ["tertunda", "server", "db"]\
		or String(hasil.get("alasan", "")).begins_with("google_"):
			return
		if not bool(hasil.get("ok", false)):
			_token_pendukung = ""
			simpan_pengaturan()
			return
		kode = String(hasil.get("kode", ""))
	else:
		kode = await papan.buat_kode_pendukung(token, produk)
	if kode == "":
		return
	kode_pendukung = kode
	_token_pendukung = ""

	if not kode_diumumkan:
		kode_diumumkan = true
		var info: CanvasLayer = load("res://scripts/info_kode_pendukung.gd").new()
		info.kode = kode
		get_tree().root.add_child(info)
	simpan_pengaturan()
	kode_pendukung_berubah.emit()
	_cek_dukungan_bebas_iklan()






var kode_iklan: = ""
var _token_iklan: = ""
var _iklan_pindah_tunggu: = false


func _coba_daftarkan_tanpa_iklan() -> void :
	if papan == null or _token_iklan == "" or kode_iklan != "":
		return
	var hasil: Dictionary = await papan.verifikasi_pembelian(_token_iklan, PRODUK_TANPA_IKLAN)
	if hasil.is_empty() or String(hasil.get("alasan", "")) in ["tertunda", "server", "db"]\
	or String(hasil.get("alasan", "")).begins_with("google_"):
		return
	if bool(hasil.get("ok", false)):
		kode_iklan = String(hasil.get("kode", ""))
	_token_iklan = ""
	simpan_pengaturan()






func bukti_pendukung_awal() -> Array:
	if kode_pendukung != "":
		return ["kode", kode_pendukung]
	if kode_iklan != "":
		return ["kode", kode_iklan]
	if OS.get_name() == "iOS" and (pendukung or tanpa_iklan):
		return ["ios", ""]
	return []


func _lanjutkan_bukti_iklan() -> void :
	_coba_daftarkan_tanpa_iklan()
	if _iklan_pindah_tunggu:
		await _periksa_iklan_pindah(false)



func _periksa_iklan_pindah(promo_iklan: bool) -> bool:
	if promo_iklan:
		_iklan_pindah_tunggu = false
		aktifkan_tanpa_iklan()
		return true
	var gagal_terhubung: = false
	for k in [kode_iklan, kode_pendukung]:
		if String(k) == "":
			continue
		var n: int = await papan.cek_bebas_iklan(String(k)) if papan != null else -1
		if n == 1:
			_iklan_pindah_tunggu = false
			aktifkan_tanpa_iklan()
			return true
		if n < 0:
			gagal_terhubung = true
	_iklan_pindah_tunggu = gagal_terhubung
	simpan_pengaturan()
	return false



func pakai_kode_pendukung(kode: String) -> String:
	var bersih: = kode.strip_edges().to_upper().replace(" ", "")
	if bersih.length() < 8:
		return "Kodenya terlalu pendek. Contoh: NPW-ABCD-EF23."
	if papan == null:
		return "Belum bisa memeriksa kode."
	var hasil: int = await papan.cek_kode_pendukung(bersih)
	if hasil < 0:
		return "Belum bisa memeriksa kode. Cek internet lalu coba lagi."
	if hasil == 0:
		return "Kode tidak ditemukan. Periksa lagi huruf dan angkanya."
	kode_pendukung = bersih
	_token_pendukung = ""
	kode_diumumkan = true
	aktifkan_pendukung()
	kode_pendukung_berubah.emit()
	_cek_dukungan_bebas_iklan(true)
	return ""






const RESET_PROGRES_RILIS: = false

const RILIS_PUBLIK_IOS: = true


const RILIS_PUBLIK_ANDROID: = true


func aturan_rilis_aktif() -> bool:
	return RESET_PROGRES_RILIS or (RILIS_PUBLIK_IOS and OS.get_name() == "iOS") or (RILIS_PUBLIK_ANDROID and OS.get_name() == "Android")
const TANPA_IKLAN_IKUT_LANJUT: = true
const FOLDER_ARSIP_UJI: = "user://arsip_uji"
var reset_rilis_dicek: = false
var info_reset_rilis: = false


func _boleh_lanjut_progres() -> bool:
	return pendukung or kode_pendukung != "" or (TANPA_IKLAN_IKUT_LANJUT and tanpa_iklan)





const FILE_RILIS_DICEK: = "user://rilis_dicek.txt"


func _cek_reset_rilis() -> void :


	if not RESET_PROGRES_RILIS or reset_rilis_dicek or FileAccess.file_exists(FILE_RILIS_DICEK):
		reset_rilis_dicek = reset_rilis_dicek or FileAccess.file_exists(FILE_RILIS_DICEK)
		return
	reset_rilis_dicek = true
	var penanda: = FileAccess.open(FILE_RILIS_DICEK, FileAccess.WRITE)
	if penanda != null:
		penanda.store_string(Time.get_datetime_string_from_system(false, true))
		penanda.close()
	var ada: = false
	for n in range(1, JUMLAH_SLOT + 1):
		ada = ada or ada_slot(n)
	if ada and not _boleh_lanjut_progres():
		DirAccess.make_dir_recursive_absolute(FOLDER_ARSIP_UJI)
		for n in range(1, JUMLAH_SLOT + 1):
			if ada_slot(n):
				DirAccess.rename_absolute(ProjectSettings.globalize_path(file_slot(n)), 
					ProjectSettings.globalize_path("%s/simpanan_%d.json" % [FOLDER_ARSIP_UJI, n]))
			_hapus_cadangan_slot(n)
		slot_terakhir = 0
		info_reset_rilis = true
	simpan_pengaturan()


func ada_arsip_uji() -> bool:
	for n in range(1, JUMLAH_SLOT + 1):
		if FileAccess.file_exists("%s/simpanan_%d.json" % [FOLDER_ARSIP_UJI, n]):
			return true
	return false



func pulihkan_arsip_uji() -> bool:
	if not _boleh_lanjut_progres():
		return false
	for n in range(1, JUMLAH_SLOT + 1):
		var arsip: = "%s/simpanan_%d.json" % [FOLDER_ARSIP_UJI, n]
		if FileAccess.file_exists(arsip):

			_sisihkan_slot_diganti(n)
			DirAccess.rename_absolute(ProjectSettings.globalize_path(arsip), ProjectSettings.globalize_path(file_slot(n)))
			slot_terakhir = n
	simpan_pengaturan()
	return true


func aktifkan_pendukung() -> void :
	pendukung = true
	simpan_pengaturan()
	dukungan_diterima.emit()



func nama_warung_tanpa_awalan() -> String:
	var n: = nama_warung.strip_edges()
	if n.to_lower().begins_with("warung "):
		n = n.substr(7).strip_edges()
	return n


func aktifkan_tanpa_iklan() -> void :
	var baru: = not tanpa_iklan
	tanpa_iklan = true
	simpan_pengaturan()
	if baru:
		bunyi("hadiah")
		pesan_toko.emit("Terima kasih! Semua iklan sudah hilang dan hadiah iklan langsung didapat.")
		tanpa_iklan_berubah.emit(true)







var dukungan_iklan_dicek: = false

func _cek_dukungan_bebas_iklan(paksa: = false) -> void :
	if papan == null or kode_pendukung == "" or tanpa_iklan or (dukungan_iklan_dicek and not paksa):
		return
	var info: Dictionary = await papan.produk_kode_pendukung(kode_pendukung)
	if info.is_empty():
		return
	dukungan_iklan_dicek = true
	simpan_pengaturan()
	if bool(info.get("ada", false)) and String(info.get("produk", "")) in PRODUK_DUKUNGAN_BEBAS_IKLAN:
		aktifkan_tanpa_iklan()
		_tampilkan_info_hadiah("Terima kasih sudah mendukung!", 
			"Dukunganmu Rp60.000 ke atas kini sekaligus membuat game bebas iklan. Hadiah iklan langsung didapat tanpa menonton.")






const NAMA_BAJU: = {"sarung": "Kaos & sarung", "batik": "Kemeja batik", "celemek": "Kaos & celemek warung", "koko": "Baju koko"}
var baju_dimiliki: = {}



var baju_dipakai: = ""

var login_harian: Node = null
var login_hari_ke: = 0
var login_tanggal: = ""
var login_siklus: = 0
var bebas_iklan_dari: = 0
var bebas_iklan_sampai: = 0
var login_tanda_sah: = true







func bebas_iklan_sementara() -> bool:
	if bebas_iklan_sampai <= 0 or not login_tanda_sah or login_harian == null:
		return false
	if login_hari_ke < 26 or bebas_iklan_sampai - bebas_iklan_dari != 86400:
		return false
	var kini: int = login_harian.sekarang()
	if kini <= 0:
		login_harian.ambil_jam()
		return false
	return kini >= bebas_iklan_dari and kini < bebas_iklan_sampai



func tanpa_iklan_aktif() -> bool:
	return tanpa_iklan or bebas_iklan_sementara()
const FILE_MODEL_BAJU: = {"sarung": "meshy_bapak_sarung.glb"}
const URUTAN_LEMARI: = ["", "sarung", "batik", "celemek", "koko"]
var promo_dipakai: = {}

const KODE_PENGEMBANG_HASH: = "48bb6e38f01895d9200dd83a17d1cd8ff46b4b7dfcf467a4d378fd7429930c8b"
var hp_pengembang: = false


static func bersihkan_kode_promo(kode: String) -> String:
	return kode.strip_edges().to_upper().replace(" ", "").replace("-", "")



func pakai_kode_promo(kode: String) -> String:
	var k: = bersihkan_kode_promo(kode)
	if k.length() < 4:
		return "Kodenya terlalu pendek."


	if k.sha256_text() == KODE_PENGEMBANG_HASH:
		hp_pengembang = true
		simpan_pengaturan()
		pesan_toko.emit("HP ini sekarang memakai iklan contoh (mode pengembang). Tutup game lalu buka lagi supaya berlaku.")
		return ""
	if papan == null or analitik == null:
		return "Belum bisa memeriksa kode."
	var hasil: Dictionary = await papan.pakai_kode_promo(k, String(analitik.id_perangkat))
	if hasil.is_empty():
		return "Belum bisa memeriksa kode. Cek internet lalu coba lagi."
	if not bool(hasil.get("ok", false)):
		match String(hasil.get("alasan", "")):
			"habis":
				return "Maaf, kode ini sudah habis dipakai."
			"kedaluwarsa":
				return "Maaf, masa berlaku kode ini sudah habis."
			"tidak_ada":
				return "Kode tidak ditemukan. Periksa lagi huruf dan angkanya."
		return "Kode belum bisa dipakai. Coba lagi nanti."
	promo_dipakai[k] = true
	var hadiah: = String(hasil.get("hadiah", ""))
	if hadiah == "bebas_iklan":
		var sudah: = tanpa_iklan
		aktifkan_tanpa_iklan()
		if sudah:
			pesan_toko.emit("Kode berhasil! Game ini memang sudah bebas iklan.")
	elif hadiah.begins_with("baju:"):
		var id: = hadiah.substr(5)
		baju_dimiliki[id] = true
		simpan_pengaturan()
		bunyi("hadiah")
		pesan_toko.emit("Kode berhasil! Baju \"%s\" untuk Pak Misran tersimpan. Nanti bisa dipakai lewat lemari di kamar." % tk(String(NAMA_BAJU.get(id, id))))
	else:
		simpan_pengaturan()
		pesan_toko.emit("Kode berhasil dipakai.")
	return ""







const BAJU_TESTER: = "sarung"
var tester: = false
var tester_dicek_rilis: = false
var tester_diumumkan: = false

func _cek_tester() -> void :
	var masa_uji: bool = load("res://scripts/cek_versi.gd").MASA_UJI
	var lama: = tester
	if masa_uji:
		tester = true
	elif not tester_dicek_rilis:
		tester_dicek_rilis = true
		var ada: = false
		for n in range(1, JUMLAH_SLOT + 1):
			ada = ada or ada_slot(n)
		if ada or ada_arsip_uji():
			tester = true
	if tester:
		baju_dimiliki[BAJU_TESTER] = true
	if tester != lama or (tester and not masa_uji and not tester_diumumkan):
		simpan_pengaturan()

	if tester and not masa_uji and not tester_diumumkan:
		tester_diumumkan = true
		simpan_pengaturan()
		_tampilkan_info_hadiah.call_deferred("Terima kasih sudah jadi tester!", 
			"Kamu ikut menguji Warung Life Simulator sebelum rilis. Sebagai hadiah, Pak Misran punya baju khusus tester: kaos & sarung. Bisa dipakai lewat lemari di kamar.")


func _tampilkan_info_hadiah(judul: String, teks: String) -> void :
	var info: CanvasLayer = load("res://scripts/info_hadiah.gd").new()
	info.judul = judul
	info.teks = teks
	get_tree().root.add_child(info)








const FORMAT_PINDAH: = 1

func _paket_pindah() -> String:
	var slot: = {}
	for n in range(1, JUMLAH_SLOT + 1):
		if ada_slot(n):
			slot[str(n)] = FileAccess.get_file_as_string(file_slot(n))
	var paket: = {
		"format": FORMAT_PINDAH, 
		"dari": OS.get_name(), 
		"versi_game": String(ProjectSettings.get_setting("application/config/version", "")), 
		"dibuat": Time.get_datetime_string_from_system(false, true), 
		"slot": slot, 
		"slot_terakhir": slot_terakhir, 
		"toko": {"tanpa_iklan": tanpa_iklan, "pendukung": pendukung, "kode_pendukung": kode_pendukung, 
			"dukungan_iklan_dicek": dukungan_iklan_dicek, "kode_iklan": kode_iklan}, 
		"lemari": baju_dimiliki.keys(), 
		"lemari_dipakai": baju_dipakai, 
		"promo": promo_dipakai.keys(), 
		"tutorial_selesai": tutorial_selesai, 
		"tip": tip_dilihat.keys(), 
		"reset_rilis_dicek": reset_rilis_dicek, 
		"tester": tester, 
	}
	var mentah: = JSON.stringify(paket).to_utf8_buffer()
	return "1:" + Marshalls.raw_to_base64(mentah.compress(FileAccess.COMPRESSION_GZIP))



func paket_cloud() -> String:
	return _paket_pindah()


func buka_paket_cloud(teks: String) -> Dictionary:
	return _buka_paket_pindah(teks)



func cadangkan_lokal_sebelum_cloud() -> void :
	if jumlah_slot_terisi() == 0:
		return
	var f: = FileAccess.open("user://cadangan_sebelum_cloud.txt", FileAccess.WRITE)
	if f != null:
		f.store_string(_paket_pindah())
		f.close()





static func alasan_paket_lebih_baru(paket: Dictionary) -> String:
	var dari: = String(paket.get("versi_game", ""))
	var saya: = String(ProjectSettings.get_setting("application/config/version", ""))
	if dari == "" or saya == "" or dari.naturalnocasecmp_to(saya) <= 0:
		return ""
	return "Simpanan ini dari game versi %s, sedangkan game di HP ini masih versi %s. Update game ini dulu di toko aplikasi supaya simpanannya tidak rusak." % [dari, saya]


static func _buka_paket_pindah(teks: String) -> Dictionary:
	if not teks.begins_with("1:"):
		return {}
	var padat: = Marshalls.base64_to_raw(teks.substr(2))
	if padat.is_empty():
		return {}
	var mentah: = padat.decompress_dynamic(20000000, FileAccess.COMPRESSION_GZIP)
	var data = JSON.parse_string(mentah.get_string_from_utf8())
	return data if typeof(data) == TYPE_DICTIONARY and data.has("slot") else {}


func jumlah_slot_terisi() -> int:
	var n: = 0
	for i in range(1, JUMLAH_SLOT + 1):
		if ada_slot(i):
			n += 1
	return n



func buat_kode_pindah() -> Dictionary:
	if papan == null or analitik == null:
		return {"alasan": "Belum bisa membuat kode."}
	if sedang_main and not mode_latihan:
		simpan()
	if jumlah_slot_terisi() == 0 and not tanpa_iklan and not pendukung and baju_dimiliki.is_empty():
		return {"alasan": "Belum ada progres atau pembelian untuk dipindahkan."}
	var hasil: Dictionary = await papan.buat_kode_pindah(String(analitik.id_perangkat), _paket_pindah())
	if hasil.is_empty():
		return {"alasan": "Belum bisa membuat kode. Cek internet lalu coba lagi."}
	if not bool(hasil.get("ok", false)):
		if String(hasil.get("alasan", "")) == "sering":
			return {"alasan": "Terlalu sering membuat kode. Coba lagi satu jam lagi."}
		return {"alasan": "Belum bisa membuat kode. Coba lagi nanti."}
	return {"kode": String(hasil.get("kode", "")), "kedaluwarsa": String(hasil.get("kedaluwarsa", ""))}



func pakai_kode_pindah(kode: String) -> String:
	var k: = kode.strip_edges().to_upper().replace(" ", "").replace("-", "")
	if k.length() != 10 or not k.begins_with("PH"):
		return "Kodenya belum lengkap. Contoh: PH-ABCD-EF23."
	if papan == null or analitik == null:
		return "Belum bisa memeriksa kode."
	var rapi: = "PH-%s-%s" % [k.substr(2, 4), k.substr(6, 4)]
	var hasil: Dictionary = await papan.ambil_kode_pindah(rapi, String(analitik.id_perangkat))
	if hasil.is_empty():
		return "Belum bisa memeriksa kode. Cek internet lalu coba lagi."
	if not bool(hasil.get("ok", false)):
		match String(hasil.get("alasan", "")):
			"dipakai":
				return "Kode ini sudah dipakai di HP lain. Buat kode baru di HP lama."
			"kedaluwarsa":
				return "Kode ini sudah lewat 7 hari. Buat kode baru di HP lama."
			"tidak_ada":
				return "Kode tidak ditemukan. Periksa lagi huruf dan angkanya."
		return "Kode belum bisa dipakai. Coba lagi nanti."
	var paket: = _buka_paket_pindah(String(hasil.get("data", "")))
	if paket.is_empty():
		return "Data pindahan rusak. Buat kode baru di HP lama."
	var lebih_baru: = alasan_paket_lebih_baru(paket)
	if lebih_baru != "":


		return lebih_baru + " Sesudah update, ketik kode yang sama lagi di HP ini (kodenya tetap berlaku sampai 7 hari)."
	terapkan_paket_pindah(paket)

	info_pindah_iklan = ""
	if bool(paket.get("toko", {}).get("tanpa_iklan", false)) and not tanpa_iklan:
		if not await _periksa_iklan_pindah(bool(hasil.get("promo_iklan", false))):
			if _iklan_pindah_tunggu:
				info_pindah_iklan = "Tanpa Iklan sedang diperiksa dan aktif otomatis begitu internet lancar."
			else:
				info_pindah_iklan = "Tanpa Iklan belum ikut pindah karena bukti pembeliannya belum ada. Buka game di HP lama (versi terbaru) sekali dengan internet, lalu buat kode pindah lagi. Atau tekan Pulihkan Pembelian kalau HP ini memakai akun Google yang sama."
	return ""


var info_pindah_iklan: = ""



func periksa_iklan_sesudah_pulih(paket: Dictionary) -> void :
	info_pindah_iklan = ""
	if bool(paket.get("toko", {}).get("tanpa_iklan", false)) and not tanpa_iklan:
		if not await _periksa_iklan_pindah(false):
			if _iklan_pindah_tunggu:
				info_pindah_iklan = "Tanpa Iklan sedang diperiksa dan aktif otomatis begitu internet lancar."
			else:
				info_pindah_iklan = "Tanpa Iklan belum ikut kembali karena bukti pembeliannya belum ada. Tekan Pulihkan Pembelian kalau HP ini memakai akun Google / Apple yang sama dengan saat membeli."



static func _slot_terjauh_paket(slot: Dictionary) -> int:
	var terbaik: = 0
	var lv_terbaik: = -1
	var hari_terbaik: = -1
	for kunci in slot:
		var n: = int(kunci)
		var d = JSON.parse_string(String(slot[kunci]))
		if n < 1 or n > JUMLAH_SLOT or typeof(d) != TYPE_DICTIONARY:
			continue
		var lv: = int(d.get("tingkat", 0))
		var hr: = int(d.get("hari", 1))
		if lv > lv_terbaik or (lv == lv_terbaik and hr > hari_terbaik):
			terbaik = n
			lv_terbaik = lv
			hari_terbaik = hr
	return terbaik


func terapkan_paket_pindah(paket: Dictionary) -> void :

	var slot: Dictionary = paket.get("slot", {})
	if not slot.is_empty():
		for n in range(1, JUMLAH_SLOT + 1):
			if ada_slot(n):
				DirAccess.remove_absolute(ProjectSettings.globalize_path(file_slot(n)))
			_hapus_cadangan_slot(n)
		for kunci in slot:
			var n: = int(kunci)
			if n < 1 or n > JUMLAH_SLOT:
				continue
			var f: = FileAccess.open(file_slot(n), FileAccess.WRITE)
			if f != null:
				f.store_string(String(slot[kunci]))
				f.close()



		slot_terakhir = _slot_terjauh_paket(slot)
		if slot_terakhir == 0:
			slot_terakhir = int(paket.get("slot_terakhir", 0))
		if slot_terakhir > 0 and not ada_slot(slot_terakhir):
			slot_terakhir = 0
	var toko: Dictionary = paket.get("toko", {})


	var iklan_baru: bool = bool(toko.get("tanpa_iklan", false)) and not tanpa_iklan and String(paket.get("dari", "")) == "iOS"
	if iklan_baru:
		tanpa_iklan = true
	if kode_iklan == "":
		kode_iklan = String(toko.get("kode_iklan", ""))
	pendukung = pendukung or bool(toko.get("pendukung", false))
	if kode_pendukung == "":
		kode_pendukung = String(toko.get("kode_pendukung", ""))
	if kode_pendukung != "":
		_token_pendukung = ""
		kode_diumumkan = true
	dukungan_iklan_dicek = dukungan_iklan_dicek or bool(toko.get("dukungan_iklan_dicek", false))
	for b in paket.get("lemari", []):
		baju_dimiliki[String(b)] = true
	if String(paket.get("lemari_dipakai", "")) != "":
		baju_dipakai = String(paket["lemari_dipakai"])
	for p in paket.get("promo", []):
		promo_dipakai[String(p)] = true
	tutorial_selesai = tutorial_selesai or bool(paket.get("tutorial_selesai", false))
	for t in paket.get("tip", []):
		tip_dilihat[String(t)] = true
	reset_rilis_dicek = reset_rilis_dicek or bool(paket.get("reset_rilis_dicek", false))
	if bool(paket.get("tester", false)) and not tester:
		tester = true
		baju_dimiliki[BAJU_TESTER] = true
	simpan_pengaturan()
	if iklan_baru:
		tanpa_iklan_berubah.emit(true)
	if pendukung:
		dukungan_diterima.emit()
		kode_pendukung_berubah.emit()

	_cek_dukungan_bebas_iklan()








var hasil_alam: = {}
var mancing_hari: = {}
var kebun_petik_hari: = -99
var _data_hasil_alam: = {}


func data_hasil_alam() -> Dictionary:
	if _data_hasil_alam.is_empty():
		var d = JSON.parse_string(FileAccess.get_file_as_string("res://data/hasil_alam.json"))
		_data_hasil_alam = d if typeof(d) == TYPE_DICTIONARY else {"ikan": {}, "buah": {}, "aturan": {}}
	return _data_hasil_alam


func aturan_hasil_alam(kunci: String, bawaan: Variant = 0) -> Variant:
	return data_hasil_alam().get("aturan", {}).get(kunci, bawaan)



func info_hasil_alam(id: String) -> Dictionary:
	var d: = data_hasil_alam()
	for kelompok in ["ikan", "buah"]:
		if d.get(kelompok, {}).has(id):
			var info: Dictionary = d[kelompok][id].duplicate()
			info["kelompok"] = kelompok
			return info
	return {}




func acak_hasil_alam(kelompok: String, bonus_langka: = 0.0) -> String:
	var daftar: Dictionary = data_hasil_alam().get(kelompok, {})
	for id in daftar:
		if daftar[id].has("legendaris") and randf() * 100.0 < float(daftar[id]["legendaris"]):
			return String(id)
	var bobot: = {}
	var total: = 0.0
	for id in daftar:
		if daftar[id].has("legendaris"):
			continue
		var p: = float(daftar[id].get("peluang", 1))

		bobot[id] = p * (1.0 + bonus_langka * clampf(50.0 / maxf(p, 1.0) - 0.8, -0.5, 1.5))
		total += float(bobot[id])
	var r: = randf() * total
	for id in bobot:
		r -= float(bobot[id])
		if r <= 0.0:
			return id
	return String(bobot.keys()[0]) if not bobot.is_empty() else ""


func legendaris(id: String) -> bool:
	return info_hasil_alam(id).has("legendaris")




func tambah_hasil_alam(id: String, n: = 1) -> int:
	if n <= 0 or info_hasil_alam(id).is_empty():
		return 0
	n = mini(n, sisa_muat_alam(id))
	if n <= 0:
		return 0
	hasil_alam[id] = int(hasil_alam.get(id, 0)) + n
	if String(info_hasil_alam(id)["kelompok"]) == "ikan":
		if int(mancing_hari.get("hari", -1)) != hari:
			mancing_hari = {"hari": hari, "ikan": 0}
		mancing_hari["ikan"] = int(mancing_hari["ikan"]) + n
	data_berubah.emit()
	return n


const ISI_KOTAK_ALAM: = 10


func _isi_alam_dengan(tambahan: Array) -> Dictionary:
	var isi: = hasil_alam.duplicate()
	for id in tambahan:
		isi[String(id)] = int(isi.get(String(id), 0)) + 1
	return isi



func sisa_muat_alam(id: String, tambahan: Array = []) -> int:
	var isi: = _isi_alam_dengan(tambahan)
	var ada: = int(isi.get(id, 0))
	var sisa_kotak_ini: = (ISI_KOTAK_ALAM - ada % ISI_KOTAK_ALAM) % ISI_KOTAK_ALAM
	return maxi(KOTAK_TAS - _kotak_terpakai_isi(isi), 0) * ISI_KOTAK_ALAM + sisa_kotak_ini



func tas_alam_penuh(kelompok: String, tambahan: Array = []) -> bool:
	for id in data_hasil_alam().get(kelompok, {}):
		if sisa_muat_alam(String(id), tambahan) > 0:
			return false
	return true



func muat_berurutan(daftar: Array, sudah: Array) -> Array:
	var ikut: = []
	var sementara: = sudah.duplicate()
	for id in daftar:
		if sisa_muat_alam(String(id), sementara) > 0:
			ikut.append(id)
			sementara.append(id)
	return ikut


func jumlah_hasil_alam(id: String) -> int:
	return int(hasil_alam.get(id, 0))



func nilai_tas() -> int:
	var total: = 0
	for id in hasil_alam:
		total += int(hasil_alam[id]) * int(info_hasil_alam(id).get("harga", 0))
	return total



func jual_hasil_alam(id: String, n: = -1) -> int:
	var ada: = jumlah_hasil_alam(id)
	if n < 0 or n > ada:
		n = ada
	if n <= 0:
		return 0
	var info: = info_hasil_alam(id)
	var uang_masuk: = n * int(info.get("harga", 0))
	hasil_alam[id] = ada - n
	if int(hasil_alam[id]) <= 0:
		hasil_alam.erase(id)
	uang += uang_masuk
	analitik.catat("jual_pasar", {"id": id, "n": n, "uang": uang_masuk})
	catat_transaksi("Jual %d %s di pasar" % [n, String(info.get("nama", id))], uang_masuk)
	data_berubah.emit()
	return uang_masuk




func buang_isi_tas(id: String, n: int) -> int:
	var sumber: Dictionary = tas_grosir if tas_grosir.has(id) else hasil_alam
	var ada: = int(sumber.get(id, 0))
	n = mini(n, ada)
	if n <= 0:
		return 0
	sumber[id] = ada - n
	if int(sumber[id]) <= 0:
		sumber.erase(id)
	data_berubah.emit()
	simpan()
	return n


func _di_jam(kunci: String) -> bool:
	var r: Array = aturan_hasil_alam(kunci, [0.0, 24.0])
	return menit >= float(r[0]) * 60.0 and menit <= float(r[1]) * 60.0



func alasan_tidak_bisa_mancing() -> String:
	if sedang_hujan():
		return "Sedang hujan, air sungai keruh dan deras. Tunggu reda dulu baru memancing."
	if not _di_jam("jam_mancing"):
		return "Sudah gelap, ikannya tidak kelihatan. Memancing lagi besok pagi saja."
	if energi < float(aturan_hasil_alam("energi_per_lempar", 3)):
		return "Pak Misran terlalu lelah untuk memancing. Istirahat dulu."
	if tas_alam_penuh("ikan"):
		return teks_tas_penuh()
	return ""



func teks_tas_penuh() -> String:
	var ikan: = 0
	var buah: = 0
	for id in hasil_alam:
		if int(hasil_alam[id]) <= 0:
			continue
		var d: = info_hasil_alam(String(id))
		if d.is_empty():
			continue
		if data_hasil_alam().get("ikan", {}).has(id):
			ikan += int(hasil_alam[id])
		else:
			buah += int(hasil_alam[id])
	var grosir: = 0
	for id in tas_grosir:
		grosir += maxi(int(tas_grosir[id]), 0)
	return "Tas penuh (%d kotak terpakai: %d ikan, %d buah, %d barang grosir). Jual ikan/buah ke Bu Ida di Pasar, atau bawa barang grosir ke warung supaya jadi stok." % [kotak_tas_terpakai(), ikan, buah, grosir]


func alasan_tidak_bisa_petik() -> String:
	if sedang_hujan():
		return "Sedang hujan, pohonnya licin. Tunggu reda dulu baru memetik buah."
	if not _di_jam("jam_petik"):
		return "Sudah gelap, buahnya tidak kelihatan. Petik buah besok pagi saja."
	if tas_alam_penuh("buah"):
		return teks_tas_penuh()
	return ""





func selesai_mancing(lemparan: = 0) -> void :
	analitik.catat("mancing", {"lempar": lemparan})
	if lemparan > 0:
		majukan_waktu(float(aturan_hasil_alam("menit_per_lempar", 3)) * lemparan)
	data_berubah.emit()



func selesai_petik(dapat: = true) -> void :
	if not dapat:
		return
	analitik.catat("petik_buah")
	kebun_petik_hari = hari
	_selesai_hasil_alam("menit_petik", 20, "energi_petik", 0)






var kebun: = {}

func waktu_hari() -> float:
	return float(hari) + menit / 1440.0


func data_pohon() -> Dictionary:
	return data_hasil_alam().get("pohon", {})




func kebun_buah() -> Dictionary:
	var sekarang: = waktu_hari()
	for id in kebun.keys():
		if not data_pohon().has(id):
			kebun.erase(id)
	for id in data_pohon():
		var p: Dictionary = data_pohon()[id]
		var n: = int(p.get("jumlah", 4))
		if kebun.has(id) and (kebun[id] as Array).size() == n:
			continue
		var masa: = float(p.get("hari_tumbuh", 3))
		var daftar: Array = []
		for i in n:
			daftar.append(sekarang - 0.1 if randf() < 0.4 else sekarang + randf_range(0.15, masa))
		kebun[id] = daftar
	return kebun



func tumbuh_buah(id_pohon: String, i: int) -> float:
	var masa: = float(data_pohon().get(id_pohon, {}).get("hari_tumbuh", 3))
	var sisa: = float(kebun_buah()[id_pohon][i]) - waktu_hari()
	return clampf(1.0 - sisa / masa, 0.0, 1.0)


func buah_matang(id_pohon: String, i: int) -> bool:
	return float(kebun_buah()[id_pohon][i]) <= waktu_hari()


func jumlah_buah_matang(id_pohon: = "") -> int:
	var n: = 0
	for id in kebun_buah():
		if id_pohon != "" and id != id_pohon:
			continue
		for i in (kebun[id] as Array).size():
			if buah_matang(String(id), i):
				n += 1
	return n



func sisa_hari_buah(id_pohon: String, i: int) -> int:
	return maxi(int(ceil(float(kebun_buah()[id_pohon][i]) - waktu_hari())), 0)



func petik_buah_kebun(id_pohon: String, i: int) -> String:
	if not buah_matang(id_pohon, i):
		return ""
	var p: Dictionary = data_pohon()[id_pohon]
	kebun[id_pohon][i] = waktu_hari() + float(p.get("hari_tumbuh", 3)) * randf_range(0.85, 1.15)
	return String(p.get("buah", id_pohon))




const HARI_PASAR_LIBUR: = ["Selasa", "Kamis"]

func pasar_buka_hari_ini() -> bool:
	return not (nama_hari() in HARI_PASAR_LIBUR)


func bu_ida_di_pasar() -> bool:
	return pasar_buka_hari_ini() and menit >= 6 * 60.0 and menit < 21 * 60.0









const KOTAK_TAS: = 16
const ISI_KOTAK_GROSIR: = 10
const PELUANG_GROSIR_MURAH: = 0.45
const GROSIR_MURAH: = [0.85, 0.9]
const GROSIR_MAHAL: = [1.05, 1.2]
var tas_grosir: = {}


func grosir_buka() -> bool:
	return bu_ida_di_pasar()



func barang_grosir() -> Array:
	var hasil: = []
	for id in barang_belanja():
		if not terbuka(id) or BARANG_TITIPAN.has(id) or ada_promo(id):
			continue
		var h: = harga_grosir(id)
		if h > 0:
			hasil.append({"id": id, "harga": h})
	return hasil


func harga_grosir(id: String) -> int:
	if not katalog.has(id):
		return 0
	var r: = RandomNumberGenerator.new()
	r.seed = hash("grosir:%d:%s:%d" % [hari, id, slot_aktif])
	var online: = harga_modal(id)
	var langkah: = 50 if online < 1000 else 100
	if r.randf() < PELUANG_GROSIR_MURAH:
		var h: = int(round(online * r.randf_range(GROSIR_MURAH[0], GROSIR_MURAH[1]) / langkah)) * langkah
		return clampi(h, langkah, maxi(online - langkah, langkah))
	var m: = int(round(online * r.randf_range(GROSIR_MAHAL[0], GROSIR_MAHAL[1]) / langkah)) * langkah
	return maxi(m, online + langkah)


func kotak_grosir(id: String) -> int:
	return ceili(int(tas_grosir.get(id, 0)) / float(ISI_KOTAK_GROSIR))


func kotak_tas_terpakai() -> int:
	return _kotak_terpakai_isi(hasil_alam)




func _kotak_terpakai_isi(isi_alam: Dictionary) -> int:
	var n: = 0
	for id in isi_alam:
		if int(isi_alam[id]) > 0 and not info_hasil_alam(String(id)).is_empty():
			n += ceili(int(isi_alam[id]) / float(ISI_KOTAK_ALAM))
	for id in tas_grosir:
		if int(tas_grosir[id]) > 0:
			n += kotak_grosir(String(id))
	return n



func sisa_muat_grosir(id: String) -> int:
	var ada: = int(tas_grosir.get(id, 0))
	var sisa_kotak_ini: = (ISI_KOTAK_GROSIR - ada % ISI_KOTAK_GROSIR) % ISI_KOTAK_GROSIR
	return maxi(KOTAK_TAS - kotak_tas_terpakai(), 0) * ISI_KOTAK_GROSIR + sisa_kotak_ini


func jumlah_tas_grosir() -> int:
	var n: = 0
	for id in tas_grosir:
		n += int(tas_grosir[id])
	return n


func alasan_tidak_bisa_grosir(id: String, jumlah: int) -> String:
	if not grosir_buka():
		return "Kios grosir sudah tutup. Buka 06.00-21.00, libur Selasa & Kamis."
	if wajib_etalase and not punya_upgrade("etalase"):
		return "Beli etalase kaca dulu lewat tombol Upgrade warung."
	var h: = harga_grosir(id)
	if h <= 0 or not terbuka(id) or ada_promo(id):
		return "Barang ini tidak dijual di grosir hari ini."
	if jumlah > sisa_muat_stok(id):
		return alasan_stok_penuh(id)
	if jumlah > sisa_muat_grosir(id):
		return "Tas sudah penuh. Bawa dulu isinya ke warung, atau jual ikan & buah ke Bu Ida."
	if uang < h * jumlah:
		return "Uang tidak cukup (%s)." % format_rupiah(h * jumlah)
	return ""


func beli_grosir(id: String, jumlah: int) -> String:
	var alasan: = alasan_tidak_bisa_grosir(id, jumlah)
	if alasan != "":
		return alasan
	var biaya: = harga_grosir(id) * jumlah
	uang -= biaya
	tas_grosir[id] = int(tas_grosir.get(id, 0)) + jumlah
	belanja_hari += biaya
	catat_transaksi("Grosir pasar %d %s" % [jumlah, String(data_barang(id)["nama"]).to_lower()], - biaya)
	analitik.catat("beli_grosir", {"id": id, "n": jumlah, "uang": biaya})
	data_berubah.emit()
	return ""





func batal_grosir(id: String, jumlah: int, harga: int) -> String:
	if int(tas_grosir.get(id, 0)) < jumlah:
		return "Barang itu sudah tidak ada di Tas."
	var kembali: = harga * jumlah
	uang += kembali
	tas_grosir[id] = int(tas_grosir.get(id, 0)) - jumlah
	if int(tas_grosir[id]) <= 0:
		tas_grosir.erase(id)
	belanja_hari = maxi(belanja_hari - kembali, 0)
	catat_transaksi("Batal grosir %d %s" % [jumlah, String(data_barang(id)["nama"]).to_lower()], kembali)
	data_berubah.emit()
	return ""











const LEVEL_TITIPAN: = 1
const HARI_TITIPAN_PERTAMA: = 3
const JUMLAH_TITIP: = 30
const JUMLAH_TITIP_LEVEL: = [[8, 30], [5, 20], [1, 10]]


func jumlah_titip() -> int:
	for p in JUMLAH_TITIP_LEVEL:
		if level() >= int(p[0]):
			return int(p[1])
	return 10
const HARI_BASI_ROTI: = 7
const JEDA_SALES: = [4, 7]
const SALES_TITIPAN: = {
	"roti": {"tipe": "sales_roti", "nama": "Kang Dede", "sebutan_sales": "sales roti", "basi": true}, 
	"jamu": {"tipe": "sales_jamu", "nama": "Kang Oding", "sebutan_sales": "sales jamu", "basi": false}, 
}



var titipan: = {}
var basi_baru: = 0


func titipan_sales(id: String) -> bool:
	return SALES_TITIPAN.has(id)


func harga_titip(id: String) -> int:
	return int(katalog[id]["modal"])



func _rapikan_batch(id: String) -> void :
	var t: Dictionary = titipan[id]
	var batch: Array = t.get("batch", [])
	var total: = 0
	for b in batch:
		total += int(b[1])
	var lebih: = total - int(stok.get(id, 0))
	while lebih > 0 and not batch.is_empty():
		var ambil: = mini(lebih, int(batch[0][1]))
		batch[0][1] = int(batch[0][1]) - ambil
		lebih -= ambil
		if int(batch[0][1]) <= 0:
			batch.pop_front()
	if lebih < 0:
		batch.append([hari, - lebih])
	t["batch"] = batch


func _atur_titipan_pagi() -> void :
	basi_baru = 0
	if level() < LEVEL_TITIPAN:
		return
	for id in SALES_TITIPAN:
		if not titipan.has(id):

			titipan[id] = {"datang": maxi(hari, HARI_TITIPAN_PERTAMA) + (1 if id == "jamu" else 0), "menit": -1, "menit_hari": -1, "awal": 0, 
				"basi": 0, "batch": [], "kurang": 0, "kunjungan": 0}
		var t: Dictionary = titipan[id]
		if bool(SALES_TITIPAN[id]["basi"]) and int(t["kunjungan"]) > 0:
			_rapikan_batch(id)
			var batch: Array = t["batch"]
			while not batch.is_empty() and hari - int(batch[0][0]) >= HARI_BASI_ROTI:
				var n: = int(batch[0][1])
				stok[id] = maxi(int(stok.get(id, 0)) - n, 0)
				t["basi"] = int(t["basi"]) + n
				basi_baru += n
				batch.pop_front()

		if int(t["kunjungan"]) > 0 and int(t["kurang"]) <= 0 and int(stok.get(id, 0)) <= 0 and int(t["datang"]) > hari:
			t["datang"] = hari
		if int(t["datang"]) <= hari:
			t["menit"] = randi_range(10 * 60, 15 * 60)
			t["menit_hari"] = hari



func sales_titipan_sekarang() -> String:
	if status_hari != "buka" or level() < LEVEL_TITIPAN:
		return ""



	for id in titipan:
		var th: Dictionary = titipan[id]
		if int(th["kunjungan"]) > 0 and int(th["kurang"]) <= 0 and int(stok.get(id, 0)) <= 0 and not (int(th["datang"]) <= hari and int(th.get("menit_hari", -1)) == hari):
			var jam: = int(menit) + randi_range(30, 90)
			if jam < jam_wajib_tutup() - 20:
				th["datang"] = hari
				th["menit"] = jam
				th["menit_hari"] = hari
	for id in titipan:
		var t: Dictionary = titipan[id]
		if int(t["datang"]) <= hari and int(t.get("menit_hari", -1)) == hari and menit >= float(t["menit"]):
			return String(id)
	return ""



func kunjungan_titipan(id: String) -> Dictionary:
	var t: Dictionary = titipan[id]
	var pertama: = int(t["kunjungan"]) == 0
	if bool(SALES_TITIPAN[id]["basi"]):
		_rapikan_batch(id)
	var sisa: = int(stok.get(id, 0))
	var terjual: = 0 if pertama else maxi(int(t["awal"]) - sisa - int(t["basi"]), 0)
	var tagihan: = terjual * harga_titip(id) + int(t["kurang"])
	_tarik_qris_untuk(tagihan, "Ambil saldo QRIS untuk bayar titipan")
	var bayar: = mini(tagihan, maxi(uang, 0))
	uang -= bayar
	t["kurang"] = tagihan - bayar
	var nama_b: = String(data_barang(id)["nama"]).to_lower()
	if bayar > 0:
		belanja_hari += bayar
		catat_transaksi("Bayar titipan %s ke %s (%d laku)" % [nama_b, String(SALES_TITIPAN[id]["nama"]), terjual], - bayar)
	if pertama and not terbuka(id):
		barang_terbuka.append(id)

	var tambah: = 0 if int(t["kurang"]) > 0 else maxi(jumlah_titip() - sisa, 0)
	stok[id] = sisa + tambah
	if bool(SALES_TITIPAN[id]["basi"]) and tambah > 0:
		(t["batch"] as Array).append([hari, tambah])
	var basi: = int(t["basi"])
	t["awal"] = int(stok[id])
	t["basi"] = 0
	t["kunjungan"] = int(t["kunjungan"]) + 1
	t["datang"] = hari + randi_range(JEDA_SALES[0], JEDA_SALES[1])
	t["menit"] = -1
	t["menit_hari"] = -1
	analitik.catat("titipan", {"id": id, "laku": terjual, "bayar": bayar, "basi": basi, "isi": tambah})
	data_berubah.emit()
	return {"pertama": pertama, "terjual": terjual, "tagihan": tagihan, "bayar": bayar, "kurang": int(t["kurang"]), 
		"basi": basi, "tambah": tambah, "stok": int(stok[id]), "datang": int(t["datang"])}



func bongkar_tas_grosir() -> Dictionary:
	var pindah: = {}
	for id in tas_grosir:
		if stok.has(id) and int(tas_grosir[id]) > 0:
			stok[id] = int(stok[id]) + int(tas_grosir[id])
			pindah[id] = int(tas_grosir[id])
	tas_grosir = {}
	if not pindah.is_empty():
		data_berubah.emit()
	return pindah



func kebun_bisa_dikunjungi() -> bool:
	return not sedang_hujan() and _di_jam("jam_petik")


func sungai_bisa_dipancing() -> bool:
	return not sedang_hujan() and _di_jam("jam_mancing")


func _selesai_hasil_alam(kunci_menit: String, menit_bawaan: float, kunci_energi: String, energi_bawaan: float) -> void :
	var awal: = energi
	majukan_waktu(float(aturan_hasil_alam(kunci_menit, menit_bawaan)))
	energi = maxf(minf(energi, awal - float(aturan_hasil_alam(kunci_energi, energi_bawaan))), 0.0)
	data_berubah.emit()




var cara_layani: = "seret"

var yang_baru_dilihat: = ""




func layani_dengan_klik() -> bool:
	return cara_layani == "ketuk" and tutorial_langkah == "" and not mode_latihan


func atur_cara_layani(cara: String) -> void :
	cara_layani = "ketuk" if cara == "ketuk" else "seret"
	simpan_pengaturan()




var nama_diganti: = 0


func ganti_nama_gratis() -> bool:
	return nama_diganti <= 0



func cek_nama_warung_baru(teks: String) -> String:
	var rapi: = rapikan_nama_warung(teks)
	if rapi == "":
		return "Tulis nama warungnya dulu, ya."
	if rapi == nama_warung:
		return "Namanya masih sama dengan sekarang."
	if papan != null and not papan.nama_pantas(rapi):
		return "Nama ini kurang pantas. Coba nama lain, ya."
	return ""



func ganti_nama_warung(teks: String) -> String:
	var alasan: = cek_nama_warung_baru(teks)
	if alasan != "":
		return alasan
	nama_warung = rapikan_nama_warung(teks)
	nama_diganti += 1
	analitik.catat("ganti_nama", {"ke": nama_diganti})
	simpan()
	data_berubah.emit()
	if papan != null:
		papan.nama_ditolak = false
		papan.segarkan(true)
	return ""






const FOLDER_CADANGAN_VERSI: = "user://cadangan_versi"


func _baca_build_terakhir() -> int:
	var cfg: = ConfigFile.new()
	if cfg.load(FILE_PENGATURAN) != OK:
		return -1
	return int(cfg.get_value("rilis", "build_terakhir", -1))


func _cadangkan_saat_ganti_versi(kode_lama: int) -> void :
	var kode_baru: int = load("res://scripts/cek_versi.gd").kode_sekarang()
	if kode_lama == kode_baru:
		return
	var file_simpanan: Array = []
	var dir: = DirAccess.open("user://")
	if dir != null:
		for f in dir.get_files():
			if f.begins_with("simpanan") and f.ends_with(".json"):
				file_simpanan.append(f)
	if not file_simpanan.is_empty():
		var tujuan: = "%s/build_%d" % [FOLDER_CADANGAN_VERSI, kode_lama]

		var akar: = DirAccess.open(FOLDER_CADANGAN_VERSI)
		if akar != null:
			for sub in akar.get_directories():
				var d: = DirAccess.open(FOLDER_CADANGAN_VERSI + "/" + sub)
				if d != null:
					for f in d.get_files():
						d.remove(f)
				akar.remove(sub)
		DirAccess.make_dir_recursive_absolute(tujuan)
		for f in file_simpanan:
			DirAccess.copy_absolute("user://" + f, tujuan + "/" + f)
	simpan_pengaturan()
