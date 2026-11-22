extends PanelContainer




const TEBAL_TIANG: = 9.0
const TEBAL_PAPAN: = 17.0

var tingkat: Array = []


func _ready() -> void :
	var kosong: = StyleBoxEmpty.new()
	kosong.content_margin_left = TEBAL_TIANG + 3
	kosong.content_margin_right = TEBAL_TIANG + 3
	kosong.content_margin_top = 6
	kosong.content_margin_bottom = TEBAL_PAPAN + 5
	add_theme_stylebox_override("panel", kosong)
	resized.connect(queue_redraw)
	sort_children.connect(queue_redraw)





static var kepekatan_dinding: = 0.42


const PAKAI_RAK_KAYU: = false

func _draw() -> void :
	if PAKAI_RAK_KAYU:
		_gambar_rak(kepekatan_dinding)
	else:
		_gambar_panel_datar()



const KEPEKATAN_PANEL: = 0.62
const GARIS_PAPAN: = true

func _gambar_panel_datar() -> void :
	var g: = StyleBoxFlat.new()
	g.bg_color = Color(0.2, 0.12, 0.06, KEPEKATAN_PANEL)
	g.border_color = Color(0.62, 0.42, 0.24, 0.9)
	g.set_border_width_all(2)
	g.set_corner_radius_all(18)
	draw_style_box(g, Rect2(Vector2.ZERO, size))
	if not GARIS_PAPAN:
		return

	var balik: = get_global_transform().affine_inverse()
	var batas: Array = []
	for baris in tingkat:
		if not is_instance_valid(baris) or not (baris as Control).visible:
			continue
		var r: Rect2 = (baris as Control).get_global_rect()
		batas.append([(balik * r.position).y, (balik * r.end).y])
	batas.sort_custom( func(a, b): return a[0] < b[0])
	for i in range(batas.size() - 1):
		var y: float = (float(batas[i][1]) + float(batas[i + 1][0])) / 2.0 + 6.0
		draw_line(Vector2(18, y), Vector2(size.x - 18, y), Color(1, 0.86, 0.6, 0.22), 1.5, true)




func _gambar_rak(a: float) -> void :
	var kayu_gelap: = Color(0.22, 0.13, 0.06)
	var kayu: = Color(0.5, 0.31, 0.15)
	var kayu_terang: = Color(0.74, 0.52, 0.3)
	var w: = size.x
	var h: = size.y

	draw_rect(Rect2(0, 0, w, h), Color(kayu_gelap, a))
	var x: = 34.0
	while x < w - 20.0:
		draw_line(Vector2(x, 4), Vector2(x, h - 4), Color(0, 0, 0, a * 0.35), 2.0)
		draw_line(Vector2(x + 2, 4), Vector2(x + 2, h - 4), Color(kayu_terang, a * 0.18), 1.0)
		x += 42.0

	draw_rect(Rect2(0, 0, w, 8), Color(kayu, 0.9))
	draw_line(Vector2(0, 8), Vector2(w, 8), Color(0, 0, 0, 0.35), 2.0)

	for baris in tingkat:
		if not is_instance_valid(baris) or not (baris as Control).visible:
			continue
		var r: Rect2 = (baris as Control).get_global_rect()
		var y: float = (get_global_transform().affine_inverse() * r.end).y
		draw_rect(Rect2(TEBAL_TIANG, y, w - 2 * TEBAL_TIANG, TEBAL_PAPAN), Color(kayu, 0.78))
		draw_line(Vector2(TEBAL_TIANG, y), Vector2(w - TEBAL_TIANG, y), Color(kayu_terang, 0.9), 2.0)
		draw_line(Vector2(TEBAL_TIANG, y + TEBAL_PAPAN), Vector2(w - TEBAL_TIANG, y + TEBAL_PAPAN), Color(0, 0, 0, 0.4), 3.0)

	for tx in [0.0, w - TEBAL_TIANG]:
		draw_rect(Rect2(tx, 0, TEBAL_TIANG, h), Color(kayu, 0.92))
		draw_line(Vector2(tx + 2, 0), Vector2(tx + 2, h), Color(kayu_terang, 0.7), 1.5)

	draw_rect(Rect2(0, h - 5, w, 5), Color(kayu_gelap, 0.95))
