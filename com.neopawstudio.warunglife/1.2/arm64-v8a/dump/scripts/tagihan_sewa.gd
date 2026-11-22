extends CanvasLayer






const GH: = preload("res://scripts/gaya_hud.gd")
const KB: = preload("res://scripts/konfirmasi_bayar.gd")

var adegan: Node
var _pesan: Label


func _ready() -> void :
	layer = 110
	process_mode = Node.PROCESS_MODE_ALWAYS
	_jeda(true)
	var gelap: = ColorRect.new()
	gelap.color = Color(0.03, 0.02, 0.01, 0.6)
	gelap.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(gelap)
	var tengah: = CenterContainer.new()
	tengah.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	gelap.add_child(tengah)
	var panel: = PanelContainer.new()
	panel.custom_minimum_size = Vector2(600, 0)
	tengah.add_child(panel)
	var isi: = VBoxContainer.new()
	isi.add_theme_constant_override("separation", 14)
	panel.add_child(isi)
	var judul: = Label.new()
	judul.text = "PAK HAJI RASYID MENAGIH SEWA"
	GH.gaya_jendela(panel, judul)
	isi.add_child(judul)
	var gs: = GameState
	var teks: = "Assalamualaikum, Pak Misran. Hari ini Minggu, waktunya bayar sewa kios minggu ini: %s." % gs.format_rupiah(gs.sewa_per_minggu())
	if gs.sewa_cicil > 0 and gs.sisa_sewa_minggu_ini() <= 0:
		teks += " Sewa minggu ini sudah lunas dicicil, terima kasih."
	elif gs.sewa_cicil > 0:
		teks += " Sudah dicicil %s, tinggal %s." % [gs.format_rupiah(gs.sewa_cicil), gs.format_rupiah(gs.sisa_sewa_minggu_ini())]
	if gs.tunggakan_sewa > 0:
		teks += " Ditambah tunggakan %s, jadi totalnya %s." % [gs.format_rupiah(gs.tunggakan_sewa), gs.format_rupiah(gs.tagihan_sewa())]
	var ket: = Label.new()
	ket.text = teks + "\nUang di laci: %s." % gs.format_rupiah(gs.uang)
	if gs.saldo_digital > 0:
		ket.text += "\nSaldo QRIS: %s (dipakai kalau uang laci kurang)." % gs.format_rupiah(gs.saldo_digital)
	ket.add_theme_font_size_override("font_size", 20)
	ket.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ket.custom_minimum_size.x = 560
	isi.add_child(ket)
	var terakhir: bool = gs.minggu_tunggak >= gs.MINGGU_DIUSIR - 1
	if terakhir:
		var awas: = Label.new()
		awas.text = "Ini tagihan ketiga. Sudah %d Minggu menunggak, tidak bisa ditunda lagi: lunasi sekarang, atau kios diambil kembali (warung tamat)." % gs.minggu_tunggak
		awas.add_theme_font_size_override("font_size", 18)
		awas.add_theme_color_override("font_color", Color(1, 0.5, 0.45))
		awas.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		awas.custom_minimum_size.x = 560
		isi.add_child(awas)
	_pesan = Label.new()
	_pesan.add_theme_font_size_override("font_size", 17)
	_pesan.add_theme_color_override("font_color", Color(1, 0.5, 0.45))
	_pesan.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_pesan.custom_minimum_size.x = 560
	isi.add_child(_pesan)
	var bayar: = Button.new()
	bayar.text = "Bayar sekarang (%s)" % gs.format_rupiah(gs.tagihan_sewa())
	bayar.theme_type_variation = &"TombolHijau"
	bayar.custom_minimum_size.y = 64
	bayar.add_theme_font_size_override("font_size", 24)

	bayar.disabled = gs.uang + gs.saldo_digital < gs.tagihan_sewa()
	if bayar.disabled:
		_pesan.text = "Uang di laci dan saldo QRIS belum cukup untuk membayar sekarang."
	bayar.pressed.connect( func():
		if GameState.sewa_hari_ini_selesai():
			return
		if not await KB.tanya(self, "Bayar sewa kios minggu ini?", GameState.tagihan_sewa()):
			return
		if GameState.sewa_hari_ini_selesai():
			return
		var alasan: = GameState.bayar_sewa_sekarang()
		if alasan != "":
			_pesan.text = alasan
			return
		GameState.bunyi("koin")
		_tutup("Sewa kios minggu ini sudah dibayar. Terima kasih, Pak Misran!"))
	isi.add_child(bayar)
	var nanti: = Button.new()

	nanti.text = "Tidak sanggup, serahkan kios" if terakhir else "Bayar nanti (tanpa denda)"
	nanti.theme_type_variation = &"TombolMerah" if terakhir else &"TombolKayu"
	nanti.custom_minimum_size.y = 58
	nanti.add_theme_font_size_override("font_size", 21)
	nanti.pressed.connect( func():
		if GameState.sewa_hari_ini_selesai():
			return

		if terakhir and not await KB.tanya(self, "Serahkan kios ke Pak Haji Rasyid?", 0, "Warung tidak bisa dipakai lagi.", "Ya, serahkan", true):
			return
		if GameState.sewa_hari_ini_selesai():
			return
		GameState.klik()
		GameState.tunda_sewa()
		_tutup("Kios diambil kembali oleh Pak Haji Rasyid." if terakhir else "Sewa dicatat dulu tanpa denda. Minggu depan ditagih lagi; bisa dicicil atau dilunasi lewat Warga Bank."))
	isi.add_child(nanti)
	panel.scale = Vector2(0.9, 0.9)
	panel.pivot_offset = panel.custom_minimum_size / 2.0
	create_tween().tween_property(panel, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	GameState.bunyi("notif")


func _tutup(pesan: String) -> void :
	_jeda(false)
	if adegan != null and adegan.has_method("tampilkan_pesan"):
		adegan.tampilkan_pesan(pesan, 4.0)
	queue_free()



func _jeda(nyala: bool) -> void :
	if adegan == null:
		return
	if "dialog_aktif" in adegan:
		adegan.dialog_aktif = nyala
	elif "sibuk" in adegan:
		adegan.sibuk = nyala
