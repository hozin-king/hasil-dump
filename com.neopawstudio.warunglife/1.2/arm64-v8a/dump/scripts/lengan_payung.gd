extends SkeletonModifier3D







var kuat: = 0.0

const LENGAN: = "mixamorig_RightArm"
const SIKU: = "mixamorig_RightForeArm"
const TANGAN: = "mixamorig_RightHand"




const ARAH_LENGAN: = [-0.85, 0.42, 0.22]
const ARAH_SIKU: = [0.55, 0.78, -0.25]


func _process_modification() -> void :
	if kuat <= 0.001:
		return
	var sk: = get_skeleton()
	if sk == null:
		return
	var badan: = _sumbu_badan(sk)
	if badan.is_empty():
		return
	_arahkan(sk, LENGAN, _arah(badan, ARAH_LENGAN))
	var d_siku: = _arah_siku(sk, badan)
	_arahkan(sk, SIKU, d_siku)
	_arahkan(sk, TANGAN, d_siku)
	_genggam(sk)
	_taruh_payung(sk)






const JARI: = ["Index", "Middle", "Ring", "Pinky"]
const KEPALAN: = [80.0, 170.0, 235.0]
const KEPALAN_JEMPOL: = [[1.0, 0.6, 0.3], [0.5, 0.5, 0.8], [0.0, 0.3, 1.0]]

func _posisi(sk: Skeleton3D, nama: String) -> Vector3:
	var i: = sk.find_bone(nama)
	return sk.get_bone_global_pose(i).origin if i >= 0 else Vector3.INF




var tekuk_lokal: = false

func _genggam_lokal(sk: Skeleton3D) -> void :
	for nama in JARI + ["Thumb"]:
		var sudut: Array = [25.0, 35.0, 35.0] if nama == "Thumb" else [80.0, 95.0, 70.0]
		for ruas in 3:
			var i: = sk.find_bone("mixamorig_RightHand%s%d" % [nama, ruas + 1])
			if i < 0:
				continue
			var lama: = sk.get_bone_pose_rotation(i)
			var tekuk: = lama * Quaternion(Vector3.RIGHT, deg_to_rad( - float(sudut[ruas])))
			sk.set_bone_pose_rotation(i, lama.slerp(tekuk, kuat))


func _genggam(sk: Skeleton3D) -> void :
	if tekuk_lokal:
		_genggam_lokal(sk)
		return
	var tangan: = _posisi(sk, TANGAN)
	var telunjuk: = _posisi(sk, "mixamorig_RightHandIndex1")
	var kelingking: = _posisi(sk, "mixamorig_RightHandPinky1")
	var tengah: = _posisi(sk, "mixamorig_RightHandMiddle1")
	var jempol: = _posisi(sk, "mixamorig_RightHandThumb2")
	if Vector3.INF in [tangan, tengah, jempol]:
		return
	var maju: = (tengah - tangan).normalized()

	var buku: = (kelingking - telunjuk).normalized() if not Vector3.INF in [telunjuk, kelingking] else (tangan - jempol).slide(maju).normalized()

	var telapak: = maju.cross(buku)
	if telapak.length() < 0.0001:
		return
	telapak = telapak.normalized()

	_geser_kepalan = telapak * (tengah - tangan).length() * GESER_KEPALAN


	var tanda: = 1.0 if (maju.rotated(buku, 0.2) - maju).dot(telapak) >= 0.0 else -1.0
	for nama in JARI:
		for ruas in 3:
			var d: = maju.rotated(buku, deg_to_rad(float(KEPALAN[ruas])) * tanda)
			_arahkan(sk, "mixamorig_RightHand%s%d" % [nama, ruas + 1], d)

	for ruas in 3:
		var k: Array = KEPALAN_JEMPOL[ruas]
		_arahkan(sk, "mixamorig_RightHandThumb%d" % (ruas + 1), (maju * float(k[0]) + telapak * float(k[1]) + buku * float(k[2])).normalized())






func _arah_siku(sk: Skeleton3D, badan: Array) -> Vector3:
	var tetap: = _arah(badan, ARAH_SIKU)
	var i_siku: = sk.find_bone(SIKU)
	var i_tangan: = sk.find_bone(TANGAN)
	var kepala: = _atas_kepala_kerangka(sk)
	var skala: = sk.global_basis.get_scale().y
	if i_siku < 0 or i_tangan < 0 or kepala == Vector3.INF or tinggi_payung <= 0.0 or skala <= 0.0:
		return tetap
	var atas: Vector3 = badan[0]
	var siku: = sk.get_bone_global_pose(i_siku).origin
	var panjang: = siku.distance_to(sk.get_bone_global_pose(i_tangan).origin) * 1.15
	var h: = tinggi_payung / skala
	var ingin: = kepala.dot(atas) + (JARAK_ATAS_KEPALA + TEPI_KANOPI - GENGGAM_DARI_BAWAH) * h
	var u: = clampf((ingin - siku.dot(atas)) / maxf(panjang, 0.001), -0.3, 0.95)
	var datar: Vector3 = (badan[1] * 0.85 - badan[2] * 0.27).normalized()
	return (atas * u + datar * sqrt(1.0 - u * u)).normalized()


func _atas_kepala_kerangka(sk: Skeleton3D) -> Vector3:
	var i_ujung: = sk.find_bone("mixamorig_HeadTop_End")
	if i_ujung >= 0:
		return sk.get_bone_global_pose(i_ujung).origin
	var i_kepala: = sk.find_bone("mixamorig_Head")
	var i_leher: = sk.find_bone("mixamorig_Neck")
	if i_kepala < 0 or i_leher < 0:
		return Vector3.INF
	var kepala: = sk.get_bone_global_pose(i_kepala).origin
	return kepala + (kepala - sk.get_bone_global_pose(i_leher).origin) * 1.8


func _arah(badan: Array, k: Array) -> Vector3:
	return (badan[0] * float(k[0]) + badan[1] * float(k[1]) + badan[2] * float(k[2])).normalized()



func _sumbu_badan(sk: Skeleton3D) -> Array:
	var i_pinggul: = sk.find_bone("mixamorig_Hips")
	var i_leher: = sk.find_bone("mixamorig_Neck")
	var i_bahu_ki: = sk.find_bone("mixamorig_LeftArm")
	var i_bahu_ka: = sk.find_bone("mixamorig_RightArm")
	if i_pinggul < 0 or i_leher < 0 or i_bahu_ki < 0 or i_bahu_ka < 0:
		return []
	var atas: = (sk.get_bone_global_pose(i_leher).origin - sk.get_bone_global_pose(i_pinggul).origin).normalized()
	var kanan: = (sk.get_bone_global_pose(i_bahu_ka).origin - sk.get_bone_global_pose(i_bahu_ki).origin)
	kanan = (kanan - atas * kanan.dot(atas)).normalized()
	var depan: = kanan.cross(atas).normalized() * _tanda_depan(sk, i_pinggul, i_leher, i_bahu_ki, i_bahu_ka)
	return [atas, depan, kanan]






var _tanda: = 0.0

func _tanda_depan(sk: Skeleton3D, i_pinggul: int, i_leher: int, i_bahu_ki: int, i_bahu_ka: int) -> float:
	if _tanda != 0.0:
		return _tanda
	_tanda = 1.0
	var i_kaki: = sk.find_bone("mixamorig_RightFoot")
	var i_jari: = sk.find_bone("mixamorig_RightToeBase")
	if i_kaki >= 0 and i_jari >= 0:
		var atas: = sk.get_bone_global_rest(i_leher).origin - sk.get_bone_global_rest(i_pinggul).origin
		var kanan: = sk.get_bone_global_rest(i_bahu_ka).origin - sk.get_bone_global_rest(i_bahu_ki).origin
		var jari: = sk.get_bone_global_rest(i_jari).origin - sk.get_bone_global_rest(i_kaki).origin
		if jari.dot(kanan.cross(atas)) < 0.0:
			_tanda = -1.0
	return _tanda



func _arahkan(sk: Skeleton3D, nama: String, d: Vector3) -> void :
	var i: = sk.find_bone(nama)
	if i < 0:
		return
	var p: = sk.get_bone_parent(i)
	var global_ini: = sk.get_bone_global_pose(i)
	var sumbu: = global_ini.basis.y.normalized()
	if sumbu.dot(d) > 0.9999:
		return
	var putar: = Quaternion(sumbu, d)
	var basis_baru: = Basis(putar) * global_ini.basis
	var induk: = sk.get_bone_global_pose(p).basis if p >= 0 else Basis()
	var lokal_baru: = (induk.inverse() * basis_baru).get_rotation_quaternion()
	var lokal_lama: = sk.get_bone_pose_rotation(i)
	sk.set_bone_pose_rotation(i, lokal_lama.slerp(lokal_baru, kuat))




var payung: Node3D = null
var skala_payung: = 1.0
var naik_payung: = 0.0
var bawah_payung: = 0.0
var tinggi_payung: = 0.0
const TITIK_GENGGAM: = 0.85
const TITIK_GENGGAM_LOKAL: = 0.75
const TEPI_KANOPI: = 0.5
const JARAK_ATAS_KEPALA: = 0.08
const GENGGAM_DARI_BAWAH: = 0.13


const GESER_KEPALAN: = 0.35
const GESER_KE_BALIK_TANGAN: = 0.22
var _geser_kepalan: = Vector3.ZERO


func _taruh_payung(sk: Skeleton3D) -> void :
	if payung == null or not is_instance_valid(payung) or not payung.visible:
		return
	var i: = sk.find_bone(TANGAN)
	if i < 0:
		return
	var tangan: = sk.global_transform * sk.get_bone_global_pose(i).origin

	var i_pangkal: = sk.find_bone("mixamorig_RightHandMiddle1")
	if i_pangkal >= 0:
		tangan = tangan.lerp(sk.global_transform * sk.get_bone_global_pose(i_pangkal).origin, TITIK_GENGGAM_LOKAL if tekuk_lokal else TITIK_GENGGAM)



	var lubang: = Vector3.ZERO
	var n: = 0
	if not tekuk_lokal:
		for nama in ["Index", "Middle", "Ring"]:
			var a: = sk.find_bone("mixamorig_RightHand%s1" % nama)
			var b: = sk.find_bone("mixamorig_RightHand%s3" % nama)
			if a >= 0 and b >= 0:
				lubang += (sk.get_bone_global_pose(a).origin + sk.get_bone_global_pose(b).origin) * 0.5
				n += 1
	if n > 0:
		tangan = sk.global_transform * (lubang / n)
	else:
		tangan += sk.global_basis * _geser_kepalan
	payung.global_basis = Basis.from_scale(Vector3.ONE * skala_payung)


	var bawah: = tangan.y - GENGGAM_DARI_BAWAH * tinggi_payung if tinggi_payung > 0.0 else tangan.y + naik_payung + bawah_payung



	if tinggi_payung > 0.0:
		var kepala: = _atas_kepala_kerangka(sk)
		if kepala != Vector3.INF:
			var y_kepala: = (sk.global_transform * kepala).y
			bawah = maxf(bawah, y_kepala + (JARAK_ATAS_KEPALA - TEPI_KANOPI) * tinggi_payung)
	payung.global_position = Vector3(tangan.x, bawah - bawah_payung, tangan.z)


	var kamera: = sk.get_viewport().get_camera_3d()
	if kamera != null:
		payung.global_position -= kamera.global_basis.z * GESER_KE_BALIK_TANGAN
