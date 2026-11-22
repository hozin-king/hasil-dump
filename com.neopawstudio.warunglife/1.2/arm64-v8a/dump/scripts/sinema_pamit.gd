extends Node















signal selesai

const SCRIPT_PELANGGAN: = preload("res://scripts/pelanggan.gd")
const KARDUS: = "res://assets/upgrade/kardus_bawa.glb"
const SUARA_MEONG: = "res://assets/suara/neo_meong_2.ogg"


const LATAR_WARUNG_KOSONG: = "res://assets/latar/latar_lowpoly_kosong.png"

const CFG_MISRAN: = {"file": "meshy_bapak.glb", "skala": 1.0, "anim_jalan": "Walking", "anim_diam": "Idle_11", 
	"anim_bicara": "Talk_with_Right_Hand_Open"}
const CFG_ENI: = {"file": "meshy_ibu_penjaga.glb", "skala": 0.94, "anim_jalan": "Walking", "anim_diam": "Idle_11", 
	"anim_bicara": "Talk_with_Right_Hand_Open"}


const WARNA_NAMA: = {"Pak Misran": Color(1.0, 0.82, 0.45), "Agus": Color(0.6, 0.85, 1.0), "Bu Eni": Color(1.0, 0.68, 0.72), 
	"Raka": Color(0.65, 0.95, 0.7)}
const HURUF_PER_DETIK: = 36.0
const JEDA_BACA: = 1.35
const TINGGI_KOTAK: = 170.0

var j: Node
var lapisan: CanvasLayer
var _bar: Array[ColorRect] = []
var _hitam: ColorRect
var _judul: Label
var _sub_judul: Label
var _kotak: PanelContainer
var _nama: Label
var _teks: Label
var _ikuti: Node2D = null
var _angkat_kamera: = 0.0
var aktor: = {}

var _neo_lihat: Array = []
var _titik_lihat_neo: = Vector2.ZERO
var _jeda_langkah: = 0.0
const SELANG_LANGKAH: = 0.6



var gaya_pamit: = "peluk"

var boleh_lewati: = false
var _sudah_selesai: = false




func mainkan(jelajah: Node) -> void :
	j = jelajah
	j.sinema_khusus = true
	j.sibuk = true
	j.ui.visible = false
	_bangun_lapisan()
	GameState.putar_musik("pamit", 1.5)
	await _layar_judul("Tiga tahun kemudian...", "", 2.6)
	await _adegan_rumah()
	await _adegan_warung()
	await _layar_judul("Warung Bu Eni", "Level 11", 4.0, true)
	_akhiri()


func _akhiri() -> void :
	if _sudah_selesai:
		return
	_sudah_selesai = true
	selesai.emit()


func _lewati() -> void :
	if _sudah_selesai:
		return
	var tw: = create_tween().set_parallel(true)
	tw.tween_property(_hitam, "modulate:a", 1.0, 0.6)
	if GameState._musik != null:
		tw.tween_property(GameState._musik, "volume_db", -60.0, 0.6)
	await tw.finished
	_akhiri()


func _process(delta: float) -> void :
	if _ikuti != null and is_instance_valid(_ikuti) and j != null:
		j.kamera.position = _ikuti.position - Vector2(0, _angkat_kamera)
	_perbarui_neo()

	var misran: Sprite2D = aktor.get("misran")
	if misran != null and is_instance_valid(misran) and misran.sedang_jalan and misran.modulate.a > 0.5:
		_jeda_langkah -= delta
		if _jeda_langkah <= 0.0:
			_jeda_langkah = SELANG_LANGKAH
			GameState.langkah_kaki()
	else:
		_jeda_langkah = 0.1


func _perbarui_neo() -> void :
	var neo: Sprite2D = aktor.get("neo")
	if neo == null or not is_instance_valid(neo):
		return
	var jumlah: = 0
	var pusat: = Vector2.ZERO
	for o in _neo_lihat:
		if is_instance_valid(o) and (o as CanvasItem).visible and (o as CanvasItem).modulate.a > 0.1:
			pusat += (o as Node2D).position
			jumlah += 1
	if jumlah > 0:
		_titik_lihat_neo = pusat / jumlah
	if _titik_lihat_neo != Vector2.ZERO:
		neo.hadap(_titik_lihat_neo - neo.position)




func _adegan_rumah() -> void :
	await _ganti_area("rumah", "rumah_misran")
	var misran: = _aktor_cfg("misran", CFG_MISRAN, Vector2(694, 506))
	var agus: = _aktor_tipe("agus", "agus", Vector2(770, 560))
	misran.hadap(Vector2(0.2, 1))
	agus.hadap(Vector2(-0.6, -0.4))
	if agus.karakter != null:
		agus.karakter.bawa_barang(KARDUS)
	_kamera_ke(Vector2(720, 470), 1.35, 0.0)
	await _terang(1.6)
	await _baris("", "Pagi itu, Pak Misran menutup pintu rumahnya untuk terakhir kalinya.")
	misran.hadap(Vector2(-0.3, -1))
	await _tunggu(1.0)
	await _baris("Pak Misran", "Rumah ini Bapak titip ya, Gus. Jendelanya dibuka tiap pagi, biar tidak lembap.", misran)
	misran.hadap(agus.position - misran.position)
	await _baris("Agus", "Iya, Pak. Aku rawat baik-baik. Kan aku yang tinggal di sini sekarang.", agus)
	await _baris("Pak Misran", "Guru TIK SD kampung... Bapak masih tidak percaya, Gus.", misran)
	await _baris("Agus", "Ayo, Pak. Bu Eni sudah menunggu di warung.", agus)

	_ikuti = misran
	_angkat_kamera = 40.0

	misran.jalan([Vector2(800, 583), Vector2(1200, 748), Vector2(1420, 905)], _kec(0.82))
	await _tunggu(0.5)
	agus.jalan([Vector2(800, 650), Vector2(1180, 812), Vector2(1400, 960)], _kec(0.82))
	await _tunggu(4.5)
	await _gelap(1.2)
	_ikuti = null
	_hapus_aktor()




func _adegan_warung() -> void :
	j.latar_paksa = {"gambar": LATAR_WARUNG_KOSONG}
	await _ganti_area("warung", "depan_warung")
	var eni: = _aktor_cfg("eni", CFG_ENI, Vector2(948, 784))
	var raka: = _aktor_tipe("raka", "pelajar_smp" if j.data_pelanggan.has("pelajar_smp") else "pelajar", Vector2(1010, 822))
	var neo: = _aktor_tipe("neo", "kucing", Vector2(884, 750))
	var nenek: = _aktor_tipe("nenek", "nenek", Vector2(1178, 916))
	var asep: = _aktor_tipe("asep", "ojek", Vector2(1118, 878))
	for o in [eni, raka, nenek, asep]:
		o.hadap(Vector2(-1, -0.45))
		if o.karakter != null:
			o.karakter.hidup = true
	neo.arah_manual = true
	if neo.karakter != null and neo.karakter._gerak_kucing != null:
		neo.karakter._gerak_kucing.tua = true
	var misran: = _aktor_cfg("misran", CFG_MISRAN, Vector2(230, 475))
	var agus: = _aktor_tipe("agus", "agus", Vector2(130, 470))
	if agus.karakter != null:
		agus.karakter.bawa_barang(KARDUS)
	_neo_lihat = [misran, agus]
	_kamera_ke(Vector2(860, 650), 1.2, 0.0)
	await _terang(1.2)
	await _tunggu(0.4)

	misran.jalan([Vector2(300, 505), Vector2(600, 630), Vector2(806, 712)], _kec(0.85))
	agus.jalan([Vector2(250, 535), Vector2(540, 660), Vector2(722, 734)], _kec(0.85))
	await _kamera_ke(Vector2(800, 660), 1.25, 5.5)
	await _sampai(misran, 16.0)
	agus.hadap(misran.position - agus.position)

	misran.hadap(Vector2(0.35, -1))
	await _baris("", "Pak Misran berhenti di depan warung. Lama ia memandangi rak-rak yang sudah kosong, yang ia jaga bertahun-tahun.")
	await _baris("Pak Misran", "Dulu Bapak mulai dari satu rak mi instan... sekarang giliran Bu Eni yang mengisi lagi.", misran)

	await _kamera_ke(Vector2(880, 690), 1.45, 1.8)
	misran.hadap(eni.position - misran.position)
	eni.hadap(misran.position - eni.position)
	raka.hadap(misran.position - raka.position)
	await _baris("Pak Misran", "Bu Eni, saya titip warung ini, ya. Sewanya bayar seikhlasnya dulu. Yang penting warung tetap buka.", misran)
	await _baris("Bu Eni", "Insya Allah saya jaga baik-baik, Pak. Kang Dedi titip salam, masih istirahat di rumah.", eni)
	await _baris("Pak Misran", "Bilang sama Dedi, cepat sehat. Nanti kita ngopi lagi di bangku itu.", misran)
	await _baris("Raka", "Pak Misran, nanti Raka yang jaga kasir!", raka)
	misran.hadap(raka.position - misran.position)
	await _baris("Pak Misran", "Wah, kasir baru. Kembaliannya jangan salah, ya.", misran)

	misran.jalan([Vector2(850, 738)], _kec(0.75))
	await _sampai(misran, 8.0)
	misran.hadap(neo.position - misran.position)
	_neo_lihat = [misran]
	if misran.karakter != null:
		misran.karakter.atur_bungkuk(32.0)
	await _kamera_ke(Vector2(868, 700), 1.7, 1.6)
	await _baris("", "Neo sudah tua. Ia tidak lagi berlari menyambut, hanya menoleh pelan.")
	_meong(neo)
	await _baris("Pak Misran", "Neo... Bapak pergi dulu, ya. Jaga warung sama Bu Eni.", misran)
	_neo_lihat = [misran, agus]
	if misran.karakter != null:
		misran.karakter.atur_bungkuk(0.0)
	await _tunggu(0.8)

	agus.jalan([Vector2(748, 774)], _kec(0.82))
	await _kamera_ke(Vector2(830, 690), 1.5, 1.4)
	await _sampai(agus, 8.0)
	agus.hadap(misran.position - agus.position)
	misran.hadap(agus.position - misran.position)
	await _baris("Agus", "Pak... jangan lupa kontrol ke dokter. Nanti aku telepon tiap malam.", agus)
	await _baris("Pak Misran", "Kamu juga, Gus. Ngajar yang sabar. Anak-anak kampung ini butuh guru kayak kamu.", misran)
	if agus.karakter != null:
		agus.karakter.lepas_barang()

	await _tunggu(0.6)
	for o in [agus, misran]:
		if o.karakter != null:
			o.karakter.batalkan_aksi()
	if gaya_pamit == "salim":
		await _pamit_salim(agus, misran)
	else:
		await _pamit_peluk(agus, misran)
	agus.jalan([misran.position + Vector2(-72, -14)], _kec(0.5))
	await _sampai(agus, 3.0)
	if misran.karakter != null:
		misran.karakter.bawa_barang(KARDUS)

	j._adegan_angkot = true
	var k = j._angkot_baru()
	var titik_naik: = Vector2(872, 806)
	var henti: = 0.0
	if k != null:
		henti = minf(j._titik_terdekat_lajur(k.lajur, titik_naik).x, k.panjang_lajur())
		j._suara_angkot(k, "mobil_datang", 14.5 - j.DETIK_ANGKOT_DATANG)
		await _kamera_ke(Vector2(860, 760), 1.3, 1.6)
		_neo_lihat = [k]
		await j._angkot_jalan(k, 0.0, henti, j.DETIK_ANGKOT_DATANG, true)
	for o in [eni, raka, agus, nenek, asep]:
		o.hadap(misran.position - o.position)
	misran.hadap(Vector2(-0.6, -0.5))
	await _baris("Pak Misran", "Angkotnya sudah datang. Assalamualaikum, semuanya.", misran)
	await _baris("Bu Eni", "Waalaikumsalam, Pak. Hati-hati di jalan.", eni)

	misran.jalan([titik_naik], _kec(0.78))
	await _sampai(misran, 8.0)
	var naik: = misran.create_tween()
	naik.tween_property(misran, "modulate:a", 0.0, 0.5)
	await _tunggu(0.9)
	_baris_lepas("", "Angkot itu membawa Pak Misran ke terminal, lalu ke kota.")
	if k != null:
		j._angkot_pergi(k, henti)
	for o in [eni, raka, agus]:
		o.hadap(Vector2(1, 0.5))
	await _tunggu(3.4)
	await _sembunyikan_teks()

	await _kamera_ke(Vector2(884, 690), 1.55, 2.6)
	await _tunggu(1.0)
	await _baris("", "Di depan warung, Neo masih menoleh ke arah jalan, seolah menunggu angkot itu kembali.")
	await _kamera_ke(Vector2(860, 560), 1.05, 3.0)
	await _gelap(1.6)
	j._adegan_angkot = false
	j.latar_paksa = {}
	_hapus_aktor()






func _pamit_peluk(agus: Sprite2D, misran: Sprite2D) -> void :


	var titik_peluk: = misran.position + Vector2(-14, 24)
	agus.jalan([titik_peluk], _kec(0.6))
	await _sampai(agus, 4.0)
	agus.hadap(misran.position - agus.position)
	misran.hadap(agus.position - misran.position)
	await _kamera_ke(misran.position + Vector2(-10, -95), 1.85, 1.2)
	if gaya_pamit == "gelap":
		_kotak.move_to_front()
		create_tween().tween_property(_hitam, "modulate:a", 0.82, 1.4)
	for o in [agus, misran]:
		if o.karakter != null:
			o.karakter.atur_peluk(1.0, 1.1)
	await _baris("", "Agus memeluk bapaknya erat-erat. Tidak ada yang bicara untuk beberapa saat.")
	await _tunggu(1.2)
	for o in [agus, misran]:
		if o.karakter != null:
			o.karakter.atur_peluk(0.0, 0.8)
	if gaya_pamit == "gelap":
		create_tween().tween_property(_hitam, "modulate:a", 0.0, 1.2)
	await _tunggu(0.9)


func _pamit_salim(agus: Sprite2D, misran: Sprite2D) -> void :

	var px_per_m: float = float(j.area["tinggi_dewasa"]) / SCRIPT_PELANGGAN.TINGGI_DEWASA_METER
	var titik: = misran.position + Vector2(-0.62, 0.06) * px_per_m
	agus.jalan([titik], _kec(0.6))
	await _sampai(agus, 4.0)
	agus.hadap(Vector2(1, 0))
	misran.hadap(Vector2(-1, 0))
	await _kamera_ke((misran.position + agus.position) / 2.0 + Vector2(0, -80), 1.85, 1.2)
	if misran.karakter != null:
		misran.karakter.atur_salim(1.0, false, 0.8)
	await _tunggu(0.5)
	if agus.karakter != null:
		agus.karakter.atur_salim(1.0, true, 0.9)
		agus.karakter.atur_bungkuk(26.0)
	await _baris("", "Agus mencium tangan bapaknya lama sekali, seperti waktu kecil dulu setiap berangkat sekolah.")
	if agus.karakter != null:
		agus.karakter.atur_salim(0.0, true, 0.7)
		agus.karakter.atur_bungkuk(0.0)
	if misran.karakter != null:
		misran.karakter.atur_salim(0.0, false, 0.7)
	await _tunggu(0.6)
	await _baris("Pak Misran", "Sudah, sudah... nanti Bapak ikut nangis.", misran)
	await _tunggu(0.4)




func _aktor_cfg(nama: String, cfg: Dictionary, posisi: Vector2) -> Sprite2D:
	var o: = Sprite2D.new()
	o.set_script(SCRIPT_PELANGGAN)
	o.tinggi_dewasa_latar = float(j.area["tinggi_dewasa"])
	j.wadah.add_child(o)
	o.atur_3d(cfg, 0.0)
	o.y_berdiri = j.latar.texture.get_size().y * 0.55
	o.perspektif = j.area.get("perspektif", [])
	o.position = posisi
	aktor[nama] = o
	return o


func _aktor_tipe(nama: String, tipe: String, posisi: Vector2) -> Sprite2D:
	var o: Sprite2D = j._buat_orang(tipe)
	j.warga.erase(o)
	o.position = posisi
	aktor[nama] = o
	return o


func _hapus_aktor() -> void :
	for n in aktor:
		if is_instance_valid(aktor[n]):
			aktor[n].queue_free()
	aktor.clear()


func _kec(meter_per_detik: float) -> float:
	return meter_per_detik * float(j.area["tinggi_dewasa"]) / SCRIPT_PELANGGAN.TINGGI_DEWASA_METER



func _sampai(o: Sprite2D, maks: float) -> void :
	var t: = 0.0
	while is_instance_valid(o) and o.sedang_jalan and t < maks:
		await get_tree().process_frame
		t += get_process_delta_time()


func _meong(neo: Node) -> void :
	if not ResourceLoader.exists(SUARA_MEONG):
		return
	var p: = AudioStreamPlayer.new()
	p.stream = load(SUARA_MEONG)
	p.bus = "Suara"
	p.volume_db = -4.0
	neo.add_child(p)
	p.play()




func _ganti_area(id: String, muncul: String) -> void :
	await j._masuk_area(id, muncul, false)
	j.sibuk = true
	j._bersihkan_warga()
	for k in j.lalu_lintas.get_children():
		k.queue_free()
	if j.neo != null and is_instance_valid(j.neo):
		j.neo.queue_free()
	j.neo = null

	j.bapak.visible = false
	j.bapak.position = Vector2(-5000, -5000)

	for anak in j.dunia.get_children() + j.wadah.get_children():
		for m in ["portal", "label_area", "penanda_alam", "penanda_angkot"] + (["upgrade"] if not j.latar_paksa.is_empty() else []):
			if anak.has_meta(m):
				anak.hide()


func _kamera_ke(pusat: Vector2, zoom_kali: float, detik: float) -> void :
	var zoom_dasar: = _zoom_dasar()
	if detik <= 0.0:
		j.kamera.position = pusat
		j.kamera.zoom = zoom_dasar * zoom_kali
		j.kamera.reset_smoothing()
		return
	var tw: = create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(j.kamera, "position", pusat, detik)
	tw.tween_property(j.kamera, "zoom", zoom_dasar * zoom_kali, detik)
	await tw.finished


func _zoom_dasar() -> Vector2:
	var lebar: = float(j.area.get("lebar_pandangan", 1300.0))
	var layar: Vector2 = j.get_viewport().get_visible_rect().size
	var z: = layar.x / lebar
	if j.latar.texture != null:
		var ukuran: Vector2 = j.latar.texture.get_size()
		z = maxf(z, maxf(layar.x / ukuran.x, layar.y / ukuran.y))
	return Vector2(z, z)




func _bangun_lapisan() -> void :
	lapisan = CanvasLayer.new()
	lapisan.layer = 50
	add_child(lapisan)
	var akar: = Control.new()
	akar.theme = j.TEMA
	akar.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	akar.mouse_filter = Control.MOUSE_FILTER_STOP
	lapisan.add_child(akar)
	var h: = j.get_viewport().get_visible_rect().size.y * 0.11
	for i in 2:
		var bar: = ColorRect.new()
		bar.color = Color.BLACK
		bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bar.set_anchors_preset(Control.PRESET_TOP_WIDE if i == 0 else Control.PRESET_BOTTOM_WIDE)
		if i == 0:
			bar.offset_bottom = h
		else:
			bar.offset_top = - h
		akar.add_child(bar)
		_bar.append(bar)

	_kotak = PanelContainer.new()
	var gaya: = StyleBoxFlat.new()
	gaya.bg_color = Color(0.05, 0.035, 0.02, 0.72)
	gaya.set_corner_radius_all(18)
	gaya.content_margin_left = 30
	gaya.content_margin_right = 30
	gaya.content_margin_top = 14
	gaya.content_margin_bottom = 16
	_kotak.add_theme_stylebox_override("panel", gaya)
	_kotak.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_kotak.anchor_left = 0.14
	_kotak.anchor_right = 0.86
	_kotak.anchor_top = 1.0
	_kotak.anchor_bottom = 1.0
	_kotak.offset_bottom = - h - 14
	_kotak.offset_top = - h - 14 - TINGGI_KOTAK
	_kotak.modulate.a = 0.0
	akar.add_child(_kotak)
	var isi: = VBoxContainer.new()
	isi.add_theme_constant_override("separation", 4)
	_kotak.add_child(isi)
	_nama = Label.new()
	_nama.add_theme_font_size_override("font_size", 26)
	isi.add_child(_nama)
	_teks = Label.new()
	_teks.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_teks.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_teks.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	_teks.add_theme_font_size_override("font_size", 28)
	isi.add_child(_teks)

	_hitam = ColorRect.new()
	_hitam.color = Color.BLACK
	_hitam.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_hitam.mouse_filter = Control.MOUSE_FILTER_IGNORE
	akar.add_child(_hitam)
	_judul = Label.new()
	_judul.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_judul.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_judul.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_judul.add_theme_font_size_override("font_size", 52)
	_judul.add_theme_color_override("font_color", Color(1, 0.97, 0.9))
	_judul.modulate.a = 0.0
	akar.add_child(_judul)
	_sub_judul = Label.new()
	_sub_judul.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_sub_judul.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_sub_judul.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_sub_judul.offset_top = 90
	_sub_judul.add_theme_font_size_override("font_size", 30)
	_sub_judul.add_theme_color_override("font_color", Color(1, 0.85, 0.55))
	_sub_judul.modulate.a = 0.0
	akar.add_child(_sub_judul)

	if boleh_lewati:
		var lewat: = Button.new()
		lewat.text = "Lewati ▸"
		lewat.flat = true
		lewat.focus_mode = Control.FOCUS_NONE
		lewat.add_theme_font_size_override("font_size", 26)
		lewat.add_theme_color_override("font_color", Color(1, 1, 1, 0.75))
		lewat.set_anchors_preset(Control.PRESET_TOP_RIGHT)
		lewat.offset_left = -190
		lewat.offset_right = -24
		lewat.offset_top = maxf(h * 0.5 - 26, 4)
		lewat.offset_bottom = lewat.offset_top + 52
		lewat.pressed.connect(_lewati)
		akar.add_child(lewat)


func _layar_judul(teks: String, sub: String, lama: float, musik_pudar: = false) -> void :
	if _hitam.modulate.a < 0.99:
		await _gelap(1.0)
	_judul.text = teks
	_sub_judul.text = sub
	var tw: = create_tween().set_parallel(true)
	tw.tween_property(_judul, "modulate:a", 1.0, 1.2)
	if sub != "":
		tw.tween_property(_sub_judul, "modulate:a", 1.0, 1.2).set_delay(0.8)
	if musik_pudar and GameState._musik != null:
		create_tween().tween_property(GameState._musik, "volume_db", -60.0, lama + 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	await _tunggu(lama)
	var tw2: = create_tween().set_parallel(true)
	tw2.tween_property(_judul, "modulate:a", 0.0, 1.0)
	tw2.tween_property(_sub_judul, "modulate:a", 0.0, 1.0)
	await tw2.finished


func _gelap(detik: float) -> void :
	var tw: = create_tween()
	tw.tween_property(_hitam, "modulate:a", 1.0, detik)
	create_tween().tween_property(_kotak, "modulate:a", 0.0, minf(detik, 0.5))
	await tw.finished


func _terang(detik: float) -> void :
	var tw: = create_tween()
	tw.tween_property(_hitam, "modulate:a", 0.0, detik)
	await tw.finished



func _baris(siapa: String, teks: String, tokoh: Sprite2D = null) -> void :
	_baris_lepas(siapa, teks, tokoh)
	await _tunggu(teks.length() / HURUF_PER_DETIK + JEDA_BACA + teks.length() * 0.012)


func _baris_lepas(siapa: String, teks: String, tokoh: Sprite2D = null) -> void :
	_nama.visible = siapa != ""
	_nama.text = siapa
	_nama.add_theme_color_override("font_color", WARNA_NAMA.get(siapa, Color.WHITE))
	_teks.text = teks
	_teks.add_theme_color_override("font_color", Color(1, 1, 1, 0.8) if siapa == "" else Color.WHITE)
	_teks.visible_ratio = 0.0
	if _kotak.modulate.a < 1.0:
		create_tween().tween_property(_kotak, "modulate:a", 1.0, 0.35)
	create_tween().tween_property(_teks, "visible_ratio", 1.0, teks.length() / HURUF_PER_DETIK)

	if tokoh != null and is_instance_valid(tokoh) and tokoh != aktor.get("agus"):
		tokoh.aksi("bicara")


func _sembunyikan_teks() -> void :
	var tw: = create_tween()
	tw.tween_property(_kotak, "modulate:a", 0.0, 0.5)
	await tw.finished


func _tunggu(detik: float) -> void :
	await GameState.get_tree().create_timer(detik).timeout
