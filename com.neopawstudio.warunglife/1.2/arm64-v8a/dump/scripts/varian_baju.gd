class_name VarianBaju





const FILE: = "res://data/varian_npc.json"
const SHADER: = preload("res://shader/varian_baju.gdshader")


const PAKAI_SHADER: = true
const BOBOT_BAWAAN: = 0.6

static var _data: = {}
static var _sifat: = {}
static var _wajah: = {}
static var _bahan: = {}


static func data() -> Dictionary:
	if _data.is_empty():
		_data = JSON.parse_string(FileAccess.get_file_as_string(FILE))
		for asal in _data["varian"]:
			for v in _data["varian"][asal]:
				_wajah[String(v["id"])] = asal
				_sifat[String(v["id"])] = String(v.get("sifat", asal))
	return _data



static func sifat(tipe: String) -> String:
	data()
	return String(_sifat.get(tipe, tipe))



static func wajah(tipe: String) -> String:
	data()
	return String(_wajah.get(tipe, tipe))


static func _cari(tipe: String) -> Dictionary:
	for asal in data()["varian"]:
		for v in data()["varian"][asal]:
			if String(v["id"]) == tipe:
				return v
	return {}


static func ada(tipe: String) -> bool:
	return not _cari(tipe).is_empty()




static func nama_catatan(tipe: String) -> String:
	var v: = _cari(tipe)
	if v.has("nama_warga"):
		return String(v["nama_warga"])
	return "Warga (%s)" % String(v.get("ciri", v.get("nama", "pembeli"))).to_lower()




static func obrolan(tipe: String, hujan: = false) -> Array:
	var kelompok: = wajah(tipe)
	var semua: Dictionary = data().get("obrolan", {}).get(kelompok, {})
	return (semua.get("hujan" if hujan else "biasa", []) as Array).duplicate()



static func nama_ulasan(tipe: String) -> String:
	return nama_catatan(tipe) if ada(tipe) else ""



static func tanpa_akrab(tipe: String) -> bool:
	var v: = _cari(tipe)
	return not v.is_empty() and not bool(v.get("akrab", false))




static func gabung(data_pelanggan: Dictionary) -> void :
	var menurut_id: = {}
	for p in data_pelanggan["pelanggan"]:
		menurut_id[String(p["id"])] = p
	var tokoh: Dictionary = data_pelanggan.get("tokoh", {})
	for asal in data()["varian"]:
		for v in data()["varian"][asal]:
			if menurut_id.has(String(v["id"])):
				continue
			var dasar_sifat: Dictionary = menurut_id.get(String(v.get("sifat", asal)), {})
			var dasar_model: Dictionary = menurut_id.get(asal, tokoh.get(asal, {}))
			if dasar_sifat.is_empty() or not dasar_model.has("model3d"):
				continue
			var baru: Dictionary = dasar_sifat.duplicate(true)
			baru.erase("berpasangan")


			baru.erase("tidak_boleh_beli")
			if v.has("tidak_boleh_beli"):
				baru["tidak_boleh_beli"] = v["tidak_boleh_beli"]
			baru["id"] = String(v["id"])
			baru["nama"] = String(v["nama"])
			baru["bobot"] = float(v.get("bobot", BOBOT_BAWAAN))
			var model: Dictionary = (dasar_model["model3d"] as Dictionary).duplicate(true)
			if v.has("skala"):
				model["skala"] = float(v["skala"])
			model["varian_baju"] = v
			baru["model3d"] = model
			data_pelanggan["pelanggan"].append(baru)



static func pasang(model: Node3D, v: Dictionary) -> void :
	if not PAKAI_SHADER:
		return


	if GameState.gpu_powervr():
		return
	for mi: MeshInstance3D in GameState.cari_anak(model, "MeshInstance3D"):
		mi.mesh = _mesh_bertanda(mi.mesh)
		for s in mi.mesh.get_surface_count():
			var asli: = mi.mesh.surface_get_material(s) as StandardMaterial3D
			if asli == null or asli.albedo_texture == null:
				continue
			var kunci: = "%s|%s|%d" % [v["id"], mi.mesh.resource_path, s]
			if not _bahan.has(kunci):
				_bahan[kunci] = _buat_bahan(asli, mi.mesh.get_aabb().end.y, v)
			mi.set_surface_override_material(s, _bahan[kunci])





static var _mesh_cache: = {}

static func _mesh_bertanda(asli: Mesh) -> Mesh:
	var kunci: = asli.resource_path if asli.resource_path != "" else str(asli.get_instance_id())
	if _mesh_cache.has(kunci):
		return _mesh_cache[kunci]
	var am: = asli as ArrayMesh
	if am == null:
		return asli
	var tinggi: = am.get_aabb().end.y
	var baru: = ArrayMesh.new()
	for s in am.get_surface_count():
		var arr: = am.surface_get_arrays(s)
		var pos: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
		var tanda: = PackedFloat32Array()
		tanda.resize(pos.size() * 4)
		for i in pos.size():
			tanda[i * 4] = pos[i].x
			tanda[i * 4 + 1] = pos[i].y / tinggi
			tanda[i * 4 + 2] = pos[i].z
			tanda[i * 4 + 3] = 1.0
		arr[Mesh.ARRAY_CUSTOM0] = tanda
		var format: = am.surface_get_format(s)
		var bendera: = (Mesh.ARRAY_CUSTOM_RGBA_FLOAT << Mesh.ARRAY_FORMAT_CUSTOM0_SHIFT)
		if format & Mesh.ARRAY_FLAG_USE_8_BONE_WEIGHTS:
			bendera |= Mesh.ARRAY_FLAG_USE_8_BONE_WEIGHTS
		baru.add_surface_from_arrays(am.surface_get_primitive_type(s), arr, [], {}, bendera)
		baru.surface_set_material(s, am.surface_get_material(s))
		baru.surface_set_name(s, am.surface_get_name(s))
	_mesh_cache[kunci] = baru
	return baru


static func _buat_bahan(asli: StandardMaterial3D, tinggi: float, v: Dictionary) -> ShaderMaterial:
	var sm: = ShaderMaterial.new()
	sm.shader = SHADER
	sm.set_shader_parameter("tex_albedo", asli.albedo_texture)
	if asli.normal_enabled and asli.normal_texture != null:
		sm.set_shader_parameter("tex_normal", asli.normal_texture)
		sm.set_shader_parameter("ada_normal", true)
	if asli.roughness_texture != null:
		sm.set_shader_parameter("tex_orm", asli.roughness_texture)
		sm.set_shader_parameter("ada_orm", true)
	sm.set_shader_parameter("tinggi_model", tinggi)
	if v.has("kecuali"):
		var k: Array = v["kecuali"]
		sm.set_shader_parameter("kecuali_min", Vector3(k[0][0], k[0][1], k[0][2]))
		sm.set_shader_parameter("kecuali_maks", Vector3(k[1][0], k[1][1], k[1][2]))
	var bagian: Array = v["bagian"]
	sm.set_shader_parameter("jumlah", mini(bagian.size(), 3))
	for i in mini(bagian.size(), 3):
		var b: Dictionary = bagian[i]
		var n: = str(i + 1)
		sm.set_shader_parameter("y_" + n, Vector2(b["y"][0], b["y"][1]))
		sm.set_shader_parameter("pilih_" + n, Vector4(b["pilih"][0], b["pilih"][1], b["pilih"][2], b["pilih"][3]))
		sm.set_shader_parameter("v_" + n, Vector2(b["v"][0], b["v"][1]))
		sm.set_shader_parameter("warna_" + n, Color.html(String(b["warna"])))
		sm.set_shader_parameter("atur_" + n, Vector3(b["atur"][0], b["atur"][1], b["atur"][2]))
		sm.set_shader_parameter("mode_" + n, int(b["mode"]))
	return sm
