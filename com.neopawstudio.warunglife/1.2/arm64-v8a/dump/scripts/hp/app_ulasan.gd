extends VBoxContainer




const UI: = preload("res://scripts/hp/hp_ui.gd")
const WARNA: = Color(0.85, 0.6, 0.1)
const IKON_BINTANG: = preload("res://assets/ikon/bintang.svg")
const IKON_BINTANG_KOSONG: = preload("res://assets/ikon/bintang_kosong.svg")

var hp: Control
var _isi: VBoxContainer


func _ready() -> void :
	add_theme_constant_override("separation", 0)
	add_child(UI.kepala("Ulasan", WARNA))
	var g: Array = UI.gulir(8)
	var tepi: = MarginContainer.new()
	tepi.size_flags_vertical = Control.SIZE_EXPAND_FILL
	for sisi in ["left", "right", "top", "bottom"]:
		tepi.add_theme_constant_override("margin_" + sisi, 8)
	tepi.add_child(g[0])
	add_child(tepi)
	_isi = g[1]


func _deret_bintang(n: int, ukuran: float) -> HBoxContainer:
	var h: = HBoxContainer.new()
	h.add_theme_constant_override("separation", 1)
	for i in 5:
		h.add_child(UI.ikon(IKON_BINTANG if i < n else IKON_BINTANG_KOSONG, ukuran))
	return h


func tampil() -> void :
	var gs: = GameState
	for anak in _isi.get_children():
		anak.queue_free()

	var kartu: = UI.panel(Color.WHITE, 10, 12)
	_isi.add_child(kartu)
	var k: = VBoxContainer.new()
	k.alignment = BoxContainer.ALIGNMENT_CENTER
	kartu.add_child(k)
	var nama: = "Warung " + (gs.nama_warung if gs.nama_warung != "" else "Pak Misran")
	var judul: = UI.label(nama, 20)
	judul.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	k.add_child(judul)

	var deret: = _deret_bintang(gs.bintang(), 28)
	deret.alignment = BoxContainer.ALIGNMENT_CENTER
	k.add_child(deret)
	var l: = UI.label("Belum ada ulasan" if gs.ulasan.is_empty() else "Reputasi %s dari 5 · %d bintang" % [gs.rating_teks(), gs.bintang()], 18)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	k.add_child(l)
	var ket: = UI.label("Rata-rata %d ulasan terakhir" % mini(gs.ulasan.size(), gs.ULASAN_DIHITUNG), 13, UI.WARNA_REDUP)
	ket.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	k.add_child(ket)
	var tips: = "Reputasi dihitung dari ulasan. Layani dengan cepat, jaga stok, harga wajar, dan bantu warga."
	var keluhan: Array = gs.keluhan_fasilitas().filter( func(x): return String(x[0]) != "")
	if gs.level() <= 2:
		tips += " Warung baru masih sering dapat catatan \"barang masih sedikit\". Naik level dan lengkapi barangnya, nanti bintangnya ikut naik."
	if not keluhan.is_empty():
		tips += " Pelanggan juga sering mengeluhkan fasilitas yang belum ada: beli upgrade (kipas, bangku, dll.) supaya keluhannya hilang dan bintangnya naik."
	_isi.add_child(UI.label(tips, 13, UI.WARNA_REDUP, true))

	var daftar: = gs.ulasan.duplicate()
	daftar.reverse()
	for u in daftar.slice(0, 30):
		var baris: = UI.panel(Color.WHITE, 8, 10)
		var kolom: = VBoxContainer.new()
		kolom.add_theme_constant_override("separation", 3)
		baris.add_child(kolom)
		var atas: = HBoxContainer.new()
		kolom.add_child(atas)
		var n: = UI.label(String(u["nama"]), 15)
		n.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		atas.add_child(n)
		atas.add_child(UI.label(gs.teks_tanggal(int(u["hari"]), true), 12, UI.WARNA_REDUP))
		kolom.add_child(_deret_bintang(int(u["bintang"]), 16))
		kolom.add_child(UI.label(String(u["teks"]), 14, UI.WARNA_TEKS, true))
		_isi.add_child(baris)
