extends "res://scripts/minigame/mg_dasar.gd"










const POTRET: = {"Bu Ida": "warga_ibu_rumah_tangga", "Nenek Sumi": "warga_nenek", "Abah Karta": "warga_petani", 
	"Pak RT": "warga_pak_rt", "Kang Dadan": "warga_kurir", "Mang Ujang": "warga_tukang", "Kang Asep": "warga_ojek", 
	"Kang Fadil": "warga_santri_putih", "Kang Hasan": "warga_santri_hitam", "Mba Giska": "warga_giska"}

const SETELAN: = {
	"antar": {"judul": "Antar pesanan Kang Asep", "petunjuk": "Baca nama di kresek, klik rumah tujuannya!", 
		"sasaran": [["Bu Ida", Color(0.85, 0.3, 0.3)], ["Nenek Sumi", Color(0.3, 0.5, 0.9)], ["Abah Karta", Color(0.35, 0.7, 0.35)], ["Pak RT", Color(0.95, 0.68, 0.2)]], 
		"bentuk": "rumah", "acak": false, "latar": [Color(0.32, 0.34, 0.4), Color(0.2, 0.21, 0.26)]}, 
	"pesanan": {"judul": "Siapkan pesanan Kang Asep", "petunjuk": "Baca struknya, klik masakan yang dipesan!", 
		"sasaran": [["Mi goreng", "mi_goreng"], ["Mi rebus", "mi_rebus"], ["Telur dadar", "telur"], ["Kopi susu", "kopi_susu"]], 
		"bentuk": "piring", "acak": true, "latar": [Color(0.55, 0.36, 0.2), Color(0.4, 0.25, 0.14)]}, 
	"tukang": {"judul": "Masak sarapan para tukang", "petunjuk": "Dengar permintaan tukang, klik masakannya!", 
		"sasaran": [["Telur dadar", "telur"], ["Sayur", "sayur"], ["Kerupuk", "kerupuk"], ["Kopi susu", "kopi_susu"]], 
		"bentuk": "piring", "acak": true, "latar": [Color(0.55, 0.36, 0.2), Color(0.4, 0.25, 0.14)]}, 
	"kardus": {"judul": "Packing pesanan Mba Giska", "petunjuk": "Pilih kardus yang pas dengan ukuran barangnya!", 
		"sasaran": [["Kecil", 0], ["Sedang", 1], ["Besar", 2]], 
		"bentuk": "kardus", "acak": false, "latar": [Color(0.78, 0.7, 0.6), Color(0.62, 0.54, 0.45)], 
		"barang": [["sabun", 0], ["permen", 0], ["obat", 0], ["sachet", 0], ["minyak_goreng", 1], ["deterjen", 1], ["biskuit", 1], ["sirup", 1], ["galon", 2], ["beras", 2], ["lpg", 2]]}, 
	"sembako": {"judul": "Bagi sembako bareng Pak RT", "petunjuk": "Lihat kartu warga, klik namanya di daftar Pak RT!", 
		"bentuk": "nama", "acak": true, "latar": [Color(0.45, 0.55, 0.4), Color(0.32, 0.4, 0.28)], 
		"nama": ["Bu Ida", "Nenek Sumi", "Abah Karta", "Kang Dadan", "Mang Ujang", "Kang Asep", "Kang Fadil", "Kang Hasan", "Mba Giska"]}, 

	"kenduri": {"judul": "Siapkan nasi kotak Jumat berkah", "petunjuk": "Baca daftar isi kotak, klik lauk yang diminta!", 
		"sasaran": [["Nasi", "beras"], ["Telur", "telur"], ["Sayur", "sayur"], ["Kerupuk", "kerupuk"]], 
		"bentuk": "piring", "acak": true, "latar": [Color(0.35, 0.5, 0.42), Color(0.24, 0.36, 0.3)]}, 
}
const PANGGUNG: = Vector2(270, 215)

var _s: Dictionary
var _sasaran: = []
var _benda: = {}
var _goyang: = 0.0
var _terbang: = []
var _salah: = -1
var _salah_umur: = 0.0


func _siapkan() -> void :
	cahaya_25d = {"dari": Vector2(300, -60), "warna": Color(1, 0.92, 0.7), "kuat": 0.9}
	_s = SETELAN.get(varian, SETELAN["antar"])
	judul = _s["judul"]
	petunjuk = _s["petunjuk"]
	target = {"sembako": 13.0, "kardus": 14.0}.get(varian, 15.0)
	_atur_sasaran()
	_benda_baru()
	contoh = {"jenis": "ketuk", "dari": (_sasaran[int(_benda["jawab"])][2] as Rect2).get_center() + Vector2(-120, 0), "ke": Vector2.ZERO, 
		"teks": "Klik kartu yang cocok"}

	for n in POTRET:
		tekstur(_potret(n))
	for s in _s.get("sasaran", []):
		if s[1] is String:
			tekstur("res://assets/barang/%s.png" % s[1])
	for b in _s.get("barang", []):
		tekstur("res://assets/barang/%s.png" % b[0])
	for b in ["mi_goreng", "telur", "beras", "minyak_goreng", "gula"]:
		tekstur("res://assets/barang/%s.png" % b)


func _atur_sasaran() -> void :
	var daftar: Array
	if _s["bentuk"] == "nama":
		var semua: Array = (_s["nama"] as Array).duplicate()
		semua.shuffle()
		daftar = []
		for n in semua.slice(0, 4):
			daftar.append([n, n])
	else:
		daftar = (_s["sasaran"] as Array).duplicate()
		if _s["acak"]:
			daftar.shuffle()
	_sasaran.clear()
	var n: = daftar.size()
	var tinggi: = (UKURAN.y - 36.0 - (n - 1) * 12.0) / n
	for i in n:
		_sasaran.append([daftar[i][0], daftar[i][1], Rect2(565, 18 + i * (tinggi + 12), 455, tinggi)])


func _benda_baru() -> void :
	var lama: = String(_benda.get("teks", ""))
	if _s["bentuk"] == "nama" or _s["acak"]:
		_atur_sasaran()
	if _s["bentuk"] == "kardus":
		var b: Array = (_s["barang"] as Array).pick_random()
		var nama: = String(b[0]).replace("_", " ").capitalize()
		_benda = {"jawab": int(b[1]), "teks": nama, "ikon": "res://assets/barang/%s.png" % b[0], "ukuran": int(b[1]), "masuk": 0.0}
	else:
		var j: = randi() % _sasaran.size()
		if String(_sasaran[j][0]) == lama and _sasaran.size() > 1:
			j = (j + 1) % _sasaran.size()
		_benda = {"jawab": j, "teks": String(_sasaran[j][0]), "data": _sasaran[j][1], "masuk": 0.0}


func _main(delta: float) -> void :
	_benda["masuk"] = minf(float(_benda["masuk"]) + delta * 5.0, 1.0)
	_goyang = maxf(_goyang - delta * 3.0, 0.0)
	_salah_umur = maxf(_salah_umur - delta, 0.0)
	for t in _terbang:
		t[2] += delta * 3.0
	_terbang = _terbang.filter( func(t): return t[2] < 1.0)


func _masukan(e: InputEvent) -> void :
	if not tekan_awal(e) or float(_benda["masuk"]) < 0.6:
		return
	for i in _sasaran.size():
		var kotak: Rect2 = _sasaran[i][2]
		if kotak.has_point(e.position):
			if i == int(_benda["jawab"]):
				tambah_skor(1, kotak.get_center())
				_terbang.append([PANGGUNG, kotak.position + Vector2(60, kotak.size.y / 2.0), 0.0])
				_benda_baru()
			else:
				tambah_skor(-1, kotak.get_center())
				_goyang = 1.0
				_salah = i
				_salah_umur = 0.4
			return


func _gambar() -> void :
	var latar: Array = _s["latar"]
	gradasi(Rect2(Vector2.ZERO, UKURAN), latar[0], latar[1])

	for i in 5:
		kanvas.draw_circle(PANGGUNG, 230 - i * 30, Color(1, 0.95, 0.8, 0.04))
	kanvas.draw_line(Vector2(540, 20), Vector2(540, UKURAN.y - 20), Color(1, 1, 1, 0.12), 2)
	for i in _sasaran.size():
		_gambar_sasaran(i)
	var geser: = sin(_goyang * 30.0) * 14.0 * _goyang
	var p: = PANGGUNG + Vector2(lerpf(-460, 0, ease(float(_benda["masuk"]), 0.4)) + geser, 0)
	_gambar_benda(p)
	for t in _terbang:
		var titik: Vector2 = (t[0] as Vector2).lerp(t[1], ease(t[2], 0.5))
		kanvas.draw_circle(titik, 22 * (1.0 - t[2] * 0.6), Color(GH.KUNING, 1.0 - t[2]))


func _potret(nama: String) -> String:
	return "res://assets/potret/%s.png" % POTRET.get(nama, "warga_ibu_rumah_tangga")


func _gambar_sasaran(i: int) -> void :
	var s: Array = _sasaran[i]
	var kotak: Rect2 = s[2]
	var dasar: = Color(0.98, 0.95, 0.88)
	if i == _salah and _salah_umur > 0.0:
		dasar = dasar.lerp(Color(1, 0.45, 0.4), _salah_umur / 0.4)
	kotak_bulat(kotak, dasar, 14, 10.0)
	var ikon: = Vector2(kotak.position.x + 62, kotak.get_center().y)
	var ukuran_ikon: = minf(kotak.size.y - 14, 84.0)
	var nama_x: = kotak.position.x + 290
	match String(_s["bentuk"]):
		"rumah":
			var warna: Color = s[1]
			kanvas.draw_rect(Rect2(ikon - Vector2(38, 8), Vector2(76, 42)), Color(0.96, 0.9, 0.78))
			kanvas.draw_rect(Rect2(ikon + Vector2(-9, 10), Vector2(18, 24)), Color(0.45, 0.3, 0.2))
			kanvas.draw_rect(Rect2(ikon + Vector2(16, 2), Vector2(14, 12)), Color(0.6, 0.8, 0.95))
			kanvas.draw_colored_polygon(PackedVector2Array([ikon + Vector2(-48, -6), ikon + Vector2(0, -44), ikon + Vector2(48, -6)]), warna)
			gambar_tekstur(_potret(String(s[0])), Vector2(kotak.end.x - 50, kotak.get_center().y), ukuran_ikon * 0.85)
			nama_x = kotak.position.x + 240
		"piring":
			bayangan(ikon + Vector2(0, ukuran_ikon * 0.42), ukuran_ikon * 1.05, 0.2)
			kanvas.draw_circle(ikon, ukuran_ikon * 0.52, Color(1, 1, 1))
			kanvas.draw_arc(ikon, ukuran_ikon * 0.4, 0, TAU, 32, Color(0.85, 0.85, 0.85), 2)
			gambar_tekstur("res://assets/barang/%s.png" % s[1], ikon, ukuran_ikon * 0.9)
		"kardus":
			_kardus(ikon, int(s[1]))
		"nama":
			kanvas.draw_rect(Rect2(ikon - Vector2(20, 20), Vector2(40, 40)), Color.WHITE)
			kanvas.draw_rect(Rect2(ikon - Vector2(20, 20), Vector2(40, 40)), Color(0.3, 0.3, 0.35), false, 3)
			for g in 3:
				kanvas.draw_line(Vector2(kotak.position.x + 110, kotak.position.y + 14 + g * 18), Vector2(kotak.end.x - 14, kotak.position.y + 14 + g * 18), Color(0.55, 0.7, 0.9, 0.35), 1)
	teks(Vector2(nama_x, kotak.get_center().y), String(s[0]).to_upper(), 32, GH.TEKS_GELAP, 330)


func _kardus(tengah: Vector2, ukuran: int) -> void :
	var u: Vector2 = [Vector2(48, 32), Vector2(66, 44), Vector2(86, 58)][ukuran]
	var depan: = Rect2(tengah - Vector2(u.x / 2.0, u.y / 2.0 - 8), u)
	bayangan(Vector2(tengah.x, depan.end.y), u.x * 1.2, 0.25)
	var miring: = Vector2(14, -10) * (0.6 + ukuran * 0.2)
	kanvas.draw_colored_polygon(PackedVector2Array([depan.position, depan.position + miring, depan.position + Vector2(u.x, 0) + miring, depan.position + Vector2(u.x, 0)]), Color(0.86, 0.68, 0.45))
	kanvas.draw_colored_polygon(PackedVector2Array([depan.position + Vector2(u.x, 0), depan.position + Vector2(u.x, 0) + miring, depan.end + miring, depan.end]), Color(0.66, 0.5, 0.3))
	kanvas.draw_rect(depan, Color(0.78, 0.6, 0.38))
	kanvas.draw_rect(Rect2(depan.position + Vector2(u.x / 2.0 - 5, 0), Vector2(10, u.y)), Color(0.85, 0.82, 0.7, 0.8))


func _gambar_benda(p: Vector2) -> void :
	match String(_s["bentuk"]):
		"rumah":

			bayangan(p + Vector2(0, 100), 170, 0.3)
			var badan: = PackedVector2Array([p + Vector2(-70, -40), p + Vector2(70, -40), p + Vector2(85, 90), p + Vector2(-85, 90)])
			kanvas.draw_colored_polygon(badan, Color(0.97, 0.97, 0.97, 0.95))
			kanvas.draw_arc(p + Vector2(-38, -40), 26, PI, TAU, 16, Color(0.95, 0.95, 0.95), 9)
			kanvas.draw_arc(p + Vector2(38, -40), 26, PI, TAU, 16, Color(0.95, 0.95, 0.95), 9)
			kanvas.draw_rect(Rect2(p + Vector2(-80, 10), Vector2(160, 20)), _benda["data"])
			gambar_tekstur("res://assets/barang/mi_goreng.png", p + Vector2(-25, 58), 52, Color(1, 1, 1, 0.7))
			gambar_tekstur("res://assets/barang/telur.png", p + Vector2(28, 60), 48, Color(1, 1, 1, 0.7))
			kotak_bulat(Rect2(p + Vector2(-120, -140), Vector2(240, 64)), Color(1, 0.97, 0.85), 10, 6.0)
			teks(p + Vector2(0, -116), "UNTUK:", 18, Color(0.4, 0.35, 0.3), 220)
			teks(p + Vector2(0, -93), String(_benda["teks"]).to_upper(), 30, GH.TEKS_GELAP, 230)
		"piring":
			if varian == "tukang":
				gambar_tekstur(_potret("Mang Ujang"), p + Vector2(-110, 40), 150)
				_gelembung(p + Vector2(70, -40), "Minta %s, ya!" % String(_benda["teks"]).to_lower())
			else:

				var r: = Rect2(p - Vector2(130, 130), Vector2(260, 250))
				bayangan(Vector2(p.x, r.end.y + 14), 250, 0.3)
				var kertas: = PackedVector2Array([r.position, r.position + Vector2(r.size.x, 0)])
				for g in 11:
					kertas.append(Vector2(r.end.x - g * r.size.x / 10.0, r.end.y + (8 if g % 2 == 0 else 0)))
				kanvas.draw_colored_polygon(kertas, Color(1, 1, 0.97))
				teks(p + Vector2(0, -100), "NASI KOTAK" if varian == "kenduri" else "PESANAN ONLINE", 22, Color(0.45, 0.45, 0.45), 240)
				kanvas.draw_dashed_line(p + Vector2(-110, -78), p + Vector2(110, -78), Color(0.6, 0.6, 0.6), 2, 6)
				teks(p + Vector2(0, -30), "1x", 30, Color(0.45, 0.45, 0.45), 240)
				teks(p + Vector2(0, 15), String(_benda["teks"]).to_upper(), 40, GH.TEKS_GELAP, 250)
				kanvas.draw_dashed_line(p + Vector2(-110, 50), p + Vector2(110, 50), Color(0.6, 0.6, 0.6), 2, 6)
				teks(p + Vector2(0, 80), "Jumat berkah" if varian == "kenduri" else "Antar: Kang Asep", 20, Color(0.45, 0.45, 0.45), 240)
		"kardus":
			var besar: float = [110.0, 170.0, 240.0][int(_benda["ukuran"])]
			bayangan(p + Vector2(0, besar * 0.45), besar * 0.9, 0.3)
			gambar_tekstur(String(_benda["ikon"]), p, besar)
			kotak_bulat(Rect2(p + Vector2(-110, 140), Vector2(220, 48)), Color(0, 0, 0, 0.45), 10)
			teks(p + Vector2(0, 164), String(_benda["teks"]).to_upper(), 30, Color.WHITE, 220)
		"nama":
			var r: = Rect2(p - Vector2(170, 120), Vector2(340, 240))
			kotak_bulat(r, Color(0.98, 0.96, 0.9), 16, 12.0)
			kotak_bulat(Rect2(r.position, Vector2(r.size.x, 48)), Color(0.8, 0.25, 0.22), 16)
			kanvas.draw_rect(Rect2(r.position + Vector2(0, 30), Vector2(r.size.x, 18)), Color(0.8, 0.25, 0.22))
			teks(r.position + Vector2(r.size.x / 2.0, 24), "KARTU SEMBAKO RT 05", 22, Color.WHITE, 320)
			gambar_tekstur(_potret(String(_benda["teks"])), r.position + Vector2(85, 140), 120)
			teks(r.position + Vector2(240, 125), String(_benda["teks"]).to_upper(), 30, GH.TEKS_GELAP, 180)
			teks(r.position + Vector2(240, 160), "Penerima", 18, Color(0.45, 0.45, 0.45), 180)
			for i in 3:
				gambar_tekstur("res://assets/barang/%s.png" % ["beras", "minyak_goreng", "gula"][i], p + Vector2(-80 + i * 80, 175), 70)


func _gelembung(p: Vector2, isi: String) -> void :
	var r: = Rect2(p - Vector2(150, 60), Vector2(300, 120))
	kotak_bulat(r, Color(1, 1, 1), 26, 8.0)
	kanvas.draw_colored_polygon(PackedVector2Array([r.position + Vector2(40, r.size.y - 4), r.position + Vector2(90, r.size.y - 4), r.position + Vector2(10, r.size.y + 40)]), Color(1, 1, 1))
	teks(p, isi, 30, GH.TEKS_GELAP, 280)
