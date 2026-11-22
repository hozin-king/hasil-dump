extends RefCounted








const BERKAS: = "user://profil.json"
const DAFTAR: = [
	["", ""], 
	["agus", "Agus"], 
	["warga_pak_rt", "Pak RT"], 
	["warga_giska", "Mba Giska"], 
	["warga_kantoran", "Pak Rudi"], 
	["warga_pelajar", "Dimas"], 
	["warga_siswi", "Neng Shinta"], 
	["warga_ibu_rumah_tangga", "Bu Ida"], 
	["warga_nenek", "Nenek Sumi"], 
	["warga_anak", "Ucup"], 
	["warga_ojek", "Kang Asep"], 
	["warga_petani", "Abah Karta"], 
	["warga_tukang", "Mang Ujang"], 
	["warga_santri_putih", "Kang Fadil"], 
	["warga_santri_hitam", "Kang Hasan"], 
	["warga_kurir", "Kang Dadan"], 
	["misran", "Pak Misran"], 
]

const URUTAN_TAMPIL: = [16, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15]

static var _tekstur: = {}


static func jumlah() -> int:
	return DAFTAR.size() - 1


static func nama(n: int) -> String:
	return String(DAFTAR[n][1]) if n > 0 and n < DAFTAR.size() else ""


static func tekstur(n: int) -> Texture2D:
	if n <= 0 or n >= DAFTAR.size():
		return null
	if not _tekstur.has(n):
		var jalur: = "res://assets/potret/%s.png" % String(DAFTAR[n][0])
		_tekstur[n] = load(jalur) if ResourceLoader.exists(jalur) else null
	return _tekstur[n]


static func _muat() -> Dictionary:
	if not FileAccess.file_exists(BERKAS):
		return {}
	var d = JSON.parse_string(FileAccess.get_file_as_string(BERKAS))
	return d if d is Dictionary else {}


static func _simpan(d: Dictionary) -> void :
	var sementara: = BERKAS + ".tmp"
	var f: = FileAccess.open(sementara, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify(d))
	f.close()
	DirAccess.rename_absolute(sementara, BERKAS)



static func pilihan() -> int:
	return clampi(int(_muat().get("foto", 0)), 0, jumlah())


static func pilih(n: int) -> void :
	var d: = _muat()
	d["foto"] = clampi(n, 0, jumlah())
	d["terkirim"] = {}
	_simpan(d)



static func pernah_memilih() -> bool:
	return _muat().has("foto")



static func sudah_terkirim(id: String) -> bool:
	var t = _muat().get("terkirim", {})
	return t is Dictionary and int(t.get(id, -1)) == pilihan()


static func tandai_terkirim(id: String, n: int) -> void :
	var d: = _muat()
	var t = d.get("terkirim", {})
	if not t is Dictionary:
		t = {}
	t[id] = n
	d["terkirim"] = t
	_simpan(d)





static func bulat(n: int, ukuran: float, warna_bingkai: = Color(1.0, 0.8, 0.42), cadangan: = "") -> Control:
	const GH: = preload("res://scripts/gaya_hud.gd")
	var wadah: = Panel.new()
	wadah.custom_minimum_size = Vector2(ukuran, ukuran)
	wadah.size = wadah.custom_minimum_size
	wadah.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	wadah.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var g: = StyleBoxFlat.new()
	g.bg_color = warna_bingkai
	g.set_corner_radius_all(int(ukuran / 2.0))
	wadah.add_theme_stylebox_override("panel", g)
	var tebal: = maxf(2.0, round(ukuran * 0.06))
	var tx: = tekstur(n)
	if tx != null:
		var t: = TextureRect.new()
		t.texture = tx
		t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		t.position = Vector2(tebal, tebal)
		t.size = Vector2(ukuran - tebal * 2.0, ukuran - tebal * 2.0)
		t.material = GH.bahan_bulat()
		t.mouse_filter = Control.MOUSE_FILTER_IGNORE
		wadah.add_child(t)
	else:
		var dalam: = Panel.new()
		var gd: = StyleBoxFlat.new()
		gd.bg_color = Color(0.2, 0.24, 0.36)
		gd.set_corner_radius_all(int(ukuran / 2.0))
		dalam.add_theme_stylebox_override("panel", gd)
		dalam.position = Vector2(tebal, tebal)
		dalam.size = Vector2(ukuran - tebal * 2.0, ukuran - tebal * 2.0)
		dalam.mouse_filter = Control.MOUSE_FILTER_IGNORE
		wadah.add_child(dalam)
		var huruf: = _inisial(cadangan)
		var l: = GH.label(huruf, int(ukuran * 0.42), Color.WHITE, true, 3)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		l.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		dalam.add_child(l)
	return wadah



static func _inisial(nama_warung: String) -> String:
	var kata: = nama_warung.strip_edges().split(" ", false)
	for k in kata:
		if not k.to_lower() in ["warung", "toko", "kios", "warung#"]:
			return k.left(1).to_upper()
	return "?" if kata.is_empty() else String(kata[0]).left(1).to_upper()



static func buka_pemilih(induk: Node, dipilih: Callable = Callable()) -> void :
	const GH: = preload("res://scripts/gaya_hud.gd")
	var lapis: = ColorRect.new()
	lapis.color = Color(0, 0, 0, 0.7)
	lapis.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	lapis.mouse_filter = Control.MOUSE_FILTER_STOP
	lapis.z_index = 300
	lapis.theme = GH.tema_jendela_emas()

	var lapisan: = CanvasLayer.new()
	lapisan.layer = 128
	induk.get_tree().root.add_child(lapisan)
	lapisan.add_child(lapis)
	var tengah: = CenterContainer.new()
	tengah.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	lapis.add_child(tengah)
	var kartu: = GH.panel_emas(Vector4(30, 22, 30, 22))
	tengah.add_child(kartu)
	var kolom: = VBoxContainer.new()
	kolom.add_theme_constant_override("separation", 14)
	kartu.add_child(kolom)
	var judul: = GH.label("Pilih foto profil", 34, GH.KUNING, true, 5)
	judul.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	kolom.add_child(judul)
	var ket: = GH.label("Fotomu tampil di papan peringkat dan Adu Laris.", 18, Color(1, 1, 1, 0.8))
	ket.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	kolom.add_child(ket)
	var kisi: = GridContainer.new()
	kisi.columns = 8
	kisi.add_theme_constant_override("h_separation", 14)
	kisi.add_theme_constant_override("v_separation", 10)
	kolom.add_child(kisi)
	var sekarang: = pilihan()
	for n in URUTAN_TAMPIL:
		var tombol: = Button.new()
		tombol.flat = true
		tombol.focus_mode = Control.FOCUS_NONE
		tombol.custom_minimum_size = Vector2(104, 122)
		var isi: = VBoxContainer.new()
		isi.add_theme_constant_override("separation", 2)
		isi.mouse_filter = Control.MOUSE_FILTER_IGNORE
		isi.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		tombol.add_child(isi)
		var foto: = bulat(n, 88, GH.HIJAU_UANG if n == sekarang else Color(1, 1, 1, 0.55))
		foto.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		isi.add_child(foto)
		var l: = GH.label(nama(n), 15, GH.HIJAU_UANG if n == sekarang else Color.WHITE, false, 3)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		isi.add_child(l)
		tombol.pressed.connect( func():
			GameState.klik()
			pilih(n)
			lapisan.queue_free()
			if GameState.papan != null:
				GameState.papan.kirim_foto()
			if dipilih.is_valid():
				dipilih.call(n))
		kisi.add_child(tombol)
	var tutup: = Button.new()
	tutup.text = "Tutup"
	tutup.theme_type_variation = &"TombolKayu"
	tutup.custom_minimum_size = Vector2(220, 60)
	tutup.add_theme_font_size_override("font_size", 24)
	tutup.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	tutup.pressed.connect( func():
		GameState.klik()
		lapisan.queue_free())
	kolom.add_child(tutup)
	GH.pasang_muncul(kartu)
