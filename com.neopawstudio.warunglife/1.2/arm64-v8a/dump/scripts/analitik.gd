extends Node















const URL: = "https://vfeihrxdwynivqcksxwl.supabase.co/rest/v1/rpc/"
const KUNCI_PUBLIK: = "sb_publishable_bGjm_-NNAqleprvQoE3dLA_IVYxzKmr"
const FILE_CFG: = "user://analitik.cfg"
const FILE_ANTRE: = "user://analitik_antre.json"
const SELANG_KIRIM: = 180.0


const TIDAK_DIKIRIM: = ["beli_grosir", "titipan", "upgrade", "bab_selesai", "lanjut_game", "ganti_nama"]
const MAKS_ANTRE: = 400



const MODE_RINGAN: = true
const MAKS_PER_KIRIM: = 60
const SESI_BARU_SETELAH: = 1800
const JEDA_SINGKAT: = 60.0

static var paksa_kirim: = false

var aktif: = true
var id_perangkat: = ""
var sesi: = ""
var _antre: Array = []
var _mengirim: = false
var _hari_ping: = ""
var _detik_sesi: = 0.0
var _dijeda_pada: = -1.0
var _jeda_tertunda_w: = -1.0
var _fps_jumlah: = 0.0
var _fps_sampel: = 0
var _fps_min: = 999
var _detik_fps: = 0.0


func _ready() -> void :
	process_mode = Node.PROCESS_MODE_ALWAYS
	var cfg: = ConfigFile.new()
	cfg.load(FILE_CFG)
	id_perangkat = String(cfg.get_value("analitik", "id", ""))
	aktif = bool(cfg.get_value("analitik", "aktif", true))
	_hari_ping = String(cfg.get_value("analitik", "hari_ping", ""))
	if id_perangkat.length() < 16:
		id_perangkat = Crypto.new().generate_random_bytes(16).hex_encode()
		_simpan_cfg()
	_muat_antre()
	var t: = Timer.new()
	t.wait_time = SELANG_KIRIM
	t.autostart = true
	t.timeout.connect(kirim)
	add_child(t)
	_mulai_sesi.call_deferred()


func boleh() -> bool:
	return aktif and (paksa_kirim or not GameState.GOD_MODE)



func catat(nama: String, data: = {}) -> void :
	if not boleh() or nama in TIDAK_DIKIRIM:
		return
	if MODE_RINGAN and not (nama == "beli" and _beli_dicatat(data)):
		return
	var d: = data.duplicate()
	if GameState.sedang_main:
		d["hari"] = d.get("hari", GameState.hari)
		d["lv"] = GameState.tingkat + 1
	_antre.append({"s": sesi, "n": nama, "w": snappedf(Time.get_unix_time_from_system(), 0.001), "d": d})
	if _antre.size() > MAKS_ANTRE:
		_antre = _antre.slice(_antre.size() - MAKS_ANTRE)





const TAHAP_BELI: = ["lunas", "tertunda", "dibatalkan", "buka_gagal", "konfirmasi_gagal"]

func _beli_dicatat(data: Dictionary) -> bool:
	var tahap: = String(data.get("tahap", ""))
	if tahap in TAHAP_BELI:
		return true
	return tahap == "hasil" and not int(data.get("kode", 0)) in [0, 1]


func atur_aktif(nyala: bool) -> void :
	aktif = nyala
	if not nyala:
		_antre.clear()
		_simpan_antre()
	_simpan_cfg()



func hapus_data_server() -> bool:
	_antre.clear()
	_simpan_antre()
	var hasil = await _rpc("hapus_analitik", {"p_id": id_perangkat})
	var ok: bool = typeof(hasil) == TYPE_DICTIONARY and hasil.get("ok", false)
	if ok:
		id_perangkat = Crypto.new().generate_random_bytes(16).hex_encode()
		_simpan_cfg()
	return ok


func kirim(paksa: = false) -> void :
	if MODE_RINGAN:

		var lama: = _antre.size()
		_antre = _antre.filter( func(e): return String(e.get("n", "")) == "beli")
		if _antre.size() != lama:
			_simpan_antre()

		if _antre.is_empty() and _hari_ping == Time.get_date_string_from_system():
			return
	elif _antre.is_empty():
		return
	if _mengirim:
		return

	if _dijeda_pada >= 0.0 and not paksa:
		return
	if not boleh():
		return
	_mengirim = true
	var bagian: = _antre.slice(0, MAKS_PER_KIRIM)
	var hasil = await _rpc("catat_analitik", {"p_id": id_perangkat, "p_versi": _versi(), 
		"p_perangkat": _info_perangkat(), "p_daftar": bagian})
	if typeof(hasil) == TYPE_DICTIONARY and (hasil.get("ok", false) or hasil.get("alasan", "") == "data"):

		_antre = _antre.slice(bagian.size())
		_simpan_antre()
		if _hari_ping != Time.get_date_string_from_system():
			_hari_ping = Time.get_date_string_from_system()
			_simpan_cfg()
	_mengirim = false


func _process(delta: float) -> void :
	if _dijeda_pada >= 0.0:
		return
	_detik_sesi += delta
	if not GameState.sedang_main:
		return
	_detik_fps += delta
	if _detik_fps >= 5.0:
		_detik_fps = 0.0
		var fps: = int(Engine.get_frames_per_second())
		if fps > 0:
			_fps_jumlah += fps
			_fps_sampel += 1
			_fps_min = mini(_fps_min, fps)


func _notification(what: int) -> void :
	match what:
		NOTIFICATION_APPLICATION_PAUSED, NOTIFICATION_WM_CLOSE_REQUEST:
			if _dijeda_pada < 0.0:
				_tutup_sesi()
				_dijeda_pada = Time.get_unix_time_from_system()
				_simpan_antre()
			if what == NOTIFICATION_WM_CLOSE_REQUEST:
				_jeda_pasti()
				kirim(true)
		NOTIFICATION_APPLICATION_RESUMED:
			if _dijeda_pada >= 0.0:
				var lama: = Time.get_unix_time_from_system() - _dijeda_pada
				_dijeda_pada = -1.0
				if lama <= JEDA_SINGKAT and _batalkan_jeda():
					return
				_jeda_pasti()
				if lama > SESI_BARU_SETELAH:
					_mulai_sesi()
				else:
					kirim()


func _mulai_sesi() -> void :
	sesi = Crypto.new().generate_random_bytes(8).hex_encode()
	_jeda_pasti()
	catat("sesi_mulai", {"grafik": GameState.kualitas, "bahasa": GameState.bahasa, 
		"renderer": String(ProjectSettings.get_setting("rendering/renderer/rendering_method", "")), 
		"tanpa_iklan": GameState.tanpa_iklan})
	kirim()


func _tutup_sesi() -> void :
	var d: = {"detik": int(_detik_sesi), "grafik": GameState.kualitas, "baterai": GameState.hemat_baterai}
	if _fps_sampel > 0:
		d["fps"] = snappedf(_fps_jumlah / _fps_sampel, 0.1)
		d["fps_min"] = _fps_min
	catat("sesi_jeda", d)
	_jeda_tertunda_w = float(_antre[-1]["w"]) if not _antre.is_empty() and _antre[-1]["n"] == "sesi_jeda" else -1.0



func _jeda_pasti() -> void :
	_jeda_tertunda_w = -1.0
	_detik_sesi = 0.0
	_fps_jumlah = 0.0
	_fps_sampel = 0
	_fps_min = 999



func _batalkan_jeda() -> bool:
	if _jeda_tertunda_w < 0.0:
		return false
	for i in range(_antre.size() - 1, -1, -1):
		var e: Dictionary = _antre[i]
		if e.get("n", "") == "sesi_jeda" and float(e.get("w", -1.0)) == _jeda_tertunda_w:
			_antre.remove_at(i)
			_simpan_antre()
			_jeda_tertunda_w = -1.0
			return true
	return false


func _versi() -> String:
	return String(ProjectSettings.get_setting("application/config/version", ""))


func _info_perangkat() -> Dictionary:
	var layar: = DisplayServer.screen_get_size()
	return {"model": OS.get_model_name(), "os": "%s %s" % [OS.get_name(), OS.get_version()], 
		"ram_mb": int(int(OS.get_memory_info().get("physical", 0)) / 1048576), 
		"layar": "%dx%d" % [layar.x, layar.y], "bahasa": GameState.bahasa}


func _rpc(fungsi: String, isi: Dictionary) -> Variant:
	var req: = HTTPRequest.new()
	req.timeout = 15.0
	add_child(req)
	var kepala: = ["apikey: " + KUNCI_PUBLIK, "Content-Type: application/json"]
	var hasil: Variant = null
	if req.request(URL + fungsi, kepala, HTTPClient.METHOD_POST, JSON.stringify(isi)) == OK:
		var jawab: Array = await req.request_completed
		if jawab[0] == HTTPRequest.RESULT_SUCCESS and int(jawab[1]) == 200:
			hasil = JSON.parse_string((jawab[3] as PackedByteArray).get_string_from_utf8())
	req.queue_free()
	return hasil


func _simpan_cfg() -> void :
	var cfg: = ConfigFile.new()
	cfg.set_value("analitik", "id", id_perangkat)
	cfg.set_value("analitik", "aktif", aktif)
	cfg.set_value("analitik", "hari_ping", _hari_ping)
	cfg.save(FILE_CFG)


func _simpan_antre() -> void :
	var f: = FileAccess.open(FILE_ANTRE, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(_antre))


func _muat_antre() -> void :
	if not FileAccess.file_exists(FILE_ANTRE):
		return
	var isi = JSON.parse_string(FileAccess.get_file_as_string(FILE_ANTRE))
	if typeof(isi) == TYPE_ARRAY:
		_antre = isi.slice(maxi(0, isi.size() - MAKS_ANTRE))
