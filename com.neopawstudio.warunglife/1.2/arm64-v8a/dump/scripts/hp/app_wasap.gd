extends Control





const UI: = preload("res://scripts/hp/hp_ui.gd")
const WARNA: = Color(0.18, 0.62, 0.35)
const WARNA_SAYA: = Color(0.84, 0.95, 0.8)
const WARNA_GELEMBUNG_SAYA: = Color(0.0, 0.4, 0.3)
const WARNA_GELEMBUNG_LAWAN: = Color(0.12, 0.5, 0.3)
const WARNA_GELEMBUNG_TRANSFER: = Color(0.16, 0.62, 0.34)


const AVATAR: = {
	"agus": [Color(0.3, 0.55, 0.8), "A"], 
	"juragan": [Color(0.55, 0.35, 0.2), "H"], 
	"rt": [Color(0.35, 0.6, 0.35), "RT"], 
	"sales": [Color(0.85, 0.45, 0.15), "S"], 
	"agen": [Color(0.15, 0.55, 0.65), "Rp"], 
	"klinik": [Color(0.8, 0.3, 0.35), "K"], 
}

var hp: Control
var _daftar: VBoxContainer
var _ruang: VBoxContainer
var _baris_kontak: = {}
var _kontak: = "agus"
var _judul_ruang: Label
var _foto_ruang: Control
var _kartu_misi: PanelContainer
var _label_misi: Label
var _bar_bawah: PanelContainer
var _gulir_chat: ScrollContainer
var _isi_chat: VBoxContainer
var _jumlah_chat_tampil: = -1
var _tanda_chat_tampil: = ""
var _bar_tagih: PanelContainer
var _label_tagih: Label
var _tombol_halus: Button
var _tombol_tegas: Button
var _label_ketik: Label


func _ready() -> void :
	_buat_daftar()
	_buat_ruang()
	GameState.data_berubah.connect(_perbarui)
	GameState.sedang_mengetik.connect( func(k: String, aktif: bool):
		if k == _kontak and is_instance_valid(_label_ketik):
			_label_ketik.visible = aktif)




func _buat_daftar() -> void :
	_daftar = VBoxContainer.new()
	_daftar.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_daftar.add_theme_constant_override("separation", 1)
	add_child(_daftar)
	_daftar.add_child(UI.kepala("Wasap", WARNA))
	_tambah_kontak_baru()



func _tambah_kontak_baru() -> void :
	for kontak in GameState.daftar_kontak():
		if not _baris_kontak.has(kontak):
			_daftar.add_child(_buat_baris_kontak(kontak))


func _buat_baris_kontak(kontak: String) -> Control:
	var baris: = Button.new()
	baris.custom_minimum_size.y = 72
	baris.mouse_filter = Control.MOUSE_FILTER_PASS
	for keadaan in ["normal", "hover", "pressed", "focus"]:
		var s: = UI.kotak(Color.WHITE if keadaan != "pressed" else Color(0.92, 0.92, 0.9), 0, 10)
		if keadaan == "focus":
			s.draw_center = false
		baris.add_theme_stylebox_override(keadaan, s)
	baris.pressed.connect(buka_chat.bind(kontak))
	var isi: = HBoxContainer.new()
	isi.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	isi.offset_left = 12
	isi.offset_right = -12
	isi.add_theme_constant_override("separation", 10)
	isi.mouse_filter = Control.MOUSE_FILTER_IGNORE
	baris.add_child(isi)
	isi.add_child(_avatar(kontak))
	var teks: = VBoxContainer.new()
	teks.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	teks.alignment = BoxContainer.ALIGNMENT_CENTER
	teks.mouse_filter = Control.MOUSE_FILTER_IGNORE
	isi.add_child(teks)
	teks.add_child(UI.label(GameState.nama_kontak(kontak), 17))
	var pratinjau: = UI.label("", 14, UI.WARNA_REDUP)
	pratinjau.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	pratinjau.custom_minimum_size.x = 60
	teks.add_child(pratinjau)
	var kanan: = VBoxContainer.new()
	kanan.alignment = BoxContainer.ALIGNMENT_CENTER
	kanan.mouse_filter = Control.MOUSE_FILTER_IGNORE
	isi.add_child(kanan)
	var jam: = UI.label("", 13, UI.WARNA_REDUP)
	kanan.add_child(jam)
	var lencana: = UI.lencana()
	lencana.size_flags_horizontal = Control.SIZE_SHRINK_END
	kanan.add_child(lencana)
	_baris_kontak[kontak] = {"pratinjau": pratinjau, "jam": jam, "lencana": lencana}
	return baris


func _avatar(kontak: String) -> Control:

	var foto: = "res://assets/potret/%s.png" % (("warga_" + kontak.substr(6)) if kontak.begins_with("utang:") else kontak)
	if ResourceLoader.exists(foto):
		var r: = UI.ikon(load(foto), 46)
		r.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		return r
	var data: Array = AVATAR.get(kontak, [Color(0.45, 0.5, 0.6), GameState.nama_kontak(kontak).left(1).to_upper()])
	var p: = UI.panel(data[0], 24, 0)
	p.custom_minimum_size = Vector2(46, 46)
	p.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var l: = UI.label(data[1], 20, Color.WHITE)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	p.add_child(l)
	return p




func _buat_ruang() -> void :
	_ruang = VBoxContainer.new()
	_ruang.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_ruang.add_theme_constant_override("separation", 0)
	_ruang.hide()
	add_child(_ruang)
	var kepala: = UI.kepala("", WARNA, kembali)
	_ruang.add_child(kepala)
	_judul_ruang = GameState.cari_anak(kepala, "Label")[0]

	_foto_ruang = Control.new()
	_foto_ruang.custom_minimum_size = Vector2(40, 40)
	_foto_ruang.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_judul_ruang.get_parent().add_child(_foto_ruang)
	_judul_ruang.get_parent().move_child(_foto_ruang, _judul_ruang.get_index())

	_kartu_misi = UI.panel(Color(1, 0.97, 0.88), 0, 10)
	_ruang.add_child(_kartu_misi)
	_label_misi = UI.label("", 15, UI.WARNA_TEKS, true)
	_kartu_misi.add_child(_label_misi)
	var g: Array = UI.gulir(6)
	_gulir_chat = g[0]
	_isi_chat = g[1]
	var tepi: = MarginContainer.new()
	tepi.size_flags_vertical = Control.SIZE_EXPAND_FILL
	for sisi in ["left", "right", "top", "bottom"]:
		tepi.add_theme_constant_override("margin_" + sisi, 8)
	tepi.add_child(_gulir_chat)
	_ruang.add_child(tepi)

	_bar_bawah = UI.panel(Color(0.93, 0.93, 0.9), 0, 8)
	_ruang.add_child(_bar_bawah)
	var tombol_kirim: = UI.tombol("Kirim uang lewat Warga Bank", WARNA, 18, 46)
	tombol_kirim.name = "TombolKirim"
	tombol_kirim.pressed.connect(_buka_bank)
	_bar_bawah.add_child(tombol_kirim)

	_label_ketik = UI.label("sedang mengetik...", 13, Color(0.2, 0.55, 0.3))
	_label_ketik.hide()
	_ruang.add_child(_label_ketik)
	_bar_tagih = UI.panel(Color(0.93, 0.93, 0.9), 0, 8)
	_ruang.add_child(_bar_tagih)
	var kolom_tagih: = VBoxContainer.new()
	kolom_tagih.add_theme_constant_override("separation", 6)
	_bar_tagih.add_child(kolom_tagih)
	_label_tagih = UI.label("", 14, UI.WARNA_REDUP, true)
	_label_tagih.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	kolom_tagih.add_child(_label_tagih)
	var baris_tagih: = HBoxContainer.new()
	baris_tagih.add_theme_constant_override("separation", 8)
	kolom_tagih.add_child(baris_tagih)
	_tombol_halus = UI.tombol("Tagih halus", WARNA, 17, 46)
	_tombol_halus.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_tombol_halus.pressed.connect(_tagih.bind(false))
	baris_tagih.add_child(_tombol_halus)
	_tombol_tegas = UI.tombol("Tagih tegas", Color(0.75, 0.35, 0.15), 17, 46)
	_tombol_tegas.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_tombol_tegas.pressed.connect(_tagih.bind(true))
	baris_tagih.add_child(_tombol_tegas)


func tampil() -> void :
	_tambah_kontak_baru()
	_daftar.show()
	_ruang.hide()
	_perbarui()


func buka_chat_agus() -> void :

	buka_chat(GameState.kontak_bab() if GameState.misi_status in ["aktif", "lunas"] and not GameState.cerita_tamat else "agus")


func buka_chat(kontak: String) -> void :
	_kontak = kontak
	_daftar.hide()
	_ruang.show()
	_tambah_kontak_baru()
	_judul_ruang.text = GameState.nama_kontak(kontak)
	_label_ketik.hide()
	for anak in _foto_ruang.get_children():
		anak.queue_free()
	var foto: = _avatar(kontak)
	foto.custom_minimum_size = Vector2(40, 40)
	foto.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_foto_ruang.add_child(foto)
	_kartu_misi.visible = _ada_kartu(kontak)
	_bar_bawah.visible = _ada_kartu(kontak)
	_bar_tagih.visible = kontak.begins_with("utang:")
	GameState.baca_chat(kontak)
	_jumlah_chat_tampil = -1
	_tanda_chat_tampil = ""
	_perbarui()



func kembali() -> bool:
	if _ruang.visible:
		_ruang.hide()
		_daftar.show()
		_perbarui()
		return true
	return false


func _perbarui() -> void :
	if not is_inside_tree():
		return

	for kontak in _baris_kontak:
		var b: Dictionary = _baris_kontak[kontak]
		var pesan: = GameState.pesan_chat(kontak)
		if pesan.is_empty():
			b["pratinjau"].text = "Belum ada pesan"
			b["jam"].text = ""
		else:
			var akhir: Dictionary = pesan[-1]
			var pengirim: = "Kamu: " if akhir["dari"] == "Bapak" else ("%s: " % akhir["dari"] if kontak == "rt" else "")
			b["pratinjau"].text = pengirim + _satu_baris(String(akhir["teks"]))
			b["jam"].text = GameState.teks_tanggal(int(akhir["hari"]), true) if int(akhir["hari"]) != GameState.hari else String(akhir["jam"])
		var ingat_kirim: bool = kontak == GameState.kontak_bab() and GameState.uang_cukup_kirim()
		UI.atur_lencana(b["lencana"], GameState.belum_dibaca(kontak) + (1 if ingat_kirim else 0))


		if ingat_kirim and GameState.belum_dibaca(kontak) == 0:
			b["pratinjau"].text = "Uang sudah cukup, ketuk untuk kirim"

		b["pratinjau"].get_parent().get_parent().get_parent().visible = not kontak in ["agen", "klinik"] or not pesan.is_empty()
	_urutkan_daftar()
	if not _ruang.visible:
		return
	if GameState.belum_dibaca(_kontak) > 0:
		GameState.baca_chat(_kontak)
	if _bar_tagih.visible:
		_perbarui_tagih()
	if _ada_kartu(_kontak):
		var punya_bab: = _kontak == GameState.kontak_bab() and not GameState.cerita_tamat
		var nama: = GameState.nama_penerima() if punya_bab else "Agus"
		var bab_ini: = GameState.data_bab()
		_bar_bawah.get_node("TombolKirim").disabled = not (punya_bab and GameState.misi_status == "aktif")
		if GameState.cerita_tamat:
			_label_misi.text = "Semua permintaan Agus selesai. Cerita Agus tamat!" if _kontak == "agus" else "Urusan ini sudah selesai."
		elif punya_bab and GameState.misi_status == "aktif":
			var butuh: = "Agus butuh %s" % bab_ini["kebutuhan"] if _kontak == "agus" else "Perlu %s" % bab_ini["kebutuhan"]
			_label_misi.text = "MISI UTAMA · Level Warung %d · %s\nTerkirim %s dari %s · batas %s (%d hari lagi)" % [
				GameState.level(), butuh, GameState.format_rupiah(GameState.kiriman_bab), 
				GameState.format_rupiah(GameState.target_bab), GameState.teks_tanggal(GameState.batas_hari), GameState.sisa_hari()]
		elif punya_bab and GameState.misi_status == "lunas":
			if String(bab_ini.get("jenis", "kirim")) == "hadiah":
				_label_misi.text = "%s sudah mengirim uang untuk Bapak. Selesaikan tugas Level Warung %d lainnya." % [nama, GameState.level()]
			else:
				_label_misi.text = "Kiriman untuk %s sudah lunas. Selesaikan tugas Level Warung %d lainnya." % [nama, GameState.level()]
		else:
			_label_misi.text = "%s sedang tidak minta kiriman. Fokus ke tugas Level Warung %d." % [nama, GameState.level()]

	var pesan_ruang: = GameState.pesan_chat(_kontak)

	var tanda: = "%d|%s" % [pesan_ruang.size(), str(pesan_ruang[-1]) if not pesan_ruang.is_empty() else ""]
	if _tanda_chat_tampil == tanda:
		return
	_tanda_chat_tampil = tanda
	_jumlah_chat_tampil = pesan_ruang.size()
	for anak in _isi_chat.get_children():
		anak.queue_free()
	var hari_lalu: = -1
	for pesan in pesan_ruang:
		if int(pesan["hari"]) != hari_lalu:
			hari_lalu = int(pesan["hari"])
			var tgl: = UI.label("%s, %s" % [GameState.nama_hari_ke(hari_lalu), GameState.teks_tanggal(hari_lalu)], 13, UI.WARNA_REDUP)
			tgl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			_isi_chat.add_child(tgl)
		_isi_chat.add_child(_gelembung(pesan))
	_gulir_ke_bawah.call_deferred()


func _gelembung(pesan: Dictionary) -> Control:

	if pesan.get("jenis", "teks") == "sistem":
		var tengah: = HBoxContainer.new()
		tengah.alignment = BoxContainer.ALIGNMENT_CENTER
		tengah.mouse_filter = Control.MOUSE_FILTER_PASS
		var info: = UI.panel(Color(0.85, 0.85, 0.85), 10, 8)
		var gaya_info: = info.get_theme_stylebox("panel") as StyleBoxFlat
		gaya_info.bg_color = Color(0.3, 0.3, 0.32, 0.95)
		var teks_info: = UI.label(String(pesan["teks"]), 14, Color(1, 1, 1, 0.9), true)
		teks_info.custom_minimum_size.x = 240
		teks_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		info.add_child(teks_info)
		tengah.add_child(info)
		return tengah
	var saya: bool = pesan["dari"] == "Bapak"
	var baris: = HBoxContainer.new()
	baris.alignment = BoxContainer.ALIGNMENT_END if saya else BoxContainer.ALIGNMENT_BEGIN
	baris.mouse_filter = Control.MOUSE_FILTER_PASS
	var transfer: bool = pesan.get("jenis", "teks") == "transfer"


	var kotak: = UI.panel(Color.WHITE, 12, 9)
	kotak.custom_minimum_size.x = 120
	var gaya_kotak: = kotak.get_theme_stylebox("panel") as StyleBoxFlat
	gaya_kotak.bg_color = WARNA_GELEMBUNG_SAYA if saya else WARNA_GELEMBUNG_LAWAN
	if transfer:
		gaya_kotak.bg_color = WARNA_GELEMBUNG_TRANSFER
		gaya_kotak.border_color = Color(1, 0.85, 0.3)
		gaya_kotak.set_border_width_all(2)
	baris.add_child(kotak)
	var kolom: = VBoxContainer.new()
	kolom.add_theme_constant_override("separation", 2)
	kotak.add_child(kolom)

	if _kontak == "rt" and not saya:
		kolom.add_child(UI.label(String(pesan["dari"]), 13, Color(1, 0.88, 0.45)))

	var panjang: = String(pesan["teks"]).length() > 26
	var teks: = UI.label(String(pesan["teks"]), 16, UI.WARNA_TEKS, panjang)
	if panjang:
		teks.custom_minimum_size.x = 250
	kolom.add_child(teks)
	var jam: = UI.label(String(pesan["jam"]), 11, Color(1, 1, 1, 0.75))
	jam.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	kolom.add_child(jam)
	return baris




func _urutkan_daftar() -> void :
	var baris: Array = []
	var urut: = 0
	for kontak in _baris_kontak:
		var b: Dictionary = _baris_kontak[kontak]
		var simpul: Control = b["pratinjau"].get_parent().get_parent().get_parent()
		var pesan: = GameState.pesan_chat(kontak)
		var waktu: = -1
		if not pesan.is_empty():
			var akhir: Dictionary = pesan[-1]
			var jm: = String(akhir.get("jam", "00.00")).split(".")
			waktu = int(akhir["hari"]) * 10000 + (int(jm[0]) * 60 + int(jm[1]) if jm.size() == 2 else 0)
		baris.append([waktu, urut, simpul])
		urut += 1
	baris.sort_custom( func(a, b): return a[0] > b[0] if a[0] != b[0] else a[1] < b[1])
	var awal: = -1
	for x in baris:
		var simpul: Control = x[2]
		if simpul.get_parent() == _daftar:
			awal = simpul.get_index() if awal < 0 else mini(awal, simpul.get_index())
	if awal < 0:
		return
	for i in baris.size():
		var simpul: Control = baris[i][2]
		if simpul.get_parent() == _daftar and simpul.get_index() != awal + i:
			_daftar.move_child(simpul, awal + i)





func _gulir_ke_bawah() -> void :
	var bar: = _gulir_chat.get_v_scroll_bar()
	var tempel: = func(): _gulir_chat.scroll_vertical = int(bar.max_value)
	if not bar.changed.is_connected(tempel):
		bar.changed.connect(tempel)

	for i in 3:
		if not is_inside_tree():
			return
		await get_tree().process_frame
		tempel.call()
	if not is_inside_tree():
		return
	await GameState.get_tree().create_timer(0.6).timeout
	tempel.call()
	if bar.changed.is_connected(tempel):
		bar.changed.disconnect(tempel)




func _perbarui_tagih() -> void :
	var i: = GameState.utang_kontak(_kontak)
	var bisa: = i >= 0 and GameState.boleh_tagih(GameState.hutang[i])

	_tombol_halus.disabled = false
	_tombol_tegas.disabled = false
	_tombol_halus.set_meta("bisa", bisa)
	if i < 0:
		_label_tagih.text = "Tidak ada utang yang belum dibayar."
	else:
		var h: Dictionary = GameState.hutang[i]
		if bool(h.get("datang_tagih", false)):
			_label_tagih.text = GameState.tk("Utang %s · mau datang bayar ke warung %s.") % [GameState.format_rupiah(int(h["jumlah"])), GameState.teks_hari_datang(int(h["tempo"]))]
		elif not GameState.utang_telat(h):
			_label_tagih.text = GameState.tk("Utang %s · janji bayar %s.") % [GameState.format_rupiah(int(h["jumlah"])), GameState.teks_tanggal(int(h["tempo"]), true)]
		elif not bisa:
			_label_tagih.text = GameState.tk("Utang %s · sudah ditagih hari ini. Coba lagi besok.") % GameState.format_rupiah(int(h["jumlah"]))
		else:
			_label_tagih.text = GameState.tk("Utang %s · telat %d hari. Halus: keakraban aman. Tegas: lebih sering berhasil, tapi bisa kesal.") % [GameState.format_rupiah(int(h["jumlah"])), GameState.hari_telat(h)]


func _tagih(tegas: bool) -> void :
	if not bool(_tombol_halus.get_meta("bisa", false)):

		GameState.bunyi("salah")
		_label_tagih.modulate = Color(1, 0.6, 0.5)
		var tw: = _label_tagih.create_tween()
		tw.tween_property(_label_tagih, "modulate", Color.WHITE, 0.8)
		return
	GameState.klik()
	GameState.tagih_lewat_chat(GameState.utang_kontak(_kontak), tegas)





func _buka_bank() -> void :
	hp.buka_aplikasi("mbanking")



func _ada_kartu(kontak: String) -> bool:
	return kontak == "agus" or (kontak == GameState.kontak_bab() and GameState.misi_status in ["aktif", "lunas"])



func _satu_baris(teks: String) -> String:
	var bagian: Array = []
	for b in teks.split("\n"):
		var s: = b.replace("•", "").strip_edges()
		if s != "":
			bagian.append(s)
	return " ".join(bagian)
