extends SubViewport








const SUDUT_KAMERA: = 35.0
const UKURAN_KAMERA: = 2.4
const PUSAT_KAMERA: = 1.08
const LEBAR_BINGKAI_PAYUNG: = 820
const TINGGI_PINGGUL: = 0.8
const LANGKAH_PER_DETIK: = 1.9
const TINGGI_DEWASA_M: = 1.72

var berjalan: = false
var berlari: = false
var arah_layar: = Vector2(0, -1)
var kamera: Camera3D

var _akar: Node3D
var _pinggul: Node3D
var _badan: Node3D
var _kepala: Node3D
var _paha: = []
var _betis: = []
var _lengan: = []
var _lengan_bawah: = []
var _waktu: = 0.0
var _sudut_hadap: = 0.0
var _animasi: AnimationPlayer = null
var _model: Node3D = null
var _anim_jalan: = "Walk"
var _anim_diam: = "Idle"
var _waktu_pose_diam: = 0.0
var _sedang_aksi: = false


func _init() -> void :


	size = Vector2i(Vector2(440, 660.0 * UKURAN_KAMERA / 1.95) * GameState.skala_viewport_3d())
	transparent_bg = true
	own_world_3d = true
	msaa_3d = GameState.msaa_3d()
	render_target_update_mode = SubViewport.UPDATE_ALWAYS






const SKALA_BINGKAI_NPC: = 0.72
var faktor_bingkai: = 1.0

func jadikan_npc() -> void :
	faktor_bingkai = SKALA_BINGKAI_NPC
	size = Vector2i(Vector2(440, 660.0 * UKURAN_KAMERA / 1.95) * skala_bingkai())
	msaa_3d = msaa_sendiri()


func skala_bingkai() -> float:
	return GameState.skala_viewport_3d() * faktor_bingkai


func msaa_sendiri() -> Viewport.MSAA:
	var m: = GameState.msaa_3d()
	if faktor_bingkai < 1.0 and m == Viewport.MSAA_4X:
		return Viewport.MSAA_2X
	return m


func rakit(cfg: Dictionary) -> void :
	_siapkan_dunia()
	_akar = Node3D.new()
	add_child(_akar)
	var skala: = float(cfg.get("skala", 1.0))
	_akar.scale = Vector3(skala, skala, skala)
	if cfg.has("model") or cfg.has("file"):
		_rakit_model(cfg, skala)
		return

	var kulit: = _warna(cfg, "kulit", "#c58a5c")
	var baju: = _warna(cfg, "baju", "#e8e8e8")
	var celana: = _warna(cfg, "celana", "#3a3f4a")
	var sepatu: = _warna(cfg, "sepatu", "#1c1c1c")
	var lengan_panjang: bool = cfg.get("lengan_panjang", false)
	var rok: = cfg.has("rok")

	_pinggul = _sendi(_akar, Vector3(0, TINGGI_PINGGUL, 0))

	for sisi in [-1, 1]:
		var paha: = _sendi(_pinggul, Vector3(0.095 * sisi, 0, 0))
		_bentuk(paha, _kapsul(0.082, 0.44), Vector3(0, -0.19, 0), _warna(cfg, "rok", "") if rok else celana)
		var betis: = _sendi(paha, Vector3(0, -0.38, 0))
		_bentuk(betis, _kapsul(0.068, 0.42), Vector3(0, -0.18, 0), kulit if cfg.get("celana_pendek", false) else celana)
		_bentuk(betis, _kotak(Vector3(0.12, 0.08, 0.22)), Vector3(0, -0.38, -0.04), sepatu)
		_paha.append(paha)
		_betis.append(betis)
	if cfg.get("celana_pendek", false):
		for paha in _paha:
			_bentuk(paha, _kapsul(0.09, 0.28), Vector3(0, -0.1, 0), celana)

	_badan = _sendi(_pinggul, Vector3(0, 0.02, 0))
	var tubuh: = _bentuk(_badan, _kapsul(0.21, 0.64), Vector3(0, 0.29, 0), baju)
	tubuh.scale = Vector3(1.0, 1.0, 0.75)
	if rok:

		var gamis: = CylinderMesh.new()
		gamis.top_radius = 0.18
		gamis.bottom_radius = 0.3
		gamis.height = 0.78
		_bentuk(_badan, gamis, Vector3(0, -0.34, 0), _warna(cfg, "rok", "#d9c2b0")).scale = Vector3(1, 1, 0.8)
	if cfg.has("tas"):
		_bentuk(_badan, _kotak(Vector3(0.32, 0.36, 0.15)), Vector3(0, 0.33, 0.19), _warna(cfg, "tas", "#222222"))
	if cfg.has("jaket_garis"):
		_bentuk(_badan, _kotak(Vector3(0.43, 0.06, 0.33)), Vector3(0, 0.38, 0), _warna(cfg, "jaket_garis", "#111111"))


	for sisi in [-1, 1]:
		var lengan: = _sendi(_badan, Vector3(0.255 * sisi, 0.52, 0))
		_bentuk(lengan, _kapsul(0.066, 0.32), Vector3(0, -0.13, 0), baju)
		var bawah: = _sendi(lengan, Vector3(0, -0.27, 0))
		_bentuk(bawah, _kapsul(0.056, 0.28), Vector3(0, -0.11, 0), baju if lengan_panjang else kulit)
		_bentuk(bawah, _bola(0.06), Vector3(0, -0.27, 0), kulit)
		lengan.rotation.z = 0.08 * sisi
		_lengan.append(lengan)
		_lengan_bawah.append(bawah)


	_bentuk(_badan, _kapsul(0.06, 0.12), Vector3(0, 0.62, 0), kulit)
	_kepala = _sendi(_badan, Vector3(0, 0.76, 0))

	_kepala.scale = Vector3(1.25, 1.25, 1.25)
	var muka: = _bentuk(_kepala, _bola(0.125), Vector3(0, 0.03, 0), kulit)
	muka.scale = Vector3(1.0, 1.12, 1.0)
	for sisi in [-1, 1]:
		_bentuk(_kepala, _bola(0.017), Vector3(0.045 * sisi, 0.05, -0.115), Color("#1a1210"))
	match cfg.get("kepala", "rambut"):
		"helm":
			var helm: = _bentuk(_kepala, _bola(0.16), Vector3(0, 0.07, 0.01), _warna(cfg, "warna_kepala", "#111111"))
			helm.scale = Vector3(1.0, 0.95, 1.05)
			_bentuk(_kepala, _kotak(Vector3(0.2, 0.06, 0.04)), Vector3(0, 0.06, -0.15), Color(0.15, 0.2, 0.25))
		"hijab":
			var tudung: = _bentuk(_kepala, _bola(0.152), Vector3(0, 0.04, 0.02), _warna(cfg, "warna_kepala", "#d8a7a7"))
			tudung.scale = Vector3(1.0, 1.08, 1.0)
			var jilbab: = CylinderMesh.new()
			jilbab.top_radius = 0.12
			jilbab.bottom_radius = 0.27
			jilbab.height = 0.28
			_bentuk(_kepala, jilbab, Vector3(0, -0.15, 0.01), _warna(cfg, "warna_kepala", "#d8a7a7")).scale = Vector3(1, 1, 0.8)

			_bentuk(_kepala, _bola(0.1), Vector3(0, 0.02, -0.05), kulit).scale = Vector3(1, 1.15, 0.9)
			for sisi in [-1, 1]:
				_bentuk(_kepala, _bola(0.016), Vector3(0.04 * sisi, 0.045, -0.14), Color("#1a1210"))
		_:
			var rambut: = _bentuk(_kepala, _bola(0.135), Vector3(0, 0.07, 0.025), _warna(cfg, "warna_kepala", "#1b130e"))
			rambut.scale = Vector3(1.02, 0.85, 1.0)


var _bingkai: = 0



var di_layar: = true

func _process(delta: float) -> void :
	if _akar == null:
		return



	if not di_layar:
		render_target_update_mode = SubViewport.UPDATE_DISABLED
	elif berjalan or _sedang_aksi or (Engine.max_fps == 30 and not GameState.grafik_rendah()):
		render_target_update_mode = SubViewport.UPDATE_ALWAYS
	else:
		_bingkai += 1
		render_target_update_mode = SubViewport.UPDATE_ONCE if _bingkai % 2 == 0 else SubViewport.UPDATE_DISABLED


	if arah_layar.length() > 0.01:
		var tanah: = Vector3(arah_layar.x, 0, arah_layar.y / sin(deg_to_rad(SUDUT_KAMERA)))
		_sudut_hadap = atan2( - tanah.x, - tanah.z)
	_perbarui_hidup(delta)

	var laju_putar: = 2.5 if hidup else (4.5 if _gerak_kucing != null else 10.0)
	_akar.rotation.y = lerp_angle(_akar.rotation.y, _sudut_hadap + _lirik, minf(delta * laju_putar, 1.0))
	if _gerak_kucing != null:
		_gerak_kucing.berjalan = berjalan
		_gerak_kucing.berlari = berlari
		_gerak_kucing.laju_tanah = laju_tanah
	if _animasi != null:
		_perbarui_payung()
		_perbarui_bawaan()
		if _sedang_aksi:
			return

		if _bawaan != null and not berjalan and PAKAI_ANIM_BAWA and _animasi.has_animation(ANIM_BAWA):
			return

		if berjalan:
			var anim: = _anim_jalan_sekarang()
			if _animasi.current_animation != anim or not _animasi.is_playing():
				_animasi.play(anim, 0.2)
			_samakan_langkah(anim, delta)
			return
		_animasi.speed_scale = _kecepatan_anim
		if _anim_diam != "":
			if _animasi.current_animation != _anim_diam:
				_animasi.play(_anim_diam, 0.2)
		elif _animasi.is_playing():
			_berdiri_diam()
		return

	var ayun: = 1.0 if berjalan else 0.0
	_waktu += delta * (LANGKAH_PER_DETIK * TAU if berjalan else 1.6)
	var s: = sin(_waktu)
	for i in 2:
		var arah: = 1.0 if i == 0 else -1.0
		var langkah: = s * arah
		_paha[i].rotation.x = lerp(_paha[i].rotation.x, langkah * 0.55 * ayun, 0.35)

		_betis[i].rotation.x = lerp(_betis[i].rotation.x, - maxf(0.0, - langkah) * 0.75 * ayun, 0.35)
		_lengan[i].rotation.x = lerp(_lengan[i].rotation.x, - langkah * 0.5 * ayun, 0.35)
		_lengan_bawah[i].rotation.x = lerp(_lengan_bawah[i].rotation.x, -0.25 - 0.15 * ayun, 0.35)

	if berjalan:
		_pinggul.position.y = TINGGI_PINGGUL + absf(sin(_waktu)) * 0.035
		_badan.rotation.y = s * 0.08
	else:
		_pinggul.position.y = lerpf(_pinggul.position.y, TINGGI_PINGGUL, 0.2)
		_badan.rotation.y = lerpf(_badan.rotation.y, 0.0, 0.2)
		_badan.scale.y = 1.0 + sin(_waktu) * 0.006



func titik_kaki() -> Vector2:
	return kamera.unproject_position(Vector3.ZERO)


func piksel_per_meter() -> float:


	return size.y / kamera.size




func _matikan_normal_map(akar: Node) -> void :
	for mi in GameState.cari_anak(akar, "MeshInstance3D"):
		var m3: = mi as MeshInstance3D
		if m3.mesh == null:
			continue
		for s in m3.mesh.get_surface_count():
			var bahan: = m3.get_active_material(s)
			if bahan is BaseMaterial3D and (bahan as BaseMaterial3D).normal_enabled:
				var salinan: = bahan.duplicate() as BaseMaterial3D
				salinan.normal_enabled = false
				salinan.normal_texture = null
				m3.set_surface_override_material(s, salinan)


func _siapkan_dunia() -> void :
	var lingkungan: = Environment.new()
	lingkungan.background_mode = Environment.BG_CLEAR_COLOR
	lingkungan.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	lingkungan.ambient_light_color = Color(0.85, 0.72, 0.62)
	lingkungan.ambient_light_energy = 0.42
	lingkungan.tonemap_mode = Environment.TONE_MAPPER_FILMIC



	var dunia: = WorldEnvironment.new()
	dunia.environment = lingkungan
	add_child(dunia)


	var lampu: = DirectionalLight3D.new()
	lampu.light_color = Color(1.0, 0.82, 0.6)
	lampu.light_energy = 1.15
	lampu.rotation = Vector3(deg_to_rad(-45), deg_to_rad(-35), 0)
	add_child(lampu)
	var isi: = DirectionalLight3D.new()
	isi.light_color = Color(0.55, 0.6, 0.85)
	isi.light_energy = 0.3
	isi.rotation = Vector3(deg_to_rad(-20), deg_to_rad(150), 0)
	add_child(isi)

	kamera = Camera3D.new()
	kamera.projection = Camera3D.PROJECTION_ORTHOGONAL
	kamera.size = UKURAN_KAMERA
	var sasaran: = Vector3(0, PUSAT_KAMERA, 0)
	var sudut: = deg_to_rad(SUDUT_KAMERA)
	kamera.position = sasaran + Vector3(0, sin(sudut), cos(sudut)) * 6.0
	kamera.rotation.x = - sudut
	add_child(kamera)
	kamera.current = true


func _sendi(induk: Node3D, posisi: Vector3) -> Node3D:
	var n: = Node3D.new()
	n.position = posisi
	induk.add_child(n)
	return n


func _bentuk(induk: Node3D, mesh: Mesh, posisi: Vector3, warna: Color) -> MeshInstance3D:
	var m: = MeshInstance3D.new()
	m.mesh = mesh
	m.position = posisi
	var bahan: = StandardMaterial3D.new()
	bahan.albedo_color = warna
	bahan.roughness = 0.85
	m.material_override = bahan
	induk.add_child(m)
	return m


func _kapsul(jari: float, tinggi: float) -> CapsuleMesh:
	var k: = CapsuleMesh.new()
	k.radius = jari
	k.height = tinggi
	k.radial_segments = 16
	k.rings = 6
	return k


func _bola(jari: float) -> SphereMesh:
	var b: = SphereMesh.new()
	b.radius = jari
	b.height = jari * 2.0
	b.radial_segments = 20
	b.rings = 10
	return b


func _kotak(ukuran: Vector3) -> BoxMesh:
	var k: = BoxMesh.new()
	k.size = ukuran
	return k


func _warna(cfg: Dictionary, kunci: String, bawaan: String) -> Color:
	return Color.html(cfg.get(kunci, bawaan)) if cfg.get(kunci, bawaan) != "" else Color.html("#888888")






const TINGGI_MODEL: = 3.33
const HADAP_MODEL: = PI

func _rakit_model(cfg: Dictionary, _skala: float) -> void :

	var file: String = cfg.get("file", "%s.gltf" % cfg.get("model", ""))
	_model = GameState.muat_model("res://assets/karakter3d/" + file)
	_model.rotation.y = HADAP_MODEL + deg_to_rad(float(cfg.get("putar_model", 0.0)))
	_akar.add_child(_model)
	if cfg.get("tanpa_normal", false):
		_matikan_normal_map(_model)
	_anim_jalan = cfg.get("anim_jalan", "Walk")
	_anim_diam = cfg.get("anim_diam", "Idle")
	var pemutar: Array = GameState.cari_anak(_model, "AnimationPlayer")
	if pemutar.is_empty():


		var ap: = AnimationPlayer.new()
		var pustaka: = AnimationLibrary.new()
		var diam: = Animation.new()
		diam.length = 1.0
		diam.loop_mode = Animation.LOOP_LINEAR
		pustaka.add_animation("diam", diam)
		ap.add_animation_library("", pustaka)
		_model.add_child(ap)
		pemutar = [ap]
		_anim_jalan = "diam"
		_anim_diam = "diam"
	_animasi = pemutar[0]
	if file == GameState.FILE_MODEL_PENJAGA["ibu"]:
		GameState.siapkan_animasi_penjaga(_animasi)
	if cfg.get("gerak", "") == "kucing":
		var kerangka_k: Array = GameState.cari_anak(_model, "Skeleton3D")
		if not kerangka_k.is_empty():
			_gerak_kucing = load("res://scripts/kucing_hidup.gd").new()
			kerangka_k[0].add_child(_gerak_kucing)

	_kecepatan_anim = float(cfg.get("kecepatan", 1.0))
	_animasi.speed_scale = _kecepatan_anim

	if cfg.has("bungkuk"):
		var kerangka: Array = GameState.cari_anak(_model, "Skeleton3D")
		if not kerangka.is_empty():
			var mod: SkeletonModifier3D = load("res://scripts/bungkuk.gd").new()
			mod.sudut = float(cfg["bungkuk"])
			kerangka[0].add_child(mod)

	var kerangka_lp: Array = GameState.cari_anak(_model, "Skeleton3D")
	if not kerangka_lp.is_empty() and (kerangka_lp[0] as Skeleton3D).find_bone("mixamorig_RightForeArm") >= 0:
		_lengan_payung = load("res://scripts/lengan_payung.gd").new()
		_lengan_payung.tekuk_lokal = file.get_file().begins_with("meshy_bapak")
		kerangka_lp[0].add_child(_lengan_payung)


	if cfg.has("mesh_warna"):
		var mesh_ada: Array = GameState.cari_anak(_model, "MeshInstance3D")
		if not mesh_ada.is_empty():
			(mesh_ada[0] as MeshInstance3D).mesh = load("res://assets/karakter3d/" + cfg["mesh_warna"])


	var tinggi: = TINGGI_MODEL
	if cfg.has("file"):
		tinggi = 0.0


		for mi: MeshInstance3D in GameState.cari_anak(_model, "MeshInstance3D"):
			tinggi = maxf(tinggi, (mi.global_transform * mi.get_aabb()).size.y / _model.scale.y / _skala)

	if cfg.has("tinggi_asli"):
		tinggi = float(cfg["tinggi_asli"])
	var s: = TINGGI_DEWASA_M / tinggi
	_model.scale = Vector3(s, s, s)

	_animasi.get_animation(_anim_jalan).loop_mode = Animation.LOOP_LINEAR
	if _animasi.has_animation(_anim_diam):
		_animasi.get_animation(_anim_diam).loop_mode = Animation.LOOP_LINEAR
		_animasi.play(_anim_diam)

		_animasi.advance(0.0)
	else:

		_waktu_pose_diam = _cari_pose_kaki_rapat()
		_anim_diam = ""
		_berdiri_diam()

	var warna: Dictionary = cfg.get("warna", {}).duplicate()

	if not warna.has("Skin"):
		warna["Skin"] = cfg.get("kulit", "#c68a5e")

	if not warna.has("Face"):
		warna["Face"] = "#1c1410"
	for mi: MeshInstance3D in GameState.cari_anak(_model, "MeshInstance3D"):
		for i in mi.mesh.get_surface_count():
			var asli: = mi.mesh.surface_get_material(i)
			if asli == null:
				continue
			var nama_bahan: = asli.resource_name
			if warna.has(nama_bahan):
				var baru: BaseMaterial3D = asli.duplicate()
				baru.albedo_color = Color.html(warna[nama_bahan])
				mi.set_surface_override_material(i, baru)

	if cfg.has("varian_baju") and not (cfg["varian_baju"].get("bagian", []) as Array).is_empty():
		VarianBaju.pasang(_model, cfg["varian_baju"])

	var tulang_ada: Array = GameState.cari_anak(_model, "Skeleton3D")
	if not tulang_ada.is_empty():
		for aksesori in cfg.get("aksesori", []):
			_pasang_aksesori(tulang_ada[0], aksesori, cfg)




func _pasang_aksesori(tulang: Skeleton3D, jenis: String, cfg: Dictionary) -> void :
	var tempel: = BoneAttachment3D.new()
	tempel.bone_name = "Torso" if jenis == "tas" else "Head"
	tulang.add_child(tempel)
	var warna_aksesori: = Color.html(cfg.get("warna_aksesori", "#141414"))
	match jenis:
		"helm":
			var helm: = _bentuk(tempel, _bola(0.56), Vector3(0, 0.62, -0.04), warna_aksesori)
			helm.scale = Vector3(1.0, 0.85, 1.05)
		"hijab":
			var tudung: = _bentuk(tempel, _bola(0.62), Vector3(0, 0.72, 0), warna_aksesori)
			tudung.scale = Vector3(1.0, 0.9, 1.0)
			var kain: = CylinderMesh.new()
			kain.top_radius = 0.48
			kain.bottom_radius = 0.8
			kain.height = 0.5
			_bentuk(tempel, kain, Vector3(0, 0.12, 0), warna_aksesori).scale = Vector3(1, 1, 0.8)
		"tas":
			_bentuk(tempel, _kotak(Vector3(0.7, 0.8, 0.32)), Vector3(0, 0.15, -0.45), warna_aksesori)



func _berdiri_diam() -> void :
	_animasi.play(_anim_jalan)
	_animasi.seek(_waktu_pose_diam, true)
	_animasi.pause()


func _cari_pose_kaki_rapat(nama: = "") -> float:
	if nama == "":
		nama = _anim_jalan
	var tulang_ada: Array = GameState.cari_anak(_model, "Skeleton3D")
	if tulang_ada.is_empty():
		return 0.0
	var tulang: Skeleton3D = tulang_ada[0]
	var kiri: = -1
	var kanan: = -1
	for i in tulang.get_bone_count():
		var n: = tulang.get_bone_name(i).to_lower()
		if n.ends_with("leftfoot"): kiri = i
		if n.ends_with("rightfoot"): kanan = i
	if kiri < 0 or kanan < 0:
		return 0.0
	var anim: = _animasi.get_animation(nama)
	_animasi.play(nama)
	var terbaik: = 0.0
	var jarak_terkecil: = INF
	for k in 40:
		var t: = anim.length * k / 40.0
		_animasi.seek(t, true)
		var a: = tulang.get_bone_global_pose(kiri).origin
		var b: = tulang.get_bone_global_pose(kanan).origin
		var jarak: = Vector2(a.x - b.x, a.z - b.z).length() + absf(a.y - b.y)
		if jarak < jarak_terkecil:
			jarak_terkecil = jarak
			terbaik = t
	return terbaik




func batalkan_aksi() -> void :
	_sedang_aksi = false

	duduk = false


func mainkan_sekali(nama: String) -> void :
	if _animasi == null or not _animasi.has_animation(nama):
		return
	_animasi.get_animation(nama).loop_mode = Animation.LOOP_NONE
	_sedang_aksi = true
	_animasi.play(nama, 0.25)
	await _animasi.animation_finished
	_sedang_aksi = false





func mainkan_tahan(nama: String, kecepatan: = 1.0, mulai: = 0.0) -> void :
	if _animasi == null or not _animasi.has_animation(nama):
		return
	_animasi.get_animation(nama).loop_mode = Animation.LOOP_NONE
	_sedang_aksi = true
	_animasi.play(nama, 0.0 if mulai > 0.0 else 0.25, kecepatan)
	if mulai > 0.0:
		_animasi.seek(mulai, true)


	await GameState.get_tree().create_timer((_animasi.get_animation(nama).length - mulai) / maxf(_animasi.speed_scale * kecepatan, 0.01)).timeout






var _kerangka_simpan: Skeleton3D = null

func _kerangka_model() -> Array:
	if _kerangka_simpan != null and is_instance_valid(_kerangka_simpan) and _kerangka_simpan.is_inside_tree():
		return [_kerangka_simpan]
	_kerangka_simpan = null
	if _model == null or not is_instance_valid(_model) or not _model.is_inside_tree():
		return []
	var semua: Array = GameState.cari_anak(_model, "Skeleton3D")
	if not semua.is_empty():
		_kerangka_simpan = semua[0]
	return semua




func mainkan_tahan_baur(nama: String, baur: float) -> void :
	if _animasi == null or not _animasi.has_animation(nama):
		return
	_animasi.get_animation(nama).loop_mode = Animation.LOOP_NONE
	_sedang_aksi = true
	_animasi.play(nama, baur)



var _mod_kaki: SkeletonModifier3D = null

func luruskan_kaki(nyala: bool, jeda: = 0.0, lama: = 1.0) -> void :
	if _mod_kaki != null:
		_mod_kaki.queue_free()
		_mod_kaki = null
	var kerangka: Array = _kerangka_model()
	if not nyala or kerangka.is_empty():
		return
	_mod_kaki = load("res://scripts/kaki_tidur.gd").new()
	kerangka[0].add_child(_mod_kaki)
	create_tween().tween_property(_mod_kaki, "kuat", 1.0, lama).set_delay(jeda)



func hadap_langsung(arah: Vector2) -> void :
	arah_layar = arah
	_sudut_hadap = atan2( - arah.x, - arah.y / sin(deg_to_rad(SUDUT_KAMERA)))
	_akar.rotation.y = _sudut_hadap + _lirik




func posisi_animasi() -> float:
	return _animasi.current_animation_position if _animasi != null and _animasi.is_playing() else 0.0



func pose_akhir(nama: String) -> void :
	if _animasi == null or not _animasi.has_animation(nama):
		return
	_animasi.get_animation(nama).loop_mode = Animation.LOOP_NONE
	_sedang_aksi = true
	_animasi.play(nama)
	_animasi.seek(_animasi.get_animation(nama).length, true)
	_animasi.pause()


func lepas_tahan() -> void :
	_sedang_aksi = false




var _mod_bungkuk: SkeletonModifier3D = null

func atur_bungkuk(derajat: float) -> void :
	if _model == null:
		return
	if _mod_bungkuk == null:
		if derajat <= 0.0:
			return
		var kerangka: Array = _kerangka_model()
		if kerangka.is_empty():
			return
		_mod_bungkuk = load("res://scripts/bungkuk.gd").new()
		kerangka[0].add_child(_mod_bungkuk)
	_mod_bungkuk.sudut = derajat
	_mod_bungkuk.active = derajat > 0.0


func ganti_anim_jalan(nama: String) -> void :
	if _animasi == null or nama == _anim_jalan or not _animasi.has_animation(nama):
		return
	_animasi.get_animation(nama).loop_mode = Animation.LOOP_LINEAR
	_anim_jalan = nama





const ANIM_DUDUK: = "Sit_Cross_Legged"
const BAUR_DUDUK: = 0.15
var duduk: = false

func bisa_duduk() -> bool:
	return _animasi != null and _animasi.has_animation(ANIM_DUDUK)


func mulai_duduk() -> void :
	if duduk or _sedang_aksi or not bisa_duduk():
		return
	duduk = true
	_sedang_aksi = true
	_animasi.get_animation(ANIM_DUDUK).loop_mode = Animation.LOOP_LINEAR
	_animasi.play(ANIM_DUDUK, BAUR_DUDUK)


func berdiri_dari_duduk() -> void :
	if not duduk:
		return
	duduk = false
	_sedang_aksi = false
	if _anim_diam != "":
		_animasi.play(_anim_diam, BAUR_DUDUK)







const ANIM_PAYUNG: = "Walk_with_Umbrella"
var _kecepatan_anim: = 1.0


var _lengan_payung: Node = null
func _pakai_payung() -> bool:
	return _lengan_payung != null and boleh_payung and _bawaan == null and GameState.sedang_hujan()


const FILE_PAYUNG: = "res://assets/payung/payung_merah.glb"
const SHADER_PAYUNG: = preload("res://shader/payung_warna.gdshader")
const WARNA_PAYUNG: = [Color(0.86, 0.09, 0.07), Color(0.13, 0.13, 0.14), Color(0.1, 0.28, 0.78), Color(0.98, 0.8, 0.08), Color(0.95, 0.45, 0.68)]
const TINGGI_PAYUNG_M: = 0.95
const ANGKAT_PAYUNG_M: = 0.04
var boleh_payung: = true
var _payung: Node3D = null
var _tangan_payung: BoneAttachment3D = null
var _dasar_payung: = 0.0
var _skala_payung: = 1.0
var _bawah_payung_model: = 0.0
var _tinggi_payung_model: = 1.0
var _lebar_tanpa_payung: = 0


func _anim_jalan_sekarang() -> String:
	return _anim_jalan









const LAJU_ANIM: = {"Walking": 1.39, "Walking_Woman": 1.45, "Running": 3.15}
const BATAS_GESER_LANGKAH: = 0.15
var laju_tanah: = -1.0

func _samakan_langkah(anim: String, delta: float) -> void :
	var alami: float = LAJU_ANIM.get(anim, 0.0) * _akar.scale.x
	if laju_tanah < 0.0 or alami <= 0.0:
		_animasi.speed_scale = _kecepatan_anim
		return
	var mau: = clampf(laju_tanah / alami, _kecepatan_anim * (1.0 - BATAS_GESER_LANGKAH), _kecepatan_anim * (1.0 + BATAS_GESER_LANGKAH))
	_animasi.speed_scale = lerpf(_animasi.speed_scale, mau, minf(delta * 8.0, 1.0))





func _jalan_di_tempat(anim: Animation) -> void :
	if anim.has_meta("di_tempat"):
		return
	anim.set_meta("di_tempat", true)
	var t: = _trek_pinggul(anim)
	if t < 0:
		return
	var n: = anim.track_get_key_count(t)
	var awal: Vector3 = anim.track_get_key_value(t, 0)
	var akhir: Vector3 = anim.track_get_key_value(t, n - 1)
	for i in n:
		var f: = anim.track_get_key_time(t, i) / maxf(anim.length, 0.001)
		var v: Vector3 = anim.track_get_key_value(t, i)
		anim.track_set_key_value(t, i, Vector3(v.x - (akhir.x - awal.x) * f, v.y, v.z - (akhir.z - awal.z) * f))


func _trek_pinggul(anim: Animation) -> int:
	for t in anim.get_track_count():
		if anim.track_get_type(t) == Animation.TYPE_POSITION_3D and str(anim.track_get_path(t)).ends_with("Hips"):
			return t
	return -1


func _perbarui_payung() -> void :
	var pakai: = _animasi != null and _pakai_payung()
	if _lengan_payung != null:
		_lengan_payung.kuat = move_toward(_lengan_payung.kuat, 1.0 if pakai else 0.0, get_process_delta_time() * 4.0)
	if pakai and _payung == null:
		_pasang_payung()
	if _payung == null:
		return
	_payung.visible = pakai

	var lebar_payung: = int(LEBAR_BINGKAI_PAYUNG * skala_bingkai())
	if pakai and size.x < lebar_payung:
		_lebar_tanpa_payung = size.x
		size.x = lebar_payung
	elif not pakai and _lebar_tanpa_payung > 0:
		size.x = _lebar_tanpa_payung
		_lebar_tanpa_payung = 0

	if _lengan_payung != null:
		_lengan_payung.payung = _payung if pakai else null
		_lengan_payung.skala_payung = _skala_payung
		_lengan_payung.naik_payung = (ANGKAT_PAYUNG_M - _dasar_payung) * _skala_payung
		_lengan_payung.bawah_payung = _bawah_payung_model * _skala_payung
		_lengan_payung.tinggi_payung = _tinggi_payung_model * _skala_payung


func _pasang_payung() -> void :
	var kerangka: Array = _kerangka_model()
	if kerangka.is_empty() or (kerangka[0] as Skeleton3D).find_bone("mixamorig_RightHand") < 0:
		return
	_tangan_payung = BoneAttachment3D.new()
	_tangan_payung.bone_name = "mixamorig_RightHand"
	kerangka[0].add_child(_tangan_payung)
	_payung = GameState.muat_model(FILE_PAYUNG)
	_warnai_payung(_payung, WARNA_PAYUNG.pick_random())

	_akar.add_child(_payung)
	var aabb: = AABB()
	for mi: MeshInstance3D in GameState.cari_anak(_payung, "MeshInstance3D"):
		aabb = mi.get_aabb() if aabb.size == Vector3.ZERO else aabb.merge(mi.get_aabb())


	_skala_payung = TINGGI_PAYUNG_M / maxf(aabb.size.y, 0.01) * _akar.scale.y

	_dasar_payung = aabb.position.y + aabb.size.y * 0.08
	_bawah_payung_model = aabb.position.y
	_tinggi_payung_model = aabb.size.y
	_payung.visible = false






var hidup: = false
var _lirik: = 0.0
var _waktu_hidup: = 0.0
var _sisa_lirik: = 3.0

func _perbarui_hidup(delta: float) -> void :

	if not hidup or berjalan or _sedang_aksi or _model == null or _gerak_kucing != null:
		_lirik = move_toward(_lirik, 0.0, delta * 2.0)
		if _model != null and _model.scale.y != _skala_napas_dasar and _skala_napas_dasar > 0.0:
			_model.scale.y = _skala_napas_dasar
		return
	if _skala_napas_dasar <= 0.0:
		_skala_napas_dasar = _model.scale.y
	_waktu_hidup += delta
	_model.scale.y = _skala_napas_dasar * (1.0 + 0.012 * sin(_waktu_hidup * 2.4))
	_sisa_lirik -= delta
	if _sisa_lirik <= 0.0:

		_target_lirik = 0.0 if absf(_target_lirik) > 0.01 else randf_range(0.25, 0.55) * (1.0 if randf() < 0.5 else -1.0)
		_sisa_lirik = randf_range(2.0, 4.0) if _target_lirik != 0.0 else randf_range(3.0, 6.0)
	_lirik = move_toward(_lirik, _target_lirik, delta * 0.8)

var _target_lirik: = 0.0
var _skala_napas_dasar: = 0.0





const ANIM_BAWA: = "Carry_Heavy_Object_Walk_inplace"
const PAKAI_ANIM_BAWA: = false
var _bawaan: Node3D = null
var _anim_jalan_sebelum_bawa: = ""
var _tangan_kiri: = -1
var _tangan_kanan: = -1
var _lengan_bawa: Node = null
var _gerak_kucing: Node = null

func bisa_bawa() -> bool:

	if _animasi == null or _model == null:
		return false
	var k: Array = _kerangka_model()
	return not k.is_empty() and (k[0] as Skeleton3D).find_bone("mixamorig_LeftHand") >= 0




func bawa_barang(file: String, lebar_m: = 0.42, gendong: = false, rapat_m: = 0.0) -> void :
	if not bisa_bawa() or _bawaan != null:
		return
	var kerangka: Array = _kerangka_model()
	if kerangka.is_empty():
		return
	var tulang: Skeleton3D = kerangka[0]
	_tangan_kiri = tulang.find_bone("mixamorig_LeftHand")
	_tangan_kanan = tulang.find_bone("mixamorig_RightHand")
	var isi: = GameState.muat_model(file)
	_bawaan = isi
	if gendong:
		_bawaan = Node3D.new()
		_bawaan.add_child(isi)
	_akar.add_child(_bawaan)
	await get_tree().process_frame
	if _bawaan == null or not is_instance_valid(_bawaan) or not is_instance_valid(isi) or not isi.is_inside_tree():
		return
	if gendong:
		var sk_isi: Array = GameState.cari_anak(isi, "Skeleton3D")
		if not sk_isi.is_empty():
			var sk: Skeleton3D = sk_isi[0]

			var ke_bungkus: = _bawaan.global_transform.affine_inverse() * sk.global_transform
			var a: = sk.find_bone("Bone_000")
			var b: = sk.find_bone("Bone_028")
			if a >= 0 and b >= 0:
				var d: = ke_bungkus.basis * (sk.get_bone_global_rest(b).origin - sk.get_bone_global_rest(a).origin)
				isi.rotate_y(PI / 2.0 - atan2(d.x, d.z))
			var gerak = load("res://scripts/kucing_hidup.gd").new()
			gerak.dipeluk = true
			sk.add_child(gerak)

	var kotak: = AABB()
	for mi: MeshInstance3D in GameState.cari_anak(_bawaan, "MeshInstance3D"):
		var k: = (_bawaan.global_transform.affine_inverse() * mi.global_transform if gendong else mi.transform) * mi.get_aabb()
		kotak = k if kotak.size == Vector3.ZERO else kotak.merge(k)
	var s: = lebar_m / maxf(kotak.size.x, maxf(kotak.size.y, kotak.size.z))
	_bawaan.set_meta("skala", s)
	_bawaan.set_meta("tengah", kotak.get_center())

	if _lengan_bawa == null:
		_lengan_bawa = load("res://scripts/lengan_bawa.gd").new()
		tulang.add_child(_lengan_bawa)
	_lengan_bawa.barang = _bawaan
	_lengan_bawa.skala_barang = s
	_lengan_bawa.tengah_barang = kotak.get_center()
	_lengan_bawa.ukuran_barang = kotak.size
	_lengan_bawa.topang_bawah = gendong
	_lengan_bawa.rapat_m = rapat_m


	if not PAKAI_ANIM_BAWA or not _animasi.has_animation(ANIM_BAWA):
		return
	_anim_jalan_sebelum_bawa = _anim_jalan
	_animasi.get_animation(ANIM_BAWA).loop_mode = Animation.LOOP_LINEAR
	_anim_jalan = ANIM_BAWA




var _lengan_peluk: SkeletonModifier3D = null

func atur_peluk(kuat: float, detik: = 0.9) -> void :
	if _lengan_peluk == null:
		if kuat <= 0.0:
			return
		var kerangka: Array = _kerangka_model()
		if kerangka.is_empty():
			return
		_lengan_peluk = load("res://scripts/lengan_peluk.gd").new()
		_lengan_peluk.influence = 0.0
		kerangka[0].add_child(_lengan_peluk)
	_lengan_peluk.active = true
	var tw: = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(_lengan_peluk, "influence", clampf(kuat, 0.0, 1.0), detik)
	if kuat <= 0.0:
		tw.tween_callback( func(): _lengan_peluk.active = false)




var _lengan_salim: SkeletonModifier3D = null

func atur_salim(kuat: float, cium: = false, detik: = 0.8) -> void :
	if _lengan_salim == null:
		if kuat <= 0.0:
			return
		var kerangka: Array = _kerangka_model()
		if kerangka.is_empty():
			return
		_lengan_salim = load("res://scripts/lengan_salim.gd").new()
		_lengan_salim.influence = 0.0
		kerangka[0].add_child(_lengan_salim)
	_lengan_salim.cium = cium
	_lengan_salim.active = true
	var tw: = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(_lengan_salim, "influence", clampf(kuat, 0.0, 1.0), detik)
	if kuat <= 0.0:
		tw.tween_callback( func(): _lengan_salim.active = false)


func lepas_barang() -> void :
	if _bawaan != null:
		_bawaan.queue_free()
		_bawaan = null
	if _lengan_bawa != null:
		_lengan_bawa.barang = null
	if _anim_jalan == ANIM_BAWA:
		_anim_jalan = _anim_jalan_sebelum_bawa if _anim_jalan_sebelum_bawa != "" else "Walking"


func _perbarui_bawaan() -> void :
	if _bawaan == null or not _bawaan.has_meta("skala") or _tangan_kiri < 0 or _tangan_kanan < 0 or not PAKAI_ANIM_BAWA or not _animasi.has_animation(ANIM_BAWA):
		return

	if not berjalan and not _sedang_aksi and _animasi.assigned_animation != ANIM_BAWA:
		_animasi.play(ANIM_BAWA)
	if not berjalan and _animasi.assigned_animation == ANIM_BAWA and _animasi.is_playing():
		_animasi.pause()
	elif berjalan and _animasi.assigned_animation == ANIM_BAWA and not _animasi.is_playing():
		_animasi.play(ANIM_BAWA)




static func _warnai_payung(payung: Node, warna: Color) -> void :
	for mi: MeshInstance3D in GameState.cari_anak(payung, "MeshInstance3D"):
		var asli: = mi.mesh.surface_get_material(0) as StandardMaterial3D
		if asli == null:
			continue
		var m: = ShaderMaterial.new()
		m.shader = SHADER_PAYUNG
		m.set_shader_parameter("tekstur", asli.albedo_texture)
		m.set_shader_parameter("warna", Color(warna, 1.0))
		mi.material_override = m





var _ransel: BoneAttachment3D = null

func pasang_ransel(warna: = Color(0.16, 0.24, 0.4)) -> void :
	if _ransel != null or _model == null:
		return
	var kerangka: Array = _kerangka_model()
	if kerangka.is_empty():
		return
	var sk: Skeleton3D = kerangka[0]
	var i_pinggang: = sk.find_bone("mixamorig_Spine")
	var i_dada: = sk.find_bone("mixamorig_Spine2")
	var i_leher: = sk.find_bone("mixamorig_Neck")
	var i_kiri: = sk.find_bone("mixamorig_LeftShoulder")
	var i_kanan: = sk.find_bone("mixamorig_RightShoulder")
	if i_pinggang < 0 or i_dada < 0 or i_leher < 0 or i_kiri < 0 or i_kanan < 0:
		return
	var p_pinggang: = sk.get_bone_global_rest(i_pinggang).origin
	var p_leher: = sk.get_bone_global_rest(i_leher).origin
	var panjang: = p_pinggang.distance_to(p_leher)
	var atas: = (p_leher - p_pinggang).normalized()
	var kanan: = (sk.get_bone_global_rest(i_kanan).origin - sk.get_bone_global_rest(i_kiri).origin).normalized()

	var depan: = atas.cross(kanan).normalized()
	kanan = atas.cross(depan).normalized()
	_ransel = BoneAttachment3D.new()
	_ransel.bone_name = "mixamorig_Spine2"
	sk.add_child(_ransel)

	var rest_dada: = sk.get_bone_global_rest(i_dada)
	var ke_tulang: = rest_dada.affine_inverse()
	var arah: = Basis(kanan, atas, depan)
	var bahan: = StandardMaterial3D.new()
	bahan.albedo_color = warna
	bahan.roughness = 0.85
	var bahan_tepi: = StandardMaterial3D.new()
	bahan_tepi.albedo_color = warna.darkened(0.35)
	bahan_tepi.roughness = 0.9
	var pusat_badan: = rest_dada.origin - depan * panjang * 0.36 - atas * panjang * 0.12

	var bagian: = [
		[Vector3(0.78, 0.95, 0.38), Vector3(0, 0, 0), bahan], 
		[Vector3(0.6, 0.38, 0.14), Vector3(0, -0.18, -0.24), bahan_tepi], 
		[Vector3(0.7, 0.16, 0.4), Vector3(0, 0.5, 0.0), bahan_tepi], 
		[Vector3(0.1, 0.9, 0.08), Vector3(-0.3, 0.05, 0.22), bahan_tepi], 
		[Vector3(0.1, 0.9, 0.08), Vector3(0.3, 0.05, 0.22), bahan_tepi], 
	]
	for b in bagian:
		var mi: = MeshInstance3D.new()
		var kotak: = BoxMesh.new()
		kotak.size = (b[0] as Vector3) * panjang
		kotak.material = b[2]
		mi.mesh = kotak
		var geser: Vector3 = b[1]
		var pos: = pusat_badan + (kanan * geser.x + atas * geser.y + depan * geser.z) * panjang
		mi.transform = ke_tulang * Transform3D(arah, pos)
		_ransel.add_child(mi)






var _perban: Array = []
var _letak_perban: Array = []


const BENTUK_PERBAN: = {
	"kaki_kiri": ["mixamorig_LeftLeg", "mixamorig_LeftFoot", 0.235, 0.22, 0.55], 
	"kaki_kanan": ["mixamorig_RightLeg", "mixamorig_RightFoot", 0.235, 0.22, 0.55], 
	"lengan_kiri": ["mixamorig_LeftForeArm", "mixamorig_LeftHand", 0.17, 0.3, 0.5], 
	"lengan_kanan": ["mixamorig_RightForeArm", "mixamorig_RightHand", 0.17, 0.3, 0.5], 
	"kepala": ["mixamorig_Head", "mixamorig_HeadTop_End", 0.46, 0.17, 0.7], 
}

func atur_perban(letak: Array) -> void :
	if _model == null or letak == _letak_perban:
		return
	for p in _perban:
		if is_instance_valid(p):
			p.queue_free()
	_perban.clear()
	_letak_perban = letak.duplicate()
	if letak.is_empty():
		return
	var kerangka: Array = _kerangka_model()
	if kerangka.is_empty():
		_letak_perban = []
		return
	var sk: Skeleton3D = kerangka[0]
	var bahan: = StandardMaterial3D.new()
	bahan.albedo_color = Color(0.96, 0.95, 0.9)
	bahan.roughness = 0.9
	for nama in letak:
		if not BENTUK_PERBAN.has(nama):
			continue
		var b: Array = BENTUK_PERBAN[nama]
		var i_pangkal: = sk.find_bone(b[0])
		var i_ujung: = sk.find_bone(b[1])
		if i_pangkal < 0 or i_ujung < 0:
			continue
		var panjang: = sk.get_bone_global_rest(i_pangkal).origin.distance_to(sk.get_bone_global_rest(i_ujung).origin)
		var tempel: = BoneAttachment3D.new()
		tempel.bone_name = b[0]
		sk.add_child(tempel)
		_perban.append(tempel)

		for n in 2:
			var mi: = MeshInstance3D.new()
			var silinder: = CylinderMesh.new()
			var jari: float = b[2] * (1.0 if n == 0 else 1.06)
			silinder.top_radius = panjang * jari
			silinder.bottom_radius = panjang * jari * 0.94
			silinder.height = panjang * b[3] * (1.0 if n == 0 else 0.55)
			silinder.radial_segments = 16
			silinder.material = bahan
			mi.mesh = silinder
			mi.position = Vector3(0, panjang * (b[4] if n == 0 else b[4] - b[3] * 0.4), 0)
			tempel.add_child(mi)
