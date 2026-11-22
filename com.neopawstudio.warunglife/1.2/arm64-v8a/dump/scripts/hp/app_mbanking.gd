extends Control









const UI: = preload("res://scripts/hp/hp_ui.gd")
const KB: = preload("res://scripts/konfirmasi_bayar.gd")
const WARNA: = Color(0.04, 0.37, 0.69)
const EMAS: = Color(0.96, 0.72, 0.24)
const LOGO: = "res://assets/ikon/logo_warga_bank.svg"
const NAMA_BANK: = "Bank Warga Sejahtera"
const REK_SAYA: = "9021 4409 7731"


const REK_PENERIMA: = {
	"agus": "9021 7733 2210", 
	"juragan": "9021 1290 4470", 
	"rt": "9021 5566 9034", 
	"klinik": "9021 4488 3120", 
}
const MAKS_RIWAYAT: = 30

var hp: Control
var _label_saldo: Label
var _label_kartu: Label
var _bar: ProgressBar
var _label_status: Label
var _tombol_kirim: Button
var _riwayat: VBoxContainer
var _lembar: PanelContainer
var _label_penerima: Label
var _label_jumlah: Label
var _pesan_kirim: Label
var _isi_lembar: VBoxContainer
var _bukti: PanelContainer
var _label_bukti: Label
var _jumlah: = 0
var _label_layanan: Label
var _kartu_digital: PanelContainer
var _label_digital: Label
var _tombol_tarik: Button
var _tombol_tarik_nominal: Array = []
var _pesan_tarik: Label
var _label_sewa: Label
var _tombol_lunasi: Button
var _label_cicil: Label
var _baris_cicil: HBoxContainer
var _pesan_sewa: Label
var _label_infak: Label
var _pesan_infak: Label
var _tombol_infak: Array[Button] = []
var _kartu_ramadan: PanelContainer
var _tombol_zakat: Button
var _label_thr: Label
var _baris_thr: HBoxContainer
var _pesan_ramadan: Label


func _ready() -> void :
	var kolom: = VBoxContainer.new()
	kolom.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	kolom.add_theme_constant_override("separation", 0)
	add_child(kolom)
	var kepala: = UI.kepala("Warga Bank", WARNA)

	var logo: = UI.ikon(load(LOGO), 38)
	(kepala.get_child(0) as HBoxContainer).add_child(logo)
	(kepala.get_child(0) as HBoxContainer).move_child(logo, 0)
	kolom.add_child(kepala)
	var g: Array = UI.gulir(10)
	var tepi: = MarginContainer.new()
	tepi.size_flags_vertical = Control.SIZE_EXPAND_FILL
	for sisi in ["left", "right", "top", "bottom"]:
		tepi.add_theme_constant_override("margin_" + sisi, 8)
	tepi.add_child(g[0])
	kolom.add_child(tepi)
	var isi: VBoxContainer = g[1]
	_buat_kartu_saldo(isi)
	_buat_kartu_kiriman(isi)
	_buat_kartu_layanan(isi)
	var judul: = UI.label("Riwayat transaksi", 17)
	isi.add_child(judul)
	_riwayat = VBoxContainer.new()
	_riwayat.add_theme_constant_override("separation", 6)
	isi.add_child(_riwayat)
	_buat_lembar()
	_buat_bukti()
	GameState.data_berubah.connect(_perbarui)
	_perbarui()


func _buat_kartu_layanan(isi: VBoxContainer) -> void :

	_kartu_digital = UI.panel(Color(0.12, 0.42, 0.78), 14, 12)
	isi.add_child(_kartu_digital)
	var kolom_digital: = VBoxContainer.new()
	kolom_digital.add_theme_constant_override("separation", 6)
	_kartu_digital.add_child(kolom_digital)
	kolom_digital.add_child(UI.label("Saldo digital (QRIS)", 15, Color(0.85, 0.93, 1)))
	_label_digital = UI.label("", 26, Color.WHITE)
	kolom_digital.add_child(_label_digital)
	kolom_digital.add_child(UI.label("Dari pelanggan yang bayar pakai QRIS. Otomatis dipakai kalau uang di laci kurang saat belanja online.", 12, Color(0.85, 0.93, 1), true))

	kolom_digital.add_child(UI.label("Tarik ke laci:", 13, Color(0.85, 0.93, 1)))
	var baris_tarik: = HBoxContainer.new()
	baris_tarik.add_theme_constant_override("separation", 6)
	kolom_digital.add_child(baris_tarik)
	_tombol_tarik_nominal.clear()
	for n in GameState.PILIHAN_TARIK_DIGITAL + [0]:
		var b: = UI.tombol("Semua" if n == 0 else GameState.format_rupiah(n), Color(0.2, 0.62, 0.3), 15, 40)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.set_meta("nominal", n)
		b.pressed.connect( func():
			var jumlah: int = GameState.saldo_digital if n == 0 else n
			if n == 0 and not bool(b.get_meta("yakin", false)):
				b.set_meta("yakin", true)
				b.text = "Yakin %s?" % GameState.format_rupiah(jumlah)
				GameState.get_tree().create_timer(3.0).timeout.connect( func():
					if is_instance_valid(b):
						b.set_meta("yakin", false)
						b.text = "Semua")
				return
			if n == 0:
				b.set_meta("yakin", false)
				b.text = "Semua"
			var alasan: = GameState.tarik_saldo_digital(n)
			if alasan == "":
				GameState.bunyi("koin")
				_pesan_tarik.text = "%s dipindah ke laci." % GameState.format_rupiah(jumlah)
				_pesan_tarik.add_theme_color_override("font_color", Color(0.75, 1, 0.8))
			else:
				_pesan_tarik.text = alasan
				_pesan_tarik.add_theme_color_override("font_color", Color(1, 0.8, 0.75)))
		baris_tarik.add_child(b)
		_tombol_tarik_nominal.append(b)
	_tombol_tarik = _tombol_tarik_nominal[-1]
	_pesan_tarik = UI.label("", 13, Color(0.75, 1, 0.8), true)
	kolom_digital.add_child(_pesan_tarik)

	var kartu_sewa: = UI.panel(Color.WHITE, 10, 10)
	isi.add_child(kartu_sewa)
	var kolom_sewa: = VBoxContainer.new()
	kolom_sewa.add_theme_constant_override("separation", 6)
	kartu_sewa.add_child(kolom_sewa)
	kolom_sewa.add_child(UI.label("Sewa kios", 17))
	_label_sewa = UI.label("", 14, UI.WARNA_TEKS, true)
	kolom_sewa.add_child(_label_sewa)

	_label_cicil = UI.label("Cicil sewa minggu ini:", 14, UI.WARNA_REDUP, true)
	kolom_sewa.add_child(_label_cicil)
	_baris_cicil = HBoxContainer.new()
	_baris_cicil.add_theme_constant_override("separation", 6)
	kolom_sewa.add_child(_baris_cicil)
	for jumlah in GameState.PILIHAN_CICIL_SEWA + [-1]:
		var b: = UI.tombol("Sisanya" if jumlah < 0 else GameState.format_rupiah(jumlah), Color(0.2, 0.45, 0.75), 15, 40)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.pressed.connect( func():
			var n: int = GameState.sisa_cicil_sewa() if jumlah < 0 else jumlah

			var keluar: = mini(n, GameState.sisa_cicil_sewa())
			if not GameState.kios_milik and keluar > 0 and GameState.uang + GameState.saldo_digital >= keluar:
				if not await KB.tanya(self, "Cicil sewa kios?", keluar):
					return
			var alasan: = GameState.cicil_sewa(n)
			var sisa_teks: = "Sisa sewa minggu ini %s." % GameState.format_rupiah(GameState.sisa_sewa_minggu_ini())
			if GameState.sewa_hari_ini_selesai():
				sisa_teks = "Ini untuk sewa MINGGU DEPAN, sisa %s." % GameState.format_rupiah(GameState.sisa_sewa_minggu_ini())
			if GameState.tunggakan_sewa > 0:
				sisa_teks = "Sisa tunggakan %s, lalu sewa minggu ini %s." % [GameState.format_rupiah(GameState.tunggakan_sewa), GameState.format_rupiah(GameState.sisa_sewa_minggu_ini())]
			_pesan_sewa.text = ("Cicilan diterima. " + sisa_teks) if alasan == "" else alasan
			_pesan_sewa.add_theme_color_override("font_color", UI.WARNA_BERHASIL if alasan == "" else UI.WARNA_GAGAL)
			if alasan == "":
				GameState.bunyi("koin"))
		_baris_cicil.add_child(b)
	_tombol_lunasi = UI.tombol("Lunasi tunggakan sekarang", Color(0.8, 0.3, 0.2), 16, 40)
	_tombol_lunasi.pressed.connect(_lunasi)
	kolom_sewa.add_child(_tombol_lunasi)
	_pesan_sewa = UI.label("", 14, UI.WARNA_BERHASIL, true)
	kolom_sewa.add_child(_pesan_sewa)

	var kartu_infak: = UI.panel(Color(0.93, 0.98, 0.93), 10, 10)
	isi.add_child(kartu_infak)
	var kolom_infak: = VBoxContainer.new()
	kolom_infak.add_theme_constant_override("separation", 6)
	kartu_infak.add_child(kolom_infak)
	kolom_infak.add_child(UI.label("Infak ke masjid", 17))
	_label_infak = UI.label("", 13, UI.WARNA_REDUP, true)
	kolom_infak.add_child(_label_infak)
	var baris_infak: = HBoxContainer.new()
	baris_infak.add_theme_constant_override("separation", 6)
	kolom_infak.add_child(baris_infak)
	for jumlah in GameState.PILIHAN_INFAK:
		var b: = UI.tombol(GameState.format_rupiah(jumlah), Color(0.2, 0.55, 0.3), 15, 40)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.pressed.connect( func():
			if GameState.boleh_infak() and GameState.uang >= jumlah and not await KB.tanya(self, "Infak ke masjid?", jumlah, "", "Ya, infak"):
				return
			var alasan: = GameState.infak(jumlah)
			_pesan_infak.text = "Infak %s diterima masjid. Reputasi warung naik." % GameState.format_rupiah(jumlah) if alasan == "" else alasan
			_pesan_infak.add_theme_color_override("font_color", UI.WARNA_BERHASIL if alasan == "" else UI.WARNA_GAGAL)
			if alasan == "":
				GameState.bunyi("koin"))
		baris_infak.add_child(b)
		_tombol_infak.append(b)
	_pesan_infak = UI.label("", 13, UI.WARNA_BERHASIL, true)
	kolom_infak.add_child(_pesan_infak)

	_kartu_ramadan = UI.panel(Color(0.98, 0.95, 0.85), 10, 10)
	isi.add_child(_kartu_ramadan)
	var kolom_r: = VBoxContainer.new()
	kolom_r.add_theme_constant_override("separation", 6)
	_kartu_ramadan.add_child(kolom_r)
	kolom_r.add_child(UI.label("Menjelang Lebaran", 17))
	_tombol_zakat = UI.tombol("Bayar zakat fitrah %s" % GameState.format_rupiah(GameState.ZAKAT_FITRAH), Color(0.2, 0.55, 0.3), 15, 40)
	_tombol_zakat.pressed.connect( func():
		if GameState.boleh_zakat() and GameState.uang >= GameState.ZAKAT_FITRAH and not await KB.tanya(self, "Bayar zakat fitrah?", GameState.ZAKAT_FITRAH):
			return
		var alasan: = GameState.bayar_zakat()
		_pesan_ramadan.text = "Zakat fitrah sudah dibayar. Semoga berkah." if alasan == "" else alasan
		if alasan == "":
			GameState.bunyi("koin"))
	kolom_r.add_child(_tombol_zakat)
	_label_thr = UI.label("THR untuk Agus (sukarela). Agus bisa membantu warung lebih lama saat mudik.", 13, UI.WARNA_REDUP, true)
	kolom_r.add_child(_label_thr)
	_baris_thr = HBoxContainer.new()
	_baris_thr.add_theme_constant_override("separation", 6)
	kolom_r.add_child(_baris_thr)
	for jumlah in GameState.PILIHAN_THR:
		var b: = UI.tombol(GameState.format_rupiah(jumlah), Color(0.75, 0.45, 0.1), 15, 40)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.pressed.connect( func():
			if GameState.boleh_thr() and GameState.uang >= jumlah and not await KB.tanya(self, "Kirim THR untuk Agus?", jumlah, "", "Ya, kirim"):
				return
			var alasan: = GameState.kirim_thr(jumlah)
			_pesan_ramadan.text = "THR %s terkirim ke Agus." % GameState.format_rupiah(jumlah) if alasan == "" else alasan
			if alasan == "":
				GameState.bunyi("koin"))
		_baris_thr.add_child(b)
	_pesan_ramadan = UI.label("", 13, UI.WARNA_BERHASIL, true)
	kolom_r.add_child(_pesan_ramadan)


func _buat_kartu_saldo(isi: VBoxContainer) -> void :
	var kartu: = UI.panel(WARNA, 16, 14)
	var gaya: = kartu.get_theme_stylebox("panel") as StyleBoxFlat
	gaya.bg_color = Color(0.03, 0.25, 0.52)
	gaya.border_color = EMAS
	gaya.set_border_width_all(2)
	isi.add_child(kartu)
	var k: = VBoxContainer.new()
	k.add_theme_constant_override("separation", 2)
	kartu.add_child(k)
	k.add_child(UI.label("%s · Tabungan" % NAMA_BANK, 14, Color(1, 0.96, 0.82)))
	k.add_child(UI.label("Saldo", 14, Color(0.82, 0.9, 1.0)))
	_label_saldo = UI.label("", 34, Color.WHITE)
	k.add_child(_label_saldo)
	k.add_child(UI.label("%s · a.n. MISRAN" % REK_SAYA, 13, Color(0.82, 0.9, 1.0)))
	_label_layanan = UI.label("", 13, Color(0.82, 0.9, 1.0), true)
	k.add_child(_label_layanan)


func _buat_kartu_kiriman(isi: VBoxContainer) -> void :
	var kartu: = UI.panel(Color.WHITE, 12, 12)
	isi.add_child(kartu)
	var k: = VBoxContainer.new()
	k.add_theme_constant_override("separation", 6)
	kartu.add_child(k)
	k.add_child(UI.label("Kirim uang", 18))
	_label_kartu = UI.label("", 15, UI.WARNA_TEKS, true)
	k.add_child(_label_kartu)
	_bar = ProgressBar.new()
	_bar.custom_minimum_size = Vector2(0, 14)
	_bar.show_percentage = false
	k.add_child(_bar)
	_label_status = UI.label("", 13, UI.WARNA_REDUP, true)
	k.add_child(_label_status)
	_tombol_kirim = UI.tombol("Kirim uang", WARNA, 18, 46)


	_tombol_kirim.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_tombol_kirim.pressed.connect(_buka_lembar)
	k.add_child(_tombol_kirim)




func _buat_lembar() -> void :

	_lembar = UI.panel(Color(0.12, 0.11, 0.1), 16, 14)
	var gaya: = _lembar.get_theme_stylebox("panel") as StyleBoxFlat
	gaya.bg_color = Color(0.12, 0.11, 0.1, 1.0)
	gaya.border_color = EMAS
	gaya.border_width_top = 2
	_lembar.mouse_filter = Control.MOUSE_FILTER_STOP
	_lembar.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE, Control.PRESET_MODE_MINSIZE)
	_lembar.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_lembar.hide()
	add_child(_lembar)
	_isi_lembar = VBoxContainer.new()
	_isi_lembar.add_theme_constant_override("separation", 8)
	_lembar.add_child(_isi_lembar)


	var judul: = UI.label("Transfer ke sesama %s" % NAMA_BANK, 17, UI.WARNA_TEKS, true)
	judul.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_isi_lembar.add_child(judul)
	_label_penerima = UI.label("", 15, Color(0.85, 0.92, 1.0), true)
	_label_penerima.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_isi_lembar.add_child(_label_penerima)
	_label_jumlah = UI.label("", 34, UI.GH.HIJAU_UANG)
	_label_jumlah.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_isi_lembar.add_child(_label_jumlah)
	_pesan_kirim = UI.label("", 14, UI.WARNA_GAGAL, true)
	_pesan_kirim.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_isi_lembar.add_child(_pesan_kirim)
	var bawah: = HBoxContainer.new()
	bawah.add_theme_constant_override("separation", 8)
	_isi_lembar.add_child(bawah)
	var batal: = UI.tombol("Batal", Color(1, 1, 1, 0.14), 18, 46)
	batal.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	batal.pressed.connect(_lembar.hide)
	bawah.add_child(batal)
	var kirim: = UI.tombol("Kirim", WARNA, 18, 46)
	kirim.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	kirim.pressed.connect(_kirim)
	bawah.add_child(kirim)


func _buka_lembar() -> void :

	_jumlah = GameState.kekurangan_kiriman()
	_pesan_kirim.text = ""
	_bukti.hide()
	_perbarui_lembar()
	_lembar.show()


func _rekening_penerima() -> String:
	return String(REK_PENERIMA.get(GameState.kontak_bab(), "9021 3000 2000"))


func _perbarui_lembar() -> void :
	_label_penerima.text = "%s · %s\na.n. %s" % [NAMA_BANK, _rekening_penerima(), GameState.nama_penerima().to_upper()]
	_label_jumlah.text = GameState.format_rupiah(_jumlah)
	if GameState.uang < _jumlah:
		_pesan_kirim.add_theme_color_override("font_color", UI.WARNA_GAGAL)
		_pesan_kirim.text = "Saldo baru %s, kurang %s lagi. Kiriman harus penuh, tidak bisa dicicil." % [
			GameState.format_rupiah(GameState.uang), GameState.format_rupiah(_jumlah - GameState.uang)]
		return
	var awas: = GameState.peringatan_kirim(_jumlah)
	_pesan_kirim.add_theme_color_override("font_color", UI.WARNA_GAGAL if awas.begins_with("Awas") else UI.WARNA_TEKS)
	_pesan_kirim.text = awas if awas != "" else "Saldo: %s. Kirim sekaligus untuk melunasi kebutuhan %s." % [GameState.format_rupiah(GameState.uang), GameState.nama_penerima()]


func _kirim() -> void :
	var jumlah: = _jumlah

	var kontak: = GameState.kontak_bab()
	var nama: = GameState.nama_penerima()
	var rekening: = _rekening_penerima()
	var bab_ini: = GameState.data_bab()
	var nomor_bab: = GameState.bab
	if GameState.kirim_akan_berhasil(jumlah):
		if not await KB.tanya(self, "Kirim uang ke %s?" % nama, mini(jumlah, GameState.kekurangan_kiriman()), "", "Ya, kirim"):
			return

		if nama != GameState.nama_penerima() or nomor_bab != GameState.bab:
			return
	var alasan: = GameState.kirim_uang(jumlah)
	if alasan != "":
		_pesan_kirim.text = alasan
		GameState.bunyi("salah")
		return
	_lembar.hide()
	GameState.bunyi("koin")
	_tampilkan_bukti(jumlah, nama, rekening)
	GameState.tambah_chat("Bapak", "Transfer %s" % GameState.format_rupiah(jumlah), false, "transfer", kontak)

	await GameState.get_tree().create_timer(1.8).timeout
	var lunas: = GameState.misi_status == "lunas" or GameState.bab != nomor_bab or GameState.cerita_tamat
	if lunas:
		var balasan: = String(bab_ini.get("balasan_lunas", ""))
		if balasan == "":
			balasan = "Alhamdulillah, Pak, sudah masuk! Uang buat %s sudah cukup semua. Makasih banyak ya, Pak. Agus janji belajar lebih rajin." % String(bab_ini["kebutuhan"])
		GameState.tambah_chat(nama, balasan, false, "teks", kontak)
	else:
		GameState.tambah_chat(nama, GameState.cerita["balasan_kirim"].pick_random(), false, "teks", kontak)
	if hp == null or hp.warung == null:
		return
	if not GameState.dialog_tertunda.is_empty() and hp.warung.has_node("UI/Akar/CeritaUI"):

		hp.tutup()
		if hp.warung.has_node("UI/Akar/CeritaUI"):
			hp.warung.get_node("UI/Akar/CeritaUI").tampilkan_dialog_tertunda()
	elif lunas and hp.warung.has_method("tampilkan_dialog_cerita"):

		hp.tutup()
		hp.warung.tampilkan_dialog_cerita()




func _buat_bukti() -> void :
	_bukti = UI.panel(Color(0.97, 0.95, 0.88), 16, 16)
	var gaya: = _bukti.get_theme_stylebox("panel") as StyleBoxFlat
	gaya.bg_color = Color(0.97, 0.95, 0.88, 1.0)
	gaya.border_color = WARNA
	gaya.set_border_width_all(3)
	_bukti.mouse_filter = Control.MOUSE_FILTER_STOP
	_bukti.set_anchors_and_offsets_preset(Control.PRESET_CENTER, Control.PRESET_MODE_MINSIZE)
	_bukti.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_bukti.grow_vertical = Control.GROW_DIRECTION_BOTH
	_bukti.custom_minimum_size = Vector2(320, 0)
	_bukti.hide()
	add_child(_bukti)
	var k: = VBoxContainer.new()
	k.add_theme_constant_override("separation", 8)
	_bukti.add_child(k)
	var logo: = UI.ikon(load(LOGO), 56)
	logo.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	k.add_child(logo)
	var judul: = UI.label("Transfer berhasil", 22, WARNA.darkened(0.2))
	judul.add_theme_color_override("font_color", Color(0.03, 0.27, 0.55))
	judul.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	k.add_child(judul)
	_label_bukti = UI.label("", 15, Color(0.2, 0.17, 0.12), true)
	_label_bukti.add_theme_color_override("font_color", Color(0.2, 0.17, 0.12))
	_label_bukti.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	k.add_child(_label_bukti)
	var tutup: = UI.tombol("Selesai", WARNA, 18, 44)
	tutup.pressed.connect(_bukti.hide)
	k.add_child(tutup)


func _tampilkan_bukti(jumlah: int, nama: String, rekening: String) -> void :
	_label_bukti.text = "%s\nke %s\n%s · %s\n\n%s, %s\nNo. ref LK%05d" % [
		GameState.format_rupiah(jumlah), nama, NAMA_BANK, rekening, 
		GameState.teks_tanggal(GameState.hari), GameState.teks_jam(), (GameState.hari * 7919 + jumlah / 1000) % 100000]
	_bukti.show()




func tampil() -> void :
	_lembar.hide()
	_bukti.hide()
	_perbarui()



func kembali() -> bool:
	if _bukti.visible:
		_bukti.hide()
		return true
	if _lembar.visible:
		_lembar.hide()
		return true
	return false


func _perbarui() -> void :
	if not is_inside_tree():
		return
	_label_saldo.text = GameState.format_rupiah(GameState.uang)
	var nama: = GameState.nama_penerima()
	var aktif: = GameState.misi_status == "aktif" and not GameState.cerita_tamat
	_tombol_kirim.disabled = not aktif
	_bar.visible = aktif
	if GameState.cerita_tamat:
		_label_kartu.text = "Semua permintaan Agus selesai. Cerita Agus tamat!"
		_label_status.text = ""
		_tombol_kirim.text = "Tidak ada kiriman"
	elif aktif:
		var butuh: = String(GameState.data_bab()["kebutuhan"])
		_label_kartu.text = ("%s · butuh %s" if GameState.kontak_bab() == "agus" else "%s · perlu %s") % [nama, butuh]
		_bar.max_value = maxf(GameState.target_bab, 1)
		_bar.value = GameState.kiriman_bab
		_label_status.text = "Terkirim %s dari %s · batas %s (%d hari lagi)" % [
			GameState.format_rupiah(GameState.kiriman_bab), GameState.format_rupiah(GameState.target_bab), 
			GameState.teks_tanggal(GameState.batas_hari), GameState.sisa_hari()]
		_tombol_kirim.text = "Kirim %s ke %s" % [GameState.format_rupiah(GameState.kekurangan_kiriman()), nama]
	elif GameState.misi_status == "lunas":
		_label_kartu.text = "Kiriman untuk %s sudah lunas." % nama
		_label_status.text = "Selesaikan tugas Level Warung %d lainnya." % GameState.level()
		_tombol_kirim.text = "Sudah lunas"
	else:
		_label_kartu.text = "%s sedang tidak minta kiriman." % nama
		_label_status.text = "Fokus ke tugas Level Warung %d." % GameState.level()
		_tombol_kirim.text = "Belum ada permintaan"
	if _lembar.visible:
		_perbarui_lembar()
	var gs: = GameState
	_label_layanan.text = "Saldo layanan (e-wallet & paket data): %s" % gs.format_rupiah(gs.saldo_layanan)

	_kartu_digital.visible = gs.punya_upgrade("qris") or gs.saldo_digital > 0
	_label_digital.text = gs.format_rupiah(gs.saldo_digital)
	for b in _tombol_tarik_nominal:
		b.disabled = gs.saldo_digital <= 0 or int(b.get_meta("nominal", 0)) > gs.saldo_digital
	var tempo: = gs.hari_jatuh_tempo_sewa()
	_label_sewa.text = "Pemilik: %s\nSewa %s per minggu, ditagih %s pukul 18.00 (%s)." % [
		gs.nama_pemilik_kios(), gs.format_rupiah(gs.sewa_per_minggu()), "hari ini" if tempo == gs.hari else "Minggu", gs.teks_tanggal(tempo)]
	if gs.sewa_hari_ini_selesai() and gs.tunggakan_sewa <= 0:
		_label_sewa.text += "\nSewa minggu ini SUDAH DIBAYAR hari ini. Cicilan dari sekarang untuk sewa minggu depan."
	if gs.sewa_cicil > 0 and gs.sisa_sewa_minggu_ini() <= 0:
		_label_sewa.text += "\nSewa minggu ini sudah lunas dicicil." if not gs.sewa_hari_ini_selesai() else "\nSewa minggu depan sudah lunas dicicil."
	elif gs.sewa_cicil > 0:
		_label_sewa.text += "\nSudah dicicil %s, sisa %s." % [gs.format_rupiah(gs.sewa_cicil), gs.format_rupiah(gs.sisa_sewa_minggu_ini())]
	if gs.utang_dokter > 0:
		_label_sewa.text += "\nUtang dokter %s, dipotong saat warung tutup." % gs.format_rupiah(gs.utang_dokter)
	if gs.kios_milik:
		_label_sewa.text = "Kios sudah menjadi milik sendiri (dibeli dari %s). Tidak ada sewa lagi." % gs.nama_pemilik_kios()
	if gs.tunggakan_sewa > 0:
		_label_sewa.text += "\nTunggakan: %s (tanpa denda). Sudah menunggak %d dari %d Minggu: tagihan ke-%d harus lunas, kalau tidak kios diambil kembali." % [
			gs.format_rupiah(gs.tunggakan_sewa), gs.minggu_tunggak, gs.MINGGU_DIUSIR, gs.MINGGU_DIUSIR]
	_label_infak.text = "Sekali sehari. Warga menghargai warung yang peduli masjid: reputasi naik sedikit." if gs.boleh_infak() else "Hari ini sudah berinfak. Jazakallah khair."
	for b in _tombol_infak:
		b.disabled = not gs.boleh_infak()
	_tombol_lunasi.visible = gs.tunggakan_sewa > 0
	var bisa_cicil: bool = not gs.kios_milik and gs.sisa_cicil_sewa() > 0
	_label_cicil.text = "Cicil tunggakan dulu, lalu sewa minggu ini:" if gs.tunggakan_sewa > 0 else ("Cicil sewa minggu depan (boleh dari sekarang):" if gs.sewa_hari_ini_selesai() else "Cicil sewa minggu ini:")
	_label_cicil.visible = bisa_cicil
	_baris_cicil.visible = bisa_cicil
	_tombol_zakat.visible = gs.boleh_zakat()
	_label_thr.visible = gs.boleh_thr()
	_baris_thr.visible = gs.boleh_thr()
	_kartu_ramadan.visible = gs.boleh_zakat() or gs.boleh_thr() or _pesan_ramadan.text != ""
	_isi_riwayat()


func _isi_riwayat() -> void :
	for anak in _riwayat.get_children():
		anak.queue_free()
	if GameState.transaksi.is_empty():
		_riwayat.add_child(UI.label("Belum ada transaksi.", 14, UI.WARNA_REDUP))
		return

	var daftar: = GameState.transaksi.duplicate()
	daftar.reverse()
	for t in daftar.slice(0, MAKS_RIWAYAT):
		var kotak: = UI.panel(Color.WHITE, 8, 8)
		_riwayat.add_child(kotak)
		var h: = HBoxContainer.new()
		h.add_theme_constant_override("separation", 8)
		kotak.add_child(h)
		var kiri: = VBoxContainer.new()
		kiri.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		kiri.add_theme_constant_override("separation", 0)
		h.add_child(kiri)
		var teks: = UI.label(String(t["teks"]), 14)
		teks.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		teks.custom_minimum_size.x = 60
		kiri.add_child(teks)
		kiri.add_child(UI.label("%s · %s" % [GameState.teks_tanggal(int(t["hari"]), true), String(t["jam"])], 12, UI.WARNA_REDUP))
		var jumlah: = int(t["jumlah"])
		var angka: = UI.label("%s%s" % ["+" if jumlah > 0 else "-", GameState.format_rupiah(absi(jumlah))], 15, UI.WARNA_BERHASIL if jumlah > 0 else UI.WARNA_GAGAL)
		angka.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		h.add_child(angka)


func _lunasi() -> void :
	var n: = GameState.tunggakan_sewa
	if n > 0 and GameState.uang + GameState.saldo_digital >= n:
		if not await KB.tanya(self, "Lunasi tunggakan sewa?", n, "", "Ya, lunasi"):
			return
	var alasan: = GameState.bayar_tunggakan_sewa()
	_pesan_sewa.text = "Tunggakan lunas." if alasan == "" else alasan
	_pesan_sewa.add_theme_color_override("font_color", UI.WARNA_BERHASIL if alasan == "" else UI.WARNA_GAGAL)
