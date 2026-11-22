@tool
extends EditorPlugin




var export_plugin: GoogleLoginExportPlugin


func _enter_tree() -> void :
	export_plugin = GoogleLoginExportPlugin.new()
	add_export_plugin(export_plugin)


func _exit_tree() -> void :
	remove_export_plugin(export_plugin)
	export_plugin = null


class GoogleLoginExportPlugin extends EditorExportPlugin:
	const NAMA: = "GodotGoogleLogin"

	const PUSTAKA: = [
		"androidx.credentials:credentials:1.3.0", 
		"androidx.credentials:credentials-play-services-auth:1.3.0", 
		"com.google.android.libraries.identity.googleid:googleid:1.1.1", 
		"com.google.android.gms:play-services-auth:21.1.1", 
	]

	func _supports_platform(platform: EditorExportPlatform) -> bool:
		return platform is EditorExportPlatformAndroid

	func _get_android_libraries(_platform: EditorExportPlatform, debug: bool) -> PackedStringArray:
		if debug:
			return PackedStringArray([NAMA + "/bin/debug/" + NAMA + "-debug.aar"])
		return PackedStringArray([NAMA + "/bin/release/" + NAMA + "-release.aar"])

	func _get_android_dependencies(_platform: EditorExportPlatform, _debug: bool) -> PackedStringArray:
		return PackedStringArray(PUSTAKA)

	func _get_name() -> String:
		return NAMA
