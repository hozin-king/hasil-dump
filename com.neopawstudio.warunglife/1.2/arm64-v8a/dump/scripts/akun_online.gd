extends Node












signal berubah
signal bonus_diterima(jumlah: int)

const URL_SUPABASE: = "https://vfeihrxdwynivqcksxwl.supabase.co"
const KUNCI_PUBLIK: = "sb_publishable_bGjm_-NNAqleprvQoE3dLA_IVYxzKmr"


const WEB_CLIENT_ID: = "817929311883-ovju5ccqlk2nj787svt662h5ommpgoln.apps.googleusercontent.com"


const IOS_CLIENT_ID: = "817929311883-598sp0u4imlto1utjrvc7mptc2docbrr.apps.googleusercontent.com"
const FILE_AKUN: = "user://akun.json"
const BONUS_TAUTAN: = 100000
const SELANG_KIRIM: = 600.0

signal _masuk_selesai(hasil: Dictionary)

var _sesi: = {}
var _plugin: Object = null
var _menunggu_masuk: = false
var _kode_apple: = ""
var _sibuk_kirim: = false
var bentrok: = false



var mundur: = false
var pesan_terakhir: = ""
const FILE_SESI_BERAKHIR: = "user://akun_sesi_berakhir.flag"
var _sesi_berakhir_dikabari: = false


func _ready() -> void :
	process_mode = Node.PROCESS_MODE_ALWAYS
	_muat_sesi()
	_siapkan_plugin()
	var t: = Timer.new()
	t.wait_time = SELANG_KIRIM
	t.autostart = true
	t.timeout.connect( func(): _otomatis())
	add_child(t)
	_req_latar = HTTPRequest.new()
	_req_latar.use_threads = true
	add_child(_req_latar)

	GameState.get_tree().create_timer(12.0, true, false, true).timeout.connect(_cek_awal)








var _req_latar: HTTPRequest = null
var _pakai_req_latar: = false


func _notification(what: int) -> void :
	if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_WM_CLOSE_REQUEST:
		if tertaut():
			_pakai_req_latar = true
			kirim()
			_pakai_req_latar = false
	elif what == NOTIFICATION_APPLICATION_RESUMED:


		if tertaut():
			_saat_kembali.call_deferred()


func _saat_kembali() -> void :


	var tunggu: = 0
	while _sibuk_kirim and tunggu < 100:
		await get_tree().create_timer(0.5, true, false, true).timeout
		tunggu += 1
	if tertaut():
		cek_bentrok()




func tersedia() -> bool:
	if not Engine.has_singleton("GodotGoogleLogin"):
		return false
	if _ios():
		return true
	return WEB_CLIENT_ID != ""


func _ios() -> bool:
	return OS.get_name() == "iOS"



func penyedia_tersedia() -> Array:
	if not tersedia():
		return []
	if not _ios():
		return ["google"]
	return ["apple", "google"] if IOS_CLIENT_ID != "" else ["apple"]



func penyedia() -> String:
	return String(_sesi.get("penyedia", "google"))



func nama_penyedia(p: = "") -> String:
	return "Apple" if (p if p != "" else penyedia()) == "apple" else "Google"


func tertaut() -> bool:
	return String(_sesi.get("segar", "")) != ""


func email() -> String:
	return String(_sesi.get("email", ""))


func versi_cloud() -> int:
	return int(_sesi.get("versi", 0))


func bonus_menunggu() -> bool:
	return bool(_sesi.get("bonus_tertunda", false))



func jam_disimpan() -> String:
	var t: = int(_sesi.get("disimpan", 0))
	if t <= 0:
		return ""
	var d: = Time.get_datetime_dict_from_unix_time(t + int(Time.get_time_zone_from_system().get("bias", 0)) * 60)
	return "%02d.%02d" % [int(d["hour"]), int(d["minute"])]




const FILE_AJAK: = "user://akun_ajak.json"
const JEDA_AJAK: = 3 * 24 * 3600

func perlu_ajak() -> bool:
	if not tersedia() or tertaut() or GameState.jumlah_slot_terisi() == 0:
		return false
	var terakhir: = 0
	if FileAccess.file_exists(FILE_AJAK):
		var isi = JSON.parse_string(FileAccess.get_file_as_string(FILE_AJAK))
		if typeof(isi) == TYPE_DICTIONARY:
			terakhir = int(isi.get("terakhir", 0))
	return int(Time.get_unix_time_from_system()) - terakhir >= JEDA_AJAK


func tandai_ajak() -> void :
	var f: = FileAccess.open(FILE_AJAK, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify({"terakhir": int(Time.get_unix_time_from_system())}))
		f.close()




func _muat_sesi() -> void :
	if not FileAccess.file_exists(FILE_AKUN):
		return
	var isi = JSON.parse_string(FileAccess.get_file_as_string(FILE_AKUN))
	if typeof(isi) == TYPE_DICTIONARY:
		_sesi = isi


func _tulis_sesi() -> void :
	var jalur: = ProjectSettings.globalize_path(FILE_AKUN)
	var f: = FileAccess.open(FILE_AKUN + ".tmp", FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify(_sesi))
	f.close()
	if FileAccess.file_exists(FILE_AKUN):
		DirAccess.remove_absolute(jalur)
	DirAccess.rename_absolute(jalur + ".tmp", jalur)


func _hapus_sesi() -> void :
	_sesi = {}
	if FileAccess.file_exists(FILE_AKUN):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(FILE_AKUN))
	bentrok = false
	_bentrok_dikabari = false
	cloud_kosong = false
	berubah.emit()


func _pakai_jawaban_token(j: Dictionary) -> void :
	var u: Dictionary = j.get("user", {}) if typeof(j.get("user")) == TYPE_DICTIONARY else {}
	_sesi["akses"] = String(j.get("access_token", ""))
	_sesi["segar"] = String(j.get("refresh_token", ""))
	_sesi["habis"] = int(Time.get_unix_time_from_system()) + int(j.get("expires_in", 3600))
	_sesi["user_id"] = String(u.get("id", _sesi.get("user_id", "")))
	_sesi["email"] = String(u.get("email", _sesi.get("email", "")))
	_tulis_sesi()
	if FileAccess.file_exists(FILE_SESI_BERAKHIR):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(FILE_SESI_BERAKHIR))




func _http(url: String, kepala: PackedStringArray, isi: Dictionary, batas: = 15.0) -> Dictionary:
	var req: HTTPRequest
	var pinjam: = false
	if _pakai_req_latar and is_instance_valid(_req_latar) and _req_latar.get_http_client_status() == HTTPClient.STATUS_DISCONNECTED:
		req = _req_latar
		pinjam = true
		_pakai_req_latar = false
	else:
		req = HTTPRequest.new()
		add_child(req)
	req.timeout = batas
	var hasil: = {"kode": 0, "json": null}
	if req.request(url, kepala, HTTPClient.METHOD_POST, JSON.stringify(isi)) == OK:
		var jawab: Array = await req.request_completed

		if GameState.papan != null:
			GameState.papan.catat_hasil_server(int(jawab[1]), jawab[0] == HTTPRequest.RESULT_SUCCESS)
		if jawab[0] == HTTPRequest.RESULT_SUCCESS:
			hasil["kode"] = int(jawab[1])
			hasil["json"] = JSON.parse_string((jawab[3] as PackedByteArray).get_string_from_utf8())
	if not pinjam:
		req.queue_free()
	return hasil


func _kepala_anon() -> PackedStringArray:
	return PackedStringArray(["apikey: " + KUNCI_PUBLIK, "Content-Type: application/json"])



func _pastikan_token() -> bool:
	if not tertaut():
		return false
	if int(_sesi.get("habis", 0)) - 90 > int(Time.get_unix_time_from_system()) and String(_sesi.get("akses", "")) != "":
		return true
	var h: = await _http(URL_SUPABASE + "/auth/v1/token?grant_type=refresh_token", _kepala_anon(), 
		{"refresh_token": String(_sesi.get("segar", ""))})
	if int(h["kode"]) == 200 and typeof(h["json"]) == TYPE_DICTIONARY and (h["json"] as Dictionary).has("access_token"):
		_pakai_jawaban_token(h["json"])
		return true

	if int(h["kode"]) == 400 or int(h["kode"]) == 401:

		var tanda: = FileAccess.open(FILE_SESI_BERAKHIR, FileAccess.WRITE)
		if tanda != null:
			tanda.store_string("1")
			tanda.close()
		_hapus_sesi()
	return false



func sesi_berakhir() -> bool:
	return FileAccess.file_exists(FILE_SESI_BERAKHIR)



func ambil_kabar_sesi_berakhir() -> bool:
	if _sesi_berakhir_dikabari or not sesi_berakhir():
		return false
	_sesi_berakhir_dikabari = true
	return true



func kirim_otomatis_gagal() -> bool:
	return pesan_terakhir in ["gagal", "sering"]



func _rpc(fungsi: String, isi: Dictionary, batas: = 20.0) -> Dictionary:
	if not await _pastikan_token():
		return {}
	var kepala: = PackedStringArray(["apikey: " + KUNCI_PUBLIK, "Content-Type: application/json", 
		"Authorization: Bearer " + String(_sesi.get("akses", ""))])
	var h: = await _http(URL_SUPABASE + "/rest/v1/rpc/" + fungsi, kepala, isi, batas)
	if int(h["kode"]) == 200 and typeof(h["json"]) == TYPE_DICTIONARY:
		return h["json"]
	return {}




func _siapkan_plugin() -> void :
	if _plugin != null or not Engine.has_singleton("GodotGoogleLogin"):
		return
	_plugin = Engine.get_singleton("GodotGoogleLogin")
	_plugin.sign_in_success.connect(_on_masuk_ok)
	_plugin.sign_in_failed.connect(_on_masuk_gagal)
	if _plugin.has_signal("apple_code"):
		_plugin.apple_code.connect( func(kode: String): _kode_apple = kode)


func _on_masuk_ok(id_token: String, email_akun: String, nama: String) -> void :
	if _menunggu_masuk:
		_menunggu_masuk = false
		_sesi["nama"] = nama
		_sesi["email"] = email_akun
		_masuk_selesai.emit({"ok": true, "token": id_token})


func _on_masuk_gagal(kode: String, _pesan: String) -> void :
	if _menunggu_masuk:
		_menunggu_masuk = false
		_masuk_selesai.emit({"ok": false, "alasan": kode})



func masuk(lewat: = "google") -> Dictionary:
	if not tersedia() or not (lewat in penyedia_tersedia()):
		return {"ok": false, "alasan": "tidak_tersedia"}
	if _menunggu_masuk:
		return {"ok": false, "alasan": "sibuk"}
	_siapkan_plugin()
	_menunggu_masuk = true

	GameState.get_tree().create_timer(120.0, true, false, true).timeout.connect( func():
		if _menunggu_masuk:
			_menunggu_masuk = false
			_masuk_selesai.emit({"ok": false, "alasan": "waktu"}))
	var isi: = {"provider": lewat}
	if _ios():
		var nonce: = _nonce_acak()
		isi["nonce"] = nonce
		if lewat == "apple":
			_plugin.signInApple(nonce.sha256_text())
		else:
			_plugin.signInGoogle(IOS_CLIENT_ID, nonce.sha256_text())
	else:
		_plugin.signIn(WEB_CLIENT_ID)
	var g: Dictionary = await _masuk_selesai
	if not bool(g.get("ok", false)):
		return g
	isi["id_token"] = String(g["token"])
	var h: = await _http(URL_SUPABASE + "/auth/v1/token?grant_type=id_token", _kepala_anon(), isi, 20.0)
	if int(h["kode"]) != 200 or typeof(h["json"]) != TYPE_DICTIONARY or not (h["json"] as Dictionary).has("access_token"):
		return {"ok": false, "alasan": "server"}
	_sesi["versi"] = 0
	_sesi["sidik"] = ""
	_sesi["penyedia"] = lewat
	_pakai_jawaban_token(h["json"])
	berubah.emit()
	return {"ok": true}


func _nonce_acak() -> String:
	var c: = Crypto.new()
	return Marshalls.raw_to_base64(c.generate_random_bytes(24)).replace("+", "-").replace("/", "_").replace("=", "")


func keluar() -> void :
	if _plugin != null:
		_plugin.signOut()
	_hapus_sesi()






const URL_CABUT_APPLE: = URL_SUPABASE + "/functions/v1/cabut-apple"

func _cabut_izin_apple() -> void :
	if not _ios() or penyedia() != "apple" or _menunggu_masuk:
		return
	_siapkan_plugin()
	if _plugin == null or not _plugin.has_signal("apple_code"):
		return
	if not await _pastikan_token():
		return
	_kode_apple = ""
	_menunggu_masuk = true
	GameState.get_tree().create_timer(120.0, true, false, true).timeout.connect( func():
		if _menunggu_masuk:
			_menunggu_masuk = false
			_masuk_selesai.emit({"ok": false, "alasan": "waktu"}))
	_plugin.signInApple(_nonce_acak().sha256_text())
	var g: Dictionary = await _masuk_selesai
	if not bool(g.get("ok", false)) or _kode_apple == "":
		return
	var kepala: = PackedStringArray(["apikey: " + KUNCI_PUBLIK, "Content-Type: application/json", 
		"Authorization: Bearer " + String(_sesi.get("akses", ""))])
	await _http(URL_CABUT_APPLE, kepala, {"kode": _kode_apple}, 20.0)
	_kode_apple = ""



func hapus_akun() -> bool:
	await _cabut_izin_apple()
	var r: = await _rpc("akun_hapus", {})
	if not bool(r.get("ok", false)):
		return false
	keluar()
	return true






func selesaikan_tautan() -> Dictionary:
	var s: = await _rpc("akun_status", {"p_id_papan": GameState.id_papan})
	if not bool(s.get("ok", false)):
		return {"kasus": "gagal"}
	_sesi["versi"] = int(s.get("versi", 0))




	if bool(s.get("ada_data", false)):
		_sesi["versi"] = -1
	_tulis_sesi()
	await _klaim_bonus()
	if not bool(s.get("ada_data", false)):
		await kirim(true)
		return {"kasus": "baru"}
	return {"kasus": "ada_cloud", "diperbarui": String(s.get("diperbarui", "")) if s.get("diperbarui") != null else ""}


func _klaim_bonus() -> void :
	var r: = await _rpc("akun_bonus", {})
	if bool(r.get("ok", false)) and bool(r.get("bonus", false)):
		_sesi["bonus_tertunda"] = true
		_tulis_sesi()
	terapkan_bonus()



func terapkan_bonus() -> void :
	if not bonus_menunggu():
		return
	if not GameState.sedang_main or GameState.mode_latihan:
		return
	_sesi["bonus_tertunda"] = false

	if GameState.bonus_tautan_diambil:
		_tulis_sesi()
		return
	GameState.bonus_tautan_diambil = true
	GameState.uang += BONUS_TAUTAN
	GameState.catat_transaksi("Bonus tautkan akun", BONUS_TAUTAN)
	GameState.bunyi("hadiah")
	GameState.data_berubah.emit()
	GameState.simpan()
	_tulis_sesi()
	bonus_diterima.emit(BONUS_TAUTAN)
	GameState._tampilkan_info_hadiah("Terima kasih sudah menautkan akun!", 
		"Akunmu sudah tertaut, simpanan warung ikut aman di cloud. Bonus Rp100.000 sudah masuk ke uang warung.")





func _sidik() -> String:
	var bagian: PackedStringArray = []
	for n in range(1, GameState.JUMLAH_SLOT + 1):
		if GameState.ada_slot(n):
			bagian.append("%d:%s" % [n, FileAccess.get_md5(GameState.file_slot(n))])
	bagian.append("%s%s%s%d" % [GameState.tanpa_iklan, GameState.pendukung, GameState.kode_pendukung, GameState.baju_dimiliki.size()])
	return "|".join(bagian).sha256_text()



func kirim(paksa: = false) -> Dictionary:
	if not tertaut() or _sibuk_kirim:
		return {"ok": false, "alasan": "tidak"}
	if GameState.jumlah_slot_terisi() == 0:
		return {"ok": false, "alasan": "kosong"}
	if GameState.sedang_main and not GameState.mode_latihan:
		GameState.simpan()
	var sidik: = _sidik()
	if not paksa and sidik == String(_sesi.get("sidik", "")):
		return {"ok": true, "alasan": "sama"}
	var hp: = kemajuan_hp()
	if not paksa and _mundur_dari(_sesi.get("kemajuan", {}), hp):
		if not mundur:
			mundur = true
			berubah.emit()
		return {"ok": false, "alasan": "mundur"}
	_sibuk_kirim = true
	var r: = await _rpc("akun_simpan", {"p_data": GameState.paket_cloud(), "p_versi_dasar": versi_cloud(), 
		"p_id_papan": GameState.id_papan, "p_paksa": paksa}, 40.0)
	_sibuk_kirim = false
	if bool(r.get("ok", false)):
		_sesi["versi"] = int(r.get("versi", versi_cloud() + 1))
		_sesi["sidik"] = sidik
		_sesi["disimpan"] = int(Time.get_unix_time_from_system())
		_sesi["kemajuan"] = hp
		_tulis_sesi()
		bentrok = false
		_bentrok_dikabari = false
		cloud_kosong = false
		mundur = false
		pesan_terakhir = ""
		berubah.emit()
		return {"ok": true}
	var alasan: = String(r.get("alasan", "gagal")) if not r.is_empty() else "gagal"
	if alasan == "bentrok" and not paksa and await _coba_pulihkan_bentrok():
		return {"ok": true, "alasan": "bentrok_dipulihkan"}
	if alasan == "bentrok":
		bentrok = true
		berubah.emit()
		peringatkan_bentrok()
	return {"ok": false, "alasan": alasan}





var _bentrok_dikabari: = false

func peringatkan_bentrok() -> void :
	if _bentrok_dikabari or not bentrok or not GameState.sedang_main or GameState.mode_latihan:
		return
	_bentrok_dikabari = true
	GameState._tampilkan_info_hadiah("Warung ini dimainkan di HP lain", 
		"Akunmu sudah menyimpan warung yang LEBIH BARU dari HP lain. Permainan di HP ini sekarang TIDAK ikut tersimpan ke cloud, supaya warung di HP lain tidak tertimpa.\n\nSupaya tidak ada yang hilang: keluar ke menu utama, lalu pilih simpanan yang mau dipakai (layar pilihan muncul sendiri). Sebaiknya main di satu HP saja.")









var _pulihkan_bentrok_jalan: = false

func _coba_pulihkan_bentrok(batas: = 40.0) -> bool:
	if _pulihkan_bentrok_jalan or not tertaut():
		return false
	_pulihkan_bentrok_jalan = true
	var cloud: = await kemajuan_cloud(batas)
	var hp: = kemajuan_hp()
	var berhasil: = false
	if not cloud.is_empty() and not hp.is_empty() and String(cloud.get("nama", "")).strip_edges().to_lower() == String(hp.get("nama", "")).strip_edges().to_lower() and not _lebih_jauh(cloud, hp):
		var h: = await kirim(true)
		berhasil = bool(h.get("ok", false))
	_pulihkan_bentrok_jalan = false
	return berhasil




var cloud_kosong: = false

func cek_bentrok(batas: = 6.0) -> bool:
	if not tertaut():
		return false
	var s: = await _rpc("akun_status", {"p_id_papan": GameState.id_papan}, batas)
	if bool(s.get("ok", false)):
		cloud_kosong = not bool(s.get("ada_data", false))
		if not cloud_kosong and int(s.get("versi", 0)) > versi_cloud():
			if await _coba_pulihkan_bentrok(batas + 4.0):
				return false
			if not bentrok:
				bentrok = true
				berubah.emit()
			peringatkan_bentrok()
	return bentrok




func pakai_cloud() -> String:
	var r: = await _rpc("akun_ambil", {}, 40.0)
	if r.is_empty():
		return "Belum bisa mengambil simpanan cloud. Cek internet lalu coba lagi."
	if not bool(r.get("ok", false)):
		return "Belum ada simpanan di cloud."
	var paket: Dictionary = GameState.buka_paket_cloud(String(r.get("data", "")))
	if paket.is_empty():
		return "Simpanan cloud rusak. Pakai simpanan HP ini lalu kirim ke cloud."

	var lebih_baru: = GameState.alasan_paket_lebih_baru(paket)
	if lebih_baru != "":
		return lebih_baru
	GameState.cadangkan_lokal_sebelum_cloud()
	GameState.terapkan_paket_pindah(paket)



	GameState.info_pindah_iklan = ""
	if bool(paket.get("toko", {}).get("tanpa_iklan", false)) and not GameState.tanpa_iklan:
		await GameState._periksa_iklan_pindah(false)
	_sesi["versi"] = int(r.get("versi", 0))
	_sesi["sidik"] = _sidik()
	_sesi["kemajuan"] = kemajuan_hp()
	_tulis_sesi()
	bentrok = false
	_bentrok_dikabari = false
	cloud_kosong = false
	mundur = false
	berubah.emit()
	return ""





func kemajuan_hp() -> Dictionary:
	var terbaik: = {}
	for n in range(1, GameState.JUMLAH_SLOT + 1):
		var i: Dictionary = GameState.info_slot(n)
		if not i.is_empty():

			var k: = {"level": int(i.get("level", 1)), "hari": int(i.get("hari", 1)), "nama": String(i.get("nama_warung", "")), "uang": int(i.get("uang", 0)), 
				"qris": int(i.get("qris", 0)), "disimpan": String(i.get("disimpan", ""))}
			if _lebih_jauh(k, terbaik):
				terbaik = k
	return terbaik



static func kemajuan_paket(paket: Dictionary) -> Dictionary:
	var terbaik: = {}
	var slot = paket.get("slot", {})
	if typeof(slot) != TYPE_DICTIONARY:
		return terbaik
	for kunci in slot:
		var d = JSON.parse_string(String(slot[kunci]))
		if typeof(d) == TYPE_DICTIONARY:
			var k: = {"level": int(d.get("tingkat", 0)) + 1, "hari": int(d.get("hari", 1)), "nama": String(d.get("nama_warung", "")), "uang": int(d.get("uang", 0)), 
				"qris": int(d.get("saldo_digital", 0)), "disimpan": String(d.get("disimpan", ""))}
			if _lebih_jauh(k, terbaik):
				terbaik = k
	return terbaik


static func _lebih_jauh(a: Dictionary, b: Dictionary) -> bool:
	if b.is_empty():
		return true
	if int(a["level"]) != int(b["level"]):
		return int(a["level"]) > int(b["level"])
	return int(a["hari"]) > int(b["hari"])



static func _mundur_dari(dasar, hp: Dictionary) -> bool:
	if typeof(dasar) != TYPE_DICTIONARY or (dasar as Dictionary).is_empty():
		return false
	if hp.is_empty():
		return true
	if int(hp["level"]) != int(dasar.get("level", 1)):
		return int(hp["level"]) < int(dasar.get("level", 1))
	return int(hp["hari"]) < int(dasar.get("hari", 1)) - 3



func cek_mundur() -> bool:
	mundur = tertaut() and _mundur_dari(_sesi.get("kemajuan", {}), kemajuan_hp())
	return mundur


func kemajuan_tersimpan() -> Dictionary:
	var k = _sesi.get("kemajuan", {})
	return k if typeof(k) == TYPE_DICTIONARY else {}



func lupakan_kemajuan() -> void :
	if _sesi.has("kemajuan"):
		_sesi.erase("kemajuan")
		_tulis_sesi()
	mundur = false



func kemajuan_cloud(batas: = 40.0) -> Dictionary:
	var r: = await _rpc("akun_ambil", {}, batas)
	if not bool(r.get("ok", false)):
		return {}
	return kemajuan_paket(GameState.buka_paket_cloud(String(r.get("data", ""))))




func _otomatis() -> void :


	if GameState.papan != null and not GameState.papan.boleh_otomatis():
		terapkan_bonus()
		return
	if tertaut() and GameState.sedang_main:
		var h: = await kirim()
		pesan_terakhir = "" if bool(h.get("ok", false)) else String(h.get("alasan", ""))
	terapkan_bonus()


func _cek_awal() -> void :
	if not tertaut():
		return
	await cek_bentrok(20.0)
	if not GameState.sedang_main and cek_mundur():
		berubah.emit()
	terapkan_bonus()
