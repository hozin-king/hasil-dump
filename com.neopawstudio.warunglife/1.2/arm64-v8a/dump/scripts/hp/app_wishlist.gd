extends VBoxContainer




const UI: = preload("res://scripts/hp/hp_ui.gd")
const KB: = preload("res://scripts/konfirmasi_bayar.gd")
const WARNA: = Color(0.9, 0.35, 0.5)



const DAFTAR: = {
	"rumah": ["Upgrade Rumah", "Rumah diperbaiki dan diperluas: kamar lebih lega, dinding dicat baru, perabot baru. Tidur lebih nyenyak: energi Pak Misran turun 15% lebih lambat.", Color(0.55, 0.36, 0.7), "res://assets/ikon/renovasi.svg", "res://assets/peta/area_kamar_baru.png"], 
	"motor": ["Upgrade Motor", "Motor baru untuk narik ojek: ambil order warga di aplikasi OjekKampung sore sampai malam sesudah warung tutup (Rp5-35 ribu per antaran + tip). Barang belanjaan juga datang lebih cepat: waktu tunggu kurir berkurang 40%.", Color(0.25, 0.55, 0.85), "res://assets/ikon/peta.svg", "res://assets/wishlist/motor.jpg"], 
	"hape": ["Upgrade Hape", "Ganti hape lama dengan hape mewah terbaru: seluruh tampilan HP ikut berganti (ikon, wallpaper, dock).", Color(0.4, 0.4, 0.45), "res://assets/ikon/chat.svg", "res://assets/ikon_hud/hp_iphone.png"], 
}

var hp: Control
var _isi: VBoxContainer


func _ready() -> void :
	add_theme_constant_override("separation", 0)
	add_child(UI.kepala("Wishlist", WARNA))
	var g: Array = UI.gulir(10)
	var tepi: = MarginContainer.new()
	tepi.size_flags_vertical = Control.SIZE_EXPAND_FILL
	for sisi in ["left", "right", "top", "bottom"]:
		tepi.add_theme_constant_override("margin_" + sisi, 10)
	tepi.add_child(g[0])
	add_child(tepi)
	_isi = g[1]


func tampil() -> void :
	var gs: = GameState
	for anak in _isi.get_children():
		anak.queue_free()
	_isi.add_child(UI.label("Impian Pak Misran. Menabung dulu, beli kalau uangnya cukup. Uang sekarang %s." % gs.format_rupiah(gs.uang), 14, UI.WARNA_REDUP, true))
	for id in DAFTAR:
		_isi.add_child(_kartu(id))


func _kartu(id: String) -> Control:
	var gs: = GameState
	var d: Array = DAFTAR[id]
	var harga: int = gs.HARGA_WISHLIST[id]
	var kartu: = UI.panel(Color(1, 0.97, 0.9), 12, 12)
	var k: = VBoxContainer.new()
	k.add_theme_constant_override("separation", 8)
	kartu.add_child(k)

	var bingkai: = UI.panel(Color(0.08, 0.08, 0.1), 10, 0)
	bingkai.clip_children = CanvasItem.CLIP_CHILDREN_AND_DRAW
	bingkai.custom_minimum_size = Vector2(0, 190)
	k.add_child(bingkai)
	var foto: = TextureRect.new()
	foto.texture = load(d[4])
	foto.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	foto.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED if id == "hape" else TextureRect.STRETCH_KEEP_ASPECT_COVERED
	foto.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bingkai.add_child(foto)
	var atas: = HBoxContainer.new()
	atas.add_theme_constant_override("separation", 10)
	k.add_child(atas)
	var judul: = UI.label(d[0], 22, UI.WARNA_TEKS, true)
	judul.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	judul.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	atas.add_child(judul)
	k.add_child(UI.label(d[1], 13, UI.WARNA_REDUP, true))
	k.add_child(UI.label("Harga: %s" % gs.format_rupiah(harga), 17, UI.WARNA_TEKS, true))

	if id == "motor" and gs.uji_ngojol():
		var uji: = Button.new()
		uji.text = "UJI: matel datang hari ini"
		uji.theme_type_variation = &"TombolKayu"
		uji.custom_minimum_size.y = 42
		uji.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		uji.add_theme_font_size_override("font_size", 15)
		uji.pressed.connect( func():
			gs.uji_matel_sekarang()
			tampil()
			_isi.add_child(UI.label("Buka warung: matel datang beberapa detik lagi (cicilan bulan ini jatuh tempo hari ini).", 14, Color(0.75, 0.2, 0.15), true)))
		k.add_child(uji)
	if gs.punya_wishlist(id):
		k.add_child(UI.label("✓ Sudah terbeli. Selamat, Pak Misran!", 15, UI.WARNA_BERHASIL, true))

		if id == "motor" and gs.motor_sisa_cicilan() > 0:
			var angsuran: = mini(int(gs.motor_cicil.get("angsuran", gs.motor_angsuran())), gs.motor_sisa_cicilan())
			k.add_child(UI.label("Cicilan ke-%d dari %d: %s, jatuh tempo %s. Sisa %s." % [int(gs.motor_cicil.get("ke", 1)), gs.MOTOR_TENOR, 
				gs.format_rupiah(angsuran), gs.nama_tanggal_hari(gs.motor_tempo()), gs.format_rupiah(gs.motor_sisa_cicilan())], 14, UI.WARNA_TEKS, true))
			k.add_child(UI.label("Telat bayar = motor langsung disita matel.", 13, Color(0.75, 0.2, 0.15), true))
			var baris: = HBoxContainer.new()
			baris.add_theme_constant_override("separation", 8)
			k.add_child(baris)
			for t in [["Bayar cicilan %s" % gs.format_rupiah(angsuran), angsuran, func(): gs.bayar_cicilan_motor(), "Bayar cicilan motor?"], 
					["Lunasi %s" % gs.format_rupiah(gs.motor_sisa_cicilan()), gs.motor_sisa_cicilan(), func(): gs.lunasi_motor(), "Lunasi cicilan motor?"]]:
				var b: = Button.new()
				b.text = t[0]
				b.theme_type_variation = &"TombolHijau" if gs.uang >= int(t[1]) else &"TombolKayu"
				b.disabled = gs.uang < int(t[1])
				b.custom_minimum_size.y = 44
				b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				b.add_theme_font_size_override("font_size", 15)
				var aksi: Callable = t[2]
				var jumlah_t: = int(t[1])
				var judul_t: = String(t[3])
				b.pressed.connect( func():
					if not await KB.tanya(self, judul_t, jumlah_t):
						return
					aksi.call()
					tampil())
				baris.add_child(b)
		return kartu
	var bar: = ProgressBar.new()
	bar.show_percentage = false
	bar.custom_minimum_size.y = 10
	bar.max_value = harga
	bar.value = clampi(gs.uang, 0, harga)
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.add_theme_stylebox_override("background", UI.kotak(Color(0.88, 0.85, 0.8), 5, 0))
	bar.add_theme_stylebox_override("fill", UI.kotak(d[2], 5, 0))
	k.add_child(bar)
	var alasan: = gs.alasan_tidak_bisa_wishlist(id)
	var tombol: = Button.new()
	tombol.text = "Beli sekarang" if alasan == "" else ("Terkunci" if gs.level() < int(gs.LEVEL_WISHLIST[id]) else "Belum cukup")
	tombol.theme_type_variation = &"TombolHijau" if alasan == "" else &"TombolKayu"
	tombol.disabled = alasan != ""
	tombol.custom_minimum_size.y = 48
	tombol.add_theme_font_size_override("font_size", 19)
	k.add_child(tombol)
	if alasan != "":
		k.add_child(UI.label(alasan, 13, UI.WARNA_REDUP, true))

	if id == "motor":
		var alasan_cicil: String = gs.alasan_tidak_bisa_cicil_motor()
		var cicil: = Button.new()
		cicil.text = "Cicil: uang muka %s + %dx %s/bulan" % [gs.format_rupiah(gs.motor_dp()), gs.MOTOR_TENOR, gs.format_rupiah(gs.motor_angsuran())]
		cicil.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		cicil.theme_type_variation = &"TombolHijau" if alasan_cicil == "" else &"TombolKayu"
		cicil.disabled = alasan_cicil != ""
		cicil.custom_minimum_size.y = 48
		cicil.add_theme_font_size_override("font_size", 16)
		k.add_child(cicil)

		k.add_child(UI.label("Cukup bayar uang muka %s, motor langsung dibawa pulang: diparkir di depan warung dan bisa dipakai ngojol hari itu juga. Sisanya dicicil %s tiap bulan." % [gs.format_rupiah(gs.motor_dp()), gs.format_rupiah(gs.motor_angsuran())], 13, UI.WARNA_TEKS, true))
		if alasan_cicil != "" and alasan_cicil != alasan:
			k.add_child(UI.label(alasan_cicil, 13, UI.WARNA_REDUP, true))
		cicil.pressed.connect( func():
			if gs.alasan_tidak_bisa_cicil_motor() == "" and not await KB.tanya(self, "Cicil motor?", gs.motor_dp(), 
					"Bayar uang muka sekarang, lalu %dx %s tiap bulan." % [gs.MOTOR_TENOR, gs.format_rupiah(gs.motor_angsuran())]):
				return
			if gs.cicil_motor() == "":
				var popup: = preload("res://scripts/popup_hadiah.gd").new()
				hp.get_parent().add_child(popup)
				popup.isi("%s Terbeli!" % d[0], "Motor sudah diparkir di depan warung dan bisa langsung dipakai ngojol. Cicilan %dx %s per bulan, jatuh tempo pertama %s. Telat bayar = motor disita matel!" % [gs.MOTOR_TENOR, gs.format_rupiah(gs.motor_angsuran()), gs.nama_tanggal_hari(gs.motor_tempo())], [])
			tampil())
	tombol.pressed.connect( func():
		if gs.alasan_tidak_bisa_wishlist(id) == "" and not await KB.tanya(self, "Beli %s?" % d[0], harga):
			return
		if gs.beli_wishlist(id) == "":
			var popup: = preload("res://scripts/popup_hadiah.gd").new()


			hp.get_parent().add_child(popup)
			popup.isi("%s Terbeli!" % d[0], String(d[1]), [])
		tampil())
	return kartu
