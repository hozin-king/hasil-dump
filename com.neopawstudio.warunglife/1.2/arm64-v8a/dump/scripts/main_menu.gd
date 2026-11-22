extends Control



const TAMPIL_UCAPAN_TESTER: = false
const JUDUL_UCAPAN: = "TERIMA KASIH"
const UCAPAN_TESTER: = "Terima kasih untuk 10.000 warga Threads yang mencoba early access Warung Life Simulator, dan terima kasih juga untuk warga baik hati yang mendukung kami dengan membeli dukungan. Info rilis akan diumumkan di Threads dan IG @neopawstudio"
const TANDA_UCAPAN: = "Tim NeoPaw Studio"






const MODE_HARD_TERSEDIA: = false


const PILIH_PENJAGA_AKTIF: = false


const PILIH_TOKOH_TAMPIL: = true
const NAMA_IBU: = "Eni"

@onready var tombol_start: Button = %TombolStart
@onready var tombol_load: Button = %TombolLoad
@onready var tombol_settings: Button = %TombolSettings
@onready var tombol_exit: Button = %TombolExit
@onready var pesan: Label = %Pesan
var tombol_slot: Button


func _ready() -> void :
	get_tree().paused = false

	GameState.teks_tokoh.atur("Misran", false)
	GameState.putar_musik("menu")


	tombol_start.text = "Mulai"
	tombol_load.text = "Lanjutkan"
	tombol_settings.text = "Pengaturan"
	tombol_exit.text = "Keluar"
	tombol_slot = tombol_load.duplicate()
	tombol_slot.unique_name_in_owner = false
	tombol_slot.text = "Load Save"
	tombol_load.get_parent().add_child(tombol_slot)
	tombol_load.get_parent().move_child(tombol_slot, tombol_load.get_index() + 1)

	var kolom: VBoxContainer = tombol_load.get_parent()
	kolom.add_theme_constant_override("separation", 10)
	(kolom.get_node("Jarak") as Control).custom_minimum_size.y = 4
	tombol_start.custom_minimum_size.y = 76
	for t in [tombol_load, tombol_slot, tombol_settings, tombol_exit]:
		t.custom_minimum_size.y = 64



	_pemain_baru = _belum_ada_simpanan()
	tombol_start.visible = _pemain_baru
	tombol_load.visible = not _pemain_baru

	tombol_start.pressed.connect(_on_start_ditekan)
	tombol_load.pressed.connect(_on_load_ditekan)
	tombol_slot.pressed.connect(_jendela_slot.bind(false))
	tombol_settings.pressed.connect(_on_settings_ditekan)
	tombol_exit.pressed.connect(_on_exit_ditekan)

	if OS.get_name() == "iOS":
		tombol_exit.hide()
	pesan.text = ""

	if GameState.god_aktif():
		var coba: = tombol_slot.duplicate() as Button
		coba.text = "Coba Mini-game"
		coba.custom_minimum_size.y = 52
		kolom.add_child(coba)
		kolom.move_child(coba, tombol_exit.get_index())
		coba.pressed.connect(_jendela_coba_minigame)

	%Versi.text = "Versi %s" % ProjectSettings.get_setting("application/config/version", "uji coba")

	if OS.get_name() in ["Android", "iOS"]:
		%Versi.text += " (%d)" % preload("res://scripts/cek_versi.gd").kode_sekarang()
	GameState.sedang_main = false

	_gaya_menu()

	_cek_versi()
	_cek_cloud()
	if _pemain_baru:
		_tawarkan_cadangan_perangkat()
	if GameState.cadangan != null and GameState.cadangan.dipindah_kabar:
		GameState.cadangan.dipindah_kabar = false
		_tampilkan_pesan("Kode Warung HP ini sudah dipakai di HP lain. Warung di HP ini sekarang terpisah dan mendapat Kode Warung baru.")

	if GameState.info_reset_rilis:
		GameState.info_reset_rilis = false
		_tampilkan_pesan("Terima kasih sudah ikut uji coba! Versi rilis dimulai dari awal. Pendukung bisa melanjutkan progres uji coba lewat kode pendukung di Dukung Kami.")




const GH: = preload("res://scripts/gaya_hud.gd")

func _gaya_menu() -> void :
	($Latar as TextureRect).texture = load("res://assets/latar/latar_warung_kosong.png")
	var kolom: VBoxContainer = tombol_load.get_parent()
	kolom.alignment = BoxContainer.ALIGNMENT_BEGIN

	var kiri: = maxf(56.0, GH.tepi_kiri_kanan(get_viewport()).x)
	kolom.offset_left = kiri
	kolom.offset_right = kiri + 414.0
	(kolom.get_node("Judul") as Control).custom_minimum_size.y = 190
	(kolom.get_node("Subjudul") as Control).hide()
	kolom.add_theme_constant_override("separation", 10)
	for t: Button in [tombol_start, tombol_load, tombol_slot, tombol_settings, tombol_exit]:

		var utama: = t == tombol_start or t == tombol_load

		var pg: = Vector4(30, 2, 30, 6)
		var gaya: StyleBoxFlat = GH.tombol_emas(pg) if utama else GH.tombol_emas_gelap(pg)
		var tekan: StyleBoxFlat = GH.tombol_emas(pg, true) if utama else GH.tombol_emas_gelap(pg, true)
		t.add_theme_stylebox_override("normal", gaya)
		t.add_theme_stylebox_override("hover", gaya)
		t.add_theme_stylebox_override("pressed", tekan)
		t.add_theme_stylebox_override("hover_pressed", tekan)
		t.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		t.alignment = HORIZONTAL_ALIGNMENT_CENTER
		t.text = t.text.to_upper()
		t.add_theme_font_override("font", GH.cetak())
		t.add_theme_font_size_override("font_size", 42)
		t.add_theme_constant_override("outline_size", 0)
		var warna: = GH.TEKS_GELAP if utama else GH.EMAS_MUDA
		for k in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color", "font_focus_color"]:
			t.add_theme_color_override(k, warna)
		t.custom_minimum_size.y = 62

	if GameState.ada_simpanan():
		var info: = GameState.info_slot(GameState.slot_terakhir)
		if not info.is_empty():
			tombol_load.custom_minimum_size.y = 78

			var l: = GH.label("Warung %s · Hari %d · %s · Level %d" % [info["nama_warung"], info["hari"], GameState.format_rupiah(info["uang"]), info["level"]], 14, Color(GH.TEKS_GELAP, 0.8), false, 0)
			l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			l.set_anchors_preset(Control.PRESET_TOP_WIDE)
			l.offset_top = 50
			tombol_load.add_child(l)
			for k in ["normal", "hover", "pressed", "hover_pressed"]:
				var s: = tombol_load.get_theme_stylebox(k).duplicate() as StyleBoxFlat
				s.content_margin_bottom = 22
				tombol_load.add_theme_stylebox_override(k, s)
	GH.gaya_label(pesan, 20, Color.WHITE)

	var kanan: VBoxContainer = $KolomKanan
	kanan.offset_left = -470.0
	kanan.offset_right = -30.0
	kanan.offset_top = -200.0
	kanan.offset_bottom = 200.0
	(kanan.get_node("LogoStudio") as Control).custom_minimum_size.y = 340

	_tengahkan_logo.call_deferred()
	if not get_viewport().size_changed.is_connected(_tengahkan_logo):
		get_viewport().size_changed.connect(_tengahkan_logo)
	var versi: Label = %Versi
	versi.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	GH.gaya_label(versi, 22, Color.WHITE, true)
	GH.tebal(versi)
	_tombol_yang_baru()

	if TAMPIL_UCAPAN_TESTER and OS.get_name() == "Android":

		var kotak_ucapan: = PanelContainer.new()
		var gaya: = StyleBoxFlat.new()
		gaya.bg_color = Color(0.07, 0.05, 0.03, 0.82)
		gaya.border_color = Color(GH.KUNING, 0.75)
		gaya.set_border_width_all(2)
		gaya.set_corner_radius_all(18)
		gaya.content_margin_left = 24
		gaya.content_margin_right = 24
		gaya.content_margin_top = 12
		gaya.content_margin_bottom = 12
		gaya.shadow_color = Color(0, 0, 0, 0.45)
		gaya.shadow_size = 12
		kotak_ucapan.add_theme_stylebox_override("panel", gaya)


		kotak_ucapan.anchor_top = 1.0
		kotak_ucapan.anchor_bottom = 1.0
		kotak_ucapan.grow_vertical = Control.GROW_DIRECTION_BEGIN
		kotak_ucapan.offset_bottom = - JARAK_BAWAH_UCAPAN
		add_child(kotak_ucapan)
		_kotak_ucapan = kotak_ucapan
		var isi_ucapan: = VBoxContainer.new()
		isi_ucapan.add_theme_constant_override("separation", 5)
		kotak_ucapan.add_child(isi_ucapan)
		var judul: = GH.tebal(GH.label(JUDUL_UCAPAN, 30, GH.KUNING, true))
		judul.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		isi_ucapan.add_child(judul)
		var garis: = ColorRect.new()
		garis.color = Color(GH.KUNING, 0.6)
		garis.custom_minimum_size = Vector2(120, 2)
		garis.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		isi_ucapan.add_child(garis)
		var ucapan: = Label.new()
		ucapan.text = UCAPAN_TESTER
		ucapan.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		ucapan.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		GH.gaya_label(ucapan, 21, Color(1, 0.98, 0.93))
		ucapan.add_theme_constant_override("line_spacing", 1)
		isi_ucapan.add_child(ucapan)
		var tanda: = GH.label(TANDA_UCAPAN, 20, GH.KUNING, true)
		tanda.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		isi_ucapan.add_child(tanda)

		kotak_ucapan.modulate.a = 0.0
		create_tween().tween_property(kotak_ucapan, "modulate:a", 1.0, 0.8).set_delay(0.3)


const JARAK_BAWAH_UCAPAN: = 40.0
var _kotak_ucapan: PanelContainer = null

func _tengahkan_logo() -> void :
	if not is_inside_tree():
		return
	_atur_ucapan()
	var kanan: VBoxContainer = $KolomKanan
	var layar: = get_viewport_rect().size
	var kiri_menu: float = (tombol_load.get_parent() as Control).get_global_rect().end.x
	var kanan_aman: = layar.x - maxf(GH.tepi_kiri_kanan(get_viewport()).y - GH.TEPI_SAMPING, 0.0)
	var lebar: = clampf(kanan_aman - kiri_menu - 40.0, 200.0, 440.0)
	var tengah: = (kiri_menu + kanan_aman) / 2.0
	kanan.offset_left = tengah - layar.x - lebar / 2.0
	kanan.offset_right = kanan.offset_left + lebar


func _atur_ucapan() -> void :
	if _kotak_ucapan == null or not is_instance_valid(_kotak_ucapan):
		return
	var layar: = get_viewport_rect().size
	var kiri_menu: float = (tombol_load.get_parent() as Control).get_global_rect().end.x
	var kanan_aman: = layar.x - maxf(GH.tepi_kiri_kanan(get_viewport()).y - GH.TEPI_SAMPING, 0.0)
	_kotak_ucapan.offset_left = kiri_menu + 36.0
	_kotak_ucapan.offset_right = kanan_aman - 36.0
	_kotak_ucapan.offset_bottom = - JARAK_BAWAH_UCAPAN
	_naikkan_logo.call_deferred()



func _naikkan_logo() -> void :
	if _kotak_ucapan == null or not is_instance_valid(_kotak_ucapan):
		return

	await get_tree().process_frame
	await get_tree().process_frame
	if not is_instance_valid(_kotak_ucapan):
		return
	var kanan: VBoxContainer = $KolomKanan
	var layar_y: = get_viewport_rect().size.y
	var tinggi_kartu: = maxf(_kotak_ucapan.size.y, _kotak_ucapan.get_combined_minimum_size().y)
	if tinggi_kartu < 60.0:
		tinggi_kartu = 190.0
	var atas_kartu: = layar_y - JARAK_BAWAH_UCAPAN - tinggi_kartu
	kanan.offset_top = 8.0 - layar_y / 2.0
	kanan.offset_bottom = maxf(atas_kartu - 10.0, layar_y * 0.45) - layar_y / 2.0




var _versi_siap: = false
var _versi_wajib: = false

func _cek_versi() -> void :
	_versi_wajib = await preload("res://scripts/cek_versi.gd").periksa(self)
	_versi_siap = true
	_yang_baru_otomatis()
	_ajak_akun_otomatis()
	_cloud_mundur_otomatis()




func _cloud_mundur_otomatis() -> void :

	if _versi_wajib or GameState.akun == null:
		return
	while not _cloud_siap and is_inside_tree():
		await get_tree().process_frame
	if not _perlu_pilih_cloud():
		return
	await GameState.get_tree().create_timer(1.5).timeout
	while is_inside_tree() and (get_node_or_null("CekVersi") != null or get_node_or_null("YangBaru") != null\
	or not get_tree().get_nodes_in_group("lapisan_atas").is_empty()):
		await GameState.get_tree().create_timer(0.5).timeout
	if not is_inside_tree() or not _perlu_pilih_cloud():
		return
	if GameState.akun.bentrok:
		_pilih_cloud_ditawarkan = true
	_buka_pilih_cloud()


func _perlu_pilih_cloud() -> bool:
	return GameState.akun != null and GameState.akun.tertaut() and (GameState.akun.bentrok or GameState.akun.cek_mundur())


func _buka_pilih_cloud() -> void :
	for n in get_tree().root.get_children():
		var s: Script = n.get_script()
		if s != null and s.resource_path.ends_with("akun_tautan.gd"):
			return
	get_tree().root.add_child(load("res://scripts/akun_tautan.gd").new())






var _cloud_siap: = false

func _cek_cloud() -> void :
	if GameState.akun != null and GameState.akun.tertaut():
		await GameState.akun.cek_bentrok(5.0)
	_cloud_siap = true



func _tunggu_cloud() -> bool:
	if not _cloud_siap:
		_tampilkan_pesan("Memeriksa simpanan cloud...")
		while not _cloud_siap and is_inside_tree():
			await get_tree().process_frame
		_tampilkan_pesan("")


	if GameState.akun != null and GameState.akun.tertaut() and GameState.akun.bentrok and not _pilih_cloud_ditawarkan:
		_pilih_cloud_ditawarkan = true
		GameState.bunyi("salah")
		_buka_pilih_cloud()
		return false
	return true

var _pilih_cloud_ditawarkan: = false




func _ajak_akun_otomatis() -> void :
	if _versi_wajib or GameState.akun == null or not GameState.akun.perlu_ajak():
		return
	await GameState.get_tree().create_timer(1.5).timeout
	while is_inside_tree() and (get_node_or_null("CekVersi") != null or get_node_or_null("YangBaru") != null\
	or not get_tree().get_nodes_in_group("lapisan_atas").is_empty()):
		await GameState.get_tree().create_timer(0.5).timeout
	if not is_inside_tree() or not GameState.akun.perlu_ajak():
		return
	get_tree().root.add_child(load("res://scripts/akun_ajak.gd").new())



const YANG_BARU: = preload("res://scripts/yang_baru.gd")


func _tombol_yang_baru() -> void :
	if YANG_BARU.versi_isi() == "":
		return
	var b: = Button.new()
	b.text = "Yang Baru"
	b.focus_mode = Control.FOCUS_NONE
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	b.custom_minimum_size = Vector2(190, 46)
	b.add_theme_font_override("font", GH.cetak())
	b.add_theme_font_size_override("font_size", 22)
	var gaya: = GH.kaca(0.55, 14, Vector4(18, 4, 18, 6))
	gaya.border_color = Color(GH.KUNING, 0.8)
	gaya.set_border_width_all(2)
	var tekan: = GH.kaca(0.75, 14, Vector4(18, 4, 18, 6))
	tekan.border_color = GH.KUNING
	tekan.set_border_width_all(2)
	b.add_theme_stylebox_override("normal", gaya)
	b.add_theme_stylebox_override("hover", tekan)
	b.add_theme_stylebox_override("pressed", tekan)
	b.add_theme_stylebox_override("hover_pressed", tekan)
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	for k in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color"]:
		b.add_theme_color_override(k, GH.KUNING)
	b.pressed.connect( func():
		GameState.klik()
		_buka_yang_baru())
	var kanan: VBoxContainer = $KolomKanan
	kanan.add_child(b)
	kanan.move_child(b, %Versi.get_index() + 1)


func _buka_yang_baru() -> void :
	if get_node_or_null("YangBaru") != null:
		return
	var kartu: Control = YANG_BARU.new()
	kartu.name = "YangBaru"
	add_child(kartu)




func _yang_baru_otomatis() -> void :
	if _versi_wajib or not is_inside_tree() or not YANG_BARU.perlu_tampil():
		return
	var ada_slot: = false
	for n in range(1, GameState.JUMLAH_SLOT + 1):
		ada_slot = ada_slot or GameState.ada_slot(n)
	if not ada_slot:
		YANG_BARU.tandai_dilihat()
		return
	var cek: = get_node_or_null("CekVersi")
	if cek != null:
		await cek.tree_exited
		if not is_inside_tree():
			return
	_buka_yang_baru()



func _tunggu_versi() -> bool:
	if not _versi_siap:
		_tampilkan_pesan("Memeriksa versi game...")
		while not _versi_siap and is_inside_tree():
			await get_tree().process_frame
		_tampilkan_pesan("")
	return not _versi_wajib


var _pemain_baru: = false


func _belum_ada_simpanan() -> bool:
	for n in range(1, GameState.JUMLAH_SLOT + 1):
		if GameState.ada_slot(n) or GameState.slot_rusak(n):
			return false
	return GameState.daftar_simpanan_lama().is_empty()


func _on_start_ditekan() -> void :



	if _belum_ada_simpanan():
		_tanya_baru_atau_pulihkan()
		return
	_jendela_slot(true)


func _mulai_baru_slot1() -> void :
	_slot_baru = 1
	_pilih_mode()




func _jendela_pilihan(judul: String, teks: String, pilihan: Array) -> Control:

	var lapisan: = ColorRect.new()
	lapisan.color = Color(0.03, 0.02, 0.01, 0.55)
	lapisan.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(lapisan)
	var tengah: = CenterContainer.new()
	tengah.set_anchors_preset(Control.PRESET_FULL_RECT)
	lapisan.add_child(tengah)
	var panel: = PanelContainer.new()
	GH.pasang_emas(panel)
	tengah.add_child(panel)
	var isi: = VBoxContainer.new()
	isi.add_theme_constant_override("separation", 14)
	panel.add_child(isi)
	var j: = Label.new()
	j.text = judul
	j.add_theme_font_size_override("font_size", 28)
	j.add_theme_color_override("font_color", GH.KUNING)
	j.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	isi.add_child(j)
	var label: = Label.new()
	label.text = teks
	label.add_theme_font_size_override("font_size", 21)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size.x = 600
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	isi.add_child(label)
	for p in pilihan:
		var b: = Button.new()
		b.text = p[0]
		b.theme_type_variation = p[1]
		b.custom_minimum_size = Vector2(0, 62)
		b.add_theme_font_size_override("font_size", 23)
		var aksi: Callable = p[2]
		b.pressed.connect( func():
			GameState.klik()
			lapisan.queue_free()
			aksi.call())
		isi.add_child(b)
	return lapisan


func _tanya_baru_atau_pulihkan() -> void :
	_jendela_pilihan("Selamat datang!", "Baru pertama kali main, atau sudah pernah main di HP lain / sebelum game dihapus?", [
		["Main baru", &"TombolHijau", _mulai_baru_slot1], 
		["Pulihkan warung lama", &"TombolKayu", _buka_pulihkan]])


func _buka_pulihkan() -> void :
	var jendela: CanvasLayer = load("res://scripts/pindah_hp.gd").new()
	jendela.dalam_game = false
	get_tree().root.add_child(jendela)


var _cadangan_ditawarkan: = false

func _tawarkan_cadangan_perangkat() -> void :
	if _cadangan_ditawarkan or GameState.cadangan == null or OS.get_name() != "Android":
		return
	_cadangan_ditawarkan = true
	var daftar: Array = await GameState.cadangan.cari_di_perangkat()
	if daftar.is_empty() or not is_inside_tree() or not _belum_ada_simpanan():
		return
	while is_inside_tree() and ( not _versi_siap or get_node_or_null("CekVersi") != null or get_node_or_null("YangBaru") != null):
		await get_tree().create_timer(0.5).timeout
	if not is_inside_tree() or _versi_wajib:
		return
	var pilihan: Array = []
	for w in daftar.slice(0, 3):
		var teks: = GameState.tk("Pulihkan %s (Level %d, hari ke-%d)") % [GameState.cadangan.nama_tampil(String(w.get("nama", ""))), int(w.get("level", 1)), int(w.get("hari", 1))]
		pilihan.append([teks, &"TombolHijau", _pulihkan_dari_perangkat.bind(String(w.get("id", "")))])
	pilihan.append(["Tidak, main baru", &"TombolKayu", func(): pass])
	_jendela_pilihan("Warungmu ditemukan!", "Kami menemukan warung yang pernah dimainkan di HP ini. Mau dilanjutkan?", pilihan)


func _pulihkan_dari_perangkat(id: String) -> void :
	_tampilkan_pesan("Memulihkan warung...")
	var alasan: String = await GameState.cadangan.pulihkan("", id)
	if not is_inside_tree():
		return
	if alasan != "":
		_tampilkan_pesan(alasan)
		GameState.bunyi("salah")
		return
	GameState.bunyi("hadiah")
	if GameState.info_pindah_iklan != "":
		_tampilkan_pesan(GameState.info_pindah_iklan)
		await get_tree().create_timer(3.0).timeout
	get_tree().reload_current_scene()


var _slot_baru: = 1

func _mulai_dengan_mode(mode: String, penjaga: = "bapak", nama: = "Misran") -> void :
	if not await _tunggu_versi():
		return
	if GameState.ada_slot(_slot_baru) and GameState.akun != null:
		GameState.akun.lupakan_kemajuan()
	GameState.hapus_slot(_slot_baru)
	GameState.slot_aktif = _slot_baru
	GameState.mode = mode

	GameState.mulai_game_baru()
	GameState.pilih_penjaga(penjaga, nama)
	GameState.tutorial_awal = not GameState.tutorial_selesai
	if GameState.tutorial_awal:
		GameState.ulang_tip()
	GameState.putar_intro = true
	GameState.ganti_layar(self, "res://scenes/warung.tscn")


func _on_load_ditekan() -> void :


	if not GameState.ada_simpanan():
		_jendela_slot(false)
		return
	_lanjut_dari_slot(0)


func _lanjut_dari_slot(n: int) -> void :
	if not await _tunggu_versi():
		return
	if not await _tunggu_cloud():
		return
	if GameState.muat(n):

		if GameState.status_hari == "persiapan" and (GameState.menit <= GameState.JAM_MULAI + 1 or GameState.bangun_kesiangan) and not GameState.bangkrut:
			GameState.tujuan_jelajah = {"area": "kamar", "muncul": "kasur", "bangun": true}
			GameState.ganti_layar(self, "res://scenes/jelajah.tscn")
			return

		var lokasi: Dictionary = GameState.lokasi
		if String(lokasi.get("adegan", "")) == "jelajah" and not GameState.bangkrut:
			GameState.tujuan_jelajah = {"area": String(lokasi.get("area", "warung")), "muncul": "", "posisi": lokasi.get("posisi", [])}
			GameState.ganti_layar(self, "res://scenes/jelajah.tscn")
			return

		if GameState.status_hari == "tutup" and not GameState.bangkrut:
			GameState.tujuan_jelajah = {"area": "warung", "muncul": "depan_warung"}
			GameState.ganti_layar(self, "res://scenes/jelajah.tscn")
			return
		GameState.putar_intro = true
		GameState.ganti_layar(self, "res://scenes/warung.tscn")
	elif GameState.slot_rusak(n if n > 0 else GameState.slot_terakhir):
		_tampilkan_pesan("Simpanan tidak bisa dibuka (rusak). Coba slot lain di Load Save.")
	elif not GameState.daftar_simpanan_lama().is_empty():
		_tampilkan_pesan("Ada simpanan lama di HP ini. Buka Load Save lalu Pulihkan simpanan lama.")
	else:
		_jendela_slot(false)




func _jendela_slot(baru: bool) -> void :
	var lapisan: = ColorRect.new()
	lapisan.color = Color(0.03, 0.02, 0.01, 0.6)
	lapisan.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(lapisan)
	var tengah: = CenterContainer.new()
	tengah.set_anchors_preset(Control.PRESET_FULL_RECT)
	lapisan.add_child(tengah)
	var panel: = PanelContainer.new()
	GH.pasang_emas(panel)
	tengah.add_child(panel)
	var isi: = VBoxContainer.new()
	isi.add_theme_constant_override("separation", 12)
	panel.add_child(isi)
	var judul: = Label.new()
	judul.theme_type_variation = &"LabelKepala"
	judul.add_theme_font_size_override("font_size", 36)
	judul.text = "Pilih slot untuk permainan baru" if baru else "Load Save"
	judul.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	isi.add_child(judul)
	var grid: = GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 10)
	isi.add_child(grid)
	for n in range(1, GameState.JUMLAH_SLOT + 1):
		var info: = GameState.info_slot(n)
		var baris: = HBoxContainer.new()
		baris.add_theme_constant_override("separation", 6)
		grid.add_child(baris)
		var t: = Button.new()
		t.custom_minimum_size = Vector2(430, 92)
		t.alignment = HORIZONTAL_ALIGNMENT_LEFT
		t.add_theme_font_size_override("font_size", 21)
		t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var rusak: = info.is_empty() and GameState.slot_rusak(n)
		if rusak:


			t.text = "Slot %d  ·  Simpanan rusak" % n
			t.theme_type_variation = &"TombolKayu"
		elif info.is_empty():

			t.text = "Slot %d  ·  Kosong\n+ Main baru di sini" % n
			t.theme_type_variation = &"TombolKayu"
		else:
			t.text = "Slot %d  ·  Warung %s  ·  %s  ·  Level %d\n%s  ·  %s" % [n, info["nama_warung"], info["panggilan"], info["level"], info["hari_teks"], GameState.format_rupiah(info["uang"])]
			t.theme_type_variation = &"TombolHijau" if n == GameState.slot_terakhir else &"TombolKayu"
		t.pressed.connect( func():
			if baru:
				_slot_baru = n
				if rusak:
					_dialog_slot_rusak(n, lapisan)
				elif info.is_empty():
					lapisan.queue_free()
					_pilih_mode()
				else:
					_konfirmasi("Slot %d sudah berisi Warung %s. Mulai baru dan timpa simpanan ini?" % [n, info["nama_warung"]], func():
						lapisan.queue_free()
						_pilih_mode())
			elif rusak:
				_slot_baru = n
				_dialog_slot_rusak(n, lapisan)
			elif info.is_empty():
				_slot_baru = n
				lapisan.queue_free()
				_pilih_mode()
			else:
				_lanjut_dari_slot(n))
		baris.add_child(t)
		if not baru and not info.is_empty():
			var hapus: = Button.new()
			hapus.text = "Hapus"
			hapus.theme_type_variation = &"TombolMerah"
			hapus.custom_minimum_size = Vector2(96, 92)
			hapus.add_theme_font_size_override("font_size", 18)
			hapus.pressed.connect( func():
				_konfirmasi("Hapus simpanan Slot %d (Warung %s)? Tidak bisa dikembalikan." % [n, info["nama_warung"]], func():
					if GameState.akun != null:
						GameState.akun.lupakan_kemajuan()
					GameState.hapus_slot(n)
					lapisan.queue_free()
					_jendela_slot(false)))
			baris.add_child(hapus)

	var lama: = GameState.daftar_simpanan_lama()
	if not lama.is_empty():
		var pulihkan: = Button.new()
		pulihkan.text = "Pulihkan simpanan lama (%d)" % lama.size()
		pulihkan.theme_type_variation = &"TombolHijau"
		pulihkan.custom_minimum_size = Vector2(0, 62)
		pulihkan.pressed.connect( func():
			lapisan.queue_free()
			_jendela_simpanan_lama(lama, baru))
		isi.add_child(pulihkan)
	var batal: = Button.new()
	batal.text = "Kembali"
	batal.theme_type_variation = &"TombolKayu"
	batal.custom_minimum_size = Vector2(0, 62)
	batal.pressed.connect( func():
		lapisan.queue_free()
		_ready_ulang())
	isi.add_child(batal)




func _jendela_simpanan_lama(lama: Array, baru: bool) -> void :
	var lapisan: = ColorRect.new()
	lapisan.color = Color(0.03, 0.02, 0.01, 0.6)
	lapisan.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(lapisan)
	var tengah: = CenterContainer.new()
	tengah.set_anchors_preset(Control.PRESET_FULL_RECT)
	lapisan.add_child(tengah)
	var panel: = PanelContainer.new()
	GH.pasang_emas(panel)
	tengah.add_child(panel)
	var isi: = VBoxContainer.new()
	isi.add_theme_constant_override("separation", 12)
	panel.add_child(isi)
	var judul: = Label.new()
	judul.theme_type_variation = &"LabelKepala"
	judul.add_theme_font_size_override("font_size", 34)
	judul.text = "Pulihkan simpanan lama"
	judul.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	isi.add_child(judul)
	var ket: = Label.new()
	ket.text = "Salinan simpanan yang masih ada di HP ini. Pilih warung yang mau dilanjutkan."
	ket.add_theme_font_size_override("font_size", 20)
	ket.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ket.custom_minimum_size.x = 880
	ket.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	isi.add_child(ket)
	var gulir: = ScrollContainer.new()
	gulir.custom_minimum_size = Vector2(880, mini(lama.size(), 4) * 102)
	gulir.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	isi.add_child(gulir)
	var daftar: = VBoxContainer.new()
	daftar.add_theme_constant_override("separation", 10)
	daftar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	gulir.add_child(daftar)
	for c in lama.slice(0, 12):
		var t: = Button.new()
		t.custom_minimum_size = Vector2(0, 92)
		t.alignment = HORIZONTAL_ALIGNMENT_LEFT
		t.add_theme_font_size_override("font_size", 21)
		t.theme_type_variation = &"TombolKayu"
		var tgl: = String(c["disimpan"]).substr(0, 10)
		var bagian_tgl: = tgl.split("-")
		if bagian_tgl.size() == 3:
			tgl = "%s/%s/%s" % [bagian_tgl[2], bagian_tgl[1], bagian_tgl[0]]
		t.text = "Warung %s  ·  %s  ·  Level %d\n%s  ·  %s  ·  disimpan %s" % [c["nama_warung"], c["panggilan"], c["level"], c["hari_teks"], GameState.format_rupiah(c["uang"]), tgl]
		t.pressed.connect( func():
			var n: = GameState.slot_untuk_pulihkan()
			var info: = GameState.info_slot(n)
			var teks: = "Pulihkan Warung %s (Level %d) ke Slot %d?" % [c["nama_warung"], c["level"], n]
			if not info.is_empty():
				teks = "Pulihkan Warung %s (Level %d) ke Slot %d? Warung %s yang ada di slot itu disisihkan dan bisa dipulihkan lagi dari sini." % [c["nama_warung"], c["level"], n, info["nama_warung"]]
			_konfirmasi(teks, func():
				if GameState.pulihkan_simpanan_lama(String(c["jalur"]), n):
					lapisan.queue_free()
					_lanjut_dari_slot(n)
				else:
					_tampilkan_pesan("Simpanan ini tidak bisa dipulihkan.")))
		daftar.add_child(t)
	var kembali: = Button.new()
	kembali.text = "Kembali"
	kembali.theme_type_variation = &"TombolKayu"
	kembali.custom_minimum_size = Vector2(0, 62)
	kembali.pressed.connect( func():
		lapisan.queue_free()
		_jendela_slot(baru))
	isi.add_child(kembali)



func _ready_ulang() -> void :

	_pemain_baru = _belum_ada_simpanan()
	tombol_start.visible = _pemain_baru
	tombol_load.visible = not _pemain_baru



func _konfirmasi(teks: String, ya: Callable) -> void :
	var lapisan: = ColorRect.new()
	lapisan.color = Color(0.03, 0.02, 0.01, 0.55)
	lapisan.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(lapisan)
	var tengah: = CenterContainer.new()
	tengah.set_anchors_preset(Control.PRESET_FULL_RECT)
	lapisan.add_child(tengah)
	var panel: = PanelContainer.new()
	GH.pasang_emas(panel)
	tengah.add_child(panel)
	var isi: = VBoxContainer.new()
	isi.add_theme_constant_override("separation", 16)
	panel.add_child(isi)
	var label: = Label.new()
	label.text = teks
	label.add_theme_font_size_override("font_size", 26)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size.x = 560
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	isi.add_child(label)
	var baris: = HBoxContainer.new()
	baris.add_theme_constant_override("separation", 16)
	isi.add_child(baris)
	for pilihan in [["Batal", &"TombolKayu", false], ["Ya", &"TombolMerah", true]]:
		var b: = Button.new()
		b.text = pilihan[0]
		b.theme_type_variation = pilihan[1]
		b.custom_minimum_size = Vector2(0, 66)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.add_theme_font_size_override("font_size", 26)
		var setuju: bool = pilihan[2]
		b.pressed.connect( func():
			lapisan.queue_free()
			if setuju:
				ya.call())
		baris.add_child(b)





const URL_FORM_BANTUAN: = "https://forms.gle/4Dt5jjowBuxtc2WL9"

func _dialog_slot_rusak(n: int, lapisan_slot: Control) -> void :
	var lapisan: = ColorRect.new()
	lapisan.color = Color(0.03, 0.02, 0.01, 0.55)
	lapisan.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(lapisan)
	var tengah: = CenterContainer.new()
	tengah.set_anchors_preset(Control.PRESET_FULL_RECT)
	lapisan.add_child(tengah)
	var panel: = PanelContainer.new()
	GH.pasang_emas(panel)
	tengah.add_child(panel)
	var isi: = VBoxContainer.new()
	isi.add_theme_constant_override("separation", 12)
	panel.add_child(isi)
	var judul: = Label.new()
	judul.text = "Simpanan Slot %d rusak" % n
	judul.add_theme_font_size_override("font_size", 28)
	judul.add_theme_color_override("font_color", GH.KUNING)
	judul.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	isi.add_child(judul)
	var akun_tertaut: bool = GameState.akun != null and GameState.akun.tertaut()
	var saran: = "Biasanya karena game tertutup saat sedang menyimpan di versi lama. Jangan mulai baru dulu, warungmu masih bisa diselamatkan:"
	saran += "\n" + ("• Ambil dari cloud: Pengaturan > Akun tertaut > Ambil dari cloud." if akun_tertaut else "• Kalau pernah menautkan akun Google: Pengaturan > Tautkan akun.")
	saran += "\n• Minta bantuan: isi form, kami kirim kode pemulihan lewat email."
	var label: = Label.new()
	label.text = saran
	label.add_theme_font_size_override("font_size", 21)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size.x = 620
	isi.add_child(label)
	var lama: = GameState.daftar_simpanan_lama()
	if not lama.is_empty():
		var pulihkan: = Button.new()
		pulihkan.text = "Pulihkan simpanan lama (%d)" % lama.size()
		pulihkan.theme_type_variation = &"TombolHijau"
		pulihkan.custom_minimum_size = Vector2(0, 60)
		pulihkan.add_theme_font_size_override("font_size", 22)
		pulihkan.pressed.connect( func():
			lapisan.queue_free()
			if is_instance_valid(lapisan_slot):
				lapisan_slot.queue_free()
			_jendela_simpanan_lama(lama, true))
		isi.add_child(pulihkan)
	var bantuan: = Button.new()
	bantuan.text = "Minta bantuan (buka form)"
	bantuan.theme_type_variation = &"TombolHijau" if lama.is_empty() else &"TombolKayu"
	bantuan.custom_minimum_size = Vector2(0, 60)
	bantuan.add_theme_font_size_override("font_size", 22)
	bantuan.pressed.connect( func(): OS.shell_open(URL_FORM_BANTUAN))
	isi.add_child(bantuan)
	var baris: = HBoxContainer.new()
	baris.add_theme_constant_override("separation", 12)
	isi.add_child(baris)
	var batal: = Button.new()
	batal.text = "Batal"
	batal.theme_type_variation = &"TombolKayu"
	batal.custom_minimum_size = Vector2(0, 60)
	batal.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	batal.add_theme_font_size_override("font_size", 22)
	batal.pressed.connect( func(): lapisan.queue_free())
	baris.add_child(batal)
	var mulai: = Button.new()
	mulai.text = "Tetap mulai baru"
	mulai.theme_type_variation = &"TombolMerah"
	mulai.custom_minimum_size = Vector2(0, 60)
	mulai.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mulai.add_theme_font_size_override("font_size", 22)
	mulai.pressed.connect( func():
		lapisan.queue_free()
		_konfirmasi("Yakin mulai baru di Slot %d? Berkas rusaknya tetap disimpan terpisah, tapi warung lama tidak bisa dilanjutkan dari slot ini." % n, func():
			if is_instance_valid(lapisan_slot):
				lapisan_slot.queue_free()
			_pilih_mode()))
	baris.add_child(mulai)


func _on_settings_ditekan() -> void :
	GameState.ganti_layar(self, "res://scenes/pengaturan.tscn")


func _on_exit_ditekan() -> void :

	get_tree().quit()


func _tampilkan_pesan(teks: String) -> void :
	pesan.text = teks



func _pilih_mode() -> void :
	var lapisan: = ColorRect.new()
	lapisan.color = Color(0.03, 0.02, 0.01, 0.6)
	lapisan.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(lapisan)
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
	judul.theme_type_variation = &"LabelKepala"
	judul.add_theme_font_size_override("font_size", 40)
	judul.text = "Pilih mode permainan"
	judul.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	isi.add_child(judul)
	var baris: = HBoxContainer.new()
	baris.add_theme_constant_override("separation", 20)
	isi.add_child(baris)
	for pilihan in [["casual", "Casual", &"TombolHijau"], ["hard", "Hard", &"TombolMerah"]]:
		var kartu: = VBoxContainer.new()
		kartu.custom_minimum_size = Vector2(300, 0)
		kartu.add_theme_constant_override("separation", 10)
		baris.add_child(kartu)
		var t: = Button.new()
		t.text = pilihan[1]
		t.theme_type_variation = pilihan[2]
		t.custom_minimum_size = Vector2(0, 86)
		t.add_theme_font_size_override("font_size", 36)
		var mode_ini: String = pilihan[0]
		t.pressed.connect( func():
			lapisan.queue_free()
			if PILIH_PENJAGA_AKTIF:
				_pilih_penjaga(mode_ini)
			elif PILIH_TOKOH_TAMPIL:
				_pilih_tokoh(mode_ini)
			else:
				_mulai_dengan_mode(mode_ini))
		kartu.add_child(t)

		if pilihan[0] == "hard" and not MODE_HARD_TERSEDIA:
			t.disabled = true
			t.text = "Hard (Segera Hadir)"
			t.add_theme_font_size_override("font_size", 26)
			t.theme_type_variation = &"TombolKayu"
			kartu.modulate.a = 0.7
	var batal: = Button.new()
	batal.text = "Kembali"
	batal.theme_type_variation = &"TombolKayu"
	batal.custom_minimum_size = Vector2(0, 66)
	batal.pressed.connect(lapisan.queue_free)
	isi.add_child(batal)



func _pilih_tokoh(mode: String) -> void :
	var lapisan: = ColorRect.new()
	lapisan.color = Color(0.03, 0.02, 0.01, 0.6)
	lapisan.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(lapisan)
	var tengah: = CenterContainer.new()
	tengah.set_anchors_preset(Control.PRESET_FULL_RECT)
	lapisan.add_child(tengah)
	var panel: = PanelContainer.new()
	GH.pasang_emas(panel)
	tengah.add_child(panel)
	var isi: = VBoxContainer.new()
	isi.add_theme_constant_override("separation", 10)
	panel.add_child(isi)
	var judul: = Label.new()
	judul.theme_type_variation = &"LabelKepala"
	judul.add_theme_font_size_override("font_size", 34)
	judul.text = "Pilih penjaga warung"
	judul.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	isi.add_child(judul)
	var baris: = HBoxContainer.new()
	baris.add_theme_constant_override("separation", 28)
	baris.alignment = BoxContainer.ALIGNMENT_CENTER
	isi.add_child(baris)
	var nama_ibu: = ("Bu " + NAMA_IBU) if NAMA_IBU != "" else "Ibu"

	for p in [["bapak", "Pak Misran", "Season 1 · Level 1-10", true], ["ibu", nama_ibu, "Season 2 · Level 11-20", false]]:
		var kartu: = VBoxContainer.new()
		kartu.add_theme_constant_override("separation", 4)
		baris.add_child(kartu)
		var lv: = Label.new()
		lv.text = p[2]
		lv.theme_type_variation = &"LabelKepala"
		lv.add_theme_font_size_override("font_size", 24)
		lv.add_theme_color_override("font_color", GH.KUNING)
		lv.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		kartu.add_child(lv)
		var gambar: = _pratinjau_penjaga(GameState.FILE_MODEL_PENJAGA[p[0]])
		gambar.custom_minimum_size = Vector2(250, 270)

		var latar_kartu: = _kartu_latar(LATAR_PENJAGA[p[0]], gambar, p[3])
		kartu.add_child(latar_kartu)
		var nama: = Label.new()
		nama.text = p[1]
		nama.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
		nama.theme_type_variation = &"LabelKepala"
		nama.add_theme_font_size_override("font_size", 28)
		nama.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		kartu.add_child(nama)
		var t: = Button.new()
		t.custom_minimum_size = Vector2(250, 62)
		t.add_theme_font_size_override("font_size", 28)
		if p[3]:
			t.text = "Pilih"
			t.theme_type_variation = &"TombolHijau"
			t.pressed.connect( func():
				lapisan.queue_free()
				_mulai_dengan_mode(mode))
		else:
			t.text = "Segera Hadir"
			t.theme_type_variation = &"TombolKayu"
			t.disabled = true
			gambar.modulate = Color(0.45, 0.45, 0.45, 0.9)
			kartu.modulate.a = 0.85
		kartu.add_child(t)
	var batal: = Button.new()
	batal.text = "Kembali"
	batal.theme_type_variation = &"TombolKayu"
	batal.custom_minimum_size = Vector2(0, 60)
	batal.pressed.connect( func():
		lapisan.queue_free()
		_pilih_mode())
	isi.add_child(batal)




func _pilih_penjaga(mode: String) -> void :
	var pilihan: = {"penjaga": ""}
	var lapisan: = ColorRect.new()
	lapisan.color = Color(0.03, 0.02, 0.01, 0.6)
	lapisan.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(lapisan)
	var tengah: = CenterContainer.new()
	tengah.set_anchors_preset(Control.PRESET_FULL_RECT)
	lapisan.add_child(tengah)
	var panel: = PanelContainer.new()
	GH.pasang_emas(panel)
	tengah.add_child(panel)
	var isi: = VBoxContainer.new()
	isi.add_theme_constant_override("separation", 10)
	panel.add_child(isi)
	var judul: = Label.new()
	judul.theme_type_variation = &"LabelKepala"
	judul.add_theme_font_size_override("font_size", 34)
	judul.text = "Siapa penjaga warungnya?"
	judul.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	isi.add_child(judul)
	var baris: = HBoxContainer.new()
	baris.add_theme_constant_override("separation", 18)
	baris.alignment = BoxContainer.ALIGNMENT_CENTER
	isi.add_child(baris)
	var tombol: = {}
	var kolom: = LineEdit.new()
	var pesan: = Label.new()
	var mulai: = Button.new()
	var segarkan: = func():
		for id in tombol:
			(tombol[id] as Button).theme_type_variation = &"TombolHijau" if id == pilihan["penjaga"] else &"TombolKayu"
		var sapaan: = "Pak" if pilihan["penjaga"] == "bapak" else "Bu"
		var nama: = GameState.rapikan_nama_pemain(kolom.text)
		if pilihan["penjaga"] == "":
			pesan.text = "Pilih Bapak atau Ibu dulu."
		elif nama == "":
			pesan.text = "Tulis namamu, ya."
		else:
			pesan.text = "Warga akan memanggilmu: %s %s" % [sapaan, nama]
		mulai.disabled = pilihan["penjaga"] == "" or nama.length() < 2
	for p in [["bapak", "Bapak"], ["ibu", "Ibu"]]:
		var kartu: = VBoxContainer.new()
		kartu.add_theme_constant_override("separation", 6)
		baris.add_child(kartu)
		kartu.add_child(_pratinjau_penjaga(GameState.FILE_MODEL_PENJAGA[p[0]]))
		var t: = Button.new()
		t.text = p[1]
		t.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
		t.custom_minimum_size = Vector2(250, 62)
		t.add_theme_font_size_override("font_size", 30)
		var id: String = p[0]
		t.pressed.connect( func():
			pilihan["penjaga"] = id
			segarkan.call())
		kartu.add_child(t)
		tombol[id] = t
	var ket: = Label.new()
	ket.text = "Namamu (huruf saja, maks. %d):" % GameState.MAKS_NAMA_PEMAIN
	ket.add_theme_font_size_override("font_size", 20)
	ket.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	isi.add_child(ket)
	kolom.max_length = GameState.MAKS_NAMA_PEMAIN + 4
	kolom.placeholder_text = "contoh: Budi"
	kolom.alignment = HORIZONTAL_ALIGNMENT_CENTER
	kolom.custom_minimum_size = Vector2(0, 58)
	kolom.add_theme_font_size_override("font_size", 28)
	isi.add_child(kolom)

	kolom.text_changed.connect( func(t: String):
		var bersih: = ""
		for c in t:
			if c == " " or c.to_lower() != c.to_upper():
				bersih += c
		if bersih != t:
			var k: = kolom.caret_column
			kolom.text = bersih
			kolom.caret_column = mini(k, bersih.length())
		segarkan.call())
	pesan.add_theme_font_size_override("font_size", 20)
	pesan.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pesan.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	isi.add_child(pesan)
	var bawah: = HBoxContainer.new()
	bawah.add_theme_constant_override("separation", 16)
	isi.add_child(bawah)
	var batal: = Button.new()
	batal.text = "Kembali"
	batal.theme_type_variation = &"TombolKayu"
	batal.custom_minimum_size = Vector2(0, 62)
	batal.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	batal.pressed.connect( func():
		lapisan.queue_free()
		_pilih_mode())
	bawah.add_child(batal)
	mulai.text = "MULAI"
	mulai.theme_type_variation = &"TombolHijau"
	mulai.custom_minimum_size = Vector2(0, 62)
	mulai.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mulai.add_theme_font_size_override("font_size", 28)
	mulai.pressed.connect( func():
		var nama: = GameState.rapikan_nama_pemain(kolom.text)
		if not GameState.papan.nama_pantas(nama):
			pesan.text = "Nama ini kurang pantas. Coba nama lain, ya."
			return
		_mulai_dengan_mode(mode, pilihan["penjaga"], nama))
	bawah.add_child(mulai)
	kolom.text_submitted.connect( func(_t): if not mulai.disabled: mulai.pressed.emit())
	segarkan.call()



const LATAR_PENJAGA: = {"bapak": "res://assets/latar/latar_warung_penuh.png", "ibu": "res://assets/peta/area_pasar.png"}



func _kartu_latar(berkas: String, tokoh: Control, bisa: bool) -> Control:
	var bingkai: = Panel.new()
	bingkai.custom_minimum_size = tokoh.custom_minimum_size
	bingkai.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bingkai.clip_children = CanvasItem.CLIP_CHILDREN_AND_DRAW
	var sb: = StyleBoxFlat.new()
	sb.bg_color = Color(0.1, 0.07, 0.05)
	sb.set_corner_radius_all(20)
	bingkai.add_theme_stylebox_override("panel", sb)
	if ResourceLoader.exists(berkas):
		var latar: = TextureRect.new()
		latar.texture = load(berkas)
		latar.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		latar.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		latar.set_anchors_preset(Control.PRESET_FULL_RECT)
		latar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		latar.modulate = Color(0.85, 0.82, 0.8) if bisa else Color(0.45, 0.45, 0.48)
		bingkai.add_child(latar)

	var sorot: = TextureRect.new()
	var gr: = Gradient.new()
	gr.set_color(0, Color(1.0, 0.85, 0.55, 0.35) if bisa else Color(0.7, 0.7, 0.75, 0.15))
	gr.set_color(1, Color(0.05, 0.03, 0.02, 0.75))
	gr.add_point(0.55, Color(0.2, 0.12, 0.06, 0.25))
	var tg: = GradientTexture2D.new()
	tg.gradient = gr
	tg.fill = GradientTexture2D.FILL_RADIAL
	tg.fill_from = Vector2(0.5, 0.45)
	tg.fill_to = Vector2(1.05, 1.0)
	tg.width = 256
	tg.height = 256
	sorot.texture = tg
	sorot.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sorot.set_anchors_preset(Control.PRESET_FULL_RECT)
	sorot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bingkai.add_child(sorot)

	var lantai: = Control.new()
	lantai.set_anchors_preset(Control.PRESET_FULL_RECT)
	lantai.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lantai.draw.connect( func():
		var c: = Vector2(lantai.size.x / 2.0, lantai.size.y * 0.9)
		for i in 4:
			lantai.draw_set_transform(c, 0.0, Vector2(1.0, 0.28))
			lantai.draw_circle(Vector2.ZERO, 70.0 - i * 14.0, Color(0, 0, 0, 0.16))
		lantai.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE))
	bingkai.add_child(lantai)
	tokoh.set_anchors_preset(Control.PRESET_FULL_RECT)
	bingkai.add_child(tokoh)

	var garis: = Panel.new()
	garis.set_anchors_preset(Control.PRESET_FULL_RECT)
	garis.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sg: = StyleBoxFlat.new()
	sg.draw_center = false
	sg.set_corner_radius_all(20)
	sg.set_border_width_all(3)
	sg.border_color = Color(1.0, 0.8, 0.35, 0.95) if bisa else Color(0.6, 0.6, 0.6, 0.7)
	garis.add_theme_stylebox_override("panel", sg)
	bingkai.add_child(garis)
	return bingkai


func _pratinjau_penjaga(file: String) -> SubViewportContainer:
	var wadah: = SubViewportContainer.new()
	wadah.custom_minimum_size = Vector2(250, 300)
	wadah.stretch = true
	wadah.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var vp: = SubViewport.new()
	vp.transparent_bg = true
	vp.own_world_3d = true
	vp.msaa_3d = GameState.msaa_3d()
	wadah.add_child(vp)
	var lingkungan: = Environment.new()
	lingkungan.background_mode = Environment.BG_CLEAR_COLOR
	lingkungan.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	lingkungan.ambient_light_color = Color(1.0, 0.88, 0.75)
	lingkungan.ambient_light_energy = 0.6
	lingkungan.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	var dunia: = WorldEnvironment.new()
	dunia.environment = lingkungan
	vp.add_child(dunia)
	var lampu: = DirectionalLight3D.new()
	lampu.light_color = Color(1.0, 0.88, 0.7)
	lampu.light_energy = 1.3
	lampu.rotation = Vector3(deg_to_rad(-25), deg_to_rad(30), 0)
	vp.add_child(lampu)
	var putar: = Node3D.new()
	vp.add_child(putar)
	var model: Node3D = GameState.muat_model("res://assets/karakter3d/" + file)
	putar.add_child(model)
	var tinggi: = 0.0
	for mi: MeshInstance3D in GameState.cari_anak(model, "MeshInstance3D"):
		tinggi = maxf(tinggi, (mi.global_transform * mi.get_aabb()).size.y)
	if tinggi > 0.0:
		var sk: = 1.72 / tinggi
		model.scale = Vector3(sk, sk, sk)
	var semua: = GameState.cari_anak(model, "AnimationPlayer")
	if not semua.is_empty():
		var ap: AnimationPlayer = semua[0]
		GameState.siapkan_animasi_penjaga(ap)
		if ap.has_animation("Idle_11"):
			ap.get_animation("Idle_11").loop_mode = Animation.LOOP_LINEAR
			ap.play("Idle_11")
	var kamera: = Camera3D.new()
	kamera.fov = 30.0
	kamera.position = Vector3(0, 0.95, 3.9)
	vp.add_child(kamera)
	kamera.look_at(Vector3(0, 0.88, 0))
	kamera.current = true
	var tw: = putar.create_tween().set_loops()
	tw.tween_property(putar, "rotation:y", deg_to_rad(25), 2.5).set_trans(Tween.TRANS_SINE)
	tw.tween_property(putar, "rotation:y", deg_to_rad(-25), 2.5).set_trans(Tween.TRANS_SINE)
	return wadah




func _jendela_coba_minigame() -> void :
	var lapisan: = ColorRect.new()
	lapisan.color = Color(0.03, 0.02, 0.01, 0.6)
	lapisan.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(lapisan)
	var tengah: = CenterContainer.new()
	tengah.set_anchors_preset(Control.PRESET_FULL_RECT)
	lapisan.add_child(tengah)
	var panel: = PanelContainer.new()
	GH.pasang_emas(panel)
	tengah.add_child(panel)
	var isi: = VBoxContainer.new()
	isi.add_theme_constant_override("separation", 10)
	panel.add_child(isi)
	var judul: = Label.new()
	judul.theme_type_variation = &"LabelKepala"
	judul.add_theme_font_size_override("font_size", 34)
	judul.text = "Coba mini-game"
	judul.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	isi.add_child(judul)
	var hasil: = Label.new()
	hasil.add_theme_font_size_override("font_size", 20)
	hasil.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	isi.add_child(hasil)
	var penjaga_asal: = GameState.penjaga
	var grid: = GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 8)
	isi.add_child(grid)
	for p in [["bapak", "Bapak"], ["ibu", "Ibu"]]:
		var kolom: = VBoxContainer.new()
		kolom.add_theme_constant_override("separation", 6)
		grid.add_child(kolom)
		var kepala: = Label.new()
		kepala.text = "Versi " + p[1]
		kepala.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
		kepala.add_theme_font_size_override("font_size", 22)
		kepala.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		kolom.add_child(kepala)
		for id in GameState.KERJA_SAMPINGAN:
			GameState.penjaga = p[0]
			var berkas: Array = GameState.minigame_kerja(id)
			var b: = Button.new()
			b.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
			b.text = "%s  (%s)" % [id.capitalize(), String(berkas[0]).get_file().trim_suffix(".gd").trim_prefix("mg_") + ("/" + berkas[1] if berkas[1] != "" else "")]
			b.theme_type_variation = &"TombolKayu"
			b.custom_minimum_size = Vector2(360, 46)
			b.add_theme_font_size_override("font_size", 18)
			var penjaga: String = p[0]
			b.pressed.connect( func():
				GameState.penjaga = penjaga
				var m: Array = GameState.minigame_kerja(id)
				var mg: Control = load(m[0]).new()
				mg.atur(m[1], id)
				add_child(mg)
				var h: float = await mg.selesai
				hasil.text = "%s (%s): hasil %d%%, upah %d%%" % [id.capitalize(), penjaga, int(round(h * 100)), int(round(GameState.pengali_hasil_kerja(h) * 100))]
				GameState.penjaga = penjaga_asal)
			kolom.add_child(b)
	GameState.penjaga = penjaga_asal

	grid.columns = 3
	var kolom_tip: = VBoxContainer.new()
	kolom_tip.add_theme_constant_override("separation", 6)
	grid.add_child(kolom_tip)
	var kepala_tip: = Label.new()
	kepala_tip.text = "Tips berjualan"
	kepala_tip.add_theme_font_size_override("font_size", 22)
	kepala_tip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	kolom_tip.add_child(kepala_tip)
	var contoh_warga: = {"kembalian": "ibu_rumah_tangga", "bungkus": "siswi", "langganan": "petani", "qris": "kantoran"}
	for id in GameState.MINIGAME_TIP.keys() + ["qris"]:
		var b: = Button.new()
		b.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
		b.text = String(id).capitalize()
		b.theme_type_variation = &"TombolHijau"
		b.custom_minimum_size = Vector2(260, 46)
		b.add_theme_font_size_override("font_size", 18)
		b.pressed.connect( func():
			var d: Dictionary = GameState.MINIGAME_QRIS if id == "qris" else GameState.MINIGAME_TIP[id]
			var mg: Control = load(String(d["file"])).new()
			mg.npc = String(contoh_warga[id])
			mg.tip_maks = int(d["tip"])
			mg.latar = "res://assets/latar/latar_warung_kosong.png"
			add_child(mg)
			var h: float = await mg.selesai
			hasil.text = "%s: hasil %d%%, tip %s" % [String(id).capitalize(), int(round(h * 100)), GameState.format_rupiah(GameState.tip_minigame(int(d["tip"]), h))])
		kolom_tip.add_child(b)
	var tutup: = Button.new()
	tutup.text = "Kembali"
	tutup.theme_type_variation = &"TombolKayu"
	tutup.custom_minimum_size = Vector2(0, 56)
	tutup.pressed.connect( func():
		GameState.penjaga = penjaga_asal
		lapisan.queue_free())
	isi.add_child(tutup)
