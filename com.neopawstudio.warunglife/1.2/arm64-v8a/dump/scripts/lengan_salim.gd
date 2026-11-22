extends "res://scripts/lengan_bawa.gd"







var cium: = false
const SALIM_MAJU_M: = 0.34
const SALIM_TURUN_M: = 0.3
const KE_TENGAH_M: = 0.06
const TUNDUK_CIUM: = deg_to_rad(30.0)
const TUNDUK_ULUR: = deg_to_rad(10.0)


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
	var l: Array = LENGAN["kanan"]
	var target: = dada + depan * SALIM_MAJU_M * m - atas * SALIM_TURUN_M * m + kanan * KE_TENGAH_M * m

	_ik(sk, String(l[0]), String(l[1]), String(l[2]), target, kanan * 0.5 - atas * 0.8, depan * 0.8 - atas * 0.3)
	var i_kepala: = sk.find_bone("mixamorig_Head")
	if i_kepala >= 0:
		var p: = sk.get_bone_parent(i_kepala)
		var g: = sk.get_bone_global_pose(i_kepala)
		var putar: = Basis(kanan, TUNDUK_CIUM if cium else TUNDUK_ULUR)
		var induk: = sk.get_bone_global_pose(p).basis if p >= 0 else Basis()
		sk.set_bone_pose_rotation(i_kepala, (induk.inverse() * (putar * g.basis)).get_rotation_quaternion())
