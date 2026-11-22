extends SkeletonModifier3D





var sudut: = 15.0
const TULANG: = ["mixamorig_Spine", "mixamorig_Spine1", "mixamorig_Spine2"]
const LEHER: = "mixamorig_Neck"


func _process_modification() -> void :
	var sk: = get_skeleton()
	if sk == null:
		return

	for nama in TULANG:
		_tekuk(sk, nama, sudut / TULANG.size())
	_tekuk(sk, LEHER, - sudut * 0.35)


func _tekuk(sk: Skeleton3D, nama: String, derajat: float) -> void :
	var i: = sk.find_bone(nama)
	if i < 0:
		return
	var rot: = sk.get_bone_pose_rotation(i)
	sk.set_bone_pose_rotation(i, rot * Quaternion(Vector3.RIGHT, deg_to_rad(derajat)))
