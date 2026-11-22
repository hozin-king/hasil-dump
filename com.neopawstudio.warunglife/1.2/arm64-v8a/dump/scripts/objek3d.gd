extends Sprite2D













const SUDUT_KAMERA: = 25.0
const UKURAN_VIEWPORT: = 512

var _viewport: SubViewport
var _model: Node3D
var _gerak: = ""
var _waktu: = 0.0
var _dasar: = Vector2.ZERO
var _sudut_dasar: = 0.0
var _lampu_kedip: Polygon2D = null
var _frame_render: = 0
var _bergerak: = false
var kamera3d: Camera3D = null
var _vp: = UKURAN_VIEWPORT




func pasang(file: String, tinggi_m: float, ppm: float, cfg: Dictionary) -> bool:

	var model: Node3D = null
	if ResourceLoader.exists(file):
		var adegan = load(file)
		if adegan is PackedScene:
			model = (adegan as PackedScene).instantiate()
	if model == null and cfg.has("cadangan"):
		model = _rakit_cadangan(cfg["cadangan"])
	if model == null:
		return false
	_gerak = String(cfg.get("gerak", ""))
	_vp = int(cfg.get("resolusi", UKURAN_VIEWPORT))
	_dasar = position
	_viewport = SubViewport.new()
	_viewport.size = Vector2i(_vp, _vp)
	_viewport.transparent_bg = true
	_viewport.own_world_3d = true
	_viewport.msaa_3d = GameState.msaa_3d()
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(_viewport)
	_siapkan_dunia()
	_model = model
	_viewport.add_child(_model)


	var kotak: = _ukur(_model, Transform3D.IDENTITY)
	var skala: = tinggi_m / maxf(kotak.size.y, 0.001)

	var lebar: = float(cfg.get("lebar", 1.0))
	_model.scale = Vector3(skala * lebar, skala, skala)
	var tengah: = kotak.get_center()
	_model.position = - Vector3(tengah.x * lebar, kotak.position.y, tengah.z) * skala
	_model.rotation.y = deg_to_rad(float(cfg.get("hadap", 0.0)))
	_sudut_dasar = _model.rotation.y
	var ukuran_m: = maxf(maxf(kotak.size.x * lebar, kotak.size.z) * skala, tinggi_m)

	var kamera: = Camera3D.new()
	kamera3d = kamera
	kamera.projection = Camera3D.PROJECTION_ORTHOGONAL
	kamera.size = ukuran_m * 1.7
	var sudut: = deg_to_rad(float(cfg.get("sudut_kamera", SUDUT_KAMERA)))
	kamera.position = Vector3(0, tinggi_m / 2.0, 0) + Vector3(0, sin(sudut), cos(sudut)) * 8.0
	kamera.rotation.x = - sudut
	_viewport.add_child(kamera)

	texture = _viewport.get_texture()
	centered = true

	var kaki: = kamera.unproject_position(Vector3.ZERO)
	offset = Vector2(_vp, _vp) / 2.0 - kaki
	offset.y -= float(cfg.get("angkat", 0.0)) / maxf(ppm * kamera.size / _vp, 0.001)
	var s: = ppm * kamera.size / _vp
	scale = Vector2(s, s)


	var anim: = _cari_animasi(_model)
	if anim != null and anim.get_animation_list().size() > 0:
		var nama: String = anim.get_animation_list()[0]
		anim.get_animation(nama).loop_mode = Animation.LOOP_LINEAR
		anim.play(nama)
		_bergerak = true
	if _gerak == "goyang":
		_bergerak = true
	if _gerak == "kedip":
		_lampu_kedip = Polygon2D.new()
		var titik: = PackedVector2Array()

		for i in 12:
			titik.append(Vector2.from_angle(TAU * i / 12.0) * 3.0 / s)
		_lampu_kedip.polygon = titik
		_lampu_kedip.color = Color(1.0, 0.15, 0.1)

		var atas: = kamera.unproject_position(Vector3(0, tinggi_m * 0.8, 0))
		_lampu_kedip.position = atas - Vector2(_vp, _vp) / 2.0 + offset
		add_child(_lampu_kedip)
	return true





const SHADER_POTONG: = "shader_type canvas_item;\nuniform vec2 a;\nuniform vec2 b;\nuniform float sisi = 1.0;\nvarying vec2 v_lokal;\nvoid vertex() { v_lokal = VERTEX; }\nvoid fragment() {\n\tvec2 d = b - a;\n\tfloat s = d.x * (v_lokal.y - a.y) - d.y * (v_lokal.x - a.x);\n\tif (s * sisi > 0.0) { discard; }\n}\n"

func potong(a_induk: Vector2, b_induk: Vector2, sisi: = 1.0) -> void :
	var balik: = get_transform().affine_inverse()
	var bahan: = ShaderMaterial.new()
	bahan.shader = Shader.new()
	bahan.shader.code = SHADER_POTONG
	bahan.set_shader_parameter("a", balik * a_induk)
	bahan.set_shader_parameter("b", balik * b_induk)
	bahan.set_shader_parameter("sisi", sisi)
	material = bahan


func _process(delta: float) -> void :
	if _viewport == null:
		return
	_waktu += delta

	if not _bergerak:
		_frame_render += 1
		if _frame_render == 4:
			_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	match _gerak:
		"goyang":
			_model.rotation.y = _sudut_dasar + sin(_waktu * 1.1) * 0.6
		"denyut":
			scale.y = scale.x * (1.0 + absf(sin(_waktu * 7.0)) * 0.025)
		"getar":
			position = _dasar + Vector2(randf_range(-0.6, 0.6), randf_range(-0.4, 0.4))
		"kedip":
			if _lampu_kedip != null:
				_lampu_kedip.visible = fmod(_waktu, 1.2) < 0.5


func _siapkan_dunia() -> void :
	var lingkungan: = Environment.new()
	lingkungan.background_mode = Environment.BG_CLEAR_COLOR
	lingkungan.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	lingkungan.ambient_light_color = Color(0.85, 0.72, 0.62)
	lingkungan.ambient_light_energy = 0.5
	lingkungan.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	var dunia: = WorldEnvironment.new()
	dunia.environment = lingkungan
	_viewport.add_child(dunia)

	var lampu: = DirectionalLight3D.new()
	lampu.light_color = Color(1.0, 0.82, 0.6)
	lampu.light_energy = 1.15
	lampu.rotation = Vector3(deg_to_rad(-45), deg_to_rad(-35), 0)
	_viewport.add_child(lampu)
	var isi: = DirectionalLight3D.new()
	isi.light_color = Color(0.55, 0.6, 0.85)
	isi.light_energy = 0.3
	isi.rotation = Vector3(deg_to_rad(-20), deg_to_rad(150), 0)
	_viewport.add_child(isi)



func _ukur(node: Node, t: Transform3D) -> AABB:
	var hasil: = AABB()
	var ada: = false
	var t_ini: = t
	if node is Node3D and node != _model:
		t_ini = t * (node as Node3D).transform
	if node is MeshInstance3D and (node as MeshInstance3D).mesh != null:
		hasil = t_ini * (node as MeshInstance3D).get_aabb()
		ada = true
	for anak in node.get_children():
		var k: = _ukur(anak, t_ini)
		if k.size != Vector3.ZERO:
			hasil = k if not ada else hasil.merge(k)
			ada = true
	return hasil




func _rakit_cadangan(daftar: Array) -> Node3D:
	var akar: = Node3D.new()
	for b in daftar:
		var m: = MeshInstance3D.new()
		var kotak: = BoxMesh.new()
		kotak.size = Vector3(b[0][0], b[0][1], b[0][2])
		var bahan: = StandardMaterial3D.new()
		bahan.albedo_color = Color(String(b[2]))
		bahan.roughness = 0.8
		if b.size() > 3:
			bahan.albedo_color.a = 1.0 - float(b[3])
			bahan.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			bahan.roughness = 0.1
		kotak.material = bahan
		m.mesh = kotak
		m.position = Vector3(b[1][0], b[1][1], b[1][2])
		akar.add_child(m)
	return akar


func _cari_animasi(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node
	for anak in node.get_children():
		var a: = _cari_animasi(anak)
		if a != null:
			return a
	return null
