extends RefCounted








static func isi(wadah: VBoxContainer) -> void :
	var dalam: VBoxContainer = wadah.get_node_or_null("IsiBukuHutang")
	if dalam == null:
		dalam = VBoxContainer.new()
		dalam.name = "IsiBukuHutang"
		dalam.add_theme_constant_override("separation", 10)
		wadah.add_child(dalam)
	for anak in dalam.get_children():
		dalam.remove_child(anak)
		anak.queue_free()
	_isi_dalam(dalam)


static func _isi_dalam(wadah: VBoxContainer) -> void :
	var belum: = GameState.hutang_aktif()
	var selesai: Array = GameState.hutang.filter( func(h): return String(h["status"]) != "belum")
	selesai.reverse()
	var semua: Array = belum + selesai.slice(0, 15)
	if semua.is_empty():
		_teks(wadah, "Belum ada catatan. Kadang pembeli minta ngutang saat membayar; kalau dikasih, catatannya muncul di sini.")
		return
	var total_belum: = 0
	for h in belum:
		total_belum += int(h["jumlah"])
	_teks(wadah, "Belum dibayar: %d orang, total %s." % [belum.size(), GameState.format_rupiah(total_belum)])


	var telat: = belum.filter( func(h): return GameState.utang_telat(h)).size()
	if telat > 0:
		_teks(wadah, "%d utang sudah lewat janji. Tekan Tagih setiap hari, kalau dibiarkan utangnya dianggap diikhlaskan." % telat)


	var gulir: ScrollContainer = load("res://scripts/hp/gulir_sentuh.gd").new()
	gulir.custom_minimum_size = Vector2(660, mini(semua.size() + 1, 6) * TINGGI_BARIS + KERTAS_ATAS + KERTAS_BAWAH)
	gulir.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	wadah.add_child(gulir)
	var kertas: = PanelContainer.new()
	kertas.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var gk: = StyleBoxFlat.new()
	gk.bg_color = WARNA_KERTAS
	gk.set_corner_radius_all(6)
	gk.content_margin_left = MARGIN_KIRI
	gk.content_margin_right = 12
	gk.content_margin_top = KERTAS_ATAS
	gk.content_margin_bottom = KERTAS_BAWAH
	kertas.add_theme_stylebox_override("panel", gk)
	kertas.mouse_filter = Control.MOUSE_FILTER_PASS
	gulir.add_child(kertas)
	var lembar: = VBoxContainer.new()
	lembar.add_theme_constant_override("separation", 0)
	lembar.mouse_filter = Control.MOUSE_FILTER_PASS
	kertas.add_child(lembar)
	kertas.draw.connect( func(): _gambar_kertas(kertas, semua.size() + 1))
	var lebar: = [140, 112, 78, 182, 96]
	var kepala: = HBoxContainer.new()
	kepala.add_theme_constant_override("separation", 0)
	kepala.custom_minimum_size.y = TINGGI_BARIS
	for i in 5:
		kepala.add_child(_tulisan(["Nama", "Jumlah", "Tgl", "Keterangan", ""][i], lebar[i], WARNA_JUDUL, false, 24))
	lembar.add_child(kepala)
	for h in semua:
		var status: = String(h["status"])
		var warna: = WARNA_TINTA if status == "belum" else (WARNA_LUNAS if status == "lunas" else WARNA_PUDAR)
		var ket: = "Janji bayar %s" % GameState.teks_tanggal(int(h["tempo"]), true)
		if status == "belum" and bool(h.get("datang_tagih", false)):
			ket = "Mau datang bayar"
		elif status == "belum" and GameState.utang_telat(h):
			warna = WARNA_TELAT
			ket = ("Telat %d hari · ditagih" if int(h.get("tagih_hari", -99)) == GameState.hari else "Telat %d hari!") % GameState.hari_telat(h)
		if status == "lunas":
			ket = "Lunas %s ✓" % GameState.teks_tanggal(int(h["hari_selesai"]), true)
		elif status == "pindah":
			ket = "Pindah rumah, hilang"
		elif status != "belum":
			ket = "Diikhlaskan"
		var isi_sel: = [String(h["nama"]), GameState.format_rupiah(int(h["jumlah"])), GameState.teks_tanggal(int(h["hari"]), true), ket]
		var baris: = HBoxContainer.new()
		baris.add_theme_constant_override("separation", 0)
		baris.custom_minimum_size.y = TINGGI_BARIS
		for i in 4:
			baris.add_child(_tulisan(isi_sel[i], lebar[i], warna, status == "lunas" and i < 3, 26 if i < 2 else 23))
		baris.add_child(_sel_aksi(h, lebar[4], wadah))
		lembar.add_child(baris)



const TINGGI_BARIS: = 46.0
const KERTAS_ATAS: = 6.0
const KERTAS_BAWAH: = 10.0
const MARGIN_KIRI: = 46.0
const WARNA_KERTAS: = Color(0.99, 0.965, 0.89)
const WARNA_GARIS: = Color(0.55, 0.7, 0.9, 0.75)
const WARNA_MARGIN: = Color(0.88, 0.35, 0.35, 0.8)
const WARNA_TINTA: = Color(0.13, 0.22, 0.52)
const WARNA_JUDUL: = Color(0.1, 0.1, 0.15)
const WARNA_TELAT: = Color(0.78, 0.13, 0.12)
const WARNA_LUNAS: = Color(0.25, 0.48, 0.24)
const WARNA_PUDAR: = Color(0.55, 0.52, 0.48)
const FONT_TANGAN: = preload("res://assets/font/PatrickHand.ttf")


static func _gambar_kertas(k: Control, jumlah_baris: int) -> void :
	var w: = k.size.x
	var y: = KERTAS_ATAS
	for i in jumlah_baris:
		y += TINGGI_BARIS
		k.draw_line(Vector2(6, y - 3), Vector2(w - 6, y - 3), WARNA_GARIS, 1.5, true)
		if i == 0:
			k.draw_line(Vector2(6, y), Vector2(w - 6, y), WARNA_GARIS, 1.5, true)
	k.draw_line(Vector2(MARGIN_KIRI - 8, 0), Vector2(MARGIN_KIRI - 8, k.size.y), WARNA_MARGIN, 2.0, true)
	var lubang: = KERTAS_ATAS + TINGGI_BARIS * 0.5
	while lubang < k.size.y:
		k.draw_circle(Vector2(17, lubang), 7.0, Color(0.16, 0.12, 0.08, 0.85))
		k.draw_circle(Vector2(18, lubang + 1.5), 7.0, Color(0, 0, 0, 0.15))
		lubang += TINGGI_BARIS * 2.0


static func _tulisan(teks: String, lebar: float, warna: Color, coret: bool, ukuran: int) -> Control:
	var r: = RichTextLabel.new()
	r.bbcode_enabled = true
	r.fit_content = true
	r.scroll_active = false
	r.autowrap_mode = TextServer.AUTOWRAP_OFF
	r.clip_contents = true
	r.custom_minimum_size = Vector2(lebar, 0)
	r.size_flags_vertical = Control.SIZE_SHRINK_END
	r.mouse_filter = Control.MOUSE_FILTER_PASS
	r.add_theme_font_override("normal_font", FONT_TANGAN)
	r.add_theme_font_size_override("normal_font_size", ukuran)
	r.add_theme_color_override("default_color", warna)
	r.text = ("[s]%s[/s]" % GameState.tk(teks)) if coret else GameState.tk(teks)
	return r


static func _teks(wadah: VBoxContainer, teks: String) -> void :
	var l: = Label.new()
	l.text = teks
	l.add_theme_font_size_override("font_size", 20)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size.x = 560
	wadah.add_child(l)



static func _sel_aksi(h: Dictionary, lebar: float, wadah: VBoxContainer) -> Control:
	var kotak: = CenterContainer.new()
	kotak.custom_minimum_size = Vector2(lebar, TINGGI_BARIS)
	kotak.mouse_filter = Control.MOUSE_FILTER_PASS
	if GameState.boleh_tagih(h):


		var b: = Button.new()
		b.text = "Tagih!"
		b.add_theme_font_override("font", FONT_TANGAN)
		b.add_theme_font_size_override("font_size", 25)
		for nama in ["font_color", "font_hover_color", "font_focus_color", "font_hover_pressed_color"]:
			b.add_theme_color_override(nama, WARNA_TELAT)
		b.add_theme_color_override("font_pressed_color", Color(0.55, 0.06, 0.06))
		for k in [["normal", 0.0], ["hover", 0.08], ["focus", 0.0], ["pressed", 0.18], ["hover_pressed", 0.18]]:
			var g: = StyleBoxFlat.new()
			g.bg_color = Color(WARNA_TELAT, k[1])
			g.draw_center = true
			g.set_border_width_all(2)
			g.border_color = Color(WARNA_TELAT, 0.85)
			g.set_corner_radius_all(14)
			g.corner_detail = 6
			g.content_margin_left = 12
			g.content_margin_right = 12
			g.content_margin_top = 0
			g.content_margin_bottom = 2
			g.anti_aliasing = true
			b.add_theme_stylebox_override(k[0], g)
		b.custom_minimum_size = Vector2(0, 36)

		var pegangan: = Control.new()
		pegangan.mouse_filter = Control.MOUSE_FILTER_PASS
		pegangan.add_child(b)
		b.rotation_degrees = -4.0
		b.resized.connect( func():
			b.pivot_offset = b.size * 0.5
			pegangan.custom_minimum_size = b.size)
		var i: int = GameState.hutang.find(h)
		b.pressed.connect( func():
			GameState.klik()
			if not _buka_wasap_tagih(i, wadah):
				buka_tagih(i, wadah))
		kotak.add_child(pegangan)
	return kotak




static func _buka_wasap_tagih(i: int, wadah: VBoxContainer) -> bool:
	var adegan: = wadah.get_tree().current_scene
	if adegan == null or adegan.get("hp") == null:
		return false
	var kontak: = GameState.kontak_utang(i)
	var luar: = wadah.get_parent()
	if luar != null:
		for b in luar.get_children():
			if b is Button and (b as Button).text == "Tutup":
				(b as Button).pressed.emit()
				break
	adegan.hp.buka("wasap")
	var app = adegan.hp.aplikasi("wasap")
	if app != null:
		app.buka_chat(kontak)
	return true



static func buka_tagih(i: int, wadah: VBoxContainer) -> CanvasLayer:
	var h: Dictionary = GameState.hutang[i]
	var lapis: = CanvasLayer.new()
	lapis.layer = 120
	lapis.process_mode = Node.PROCESS_MODE_ALWAYS
	wadah.get_tree().root.add_child(lapis)
	var gelap: = ColorRect.new()
	gelap.color = Color(0, 0, 0, 0.55)
	gelap.set_anchors_preset(Control.PRESET_FULL_RECT)
	gelap.mouse_filter = Control.MOUSE_FILTER_STOP
	gelap.theme = load("res://scripts/gaya_hud.gd").tema_jendela_emas()
	lapis.add_child(gelap)
	var tengah: = CenterContainer.new()
	tengah.set_anchors_preset(Control.PRESET_FULL_RECT)
	gelap.add_child(tengah)

	var kartu: PanelContainer = load("res://scripts/gaya_hud.gd").panel_emas(Vector4(30, 24, 30, 24))
	kartu.custom_minimum_size = Vector2(600, 0)
	tengah.add_child(kartu)
	var isi_k: = VBoxContainer.new()
	isi_k.add_theme_constant_override("separation", 14)
	kartu.add_child(isi_k)
	var judul: = Label.new()
	judul.text = GameState.tk("Tagih utang %s") % String(h["nama"])
	judul.theme_type_variation = &"LabelKepala"
	judul.add_theme_font_size_override("font_size", 28)
	judul.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	isi_k.add_child(judul)
	var ket: = Label.new()
	ket.text = GameState.tk("Utang %s, telat %d hari. Pak Misran mengirim pesan lewat Wasap atau titip ke tetangga.") % [GameState.format_rupiah(int(h["jumlah"])), GameState.hari_telat(h)]
	ket.add_theme_font_size_override("font_size", 20)
	ket.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ket.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ket.custom_minimum_size.x = 560
	isi_k.add_child(ket)
	var baris: = HBoxContainer.new()
	baris.add_theme_constant_override("separation", 12)
	isi_k.add_child(baris)
	var saran: = Label.new()
	saran.text = "Halus: keakraban aman. Tegas: lebih sering berhasil, tapi warga bisa kesal."
	saran.add_theme_font_size_override("font_size", 17)
	saran.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	saran.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	saran.custom_minimum_size.x = 560
	for p in [["Halus", false], ["Tegas", true]]:
		var b: = Button.new()
		b.text = String(p[0])
		b.theme_type_variation = &"TombolHijau"
		b.custom_minimum_size = Vector2(0, 60)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.add_theme_font_size_override("font_size", 22)
		var tegas: bool = p[1]
		b.pressed.connect( func():
			GameState.klik()
			var hasil: Dictionary = GameState.tagih_hutang(i, tegas)
			for c in baris.get_children():
				c.queue_free()
			saran.hide()
			var lanjut: String = (GameState.tk("Ia akan datang ke warung %s.") % GameState.teks_hari_datang(int(hasil.get("hari_datang", GameState.hari + 1)))) if hasil.get("berhasil", false) else GameState.tk("Coba tagih lagi besok.")
			ket.text = "\"%s\"\n\n%s" % [GameState.tk(String(hasil.get("balasan", ""))), lanjut]
			GameState.bunyi("notif"))
		baris.add_child(b)
	isi_k.add_child(saran)
	var b_tutup: = Button.new()
	b_tutup.text = "Tutup"
	b_tutup.theme_type_variation = &"TombolKayu"
	b_tutup.custom_minimum_size = Vector2(0, 54)
	b_tutup.add_theme_font_size_override("font_size", 22)
	b_tutup.pressed.connect( func():
		GameState.klik()
		lapis.queue_free()
		if is_instance_valid(wadah) and wadah.get_parent() is VBoxContainer:
			isi(wadah.get_parent()))
	isi_k.add_child(b_tutup)
	return lapis
