extends Control




const MAKS_HARI: = 7
const WARNA_OMZET: = Color(0.96, 0.56, 0.16)
const WARNA_LABA: = Color(0.27, 0.7, 0.33)
const WARNA_TEKS: = Color(0.36, 0.22, 0.1)
const WARNA_GARIS: = Color(0.36, 0.22, 0.1, 0.18)

var data: Array = []
var font: Font


func atur(riwayat: Array) -> void :
	data = riwayat.slice(maxi(riwayat.size() - MAKS_HARI, 0))
	font = get_theme_default_font()
	queue_redraw()


func _draw() -> void :
	if data.is_empty():
		return
	var kiri: = 70.0
	var bawah: = size.y - 34.0
	var atas: = 12.0
	var lebar: = size.x - kiri - 8.0
	var tertinggi: = 1
	for d in data:
		tertinggi = maxi(tertinggi, int(d["omzet"]))
	tertinggi = _angka_bulat(tertinggi)


	for i in 4:
		var nilai: = tertinggi * i / 3
		var y: = bawah - (bawah - atas) * float(i) / 3.0
		draw_line(Vector2(kiri, y), Vector2(size.x - 8.0, y), WARNA_GARIS, 1.0)
		draw_string(font, Vector2(0, y + 6), GameState.tk("%drb" % (nilai / 1000)), HORIZONTAL_ALIGNMENT_RIGHT, kiri - 8.0, 15, WARNA_TEKS)

	var kolom: = lebar / MAKS_HARI
	var lebar_batang: = minf(kolom * 0.32, 26.0)
	for i in data.size():
		var d: Dictionary = data[i]
		var x: = kiri + kolom * (i + 0.5)
		var hari_ini: = i == data.size() - 1
		for j in 2:
			var nilai: float = float(d["omzet"] if j == 0 else maxi(int(d["laba"]), 0))
			var tinggi: = (bawah - atas) * nilai / tertinggi
			var posisi: = Vector2(x - lebar_batang - 2.0 + j * (lebar_batang + 4.0), bawah - tinggi)
			var warna: = WARNA_OMZET if j == 0 else WARNA_LABA
			if not hari_ini:
				warna = warna.lerp(Color(0.85, 0.8, 0.72), 0.35)
			draw_rect(Rect2(posisi, Vector2(lebar_batang, tinggi)), warna)
		var tgl: Dictionary = GameState.tanggal(int(d["hari"]))
		var label: = "%d/%d" % [int(tgl["day"]), int(tgl["month"])]
		draw_string(font, Vector2(x - kolom / 2.0, bawah + 22), GameState.tk(label), HORIZONTAL_ALIGNMENT_CENTER, kolom, 15 if not hari_ini else 16, WARNA_TEKS)
	draw_line(Vector2(kiri, bawah), Vector2(size.x - 8.0, bawah), WARNA_TEKS, 2.0)



func _angka_bulat(n: int) -> int:
	var langkah: = 10000
	for l in [10000, 25000, 50000, 100000, 250000, 500000, 1000000]:
		langkah = l
		if n <= l * 3:
			break
	return maxi(ceili(float(n) / (langkah * 3)) * langkah * 3, langkah * 3)
