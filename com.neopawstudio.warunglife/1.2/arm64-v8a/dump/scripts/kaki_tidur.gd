extends SkeletonModifier3D





const TURUN_KAKI: = 0.03
var kuat: = 0.0


func _process_modification() -> void :
	var sk: = get_skeleton()
	if sk == null or kuat <= 0.0:
		return
	var paha: = [sk.find_bone("mixamorig_LeftUpLeg"), sk.find_bone("mixamorig_RightUpLeg")]
	var kaki: = [sk.find_bone("mixamorig_LeftFoot"), sk.find_bone("mixamorig_RightFoot")]
	var kepala: = sk.find_bone("mixamorig_Head")
	if -1 in paha or -1 in kaki or kepala < 0:
		return
	var pangkal: Vector3 = (sk.get_bone_global_pose(paha[0]).origin + sk.get_bone_global_pose(paha[1]).origin) / 2.0
	var ujung: Vector3 = (sk.get_bone_global_pose(kaki[0]).origin + sk.get_bone_global_pose(kaki[1]).origin) / 2.0
	var atas: Vector3 = (sk.global_basis.inverse() * Vector3.UP).normalized()
	var badan: Vector3 = pangkal - sk.get_bone_global_pose(kepala).origin
	var arah: Vector3 = (badan - atas * badan.dot(atas)).normalized()
	var putar: = Quaternion((ujung - pangkal).normalized(), (arah - atas * TURUN_KAKI).normalized())
	var q: Quaternion = Quaternion.IDENTITY.slerp(putar, kuat)
	for i: int in paha:
		var pose: = sk.get_bone_global_pose(i)
		pose.basis = Basis(q) * pose.basis
		sk.set_bone_global_pose(i, pose)
