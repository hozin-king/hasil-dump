extends RefCounted
class_name WarnaProyeksi








const AMBANG_LATAR: = 0.9




static func warnai(mi: MeshInstance3D, gambar: Image, warna_tonjolan_belakang = null) -> void :
	gambar = gambar.duplicate()
	gambar.convert(Image.FORMAT_RGBA8)
	var kotak: = _isi_latar_dengan_warna_tetangga(gambar)

	var warna_rambut: = gambar.get_pixel(kotak.position.x + kotak.size.x / 2, kotak.position.y + int(kotak.size.y * 0.015))
	var lama: Mesh = mi.mesh
	var baru: = ArrayMesh.new()

	var batas: = lama.get_aabb()
	for s in lama.get_surface_count():
		var a: = lama.surface_get_arrays(s)
		var titik: PackedVector3Array = a[Mesh.ARRAY_VERTEX]

		var z_kepala: = 0.0
		var n_kepala: = 0
		for p in titik:
			if 1.0 - (p.y - batas.position.y) / batas.size.y < 0.17:
				z_kepala += p.z
				n_kepala += 1
		z_kepala = z_kepala / maxi(n_kepala, 1)
		var warna: = PackedColorArray()
		warna.resize(titik.size())

		var z_belakang: = batas.position.z + batas.size.z * 0.28
		for i in titik.size():
			var p: = titik[i]
			var u: = (p.x - batas.position.x) / batas.size.x
			var v: = 1.0 - (p.y - batas.position.y) / batas.size.y
			var px: = int(clampf(kotak.position.x + u * kotak.size.x, 0, gambar.get_width() - 1))
			var py: = int(clampf(kotak.position.y + v * kotak.size.y, 0, gambar.get_height() - 1))
			var c: = gambar.get_pixel(px, py)
			if warna_tonjolan_belakang != null and p.z < z_belakang and v > 0.18 and v < 0.6:
				c = warna_tonjolan_belakang

			elif v < 0.17 and p.z < z_kepala - 0.01:
				c = warna_rambut
			warna[i] = c
		a[Mesh.ARRAY_COLOR] = warna
		var bentuk: Mesh.PrimitiveType = lama.surface_get_primitive_type(s)

		var bendera: = 0
		if a[Mesh.ARRAY_WEIGHTS] != null and a[Mesh.ARRAY_WEIGHTS].size() == titik.size() * 8:
			bendera = Mesh.ARRAY_FLAG_USE_8_BONE_WEIGHTS
		baru.add_surface_from_arrays(bentuk, a, [], {}, bendera)
		var bahan: = StandardMaterial3D.new()
		bahan.vertex_color_use_as_albedo = true
		bahan.vertex_color_is_srgb = true
		bahan.roughness = 0.85
		baru.surface_set_material(s, bahan)
	mi.mesh = baru




static func _isi_latar_dengan_warna_tetangga(g: Image) -> Rect2i:
	var w: = g.get_width()
	var h: = g.get_height()
	var latar: = PackedByteArray();latar.resize(w * h)
	var tumpuk: = []
	for x in w:
		tumpuk.append(x);tumpuk.append((h - 1) * w + x)
	for y in h:
		tumpuk.append(y * w);tumpuk.append(y * w + w - 1)
	while tumpuk.size() > 0:
		var p: int = tumpuk.pop_back()
		if latar[p] == 1:
			continue
		var c: = g.get_pixel(p % w, p / w)
		if minf(c.r, minf(c.g, c.b)) < AMBANG_LATAR:
			continue
		latar[p] = 1
		var px: = p % w
		if px > 0: tumpuk.append(p - 1)
		if px < w - 1: tumpuk.append(p + 1)
		if p >= w: tumpuk.append(p - w)
		if p < (h - 1) * w: tumpuk.append(p + w)
	var kotak: = Rect2i()
	var ada: = false
	for y in h:
		for x in w:
			if latar[y * w + x] == 0:
				kotak = Rect2i(x, y, 1, 1) if not ada else kotak.merge(Rect2i(x, y, 1, 1))
				ada = true

	for ulang in 28:
		var baru: = latar.duplicate()
		for y in range(1, h - 1):
			for x in range(1, w - 1):
				var i: = y * w + x
				if latar[i] == 0:
					continue
				for t in [i - 1, i + 1, i - w, i + w]:
					if latar[t] == 0:
						g.set_pixel(x, y, g.get_pixel(t % w, t / w))
						baru[i] = 0
						break
		latar = baru
	return kotak
