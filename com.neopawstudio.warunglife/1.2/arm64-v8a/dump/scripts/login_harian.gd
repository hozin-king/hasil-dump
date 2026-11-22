extends Node



















const PANJANG: = 30
const UANG_HARIAN: = 15000
const HADIAH: = {4: 100000, 8: 150000, 12: 200000, 16: 250000, 20: 300000, 24: 350000, 26: "bebas_iklan", 28: 400000, 30: "baju"}
const UANG_PENGGANTI_BAJU: = 500000
const UANG_PENGGANTI_IKLAN: = 100000
const URL_JAM: = ["https://neopawstudio.github.io/versi.json", "https://vfeihrxdwynivqcksxwl.supabase.co/auth/v1/health"]
const ZONA: = 7 * 3600
const SEHARI: = 86400
const BULAN: = {"Jan": 1, "Feb": 2, "Mar": 3, "Apr": 4, "May": 5, "Jun": 6, "Jul": 7, "Aug": 8, "Sep": 9, "Oct": 10, "Nov": 11, "Dec": 12}

var _jam_server: = 0.0
var _detik_mesin: = 0.0
var _mengambil_jam: = false
var _gagal_terakhir: = -9999.0
var _offline_diberitahu: = false
var paksa_jam: = 0
var paksa_offline: = false


func _notification(what: int) -> void :

	if what == NOTIFICATION_APPLICATION_RESUMED:
		_jam_server = 0.0


func _detik() -> float:
	return Time.get_ticks_msec() / 1000.0



func sekarang() -> int:
	if paksa_jam > 0:
		return paksa_jam
	if _jam_server <= 0.0:
		return 0
	return int(_jam_server + (_detik() - _detik_mesin))



const KUNCI_TANDA: = "kalender-warung-21nov-7f3a9c"

func tanda_catatan() -> String:
	var gs = GameState
	var h: = HMACContext.new()
	h.start(HashingContext.HASH_SHA256, KUNCI_TANDA.to_utf8_buffer())
	h.update(("%d|%s|%d|%d|%d" % [gs.login_hari_ke, gs.login_tanggal, gs.login_siklus, gs.bebas_iklan_dari, gs.bebas_iklan_sampai]).to_utf8_buffer())
	return h.finish().hex_encode().left(32)


static func tanggal(unix: int) -> String:
	return Time.get_date_string_from_unix_time(unix + ZONA)


static func _unix_tanggal(t: String) -> int:
	return int(Time.get_unix_time_from_datetime_string(t + "T00:00:00")) - ZONA



static func baca_tanggal_http(teks: String) -> int:
	var b: = teks.strip_edges().split(" ", false)
	if b.size() < 5 or not BULAN.has(b[2]):
		return 0
	var s: = "%04d-%02d-%02dT%s" % [int(b[3]), int(BULAN[b[2]]), int(b[1]), b[4]]
	return int(Time.get_unix_time_from_datetime_string(s))



func ambil_jam(paksa: = false) -> bool:
	if paksa_jam > 0:
		return true
	if paksa_offline:
		return false
	if sekarang() > 0:
		return true
	if not paksa and _detik() - _gagal_terakhir < 30.0:
		return false
	if _mengambil_jam:
		while _mengambil_jam:
			await get_tree().process_frame
		return sekarang() > 0
	_mengambil_jam = true
	for url in URL_JAM:
		var req: = HTTPRequest.new()
		req.timeout = 8.0
		add_child(req)
		var mulai: = _detik()
		if req.request(url + "?t=%d" % Time.get_ticks_msec(), [], HTTPClient.METHOD_HEAD) == OK:
			var jawab: Array = await req.request_completed
			if jawab[0] == HTTPRequest.RESULT_SUCCESS:
				for h in (jawab[2] as PackedStringArray):
					if h.to_lower().begins_with("date:"):
						var u: = baca_tanggal_http(h.substr(5))
						if u > 1700000000:
							_jam_server = float(u) + (_detik() - mulai) / 2.0
							_detik_mesin = _detik()
		req.queue_free()
		if _jam_server > 0.0:
			break
	_mengambil_jam = false
	if _jam_server <= 0.0:
		_gagal_terakhir = _detik()
	return _jam_server > 0.0



func hari_berikut(hari_ini: String) -> int:
	var gs = GameState
	if gs.login_tanggal != "" and gs.login_tanggal >= hari_ini:
		return 0
	if gs.login_hari_ke >= PANJANG:
		return 0
	return gs.login_hari_ke + 1



func hadiah(n: int) -> Dictionary:
	var gs = GameState
	if not HADIAH.has(n):
		return {"jenis": "uang", "n": UANG_HARIAN, "teks": gs.format_rupiah(UANG_HARIAN), "besar": false}
	var h = HADIAH[n]
	if h is String and h == "baju":
		if not gs.baju_dimiliki.has(gs.BAJU_TESTER):
			return {"jenis": "baju", "teks": tr("Baju Kaos & sarung"), "besar": true}
		h = UANG_PENGGANTI_BAJU
	elif h is String and h == "bebas_iklan":
		if not gs.tanpa_iklan:
			return {"jenis": "bebas_iklan", "teks": tr("Tanpa Iklan 1 hari"), "besar": true}
		h = UANG_PENGGANTI_IKLAN
	return {"jenis": "uang", "n": int(h), "teks": gs.format_rupiah(int(h)), "besar": true}



func boleh_ditawarkan() -> bool:
	var gs = GameState
	return gs.slot_aktif > 0 and gs.tutorial_selesai and gs.tutorial_langkah == "" and not gs.mode_latihan\
	and not gs.tutorial_awal and not gs.tutorial_penutup




func ambil(n: int) -> Dictionary:
	var gs = GameState
	if not boleh_ditawarkan():
		return {"ok": false, "alasan": "tidak_boleh"}
	if paksa_jam <= 0:
		_jam_server = 0.0
	if not await ambil_jam(true):
		return {"ok": false, "alasan": "internet"}
	var kini: = sekarang()
	var hari_ini: = tanggal(kini)
	if hari_berikut(hari_ini) != n:
		return {"ok": false, "alasan": "sudah"}
	var h: = hadiah(n)
	match String(h["jenis"]):
		"uang":
			gs.uang += int(h["n"])
			gs.catat_transaksi(tr("Hadiah kalender hari ke-%d") % n, int(h["n"]))
		"baju":
			gs.baju_dimiliki[gs.BAJU_TESTER] = true
		"bebas_iklan":
			gs.bebas_iklan_dari = kini
			gs.bebas_iklan_sampai = kini + SEHARI
	gs.login_hari_ke = n
	gs.login_tanggal = hari_ini
	gs.login_tanda_sah = true
	if n == PANJANG:
		gs.login_siklus += 1
	gs.simpan_pengaturan()
	gs.simpan()
	gs.data_berubah.emit()
	if gs.analitik != null:
		gs.analitik.catat("login_harian", {"hari": n, "jenis": String(h["jenis"])})
	return {"ok": true, "teks": String(h["teks"])}



var _kartu_terbuka: = false
var _tunda_sampai: = 0.0

func tunda() -> void :
	_tunda_sampai = _detik() + 300.0

func cek(j: Node) -> void :
	if _kartu_terbuka or _mengambil_jam or _detik() < _tunda_sampai or not boleh_ditawarkan():
		return
	if GameState.login_hari_ke >= PANJANG:
		return
	var gs = GameState

	if sekarang() > 0 and hari_berikut(tanggal(sekarang())) == 0:
		return

	if sekarang() <= 0 and gs.login_tanggal == tanggal(int(Time.get_unix_time_from_system())):
		return
	if sekarang() <= 0 and _detik() - _gagal_terakhir < 60.0:
		return
	if not await ambil_jam():
		if not _offline_diberitahu and is_instance_valid(j) and j.has_method("tampilkan_pesan"):
			_offline_diberitahu = true
			j.tampilkan_pesan(tr("Hadiah harian menunggu. Sambungkan internet untuk mengambilnya."), 5.0)
		return
	var n: = hari_berikut(tanggal(sekarang()))
	if n == 0 or not is_instance_valid(j) or not boleh_ditawarkan():
		return
	if j.get("sibuk") or (j.get("dialog") != null and j.dialog.visible) or j.get("pindah") or j.get("sinema_khusus")\
	or j.get("_sinema_aktif") or (j.get("hp") != null and j.hp.visible):
		return
	await _tampilkan(j, n, "ambil")




func ada_hadiah_hari_ini() -> bool:
	var gs = GameState
	if not boleh_ditawarkan() or gs.login_hari_ke >= PANJANG:
		return false
	var kini: = sekarang()
	var hari_ini: = tanggal(kini) if kini > 0 else tanggal(int(Time.get_unix_time_from_system()))
	return hari_berikut(hari_ini) > 0





func buka_dari_hp(adegan: Node) -> void :
	if _kartu_terbuka or not is_instance_valid(adegan):
		return
	var gs = GameState
	if not boleh_ditawarkan():
		await _tampilkan(adegan, mini(gs.login_hari_ke + 1, PANJANG), "tutorial")
		return
	if gs.login_hari_ke >= PANJANG:
		await _tampilkan(adegan, PANJANG, "selesai")
		return
	if not await ambil_jam(true):
		await _tampilkan(adegan, gs.login_hari_ke + 1, "offline")
		return
	var n: = hari_berikut(tanggal(sekarang()))
	if n > 0:
		_tunda_sampai = 0.0
		await _tampilkan(adegan, n, "ambil")
	else:
		await _tampilkan(adegan, mini(gs.login_hari_ke + 1, PANJANG), "sudah")


func _tampilkan(adegan: Node, n: int, mode: String) -> void :
	_kartu_terbuka = true
	var sibuk_dipasang: = false
	if adegan.get("sibuk") == false:
		adegan.set("sibuk", true)
		sibuk_dipasang = true
	var kartu: Control = load("res://scripts/login_harian_ui.gd").new()
	kartu.set("hari_ke", n)
	kartu.set("mode", mode)
	var induk = adegan.get("ui")
	if not (induk is Node):
		induk = adegan.get("akar_ui")
	if not (induk is Node):
		induk = adegan
	(induk as Node).add_child(kartu)
	await kartu.ditutup
	if sibuk_dipasang and is_instance_valid(adegan):
		adegan.set("sibuk", false)
	_kartu_terbuka = false
