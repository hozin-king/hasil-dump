extends RefCounted







static func jumlah_kamu(tab: String) -> int:
	if tab == "minggu":
		return GameState.pembeli_minggu_ini()
	return GameState.total_pembeli if tab == "semua" else GameState.pembeli_bulan_ini()


static func omzet_kamu(tab: String) -> int:
	if tab == "minggu":
		return GameState.omzet_minggu_ini()
	return GameState.omzet_semua() if tab == "semua" else GameState.omzet_bulan_ini()








static func papan(tab: String) -> Dictionary:
	var jumlah: = jumlah_kamu(tab)
	var saya: = [GameState.nama_warung_lengkap(), jumlah, "", GameState.bintang(), GameState.level(), true]
	var d: Dictionary = GameState.papan.data(tab) if GameState.papan != null else {}
	if d.is_empty():
		return {"daftar": [saya], "kamu": 0, "peringkat": 0, "jumlah_warung": 1, "online": false}
	var punya_saya: bool = GameState.papan.id_data() == GameState.id_papan
	var kode_saya: String = GameState.papan.kode(GameState.id_papan)
	var lain: = []
	var ada_di_server: bool = punya_saya and d.get("peringkat") != null
	for b in d.get("daftar", []):
		if String(b[2]) == kode_saya:
			ada_di_server = true
			continue
		lain.append([String(b[0]), int(b[1]), String(b[2]), int(b[3]) if b.size() > 3 and b[3] != null else -1, 
			int(b[4]) if b.size() > 4 and b[4] != null else -1])
	var kamu: = lain.size()
	for i in lain.size():
		if jumlah > int(lain[i][1]):
			kamu = i
			break
	var jumlah_warung: = int(d.get("jumlah_warung", 0)) + (0 if ada_di_server else 1)
	var peringkat: = kamu + 1

	if kamu == lain.size() and lain.size() >= 49:
		peringkat = maxi(int(d["peringkat"]), kamu + 1) if punya_saya and d.get("peringkat") != null else 0
	lain.insert(kamu, saya)
	return {"daftar": lain, "kamu": kamu, "peringkat": peringkat, "jumlah_warung": maxi(jumlah_warung, lain.size()), "online": true}



static func peringkat(tab: = "semua") -> int:
	return int(papan(tab)["peringkat"])


static func angka(n: int) -> String:
	var s: = str(n)
	var hasil: = ""
	while s.length() > 3:
		hasil = "." + s.right(3) + hasil
		s = s.left(s.length() - 3)
	return s + hasil






static func papan_besar(tab: String) -> Dictionary:
	var dasar: = papan(tab) if tab != "minggu" or (GameState.papan != null and not GameState.papan.data("minggu").is_empty()) else {}
	var mentah: Dictionary = GameState.papan.data(tab) if GameState.papan != null else {}
	var info: = {}
	for b in mentah.get("daftar", []):
		info[String(b[2])] = b
	var ada_omzet: = false
	var baris: = []
	if dasar.is_empty():

		dasar = {"daftar": [[GameState.nama_warung_lengkap(), jumlah_kamu(tab), "", GameState.bintang(), GameState.level(), true]], 
			"kamu": 0, "peringkat": 0, "jumlah_warung": 1, "online": false}
	for b in dasar["daftar"]:
		var saya: bool = b.size() > 5
		var x: Array = info.get(String(b[2]), [])
		var o: = omzet_kamu(tab) if saya else (int(x[5]) if x.size() > 5 and x[5] != null else -1)
		if x.size() > 5:
			ada_omzet = true
		baris.append({"nama": String(b[0]), "pembeli": int(b[1]), "omzet": o, "kode": String(b[2]), 
			"bintang": int(b[3]), "level": int(b[4]), 
			"jempol": (GameState.papan.jempol_saya() if saya else (int(x[6]) if x.size() > 6 else 0)), 
			"sudah": bool(x[7]) if x.size() > 7 else false, "saya": saya, 
			"pendukung": pendukung_awal(String(b[2]), tab, saya), "peduli": peduli(String(b[2]), saya), 
			"foto": foto(String(b[2]), tab, saya)})
	return {"baris": baris, "kamu": int(dasar["kamu"]), "peringkat": int(dasar["peringkat"]), 
		"jumlah_warung": int(dasar["jumlah_warung"]), "online": bool(dasar["online"]), "ada_omzet": ada_omzet}




const NAMA_LENCANA_PENDUKUNG: = "Warga Baik Hati"
const NAMA_LENCANA_PEDULI: = "Warga Peduli"

const WARNA_NAMA_PENDUKUNG: = Color(1.0, 0.93, 0.8)



static func foto(kode_warung: String, tab: = "semua", saya: = false) -> int:
	if saya:
		return preload("res://scripts/foto_profil.gd").pilihan()
	return GameState.papan.foto(kode_warung, tab) if GameState.papan != null else 0


static func pendukung_awal(kode_warung: String, tab: = "semua", saya: = false) -> bool:
	if GameState.papan == null:
		return false
	if saya:
		return GameState.papan.pendukung_saya()
	return GameState.papan.pendukung_awal(kode_warung, tab)




static func angka_ringkas(n: int) -> String:
	if n < 1000:
		return angka(maxi(n, 0))
	var en: = GameState.bahasa == "en"
	var bagi: = 1000000.0 if n >= 1000000 else 1000.0
	var akhiran: = ("M" if en else "jt") if n >= 1000000 else "k"
	var x: = floorf(n / bagi * 10.0) / 10.0
	var teks: = String.num(x, 1)
	if teks.ends_with(".0"):
		teks = teks.left(teks.length() - 2)
	return (teks if en else teks.replace(".", ",")) + akhiran



const EMAS_PITA: = Color(1.0, 0.8, 0.18)
const EMAS_PITA_GELAP: = Color(0.72, 0.45, 0.05)
const PLATINUM_PITA: = Color(0.86, 0.9, 0.97)
const PLATINUM_PITA_GELAP: = Color(0.5, 0.56, 0.68)


static func bahan_platinum(lebar: float) -> ShaderMaterial:
	var m: = ShaderMaterial.new()
	m.shader = preload("res://shader/nama_platinum.gdshader")
	m.set_shader_parameter("lebar", lebar)
	return m


static func pita_gelar(ukuran: int, peduli_: = false) -> PanelContainer:
	var tenang: = preload("res://scripts/tema_tenang.gd")
	var wadah: = PanelContainer.new()
	wadah.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wadah.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	if peduli_:
		wadah.add_theme_stylebox_override("panel", tenang.kotak(PLATINUM_PITA, 8, Vector4(7, 1, 7, 2), 1, PLATINUM_PITA_GELAP, 2))
		wadah.material = bahan_platinum(140.0)
	else:
		wadah.add_theme_stylebox_override("panel", tenang.kotak(EMAS_PITA, 8, Vector4(7, 1, 7, 2), 1, EMAS_PITA_GELAP, 2))
	var l: = Label.new()
	l.text = "★ " + TranslationServer.translate(NAMA_LENCANA_PEDULI if peduli_ else NAMA_LENCANA_PENDUKUNG)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.add_theme_font_size_override("font_size", ukuran)
	l.add_theme_color_override("font_color", Color(0.32, 0.18, 0.0) if not peduli_ else Color(0.12, 0.16, 0.3))
	wadah.add_child(l)
	return wadah


static func peduli(kode_warung: String, saya: = false) -> bool:
	if GameState.papan == null:
		return false
	if saya:
		return GameState.papan.peduli_saya()
	return GameState.papan.peduli(kode_warung)


static func rupiah_ringkas(n: int) -> String:
	if n < 0:
		return "-"

	var en: = GameState.bahasa == "en"
	if n >= 1000000000:
		var m: = String.num(n / 1000000000.0, 1)
		return ("Rp%sB" % m) if en else ("Rp%s M" % m.replace(".", ","))
	if n >= 1000000:
		var j: = String.num(n / 1000000.0, 1)
		return ("Rp%sM" % j) if en else ("Rp%s jt" % j.replace(".", ","))
	return "Rp" + angka(n)
