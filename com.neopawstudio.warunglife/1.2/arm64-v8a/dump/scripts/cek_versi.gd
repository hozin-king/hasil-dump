extends Node








const URL: = "https://neopawstudio.github.io/versi.json"
const URL_PLAY_STORE: = "market://details?id=com.neopawstudio.warunglife"
const URL_PLAY_STORE_WEB: = "https://play.google.com/store/apps/details?id=com.neopawstudio.warunglife"


const APP_STORE_ID: = "6832916163"
const URL_SITUS: = "https://neopawstudio.github.io"




static func di_ios() -> bool:
	return OS.get_name() == "iOS"


static func toko_ios_siap() -> bool:
	return APP_STORE_ID != ""



static func url_toko_web() -> String:
	if di_ios():
		return "https://apps.apple.com/app/id%s" % APP_STORE_ID if toko_ios_siap() else URL_SITUS
	return URL_PLAY_STORE_WEB

const GH: = preload("res://scripts/gaya_hud.gd")

static var saran_ditutup: = false






const KODE_BUILD_ANDROID: = 49
const KODE_BUILD_IOS: = 48


static func kode_sekarang() -> int:
	if OS.get_name() == "Android":
		return KODE_BUILD_ANDROID
	if OS.get_name() == "iOS":
		return KODE_BUILD_IOS
	var v: = String(ProjectSettings.get_setting("application/config/version", "0"))
	var bagian: = v.split(".")
	if bagian.size() >= 2 and bagian[0] == "0":
		return int(bagian[1])
	return int(bagian[0]) * 100 + (int(bagian[1]) if bagian.size() >= 2 else 0)





static func periksa(induk: Control) -> bool:
	if GameState.GOD_MODE and OS.has_feature("editor"):
		return false
	var req: = HTTPRequest.new()
	req.timeout = 3.0
	induk.add_child(req)

	if req.request(URL + "?t=%d" % int(Time.get_unix_time_from_system())) != OK:
		req.queue_free()
		return false
	var jawab: Array = await req.request_completed
	req.queue_free()
	if not is_instance_valid(induk) or jawab[0] != HTTPRequest.RESULT_SUCCESS or int(jawab[1]) != 200:
		return false
	var isi = JSON.parse_string((jawab[3] as PackedByteArray).get_string_from_utf8())
	if typeof(isi) != TYPE_DICTIONARY:
		return false

	if GameState.papan != null:
		GameState.papan.terapkan_saklar(isi)

	var akhiran: = "_ios" if di_ios() else ""
	var u: = String(isi.get("url_update" + akhiran, ""))
	if u.begins_with("https://"):
		url_update_jarak_jauh = u
	var kode: = kode_sekarang()
	var versi_baru: = String(isi.get("versi_terbaru" + akhiran, ""))
	if kode < int(isi.get("min_kode" + akhiran, 0)):
		_tampilkan(induk, true, versi_baru)
		return true
	if kode < int(isi.get("kode_terbaru" + akhiran, 0)) and not saran_ditutup:
		_tampilkan(induk, false, versi_baru)
	return false




const MASA_UJI: = false
const URL_GABUNG_PENGUJI: = "https://play.google.com/apps/testing/com.neopawstudio.warunglife"

static var url_update_jarak_jauh: = ""

static func buka_play_store() -> void :
	if url_update_jarak_jauh != "":
		OS.shell_open(url_update_jarak_jauh)
		return
	if di_ios():
		if toko_ios_siap():
			OS.shell_open("itms-apps://apps.apple.com/app/id%s" % APP_STORE_ID)
		return



	if OS.get_name() == "Android" and OS.shell_open(URL_PLAY_STORE) == OK:
		return
	if MASA_UJI:
		OS.shell_open(URL_GABUNG_PENGUJI)
		return
	OS.shell_open(URL_PLAY_STORE_WEB)


static func _tampilkan(induk: Control, wajib: bool, versi_baru: String) -> CanvasLayer:

	var kanvas: = CanvasLayer.new()
	kanvas.name = "CekVersi"
	kanvas.layer = 100
	induk.add_child(kanvas)
	var lapisan: = ColorRect.new()
	lapisan.color = Color(0.03, 0.02, 0.01, 0.82 if wajib else 0.55)
	lapisan.set_anchors_preset(Control.PRESET_FULL_RECT)
	lapisan.mouse_filter = Control.MOUSE_FILTER_STOP
	kanvas.add_child(lapisan)
	var tengah: = CenterContainer.new()
	tengah.set_anchors_preset(Control.PRESET_FULL_RECT)
	lapisan.add_child(tengah)
	var panel: = PanelContainer.new()
	GH.pasang_emas(panel)
	tengah.add_child(panel)
	var isi: = VBoxContainer.new()
	isi.add_theme_constant_override("separation", 16)
	panel.add_child(isi)
	var judul: = Label.new()
	judul.text = "Wajib update" if wajib else "Versi baru tersedia"
	judul.add_theme_font_size_override("font_size", 34)
	judul.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	isi.add_child(judul)
	var teks: = Label.new()
	if wajib:
		teks.text = ("Versi game ini sudah tidak didukung. Silakan update ke versi %s di Play Store untuk lanjut bermain. Simpanan permainanmu tetap aman." % versi_baru) if versi_baru != "" else "Versi game ini sudah tidak didukung. Silakan update ke versi terbaru di Play Store untuk lanjut bermain. Simpanan permainanmu tetap aman."
	else:
		teks.text = ("Versi %s sudah tersedia dengan perbaikan dan fitur baru. Update di Play Store, yuk! Simpanan permainanmu tetap aman." % versi_baru) if versi_baru != "" else "Versi baru sudah tersedia dengan perbaikan dan fitur baru. Update di Play Store, yuk! Simpanan permainanmu tetap aman."
	teks.add_theme_font_size_override("font_size", 24)
	teks.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	teks.custom_minimum_size.x = 580
	teks.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	isi.add_child(teks)


	var awas: = Label.new()
	awas.text = "Jangan hapus game untuk update, simpanan bisa hilang. Cukup tekan Update di toko aplikasi."
	awas.add_theme_font_size_override("font_size", 21)
	awas.add_theme_color_override("font_color", Color(1.0, 0.72, 0.45))
	awas.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	awas.custom_minimum_size.x = 580
	awas.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	isi.add_child(awas)

	var petunjuk: = Label.new()
	petunjuk.text = "Tombol Update belum muncul? Tutup App Store lalu buka lagi, atau tunggu beberapa menit." if di_ios()\
	else "Tombol Update belum muncul? Tutup Play Store lalu buka lagi, atau tunggu beberapa menit."
	petunjuk.add_theme_font_size_override("font_size", 18)
	petunjuk.add_theme_color_override("font_color", Color(1, 1, 1, 0.75))
	petunjuk.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	petunjuk.custom_minimum_size.x = 580
	petunjuk.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	isi.add_child(petunjuk)
	var baris: = HBoxContainer.new()
	baris.add_theme_constant_override("separation", 16)
	isi.add_child(baris)
	var pilihan: = [["Keluar" if wajib else "Nanti saja", &"TombolKayu", false], ["Update sekarang", &"TombolMerah", true]]
	if wajib and di_ios():
		pilihan.pop_front()
	for p in pilihan:
		var b: = Button.new()
		b.text = p[0]
		b.theme_type_variation = p[1]
		b.custom_minimum_size = Vector2(0, 66)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.add_theme_font_size_override("font_size", 26)
		var update: bool = p[2]
		b.pressed.connect( func():
			if update:
				buka_play_store()
			elif wajib:
				induk.get_tree().quit()
			else:
				saran_ditutup = true
				kanvas.queue_free())
		baris.add_child(b)
	return kanvas
