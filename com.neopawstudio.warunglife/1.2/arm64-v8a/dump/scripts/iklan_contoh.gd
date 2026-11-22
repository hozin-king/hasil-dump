extends ColorRect




signal selesai(berhasil: bool)

const LAMA: = 5


var selingan: = false


func _ready() -> void :
	theme = load("res://scripts/gaya_hud.gd").tema_jendela()
	process_mode = Node.PROCESS_MODE_ALWAYS
	color = Color(0.05, 0.05, 0.08, 0.96)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 100
	var tengah: = CenterContainer.new()
	tengah.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(tengah)
	var kolom: = VBoxContainer.new()
	kolom.add_theme_constant_override("separation", 18)
	tengah.add_child(kolom)
	var judul: = Label.new()
	judul.text = "IKLAN ANTAR-LEVEL (contoh)" if selingan else "IKLAN (contoh)"
	judul.add_theme_font_size_override("font_size", 44)
	judul.add_theme_color_override("font_color", Color(1, 0.85, 0.3))
	judul.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	kolom.add_child(judul)
	var ket: = Label.new()
	ket.text = "Iklan sungguhan dipasang saat game dirilis.\n" + ("Terima kasih sudah mendukung Warung Life!" if selingan else "Selesaikan hitungan untuk mendapat hadiah.")
	ket.add_theme_font_size_override("font_size", 22)
	ket.add_theme_color_override("font_color", Color(0.9, 0.9, 0.95))
	ket.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	kolom.add_child(ket)
	var hitung: = Label.new()
	hitung.add_theme_font_size_override("font_size", 64)
	hitung.add_theme_color_override("font_color", Color.WHITE)
	hitung.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	kolom.add_child(hitung)
	var ambil: = Button.new()
	ambil.text = "Lanjut" if selingan else "Ambil hadiah"
	ambil.theme_type_variation = &"TombolHijau"
	ambil.custom_minimum_size = Vector2(320, 66)
	ambil.add_theme_font_size_override("font_size", 26)
	ambil.disabled = true
	ambil.pressed.connect( func(): _akhiri(true))
	kolom.add_child(ambil)
	var lewati: = Button.new()
	lewati.text = "Lewati (tanpa hadiah)"
	lewati.theme_type_variation = &"TombolKayu"
	lewati.custom_minimum_size = Vector2(320, 52)
	lewati.add_theme_font_size_override("font_size", 20)
	lewati.pressed.connect( func(): _akhiri(false))
	if not selingan:
		kolom.add_child(lewati)
	for i in range(LAMA, 0, -1):
		hitung.text = str(i)
		await GameState.get_tree().create_timer(1.0, true, false, true).timeout
	hitung.text = "✓"
	ambil.disabled = false


func _akhiri(berhasil: bool) -> void :
	selesai.emit(berhasil)
	queue_free()
