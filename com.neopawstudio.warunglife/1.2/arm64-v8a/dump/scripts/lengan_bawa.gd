extends SkeletonModifier3D







var barang: Node3D = null
var skala_barang: = 1.0
var tengah_barang: = Vector3.ZERO
var ukuran_barang: = Vector3.ONE
var rapat_m: = 0.0
var topang_bawah: = false


const MAJU_M: = 0.1
const TURUN_M: = 0.16
const SELIP_M: = 0.015
const TURUN_GENDONG_M: = 0.06
const MAJU_GENDONG_M: = 0.04

const LENGAN: = {
	"kanan": ["mixamorig_RightArm", "mixamorig_RightForeArm", "mixamorig_RightHand", 1.0], 
	"kiri": ["mixamorig_LeftArm", "mixamorig_LeftForeArm", "mixamorig_LeftHand", -1.0], 
}


func _process_modification() -> void :
	if barang == null or not is_instance_valid(barang):
		return
	var sk: = get_skeleton()
	if sk == null:
		return
	var badan: = _sumbu_badan(sk)
	if badan.is_empty():
		return


	var atas_dunia: = (sk.global_transform.basis.inverse() * Vector3.UP).normalized()
	var atas: Vector3 = ((badan[0] as Vector3) + atas_dunia).normalized()
	var kanan: Vector3 = badan[2]
	var depan: Vector3 = (badan[1] as Vector3 - atas * (badan[1] as Vector3).dot(atas)).normalized()

	var m: = 1.0 / maxf(sk.global_transform.basis.get_scale().x, 0.0001)
	var i_dada: = sk.find_bone("mixamorig_Spine2")
	if i_dada < 0:
		return
	var tebal: = ukuran_barang.z * skala_barang * m
	var lebar: = ukuran_barang.x * skala_barang * m

	var turun: = TURUN_GENDONG_M if topang_bawah else TURUN_M
	var maju: = (MAJU_GENDONG_M if topang_bawah else MAJU_M) - rapat_m
	var pusat: = sk.get_bone_global_pose(i_dada).origin + depan * (maju * m + tebal / 2.0) - atas * turun * m


	var basis_lokal: = Basis(atas.cross(depan).normalized(), atas, depan).orthonormalized()
	var basis_dunia: = sk.global_transform.basis.orthonormalized() * basis_lokal
	barang.global_basis = basis_dunia.scaled(Vector3.ONE * skala_barang)
	barang.global_position = sk.global_transform * pusat - barang.global_basis * tengah_barang


	var tinggi: = ukuran_barang.y * skala_barang * m
	for sisi in LENGAN:
		var l: Array = LENGAN[sisi]
		var arah: = float(l[3])
		var target: = pusat + kanan * arah * (lebar / 2.0 + SELIP_M * m) - depan * tebal * 0.1
		if topang_bawah:
			target = pusat + kanan * arah * lebar * 0.2 - atas * tinggi * 0.45 + depan * tebal * 0.1
		_ik(sk, String(l[0]), String(l[1]), String(l[2]), target, kanan * arah * 0.7 - atas * 0.6 - depan * 0.2, depan * 0.6 - kanan * arah * 0.4)



func _ik(sk: Skeleton3D, n_lengan: String, n_siku: String, n_tangan: String, target: Vector3, kutub: Vector3, arah_tangan: Vector3) -> void :
	var i_l: = sk.find_bone(n_lengan)
	var i_s: = sk.find_bone(n_siku)
	var i_t: = sk.find_bone(n_tangan)
	if i_l < 0 or i_s < 0 or i_t < 0:
		return
	var p1: = sk.get_bone_global_rest(i_s).origin.distance_to(sk.get_bone_global_rest(i_l).origin)
	var p2: = sk.get_bone_global_rest(i_t).origin.distance_to(sk.get_bone_global_rest(i_s).origin)
	var bahu: = sk.get_bone_global_pose(i_l).origin
	var ke: = target - bahu
	var d: = clampf(ke.length(), 0.001, (p1 + p2) * 0.999)
	var arah: = ke.normalized()
	var a: = (p1 * p1 - p2 * p2 + d * d) / (2.0 * d)
	var h: = sqrt(maxf(p1 * p1 - a * a, 0.0))
	var k: = kutub - arah * kutub.dot(arah)
	if k.length() < 0.0001:
		k = Vector3.DOWN
	var siku: = bahu + arah * a + k.normalized() * h
	_arahkan(sk, i_l, (siku - bahu).normalized())
	_arahkan(sk, i_s, (bahu + arah * d - siku).normalized())
	_arahkan(sk, i_t, arah_tangan.normalized())



func _arahkan(sk: Skeleton3D, i: int, d: Vector3) -> void :
	var p: = sk.get_bone_parent(i)
	var global_ini: = sk.get_bone_global_pose(i)
	var sumbu: = global_ini.basis.y.normalized()
	if sumbu.dot(d) > 0.99999:
		return
	var putar: = Quaternion(sumbu, d) if sumbu.dot(d) > -0.9999 else Quaternion(global_ini.basis.x.normalized(), PI)
	var basis_baru: = Basis(putar) * global_ini.basis
	var induk: = sk.get_bone_global_pose(p).basis if p >= 0 else Basis()
	sk.set_bone_pose_rotation(i, (induk.inverse() * basis_baru).get_rotation_quaternion())



var _tanda: = 0.0

func _sumbu_badan(sk: Skeleton3D) -> Array:
	var i_pinggul: = sk.find_bone("mixamorig_Hips")
	var i_leher: = sk.find_bone("mixamorig_Neck")
	var i_bahu_ki: = sk.find_bone("mixamorig_LeftArm")
	var i_bahu_ka: = sk.find_bone("mixamorig_RightArm")
	if i_pinggul < 0 or i_leher < 0 or i_bahu_ki < 0 or i_bahu_ka < 0:
		return []
	var atas: = (sk.get_bone_global_pose(i_leher).origin - sk.get_bone_global_pose(i_pinggul).origin).normalized()
	var kanan: = sk.get_bone_global_pose(i_bahu_ka).origin - sk.get_bone_global_pose(i_bahu_ki).origin
	kanan = (kanan - atas * kanan.dot(atas)).normalized()
	if _tanda == 0.0:
		_tanda = 1.0
		var i_kaki: = sk.find_bone("mixamorig_RightFoot")
		var i_jari: = sk.find_bone("mixamorig_RightToeBase")
		if i_kaki >= 0 and i_jari >= 0:
			var a0: = sk.get_bone_global_rest(i_leher).origin - sk.get_bone_global_rest(i_pinggul).origin
			var k0: = sk.get_bone_global_rest(i_bahu_ka).origin - sk.get_bone_global_rest(i_bahu_ki).origin
			var jari: = sk.get_bone_global_rest(i_jari).origin - sk.get_bone_global_rest(i_kaki).origin
			if jari.dot(k0.cross(a0)) < 0.0:
				_tanda = -1.0
	var depan: = kanan.cross(atas).normalized() * _tanda
	return [atas, depan, kanan]
