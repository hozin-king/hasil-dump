extends ColorRect





signal ditutup

const TEMA: = preload("res://ui/tema.tres")
var _pesan: Label
var _tombol_beli: Button


func _ready() -> void :
	theme = load("res://scripts/gaya_hud.gd").tema_jendela_emas()
	process_mode = Node.PROCESS_MODE_ALWAYS
	color = Color(0.03, 0.02, 0.01, 0.75)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 120
	var tengah: = CenterContainer.new()
	tengah.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(tengah)
	var kartu: = PanelContainer.new()
	kartu.add_theme_stylebox_override("panel", load("res://scripts/gaya_hud.gd").bingkai_emas())
	kartu.custom_minimum_size = Vector2(600, 0)
	tengah.add_child(kartu)
	var isi: = VBoxContainer.new()
	isi.add_theme_constant_override("separation", 12)
	kartu.add_child(isi)
	var judul: = Label.new()
	judul.text = "Main Tanpa Iklan"
	judul.theme_type_variation = &"LabelKepala"
	judul.add_theme_font_size_override("font_size", 32)
	judul.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	isi.add_child(judul)
	for baris in ["Semua iklan hilang, termasuk iklan saat naik level.", 
			"Semua hadiah iklan langsung didapat tanpa menonton: kerja sampingan tambahan, upah 2x, energi penuh, dan potongan harga upgrade.", 
			"Sekali beli, berlaku selamanya di akun Google Play-mu (juga setelah instal ulang)."]:
		var l: = Label.new()
		l.text = "• " + baris
		l.add_theme_font_size_override("font_size", 19)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size.x = 560
		isi.add_child(l)
	_tombol_beli = Button.new()
	_tombol_beli.theme_type_variation = &"TombolHijau"
	_tombol_beli.custom_minimum_size = Vector2(0, 70)
	_tombol_beli.add_theme_font_size_override("font_size", 26)
	_tombol_beli.pressed.connect( func():
		GameState.klik()
		GameState.beli_tanpa_iklan())
	isi.add_child(_tombol_beli)

	if OS.get_name() != "iOS":
		var tips: = Label.new()
		tips.text = "Tips: bayar pakai pulsa, e-wallet (GoPay/DANA/OVO/ShopeePay), atau kartu supaya langsung aktif. Kalau memilih QRIS, transfer bank, atau bayar di minimarket, selesaikan pembayarannya dulu sebelum batas waktu, kalau tidak Google membatalkannya otomatis."
		tips.add_theme_font_size_override("font_size", 16)
		tips.add_theme_color_override("font_color", Color(1.0, 0.85, 0.55))
		tips.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		tips.custom_minimum_size.x = 560
		isi.add_child(tips)
	var pulihkan: = Button.new()
	pulihkan.text = "Pulihkan pembelian"
	pulihkan.theme_type_variation = &"TombolKayu"
	pulihkan.custom_minimum_size = Vector2(0, 52)
	pulihkan.add_theme_font_size_override("font_size", 20)
	pulihkan.pressed.connect( func():
		GameState.klik()
		GameState.pulihkan_pembelian(true))
	isi.add_child(pulihkan)
	_pesan = Label.new()
	_pesan.add_theme_font_size_override("font_size", 17)
	_pesan.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_pesan.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_pesan.custom_minimum_size.x = 560
	isi.add_child(_pesan)
	var tutup: = Button.new()
	tutup.text = "Tutup"
	tutup.theme_type_variation = &"TombolKayu"
	tutup.custom_minimum_size = Vector2(0, 56)
	tutup.add_theme_font_size_override("font_size", 22)
	tutup.pressed.connect( func():
		ditutup.emit()
		queue_free())
	isi.add_child(tutup)
	GameState.pesan_toko.connect(_on_pesan)
	GameState.tanpa_iklan_berubah.connect(_on_berubah)
	_perbarui()


func _perbarui() -> void :
	if GameState.tanpa_iklan:
		_tombol_beli.text = "Tanpa Iklan sudah aktif"
		_tombol_beli.disabled = true
	else:
		_tombol_beli.text = "Beli Tanpa Iklan · %s" % GameState.harga_tanpa_iklan


func _on_pesan(teks: String) -> void :
	if is_instance_valid(_pesan):
		_pesan.text = teks


func _on_berubah(_aktif: bool) -> void :
	_perbarui()


func _exit_tree() -> void :
	if GameState.pesan_toko.is_connected(_on_pesan):
		GameState.pesan_toko.disconnect(_on_pesan)
	if GameState.tanpa_iklan_berubah.is_connected(_on_berubah):
		GameState.tanpa_iklan_berubah.disconnect(_on_berubah)
