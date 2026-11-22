extends "res://scripts/minigame/mg_dasar.gd"










const STAND: = Vector2(250, 222)
const HP_AWAL: = Vector2(810, 236)
const UKURAN_HP: = Vector2(150, 270)
const JARAK_PINDAI: = 110.0
const JARAK_PINDAI_LEPAS: = 200.0
const LAMA_PINDAI: = 0.7
const TERIMA: = Rect2(560, 344, 210, 62)
const TOLAK: = Rect2(800, 344, 210, 62)
const STRUK: = Rect2(560, 22, 450, 74)
const TOKO_LAIN: = ["Toko Sinar Jaya", "Warung Bu Tini", "Kios Mandiri", "Toko Berkah Abadi"]

var _tahap: = "seret"
var _hp: = HP_AWAL
var _pegang: = false
var _geser_pegang: = Vector2.ZERO
var _waktu_tahap: = 0.0
var _kasus: = {}
var _qr: = []
var _alasan: = ""
var _alasan_umur: = 0.0


const ZOOM: = 1.45
const POS_ZOOM: = Vector2(400, 214)
var _zoom: = 1.0


func _siapkan() -> void :
	cahaya_25d = {"dari": Vector2(520, -90), "warna": Color(1, 0.9, 0.62), "kuat": 1.0}
	judul = "Cek QRIS"
	petunjuk = "Seret HP pembeli ke QRIS. TERIMA hanya kalau berhasil, nominal pas, nama warung benar, dan bukan bukti palsu. Selain itu TOLAK!"
	durasi = 39.0
	target = 4.0

	contoh = {"jenis": "seret", "dari": HP_AWAL, "ke": Vector2(STAND.x, HP_AWAL.y), "teks": "Seret HP pembeli ke kode QRIS"}
	_buat_qr()
	_pembeli_baru()


func _buat_qr() -> void :
	var r: = RandomNumberGenerator.new()
	r.seed = hash(GameState.nama_warung)
	for y in 25:
		for x in 25:
			var di_penanda: = (x < 8 and y < 8) or (x > 16 and y < 8) or (x < 8 and y > 16)
			if not di_penanda and r.randf() < 0.48:
				_qr.append(Vector2i(x, y))


func _nama_toko() -> String:
	return GameState.nama_warung_lengkap().to_upper()



func _nama_mirip() -> String:
	var asli: = _nama_toko()
	if randf() < 0.5:
		return asli + [" JAYA", " 2", " BARU"].pick_random()
	var huruf: = asli.split("")
	var kandidat: = []
	for i in range(huruf.size()):
		if huruf[i] in ["A", "I", "U", "E", "O"] and i > 7:
			kandidat.append(i)
	if kandidat.is_empty():
		return asli + " JAYA"
	var i: int = kandidat.pick_random()
	huruf[i] = {"A": "E", "I": "E", "U": "O", "E": "A", "O": "U"}[huruf[i]]
	return "".join(huruf)


func _pembeli_baru() -> void :
	var total: = randi_range(5, 120) * 500
	var acak: = randf()

	var jenis: = "ok" if acak < 0.5 else ("nominal" if acak < 0.625 else ("gagal" if acak < 0.75 else ("toko" if acak < 0.875 else "palsu")))
	var dibayar: = total
	if jenis == "nominal":
		var selisih: int = [1000, 2000, 5000, 10000].pick_random()
		dibayar = total + selisih if randf() < 0.35 else maxi(total - selisih, 500)
		if dibayar == total:
			jenis = "ok"
	var toko: = _nama_toko()
	if jenis == "toko":
		toko = TOKO_LAIN.pick_random().to_upper() if randf() < 0.5 else _nama_mirip()
	_kasus = {"jenis": jenis, "total": total, "dibayar": dibayar, "toko": toko, 
		"palsu": ["ketik", "jam", "centang"].pick_random() if jenis == "palsu" else ""}
	_tahap = "seret"
	_hp = HP_AWAL + Vector2(420, 0) if main else HP_AWAL
	_waktu_tahap = 0.0


func _main(delta: float) -> void :
	_waktu_tahap += delta
	if _alasan != "":
		_alasan_umur += delta
		if _alasan_umur > 2.5:
			_alasan = ""
	var zoom_tuju: = ZOOM if _tahap == "putus" else 1.0
	_zoom = lerpf(_zoom, zoom_tuju, minf(delta * 10.0, 1.0))
	match _tahap:
		"putus":
			_hp = _hp.lerp(POS_ZOOM, minf(delta * 10.0, 1.0))
		"seret":
			if not _pegang:
				_hp = _hp.lerp(HP_AWAL, minf(delta * 9.0, 1.0))
		"pindai":
			_hp = _hp.lerp(STAND + Vector2(0, 8), minf(delta * 14.0, 1.0))
			if _waktu_tahap >= LAMA_PINDAI:
				_tahap = "putus"
				_waktu_tahap = 0.0
				GameState.bunyi("notif")
		"keluar":
			_hp.x -= delta * 1900.0
			if _waktu_tahap > 0.35:
				_pembeli_baru()


func _masukan(e: InputEvent) -> void :
	if tekan_awal(e):
		if _tahap == "seret" and Rect2(_hp - UKURAN_HP / 2.0, UKURAN_HP).grow(20).has_point(e.position):
			_pegang = true
			_geser_pegang = _hp - e.position
		elif _tahap == "putus":
			if TERIMA.has_point(e.position):
				_putuskan(true)
			elif TOLAK.has_point(e.position):
				_putuskan(false)
	elif lepas(e):


		if _pegang and _tahap == "seret" and _hp.distance_to(STAND) < JARAK_PINDAI_LEPAS:
			_tahap = "pindai"
			_waktu_tahap = 0.0
			GameState.bunyi("klik")
		_pegang = false
	elif e is InputEventMouseMotion and _pegang and _tahap == "seret":
		_hp = e.position + _geser_pegang
		if _hp.distance_to(STAND) < JARAK_PINDAI:
			_pegang = false
			_tahap = "pindai"
			_waktu_tahap = 0.0
			GameState.bunyi("klik")


func _putuskan(terima: bool) -> void :
	var benar: bool = (_kasus["jenis"] == "ok") == terima
	var p: = TERIMA.get_center() if terima else TOLAK.get_center()
	if benar:
		var alasan: = {"ok": "Lunas!", "nominal": "Nominal tidak sesuai!", "gagal": "Saldo kurang!", "toko": "Nama warung salah!", "palsu": "Bukti bayar palsu!"}
		tambah_skor(1, p + Vector2(0, -60))
		kilat(Vector2(UKURAN.x * 0.62, 150), alasan[_kasus["jenis"]], Color(0.5, 1, 0.55))
		percik(p, Color(0.5, 1, 0.55), 12, 5.0)
	else:
		tambah_skor(-1, p + Vector2(0, -60))

		var sebab: = {"nominal": "Nominalnya %s, totalnya %s" % [GameState.format_rupiah(int(_kasus["dibayar"])), GameState.format_rupiah(int(_kasus["total"]))], 
			"gagal": "Pembayarannya gagal", "toko": "Nama warungnya beda: %s" % String(_kasus["toko"]), 
			"palsu": {"ketik": "Salah ketik: \"Berhasll\"", "jam": "Bukti bayar kemarin", "centang": "Tidak ada tanda centang"}.get(String(_kasus.get("palsu", "")), "Bukti bayar palsu")}
		kilat(Vector2(UKURAN.x * 0.62, 150), "Harusnya ditolak!" if terima else "Harusnya diterima!", Color(1, 0.4, 0.35))
		_alasan = "Semuanya sudah benar." if not terima else String(sebab.get(String(_kasus["jenis"]), ""))
		_alasan_umur = 0.0
	_tahap = "keluar"
	_waktu_tahap = 0.0



func _gambar() -> void :
	_meja()
	_stand()
	_sorotan()
	_struk()
	_gambar_hp(_hp)
	if _tahap == "putus":
		_tombol(TERIMA, "Terima", Color(0.2, 0.62, 0.3))
		_tombol(TOLAK, "Tolak", Color(0.78, 0.22, 0.2))
	elif _tahap == "seret" and main:
		teks(Vector2(785, 392), "Seret HP ke kode QRIS", 22, Color(1, 1, 1, 0.9), 420, 6)
	if _alasan != "":
		var a: = clampf((2.5 - _alasan_umur) / 0.4, 0.0, 1.0)
		teks(Vector2(785, 250), _alasan, 22, Color(1, 0.88, 0.82, a), 460, 6)



func _meja() -> void :
	gradasi(Rect2(Vector2.ZERO, UKURAN), Color(0.5, 0.33, 0.19), Color(0.34, 0.21, 0.11))
	for i in 9:
		var y: = 20.0 + i * 50.0
		kanvas.draw_line(Vector2(0, y), Vector2(UKURAN.x, y + 6), Color(0.28, 0.16, 0.08, 0.5), 2)
		kanvas.draw_line(Vector2(0, y + 2), Vector2(UKURAN.x, y + 8), Color(0.85, 0.62, 0.4, 0.12), 1)



func _stand() -> void :
	var papan: = Rect2(STAND - Vector2(115, 150), Vector2(230, 300))
	bayangan(Vector2(STAND.x + 18, papan.end.y + 6), 280, 0.35)
	kotak_bulat(Rect2(STAND.x - 70, papan.end.y - 8, 140, 18), Color(0.75, 0.78, 0.82), 6)
	kotak_bulat(Rect2(papan.position + Vector2(6, 8), papan.size), Color(0, 0, 0, 0.25), 14)
	kotak_bulat(papan, Color(0.97, 0.97, 0.96), 14)
	kotak_bulat(Rect2(papan.position, Vector2(papan.size.x, 52)), Color(0.82, 0.12, 0.16), 14)
	kanvas.draw_rect(Rect2(papan.position + Vector2(0, 34), Vector2(papan.size.x, 18)), Color(0.82, 0.12, 0.16))
	teks(papan.position + Vector2(papan.size.x / 2.0, 24), "QRIS", 30, Color.WHITE, 200)

	var sisi: = 6.0
	var kiri: = STAND - Vector2(25, 25) * sisi / 2.0 + Vector2(0, 8)
	kanvas.draw_rect(Rect2(kiri - Vector2(6, 6), Vector2(25, 25) * sisi + Vector2(12, 12)), Color.WHITE)
	for m in _qr:
		kanvas.draw_rect(Rect2(kiri + Vector2(m) * sisi, Vector2(sisi, sisi)), Color(0.08, 0.08, 0.1))
	for sudut in [Vector2(0, 0), Vector2(18, 0), Vector2(0, 18)]:
		var p: Vector2 = kiri + sudut * sisi
		kanvas.draw_rect(Rect2(p, Vector2(7, 7) * sisi), Color(0.08, 0.08, 0.1))
		kanvas.draw_rect(Rect2(p + Vector2(1, 1) * sisi, Vector2(5, 5) * sisi), Color.WHITE)
		kanvas.draw_rect(Rect2(p + Vector2(2, 2) * sisi, Vector2(3, 3) * sisi), Color(0.08, 0.08, 0.1))
	teks(Vector2(STAND.x, papan.end.y - 26), _nama_toko(), 17, Color(0.2, 0.2, 0.22), 220)

	kanvas.draw_colored_polygon(PackedVector2Array([papan.position + Vector2(20, 60), papan.position + Vector2(70, 60), 
		papan.position + Vector2(30, 290), papan.position + Vector2(8, 290)]), Color(1, 1, 1, 0.18))



func _struk() -> void :
	panel_timbul(STRUK, Color(0.99, 0.96, 0.86), 12, 5)
	teks(Vector2(STRUK.position.x + 120, STRUK.position.y + 28), "Total belanja", 22, Color(0.35, 0.25, 0.15), 220)
	teks(Vector2(STRUK.position.x + 120, STRUK.position.y + 55), _nama_toko(), 17, Color(0.15, 0.3, 0.6), 230)
	teks(Vector2(STRUK.end.x - 120, STRUK.position.y + 38), GameState.format_rupiah(int(_kasus["total"])), 32, Color(0.7, 0.15, 0.1), 230)



func _sorotan() -> void :
	var kuat: = clampf((_zoom - 1.0) / (ZOOM - 1.0), 0.0, 1.0)
	if kuat <= 0.01:
		return
	kanvas.draw_rect(Rect2(Vector2.ZERO, UKURAN), Color(0, 0, 0, 0.55 * kuat))
	for i in 6:
		kanvas.draw_circle(_hp, 230.0 - i * 28.0, Color(1, 0.95, 0.75, 0.035 * kuat))


func _tombol(r: Rect2, isi: String, warna: Color) -> void :
	panel_timbul(r, warna, 14, 6)
	teks(r.get_center() + Vector2(0, -2), isi, 28, Color.WHITE, r.size.x, 5)



func _gambar_hp(p: Vector2) -> void :
	var r: = Rect2(p - UKURAN_HP / 2.0, UKURAN_HP)
	var miring: = 0.0 if _tahap != "seret" or not _pegang else -0.06
	kanvas.draw_set_transform(p, miring, Vector2(_zoom, _zoom))
	r.position -= p
	bayangan(Vector2(14, UKURAN_HP.y / 2.0 + 10), 170, 0.3)
	kotak_bulat(Rect2(r.position + Vector2(5, 7), r.size), Color(0, 0, 0, 0.3), 22)
	kotak_bulat(r, Color(0.12, 0.12, 0.14), 22)
	kanvas.draw_line(r.position + Vector2(20, 2), r.position + Vector2(r.size.x - 20, 2), Color(1, 1, 1, 0.3), 2)
	var layar: = r.grow(-8)
	layar.position.y += 10
	layar.size.y -= 18
	if _tahap == "seret" or _tahap == "pindai":
		kotak_bulat(layar, Color(0.16, 0.18, 0.2), 14)
		teks(Vector2(0, layar.position.y + 24), "Pindai QRIS", 16, Color.WHITE, layar.size.x)
		var bingkai: = Rect2(-48, -40, 96, 96)
		for sx in [0.0, 1.0]:
			for sy in [0.0, 1.0]:
				var titik: Vector2 = bingkai.position + bingkai.size * Vector2(sx, sy)
				var arah: = Vector2(1.0 - 2.0 * sx, 1.0 - 2.0 * sy)
				kanvas.draw_line(titik, titik + Vector2(arah.x * 22, 0), Color.WHITE, 4)
				kanvas.draw_line(titik, titik + Vector2(0, arah.y * 22), Color.WHITE, 4)
		if _tahap == "pindai":
			var y: = bingkai.position.y + bingkai.size.y * fposmod(_waktu_tahap * 2.4, 1.0)
			kanvas.draw_line(Vector2(bingkai.position.x, y), Vector2(bingkai.end.x, y), Color(0.3, 1, 0.45), 3)
			kanvas.draw_rect(Rect2(bingkai.position.x, y - 10, bingkai.size.x, 10), Color(0.3, 1, 0.45, 0.18))
	else:
		_layar_hasil(layar)
	kanvas.draw_circle(Vector2(0, r.position.y + 10), 3, Color(0.3, 0.3, 0.32))
	kanvas.draw_set_transform(Vector2.ZERO)



func _ukuran_muat(s: String, dasar: int, lebar: float) -> int:
	var font: = GH.cetak()
	var u: = dasar
	while u > 7 and font.get_string_size(GameState.tk(s), HORIZONTAL_ALIGNMENT_LEFT, -1, u).x > lebar:
		u -= 1
	return u



func _pecah_dua(s: String) -> Array:
	var tengah: = s.length() / 2
	var pos: = -1
	for i in s.length():
		if s[i] == " " and (pos < 0 or absi(i - tengah) < absi(pos - tengah)):
			pos = i
	if pos < 0:
		return [s.substr(0, tengah), s.substr(tengah)]
	return [s.substr(0, pos), s.substr(pos + 1)]


func _layar_hasil(layar: Rect2) -> void :
	var gagal: bool = String(_kasus["jenis"]) == "gagal"
	var warna: = Color(0.82, 0.2, 0.18) if gagal else Color(0.18, 0.6, 0.3)
	kotak_bulat(layar, Color(0.98, 0.98, 0.97), 14)
	kotak_bulat(Rect2(layar.position, Vector2(layar.size.x, 92)), warna, 14)
	kanvas.draw_rect(Rect2(layar.position + Vector2(0, 70), Vector2(layar.size.x, 22)), warna)
	var pusat: = Vector2(0, layar.position.y + 40)
	kanvas.draw_circle(pusat, 22, Color.WHITE)
	var palsu: = String(_kasus.get("palsu", ""))
	if gagal:
		kanvas.draw_line(pusat + Vector2(-9, -9), pusat + Vector2(9, 9), warna, 5)
		kanvas.draw_line(pusat + Vector2(9, -9), pusat + Vector2(-9, 9), warna, 5)
	elif palsu != "centang":
		kanvas.draw_polyline(PackedVector2Array([pusat + Vector2(-10, 0), pusat + Vector2(-3, 8), pusat + Vector2(11, -8)]), warna, 5)
	var status: = "Pembayaran Gagal" if gagal else ("Pembayaran Berhasll" if palsu == "ketik" else "Pembayaran Berhasil")
	teks(Vector2(0, layar.position.y + 80), status, 14, Color.WHITE, layar.size.x)
	var y: = layar.position.y + 118
	if gagal:
		teks(Vector2(0, y), "Saldo tidak cukup", 15, Color(0.45, 0.2, 0.18), layar.size.x)
		teks(Vector2(0, y + 32), GameState.format_rupiah(int(_kasus["total"])), 22, Color(0.5, 0.5, 0.5), layar.size.x)
	else:
		teks(Vector2(0, y), GameState.format_rupiah(int(_kasus["dibayar"])), 26, Color(0.1, 0.1, 0.12), layar.size.x)
		teks(Vector2(0, y + 34), "ke", 13, Color(0.45, 0.45, 0.48), layar.size.x)

		var nama: = String(_kasus["toko"])

		var dasar: = 15 if _tahap == "putus" else 13



		var lebar: = layar.size.x - 8
		var ukuran: = _ukuran_muat(nama, dasar, lebar)
		if ukuran >= 10:
			teks(Vector2(0, y + 56), nama, ukuran, Color(0.15, 0.3, 0.6), layar.size.x - 4)
		else:
			var baris: = _pecah_dua(nama)
			var u2: = mini(_ukuran_muat(baris[0], dasar, lebar), _ukuran_muat(baris[1], dasar, lebar))
			teks(Vector2(0, y + 50), baris[0], u2, Color(0.15, 0.3, 0.6), layar.size.x - 4)
			teks(Vector2(0, y + 50 + u2 + 2), baris[1], u2, Color(0.15, 0.3, 0.6), layar.size.x - 4)

	if _tahap == "putus":
		var denyut: = 0.65 + 0.35 * sin(_waktu_tahap * 6.0)
		var penting: = Rect2(layar.position.x + 4, layar.position.y + 98, layar.size.x - 8, 86 if not gagal else 64)
		kanvas.draw_rect(penting, Color(1, 0.82, 0.2, 0.12 * denyut))
		kanvas.draw_rect(penting, Color(1, 0.78, 0.1, denyut), false, 2.5)

	var jam: = "Kemarin %02d.%02d" % [int(_kasus["total"]) / 500 % 12 + 8, int(_kasus["total"]) / 500 * 7 % 60] if String(_kasus.get("palsu", "")) == "jam" else GameState.teks_jam()
	teks(Vector2(0, layar.end.y - 16), "QRIS · %s" % jam, 11, Color(0.55, 0.55, 0.58), layar.size.x)
