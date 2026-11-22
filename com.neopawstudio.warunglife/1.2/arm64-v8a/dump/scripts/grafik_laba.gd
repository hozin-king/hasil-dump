extends Control





const MAKS_HARI: = 7
const WARNA_HARI_INI: = Color(0.45, 0.85, 0.45)
const WARNA_LALU: = Color(0.45, 0.85, 0.45, 0.4)
const WARNA_TEKS: = Color(1, 1, 1, 0.92)

var data: Array = []
var font: Font


func atur(riwayat: Array) -> void :
	data = riwayat.slice(maxi(riwayat.size() - MAKS_HARI, 0))
	font = get_theme_default_font()
	queue_redraw()


func _draw() -> void :

	var kosong: = MAKS_HARI - data.size()
	var hari_akhir: = int(data[-1]["hari"]) if not data.is_empty() else GameState.hari
	if data.is_empty():
		return
	var bawah: = size.y - 30.0
	var atas: = 30.0
	var tertinggi: = 1
	for d in data:
		tertinggi = maxi(tertinggi, int(d.get("bersih", d["laba"])))
	var kolom: = size.x / MAKS_HARI
	var lebar_batang: = minf(kolom * 0.6, 56.0)
	for i in data.size():
		var d: Dictionary = data[i]
		var x: = kolom * (i + 0.5)
		var hari_ini: = i == data.size() - 1
		var laba: = maxi(int(d.get("bersih", d["laba"])), 0)
		var tinggi: = maxf((bawah - atas) * float(laba) / tertinggi, 3.0)
		var warna: = WARNA_HARI_INI if hari_ini else WARNA_LALU
		draw_rect(Rect2(Vector2(x - lebar_batang / 2.0, bawah - tinggi), Vector2(lebar_batang, tinggi)), warna)
		draw_string(font, Vector2(x - kolom / 2.0, bawah - tinggi - 8.0), GameState.tk(GameState.rupiah_singkat(laba)), HORIZONTAL_ALIGNMENT_CENTER, kolom, 17 if hari_ini else 15, WARNA_TEKS)
		var label: = "Hari ini" if hari_ini else GameState.nama_hari_ke(int(d["hari"])).left(3)
		draw_string(font, Vector2(x - kolom / 2.0, bawah + 22.0), GameState.tk(label), HORIZONTAL_ALIGNMENT_CENTER, kolom, 17 if hari_ini else 15, WARNA_TEKS)
	for j in kosong:
		var x: = kolom * (data.size() + j + 0.5)
		var h_depan: = hari_akhir + j + 1
		draw_rect(Rect2(Vector2(x - lebar_batang / 2.0, bawah - 3.0), Vector2(lebar_batang, 3.0)), Color(1, 1, 1, 0.15))
		draw_string(font, Vector2(x - kolom / 2.0, bawah - 11.0), GameState.tk(GameState.rupiah_singkat(0)), HORIZONTAL_ALIGNMENT_CENTER, kolom, 15, Color(1, 1, 1, 0.3))
		draw_string(font, Vector2(x - kolom / 2.0, bawah + 22.0), GameState.tk(GameState.nama_hari_ke(h_depan).left(3)), HORIZONTAL_ALIGNMENT_CENTER, kolom, 15, Color(1, 1, 1, 0.3))
	draw_line(Vector2(0, bawah), Vector2(size.x, bawah), WARNA_TEKS, 2.0)
