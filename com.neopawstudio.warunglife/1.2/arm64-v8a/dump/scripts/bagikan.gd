extends RefCounted







const PP: = preload("res://scripts/papan_peringkat.gd")
const FILE: = "user://kartu_bagikan.png"
const URL_PLAY: = "https://play.google.com/store/apps/details?id=com.neopawstudio.warunglife"


static func data_pemain() -> Dictionary:
	var p: = PP.papan("semua")
	return {"nama": GameState.nama_warung_lengkap(), "level": GameState.level(), "pembeli": GameState.total_pembeli, 
		"bintang": GameState.bintang(), "peringkat": int(p["peringkat"]), "jumlah_warung": int(p["jumlah_warung"]), 
		"hari": GameState.hari}


static func teks_ajakan(data: Dictionary) -> String:
	var CV: = preload("res://scripts/cek_versi.gd")
	if CV.di_ios():

		var t: = GameState.tk("%s sudah Level %d, %s pembeli, reputasi %d bintang di Warung Life Simulator!") % [
			String(data["nama"]), int(data["level"]), PP.angka(int(data["pembeli"])), int(data["bintang"])]
		if int(data["peringkat"]) > 0 and int(data["jumlah_warung"]) > 0:
			t += " " + GameState.tk("Peringkat #%s dari %s warung.") % [PP.angka(int(data["peringkat"])), PP.angka(int(data["jumlah_warung"]))]
		return t + " " + GameState.tk("Main juga yuk: %s") % CV.url_toko_web()
	return GameState.tk("Warungku sudah Level %d dengan %s pembeli di Warung Life Simulator! Main juga yuk: %s") % [
		int(data["level"]), PP.angka(int(data["pembeli"])), preload("res://scripts/cek_versi.gd").url_toko_web()]



static func buat_gambar(induk: Node, data: Dictionary) -> String:
	var vp: = SubViewport.new()
	vp.size = Vector2i(1080, 1350)
	vp.transparent_bg = false
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	induk.add_child(vp)
	var kartu: Control = load("res://scripts/kartu_bagikan.gd").new()
	vp.add_child(kartu)
	kartu.isi(data)
	for i in 3:
		await RenderingServer.frame_post_draw
	var gambar: = vp.get_texture().get_image()
	vp.queue_free()
	if gambar == null or gambar.save_png(FILE) != OK:
		return ""
	return ProjectSettings.globalize_path(FILE)



static func bagikan(path: String, teks: String) -> bool:
	if _bagikan_android(path, teks):
		return true


	if OS.get_name() == "iOS":
		OS.shell_open("https://www.threads.net/intent/post?text=" + teks.uri_encode())
		return true
	OS.shell_open(path)
	return false


static func _bagikan_android(path: String, teks: String) -> bool:
	if OS.get_name() != "Android" or not Engine.has_singleton("AndroidRuntime"):
		return false
	var aktivitas = Engine.get_singleton("AndroidRuntime").getActivity()
	var kelas_file = JavaClassWrapper.wrap("java.io.File")
	var kelas_penyedia = JavaClassWrapper.wrap("androidx.core.content.FileProvider")
	var kelas_intent = JavaClassWrapper.wrap("android.content.Intent")
	if aktivitas == null or kelas_file == null or kelas_penyedia == null or kelas_intent == null:
		return false
	var berkas = kelas_file.File(path)
	var uri = kelas_penyedia.getUriForFile(aktivitas, String(aktivitas.getPackageName()) + ".fileprovider", berkas)
	if uri == null:
		return false
	var intent = kelas_intent.Intent("android.intent.action.SEND")
	if intent == null:
		return false
	intent.setType("image/png")
	intent.putExtra("android.intent.extra.STREAM", uri)
	intent.putExtra("android.intent.extra.TEXT", teks)
	intent.addFlags(1)
	var pilihan = kelas_intent.createChooser(intent, GameState.tk("Bagikan capaian"))
	if pilihan == null:
		return false
	aktivitas.startActivity(pilihan)
	return true
