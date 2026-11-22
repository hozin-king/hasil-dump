extends Node2D







const SCRIPT_PELANGGAN: = preload("res://scripts/pelanggan.gd")
const SCRIPT_JOYSTICK: = preload("res://scripts/joystick.gd")
const BukuHutang: = preload("res://scripts/buku_hutang.gd")
const SCRIPT_PORTAL: = preload("res://scripts/penunjuk.gd")
const TEMA: = preload("res://ui/tema.tres")
const GH: = preload("res://scripts/gaya_hud.gd")
const KB: = preload("res://scripts/konfirmasi_bayar.gd")
const KECEPATAN_METER: = 1.35
const PENGALI_LARI: = 2.1
const PENGALI_LARI_PAYUNG: = 1.6
const JAM_JUMATAN: = 11 * 60 + 30
const JAM_SELESAI_JUMATAN: = 13 * 60
const AMBANG_LARI: = 0.9
const JEDA_LANGKAH: = 0.5
const JEDA_LANGKAH_LARI: = 0.3
const JARAK_NPC: = 0.5
const MAKS_NPC: = 3
const SABAR_NPC: = 2.0
const JARI_BADAN: = 0.12
const JARAK_NGOBROL: = 0.6
const JANGKAUAN_CERITA: = 1.4
const LEBAR_TIANG_MAKS: = 130.0
const BLOK_OTOMATIS: = false
const PIJAKAN_TIANG: = 0.55
const ARAH_KASUR: = Vector2(1, 0.49)
const LANGKAH_DUDUK_M: = 0.32
const BAUR_DUDUK_TIDUR: = 0.7
const LEBAR_BINGKAI_TIDUR: = 1100
const SCRIPT_HP: = preload("res://scripts/hp/hp.gd")
const UI_HP: = preload("res://scripts/hp/hp_ui.gd")

var data: = {}
var data_pelanggan: = {}
var area_id: = ""
var area: = {}
var dunia: Node2D
var latar: Sprite2D
var wadah: Node2D
var bapak: Sprite2D
var kamera: Camera2D
var suasana: CanvasModulate
var rak: Sprite2D = null
var lantai: Array[PackedVector2Array] = []
var halangan: Array[PackedVector2Array] = []
var warga: Array[Sprite2D] = []
var ui: CanvasLayer
var joystick: Control
var tombol_aksi: Button
var tombol_warung: Button
var label_jam: Label
var label_area: Label
var pesan: Label
var tabir: ColorRect
var label_loading: Label
var sibuk: = false
var latar_paksa: = {}
var sinema_khusus: = false
var pindah: = false
var arah_pindah: = Vector2.ZERO
var sudah_masuk: = false
var pintu_dekat: Dictionary = {}
var warga_dekat: Sprite2D = null
var data_warga: = {}
var data_tokoh: = {}
var obrolan_terakhir: = {}
var waktu_langkah: = 0.0
var waktu_npc_baru: = 2.0
var hp: Control
var tombol_hp: Button
var label_jam_besar: Label
var _hud_kolom: VBoxContainer

const UKURAN_TOMBOL_HP: = Vector2(170, 178)
var lencana_hp: Control
var jam_dinding: Node2D = null
var jalur_tengah: Array[Vector2] = []
var panjang_jalur: Array[float] = []
var lebar_lajur: = 10.0
var dialog: Control


func _ready() -> void :
	get_tree().paused = false
	GameState.sedang_main = true
	GameState.putar_musik(GameState.musik_suasana())

	var t_login: = Timer.new()
	t_login.wait_time = 3.0
	t_login.autostart = true
	t_login.timeout.connect( func(): GameState.login_harian.cek(self))
	add_child(t_login)
	data = JSON.parse_string(FileAccess.get_file_as_string("res://data/peta.json"))
	var dp: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/pelanggan.json"))
	VarianBaju.gabung(dp)
	data_tokoh = dp.get("tokoh", {})
	for p in dp["pelanggan"]:
		data_pelanggan[String(p["id"])] = p
	data_warga = JSON.parse_string(FileAccess.get_file_as_string("res://data/warga.json"))
	_bangun_dunia()
	_bangun_ui()
	var tujuan: Dictionary = GameState.tujuan_jelajah


	if String(tujuan.get("sinematik", "")) == "pamit_misran":
		GameState.tujuan_jelajah.erase("sinematik")
		var sinema: Node = preload("res://scripts/sinema_pamit.gd").new()
		sinema.boleh_lewati = bool(tujuan.get("lewati", false))
		sinema.gaya_pamit = String(tujuan.get("gaya_pamit", sinema.gaya_pamit))
		GameState.tujuan_jelajah.erase("lewati")
		GameState.tujuan_jelajah.erase("gaya_pamit")
		add_child(sinema)
		sinema.mainkan(self)
		await sinema.selesai
		GameState.sedang_main = false
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
		return

	tabir.modulate.a = 1.0
	await _masuk_area(String(tujuan.get("area", "warung")), String(tujuan.get("muncul", "depan_warung")), false)

	var posisi: Array = tujuan.get("posisi", [])
	if posisi.size() == 2:
		var asal: = bapak.position
		bapak.position = _v(posisi)


		if _di_atas_kasur(bapak.position):
			bapak.position = _v(area["muncul"]["kasur"])

		if not _titik_lantai_bebas(bapak.position):
			var bebas: = _lantai_bebas_terdekat(bapak.position, 160.0)
			bapak.position = bebas if _titik_lantai_bebas(bebas) else asal
		kamera.position = bapak.position
		kamera.reset_smoothing()
		GameState.tujuan_jelajah.erase("posisi")
	_loading(false, "")

	if String(tujuan.get("alasan", "")) == "lelah":
		GameState.tujuan_jelajah.erase("alasan")
		var popup: = POPUP_HADIAH.new()
		ui.add_child(popup)
		popup.isi("Pak Misran kelelahan", "Energinya tinggal %d%%, tidak kuat lagi menjaga warung. Pulang ke rumah dan tidur, atau klik bar Energi untuk ngopi atau makan mi rebus (+30%%), atau tonton iklan supaya energi penuh lagi." % int(GameState.energi), [], "", false)
	if bool(tujuan.get("bangun", false)):
		GameState.tujuan_jelajah.erase("bangun")
		_bangun_pagi(false)


var _naik_level_tampil: = false

func _tampilkan_naik_level() -> void :
	_naik_level_tampil = true
	await GameState.get_tree().create_timer(0.4).timeout
	while not GameState.naik_level_tertunda.is_empty() and is_inside_tree():
		if sibuk or hp.visible or dialog.visible:
			await GameState.get_tree().create_timer(0.3).timeout
			continue
		var naik: Dictionary = GameState.naik_level_tertunda.pop_front()
		GameState.simpan()
		sibuk = true
		var isi: Array = GameState.isi_popup_naik(naik)
		var popup: = POPUP_HADIAH.new()
		ui.add_child(popup)
		popup.isi(isi[0], isi[1], isi[2])
		await popup.ditutup
		await GameState.tampilkan_iklan_selingan(ui)
		var level_baru: = int(naik["level"])
		if not GameState.data_tingkat(level_baru - 1).get("segera_hadir", false):
			var kartu: = preload("res://scripts/judul_level.gd").new()
			ui.add_child(kartu)
			kartu.tampil(level_baru, String(GameState.data_tingkat(level_baru - 1).get("nama", "")))
			await kartu.selesai
		sibuk = false
	_naik_level_tampil = false


func _v(p: Array) -> Vector2:
	return Vector2(float(p[0]), float(p[1]))


func _poligon(titik: Array) -> PackedVector2Array:
	var hasil: = PackedVector2Array()
	for p in titik:
		hasil.append(_v(p))
	return hasil




func _bangun_dunia() -> void :
	dunia = Node2D.new()
	add_child(dunia)
	latar = Sprite2D.new()
	latar.centered = false
	dunia.add_child(latar)
	wadah = Node2D.new()
	wadah.y_sort_enabled = true
	dunia.add_child(wadah)
	bapak = Sprite2D.new()
	bapak.set_script(SCRIPT_PELANGGAN)
	wadah.add_child(bapak)
	bapak.atur_3d(GameState.cfg_penjaga({"file": GameState.file_model_penjaga(), "skala": GameState.skala_penjaga(), "anim_jalan": "Walking", "anim_diam": "Idle_11"}), 0.0)
	bapak.set_meta("baju", String(GameState.baju_penjaga().get("id", "")))
	lalu_lintas = Node2D.new()
	lalu_lintas.y_sort_enabled = true
	dunia.add_child(lalu_lintas)
	kamera = Camera2D.new()
	kamera.position_smoothing_enabled = true
	kamera.position_smoothing_speed = 6.0
	dunia.add_child(kamera)
	kamera.make_current()

	suasana = CanvasModulate.new()
	add_child(suasana)




func _perbarui_baju_bapak() -> void :
	if bapak == null or bapak.karakter == null or bapak.karakter._model == null:
		return
	var baju: Dictionary = GameState.baju_penjaga()
	var id: = String(baju.get("id", ""))
	if String(bapak.get_meta("baju", "")) == id:
		return
	bapak.set_meta("baju", id)
	if id != "":
		VarianBaju.pasang(bapak.karakter._model, baju)
	else:
		for mi: MeshInstance3D in GameState.cari_anak(bapak.karakter._model, "MeshInstance3D"):
			for s in mi.mesh.get_surface_count():
				mi.set_surface_override_material(s, null)


func _masuk_area(id: String, muncul: String, pakai_loading: = true) -> void :

	if id == "kamar" and GameState.rumah_renovasi and data["area"].has("kamar_baru"):
		id = "kamar_baru"

	if not area.is_empty():
		_catat_semua_lintas()
	sibuk = true
	if pakai_loading:


		var j: Vector2 = joystick.baca()
		arah_pindah = j.normalized() if j.length() > 0.15 else bapak.karakter.arah_layar.normalized()
		pindah = true
		sudah_masuk = false
		await _loading(true, String(data["area"][id]["nama"]))
	sudah_masuk = true
	tepi_tertahan = true
	_perbarui_baju_bapak()
	GameState.cek_bayar_menunggu()
	area_id = id
	area = data["area"][id]

	GameState.volume_takbir_db = float(VOLUME_TAKBIR_AREA.get(id.trim_suffix("_baru"), -10.0))

	for anak in dunia.get_children() + wadah.get_children():
		if anak.has_meta("transisi") or anak.has_meta("penanda_cerita"):
			anak.queue_free()
	latar.texture = load(_varian()["gambar"])
	var ukuran: = latar.texture.get_size()
	kamera.limit_left = 0
	kamera.limit_top = 0
	kamera.limit_right = int(ukuran.x)
	kamera.limit_bottom = int(ukuran.y)
	_sesuaikan_zoom()
	lantai.clear()
	for p in area.get("lantai", []):
		lantai.append(_poligon(p))


	poligon_zebra = PackedVector2Array()
	if area.has("zebra") and bool(area["zebra"].get("diinjak", false)):
		poligon_zebra = _bentuk_zebra(area["zebra"])
		lantai.append(poligon_zebra)
	halangan.clear()
	for p in area.get("halangan", []):
		halangan.append(_poligon(p))
	_blok_penutup()
	_pasang_upgrade()
	_pasang_rak()
	_pasang_gelap_kios()
	_pasang_kabur()
	_pasang_penutup()
	_gelapkan_penutup()
	_pasang_label()
	_pasang_portal()
	_pasang_penanda_alam()
	_pasang_jam_dinding()
	_pasang_catatan_hutang()
	_pasang_tv()
	_pasang_papan_nama()
	_pasang_tulisan_atap()
	_siapkan_jalur_warga()
	_bersihkan_warga()
	_siapkan_lalu_lintas()
	_pasang_zebra()
	bapak.perspektif = area.get("perspektif", [])

	bapak.tinggi_dewasa_latar = float(area["tinggi_dewasa"])
	bapak.skala_3d = bapak.tinggi_dewasa_latar / (SCRIPT_PELANGGAN.TINGGI_DEWASA_METER * bapak.karakter.piksel_per_meter())
	bapak.karakter.lepas_tahan()

	bapak.karakter.boleh_payung = not area_id.begins_with("kamar")
	bapak.atur_lebar_bingkai(0)
	bapak.bayangan.show()
	bapak.z_index = 0
	bapak.y_berdiri = ukuran.y * 0.55
	bapak.karakter.ganti_anim_jalan("Walking")
	var semua_muncul: Dictionary = area["muncul"]
	bapak.position = _v(semua_muncul.get(muncul, semua_muncul.values()[0]))
	bapak.sedang_jalan = false
	kamera.position = bapak.position
	kamera.reset_smoothing()
	label_area.text = String(area["nama"]).to_upper()
	_pasang_warga_awal()
	_perbarui_npc_event(true)
	campur_malam = _target_campur_malam()
	suasana.color = _warna_suasana()
	if pakai_loading:
		await _loading(false, "")
	pindah = false
	sibuk = false



func _langkah_pindah(delta: float) -> void :
	var kecepatan: float = KECEPATAN_METER * bapak.tinggi_dewasa_latar / SCRIPT_PELANGGAN.TINGGI_DEWASA_METER * bapak.faktor_jarak()
	var baru: Vector2 = bapak.position + arah_pindah * kecepatan * delta


	if arah_pindah == Vector2.ZERO or (sudah_masuk and ( not _boleh(baru, bapak.position) or not _tepi_di(baru).is_empty())):
		bapak.sedang_jalan = false
		return
	bapak.position = baru
	bapak.karakter.arah_layar = arah_pindah
	bapak.sedang_jalan = true



var gelap_kios: Sprite2D = null

func _pasang_gelap_kios() -> void :
	if gelap_kios != null:
		gelap_kios.queue_free()
		gelap_kios = null
	if area_id != "warung":
		return
	gelap_kios = GameState.buat_gelap_kios()
	gelap_kios.modulate.a = 1.0 if GameState.kios_tampak_tutup() else 0.0
	dunia.add_child(gelap_kios)
	dunia.move_child(gelap_kios, (rak.get_index() + 1) if rak != null else 1)
	_gelapkan_penutup()





var _gelap_salinan: Array[Sprite2D] = []

func _gelapkan_penutup() -> void :
	_gelap_salinan = _gelap_salinan.filter( func(g): return is_instance_valid(g) and not g.is_queued_for_deletion())
	if gelap_kios == null:
		return
	for simpul in wadah.get_children():
		if not simpul.has_meta("penutup") or simpul.is_queued_for_deletion():
			continue
		var isi: CanvasItem = simpul.get_meta("isi")
		if isi.has_meta("gelap"):
			continue
		isi.clip_children = CanvasItem.CLIP_CHILDREN_AND_DRAW
		var g: = GameState.buat_gelap_kios()

		g.position = - (simpul.position + isi.position)
		g.modulate.a = gelap_kios.modulate.a
		isi.add_child(g)
		isi.set_meta("gelap", g)
		_gelap_salinan.append(g)


func _pasang_rak() -> void :

	if rak != null:
		rak.queue_free()
		rak = null
	if not area.has("rak"):
		return


	var data_rak: Dictionary = _varian()["rak"]
	if data_rak.has("lapisan"):
		rak = Sprite2D.new()
		rak.centered = false
		rak.texture = load(data_rak["lapisan"][1])
		rak.position = _v(data_rak["posisi"])
		dunia.add_child(rak)
		dunia.move_child(rak, 1)
		return
	rak = Sprite2D.new()
	rak.centered = false
	rak.texture = load(area["rak"]["gambar"])
	rak.position = _v(area["rak"]["posisi"])
	var bahan: = ShaderMaterial.new()
	bahan.shader = load("res://shader/rak_isi.gdshader")
	bahan.set_shader_parameter("urutan", load(area["rak"]["urutan"]))
	bahan.set_shader_parameter("isi", _isi_rak())
	rak.material = bahan
	dunia.add_child(rak)
	dunia.move_child(rak, 1)




func _pasang_jam_dinding() -> void :
	if jam_dinding != null:
		jam_dinding.queue_free()
		jam_dinding = null
	if not _varian().has("jam_dinding"):
		return
	var j: Dictionary = _varian()["jam_dinding"]
	var pusat: = _v(j["pusat"])
	var ke_3: = _v(j["arah_3"])
	var ke_12: = _v(j["arah_12"])

	var jam: = Node2D.new()
	jam_dinding = jam
	dunia.add_child(jam)
	dunia.move_child(jam, 1)
	var gambar_jarum: = func(sudut: float, panjang: float, tebal: float) -> void :
		var ujung: = pusat + (ke_3 * sin(sudut) + ke_12 * cos(sudut)) * panjang
		var ekor: = pusat - (ke_3 * sin(sudut) + ke_12 * cos(sudut)) * 0.12
		jam.draw_line(ekor, ujung, Color(0.12, 0.1, 0.09), tebal, true)
	jam.draw.connect( func():
		var m: = fmod(GameState.menit, 720.0)
		gambar_jarum.call(TAU * m / 720.0, 0.5, 3.0)
		gambar_jarum.call(TAU * fmod(GameState.menit, 60.0) / 60.0, 0.78, 2.0)
		jam.draw_circle(pusat, 2.6, Color(0.12, 0.1, 0.09)))






var catatan_hutang: Node2D = null
const UKURAN_CATATAN: = Vector2(52, 60)

func _pasang_catatan_hutang() -> void :
	if catatan_hutang != null:
		catatan_hutang.queue_free()
		catatan_hutang = null
	if not area.has("catatan_hutang"):
		return
	var c: Dictionary = area["catatan_hutang"]
	var kertas: = Node2D.new()
	catatan_hutang = kertas
	kertas.transform = Transform2D(_v(c["sisi_atas"]) / UKURAN_CATATAN.x, _v(c["sisi_kiri"]) / UKURAN_CATATAN.y, _v(c["pojok"]))

	var siang: bool = area.has("siang") and GameState.menit >= 5 * 60 and GameState.menit < GameState.JAM_MALAM
	kertas.modulate = Color.WHITE if siang else Color(0.78, 0.66, 0.55)
	dunia.add_child(kertas)
	dunia.move_child(kertas, 1)
	var huruf: Font = load("res://assets/font/Fredoka.ttf")
	var u: = UKURAN_CATATAN
	kertas.draw.connect( func():
		kertas.draw_rect(Rect2(Vector2(2, 3), u), Color(0, 0, 0, 0.3))
		kertas.draw_rect(Rect2(Vector2.ZERO, u), Color("#fff1a6"))
		kertas.draw_rect(Rect2(Vector2(0, u.y - 8), Vector2(u.x, 8)), Color("#f2dc84"))
		kertas.draw_rect(Rect2(Vector2(u.x / 2 - 12, -5), Vector2(24, 10)), Color(1, 1, 1, 0.65))
		var baris: = GameState.tk("Catatan hutang").split(" ", true, 1)
		for i in baris.size():
			kertas.draw_string(huruf, Vector2(0, 21 + i * 13), baris[i], HORIZONTAL_ALIGNMENT_CENTER, u.x, 12, Color("#5a2e12"))
		for i in 2:
			var y: = 42.0 + i * 7.0
			kertas.draw_line(Vector2(8, y), Vector2(u.x - 8 - i * 10, y), Color("#c0392b") if i == 0 else Color("#2c4f8a"), 1.5, true))

	var ketuk: = Control.new()
	ketuk.position = Vector2(-12, -12)
	ketuk.size = u + Vector2(24, 24)
	ketuk.mouse_filter = Control.MOUSE_FILTER_STOP
	ketuk.gui_input.connect( func(e: InputEvent):
		if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT and not e.pressed:
			GameState.klik()
			_jalankan("buku_hutang"))
	kertas.add_child(ketuk)





var zebra: Node2D = null

const SHADER_ZEBRA: = "\r\nshader_type canvas_item;\r\nuniform sampler2D latar : filter_linear;\r\nuniform vec2 ukuran;\r\nvarying vec2 titik;\r\n\r\nvoid vertex() {\r\n\ttitik = VERTEX;   // koordinat gambar latar (zebra & latar sama-sama di titik 0,0 dunia)\r\n}\r\n\r\nvoid fragment() {\r\n\tvec3 c = texture(latar, titik / ukuran).rgb;\r\n\tfloat terang = dot(c, vec3(0.299, 0.587, 0.114));\r\n\tfloat warna = max(max(c.r, c.g), c.b) - min(min(c.r, c.g), c.b);\r\n\tfloat aspal = smoothstep(0.17, 0.24, terang) * (1.0 - smoothstep(0.42, 0.5, terang)) * (1.0 - smoothstep(0.16, 0.26, warna));\r\n\tCOLOR.a *= aspal;\r\n}\r\n"


















func _pasang_zebra() -> void :
	if zebra != null:
		zebra.queue_free()
		zebra = null
	if not area.has("zebra"):
		return
	zebra = buat_zebra(area["zebra"], load(String(area["gambar"])))
	dunia.add_child(zebra)

	dunia.move_child(zebra, mini(wadah.get_index(), lalu_lintas.get_index()))





static func buat_zebra(z: Dictionary, masker: Texture2D) -> Node2D:
	var dekat: = Vector2(z["dekat"][0], z["dekat"][1])
	var seberang: = Vector2(z["jauh"][0], z["jauh"][1]) - dekat
	var total: = seberang.length()
	var lintas: = seberang / total
	var sepanjang: = Vector2(z["arah_jalan"][0], z["arah_jalan"][1]).normalized() * float(z["panjang"]) / 2.0
	var tebal: = float(z["lebar_garis"])
	var warna: = Color(0.96, 0.95, 0.9, float(z.get("alfa", 0.85)))
	var hasil: = Node2D.new()
	var s: = tebal * 0.4
	while s + tebal <= total - tebal * 0.4:
		var a: = dekat + lintas * s
		var b: = dekat + lintas * (s + tebal)
		var garis: = Polygon2D.new()
		garis.polygon = PackedVector2Array([a - sepanjang, a + sepanjang, b + sepanjang, b - sepanjang])
		garis.color = warna
		garis.use_parent_material = true
		hasil.add_child(garis)
		s += tebal * 2.0
	var bahan: = ShaderMaterial.new()
	bahan.shader = Shader.new()
	bahan.shader.code = SHADER_ZEBRA
	bahan.set_shader_parameter("latar", masker)
	bahan.set_shader_parameter("ukuran", masker.get_size())
	hasil.material = bahan
	return hasil







var tv: Node2D = null
var tv_layar: Sprite2D = null
static var tv_menyala: = true
var tv_video: VideoStreamPlayer = null
const VIDEO_TV: = "res://assets/video/logo_studio.ogv"
const TAYANGAN_VIDEO: = false

const SHADER_TV: = "\r\nshader_type canvas_item;\r\nrender_mode unshaded;\r\nuniform sampler2D masker : filter_linear;\r\nuniform sampler2D isi : filter_linear;\r\nuniform vec2 ukuran_masker;\r\nuniform vec2 asal;\r\nuniform vec2 ukuran;\r\nuniform vec2 p0; // kiri atas\r\nuniform vec2 p1; // kanan atas\r\nuniform vec2 p2; // kanan bawah\r\nuniform vec2 p3; // kiri bawah\r\nuniform float nyala = 1.0;\r\n\r\nfloat silang(vec2 a, vec2 b) { return a.x * b.y - a.y * b.x; }\r\n\r\n// Kebalikan pemetaan bilinear: titik dunia -> (u, v) di dalam segi empat layar.\r\nvec2 balik_bilinear(vec2 p) {\r\n\tvec2 e = p1 - p0; vec2 f = p3 - p0; vec2 g = p0 - p1 + p2 - p3; vec2 h = p - p0;\r\n\tfloat k2 = silang(g, f);\r\n\tfloat k1 = silang(e, f) + silang(h, g);\r\n\tfloat k0 = silang(h, e);\r\n\tfloat v;\r\n\tif (abs(k2) < 0.001) {\r\n\t\tv = -k0 / k1;\r\n\t} else {\r\n\t\tfloat w = sqrt(max(k1 * k1 - 4.0 * k0 * k2, 0.0));\r\n\t\tv = (-k1 - w) / (2.0 * k2);\r\n\t\tif (v < 0.0 || v > 1.0) v = (-k1 + w) / (2.0 * k2);\r\n\t}\r\n\tfloat u = (h.x - f.x * v) / (e.x + g.x * v);\r\n\treturn vec2(u, v);\r\n}\r\n\r\nvoid fragment() {\r\n\tvec2 dunia = asal + UV * ukuran;\r\n\tvec4 m = texture(masker, dunia / ukuran_masker);\r\n\tfloat hijau = smoothstep(0.1, 0.3, m.g - max(m.r, m.b));\r\n\tvec2 uv = clamp(balik_bilinear(dunia), 0.0, 1.0);\r\n\tvec3 c = texture(isi, uv).rgb;\r\n\tc *= 0.9 + 0.1 * sin(uv.y * 260.0);                     // garis-garis halus layar TV\r\n\tc *= 1.0 - 0.35 * pow(length(uv - 0.5) * 1.3, 2.0);      // tepi layar sedikit gelap\r\n\tc = mix(vec3(0.04, 0.05, 0.06), c, nyala);              // TV mati = layar gelap\r\n\tCOLOR = vec4(c, hijau);\r\n}\r\n"















































func _pasang_tv() -> void :
	if tv != null:
		tv.queue_free()
		tv = null
		tv_layar = null
		tv_video = null
	if not area.has("tv"):
		return
	var t: Dictionary = area["tv"]
	var sudut: Array[Vector2] = []
	for p in t["layar"]:
		sudut.append(_v(p))
	var kotak: = Rect2(sudut[0], Vector2.ZERO)
	for p in sudut:
		kotak = kotak.expand(p)
	kotak = kotak.grow(3.0)
	tv = Node2D.new()
	dunia.add_child(tv)
	dunia.move_child(tv, wadah.get_index())

	var vp: = SubViewport.new()
	vp.size = Vector2i(284, 200)
	vp.disable_3d = true
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	tv.add_child(vp)
	var latar_tv: = TextureRect.new()
	var gradasi: = GradientTexture2D.new()
	gradasi.gradient = Gradient.new()
	gradasi.gradient.set_color(0, Color(0.1, 0.12, 0.3))
	gradasi.gradient.set_color(1, Color(0.02, 0.03, 0.1))
	gradasi.fill = GradientTexture2D.FILL_RADIAL
	gradasi.fill_from = Vector2(0.5, 0.45)
	gradasi.fill_to = Vector2(1.1, 1.1)
	latar_tv.texture = gradasi
	latar_tv.size = Vector2(vp.size)
	vp.add_child(latar_tv)
	var logo: = TextureRect.new()
	logo.texture = load("res://assets/ui/logo_studio.png")
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	logo.size = Vector2(170, 125)
	logo.position = Vector2((vp.size.x - logo.size.x) / 2.0, 22)
	logo.pivot_offset = logo.size / 2.0
	vp.add_child(logo)
	var tulisan: = Label.new()
	tulisan.text = "NeoPaw TV"
	tulisan.add_theme_font_size_override("font_size", 22)
	tulisan.add_theme_color_override("font_color", Color(1, 0.9, 0.6))
	tulisan.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tulisan.size = Vector2(vp.size.x, 30)
	tulisan.position = Vector2(0, 155)
	vp.add_child(tulisan)


	var cuaca_tv: Control = load("res://scripts/tv_cuaca.gd").new()
	cuaca_tv.size = Vector2(vp.size)
	vp.add_child(cuaca_tv)
	logo.hide()
	tulisan.hide()
	if TAYANGAN_VIDEO and ResourceLoader.exists(VIDEO_TV):
		var video: = VideoStreamPlayer.new()
		video.stream = load(VIDEO_TV)
		video.expand = true
		video.size = Vector2(vp.size)
		video.volume_db = -22.0
		video.finished.connect(video.play)
		vp.add_child(video)
		video.play()
		tv_video = video
		logo.hide()
		tulisan.hide()
	var denyut: = logo.create_tween().set_loops()
	denyut.tween_property(logo, "scale", Vector2(1.06, 1.06), 1.2).set_trans(Tween.TRANS_SINE)
	denyut.tween_property(logo, "scale", Vector2(0.96, 0.96), 1.2).set_trans(Tween.TRANS_SINE)
	var kedip: = tulisan.create_tween().set_loops()
	kedip.tween_property(tulisan, "modulate:a", 0.45, 0.9)
	kedip.tween_property(tulisan, "modulate:a", 1.0, 0.9)

	tv_layar = Sprite2D.new()

	var putih: = Image.create(1, 1, false, Image.FORMAT_RGBA8)
	putih.fill(Color.WHITE)
	tv_layar.texture = ImageTexture.create_from_image(putih)
	tv_layar.centered = false
	tv_layar.position = kotak.position
	tv_layar.scale = kotak.size
	var bahan: = ShaderMaterial.new()
	bahan.shader = Shader.new()
	bahan.shader.code = SHADER_TV
	var masker: Texture2D = load(String(t["masker"]))
	bahan.set_shader_parameter("masker", masker)
	bahan.set_shader_parameter("ukuran_masker", masker.get_size())
	bahan.set_shader_parameter("isi", vp.get_texture())
	bahan.set_shader_parameter("asal", kotak.position)
	bahan.set_shader_parameter("ukuran", kotak.size)
	for i in 4:
		bahan.set_shader_parameter("p%d" % i, sudut[i])
	tv_layar.material = bahan
	tv.add_child(tv_layar)
	_atur_tv()


func _atur_tv() -> void :
	if tv_layar != null:
		(tv_layar.material as ShaderMaterial).set_shader_parameter("nyala", 1.0 if tv_menyala else 0.0)
	if tv_video != null:
		tv_video.paused = not tv_menyala




var papan_nama: Node2D = null

func _pasang_papan_nama() -> void :
	if papan_nama != null:
		papan_nama.queue_free()
		papan_nama = null
	if not area.has("papan_nama") or GameState.nama_warung == "":
		return
	var p: Dictionary = area["papan_nama"]
	var ukuran: = _v(p["ukuran"])
	var font: = FontVariation.new()
	font.base_font = load("res://assets/font/BebasNeue.ttf")
	font.spacing_glyph = 1

	var label: Control = SCRIPT_WARUNG.SCRIPT_TEKS_TENGAH.new()
	label.atur(font, [[GameState.nama_warung.to_upper(), SCRIPT_WARUNG.WARNA_NAMA_PAPAN, SCRIPT_WARUNG.ukuran_nama_papan(ukuran)]], ukuran)
	papan_nama = Node2D.new()
	papan_nama.transform = Transform2D(Vector2(1, float(p["miring"])), Vector2(0, 1), _v(p["posisi"]))
	papan_nama.add_child(label)
	dunia.add_child(papan_nama)
	dunia.move_child(papan_nama, 1)




var tulisan_atap: Node2D = null

func _pasang_tulisan_atap() -> void :
	if is_instance_valid(tulisan_atap):
		tulisan_atap.queue_free()
	tulisan_atap = null
	if not area.has("tulisan_atap") or not GameState.pendukung or GameState.nama_warung == "":
		return
	tulisan_atap = preload("res://scripts/spanduk_atap.gd").buat(area["tulisan_atap"]["sudut"], load(String(area["gambar"])))
	dunia.add_child(tulisan_atap)
	dunia.move_child(tulisan_atap, 1)



func _siapkan_jalur_warga() -> void :
	jalur_tengah.clear()
	panjang_jalur.clear()
	lebar_lajur = float(area.get("lajur", 10))
	var total: = 0.0
	for p in area.get("jalur_npc", []):
		var t: = _v(p)
		if not jalur_tengah.is_empty():
			total += jalur_tengah[-1].distance_to(t)
		jalur_tengah.append(t)
		panjang_jalur.append(total)



func _titik_jalur(s: float) -> Array:
	for i in jalur_tengah.size() - 1:
		if s <= panjang_jalur[i + 1] or i == jalur_tengah.size() - 2:
			var arah: = (jalur_tengah[i + 1] - jalur_tengah[i]).normalized()
			var t: = clampf((s - panjang_jalur[i]) / maxf(panjang_jalur[i + 1] - panjang_jalur[i], 0.01), 0.0, 1.0)
			return [jalur_tengah[i].lerp(jalur_tengah[i + 1], t), arah]
	return [jalur_tengah[0], Vector2.RIGHT]












const IRISAN: = 16.0

func _penutup_tetap(p: Dictionary) -> bool:
	return String(p.get("masker", "")) != "daun" and bool(p.get("blok", true))


func _pasang_penutup() -> void :
	for anak in wadah.get_children():
		if anak.has_meta("penutup"):
			anak.queue_free()
	var daftar: Array = area.get("penutup", [])
	if daftar.is_empty():
		return
	var gambar: Image = null
	for p in daftar:
		var masker: = String(p.get("masker", ""))

		if masker == "" and bool(p.get("halus", false)):
			masker = "halus"
		var poli: = _poligon(p["titik"])
		var kotak: = _kotak_poli(poli)
		if masker != "" and gambar == null:
			gambar = latar.texture.get_image()
			if gambar.is_compressed():
				gambar.decompress()
		if not _penutup_tetap(p):

			var simpul: = _simpul_penutup(poli, masker, gambar, float(p["dasar"]))

			if not bool(p.get("tutup", false)):
				simpul.set_meta("pudar", true)
			simpul.set_meta("alfa", float(p.get("alfa", 1.0)))
			simpul.modulate.a = float(p.get("alfa", 1.0))
			simpul.set_meta("dasar", float(p["dasar"]))
			simpul.set_meta("kotak", kotak)
			simpul.set_meta("bawah", _tepi_bawah(poli, kotak))
			simpul.set_meta("daun", masker == "daun")
			continue
		var bawah: = _tepi_bawah(poli, kotak)
		var x: = floorf(kotak.position.x)
		while x < kotak.end.x:
			var kolom: = PackedVector2Array([Vector2(x, kotak.position.y - 1), Vector2(x + IRISAN, kotak.position.y - 1), 
				Vector2(x + IRISAN, kotak.end.y + 1), Vector2(x, kotak.end.y + 1)])
			var urut: = INF
			for i in range(int(x - kotak.position.x), int(x + IRISAN - kotak.position.x) + 1):
				if i >= 0 and i < bawah.size() and bawah[i] > kotak.position.y:
					urut = minf(urut, bawah[i])
			if urut < INF:
				for potong in Geometry2D.intersect_polygons(poli, kolom):
					_simpul_penutup(potong, masker, gambar, urut)
			x += IRISAN


func _simpul_penutup(poli: PackedVector2Array, masker: String, gambar: Image, y: float) -> Node2D:
	var simpul: = Node2D.new()
	simpul.set_meta("penutup", true)
	var isi: Node2D
	if masker == "":

		var bentuk: = Polygon2D.new()
		bentuk.texture = latar.texture
		bentuk.polygon = poli
		bentuk.uv = poli
		isi = bentuk
	else:
		var potongan: = Sprite2D.new()
		potongan.centered = false
		var hasil: Array = _potong_penutup(gambar, poli, masker)
		potongan.texture = hasil[0]
		potongan.set_meta("pojok", Vector2(hasil[1]))
		isi = potongan
	simpul.add_child(isi)
	simpul.set_meta("isi", isi)
	_letakkan_penutup(simpul, y)
	wadah.add_child(simpul)
	return simpul


func _kotak_poli(poli: PackedVector2Array) -> Rect2:
	var kotak: = Rect2(poli[0], Vector2.ZERO)
	for t in poli:
		kotak = kotak.expand(t)
	return kotak









func _blok_penutup() -> void :


	if not BLOK_OTOMATIS:
		return
	var lebar_badan: = float(area.get("tinggi_dewasa", 150)) * 0.2
	for p in area.get("penutup", []):
		if not _penutup_tetap(p):
			continue
		var poli: = _poligon(p["titik"])
		var kotak: = _kotak_poli(poli)
		var bawah: = _tepi_bawah(poli, kotak)
		var penuh: = String(p.get("masker", "")) == "tanaman" or (String(p.get("masker", "")) == "" and kotak.size.x <= LEBAR_TIANG_MAKS)
		if penuh:
			halangan.append(_pijakan_tiang(bawah, kotak))
			continue
		var atas_garis: = PackedVector2Array()
		var bawah_garis: = PackedVector2Array()
		var x: = kotak.position.x - lebar_badan
		while x <= kotak.end.x + lebar_badan:
			var maks: = - INF
			var mini: = INF
			for i in range(int(x - lebar_badan - IRISAN - kotak.position.x), int(x + lebar_badan + IRISAN - kotak.position.x) + 1):
				if i >= 0 and i < bawah.size() and bawah[i] > kotak.position.y:
					mini = minf(mini, bawah[i])
					if absf(kotak.position.x + i - x) <= lebar_badan:
						maks = maxf(maks, bawah[i])
			if maks > - INF:
				var dalam: = maks - mini + 6.0
				atas_garis.append(Vector2(x, maks - dalam))
				bawah_garis.append(Vector2(x, maks + 1.0))
			x += 4.0
		if atas_garis.size() < 2:
			continue
		bawah_garis.reverse()
		halangan.append(atas_garis + bawah_garis)





func _pijakan_tiang(bawah: PackedFloat32Array, kotak: Rect2) -> PackedVector2Array:
	var dalam: = kotak.size.x * PIJAKAN_TIANG
	var atas_garis: = PackedVector2Array()
	var bawah_garis: = PackedVector2Array()
	var x: = kotak.position.x
	while x <= kotak.end.x:
		var i: = clampi(int(x - kotak.position.x), 0, bawah.size() - 1)
		var y: = bawah[i]
		if y > kotak.position.y:
			atas_garis.append(Vector2(x, maxf(kotak.position.y, y - dalam)))
			bawah_garis.append(Vector2(x, y + 1.0))
		x += 4.0
	bawah_garis.reverse()
	return atas_garis + bawah_garis



func _tepi_bawah(poli: PackedVector2Array, kotak: Rect2) -> PackedFloat32Array:
	var hasil: = PackedFloat32Array()
	for i in int(ceil(kotak.size.x)) + 1:
		var x: = kotak.position.x + i
		var y: = kotak.end.y
		while y > kotak.position.y and not Geometry2D.is_point_in_polygon(Vector2(x, y), poli):
			y -= 1.0
		hasil.append(y)
	return hasil



func _letakkan_penutup(simpul: Node2D, y: float) -> void :
	simpul.position.y = y
	var isi: Node2D = simpul.get_meta("isi")
	isi.position = (isi.get_meta("pojok") if isi.has_meta("pojok") else Vector2.ZERO) - Vector2(0, y)



const ALFA_TEMBUS: = 0.3

func _perbarui_penutup(delta: float) -> void :
	var tinggi: = float(area.get("tinggi_dewasa", 150))
	var orang: Array[Sprite2D] = [bapak]
	for w in warga:
		if is_instance_valid(w) and not w.has_meta("pergi"):
			orang.append(w)
	for simpul in wadah.get_children():
		if not simpul.has_meta("pudar") or simpul.is_queued_for_deletion():
			continue
		var kotak: Rect2 = simpul.get_meta("kotak")
		var alfa: float = simpul.get_meta("alfa")
		for o in orang:
			var kaki: Vector2 = o.position
			var badan: = Rect2(kaki.x - tinggi * 0.22, kaki.y - tinggi, tinggi * 0.44, tinggi)
			if kotak.intersects(badan) and kaki.y < float(simpul.get_meta("dasar")):
				alfa = minf(alfa, ALFA_TEMBUS)
		simpul.modulate.a = move_toward(simpul.modulate.a, alfa, delta * 3.0)








func _potong_penutup(gambar: Image, poli: PackedVector2Array, masker: String) -> Array:
	if masker == "halus":
		return _potong_halus(gambar, poli)
	var batas: = Rect2(poli[0], Vector2.ZERO)
	for t in poli:
		batas = batas.expand(t)
	var r: = Rect2i(Vector2i(batas.position.floor()), Vector2i(batas.size.ceil()) + Vector2i.ONE).intersection(Rect2i(Vector2i.ZERO, gambar.get_size()))
	var hasil: = Image.create(r.size.x, r.size.y, false, Image.FORMAT_RGBA8)
	for y in r.size.y:
		for x in r.size.x:
			var titik: = Vector2(r.position.x + x + 0.5, r.position.y + y + 0.5)
			if not Geometry2D.is_point_in_polygon(titik, poli):
				continue
			var c: = gambar.get_pixel(r.position.x + x, r.position.y + y)
			if masker == "hijau":
				var hijau: = c.g - maxf(c.r, c.b)
				if hijau < 0.04 and c.get_luminance() > 0.3:
					continue
			elif masker == "daun":

				if c.g - c.b < 0.06 or c.g < c.r * 0.85:
					continue
			elif masker == "tanaman":

				var daun: = c.g - c.b > 0.06 and c.g >= c.r * 0.85
				var pot: = maxf(c.r, maxf(c.g, c.b)) - minf(c.r, minf(c.g, c.b)) < 0.09 and c.get_luminance() < 0.55
				if not daun and not pot:
					continue
			c.a = 1.0
			hasil.set_pixel(x, y, c)

	hasil.fix_alpha_edges()
	return [ImageTexture.create_from_image(hasil), r.position]






const LEBAR_HALUS: = 6

func _potong_halus(gambar: Image, poli: PackedVector2Array) -> Array:
	var batas: = _kotak_poli(poli).grow(LEBAR_HALUS)
	var r: = Rect2i(Vector2i(batas.position.floor()), Vector2i(batas.size.ceil()) + Vector2i.ONE).intersection(Rect2i(Vector2i.ZERO, gambar.get_size()))
	var topeng: = Image.create(r.size.x, r.size.y, false, Image.FORMAT_L8)
	var geser: = PackedVector2Array()
	for t in poli:
		geser.append(t - Vector2(r.position))
	for y in r.size.y:
		for x in r.size.x:
			if Geometry2D.is_point_in_polygon(Vector2(x + 0.5, y + 0.5), geser):
				topeng.set_pixel(x, y, Color.WHITE)
	var buram: = topeng.duplicate() as Image
	for n in 2:
		buram.resize(maxi(1, buram.get_width() / 2), maxi(1, buram.get_height() / 2), Image.INTERPOLATE_BILINEAR)
	buram.resize(r.size.x, r.size.y, Image.INTERPOLATE_CUBIC)
	var hasil: = Image.create(r.size.x, r.size.y, false, Image.FORMAT_RGBA8)
	for y in r.size.y:
		for x in r.size.x:
			var a: = smoothstep(0.03, 0.8, buram.get_pixel(x, y).r)
			if a <= 0.0:
				continue
			var c: = gambar.get_pixel(r.position.x + x, r.position.y + y)
			c.a = a
			hasil.set_pixel(x, y, c)
	hasil.fix_alpha_edges()
	return [ImageTexture.create_from_image(hasil), r.position]


func _isi_rak() -> float:
	var jumlah: = 0
	var kapasitas: = 0
	for id in GameState.barang_fisik():
		if GameState.terbuka(id):
			jumlah += mini(GameState.stok[id], 12)
			kapasitas += 12
	return float(jumlah) / maxf(kapasitas, 1.0)


func _sesuaikan_zoom() -> void :
	var layar: = get_viewport_rect().size
	var z: = layar.x / float(area.get("lebar_pandangan", 1250))

	if latar.texture != null:
		var ukuran: = latar.texture.get_size()
		z = maxf(z, maxf(layar.x / ukuran.x, layar.y / ukuran.y))
	kamera.zoom = Vector2(z, z)




func _pasang_kabur() -> void :
	for anak in dunia.get_children():
		if anak.has_meta("kabur"):
			anak.queue_free()
	if not area.has("kabur"):
		return
	var s: = Sprite2D.new()
	s.set_meta("kabur", true)
	s.centered = false
	var data_kabur: Dictionary = _varian()["kabur"]
	s.texture = load(data_kabur["gambar"])
	s.position = _v(data_kabur["posisi"])
	dunia.add_child(s)
	dunia.move_child(s, latar.get_index() + 1)





func _pasang_portal() -> void :
	for anak in dunia.get_children():
		if anak.has_meta("portal"):
			anak.queue_free()

	if bool(area.get("dalam_ruangan", false)):
		return
	var jari: = float(area["tinggi_dewasa"]) * 0.32
	var daftar: Array = []
	for p in area.get("pintu", []):
		if String(p["aksi"]).begins_with("area:"):

			daftar.append([_v(p.get("penunjuk", p["posisi"])), String(p["aksi"]), p])


			for titik in p.get("penunjuk_lain", []):
				daftar.append([_v(titik), String(p["aksi"]), p])
	for t in area.get("tepi", []):
		var p: = _v(t["penunjuk"]) if t.has("penunjuk") else _titik_tepi(t, jari)
		if p != Vector2.INF:
			daftar.append([p, String(t["aksi"]), t])
	var tengah: = Vector2.ZERO
	var n: = 0
	for poli in lantai:
		for titik in poli:
			tengah += titik
			n += 1
	tengah /= maxf(n, 1)
	for d in daftar:
		var tujuan_id: String = d[1].split(":")[1]
		var p: = Node2D.new()
		p.set_script(SCRIPT_PORTAL)
		p.set("tujuan", String(data["area"][tujuan_id]["nama"]) if data["area"].has(tujuan_id) else tujuan_id)


		var arah: Vector2 = (d[0] - tengah).normalized()
		if d[2].has("arah"):
			arah = _v(d[2]["arah"]).normalized()
		elif d[2].has("sisi"):
			var trotoar: = _arah_trotoar(d[0])
			if trotoar != Vector2.ZERO:
				arah = trotoar if trotoar.dot(d[0] - tengah) >= 0.0 else - trotoar
		p.set("arah", arah)
		p.set("samping_jalan", _v(d[2]["samping"]).normalized() if d[2].has("samping") else _samping_tanah(arah))

		p.set("skala", 1.0 / kamera.zoom.x)
		p.set("tinggi", float(area["tinggi_dewasa"]))
		if d[2].has("angkat_papan"):
			p.set("angkat", float(d[2]["angkat_papan"]))
		p.set_meta("portal", true)
		p.set_meta("ke_area", tujuan_id)
		p.position = d[0]
		dunia.add_child(p)




func _area_berikut(dari: String, ke: String) -> String:
	if dari == ke:
		return ""
	var asal: = {dari: ""}
	var antre: Array = [dari]
	while not antre.is_empty():
		var a: String = antre.pop_front()
		var dt: Dictionary = data["area"].get(a, {})
		for t in dt.get("pintu", []) + dt.get("tepi", []):
			var aksi: = String(t["aksi"])
			if not aksi.begins_with("area:"):
				continue
			var b: = aksi.split(":")[1]
			if asal.has(b):
				continue
			asal[b] = a
			if b == ke:
				var langkah: = b
				while asal[langkah] != dari:
					langkah = asal[langkah]
				return langkah
			antre.append(b)
	return ""





var sorot_tut: Control = null
var _tut_pesan: = ""




var bar_energi: Control = null
var _tip_jalan: = false
var _tip_tunggu: = 0.0

func _cek_tip_jelajah() -> void :
	if _tip_jalan or sibuk or pindah or dialog.visible or hp.visible or _sinema_aktif or ikuti_kerja != "":
		_tip_tunggu = 0.0
		return

	_tip_tunggu += get_process_delta_time()
	if _tip_tunggu < 1.5:
		return
	var aksi: = String(pintu_dekat.get("aksi", "")) if tombol_aksi.visible else ""
	if aksi == "mancing" and GameState.tip_baru("mancing"):
		_jelaskan_tip([[tombol_aksi, "Tempat memancing! Klik untuk melempar kail. Ikan yang didapat masuk Tas dan bisa dijual di Pasar."]], "mancing")
	elif aksi == "petik" and GameState.tip_baru("petik"):
		_jelaskan_tip([[tombol_aksi, "Kebun buah! Klik untuk memetik buah yang sudah matang. Hasilnya masuk Tas dan bisa dijual di Pasar."]], "petik")
	elif aksi.begins_with("angkot:") and GameState.tip_baru("angkot"):
		_jelaskan_tip([[tombol_aksi, "Angkot ke Pasar, ongkosnya Rp2.000. Di Pasar, hasil pancingan dan kebun bisa dijual ke Bu Ida."]], "angkot")
	elif panel_misi != null and panel_misi.is_visible_in_tree() and GameState.tip_baru("misi"):
		_jelaskan_tip([[panel_misi, "Ini daftar misi dan cerita warga. Warga bertanda \"!\" punya cerita: dekati lalu klik Sapa. Klik tombol kecil di pojok untuk memperkecil panel ini."]], "misi")
	elif panel_kerja != null and panel_kerja.is_visible_in_tree() and GameState.tip_baru("kerja"):
		_jelaskan_tip([[panel_kerja, "Ini kerja sampingan hari ini, upahnya naik setiap Level Warung. Klik Ikuti, Pak Misran berjalan sendiri ke tempatnya."]], "kerja")
	elif bar_energi != null and bar_energi.is_visible_in_tree() and GameState.energi < 35.0 and GameState.tip_baru("energi"):
		_jelaskan_tip([[bar_energi, "Energi Pak Misran tinggal sedikit. Klik bar ini untuk ngopi, atau pulang dan tidur supaya penuh lagi. Kalau energi habis, Pak Misran pingsan."]], "energi")


func _jelaskan_tip(daftar: Array, id: String) -> void :
	_tip_jalan = true
	GameState.tandai_tip(id)
	var s: Control = load("res://scripts/sorot_tutorial.gd").new()
	s.process_mode = Node.PROCESS_MODE_ALWAYS
	s.theme = TEMA
	ui.add_child(s)
	await s.jelaskan_urut(daftar)
	s.queue_free()
	_tip_jalan = false
	_tip_tunggu = 0.0


func _perbarui_tutorial() -> void :
	var langkah: = GameState.tutorial_langkah

	if langkah in ["layani", "tunggu_tutup", "keluar"] and GameState.status_hari == "tutup":
		GameState.tutorial_langkah = "pulang"
		langkah = "pulang"
	if langkah == "pulang" and area_id == "kamar":
		GameState.tutorial_langkah = "tidur"
		langkah = "tidur"
	if sorot_tut == null:
		sorot_tut = load("res://scripts/sorot_tutorial.gd").new()
		sorot_tut.process_mode = Node.PROCESS_MODE_ALWAYS
		ui.add_child(sorot_tut)
	var sasaran: Control = null
	var teks: = ""
	var pesan: = ""
	if langkah == "pulang":
		if tombol_aksi.visible and String(pintu_dekat.get("aksi", "")).begins_with("area:kamar"):
			sasaran = tombol_aksi
			teks = "Ini rumah Pak Misran. Klik untuk masuk."
		else:
			pesan = "Saatnya pulang. Ikuti penunjuk kuning yang berkedip menuju rumah Pak Misran."
	elif langkah == "tidur":
		if tombol_aksi.visible and String(pintu_dekat.get("aksi", "")) == "tidur":
			sasaran = tombol_aksi
			teks = "Klik Tidur untuk menyelesaikan tutorial. Besok pagi, jalan sendiri ke warung dan mulai berjualan sungguhan." if GameState.mode_latihan else "Klik Tidur. Hari berganti dan permainan tersimpan otomatis."
		else:
			pesan = "Dekati kasur, lalu klik Tidur."
	if sasaran != null and not sibuk and not dialog.visible:
		if sorot_tut.sasaran != sasaran or sorot_tut._teks != teks or not sorot_tut.visible:
			sorot_tut.sorot(sasaran, teks)
	elif sorot_tut.visible:
		sorot_tut.lepas()
	if pesan != "" and pesan != _tut_pesan and not sibuk:
		_tut_pesan = pesan
		tampilkan_pesan(pesan, 7.0)



func _perbarui_penunjuk_kerja() -> void :
	var id: = GameState.kerja_tujuan
	if id != "" and not GameState.kerja_tersedia(id):
		GameState.kerja_tujuan = ""
		id = ""
	var ke: = "" if id == "" else _area_berikut(area_id, String(GameState.KERJA_SAMPINGAN[id]["area"]))

	if GameState.tutorial_langkah in ["pulang", "tidur"]:
		ke = _area_berikut(area_id, "kamar")
	var kedip: = 0.5 + 0.5 * sin(Time.get_ticks_msec() / 160.0)

	var tut: = _tujuan_tutorial()
	var portal_tut: Node2D = null
	for anak in dunia.get_children():
		if anak.has_meta("ke_area"):
			anak.modulate = Color(1.0 + 0.6 * kedip, 1.0 + 0.45 * kedip, 0.6 + 0.2 * kedip) if String(anak.get_meta("ke_area")) == ke and ke != "" else Color.WHITE
			anak.visible = tut == "" or String(anak.get_meta("ke_area")) == tut
			if tut != "" and String(anak.get_meta("ke_area")) == tut:
				portal_tut = anak

	if portal_tut != null:
		if _jejak == null:
			_jejak = load("res://scripts/jejak_tutorial.gd").new()
			dunia.add_child(_jejak)
			dunia.move_child(_jejak, latar.get_index() + 1)
		_jejak.visible = not sibuk
		_jejak.dari = bapak.position
		_jejak.ke = portal_tut.position
		_jejak.skala = 1.0 / kamera.zoom.x
	elif _jejak != null:
		_jejak.queue_free()
		_jejak = null


var _jejak: Node2D = null


func _tujuan_tutorial() -> String:
	if GameState.tutorial_langkah in ["pulang", "tidur"] and area_id != "kamar":
		return _area_berikut(area_id, "kamar")
	return ""



func _arah_trotoar(p: Vector2) -> Vector2:
	var jalur: Array = area.get("jalur_npc", [])
	var terbaik: = Vector2.ZERO
	var jarak_min: = INF
	for i in jalur.size() - 1:
		var a: = _v(jalur[i])
		var b: = _v(jalur[i + 1])
		var d: = p.distance_to(Geometry2D.get_closest_point_to_segment(p, a, b))
		if d < jarak_min and a != b:
			jarak_min = d
			terbaik = (b - a).normalized()
	return terbaik




static func _samping_tanah(a: Vector2) -> Vector2:
	var s: = sin(deg_to_rad(SCRIPT_OBJEK3D.SUDUT_KAMERA))
	return Vector2( - a.y / s, a.x * s).normalized()



func _titik_tepi(t: Dictionary, jari: float) -> Vector2:
	var batas: = float(t["batas"])
	var ukuran: = latar.texture.get_size()
	var kumpulan: Array[float] = []
	var mendatar: = String(t["sisi"]) in ["atas", "bawah"]
	var geser: = jari * 1.3 * (1.0 if String(t["sisi"]) in ["kiri", "atas"] else -1.0)
	var garis: = batas + geser
	var ujung: = ukuran.x if mendatar else ukuran.y
	var i: = 0.0
	while i < ujung:
		var p: = Vector2(i, garis) if mendatar else Vector2(garis, i)
		if _boleh(p, p) and ( not mendatar or p.x >= float(t.get("min_x", - INF))):
			kumpulan.append(i)
		i += 4.0
	if kumpulan.is_empty():
		return Vector2.INF
	var tengah: float = (kumpulan.front() + kumpulan.back()) / 2.0
	return Vector2(tengah, garis) if mendatar else Vector2(garis, tengah)


func _pasang_label() -> void :
	for anak in dunia.get_children():
		if anak.has_meta("label_area"):
			anak.queue_free()

	var skala: = 1.0 / kamera.zoom.x
	for l in area.get("label", []):

		var teks_l: = String(l["teks"])
		if teks_l.contains("◀") or teks_l.contains("▶") or teks_l.contains("▼") or teks_l.contains("▲"):
			continue
		var kotak: = PanelContainer.new()
		kotak.set_meta("label_area", true)
		var gaya: = StyleBoxFlat.new()
		gaya.bg_color = Color(0.2, 0.13, 0.07, 0.78)
		gaya.set_corner_radius_all(10)
		gaya.set_content_margin_all(6)
		gaya.border_color = Color(1, 0.88, 0.6, 0.8)
		gaya.set_border_width_all(2)
		kotak.add_theme_stylebox_override("panel", gaya)
		kotak.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var t: = Label.new()
		t.text = String(l["teks"])
		t.add_theme_font_size_override("font_size", 17)
		t.add_theme_color_override("font_color", Color(1, 0.95, 0.85))
		kotak.add_child(t)
		kotak.theme = TEMA
		kotak.scale = Vector2(skala, skala)
		dunia.add_child(kotak)
		kotak.position = _v(l["posisi"])





const WARNA_UPGRADE_MALAM: = Color(0.5, 0.47, 0.6)

func _gelapkan_upgrade_malam() -> void :
	var warna: = Color.WHITE.lerp(WARNA_UPGRADE_MALAM, campur_malam)
	for anak in wadah.get_children() + dunia.get_children():
		if anak.has_meta("upgrade"):
			(anak as CanvasItem).modulate = warna
	if is_instance_valid(tulisan_atap):
		tulisan_atap.modulate = warna



func _warna_suasana() -> Color:
	var c: = GameState.warna_suasana()

	if bool(area.get("dalam_ruangan", false)):
		return Color(1, 1, 1)


	c = c.lerp(Color.WHITE, 0.75 * campur_malam)

	var r: Array = GameState.efek_cuaca().get("redup", [])
	if r.size() == 3:
		c *= Color(r[0], r[1], r[2])
	return c



var hujan: Node2D = null
var _lapisan_hujan: CanvasLayer

func _perbarui_hujan() -> void :
	var mau: = GameState.sedang_hujan() and not bool(area.get("dalam_ruangan", false))
	if mau and hujan == null:
		if _lapisan_hujan == null:
			_lapisan_hujan = CanvasLayer.new()
			add_child(_lapisan_hujan)
			move_child(_lapisan_hujan, ui.get_index())
		var layar: = get_viewport().get_visible_rect().size
		hujan = preload("res://scripts/hujan.gd").new()
		hujan.ukuran = layar
		hujan.position = layar / 2.0
		_lapisan_hujan.add_child(hujan)
	elif not mau and hujan != null:
		hujan.berhenti()
		hujan = null



const DURASI_TRANSISI: = 3.0
var campur_malam: = 0.0

func _target_campur_malam() -> float:
	return 1.0 if area.has("malam") and GameState.malam_hari() else 0.0




func _bangun_ui() -> void :
	ui = CanvasLayer.new()
	add_child(ui)
	var akar: = Control.new()
	akar.theme = TEMA
	akar.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	akar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(akar)



	var kolom: = VBoxContainer.new()
	kolom.position = Vector2(16, 6)
	kolom.add_theme_constant_override("separation", 4)
	kolom.mouse_filter = Control.MOUSE_FILTER_IGNORE
	akar.add_child(kolom)

	var baris_atas: = HBoxContainer.new()
	baris_atas.add_theme_constant_override("separation", 26)
	baris_atas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	kolom.add_child(baris_atas)
	var kolom_jam: = VBoxContainer.new()
	kolom_jam.add_theme_constant_override("separation", -4)
	kolom_jam.mouse_filter = Control.MOUSE_FILTER_IGNORE
	baris_atas.add_child(kolom_jam)
	label_jam_besar = GH.tebal(GH.label("", GH.UKURAN_JAM_HUD, Color.WHITE, true))
	kolom_jam.add_child(label_jam_besar)
	label_jam = GH.tebal(GH.label("", GH.UKURAN_TANGGAL_HUD, Color.WHITE, true))
	kolom_jam.add_child(label_jam)
	label_area = GH.tebal(GH.label("", 20, GH.BIRU_NAMA, true))

	kolom_jam.add_child(GH.tanpa_lebar(label_area))
	GH.kunci_lebar_jam(kolom_jam, label_jam_besar, label_jam)
	var kolom_rep: = VBoxContainer.new()
	kolom_rep.add_theme_constant_override("separation", 2)
	kolom_rep.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	kolom_rep.mouse_filter = Control.MOUSE_FILTER_IGNORE
	baris_atas.add_child(kolom_rep)

	var energi: = preload("res://scripts/bar_energi.gd").new()
	bar_energi = energi
	energi.adegan = self
	energi.akar = akar
	energi.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	baris_atas.add_child(energi)
	var atas: = HBoxContainer.new()
	atas.add_theme_constant_override("separation", 10)
	_hud_kolom = kolom

	var tanpa_iklan: = Button.new()
	tanpa_iklan.text = "Tanpa Iklan"

	_gaya_tombol_kuning(tanpa_iklan, 16)
	tanpa_iklan.custom_minimum_size = Vector2(170, 54)
	tanpa_iklan.visible = not GameState.tanpa_iklan
	tanpa_iklan.pressed.connect( func():
		if sibuk:
			return
		GameState.klik()
		var jendela: ColorRect = preload("res://scripts/tanpa_iklan.gd").new()
		sibuk = true
		akar.add_child(jendela)
		await jendela.ditutup
		sibuk = false)
	tombol_tanpa_iklan = tanpa_iklan

	var dukung: = Button.new()
	dukung.text = "Dukung Kami"


	_gaya_tombol_kuning(dukung, 44)
	var hati: = Control.new()
	hati.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hati.position = Vector2(12, 14)
	hati.custom_minimum_size = Vector2(26, 26)
	hati.size = Vector2(26, 26)
	hati.draw.connect( func():
		var r: = 6.5
		var p: = Vector2(13, 11)
		hati.draw_circle(p + Vector2( - r * 0.95, - r * 0.3), r, Color(0.08, 0.06, 0.04))
		hati.draw_circle(p + Vector2(r * 0.95, - r * 0.3), r, Color(0.08, 0.06, 0.04))
		hati.draw_colored_polygon(PackedVector2Array([p + Vector2( - r * 1.95, 0), p + Vector2(r * 1.95, 0), p + Vector2(0, r * 2.2)]), Color(0.08, 0.06, 0.04)))
	dukung.add_child(hati)
	dukung.custom_minimum_size = Vector2(190, 54)
	dukung.pressed.connect( func():
		if sibuk:
			return
		GameState.klik()
		_buka_dukungan())
	tombol_dukung = dukung
	if GameState.god_aktif():
		var god = load(GameState.JALUR_GOD).new()
		god.adegan = self
		god.akar = akar
		atas.add_child(god)

	var kanan: = HBoxContainer.new()
	kanan.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	kanan.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	kanan.position = Vector2(get_viewport_rect().size.x - 16, 14)
	kanan.add_theme_constant_override("separation", 10)
	akar.add_child(kanan)
	tombol_warung = Button.new()
	tombol_warung.theme_type_variation = &"TombolHijau"
	tombol_warung.custom_minimum_size = Vector2(160, 58)
	tombol_warung.add_theme_font_size_override("font_size", 22)
	tombol_warung.pressed.connect(_on_tombol_warung)
	kanan.add_child(tombol_warung)

	tombol_warung.hide()
	_pasang_hud_reputasi(kolom_rep)
	_hud_kolom.add_child(atas)
	GH.latar_kolom(_hud_kolom, 0.5)

	var tombol_menu: = Button.new()
	for k in ["normal", "hover", "pressed", "hover_pressed", "focus"]:
		tombol_menu.add_theme_stylebox_override(k, StyleBoxEmpty.new())
	tombol_menu.icon = load("res://assets/ikon/menu.svg")
	tombol_menu.expand_icon = true
	tombol_menu.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tombol_menu.custom_minimum_size = Vector2(50, 50)
	tombol_menu.add_theme_constant_override("icon_max_width", 36)
	tombol_menu.pressed.connect(_buka_menu)

	var peringkat: = preload("res://scripts/lencana_peringkat.gd").new()
	peringkat.saat_diketuk = func(): if not sibuk: _buka_papan_besar()
	kanan.add_child(peringkat)
	kanan.add_child(dukung)
	kanan.add_child(tanpa_iklan)
	kanan.add_child(tombol_menu)
	kanan.resized.connect( func(): kanan.position.x = get_viewport_rect().size.x - 16 - kanan.size.x)


	joystick = Control.new()
	joystick.set_script(SCRIPT_JOYSTICK)
	akar.add_child(joystick)
	akar.move_child(joystick, 0)

	tombol_aksi = Button.new()
	GH.gaya_tombol(tombol_aksi, true, 30)
	tombol_aksi.custom_minimum_size = Vector2(300, 84)
	tombol_aksi.hide()
	tombol_aksi.pressed.connect( func():
		if not pintu_dekat.is_empty():
			_buka_pintu(pintu_dekat)
		elif is_instance_valid(warga_dekat):
			_ngobrol(warga_dekat))
	akar.add_child(tombol_aksi)

	pesan = Label.new()
	GH.gaya_label(pesan, 17, GH.KUNING, false, 4)

	pesan.add_theme_stylebox_override("normal", GH.kartu_notif(0.75, Vector4(28, 10, 24, 12)))
	pesan.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pesan.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	akar.add_child(pesan)

	dialog = load("res://scripts/dialog_bawah.gd").new()
	dialog.tinggi_bar_sinema = TINGGI_BAR_SINEMA
	akar.add_child(dialog)
	dialog.baris_dimulai.connect(_meong)

	hp = SCRIPT_HP.new()
	hp.warung = self
	akar.add_child(hp)
	tombol_hp = GH.tombol_ikon(GameState.ikon_hp(), "HP", UKURAN_TOMBOL_HP.y - 30.0, Color.WHITE, 2.0)
	tombol_hp.size = UKURAN_TOMBOL_HP
	tombol_hp.pivot_offset = UKURAN_TOMBOL_HP / 2.0
	tombol_hp.pressed.connect( func(): if not sibuk: hp.buka())
	akar.add_child(tombol_hp)
	akar.move_child(tombol_hp, hp.get_index())
	lencana_hp = UI_HP.lencana()
	GH.gaya_lencana(lencana_hp)
	lencana_hp.position = GH.letak_lencana_hp(tombol_hp)
	tombol_hp.add_child(lencana_hp)
	GameState.data_berubah.connect( func(): (tombol_hp.get_node("Ikon") as TextureRect).texture = load(GameState.ikon_hp()))
	GameState.data_berubah.connect(_perbarui_lencana_hp)
	GameState.akrab_naik.connect(_on_akrab_naik)
	GameState.dukungan_diterima.connect(_pasang_tulisan_atap)
	_perbarui_lencana_hp()

	var goyang: = create_tween().set_loops()
	goyang.tween_interval(4.0)
	goyang.tween_callback( func():
		if SCRIPT_HP.total_notif() > 0 and not sibuk and not hp.visible:
			var t: = tombol_hp.create_tween()
			for sudut in [-10.0, 8.0, -6.0, 4.0, 0.0]:
				t.tween_property(tombol_hp, "rotation_degrees", sudut, 0.08))

	akar.move_child(dialog, akar.get_child_count() - 1)

	tabir = ColorRect.new()
	tabir.color = Color(0.06, 0.04, 0.02)
	tabir.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tabir.modulate.a = 0.0
	tabir.mouse_filter = Control.MOUSE_FILTER_IGNORE
	akar.add_child(tabir)
	label_loading = Label.new()
	GH.gaya_label(label_loading, 40, GH.KUNING, false, 4)
	label_loading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label_loading.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label_loading.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label_loading.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	label_loading.offset_left = 120
	label_loading.offset_right = -120
	tabir.add_child(label_loading)

	GH.jaga_tepi(akar, [tombol_aksi, tombol_hp, pesan, joystick, dialog, tabir])
	get_viewport().size_changed.connect(_atur_letak_ui)
	_atur_letak_ui()



func tombol_kembali() -> void :
	_buka_menu()



func boleh_simpan_otomatis() -> bool:
	return not sibuk



func lokasi_simpan() -> Dictionary:
	var p: = bapak.position

	if _di_atas_kasur(p):
		p = _v(area["muncul"]["kasur"])
	return {"adegan": "jelajah", "area": area_id, "posisi": [snappedf(p.x, 0.1), snappedf(p.y, 0.1)]}



func _di_atas_kasur(p: Vector2) -> bool:
	if not area_id.begins_with("kamar") or not area.has("kasur") or not area.get("muncul", {}).has("kasur"):
		return false
	var kasur: = _v(area["kasur"])
	return p.distance_to(kasur) < kasur.distance_to(_v(area["muncul"]["kasur"])) * 0.8




func _tampilkan_ramalan() -> void :
	if sibuk:
		return
	sibuk = true
	bapak.sedang_jalan = false
	tombol_aksi.hide()
	var hari_ini: Dictionary = GameState.cuaca
	var besok: Dictionary = GameState.ramalan_besok()
	var lapisan: = ColorRect.new()
	lapisan.color = Color(0.03, 0.02, 0.01, 0.6)
	lapisan.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui.get_child(0).add_child(lapisan)
	var tengah: = CenterContainer.new()
	tengah.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	lapisan.add_child(tengah)
	var panel: = PanelContainer.new()
	panel.custom_minimum_size = Vector2(620, 0)
	tengah.add_child(panel)
	var isi: = VBoxContainer.new()
	isi.add_theme_constant_override("separation", 12)
	panel.add_child(isi)
	var judul: = Label.new()
	judul.theme_type_variation = &"LabelKepala"
	judul.add_theme_font_size_override("font_size", 30)
	judul.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	judul.text = "Prakiraan Cuaca"
	isi.add_child(judul)

	var tv_gambar: = Control.new()
	tv_gambar.custom_minimum_size = Vector2(580, 250)
	isi.add_child(tv_gambar)
	var hari_teks: = ["Hari ini · " + GameState.nama_hari_ke(GameState.hari), "Besok · " + GameState.nama_hari_ke(GameState.hari + 1)]
	var cuaca_dua: = [hari_ini, besok]
	var font: = tv_gambar.get_theme_default_font()
	tv_gambar.draw.connect( func():
		var s: = tv_gambar.size
		tv_gambar.draw_rect(Rect2(Vector2.ZERO, s), Color(0.08, 0.08, 0.09))
		var layar: = Rect2(Vector2(14, 14), s - Vector2(28, 28))
		tv_gambar.draw_rect(layar, Color(0.1, 0.2, 0.42))
		tv_gambar.draw_rect(Rect2(layar.position, Vector2(layar.size.x, 34)), Color(0.05, 0.1, 0.25))
		tv_gambar.draw_string(font, layar.position + Vector2(12, 24), GameState.tk("NeoPaw TV  ·  PRAKIRAAN CUACA"), HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(1, 0.9, 0.6))
		for n in 2:
			var kartu: = Rect2(layar.position + Vector2(14 + n * (layar.size.x - 14) / 2.0, 46), Vector2((layar.size.x - 42) / 2.0, layar.size.y - 60))
			tv_gambar.draw_rect(kartu, Color(1, 1, 1, 0.1))
			tv_gambar.draw_string(font, kartu.position + Vector2(0, 26), GameState.tk(hari_teks[n]), HORIZONTAL_ALIGNMENT_CENTER, kartu.size.x, 18, Color.WHITE)
			_gambar_ikon_cuaca(tv_gambar, kartu.position + Vector2(kartu.size.x / 2.0, 90), cuaca_dua[n])
			var c: Dictionary = cuaca_dua[n]
			var singkat: = "Cerah" if c.is_empty() else ("Hujan seharian" if bool(c.get("seharian", false)) else "Hujan %02d.00-%02d.00" % [int(c["mulai"]) / 60, int(ceil((float(c["mulai"]) + float(c["lama"])) / 60.0))])
			tv_gambar.draw_string(font, kartu.position + Vector2(0, kartu.size.y - 14), GameState.tk(singkat), HORIZONTAL_ALIGNMENT_CENTER, kartu.size.x, 20, Color(1, 0.95, 0.75)))
	var jelas: = Label.new()
	jelas.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	jelas.custom_minimum_size.x = 580
	jelas.add_theme_font_size_override("font_size", 20)
	jelas.text = "Hari ini: %s.\nBesok (%s): %s." % [GameState.teks_ramalan(hari_ini), GameState.nama_hari_ke(GameState.hari + 1), GameState.teks_ramalan(besok).to_lower()]
	if not hari_ini.is_empty() or not besok.is_empty():
		jelas.text += "\nSaat hujan, sebagian warga memilih di rumah saja, jadi pembeli bisa lebih sepi."
	isi.add_child(jelas)
	var b: = Button.new()
	b.text = "Tutup"
	b.theme_type_variation = &"TombolHijau"
	b.custom_minimum_size = Vector2(0, 64)
	b.add_theme_font_size_override("font_size", 24)
	b.pressed.connect( func():
		lapisan.queue_free()
		sibuk = false)
	isi.add_child(b)



func _gambar_ikon_cuaca(kanvas: Control, pusat: Vector2, c: Dictionary) -> void :
	if c.is_empty():
		for i in 8:
			var a: = TAU * i / 8.0
			kanvas.draw_line(pusat + Vector2.from_angle(a) * 34, pusat + Vector2.from_angle(a) * 46, Color(1, 0.82, 0.25), 5.0, true)
		kanvas.draw_circle(pusat, 26, Color(1, 0.85, 0.3))
		return
	var abu: = Color(0.85, 0.88, 0.95)
	for p in [[Vector2(-22, 0), 20.0], [Vector2(0, -12), 26.0], [Vector2(24, 0), 20.0]]:
		kanvas.draw_circle(pusat + p[0] + Vector2(0, -10), p[1], abu)
	kanvas.draw_rect(Rect2(pusat + Vector2(-42, -10), Vector2(86, 20)), abu)
	var deras: = bool(c.get("seharian", false))
	for i in (5 if deras else 3):
		var x: = -30.0 + i * (60.0 / ((5 if deras else 3) - 1))
		kanvas.draw_line(pusat + Vector2(x, 18), pusat + Vector2(x - 6, 36), Color(0.45, 0.7, 1.0), 4.0, true)



func _buka_menu() -> void :
	if sibuk or dialog.visible or hp.visible:
		return
	sibuk = true
	bapak.sedang_jalan = false
	tombol_aksi.hide()
	var lapisan: = ColorRect.new()
	lapisan.color = Color(0.03, 0.02, 0.01, 0.6)
	lapisan.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui.get_child(0).add_child(lapisan)
	var tengah: = CenterContainer.new()
	tengah.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	lapisan.add_child(tengah)
	var panel: = PanelContainer.new()
	panel.custom_minimum_size = Vector2(460, 0)
	tengah.add_child(panel)
	var isi: = VBoxContainer.new()
	isi.add_theme_constant_override("separation", 12)
	panel.add_child(isi)
	var judul: = Label.new()
	judul.text = "PERMAINAN DIJEDA"
	GH.gaya_jendela(panel, judul)
	isi.add_child(judul)
	var tutup: = func():
		lapisan.queue_free()
		sibuk = false
	for t in [["Lanjutkan", &"TombolHijau", tutup], 
			["Simpan", &"TombolKayu", func():
				tutup.call()
				GameState.simpan()
				tampilkan_pesan("Tersimpan: %s, %s, %s." % [GameState.nama_hari(), GameState.teks_jam(), String(area["nama"])])], 
			["Panduan", &"TombolKayu", func(): tutup.call();hp.buka("panduan")], 
			["Pengaturan", &"TombolKayu", func(): tutup.call();_buka_pengaturan()], 
			["Dukung Kami", &"TombolKayu", func(): tutup.call();_buka_dukungan()], 
			["Simpan & ke Menu Utama", &"TombolKayu", func():
				GameState.simpan()
				GameState.sedang_main = false
				GameState.ganti_layar(self, "res://scenes/main_menu.tscn")]]:
		var b: = Button.new()
		b.text = t[0]
		b.theme_type_variation = t[1]
		b.custom_minimum_size = Vector2(0, 70)
		b.add_theme_font_size_override("font_size", 26)
		b.pressed.connect(t[2])
		isi.add_child(b)
	var catatan: = Label.new()
	catatan.text = GameState.teks_simpan_terakhir()
	catatan.add_theme_font_size_override("font_size", 16)
	catatan.add_theme_color_override("font_color", Color(1, 1, 1, 0.7))
	catatan.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	isi.add_child(catatan)
	var kode_w: = GameState.tombol_kode_warung()
	if kode_w != null:
		isi.add_child(kode_w)





func _buka_buku_hutang() -> void :
	if sibuk or dialog.visible or hp.visible:
		return
	sibuk = true
	bapak.sedang_jalan = false
	tombol_aksi.hide()
	var lapisan: = ColorRect.new()
	lapisan.color = Color(0.03, 0.02, 0.01, 0.6)
	lapisan.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui.get_child(0).add_child(lapisan)
	var tengah: = CenterContainer.new()
	tengah.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	lapisan.add_child(tengah)
	var panel: = PanelContainer.new()
	panel.custom_minimum_size = Vector2(700, 0)
	tengah.add_child(panel)
	var isi: = VBoxContainer.new()
	isi.add_theme_constant_override("separation", 12)
	panel.add_child(isi)
	var judul: = Label.new()
	judul.text = "BUKU HUTANG"
	GH.gaya_jendela(panel, judul)
	isi.add_child(judul)
	BukuHutang.isi(isi)
	var tutup: = Button.new()
	tutup.text = "Tutup"
	tutup.theme_type_variation = &"TombolKayu"
	tutup.custom_minimum_size = Vector2(200, 58)
	tutup.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	tutup.add_theme_font_size_override("font_size", 24)
	tutup.pressed.connect( func():
		lapisan.queue_free()
		sibuk = false)
	isi.add_child(tutup)




const LEMARI_BAJU: = preload("res://scripts/lemari_baju.gd")

func _buka_lemari() -> void :
	if sibuk or dialog.visible or hp.visible:
		return
	if GameState.adalah_ibu():
		tampilkan_pesan("Lemari baju baru tersedia untuk Pak Misran.", 3.0)
		return
	sibuk = true
	bapak.sedang_jalan = false
	tombol_aksi.hide()
	var lemari: Control = LEMARI_BAJU.new()
	lemari.dipilih.connect(_ganti_baju)
	lemari.ditutup.connect( func(): sibuk = false)
	ui.get_child(0).add_child(lemari)


func _ganti_baju(id: String) -> void :
	GameState.baju_dipakai = id
	GameState.simpan_pengaturan()
	bapak.ganti_model_3d(GameState.cfg_penjaga({"file": GameState.file_model_penjaga(), "skala": GameState.skala_penjaga(), "anim_jalan": "Walking", "anim_diam": "Idle_11"}))
	bapak.set_meta("baju", String(GameState.baju_penjaga().get("id", "")))
	bapak.karakter.boleh_payung = not area_id.begins_with("kamar")
	bapak.atur_lebar_bingkai(0)
	bungkuk_lelah = false
	if dialog != null and dialog.has_method("segarkan_bapak"):
		dialog.segarkan_bapak()
	var nama: = "Baju bawaan" if id == "" else String(GameState.NAMA_BAJU.get(id, id))
	tampilkan_pesan("Pak Misran ganti baju: %s." % nama, 3.0)


func _atur_letak_ui() -> void :
	var layar: = get_viewport_rect().size
	joystick.atur_area()
	var tepi_kanan: float = GH.tepi_kiri_kanan(get_viewport()).y
	tombol_aksi.position = Vector2(layar.x - tepi_kanan - maxf(tombol_aksi.size.x, tombol_aksi.custom_minimum_size.x), layar.y - 40 - tombol_aksi.custom_minimum_size.y)
	pesan.size = Vector2(layar.x - 700, 80)

	pesan.position = Vector2(350, 150)
	tombol_hp.position = Vector2(layar.x - tepi_kanan - UKURAN_TOMBOL_HP.x - 20, layar.y - 40 - tombol_aksi.custom_minimum_size.y - 24 - UKURAN_TOMBOL_HP.y)
	if kamera != null and latar.texture != null:
		_sesuaikan_zoom()


func _perbarui_lencana_hp() -> void :
	UI_HP.atur_lencana(lencana_hp, SCRIPT_HP.total_notif())



var bintang_hud: Array[TextureRect] = []

func _pasang_hud_reputasi(wadah_hud: Container) -> void :

	wadah_hud.add_child(GH.tebal(GH.label("REPUTASI WARUNG", GH.UKURAN_JUDUL_HUD, GH.KUNING, true)))
	var panel: = PanelContainer.new()
	panel.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	wadah_hud.add_child(panel)
	var baris: = HBoxContainer.new()
	baris.add_theme_constant_override("separation", 2)
	panel.add_child(baris)
	for i in 5:
		var b: = TextureRect.new()
		b.custom_minimum_size = Vector2.ONE * GH.UKURAN_BINTANG_HUD
		b.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		b.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		baris.add_child(b)
		bintang_hud.append(b)
	var tombol_ulasan: = Button.new()
	tombol_ulasan.flat = true
	tombol_ulasan.focus_mode = Control.FOCUS_NONE
	tombol_ulasan.icon = load("res://assets/ikon/ulasan.svg")
	tombol_ulasan.expand_icon = true
	tombol_ulasan.custom_minimum_size = Vector2(34, 30)
	for gaya in ["normal", "hover", "pressed", "focus"]:
		tombol_ulasan.add_theme_stylebox_override(gaya, StyleBoxEmpty.new())
	tombol_ulasan.pressed.connect( func():
		if not sibuk:
			hp.buka("ulasan"))
	baris.add_child(tombol_ulasan)
	_perbarui_hud_reputasi()
	GameState.data_berubah.connect(_perbarui_hud_reputasi)


func _perbarui_hud_reputasi() -> void :
	for i in bintang_hud.size():
		bintang_hud[i].texture = load("res://assets/ikon/bintang.svg" if i < GameState.bintang() else "res://assets/ikon/bintang_kosong.svg")



func pergi_ke(id: String, muncul: String) -> void :
	if sibuk:
		return
	_masuk_area(id, muncul)


func _on_tombol_warung() -> void :
	if GameState.status_hari == "tutup":
		_jalankan("area:kamar:pintu")
	elif area_id != "warung":
		_jalankan("area:warung:depan_warung")
	else:
		_jalankan("warung")


func _loading(masuk: bool, nama: String) -> void :
	tabir.mouse_filter = Control.MOUSE_FILTER_STOP if masuk else Control.MOUSE_FILTER_IGNORE
	if masuk:
		label_loading.text = "Menuju %s...\n\nMemuat..." % nama
	var tween: = create_tween()
	tween.tween_property(tabir, "modulate:a", 1.0 if masuk else 0.0, 0.35)
	await tween.finished
	if masuk:
		await GameState.get_tree().create_timer(0.5).timeout


func tampilkan_pesan(teks: String, lama: = 3.5) -> void :
	var baru: = pesan.text != teks
	pesan.text = teks
	_letakkan_pesan()
	if baru and teks != "":
		_pop_pesan.call_deferred()
	await GameState.get_tree().create_timer(lama).timeout
	if pesan.text == teks:
		pesan.text = ""




func _letakkan_pesan() -> void :
	var layar: = get_viewport_rect().size
	var kiri: = 350.0
	var kanan: = layar.x - 350.0
	var bawah_panel: = 0.0
	for p in [panel_misi, panel_kerja]:
		if p == null or not is_instance_valid(p) or not p.is_visible_in_tree():
			continue
		var r: Rect2 = p.get_global_rect()
		if r.get_center().x < layar.x / 2.0:
			kiri = maxf(kiri, r.end.x + 16.0)
		else:
			kanan = minf(kanan, r.position.x - 16.0)
		bawah_panel = maxf(bawah_panel, r.end.y)
	if kanan - kiri >= 380.0:
		pesan.size = Vector2(kanan - kiri, 0)
		pesan.position = Vector2(kiri, 150)
	else:
		var lebar: = minf(layar.x - 120.0, 620.0)
		pesan.size = Vector2(lebar, 0)
		pesan.position = Vector2((layar.x - lebar) / 2.0, maxf(150.0, bawah_panel + 12.0))



func _pop_pesan() -> void :

	if not is_inside_tree():
		return
	await get_tree().process_frame
	if not is_inside_tree() or not is_instance_valid(pesan):
		return
	pesan.visible = true
	pesan.size.y = 0.0
	GH.pop_masuk(pesan)







func _proses_kiriman_di_luar(delta: float) -> void :
	if GameState.kiriman_stok.is_empty():
		return
	if (hp != null and hp.visible) or (dialog != null and dialog.visible):
		return
	GameState.kurir_dalam_perjalanan = false
	GameState.detik_kiriman -= delta
	if GameState.detik_kiriman > 0.0:
		return
	var jumlah: = 0
	for id in GameState.kiriman_stok:
		jumlah += int(GameState.kiriman_stok[id])
	GameState.terima_kiriman()
	GameState.bunyi("kurir")
	tampilkan_pesan("Paket kurir sudah ditaruh di warung: %d barang masuk stok." % jumlah, 4.0)


func _process(delta: float) -> void :
	GameState.cek_mulai_banjir(false)
	if sinema_khusus:
		return
	_proses_kiriman_di_luar(delta)
	if not sibuk and not dialog.visible and GameState.matel_perlu_datang():
		_matel_di_jalan()
	if pesan.visible != (pesan.text != ""):
		pesan.visible = pesan.text != ""
	if pesan.visible:
		pesan.size.y = 0.0
	label_jam_besar.text = GameState.teks_jam().replace(" WIB", "")
	label_jam.text = ("%s, %s" % [GameState.nama_hari(), GameState.teks_tanggal(-1, true)]).to_upper()

	if is_instance_valid(bapak) and is_instance_valid(bapak.karakter):
		bapak.karakter.atur_perban(GameState.perban_tampil())
	if tombol_tanpa_iklan != null:
		tombol_tanpa_iklan.visible = not GameState.tanpa_iklan and not GameState.mode_latihan
	if tombol_dukung != null:
		tombol_dukung.visible = not GameState.mode_latihan


	if not GameState.naik_level_tertunda.is_empty() and not _naik_level_tampil and not sibuk and not pindah and not hp.visible and not dialog.visible and tabir.modulate.a < 0.3:
		_tampilkan_naik_level()

	if panel_misi != null:
		panel_misi.visible = not sibuk and tabir.modulate.a < 0.3
		var target_misi: = ALFA_MISI_TERTUTUP if _bapak_di_balik_misi() else 1.0
		panel_misi.modulate.a = move_toward(panel_misi.modulate.a, target_misi, delta * 4.0)


	if panel_kerja != null:
		panel_kerja.visible = not sibuk and tabir.modulate.a < 0.3 and panel_kerja.get_child_count() > 0
		var layar: = get_viewport_rect().size
		var tepi_kanan: float = GH.tepi_kiri_kanan(get_viewport()).y
		var atas: = 84.0
		if tombol_tanpa_iklan != null and tombol_tanpa_iklan.is_visible_in_tree():
			atas = tombol_tanpa_iklan.get_global_rect().end.y + 8.0
		panel_kerja.position = Vector2(layar.x - tepi_kanan - panel_kerja.size.x, atas)
		var target_kerja: = ALFA_MISI_TERTUTUP if _bapak_di_balik(panel_kerja) else 1.0
		panel_kerja.modulate.a = move_toward(panel_kerja.modulate.a, target_kerja, delta * 4.0)
	tombol_warung.text = "Pulang" if GameState.status_hari == "tutup" else "Ke Warung"

	GameState.tampak_malam = area.has("siang") and _varian() != area["siang"]
	campur_malam = move_toward(campur_malam, _target_campur_malam(), delta / DURASI_TRANSISI)
	suasana.color = _warna_suasana()
	_gelapkan_upgrade_malam()
	_perbarui_hujan()
	_perbarui_varian()

	if GameState.tutup_otomatis():
		if GameState.kios_milik:
			tampilkan_pesan("Sudah %s: warung ditutup, %s." % [GameState.teks_jam_tutup(true), GameState.alasan_wajib_tutup()], 6.0)
		else:
			tampilkan_pesan("Sudah " + GameState.teks_jam_tutup(true) + ": warung ditutup sesuai pesan Pak Haji Rasyid. Saatnya keliling kampung!", 6.0)
	if gelap_kios != null:
		gelap_kios.modulate.a = move_toward(gelap_kios.modulate.a, 1.0 if GameState.kios_tampak_tutup() else 0.0, delta * 1.5)
		for g in _gelap_salinan:
			if is_instance_valid(g):
				g.modulate.a = gelap_kios.modulate.a
	_perbarui_penunjuk_kerja()
	_perbarui_tutorial()
	_cek_tip_jelajah()
	if jam_dinding != null:
		jam_dinding.queue_redraw()



	if awas_kendaraan != null and (pindah or sibuk or hp.visible or _sinema_aktif):
		awas_kendaraan.hide()
	if pindah:
		_langkah_pindah(delta)
		_gerak_warga(delta)
		_gerak_kendaraan(delta)
		kamera.position = bapak.position
		return


	if _sinema_aktif and not hp.visible:
		bapak.sedang_jalan = false
		_gerak_warga(delta)
		_gerak_kendaraan(delta)
		return

	if _adegan_angkot and not hp.visible:
		bapak.sedang_jalan = false
		_gerak_warga(delta)
		_gerak_kendaraan(delta)
		return



	if sibuk or hp.visible or _tip_jalan:
		bapak.sedang_jalan = false
		for w in warga:


			if is_instance_valid(w) and not w.has_meta("pergi_jalan"):
				w.sedang_jalan = false
		return

	GameState.majukan_waktu(delta * GameState.kecepatan_waktu)
	if GameState.energi <= 0.0 and not GameState.mode_latihan:
		_pingsan()
		return
	if GameState.menit >= GameState.JAM_BATAS:
		_ketiduran()
		return
	if _waktunya_jumatan():
		if GameState.hari_libur():
			_jumatan_libur()
		else:
			_ke_jumatan()
		return
	_gerak_bapak(delta)
	if _cek_jumatan_jalan_sendiri():
		return
	_perbarui_gendong(delta)
	if _cek_tertabrak():
		return
	_perbarui_penutup(delta)
	kamera.position = bapak.position
	_gerak_warga(delta)
	_perbarui_neo(delta)
	_gerak_kendaraan(delta)
	_perbarui_awas_kendaraan()
	_cek_tepi()
	_cek_pintu()

	if not sibuk and not pintu_dekat.is_empty() and bool(pintu_dekat.get("otomatis", false)) and joystick.baca().normalized().dot(_v(pintu_dekat.get("arah", [0, 0])).normalized()) > 0.55:
		_buka_pintu(pintu_dekat)
		return
	waktu_cek_event -= delta
	if waktu_cek_event <= 0.0:
		waktu_cek_event = 1.0

		if not GameState.dialog_tertunda.is_empty() and GameState.tutorial_langkah == "" and not GameState.mode_latihan:
			tampilkan_dialog_cerita()
		_perbarui_npc_event()
		_pulangkan_penjual()
		_perbarui_daftar_misi()
		_perbarui_panel_kerja()
	_perbarui_penanda_event()
	_perbarui_koin()
	if rak != null and rak.material != null:
		(rak.material as ShaderMaterial).set_shader_parameter("isi", _isi_rak())


var bungkuk_lelah: = false

func _gerak_bapak(delta: float) -> void :
	var mau_bungkuk: = GameState.energi < GameState.ENERGI_MIN_BUKA
	if mau_bungkuk != bungkuk_lelah:
		bungkuk_lelah = mau_bungkuk
		bapak.karakter.atur_bungkuk(20.0 if mau_bungkuk else 0.0)

		if mau_bungkuk:
			tampilkan_pesan("Energi Pak Misran di bawah %d%%: ia kelelahan, jalannya pelan dan tidak bisa berlari. Klik bar Energi untuk ngopi/makan, atau pulang tidur." % int(GameState.ENERGI_MIN_BUKA), 6.0)

	if ikuti_kerja != "":



		if joystick.baca().length() > 0.15:
			if ikuti_kerja == IKUTI_JUMATAN:
				_jumatan_jalan_sendiri = true
				tampilkan_pesan("Pak Misran berjalan sendiri. Sholat Jumat dimulai begitu sampai di depan Masjid Al-Ikhlas (sebelum 13.00).", 5.0)
			_batal_ikuti()
		else:
			_gerak_ikuti(delta)
			return
	var arah: Vector2 = joystick.baca()
	var bergerak: = arah.length() > 0.15

	var lari: = arah.length() >= AMBANG_LARI and GameState.energi >= GameState.ENERGI_MIN_BUKA

	if lari and _digendong != "" and not _digendong.begins_with(AWAL_BAWA):
		lari = false
		if not _pesan_jalan_pelan:
			_pesan_jalan_pelan = true
			tampilkan_pesan("Pelan-pelan, Pak Misran sedang menggendong Neo.", 3.0)
	if bergerak:
		arah = arah.normalized()
		var kecepatan: float = KECEPATAN_METER * bapak.tinggi_dewasa_latar / SCRIPT_PELANGGAN.TINGGI_DEWASA_METER * bapak.faktor_jarak() * GameState.pengali_jalan_lelah()
		if lari:

			kecepatan *= PENGALI_LARI_PAYUNG if (GameState.sedang_hujan() and not bool(area.get("dalam_ruangan", false))) else PENGALI_LARI

			GameState.energi = maxf(GameState.energi - GameState.ENERGI_LARI_PER_DETIK * delta * (GameState.PENGALI_ENERGI_RUMAH_BARU if GameState.rumah_renovasi else 1.0), 0.0)
		var langkah: float = kecepatan * delta
		var baru: Vector2 = bapak.position + arah * langkah

		if not _boleh(baru, bapak.position):
			var pilihan: Array[Vector2] = [
				bapak.position + Vector2(arah.x, 0).normalized() * langkah if absf(arah.x) > 0.05 else bapak.position, 
				bapak.position + Vector2(0, arah.y).normalized() * langkah if absf(arah.y) > 0.05 else bapak.position, 
				bapak.position + arah.rotated(0.6) * langkah, 
				bapak.position + arah.rotated(-0.6) * langkah, 

				bapak.position + arah.rotated(1.0) * langkah * 0.8, 
				bapak.position + arah.rotated(-1.0) * langkah * 0.8, 
				bapak.position + arah.rotated(1.35) * langkah * 0.6, 
				bapak.position + arah.rotated(-1.35) * langkah * 0.6, 
			]

			baru = bapak.position
			var maju_terbaik: = 0.0
			for p in pilihan:
				var maju: = (p - bapak.position).dot(arah)
				if maju > maju_terbaik and _boleh(p, bapak.position):
					maju_terbaik = maju
					baru = p


		if baru.distance_to(bapak.position) <= 0.01:
			_macet_detik += delta
			if _macet_detik >= 1.5:
				_macet_detik = 0.0
				baru = _lepas_macet(arah)


				if baru == bapak.position and not _titik_lantai_bebas(bapak.position):
					baru = _lantai_bebas_terdekat(bapak.position, 160.0)
		else:
			_macet_detik = 0.0
		bergerak = baru.distance_to(bapak.position) > 0.01
		if bergerak:
			bapak.karakter.arah_layar = (baru - bapak.position).normalized()
			bapak.position = baru
	bapak.karakter.ganti_anim_jalan("Running" if (bergerak and lari) else "Walking")
	bapak.sedang_jalan = bergerak

	if bergerak:
		waktu_langkah -= delta
		if waktu_langkah <= 0.0:
			GameState.langkah_kaki(lari, not bool(area.get("dalam_ruangan", false)))
			waktu_langkah = JEDA_LANGKAH_LARI if lari else JEDA_LANGKAH
	else:
		waktu_langkah = 0.12


var _macet_detik: = 0.0



func _lepas_macet(arah: Vector2) -> Vector2:
	for jarak in range(2, 13, 2):
		for sudut in [0.0, 0.4, -0.4, 0.8, -0.8, 1.2, -1.2, 1.57, -1.57]:
			var p: Vector2 = bapak.position + arah.rotated(sudut) * float(jarak)
			if _titik_lantai_bebas(p):
				return p
	return bapak.position




func _lantai_bebas_terdekat(p: Vector2, radius_maks: float) -> Vector2:
	if _titik_lantai_bebas(p):
		return p
	var r: = 4.0
	while r <= radius_maks:
		var n: = maxi(8, int(TAU * r / 6.0))
		for i in n:
			var q: = p + Vector2.RIGHT.rotated(TAU * i / n) * Vector2(r, r * 0.5)
			if _titik_lantai_bebas(q):
				return q
		r += 4.0
	return p



func _boleh(p: Vector2, dari: Vector2) -> bool:
	var di_lantai: = false
	for poli in lantai:
		if Geometry2D.is_point_in_polygon(p, poli):
			di_lantai = true
			break
	if not di_lantai:
		return false
	for poli in halangan:
		if Geometry2D.is_point_in_polygon(p, poli):
			return false

	var jari: = float(area.get("tinggi_dewasa", 150)) * JARI_BADAN
	for w in warga:
		if is_instance_valid(w) and not w.has_meta("pergi"):
			var d: = _jarak_lantai(p, w.position)
			if d < jari * 2.0 and d < _jarak_lantai(dari, w.position):
				return false
	return true



func _jarak_lantai(a: Vector2, b: Vector2) -> float:
	return Vector2(a.x - b.x, (a.y - b.y) * 2.0).length()



func _tepi_di(p: Vector2, longgar: = 0.0) -> Dictionary:
	for t in area.get("tepi", []):
		var batas: = float(t["batas"])
		var keluar: = false
		match String(t["sisi"]):
			"kiri": keluar = p.x < batas + longgar
			"kanan": keluar = p.x > batas - longgar
			"atas": keluar = p.y < batas + longgar
			"bawah": keluar = p.y > batas - longgar
		if keluar and p.x >= float(t.get("min_x", - INF)) - longgar and p.y >= float(t.get("min_y", - INF)) - longgar:
			return t
	return {}





const ZONA_AMAN_TEPI: = 30.0
var tepi_tertahan: = false

func _cek_tepi() -> void :
	if tepi_tertahan:
		if joystick.baca().length() < 0.15 or _tepi_di(bapak.position, ZONA_AMAN_TEPI).is_empty():
			tepi_tertahan = false
		return
	var t: = _tepi_di(bapak.position)
	if not t.is_empty():

		var tut: = _tujuan_tutorial()
		if tut != "" and String(t["aksi"]).begins_with("area:") and String(t["aksi"]).split(":")[1] != tut:
			tepi_tertahan = true
			tampilkan_pesan("Pulang dulu ke rumah Pak Misran. Ikuti panah kuning.", 3.0)
			return
		_jalankan(String(t["aksi"]))


func _cek_pintu() -> void :
	var terdekat: Dictionary = {}
	var jarak_min: = INF

	var semua_pintu: Array = area.get("pintu", []).duplicate()

	for w in warga:
		if is_instance_valid(w) and w.has_meta("kerja"):
			var id: = String(w.get_meta("kerja"))
			var k: Dictionary = GameState.data_kerja(id)

			semua_pintu.append({"posisi": [w.position.x, w.position.y], "radius": maxf(75.0, float(area.get("tinggi_dewasa", 150)) * JARAK_NGOBROL * 1.3), "label": "%s (+%s)" % [k["tombol"], GameState.format_rupiah(GameState.upah_kerja(id))], "aksi": "kerja:" + id})

	if area_id == "masjid" and GameState.boleh_tarawih():
		semua_pintu.append({"posisi": [690, 600], "radius": 240, "label": "Ikut tarawih", "aksi": "tarawih"})

	var tut: = _tujuan_tutorial()
	if tut != "":
		semua_pintu = semua_pintu.filter( func(p): return String(p["aksi"]).begins_with("area:" + tut))
	for p in semua_pintu:
		var d: = bapak.position.distance_to(_v(p["posisi"]))

		if p.has("di_lantai") and Geometry2D.is_point_in_polygon(bapak.position, _poligon(area["lantai"][int(p["di_lantai"])])):
			d = 0.0
		if d <= float(p["radius"]) and d < jarak_min:
			jarak_min = d
			terdekat = p
	pintu_dekat = terdekat

	warga_dekat = null
	var batas: = float(area.get("tinggi_dewasa", 150)) * JARAK_NGOBROL
	for w in warga:

		if is_instance_valid(w) and not w.has_meta("pergi") and not w.has_meta("kerja") and not w.has_meta("datang") and (data_warga["warga"].has(String(w.get_meta("tipe"))) or VarianBaju.ada(String(w.get_meta("tipe"))) or w.has_meta("neo") or w.has_meta("event")):

			var d: = _jarak_lantai(bapak.position, w.position) / (JANGKAUAN_CERITA if (w.has_meta("event") or w.has_meta("penjual")) else 1.0)
			if d <= batas:
				batas = d
				warga_dekat = w

	if GameState.waktunya_ronda():
		for w in warga:
			if is_instance_valid(w) and w.has_meta("ronda") and _jarak_lantai(bapak.position, w.position) <= float(area.get("tinggi_dewasa", 150)) * JARAK_NGOBROL:
				warga_dekat = w
	if warga_dekat != null and not terdekat.is_empty() and _warga_didahulukan(terdekat, jarak_min, tut):
		terdekat = {}
		pintu_dekat = {}
	tombol_aksi.visible = not terdekat.is_empty() or warga_dekat != null
	if not terdekat.is_empty():
		tombol_aksi.text = "Lihat ramalan cuaca" if String(terdekat["aksi"]) == "tv" else String(terdekat["label"])
		if String(terdekat["aksi"]) == "dialog:pos_ronda" and GameState.waktunya_ronda():
			tombol_aksi.text = "Ikut ronda"

	elif warga_dekat != null:

		var label_cerita: = ""
		if warga_dekat.has_meta("event") and not warga_dekat.has_meta("event_tetap"):
			label_cerita = String(_tahap_sekarang(String(warga_dekat.get_meta("event"))).get("tombol", ""))
		tombol_aksi.text = label_cerita if label_cerita != "" else "Sapa %s" % _nama_warga(warga_dekat)
		if warga_dekat.has_meta("penjual") and label_cerita == "" and not (warga_dekat.has_meta("event") and not warga_dekat.has_meta("event_tetap")):
			tombol_aksi.text = ("Beli jajan di %s" if warga_dekat.has_meta("jajan") else ("Belanja grosir di %s" if warga_dekat.has_meta("grosir") else "Jual ke %s")) % _nama_warga(warga_dekat)
	if tombol_aksi.visible and tombol_aksi.text != _teks_aksi_lalu:
		_teks_aksi_lalu = tombol_aksi.text
		_rapikan_tombol_aksi()
	_perbarui_ikon_ngobrol()




const MAKS_LEBAR_AKSI: = 560.0
var _teks_aksi_lalu: = ""

func _rapikan_tombol_aksi() -> void :
	var f: Font = tombol_aksi.get_theme_font("font")
	var teks: = TranslationServer.translate(tombol_aksi.text)
	var u: = GH.ukuran_cetak(30)
	while u > 16 and f.get_string_size(teks, HORIZONTAL_ALIGNMENT_LEFT, -1, u).x + 64.0 > MAKS_LEBAR_AKSI:
		u -= 1
	tombol_aksi.add_theme_font_size_override("font_size", u)
	tombol_aksi.size = Vector2.ZERO
	tombol_aksi.reset_size()
	var layar: = get_viewport_rect().size
	var tepi_kanan: float = GH.tepi_kiri_kanan(get_viewport()).y
	tombol_aksi.position.x = layar.x - tepi_kanan - tombol_aksi.size.x






func _warga_didahulukan(pintu: Dictionary, jarak_pintu: float, tutorial: String) -> bool:
	var aksi: = String(pintu["aksi"])
	if aksi.begins_with("kerja:"):
		return false
	if bapak.position.distance_to(warga_dekat.position) < jarak_pintu:
		return true
	if aksi == "dialog:pos_ronda" and GameState.waktunya_ronda():
		return false
	if aksi.begins_with("area:kamar"):
		return tutorial == "" and not warga_dekat.has_meta("neo")
	return aksi.begins_with("dialog:")




var ikon_ngobrol: Control = null
const UKURAN_IKON_NGOBROL: = 52.0

func _perbarui_ikon_ngobrol() -> void :
	if ikon_ngobrol == null:
		var latar_ikon: = Panel.new()
		var gaya: = StyleBoxFlat.new()
		gaya.bg_color = Color(0.08, 0.06, 0.05, 0.45)
		gaya.border_color = Color(1, 1, 1, 0.55)
		gaya.set_border_width_all(2)
		gaya.set_corner_radius_all(int(UKURAN_IKON_NGOBROL / 2.0))
		latar_ikon.add_theme_stylebox_override("panel", gaya)
		latar_ikon.size = Vector2(UKURAN_IKON_NGOBROL, UKURAN_IKON_NGOBROL)
		latar_ikon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		latar_ikon.modulate.a = 0.85
		latar_ikon.z_index = 100
		var gambar: = TextureRect.new()
		gambar.texture = load("res://assets/ikon/chat.svg")
		gambar.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		gambar.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		gambar.position = Vector2(10, 10)
		gambar.size = Vector2(UKURAN_IKON_NGOBROL - 20, UKURAN_IKON_NGOBROL - 20)
		gambar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		latar_ikon.add_child(gambar)
		ikon_ngobrol = latar_ikon
		dunia.add_child(ikon_ngobrol)
	ikon_ngobrol.visible = warga_dekat != null and not sibuk
	if not ikon_ngobrol.visible:
		return

	var s: = 1.0 / kamera.zoom.x
	ikon_ngobrol.scale = Vector2(s, s)
	var naik: = sin(Time.get_ticks_msec() / 250.0) * 4.0 * s
	var kepala: float = warga_dekat.tinggi_badan() + 12.0 * s
	ikon_ngobrol.position = warga_dekat.position + Vector2( - UKURAN_IKON_NGOBROL * s / 2.0, - kepala - UKURAN_IKON_NGOBROL * s + naik)


func _nama_warga(w: Sprite2D) -> String:
	return _nama_tipe(String(w.get_meta("tipe")))


func _tahap_sekarang(id: String) -> Dictionary:
	var semua: Array = GameState.data_event()[id]["tahap"]
	return semua[mini(GameState.tahap_event(id), semua.size() - 1)]



func _nama_tipe(tipe: String) -> String:
	if data_warga["warga"].has(tipe):
		return String(data_warga["warga"][tipe]["nama"])
	if VarianBaju.ada(tipe):
		return VarianBaju.nama_catatan(tipe)
	if data_tokoh.has(tipe):
		return String(data_tokoh[tipe]["nama"])
	return tipe.capitalize()






func _ngobrol(w: Sprite2D) -> void :
	if sibuk or dialog.visible:
		return
	if w.has_meta("event") and not w.has_meta("event_tetap"):
		_jalankan_event(w)
		return
	if w.has_meta("ronda") and GameState.waktunya_ronda():
		_ronda()
		return
	if w.has_meta("neo"):
		_sapa_neo(w)
		return
	if w.has_meta("penjual"):
		_buka_jual(w)
		return
	var tipe: = String(w.get_meta("tipe"))
	var nama: = _nama_tipe(tipe)
	var jam: = GameState.menit / 60.0
	var waktu: = "malam" if (jam >= 18.0 or jam < 4.0) else ("sore" if jam >= 15.0 else ("siang" if jam >= 11.0 else "pagi"))



	var basah: = GameState.tanah_basah()
	var sesuai_waktu: = func(o) -> bool: return typeof(o) != TYPE_DICTIONARY\
	or (( not o.has("waktu") or waktu in o["waktu"]) and not (basah and String(o.get("cuaca", "")) == "cerah"))
	var daftar: Array = (data_warga["warga"].get(tipe, {}).get("obrolan", []) as Array).filter(sesuai_waktu)

	if VarianBaju.ada(tipe):
		daftar = VarianBaju.obrolan(tipe).filter(sesuai_waktu)
	var dari_cerita: = _obrolan_event(tipe).filter(sesuai_waktu)
	var kunci: = tipe + ":" + waktu

	var soal_hujan: Array = (data_warga.get("obrolan_hujan", {}).get(tipe, []) as Array).filter(sesuai_waktu)
	if VarianBaju.ada(tipe):
		soal_hujan = VarianBaju.obrolan(tipe, true).filter(sesuai_waktu)
	if GameState.sedang_hujan() and not soal_hujan.is_empty() and (daftar.is_empty() or randf() < 0.6):
		daftar = soal_hujan
		kunci = tipe + ":hujan"
	if not dari_cerita.is_empty() and (daftar.is_empty() or randf() < 0.7):
		daftar = dari_cerita
		kunci = tipe + ":cerita:" + waktu

	if GameState.hari == GameState.hari_sembuh:
		daftar = OBROLAN_SEMBUH
		kunci = tipe + ":sembuh"
	if daftar.is_empty():
		return
	var nomor: = randi() % daftar.size()
	if daftar.size() > 1 and nomor == int(obrolan_terakhir.get(kunci, -1)):
		nomor = (nomor + 1) % daftar.size()
	obrolan_terakhir[kunci] = nomor


	var jenis_sapa: = waktu
	var daftar_sapa: Array = data_warga["sapaan"][waktu]
	if GameState.sedang_hujan() and waktu != "malam":
		daftar_sapa = data_warga["sapaan"]["hujan"]
		jenis_sapa = "hujan"
	elif basah:
		daftar_sapa = daftar_sapa.filter( func(k): return not String(k).contains("Panas"))
		if waktu != "malam" and randf() < 0.5:
			daftar_sapa = data_warga["sapaan"]["reda"]
			jenis_sapa = "reda"
	var no_sapa: = randi() % daftar_sapa.size()
	var sapa: = String(daftar_sapa[no_sapa]).replace("{nama}", nama)
	var baris: Array = [{"siapa": "bapak", "teks": sapa}]
	var pilihan = daftar[nomor]


	var baris_obrolan: Array = pilihan["baris"] if typeof(pilihan) == TYPE_DICTIONARY else pilihan
	var balasan: Array = data_warga.get("balasan_sapaan", {}).get(jenis_sapa, [])
	var awal_obrolan: = String(baris_obrolan[0]["teks"]) if not baris_obrolan.is_empty() else ""
	var sudah_salam: = false
	for salam in ["Pagi", "Siang", "Sore", "Malam", "Assalamualaikum"]:
		sudah_salam = sudah_salam or awal_obrolan.begins_with(salam)
	if not balasan.is_empty() and not sudah_salam:
		var b_sapa = balasan[no_sapa % balasan.size()]
		baris.append({"siapa": tipe, "nama": nama, "teks": String((b_sapa as Array).pick_random() if b_sapa is Array else b_sapa)})
	for b in (pilihan["baris"] if typeof(pilihan) == TYPE_DICTIONARY else pilihan):
		var teks: = String(b["teks"]).replace("{warung}", GameState.nama_warung)
		if String(b["siapa"]) == "warga":
			baris.append({"siapa": tipe, "nama": nama, "teks": teks})
		else:
			baris.append({"siapa": "bapak", "teks": teks})

	w.set_meta("ngobrol", true)
	w.sedang_jalan = false
	var arah: = (bapak.position - w.position).normalized()

	if w.karakter != null:
		w.karakter.arah_layar = arah
	if bapak.karakter != null:
		bapak.karakter.arah_layar = - arah
	bapak.sedang_jalan = false
	sibuk = true
	tombol_aksi.hide()
	dialog.tampilkan(baris)
	await dialog.selesai
	sibuk = false
	var kabar: = GameState.sapa_warga(tipe, nama)
	if kabar != "":
		tampilkan_pesan(kabar, 3.0)
	if is_instance_valid(w):
		w.remove_meta("ngobrol")
		if not w.has_meta("diam"):
			_letakkan_pejalan(w)


func _jalankan(aksi: String) -> void :
	if sibuk:
		return
	var bagian: = aksi.split(":", true, 2)
	match bagian[0]:
		"area":
			_masuk_area(bagian[1], bagian[2])
		"warung":
			if GameState.status_hari == "tutup":
				buka_dialog("warung_tutup")
				return
			if GameState.energi < GameState.ENERGI_MIN_BUKA:
				tampilkan_pesan("Pak Misran terlalu lelah untuk jaga warung (energi di bawah %d%%). Pulang tidur, atau klik bar Energi untuk minum/makan dulu." % int(GameState.ENERGI_MIN_BUKA), 5.0)
				return
			sibuk = true
			await _loading(true, "Warung")
			GameState.putar_intro = false
			GameState.ganti_layar(self, "res://scenes/warung.tscn")
		"tv":

			tv_menyala = true
			_atur_tv()
			_tampilkan_ramalan()
		"tidur":
			_tidur()
		"buku_hutang":
			_buka_buku_hutang()
		"lemari":
			_buka_lemari()
		"kerja":
			_kerja(bagian[1])
		"mancing", "petik":
			_hasil_alam(bagian[0])
		"adu_laris":
			_menu_adu_laris()
		"angkot":
			_naik_angkot(bagian[1])
		"tarawih":
			if not GameState.boleh_tarawih():
				return
			sibuk = true


			await _perjalanan({"teks": "Pak Misran sholat Isya dan tarawih berjamaah di masjid...", "menit": 0, "langkah": false, "detik": 2.5, 
				"saat_gelap": func(): GameState.ikut_tarawih()})
			sibuk = false
			tampilkan_pesan("Selesai tarawih. Jamaah makin akrab dengan Pak Misran.", 4.0)
		"dialog":
			if bagian[1] == "pos_ronda" and GameState.waktunya_ronda():
				_ronda()
				return
			buka_dialog(bagian[1])
		"pesan":
			tampilkan_pesan(bagian[1])






const POPUP_HADIAH: = preload("res://scripts/popup_hadiah.gd")
const LAYAR_KERJA: = preload("res://scripts/layar_kerja.gd")
const VOLUME_TAKBIR_AREA: = {"masjid": -2.0, "warung": -6.0, "sd": -8.0, "pesantren": -9.0, "rumah": -10.0, "sawah": -12.0, "pasar": -14.0, "kamar": -15.0}
const FOTO_RONDA: = "res://assets/cerita/ronda_malam.png"
var waktu_cek_event: = 1.0







const CERITA_PER_PETA_LIBUR: = 2
const JARAK_MIN_TOKOH_CERITA: = 70.0

func _event_di_sini() -> Array:
	var calon: = _semua_event_di_sini()


	var temui: Array = calon.filter( func(c): return bool(c[1].get("_temui", false)))
	if not temui.is_empty():
		var tipe_temui: Array = temui.map( func(c): return String(c[1]["npc"]))
		calon = calon.filter( func(c): return not bool(c[1].get("_temui", false)) and not String(c[1]["npc"]) in tipe_temui)
		var lain: = _pilih_event(calon)
		return temui + lain.filter( func(c): return temui.all( func(t): return _v(t[1]["posisi"]).distance_to(_v(c[1]["posisi"])) >= JARAK_MIN_TOKOH_CERITA))
	return _pilih_event(calon)


func _pilih_event(calon: Array) -> Array:

	for c in calon:
		if String(c[0]) == GameState.god_paksa_event:
			return [c]




	var nilai: = func(c: Array) -> int:
		if bool(c[2]):
			return 3
		var id: = String(c[0])
		if GameState.tahap_event(id) > 0:
			return 1
		return 0 if GameState.janji_hari_ini(id) else 2
	var akhir_jam: = func(c: Array) -> float: return float(c[1].get("jam", [0, 24])[1])

	var urut: Array = calon.duplicate()
	urut.sort_custom( func(a, b):
		var na: int = nilai.call(a)
		var nb: int = nilai.call(b)
		if na != nb:
			return na < nb
		if na == 2 and akhir_jam.call(a) != akhir_jam.call(b):
			return akhir_jam.call(a) < akhir_jam.call(b)
		return calon.find(a) < calon.find(b))
	var batas: = CERITA_PER_PETA_LIBUR if GameState.hari_libur() else 1
	var terpilih: Array = []
	for c in urut:



		var wajib: bool = nilai.call(c) <= 1
		if terpilih.size() >= batas and not wajib:
			break

		if bool(c[2]) and not terpilih.is_empty():
			break
		var tipe: = String(c[1]["npc"])
		if terpilih.any( func(t): return String(t[1]["npc"]) == tipe):
			continue
		var pos: = _v(c[1]["posisi"])
		var dekat: = func(q: Vector2) -> bool: return terpilih.any( func(t): return _v(t[1]["posisi"]).distance_to(q) < JARAK_MIN_TOKOH_CERITA)
		if dekat.call(pos):


			var geser: = _titik_cerita_lain(pos, dekat)
			if geser == Vector2.INF:
				continue
			var t2: Dictionary = (c[1] as Dictionary).duplicate()
			t2["posisi"] = [geser.x, geser.y]
			c = [c[0], t2, c[2]]
		terpilih.append(c)
		if bool(c[2]):
			break
	return terpilih



func _titik_cerita_lain(pos: Vector2, dekat: Callable) -> Vector2:
	var j: = JARAK_MIN_TOKOH_CERITA * 1.3
	for g in [Vector2(j, 0), Vector2( - j, 0), Vector2(j * 0.7, j * 0.6), Vector2( - j * 0.7, j * 0.6), Vector2(0, j * 0.8), 
			Vector2(j * 0.7, - j * 0.5), Vector2( - j * 0.7, - j * 0.5), Vector2(j * 1.8, 0), Vector2( - j * 1.8, 0)]:
		var q: Vector2 = pos + g
		if not dekat.call(q) and _di_lantai_bebas(q):
			return q
	return Vector2.INF


func _di_lantai_bebas(p: Vector2) -> bool:
	var ada: = false
	for poli in lantai:
		if Geometry2D.is_point_in_polygon(p, poli):
			ada = true
			break
	if not ada:
		return false
	for poli in halangan:
		if Geometry2D.is_point_in_polygon(p, poli):
			return false
	return true


func _semua_event_di_sini() -> Array:
	var hasil: Array = []
	var jam: = GameState.menit / 60.0
	for id in GameState.data_event():
		var ev: Dictionary = GameState.data_event()[id]
		var tempat: = {}
		var tetap: = false

		var paksa: = String(id) == GameState.god_paksa_event
		if GameState.hasil_event(id) == "":
			if not paksa and (GameState.hari < int(ev.get("hari_min", 1)) or not GameState.cerita_terbuka(id)):
				continue

			if not paksa and GameState.event_kedaluwarsa(ev, GameState.hari) and GameState.tahap_event(id) == 0:
				continue

			if not paksa and ev.has("setelah") and GameState.hasil_event(String(ev["setelah"])) == "":
				continue



			var ditunda: = GameState.cerita_ditunda(id)
			if not paksa and ( not GameState.cerita_cocok_hasil(ev) or (GameState.tahap_event(id) == 0 and GameState.cerita_menunggu(ev) and not ditunda)):
				continue

			if not paksa and GameState.tahap_event(id) == 0 and ((bool(ev.get("hari_sekolah", false)) and GameState.nama_hari() == "Minggu")\
			or (bool(ev.get("bukan_ramadan", false)) and GameState.ramadan()) or (bool(ev.get("hari_pasar", false)) and not GameState.pasar_buka_hari_ini())):
				continue

			if not paksa and GameState.tahap_event(id) == 0 and GameState.hari_libur() and GameState.event_janji(id)\
			and not GameState.janji_hari_ini(id) and not ditunda:


				continue
			tempat = ev["tahap"][mini(GameState.tahap_event(id), ev["tahap"].size() - 1)]
		elif ev.has("tetap"):
			tempat = ev["tetap"]
			tetap = true
		else:
			continue

		if tempat.has("temui"):
			if _sudah_malam():
				continue
			for sub in GameState.temui_sisa(id):
				if String(sub["area"]) == area_id and not GameState.di_rumah_saat_hujan(String(sub["npc"])):
					var t2: Dictionary = sub.duplicate()
					t2["jam"] = tempat.get("jam", [7, 22])
					t2["_temui"] = true
					hasil.append([id, t2, false])
			continue


		var j: Array = tempat["jam"]
		var sesuai_jam: = jam >= float(j[0]) and jam < float(j[1])
		if GameState.tahap_event(id) > 0 and not tetap and not bool(tempat.get("jam_ketat", false)):
			sesuai_jam = true


		if GameState.di_rumah_saat_hujan(String(tempat["npc"])) and not paksa and not GameState.janji_hari_ini(String(id))\
		and not GameState.cerita_ditunda(String(id)):
			continue

		if _sudah_malam():
			continue
		if String(tempat["area"]) == area_id and sesuai_jam:
			hasil.append([id, tempat, tetap])
	return hasil




const JARAK_ORANG_SAMA: = 80.0

func _orang_di_tempat(tipe: String, pos: Vector2) -> Sprite2D:
	for w in warga:
		if is_instance_valid(w) and w.has_meta("diam") and not w.has_meta("pergi") and String(w.get_meta("tipe")) == tipe\
		and w.position.distance_to(pos) < JARAK_ORANG_SAMA:
			return w
	return null



func _lepas_kembaran(tipe: String) -> void :
	for w in warga.duplicate():
		if not is_instance_valid(w) or w.has_meta("pergi") or String(w.get_meta("tipe")) != tipe:
			continue
		if w.has_meta("diam") and (w.has_meta("diam_area") or w.has_meta("event") or w.has_meta("kerja") or w.has_meta("ronda_warga") or w.has_meta("ngobrol")):
			continue
		_warga_pergi(w)




func _pasang_pendamping(tokoh: Sprite2D, tempat: Dictionary) -> void :
	if tokoh.has_meta("pendamping_terpasang"):
		return
	tokoh.set_meta("pendamping_terpasang", true)
	for pd in tempat.get("pendamping", []):
		var tipe: = String(pd["npc"])
		if GameState.di_rumah_saat_hujan(tipe):
			continue
		var pos: = _v(pd["posisi"])
		if _orang_di_tempat(tipe, pos) != null:
			continue
		_lepas_kembaran(tipe)
		var teman: = _buat_orang(tipe)
		teman.position = pos
		teman.hadap(_v(pd.get("hadap", [0, 1])))
		teman.set_meta("diam", true)
		if teman.karakter != null:
			teman.karakter.hidup = true
		teman.modulate.a = 0.0
		teman.create_tween().tween_property(teman, "modulate:a", 1.0, 0.6)




func _penunggu_di_sini() -> Array:
	var hasil: Array = []
	for id in GameState.data_event():
		if GameState.hasil_event(id) != "":
			continue
		var tahap: Array = GameState.data_event()[id].get("tahap", [])
		var kini: = GameState.tahap_event(id)
		if kini <= 0 or kini >= tahap.size():
			continue
		for j in range(kini + 1, tahap.size()):
			var nanti: Dictionary = tahap[j]
			if String(nanti.get("area", "")) != area_id or not nanti.has("posisi"):
				continue
			for i in kini:
				var dulu: Dictionary = tahap[i]
				if String(dulu.get("area", "")) == area_id and String(dulu.get("npc", "")) == String(nanti.get("npc", "")) and _v(dulu.get("posisi", [0, 0])).distance_to(_v(nanti["posisi"])) < JARAK_ORANG_SAMA:
					hasil.append({"tipe": String(nanti["npc"]), "posisi": _v(nanti["posisi"]), "hadap": _v(nanti.get("hadap", [0, 1]))})
					break
	return hasil


func _penunggu_di(tipe: String, pos: Vector2) -> Dictionary:
	for p in _penunggu_di_sini():
		if p["tipe"] == tipe and (p["posisi"] as Vector2).distance_to(pos) < JARAK_ORANG_SAMA:
			return p
	return {}



func _pasang_penunggu(mau: Array) -> void :
	for p in _penunggu_di_sini():
		var tipe: String = p["tipe"]
		if mau.any( func(m): return String(m[1]["npc"]) == tipe) or GameState.di_rumah_saat_hujan(tipe):
			continue
		if _orang_di_tempat(tipe, p["posisi"]) != null:
			continue
		var sudah: = false
		for w in warga:
			if is_instance_valid(w) and String(w.get_meta("tipe", "")) == tipe and not w.has_meta("pergi") and (w.position as Vector2).distance_to(p["posisi"]) < JARAK_ORANG_SAMA:
				sudah = true
		if sudah:
			continue
		_lepas_kembaran(tipe)
		var o: = _buat_orang(tipe)
		o.position = p["posisi"]
		o.hadap(p["hadap"])
		o.set_meta("diam", true)
		if o.karakter != null:
			o.karakter.hidup = true
		o.modulate.a = 0.0
		o.create_tween().tween_property(o, "modulate:a", 1.0, 0.6)



func _sedang_bercerita(tipe: String) -> bool:
	for w in warga:
		if is_instance_valid(w) and String(w.get_meta("tipe")) == tipe and w.has_meta("event") and not w.has_meta("event_tetap"):
			return true
	return false


func _perbarui_npc_event(paksa: = false) -> void :
	if (sibuk and not paksa) or area.is_empty():
		return
	_perbarui_ronda()
	_perbarui_kerja()
	var mau: = _event_di_sini()
	var ada: = {}
	for w in warga.duplicate():
		if not is_instance_valid(w) or not w.has_meta("event"):
			continue
		var masih: = false
		for m in mau:


			if m[0] == w.get_meta("event") and bool(m[2]) == w.has_meta("event_tetap")\
			and String(w.get_meta("tipe", "")) == String(m[1]["npc"]):
				masih = true
		if masih:
			ada["%s|%s" % [w.get_meta("event"), w.get_meta("tipe", "")]] = true
			continue




		_hapus_penanda(w)
		w.remove_meta("event")
		w.remove_meta("event_tetap")
		w.set_meta("misi_selesai", true)
	for w in warga.duplicate():
		if is_instance_valid(w) and w.has_meta("misi_selesai") and w.has_meta("penjual"):
			w.remove_meta("misi_selesai")
			continue
		if is_instance_valid(w) and w.has_meta("misi_selesai") and not w.has_meta("ngobrol") and not w.has_meta("pergi") and not w.has_meta("event") and not sibuk:

			var dipakai_lagi: = false
			for m in mau:
				if String(m[1]["npc"]) == String(w.get_meta("tipe", "")) and w.position.distance_to(_v(m[1]["posisi"])) < JARAK_ORANG_SAMA:
					dipakai_lagi = true
			if dipakai_lagi:
				w.remove_meta("misi_selesai")
				continue


			if _penunggu_di(String(w.get_meta("tipe", "")), w.position) != {}:
				continue
			_tokoh_pergi_keluar(w)
	_pasang_penunggu(mau)

	if _sudah_malam():
		for w in warga.duplicate():
			if is_instance_valid(w) and w.has_meta("diam_area") and not w.has_meta("pergi") and not w.has_meta("ngobrol") and not w.has_meta("event"):
				_tokoh_pergi_keluar(w)
	for m in mau:
		if ada.has("%s|%s" % [m[0], m[1]["npc"]]):
			continue
		var tempat: Dictionary = m[1]
		var tipe: = String(tempat["npc"])
		var pos: = _v(tempat["posisi"])

		var o: Sprite2D = _orang_di_tempat(tipe, pos)
		if o == null:
			_lepas_kembaran(tipe)
			o = _buat_orang(tipe)
			pos = _tempat_tanpa_tumpuk(pos, o)
			o.position = pos
			o.hadap(_v(tempat.get("hadap", [0, 1])))
			o.set_meta("diam", true)
			if o.karakter != null:
				o.karakter.hidup = true
			o.modulate.a = 0.0
			o.create_tween().tween_property(o, "modulate:a", 1.0, 0.6)


			if bool(tempat.get("ransel", false)) and o.karakter != null:
				o.karakter.pasang_ransel()
			if tempat.has("datang_dari"):
				var jalur_datang: Array = []
				for t in tempat["datang_dari"]:
					jalur_datang.append(_v(t))
				o.position = jalur_datang[0]
				jalur_datang.append(pos)
				o.set_meta("datang", true)
				var arah_akhir: = _v(tempat.get("hadap", [0, 1]))
				o.jalan(jalur_datang.slice(1), KECEPATAN_DATANG_TOKOH)
				o.sampai.connect( func():
					if is_instance_valid(o):
						o.remove_meta("datang")
						o.hadap(arah_akhir), CONNECT_ONE_SHOT)
		o.set_meta("event", m[0])
		if bool(m[2]):
			o.set_meta("event_tetap", true)
		_pasang_pendamping(o, tempat)



func _perbarui_penanda_event() -> void :
	var s: = 1.0 / kamera.zoom.x
	for w in warga:
		if not is_instance_valid(w):
			continue
		var ajak_ronda: = w.has_meta("ronda") and GameState.waktunya_ronda()
		if not (w.has_meta("event") or ajak_ronda) or w.has_meta("event_tetap"):


			_hapus_penanda(w)
			continue
		if w.has_meta("penanda") and ( not is_instance_valid(w.get_meta("penanda")) or (w.get_meta("penanda") as Node).is_queued_for_deletion()):
			w.remove_meta("penanda")
		if not w.has_meta("penanda"):
			var p: = Panel.new()
			var gaya: = StyleBoxFlat.new()
			gaya.bg_color = Color(0.9, 0.12, 0.1)
			gaya.border_color = Color(1, 1, 1)
			gaya.set_border_width_all(3)
			gaya.set_corner_radius_all(20)
			p.add_theme_stylebox_override("panel", gaya)
			p.size = Vector2(40, 40)
			p.mouse_filter = Control.MOUSE_FILTER_IGNORE
			p.z_index = 100
			var tanda: = Label.new()
			tanda.text = "!"
			tanda.add_theme_font_size_override("font_size", 28)
			tanda.add_theme_color_override("font_color", Color.WHITE)
			tanda.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			tanda.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			tanda.size = p.size
			p.add_child(tanda)
			p.set_meta("penanda_cerita", true)
			dunia.add_child(p)
			w.set_meta("penanda", p)


			var id_penanda: = p.get_instance_id()
			w.tree_exiting.connect( func():
				var sisa = instance_from_id(id_penanda)
				if is_instance_valid(sisa):
					sisa.queue_free(), CONNECT_ONE_SHOT)
		var penanda: Control = w.get_meta("penanda")
		penanda.visible = not sibuk and w != warga_dekat
		penanda.scale = Vector2(s, s)
		var naik: = sin(Time.get_ticks_msec() / 200.0) * 5.0 * s
		penanda.position = w.position + Vector2(-20.0 * s, - w.tinggi_badan() - 52.0 * s + naik)


func _hapus_penanda(w: Sprite2D) -> void :
	if w.has_meta("penanda"):
		var p = w.get_meta("penanda")
		if is_instance_valid(p):
			(p as Node).queue_free()
		w.remove_meta("penanda")



func _obrolan_event(tipe: String) -> Array:
	var hasil: Array = []
	for id in GameState.cerita_warga:
		var h: = GameState.hasil_event(id)
		if h != "" and GameState.data_event().has(id):
			hasil.append_array(GameState.data_event()[id].get("obrolan", {}).get(h, {}).get(tipe, []))
	return hasil


func _baris_event(b: Dictionary) -> Dictionary:
	var siapa: = String(b.get("siapa", ""))
	var baris: = {"siapa": siapa, "teks": String(b["teks"]).replace("{warung}", GameState.nama_warung)}
	if siapa != "" and siapa != "bapak":
		baris["nama"] = _nama_tipe(siapa)
	return baris


func _dialog_event(daftar: Array) -> void :
	if daftar.is_empty():
		return
	var baris: Array = []
	for b in daftar:
		baris.append(_baris_event(b))
	dialog.tampilkan(baris)
	await dialog.selesai


func _jalankan_event(w: Sprite2D) -> void :
	var id: = String(w.get_meta("event"))
	var ev: Dictionary = GameState.data_event()[id]
	var tahap: Dictionary = ev["tahap"][GameState.tahap_event(id)]

	w.set_meta("ngobrol", true)
	var arah: = (bapak.position - w.position).normalized()

	if w.karakter != null:
		w.karakter.arah_layar = arah
	if bapak.karakter != null:
		bapak.karakter.arah_layar = - arah
	bapak.sedang_jalan = false
	sibuk = true
	tombol_aksi.hide()
	await _mulai_sinematik(w)
	if tahap.has("temui"):
		await _temui_warga(w, id, tahap)
		return

	if tahap.has("pendamping_sesudah"):
		_serahkan_gendongan(id)
		var pd: Dictionary = tahap["pendamping_sesudah"]

		if bool(pd.get("digendong", false)) and w.karakter != null:
			var cfg: Dictionary = (data_pelanggan[String(pd["npc"])] if data_pelanggan.has(String(pd["npc"])) else data_tokoh[String(pd["npc"])])["model3d"]
			w.karakter.bawa_barang("res://assets/karakter3d/" + String(cfg["file"]), 0.5, true, 0.1)
			w.set_meta("gendong_neo", true)
		else:
			var teman: = _buat_orang(String(pd["npc"]))
			teman.position = w.position + _v(pd.get("geser", [60, 20]))
			teman.hadap(_v(pd.get("hadap", [0, 1])))
			teman.set_meta("diam", true)
			if teman.karakter != null:
				teman.karakter.hidup = true
			teman.modulate.a = 0.0
			teman.create_tween().tween_property(teman, "modulate:a", 1.0, 0.6)
	await _dialog_event(tahap.get("dialog", []))
	var aksi: = String(tahap.get("aksi", ""))
	if tahap.has("pilihan"):


		var semua: Array = (tahap["pilihan"]["opsi"] as Array).filter( func(o):

			return ( not o.has("jika_uang_cukup") or GameState.uang >= int(o["jika_uang_cukup"]))\
			and ( not o.has("jika_uang_kurang") or GameState.uang < int(o["jika_uang_kurang"])))

		if semua.is_empty():
			semua = (tahap["pilihan"]["opsi"] as Array).filter( func(o): return not o.has("jika_uang_cukup"))
		if semua.is_empty():
			semua = tahap["pilihan"]["opsi"]
		semua = GameState.opsi_cerita_lengkap(semua)
		var tombol: Array = []
		for o in semua:
			var biaya: = int(o.get("biaya", 0))

			var cukup: = biaya <= 0 or GameState.uang >= biaya
			tombol.append({"teks": String(o["teks"]) + ("" if cukup else "  (uang belum cukup)"), "aktif": cukup})

		var nomor: = -1
		while true:
			nomor = await dialog.tanya(_baris_event(tahap["pilihan"]["tanya"]), tombol)
			var biaya_pilih: = int(semua[nomor].get("biaya", 0))
			if biaya_pilih <= 0 or await KB.tanya(self, String(ev["judul"]), biaya_pilih, String(semua[nomor]["teks"])):
				break
		var opsi: Dictionary = semua[nomor]
		aksi = String(opsi["aksi"])
		var biaya: = int(opsi.get("biaya", 0))
		if biaya > 0:
			GameState.uang -= biaya
			GameState.catat_transaksi("Cerita warga: %s" % String(ev["judul"]), - biaya)
			GameState.data_berubah.emit()
		await _dialog_event(opsi.get("dialog", []))


		if opsi.has("pergi_ke") and is_instance_valid(w):
			_warga_jalan_pergi(w, opsi["pergi_ke"])


		elif bool(opsi.get("hilang", false)) and is_instance_valid(w):
			_hapus_penanda(w)
			w.remove_meta("event")
			w.remove_meta("event_tetap")
			_warga_pergi(w)
		if opsi.has("maju_menit"):
			GameState.majukan_waktu(float(opsi["maju_menit"]))

		if opsi.has("perjalanan"):
			await _perjalanan(opsi["perjalanan"])
			await _dialog_event(opsi.get("dialog_sesudah", []))
	match aksi:
		"lanjut":
			GameState.majukan_event(id)
		"tunda":

			var cw: Dictionary = GameState.cerita_warga.get(id, {"tahap": 0, "hasil": ""}).duplicate()
			cw["ditunda"] = true
			GameState.cerita_warga[id] = cw
		"tolong", "tolak":
			var h: = GameState.selesaikan_event(id, aksi)
			var p: Dictionary = h.get("popup", {})
			await _akhiri_sinematik()
			if not p.is_empty():
				var popup: = POPUP_HADIAH.new()
				ui.add_child(popup)
				popup.isi(String(p.get("judul", "")), String(p.get("isi", "")), p.get("daftar", []), String(p.get("gambar", "")), aksi == "tolong")
				await popup.ditutup
	await _akhiri_sinematik()
	sibuk = false
	if is_instance_valid(w):
		w.remove_meta("ngobrol")
	_perbarui_npc_event()




func _temui_warga(w: Sprite2D, id: String, tahap: Dictionary) -> void :
	var tipe: = String(w.get_meta("tipe", ""))
	for s in tahap["temui"]:
		if String(s["npc"]) == tipe:
			await _dialog_event(s.get("dialog", []))
	GameState.temui_tandai(id, tipe)
	_hapus_penanda(w)
	w.remove_meta("event")
	var total: = (tahap["temui"] as Array).size()
	var sudah: = GameState.temui_sudah(id).size()
	if sudah >= total:
		await _dialog_event(tahap.get("dialog_selesai", []))
		GameState.majukan_event(id)
	await _akhiri_sinematik()
	sibuk = false
	if is_instance_valid(w):
		w.remove_meta("ngobrol")
	_perbarui_npc_event()
	_perbarui_daftar_misi()
	if sudah < total:
		tampilkan_pesan("%s setuju. Sudah %d dari %d warga." % [_nama_tipe(tipe), sudah, total], 4.0)






const TINGGI_BAR_SINEMA: = 0.12
const ZOOM_SINEMA: = 1.35
const DURASI_SINEMA: = 0.6
var _sinema_aktif: = false
var _bar_sinema: Array[ColorRect] = []
var _ui_sinema: Array = []
var _zoom_sebelum_sinema: = Vector2.ONE
var _tokoh_sinema: = {}
var _lawan_bicara: Sprite2D = null
var _sudah_bicara: = {}


func _mulai_sinematik(w: Sprite2D) -> void :
	if _sinema_aktif:
		return
	_sinema_aktif = true
	_lawan_bicara = w
	var akar: Control = dialog.get_parent()


	_tokoh_sinema = {"bapak": bapak, String(w.get_meta("tipe", "")): w}
	for o in warga:
		if is_instance_valid(o) and o != w and o.has_meta("diam") and o.position.distance_to(w.position) < 420.0:
			var t: = String(o.get_meta("tipe", ""))
			if not _tokoh_sinema.has(t):
				_tokoh_sinema[t] = o
	_sudah_bicara.clear()

	for o in warga:
		if is_instance_valid(o) and o.has_meta("penanda") and is_instance_valid(o.get_meta("penanda")):
			(o.get_meta("penanda") as CanvasItem).hide()

	_ui_sinema.clear()
	for n in akar.get_children():

		if n == dialog or n == tabir or not (n is CanvasItem) or not (n as CanvasItem).visible:
			continue
		(n as CanvasItem).hide()
		_ui_sinema.append(n)

	if _bar_sinema.is_empty():
		for i in 2:
			var bar: = ColorRect.new()
			bar.color = Color.BLACK
			bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
			bar.set_anchors_preset(Control.PRESET_TOP_WIDE if i == 0 else Control.PRESET_BOTTOM_WIDE)
			akar.add_child(bar)
			_bar_sinema.append(bar)
	var h: = get_viewport_rect().size.y * TINGGI_BAR_SINEMA
	for bar in _bar_sinema:
		akar.move_child(bar, dialog.get_index())
		bar.show()
	_bar_sinema[0].offset_top = 0.0
	_bar_sinema[0].offset_bottom = 0.0
	_bar_sinema[1].offset_top = 0.0
	_bar_sinema[1].offset_bottom = 0.0
	dialog.sinematik = true
	if not dialog.baris_dimulai.is_connected(_tokoh_bicara):
		dialog.baris_dimulai.connect(_tokoh_bicara)

	_zoom_sebelum_sinema = kamera.zoom
	var pusat: = (bapak.position + w.position) / 2.0 - Vector2(0, bapak.tinggi_badan() * 0.45)
	var tw: = create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(_bar_sinema[0], "offset_bottom", h, DURASI_SINEMA)
	tw.tween_property(_bar_sinema[1], "offset_top", - h, DURASI_SINEMA)
	tw.tween_property(kamera, "position", pusat, DURASI_SINEMA)
	tw.tween_property(kamera, "zoom", _zoom_sebelum_sinema * ZOOM_SINEMA, DURASI_SINEMA)
	await tw.finished


func _akhiri_sinematik() -> void :
	if not _sinema_aktif:
		return
	_sinema_aktif = false
	dialog.sinematik = false
	if dialog.baris_dimulai.is_connected(_tokoh_bicara):
		dialog.baris_dimulai.disconnect(_tokoh_bicara)
	var tw: = create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(_bar_sinema[0], "offset_bottom", 0.0, DURASI_SINEMA * 0.8)
	tw.tween_property(_bar_sinema[1], "offset_top", 0.0, DURASI_SINEMA * 0.8)
	tw.tween_property(kamera, "position", bapak.position, DURASI_SINEMA * 0.8)
	tw.tween_property(kamera, "zoom", _zoom_sebelum_sinema, DURASI_SINEMA * 0.8)
	await tw.finished
	for bar in _bar_sinema:
		bar.hide()
	for n in _ui_sinema:
		if is_instance_valid(n):
			(n as CanvasItem).show()
	_ui_sinema.clear()
	_tokoh_sinema.clear()
	_lawan_bicara = null




func _tokoh_bicara(siapa: String) -> void :
	if not _sinema_aktif or not _tokoh_sinema.has(siapa):
		return
	if not is_instance_valid(_tokoh_sinema[siapa]):
		return
	var pembicara: Sprite2D = _tokoh_sinema[siapa]
	var lawan = bapak
	if pembicara == bapak:
		lawan = _lawan_bicara if is_instance_valid(_lawan_bicara) else null
	if lawan != null and lawan != pembicara:
		pembicara.hadap(lawan.position - pembicara.position)


	_sudah_bicara[siapa] = true
	for t in _tokoh_sinema:

		if not is_instance_valid(_tokoh_sinema[t]):
			continue
		var o: Sprite2D = _tokoh_sinema[t]
		var ikut: = o == bapak or o == _lawan_bicara or _sudah_bicara.has(t)
		if o != pembicara and ikut and String(t) != "kucing":
			o.hadap(pembicara.position - o.position)
	pembicara.aksi("bicara")




func _perjalanan(p: Dictionary) -> void :
	label_loading.text = String(p.get("teks", "Pak Misran pergi sebentar..."))
	tabir.mouse_filter = Control.MOUSE_FILTER_STOP
	var gelap: = create_tween()
	gelap.tween_property(tabir, "modulate:a", 1.0, 0.45)
	await gelap.finished
	var lama: = float(p.get("detik", 2.8))
	if bool(p.get("langkah", true)):
		var t: = 0.0
		while t < lama:
			GameState.langkah_kaki()
			await GameState.get_tree().create_timer(0.42).timeout
			t += 0.42
	else:
		await GameState.get_tree().create_timer(lama).timeout
	GameState.majukan_waktu(float(p.get("menit", 15)))

	if p.has("saat_gelap"):
		(p["saat_gelap"] as Callable).call()
	var terang: = create_tween()
	terang.tween_property(tabir, "modulate:a", 0.0, 0.45)
	await terang.finished
	tabir.mouse_filter = Control.MOUSE_FILTER_IGNORE








func _bersihkan_warga() -> void :
	for w in warga:
		if is_instance_valid(w):
			_hapus_penanda(w)
			_hapus_koin(w)
			w.queue_free()
	warga.clear()
	waktu_npc_baru = randf_range(1.0, 3.0)


func _buat_orang(tipe: String) -> Sprite2D:
	var cfg: Dictionary = (data_pelanggan[tipe] if data_pelanggan.has(tipe) else data_tokoh[tipe])["model3d"]
	var o: = Sprite2D.new()
	o.set_script(SCRIPT_PELANGGAN)
	o.tinggi_dewasa_latar = float(area["tinggi_dewasa"])
	o.set_meta("tipe", tipe)
	wadah.add_child(o)
	o.atur_3d(cfg, 0.0)
	o.y_berdiri = latar.texture.get_size().y * 0.55
	o.perspektif = area.get("perspektif", [])
	warga.append(o)
	return o


func _pasang_warga_awal() -> void :

	for n in area.get("npc_diam", []):
		var penjual: = bool(n.get("penjual", false))

		if n.has("jam") and not (_penjual_ada(n["jam"]) if penjual else _dalam_jam(n["jam"])):
			continue
		if (GameState.di_rumah_saat_hujan(String(n["tipe"])) and not penjual) or _sudah_malam():
			continue
		var o: = _buat_orang(String(n["tipe"]))
		o.position = _v(n["posisi"])
		o.hadap(_v(n.get("hadap", [0, 1])))
		o.set_meta("diam", true)
		o.set_meta("diam_area", true)
		if penjual:
			o.set_meta("penjual", true)
			o.set_meta("jam_penjual", n["jam"])
			if bool(n.get("jajan", false)):
				o.set_meta("jajan", true)
			if bool(n.get("grosir", false)):
				o.set_meta("grosir", true)
		if o.karakter != null:
			o.karakter.hidup = true

	_munculkan_lintas()

	if jalur_tengah.size() >= 2:
		for i in mini(randi_range(1, 2), _maks_warga() - _pejalan().size()):
			_tambah_pejalan(randf_range(0.15, 0.85))


func _maks_warga() -> int:
	var jam: = GameState.menit / 60.0
	if jam < 5.0:
		return 0
	if jam >= 19.0:
		return 1

	return MAKS_NPC - 1 if GameState.grafik_rendah() else MAKS_NPC




const JAM_WARGA_PULANG: = 22.0

const PENGALI_VARIAN_JALAN: = 0.5
const TIPE_MUDA: = ["anak", "pelajar", "siswi", "santri_putih", "santri_hitam", "giska"]

func _sudah_malam() -> bool:
	var jam: = GameState.menit / 60.0
	return jam >= JAM_WARGA_PULANG or jam < 5.0


func _pejalan() -> Array[Sprite2D]:
	var hasil: Array[Sprite2D] = []
	for w in warga:
		if is_instance_valid(w) and not w.has_meta("diam") and not w.has_meta("pergi"):
			hasil.append(w)
	return hasil



func _tambah_pejalan(mulai: = 0.0) -> void :
	if jalur_tengah.size() < 2:
		return

	var ada: Array = []
	for w in warga:
		if is_instance_valid(w):
			ada.append(VarianBaju.wajah(String(w.get_meta("tipe"))))
	var pilihan: Array = []

	var semua_tipe: Array = data_pelanggan.keys()
	for id in data_tokoh:
		if data_warga["warga"].has(id):
			semua_tipe.append(id)
	var tokoh_cerita: = GameState.tipe_cerita_aktif()
	for id in semua_tipe:


		if _sudah_malam() and VarianBaju.sifat(id) in TIPE_MUDA:
			continue
		if id == "ibu_rumah_tangga" and GameState.bu_ida_di_pasar():
			continue
		if id == "haji_krem" and GameState.grosir_buka():
			continue
		if area_id == "pasar" and not VarianBaju.ada(id):
			continue
		if not ada.has(VarianBaju.wajah(id)) and not tokoh_cerita.has(id) and randf() < GameState.pengali_tipe(id) * float(data_pelanggan.get(id, {}).get("bobot", 1.0)) * (PENGALI_VARIAN_JALAN if VarianBaju.ada(id) else 1.0) and not GameState.di_rumah_saat_hujan(id):
			pilihan.append(id)
	if pilihan.is_empty():
		return

	for e in GameState.pejalan_lintas:
		if String(e["ke"]) == area_id:
			pilihan.erase(String(e["tipe"]))
	if pilihan.is_empty():
		return
	var total: float = panjang_jalur[-1]
	var maju: = randf() < 0.5
	var arah: = 1.0 if maju else -1.0
	var s: = total * mulai if maju else total * (1.0 - mulai)
	var o: = _buat_pejalan(String(pilihan.pick_random()), s, arah)
	if o != null and mulai == 0.0:
		o.modulate.a = 0.0
		o.create_tween().tween_property(o, "modulate:a", 1.0, 0.6)



func _buat_pejalan(tipe: String, s: float, arah: float, kecepatan_mps: = 0.0) -> Sprite2D:
	var lajur: = lebar_lajur * arah

	for w in _pejalan():
		if absf(float(w.get_meta("s")) - s) < _jarak_aman() * 1.5 and is_equal_approx(float(w.get_meta("lajur")), lajur):
			return null
	var o: = _buat_orang(tipe)
	o.arah_manual = true
	o.set_meta("s", s)
	o.set_meta("arah", arah)
	o.set_meta("lajur", lajur)
	o.set_meta("geser", lajur)
	o.set_meta("tunggu", 0.0)
	o.set_meta("tembus", 0.0)



	var mps: float = kecepatan_mps if kecepatan_mps > 0.0 else randf_range(0.8, 0.95) * KECEPATAN_METER * o.faktor_kecepatan * o.skala_model()
	o.set_meta("kecepatan", mps * o.tinggi_dewasa_latar / SCRIPT_PELANGGAN.TINGGI_DEWASA_METER)
	_letakkan_pejalan(o)
	return o








const BATAS_LINTAS_MS: = 180000

func _catat_lintas(w: Sprite2D, sisa_px: float) -> void :
	var uj: Array = area.get("ujung_jalur", ["", ""])
	var arah: = float(w.get_meta("arah"))
	var ke: = String(uj[1] if arah > 0.0 else uj[0])
	var px: float = float(w.get_meta("kecepatan"))
	if ke == "" or px <= 0.0 or w.has_meta("event") or w.has_meta("neo"):
		return
	var sekarang: = Time.get_ticks_msec()
	GameState.pejalan_lintas.append({"tipe": String(w.get_meta("tipe")), "dari": area_id, "ke": ke, 
		"mps": px * SCRIPT_PELANGGAN.TINGGI_DEWASA_METER / float(area["tinggi_dewasa"]), 
		"sampai": sekarang + int(maxf(sisa_px, 0.0) / px * 1000.0), "dicatat": sekarang})



func _catat_semua_lintas() -> void :
	if jalur_tengah.size() < 2:
		return
	var total: float = panjang_jalur[-1]
	for w in _pejalan():
		var s: = float(w.get_meta("s"))
		_catat_lintas(w, total - s if float(w.get_meta("arah")) > 0.0 else s)



func _munculkan_lintas() -> void :
	if jalur_tengah.size() < 2:
		return
	var sekarang: = Time.get_ticks_msec()
	var total: float = panjang_jalur[-1]
	var uj: Array = area.get("ujung_jalur", ["", ""])
	var tokoh_cerita: = GameState.tipe_cerita_aktif()
	var sisa: Array = []
	for e in GameState.pejalan_lintas:
		if sekarang - int(e["dicatat"]) > BATAS_LINTAS_MS:
			continue
		if String(e["ke"]) != area_id or sekarang < int(e["sampai"]):
			sisa.append(e)
			continue
		var tipe: = String(e["tipe"])
		var dari: = String(e["dari"])
		if dari != String(uj[0]) and dari != String(uj[1]):
			continue
		var arah: = 1.0 if dari == String(uj[0]) else -1.0
		var maju: float = (sekarang - int(e["sampai"])) / 1000.0 * float(e["mps"]) * float(area["tinggi_dewasa"]) / SCRIPT_PELANGGAN.TINGGI_DEWASA_METER
		if maju >= total:
			continue

		var ada: = false
		for w in warga:
			if is_instance_valid(w) and VarianBaju.wajah(String(w.get_meta("tipe"))) == VarianBaju.wajah(tipe):
				ada = true
		if ada or tokoh_cerita.has(tipe) or GameState.di_rumah_saat_hujan(tipe) or (_sudah_malam() and VarianBaju.sifat(tipe) in TIPE_MUDA)\
		or ( not data_pelanggan.has(tipe) and not data_tokoh.has(tipe)):
			continue
		var o: = _buat_pejalan(tipe, maju if arah > 0.0 else total - maju, arah, float(e["mps"]))
		if o == null:
			sisa.append(e)
			continue
		if maju < float(area["tinggi_dewasa"]) * 0.8:
			o.modulate.a = 0.0
			o.create_tween().tween_property(o, "modulate:a", 1.0, 0.4)
	GameState.pejalan_lintas = sisa


func _jarak_aman() -> float:
	return float(area["tinggi_dewasa"]) * JARAK_NPC



func _letakkan_pejalan(w: Sprite2D) -> void :
	var t: Array = _titik_jalur(float(w.get_meta("s")))
	var arah_garis: Vector2 = t[1]
	var samping: = Vector2( - arah_garis.y, arah_garis.x)
	w.position = (t[0] as Vector2) + samping * float(w.get_meta("geser"))

	w.karakter.arah_layar = arah_garis * float(w.get_meta("arah"))



func _lajur_terhalang(w: Sprite2D, lajur: float, dekat: float, cek_warga: = true) -> bool:
	var s: float = w.get_meta("s")
	var arah: float = w.get_meta("arah")
	for lain in _pejalan():
		if lain == w or not cek_warga:
			continue
		var depan: = (float(lain.get_meta("s")) - s) * arah
		if depan > - dekat * 0.3 and depan < dekat and absf(float(lain.get_meta("geser")) - lajur) < lebar_lajur:
			return true

	var t: Array = _titik_jalur(s)
	var arah_garis: Vector2 = t[1]
	var ke_bapak: = bapak.position - (t[0] as Vector2)
	var depan_b: = ke_bapak.dot(arah_garis) * arah
	var samping_b: = ke_bapak.dot(Vector2( - arah_garis.y, arah_garis.x))
	return depan_b > 0.0 and depan_b < dekat and absf(samping_b - lajur) < lebar_lajur * 1.5




func _geser_elak_bapak(w: Sprite2D, lajur: float, dekat: float) -> float:
	var s: float = w.get_meta("s")
	var arah: float = w.get_meta("arah")
	var t: Array = _titik_jalur(s)
	var arah_garis: Vector2 = t[1]
	var samping: = Vector2( - arah_garis.y, arah_garis.x)
	var ke_bapak: = bapak.position - (t[0] as Vector2)
	var depan_b: = ke_bapak.dot(arah_garis) * arah
	var samping_b: = ke_bapak.dot(samping)
	if depan_b < - dekat * 0.2 or depan_b > dekat * 1.3 or absf(samping_b - lajur) >= lebar_lajur * 1.5:
		return NAN
	var jarak: = lebar_lajur * 1.8
	var utama: = -1.0 if samping_b >= lajur else 1.0
	for tanda in [utama, - utama]:
		var geser_elak: float = samping_b + float(tanda) * jarak

		var titik: Vector2 = (t[0] as Vector2) + samping * geser_elak + arah_garis * arah * minf(depan_b, dekat * 0.5)
		if _titik_lantai_bebas(titik) and _titik_lantai_bebas((t[0] as Vector2) + samping * geser_elak):
			return geser_elak
	return NAN


func _gerak_warga(delta: float) -> void :
	_munculkan_lintas()
	waktu_npc_baru -= delta
	if waktu_npc_baru <= 0.0:
		waktu_npc_baru = randf_range(4.0, 9.0)
		if _pejalan().size() < _maks_warga():
			_tambah_pejalan()
	var dekat: = _jarak_aman()
	for w in _pejalan():
		if w.has_meta("ngobrol"):
			continue
		var lajur: float = w.get_meta("lajur")
		var tembus: float = maxf(float(w.get_meta("tembus")) - delta, 0.0)
		w.set_meta("tembus", tembus)
		var jalan: = true

		var elak: = _geser_elak_bapak(w, lajur, dekat)
		if not is_nan(elak):
			w.set_meta("elak", elak)
		elif w.has_meta("elak"):
			w.remove_meta("elak")
		var tujuan_geser: float = w.get_meta("elak") if w.has_meta("elak") else lajur

		if not w.has_meta("elak") and _lajur_terhalang(w, lajur, dekat, tembus <= 0.0):

			if not _lajur_terhalang(w, - lajur, dekat):
				lajur = - lajur
				w.set_meta("lajur", lajur)
			else:
				jalan = false
		if not jalan:
			w.sedang_jalan = false
			w.set_meta("tunggu", float(w.get_meta("tunggu")) + delta)

			if float(w.get_meta("tunggu")) > SABAR_NPC:
				w.set_meta("tembus", 1.5)
				w.set_meta("tunggu", 0.0)
			continue
		w.set_meta("tunggu", 0.0)
		var kecepatan: float = w.get_meta("kecepatan")
		w.set_meta("s", float(w.get_meta("s")) + kecepatan * delta * float(w.get_meta("arah")))
		if w.has_meta("elak"):
			tujuan_geser = w.get_meta("elak")

			var kurang: = absf(float(w.get_meta("geser")) - tujuan_geser)
			if kurang > lebar_lajur * 0.6:
				w.set_meta("s", float(w.get_meta("s")) - kecepatan * delta * float(w.get_meta("arah")) * 0.6)
			w.set_meta("geser", move_toward(float(w.get_meta("geser")), tujuan_geser, kecepatan * 0.9 * delta))
		else:
			w.set_meta("geser", move_toward(float(w.get_meta("geser")), lajur, kecepatan * 0.45 * delta))
		_letakkan_pejalan(w)
		w.sedang_jalan = true
		var s: float = w.get_meta("s")
		if s < 0.0 or s > panjang_jalur[-1]:
			_catat_lintas(w, 0.0)
			_warga_pergi(w)


func _warga_jalan_pergi(w: Sprite2D, titik: Array) -> void :
	_hapus_penanda(w)
	w.remove_meta("event")
	w.remove_meta("event_tetap")
	w.set_meta("pergi", true)
	w.set_meta("pergi_jalan", true)
	var jalur: Array = []
	for p in titik:
		jalur.append(_v(p))
	if w.karakter != null:
		w.karakter.hidup = false
	w.jalan(jalur, float(area.get("tinggi_dewasa", 150)) * 0.75)
	await w.sampai
	if is_instance_valid(w):
		w.remove_meta("pergi_jalan")
		_warga_pergi(w)




func _tempat_tanpa_tumpuk(pos: Vector2, kecuali: Sprite2D) -> Vector2:
	var jari: = float(area.get("tinggi_dewasa", 150)) * JARI_BADAN * 2.4
	var geser: = [Vector2.ZERO]
	for r in [1.0, 1.6, 2.2]:
		for arah in [Vector2(1, 0), Vector2(-1, 0), Vector2(1, 0.5), Vector2(-1, 0.5), Vector2(1, -0.5), Vector2(-1, -0.5), Vector2(0, 0.6), Vector2(0, -0.6)]:
			geser.append(arah * jari * r)
	for d in geser:
		var p: Vector2 = pos + d
		if d != Vector2.ZERO and not _titik_lantai_bebas(p):
			continue
		var kosong: = true
		for w in warga:
			if is_instance_valid(w) and w != kecuali and not w.has_meta("pergi") and _jarak_lantai(p, w.position) < jari:
				kosong = false
				break
		if kosong:
			return p
	return pos




const KECEPATAN_PERGI_TOKOH: = 95.0

func _tokoh_pergi_keluar(w: Sprite2D) -> void :
	if jalur_tengah.size() < 2:
		_warga_pergi(w)
		return
	w.set_meta("pergi", true)
	w.remove_meta("diam")
	_hapus_penanda(w)
	if w.karakter != null:
		w.karakter.hidup = false
	var dekat: = 0
	for i in jalur_tengah.size():
		if jalur_tengah[i].distance_to(w.position) < jalur_tengah[dekat].distance_to(w.position):
			dekat = i


	var rute: Array = []
	var jalan_kaki: = _rute_lantai(w.position, jalur_tengah[dekat])

	if jalan_kaki.size() == 1 and not _garis_lantai_bebas(w.position, jalur_tengah[dekat]):
		w.remove_meta("pergi")
		_warga_pergi(w)
		return
	var gabung: = jalur_tengah[dekat]
	var s_gabung: = panjang_jalur[dekat]
	for p in jalan_kaki:
		var titik_jalur: = _titik_terdekat_jalur(p)
		if p.distance_to(titik_jalur[0]) < lebar_lajur * 2.0 + 12.0:
			gabung = titik_jalur[0]
			s_gabung = titik_jalur[1]
			break
		rute.append(p)
	rute.append(gabung)
	if s_gabung < panjang_jalur[-1] / 2.0:
		for i in range(jalur_tengah.size() - 1, -1, -1):
			if panjang_jalur[i] < s_gabung:
				rute.append(jalur_tengah[i])
	else:
		for i in jalur_tengah.size():
			if panjang_jalur[i] > s_gabung:
				rute.append(jalur_tengah[i])
	w.tree_exiting.connect( func(): warga.erase(w), CONNECT_ONE_SHOT)
	w.pergi_pelan(rute, KECEPATAN_PERGI_TOKOH)



func _titik_terdekat_jalur(p: Vector2) -> Array:
	var hasil: Array = [jalur_tengah[0], 0.0]
	var terbaik: = INF
	for i in jalur_tengah.size() - 1:
		var t: = Geometry2D.get_closest_point_to_segment(p, jalur_tengah[i], jalur_tengah[i + 1])
		var d: = p.distance_to(t)
		if d < terbaik:
			terbaik = d
			hasil = [t, panjang_jalur[i] + jalur_tengah[i].distance_to(t)]
	return hasil





const SEL_RUTE: = 10.0

var _astar_rute: AStarGrid2D = null
var _kunci_astar: = ""

func _kotak_rute() -> AStarGrid2D:
	var kunci: = "%s:%d:%d" % [str(area.get("gambar", "")), lantai.size(), halangan.size()]
	if _astar_rute != null and kunci == _kunci_astar:
		return _astar_rute
	var kotak: = Rect2()
	var awal: = true
	for poli in lantai:
		for t in poli:
			kotak = Rect2(t, Vector2.ZERO) if awal else kotak.expand(t)
			awal = false
	var astar: = AStarGrid2D.new()
	astar.region = Rect2i(Vector2i((kotak.position / SEL_RUTE).floor()) - Vector2i.ONE, Vector2i((kotak.size / SEL_RUTE).ceil()) + Vector2i(3, 3))
	astar.cell_size = Vector2(SEL_RUTE, SEL_RUTE)
	astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	astar.update()
	var r: = astar.region
	var tengah: = Vector2(SEL_RUTE, SEL_RUTE) / 2.0
	for x in range(r.position.x, r.end.x):
		for y in range(r.position.y, r.end.y):
			astar.set_point_solid(Vector2i(x, y), not _titik_lantai_bebas(Vector2(x, y) * SEL_RUTE + tengah))
	_astar_rute = astar
	_kunci_astar = kunci
	return astar


func _rute_lantai(dari: Vector2, ke: Vector2) -> Array:
	if lantai.is_empty():
		return [ke]
	var astar: = _kotak_rute()
	var a: = _sel_bebas_terdekat(astar, dari)
	var b: = _sel_bebas_terdekat(astar, ke)
	if a == Vector2i(-99999, -99999) or b == Vector2i(-99999, -99999):
		return [ke]
	var titik: Array = []
	for t in astar.get_point_path(a, b):
		titik.append(t + Vector2(SEL_RUTE, SEL_RUTE) / 2.0)
	if titik.is_empty():
		return [ke]
	titik.append(ke)

	var rapi: Array = []
	var sekarang: = dari
	var i: = 0
	while i < titik.size():
		var j: = titik.size() - 1
		while j > i and not _garis_lantai_bebas(sekarang, titik[j]):
			j -= 1
		sekarang = titik[j]
		rapi.append(sekarang)
		i = j + 1
	return rapi


func _sel_bebas_terdekat(astar: AStarGrid2D, p: Vector2) -> Vector2i:
	var sel: = Vector2i((p / SEL_RUTE).floor())
	for jari in 8:
		for dx in range( - jari, jari + 1):
			for dy in range( - jari, jari + 1):
				var c: = sel + Vector2i(dx, dy)
				if maxi(absi(dx), absi(dy)) == jari and astar.is_in_boundsv(c) and not astar.is_point_solid(c):
					return c
	return Vector2i(-99999, -99999)


func _garis_lantai_bebas(a: Vector2, b: Vector2) -> bool:
	var n: = int(ceil(a.distance_to(b) / (SEL_RUTE * 0.5)))
	for k in range(1, n):
		if not _titik_lantai_bebas(a.lerp(b, float(k) / n)):
			return false
	return true


func _warga_pergi(w: Sprite2D) -> void :
	w.set_meta("pergi", true)
	w.sedang_jalan = false
	var tween: = w.create_tween()
	tween.tween_property(w, "modulate:a", 0.0, 0.5)
	tween.tween_callback( func():
		warga.erase(w)
		w.queue_free())





const SCRIPT_WARUNG: = preload("res://scripts/warung.gd")
const SCRIPT_OBJEK3D: = preload("res://scripts/objek3d.gd")

func _pasang_upgrade() -> void :
	for anak in wadah.get_children() + dunia.get_children():
		if anak.has_meta("upgrade"):
			anak.queue_free()
	if not bool(area.get("upgrade_warung", false)):
		return
	var ppm: float = SCRIPT_WARUNG.PIKSEL_PER_METER_OBJEK
	for u in GameState.daftar_upgrade + GameState.daftar_dekorasi:
		var id: String = u["id"]
		var v: Dictionary = u.get("visual", {})
		var tampil: = GameState.terbuka(String(u["barang"])) if u.has("barang") else GameState.punya_upgrade(id)

		if u.has("wishlist"):
			tampil = GameState.punya_wishlist(String(u["wishlist"]))
		if u.has("ikut"):
			tampil = GameState.punya_upgrade(String(u["ikut"]))
		for lain in GameState.upgrade_dimiliki:
			if GameState.data_upgrade(lain).get("visual", {}).get("ganti", "") == id:
				tampil = false
		if not tampil:
			continue
		if v.get("spanduk", false):
			var font: = FontVariation.new()
			font.base_font = load("res://assets/font/BebasNeue.ttf")
			font.spacing_glyph = 1
			var sp: Node2D = SCRIPT_WARUNG.rakit_spanduk(SCRIPT_WARUNG.POSISI_SPANDUK, font)
			sp.set_meta("upgrade", true)
			dunia.add_child(sp)
			dunia.move_child(sp, wadah.get_index())
		elif v.has("model"):
			if v.has("di_atas"):
				v = SCRIPT_WARUNG.posisi_di_atas(v, ppm)
			else:
				halangan.append(SCRIPT_WARUNG.jejak_upgrade(v, ppm))
			var obj: Sprite2D = SCRIPT_OBJEK3D.new()
			obj.set_meta("upgrade", true)
			obj.position = Vector2(v["posisi"][0], v["posisi"][1])
			wadah.add_child(obj)
			if not obj.pasang(SCRIPT_WARUNG.FOLDER_MODEL_UPGRADE + String(v["model"]), float(v.get("tinggi_m", 1.0)), ppm, v):
				obj.queue_free()
			elif v.has("potong"):
				var g: Array = v["potong"]["garis"]
				obj.potong(Vector2(g[0][0], g[0][1]), Vector2(g[1][0], g[1][1]), float(v["potong"].get("sisi", 1.0)))







const SCRIPT_KENDARAAN: = preload("res://scripts/kendaraan.gd")
const JEDA_KENDARAAN: = 10.0
const SKALA_KENDARAAN: = 1.035
var lalu_lintas: Node2D
var waktu_kendaraan: = 2.0
const URUTAN_KENDARAAN: = ["angkot", "motor", "mobil", "motor", "bak", "motor", "mobil"]
var giliran_kendaraan: = 0
var calon_kendaraan: = {}


func _siapkan_lalu_lintas() -> void :
	for k in lalu_lintas.get_children():
		k.queue_free()
	waktu_kendaraan = 2.0
	if awas_kendaraan != null:
		awas_kendaraan.hide()
	if not area.has("jalan"):
		return
	dunia.move_child(lalu_lintas, wadah.get_index() + (1 if bool(area["jalan"].get("di_depan", true)) else 0))
	_ikon_angkot_di_bawah_lalu_lintas()





func _ikon_angkot_di_bawah_lalu_lintas() -> void :
	for n in dunia.get_children():
		if n.has_meta("penanda_angkot") and n.get_index() > lalu_lintas.get_index():
			dunia.move_child(n, lalu_lintas.get_index())


func _ada_kendaraan() -> bool:
	for k in lalu_lintas.get_children():
		if not k.is_queued_for_deletion():
			return true
	return false


func _gerak_kendaraan(delta: float) -> void :
	if not area.has("jalan"):
		return
	waktu_kendaraan -= delta

	if waktu_kendaraan <= 0.0 and not _ada_kendaraan() and not _jalan_sepi() and not _adegan_angkot:
		waktu_kendaraan = JEDA_KENDARAAN * (1.6 if GameState.grafik_rendah() else 1.0)
		_tambah_kendaraan()
	for k in lalu_lintas.get_children():
		if k.is_queued_for_deletion() or k.has_meta("adegan"):
			continue

		var rem: = 0.35 if GameState.efek_cerita("zebra_aman") < 1.0 and _di_zebra() else 1.0
		k.jarak += k.kecepatan * delta * rem
		k.position = k.titik_lajur(k.jarak)

		if area["jalan"].has("pudar_x"):
			var pudar: Array = area["jalan"]["pudar_x"]
			k.modulate.a = clampf((k.position.x - float(pudar[0])) / (float(pudar[1]) - float(pudar[0])), 0.0, 1.0)
		_bunyi_kendaraan_lewat(k)
		if k.jarak > k.panjang_lajur():
			k.queue_free()


func _jalan_sepi() -> bool:
	var jam: = GameState.menit / 60.0
	return jam >= 23.0 or jam < 4.0



func _titik_terdekat_lajur(lajur: Array, titik: Vector2) -> Vector2:
	var terdekat: = INF
	var jarak_lajur: = 0.0
	var tempuh: = 0.0
	for i in lajur.size() - 1:
		var a: Vector2 = lajur[i]
		var b: Vector2 = lajur[i + 1]
		var pada: = Geometry2D.get_closest_point_to_segment(titik, a, b)
		var d: = titik.distance_to(pada)
		if d < terdekat:
			terdekat = d
			jarak_lajur = tempuh + a.distance_to(pada)
		tempuh += a.distance_to(b)
	return Vector2(jarak_lajur, terdekat)








const DETIK_AWAS: = 4.5
const DETIK_GENTING: = 2.0
const JARAK_AWAS_ZEBRA: = 1.6
const NAMA_KENDARAAN: = {"angkot": "ANGKOT", "motor": "MOTOR", "mobil": "MOBIL", "bak": "MOBIL BAK"}
const SCRIPT_AWAS: = preload("res://scripts/awas_kendaraan.gd")
var awas_kendaraan: Node2D = null



func _ppm_kendaraan() -> float:
	return float(area.get("tinggi_kendaraan", area["tinggi_dewasa"])) / SCRIPT_PELANGGAN.TINGGI_DEWASA_METER * SKALA_KENDARAAN



func _calon_kendaraan() -> Dictionary:
	if calon_kendaraan.is_empty():
		var jenis: String = URUTAN_KENDARAAN[giliran_kendaraan % URUTAN_KENDARAAN.size()]
		giliran_kendaraan += 1
		calon_kendaraan = {"jenis": jenis, "ke_kanan": randf() < 0.5, 
			"mps": randf_range(7.0, 9.5) if jenis == "motor" else randf_range(5.0, 7.5)}
	return calon_kendaraan



func _kendaraan_mendekat(titik: Vector2) -> Dictionary:
	var hasil: = {}
	for k in lalu_lintas.get_children():
		if k.is_queued_for_deletion() or k.kecepatan <= 0.0:
			continue
		var detik: float = (_titik_terdekat_lajur(k.lajur, titik).x - k.jarak) / k.kecepatan
		if detik > -0.3 and (hasil.is_empty() or detik < float(hasil["detik"])):
			hasil = {"detik": detik, "jenis": k.jenis, "lajur": k.lajur, "kendaraan": k}

	if not _ada_kendaraan() and not _jalan_sepi():
		var c: = _calon_kendaraan()
		var lajur: Array = []
		for t in area["jalan"]["lajur_kanan" if bool(c["ke_kanan"]) else "lajur_kiri"]:
			lajur.append(_v(t))
		var detik: float = maxf(waktu_kendaraan, 0.0) + _titik_terdekat_lajur(lajur, titik).x / (float(c["mps"]) * _ppm_kendaraan())
		hasil = {"detik": detik, "jenis": c["jenis"], "lajur": lajur, "kendaraan": null}
	return hasil


func _perbarui_awas_kendaraan() -> void :
	if poligon_zebra.is_empty() or not area.has("jalan") or GameState.mode_latihan or GameState.tutorial_langkah != "" or not GameState.pernah_tertabrak():
		if awas_kendaraan != null:
			awas_kendaraan.hide()
		return
	var z: Dictionary = area["zebra"]
	var tinggi: = float(area.get("tinggi_dewasa", 150))
	var titik: = Geometry2D.get_closest_point_to_segment(bapak.position, _v(z["dekat"]), _v(z["jauh"]))
	var bahaya: = {}
	if bapak.position.distance_to(titik) < tinggi * JARAK_AWAS_ZEBRA:
		bahaya = _kendaraan_mendekat(titik)
	if bahaya.is_empty() or float(bahaya["detik"]) > DETIK_AWAS:
		if awas_kendaraan != null:
			awas_kendaraan.hide()
		return
	if awas_kendaraan == null:
		awas_kendaraan = SCRIPT_AWAS.new()
		ui.add_child(awas_kendaraan)
	var detik: = float(bahaya["detik"])
	var genting: = detik < DETIK_GENTING and _di_zebra()
	var lajur: Array = bahaya["lajur"]
	var dari_kiri: bool = (lajur[0] as Vector2).x < (lajur[-1] as Vector2).x
	var teks: = "AWAS %s DARI %s!" % [NAMA_KENDARAAN.get(String(bahaya["jenis"]), "KENDARAAN"), "KIRI" if dari_kiri else "KANAN"]
	awas_kendaraan.tampil(teks, ((lajur[0] as Vector2) - (lajur[-1] as Vector2)).normalized(), genting)

	var layar: = get_viewport().get_visible_rect().size
	var kaki: = bapak.get_global_transform_with_canvas().origin
	var di_atas: = kaki - Vector2(0, tinggi * kamera.zoom.y + 90.0)
	awas_kendaraan.position = Vector2(clampf(di_atas.x, 220.0, layar.x - 220.0), clampf(di_atas.y, 120.0, layar.y - 120.0))
	var k = bahaya["kendaraan"]
	if genting and k != null and not k.has_meta("klakson"):
		k.set_meta("klakson", true)
		GameState.bunyi("klakson_motor" if k.jenis == "motor" else "klakson_mobil", -4.0)





const SUARA_LEWAT: = {"motor": ["res://assets/suara/motor_lewat.ogg", 2.7], "mobil": ["res://assets/suara/mobil_lewat.ogg", 3.75]}
const JARAK_SUARA_MAKS: = 40.0

func _bunyi_kendaraan_lewat(k) -> void :
	if k.has_meta("bunyi") or bapak == null or k.kecepatan <= 0.0:
		return
	var data_suara: Array = SUARA_LEWAT["motor" if k.jenis == "motor" else "mobil"]
	if not ResourceLoader.exists(data_suara[0]):
		k.set_meta("bunyi", true)
		return

	var dekat: = _titik_terdekat_lajur(k.lajur, bapak.position)
	var terdekat: = dekat.y
	var detik_sampai: float = (dekat.x - k.jarak) / k.kecepatan
	var puncak: = float(data_suara[1])
	if detik_sampai > puncak:
		return

	if detik_sampai < -1.5:
		k.set_meta("bunyi", true)
		return

	var ppm: = float(area["tinggi_dewasa"]) / SCRIPT_PELANGGAN.TINGGI_DEWASA_METER
	var meter: = terdekat / ppm
	if meter > JARAK_SUARA_MAKS:
		return
	k.set_meta("bunyi", true)
	var p: = AudioStreamPlayer.new()
	p.stream = load(data_suara[0])
	p.volume_db = lerpf(0.0, -20.0, clampf((meter - 3.0) / (JARAK_SUARA_MAKS - 3.0), 0.0, 1.0))
	p.pitch_scale = randf_range(0.95, 1.05)
	p.bus = "Sekitar"

	add_child(p)
	p.finished.connect(p.queue_free)
	p.play(maxf(puncak - detik_sampai, 0.0))


func _tambah_kendaraan() -> void :

	var calon: = _calon_kendaraan()
	calon_kendaraan = {}
	var ke_kanan: bool = calon["ke_kanan"]
	var titik: Array = area["jalan"]["lajur_kanan" if ke_kanan else "lajur_kiri"]
	var jenis: String = calon["jenis"]
	var ppm: = _ppm_kendaraan()
	var k: = SCRIPT_KENDARAAN.new()
	k.lajur.clear()
	for t in titik:
		k.lajur.append(_v(t))
	k.position = k.lajur[0]
	if area["jalan"].has("pudar_x") and k.position.x < float(area["jalan"]["pudar_x"][1]):
		k.modulate.a = 0.0
	lalu_lintas.add_child(k)
	var hadap_jalan: Array = area["jalan"].get("hadap", [135.0, -45.0])
	if not k.siapkan(jenis, ppm, ke_kanan, float(hadap_jalan[0 if ke_kanan else 1])):
		k.queue_free()
		return
	if area["jalan"].has("kabur"):
		k.atur_kabur(float(area["jalan"]["kabur"]))
	k.kecepatan = float(calon["mps"]) * ppm




func _tidur() -> void :


	var dikecualikan: = GameState.tutorial_langkah in ["pulang", "tidur"] or GameState.mode_latihan\
	or GameState.energi < GameState.ENERGI_MIN_BUKA
	if GameState.menit < GameState.JAM_BOLEH_TIDUR and not dikecualikan:
		buka_dialog("belum_malam" if GameState.menit < GameState.JAM_BOLEH_TUTUP else "masih_sore")
		return

	if _wajib_ronda():
		buka_dialog("harus_ronda")
		tampilkan_pesan("Malam Jumat giliran ronda. Temui Pak RT di pos ronda (area Rumah Warga) sebelum tidur.", 6.0)
		return
	sibuk = true
	tombol_aksi.hide()
	pesan.text = ""







	var kasur: = _v(area["kasur"])
	var samping: Vector2 = _v(area["muncul"]["kasur"])
	var arah: Vector2 = _v(area["arah_kasur"]).normalized() if area.has("arah_kasur") else ARAH_KASUR
	var ppm: = float(area.get("tinggi_dewasa", 150)) / SCRIPT_PELANGGAN.TINGGI_DEWASA_METER
	var sin_k: = sin(deg_to_rad(bapak.karakter.SUDUT_KAMERA))

	var kaki_tanah: = Vector2(arah.x, arah.y / sin_k).normalized()
	var keluar_tanah: = Vector2( - kaki_tanah.y, kaki_tanah.x)
	var ke_samping: = samping - kasur
	if keluar_tanah.dot(Vector2(ke_samping.x, ke_samping.y / sin_k)) < 0.0:
		keluar_tanah = - keluar_tanah
	var keluar: = Vector2(keluar_tanah.x, keluar_tanah.y * sin_k)
	var berdiri: = kasur + Vector2(keluar_tanah.x, keluar_tanah.y * sin_k) * LANGKAH_DUDUK_M * ppm
	if bapak.position.distance_to(berdiri) > 4.0:
		bapak.jalan([berdiri], KECEPATAN_METER * ppm)
		await bapak.sampai
	bapak.sedang_jalan = false
	bapak.karakter.hadap_langsung(keluar)
	bapak.bayangan.hide()

	bapak.z_index = 5

	bapak.atur_lebar_bingkai(LEBAR_BINGKAI_TIDUR)
	if area.get("luruskan_kaki_tidur", false):
		bapak.karakter.luruskan_kaki(true, 3.4, 1.5)

	var duduk: = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	duduk.tween_property(bapak, "position", kasur, BAUR_DUDUK_TIDUR)

	duduk.tween_method( func(t: float):
		bapak.karakter.arah_layar = keluar.slerp(arah, t), 0.0, 1.0, 1.2).set_delay(0.3)
	bapak.karakter.mainkan_tahan_baur("sleep", BAUR_DUDUK_TIDUR)
	await GameState.get_tree().create_timer(BAUR_DUDUK_TIDUR + 0.3 + 1.2).timeout
	bapak.karakter.hadap_langsung(arah)
	await GameState.get_tree().create_timer(maxf(5.7 - (BAUR_DUDUK_TIDUR + 1.5), 0.5)).timeout
	await GameState.get_tree().create_timer(0.8).timeout
	await _istirahat("Selamat tidur, Pak Misran...\n\nPermainan disimpan.")






const BIAYA_PINGSAN: = 20000

func _pingsan() -> void :
	sibuk = true
	tombol_aksi.hide()
	pesan.text = ""
	bapak.sedang_jalan = false
	var bayar: = mini(BIAYA_PINGSAN, maxi(GameState.uang, 0))
	if bayar > 0:
		GameState.uang -= bayar
		GameState.catat_transaksi("Mantri (Pak Misran pingsan kecapekan)", - bayar)
	GameState.data_berubah.emit()
	await _istirahat("Pak Misran pingsan karena kecapekan...\n\nWarga membawanya pulang dan memanggil mantri (%s).\n\nPermainan disimpan." % GameState.format_rupiah(bayar), true, true, "pingsan")







const OBROLAN_SEMBUH: = [
	[{"siapa": "warga", "teks": "Ya Allah, Pak Misran! Katanya kemarin hampir ketabrak di jalan depan? Sudah sehat, Pak?"}, 
		{"siapa": "bapak", "teks": "Alhamdulillah sudah mendingan. Masih agak pegal saja."}], 
	[{"siapa": "warga", "teks": "Pak Misran, gimana kakinya? Sekampung pada khawatir lho waktu dengar sirene ambulans."}, 
		{"siapa": "bapak", "teks": "Sudah bisa jalan lagi, alhamdulillah. Makasih sudah ditanyakan."}], 
	[{"siapa": "warga", "teks": "Lain kali hati-hati nyeberang, Pak. Motor di jalan itu suka ngebut."}, 
		{"siapa": "bapak", "teks": "Iya, kapok. Sekarang lihat kiri-kanan dulu."}], 
	[{"siapa": "warga", "teks": "Sudah sembuh, Pak? Jangan dipaksa kerja berat dulu, ya."}, 
		{"siapa": "bapak", "teks": "Insyaallah pelan-pelan. Hatur nuhun perhatiannya."}], 
]

func _buka_pintu(p: Dictionary) -> void :
	if sibuk:
		return
	_jalankan(String(p["aksi"]))




var poligon_zebra: = PackedVector2Array()

func _bentuk_zebra(z: Dictionary) -> PackedVector2Array:
	var lintas: = (_v(z["jauh"]) - _v(z["dekat"])).normalized()
	var sambung: = lintas * float(area.get("tinggi_dewasa", 150)) * 0.35
	var dekat: = _v(z["dekat"]) - sambung
	var jauh: = _v(z["jauh"]) + sambung
	var lebar: = _v(z["arah_jalan"]).normalized() * float(z["panjang"]) * 0.4
	return PackedVector2Array([dekat - lebar, dekat + lebar, jauh + lebar, jauh - lebar])






func _di_zebra() -> bool:
	return not poligon_zebra.is_empty() and Geometry2D.is_point_in_polygon(bapak.position, poligon_zebra)


func _cek_tertabrak() -> bool:


	if sibuk or GameState.mode_latihan or GameState.tutorial_langkah != "" or ikuti_kerja != "" or not _di_zebra():
		return false
	var tinggi: = float(area.get("tinggi_dewasa", 150))
	for k in lalu_lintas.get_children():
		if k.is_queued_for_deletion() or k.kecepatan <= 0.0:
			continue
		var arah: Vector2 = (k.titik_lajur(k.jarak + 10.0) - k.position).normalized()
		var d: Vector2 = bapak.position - k.position
		var panjang: float = float(k.MODEL[k.jenis]["panjang_m"]) * float(k._ppm)


		var sejajar: = d.dot(arah)
		var celah: = sejajar - panjang * BUMPER_DEPAN
		if celah < tinggi * JARAK_REM and sejajar > - panjang * 0.4 and absf(d.cross(arah)) < tinggi * 0.3:
			_tertabrak(arah, k, celah)
			return true
	return false






const JARAK_REM: = 0.3
const SISA_JARAK_REM: = 0.15
const POTONG_JATUH: = 1.0
const BATAS_POTONG: = 2.5
const JEDA_SIRENE: = 3.4
const GESER_JATUH: = 1.3
const BUMPER_DEPAN: = 0.55

func _tertabrak(dorong: = Vector2.ZERO, kendaraan = null, celah: = 0.0) -> void :
	sibuk = true


	_batal_ikuti()
	_jumatan_jalan_sendiri = false

	GameState.tabrakan_tertunda = true
	GameState.simpan()
	tombol_aksi.hide()
	pesan.text = ""

	GameState.hentikan_musik()
	GameState.putar_musik("tertabrak")
	bapak.sedang_jalan = false


	GameState.bunyi("tabrakan")
	if kendaraan != null and is_instance_valid(kendaraan):
		GameState.bunyi("klakson_motor" if kendaraan.jenis == "motor" else "klakson_mobil")
	if dorong != Vector2.ZERO:
		bapak.karakter.arah_layar = - dorong
	bapak.atur_lebar_bingkai(1500, 2.6)


	var ke_rumah: = dorong.x < 0.0
	if kendaraan != null and is_instance_valid(kendaraan):
		ke_rumah = (kendaraan.titik_lajur(kendaraan.jarak + 10.0) - kendaraan.position).x < 0.0
	bapak.z_index = 0 if ke_rumah else 2
	bapak.karakter.mainkan_tahan("Knock_Down")
	var tinggi: = float(area.get("tinggi_dewasa", 150))
	var sisa_rem: = maxf(celah + tinggi * (GESER_JATUH - SISA_JARAK_REM), 0.0)
	var jarak_awal: = 0.0

	var lama_rem: = 0.9
	if kendaraan != null and is_instance_valid(kendaraan):
		jarak_awal = kendaraan.jarak
		if kendaraan.kecepatan > 1.0:
			lama_rem = clampf(2.0 * sisa_rem / kendaraan.kecepatan, 0.35, 1.2)
	var t: = 0.0
	while bapak.karakter.posisi_animasi() < POTONG_JATUH and t < BATAS_POTONG:
		await get_tree().process_frame
		t += get_process_delta_time()
		if kendaraan != null and is_instance_valid(kendaraan):
			kendaraan.jarak = jarak_awal + sisa_rem * (1.0 - pow(maxf(1.0 - t / lama_rem, 0.0), 2.0))
			kendaraan.position = kendaraan.titik_lajur(kendaraan.jarak)
	var kilat: = ColorRect.new()
	kilat.color = Color(0, 0, 0, 1)
	kilat.set_anchors_preset(Control.PRESET_FULL_RECT)
	kilat.mouse_filter = Control.MOUSE_FILTER_STOP
	(dialog.get_parent() as Control).add_child(kilat)

	var judul: = Label.new()
	judul.text = "PAK MISRAN KESEREMPET!"
	judul.set_anchors_preset(Control.PRESET_FULL_RECT)
	judul.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	judul.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	GH.gaya_label(judul, 96, Color(0.95, 0.25, 0.2), true, 10)
	kilat.add_child(judul)
	await GameState.get_tree().create_timer(JEDA_SIRENE).timeout
	GameState.bunyi("ambulans")
	await GameState.get_tree().create_timer(2.6).timeout

	label_loading.text = "%s\nPak Misran istirahat 2 hari.\n\nLihat kiri-kanan sebelum menyeberang!" % GameState.teks_biaya_tertabrak()
	tabir.mouse_filter = Control.MOUSE_FILTER_STOP
	tabir.modulate.a = 1.0
	kilat.queue_free()
	await GameState.get_tree().create_timer(5.0).timeout
	if not GameState.tertabrak():
		GameState.ganti_layar(self, "res://scenes/warung.tscn")
		return
	label_loading.text = "Dua hari kemudian...\n\n%s, %s\nPukul %s" % [GameState.nama_hari(), GameState.teks_tanggal(), GameState.teks_jam().trim_suffix(" WIB")]
	await GameState.get_tree().create_timer(2.2).timeout
	await _masuk_area("kamar", "kasur", false)
	GameState.putar_musik(GameState.musik_suasana())
	sibuk = true
	_bangun_pagi(true)


func _ketiduran() -> void :
	sibuk = true
	tombol_aksi.hide()
	pesan.text = ""

	if _wajib_ronda():
		_catat_tolak_ronda("Semalam ditunggu di pos ronda, Pak Misran nggak datang.")
	await _istirahat("Pak Misran kembali ke rumahnya karena kelelahan...\n\nPermainan disimpan.", true)



func _waktunya_jumatan() -> bool:
	return GameState.ikut_ronda_jumatan() and GameState.nama_hari() == "Jumat" and GameState.status_hari != "tutup" and GameState.jumatan_hari != GameState.hari\
	and GameState.menit >= JAM_JUMATAN and GameState.menit < JAM_SELESAI_JUMATAN



func _jumatan_libur() -> void :
	sibuk = true
	bapak.sedang_jalan = false
	tombol_aksi.hide()
	GameState.jumatan_hari = GameState.hari
	GameState.putar_adzan()
	var nomor: int = await dialog.tanya({"siapa": "haji_doni", "nama": "Haji Doni", "teks": "Assalamualaikum, Pak Misran! Sudah adzan, ayo Jumatan dulu ke masjid."}, 
		[{"teks": "Ikut Jumatan", "aktif": true}, {"teks": "Nanti saja", "aktif": true}])
	if nomor != 0:
		GameState.ulasan_warga(1, "Hari Jumat warungnya libur, tapi Pak Misran nggak kelihatan di masjid.", "Haji Doni")
		GameState.data_berubah.emit()
		tampilkan_pesan("Pak Misran tidak ikut Jumatan. Warga yang tahu jadi kecewa: reputasi turun.", 5.0)
		sibuk = false
		return
	GameState.ulasan_warga(5, "Pak Misran rajin Jumatan. Salut!")
	sibuk = false



	if area_id == String(TITIK_JUMATAN["area"]) or _area_berikut(area_id, String(TITIK_JUMATAN["area"])) != "":
		ikuti_kerja = IKUTI_JUMATAN
		_rute_ikut = []
		_tujuan_ikut = Vector2.INF
		_macet_ikut = 0.0
		tampilkan_pesan("Pak Misran berjalan ke Masjid Al-Ikhlas untuk Sholat Jumat...", 4.0)
	else:
		await _sampai_jumatan()



const IKUTI_JUMATAN: = "jumatan"
const TITIK_JUMATAN: = {"area": "masjid", "posisi": [295, 565], "nama": "Masjid Al-Ikhlas"}


func _jumatan_masih_berlaku() -> bool:
	return GameState.nama_hari() == "Jumat" and GameState.jumatan_hari == GameState.hari and GameState.menit < JAM_SELESAI_JUMATAN


var _jumatan_jalan_sendiri: = false


func _cek_jumatan_jalan_sendiri() -> bool:
	if not _jumatan_jalan_sendiri:
		return false
	if not _jumatan_masih_berlaku():
		_jumatan_jalan_sendiri = false
		return false
	if area_id != String(TITIK_JUMATAN["area"]) or ikuti_kerja != "":
		return false
	if bapak.position.distance_to(_v(TITIK_JUMATAN["posisi"])) > float(area.get("tinggi_dewasa", 150)) * 0.6:
		return false
	_sampai_jumatan()
	return true


func _sampai_jumatan() -> void :
	sibuk = true
	_jumatan_jalan_sendiri = false
	_batal_ikuti()
	_diam_ikut()
	bapak.sedang_jalan = false
	tombol_aksi.hide()
	var sisa: = maxf(JAM_SELESAI_JUMATAN - GameState.menit, 0.0)
	var layar: = LAYAR_KERJA.new()
	ui.add_child(layar)


	layar.isi_cerita("Pak Misran sedang Jumatan", "", 
		"Sholat Jumat berjamaah bersama warga di Masjid Al-Ikhlas sampai pukul 13.00.", sisa, true, true)
	GameState.get_tree().create_timer(1.1).timeout.connect( func():
		if is_instance_valid(bapak) and is_instance_valid(layar):
			bapak.visible = false)

	var maju: = [false]
	var keluar_masjid: = func():
		bapak.visible = true
		if not maju[0]:
			maju[0] = true
			GameState.majukan_waktu(sisa)
			GameState.data_berubah.emit()
	layar.memudar.connect(keluar_masjid)
	await layar.selesai
	keluar_masjid.call()
	sibuk = false
	tampilkan_pesan("Selesai Jumatan. Pukul 13.00, hari masih panjang.", 4.0)




func _ke_jumatan() -> void :
	sibuk = true
	bapak.sedang_jalan = false
	tombol_aksi.hide()
	pesan.text = "Sudah pukul 11.30, waktunya Sholat Jumat! Pak Misran segera kembali ke warung."
	await GameState.get_tree().create_timer(2.5).timeout
	label_loading.text = "Waktunya Sholat Jumat!\n\nPak Misran kembali ke warung..."
	tabir.mouse_filter = Control.MOUSE_FILTER_STOP
	var gelap: = create_tween()
	gelap.tween_property(tabir, "modulate:a", 1.0, 0.6)
	gelap.tween_interval(1.5)
	await gelap.finished
	GameState.putar_intro = false
	GameState.ganti_layar(self, "res://scenes/warung.tscn")







const WARGA_RONDA: = [
	{"tipe": "ojek", "posisi": [172, 345], "hadap": [1, 0.2]}, 
	{"tipe": "tukang", "posisi": [215, 332], "hadap": [1, 0.45]}, 
	{"tipe": "pak_rt", "posisi": [272, 360], "hadap": [-0.6, 0.5]}, 
]
var ronda_diingatkan: = false

func _perbarui_ronda() -> void :
	if not GameState.waktunya_ronda():
		return
	if not ronda_diingatkan:
		ronda_diingatkan = true
		tampilkan_pesan("Malam Jumat: warga berkumpul di pos ronda (area Rumah Warga). Ronda dimulai pukul 22.00.", 6.0)
	if area_id != "rumah":
		return
	for w in warga:
		if is_instance_valid(w) and w.has_meta("ronda_warga"):
			return
	for r in WARGA_RONDA:
		var tipe: = String(r["tipe"])
		var o: Sprite2D = _orang_di_tempat(tipe, _v(r["posisi"]))
		if o == null:
			_lepas_kembaran(tipe)
			o = _buat_orang(tipe)
			o.position = _v(r["posisi"])
			o.hadap(_v(r["hadap"]))
			o.set_meta("diam", true)
			if o.karakter != null:
				o.karakter.hidup = true
			o.modulate.a = 0.0
			o.create_tween().tween_property(o, "modulate:a", 1.0, 0.6)
		o.set_meta("ronda_warga", true)
		if tipe == "pak_rt":
			o.set_meta("ronda", true)


func _ronda() -> void :
	if sibuk or dialog.visible:
		return
	sibuk = true
	bapak.sedang_jalan = false
	tombol_aksi.hide()
	for w in warga:
		if is_instance_valid(w) and w.has_meta("ronda"):
			var arah: = (bapak.position - w.position).normalized()
			w.karakter.arah_layar = arah
			bapak.karakter.arah_layar = - arah
	var awal: = GameState.menit < GameState.JAM_MULAI_RONDA
	var sapa: Array = [{"siapa": "pak_rt", "teks": "Malam, Pak Misran! Pas sekali, malam ini malam Jumat, giliran kita ronda."}]
	if awal:
		sapa.append({"siapa": "pak_rt", "teks": "Kita mulai keliling jam 10 malam. Sambil menunggu, ngopi dulu di pos."})
	await _dialog_event(sapa)
	var pilihan: Array = [{"teks": "Ikut ronda", "aktif": true}, {"teks": "Maaf, malam ini tidak bisa", "aktif": true}]
	if awal:
		pilihan.insert(1, {"teks": "Nanti dulu", "aktif": true})
	var nomor: int = await dialog.tanya(_baris_event({"siapa": "pak_rt", "teks": "Ikut ronda sampai menjelang subuh, Pak? Besok pasti bangun kesiangan, lho."}), pilihan)
	if String(pilihan[nomor]["teks"]) == "Nanti dulu":
		await _dialog_event([{"siapa": "bapak", "teks": "Sebentar ya, Pak RT. Nanti saya ke sini lagi."}])
		sibuk = false
		return
	if nomor != 0:
		await _tolak_ronda()
		sibuk = false
		return
	if awal:
		await _dialog_event([{"siapa": "", "teks": "Pak Misran menunggu sambil ngopi dan mengobrol di pos ronda sampai pukul 22.00."}])
		GameState.menit = GameState.JAM_MULAI_RONDA
	await _dialog_event([
		{"siapa": "pak_rt", "teks": "Sudah jam 10. Ayo, Bapak-bapak, kita mulai keliling. Kentongannya dibawa!"}, 
		{"siapa": "ojek", "teks": "Siap, Pak RT! Senternya sudah saya bawa."}, 
		{"siapa": "tukang", "teks": "Saya yang pukul kentongan, ya. Tong... tong... tong..."}, 
		{"siapa": "bapak", "teks": "Bismillah. Ayo, kita jaga kampung bareng-bareng."}, 
	])


	var layar_ronda: = LAYAR_KERJA.new()
	ui.add_child(layar_ronda)
	layar_ronda.isi_cerita("Ronda Malam Jumat", "", 
		"Pak Misran berkeliling kampung bersama Pak RT, Kang Asep, dan Mang Ujang.", 270.0)
	await layar_ronda.selesai
	GameState.ronda_terakhir = GameState.hari
	GameState.ulasan_warga(5, "Pak Misran ikut ronda semalam. Kampung jadi aman, warungnya juga makin dipercaya.", "Pak RT")
	GameState.data_berubah.emit()
	var popup: = POPUP_HADIAH.new()
	ui.add_child(popup)
	popup.isi("Ronda Malam Jumat", "Pak Misran berkeliling kampung bersama Pak RT dan warga sampai menjelang subuh. Kampung aman, warga makin akrab dengan Pak Misran.", 
		["Reputasi warung naik", "Besok bangun kesiangan pukul 10.00 karena begadang"])
	await popup.ditutup
	await _istirahat("Pak Misran ronda keliling kampung sampai menjelang subuh,\nlalu pulang dan tidur...\n\nPermainan disimpan.", false, true)





func _matel_di_jalan() -> void :
	sibuk = true
	GameState.matel_datang_hari = GameState.hari
	if is_instance_valid(bapak):
		bapak.sedang_jalan = false
	tombol_aksi.hide()
	var angsuran: = mini(int(GameState.motor_cicil.get("angsuran", GameState.motor_angsuran())), GameState.motor_sisa_cicilan())
	GameState.bunyi("salah")
	await _dialog_event([{"siapa": "", "teks": "Dua pria berjaket kulit menghentikan Pak Misran di jalan. Satu memegang map leasing."}])
	var cukup: = GameState.uang >= angsuran
	var pilihan: Array = [{"teks": "Bayar " + GameState.format_rupiah(angsuran), "aktif": cukup}, {"teks": "Tidak ada uang", "aktif": true}]
	var tanya: = {"siapa": "preman", "nama": "Matel", "teks": "Pak Misran? Kami dari leasing. Cicilan motor bulan ini %s, jatuh tempo hari ini. Bayar sekarang, atau motornya kami bawa.%s" % [
		GameState.format_rupiah(angsuran), "" if cukup else """
(Uang Pak Misran tidak cukup.)"""]}

	var nomor: = -1
	while true:
		nomor = await dialog.tanya(tanya, pilihan)
		if nomor == 0 and await KB.tanya(self, "Bayar cicilan motor?", angsuran):
			break
		if nomor != 0 and await KB.tanya(self, "Motor akan dibawa matel. Yakin?", 0, "", "Ya, biarkan", true):
			break
	if nomor == 0 and GameState.bayar_cicilan_motor() == "":
		var lanjut: = "Jatuh tempo berikutnya %s." % GameState.nama_tanggal_hari(GameState.motor_tempo()) if GameState.motor_sisa_cicilan() > 0 else "Motor sekarang LUNAS!"
		await _ucap_matel([{"siapa": "preman", "teks": "Oke, Pak. Sudah lunas bulan ini. " + lanjut}])
	else:
		GameState.sita_motor("Motornya dibawa matel leasing, Pak. Uang yang sudah dibayar hangus. Kalau mau, bisa cicil motor lagi dari awal di Wishlist.")
		await _ucap_matel([{"siapa": "preman", "teks": "Maaf, Pak. Aturannya begitu. Motornya kami bawa."}, 
			{"siapa": "", "teks": "Matel pergi membawa motor Pak Misran. OjekKampung tidak bisa dipakai sampai punya motor lagi."}])
	sibuk = false



func _ucap_matel(daftar: Array) -> void :
	var baris: Array = []
	for b in daftar:
		var x: = _baris_event(b)
		if String(b.get("siapa", "")) == "preman":
			x["nama"] = "Matel"
		baris.append(x)
	dialog.tampilkan(baris)
	await dialog.selesai



const ULASAN_TOLAK_RONDA: = 2

func _tolak_ronda() -> void :
	await _dialog_event([
		{"siapa": "bapak", "teks": "Maaf, Pak RT, badan saya lagi kurang enak. Malam ini saya nggak ikut dulu."}, 
		{"siapa": "pak_rt", "teks": "Oh... ya sudah, Pak. Padahal yang jaga malam ini sedikit. Semoga cepat sehat."}])
	_catat_tolak_ronda("Pak Misran nggak ikut ronda malam Jumat. Warga yang lain jadi kurang orang.")
	var popup: = POPUP_HADIAH.new()
	ui.add_child(popup)
	popup.isi("Tidak Ikut Ronda", "Pak RT dan warga kecewa Pak Misran tidak ikut ronda malam ini.", 
		["Reputasi warung turun", "Malam ini Pak Misran boleh tidur seperti biasa"])
	await popup.ditutup


func _catat_tolak_ronda(teks: String) -> void :
	GameState.ronda_terakhir = GameState.hari
	GameState.ulasan_warga(1, teks, "Pak RT", ULASAN_TOLAK_RONDA)
	GameState.data_berubah.emit()
	GameState.simpan()



func _wajib_ronda() -> bool:
	return GameState.ikut_ronda_jumatan() and GameState.nama_hari() == "Kamis" and GameState.ronda_terakhir != GameState.hari\
	and not GameState.mode_latihan and GameState.tutorial_langkah == ""





var kerja_diumumkan: = {}

func _perbarui_kerja() -> void :
	for id in GameState.KERJA_SAMPINGAN:
		var k: Dictionary = GameState.data_kerja(id)
		var ada: bool = GameState.kerja_tersedia(id)


		if ada and not sibuk and not dialog.visible and int(kerja_diumumkan.get(id, 0)) != GameState.hari:
			kerja_diumumkan[id] = GameState.hari
			if GameState.kerja_tujuan == "":
				GameState.kerja_tujuan = id

		if String(k["area"]) != area_id:
			continue
		var pos: = _v(k["posisi"])
		var orang: Sprite2D = _orang_di_tempat(String(k["npc"]), pos)

		if _sedang_bercerita(String(k["npc"])):
			ada = false
		if not ada:
			if orang != null and orang.has_meta("kerja"):
				orang.remove_meta("kerja")
				_hapus_koin(orang)
			continue
		if orang == null:
			_lepas_kembaran(String(k["npc"]))
			orang = _buat_orang(String(k["npc"]))
			orang.position = pos
			orang.hadap(_v(k["hadap"]))
			orang.set_meta("diam", true)
			if orang.karakter != null:
				orang.karakter.hidup = true
			orang.modulate.a = 0.0
			orang.create_tween().tween_property(orang, "modulate:a", 1.0, 0.6)
		orang.set_meta("kerja", id)


func _hapus_koin(w: Sprite2D) -> void :
	if w.has_meta("koin"):
		(w.get_meta("koin") as Node).queue_free()
		w.remove_meta("koin")




const UKURAN_TANDA_KERJA: = Vector2(40, 40)

func _perbarui_koin() -> void :
	var s: = 1.0 / kamera.zoom.x
	for w in warga:
		if not is_instance_valid(w):
			continue
		if not w.has_meta("kerja"):
			_hapus_koin(w)
			continue
		if not w.has_meta("koin"):
			var p: = Panel.new()
			var gaya: = StyleBoxFlat.new()
			gaya.bg_color = Color(0.05, 0.05, 0.05, 0.55)
			gaya.border_color = Color(GH.KUNING, 0.85)
			gaya.set_border_width_all(2)
			gaya.shadow_color = Color(0, 0, 0, 0.35)
			gaya.shadow_size = 3
			gaya.set_corner_radius_all(20)
			p.add_theme_stylebox_override("panel", gaya)
			p.size = UKURAN_TANDA_KERJA
			p.mouse_filter = Control.MOUSE_FILTER_IGNORE
			p.z_index = 100
			var l: = Label.new()
			l.text = "Rp"
			l.add_theme_font_size_override("font_size", 17)
			GH.gaya_label(l, 20, GH.KUNING, true, 3)
			l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			l.size = p.size
			p.add_child(l)
			dunia.add_child(p)
			w.set_meta("koin", p)
		var koin: Control = w.get_meta("koin")
		koin.visible = not sibuk and w != warga_dekat
		koin.scale = Vector2(s, s)
		var naik: = sin(Time.get_ticks_msec() / 260.0) * 3.0 * s
		koin.position = w.position + Vector2( - UKURAN_TANDA_KERJA.x / 2.0 * s, - w.tinggi_badan() - 34.0 * s + naik)


const PAPAN_KERJA_UI: = preload("res://scripts/papan_kerja_ui.gd")

func _kerja(id: String) -> void :
	if sibuk or dialog.visible or not GameState.kerja_tersedia(id):
		return
	var k: Dictionary = GameState.KERJA_SAMPINGAN[id]
	sibuk = true
	bapak.sedang_jalan = false
	tombol_aksi.hide()
	for w in warga:
		if is_instance_valid(w) and w.get_meta("kerja", "") == id:
			var arah: = (bapak.position - w.position).normalized()
			w.karakter.arah_layar = arah
			bapak.karakter.arah_layar = - arah

	var upah: = GameState.format_rupiah(GameState.upah_kerja(id))
	var perlu_iklan: = GameState.kerja_perlu_iklan()
	var ajak: = "%s\n(%s%s)" % [GameState.ajakan_kerja(id), GameState.teks_durasi(float(k["menit"])), 
		", energi -%d%%" % int(k["energi"]) if int(k["energi"]) > 0 else ""]

	var papan_kerja: PanelContainer = PAPAN_KERJA_UI.new()
	papan_kerja.set("kerja", id)
	ui.add_child(papan_kerja)
	var nomor: int = await dialog.tanya({"siapa": String(k["npc"]), "nama": _nama_tipe(String(k["npc"])), "teks": ajak}, 
		[{"teks": (("Bantu (upah s.d. %s)" if GameState.tanpa_iklan else "Tonton iklan & bantu (upah s.d. %s)") if perlu_iklan else "Bantu, gratis hari ini (upah s.d. %s)") % upah, "aktif": true}, 
		{"teks": "Nanti saja", "aktif": true}])
	if is_instance_valid(papan_kerja):
		papan_kerja.queue_free()
	if nomor != 0:
		sibuk = false
		return
	var alasan: = GameState.alasan_tidak_bisa_kerja(id)
	if alasan != "":
		await _dialog_event([{"siapa": "bapak", "teks": "Aduh, badan sudah lemas. " + alasan}])
		sibuk = false
		return
	if perlu_iklan and not await GameState.tonton_iklan(ui):
		tampilkan_pesan("Iklan dilewati, Pak Misran batal membantu %s." % String(k["nama"]), 4.0)
		sibuk = false
		return

	GameState.pengali_kerja = 1.0
	var mg_file: Array = GameState.minigame_kerja(id)
	if not mg_file.is_empty():
		var mg: Control = load(mg_file[0]).new()
		mg.atur(mg_file[1], id)
		ui.add_child(mg)
		GameState.mulai_kerja_berjalan(id)
		var hasil_mg: float = await mg.selesai
		GameState.kerja_berjalan = ""
		GameState.pengali_kerja = GameState.pengali_hasil_kerja(hasil_mg)
	GameState.kerjakan(id)
	var layar: = LAYAR_KERJA.new()
	ui.add_child(layar)
	layar.isi(id)

	var gandakan: bool = await layar.selesai
	var total: = GameState.upah_diterima(id)

	if gandakan and (layar.iklan_ditonton or await GameState.tonton_iklan(ui)):
		total += GameState.bonus_iklan_kerja(id)
		GameState.gandakan_upah_kerja(id)
	for w in warga:
		if is_instance_valid(w) and w.get_meta("kerja", "") == id:
			w.remove_meta("kerja")
			_hapus_koin(w)
	GameState.pengali_kerja = 1.0
	var catatan: = "" if (perlu_iklan or GameState.tanpa_iklan or not GameState.kerja_perlu_iklan()) else " Kerja sampingan berikutnya hari ini perlu menonton 1 iklan."
	tampilkan_pesan("Upah %s diterima. Energi tinggal %d%%.%s" % [GameState.format_rupiah(total), int(GameState.energi), catatan], 6.0)
	sibuk = false




const MG_OJOL: = "res://scripts/minigame/mg_ojol.gd"





const ADU_LARIS: = preload("res://scripts/adu_laris.gd")
const MG_ADU_LARIS: = "res://scripts/minigame/mg_adu_laris.gd"

func _menu_adu_laris() -> void :
	if sibuk or dialog.visible:
		return
	if not ADU_LARIS.boleh_latihan():
		tampilkan_pesan("Adu Laris belum bisa dimainkan sekarang.", 4.0)
		return
	sibuk = true
	bapak.sedang_jalan = false
	tombol_aksi.hide()
	var data: = ADU_LARIS.data_pemain()
	var sisa: = ADU_LARIS.sisa_kesempatan()

	var alasan: = ADU_LARIS.alasan_tidak_bisa()
	var teks: = tr("Warung lain menantang adu laris: siapa paling laris dalam 1 menit? Trofi kamu: %d.") % int(data["trofi"])
	if alasan != "":
		teks += " " + tr(alasan)
	var pilihan_adu: = tr("Duel resmi (masuk papan, 1 jam) · sisa %d/%d") % [sisa, ADU_LARIS.MAKS_MAIN]
	var pilihan: = [{"teks": pilihan_adu, "aktif": alasan == ""}, {"teks": "Latihan (bebas, tidak masuk papan)", "aktif": true}, 
		{"teks": "Nanti dulu", "aktif": true}]
	var nomor: int = await dialog.tanya({"siapa": "bapak", "teks": teks}, pilihan)
	sibuk = false
	if nomor == 1:
		_latihan_adu_laris()
		return
	if nomor != 0 or ADU_LARIS.alasan_tidak_bisa() != "":
		return
	sibuk = true
	var lawan: = ADU_LARIS.pilih_lawan()
	ADU_LARIS.catat_mulai()
	var mg: Control = load(MG_ADU_LARIS).new()
	mg.set("lawan", lawan)
	mg.atur("", "")
	ui.add_child(mg)
	var hasil: float = await mg.selesai
	GameState.majukan_waktu(ADU_LARIS.MENIT_GAME)
	GameState.data_berubah.emit()
	GameState.simpan()
	var kata: = "Menang adu laris!" if hasil >= 1.0 else ("Seri adu laris." if hasil > 0.0 else "Kalah adu laris, coba lagi nanti.")
	tampilkan_pesan(tr("%s Satu jam berlalu. Energi tinggal %d%%.") % [tr(kata), int(GameState.energi)], 5.0)
	sibuk = false



func _latihan_adu_laris() -> void :
	sibuk = true
	bapak.sedang_jalan = false
	tombol_aksi.hide()
	var ulang: = true
	while ulang:
		var mg: Control = load(MG_ADU_LARIS).new()
		mg.set("lawan", ADU_LARIS.pilih_lawan())
		mg.set("latihan", true)
		mg.atur("", "")
		ui.add_child(mg)
		var hasil: float = await mg.selesai
		ulang = hasil >= 2.0
	tampilkan_pesan("Latihan selesai. Duel resmi masuk papan Adu Laris mingguan.", 4.0)
	sibuk = false

func mulai_ngojol(order: Dictionary) -> void :
	if sibuk or dialog.visible:
		return
	var alasan: = GameState.alasan_tidak_bisa_ngojol()
	if alasan != "":
		tampilkan_pesan(alasan, 4.0)
		return
	sibuk = true
	bapak.sedang_jalan = false
	tombol_aksi.hide()
	var mg: Control = load(MG_OJOL).new()
	mg.set("order", order)
	mg.atur("", "")
	ui.add_child(mg)
	var hasil: float = await mg.selesai
	var uang: = GameState.selesaikan_ngojol(int(order["no"]), hasil)
	var sisa: = GameState.ngojol_sisa()
	tampilkan_pesan("Ongkos ojek %s diterima. Energi tinggal %d%%.%s" % [GameState.format_rupiah(uang), int(GameState.energi), 
		((" Masih ada %d order hari ini di OjekKampung." if GameState.hari_libur() else " Masih ada %d order malam ini di OjekKampung.") % sisa) if sisa > 0 and GameState.alasan_tidak_bisa_ngojol() == "" else ""], 6.0)
	sibuk = false





const MG_MANCING: = "res://scripts/minigame/mg_mancing.gd"
const MG_PETIK: = "res://scripts/minigame/mg_petik.gd"



const SCRIPT_PENANDA_ALAM: = preload("res://scripts/penanda_hasil_alam.gd")

func _pasang_penanda_alam() -> void :
	for anak in dunia.get_children():
		if anak.has_meta("penanda_alam"):
			anak.queue_free()
	for p in area.get("pintu", []):
		var aksi: = String(p["aksi"])
		if aksi != "mancing" and aksi != "petik" and aksi != "adu_laris" and not aksi.begins_with("angkot:"):
			continue
		var n: = Node2D.new()
		n.set_script(SCRIPT_PENANDA_ALAM)
		n.set("jenis", "angkot" if aksi.begins_with("angkot:") else aksi)
		n.set("judul", "Angkot" if aksi.begins_with("angkot:") else String(p.get("label", "")))
		n.set_meta("penanda_alam", true)
		n.position = _v(p.get("penanda", p["posisi"]))
		n.z_index = 90
		dunia.add_child(n)

		if aksi.begins_with("angkot:"):
			n.z_index = 0
			n.set_meta("penanda_angkot", true)
			dunia.move_child(n, lalu_lintas.get_index())






const ONGKOS_ANGKOT: = 2000
const JAM_ANGKOT: = [5.0, 21.0]
const MENIT_ANGKOT: = 30.0
const MENIT_JALAN_KAKI: = 90.0
const DETIK_LOADING_ANGKOT: = 2.0
const SCRIPT_JUAL: = preload("res://scripts/jual_pasar.gd")
const SCRIPT_JAJAN: = preload("res://scripts/jajan_pasar.gd")
const SCRIPT_GROSIR: = preload("res://scripts/grosir_pasar.gd")

func _dalam_jam(r: Array) -> bool:
	var jam: = GameState.menit / 60.0
	return jam >= float(r[0]) and jam < float(r[1])



func _penjual_ada(jam: Array) -> bool:
	return _dalam_jam(jam) and GameState.pasar_buka_hari_ini()


func _naik_angkot(tujuan: String) -> void :
	if sibuk or dialog.visible:
		return
	var ke_pasar: = tujuan == "pasar"
	var jam: = GameState.menit / 60.0
	if ke_pasar and (jam < JAM_ANGKOT[0] or jam >= JAM_ANGKOT[1]):
		tampilkan_pesan("Angkot ke pasar sudah tidak lewat. Besok pagi saja (angkot jalan pukul 05.00-21.00).", 4.5)
		return
	if ke_pasar and GameState.uang < ONGKOS_ANGKOT:
		tampilkan_pesan("Uang tidak cukup untuk ongkos angkot (%s)." % GameState.format_rupiah(ONGKOS_ANGKOT), 4.0)
		return
	tombol_aksi.hide()
	bapak.sedang_jalan = false

	sibuk = true
	var pertanyaan: = "Pergi ke pasar sekarang?"
	if not ke_pasar:
		pertanyaan = "Pulang ke kampung sekarang?" if GameState.uang >= ONGKOS_ANGKOT else "Uang tidak cukup untuk ongkos angkot. Jalan kaki pulang sekarang?"
	var nomor: int = await dialog.tanya({"siapa": "bapak", "teks": pertanyaan}, [{"teks": "Gas", "aktif": true}, {"teks": "Nanti dulu", "aktif": true}])
	if nomor != 0:
		sibuk = false
		return
	var bayar: = GameState.uang >= ONGKOS_ANGKOT
	if bayar:
		GameState.uang -= ONGKOS_ANGKOT
		GameState.catat_transaksi("Ongkos angkot ke pasar" if ke_pasar else "Ongkos angkot pulang dari pasar", - ONGKOS_ANGKOT)
		GameState.data_berubah.emit()

	sibuk = true
	if not bayar:
		label_loading.text = "Uang tidak cukup untuk ongkos angkot.\r\nPak Misran jalan kaki pulang...\r\n\r\n± 1,5 jam perjalanan"



	elif ke_pasar:
		label_loading.text = """Naik angkot ke Pasar...
Ongkos %s

± 30 menit perjalanan""" %GameState.format_rupiah(ONGKOS_ANGKOT)
	else:
		label_loading.text = """Naik angkot pulang ke kampung...
Ongkos %s

± 30 menit perjalanan""" %GameState.format_rupiah(ONGKOS_ANGKOT)

	if bayar:
		await _adegan_naik()
	tabir.mouse_filter = Control.MOUSE_FILTER_STOP
	var gelap: = create_tween()
	gelap.tween_property(tabir, "modulate:a", 1.0, 0.5)
	await gelap.finished
	if bayar:

		GameState.bunyi("mobil_lewat")
		await GameState.get_tree().create_timer(DETIK_LOADING_ANGKOT).timeout
	else:
		var t: = 0.0
		while t < DETIK_LOADING_ANGKOT:
			GameState.langkah_kaki()
			await GameState.get_tree().create_timer(0.42).timeout
			t += 0.42
	GameState.majukan_waktu(MENIT_ANGKOT if bayar else MENIT_JALAN_KAKI)
	await _masuk_area("pasar" if ke_pasar else "rumah", "halte" if ke_pasar else "angkot", false)
	if bayar:

		sibuk = true
		bapak.modulate.a = 0.0
		_adegan_angkot = true
		await _loading(false, "")
		await _adegan_turun()
		bapak.modulate.a = 1.0
		sibuk = false
	else:
		await _loading(false, "")
	if not bayar:
		tampilkan_pesan("Uang tidak cukup untuk ongkos angkot, Pak Misran jalan kaki pulang (1,5 jam).", 5.0)
	elif ke_pasar:
		var teks: = "Sampai di pasar (ongkos angkot %s). Bu Ida membeli ikan & buah, Haji Maman menjual barang grosir di dekat pot tanaman hijau."
		if not GameState.pasar_buka_hari_ini():
			teks = "Sampai di pasar (ongkos angkot %s). Hari ini pasar libur (Selasa & Kamis), Bu Ida di rumah."
		elif not _dalam_jam([6.0, 19.0]):
			teks = "Sampai di pasar (ongkos angkot %s). Pasar sudah tutup, Bu Ida sudah pulang."
		tampilkan_pesan(teks % GameState.format_rupiah(ONGKOS_ANGKOT), 5.0)
	else:
		tampilkan_pesan("Sampai di ujung jalan kampung (ongkos angkot %s)." % GameState.format_rupiah(ONGKOS_ANGKOT), 4.0)



const DETIK_ANGKOT_DATANG: = 2.6
const DETIK_ANGKOT_PERGI: = 2.4
const JARAK_ANGKOT_PERGI: = 1700.0
const JEDA_ANGKOT_PERGI: = 1.2




func _suara_angkot(k, nama: String, mulai: float) -> void :
	var file: = "res://assets/suara/%s.wav" % nama
	if not is_instance_valid(k) or not ResourceLoader.exists(file):
		return
	var p: = AudioStreamPlayer.new()
	p.stream = load(file)
	p.volume_db = 2.5
	k.add_child(p)
	p.play(maxf(mulai, 0.0))



var _adegan_angkot: = false



func _tunggu_jalan_kosong() -> void :
	var t: = 0.0
	while _ada_kendaraan() and t < 8.0:
		await GameState.get_tree().create_timer(0.2).timeout
		t += 0.2


func _angkot_baru() -> Node2D:
	if not area.has("jalan"):
		return null
	var jalan: Dictionary = area["jalan"]
	var k: = SCRIPT_KENDARAAN.new()
	k.lajur.clear()
	for t in jalan["lajur_kanan"]:
		k.lajur.append(_v(t))
	k.position = k.lajur[0]
	lalu_lintas.add_child(k)
	var hadap: Array = jalan.get("hadap", [135.0, -45.0])
	if not k.siapkan("angkot", _ppm_kendaraan(), true, float(hadap[0])):
		k.queue_free()
		return null
	if jalan.has("kabur"):
		k.atur_kabur(float(jalan["kabur"]))
	k.kecepatan = 0.0
	k.set_meta("bunyi", true)
	k.set_meta("adegan", true)
	return k






func _angkot_jalan(k, dari: float, ke: float, detik: float, datang: bool) -> void :
	if not is_instance_valid(k):
		return
	var langkah: = func(d: float) -> void :
		if is_instance_valid(k):
			k.jarak = d
			k.position = k.titik_lajur(d)
	var tw: Tween = k.create_tween()
	tw.tween_method(langkah, dari, ke, detik).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT if datang else Tween.EASE_IN)
	await GameState.get_tree().create_timer(detik + 0.05).timeout


func _angkot_pergi(k, dari: float) -> void :
	if not is_instance_valid(k):
		return

	_suara_angkot(k, "mobil_pergi", 0.0)
	await GameState.get_tree().create_timer(JEDA_ANGKOT_PERGI).timeout
	await _angkot_jalan(k, dari, dari + JARAK_ANGKOT_PERGI, DETIK_ANGKOT_PERGI, false)
	if is_instance_valid(k):
		k.queue_free()


const TEKS_TUNGGU_ANGKOT: = "Menunggu angkot datang..."


func _adegan_naik() -> void :
	_adegan_angkot = true

	tampilkan_pesan(TEKS_TUNGGU_ANGKOT, 30.0)
	await _tunggu_jalan_kosong()
	var k: = _angkot_baru()
	if k == null:
		if pesan.text == TEKS_TUNGGU_ANGKOT:
			pesan.text = ""
		_adegan_angkot = false
		return
	var henti: float = minf(_titik_terdekat_lajur(k.lajur, bapak.position).x, k.panjang_lajur())

	_suara_angkot(k, "mobil_datang", 14.5 - DETIK_ANGKOT_DATANG)
	await _angkot_jalan(k, 0.0, henti, DETIK_ANGKOT_DATANG, true)
	await GameState.get_tree().create_timer(0.5).timeout

	if pesan.text == TEKS_TUNGGU_ANGKOT:
		pesan.text = ""
	var naik: = create_tween()
	naik.tween_property(bapak, "modulate:a", 0.0, 0.4)
	await GameState.get_tree().create_timer(0.45).timeout
	await GameState.get_tree().create_timer(0.4).timeout
	_angkot_pergi(k, henti)
	await GameState.get_tree().create_timer(1.0).timeout
	_adegan_angkot = false


func _adegan_turun() -> void :
	_adegan_angkot = true
	await _tunggu_jalan_kosong()
	var k: = _angkot_baru()
	if k == null:
		_adegan_angkot = false
		return
	var henti: float = minf(_titik_terdekat_lajur(k.lajur, bapak.position).x, k.panjang_lajur())

	_suara_angkot(k, "mobil_datang", 14.5 - DETIK_ANGKOT_DATANG)
	await _angkot_jalan(k, 0.0, henti, DETIK_ANGKOT_DATANG, true)
	await GameState.get_tree().create_timer(0.5).timeout

	var turun: = create_tween()
	turun.tween_property(bapak, "modulate:a", 1.0, 0.4)
	await GameState.get_tree().create_timer(0.45).timeout
	bapak.modulate.a = 1.0
	await GameState.get_tree().create_timer(0.4).timeout
	_angkot_pergi(k, henti)
	await GameState.get_tree().create_timer(0.8).timeout
	_adegan_angkot = false
	waktu_kendaraan = maxf(waktu_kendaraan, DETIK_ANGKOT_PERGI)



func _pulangkan_penjual() -> void :


	var tipe_cerita: = {}
	for w in warga:
		if is_instance_valid(w) and w.has_meta("event"):
			tipe_cerita[String(w.get_meta("tipe", ""))] = true
	for w in warga.duplicate():

		if is_instance_valid(w) and w.has_meta("penjual") and not w.has_meta("pergi") and ( not _penjual_ada(w.get_meta("jam_penjual")) or (tipe_cerita.has(String(w.get_meta("tipe", ""))) and not w.has_meta("event"))):
			if w == warga_dekat:
				tampilkan_pesan("Pasar sudah tutup. %s pulang dulu, besok lagi ya, Pak." % _nama_warga(w), 4.0)

			w.remove_meta("penjual")
			_tokoh_pergi_keluar(w)


func _buka_jual(w: Sprite2D) -> void :
	if not _penjual_ada(w.get_meta("jam_penjual")):
		_pulangkan_penjual()
		return
	if w.has_meta("jajan"):
		_buka_jajan(w)
		return
	if w.has_meta("grosir"):
		_buka_grosir(w)
		return
	sibuk = true
	tombol_aksi.hide()
	bapak.sedang_jalan = false
	var arah: = (bapak.position - w.position).normalized()

	if w.karakter != null:
		w.karakter.arah_layar = arah
	if bapak.karakter != null:
		bapak.karakter.arah_layar = - arah
	var layar: Control = SCRIPT_JUAL.new()
	ui.add_child(layar)
	var total: int = await layar.selesai
	if total > 0:
		tampilkan_pesan("Terjual ke Bu Ida: %s. Uang sekarang %s." % [GameState.format_rupiah(total), GameState.format_rupiah(GameState.uang)], 5.0)
		GameState.simpan()
	sibuk = false



func _buka_jajan(w: Sprite2D) -> void :
	sibuk = true
	tombol_aksi.hide()
	bapak.sedang_jalan = false
	var arah: = (bapak.position - w.position).normalized()

	if w.karakter != null:
		w.karakter.arah_layar = arah
	if bapak.karakter != null:
		bapak.karakter.arah_layar = - arah
	var layar: Control = SCRIPT_JAJAN.new(_nama_warga(w))
	ui.add_child(layar)
	var id: String = await layar.selesai
	if id != "":
		tampilkan_pesan("Pak Misran sudah jajan. Energi sekarang %d%%." % int(GameState.energi), 5.0)
		GameState.simpan()
	sibuk = false



func _buka_grosir(w: Sprite2D) -> void :
	sibuk = true
	tombol_aksi.hide()
	bapak.sedang_jalan = false
	var arah: = (bapak.position - w.position).normalized()
	if w.karakter != null:
		w.karakter.arah_layar = arah
	if bapak.karakter != null:
		bapak.karakter.arah_layar = - arah
	var layar: Control = SCRIPT_GROSIR.new(_nama_warga(w))
	ui.add_child(layar)
	var total: int = await layar.selesai
	if total > 0:
		tampilkan_pesan("Belanja grosir %s, barangnya di Tas. Begitu masuk warung, langsung jadi stok." % GameState.format_rupiah(total), 5.0)
		GameState.simpan()
	sibuk = false


func _hasil_alam(jenis: String) -> void :
	if sibuk or dialog.visible:
		return
	var mancing: = jenis == "mancing"
	var alasan: = GameState.alasan_tidak_bisa_mancing() if mancing else GameState.alasan_tidak_bisa_petik()
	if alasan != "":
		tampilkan_pesan(alasan, 4.5)
		return
	sibuk = true
	bapak.sedang_jalan = false
	tombol_aksi.hide()
	if pintu_dekat.has("hadap"):
		bapak.karakter.arah_layar = _v(pintu_dekat["hadap"])
	var mg: Control = load(MG_MANCING if mancing else MG_PETIK).new()
	mg.atur("", "")
	ui.add_child(mg)
	await mg.selesai
	GameState.tangkapan_tertunda = []
	var dapat: Array = mg.tangkapan.duplicate()
	var masuk: = 0
	for id in dapat:
		masuk += GameState.tambah_hasil_alam(String(id))
	var lepas: = dapat.size() - masuk
	var menit_mancing: = int(mg.get("lemparan")) * int(GameState.aturan_hasil_alam("menit_per_lempar", 3)) if mancing else 0
	if mancing:
		GameState.selesai_mancing(int(mg.get("lemparan")))
	else:
		GameState.selesai_petik( not dapat.is_empty())
	if dapat.is_empty() and not mancing:
		tampilkan_pesan("Tidak ada buah yang dipetik.", 3.5)
	elif dapat.is_empty():
		tampilkan_pesan(("Belum dapat ikan. Energi tinggal %d%%." if mancing else "Belum dapat buah. Energi tinggal %d%%.") % int(GameState.energi), 4.5)
	elif lepas > 0:
		tampilkan_pesan(("Tas penuh! %d ekor ikan masuk Tas, %d ekor dilepas lagi ke sungai. Jual dulu ke Bu Ida di Pasar." if mancing else "Tas penuh! %d buah masuk Tas, %d buah tidak muat. Jual dulu ke Bu Ida di Pasar.") % [masuk, lepas], 6.0)
	else:
		tampilkan_pesan(("%d ekor ikan masuk Tas (buka HP). Energi tinggal %d%%." if mancing else "%d buah masuk Tas (buka HP). Energi tinggal %d%%.") % [dapat.size(), int(GameState.energi)], 5.0)

	if mancing and menit_mancing > 0:
		var lama_mancing: = ("%d menit" % menit_mancing) if menit_mancing < 60 else ("%d jam %d menit" % [menit_mancing / 60, menit_mancing % 60])
		tampilkan_pesan("%s %s" % [tr(pesan.text), tr("Mancing %s, sekarang pukul %s.") % [lama_mancing, GameState.teks_jam()]], 6.0)
	sibuk = false




func _istirahat(teks: String, mendadak: = false, kesiangan: = false, alasan: = "") -> void :
	label_loading.text = teks
	tabir.mouse_filter = Control.MOUSE_FILTER_STOP
	var gelap: = create_tween()
	gelap.tween_property(tabir, "modulate:a", 1.0, 0.15 if mendadak else 1.2)
	if mendadak:
		gelap.tween_interval(1.5)
	await gelap.finished

	if GameState.tutorial_langkah == "tidur":
		GameState.tutorial_langkah = "selesai_baru"


	if GameState.mode_latihan:
		GameState.selesai_latihan()
		GameState.menit = 8 * 60
		GameState.putar_intro = false
		GameState.simpan()
	elif not GameState.tidur(kesiangan, alasan):

		await GameState.get_tree().create_timer(1.0).timeout
		GameState.ganti_layar(self, "res://scenes/warung.tscn")
		return
	await GameState.get_tree().create_timer(1.6).timeout
	label_loading.text = "%s, %s\nPukul %s" % [GameState.nama_hari(), GameState.teks_tanggal(), GameState.teks_jam().trim_suffix(" WIB")]
	await GameState.get_tree().create_timer(1.2).timeout
	if not area_id.begins_with("kamar"):
		await _masuk_area("kamar", "kasur", false)
	sibuk = true
	_bangun_pagi(true)



func _bangun_pagi(dari_gelap: bool) -> void :
	sibuk = true
	bapak.karakter.lepas_tahan()
	bapak.karakter.luruskan_kaki(false)
	bapak.atur_lebar_bingkai(0)
	bapak.bayangan.show()
	bapak.z_index = 0
	bapak.sedang_jalan = false
	bapak.position = _v(area["muncul"]["kasur"])
	bapak.karakter.arah_layar = Vector2(0.3, 1).normalized()
	kamera.position = bapak.position
	kamera.reset_smoothing()
	suasana.color = _warna_suasana()
	if dari_gelap:
		tabir.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var terang: = create_tween()
		terang.tween_property(tabir, "modulate:a", 0.0, 1.0)
		await terang.finished
	sibuk = false

	if GameState.bangun_kesiangan:
		GameState.bangun_kesiangan = false
		if GameState.alasan_bangun == "begadang":
			var jam: = "%02d.00" % (GameState.jam_bangun_tadi / 60)
			buka_dialog("", [
				{"siapa": "bapak", "teks": "Waduh, sudah jam %s! Semalam tidur kemalaman, jadi bangun kesiangan." % jam}, 
				{"siapa": "", "teks": "Efek begadang: makin larut Pak Misran tidur, makin siang ia bangun. Tidur sebelum pukul 22.00 supaya bisa bangun pukul 07.00."}, 
			])
		elif GameState.alasan_bangun == "tertabrak":
			buka_dialog("", [
				{"siapa": "bapak", "teks": "Aduh... badan masih pegal semua. Alhamdulillah sudah bisa jalan lagi."}, 
				{"siapa": "", "teks": "Dua hari Pak Misran beristirahat sampai kakinya pulih. Warung tutup selama itu. Hati-hati saat menyeberang: tunggu jalan sepi dulu."}, 
			])
		elif GameState.alasan_bangun == "pingsan":
			buka_dialog("", [
				{"siapa": "bapak", "teks": "Aduh, kepala masih pusing... Kemarin sampai pingsan, sudah jam sepuluh begini."}, 
				{"siapa": "", "teks": "Energi habis membuat Pak Misran pingsan: bayar mantri, dan bangun kesiangan. Jaga energi dengan ngopi, makan, atau tidur sebelum habis."}, 
			])
		else:
			buka_dialog("bangun_ronda")
		return

	GameState.bunyi("ayam_berkokok", -5.0)

	if GameState.ramadan() and not GameState.sambut_asli and GameState.tutorial_langkah == "" and not GameState.tutorial_penutup:
		if GameState.hari == GameState.RAMADAN_MULAI:
			buka_dialog("", [
				{"siapa": "", "teks": "Pukul tiga dini hari, anak-anak kampung berkeliling memukul kentongan: \"Sahur, sahur!\" Pak Misran bangun, sahur, lalu tidur lagi sebentar."}, 
				{"siapa": "bapak", "teks": "Marhaban ya Ramadan. Bismillah, puasa hari pertama."}, 
				{"siapa": "", "teks": "Selama Ramadan: siang warung sepi, pagi ramai bahan masak, sore ramai pembeli takjil. Warung boleh buka sampai 19.00. Pak Misran berpuasa: buka puasa sekali sehari sesudah adzan Maghrib (klik bar energi). Malam bisa ikut tarawih di masjid."}, 
			])
			return
		tampilkan_pesan("Tadi dini hari anak-anak keliling membangunkan sahur. Pak Misran sudah sahur. Selamat berpuasa!", 5.0)

	if GameState.sambut_asli:
		GameState.sambut_asli = false
		_judul_besar("Selamat bermain!")

	if GameState.tutorial_langkah == "selesai_baru" or GameState.tutorial_penutup:
		GameState.tutorial_langkah = ""
		GameState.tutorial_penutup = false
		buka_dialog("", [
			{"siapa": "bapak", "teks": "Alhamdulillah, hari pertama berjalan lancar. Bismillah, hari ini jualan lagi."}, 
			{"siapa": "", "teks": "Tutorial selesai! Pagi (07.00-09.00) bisa dipakai keliling kampung atau kerja sampingan. Sore dan malam bebas keliling, lalu pulang dan tidur. Hal baru akan dijelaskan saat pertama kali kamu menemuinya. Kalau bingung, buka HP, Panduan."}, 
		])
		return


	if GameState.warung_libur():
		var isi_libur: Array = [
			{"siapa": "bapak", "teks": "Alhamdulillah, hari %s. Warung libur dulu hari ini." % GameState.nama_hari()}, 
			{"siapa": "", "teks": "Setiap Jumat warung libur. Keliling kampung, ngobrol dengan warga, cari cerita, atau ambil kerja sampingan."}, 
		]
		var janji_ini: Array = GameState.daftar_janji_hari_ini()
		if not janji_ini.is_empty():
			isi_libur.append({"siapa": "", "teks": "Janji hari ini:\n• " + "\n• ".join(janji_ini)})
		buka_dialog("", isi_libur)
		return
	buka_dialog("bangun")




func _varian() -> Dictionary:
	if not latar_paksa.is_empty():
		var vp: = area.duplicate()
		vp.merge(latar_paksa, true)
		return vp
	if area.has("siang") and GameState.menit >= 5 * 60 and GameState.menit < GameState.JAM_MALAM:
		return area["siang"]


	var malam: bool = area.has("malam") and GameState.malam_hari()
	var kunci_basah: = "malam_basah" if malam else "basah"
	var basah: bool = area.has(kunci_basah) and GameState.tanah_basah()
	if not malam and not basah:
		return area
	var v: = area.duplicate()
	if malam:
		v.merge(area["malam"], true)
	if basah:
		v.merge(area[kunci_basah], true)
	return v



func _perbarui_varian() -> void :
	if not area.has("siang") and not area.has("malam"):
		return
	var mau: String = _varian()["gambar"]
	if latar.texture == null or latar.texture.resource_path == mau:
		return


	var lama: = Node2D.new()
	lama.set_meta("transisi", true)
	var s: = Sprite2D.new()
	s.centered = false
	s.texture = latar.texture
	lama.add_child(s)
	for anak in dunia.get_children():
		if anak == rak or anak.has_meta("kabur"):
			lama.add_child(anak.duplicate())

	var penutup_lama: Array[Node] = []
	for anak in wadah.get_children():
		if anak.has_meta("penutup"):
			anak.remove_meta("penutup")
			anak.set_meta("transisi", true)
			penutup_lama.append(anak)
	latar.texture = load(mau)
	_pasang_rak()
	_pasang_kabur()
	_pasang_penutup()
	_gelapkan_penutup()
	_pasang_jam_dinding()
	_pasang_catatan_hutang()
	dunia.add_child(lama)
	dunia.move_child(lama, wadah.get_index())
	if tv != null:
		dunia.move_child(tv, wadah.get_index())
	var tw: = create_tween()
	tw.tween_property(lama, "modulate:a", 0.0, DURASI_TRANSISI)
	tw.tween_callback(lama.queue_free)
	for anak in wadah.get_children():
		if anak.has_meta("penutup"):
			var isi: Node2D = anak.get_meta("isi")
			isi.modulate.a = 0.0
			create_tween().tween_property(isi, "modulate:a", 1.0, DURASI_TRANSISI)
	for anak in penutup_lama:
		GameState.get_tree().create_timer(DURASI_TRANSISI).timeout.connect(anak.queue_free)



func buka_dialog(id: String, baris_langsung: Array = []) -> void :
	var baris: Array = baris_langsung if not baris_langsung.is_empty() else data.get("dialog", {}).get(id, [])
	if baris.is_empty() or dialog.visible:
		return
	var sibuk_sebelum: = sibuk
	sibuk = true
	tombol_aksi.hide()
	dialog.tampilkan(baris)
	await dialog.selesai
	sibuk = sibuk_sebelum





func tampilkan_dialog_cerita() -> void :
	while hp.visible:
		await get_tree().process_frame
	if sibuk or pindah or dialog.visible:
		return
	var baris: Array = []
	var sisa: Array = []
	for kunci in GameState.dialog_tertunda:
		if kunci in ["tamat", "awal:0"]:
			sisa.append(kunci)
			continue
		var isi: = GameState.isi_dialog(kunci)
		GameState.simpan_dialog_ke_chat(kunci, isi)
		for b in isi:
			baris.append(_baris_dialog_cerita(String(b[0]), String(b[1])))
	if baris.is_empty():
		return
	GameState.dialog_tertunda = sisa
	GameState.simpan()
	pesan.text = ""
	buka_dialog("", baris)



func _baris_dialog_cerita(pembicara: String, teks: String) -> Dictionary:
	if pembicara == "Bapak":
		return {"siapa": "bapak", "teks": teks}
	if pembicara == "Agus":
		return {"siapa": "agus", "nama": "Agus (lewat telepon)", "teks": teks}
	if pembicara.begins_with("Kontak|"):
		var bagian: = pembicara.split("|")
		return {"siapa": "pak_rt" if bagian[2] == "rt" else bagian[2], "nama": "%s (lewat telepon)" % bagian[1], "teks": teks}
	return {"siapa": "", "teks": teks}



func _judul_besar(teks: String) -> void :
	var l: = Label.new()
	l.text = teks
	l.set_anchors_preset(Control.PRESET_FULL_RECT)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", 72)
	l.add_theme_color_override("font_color", Color(1.0, 0.86, 0.3))
	l.add_theme_color_override("font_outline_color", Color(0.25, 0.12, 0.02))
	l.add_theme_constant_override("outline_size", 14)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.pivot_offset = get_viewport().get_visible_rect().size / 2.0
	ui.add_child(l)
	l.modulate.a = 0.0
	l.scale = Vector2(0.7, 0.7)
	var tw: = create_tween()
	tw.tween_property(l, "modulate:a", 1.0, 0.3)
	tw.parallel().tween_property(l, "scale", Vector2.ONE, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_interval(2.2)
	tw.tween_property(l, "modulate:a", 0.0, 0.6)
	tw.tween_callback(l.queue_free)






const WARNA_EMAS: = Color(1.0, 0.82, 0.38)
const WARNA_PANEL_MISI: = Color(0.07, 0.05, 0.03, 0.78)
var panel_misi: PanelContainer = null






func _pasang_di_bawah_hp(p: Control) -> void :
	if hp == null or hp.get_parent() == null:
		ui.add_child(p)
		return
	var akar: = hp.get_parent()


	p.theme = ThemeDB.get_default_theme()
	akar.add_child(p)
	akar.move_child(p, hp.get_index())
var tombol_tanpa_iklan: Button = null
var tombol_dukung: Button = null
var _isi_misi_lalu: = ""
var _misi_terbuka: = false


const ALFA_MISI_TERTUTUP: = 0.15
const MAKS_MISI_TAMPIL: = 2

func _bapak_di_balik_misi() -> bool:
	if bapak == null or not panel_misi.visible:
		return false
	var kaki: = bapak.get_global_transform_with_canvas().origin
	var tinggi: = float(area.get("tinggi_dewasa", 150)) * kamera.zoom.y
	return panel_misi.get_global_rect().intersects(Rect2(kaki.x - tinggi * 0.25, kaki.y - tinggi, tinggi * 0.5, tinggi))


func _perbarui_daftar_misi() -> void :
	var aktif: = GameState.misi_warga_aktif()
	var baris: Array = []

	if GameState.kekurangan_kiriman() > 0:
		baris.append(["MISI UTAMA · %s" % String(GameState.data_bab()["judul"]), GameState.teks_cara_kirim(), 
			"Batas %s · %s" % [GameState.teks_tanggal(GameState.batas_hari), "hari ini!" if GameState.sisa_hari() <= 1 else "%d hari lagi" % GameState.sisa_hari()]])
	for m in aktif:
		var ev: Dictionary = GameState.data_event()[String(m[0])]
		var t: Dictionary = m[1]
		var nama_area: String = String(data["area"][String(t.get("area", ""))]["nama"]) if data["area"].has(String(t.get("area", ""))) else "Seluruh kampung"
		var teks: = String(t.get("misi", ""))

		if t.has("temui"):
			teks += " (%d/%d)" % [GameState.temui_sudah(String(m[0])).size(), (t["temui"] as Array).size()]
		if teks == "":
			teks = "Temui %s di %s" % [_nama_tipe(String(t["npc"])), nama_area]
		baris.append([String(ev["judul"]), teks, "%s · %s" % [_jam_misi(String(m[0]), t), nama_area], String(m[0])])
	var selesai: = 0

	var semua: Array = GameState.data_event().keys().filter( func(i): return GameState.cerita_tampil_di_daftar(String(i)))
	for id in semua:
		if GameState.hasil_event(id) != "":
			selesai += 1
	var tanda: = "%s|%s|%d|%d|%s" % [str(baris), str(_misi_terbuka), selesai, GameState.level(), str(GameState.panel_misi_kecil)]
	if panel_misi != null and tanda == _isi_misi_lalu:
		panel_misi.visible = not sibuk
		return
	_isi_misi_lalu = tanda
	if panel_misi == null:
		panel_misi = PanelContainer.new()

		var gaya: = GH.kaca(0.6, 8)
		gaya.content_margin_left = 12
		gaya.content_margin_right = 12
		gaya.content_margin_top = 8
		gaya.content_margin_bottom = 10
		gaya.shadow_color = Color(0, 0, 0, 0.35)
		gaya.shadow_size = 5
		panel_misi.add_theme_stylebox_override("panel", gaya)
		panel_misi.position = Vector2(GH.tepi_kiri_kanan(get_viewport()).x, 204)


		panel_misi.mouse_filter = Control.MOUSE_FILTER_STOP
		_pasang_di_bawah_hp(panel_misi)

	for c in panel_misi.get_children():
		panel_misi.remove_child(c)
		c.queue_free()
	var kolom: = VBoxContainer.new()
	kolom.add_theme_constant_override("separation", 6)
	kolom.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel_misi.add_child(kolom)

	if GameState.panel_misi_kecil:
		var ringkas: = "Belum ada misi aktif" if baris.is_empty() else String(baris[0][1])
		kolom.add_child(_baris_kecil("berlian", "MISI %d/%d" % [selesai, semua.size()], ringkas, func():
			GameState.panel_misi_kecil = false
			GameState.simpan_pengaturan()
			_perbarui_daftar_misi.call_deferred()))
		panel_misi.size = Vector2.ZERO
		panel_misi.reset_size()
		panel_misi.call_deferred("reset_size")
		panel_misi.visible = not sibuk
		return


	var kepala: = HBoxContainer.new()
	kepala.add_theme_constant_override("separation", 8)
	kepala.custom_minimum_size.y = 40
	kepala.mouse_filter = Control.MOUSE_FILTER_STOP
	kepala.gui_input.connect( func(e: InputEvent):
		if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT and not e.pressed:
			_misi_terbuka = not _misi_terbuka
			GameState.klik()
			_perbarui_daftar_misi.call_deferred())
	kolom.add_child(kepala)
	kepala.add_child(_ikon_misi("berlian"))
	var judul: = _judul_panel("MISI")
	judul.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	kepala.add_child(judul)
	kepala.add_child(_chip("%d/%d" % [selesai, semua.size()], Color(1, 1, 1, 0.12), Color(0.92, 0.9, 0.84), 15))
	var tombol: = Button.new()
	tombol.flat = true
	tombol.focus_mode = Control.FOCUS_NONE
	tombol.custom_minimum_size = Vector2(40, 32)
	tombol.tooltip_text = "Tutup daftar cerita" if _misi_terbuka else "Lihat semua cerita warga"
	var panah: = _ikon_misi("tutup" if _misi_terbuka else "buka")
	panah.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panah.position -= Vector2(11, 11)
	tombol.add_child(panah)
	tombol.mouse_filter = Control.MOUSE_FILTER_IGNORE
	kepala.add_child(tombol)
	kepala.add_child(_tombol_perkecil( func():
		GameState.panel_misi_kecil = true
		_misi_terbuka = false
		GameState.simpan_pengaturan()
		_perbarui_daftar_misi.call_deferred()))

	if baris.is_empty():
		kolom.add_child(_label_misi("Belum ada misi aktif. Cari warga bertanda \"!\" di kampung.", 15, Color(0.85, 0.82, 0.75), 300))


	var wadah_baris: VBoxContainer = kolom
	var gulir_misi: ScrollContainer = null
	if baris.size() > MAKS_MISI_TAMPIL:
		gulir_misi = load("res://scripts/hp/gulir_sentuh.gd").new()
		gulir_misi.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		gulir_misi.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
		gulir_misi.custom_minimum_size = Vector2(320, 150)
		kolom.add_child(gulir_misi)
		wadah_baris = VBoxContainer.new()
		wadah_baris.add_theme_constant_override("separation", 8)
		wadah_baris.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		wadah_baris.mouse_filter = Control.MOUSE_FILTER_PASS
		gulir_misi.add_child(wadah_baris)
	var blok_misi: Array = []
	for b in baris:


		var utama: = String(b[0]).begins_with("MISI UTAMA")
		var aksen: = WARNA_EMAS if utama else Color(0.36, 0.8, 0.78)
		var kartu: = _kartu_aksen(aksen)
		kartu.mouse_filter = Control.MOUSE_FILTER_PASS if gulir_misi != null else Control.MOUSE_FILTER_IGNORE

		if b.size() > 3:
			kartu.mouse_filter = Control.MOUSE_FILTER_PASS if gulir_misi != null else Control.MOUSE_FILTER_STOP
			_bisa_diketuk(kartu, _buka_info_misi.bind(String(b[3])))
		wadah_baris.add_child(kartu)
		blok_misi.append(kartu)
		var blok: = VBoxContainer.new()
		blok.add_theme_constant_override("separation", 3)
		blok.mouse_filter = Control.MOUSE_FILTER_IGNORE
		kartu.add_child(blok)
		if utama:
			var atas_misi: = HBoxContainer.new()
			atas_misi.add_theme_constant_override("separation", 6)
			atas_misi.mouse_filter = Control.MOUSE_FILTER_IGNORE
			atas_misi.add_child(_chip("MISI UTAMA", WARNA_EMAS, Color(0.2, 0.12, 0.02), 13))
			var sisa_judul: = String(b[0]).trim_prefix("MISI UTAMA").trim_prefix(" · ")
			if sisa_judul != "":
				var lj: = _label_misi(sisa_judul, 15, WARNA_EMAS)
				lj.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
				lj.clip_text = true
				lj.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				atas_misi.add_child(lj)
			blok.add_child(atas_misi)
		else:
			blok.add_child(_label_misi(String(b[0]), 15, aksen, 290))
		blok.add_child(_label_misi(String(b[1]), 17, Color.WHITE, 290))
		var ket: = HBoxContainer.new()
		ket.add_theme_constant_override("separation", 5)
		ket.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ket.add_child(_ikon_misi("jam"))
		var mendesak: = String(b[2]).ends_with("hari ini!")
		ket.add_child(_label_misi(String(b[2]), 14, Color(1, 0.62, 0.55) if mendesak else Color(0.78, 0.86, 0.95), 262))
		blok.add_child(ket)

	if gulir_misi != null:
		var ukur: = func():
			if not is_instance_valid(gulir_misi):
				return
			var tinggi: = 0.0
			for i in mini(MAKS_MISI_TAMPIL, blok_misi.size()):
				tinggi += (blok_misi[i] as Control).get_combined_minimum_size().y
			gulir_misi.custom_minimum_size.y = tinggi + 8.0 * (MAKS_MISI_TAMPIL - 1) + 2.0
			panel_misi.reset_size()
		ukur.call_deferred()

	if _misi_terbuka:
		var garis: = ColorRect.new()
		garis.color = Color(WARNA_EMAS, 0.35)
		garis.custom_minimum_size = Vector2(0, 1)
		garis.mouse_filter = Control.MOUSE_FILTER_IGNORE
		kolom.add_child(garis)
		kolom.add_child(_label_misi("Cerita warga · ketuk untuk lihat lokasi", 15, Color(0.85, 0.82, 0.75)))
		var gulir: ScrollContainer = load("res://scripts/hp/gulir_sentuh.gd").new()
		gulir.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		gulir.custom_minimum_size = Vector2(310, mini(semua.size(), 6) * 27)
		kolom.add_child(gulir)
		var daftar: = VBoxContainer.new()
		daftar.add_theme_constant_override("separation", 3)
		daftar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		gulir.add_child(daftar)
		for id in semua:
			var keadaan: = "selesai" if GameState.hasil_event(id) != "" else ("jalan" if aktif.any( func(m): return String(m[0]) == id) else "belum")
			if keadaan == "belum" and not GameState.cerita_terbuka(id):
				keadaan = "terkunci"
			var b: = HBoxContainer.new()
			b.add_theme_constant_override("separation", 8)
			b.mouse_filter = Control.MOUSE_FILTER_PASS
			b.add_child(_ikon_misi(keadaan))
			var warna: = Color(0.62, 0.86, 0.55) if keadaan == "selesai" else (WARNA_EMAS if keadaan == "jalan" else Color(0.8, 0.78, 0.72))
			var judul_cerita: = String(GameState.data_event()[id]["judul"])
			if keadaan == "terkunci":

				warna = Color(0.6, 0.58, 0.54)
				judul_cerita += "  ·  Terbuka di Level %d" % GameState.level_cerita(id)
			var l: = _label_misi(judul_cerita, 16, warna)
			l.mouse_filter = Control.MOUSE_FILTER_PASS
			b.add_child(l)
			if keadaan != "selesai":
				b.custom_minimum_size.y = 34
				_bisa_diketuk(b, _buka_info_misi.bind(String(id)))
			daftar.add_child(b)
	panel_misi.size = Vector2.ZERO
	panel_misi.reset_size()
	panel_misi.call_deferred("reset_size")
	panel_misi.visible = not sibuk







var panel_kerja: PanelContainer = null
var _isi_kerja_lalu: = ""
var ikuti_kerja: = ""
var _rute_ikut: Array = []
var _tujuan_ikut: = Vector2.INF
var _macet_ikut: = 0.0
var _area_ikut: = ""
var _sisi_ikut: = 1.0


func _keadaan_kerja(id: String) -> String:
	var k: Dictionary = GameState.data_kerja(id)
	var jam: = GameState.menit / 60.0
	if int(GameState.kerja_hari.get(id, 0)) == GameState.hari:
		return "selesai"
	if jam >= float(k["jam"][1]):
		return "lewat"
	if jam < float(k["jam"][0]):
		return "nanti"
	return "buka"


func _perbarui_panel_kerja() -> void :
	var daftar: Array = GameState.kerja_daftar_hari() if not GameState.mode_latihan else []
	var tanda: = "%s|%s|%d|%s" % [str(daftar.map( func(id): return id + ":" + _keadaan_kerja(id))), ikuti_kerja, GameState.level(), str(GameState.panel_kerja_kecil)]
	if panel_kerja != null and tanda == _isi_kerja_lalu:
		return
	_isi_kerja_lalu = tanda
	if panel_kerja == null:
		panel_kerja = PanelContainer.new()
		var gaya: = GH.kaca(0.6, 8)
		gaya.content_margin_left = 12
		gaya.content_margin_right = 12
		gaya.content_margin_top = 8
		gaya.content_margin_bottom = 10
		gaya.shadow_color = Color(0, 0, 0, 0.35)
		gaya.shadow_size = 5
		panel_kerja.add_theme_stylebox_override("panel", gaya)
		panel_kerja.mouse_filter = Control.MOUSE_FILTER_STOP
		_pasang_di_bawah_hp(panel_kerja)
	for c in panel_kerja.get_children():
		panel_kerja.remove_child(c)
		c.queue_free()
	if daftar.is_empty():
		panel_kerja.hide()
		return
	var kolom: = VBoxContainer.new()
	kolom.add_theme_constant_override("separation", 6)
	kolom.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel_kerja.add_child(kolom)

	if GameState.panel_kerja_kecil:
		var buka: = daftar.filter( func(id): return _keadaan_kerja(id) == "buka").size()
		var nanti: = daftar.filter( func(id): return _keadaan_kerja(id) == "nanti").size()
		var ringkas: = "Sedang diikuti" if ikuti_kerja in daftar else ("%d bisa dikerjakan" % buka if buka > 0 else ("%d nanti" % nanti if nanti > 0 else "Selesai hari ini"))
		kolom.add_child(_baris_kecil("", "KERJA", ringkas, func():
			GameState.panel_kerja_kecil = false
			GameState.simpan_pengaturan()
			_perbarui_panel_kerja.call_deferred()))
		panel_kerja.show()
		panel_kerja.size = Vector2.ZERO
		panel_kerja.reset_size()
		return
	var kepala: = HBoxContainer.new()
	kepala.add_theme_constant_override("separation", 8)
	kepala.mouse_filter = Control.MOUSE_FILTER_IGNORE
	kolom.add_child(kepala)

	var judul_kerja: = _judul_panel("KERJA SAMPINGAN")
	judul_kerja.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	kepala.add_child(judul_kerja)
	kepala.add_child(_tombol_perkecil( func():
		GameState.panel_kerja_kecil = true
		GameState.simpan_pengaturan()
		_perbarui_panel_kerja.call_deferred()))
	for id in daftar:
		var k: Dictionary = GameState.data_kerja(id)
		var keadaan: = _keadaan_kerja(id)

		var aksen_kerja: Color = {"buka": Color(0.38, 0.82, 0.42), "nanti": Color(0.45, 0.66, 0.95)}.get(keadaan, Color(0.6, 0.6, 0.6))
		var kartu: = _kartu_aksen(aksen_kerja)
		kartu.modulate.a = 0.6 if keadaan == "lewat" else 1.0
		kolom.add_child(kartu)
		var blok: = VBoxContainer.new()
		blok.add_theme_constant_override("separation", 4)
		blok.mouse_filter = Control.MOUSE_FILTER_IGNORE
		kartu.add_child(blok)
		blok.add_child(_label_misi(String(k["judul"]), 17, Color.WHITE, 270))
		var nama_area: String = String(data["area"][String(k["area"])]["nama"]) if data["area"].has(String(k["area"])) else String(k["area"])
		var ket: = HBoxContainer.new()
		ket.add_theme_constant_override("separation", 5)
		ket.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ket.add_child(_ikon_misi("jam"))
		ket.add_child(_label_misi("%s-%s · %s" % [GameState._jam_titik(float(k["jam"][0])), GameState._jam_titik(float(k["jam"][1])), GameState.tk(nama_area)], 14, Color(0.78, 0.86, 0.95)))
		ket.add_child(_pil_upah(GameState.format_rupiah(GameState.upah_kerja(id))))
		if keadaan != "selesai":
			blok.add_child(ket)
		else:
			ket.free()
		match keadaan:
			"selesai":

				var sudah: = HBoxContainer.new()
				sudah.add_theme_constant_override("separation", 6)
				sudah.mouse_filter = Control.MOUSE_FILTER_IGNORE
				sudah.add_child(_ikon_misi("selesai"))
				sudah.add_child(_label_misi("Sudah dikerjakan", 15, Color(0.62, 0.86, 0.55)))
				blok.add_child(sudah)
			"lewat":
				blok.add_child(_chip("Sudah lewat", Color(1, 1, 1, 0.12), Color(0.85, 0.83, 0.78), 13))
			_:
				var b: = Button.new()
				b.focus_mode = Control.FOCUS_NONE
				b.text = "Berhenti mengikuti" if ikuti_kerja == id else "Ikuti"

				if keadaan == "nanti" and ikuti_kerja != id:
					b.text = "Mulai %s" % GameState._jam_titik(float(k["jam"][0]))
					b.disabled = true


				b.theme = GH.tema_jendela()
				b.theme_type_variation = &"TombolKayu" if ikuti_kerja == id else &"TombolHijau"
				b.custom_minimum_size = Vector2(0, 36)
				b.add_theme_font_size_override("font_size", 16)
				b.pressed.connect( func():
					if ikuti_kerja == id:
						_batal_ikuti()
					else:
						mulai_ikuti_kerja(id)
					_perbarui_panel_kerja.call_deferred())
				blok.add_child(b)
	panel_kerja.show()
	panel_kerja.size = Vector2.ZERO
	panel_kerja.reset_size()



func _kartu_aksen(aksen: Color) -> PanelContainer:
	var kartu: = PanelContainer.new()
	var sb: = StyleBoxFlat.new()
	sb.bg_color = Color(1, 1, 1, 0.07)
	sb.set_corner_radius_all(10)
	sb.border_width_left = 5
	sb.border_color = aksen
	sb.content_margin_left = 12
	sb.content_margin_right = 10
	sb.content_margin_top = 7
	sb.content_margin_bottom = 8
	kartu.add_theme_stylebox_override("panel", sb)
	kartu.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return kartu



func _judul_panel(teks: String) -> Label:
	var l: = GH.tebal(GH.label(teks, 22, WARNA_EMAS, true))
	l.add_theme_constant_override("outline_size", 5)
	return l



func _chip(teks: String, latar: Color, warna_teks: Color, ukuran: = 14) -> PanelContainer:
	var pil: = PanelContainer.new()
	var sb: = StyleBoxFlat.new()
	sb.bg_color = latar
	sb.set_corner_radius_all(8)
	sb.content_margin_left = 8
	sb.content_margin_right = 8
	sb.content_margin_top = 1
	sb.content_margin_bottom = 2
	pil.add_theme_stylebox_override("panel", sb)
	pil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pil.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	pil.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	var l: = _label_misi(teks, ukuran, warna_teks)
	l.add_theme_constant_override("outline_size", 0)
	l.add_theme_font_override("font", GH.font("Nunito", 900))
	pil.add_child(l)
	return pil



func _pil_upah(teks: String) -> PanelContainer:
	var pil: = PanelContainer.new()
	var gaya: = StyleBoxFlat.new()
	gaya.bg_color = Color(0.2, 0.62, 0.27)
	gaya.set_corner_radius_all(9)
	gaya.content_margin_left = 8
	gaya.content_margin_right = 8
	gaya.content_margin_top = 1
	gaya.content_margin_bottom = 1
	pil.add_theme_stylebox_override("panel", gaya)
	pil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pil.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var l: = _label_misi(teks, 15, Color.WHITE)
	l.add_theme_color_override("font_outline_color", Color(0, 0.25, 0.05, 0.7))
	pil.add_child(l)
	return pil


func _bapak_di_balik(c: Control) -> bool:
	if bapak == null or c == null or not c.visible:
		return false
	var kaki: = bapak.get_global_transform_with_canvas().origin
	var tinggi: = float(area.get("tinggi_dewasa", 150)) * kamera.zoom.y
	return c.get_global_rect().intersects(Rect2(kaki.x - tinggi * 0.25, kaki.y - tinggi, tinggi * 0.5, tinggi))


func mulai_ikuti_kerja(id: String) -> void :
	if sibuk or dialog.visible or _keadaan_kerja(id) != "buka":
		return
	ikuti_kerja = id
	GameState.kerja_tujuan = id
	_rute_ikut = []
	_tujuan_ikut = Vector2.INF
	_macet_ikut = 0.0
	GameState.klik()
	var k: Dictionary = GameState.KERJA_SAMPINGAN[id]
	tampilkan_pesan("Pak Misran menuju %s. Gerakkan joystick untuk berhenti mengikuti." % String(k["nama"]), 3.0)


func _batal_ikuti() -> void :
	ikuti_kerja = ""
	_rute_ikut = []
	_tujuan_ikut = Vector2.INF
	_isi_kerja_lalu = ""



func _sasaran_ikut() -> Array:
	var k: Dictionary = TITIK_JUMATAN if ikuti_kerja == IKUTI_JUMATAN else GameState.KERJA_SAMPINGAN[ikuti_kerja]
	var tujuan_area: = String(k["area"])
	if tujuan_area == area_id:
		return [_v(k["posisi"]), {}, "npc"]
	var lanjut: = _area_berikut(area_id, tujuan_area)
	if lanjut == "":
		return []
	var jari: = float(area["tinggi_dewasa"]) * 0.32
	var terbaik: Array = []
	var jarak_min: = INF
	for p in area.get("pintu", []):
		var aksi: = String(p["aksi"])
		if aksi.begins_with("area:") and aksi.split(":")[1] == lanjut:
			var titik: = _v(p["posisi"])
			var d: = bapak.position.distance_to(titik)
			if d < jarak_min:
				jarak_min = d
				terbaik = [titik, p, "pintu"]
	for t in area.get("tepi", []):
		var aksi: = String(t["aksi"])
		if aksi.begins_with("area:") and aksi.split(":")[1] == lanjut:
			var titik: = _v(t["penunjuk"]) if t.has("penunjuk") else _titik_tepi(t, jari)
			if titik == Vector2.INF:
				continue
			var d: = bapak.position.distance_to(titik)
			if d < jarak_min:
				jarak_min = d
				terbaik = [titik, t, "tepi"]
	return terbaik


func _gerak_ikuti(delta: float) -> void :
	var jumatan: = ikuti_kerja == IKUTI_JUMATAN

	if jumatan and not _jumatan_masih_berlaku():
		_batal_ikuti()
		_diam_ikut()
		return

	if jumatan and GameState.menit >= JAM_SELESAI_JUMATAN - 5:
		_sampai_jumatan()
		return
	if not jumatan and ( not GameState.KERJA_SAMPINGAN.has(ikuti_kerja) or _keadaan_kerja(ikuti_kerja) in ["selesai", "lewat"]):
		_batal_ikuti()
		return
	if _area_ikut != area_id:
		_area_ikut = area_id
		_rute_ikut = []
		_tujuan_ikut = Vector2.INF
	var s: = _sasaran_ikut()
	if s.is_empty():
		if jumatan:
			_sampai_jumatan()
			return
		_batal_ikuti()
		return
	var tujuan: Vector2 = s[0]
	var tinggi: = float(area.get("tinggi_dewasa", 150))
	var jarak: = bapak.position.distance_to(tujuan)
	match String(s[2]):
		"npc":
			if jumatan and jarak <= tinggi * 0.35:
				_sampai_jumatan()
				return
			if not jumatan and jarak <= tinggi * JARAK_NGOBROL * 1.1:
				var k: Dictionary = GameState.data_kerja(ikuti_kerja)
				if _keadaan_kerja(ikuti_kerja) == "nanti":
					tampilkan_pesan("Sudah sampai. Kerja %s mulai pukul %s." % [String(k["nama"]), GameState._jam_titik(float(k["jam"][0]))], 4.0)
				_batal_ikuti()
				_diam_ikut()
				return
		"pintu":
			if jarak <= maxf(float((s[1] as Dictionary).get("radius", 60.0)) * 0.6, tinggi * 0.2):
				_diam_ikut()
				_rute_ikut = []
				_buka_pintu(s[1])
				return
		"tepi":
			if jarak <= tinggi * 0.3:
				_diam_ikut()
				_rute_ikut = []
				_jalankan(String((s[1] as Dictionary)["aksi"]))
				return
	if _rute_ikut.is_empty() or _tujuan_ikut.distance_to(tujuan) > 1.0:
		_rute_ikut = _rute_lantai(bapak.position, tujuan)
		_tujuan_ikut = tujuan
	while not _rute_ikut.is_empty() and bapak.position.distance_to(_rute_ikut[0]) < 4.0:
		_rute_ikut.pop_front()
	if _rute_ikut.is_empty():
		_diam_ikut()
		return
	var titik: Vector2 = _rute_ikut[0]
	var lari: = GameState.energi >= GameState.ENERGI_MIN_BUKA and _digendong == ""
	var kecepatan: float = KECEPATAN_METER * bapak.tinggi_dewasa_latar / SCRIPT_PELANGGAN.TINGGI_DEWASA_METER * bapak.faktor_jarak() * GameState.pengali_jalan_lelah()
	if lari:
		kecepatan *= PENGALI_LARI_PAYUNG if (GameState.sedang_hujan() and not bool(area.get("dalam_ruangan", false))) else PENGALI_LARI
		GameState.energi = maxf(GameState.energi - GameState.ENERGI_LARI_PER_DETIK * delta * (GameState.PENGALI_ENERGI_RUMAH_BARU if GameState.rumah_renovasi else 1.0), 0.0)
	var arah: = (titik - bapak.position).normalized()
	var baru: = bapak.position + arah * minf(kecepatan * delta, bapak.position.distance_to(titik))


	if not _boleh(baru, bapak.position) and _boleh(bapak.position, bapak.position):
		for sudut in [0.6, 1.1, 1.6]:
			var lolos: = false
			for sisi in [_sisi_ikut, - _sisi_ikut]:
				var a2: = arah.rotated(sudut * sisi)
				var b2: = bapak.position + a2 * kecepatan * delta
				if _boleh(b2, bapak.position):
					arah = a2
					baru = b2
					_sisi_ikut = sisi
					lolos = true
					break
			if lolos:
				break
	if not _boleh(baru, bapak.position) and _boleh(bapak.position, bapak.position):

		_macet_ikut += delta
		if _macet_ikut > 1.2:
			_rute_ikut = []
		if _macet_ikut > 5.0:
			if jumatan:
				_sampai_jumatan()
				_diam_ikut()
				return
			_batal_ikuti()
			tampilkan_pesan("Jalannya terhalang. Lanjutkan dengan joystick, ya.", 3.0)
		_diam_ikut()
		return
	_macet_ikut = 0.0
	bapak.karakter.arah_layar = arah
	bapak.position = baru
	bapak.karakter.ganti_anim_jalan("Running" if lari else "Walking")
	bapak.sedang_jalan = true
	waktu_langkah -= delta
	if waktu_langkah <= 0.0:
		GameState.langkah_kaki(lari, not bool(area.get("dalam_ruangan", false)))
		waktu_langkah = JEDA_LANGKAH_LARI if lari else JEDA_LANGKAH


func _diam_ikut() -> void :
	bapak.sedang_jalan = false
	bapak.karakter.ganti_anim_jalan("Walking")




func _jam_misi(id: String, t: Dictionary) -> String:
	var j: = GameState.jam_cerita(id, t)
	return "%s-%s" % [GameState._jam_titik(float(j[0])), GameState._jam_titik(float(j[1]))]



func _bisa_diketuk(c: Control, aksi: Callable) -> void :
	c.gui_input.connect( func(e: InputEvent):
		if not (e is InputEventMouseButton) or e.button_index != MOUSE_BUTTON_LEFT:
			return
		if e.pressed:
			c.set_meta("tekan", e.global_position)
		elif c.has_meta("tekan"):
			var awal: Vector2 = c.get_meta("tekan")
			c.remove_meta("tekan")
			if e.global_position.distance_to(awal) < 16.0:
				aksi.call())


const INFO_MISI: = preload("res://scripts/info_misi.gd")


func _buka_info_misi(id: String) -> void :
	if sibuk or dialog.visible or not GameState.data_event().has(id):
		return
	var j: = GameState.jadwal_cerita(id)
	var t: Dictionary = j["tahap"]

	var orang: Array = GameState.temui_sisa(id) if t.has("temui") else [t]
	if orang.is_empty():
		return

	var kelompok: Array = []
	for o in orang:
		var a: = String(o["area"])
		var isi_area: Dictionary = {}
		for k in kelompok:
			if String(k["area"]) == a:
				isi_area = k
		if isi_area.is_empty():
			isi_area = {"area": a, "tempat": _nama_area_misi(a), "gambar": String(data["area"][a]["gambar"]) if data["area"].has(a) else "", 
				"titik": [], "nama": [], "saya": bapak.position if area_id == a else Vector2(-1, -1)}
			kelompok.append(isi_area)
		var nama: = _nama_tipe(String(o["npc"]))
		isi_area["nama"].append(nama)
		isi_area["titik"].append({"nama": nama, "posisi": _v(o["posisi"])})
	var tugas: = String(t.get("misi", ""))
	if tugas == "":
		tugas = "Temui %s di %s" % [kelompok[0]["nama"][0], kelompok[0]["tempat"]]
	var data_info: = {"judul": String(GameState.data_event()[id]["judul"]), "tugas": tugas, "kelompok": kelompok, 
		"hari": j["hari"], "jam": j["jam"], "catatan": j["catatan"], "syarat": j["syarat"], "keadaan": j["keadaan"], "status": j["status"]}
	sibuk = true
	bapak.sedang_jalan = false
	tombol_aksi.hide()
	var p: = INFO_MISI.new()
	ui.add_child(p)
	p.isi(data_info)
	await p.ditutup
	sibuk = false
	_perbarui_daftar_misi.call_deferred()


func _nama_area_misi(a: String) -> String:
	return String(data["area"][a]["nama"]) if data["area"].has(a) else "Seluruh kampung"



func _tombol_perkecil(aksi: Callable) -> Button:
	var b: = Button.new()
	b.flat = true
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(40, 32)
	b.tooltip_text = "Perkecil"
	var ikon: = _ikon_misi("kecil")
	ikon.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	ikon.position -= Vector2(11, 11)
	b.add_child(ikon)
	b.pressed.connect( func():
		GameState.klik()
		aksi.call())
	return b



func _baris_kecil(ikon: String, judul: String, ringkas: String, buka: Callable) -> HBoxContainer:
	var h: = HBoxContainer.new()
	h.add_theme_constant_override("separation", 8)
	h.custom_minimum_size.y = 34
	h.mouse_filter = Control.MOUSE_FILTER_STOP
	h.gui_input.connect( func(e: InputEvent):
		if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT and not e.pressed:
			GameState.klik()
			buka.call())
	if ikon != "":
		h.add_child(_ikon_misi(ikon))
	h.add_child(_label_misi(judul, 17, WARNA_EMAS))
	var l: = _label_misi(ringkas, 15, Color(0.92, 0.9, 0.85))
	l.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	l.clip_text = true
	l.custom_minimum_size.x = 170 if ikon != "" else 130
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(l)
	h.add_child(_ikon_misi("besar"))
	return h


func _label_misi(teks: String, ukuran: int, warna: Color, lebar: = 0) -> Label:
	var l: = Label.new()
	l.text = teks
	l.add_theme_font_size_override("font_size", ukuran)
	l.add_theme_color_override("font_color", warna)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.6))
	l.add_theme_constant_override("outline_size", 3)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if lebar > 0:
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size.x = lebar
	return l




func _ikon_misi(jenis: String) -> Control:
	var c: = Control.new()
	c.custom_minimum_size = Vector2(22, 22)
	c.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.draw.connect(_gambar_ikon_misi.bind(c, jenis))
	return c


func _gambar_ikon_misi(c: Control, jenis: String) -> void :
	var p: = Vector2(11, 11)
	match jenis:
		"berlian":
			c.draw_colored_polygon(PackedVector2Array([p + Vector2(0, -10), p + Vector2(10, 0), p + Vector2(0, 10), p + Vector2(-10, 0)]), WARNA_EMAS)
			c.draw_line(p + Vector2(0, -5), p + Vector2(0, 2), Color(0.2, 0.1, 0.0), 2.5)
			c.draw_circle(p + Vector2(0, 5.5), 1.5, Color(0.2, 0.1, 0.0))
		"buka", "tutup":
			var a: = 1.0 if jenis == "buka" else -1.0
			c.draw_polyline(PackedVector2Array([p + Vector2(-6, -3 * a), p + Vector2(0, 3 * a), p + Vector2(6, -3 * a)]), WARNA_EMAS, 2.5, true)
		"kecil", "besar":

			c.draw_rect(Rect2(p.x - 9, p.y - 9, 18, 18), Color(WARNA_EMAS, 0.85), false, 1.6)
			c.draw_line(p + Vector2(-5, 0), p + Vector2(5, 0), WARNA_EMAS, 2.4)
			if jenis == "besar":
				c.draw_line(p + Vector2(0, -5), p + Vector2(0, 5), WARNA_EMAS, 2.4)
		"jam":
			c.draw_arc(p, 7.0, 0.0, TAU, 20, Color(0.78, 0.86, 0.95), 1.6, true)
			c.draw_line(p, p + Vector2(0, -4.5), Color(0.78, 0.86, 0.95), 1.6)
			c.draw_line(p, p + Vector2(3.5, 0), Color(0.78, 0.86, 0.95), 1.6)
		"selesai":
			c.draw_circle(p, 9.0, Color(0.3, 0.68, 0.32))
			c.draw_polyline(PackedVector2Array([p + Vector2(-4.5, 0), p + Vector2(-1.2, 3.5), p + Vector2(5, -3.5)]), Color.WHITE, 2.4, true)
		"jalan":
			c.draw_arc(p, 8.0, 0.0, TAU, 24, WARNA_EMAS, 2.2, true)
			c.draw_circle(p, 3.5, WARNA_EMAS)
		"terkunci":
			var abu: = Color(0.62, 0.6, 0.56)
			c.draw_arc(p + Vector2(0, -2), 4.5, PI, TAU, 12, abu, 2.0, true)
			c.draw_rect(Rect2(p.x - 6.5, p.y - 2.0, 13.0, 10.0), abu)
		_:
			c.draw_arc(p, 8.0, 0.0, TAU, 24, Color(0.8, 0.78, 0.72, 0.8), 2.0, true)



const PANAH_AKRAB: = preload("res://scripts/panah_akrab.gd")

func _on_akrab_naik(tipe: String, naik_tingkat: bool) -> void :
	for w in warga:
		if is_instance_valid(w) and String(w.get_meta("tipe", "")) == tipe:
			PANAH_AKRAB.tampilkan(w, naik_tingkat)
			return
	GameState.bunyi("akrab_naik")




func _buka_dukungan() -> void :
	var d: = preload("res://scripts/dukungan.gd").new()
	sibuk = true
	(dialog.get_parent() as Control).add_child(d)
	await d.ditutup
	sibuk = false


func _buka_pengaturan() -> void :
	var p: Control = load("res://scenes/pengaturan.tscn").instantiate()
	p.dalam_game = true
	p.bisa_reset_posisi = true
	sibuk = true
	(dialog.get_parent() as Control).add_child(p)
	await p.ditutup
	sibuk = false
	if p.minta_reset_posisi:
		_reset_posisi_misran()





func _reset_posisi_misran() -> void :
	if pindah or sinema_khusus or _sinema_aktif or area.is_empty() or not is_instance_valid(bapak):
		tampilkan_pesan("Tunggu sebentar sampai adegan ini selesai, lalu coba lagi.", 4.0)
		return
	var semua_muncul: Dictionary = area.get("muncul", {})
	if semua_muncul.is_empty():
		return
	var kunci_dekat: String = String(semua_muncul.keys()[0])
	var pos: Vector2 = bapak.position
	if is_finite(pos.x) and is_finite(pos.y):
		var jarak_min: = INF
		for k in semua_muncul:
			var d: = pos.distance_to(_v(semua_muncul[k]))
			if d < jarak_min:
				jarak_min = d
				kunci_dekat = String(k)
	bapak.sedang_jalan = false
	await _masuk_area(area_id, kunci_dekat, true)
	tampilkan_pesan("Pak Misran sudah dipindahkan ke tempat aman.", 3.5)







const AREA_NEO: = ["rumah"]
const JAM_NEO: = [7.0, 21.0]
const KECEPATAN_NEO: = 0.5
const KECEPATAN_NEO_LARI: = 1.7
const PELUANG_NEO_LARI: = 0.25
const RADIUS_NEO: = 5.0
const SAPAAN_NEO: = [
	"Eh, Neo! Jalan-jalan sendiri lagi, ya?", 
	"Neo, sudah makan belum? Nanti Mba Giska nyariin, lho.", 
	"Halo, Neo. Jangan main jauh-jauh, nanti tersesat.", 
	"Pus, pus... sini, Neo. Wah, bulunya halus sekali.", 
	"Neo, jangan nyeberang jalan sendirian, ya. Banyak motor lewat."]
const KECEPATAN_DATANG_TOKOH: = 70.0
const JAWAB_NEO: = ["Meong~", "Meooong!", "Mrrrp... meong.", "Meong! (menggesekkan badan ke kaki Pak Misran)", "Meong..."]

const OBROLAN_NEO_AKRAB: = [
	["Neo! Sini, sini. Bapak sudah sisihkan makanan buat kamu, lho.", "Meong! (melompat ke pangkuan Pak Misran)"], 
	["Kamu nungguin Bapak pulang dari warung, ya? Setia sekali kamu.", "Mrrr... (berjalan mengekor di belakang Pak Misran)"], 
	["Neo, nanti kalau Agus pulang, kenalan, ya. Dia pasti suka sama kamu.", "Meong~ (ekornya tegak, bergetar senang)"], 
	["Kata Mba Giska, sekarang kamu lebih sering main ke rumah Bapak daripada di rumahnya sendiri.", "Meong! (menggosokkan kepala ke tangan Pak Misran)"], 
	["Capek sekali hari ini, Neo... Tapi lihat kamu, capeknya hilang.", "Purrr... (mendengkur pelan di samping Pak Misran)"], 
]
var _obrolan_neo_akrab: = 0


func _teks_makan_neo(alasan: String) -> String:
	if GameState.neo_makan_hari == GameState.hari:
		return "Kasih makan (sudah makan hari ini)"
	if not GameState.terbuka("makanan_kucing"):
		return "Kasih makan (warung belum jual makanan kucing)"
	if alasan != "":
		return "Kasih makan (stok makanan kucing habis)"
	return "Kasih makan (makanan kucing, stok %d)" % int(GameState.stok.get("makanan_kucing", 0))
var neo: Sprite2D = null
var _pusat_neo: = Vector2.ZERO
var _tujuan_neo: = Vector2.ZERO
var _diam_neo: = 2.0
var _cek_neo: = 0.0
var _sapaan_neo_lalu: = -1
var _pemutar_neo: AudioStreamPlayer = null
var _laju_neo: = 0.15
var _neo_lari: = false


func _neo_boleh_keluar() -> bool:
	var jam: = GameState.menit / 60.0
	if not area_id in AREA_NEO or jam < JAM_NEO[0] or jam >= JAM_NEO[1] or GameState.sedang_hujan() or GameState.mode_latihan:
		return false

	if GameState.hasil_event("kucing_bu_ida") != "tolong" or GameState.tipe_cerita_aktif().has("kucing"):
		return false

	for w in warga:
		if is_instance_valid(w) and ((w != neo and String(w.get_meta("tipe", "")) == "kucing") or w.has_meta("gendong_neo")):
			return false
	return data_tokoh.has("kucing")



func _titik_neo_acak(dari: Vector2, jauh: = 1.0) -> Vector2:
	var t: = float(area.get("tinggi_dewasa", 150))
	for i in 40:
		var arah: = Vector2.from_angle(randf() * TAU)
		var p: = dari + Vector2(arah.x, arah.y * 0.6) * randf_range(0.6, 2.4) * jauh * t
		if p.distance_to(_pusat_neo) > RADIUS_NEO * t:
			continue
		var aman: = true
		for k in 7:
			if not _titik_lantai_bebas(dari.lerp(p, (k + 1) / 7.0)):
				aman = false
				break
		if aman:
			return p
	return dari


func _titik_lantai_bebas(p: Vector2) -> bool:
	var di_lantai: = false
	for poli in lantai:
		if Geometry2D.is_point_in_polygon(p, poli):
			di_lantai = true
			break
	if not di_lantai:
		return false
	for poli in halangan:
		if Geometry2D.is_point_in_polygon(p, poli):
			return false
	return true


func _pasang_neo() -> void :
	if jalur_tengah.size() < 2:
		return

	var total: float = panjang_jalur[-1]
	for coba in 20:
		var t: Array = _titik_jalur(total * randf_range(0.25, 0.75))
		var p: Vector2 = t[0]
		if _titik_lantai_bebas(p) and p.distance_to(bapak.position) > float(area.get("tinggi_dewasa", 150)) * 1.5:
			_pusat_neo = p
			break
	if _pusat_neo == Vector2.ZERO:
		return
	neo = _buat_orang("kucing")
	neo.set_meta("diam", true)
	neo.set_meta("neo", true)
	neo.arah_manual = true
	neo.position = _titik_neo_acak(_pusat_neo)
	_tujuan_neo = neo.position
	_diam_neo = randf_range(2.0, 6.0)
	neo.modulate.a = 0.0
	neo.create_tween().tween_property(neo, "modulate:a", 1.0, 0.6)


func _perbarui_neo(delta: float) -> void :
	if neo != null and not is_instance_valid(neo):
		neo = null
	_cek_neo -= delta
	if _cek_neo <= 0.0:
		_cek_neo = 2.0
		var boleh: = _neo_boleh_keluar()
		if neo == null and boleh:
			_pusat_neo = Vector2.ZERO
			_pasang_neo()
		elif neo != null and not boleh and not neo.has_meta("ngobrol"):
			_warga_pergi(neo)
			neo = null
	if neo == null or neo.has_meta("ngobrol") or neo.has_meta("pergi"):
		if neo != null:
			neo.sedang_jalan = false
		return

	var t_orang: = float(area.get("tinggi_dewasa", 150))
	if _jarak_lantai(bapak.position, neo.position) < t_orang * 0.9:
		neo.sedang_jalan = false
		neo.karakter.arah_layar = (bapak.position - neo.position).normalized()
		_tujuan_neo = neo.position
		_diam_neo = maxf(_diam_neo, 2.0)
		return
	var ke: = _tujuan_neo - neo.position
	if ke.length() > 2.0:
		var t: = float(area.get("tinggi_dewasa", 150))

		_laju_neo = move_toward(_laju_neo, KECEPATAN_NEO_LARI if _neo_lari else KECEPATAN_NEO, delta * 1.5)
		var laju: = _laju_neo * t / SCRIPT_PELANGGAN.TINGGI_DEWASA_METER
		if ke.length() < t * 0.25:
			laju *= clampf(ke.length() / (t * 0.25), 0.35, 1.0)
		neo.position += ke.normalized() * minf(laju * delta, ke.length())
		neo.karakter.arah_layar = ke.normalized()
		neo.karakter.berlari = _neo_lari
		neo.sedang_jalan = true
		return
	neo.sedang_jalan = false
	neo.karakter.berlari = false
	_laju_neo = 0.15
	_diam_neo -= delta
	if _diam_neo <= 0.0:
		_diam_neo = randf_range(4.0, 12.0)

		_neo_lari = randf() < PELUANG_NEO_LARI
		_tujuan_neo = _titik_neo_acak(neo.position, 1.6 if _neo_lari else 1.0)


func _sapa_neo(w: Sprite2D) -> void :
	var nomor: = randi() % SAPAAN_NEO.size()
	if nomor == _sapaan_neo_lalu:
		nomor = (nomor + 1) % SAPAAN_NEO.size()
	_sapaan_neo_lalu = nomor
	w.set_meta("ngobrol", true)
	w.sedang_jalan = false
	var arah: = (bapak.position - w.position).normalized()

	if w.karakter != null:
		w.karakter.arah_layar = arah
	if bapak.karakter != null:
		bapak.karakter.arah_layar = - arah
	bapak.sedang_jalan = false
	sibuk = true
	tombol_aksi.hide()


	var gs: = GameState
	var alasan_makan: = gs.alasan_tidak_bisa_kasih_makan_neo()
	var opsi: = [{"teks": "Elus Neo"}, 
		{"teks": _teks_makan_neo(alasan_makan), "aktif": alasan_makan == ""}, 
		{"teks": "Sudah dulu"}]
	var pilih: int = await dialog.tanya({"siapa": "kucing", "nama": "Neo", "teks": JAWAB_NEO.pick_random()}, opsi)
	var akrab_penuh: = gs.tingkat_akrab(gs.TIPE_NEO) >= gs.TINGKAT_KELUARGA
	if pilih == 1:
		var alasan: = gs.kasih_makan_neo()
		if alasan != "":
			dialog.tampilkan([{"siapa": "bapak", "teks": alasan}])
		else:
			dialog.tampilkan([{"siapa": "bapak", "teks": "Ini, Neo, makan dulu. Bapak ambilkan dari warung."}, 
				{"siapa": "kucing", "nama": "Neo", "teks": "Meong! (makan dengan lahap, lalu menjilat-jilat kumisnya)"}, 
				{"siapa": "", "teks": "Neo makin akrab dengan Pak Misran. (1 makanan kucing dari stok warung terpakai)"}])
		await dialog.selesai
	elif pilih == 0:
		gs.tambah_akrab(gs.TIPE_NEO, gs.AKRAB_SAPA)

		if akrab_penuh:
			var o: Array = OBROLAN_NEO_AKRAB[_obrolan_neo_akrab % OBROLAN_NEO_AKRAB.size()]
			_obrolan_neo_akrab += 1
			dialog.tampilkan([{"siapa": "bapak", "teks": o[0]}, {"siapa": "kucing", "nama": "Neo", "teks": o[1]}])
		else:
			dialog.tampilkan([{"siapa": "bapak", "teks": SAPAAN_NEO[nomor]}, 
				{"siapa": "kucing", "nama": "Neo", "teks": JAWAB_NEO.pick_random()}])
		await dialog.selesai
	sibuk = false
	if is_instance_valid(w):
		w.remove_meta("ngobrol")
		_diam_neo = randf_range(2.0, 5.0)





const AWAL_BAWA: = "bawa:"
var _digendong: = ""
var _sudah_diserahkan: = ""
var _jeda_meong_gendong: = 3.0
var _pesan_jalan_pelan: = false

func _tokoh_digendong() -> String:
	for id in GameState.cerita_warga:
		if id == _sudah_diserahkan or GameState.hasil_event(id) != "" or not GameState.data_event().has(id):
			continue
		var semua: Array = GameState.data_event()[id]["tahap"]
		var i: = GameState.tahap_event(id)
		if i < semua.size() and (semua[i] as Dictionary).has("gendong"):
			return String(semua[i]["gendong"])

		if i < semua.size() and (semua[i] as Dictionary).has("bawa"):
			return AWAL_BAWA + String(semua[i]["bawa"])
	return ""


func _perbarui_gendong(delta: float) -> void :
	if bapak == null or bapak.karakter == null:
		return
	var mau: = _tokoh_digendong()
	if mau != _digendong:
		if _digendong != "":
			bapak.karakter.lepas_barang()
		_digendong = mau
		_jeda_meong_gendong = randf_range(1.5, 3.0)
		if mau.begins_with(AWAL_BAWA):
			bapak.karakter.bawa_barang(mau.trim_prefix(AWAL_BAWA))
		elif mau != "":
			var cfg: Dictionary = (data_pelanggan[mau] if data_pelanggan.has(mau) else data_tokoh[mau])["model3d"]
			bapak.karakter.bawa_barang("res://assets/karakter3d/" + String(cfg["file"]), 0.5, true)
	if _digendong == "kucing":
		_jeda_meong_gendong -= delta
		if _jeda_meong_gendong <= 0.0:
			_jeda_meong_gendong = randf_range(7.0, 13.0)
			_meong("kucing")


func _serahkan_gendongan(id: String) -> void :
	_sudah_diserahkan = id
	if _digendong != "" and bapak != null and bapak.karakter != null:
		bapak.karakter.lepas_barang()
	_digendong = ""



func _meong(siapa: String) -> void :
	if siapa != "kucing":
		return
	if _pemutar_neo == null:
		_pemutar_neo = AudioStreamPlayer.new()
		_pemutar_neo.bus = "Suara"
		add_child(_pemutar_neo)
	var daftar: Array = []
	for n in range(1, 10):
		var f: = "res://assets/suara/neo_meong_%d.ogg" % n
		if ResourceLoader.exists(f):
			daftar.append(f)
	if daftar.is_empty():
		return
	_pemutar_neo.stream = load(String(daftar.pick_random()))
	_pemutar_neo.pitch_scale = randf_range(0.95, 1.08)
	_pemutar_neo.play()



func _buka_papan_besar() -> void :
	sibuk = true
	var d: = preload("res://scripts/papan_besar.gd").new()
	(dialog.get_parent() as Control).add_child(d)
	await d.ditutup
	sibuk = false




func _gaya_tombol_kuning(b: Button, kiri: int) -> void :
	b.focus_mode = Control.FOCUS_NONE
	var kuning: = Color(1.0, 0.8, 0.2)
	for k in [["normal", kuning, 4], ["hover", kuning.lightened(0.08), 4], ["pressed", kuning.darkened(0.1), 2]]:
		var sb: = StyleBoxFlat.new()
		sb.bg_color = k[1]
		sb.set_corner_radius_all(16)
		sb.border_color = kuning.darkened(0.4)
		sb.border_width_bottom = k[2]
		sb.content_margin_left = kiri
		sb.content_margin_right = 16
		sb.content_margin_top = 6
		sb.content_margin_bottom = 6 + k[2]
		b.add_theme_stylebox_override(k[0], sb)
	b.add_theme_stylebox_override("hover_pressed", b.get_theme_stylebox("pressed"))
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	for k in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color", "font_focus_color"]:
		b.add_theme_color_override(k, Color(0.08, 0.06, 0.04))
	b.add_theme_constant_override("outline_size", 0)
	b.add_theme_font_override("font", GH.font("Nunito", 900))
	b.add_theme_font_size_override("font_size", 22)
