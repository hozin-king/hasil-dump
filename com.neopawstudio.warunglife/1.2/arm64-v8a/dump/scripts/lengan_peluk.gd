extends "res://scripts/lengan_bawa.gd"










const JARAK_LAWAN_M: = 0.3
const LEBAR_M: = 0.15
const NAIK_KANAN_M: = -0.04
const TURUN_KIRI_M: = 0.2
const TUNDUK: = deg_to_rad(16.0)
const MIRING: = deg_to_rad(12.0)


func _process_modification() -> void :
	var sk: = get_skeleton()
	if sk == null:
		return
	var badan: = _sumbu_badan(sk)
	if badan.is_empty():
		return
	var atas: Vector3 = badan[0]
	var depan: Vector3 = badan[1]
	var kanan: Vector3 = badan[2]
	var m: = 1.0 / maxf(sk.global_transform.basis.get_scale().x, 0.0001)
	var i_dada: = sk.find_bone("mixamorig_Spine2")
	if i_dada < 0:
		return
	var dada: = sk.get_bone_global_pose(i_dada).origin
	for sisi in LENGAN:
		var l: Array = LENGAN[sisi]
		var arah: = float(l[3])
		var tinggi: = NAIK_KANAN_M if arah > 0.0 else - TURUN_KIRI_M
		var target: = dada + depan * JARAK_LAWAN_M * m + kanan * arah * LEBAR_M * m + atas * tinggi * m

		_ik(sk, String(l[0]), String(l[1]), String(l[2]), target, kanan * arah - atas * 0.3, - kanan * arah * 0.8 + depan * 0.4)

	var i_kepala: = sk.find_bone("mixamorig_Head")
	if i_kepala >= 0:
		var p: = sk.get_bone_parent(i_kepala)
		var g: = sk.get_bone_global_pose(i_kepala)
		var putar: = Basis(kanan, TUNDUK) * Basis(depan, - MIRING)
		var induk: = sk.get_bone_global_pose(p).basis if p >= 0 else Basis()
		sk.set_bone_pose_rotation(i_kepala, (induk.inverse() * (putar * g.basis)).get_rotation_quaternion())
