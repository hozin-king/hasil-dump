extends "res://scripts/objek3d.gd"












const MODEL: = {
	"angkot": {"file": "res://assets/kendaraan/angkot.glb", "panjang_m": 4.3}, 
	"bak": {"file": "res://assets/kendaraan/mobil_bak.glb", "panjang_m": 4.0}, 
	"mobil": {"file": "res://assets/kendaraan/mobil.glb", "panjang_m": 4.2, "tinggi_per_panjang": 0.41, "jari_roda": 0.18}, 

	"motor": {"file": "res://assets/kendaraan/motor.glb", "panjang_m": 1.9, "tinggi_per_panjang": 0.754, "jari_roda": 0.18, "roda_tengah": true, "asap": 0.35}, 
}
const TINGGI_PER_PANJANG: = 0.49
const JARI_RODA: = 0.155


static var _cache_roda: = {}

var jenis: = ""
var ke_kanan: = true
var kecepatan: = 0.0
var jarak: = 0.0
var lajur: Array[Vector2] = []

var _ppm: = 100.0
var _roda: Array[MeshInstance3D] = []
var _jari_dunia: = 0.3
var _posisi_lalu: = Vector2.INF
var _diam_frame: = 0
var _offset_dasar: = Vector2.ZERO
var _asap: CPUParticles2D
var _lampu: Array[Sprite2D] = []





func siapkan(jenis_kendaraan: String, ppm: float, arah_kanan: bool, hadap_derajat: = NAN) -> bool:
	jenis = jenis_kendaraan
	ke_kanan = arah_kanan
	_ppm = ppm
	var m: Dictionary = MODEL[jenis]
	var tinggi: = float(m["panjang_m"]) * float(m.get("tinggi_per_panjang", TINGGI_PER_PANJANG))
	if not pasang(String(m["file"]), tinggi, ppm, {"hadap": hadap_derajat if not is_nan(hadap_derajat) else (135.0 if arah_kanan else -45.0), "resolusi": 768}):
		return false
	_bergerak = true
	_offset_dasar = offset
	var mi: = _cari_mesh(_model)
	if mi != null:
		_pisah_roda(mi)
		var aabb: = mi.mesh.get_aabb()
		_pasang_asap(mi, aabb)
		_pasang_lampu(mi, aabb)
	return true


func _process(delta: float) -> void :
	super (delta)
	if _viewport == null or delta <= 0.0:
		return

	var v: = 0.0
	if _posisi_lalu != Vector2.INF:
		v = position.distance_to(_posisi_lalu) / delta
	_posisi_lalu = position
	var melaju: = v > 1.0
	if melaju:
		var putar: = (v / _ppm) / maxf(_jari_dunia, 0.05) * delta
		for r in _roda:
			r.rotation.z += putar
		_diam_frame = 0
	else:
		_diam_frame += 1

	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS if (melaju or _diam_frame < 4) else SubViewport.UPDATE_DISABLED

	var getar: = (0.9 if not melaju else 0.5) / scale.x
	offset = _offset_dasar + Vector2(0, sin(_waktu * 55.0) * getar)
	var malam: = GameState.malam_hari()
	for l in _lampu:
		l.visible = malam


func _cari_mesh(node: Node) -> MeshInstance3D:
	if node is MeshInstance3D:
		return node
	for anak in node.get_children():
		var m: = _cari_mesh(anak)
		if m != null:
			return m
	return null


func _pisah_roda(mi: MeshInstance3D) -> void :
	if not _cache_roda.has(jenis):
		_cache_roda[jenis] = _hitung_roda(mi.mesh)
	var c: Dictionary = _cache_roda[jenis]
	if c.is_empty():
		return
	mi.mesh = c["badan"]
	for r in c["roda"]:
		var w: = MeshInstance3D.new()
		w.mesh = r[0]
		w.position = r[1]
		mi.add_child(w)
		_roda.append(w)
	_jari_dunia = float(c["jari"]) * _model.scale.y * mi.transform.basis.get_scale().y




func _hitung_roda(mesh: Mesh) -> Dictionary:
	var mdt: = MeshDataTool.new()
	if mesh == null or mdt.create_from_surface(mesh as ArrayMesh, 0) != OK:
		return {}
	var aabb: = mesh.get_aabb()
	var ymin: = aabb.position.y
	var tinggi: = aabb.size.y
	var tengah: = aabb.get_center()
	var m: Dictionary = MODEL[jenis]
	var jari: = tinggi * float(m.get("jari_roda", JARI_RODA))
	var roda_tengah: = bool(m.get("roda_tengah", false))

	var jumlah: = [0.0, 0.0]
	var banyak: = [0, 0]
	for i in mdt.get_vertex_count():
		var p: = mdt.get_vertex(i)
		if p.y < ymin + tinggi * 0.02:
			var sisi: = 0 if p.x < tengah.x else 1
			jumlah[sisi] += p.x
			banyak[sisi] += 1
	if banyak[0] == 0 or banyak[1] == 0:
		return {}
	var poros: = [jumlah[0] / banyak[0], jumlah[1] / banyak[1]]
	var y_poros: = ymin + jari
	var bahan: = mesh.surface_get_material(0)
	var st_badan: = SurfaceTool.new()
	st_badan.begin(Mesh.PRIMITIVE_TRIANGLES)
	st_badan.set_material(bahan)
	var st_roda: Array[SurfaceTool] = []
	for i in 4:
		var st: = SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		st.set_material(bahan)
		st_roda.append(st)
	var pusat: Array[Vector3] = []
	for i in 4:
		pusat.append(Vector3(poros[i / 2], y_poros, 0.0))
	var isi: = [0, 0, 0, 0]
	for f in mdt.get_face_count():
		var c: = Vector3.ZERO
		for k in 3:
			c += mdt.get_vertex(mdt.get_face_vertex(f, k))
		c /= 3.0
		var roda: = -1

		var di_roda: = absf(c.z - tengah.z) < aabb.size.z * 0.12 if roda_tengah else absf(c.z - tengah.z) > aabb.size.z * 0.28
		if di_roda:
			for a in 2:

				var masuk: = true
				for k in 3:
					var p: = mdt.get_vertex(mdt.get_face_vertex(f, k))
					if Vector2(p.x - poros[a], p.y - y_poros).length() > jari * 1.1:
						masuk = false
				if masuk:
					roda = a * 2 + (0 if c.z < tengah.z else 1)
		var st: SurfaceTool = st_badan if roda < 0 else st_roda[roda]
		var geser: = Vector3.ZERO if roda < 0 else pusat[roda]
		if roda >= 0:
			isi[roda] += 1
		for k in 3:
			var v: = mdt.get_face_vertex(f, k)
			st.set_normal(mdt.get_vertex_normal(v))
			st.set_uv(mdt.get_vertex_uv(v))
			st.add_vertex(mdt.get_vertex(v) - geser)
	var hasil: = {"badan": st_badan.commit(), "roda": [], "jari": jari}
	for i in 4:
		if isi[i] > 0:
			hasil["roda"].append([st_roda[i].commit(), pusat[i]])
	return hasil



func _ke_gambar(mi: MeshInstance3D, p: Vector3) -> Vector2:
	var dunia: = mi.global_transform * p
	return kamera3d.unproject_position(dunia) - Vector2(_vp, _vp) / 2.0 + _offset_dasar



func _pasang_asap(mi: MeshInstance3D, aabb: AABB) -> void :
	_asap = CPUParticles2D.new()
	_asap.position = _ke_gambar(mi, Vector3(aabb.end.x, aabb.position.y + aabb.size.y * 0.12, aabb.position.z + aabb.size.z * 0.3))
	_asap.amount = 14
	_asap.lifetime = 1.4
	_asap.preprocess = 1.0
	_asap.local_coords = false
	_asap.direction = Vector2(0, -1)
	_asap.spread = 25.0
	var s: = scale.x if scale.x > 0.0 else 1.0
	_asap.initial_velocity_min = 8.0 / s
	_asap.initial_velocity_max = 16.0 / s
	_asap.gravity = Vector2(0, -6.0 / s)
	var besar_asap: = float(MODEL[jenis].get("asap", 1.0))
	_asap.scale_amount_min = 3.0 * besar_asap / s
	_asap.scale_amount_max = 5.0 * besar_asap / s
	var besar: = Curve.new()
	besar.add_point(Vector2(0, 0.4))
	besar.add_point(Vector2(1, 1.6))
	_asap.scale_amount_curve = besar
	var warna: = Gradient.new()
	warna.set_color(0, Color(0.75, 0.75, 0.75, 0.45))
	warna.set_color(1, Color(0.85, 0.85, 0.85, 0.0))
	_asap.color_ramp = warna
	if GameState.google_play_pc():

		_asap.color_ramp = null
		_asap.material = GameState.bahan_partikel(Color(0.8, 0.8, 0.8, 0.3))
		var besar_pc: = Curve.new()
		besar_pc.add_point(Vector2(0, 0.4))
		besar_pc.add_point(Vector2(0.8, 1.4))
		besar_pc.add_point(Vector2(1, 0.2))
		_asap.scale_amount_curve = besar_pc
	_asap.texture = _tekstur_bulat()
	add_child(_asap)



func _pasang_lampu(mi: MeshInstance3D, aabb: AABB) -> void :
	var s: = scale.x if scale.x > 0.0 else 1.0
	var posisi_z: = [aabb.get_center().z] if bool(MODEL[jenis].get("roda_tengah", false)) else [aabb.position.z + aabb.size.z * 0.2, aabb.end.z - aabb.size.z * 0.2]
	for z in posisi_z:
		var l: = Sprite2D.new()
		l.texture = _tekstur_bulat()
		l.position = _ke_gambar(mi, Vector3(aabb.position.x, aabb.position.y + aabb.size.y * 0.32, z))
		l.scale = Vector2.ONE * (34.0 / s) / 64.0
		l.modulate = Color(1.0, 0.92, 0.6, 0.9)
		var bahan: = CanvasItemMaterial.new()
		bahan.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		bahan.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
		l.material = bahan
		l.visible = false
		add_child(l)
		_lampu.append(l)


static var _bulat: Texture2D = null

static func _tekstur_bulat() -> Texture2D:
	if _bulat == null:
		var g: = Gradient.new()
		g.set_color(0, Color(1, 1, 1, 1))
		g.set_color(1, Color(1, 1, 1, 0))
		var t: = GradientTexture2D.new()
		t.gradient = g
		t.fill = GradientTexture2D.FILL_RADIAL
		t.fill_from = Vector2(0.5, 0.5)
		t.fill_to = Vector2(1.0, 0.5)
		t.width = 64
		t.height = 64
		_bulat = t
	return _bulat



func atur_kabur(jari: float) -> void :
	var bahan: = ShaderMaterial.new()
	bahan.shader = preload("res://shader/kabur_ringan.gdshader")
	bahan.set_shader_parameter("jari", jari)
	material = bahan



func titik_lajur(d: float) -> Vector2:
	for i in lajur.size() - 1:
		var panjang: = lajur[i].distance_to(lajur[i + 1])
		if d <= panjang or i == lajur.size() - 2:
			return lajur[i].lerp(lajur[i + 1], clampf(d / maxf(panjang, 0.01), 0.0, 1.0))
		d -= panjang
	return lajur[0]


func panjang_lajur() -> float:
	var total: = 0.0
	for i in lajur.size() - 1:
		total += lajur[i].distance_to(lajur[i + 1])
	return total
