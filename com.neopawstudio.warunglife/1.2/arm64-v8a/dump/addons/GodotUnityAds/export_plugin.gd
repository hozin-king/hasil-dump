@tool
extends EditorPlugin




var export_plugin: UnityAdsExportPlugin


func _enter_tree() -> void :
	export_plugin = UnityAdsExportPlugin.new()
	add_export_plugin(export_plugin)


func _exit_tree() -> void :
	remove_export_plugin(export_plugin)
	export_plugin = null


class UnityAdsExportPlugin extends EditorExportPlugin:
	const NAMA: = "GodotUnityAds"

	const SDK_UNITY_ADS: = "com.unity3d.ads:unity-ads:4.21.0"

	func _supports_platform(platform: EditorExportPlatform) -> bool:
		return platform is EditorExportPlatformAndroid

	func _get_android_libraries(_platform: EditorExportPlatform, debug: bool) -> PackedStringArray:
		if debug:
			return PackedStringArray([NAMA + "/bin/debug/" + NAMA + "-debug.aar"])
		return PackedStringArray([NAMA + "/bin/release/" + NAMA + "-release.aar"])

	func _get_android_dependencies(_platform: EditorExportPlatform, _debug: bool) -> PackedStringArray:
		return PackedStringArray([SDK_UNITY_ADS])

	func _get_name() -> String:
		return NAMA
