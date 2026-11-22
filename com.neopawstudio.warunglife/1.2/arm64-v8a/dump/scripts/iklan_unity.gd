extends Node













const IKLAN_UJI: = false


const IKLAN_UJI_IOS: = false


func _mode_uji() -> bool:
	if GameState.hp_pengembang:
		return true
	return IKLAN_UJI_IOS if OS.get_name() == "iOS" else IKLAN_UJI
const GAME_ID_ANDROID: = "800425443"

const GAME_ID_IOS: = "800432061"
var PENEMPATAN_HADIAH: = "BP_Rewarded_iOS" if OS.get_name() == "iOS" else "BP_Rewarded_Android"
var PENEMPATAN_SELINGAN: = "BP_Interstitial_iOS" if OS.get_name() == "iOS" else "BP_Interstitial_Android"
const BATAS_TUNGGU: = 15.0
const JEDA_COBA_LAGI: = 20.0
const MAKS_COBA_LAGI: = 3

const GALAT_JARINGAN: = ["INITIALIZE_FAILED", "TIMEOUT", "NETWORK_ERROR"]

signal _tayang_selesai

var _plugin: Object = null
var _sdk_siap: = false
var _memulai_sdk: = false
var _gagal_sdk: = 0
var _hadiah_siap: = false
var _selingan_siap: = false
var _memuat_hadiah: = false
var _memuat_selingan: = false
var _gagal_hadiah: = 0
var _gagal_selingan: = 0
var _dapat_hadiah: = false
var _galat_hadiah: = ""
var _pesan_galat: = ""


func _game_id() -> String:
	return GAME_ID_IOS if OS.get_name() == "iOS" else GAME_ID_ANDROID


func siapkan() -> void :
	if not Engine.has_singleton("GodotUnityAds"):
		_galat_hadiah = "NO_PLUGIN"
		_pesan_galat = "Plugin GodotUnityAds tidak ada di build ini"
		return
	if _game_id() == "":
		_galat_hadiah = "NO_GAME_ID"
		_pesan_galat = "Game ID Unity untuk %s belum diisi" % OS.get_name()
		return
	_plugin = Engine.get_singleton("GodotUnityAds")
	_plugin.connect("init_complete", _saat_sdk_siap)
	_plugin.connect("init_failed", _saat_sdk_gagal)
	_plugin.connect("ad_loaded", _saat_dimuat)
	_plugin.connect("ad_load_failed", _saat_gagal_dimuat)
	_plugin.connect("ad_show_complete", _saat_tayang_selesai)
	_plugin.connect("ad_show_failed", _saat_tayang_gagal)


	if pemain_eropa() and _plugin.has_method("setUserConsent"):
		_plugin.setUserConsent(false)
	_mulai_sdk()



const NEGARA_GDPR: = ["AT", "BE", "BG", "HR", "CY", "CZ", "DK", "EE", "FI", "FR", "DE", "GR", "HU", "IE", "IT", "LV", 
	"LT", "LU", "MT", "NL", "PL", "PT", "RO", "SK", "SI", "ES", "SE", "IS", "LI", "NO", "GB", "CH"]



static func pemain_eropa() -> bool:
	var bagian: = OS.get_locale().replace("-", "_").split("_")
	for i in range(1, bagian.size()):
		if String(bagian[i]).length() == 2:
			return String(bagian[i]).to_upper() in NEGARA_GDPR
	return String(Time.get_time_zone_from_system().get("name", "")).begins_with("Europe/")


func _mulai_sdk() -> void :
	if _plugin == null or _sdk_siap or _memulai_sdk:
		return
	_memulai_sdk = true
	_plugin.initialize(_game_id(), _mode_uji())


func _saat_sdk_siap() -> void :
	_memulai_sdk = false
	_sdk_siap = true
	_gagal_sdk = 0
	_muat_hadiah()
	_muat_selingan()


func _saat_sdk_gagal(kode: String, pesan: String) -> void :
	_memulai_sdk = false
	_galat_hadiah = kode
	_pesan_galat = pesan
	_gagal_sdk += 1
	if _gagal_sdk <= MAKS_COBA_LAGI:
		GameState.get_tree().create_timer(JEDA_COBA_LAGI * _gagal_sdk, true, false, true).timeout.connect(_mulai_sdk)


func _muat_hadiah() -> void :
	if not _sdk_siap:
		_mulai_sdk()
		return
	if _hadiah_siap or _memuat_hadiah:
		return
	_memuat_hadiah = true
	_plugin.load(PENEMPATAN_HADIAH)


func _muat_selingan() -> void :
	if not _sdk_siap:
		_mulai_sdk()
		return
	if _selingan_siap or _memuat_selingan:
		return
	_memuat_selingan = true
	_plugin.load(PENEMPATAN_SELINGAN)


func _saat_dimuat(penempatan: String) -> void :
	if penempatan == PENEMPATAN_HADIAH:
		_memuat_hadiah = false
		_hadiah_siap = true
		_gagal_hadiah = 0
		_galat_hadiah = ""
	elif penempatan == PENEMPATAN_SELINGAN:
		_memuat_selingan = false
		_selingan_siap = true
		_gagal_selingan = 0


func _saat_gagal_dimuat(penempatan: String, kode: String, pesan: String) -> void :
	if penempatan == PENEMPATAN_HADIAH:
		_memuat_hadiah = false
		_galat_hadiah = kode
		_pesan_galat = pesan
		_gagal_hadiah += 1
		if _gagal_hadiah <= MAKS_COBA_LAGI:
			GameState.get_tree().create_timer(JEDA_COBA_LAGI * _gagal_hadiah, true, false, true).timeout.connect(_muat_hadiah)
	elif penempatan == PENEMPATAN_SELINGAN:
		_memuat_selingan = false
		_gagal_selingan += 1
		if _gagal_selingan <= MAKS_COBA_LAGI:
			GameState.get_tree().create_timer(JEDA_COBA_LAGI * _gagal_selingan, true, false, true).timeout.connect(_muat_selingan)


func _saat_tayang_selesai(penempatan: String, ditonton_penuh: bool) -> void :
	if penempatan == PENEMPATAN_HADIAH:
		_dapat_hadiah = ditonton_penuh
	_tayang_selesai.emit()


func _saat_tayang_gagal(penempatan: String, kode: String, pesan: String) -> void :
	if penempatan == PENEMPATAN_HADIAH:
		_galat_hadiah = kode
		_pesan_galat = pesan
		_dapat_hadiah = false
	_tayang_selesai.emit()



func tonton(akar: Node) -> bool:
	if not _hadiah_siap:
		var layar: = _layar_pesan(akar, "Memuat iklan...")
		_gagal_hadiah = 0
		_gagal_sdk = 0
		_muat_hadiah()
		var sisa: = BATAS_TUNGGU
		while not _hadiah_siap and (_memuat_hadiah or _memulai_sdk) and sisa > 0.0:
			await GameState.get_tree().create_timer(0.2, true, false, true).timeout
			sisa -= 0.2
		layar.queue_free()
		if not _hadiah_siap:
			_memuat_hadiah = false
	if not _hadiah_siap:
		var saran: = "Periksa internet, lalu coba lagi." if _galat_hadiah in GALAT_JARINGAN or _galat_hadiah == "" else "Coba lagi sebentar lagi."

		var teknis: = "(kode %s: %s)" % [_galat_hadiah, _pesan_galat.left(90)] if _galat_hadiah != "" else "(tidak ada jawaban, SDK %s)" % ("siap" if _sdk_siap else "belum siap")
		var layar: = _layar_pesan(akar, "Iklan belum tersedia.\n%s" % saran, teknis)
		var tutup: = Button.new()
		tutup.text = "Tutup"
		tutup.theme_type_variation = &"TombolKayu"
		tutup.custom_minimum_size = Vector2(240, 56)
		tutup.add_theme_font_size_override("font_size", 22)
		layar.get_meta("kolom").add_child(tutup)
		await tutup.pressed
		layar.queue_free()
		return false
	_hadiah_siap = false
	_dapat_hadiah = false
	AudioServer.set_bus_mute(0, true)
	_plugin.show(PENEMPATAN_HADIAH)
	await _tayang_selesai
	AudioServer.set_bus_mute(0, false)
	await get_tree().process_frame
	_muat_hadiah()
	return _dapat_hadiah



func tampilkan_selingan() -> void :
	if not _selingan_siap:
		_muat_selingan()
		return
	_selingan_siap = false
	AudioServer.set_bus_mute(0, true)
	_plugin.show(PENEMPATAN_SELINGAN)
	await _tayang_selesai
	AudioServer.set_bus_mute(0, false)
	_muat_selingan()



func _layar_pesan(akar: Node, teks: String, teknis: = "") -> ColorRect:
	var layar: = ColorRect.new()
	layar.theme = load("res://scripts/gaya_hud.gd").tema_jendela()
	layar.process_mode = Node.PROCESS_MODE_ALWAYS
	layar.color = Color(0.05, 0.05, 0.08, 0.9)
	layar.mouse_filter = Control.MOUSE_FILTER_STOP
	layar.z_index = 100
	akar.add_child(layar)
	layar.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var tengah: = CenterContainer.new()
	tengah.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layar.add_child(tengah)
	var kolom: = VBoxContainer.new()
	kolom.add_theme_constant_override("separation", 18)
	tengah.add_child(kolom)
	var lebar: = minf(akar.get_viewport().get_visible_rect().size.x * 0.8, 900.0)
	var label: = Label.new()
	label.text = teks
	label.add_theme_font_size_override("font_size", 26)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size.x = lebar
	kolom.add_child(label)
	if teknis != "":
		var kecil: = Label.new()
		kecil.text = teknis
		kecil.add_theme_font_size_override("font_size", 16)
		kecil.modulate = Color(1, 1, 1, 0.6)
		kecil.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		kecil.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		kecil.custom_minimum_size.x = lebar
		kolom.add_child(kecil)
	layar.set_meta("kolom", kolom)
	return layar
