extends Node
















const FILE_CADANGAN: = "user://cadangan_hp.cfg"
const SELANG_MAIN: = 1800.0
const SELANG_DITINGGAL: = 600.0

var kode: = ""
var _rahasia: = ""
var _sidik_terkirim: = ""
var _terakhir: = -100000.0
var _sibuk: = false
var dipindah_kabar: = false


func _ready() -> void :
	process_mode = Node.PROCESS_MODE_ALWAYS
	_muat()
	var t: = Timer.new()
	t.wait_time = 60.0
	t.autostart = true
	t.timeout.connect( func(): kirim(SELANG_MAIN))
	add_child(t)

	GameState.get_tree().create_timer(25.0, true, false, true).timeout.connect( func(): kirim(SELANG_DITINGGAL))


func _notification(what: int) -> void :
	if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_WM_CLOSE_REQUEST:
		kirim(SELANG_DITINGGAL)


func _muat() -> void :
	var cfg: = ConfigFile.new()
	if cfg.load(FILE_CADANGAN) == OK:
		kode = String(cfg.get_value("cadangan", "kode", ""))
		_rahasia = String(cfg.get_value("cadangan", "rahasia", ""))
		_sidik_terkirim = String(cfg.get_value("cadangan", "sidik", ""))
	if _rahasia.length() < 24:
		_rahasia = Crypto.new().generate_random_bytes(16).hex_encode()
		_simpan()


func _simpan() -> void :
	var cfg: = ConfigFile.new()
	cfg.set_value("cadangan", "kode", kode)
	cfg.set_value("cadangan", "rahasia", _rahasia)
	cfg.set_value("cadangan", "sidik", _sidik_terkirim)
	cfg.save(FILE_CADANGAN)



func perangkat() -> String:
	var asli: = OS.get_unique_id()
	if asli == "" and GameState.analitik != null:
		asli = String(GameState.analitik.id_perangkat)
	if asli == "":
		asli = _rahasia
	return ("warung|" + asli).sha256_text().left(40)


func _sidik() -> String:
	var bagian: PackedStringArray = []
	for n in range(1, GameState.JUMLAH_SLOT + 1):
		if GameState.ada_slot(n):
			bagian.append("%d:%s" % [n, FileAccess.get_md5(GameState.file_slot(n))])
	bagian.append("%s%s%s" % [GameState.tanpa_iklan, GameState.pendukung, GameState.kode_pendukung])
	return "|".join(bagian).sha256_text()


func _versi() -> String:
	return String(ProjectSettings.get_setting("application/config/version", ""))



func kirim(selang: = SELANG_MAIN) -> void :
	if _sibuk or GameState.papan == null or GameState.mode_latihan or GameState.jumlah_slot_terisi() == 0:
		return
	if GameState.akun != null and GameState.akun.tertaut():
		return
	if not GameState.papan.boleh_otomatis():
		return
	var sekarang: = Time.get_ticks_msec() / 1000.0
	if sekarang - _terakhir < selang:
		return
	var sidik: = _sidik()
	if sidik == _sidik_terkirim and kode != "":
		return
	_terakhir = sekarang
	_sibuk = true
	var data: String = GameState.paket_cloud()
	var k: Dictionary = GameState.akun.kemajuan_hp() if GameState.akun != null else {}
	var dev: = perangkat()
	var h = await GameState.papan._rpc("cadangan_simpan", {
		"p_kode": kode, "p_rahasia": _rahasia, "p_perangkat": dev, "p_data": data, 
		"p_nama": String(k.get("nama", "")), "p_level": int(k.get("level", 1)), "p_hari": int(k.get("hari", 1)), 
		"p_versi": _versi(), 
		"p_tanda": GameState.papan._tanda("%s|%s|%s" % [dev, _rahasia, data.sha256_text()])}, 40.0)
	_sibuk = false
	if typeof(h) != TYPE_DICTIONARY:
		return
	if bool(h.get("ok", false)):
		kode = String(h.get("kode", kode))
		_sidik_terkirim = sidik
		_simpan()
		return
	match String(h.get("alasan", "")):
		"tidak_ada":
			kode = ""
			_simpan()
		"dipindah":


			kode = ""
			_rahasia = Crypto.new().generate_random_bytes(16).hex_encode()
			_sidik_terkirim = ""
			_simpan()
			dipindah_kabar = true
			_terakhir = -100000.0
			kabari_dipindah()



func kabari_dipindah() -> void :
	if not dipindah_kabar or not GameState.sedang_main:
		return
	dipindah_kabar = false
	GameState._tampilkan_info_hadiah("Warung ini dipulihkan di HP lain", 
		"Kode Warung milik HP ini sudah dipakai untuk memulihkan warung di HP lain. Kalau kamu tetap main di HP ini, warungnya jadi terpisah dan mendapat Kode Warung baru. Supaya tidak bingung, main di satu HP saja.")





static func nama_tampil(nama: String) -> String:
	if nama == "" or nama.to_lower().begins_with("warung"):
		return nama if nama != "" else "Warung"
	return "Warung " + nama



static func rapikan_kode(teks: String) -> String:
	var k: = teks.strip_edges().to_upper().replace(" ", "").replace("-", "")
	if k.length() != 9 or not k.begins_with("W"):
		return ""
	return "W-%s-%s" % [k.substr(1, 4), k.substr(5, 4)]


func _panggil_ambil(kode_w: String, id: String, rahasia_baru: String, pasang: bool) -> Dictionary:
	var dev: = perangkat()
	var h = await GameState.papan._rpc("cadangan_ambil", {
		"p_kode": kode_w, "p_id": id, "p_perangkat": dev, "p_rahasia_baru": rahasia_baru, "p_pasang": pasang, 
		"p_tanda": GameState.papan._tanda("%s|%s|%s|%s" % [dev, kode_w, id, rahasia_baru])}, 40.0)
	return h if typeof(h) == TYPE_DICTIONARY else {}



func lihat(kode_w: = "", id: = "") -> Dictionary:
	if GameState.papan == null:
		return {"pesan": "Belum bisa memeriksa kode."}
	var h: = await _panggil_ambil(kode_w, id, _rahasia, false)
	if h.is_empty():
		return {"pesan": "Belum bisa memeriksa kode. Cek internet lalu coba lagi."}
	if not bool(h.get("ok", false)):
		if String(h.get("alasan", "")) == "tidak_ada":
			return {"pesan": "Kode warung tidak ditemukan. Periksa lagi huruf dan angkanya."}
		return {"pesan": "Kode belum bisa dipakai. Coba lagi nanti."}
	var dari: = String(h.get("versi_game", ""))
	var saya: = _versi()
	if dari != "" and saya != "" and dari.naturalnocasecmp_to(saya) > 0:
		return {"pesan": "Warung ini disimpan dari game versi %s, sedangkan game di HP ini masih versi %s. Update game ini dulu di toko aplikasi, lalu masukkan kodenya lagi (kodenya tetap berlaku)." % [dari, saya]}
	return h



func pulihkan(kode_w: = "", id: = "") -> String:
	var cek: = await lihat(kode_w, id)
	if cek.has("pesan"):
		return String(cek["pesan"])
	var rahasia_baru: = Crypto.new().generate_random_bytes(16).hex_encode()
	var h: = await _panggil_ambil(kode_w, id, rahasia_baru, true)
	if h.is_empty() or not bool(h.get("ok", false)):
		return "Belum bisa memulihkan warung. Cek internet lalu coba lagi."
	var paket: Dictionary = GameState.buka_paket_cloud(String(h.get("data", "")))
	if paket.is_empty():
		return "Data cadangan rusak. Isi form Bantuan supaya kami bantu."
	GameState.cadangkan_lokal_sebelum_cloud()
	GameState.terapkan_paket_pindah(paket)

	kode = String(h.get("kode", ""))
	_rahasia = rahasia_baru
	_sidik_terkirim = _sidik()
	_simpan()
	await GameState.periksa_iklan_sesudah_pulih(paket)
	return ""



func cari_di_perangkat() -> Array:
	if GameState.papan == null:
		return []
	var dev: = perangkat()
	var h = await GameState.papan._rpc("cadangan_cari", {"p_perangkat": dev, 
		"p_tanda": GameState.papan._tanda(dev + "|cari")}, 12.0)
	if typeof(h) != TYPE_DICTIONARY or not bool(h.get("ok", false)):
		return []
	var w = h.get("warung", [])
	return w if typeof(w) == TYPE_ARRAY else []
