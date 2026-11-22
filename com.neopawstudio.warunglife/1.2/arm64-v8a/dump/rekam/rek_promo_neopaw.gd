extends SceneTree



var gs
var adegan: = ""
var j = null


func _initialize() -> void :
	_jalan()


func _tunggu(d: float) -> void :
	await create_timer(d).timeout



func _pembersih() -> void :
	while true:
		await _tunggu(0.05)
		var sc = current_scene
		if sc == null:
			continue
		for n in sc.find_children("*", "", true, false):
			var sk = n.get_script()
			if sk != null and String(sk.resource_path).ends_with("god_mode.gd") and n is CanvasItem:
				n.visible = false
		gs.kirim_diingatkan_hari = gs.hari


func _siapkan() -> void :
	gs.mulai_game_baru()
	gs.atur_bahasa("id")
	gs.tanpa_iklan = true
	gs.set_meta("rekam", true)
	gs.nama_warung = "Berkah"
	gs.tutorial_selesai = true
	gs.tutorial_awal = false
	gs.tutorial_penutup = false
	gs.tutorial_langkah = ""
	gs.wajib_etalase = false
	gs.putar_intro = false
	gs.dialog_tertunda.clear()
	gs.hari = 3
	gs.uang = 120000
	gs.tingkat = 3
	gs.reputasi = 88.0
	gs.reputasi_awal_hari = 88.0
	gs.energi = 100.0
	for u in ["etalase", "kipas", "lampu", "spanduk", "bangku", "radio"]:
		if not gs.upgrade_dimiliki.has(u):
			gs.upgrade_dimiliki.append(u)
	for id in gs.urutan_barang:
		if not gs.barang_terbuka.has(id):
			gs.barang_terbuka.append(id)
	for id in gs.stok:
		gs.stok[id] = 40

	gs._minta_utang_hari = gs.hari
	gs._minta_utang_jumlah = 99
	gs.cuaca = {}


func _warung(menit: int) -> void :
	gs.menit = menit
	gs.status_hari = "buka"
	change_scene_to_file("res://scenes/warung.tscn")
	await _tunggu(0.6)
	j = current_scene
	j.get_node("Layanan").detik_datang_berikutnya = 0.8


func _layani_otomatis(lama: float, sekali: = false) -> void :
	var l = j.get_node("Layanan")
	var t: = 0.0
	while t < lama:
		await _tunggu(0.3)
		t += 0.3
		if j.dialog_aktif:
			continue
		var p: Dictionary = l._depan()
		if not p.is_empty() and p["status"] == "depan" and p["waktu"] > 0.9:
			l.keranjang.clear()
			for b in p["pesanan"]:
				l.keranjang[b[0]] = b[1]
			l._perbarui_tombol_barang()
			await _tunggu(0.6)
			t += 0.6
			l._on_layani_ditekan()
			if sekali:
				return




func _dialog_otomatis(lama: float, pilihan: int, tahan: = 1.1, tahan_tanya: = 1.8) -> void :
	var d = j.dialog
	var t: = 0.0
	var diam: = 0.0
	while t < lama:
		await _tunggu(0.1)
		t += 0.1
		if not d.visible:
			diam = 0.0
			continue
		diam += 0.1
		if d._memilih:
			if diam >= tahan_tanya:
				d.dipilih.emit(pilihan)
				diam = 0.0
		elif d._teks.visible_ratio >= 1.0 and diam >= tahan:
			d.lanjut()
			if d.visible and d._teks.visible_ratio >= 1.0 and not d._memilih:
				d.lanjut()
			diam = 0.0


func _jelajah(area: String, muncul: String, menit: int) -> void :
	gs.menit = menit
	if gs.status_hari == "":
		gs.status_hari = "buka"
	gs.tujuan_jelajah = {"area": area, "muncul": muncul}
	change_scene_to_file("res://scenes/jelajah.tscn")
	await _tunggu(1.2)
	j = current_scene
	j.joystick.visible = false
	if adegan in ["neo", "sawah", "ucup", "hujan"]:
		j.kamera.zoom *= 1.3



func _jalan_ke(tujuan: Vector2, jarak: = 90.0, batas: = 6.0, kuat: = 1.0) -> void :
	var t: = 0.0
	while t < batas:
		var v: Vector2 = tujuan - j.bapak.position
		if v.length() < jarak:
			break
		j.joystick.arah = v.normalized() * kuat
		await _tunggu(0.05)
		t += 0.05
	j.joystick.arah = Vector2.ZERO



func _warga_event():
	for x in j.warga:
		if is_instance_valid(x) and x.has_meta("event"):
			return x
	return null


func _jalan() -> void :
	await process_frame
	gs = root.get_node("GameState")
	for a in OS.get_cmdline_user_args():
		adegan = a
	_siapkan()
	_pembersih()
	match adegan:
		"jualan":
			await _warung(9 * 60 + 20)
			await _layani_otomatis(22.0)
		"hutang":
			gs._minta_utang_jumlah = 0
			gs.hari = 4
			gs._minta_utang_hari = gs.hari
			await _warung(13 * 60)
			var l = j.get_node("Layanan")
			var t: = 0.0
			while t < 25.0:
				await _tunggu(0.3)
				t += 0.3
				var p: Dictionary = l._depan()
				if not p.is_empty() and p["status"] == "depan" and p["waktu"] > 0.9:
					break

			gs.set_meta("paksa_utang", true)
			t = 0.0
			while t < 40.0 and gs.has_meta("paksa_utang"):
				await _layani_otomatis(0.9, true)
				t += 0.9
			await _tekan("Kasih utang", 10.0, 2.8)
			await _tunggu(6.0)
		"preman":
			await _warung(11 * 60)

			j.get_node("Layanan").detik_datang_berikutnya = 999.0
			await _tunggu(1.0)
			gs.kejadian = {"id": "palak", "mulai": int(gs.menit) + 1, "lama": 0, "status": "menunggu", "tangkal": false}
			await _tekan("Tolak", 40.0, 2.6)
			await _tunggu(9.0)
		"jumatan":
			gs.hari = 5
			gs.jumatan_hari = 0
			await _warung(11 * 60 + 28)
			await _tekan("Ikut Jumatan", 40.0, 2.0)
			await _tunggu(14.0)
		"neo":

			gs.hari = 5
			gs.cerita_warga["kucing_bu_ida"] = {"tahap": 3}
			gs.god_paksa_event = "kucing_bu_ida"
			await _jelajah("rumah", "kanan", 10 * 60)
			await _tunggu(1.0)
			var w = _warga_event()
			if w == null:
				print("GISKA TIDAK ADA")
				quit()
				return
			await _jalan_ke(w.position, 120.0, 16.0)
			await _tunggu(0.3)
			j._ngobrol(w)
			await _dialog_otomatis(16.0, 0)
		"neo_makan":
			gs.cerita_warga["kucing_bu_ida"] = {"tahap": 99, "hasil": "tolong"}
			await _jelajah("rumah", "kanan", 9 * 60)
			var t: = 0.0
			while j.neo == null and t < 5.0:
				await _tunggu(0.2)
				t += 0.2
			if j.neo == null:
				print("NEO TIDAK MUNCUL")
				quit()
				return
			await _jalan_ke(j.neo.position, 110.0, 6.0)
			await _tunggu(0.4)
			j._sapa_neo(j.neo)
			await _dialog_otomatis(12.0, 1)
		"ucup":
			gs.god_paksa_event = "ucup_sekolah"
			await _jelajah("sd", "kiri", 9 * 60)
			await _tunggu(0.5)
			var w = _warga_event()
			if w == null:
				print("UCUP TIDAK ADA")
				quit()
				return
			await _jalan_ke(w.position, 120.0, 6.0)
			j._ngobrol(w)
			await _dialog_otomatis(40.0, 0, 0.9)
		"sawah":
			gs.god_paksa_event = "beras_abah_karta"
			await _jelajah("sawah", "trotoar", 8 * 60)
			await _tunggu(0.5)
			var w = _warga_event()
			if w == null:
				print("ABAH KARTA TIDAK ADA")
				quit()
				return
			await _jalan_ke(w.position, 120.0, 8.0)
			j._ngobrol(w)
			await _dialog_otomatis(30.0, 0, 1.0)
		"tabrak":
			await _jelajah("warung", "depan_warung", 10 * 60 + 40)
			var z: Dictionary = j.area["zebra"]
			var dekat: Vector2 = j._v(z["dekat"])
			var jauh: Vector2 = j._v(z["jauh"])
			var lk: Array = j.area["jalan"]["lajur_kanan"]
			var titik = Geometry2D.segment_intersects_segment(dekat, jauh, j._v(lk[0]), j._v(lk[1]))
			if titik == null:
				titik = dekat.lerp(jauh, 0.25)
			await _jalan_ke(dekat, 30.0, 6.0)
			for k in j.lalu_lintas.get_children():
				k.queue_free()
			for coba in 40:
				j._tambah_kendaraan()
				var k = j.lalu_lintas.get_child(j.lalu_lintas.get_child_count() - 1)
				if k.is_queued_for_deletion():
					continue
				if k.lajur[0] == j._v(lk[0]) and k.jenis == "angkot":
					break
				k.queue_free()
			await _tunggu(0.6)
			await _jalan_ke(titik, 12.0, 4.0)
			await _tunggu(12.0)
		"hujan":
			gs.menit = 14 * 60 + 10
			gs.cuaca = {"mulai": 14 * 60, "lama": 120, "dikabari": true}
			await _jelajah("warung", "depan_warung", 14 * 60 + 10)
			await _tunggu(1.5)
			var awal: Vector2 = j.bapak.position
			await _jalan_ke(awal + Vector2(-420, -60), 40.0, 3.0)
			await _jalan_ke(awal + Vector2(260, 40), 40.0, 3.5)
			await _jalan_ke(awal + Vector2(-150, -20), 40.0, 3.0)
			await _tunggu(2.0)
		"tv":
			gs.menit = 7 * 60 + 5
			gs.status_hari = "persiapan"
			gs.cuaca = {"mulai": 13 * 60, "lama": 120, "dikabari": false}
			await _jelajah("kamar", "kasur", 7 * 60 + 5)
			await _tunggu(4.5)
			await _jalan_ke(j._v([380, 660]), 40.0, 5.0, 0.5)
			await _tunggu(0.5)
			j._tampilkan_ramalan()
			await _tunggu(8.0)
		"puasa":

			gs.hari = 60
			gs._minta_utang_hari = gs.hari
			await _warung(17 * 60 + 56)
			await _layani_otomatis(14.0)
		"tarawih":
			gs.hari = 60
			gs._minta_utang_hari = gs.hari
			gs.status_hari = "tutup"
			await _jelajah("masjid", "kiri", 19 * 60 + 35)
			await _jalan_ke(j._v([690, 600]), 160.0, 8.0)
			await _tekan("Ikut tarawih", 10.0, 1.5)
			await _tunggu(8.0)
		"kampung":

			await _jelajah("warung", "depan_warung", 8 * 60 + 30)
			await _tunggu(0.8)
			var awal: Vector2 = j.bapak.position
			await _jalan_ke(awal + Vector2(-480, -40), 40.0, 3.5)
			await _jalan_ke(awal + Vector2(-900, 60), 40.0, 3.5)
			await _tunggu(2.0)
		"bukapuasa":
			gs.hari = 60
			gs._minta_utang_hari = gs.hari
			gs.energi = 55.0
			await _warung(17 * 60 + 56)
			await _layani_otomatis(7.0)
			for n in j.find_children("*", "", true, false):
				var sk = n.get_script()
				if sk != null and String(sk.resource_path).ends_with("bar_energi.gd"):
					n._buka_istirahat()
					break
			await _tekan_awal("Buka puasa", 6.0, 1.6)
			await _tunggu(5.0)
		"malam":
			await _warung(19 * 60 + 10)
			await _layani_otomatis(8.0)
	quit()



func _tekan_awal(teks: String, batas: float, tahan: float) -> void :
	var t: = 0.0
	while t < batas:
		await _tunggu(0.2)
		t += 0.2
		for b in root.find_children("*", "Button", true, false):
			if b.is_visible_in_tree() and String(b.text).begins_with(teks):
				await _tunggu(tahan)
				b.pressed.emit()
				return
	print("TOMBOL TIDAK ADA: ", teks)



func _tekan(teks: String, batas: float, tahan: float) -> void :
	var t: = 0.0
	while t < batas:
		await _tunggu(0.2)
		t += 0.2
		for b in j.find_children("*", "Button", true, false):
			if b.is_visible_in_tree() and String(b.text) == teks:
				await _tunggu(tahan)
				b.pressed.emit()
				return
	print("TOMBOL TIDAK ADA: ", teks)
