extends "res://scripts/minigame/mg_dasar.gd"















const TITIK_JORAN: = Vector2(250, 120)
const PANGKAL_JORAN: = Vector2(40, 470)
const Y_AIR: = 150.0

var _tahap: = "siap"
var _waktu: = 0.0
var _kuat: = 0.0
var _kuat_naik: = true
var _pelampung: = Vector2(600, 300)
var _asal_lempar: = TITIK_JORAN
var _tunggu: = 3.0
var _getar: = []
var _getar_sisa: = 0.0
var _jenis: = ""
var _jendela: = 0.6
var _ikan_terbang: = []
var _riak: = []
var _pesan: = ""
var _pesan_warna: = Color.WHITE
var _bayang: = Vector2.ZERO
var _sentak: = 0.0
var lemparan: = 0
var _label_energi: Label
var _label_jam: Label
var _label_lama: Label
var _kotak_jam: Control
var _tombol_selesai: Button


func _siapkan() -> void :
	cahaya_25d = {"dari": Vector2(900, -40), "warna": Color(1, 0.95, 0.75), "kuat": 0.7}
	judul = "Memancing di sungai"
	petunjuk = "Klik untuk melempar kail (energi -3%). Tunggu sampai ikan MENYAMBAR umpan (tanda !), lalu cepat klik! Terlalu cepat atau telat, ikannya lepas. Ada ikan legendaris yang sangat langka!"
	target = 5.0
	latar = "res://assets/peta/area_sawah.png"
	contoh = {"jenis": "ketuk", "dari": Vector2(640, 280), "ke": Vector2(640, 280), "teks": "Klik saat ikan menyambar"}
	_pelampung = Vector2(640, 280)


func _energi_lempar() -> float:
	return float(GameState.aturan_hasil_alam("energi_per_lempar", 3))



func _mulai() -> void :
	sisa = 1000000000.0
	main = true
	_sudah_mulai = true
	var baris: = _bar.get_parent()
	baris.get_child(0).hide()
	_label_energi = GH.label("", 18, Color.WHITE, true)
	baris.add_child(_label_energi)
	baris.move_child(_label_energi, 0)
	_bar.max_value = 100.0

	_bar.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_bar.custom_minimum_size = Vector2(240, 18)
	(_bar.get_theme_stylebox("fill") as StyleBoxFlat).bg_color = Color(0.35, 0.82, 0.38)



	var kotak_jam: = PanelContainer.new()
	kotak_jam.add_theme_stylebox_override("panel", GH.kaca(0.78, 16, Vector4(16, 6, 18, 8)))
	kotak_jam.mouse_filter = Control.MOUSE_FILTER_IGNORE
	kanvas.get_parent().add_child(kotak_jam)
	var isi_jam: = HBoxContainer.new()
	isi_jam.add_theme_constant_override("separation", 10)
	kotak_jam.add_child(isi_jam)
	var ikon_jam: = _ikon("res://assets/ikon/jam.svg", 46)
	isi_jam.add_child(ikon_jam)
	var kolom_jam: = VBoxContainer.new()
	kolom_jam.add_theme_constant_override("separation", -6)
	isi_jam.add_child(kolom_jam)
	_label_jam = GH.label("", 46, GH.KUNING, true, 6)
	kolom_jam.add_child(_label_jam)
	_label_lama = GH.label("", 17, Color(1, 1, 1, 0.9), false, 3)
	kolom_jam.add_child(_label_lama)
	_kotak_jam = kotak_jam
	_perbarui_energi()
	_tombol_selesai = Button.new()
	_tombol_selesai.text = "Selesai"
	GH.gaya_tombol(_tombol_selesai, true, 26)
	_tombol_selesai.custom_minimum_size = Vector2(170, 56)
	_tombol_selesai.position = Vector2(14, 12)
	_tombol_selesai.pressed.connect(_selesai_mancing)
	kanvas.get_parent().add_child(_tombol_selesai)



func menit_sekarang() -> float:
	return GameState.menit + float(GameState.aturan_hasil_alam("menit_per_lempar", 3)) * lemparan


func _batas_jam() -> float:
	return float((GameState.aturan_hasil_alam("jam_mancing", [6.0, 20.0]) as Array)[1])


func _teks_batas_jam() -> String:
	var b: = _batas_jam()
	return "%02d.%02d" % [int(b), int(round(fmod(b, 1.0) * 60))]


func _sudah_gelap() -> bool:
	return menit_sekarang() / 60.0 >= _batas_jam()


func _perbarui_jam() -> void :
	if _label_jam == null:
		return
	var m: = int(menit_sekarang()) % (24 * 60)
	var waktu: = float(lemparan) * float(GameState.aturan_hasil_alam("menit_per_lempar", 3))
	_label_jam.text = "%02d.%02d" % [m / 60, m % 60]
	var lama: = "Mancing sampai %s" % _teks_batas_jam()
	if lemparan > 0:
		lama = ("Sudah %d menit" % int(waktu)) if waktu < 60.0 else ("Sudah %d jam %d menit" % [int(waktu) / 60, int(waktu) % 60])

	var sisa_menit: = _batas_jam() * 60.0 - menit_sekarang()
	_label_jam.add_theme_color_override("font_color", Color(1, 0.6, 0.35) if sisa_menit <= 30.0 else GH.KUNING)
	if sisa_menit <= 30.0:
		lama = "Mancing sampai %s!" % _teks_batas_jam()
	_label_lama.text = lama

	await get_tree().process_frame
	if is_instance_valid(_kotak_jam):
		_kotak_jam.reset_size()
		_kotak_jam.position = Vector2(UKURAN.x - _kotak_jam.size.x - 14, 12)

	if lemparan > 0 and is_instance_valid(_label_jam):
		_label_jam.pivot_offset = _label_jam.size / 2.0
		_label_jam.scale = Vector2.ONE * 1.25
		create_tween().tween_property(_label_jam, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _perbarui_energi() -> void :
	_perbarui_jam()
	create_tween().tween_property(_bar, "value", GameState.energi, 0.35).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_label_energi.text = "ENERGI %d%%" % int(floor(GameState.energi))
	var fill: = _bar.get_theme_stylebox("fill") as StyleBoxFlat
	fill.bg_color = Color(0.35, 0.82, 0.38) if GameState.energi >= 30.0 else (GH.KUNING if GameState.energi >= 15.0 else GH.MERAH)



func _boleh_bonus_ganda() -> bool:
	return super._boleh_bonus_ganda() and GameState.bonus_mancing_hari != GameState.hari


func _saat_bonus_ganda() -> void :
	GameState.bonus_mancing_hari = GameState.hari
	_tombol_selesai.hide()





func _cek_skor_ganda() -> void :
	if not _boleh_bonus_ganda():
		return
	if not _kabar_ganda and skor >= target:
		_kabar_ganda = true
		kilat(UKURAN / 2.0 + Vector2(0, -90), "Kejar 10 ikan, ada bonus!", GH.KUNING)
	if skor >= target * 2.0:
		GameState.bonus_mancing_hari = GameState.hari
		GameState.beri_bonus_skor_ganda()
		kilat(UKURAN / 2.0 + Vector2(0, -90), "Bonus %s! Lanjut mancing" % GameState.format_rupiah(GameState.BONUS_SKOR_GANDA), GH.KUNING)
		percik(UKURAN / 2.0, GH.KUNING, 24, 6.0)
		GameState.bunyi("koin")


func _selesai_mancing() -> void :
	if not main:
		return
	main = false
	_tombol_selesai.hide()
	_akhiri()


func hasil() -> float:
	return 1.0


func _perbarui_skor() -> void :
	_label_skor.text = "%d" % int(skor)


func _main(delta: float) -> void :
	_waktu += delta
	_sentak = maxf(_sentak - delta * 3.0, 0.0)
	for r in _riak:
		r[1] += delta
	_riak = _riak.filter( func(r): return r[1] < 1.4)
	for f in _ikan_terbang:
		f[1] += delta
	_ikan_terbang = _ikan_terbang.filter( func(f): return f[1] < 1.1)
	match _tahap:
		"siap":

			_kuat += delta * 0.9 * (1.0 if _kuat_naik else -1.0)
			if _kuat >= 1.0:
				_kuat = 1.0
				_kuat_naik = false
			elif _kuat <= 0.0:
				_kuat = 0.0
				_kuat_naik = true
		"lempar":
			if _waktu >= 0.55:
				_mulai_tunggu()
		"tunggu":
			_getar_sisa = maxf(_getar_sisa - delta, 0.0)
			if not _getar.is_empty() and _waktu >= float(_getar[0]):
				_getar.pop_front()
				_getar_sisa = 0.3
				_riak.append([_pelampung, 0.0, 0.5])

			var t: = clampf(_waktu / _tunggu, 0.0, 1.0)
			_bayang = _bayang.lerp(_pelampung + Vector2(-40, 16) * (1.0 - t), minf(delta * 1.5, 1.0))
			if _waktu >= _tunggu:
				_ubah("gigit")
				_riak.append([_pelampung, 0.0, 1.2])
				percik(_pelampung, Color(0.8, 0.92, 1.0), 10, 5.0)
				GameState.klik()

				if OS.has_feature("mobile"):
					Input.vibrate_handheld(160)
		"gigit":
			if _waktu >= _jendela:
				_gagal("Telat! Ikannya lepas.")
		"tarik":
			if _waktu >= 0.9:
				_ke_siap()
		"gagal":
			if _waktu >= 1.1:
				_ke_siap()


func _masukan(e: InputEvent) -> void :
	if not tekan_awal(e):
		return
	match _tahap:
		"siap":
			_lempar()
		"tunggu":
			_gagal("Terlalu cepat! Ikannya kabur.")
		"gigit":
			_dapat()


func _ubah(t: String) -> void :
	_tahap = t
	_waktu = 0.0


func _ke_siap() -> void :
	_pesan = ""
	_ubah("siap")
	_kuat = 0.0
	_kuat_naik = true


func _lempar() -> void :

	if GameState.tas_alam_penuh("ikan", tangkapan):
		_pesan = "Tas penuh! Jual dulu ke Bu Ida di Pasar."
		_pesan_warna = Color(1, 0.55, 0.45)
		_selesai_mancing()
		return

	if _sudah_gelap():
		_pesan = "Sudah pukul %s, hari mulai gelap. Mancing selesai." % _teks_batas_jam()
		_pesan_warna = Color(1, 0.8, 0.45)
		_selesai_mancing()
		return
	if GameState.energi < _energi_lempar():
		_pesan = "Energi tidak cukup untuk melempar lagi."
		_pesan_warna = Color(1, 0.55, 0.45)
		_selesai_mancing()
		return
	GameState.energi = maxf(GameState.energi - _energi_lempar(), 0.0)
	lemparan += 1
	_perbarui_energi()
	kilat(Vector2(290, 46), "-%d%%" % int(_energi_lempar()), Color(1, 0.6, 0.45))
	kilat(Vector2(UKURAN.x - 340, 70), "+%d menit" % int(GameState.aturan_hasil_alam("menit_per_lempar", 3)), GH.KUNING)
	GameState.data_berubah.emit()
	GameState.klik()
	var jauh: = _kuat
	_asal_lempar = _ujung_joran()
	_pelampung = Vector2(lerpf(430.0, 860.0, jauh), lerpf(345.0, 215.0, jauh)) + Vector2(randf_range(-30, 30), randf_range(-12, 12))
	_jenis = GameState.acak_hasil_alam("ikan", jauh * 0.25)
	_jendela = float(GameState.info_hasil_alam(_jenis).get("jendela", 0.6))
	_pesan = ""
	_ubah("lempar")


func _mulai_tunggu() -> void :
	_ubah("tunggu")
	_riak.append([_pelampung, 0.0, 1.0])
	GameState.klik()
	_tunggu = randf_range(2.0, 5.0)
	_getar = []
	var n: = randi_range(0, 3)
	for i in n:
		_getar.append(randf_range(0.6, _tunggu - 0.5))
	_getar.sort()
	_bayang = _pelampung + Vector2(randf_range(-260, -140), randf_range(30, 70))


func _dapat() -> void :
	_ubah("tarik")
	_sentak = 1.0
	if GameState.sisa_muat_alam(_jenis, tangkapan) <= 0:

		_pesan = "Tas penuh, %s dilepas lagi." % String(GameState.info_hasil_alam(_jenis).get("nama", _jenis))
		_pesan_warna = Color(1, 0.8, 0.5)
		percik(_pelampung, Color(0.8, 0.92, 1.0), 10, 5.0)
		return
	tangkapan.append(_jenis)
	GameState.tangkapan_tertunda = Array(tangkapan)
	var info: = GameState.info_hasil_alam(_jenis)
	_pesan = "Dapat %s!" % String(info.get("nama", _jenis))
	_pesan_warna = GH.KUNING
	_ikan_terbang.append([_jenis, 0.0])
	percik(_pelampung, Color(0.8, 0.92, 1.0), 16, 6.0)
	tambah_skor(1, _pelampung + Vector2(0, -50))
	GameState.bunyi("koin")
	if OS.has_feature("mobile") and not GameState.legendaris(_jenis):
		Input.vibrate_handheld(90)
	if GameState.legendaris(_jenis):
		_pesan = "IKAN LEGENDARIS! Dapat %s!" % String(info.get("nama", _jenis))
		percik(_pelampung, GH.KUNING, 40, 9.0)
		kilat(_pelampung + Vector2(0, -110), "LEGENDARIS!", GH.KUNING)
		_guncang = 0.8
		GameState.bunyi("hadiah")
		if OS.has_feature("mobile"):
			Input.vibrate_handheld(200)


func _gagal(teks: String) -> void :
	_ubah("gagal")
	_pesan = teks
	_pesan_warna = Color(1, 0.55, 0.5)
	_riak.append([_pelampung, 0.0, 0.8])
	_beruntun = 0
	_guncang = 0.6
	if OS.has_feature("mobile"):
		Input.vibrate_handheld(60)


func _ujung_joran() -> Vector2:

	var lentur: = 0.0
	if _tahap == "gigit":
		lentur = 26.0
	return TITIK_JORAN + Vector2(0, lentur - 50.0 * _sentak)



var _senja: = 0.0
var _gelap: = 0.0


func _hitung_senja() -> void :
	var jam: = GameState.menit / 60.0
	_senja = clampf((jam - 17.0) / 1.5, 0.0, 1.0)
	_gelap = clampf((jam - 18.5) / 1.0, 0.0, 1.0)



func _w(siang: Color, senja: Color, malam: Color) -> Color:
	return siang.lerp(senja, _senja).lerp(malam, _gelap)


func _redup(c: Color) -> Color:
	var gelap: = Color(c.r * 0.45, c.g * 0.42, c.b * 0.62, c.a)
	return c.lerp(Color(c.r * 0.85, c.g * 0.7, c.b * 0.6, c.a), _senja * (1.0 - _gelap)).lerp(gelap, _gelap)



func _gambar() -> void :
	var w: = Time.get_ticks_msec() / 1000.0




	_hitung_senja()
	kanvas.draw_polygon(PackedVector2Array([Vector2.ZERO, Vector2(UKURAN.x, 0), Vector2(UKURAN.x, Y_AIR), Vector2(0, Y_AIR)]), 
		PackedColorArray([_w(Color(0.5, 0.72, 0.92), Color(0.36, 0.33, 0.6), Color(0.06, 0.07, 0.18)), 
			_w(Color(0.7, 0.82, 0.92), Color(0.62, 0.45, 0.62), Color(0.1, 0.1, 0.24)), 
			_w(Color(1.0, 0.88, 0.66), Color(1.0, 0.56, 0.28), Color(0.42, 0.24, 0.28)), 
			_w(Color(0.9, 0.9, 0.82), Color(0.98, 0.7, 0.48), Color(0.24, 0.18, 0.28))]))
	if _gelap > 0.0:
		for i in 40:
			var bx: = fmod(i * 197.3 + 31.0, UKURAN.x)
			var by: = fmod(i * 61.7 + 7.0, Y_AIR - 60.0)
			kanvas.draw_circle(Vector2(bx, by), 1.2 + (i % 3) * 0.5, Color(1, 1, 0.9, _gelap * (0.45 + 0.35 * sin(w * 1.7 + i))))
		var bulan: = Vector2(UKURAN.x - 210, 34)
		for i in 4:
			kanvas.draw_circle(bulan, 22.0 + i * 9.0, Color(0.95, 0.95, 0.8, (0.07 - i * 0.015) * _gelap))
		kanvas.draw_circle(bulan, 17, Color(0.98, 0.96, 0.86, _gelap))
		var langit: = _w(Color(0.5, 0.72, 0.92), Color(0.36, 0.33, 0.6), Color(0.06, 0.07, 0.18))
		kanvas.draw_circle(bulan + Vector2(7, -4), 15, Color(langit, _gelap))
	var surya: = Vector2(UKURAN.x - 330, lerpf(46.0, 62.0, _senja))
	var warna_surya: = Color(1, 0.95, 0.78).lerp(Color(1, 0.58, 0.32), _senja)
	var a_surya: = 1.0 - _gelap
	if a_surya > 0.0:
		for i in 6:
			kanvas.draw_circle(surya, 30.0 + i * 18.0 * (1.0 + _senja * 0.6), Color(warna_surya.r, warna_surya.g * 0.95, warna_surya.b * 0.8, (0.16 - i * 0.024) * a_surya * (1.0 + _senja)))
		kanvas.draw_circle(surya, 26 + 6 * _senja, Color(warna_surya, a_surya))

	for i in 12:
		kanvas.draw_circle(Vector2(i * 95.0 + 10.0, Y_AIR - 58), 44, _redup(Color(0.46, 0.6, 0.55)))
	for i in 9:
		var x: = i * 130.0 + 40.0

		kanvas.draw_circle(Vector2(x, Y_AIR - 40), 62, _redup(Color(0.17, 0.33, 0.19)))
		kanvas.draw_circle(Vector2(x + 8, Y_AIR - 46), 55, _redup(Color(0.26, 0.46, 0.27)))
		kanvas.draw_circle(Vector2(x + 50, Y_AIR - 22), 48, _redup(Color(0.19, 0.36, 0.2)))
		kanvas.draw_circle(Vector2(x + 57, Y_AIR - 27), 42, _redup(Color(0.29, 0.5, 0.29)))
	kanvas.draw_rect(Rect2(0, Y_AIR - 40, UKURAN.x, 18), Color(1, 0.95, 0.85, 0.12 * (1.0 - _gelap)))

	kanvas.draw_rect(Rect2(0, Y_AIR - 22, UKURAN.x, 26), _redup(Color(0.42, 0.38, 0.33)))
	for i in 22:
		kotak_bulat(Rect2(i * 50 - (12 if i % 2 else 0), Y_AIR - 20, 44, 10), _redup(Color(0.62, 0.58, 0.5)), 4)
		kanvas.draw_line(Vector2(i * 50 - (12 if i % 2 else 0) + 4, Y_AIR - 19), Vector2(i * 50 - (12 if i % 2 else 0) + 40, Y_AIR - 19), Color(1, 1, 1, 0.25 * (1.0 - _gelap * 0.7)), 1)
	kanvas.draw_rect(Rect2(0, Y_AIR + 2, UKURAN.x, 4), Color(0, 0, 0, 0.25))

	kanvas.draw_polygon(PackedVector2Array([Vector2(0, Y_AIR), Vector2(UKURAN.x, Y_AIR), Vector2(UKURAN.x, UKURAN.y), Vector2(0, UKURAN.y)]), 
		PackedColorArray([_w(Color(0.45, 0.66, 0.7), Color(0.62, 0.48, 0.5), Color(0.14, 0.15, 0.26)), 
			_w(Color(0.62, 0.7, 0.68), Color(0.86, 0.56, 0.4), Color(0.26, 0.18, 0.26)), 
			_w(Color(0.14, 0.32, 0.36), Color(0.14, 0.22, 0.3), Color(0.04, 0.07, 0.12)), 
			_w(Color(0.15, 0.33, 0.38), Color(0.14, 0.22, 0.3), Color(0.04, 0.07, 0.12))]))

	for i in 9:
		var x: = i * 130.0 + 40.0 + sin(w * 1.3 + i) * 3.0
		_elips_isi(Vector2(x + 20, Y_AIR + 22), 92, 16, 0.0, Color(0.08, 0.22, 0.16, 0.12))

	for k in 14:
		var y: = Y_AIR + 14 + k * 16.0
		var lebar: = 20.0 + k * 6.0
		var kedip: = 0.25 + 0.2 * sin(w * 3.0 + k * 1.7)
		var x: = surya.x + sin(w * 1.5 + k) * 10.0
		kanvas.draw_line(Vector2(x - lebar / 2.0, y), Vector2(x + lebar / 2.0, y), Color(Color(1, 0.92, 0.7).lerp(Color(1, 0.62, 0.32), _senja), kedip * (1.0 - _gelap * 0.85)), 2.5)
	for i in 18:
		var y: = Y_AIR + 20 + (i % 9) * 30.0
		var x: = fmod(i * 173.0 + w * (30.0 + (i % 3) * 10.0), UKURAN.x + 200) - 100
		kanvas.draw_line(Vector2(x, y + 2), Vector2(x + 60 + (i % 4) * 14, y + 2), Color(0, 0.1, 0.12, 0.18), 3)
		kanvas.draw_line(Vector2(x, y), Vector2(x + 60 + (i % 4) * 14, y), Color(1, 1, 1, 0.18), 2)

	if _senja > 0.0:
		kanvas.draw_rect(Rect2(0, Y_AIR, UKURAN.x, UKURAN.y - Y_AIR), Color(0.1, 0.05, 0.18, 0.08 * _senja + 0.25 * _gelap))
		kanvas.draw_rect(Rect2(0, 0, UKURAN.x, UKURAN.y), Color(1, 0.45, 0.2, 0.07 * _senja * (1.0 - _gelap)))

	if _tahap == "tunggu" or _tahap == "gigit":
		var arah: = (_pelampung - _bayang).normalized()
		if GameState.legendaris(_jenis):

			kanvas.draw_circle(_bayang, 34, Color(0.95, 0.75, 0.2, 0.18 + 0.08 * sin(w * 5.0)))
			kanvas.draw_circle(_bayang, 26, Color(0.95, 0.75, 0.2, 0.3 + 0.12 * sin(w * 5.0)))
		else:
			kanvas.draw_circle(_bayang, 19, Color(0.05, 0.12, 0.15, 0.18))
			kanvas.draw_circle(_bayang, 14, Color(0.05, 0.12, 0.15, 0.32))

	for r in _riak:
		var a: = 1.0 - float(r[1]) / 1.4
		var jari: = (12.0 + float(r[1]) * 50.0) * float(r[2])
		_elips_garis(r[0], jari, jari * 0.35, Color(1, 1, 1, a * 0.6))

	gradasi(Rect2(0, UKURAN.y - 40, UKURAN.x, 40), _redup(Color(0.3, 0.5, 0.22)), _redup(Color(0.16, 0.28, 0.12)))
	for i in 40:
		var x: = i * 27.0 + 6.0
		var gy: = sin(w * 2.0 + i) * 4.0
		kanvas.draw_line(Vector2(x, UKURAN.y), Vector2(x + gy + 4, UKURAN.y - 50 - (i % 3) * 12), _redup(Color(0.42, 0.66, 0.3)), 4)
	for i in 30:
		var x: = i * 37.0 + 20.0
		var gy: = sin(w * 1.6 + i * 0.7) * 6.0
		kanvas.draw_colored_polygon(PackedVector2Array([Vector2(x - 5, UKURAN.y + 2), Vector2(x + 5, UKURAN.y + 2), Vector2(x + gy + 2, UKURAN.y - 34 - (i % 4) * 9)]), _redup(Color(0.12, 0.22, 0.08, 0.95)))

	var ujung: = _ujung_joran()
	kanvas.draw_line(PANGKAL_JORAN + Vector2(8, 6), ujung + Vector2(8, 6), Color(0, 0, 0, 0.18), 8)
	kanvas.draw_line(PANGKAL_JORAN, ujung, Color(0.35, 0.22, 0.1), 9)
	kanvas.draw_line(PANGKAL_JORAN, ujung, Color(0.62, 0.42, 0.22), 5)
	kanvas.draw_line(PANGKAL_JORAN + Vector2(-1, -1), ujung + Vector2(-1, -1), Color(0.95, 0.78, 0.5, 0.7), 1.5)
	kanvas.draw_circle(PANGKAL_JORAN.lerp(ujung, 0.18), 14, Color(0.2, 0.2, 0.22))
	kanvas.draw_circle(PANGKAL_JORAN.lerp(ujung, 0.18), 6, Color(0.7, 0.7, 0.72))
	match _tahap:
		"siap":
			_gambar_bar_kuat()
			_tali(ujung, ujung + Vector2(0, 60), 0.0)
			_gambar_pelampung(ujung + Vector2(0, 66), 0.0)
		"lempar":
			var t: = clampf(_waktu / 0.55, 0.0, 1.0)
			var p: = _asal_lempar.lerp(_pelampung, t) + Vector2(0, - sin(t * PI) * 140.0)
			_tali(ujung, p, 0.0)
			_gambar_pelampung(p, 0.0)
		"tunggu", "gigit":
			var turun: = 0.0
			var geser: = Vector2.ZERO
			if _tahap == "tunggu":
				turun = sin(w * 2.5) * 2.0
				if _getar_sisa > 0.0:
					geser.x = sin(w * 60.0) * 3.0
					turun += 4.0
			else:
				turun = 16.0 + sin(w * 30.0) * 3.0
			var p: = _pelampung + Vector2(0, turun) + geser
			_tali(ujung, p, 0.3 if _tahap == "tunggu" else 0.0)
			_gambar_pelampung(p, 1.0 if _tahap == "gigit" else 0.0)
			if _tahap == "gigit":
				_tanda_seru(_pelampung + Vector2(0, -70), w)
		"tarik", "gagal":
			_tali(ujung, ujung + Vector2(0, 60), 0.0)
			_gambar_pelampung(ujung + Vector2(0, 66), 0.0)

	for f in _ikan_terbang:
		var t: = clampf(float(f[1]) / 0.8, 0.0, 1.0)
		var p: = _pelampung.lerp(ujung + Vector2(60, 40), t) + Vector2(0, - sin(t * PI) * 160.0)
		kanvas.draw_set_transform(p, sin(t * TAU) * 0.6, Vector2.ONE)
		gambar_tekstur(String(GameState.info_hasil_alam(String(f[0])).get("ikon", "")), Vector2.ZERO, 110)
		kanvas.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	var teks_bawah: = _pesan
	var warna: = _pesan_warna
	if teks_bawah == "":
		match _tahap:
			"siap":
				teks_bawah = "Klik untuk melempar kail"
				warna = Color.WHITE
			"tunggu":
				teks_bawah = "Sabar... tunggu ikan menyambar"
				warna = Color(1, 1, 1, 0.85)
			"gigit":
				teks_bawah = "SEKARANG! KLIK!"
				warna = GH.KUNING
	if teks_bawah != "":
		teks(Vector2(UKURAN.x / 2.0 + 90, 40), teks_bawah, 34, warna, 760, 8)
	teks(Vector2(UKURAN.x - 150, UKURAN.y - 22), "Ikan didapat: %d" % int(skor), 20, Color(1, 1, 1, 0.9), 230, 6)


func _gambar_bar_kuat() -> void :

	var r: = Rect2(UKURAN.x - 90, 150, 34, 200)
	kotak_bulat(r.grow(5), Color(0, 0, 0, 0.55), 12)
	var tinggi: = r.size.y * _kuat
	var warna: = Color(0.4, 0.85, 0.4).lerp(GH.KUNING, _kuat).lerp(Color(1, 0.45, 0.3), maxf(_kuat - 0.7, 0.0) / 0.3)
	kotak_bulat(Rect2(r.position.x, r.end.y - tinggi, r.size.x, tinggi), warna, 8)
	garis_bulat(r.grow(5), Color(1, 1, 1, 0.8), 12, 3)
	teks(Vector2(r.get_center().x, r.position.y - 26), "Jauh", 18, Color.WHITE, 120, 5)
	teks(Vector2(r.get_center().x, r.end.y + 26), "Dekat", 18, Color.WHITE, 120, 5)


func _tali(a: Vector2, b: Vector2, kendur: float) -> void :
	var titik: = PackedVector2Array()
	for i in 13:
		var t: = i / 12.0
		titik.append(a.lerp(b, t) + Vector2(0, sin(t * PI) * 40.0 * kendur))
	kanvas.draw_polyline(titik, Color(1, 1, 1, 0.75), 2.0, true)



func _gambar_pelampung(p: Vector2, tenggelam: float) -> void :
	if tenggelam > 0.0:
		kanvas.draw_circle(p + Vector2(0, -2), 8, Color(0.85, 0.12, 0.1))
		_elips_garis(p + Vector2(0, 4), 16, 6, Color(1, 1, 1, 0.7))
		return
	kanvas.draw_line(p + Vector2(0, -26), p + Vector2(0, -10), Color(0.15, 0.15, 0.15), 3)
	kanvas.draw_circle(p + Vector2(0, -4), 11, Color(0.92, 0.15, 0.12))
	kanvas.draw_circle(p + Vector2(0, 5), 10, Color(0.97, 0.97, 0.95))
	kanvas.draw_circle(p + Vector2(-3, -7), 3, Color(1, 1, 1, 0.7))


func _tanda_seru(p: Vector2, w: float) -> void :
	var s: = 1.0 + sin(w * 18.0) * 0.12
	kanvas.draw_circle(p, 30 * s, Color(0.1, 0.1, 0.1, 0.6))
	kanvas.draw_circle(p, 26 * s, GH.KUNING)
	teks(p + Vector2(0, -4), "!", 44, Color(0.2, 0.1, 0.05), 60)


func _elips_isi(p: Vector2, rx: float, ry: float, sudut: float, warna: Color) -> void :
	var titik: = PackedVector2Array()
	for i in 20:
		var a: = i * TAU / 20.0
		titik.append(p + Vector2(cos(a) * rx, sin(a) * ry).rotated(sudut))
	kanvas.draw_colored_polygon(titik, warna)


func _elips_garis(p: Vector2, rx: float, ry: float, warna: Color) -> void :
	var titik: = PackedVector2Array()
	for i in 25:
		var a: = i * TAU / 24.0
		titik.append(p + Vector2(cos(a) * rx, sin(a) * ry))
	kanvas.draw_polyline(titik, warna, 2.0, true)



func _isi_hasil_khusus(kolom: VBoxContainer, t: Label) -> bool:
	kolom.get_child(0).hide()
	kartu_hasil_alam(kolom, t, true, "Ikan disimpan di Tas (buka HP). Jual ke Bu Ida di Pasar.", "Jangan menyerah, Pak! Klik tepat saat ikan menyambar umpan.")

	var waktu: = int(float(lemparan) * float(GameState.aturan_hasil_alam("menit_per_lempar", 3)))
	var m: = int(menit_sekarang()) % (24 * 60)
	var baris: = ("Mancing %d menit, sekarang pukul %02d.%02d." % [waktu, m / 60, m % 60]) if waktu < 60 else ("Mancing %d jam %d menit, sekarang pukul %02d.%02d." % [waktu / 60, waktu % 60, m / 60, m % 60])
	if _pesan.begins_with("Sudah pukul") or _pesan.begins_with("Energi tidak cukup") or _pesan.begins_with("Tas penuh!"):
		baris = _pesan + """
""" + baris
	if lemparan > 0:
		var ket: = GH.label(baris, 20, Color(1, 0.85, 0.55), false, 3)
		ket.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		kolom.add_child(ket)
		kolom.move_child(ket, mini(2, kolom.get_child_count() - 1))
	return true
