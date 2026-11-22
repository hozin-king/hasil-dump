extends VBoxContainer








const UI: = preload("res://scripts/hp/hp_ui.gd")
const WARNA: = Color(0.75, 0.25, 0.25)

var hp: Control
var _isi: VBoxContainer
var _tab: = "tugas"
var _tombol_tab: = {}


func _ready() -> void :
	add_theme_constant_override("separation", 0)
	add_child(UI.kepala("Misi", WARNA))

	var tepi_tab: = MarginContainer.new()
	for sisi in ["left", "right"]:
		tepi_tab.add_theme_constant_override("margin_" + sisi, 8)
	tepi_tab.add_theme_constant_override("margin_top", 8)
	add_child(tepi_tab)
	var baris_tab: = HBoxContainer.new()
	baris_tab.add_theme_constant_override("separation", 6)
	tepi_tab.add_child(baris_tab)
	for p in [["tugas", "Tugas"], ["jalan", "Milestone"]]:
		var b: = UI.tombol(p[1], WARNA, 16, 36)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.pressed.connect( func():
			GameState.klik()
			_tab = p[0]
			tampil())
		baris_tab.add_child(b)
		_tombol_tab[p[0]] = b
	var g: Array = UI.gulir(8)
	var tepi: = MarginContainer.new()
	tepi.size_flags_vertical = Control.SIZE_EXPAND_FILL
	for sisi in ["left", "right", "top", "bottom"]:
		tepi.add_theme_constant_override("margin_" + sisi, 8)
	tepi.add_child(g[0])
	add_child(tepi)
	_isi = g[1]


func _bar(nilai: float, maks: float, warna: Color) -> ProgressBar:
	var bar: = ProgressBar.new()
	bar.show_percentage = false
	bar.custom_minimum_size.y = 10
	bar.max_value = maxf(maks, 1.0)
	bar.value = minf(nilai, maks)
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.add_theme_stylebox_override("background", UI.kotak(Color(0.88, 0.85, 0.8), 5, 0))
	bar.add_theme_stylebox_override("fill", UI.kotak(warna, 5, 0))
	return bar


func tampil() -> void :
	for anak in _isi.get_children():
		anak.queue_free()
	for id in _tombol_tab:
		_tombol_tab[id].modulate = Color.WHITE if id == _tab else Color(1, 1, 1, 0.55)
	if _tab == "jalan":
		_tampil_jalan_level()
	else:
		_tampil_tugas()


func _tampil_tugas() -> void :
	var gs: = GameState

	var t: = gs.tugas_sekarang()
	_isi.add_child(UI.label("Level Warung %d · %s" % [gs.level(), t["nama"]], 18, UI.WARNA_TEKS, true))
	if gs.misi_status == "aktif":
		var kartu: = UI.panel(Color(1, 0.97, 0.88), 10, 10)
		_isi.add_child(kartu)
		var k: = VBoxContainer.new()
		k.add_theme_constant_override("separation", 6)
		kartu.add_child(k)
		var butuh: String = "Agus butuh %s." % gs.data_bab()["kebutuhan"] if gs.kontak_bab() == "agus" else "Perlu %s." % gs.data_bab()["kebutuhan"]
		k.add_child(UI.label("MISI UTAMA", 18, WARNA, true))
		k.add_child(UI.label(butuh, 16, UI.WARNA_TEKS, true))
		k.add_child(UI.label("Terkirim %s dari %s · batas %s (%d hari lagi)" % [gs.format_rupiah(gs.kiriman_bab), gs.format_rupiah(gs.target_bab), gs.teks_tanggal(gs.batas_hari), gs.sisa_hari()], 14, UI.WARNA_REDUP, true))
		k.add_child(_bar(gs.kiriman_bab, gs.target_bab, WARNA))
		k.add_child(UI.label("Kirim uangnya lewat aplikasi Warga Bank, lalu tekan Kirim uang untuk %s." % gs.nama_penerima(), 13, UI.WARNA_REDUP, true))
		if hp != null:
			var ke_wasap: = UI.tombol("Buka Warga Bank", WARNA, 15, 36)
			ke_wasap.pressed.connect( func(): hp.buka_aplikasi("mbanking"))
			k.add_child(ke_wasap)
	var kartu_tugas: = UI.panel(Color.WHITE, 10, 10)
	_isi.add_child(kartu_tugas)
	var kt: = VBoxContainer.new()
	kt.add_theme_constant_override("separation", 4)
	kartu_tugas.add_child(kt)
	for baris_tugas in gs.baris_tugas():
		var selesai: bool = baris_tugas[1] >= baris_tugas[2]
		var atas: = HBoxContainer.new()
		kt.add_child(atas)

		var nama: = UI.label(baris_tugas[0], 14, UI.WARNA_TEKS, true)
		nama.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		nama.custom_minimum_size.x = 120
		atas.add_child(nama)
		atas.add_child(UI.label("selesai" if selesai else baris_tugas[3], 13, UI.WARNA_BERHASIL if selesai else UI.WARNA_REDUP))

		if String(baris_tugas[0]).begins_with("Upgrade:") and not selesai and hp != null:
			var ke: = UI.tombol("Beli", Color(0.45, 0.3, 0.18), 13, 26)
			ke.custom_minimum_size.x = 52
			ke.pressed.connect( func(): hp.buka_aplikasi("upgrade"))
			atas.add_child(ke)
		kt.add_child(_bar(baris_tugas[1], baris_tugas[2], Color(0.27, 0.7, 0.33) if selesai else Color(0.96, 0.62, 0.18)))
	if gs.segera_hadir():
		kt.add_child(UI.label("Level %d sedang disiapkan. Nantikan pembaruan berikutnya!" % gs.level(), 14, UI.WARNA_TEKS, true))
	else:
		kt.add_child(UI.label("Hadiah naik level: %s" % gs.format_rupiah(t["hadiah"]), 14, UI.WARNA_TEKS, true))
	kt.add_child(UI.label("Lihat hadiah tiap level di tab Milestone. Penjelasan tugas ada di aplikasi Panduan.", 13, UI.WARNA_REDUP, true))

	_isi.add_child(UI.label("Misi Utama", 18))
	if gs.cerita_tamat:
		_isi.add_child(UI.label("Semua misi utama selesai. Kios sudah jadi milik sendiri!", 14, UI.WARNA_TEKS, true))
	for i in gs.cerita["bab"].size():
		var b: Dictionary = gs.cerita["bab"][i]
		var status: = "belum dimulai"
		if gs.cerita_tamat or i < gs.bab or (i == gs.bab and gs.misi_status in ["lunas", ""]):
			status = "selesai"
		elif i == gs.bab and gs.misi_status == "aktif":
			status = "sedang berjalan"
		elif i == gs.bab and gs.misi_status == "menunggu":
			status = "segera"
		var baris: = UI.panel(Color.WHITE, 8, 8)
		baris.modulate.a = 0.6 if status == "belum dimulai" else 1.0
		var h: = HBoxContainer.new()
		baris.add_child(h)

		var nama: = UI.label("Lv %d · %s" % [gs.level_bab(i), "????????" if status in ["belum dimulai", "segera"] else b["judul"]], 15)
		nama.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(nama)
		h.add_child(UI.label(status, 13, UI.WARNA_BERHASIL if status == "selesai" else UI.WARNA_REDUP))
		_isi.add_child(baris)




func _tampil_jalan_level() -> void :
	var gs: = GameState
	_isi.add_child(UI.label("Naik level membuka barang dagangan baru dan upgrade warung. Ini yang menunggu di tiap level:", 14, UI.WARNA_REDUP, true))
	for lv in range(1, gs.daftar_tingkat.size() + 1):
		_isi.add_child(_kartu_level(lv))

	var segera: = UI.panel(Color(0.95, 0.93, 0.9), 12, 10)
	segera.modulate.a = 0.75
	var ks: = VBoxContainer.new()
	segera.add_child(ks)
	var atas_s: = HBoxContainer.new()
	ks.add_child(atas_s)
	var judul_s: = UI.label("Level %d · Segera hadir" % (gs.daftar_tingkat.size() + 1), 16, UI.WARNA_TEKS)
	judul_s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	atas_s.add_child(judul_s)
	ks.add_child(UI.label("Barang, upgrade, dan cerita baru sedang disiapkan. Nantikan pembaruan berikutnya!", 13, UI.WARNA_REDUP, true))
	_isi.add_child(segera)

	_isi.add_child(UI.label("Barang dari cerita warga", 18))
	_isi.add_child(UI.label("Barang ini tidak terbuka dari level, tapi dengan menolong warga di mode jalan-jalan.", 13, UI.WARNA_REDUP, true))
	for ev in gs.data_event():
		var e: Dictionary = gs.data_event()[ev]
		var buka: Array = e.get("hasil", {}).get("tolong", {}).get("buka", [])
		if buka.is_empty() or not gs.cerita_tampil_di_daftar(ev):
			continue



		var dapat: bool = gs.hasil_event(ev) == "tolong" or buka.all( func(b): return gs.terbuka(String(b)))
		var p: = UI.panel(Color(0.93, 0.98, 0.92) if dapat else Color.WHITE, 10, 8)
		var k: = VBoxContainer.new()
		k.add_theme_constant_override("separation", 4)
		p.add_child(k)
		k.add_child(_baris_ikon_barang(buka))
		var npc: = String(e["tahap"][0]["npc"])
		var teks: = "✓ Sudah terbuka" if dapat else "Selesaikan cerita \"%s\" bersama %s" % [e["judul"], _nama_npc(npc)]
		k.add_child(UI.label(teks, 13, UI.WARNA_BERHASIL if dapat else UI.WARNA_TEKS, true))
		_isi.add_child(p)


func _kartu_level(lv: int) -> Control:
	var gs: = GameState
	var t: = gs.data_tingkat(lv - 1)
	var sekarang: = lv == gs.level()
	var lewat: = lv < gs.level()
	var p: = UI.panel(Color(1, 0.96, 0.85) if sekarang else Color.WHITE, 12, 10)
	p.modulate.a = 1.0 if lv <= gs.level() + 1 else 0.7
	var k: = VBoxContainer.new()
	k.add_theme_constant_override("separation", 5)
	p.add_child(k)
	var atas: = HBoxContainer.new()
	k.add_child(atas)
	var judul: = UI.label("Level %d · %s" % [lv, t["nama"]], 16, UI.WARNA_TEKS)
	judul.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	atas.add_child(judul)
	atas.add_child(UI.label("✓ tercapai" if lewat else ("sekarang" if sekarang else "terkunci"), 13, 
		UI.WARNA_BERHASIL if lewat else (WARNA if sekarang else UI.WARNA_REDUP)))
	var h: Dictionary = gs.hadiah_level(lv)
	if not (h["barang"] as Array).is_empty():
		k.add_child(UI.label("Barang awal:" if lv == 1 else "Barang baru:", 13, UI.WARNA_REDUP))
		k.add_child(_baris_ikon_barang(h["barang"]))
	if not (h["upgrade"] as Array).is_empty():
		k.add_child(UI.label("Upgrade terbuka:", 13, UI.WARNA_REDUP))
		k.add_child(_baris_ikon_upgrade(h["upgrade"]))
	k.add_child(UI.label("Sewa kios %s per minggu" % gs.format_rupiah(gs.sewa_per_minggu(lv - 1)), 13, UI.WARNA_REDUP))
	if not t.get("upgrade", []).is_empty():
		var beres: = gs.syarat_upgrade_beres(t)
		k.add_child(UI.label(("✓ " if beres else "Syarat naik level: ") + gs.teks_syarat_upgrade(t).replace("Upgrade: ", "beli ") + (" (pilih salah satu)" if (t["upgrade"] as Array).size() > 1 else ""), 
			13, UI.WARNA_BERHASIL if beres else UI.WARNA_TEKS, true))
	return p



func _baris_ikon_barang(daftar: Array) -> Control:
	var wadah: = HFlowContainer.new()
	wadah.add_theme_constant_override("h_separation", 6)
	wadah.add_theme_constant_override("v_separation", 4)
	for id in daftar:
		var b: = GameState.data_barang(String(id))
		wadah.add_child(_ikon_bernama(load("res://assets/barang/%s.png" % id), String(b.get("nama", id))))
	return wadah


func _baris_ikon_upgrade(daftar: Array) -> Control:
	var wadah: = HFlowContainer.new()
	wadah.add_theme_constant_override("h_separation", 6)
	wadah.add_theme_constant_override("v_separation", 4)
	for id in daftar:
		var u: = GameState.data_upgrade(String(id))
		var ikon: = GameState.ikon_upgrade(id)
		var kotak: = _ikon_bernama(load(ikon) if ResourceLoader.exists(ikon) else null, String(u.get("nama", id)))
		if GameState.punya_upgrade(String(id)):
			kotak.modulate = Color(0.75, 1.0, 0.75)
		wadah.add_child(kotak)
	return wadah


func _ikon_bernama(tekstur: Texture2D, nama: String) -> Control:
	var kolom: = VBoxContainer.new()
	kolom.add_theme_constant_override("separation", 0)
	kolom.custom_minimum_size.x = 64
	if tekstur != null:
		var ikon: = UI.ikon(tekstur, 40)
		ikon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		kolom.add_child(ikon)
	var l: = UI.label(nama, 10, UI.WARNA_REDUP)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size.x = 64
	kolom.add_child(l)
	return kolom



func _nama_npc(tipe: String) -> String:
	var warga: = GameState.daftar_warga()
	if warga.has(tipe):
		return String(warga[tipe])
	return {"haji_doni": "Haji Doni", "pak_rt": "Pak RT", "fariz": "Mas Fariz"}.get(tipe, tipe)
