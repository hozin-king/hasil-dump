extends "res://scripts/minigame/mg_dasar.gd"















const OBJEK3D: = preload("res://scripts/objek3d.gd")
const FILE_MOTOR: = "res://assets/kendaraan/motor_misran.glb"
const FILE_MOTOR_CADANGAN: = "res://assets/kendaraan/motor.glb"
const Y_TROTOAR: = 150.0
const Y_JALAN_ATAS: = 176.0
const Y_JALAN_BAWAH: = 418.0
const Y_MIN: = 214.0
const Y_MAKS: = 404.0
const X_MOTOR: = 230.0
const KEC_NAIK_TURUN: = 430.0
const SCRIPT_JOYSTICK: = preload("res://scripts/joystick.gd")
const PPM_KENDARAAN: = 80.0



const LAJUR_KENDARAAN: = [Y_MIN + 14.0, Y_MAKS - 6.0]
const JARAK_ANTAR_KENDARAAN: = 90.0

const SUARA_MESIN: = "res://assets/suara/motor_lewat.ogg"
const SUARA_LEWAT: = {"motor": ["res://assets/suara/motor_lewat.ogg", 2.7], "mobil": ["res://assets/suara/mobil_lewat.ogg", 3.75]}

const UCAP_BAGUS: = ["Mantap, Pak! Cepat dan nyaman. Besok saya pesan lagi!", "Enak bawa motornya, Pak. Makasih!", 
	"Halus banget, Pak, sampai ngantuk saya.", "Pak Misran memang ojek paling jago sekampung!", "Tepat waktu, Pak. Langganan saya sekarang!"]
const UCAP_JELEK: = ["Lain kali bawa motornya yang bener, Pak!", "Aduh, pinggang saya encok semua, Pak...", 
	"Hampir jantungan saya, Pak. Pelan-pelan dong.", "Kapok saya, Pak. Nyetirnya ugal-ugalan.", "Semua lubang dihajar, Pak. Bintang satu ya."]
const UCAP_BARANG_BAGUS: = ["Barangnya utuh, makasih, Pak!", "Mantap, Pak! Utuh dan cepat. Nanti saya titip lagi!", 
	"Rapi banget bawanya, Pak. Makasih!", "Cepat sampai, masih bagus semua. Makasih, Pak!", "Pak Misran memang bisa dipercaya!"]
const UCAP_BARANG_JELEK: = ["Barangnya penyok, Pak. Lain kali hati-hati ya.", "Waduh, isinya berantakan semua, Pak...", 
	"Hampir pecah, Pak! Bawanya yang bener dong.", "Bungkusnya basah dan sobek, Pak.", "Lain kali saya titip ke orang lain aja deh, Pak."]

const KENDARAAN: = {
	"mobil": ["res://assets/kendaraan/mobil.glb", 4.2, 0.41], 
	"motor": ["res://assets/kendaraan/motor.glb", 1.9, 0.754], 
	"angkot": ["res://assets/kendaraan/angkot.glb", 4.3, 0.49], 
	"bak": ["res://assets/kendaraan/mobil_bak.glb", 4.0, 0.49], 
}
const KECEPATAN: = 470.0
const TEMPUH: = [17.0, 21.0, 25.0]
const CELAH_POLISI: = 104.0

var order: = {}
var _pos: = Vector2(X_MOTOR, 285.0)
var _joy: Control
var _mesin: AudioStreamPlayer
var _motor: Sprite2D
var _skala_motor: = 1.0
var _jarak: = 0.0
var _jarak_tujuan: = 1.0
var _geser: = 0.0
var _nyaman: = 100.0
var _benda: = []
var _jeda_benda: = 1.0
var _lambat: = 0.0
var _lonjak: = 0.0
var _komentar: = ""
var _umur_komentar: = 0.0
var _malam: = false
var _hujan: = false
var _rintik: = []
var _barang: = false
var _sifat: = "santai"
var _bintik: = []


func _siapkan() -> void :
	_malam = GameState.menit >= 18.5 * 60
	_hujan = GameState.sedang_hujan()
	_barang = String(order.get("jenis", "orang")) == "barang"
	_sifat = String(order.get("sifat", "santai"))
	if _barang:
		judul = "Antar %s ke %s" % [String(order.get("barang", "barang")).to_lower(), String(order.get("nama", "warga"))]
		petunjuk = "Geser joystick ke atas / bawah untuk pindah posisi. Hindari mobil, motor, dan lubang. Lewati polisi tidur di celahnya supaya barangnya aman!"
	else:
		judul = "Ngojol: antar %s" % String(order.get("nama", "penumpang"))
		petunjuk = "Geser joystick ke atas / bawah untuk pindah posisi. Hindari mobil, motor, dan lubang. Lewati polisi tidur di celahnya supaya penumpang nyaman sampai %s!" % String(order.get("tujuan", "tujuan"))
	if _sifat == "buru":
		petunjuk += " Penumpang buru-buru: waktunya lebih sedikit!"
	npc = String(order.get("npc", "ojek"))
	latar = "res://assets/peta/area_rumah_malam.png" if _malam else "res://assets/peta/area_rumah.png"
	target = 100.0
	var tempuh: float = TEMPUH[clampi(int(order.get("jarak", 1)), 0, 2)]
	_jarak_tujuan = tempuh * KECEPATAN
	durasi = tempuh + (4.0 if _sifat == "buru" else 9.0)
	contoh = {"jenis": "geser", "dari": Vector2(150, 380), "ke": Vector2(150, 260), "teks": "Geser joystick ke atas / bawah"}
	cahaya_25d = {"dari": Vector2(860, -70), "warna": Color(1.0, 0.82, 0.5) if _malam else Color(1, 0.95, 0.8), "kuat": 0.5}
	if _hujan:
		for i in 80:
			_rintik.append(Vector2(randf() * UKURAN.x, randf() * UKURAN.y))
	var acak: = RandomNumberGenerator.new()
	acak.seed = 11
	for i in 90:
		_bintik.append(Vector3(acak.randf() * UKURAN.x, acak.randf_range(Y_JALAN_ATAS + 6, Y_JALAN_BAWAH - 4), acak.randf()))




const FILE_KARDUS: = "res://assets/upgrade/kardus_bawa.glb"
const UKURAN_KARDUS: = 0.42
const KARDUS_X: = 0.3
const KARDUS_Y: = 0.7






const RODA: = {
	"motor_misran": {"roda": [[117.5, 247.0, 27.0], [274.0, 249.0, 26.0]], "kecuali": [[96.0, 235.0, 174.0, 263.0], [257.0, 221.0, 272.0, 250.0]]}, 
	"motor": {"roda": [[120.0, 245.0, 30.0], [272.0, 247.5, 31.0]], "kecuali": [[90.0, 237.0, 152.0, 257.0], [254.0, 209.0, 275.0, 248.0], [274.0, 235.0, 303.0, 263.0]]}, 
	"mobil": {"roda": [[125.6, 226.0, 17.8], [265.6, 226.0, 17.8]], "kecuali": []}, 
	"angkot": {"roda": [[131.5, 237.0, 17.0], [257.0, 237.0, 17.0]], "kecuali": []}, 
	"bak": {"roda": [[131.5, 235.0, 18.0], [258.0, 235.0, 18.0]], "kecuali": []}, 
}



const PILIH_WARNA: = {
	"mobil": [[0.02, 0.14, 0.0, 0.42], [0.38, 1.0], 0.72], 
	"bak": [[0.04, 0.14, 0.28, 0.65], [0.08, 0.4], 0.22], 
	"angkot": [[0.0, 1.0, 0.35, 1.0], [0.0, 1.0], 0.8], 
	"motor": [[0.96, 0.03, 0.6, 1.0], [0.25, 1.0], 0.8], 
}

const VARIAN_KENDARAAN: = {
	"mobil": [{}, {"cat": Color(0.62, 0.08, 0.08)}, {"cat": Color(0.12, 0.25, 0.6)}, {"cat": Color(0.2, 0.2, 0.22)}, 
		{"cat": Color(0.95, 0.95, 0.93), "kuat": 0.7}, {"cat": Color(0.1, 0.38, 0.22)}, {"cat": Color(0.85, 0.62, 0.15)}], 

	"angkot": [{}, {"hue": 0.27}, {"hue": -0.12}], 
	"motor": [{}], 
	"bak": [{}, {"cat": Color(0.15, 0.3, 0.7)}, {"cat": Color(0.6, 0.1, 0.1)}], 
}

func _pasang_varian(sp: Sprite2D, model: String, varian: Dictionary) -> void :
	if not (sp.material is ShaderMaterial) or varian.is_empty() or not PILIH_WARNA.has(model):
		return
	var m: = sp.material as ShaderMaterial
	var p: Array = PILIH_WARNA[model]
	m.set_shader_parameter("pilih", Vector4(p[0][0], p[0][1], p[0][2], p[0][3]))
	m.set_shader_parameter("nilai", Vector2(p[1][0], p[1][1]))
	m.set_shader_parameter("acuan", float(p[2]))
	if varian.has("cat"):
		var c: Color = varian["cat"]
		m.set_shader_parameter("cat", Vector4(c.r, c.g, c.b, float(varian.get("kuat", 0.92))))
	m.set_shader_parameter("geser_hue", float(varian.get("hue", 0.0)))

const RODA_VELG: = 0.74
const SHADER_RODA: = "\r\nshader_type canvas_item;\r\nuniform vec3 roda0;   // pusat u, v, jari-jari (UV)\r\nuniform vec3 roda1;\r\nuniform vec4 kecuali0 = vec4(-1.0);\r\nuniform vec4 kecuali1 = vec4(-1.0);\r\nuniform vec4 kecuali2 = vec4(-1.0);\r\nvarying vec4 warna_titik;\r\n// 16 Nov: variasi warna kendaraan (tanpa aset baru). Hanya di luar lingkaran ban, jadi roda/velg tidak ikut.\r\n// Bagian yang diubah dipilih per jenis kendaraan lewat rentang warna (pilih = hue min, hue max, saturasi min, max;\r\n// nilai = terang min, max), karena cahaya dunia 3D kekuningan (silver terbaca krem). Lalu: cat.a > 0 = dicat warna\r\n// cat.rgb (terang-gelap tetap dari gambar, dibagi acuan); geser_hue = warnanya digeser.\r\nuniform vec4 cat = vec4(0.0);\r\nuniform vec4 pilih = vec4(0.0, 1.0, 0.35, 1.0);\r\nuniform vec2 nilai = vec2(0.0, 1.0);\r\nuniform float acuan = 0.8;\r\nuniform float geser_hue = 0.0;\r\n\r\nbool terpilih(vec3 hsv) {\r\n\tbool hue_ok = pilih.x <= pilih.y ? (hsv.x >= pilih.x && hsv.x <= pilih.y) : (hsv.x >= pilih.x || hsv.x <= pilih.y);\r\n\treturn hue_ok && hsv.y >= pilih.z && hsv.y <= pilih.w && hsv.z >= nilai.x && hsv.z <= nilai.y;\r\n}\r\n\r\nvec3 ke_hsv(vec3 c) {\r\n\tvec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);\r\n\tvec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));\r\n\tvec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));\r\n\tfloat d = q.x - min(q.w, q.y);\r\n\treturn vec3(abs(q.z + (q.w - q.y) / (6.0 * d + 1e-10)), d / (q.x + 1e-10), q.x);\r\n}\r\n\r\nvec3 dari_hsv(vec3 c) {\r\n\tvec3 p = abs(fract(c.xxx + vec3(1.0, 2.0 / 3.0, 1.0 / 3.0)) * 6.0 - 3.0);\r\n\treturn c.z * mix(vec3(1.0), clamp(p - 1.0, 0.0, 1.0), c.y);\r\n}\r\n\r\nbool di_ban(vec2 uv, vec3 r) {\r\n\treturn length(uv - r.xy) < r.z / 0.74 * 1.05;\r\n}\r\nuniform float sudut = 0.0;\r\nuniform float kabur = 0.6;\r\n\r\nbool di_kecuali(vec2 p) {\r\n\treturn (p.x > kecuali0.x && p.x < kecuali0.z && p.y > kecuali0.y && p.y < kecuali0.w)\r\n\t\t|| (p.x > kecuali1.x && p.x < kecuali1.z && p.y > kecuali1.y && p.y < kecuali1.w)\r\n\t\t|| (p.x > kecuali2.x && p.x < kecuali2.z && p.y > kecuali2.y && p.y < kecuali2.w);\r\n}\r\n\r\nvec2 putar(vec2 d, float a) {\r\n\treturn vec2(d.x * cos(a) - d.y * sin(a), d.x * sin(a) + d.y * cos(a));\r\n}\r\n\r\nvec4 roda(sampler2D tex, vec4 asli, vec2 uv, vec3 r) {\r\n\tvec2 d = uv - r.xy;\r\n\tfloat jarak = length(d) / r.z;\r\n\tif (jarak >= 1.0 || di_kecuali(uv)) {\r\n\t\treturn asli;\r\n\t}\r\n\t// Kabur gerak: rata-rata 12 titik sekeliling (titik yang jatuh di bagian kecuali dilewati). Warna dirata-rata\r\n\t// menurut alpha (velg jari-jari motor tembus pandang: tanpa ini latar ikut tercampur jadi bayangan abu-abu).\r\n\tvec3 warna = vec3(0.0);\r\n\tfloat alpha = 0.0;\r\n\tfloat n = 0.0;\r\n\tfor (int i = 0; i < 12; i++) {\r\n\t\tvec2 q = r.xy + putar(d, sudut + float(i) * 0.5236);\r\n\t\tif (!di_kecuali(q)) {\r\n\t\t\tvec4 t = texture(tex, q);\r\n\t\t\twarna += t.rgb * t.a;\r\n\t\t\talpha += t.a;\r\n\t\t\tn += 1.0;\r\n\t\t}\r\n\t}\r\n\tvec4 rata = (n > 0.0 && alpha > 0.001) ? vec4(warna / alpha, alpha / n) : asli;\r\n\tvec2 qp = r.xy + putar(d, sudut);\r\n\tvec4 diputar = di_kecuali(qp) ? asli : texture(tex, qp);\r\n\tvec4 hasil = mix(diputar, rata, kabur);\r\n\t// Tepi lembut ke ban (tidak ada garis potong).\r\n\treturn mix(hasil, asli, smoothstep(0.8, 1.0, jarak));\r\n}\r\n\r\n// Warna titik (modulate) disimpan dari vertex: COLOR di fragment sudah dikali tekstur, jadi tidak boleh dikali lagi.\r\nvoid vertex() {\r\n\twarna_titik = COLOR;\r\n}\r\n\r\nvoid fragment() {\r\n\tvec4 c = texture(TEXTURE, UV);\r\n\tc = roda(TEXTURE, c, UV, roda0);\r\n\tc = roda(TEXTURE, c, UV, roda1);\r\n\tif ((cat.a > 0.0 || geser_hue != 0.0) && !di_ban(UV, roda0) && !di_ban(UV, roda1)) {\r\n\t\tvec3 hsv = ke_hsv(c.rgb);\r\n\t\tif (terpilih(hsv)) {\r\n\t\t\tif (cat.a > 0.0) {\r\n\t\t\t\tc.rgb = mix(c.rgb, clamp(cat.rgb * (hsv.z / acuan), 0.0, 1.0), cat.a);\r\n\t\t\t} else {\r\n\t\t\t\tc.rgb = dari_hsv(vec3(fract(hsv.x + geser_hue), hsv.y, hsv.z));\r\n\t\t\t}\r\n\t\t}\r\n\t}\r\n\tCOLOR = c * warna_titik;\r\n}\r\n"







































































































func _pasang_roda(sp: Sprite2D, nama: String, menghadap_kanan: bool) -> void :
	if not RODA.has(nama) or sp.texture == null:
		return
	var d: Dictionary = RODA[nama]
	var vp: = 384.0
	var bahan: = ShaderMaterial.new()
	bahan.shader = _shader_roda()
	for i in 2:
		var r: Array = d["roda"][i]
		var u: = float(r[0]) / vp
		bahan.set_shader_parameter("roda%d" % i, Vector3(u if menghadap_kanan else 1.0 - u, float(r[1]) / vp, float(r[2]) * RODA_VELG / vp))
	var k: Array = d["kecuali"]
	for i in k.size():
		var a: Array = k[i]
		var x0: = float(a[0]) / vp
		var x1: = float(a[2]) / vp
		if not menghadap_kanan:
			var t: = x0
			x0 = 1.0 - x1
			x1 = 1.0 - t
		bahan.set_shader_parameter("kecuali%d" % i, Vector4(x0, float(a[1]) / vp, x1, float(a[3]) / vp))
	sp.material = bahan
	sp.set_meta("roda_jari", float(d["roda"][0][2]) * absf(sp.scale.x))
	sp.set_meta("roda_arah", 1.0 if menghadap_kanan else -1.0)


var _shader_roda_cache: Shader = null

func _shader_roda() -> Shader:
	if _shader_roda_cache == null:
		_shader_roda_cache = Shader.new()
		_shader_roda_cache.code = SHADER_RODA
	return _shader_roda_cache



func _putar_roda(sp: Sprite2D, v: float, delta: float) -> void :
	if sp == null or not is_instance_valid(sp) or not (sp.material is ShaderMaterial) or not sp.has_meta("roda_jari"):
		return
	var a: = float(sp.get_meta("roda_sudut", 0.0)) + float(sp.get_meta("roda_arah")) * v * delta / maxf(float(sp.get_meta("roda_jari")), 1.0)
	a = fmod(a, TAU)
	sp.set_meta("roda_sudut", a)
	(sp.material as ShaderMaterial).set_shader_parameter("sudut", a)





const FILE_POSE_DUDUK: = "res://assets/karakter3d/meshy_bapak.glb"
const ANIM_POSE_DUDUK: = "Chair_Sit_Idle_M"
const PENUMPANG_X: = 0.13
const PENUMPANG_Y: = 0.36

const PENUMPANG_MENYAMPING: = ["ibu_rumah_tangga", "nenek", "giska", "siswi", "bu_ida", "ibu", "kantoran_cewek"]
const PENUMPANG_TINGGI: = 1.62

static var _data_warga3d: = {}

func _cfg_warga3d(tipe: String) -> Dictionary:
	if _data_warga3d.is_empty():
		var dp = JSON.parse_string(FileAccess.get_file_as_string("res://data/pelanggan.json"))
		if typeof(dp) == TYPE_DICTIONARY:
			for p in dp.get("pelanggan", []):
				if p.has("model3d"):
					_data_warga3d[String(p["id"])] = p["model3d"]
			for k in dp.get("tokoh", {}):
				var t = dp["tokoh"][k]
				if typeof(t) == TYPE_DICTIONARY and t.has("model3d"):
					_data_warga3d[String(k)] = t["model3d"]
	return _data_warga3d.get(tipe, {})


func _pasang_penumpang() -> void :
	var vp: SubViewport = _motor.get("_viewport")
	var motor3d: Node3D = _motor.get("_model")
	var cfg: = _cfg_warga3d(String(order.get("npc", "")))
	if vp == null or motor3d == null or cfg.is_empty() or not cfg.has("file"):
		return
	var file: = "res://assets/karakter3d/" + String(cfg["file"])
	if not ResourceLoader.exists(file) or not ResourceLoader.exists(FILE_POSE_DUDUK):
		return
	var orang: Node3D = GameState.muat_model(file)
	var ap: AnimationPlayer = orang.find_child("AnimationPlayer", true, false)
	var sumber: Node = GameState.muat_model(FILE_POSE_DUDUK)
	var ap_sumber: AnimationPlayer = sumber.find_child("AnimationPlayer", true, false)
	if ap == null or ap_sumber == null or not ap_sumber.has_animation(ANIM_POSE_DUDUK):
		orang.free()
		sumber.free()
		return
	var anim: Animation = ap_sumber.get_animation(ANIM_POSE_DUDUK).duplicate()
	sumber.free()


	var kerangka: Skeleton3D = orang.find_child("Skeleton3D", true, false)
	if kerangka != null:
		var jalur_kerangka: = String(ap.get_node(ap.root_node).get_path_to(kerangka))
		for t in anim.get_track_count():
			var jalur: NodePath = anim.track_get_path(t)
			anim.track_set_path(t, NodePath("%s:%s" % [jalur_kerangka, String(jalur.get_concatenated_subnames())]))
	var pustaka: = AnimationLibrary.new()
	pustaka.add_animation("duduk_motor", anim)
	ap.add_animation_library("ojol", pustaka)

	var kotak: AABB = _motor._ukur(orang, Transform3D.IDENTITY)
	var s: = PENUMPANG_TINGGI * float(cfg.get("skala", 1.0)) / maxf(kotak.size.y, 0.001)
	orang.scale = Vector3.ONE * s


	var menyamping: = String(order.get("npc", "")) in PENUMPANG_MENYAMPING
	orang.rotation.y = deg_to_rad(25.0 if menyamping else 90.0)
	var panjang: float = _motor._ukur(motor3d, Transform3D.IDENTITY).size.x * absf(motor3d.scale.x)

	orang.position = Vector3( - panjang * (0.36 if menyamping else PENUMPANG_X), PENUMPANG_Y - kotak.position.y * s, 0.22 if menyamping else 0.0)
	vp.add_child(orang)
	ap.play("ojol/duduk_motor")
	ap.seek(0.0, true)
	ap.pause()
	if kerangka != null:
		if menyamping:
			_atur_kaki(kerangka, PAHA_RAPAT_MENYAMPING, PAHA_TURUN_MENYAMPING)
		else:
			_atur_kaki(kerangka, PAHA_BUKA, PAHA_TURUN)




const PAHA_TURUN: = 30.0
const PAHA_BUKA: = 40.0
const PAHA_TURUN_MENYAMPING: = 8.0
const PAHA_RAPAT_MENYAMPING: = -14.0

func _putar_tulang(kerangka: Skeleton3D, tulang: int, putar: Quaternion) -> void :
	var induk: = kerangka.get_bone_parent(tulang)
	var global_lama: = kerangka.get_bone_global_pose(tulang).basis.get_rotation_quaternion()
	var global_induk: = kerangka.get_bone_global_pose(induk).basis.get_rotation_quaternion()
	kerangka.set_bone_pose_rotation(tulang, global_induk.inverse() * putar * global_lama)


func _atur_kaki(kerangka: Skeleton3D, buka: float, turun: float) -> void :
	for sisi in [["Left", 1.0], ["Right", -1.0]]:
		var paha: = kerangka.find_bone("mixamorig_%sUpLeg" % String(sisi[0]))
		var betis: = kerangka.find_bone("mixamorig_%sLeg" % String(sisi[0]))
		if paha < 0 or betis < 0:
			continue
		_putar_tulang(kerangka, paha, Quaternion(Vector3.UP, deg_to_rad(buka) * float(sisi[1])) * Quaternion(Vector3.RIGHT, deg_to_rad(turun)))
		_putar_tulang(kerangka, betis, Quaternion(Vector3.RIGHT, deg_to_rad( - turun)))


func _pasang_kardus() -> void :
	var vp: SubViewport = _motor.get("_viewport")
	var model: Node3D = _motor.get("_model")
	if vp == null or model == null or not ResourceLoader.exists(FILE_KARDUS):
		return
	var adegan = load(FILE_KARDUS)
	if not adegan is PackedScene:
		return
	var kardus: Node3D = (adegan as PackedScene).instantiate()
	var kotak: AABB = _motor._ukur(kardus, Transform3D.IDENTITY)
	var s: = UKURAN_KARDUS / maxf(maxf(kotak.size.x, kotak.size.y), maxf(kotak.size.z, 0.001))
	kardus.scale = Vector3.ONE * s
	var panjang: float = _motor._ukur(model, Transform3D.IDENTITY).size.x * absf(model.scale.x)
	var tengah: = kotak.get_center() * s
	kardus.position = Vector3( - panjang * KARDUS_X - tengah.x, KARDUS_Y - kotak.position.y * s, - tengah.z)
	vp.add_child(kardus)


func _ready() -> void :
	super._ready()
	_motor = Sprite2D.new()
	_motor.set_script(OBJEK3D)
	_motor.position = _pos
	kanvas.add_child(_motor)
	var file: = FILE_MOTOR if ResourceLoader.exists(FILE_MOTOR) else FILE_MOTOR_CADANGAN

	_motor.pasang(file, 1.43, 98.0, {"hadap": 180.0, "sudut_kamera": 8.0, "gerak": "getar", "resolusi": 384})
	_skala_motor = _motor.scale.x
	_pasang_roda(_motor, "motor_misran" if file == FILE_MOTOR else "motor", true)
	if _barang:
		_pasang_kardus()
	else:
		_pasang_penumpang()

	_joy = Control.new()
	_joy.set_script(SCRIPT_JOYSTICK)
	add_child(_joy)

	if ResourceLoader.exists(SUARA_MESIN):
		var st = load(SUARA_MESIN).duplicate()
		if st is AudioStreamOggVorbis:
			st.loop = true
		_mesin = AudioStreamPlayer.new()
		_mesin.stream = st
		_mesin.bus = "Suara"
		_mesin.volume_db = -13.0
		add_child(_mesin)



func _akhiri() -> void :
	if is_instance_valid(_joy):
		_joy.queue_free()
	if is_instance_valid(_mesin):
		_mesin.stop()
	for b in _benda:
		if b.has("sprite") and is_instance_valid(b["sprite"]):
			b["sprite"].queue_free()
	super._akhiri()



func _boleh_bonus_ganda() -> bool:
	return false


func _perbarui_skor() -> void :
	if _label_skor != null:
		_label_skor.text = "%d%%" % int(round(_nyaman))


func _kemajuan() -> float:
	return clampf(_jarak / _jarak_tujuan, 0.0, 1.0)


func _laju() -> float:
	var v: = KECEPATAN * (1.0 + 0.3 * _kemajuan()) * (1.15 if _sifat == "buru" else 1.0)
	return v * (0.45 if _lambat > 0.0 else 1.0)



func _dalam(y: float) -> float:
	return inverse_lerp(Y_JALAN_ATAS, Y_JALAN_BAWAH, y)


func _main(delta: float) -> void :
	var laju: = _laju()
	_putar_roda(_motor, laju, delta)
	if is_instance_valid(_mesin):
		if not _mesin.playing:
			_mesin.play()
		_mesin.pitch_scale = lerpf(_mesin.pitch_scale, 0.85 + 0.35 * (laju / (KECEPATAN * 1.3)), minf(delta * 4.0, 1.0))
	_jarak += laju * delta
	_geser += laju * delta
	_lambat = maxf(_lambat - delta, 0.0)

	var ay: float = (_joy.baca().y if is_instance_valid(_joy) and _joy.has_method("baca") else 0.0)
	_pos.y = clampf(_pos.y + ay * KEC_NAIK_TURUN * delta, Y_MIN, Y_MAKS)
	_pos.x = X_MOTOR
	var vy: = ay * KEC_NAIK_TURUN
	_lonjak = maxf(_lonjak - delta * 3.0, 0.0)
	if _motor != null:
		var naik: = sin(_lonjak * PI) * 24.0 if _lonjak > 0.0 else 0.0
		_motor.set("_dasar", Vector2(_pos.x, _pos.y - naik))
		_motor.rotation = lerp_angle(_motor.rotation, clampf(vy * 0.0009, -0.2, 0.2), minf(delta * 10.0, 1.0))
		_motor.scale.x = _skala_motor * lerpf(0.84, 1.04, _dalam(_pos.y))
		_motor.scale.y = _motor.scale.x
		_motor.z_index = int(_pos.y / 10.0)
	_umur_komentar = maxf(_umur_komentar - delta, 0.0)

	_jeda_benda -= delta
	if _jeda_benda <= 0.0 and _jarak < _jarak_tujuan - KECEPATAN * 1.6:


		var rapat: = lerpf(1.0, 0.8, _kemajuan()) * (0.88 if _sifat == "buru" else 1.0)
		_jeda_benda = randf_range(0.72, 1.08) * rapat
		_munculkan_benda()
	for b in _benda:
		b["x"] -= (laju + float(b.get("vx", 0.0))) * delta
		if b.has("vy"):
			b["y"] += float(b["vy"]) * delta
			if b["y"] < Y_MIN - 10.0 or b["y"] > Y_MAKS + 8.0:
				b["vy"] = - float(b["vy"])
		b["t"] = float(b.get("t", 0.0)) + delta
		if b["jenis"] == "kendaraan" and not b.has("bunyi"):
			_bunyi_lewat(b, laju)
		if b.has("sprite") and is_instance_valid(b["sprite"]):
			b["sprite"].set("_dasar", Vector2(float(b["x"]), float(b["y"])))
			_putar_roda(b["sprite"], absf(float(b.get("vx", 0.0))), delta)
			b["sprite"].z_index = int(float(b["y"]) / 10.0)
		if not b["kena"] and _kena(b):
			b["kena"] = true
			_tabrak(b)
	for b in _benda:
		if float(b["x"]) <= -320.0 and b.has("sprite") and is_instance_valid(b["sprite"]):
			b["sprite"].queue_free()
	_benda = _benda.filter( func(b): return float(b["x"]) > -320.0)
	skor = clampf(0.4 * _kemajuan() * 100.0 + 0.6 * _nyaman, 0.0, 100.0)
	_perbarui_skor()
	if _jarak >= _jarak_tujuan:
		_jarak = _jarak_tujuan
		kilat(_pos + Vector2(120, -140), "Sampai!", GH.HIJAU_UANG)
		sisa = 0.0



const UKURAN_BENDA: = {"lubang": Vector2(36, 13), "genangan": Vector2(50, 16), "batu": Vector2(20, 10), "ayam": Vector2(24, 13), 
	"kucing": Vector2(22, 11), "bola": Vector2(16, 10), "koin": Vector2(26, 22)}


func _kena(b: Dictionary) -> bool:
	var dx: = absf(float(b["x"]) - _pos.x)
	if b["jenis"] == "polisi":
		if dx > 18.0:
			return false
		return absf(_pos.y - float(b["celah"])) > CELAH_POLISI * 0.5
	var u: Vector2 = UKURAN_BENDA.get(String(b["jenis"]), Vector2(30, 12)) * lerpf(0.8, 1.05, _dalam(float(b["y"])))
	if b["jenis"] == "kendaraan":
		u = Vector2(float(KENDARAAN[b["model"]][1]) * PPM_KENDARAAN * 0.42, 18.0)
	var dy: = absf(float(b["y"]) - _pos.y)

	return pow(dx / (u.x + 48.0), 2) + pow(dy / (u.y + 14.0), 2) < 1.0


func _munculkan_benda() -> void :
	var r: = randf()
	var y: = randf_range(Y_MIN, Y_MAKS)
	var b: = {"x": UKURAN.x + 90.0, "y": y, "kena": false}



	if r < 0.22:
		b["jenis"] = "polisi"
		var bawah: = Y_MIN + CELAH_POLISI * 0.35
		var atas: = Y_MAKS - CELAH_POLISI * 0.35
		var celah: = randf_range(bawah, atas)
		if randf() < 0.7:
			for coba in 6:
				if absf(celah - _pos.y) >= CELAH_POLISI * 0.75:
					break
				celah = randf_range(bawah, atas)
		b["celah"] = celah
	elif r < 0.34:
		b["jenis"] = "koin"
	elif r < 0.62:
		b["jenis"] = "lubang"
		var tengah: = (Y_MIN + Y_MAKS) * 0.5
		if randf() < 0.55:
			b["y"] = clampf(_pos.y + randf_range(-22.0, 22.0), Y_MIN, Y_MAKS)
		elif randf() < 0.6:
			b["y"] = tengah + randf_range(-45.0, 45.0)
	else:
		_kendaraan_3d(b)
	_benda.append(b)


	if b["jenis"] in ["lubang", "kendaraan"] and randf() < 0.5:
		var b2: = {"x": float(b["x"]) + randf_range(-30.0, 60.0), "kena": false, "jenis": "lubang"}
		var arah: = 1.0 if float(b["y"]) < (Y_MIN + Y_MAKS) * 0.5 else -1.0
		b2["y"] = clampf(float(b["y"]) + arah * randf_range(150.0, 185.0), Y_MIN, Y_MAKS)
		_benda.append(b2)

	if b["jenis"] in ["polisi", "kendaraan"]:
		_jeda_benda += 0.4



func _kendaraan_3d(b: Dictionary) -> void :

	var model: String = ["mobil", "motor", "motor", "angkot", "bak"].pick_random()
	var dari_depan: = randf() < 0.6
	var d: Array = KENDARAAN[model]
	b["jenis"] = "kendaraan"
	b["model"] = model
	b["vx"] = 240.0 if dari_depan else - KECEPATAN * 0.5


	b["y"] = LAJUR_KENDARAAN[1] if dari_depan else LAJUR_KENDARAAN[0]


	if model == "motor" and dari_depan and randf() < 0.45:
		b["vy"] = randf_range(45.0, 70.0) * (-1.0 if randf() < 0.5 else 1.0)
	var setengah: = float(d[1]) * PPM_KENDARAAN * 0.5
	b["x"] = UKURAN.x + setengah + 40.0

	for lain in _benda:
		if lain["jenis"] == "kendaraan" and float(lain["y"]) == float(b["y"]):
			var ujung: = float(lain["x"]) + float(KENDARAAN[lain["model"]][1]) * PPM_KENDARAAN * 0.5
			b["x"] = maxf(float(b["x"]), ujung + JARAK_ANTAR_KENDARAAN + setengah)
	var sp: = Sprite2D.new()
	sp.set_script(OBJEK3D)
	sp.position = Vector2(float(b["x"]), float(b["y"]))
	kanvas.add_child(sp)
	if sp.pasang(String(d[0]), float(d[1]) * float(d[2]), PPM_KENDARAAN, {"hadap": 0.0 if dari_depan else 180.0, "sudut_kamera": 8.0, "gerak": "getar", "resolusi": 384}):
		b["sprite"] = sp
		_pasang_roda(sp, model, not dari_depan)
		var varian: Dictionary = (VARIAN_KENDARAAN.get(model, [{}]) as Array).pick_random()
		_pasang_varian(sp, model, varian)
		b["varian"] = varian
	else:
		sp.queue_free()



func _bunyi_lewat(b: Dictionary, laju: float) -> void :
	var data: Array = SUARA_LEWAT["motor" if b["model"] == "motor" else "mobil"]
	var v: = laju + float(b.get("vx", 0.0))
	if v <= 1.0 or not ResourceLoader.exists(data[0]):
		b["bunyi"] = true
		return
	var detik: = (float(b["x"]) - X_MOTOR) / v
	if detik > float(data[1]):
		return
	b["bunyi"] = true
	var p: = AudioStreamPlayer.new()
	p.stream = load(data[0])
	p.bus = "Suara"
	p.volume_db = lerpf(-3.0, -14.0, clampf(absf(float(b["y"]) - _pos.y) / 180.0, 0.0, 1.0))
	p.pitch_scale = randf_range(0.95, 1.08)
	add_child(p)
	p.finished.connect(p.queue_free)
	p.play(maxf(float(data[1]) - detik, 0.0))


func _tabrak(b: Dictionary) -> void :
	var p: = _pos + Vector2(0, -90)
	var k: = 1.5 if _sifat == "rapuh" else 1.0
	match String(b["jenis"]):
		"koin":
			_nyaman = minf(_nyaman + 4.0, 100.0)
			kilat(p, "+tip", GH.KUNING)
			percik(p, GH.KUNING, 8, 5.0)
			GameState.klik()
			return
		"polisi":
			_lonjak = 1.0
			_kurangi(12.0 * k, ["Barangnya terguncang!"] if _barang else ["Aduh, pelan-pelan, Pak!"])
		"lubang":
			_lonjak = 0.8
			_kurangi(16.0 * k, ["Barangnya hampir jatuh!"] if _barang else ["Awas lubang, Pak!", "Aduh, pinggangku..."])
		"batu":
			_lonjak = 0.6
			_kurangi(12.0 * k, ["Kena batu!"] if _barang else ["Batu, Pak!", "Hati-hati, Pak!"])
		"ayam":
			_kurangi(12.0, ["Ayamnya!"] if _barang else ["Ayamnya, Pak!", "Hampir saja!"])
			percik(p + Vector2(40, 60), Color(0.95, 0.9, 0.8), 10, 4.0)
		"kucing":
			_kurangi(10.0, ["Kucing lewat!"] if _barang else ["Kucingnya, Pak!", "Astaga, kucing!"])
		"bola":
			_kurangi(8.0, ["Bola anak-anak!"] if _barang else ["Bolanya, Pak!", "Awas anak main bola!"])
		"kendaraan":
			_lonjak = 0.5
			GameState.bunyi("tabrakan", -6.0)
			GameState.bunyi("klakson_motor" if b["model"] == "motor" else "klakson_mobil", -4.0)
			_kurangi(22.0 * k, ["Hampir tabrakan!"] if _barang else ["Astagfirullah, Pak!", "Hampir tabrakan!", "Awas mobil, Pak!"])
		"genangan":
			_kurangi(10.0, ["Barangnya basah!"] if _barang else ["Basah semua, Pak!", "Waduh, kecipratan!"])
			percik(p + Vector2(0, 80), Color(0.6, 0.75, 0.9), 14, 4.0)
	_lambat = 0.55


func _kurangi(n: float, kata: Array) -> void :
	_nyaman = maxf(_nyaman - n, 0.0)
	kilat(_pos + Vector2(0, -90), "-%d%%" % int(round(n)), Color(1, 0.4, 0.35))
	_komentar = String(kata.pick_random())
	_umur_komentar = 1.6
	_guncang = 1.0
	if OS.has_feature("mobile"):
		Input.vibrate_handheld(60)



func _masukan(_e: InputEvent) -> void :
	pass




func _gambar() -> void :
	var waktu: = Time.get_ticks_msec() / 1000.0

	var atas: = Color(0.07, 0.09, 0.2) if _malam else Color(0.98, 0.6, 0.36)
	var bawah: = Color(0.22, 0.2, 0.32) if _malam else Color(1.0, 0.84, 0.58)
	gradasi(Rect2(0, 0, UKURAN.x, Y_TROTOAR), atas, bawah)
	var surya: = Vector2(820, 46)
	for i in 5:
		kanvas.draw_circle(surya, 26.0 + i * 16.0, Color(1, 0.95, 0.8, 0.12 - i * 0.02) if _malam else Color(1, 0.9, 0.6, 0.18 - i * 0.03))
	kanvas.draw_circle(surya, 22, Color(0.95, 0.95, 0.88) if _malam else Color(1, 0.93, 0.7))

	var g_bukit: = fmod(_geser * 0.06, 400.0)
	var bukit: = PackedVector2Array([Vector2(-400, Y_TROTOAR)])
	for i in 10:
		var x: = i * 200.0 - g_bukit - 200.0
		bukit.append(Vector2(x, Y_TROTOAR - 46 - (i % 3) * 14))
		bukit.append(Vector2(x + 100, Y_TROTOAR - 30))
	bukit.append(Vector2(UKURAN.x + 400, Y_TROTOAR))
	kanvas.draw_colored_polygon(bukit, Color(0.16, 0.18, 0.28) if _malam else Color(0.72, 0.6, 0.55))
	_rumah_rumah()

	kanvas.draw_rect(Rect2(0, Y_TROTOAR, UKURAN.x, Y_JALAN_ATAS - Y_TROTOAR - 10), Color(0.5, 0.48, 0.47) if _malam else Color(0.74, 0.7, 0.64))
	kanvas.draw_rect(Rect2(0, Y_JALAN_ATAS - 10, UKURAN.x, 10), Color(0.32, 0.3, 0.3) if _malam else Color(0.55, 0.52, 0.48))
	var g_ubin: = fmod(_geser, 70.0)
	for i in 17:
		var x: = i * 70.0 - g_ubin
		kanvas.draw_line(Vector2(x, Y_TROTOAR), Vector2(x - 8, Y_JALAN_ATAS - 10), Color(0, 0, 0, 0.12), 1)

	var aspal_jauh: = Color(0.3, 0.3, 0.34) if _malam else Color(0.46, 0.45, 0.46)
	var aspal_dekat: = Color(0.14, 0.14, 0.16) if _malam else Color(0.27, 0.26, 0.28)
	if _hujan:
		aspal_jauh = aspal_jauh.darkened(0.15)
		aspal_dekat = aspal_dekat.darkened(0.15)
	gradasi(Rect2(0, Y_JALAN_ATAS, UKURAN.x, Y_JALAN_BAWAH - Y_JALAN_ATAS), aspal_jauh, aspal_dekat)
	for t in _bintik:
		var x: = fposmod(t.x - _geser, UKURAN.x)
		var d: = _dalam(t.y)
		kanvas.draw_circle(Vector2(x, t.y), lerpf(0.8, 2.2, d), Color(1, 1, 1, 0.05 + t.z * 0.06))

	kanvas.draw_rect(Rect2(0, Y_JALAN_ATAS + 6, UKURAN.x, 3), Color(0.92, 0.9, 0.84, 0.6))
	kanvas.draw_rect(Rect2(0, Y_JALAN_BAWAH - 12, UKURAN.x, 4), Color(0.92, 0.9, 0.84, 0.7))
	var g_garis: = fmod(_geser, 130.0)
	var y_marka: = (Y_JALAN_ATAS + Y_JALAN_BAWAH) * 0.5
	for i in 10:
		var x: = i * 130.0 - g_garis
		kanvas.draw_rect(Rect2(x, y_marka - 3, 66, 6), Color(0.95, 0.88, 0.5, 0.75))

	var g_tiang: = fmod(_geser, 380.0)
	if _malam:
		for i in 4:
			var x: = i * 380.0 - g_tiang + 150.0
			_elips(Vector2(x + 40, Y_JALAN_ATAS + 60), Vector2(150, 46), Color(1.0, 0.85, 0.5, 0.13))

	kanvas.draw_rect(Rect2(0, Y_JALAN_BAWAH, UKURAN.x, UKURAN.y - Y_JALAN_BAWAH), Color(0.4, 0.38, 0.37) if _malam else Color(0.6, 0.57, 0.53))
	kanvas.draw_rect(Rect2(0, Y_JALAN_BAWAH, UKURAN.x, 3), Color(1, 1, 1, 0.18))

	var urut: = _benda.duplicate()
	urut.sort_custom( func(a, b): return _y_urut(a) < _y_urut(b))
	for b in urut:
		_gambar_benda(b, waktu)

	bayangan(_pos + Vector2(6, -2), 150.0 * lerpf(0.84, 1.04, _dalam(_pos.y)), 0.32)
	if _malam:
		var l: = _pos + Vector2(70, -30)
		kanvas.draw_colored_polygon(PackedVector2Array([l, l + Vector2(260, -60), l + Vector2(300, 40), l + Vector2(20, 12)]), Color(1.0, 0.95, 0.7, 0.14))

	for i in 4:
		var x: = i * 380.0 - g_tiang + 150.0
		kanvas.draw_line(Vector2(x + 4, Y_JALAN_ATAS - 8), Vector2(x + 30, Y_JALAN_ATAS + 6), Color(0, 0, 0, 0.18), 6)
		kanvas.draw_line(Vector2(x, Y_JALAN_ATAS - 8), Vector2(x, 54), Color(0.22, 0.22, 0.25), 6)
		kanvas.draw_line(Vector2(x - 2, Y_JALAN_ATAS - 8), Vector2(x - 2, 54), Color(0.5, 0.5, 0.55, 0.6), 1)
		kanvas.draw_line(Vector2(x, 56), Vector2(x + 34, 56), Color(0.22, 0.22, 0.25), 5)
		if _malam:
			kanvas.draw_circle(Vector2(x + 34, 62), 8, Color(1.0, 0.92, 0.65))
			kanvas.draw_circle(Vector2(x + 34, 62), 26, Color(1.0, 0.85, 0.5, 0.2))

	var sisa_px: = _jarak_tujuan - _jarak
	if sisa_px < UKURAN.x:
		var x: = _pos.x + sisa_px + 60.0
		for tx in [x, x + 170.0]:
			kanvas.draw_rect(Rect2(tx + 12, 112, 6, Y_JALAN_BAWAH - 112), Color(0.45, 0.1, 0.08))
			kanvas.draw_rect(Rect2(tx, 112, 14, Y_JALAN_BAWAH - 112), Color(0.85, 0.25, 0.2))
		kotak_bulat(Rect2(x - 22, 86, 228, 46), Color(0.98, 0.95, 0.88), 10, 0.3)
		teks(Vector2(x + 92, 108), String(order.get("tujuan", "Tujuan")), 21, Color(0.3, 0.15, 0.1), 220)

	if _hujan:
		for i in _rintik.size():
			var p: Vector2 = _rintik[i]
			p.x = fmod(p.x - _geser * 0.9 + UKURAN.x * 4.0, UKURAN.x)
			p.y = fmod(p.y + Time.get_ticks_msec() * 0.9, UKURAN.y)
			kanvas.draw_line(p, p + Vector2(-6, 18), Color(0.75, 0.82, 1.0, 0.45), 2)

	if _kemajuan() > 0.4 and _lambat <= 0.0:
		var a: = (_kemajuan() - 0.4) * 0.35
		for i in 6:
			var y: = 190.0 + i * 40.0
			var x: = fposmod(UKURAN.x - _geser * 1.6 - i * 170.0, UKURAN.x + 200.0) - 100.0
			kanvas.draw_line(Vector2(x, y), Vector2(x + 90, y), Color(1, 1, 1, a), 2)

	for sisi in [0.0, 1.0]:
		var x0: float = sisi * (UKURAN.x - 90.0)
		var kiri: = Color(0, 0, 0, 0.22 if sisi == 0.0 else 0.0)
		var kanan: = Color(0, 0, 0, 0.0 if sisi == 0.0 else 0.22)
		kanvas.draw_polygon(PackedVector2Array([Vector2(x0, 0), Vector2(x0 + 90, 0), Vector2(x0 + 90, UKURAN.y), Vector2(x0, UKURAN.y)]), 
			PackedColorArray([kiri, kanan, kanan, kiri]))

	var r: = Rect2(UKURAN.x - 300, 10, 280, 66)
	kotak_bulat(r, Color(0, 0, 0, 0.5), 14)
	teks(Vector2(r.get_center().x, r.position.y + 18), "Ke %s" % String(order.get("tujuan", "tujuan")), 17, GH.KUNING, r.size.x - 16, 4)
	var sisa_km: = maxf(float(order.get("km", 1.0)) * (1.0 - _kemajuan()), 0.0)
	var tulisan_km: = "Sampai!" if sisa_km < 0.05 else ("%s m lagi" % int(round(sisa_km * 1000.0 / 50.0) * 50) if sisa_km < 1.0 else "%s km lagi" % String.num(sisa_km, 1).replace(".", ","))
	teks(Vector2(r.get_center().x, r.position.y + 46), tulisan_km, 26, Color.WHITE, r.size.x - 16, 5)
	teks(Vector2(120, 26), "Barang aman" if _barang else "Penumpang nyaman", 17, Color.WHITE, 220, 4)

	if _umur_komentar > 0.0 and _komentar != "":
		var a: = minf(_umur_komentar * 2.0, 1.0)
		var kotak: = Rect2(_pos.x - 60, _pos.y - 206, 270, 44)
		kotak_bulat(kotak, Color(1, 1, 1, 0.94 * a), 14)
		kanvas.draw_colored_polygon(PackedVector2Array([Vector2(kotak.position.x + 40, kotak.end.y), Vector2(kotak.position.x + 64, kotak.end.y), 
			Vector2(kotak.position.x + 46, kotak.end.y + 14)]), Color(1, 1, 1, 0.94 * a))
		teks(kotak.get_center() + Vector2(0, -2), _komentar, 18, Color(0.2, 0.15, 0.1, a), 260)


func _y_urut(b: Dictionary) -> float:
	return Y_JALAN_ATAS if b["jenis"] == "polisi" else float(b["y"])



func _rumah_rumah() -> void :
	var g: = fmod(_geser * 0.4, 250.0)
	for i in 7:
		var x: = i * 250.0 - g - 40.0
		var tinggi: = 62.0 + float((i * 37) % 34)
		var dasar: = Y_TROTOAR
		var muka: Color = Color(0.24, 0.22, 0.27) if _malam else [Color(0.86, 0.7, 0.52), Color(0.78, 0.82, 0.7), Color(0.9, 0.78, 0.66)][i % 3]
		var samping: = muka.darkened(0.3)
		kanvas.draw_colored_polygon(PackedVector2Array([Vector2(x + 170, dasar - tinggi), Vector2(x + 196, dasar - tinggi - 10), Vector2(x + 196, dasar - 8), Vector2(x + 170, dasar)]), samping)
		kanvas.draw_rect(Rect2(x + 20, dasar - tinggi, 150, tinggi), muka)
		var atap: = Color(0.2, 0.1, 0.1) if _malam else Color(0.62, 0.24, 0.16)
		kanvas.draw_colored_polygon(PackedVector2Array([Vector2(x + 6, dasar - tinggi + 2), Vector2(x + 30, dasar - tinggi - 34), Vector2(x + 206, dasar - tinggi - 44), Vector2(x + 184, dasar - tinggi - 2)]), atap)
		kanvas.draw_line(Vector2(x + 6, dasar - tinggi + 2), Vector2(x + 184, dasar - tinggi - 2), atap.darkened(0.35), 3)
		var jendela: = Color(1.0, 0.82, 0.45) if _malam else Color(0.36, 0.46, 0.56)
		for jx in [52.0, 112.0]:
			kanvas.draw_rect(Rect2(x + jx - 2, dasar - tinggi + 20, 30, 26), Color(0.15, 0.12, 0.1) if _malam else Color(0.95, 0.92, 0.85))
			kanvas.draw_rect(Rect2(x + jx, dasar - tinggi + 22, 26, 22), jendela)
			if _malam:
				kanvas.draw_circle(Vector2(x + jx + 13, dasar - tinggi + 33), 26, Color(1, 0.8, 0.4, 0.08))
		kanvas.draw_rect(Rect2(x + 84, dasar - 40, 24, 40), muka.darkened(0.45))


func _elips(c: Vector2, r: Vector2, w: Color) -> void :
	var t: = PackedVector2Array()
	for i in 20:
		var a: = i * TAU / 20.0
		t.append(c + Vector2(cos(a) * r.x, sin(a) * r.y))
	kanvas.draw_colored_polygon(t, w)


func _gambar_benda(b: Dictionary, waktu: float) -> void :
	var x: = float(b["x"])
	var y: = float(b["y"])
	var s: = lerpf(0.8, 1.05, _dalam(y))
	match String(b["jenis"]):
		"lubang":
			_elips(Vector2(x, y - 12), Vector2(38, 14) * s, Color(0.06, 0.05, 0.05))
			_elips(Vector2(x - 2, y - 15), Vector2(30, 9) * s, Color(0.02, 0.02, 0.02))
			kanvas.draw_arc(Vector2(x, y - 12), 38 * s, PI * 0.1, PI * 0.9, 12, Color(1, 1, 1, 0.12), 2)
		"genangan":
			_elips(Vector2(x, y - 12), Vector2(52, 16) * s, Color(0.42, 0.52, 0.7, 0.8))
			_elips(Vector2(x - 12, y - 16), Vector2(22, 4) * s, Color(1, 1, 1, 0.35))
		"batu":
			bayangan(Vector2(x + 4, y - 4), 44 * s, 0.3)
			kanvas.draw_circle(Vector2(x, y - 14 * s), 16 * s, Color(0.45, 0.43, 0.42))
			kanvas.draw_circle(Vector2(x - 5, y - 19 * s), 8 * s, Color(0.65, 0.63, 0.6))
		"ayam":
			var goyang: = sin(float(b.get("t", 0.0)) * 12.0) * 3.0
			var p: = Vector2(x, y - 34 * s + goyang)
			bayangan(Vector2(x, y - 4), 42 * s, 0.28)
			kanvas.draw_circle(p, 17 * s, Color(0.97, 0.95, 0.9))
			kanvas.draw_circle(p + Vector2(-14, -16) * s, 10 * s, Color(0.97, 0.95, 0.9))
			kanvas.draw_circle(p + Vector2(-14, -27) * s, 5 * s, Color(0.9, 0.2, 0.15))
			kanvas.draw_colored_polygon(PackedVector2Array([p + Vector2(-24, -17) * s, p + Vector2(-33, -13) * s, p + Vector2(-24, -11) * s]), Color(0.95, 0.65, 0.1))
			kanvas.draw_line(p + Vector2(-4, 14) * s, p + Vector2(-4, 28) * s, Color(0.95, 0.65, 0.1), 3)
			kanvas.draw_line(p + Vector2(5, 14) * s, p + Vector2(5, 28) * s, Color(0.95, 0.65, 0.1), 3)
		"kucing":
			var p: = Vector2(x, y - 20 * s)
			bayangan(Vector2(x, y - 3), 46 * s, 0.25)
			_elips(p, Vector2(24, 11) * s, Color(0.85, 0.55, 0.25))
			kanvas.draw_circle(p + Vector2(-24, -8) * s, 10 * s, Color(0.85, 0.55, 0.25))
			kanvas.draw_colored_polygon(PackedVector2Array([p + Vector2(-31, -14) * s, p + Vector2(-28, -24) * s, p + Vector2(-23, -15) * s]), Color(0.75, 0.45, 0.2))
			kanvas.draw_line(p + Vector2(22, -2) * s, p + Vector2(34, -18 + sin(waktu * 8.0) * 4.0) * s, Color(0.85, 0.55, 0.25), 4)
		"bola":
			var p: = Vector2(x, y - 14 * s)
			bayangan(Vector2(x, y - 2), 30 * s, 0.3)
			kanvas.draw_circle(p, 13 * s, Color(0.95, 0.95, 0.95))
			kanvas.draw_circle(p, 5 * s, Color(0.1, 0.1, 0.1))
			kanvas.draw_circle(p + Vector2(-4, -5) * s, 4 * s, Color(1, 1, 1))
		"koin":
			if not b["kena"]:
				var naik: = sin(waktu * 5.0 + x * 0.01) * 5.0
				bayangan(Vector2(x, y - 4), 30 * s, 0.22)
				gambar_tekstur("res://assets/ikon/koin.svg", Vector2(x, y - 46 * s + naik), 44 * s)
		"kendaraan":

			var panjang: = float(KENDARAAN[b["model"]][1]) * PPM_KENDARAAN
			bayangan(Vector2(x + 8, y - 2), panjang * 0.95, 0.34)
			if _malam and float(b.get("vx", 0.0)) > 0.0:
				var l: = Vector2(x - panjang * 0.45, y - 30)
				kanvas.draw_colored_polygon(PackedVector2Array([l, l + Vector2(-220, -50), l + Vector2(-240, 40), l + Vector2(-10, 12)]), Color(1, 0.95, 0.7, 0.14))
		"polisi":

			var celah: = float(b["celah"])
			for bagian in [[Y_JALAN_ATAS + 4.0, celah - CELAH_POLISI * 0.5], [celah + CELAH_POLISI * 0.5, Y_JALAN_BAWAH - 4.0]]:
				var y0: float = bagian[0]
				var y1: float = bagian[1]
				if y1 - y0 < 4.0:
					continue
				kanvas.draw_rect(Rect2(x + 12, y0 + 4, 8, y1 - y0), Color(0, 0, 0, 0.3))
				kanvas.draw_rect(Rect2(x - 14, y0, 28, y1 - y0), Color(0.12, 0.11, 0.1))
				var yy: = y0
				var kuning: = true
				while yy < y1:
					kanvas.draw_rect(Rect2(x - 12, yy, 22, minf(20.0, y1 - yy)), Color(0.98, 0.82, 0.14) if kuning else Color(0.14, 0.13, 0.12))
					kuning = not kuning
					yy += 20.0
				kanvas.draw_rect(Rect2(x - 12, y0, 4, y1 - y0), Color(1, 1, 1, 0.22))
			for i in 4:
				kanvas.draw_circle(Vector2(x - 8 + i * 6, celah - 20 + i * 12), 2.5, Color(0.55, 0.52, 0.5))



func _isi_hasil_khusus(kolom: VBoxContainer, _t: Label) -> bool:
	var h: = hasil()
	var bintang: = 3 if h >= 0.9 else (2 if h >= 0.6 else (1 if h >= 0.3 else 0))
	var p: = potret_warga()
	var ucap: = HBoxContainer.new()
	ucap.alignment = BoxContainer.ALIGNMENT_CENTER
	ucap.add_theme_constant_override("separation", 12)
	kolom.add_child(ucap)
	if p != null:
		ucap.add_child(_bulat(p, 64))
	var bagus: = bintang >= 2
	var kalimat: String = (UCAP_BARANG_BAGUS if bagus else UCAP_BARANG_JELEK).pick_random() if _barang else (UCAP_BAGUS if bagus else UCAP_JELEK).pick_random()
	ucap.add_child(GH.label("\"%s\"" % kalimat, 22, Color.WHITE))
	var bayar: Dictionary = GameState.ngojol_bayaran(order, h)
	var ongkos: = int(bayar["ongkos"])
	var tip: = int(bayar["tip"])
	var u: = GH.label("Ongkos %s%s" % [GameState.format_rupiah(ongkos), (" + tip %s" % GameState.format_rupiah(tip)) if tip > 0 else ""], 28, GH.HIJAU_UANG, true)
	u.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	kolom.add_child(u)
	if int(bayar.get("potong", 0)) > 0:
		var pt: = GH.label("Dipotong %s karena nyetirnya kurang mulus." % GameState.format_rupiah(int(bayar["potong"])), 20, Color(1.0, 0.75, 0.6))
		pt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		kolom.add_child(pt)
	return true
