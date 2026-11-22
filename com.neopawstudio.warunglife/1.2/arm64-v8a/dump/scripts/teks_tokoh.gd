extends Translation












const FILE_IBU: = "res://data/teks_ibu.json"
const NAMA_LAIN: = ["RT", "Haji", "Rudi", "Slamet", "Darto", "Kades", "Hendra", "Engkus", "Tani", "Joko", "Asep"]
const LINDUNG: = [["Bapak-bapak", "A"], ["bapak-bapak", "B"], ["Bapak saya", "C"], 
	["bapak saya", "D"], ["BAPAK-BAPAK", "E"], ["almarhum Bapak", "F"], ["Bapak berkoko", "G"], 
	["Bapak-Ibu", "H"]]
const BATAS_CACHE: = 4000

var nama: = "Misran"
var ibu: = false
var en: RefCounted = null
var _utuh: = []
var _pola: = []
var _cache: = {}
var _re_bapak: RegEx
var _re_pak: RegEx
var _re_bapak_besar: RegEx
var _re_pak_besar: RegEx


func _init() -> void :
	locale = "id"
	var lain: = "|".join(NAMA_LAIN)
	_re_bapak = RegEx.create_from_string("(?<![\\w-])Bapak(?![\\w-])(?!\\s+(?:%s)\\b)" % lain)
	_re_pak = RegEx.create_from_string("(?<![\\w-])Pak(?![\\w-])(?!\\s+(?:%s)\\b)" % lain)
	_re_bapak_besar = RegEx.create_from_string("(?<![\\w-])BAPAK(?![\\w-])(?!\\s+(?:RT|HAJI)\\b)")
	_re_pak_besar = RegEx.create_from_string("(?<![\\w-])PAK(?![\\w-])(?!\\s+(?:RT|HAJI)\\b)")
	if not FileAccess.file_exists(FILE_IBU):
		return
	var d = JSON.parse_string(FileAccess.get_file_as_string(FILE_IBU))
	if typeof(d) != TYPE_DICTIONARY:
		return
	for k in d:
		var kunci: = String(k)
		if kunci.begins_with("_"):
			continue
		if kunci.contains("{"):
			_pola.append(_buat_pola(kunci, String(d[k])))
		else:
			_utuh.append([kunci, String(d[k])])
	_utuh.sort_custom( func(a, b): return String(a[0]).length() > String(b[0]).length())



func _buat_pola(kunci: String, ganti: String) -> Array:
	var khusus: = ".^$*+?()[]{}|\\/"
	var pola: = ""
	var i: = 0
	while i < kunci.length():
		var c: = kunci[i]
		var akhir: = kunci.find("}", i)
		if c == "{" and akhir > i:

			pola += "(?<%s>Rp[0-9.]*[0-9]|.+?)" % kunci.substr(i + 1, akhir - i - 1)
			i = akhir + 1
			continue
		pola += ("\\" + c) if khusus.contains(c) else c
		i += 1
	var isian: = RegEx.create_from_string("\\{(\\w+)\\}")
	for m in isian.search_all(ganti):
		ganti = ganti.replace(m.get_string(), "${" + m.get_string(1) + "}")
	return [RegEx.create_from_string(pola), ganti]



func atur_bahasa(kode: String) -> void :
	if kode == "en":
		if en == null:
			en = load("res://scripts/terjemah.gd").new()
	else:
		en = null
	_cache.clear()


func atur(nama_baru: String, penjaga_ibu: bool) -> void :
	nama = nama_baru if nama_baru != "" else "Misran"
	ibu = penjaga_ibu
	_cache.clear()


func _get_message(src_message: StringName, _context: StringName) -> StringName:
	var s: = String(src_message)
	if _cache.has(s):
		return _cache[s]
	var hasil: = ubah(s)
	if _cache.size() > BATAS_CACHE:
		_cache.clear()

	var jawab: = StringName(hasil) if hasil != s else StringName()
	_cache[s] = jawab
	return jawab


func ubah(s: String) -> String:
	if en != null:
		s = en.terjemah(s)
	elif ibu:
		s = _ubah_ibu(s)
	if nama != "Misran":
		s = s.replace("MISRAN", nama.to_upper()).replace("Misran", nama)
	if _ios and (s.contains("Google Play") or s.contains("Play Store")):
		s = _ke_app_store(s)
	return s




var _ios: = OS.get_name() == "iOS"
const GANTI_IOS: = [
	["di akun Google Play-mu", "di Apple ID-mu"], ["akun Google Play ini", "Apple ID ini"], 
	["on your Google Play account", "on your Apple ID"], ["this Google Play account", "this Apple ID"], 
	["Google Play", "App Store"], ["the Play Store", "the App Store"], ["Play Store", "App Store"]]

func _ke_app_store(s: String) -> String:
	for g in GANTI_IOS:
		s = s.replace(g[0], g[1])
	return s


func _ubah_ibu(s: String) -> String:
	for u in _utuh:
		if s.contains(u[0]):
			s = s.replace(u[0], u[1])
	for p in _pola:
		s = (p[0] as RegEx).sub(s, p[1], true)
	if not (s.contains("ak") or s.contains("AK") or s.contains("Misran")):
		return s
	for p in LINDUNG:
		s = s.replace(p[0], p[1])
	s = s.replace("Pak Misran", "Bu Misran").replace("Kang Misran", "Ceu Misran").replace("Mang Misran", "Ceu Misran")
	s = s.replace("PAK MISRAN", "BU MISRAN")
	s = _re_bapak.sub(s, "Ibu", true)
	s = _re_pak.sub(s, "Bu", true)
	s = _re_bapak_besar.sub(s, "IBU", true)
	s = _re_pak_besar.sub(s, "BU", true)
	for p in LINDUNG:
		s = s.replace(p[1], p[0])
	return s
