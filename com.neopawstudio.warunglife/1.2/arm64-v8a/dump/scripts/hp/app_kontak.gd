extends VBoxContainer





const UI: = preload("res://scripts/hp/hp_ui.gd")
const BAR_AKRAB: = preload("res://scripts/hp/bar_akrab.gd")
const WARNA: = Color(0.2, 0.55, 0.5)

const PERAN: = {
	"kucing": "Kucing Mba Giska. Kasih makanan kucing dari warung sekali sehari supaya makin akrab.", 
	"pelajar": "Pelajar SMA, suka jajan sepulang sekolah", 
	"kantoran": "Pegawai kantor, berangkat pagi pulang sore", 
	"ojek": "Tukang ojek pangkalan", 
	"ibu_rumah_tangga": "Ibu rumah tangga, langganan belanja dapur", 
	"anak": "Anak SD berbaju merah", 
	"nenek": "Nenek yang ramah, suka menasihati", 
	"siswi": "Siswi, aktif di kegiatan sekolah", 
	"giska": "Warga baru, pindahan dari kota", 
	"santri_putih": "Santri, sering ke masjid", 
	"santri_hitam": "Santri, teman mengaji Kang Fadil", 
	"tukang": "Tukang bangunan", 
	"petani": "Petani padi di sawah kampung", 
	"pak_rt": "Ketua RT", 
}

var hp: Control
var _isi: VBoxContainer


func _ready() -> void :
	add_theme_constant_override("separation", 0)
	add_child(UI.kepala("Kontak", WARNA))
	var g: Array = UI.gulir(8)
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
	var info: = UI.panel(Color(0.93, 0.97, 0.95), 12, 10)
	info.add_child(UI.label("Sapa warga sekali sehari di mode jalan-jalan, bantu kerja sampingan dan ceritanya, dan layani mereka dengan cepat. Warga yang akrab lebih sering mampir ke warung. Langganan setia kadang memberi tip, dan yang sudah seperti keluarga sesekali datang membawakan makanan.", 14, UI.WARNA_REDUP, true))
	_isi.add_child(info)
	var warga: = gs.daftar_warga()
	var urut: Array = warga.keys()
	urut.sort_custom( func(a, b): return gs.akrab(a) > gs.akrab(b))
	for tipe in urut:
		_isi.add_child(_kartu(tipe, String(warga[tipe])))

	if gs.neo_bisa_disapa():
		_isi.add_child(_kartu(gs.TIPE_NEO, "Neo"))


func _kartu(tipe: String, nama: String) -> Control:
	var gs: = GameState
	var p: = UI.panel(Color.WHITE, 14, 10)
	var baris: = HBoxContainer.new()
	baris.add_theme_constant_override("separation", 12)
	p.add_child(baris)
	var file: = "res://assets/potret/warga_%s.png" % tipe
	if ResourceLoader.exists(file):
		baris.add_child(UI.ikon(load(file), 72))
	var teks: = VBoxContainer.new()
	teks.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	teks.add_theme_constant_override("separation", 2)
	baris.add_child(teks)
	var atas: = HBoxContainer.new()
	teks.add_child(atas)
	var l_nama: = UI.label(nama, 18)
	l_nama.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	atas.add_child(l_nama)
	if int(gs.sapa_hari.get(tipe, 0)) == gs.hari:
		atas.add_child(UI.label("✓ disapa", 12, UI.WARNA_BERHASIL))
	teks.add_child(UI.label(String(PERAN.get(tipe, "Warga kampung")), 13, UI.WARNA_REDUP, true))


	var tingkat: = gs.tingkat_akrab(tipe)
	var bar: Control = BAR_AKRAB.new()
	bar.atur(gs.akrab(tipe), tingkat)
	teks.add_child(bar)
	var bonus: = roundi((gs.pengali_akrab(tipe) - 1.0) * 100.0)
	var manfaat: Array = []
	if tipe == gs.TIPE_NEO:
		manfaat.append("dikasih makan hari ini" if gs.neo_makan_hari == gs.hari else "belum dikasih makan hari ini")
	elif bonus > 0:
		manfaat.append("mampir +%d%%" % bonus)
	if tingkat >= gs.TINGKAT_LANGGANAN and tipe != gs.TIPE_NEO:
		manfaat.append("kadang memberi tip")
	if tingkat >= gs.TINGKAT_KELUARGA and tipe != gs.TIPE_NEO:
		manfaat.append("kadang mengirim makanan")
	teks.add_child(UI.label(gs.nama_tingkat_akrab(tipe) + ("  · " + ", ".join(manfaat) if not manfaat.is_empty() else ""), 13, 
		BAR_AKRAB.WARNA_TINGKAT[tingkat].darkened(0.25), true))
	return p
