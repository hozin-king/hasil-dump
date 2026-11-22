extends SkeletonModifier3D















var berjalan: = false
var berlari: = false
var dipeluk: = false

var tua: = false


var laju_tanah: = -1.0

const PINGGUL: = "Bone_000"
const PANGGUL: = "Bone_024"
const PUNGGUNG: = "Bone_022"
const BAHU: = "Bone_020"
const LEHER: = "Bone_029"
const KEPALA: = "Bone_028"
const TELINGA: = []
const KAKI_BELAKANG: = [["Bone_007", "Bone_006", "Bone_005", "Bone_004"], ["Bone_013", "Bone_012", "Bone_011", "Bone_010"]]
const KAKI_DEPAN: = [["Bone_035", "Bone_034", "Bone_033", "Bone_032"], ["Bone_041", "Bone_040", "Bone_039", "Bone_038"]]
const EKOR: = ["Bone_019", "Bone_018", "Bone_017", "Bone_016", "Bone_015"]


const SUDUT_DUDUK: = deg_to_rad(31.0)
const TURUN_DUDUK: = 0.36
const PUSAT_PUTAR: = Vector3(0.0, 0.0, 0.05)
const LANGKAH_JALAN: = 7.0
const LANGKAH_LARI: = 15.0

const PILIHAN_TOLEH: = [0.0, 0.0, 0.0, 0.0, 30.0, -30.0, 55.0, -55.0]

var _waktu: = 0.0
var _keadaan: = "duduk"
var _sisa: = 3.0
var _duduk: = 1.0
var _putar: = 0.0
var _putar_target: = 0.0
var _toleh: = 0.0
var _toleh_target: = 0.0
var _angguk: = 0.0
var _angguk_target: = 0.0
var _sisa_toleh: = 1.5
var _kedut: = 0.0
var _sisa_kedut: = 2.0
var _langkah: = 0.0
var _jalan: = 0.0
var _lari: = 0.0


func _ready() -> void :
	_sisa = randf_range(2.0, 5.0)
	if dipeluk:
		_duduk = 0.0


func _process_modification() -> void :
	var sk: = get_skeleton()
	if sk == null:
		return
	var dt: = get_process_delta_time() if is_inside_tree() else 0.016
	_perbarui_keadaan(dt)
	for i in sk.get_bone_count():
		sk.set_bone_pose(i, sk.get_bone_rest(i))
	var atas: = Vector3.UP
	var depan: = _depan_model(sk)
	var kanan: = atas.cross(depan).normalized()
	var duduk: = smoothstep(0.0, 1.0, _duduk)
	var jalan: = _jalan * (1.0 - _lari)
	var lari: = _jalan * _lari

	var i0: = sk.find_bone(PINGGUL)
	if i0 >= 0:
		var r: = Basis(atas, _putar)
		var asal: = sk.get_bone_rest(i0).origin
		var o: = PUSAT_PUTAR + r * (asal - PUSAT_PUTAR)
		o.y = asal.y - TURUN_DUDUK * duduk + absf(sin(_langkah)) * 0.015 * jalan + sin(_langkah) * 0.06 * lari
		sk.set_bone_pose_position(i0, o)
		_putar_global(sk, i0, atas, _putar)

		_putar_global(sk, i0, r * depan, sin(_langkah) * deg_to_rad(4.0) * jalan)
		depan = r * depan
		kanan = r * kanan

	_putar_global(sk, sk.find_bone(PANGGUL), kanan, - SUDUT_DUDUK * duduk + sin(_langkah) * deg_to_rad(10.0) * lari)
	var depan_badan: = Basis(kanan, - SUDUT_DUDUK * duduk) * depan

	_putar_global(sk, sk.find_bone(PUNGGUNG), kanan, sin(_waktu * lerpf(2.4, 4.0, _lari)) * deg_to_rad(1.5) - sin(_langkah) * deg_to_rad(8.0) * lari)
	_putar_global(sk, sk.find_bone(PUNGGUNG), atas, sin(_langkah) * deg_to_rad(3.5) * jalan)
	if dipeluk:
		_pose_dipeluk(sk, atas, depan, kanan)
	else:
		_pose_kaki(sk, atas, depan, kanan, duduk, jalan, lari)


	var i_leher: = sk.find_bone(LEHER)
	_putar_global(sk, i_leher, kanan, SUDUT_DUDUK * duduk * 0.8 + sin(_langkah) * deg_to_rad(6.0) * lari)
	_putar_global(sk, i_leher, atas, _toleh * 0.55 - sin(_langkah) * deg_to_rad(3.0) * jalan)
	var i_kepala: = sk.find_bone(KEPALA)
	_putar_global(sk, i_kepala, atas, _toleh * 0.45)
	_putar_global(sk, i_kepala, Basis(atas, _toleh) * kanan, _angguk + absf(sin(_langkah)) * deg_to_rad(2.0) * jalan)

	for n in TELINGA.size():
		_putar_global(sk, sk.find_bone(TELINGA[n]), depan_badan, (1.0 if n == 0 else -1.0) * _kedut * deg_to_rad(18.0))


	if dipeluk:
		_arahkan(sk, EKOR[0], EKOR[1], ( - depan * 0.45 - atas * 0.9).normalized(), 1.0)
	elif lari > 0.01:
		_arahkan(sk, EKOR[0], EKOR[1], ( - depan + atas * 0.15).normalized(), lari)
	var cepat: = lerpf(1.6, 3.0, _jalan)
	for n in EKOR.size():
		var ayun: = sin(_waktu * cepat - n * 0.7) * deg_to_rad(9.0 + n * 4.0) * (1.0 - lari * 0.7)
		var lingkar: = deg_to_rad(16.0) * duduk
		_putar_global(sk, sk.find_bone(EKOR[n]), atas, ayun + lingkar)

		if n >= 3:
			_putar_global(sk, sk.find_bone(EKOR[n]), kanan, - deg_to_rad(12.0) * jalan)



func _pose_kaki(sk: Skeleton3D, atas: Vector3, depan: Vector3, kanan: Vector3, duduk: float, jalan: float, lari: float) -> void :


	for sisi in 2:
		var k: Array = KAKI_BELAKANG[sisi]
		var fase: = _langkah + lerpf(PI * sisi, 0.35 * sisi, _lari)
		if duduk > 0.01:
			_arahkan(sk, k[0], k[1], (depan * 0.8 - atas * 0.6).normalized(), duduk)
			_arahkan(sk, k[1], k[2], ( - depan * 0.9 - atas * 0.45).normalized(), duduk)
			_arahkan(sk, k[2], k[3], (depan * 0.95 - atas * 0.3).normalized(), duduk)
		var gerak: = jalan + lari
		if gerak > 0.01:
			var ayun: = lerpf(24.0, 38.0, _lari)
			var angkat: = maxf(0.0, - sin(fase - 0.6))
			_putar_global(sk, sk.find_bone(k[0]), kanan, sin(fase) * deg_to_rad(ayun) * gerak)
			_putar_global(sk, sk.find_bone(k[1]), kanan, - angkat * deg_to_rad(lerpf(32.0, 45.0, _lari)) * gerak)
			_putar_global(sk, sk.find_bone(k[2]), kanan, angkat * deg_to_rad(lerpf(20.0, 30.0, _lari)) * gerak)
	for sisi in 2:
		var k: Array = KAKI_DEPAN[sisi]
		var fase: = _langkah + lerpf(PI * sisi + PI / 2.0, PI + 0.3 * sisi, _lari)
		if duduk > 0.01:

			_arahkan(sk, k[1], k[2], ( - atas + depan * 0.05).normalized(), duduk)
			_arahkan(sk, k[2], k[3], ( - atas + depan * 0.08).normalized(), duduk)
		var gerak: = jalan + lari
		if gerak > 0.01:
			var ayun: = lerpf(22.0, 36.0, _lari)
			var angkat: = maxf(0.0, sin(fase + 0.6))
			_putar_global(sk, sk.find_bone(k[0]), kanan, sin(fase) * deg_to_rad(ayun) * gerak)
			_putar_global(sk, sk.find_bone(k[1]), kanan, angkat * deg_to_rad(lerpf(28.0, 40.0, _lari)) * gerak)
			_putar_global(sk, sk.find_bone(k[2]), kanan, - angkat * deg_to_rad(lerpf(18.0, 26.0, _lari)) * gerak)



func _pose_dipeluk(sk: Skeleton3D, atas: Vector3, depan: Vector3, kanan: Vector3) -> void :
	var ayun: = sin(_waktu * 1.3) * 0.08
	for sisi in 2:
		var k: Array = KAKI_DEPAN[sisi]
		_arahkan(sk, k[1], k[2], ( - atas * 0.8 + depan * (0.45 + ayun)).normalized(), 1.0)
		_arahkan(sk, k[2], k[3], ( - atas + depan * 0.2).normalized(), 1.0)
		var b: Array = KAKI_BELAKANG[sisi]
		_arahkan(sk, b[1], b[2], ( - atas + depan * (0.1 - ayun)).normalized(), 0.8)


func _perbarui_keadaan(dt: float) -> void :
	_waktu += dt
	_lari = move_toward(_lari, 1.0 if (berlari and berjalan) else 0.0, dt * 3.0)
	if dipeluk:
		_duduk = 0.0
		_jalan = 0.0
	elif berjalan:
		_jalan = move_toward(_jalan, 1.0, dt * 4.0)
		_duduk = move_toward(_duduk, 0.0, dt * 3.0)
		_langkah += dt * lerpf(LANGKAH_JALAN, LANGKAH_LARI, _lari)
		_putar = lerp_angle(_putar, 0.0, minf(dt * 4.0, 1.0))
		_putar_target = _putar
	else:
		_jalan = move_toward(_jalan, 0.0, dt * 3.0)

		if _jalan > 0.01:
			_langkah += dt * LANGKAH_JALAN * _jalan
		_sisa -= dt
		if tua:
			_keadaan = "duduk"
		match _keadaan:
			"duduk":
				_duduk = move_toward(_duduk, 1.0, dt * 1.0)
			"berdiri":
				_duduk = move_toward(_duduk, 0.0, dt * 1.0)
			"putar":
				_duduk = move_toward(_duduk, 0.0, dt * 2.0)
				if _duduk <= 0.01:
					_putar = move_toward(_putar, _putar_target, dt * TAU / 2.6)
					if is_equal_approx(_putar, _putar_target):
						_sisa = 0.0
		if _sisa <= 0.0:
			_ganti_keadaan()


	_sisa_toleh -= dt
	if _sisa_toleh <= 0.0:
		if berjalan:
			_sisa_toleh = randf_range(1.5, 3.5)
			_toleh_target = 0.0 if (berlari or randf() < 0.7) else deg_to_rad(randf_range(-20.0, 20.0))
			_angguk_target = 0.0
		else:
			_sisa_toleh = randf_range(1.2, 3.0)
			_toleh_target = deg_to_rad(float(PILIHAN_TOLEH.pick_random()))
			_angguk_target = [0.0, 0.0, 0.0, deg_to_rad(-14.0), deg_to_rad(10.0)].pick_random()

	_toleh = lerpf(_toleh, _toleh_target, minf(dt * 3.0, 1.0))
	_angguk = lerpf(_angguk, _angguk_target, minf(dt * 2.0, 1.0))
	_sisa_kedut -= dt
	if _sisa_kedut <= 0.0:
		_sisa_kedut = randf_range(1.5, 4.5)
		_kedut = 1.0
	_kedut = move_toward(_kedut, 0.0, dt * 6.0)


func _ganti_keadaan() -> void :

	_keadaan = "duduk" if randf() < 0.65 else "berdiri"
	_sisa = randf_range(5.0, 9.0) if _keadaan == "duduk" else (randf_range(3.0, 5.0) if _keadaan == "berdiri" else 6.0)
	if _keadaan != "putar":
		_putar = fposmod(_putar, TAU)



var _depan: = Vector3.ZERO
func _depan_model(sk: Skeleton3D) -> Vector3:
	if _depan == Vector3.ZERO:
		var a: = sk.find_bone(PINGGUL)
		var b: = sk.find_bone(KEPALA)
		if a >= 0 and b >= 0:
			_depan = sk.get_bone_global_rest(b).origin - sk.get_bone_global_rest(a).origin
			_depan.y = 0.0
		_depan = _depan.normalized() if _depan.length() > 0.001 else Vector3.BACK
	return _depan



func _putar_global(sk: Skeleton3D, i: int, sumbu: Vector3, sudut: float) -> void :
	if i < 0 or absf(sudut) < 1e-05:
		return
	var g: = sk.get_bone_global_pose(i)
	var basis_baru: = Basis(sumbu.normalized(), sudut) * g.basis
	var p: = sk.get_bone_parent(i)
	var induk: = sk.get_bone_global_pose(p).basis if p >= 0 else Basis()
	sk.set_bone_pose_rotation(i, (induk.inverse() * basis_baru).get_rotation_quaternion())



func _arahkan(sk: Skeleton3D, nama: String, nama_anak: String, d: Vector3, kuat: float) -> void :
	var i: = sk.find_bone(nama)
	var a: = sk.find_bone(nama_anak)
	if i < 0 or a < 0:
		return
	var sekarang: = sk.get_bone_global_pose(a).origin - sk.get_bone_global_pose(i).origin
	if sekarang.length() < 0.0001:
		return
	sekarang = sekarang.normalized()
	if sekarang.dot(d) > 0.9999:
		return
	var q: = Quaternion(sekarang, d)
	var sudut: = q.get_angle() * kuat
	_putar_global(sk, i, q.get_axis(), sudut)
