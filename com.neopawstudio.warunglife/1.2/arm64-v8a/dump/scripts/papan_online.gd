extends Node






signal diperbarui

const URL: = "https://vfeihrxdwynivqcksxwl.supabase.co/rest/v1/rpc/"
const KUNCI_PUBLIK: = "sb_publishable_bGjm_-NNAqleprvQoE3dLA_IVYxzKmr"
const RAHASIA: = "286783789c42ce2d58436f6a42b7ea87f3eaa6ace75a188f"
const FILE_CACHE: = "user://papan_cache.json"
const FILE_HP: = "user://papan_hp.cfg"
const UMUR_CACHE: = 600.0



const JEDA_KIRIM: = 600.0
const SLOT_PAPAN: = 1800
const SELANG_OTOMATIS: = 600.0





const URL_SAKLAR: = "https://neopawstudio.github.io/versi.json"
const CEK_SAKLAR: = 900.0


const MUNDUR_AWAL: = 180.0
const MUNDUR_MAKS: = 1800.0
var jeda_server: = false
var _saklar_dicek: = -1000000000.0
var _gagal_beruntun: = 0
var _tunda_sampai: = -1000000000.0


static var paksa_kirim: = false

var status: = ""
var nama_ditolak: = false
var _data: = {}
var _waktu_ambil: = -1000000000.0
var _waktu_kirim: = -1000000000.0
var _terkirim: = ""
var _id_data: = ""
var _jalan: = 0
var _laporan: = {}
var _slot_ambil: = -1
var _jeda_slot: = 60.0
var _hp_dicoba: = {}


func _ready() -> void :
	process_mode = Node.PROCESS_MODE_ALWAYS
	_jeda_slot = randf_range(30.0, 240.0)
	_muat_cache()
	var t: = Timer.new()
	t.wait_time = SELANG_OTOMATIS
	t.timeout.connect( func(): segarkan())
	add_child(t)

	GameState.get_tree().create_timer(randf_range(60.0, SELANG_OTOMATIS)).timeout.connect( func():
		segarkan()
		t.start())



func boleh_otomatis() -> bool:
	return not jeda_server and Time.get_ticks_msec() / 1000.0 >= _tunda_sampai


func terapkan_saklar(isi: Dictionary) -> void :
	_saklar_dicek = Time.get_ticks_msec() / 1000.0
	jeda_server = bool(isi.get("jeda_server", false))


func _cek_saklar() -> void :
	if Time.get_ticks_msec() / 1000.0 - _saklar_dicek < CEK_SAKLAR:
		return
	_saklar_dicek = Time.get_ticks_msec() / 1000.0
	var req: = HTTPRequest.new()
	req.timeout = 8.0
	add_child(req)

	if req.request(URL_SAKLAR + "?t=%d" % (int(Time.get_unix_time_from_system()) / 300)) == OK:
		var jawab: Array = await req.request_completed
		if jawab[0] == HTTPRequest.RESULT_SUCCESS and int(jawab[1]) == 200:
			var isi = JSON.parse_string((jawab[3] as PackedByteArray).get_string_from_utf8())
			if typeof(isi) == TYPE_DICTIONARY:
				jeda_server = bool(isi.get("jeda_server", false))
	req.queue_free()


func catat_hasil_server(kode_http: int, berhasil_terhubung: bool) -> void :
	if berhasil_terhubung and kode_http > 0 and kode_http < 500:
		_gagal_beruntun = 0
		_tunda_sampai = -1000000000.0
		return
	_gagal_beruntun += 1
	var tunda: = minf(MUNDUR_AWAL * pow(2.0, _gagal_beruntun - 1), MUNDUR_MAKS) * randf_range(0.8, 1.2)
	_tunda_sampai = Time.get_ticks_msec() / 1000.0 + tunda


func data(tab: String) -> Dictionary:
	return _data.get(tab, {})


func id_data() -> String:
	return _id_data


func sedang_memuat() -> bool:
	return _jalan > 0




const KATA_TERLARANG: = ["anjing", "anjeng", "bangsat", "babi", "kontol", "memek", "ngentot", "ngewe", "jancok", 
	"jancuk", "cuki", "goblok", "goblog", "tolol", "kampret", "bajingan", "pepek", "peler", "pantek", "puki", "lonte", 
	"pelacur", "bencong", "banci", "idiot", "kafir", "fuck", "shit", "bitch", "pussy", "nigga", "nigger", "porn", 
	"bokep", "jembut", "silit", "judol", "slot gacor", "gacor", "togel", "http", "www", ".com"]
const KATA_TERLARANG_UTUH: = ["perek", "asu", "tai", "taik", "bego", "dick", "sange", "coli", "itil", "setan", "iblis"]


static func nama_pantas(nama: String) -> bool:
	var n: = nama.to_lower()
	for i in "0134578@$!|".length():
		n = n.replace("0134578@$!|"[i], "oieastbasil"[i])
	var rapat: = RegEx.create_from_string("[^a-z]").sub(n, "", true)
	for k in KATA_TERLARANG:
		if n.contains(k) or (RegEx.create_from_string("^[a-z]+$").search(k) != null and rapat.contains(k)):
			return false
	for k in KATA_TERLARANG_UTUH:
		if RegEx.create_from_string("(^|[^a-z])" + k + "([^a-z]|$)").search(n) != null:
			return false
	return true


static func kode(id: String) -> String:
	return id.md5_text().substr(0, 12)


func boleh_kirim() -> bool:
	return paksa_kirim or not (GameState.GOD_MODE or GameState.mode_latihan)




func segarkan(paksa: = false, umur_maks: = UMUR_CACHE) -> void :
	if GameState.id_papan == "" or _jalan > 0:
		return
	await _cek_saklar()

	if jeda_server or ( not boleh_otomatis() and not (paksa and _gagal_beruntun == 0)):
		return
	await kirim()
	if _gagal_beruntun > 0:
		return
	await _catat_hp()
	if _gagal_beruntun == 0 and _perlu_ambil(paksa, umur_maks):
		await ambil()




static func jenis_hp(nama_os: String, model: String) -> String:
	if nama_os == "Android":
		return "android"
	if nama_os == "iOS":
		return "ipad" if model.to_lower().begins_with("ipad") else "iphone"
	return ""




func _catat_hp(hp: = jenis_hp(OS.get_name(), OS.get_model_name())) -> void :
	var id: = GameState.id_papan
	if hp == "" or id == "" or _hp_dicoba.has(id) or not boleh_kirim():
		return
	if GameState.analitik == null or not GameState.analitik.aktif:
		return
	_hp_dicoba[id] = true
	var cfg: = ConfigFile.new()
	cfg.load(FILE_HP)
	if String(cfg.get_value("hp", id, "")) == hp:
		return
	var hasil = await _rpc("catat_hp_warung", {"p_id": id, "p_os": hp, "p_tanda": _tanda("hp|%s|%s" % [id, hp])})
	if typeof(hasil) == TYPE_DICTIONARY and hasil.get("ok", false):
		cfg.set_value("hp", id, hp)
		cfg.save(FILE_HP)


func _slot_sekarang() -> int:
	return int(Time.get_unix_time_from_system()) / SLOT_PAPAN




func _perlu_ambil(paksa: bool, umur_maks: float) -> bool:
	if _id_data != GameState.id_papan or _slot_ambil < 0:
		return true
	var slot: = _slot_sekarang()
	var detik_dalam_slot: = int(Time.get_unix_time_from_system()) % SLOT_PAPAN
	if slot > _slot_ambil and detik_dalam_slot >= _jeda_slot:
		return true
	return paksa and Time.get_ticks_msec() / 1000.0 - _waktu_ambil > minf(umur_maks, 120.0)


func kirim() -> void :
	if not boleh_kirim() or GameState.id_papan == "":
		return
	var id: = GameState.id_papan
	var nama: = GameState.nama_warung_lengkap().left(40)
	var total: = GameState.total_pembeli
	var bulan: = GameState.bulan_sekarang()
	var jumlah_bulan: = GameState.pembeli_bulan_ini()
	var bintang: = GameState.bintang()
	var level: = GameState.level()
	var isi: = "%s|%s|%d|%s|%d|%d|%d" % [id, nama, total, bulan, jumlah_bulan, bintang, level]
	if isi == _terkirim or Time.get_ticks_msec() / 1000.0 - _waktu_kirim < JEDA_KIRIM:
		return
	_waktu_kirim = Time.get_ticks_msec() / 1000.0


	var hari_game: = maxi(GameState.hari, 1)

	var omzet: = GameState.omzet_semua()
	var omzet_bulan: = GameState.omzet_bulan_ini()
	var minggu: = GameState.minggu_sekarang()
	var pembeli_minggu: = GameState.pembeli_minggu_ini()
	var omzet_minggu: = GameState.omzet_minggu_ini()
	var isi5: = isi + "|%d|%d|%d|%s|%d|%d" % [hari_game, omzet, omzet_bulan, minggu, pembeli_minggu, omzet_minggu]
	if isi5 == _terkirim:
		return
	var hasil = await _rpc("kirim_skor5", {"p_id": id, "p_nama": nama, "p_total": total, "p_bulan": bulan, 
		"p_total_bulan": jumlah_bulan, "p_bintang": bintang, "p_level": level, "p_hari": hari_game, 
		"p_omzet": omzet, "p_omzet_bulan": omzet_bulan, "p_minggu": minggu, "p_total_minggu": pembeli_minggu, 
		"p_omzet_minggu": omzet_minggu, "p_tanda": _tanda(isi5)})


	if typeof(hasil) != TYPE_DICTIONARY:
		return
	var ditolak5: bool = not hasil.get("ok", false) and hasil.get("alasan", "") == "nama"
	if ditolak5 != nama_ditolak:
		nama_ditolak = ditolak5
		diperbarui.emit()
	if hasil.get("ok", false):
		_terkirim = isi5


func ambil() -> void :
	var id: = GameState.id_papan
	status = "memuat"
	diperbarui.emit()
	var baru: = {}



	var id_hp: = id_hp_jempol()
	for tab in ["semua", "minggu", "bulan"]:
		var hasil = await _rpc("ambil_papan2", {"p_jenis": tab, "p_id": id, "p_hp": id_hp})
		if typeof(hasil) != TYPE_DICTIONARY or not hasil.has("daftar"):
			status = "gagal"
			diperbarui.emit()
			return
		baru[tab] = hasil
	_data = baru
	_id_data = id
	_waktu_ambil = Time.get_ticks_msec() / 1000.0
	_slot_ambil = _slot_sekarang()
	status = "ok"
	_simpan_cache()
	diperbarui.emit()
	_ambil_baik_hati()
	_ambil_foto()







var _baik_hati: = {}


func pendukung_awal(kode_warung: String, _tab: = "semua") -> bool:
	return kode_warung in (_baik_hati.get("kode", []) as Array)


func pendukung_saya() -> bool:
	return bool(_baik_hati.get("saya", false)) and String(_baik_hati.get("id", "")) == GameState.id_papan


func peduli(kode_warung: String) -> bool:
	return kode_warung in (_baik_hati.get("peduli", []) as Array)


func peduli_saya() -> bool:
	return bool(_baik_hati.get("peduli_saya", false)) and String(_baik_hati.get("id", "")) == GameState.id_papan


func _ambil_baik_hati() -> void :
	var id: = GameState.id_papan
	var hasil = await _rpc("ambil_warga_baik_hati", {"p_id": id})
	if typeof(hasil) != TYPE_DICTIONARY or typeof(hasil.get("kode")) != TYPE_ARRAY or id != GameState.id_papan:
		return
	_baik_hati = {"id": id, "kode": hasil["kode"], "saya": bool(hasil.get("saya", false)), 
		"peduli": hasil.get("peduli", []) if typeof(hasil.get("peduli")) == TYPE_ARRAY else [], 
		"peduli_saya": bool(hasil.get("peduli_saya", false))}
	_simpan_cache()
	diperbarui.emit()
	_cek_baik_hati()


var _tandai_dicoba: = {}




func _cek_baik_hati() -> void :
	var id: = GameState.id_papan
	if id == "" or String(_baik_hati.get("id", "")) != id or bool(_baik_hati.get("peduli_saya", false)) or _tandai_dicoba.has(id):
		return
	var bukti: Array = GameState.bukti_pendukung_awal()
	if bukti.is_empty():
		return
	if bool(_baik_hati.get("saya", false)) and (String(bukti[0]) != "kode" or GameState.kode_pendukung == ""):
		return
	_tandai_dicoba[id] = true
	var kode_bukti: = String(bukti[1]).to_upper().replace(" ", "")
	var hasil = await _rpc("tandai_warga_baik_hati", {"p_id": id, "p_kode": kode_bukti, "p_jenis": String(bukti[0]), 
		"p_tanda": _tanda("%s|%s|%s" % [id, kode_bukti, String(bukti[0])])})
	if typeof(hasil) == TYPE_DICTIONARY and hasil.get("ok", false) and String(_baik_hati.get("id", "")) == id:
		_baik_hati["saya"] = true
		_baik_hati["peduli_saya"] = int(hasil.get("tingkat", 1)) >= 2
		_simpan_cache()
		diperbarui.emit()



func id_hp_jempol() -> String:
	return String(GameState.analitik.id_perangkat) if GameState.analitik != null else ""


func ada_jempol() -> bool:
	var d: Dictionary = _data.get("semua", {})
	var daftar: Array = d.get("daftar", [])
	return d.has("jempol_saya") or ( not daftar.is_empty() and (daftar[0] as Array).size() > 6)


func jempol_saya() -> int:
	return int(_data.get("semua", {}).get("jempol_saya", 0))



func beri_jempol(kode_warung: String) -> Dictionary:
	if GameState.id_papan == "" or id_hp_jempol().length() < 16:
		return {"ok": false, "alasan": "data"}
	var hasil = await _rpc("beri_jempol", {"p_id": GameState.id_papan, "p_kode": kode_warung, "p_hp": id_hp_jempol()})
	if typeof(hasil) != TYPE_DICTIONARY:
		return {"ok": false, "alasan": "offline"}
	if hasil.get("ok", false):

		for tab in _data:
			for b in _data[tab].get("daftar", []):
				if String(b[2]) == kode_warung and (b as Array).size() > 7:
					b[6] = int(hasil.get("jempol", int(b[6]) + 1))
					b[7] = true
		_simpan_cache()
		diperbarui.emit()
	return hasil


func laporkan(kode_warung: String) -> bool:
	if _laporan.has(kode_warung) or GameState.id_papan == "":
		return true



	var id_hp: = String(GameState.analitik.id_perangkat) if GameState.analitik != null else ""
	var hasil = null
	if id_hp.length() >= 16:
		hasil = await _rpc("laporkan_nama2", {"p_id": GameState.id_papan, "p_kode": kode_warung, "p_hp": id_hp})
	if typeof(hasil) != TYPE_DICTIONARY:
		hasil = await _rpc("laporkan_nama", {"p_id": GameState.id_papan, "p_kode": kode_warung})
	var ok: bool = typeof(hasil) == TYPE_DICTIONARY and hasil.get("ok", false)
	if ok:
		_laporan[kode_warung] = true
	return ok


func sudah_dilaporkan(kode_warung: String) -> bool:
	return _laporan.has(kode_warung)



func hapus(id: String) -> void :
	if id != "":
		await _rpc("hapus_skor", {"p_id": id})




func buat_kode_pendukung(token: String, produk: String) -> String:
	var id: = GameState.id_papan
	var hasil = await _rpc("buat_kode_pendukung", {"p_id": id, "p_token": token, "p_produk": produk, 
		"p_tanda": _tanda("%s|%s|%s" % [id, token, produk])})
	if typeof(hasil) == TYPE_DICTIONARY and hasil.get("ok", false):
		return String(hasil.get("kode", ""))
	return ""





const URL_VERIFIKASI: = "https://vfeihrxdwynivqcksxwl.supabase.co/functions/v1/verifikasi-pembelian"

func verifikasi_pembelian(token: String, produk: String) -> Dictionary:
	var req: = HTTPRequest.new()
	req.timeout = 20.0
	add_child(req)
	var hasil: Dictionary = {}
	var isi: = JSON.stringify({"id": GameState.id_papan, "token": token, "produk": produk, "platform": "android"})
	if req.request(URL_VERIFIKASI, ["apikey: " + KUNCI_PUBLIK, "Content-Type: application/json"], HTTPClient.METHOD_POST, isi) == OK:
		var jawab: Array = await req.request_completed
		if jawab[0] == HTTPRequest.RESULT_SUCCESS and int(jawab[1]) == 200:
			var j = JSON.parse_string((jawab[3] as PackedByteArray).get_string_from_utf8())
			if typeof(j) == TYPE_DICTIONARY:
				hasil = j
	req.queue_free()
	return hasil




func cek_bebas_iklan(kode: String) -> int:
	var hasil = await _rpc("cek_bebas_iklan", {"p_kode": kode})
	if typeof(hasil) != TYPE_DICTIONARY or not hasil.get("ok", false):
		return -1
	return 1 if hasil.get("bebas", false) else 0




func cek_hak_bebas_iklan(id: String) -> int:
	var hasil = await _rpc("cek_hak_bebas_iklan", {"p_id": id})
	if typeof(hasil) != TYPE_DICTIONARY or not hasil.get("ok", false):
		return -1
	return 1 if hasil.get("bebas", false) else 0



func cek_kode_pendukung(kode: String) -> int:
	var hasil = await _rpc("cek_kode_pendukung", {"p_kode": kode})
	if typeof(hasil) != TYPE_DICTIONARY or not hasil.get("ok", false):
		return -1
	return 1 if hasil.get("ada", false) else 0




func produk_kode_pendukung(kode: String) -> Dictionary:
	var hasil = await _rpc("cek_kode_pendukung2", {"p_kode": kode})
	if typeof(hasil) != TYPE_DICTIONARY or not hasil.get("ok", false):
		return {}
	return {"ada": bool(hasil.get("ada", false)), "produk": String(hasil.get("produk", "")) if hasil.get("produk") != null else ""}



func pakai_kode_promo(kode: String, id_perangkat: String) -> Dictionary:
	var hasil = await _rpc("pakai_kode_promo", {"p_kode": kode, "p_id": id_perangkat, 
		"p_tanda": _tanda("%s|%s" % [id_perangkat, kode])})
	return hasil if typeof(hasil) == TYPE_DICTIONARY else {}



func buat_kode_pindah(id_perangkat: String, data: String) -> Dictionary:
	var hasil = await _rpc("buat_kode_pindah", {"p_id": id_perangkat, "p_data": data, 
		"p_tanda": _tanda("%s|%s" % [id_perangkat, data.sha256_text()])}, 40.0)
	return hasil if typeof(hasil) == TYPE_DICTIONARY else {}


func ambil_kode_pindah(kode: String, id_perangkat: String) -> Dictionary:
	var hasil = await _rpc("ambil_kode_pindah", {"p_kode": kode, "p_id": id_perangkat, 
		"p_tanda": _tanda("%s|%s" % [id_perangkat, kode])}, 40.0)
	return hasil if typeof(hasil) == TYPE_DICTIONARY else {}






const FOTO_PROFIL: = preload("res://scripts/foto_profil.gd")
var _foto: = {}
var _kirim_foto_jalan: = false


func foto(kode_warung: String, tab: = "semua") -> int:
	var peta = _foto.get(tab, {})
	if not peta is Dictionary or not peta.has(kode_warung):
		peta = _foto.get("semua", {})
	return int(peta.get(kode_warung, 0)) if peta is Dictionary else 0


func _ambil_foto() -> void :
	var hasil = await _rpc("ambil_foto_papan", {})
	if typeof(hasil) == TYPE_DICTIONARY:
		_foto = hasil
		_simpan_cache()
		diperbarui.emit()
	kirim_foto()



func kirim_foto() -> void :
	var id: = GameState.id_papan
	var n: = FOTO_PROFIL.pilihan()
	if id == "" or _kirim_foto_jalan or not boleh_kirim() or not FOTO_PROFIL.pernah_memilih() or FOTO_PROFIL.sudah_terkirim(id):
		return
	_kirim_foto_jalan = true
	var hasil = await _rpc("atur_foto_profil", {"p_id": id, "p_foto": n, "p_tanda": _tanda("foto|%s|%d" % [id, n])})
	_kirim_foto_jalan = false
	if typeof(hasil) == TYPE_DICTIONARY and hasil.get("ok", false):
		FOTO_PROFIL.tandai_terkirim(id, n)





const FILE_ADU: = "user://adu_laris_tertunda.json"
const UMUR_PAPAN_ADU: = 300.0
var _papan_adu: = {}
var _waktu_papan_adu: = -1000000000.0
var _kirim_adu_jalan: = false
var status_adu: = ""


func papan_adu() -> Dictionary:
	return _papan_adu


func kirim_adu_laris(omzet: int, pembeli: int, hasil: String, rekaman: Array, minggu: String) -> void :
	var antre: = _antre_adu()
	antre.append({"id": GameState.id_papan, "omzet": omzet, "pembeli": pembeli, "hasil": hasil, "rekaman": rekaman, "minggu": minggu})
	while antre.size() > 5:
		antre.pop_front()
	_simpan_antre_adu(antre)
	await kirim_adu_tertunda()


func kirim_adu_tertunda() -> void :
	if _kirim_adu_jalan or not boleh_kirim():
		return
	var id_hp: = id_hp_jempol()
	if id_hp.length() < 8:
		return
	_kirim_adu_jalan = true
	var antre: = _antre_adu()
	var sisa_antre: = []
	for d in antre:
		if String(d.get("id", "")) == "":
			continue
		var isi: = "adu|%s|%s|%d|%d|%s" % [String(d["id"]), String(d["minggu"]), int(d["omzet"]), int(d["pembeli"]), String(d["hasil"])]
		var rek: Array = (d["rekaman"] as Array).map( func(x): return int(x))
		var hasil = await _rpc("kirim_adu_laris", {"p_id": String(d["id"]), "p_hp": id_hp, "p_minggu": String(d["minggu"]), 
			"p_omzet": int(d["omzet"]), "p_pembeli": int(d["pembeli"]), "p_hasil": String(d["hasil"]), "p_rekaman": rek, 
			"p_tanda": _tanda(isi)})

		if typeof(hasil) != TYPE_DICTIONARY:
			sisa_antre.append(d)

	for d in _antre_adu():
		if not antre.has(d):
			sisa_antre.append(d)
	while sisa_antre.size() > 5:
		sisa_antre.pop_front()
	_simpan_antre_adu(sisa_antre)
	_kirim_adu_jalan = false
	_waktu_papan_adu = -1000000000.0


func ambil_papan_adu(paksa: = false) -> void :
	if status_adu == "memuat" or ( not paksa and Time.get_ticks_msec() / 1000.0 - _waktu_papan_adu < UMUR_PAPAN_ADU and not _papan_adu.is_empty()):
		return
	await kirim_adu_tertunda()
	status_adu = "memuat"
	diperbarui.emit()
	var hasil = await _rpc("ambil_papan_adu_laris", {"p_id": GameState.id_papan})
	if typeof(hasil) == TYPE_DICTIONARY and hasil.has("daftar"):
		_papan_adu = hasil
		_waktu_papan_adu = Time.get_ticks_msec() / 1000.0
		status_adu = "ok"
	else:
		status_adu = "gagal"
	diperbarui.emit()





const FILE_KERJA: = "user://kerja_tertunda.json"
var _papan_kerja: = {}
var _waktu_papan_kerja: = -1000000000.0
var _kirim_kerja_jalan: = false
var status_kerja: = ""


func papan_kerja(kerja: String) -> Dictionary:
	return (_papan_kerja.get("papan", {}) as Dictionary).get(kerja, {})


static func minggu_wib() -> String:
	var wib: = int(Time.get_unix_time_from_system()) + 7 * 3600
	var t: = Time.get_datetime_dict_from_unix_time(wib)
	var senin: = Time.get_datetime_dict_from_unix_time(wib - ((int(t["weekday"]) + 6) % 7) * 86400)
	return "%04d-%02d-%02d" % [senin["year"], senin["month"], senin["day"]]


func kirim_skor_kerja(kerja: String, skor: int, detik: float) -> void :
	if GameState.id_papan == "" or not boleh_kirim():
		return
	var antre: = _baca_json_array(FILE_KERJA)
	antre.append({"id": GameState.id_papan, "kerja": kerja, "skor": maxi(skor, 0), "detik": snappedf(clampf(detik, 0.0, 20.0), 0.1), 
		"minggu": minggu_wib()})
	while antre.size() > 10:
		antre.pop_front()
	_tulis_json(FILE_KERJA, antre)
	await kirim_kerja_tertunda()


func kirim_kerja_tertunda() -> void :
	if _kirim_kerja_jalan or not boleh_kirim():
		return
	var id_hp: = id_hp_jempol()
	if id_hp.length() < 8:
		return
	_kirim_kerja_jalan = true
	var sisa_antre: = []
	var dikirim: = _baca_json_array(FILE_KERJA)
	for d in dikirim:
		var detik: = "%.1f" % float(d["detik"])
		var isi: = "kerja|%s|%s|%s|%d|%s" % [String(d["id"]), String(d["minggu"]), String(d["kerja"]), int(d["skor"]), detik]
		var hasil = await _rpc("kirim_skor_kerja", {"p_id": String(d["id"]), "p_hp": id_hp, "p_minggu": String(d["minggu"]), 
			"p_kerja": String(d["kerja"]), "p_skor": int(d["skor"]), "p_detik": float(detik), "p_tanda": _tanda(isi)})
		if typeof(hasil) != TYPE_DICTIONARY:
			sisa_antre.append(d)

	for d in _baca_json_array(FILE_KERJA):
		if not dikirim.has(d):
			sisa_antre.append(d)
	while sisa_antre.size() > 10:
		sisa_antre.pop_front()
	_tulis_json(FILE_KERJA, sisa_antre)
	_kirim_kerja_jalan = false
	_waktu_papan_kerja = -1000000000.0


func ambil_papan_kerja(paksa: = false) -> void :
	if status_kerja == "memuat" or ( not paksa and Time.get_ticks_msec() / 1000.0 - _waktu_papan_kerja < 300.0 and not _papan_kerja.is_empty()):
		return
	await kirim_kerja_tertunda()
	status_kerja = "memuat"
	var hasil = await _rpc("ambil_papan_kerja", {"p_id": GameState.id_papan})
	if typeof(hasil) == TYPE_DICTIONARY and hasil.has("papan"):
		_papan_kerja = hasil
		_waktu_papan_kerja = Time.get_ticks_msec() / 1000.0
		status_kerja = "ok"
	else:
		status_kerja = "gagal"
	diperbarui.emit()


func _baca_json_array(berkas: String) -> Array:
	if not FileAccess.file_exists(berkas):
		return []
	var d = JSON.parse_string(FileAccess.get_file_as_string(berkas))
	return d if d is Array else []


func _tulis_json(berkas: String, isi: Variant) -> void :
	var f: = FileAccess.open(berkas, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(isi))


func _antre_adu() -> Array:
	if not FileAccess.file_exists(FILE_ADU):
		return []
	var d = JSON.parse_string(FileAccess.get_file_as_string(FILE_ADU))
	return d if d is Array else []


func _simpan_antre_adu(antre: Array) -> void :
	var f: = FileAccess.open(FILE_ADU, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(antre))


func _tanda(isi: String) -> String:
	var h: = HMACContext.new()
	h.start(HashingContext.HASH_SHA256, RAHASIA.to_utf8_buffer())
	h.update(isi.to_utf8_buffer())
	return h.finish().hex_encode()



func _rpc(fungsi: String, isi: Dictionary, batas_waktu: = 12.0) -> Variant:
	var req: = HTTPRequest.new()
	req.timeout = batas_waktu
	add_child(req)
	_jalan += 1
	var kepala: = ["apikey: " + KUNCI_PUBLIK, "Content-Type: application/json"]
	var hasil: Variant = null
	if req.request(URL + fungsi, kepala, HTTPClient.METHOD_POST, JSON.stringify(isi)) == OK:
		var jawab: Array = await req.request_completed
		catat_hasil_server(int(jawab[1]), jawab[0] == HTTPRequest.RESULT_SUCCESS)
		if jawab[0] == HTTPRequest.RESULT_SUCCESS and int(jawab[1]) == 200:
			hasil = JSON.parse_string((jawab[3] as PackedByteArray).get_string_from_utf8())
	_jalan -= 1
	req.queue_free()
	return hasil



func jam_diperbarui() -> String:
	var teks: = String(_data.get("semua", {}).get("diperbarui", ""))
	if teks.length() < 19:
		return ""
	var unix: = Time.get_unix_time_from_datetime_string(teks.substr(0, 19)) + 7 * 3600
	var d: = Time.get_datetime_dict_from_unix_time(unix)
	return "%02d.%02d" % [int(d["hour"]), int(d["minute"])]


func _simpan_cache() -> void :
	var f: = FileAccess.open(FILE_CACHE, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify({"id": _id_data, "data": _data, "baik_hati": _baik_hati, "foto": _foto}))


func _muat_cache() -> void :
	if not FileAccess.file_exists(FILE_CACHE):
		return
	var isi = JSON.parse_string(FileAccess.get_file_as_string(FILE_CACHE))
	if typeof(isi) == TYPE_DICTIONARY and typeof(isi.get("data")) == TYPE_DICTIONARY:
		_data = isi["data"]
		_id_data = String(isi.get("id", ""))
		if typeof(isi.get("baik_hati")) == TYPE_DICTIONARY:
			_baik_hati = isi["baik_hati"]
		if typeof(isi.get("foto")) == TYPE_DICTIONARY:
			_foto = isi["foto"]
		status = "ok"
