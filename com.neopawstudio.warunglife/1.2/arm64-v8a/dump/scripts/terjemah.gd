extends RefCounted











const FILE_KAMUS: = "res://data/terjemahan_en.json"
const FILE_BELUM: = "user://belum_terjemah_en.txt"
const KEDALAMAN_MAKS: = 3

var _utuh: = {}
var _pola: = []
var _belum: = {}
var _cache: = {}
var _besar: = {}
var _catat: = false
var _re_kalimat: RegEx
var _re_isian_format: RegEx
var _re_isian_kurawal: RegEx
var _re_huruf_id: RegEx
var _re_awalan: RegEx


func _init() -> void :
	_catat = OS.is_debug_build()
	_re_kalimat = RegEx.create_from_string("(?<=[.!?…])\\s+(?=[A-Z0-9\"“(\\[])")
	_re_isian_format = RegEx.create_from_string("%[-+0#]*[0-9]*(?:\\.[0-9]+)?[sdifxX]")
	_re_isian_kurawal = RegEx.create_from_string("\\{([a-z_0-9]+)\\}")
	_re_huruf_id = RegEx.create_from_string("[A-Za-z]{2,}")

	_re_awalan = RegEx.create_from_string("^([^A-Za-z0-9\"“(\\[{%+\\-]+)(.+)$")
	if not FileAccess.file_exists(FILE_KAMUS):
		return
	var d = JSON.parse_string(FileAccess.get_file_as_string(FILE_KAMUS))
	if typeof(d) != TYPE_DICTIONARY:
		push_warning("terjemahan_en.json rusak")
		return
	for k in d:
		var kunci: = String(k)
		var nilai: = String(d[k])
		if kunci.begins_with("_") or nilai == "":
			continue
		if _re_isian_format.search(kunci) != null or _re_isian_kurawal.search(kunci) != null:
			var p: = _buat_pola(kunci, nilai)
			if not p.is_empty():
				_pola.append(p)
		else:
			_utuh[kunci] = nilai

	_pola.sort_custom( func(a, b): return int(a[4]) > int(b[4]))
	for k in _utuh:
		var besar: = String(k).to_upper()
		if besar != k and not _utuh.has(besar):
			_besar[besar] = String(_utuh[k]).to_upper()



func _buat_pola(kunci: String, nilai: String) -> Array:
	var khusus: = ".^$*+?()[]{}|\\/"
	var pola: = "^"
	var nama: Array = []
	var potongan: Array = []
	var tetap: = ""
	var i: = 0
	var n: = kunci.length()
	while i < n:
		var c: = kunci[i]
		if c == "%" and i + 1 < n and kunci[i + 1] == "%":
			pola += "%"
			tetap += "%"
			i += 2
			continue
		if c == "%":
			var m: = _re_isian_format.search(kunci, i)
			if m != null and m.get_start() == i:
				var jenis: = m.get_string()[-1]
				pola += "(-?[0-9][0-9.,]*)" if jenis in ["d", "i"] else "(.*?)"
				nama.append(str(nama.size()))
				potongan.append(tetap)
				tetap = ""
				i = m.get_end()
				continue
		if c == "{":
			var m2: = _re_isian_kurawal.search(kunci, i)
			if m2 != null and m2.get_start() == i:
				pola += "(Rp[0-9.]*[0-9]|.+?)"
				nama.append(m2.get_string(1))
				potongan.append(tetap)
				tetap = ""
				i = m2.get_end()
				continue
		pola += ("\\" + c) if khusus.contains(c) else c
		tetap += c
		i += 1
	potongan.append(tetap)
	pola += "$"
	var jangkar: = ""
	var panjang_tetap: = 0
	for p in potongan:
		panjang_tetap += String(p).length()
		if String(p).length() > jangkar.length():
			jangkar = p
	var re: = RegEx.create_from_string(pola)
	if not re.is_valid():
		return []

	var re_besar: = RegEx.create_from_string("(?i)" + pola)
	return [re, nilai, nama, jangkar, panjang_tetap, re_besar]


func terjemah(s: String) -> String:
	if _cache.has(s):
		return _cache[s]
	var hasil: = _terjemah(s, 0)
	if _cache.size() > 4000:
		_cache.clear()
	_cache[s] = hasil
	return hasil


func _terjemah(s: String, dalam: int) -> String:
	if s == "" or _re_huruf_id.search(s) == null:
		return s
	if _utuh.has(s):
		return _utuh[s]
	if _besar.has(s):
		return _besar[s]


	var beda_huruf: = _beda_huruf(s)
	if beda_huruf != "":
		return beda_huruf

	var inti: = s.strip_edges()
	if inti != s and inti != "":
		var t: = _terjemah(inti, dalam)
		if t != inti:
			var awal: = s.find(inti)
			return s.substr(0, awal) + t + s.substr(awal + inti.length())
		return s
	var hasil: = _cocok_pola(s, dalam)


	if hasil != "" and hasil.count("\n") >= s.count("\n"):
		return hasil

	if s == s.to_upper() and s != s.to_lower():
		hasil = _cocok_pola(s, dalam, true)
		if hasil != "":
			return hasil.to_upper()

	if dalam < KEDALAMAN_MAKS and s.contains(" · "):
		var bagian: = s.split(" · ")
		var ubah: = false
		for i in bagian.size():
			var inti_b: = bagian[i].strip_edges()
			var t: = _terjemah(inti_b, dalam + 1)
			if t != inti_b:
				ubah = true
				bagian[i] = bagian[i].replace(inti_b, t)
		if ubah:
			return " · ".join(bagian)

	if dalam < KEDALAMAN_MAKS:
		var m: = _re_awalan.search(s)
		if m != null:
			var sisa: = m.get_string(2)
			var t: = _terjemah(sisa, dalam + 1)
			if t != sisa:
				return m.get_string(1) + t


		var akhir: = s[-1]
		if akhir in [".", "!", "?", ":", ","] and s.length() > 2 and not s.contains("\n"):
			var tanpa: = s.left(-1)
			var t2: = _terjemah(tanpa, dalam + 1)
			if t2 != tanpa:
				return t2 + akhir

	if s.contains("\n"):
		var baris: = s.split("\n")
		var berubah: = false
		for i in baris.size():
			var t: = _terjemah(baris[i], dalam)
			if t != baris[i]:
				berubah = true
				baris[i] = t
		if berubah:
			return "\n".join(baris)
		return s

	if dalam < KEDALAMAN_MAKS:
		var kalimat: = _pecah_kalimat(s)
		if kalimat.size() > 1:
			var semua: = true
			var keluar: Array = []
			for k in kalimat:
				var t: = _terjemah(k, dalam + 1)
				if t == k and _tampak_indonesia(k) and not _utuh.has(k):
					semua = false
				keluar.append(t)
			if semua:
				return " ".join(keluar)
	if dalam == 0:
		_catat_belum(s)
	return s


func _beda_huruf(s: String) -> String:
	var kunci: = ""
	var kecil: = s.to_lower()
	var awal_besar: = s.left(1).to_upper() + kecil.substr(1)
	if _utuh.has(kecil):
		kunci = kecil
	elif _utuh.has(awal_besar):
		kunci = awal_besar
	if kunci == "" or kunci == s:
		return ""
	var t: = String(_utuh[kunci])
	if s == s.to_upper():
		return t.to_upper()
	if s.length() > 1 and s == s.capitalize() and s.contains(" "):
		return t.capitalize()
	if s.left(1) == s.left(1).to_upper():
		return t.left(1).to_upper() + t.substr(1)
	return t.left(1).to_lower() + t.substr(1)


func _cocok_pola(s: String, dalam: int, abaikan_huruf: = false) -> String:
	if dalam > KEDALAMAN_MAKS:
		return ""
	var s_kecil: = s.to_lower()
	for p in _pola:
		if abaikan_huruf:
			if p[3] != "" and not s_kecil.contains(String(p[3]).to_lower()):
				continue
		elif p[3] != "" and not s.contains(p[3]):
			continue
		var m: RegExMatch = (p[5 if abaikan_huruf else 0] as RegEx).search(s)
		if m == null:
			continue
		var hasil: = String(p[1])
		var nama: Array = p[2]
		var urut: = 0
		for g in nama.size():
			var isi: = m.get_string(g + 1)
			var t: = _terjemah(isi, dalam + 1)
			var kunci: = String(nama[g])
			if kunci.is_valid_int():

				if hasil.contains("{%s}" % kunci):
					hasil = hasil.replace("{%s}" % kunci, t)
				else:
					var pos: = _cari_isian(hasil, urut)
					if pos.x >= 0:
						hasil = hasil.substr(0, pos.x) + t + hasil.substr(pos.y)
						urut = pos.x + t.length()
			else:
				hasil = hasil.replace("{%s}" % kunci, t)
		return hasil.replace("%%", "%")
	return ""



func _cari_isian(t: String, dari: int) -> Vector2i:
	var m: = _re_isian_format.search(t, dari)
	while m != null:
		var a: = m.get_start()
		if a > 0 and t[a - 1] == "%":
			m = _re_isian_format.search(t, m.get_end())
			continue
		return Vector2i(a, m.get_end())
	return Vector2i(-1, -1)


func _pecah_kalimat(s: String) -> PackedStringArray:
	var hasil: = PackedStringArray()
	var awal: = 0
	for m in _re_kalimat.search_all(s):
		hasil.append(s.substr(awal, m.get_start() - awal))
		awal = m.get_end()
	hasil.append(s.substr(awal))
	return hasil



const KATA_UMUM: = ["yang", "dan", "di", "ke", "dari", "ini", "itu", "untuk", "tidak", "sudah", "belum", "ada", "bisa", 
	"saya", "kamu", "lagi", "dengan", "akan", "warga", "beli", "jual", "hari", "uang", "harga", "barang", "pembeli", 
	"tutup", "buka", "kembali", "lanjut", "pak", "bu", "ya", "nggak", "aja", "dulu", "baru", "jam", "menit"]


func _tampak_indonesia(s: String) -> bool:
	for k in s.to_lower().split(" ", false):
		if KATA_UMUM.has(k.strip_edges().trim_suffix(",").trim_suffix(".").trim_suffix("!").trim_suffix("?")):
			return true
	return false


func _catat_belum(s: String) -> void :
	if not _catat or _belum.has(s) or _belum.size() > 3000 or not _tampak_indonesia(s):
		return
	_belum[s] = true
	var f: = FileAccess.open(FILE_BELUM, FileAccess.READ_WRITE if FileAccess.file_exists(FILE_BELUM) else FileAccess.WRITE)
	if f == null:
		return
	f.seek_end()
	f.store_line(s.c_escape())
	f.close()
