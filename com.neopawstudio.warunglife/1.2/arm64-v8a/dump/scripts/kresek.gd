extends Control








signal dijatuhi(id: String)
signal diketuk

const FILE_3D: = "res://assets/kresek/kresek.glb"
const WARNA_PLASTIK: = Color(0.07, 0.07, 0.08)
const WARNA_KILAP: = Color(0.35, 0.35, 0.38, 0.7)
const WARNA_SOROT: = Color(1.0, 0.85, 0.3)

const KAKU: = 210.0
const REDAM: = 10.0
const KAKU_GOYANG: = 140.0
const REDAM_GOYANG: = 7.0
const TULANG_PEGANGAN: = ["Bone_005", "Bone_007"]
const TULANG_BADAN: = ["Bone_003", "Bone_002"]

var isi: Array[String] = []
var _disorot: = false


var siap: = false:
	set(v):
		if v != siap:
			siap = v
			queue_redraw()

var _vp: SubViewport = null
var _gambar: TextureRect
var _label: Label
var _model: Node3D
var _skala_model: = Vector3.ONE
var _rangka: Skeleton3D = null
var _rest: = {}
var _per: = 0.0
var _kec: = 0.0
var _goyang: = 0.0
var _kec_goyang: = 0.0
var _diam: = 0


func _ready() -> void :

	if custom_minimum_size == Vector2.ZERO:
		custom_minimum_size = Vector2(180, 180)
	size = custom_minimum_size
	if pivot_offset == Vector2.ZERO:
		pivot_offset = size / 2.0
	mouse_filter = Control.MOUSE_FILTER_STOP
	if ResourceLoader.exists(FILE_3D):
		_siapkan_3d()


func _siapkan_3d() -> void :
	var adegan = load(FILE_3D)
	if not adegan is PackedScene:
		return
	_vp = SubViewport.new()
	_vp.size = Vector2i(360, 360)
	_vp.transparent_bg = true
	_vp.own_world_3d = true
	_vp.msaa_3d = GameState.msaa_3d()
	_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(_vp)
	var env: = Environment.new()
	env.background_mode = Environment.BG_CLEAR_COLOR
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.8, 0.75, 0.7)
	env.ambient_light_energy = 0.5
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	var dunia: = WorldEnvironment.new()
	dunia.environment = env
	_vp.add_child(dunia)
	var lampu: = DirectionalLight3D.new()
	lampu.light_color = Color(1.0, 0.9, 0.78)
	lampu.light_energy = 1.4
	lampu.rotation = Vector3(deg_to_rad(-40), deg_to_rad(-25), 0)
	_vp.add_child(lampu)
	_model = (adegan as PackedScene).instantiate()
	_vp.add_child(_model)
	_skala_model = _model.scale
	var kamera: = Camera3D.new()
	kamera.projection = Camera3D.PROJECTION_ORTHOGONAL
	kamera.size = 2.3
	var sudut: = deg_to_rad(22.0)
	var sasaran: = Vector3(0, 0.9, 0)
	kamera.position = sasaran + Vector3(0, sin(sudut), cos(sudut)) * 6.0
	kamera.rotation.x = - sudut
	_vp.add_child(kamera)
	kamera.current = true
	_rangka = _cari_rangka(_model)
	if _rangka != null:
		for nama in TULANG_PEGANGAN + TULANG_BADAN:
			var i: = _rangka.find_bone(nama)
			if i >= 0:
				_rest[i] = _rangka.get_bone_rest(i).basis.get_rotation_quaternion()
	_gambar = TextureRect.new()
	_gambar.texture = _vp.get_texture()
	_gambar.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_gambar.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_gambar.set_anchors_preset(Control.PRESET_FULL_RECT)
	_gambar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_gambar)
	_label = Label.new()
	_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	_label.add_theme_font_size_override("font_size", 17)
	_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.9))
	_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	_label.add_theme_constant_override("outline_size", 5)
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label.visible = false
	add_child(_label)
	_perbarui_label()


func _cari_rangka(n: Node) -> Skeleton3D:
	if n is Skeleton3D:
		return n
	for c in n.get_children():
		var r: = _cari_rangka(c)
		if r != null:
			return r
	return null


func atur_isi(keranjang: Dictionary) -> void :
	var baru: Array[String] = []
	for id in keranjang:
		for i in int(keranjang[id]):
			baru.append(String(id))

	if baru == isi:
		return
	var lama: = isi.size()
	isi = baru
	_perbarui_label()
	if _vp != null:
		_perbarui_isi_3d(isi.size() > lama)
	queue_redraw()






const MAKS_ISI_3D: = 6
const UKURAN_BARANG_M: = 0.95
const Y_ISI: = 0.86
const Y_DASAR: = Y_ISI - UKURAN_BARANG_M / 2.0
const Y_MULUT: = 1.2
const NONGOL_MIN: = 0.15

const UKURAN_ASLI: = {
	"permen": 0.42, "sachet": 0.5, "obat": 0.38, "sabun": 0.65, "telur": 0.75, "susu_kotak": 0.7, "es_krim": 0.7, 
	"minuman_energi": 0.75, "kopi_susu": 0.8, "soda": 0.8, "kopi_bubuk": 0.8, "biskuit": 0.9, "buku_tulis": 0.9, 
	"teh_botol": 0.95, "mi_goreng": 1.0, "mi_rebus": 1.0, "air_mineral": 1.0, "makanan_kucing": 1.0, "gula": 1.0, 
	"rengginang": 1.05, "sayur": 1.05, "deterjen": 1.1, "minyak_goreng": 1.15, "kerupuk": 1.2, "ciki": 1.25, 
	"beras": 1.3, "lpg": 1.45, "galon": 1.5, 
	"danda": 0.55, "data_2gb": 0.55, "data_5gb": 0.55, "data_10gb": 0.55, "token_listrik": 0.55}
var _isi_3d: Array[Sprite3D] = []


func _perbarui_isi_3d(ada_baru: bool) -> void :
	for s in _isi_3d:
		s.queue_free()
	_isi_3d.clear()
	var tampil: = isi.slice(maxi(isi.size() - MAKS_ISI_3D, 0))
	for i in tampil.size():
		var tex: Texture2D = load("res://assets/barang/%s.png" % tampil[i])
		if tex == null:
			continue
		var s: = Sprite3D.new()
		s.texture = tex
		s.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
		s.shaded = false
		var k: = float(UKURAN_ASLI.get(tampil[i], 1.0))
		var tinggi_m: = UKURAN_BARANG_M * k

		s.pixel_size = tinggi_m / maxf(maxf(tex.get_width(), tex.get_height()), 1.0) / _skala_model.y

		var baris: = i / 3
		var sebaris: = mini(3, tampil.size() - baris * 3)
		var x: = (float(i % 3) - (sebaris - 1) / 2.0) * 0.31 / maxf(k, 1.0)


		var y: = maxf(Y_DASAR + tinggi_m / 2.0, Y_MULUT + NONGOL_MIN - tinggi_m / 2.0)

		var pos: = Vector3(x + sin(i * 2.3) * 0.03, y + 0.12 - baris * 0.1, -0.12 + baris * 0.16 - (k - 1.0) * 0.12)
		s.position = pos / _skala_model
		s.rotation.z = sin(i * 1.7 + 0.5) * 0.22
		_model.add_child(s)
		_isi_3d.append(s)


		if ada_baru and i == tampil.size() - 1:
			var akhir: = s.position
			var ukuran: = s.pixel_size
			s.position.y += 0.5 / _skala_model.y
			s.pixel_size = ukuran * 1.35
			var tw: = s.create_tween().set_parallel()
			tw.tween_property(s, "position", akhir, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
			tw.tween_property(s, "pixel_size", ukuran, 0.3)
	_diam = 0
	_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS


func _perbarui_label() -> void :
	if _label != null:
		_label.text = "%d barang" % isi.size() if not isi.is_empty() else "Taruh di sini"


func pantul() -> void :
	if _vp != null:

		_kec -= 5.5
		_kec_goyang += randf_range(2.5, 4.0) * (1.0 if randf() < 0.5 else -1.0)
		_diam = 0
		_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		return
	var tw: = create_tween()
	tw.tween_property(self, "scale", Vector2(1.12, 0.92), 0.07)
	tw.tween_property(self, "scale", Vector2(0.96, 1.05), 0.08)
	tw.tween_property(self, "scale", Vector2.ONE, 0.1)


func _process(delta: float) -> void :
	if _vp == null or delta <= 0.0:
		return
	var langkah: = minf(delta, 1.0 / 30.0)
	_kec += ( - KAKU * _per - REDAM * _kec) * langkah
	_per += _kec * langkah
	_kec_goyang += ( - KAKU_GOYANG * _goyang - REDAM_GOYANG * _kec_goyang) * langkah
	_goyang += _kec_goyang * langkah
	var gerak: = absf(_per) + absf(_kec) * 0.05 + absf(_goyang) + absf(_kec_goyang) * 0.05
	if gerak < 0.002:
		_diam += 1
		if _diam == 3:
			_vp.render_target_update_mode = SubViewport.UPDATE_DISABLED
		return

	var p: = clampf(_per, -0.35, 0.35)
	_model.scale = _skala_model * Vector3(1.0 - p * 0.55, 1.0 + p, 1.0 - p * 0.55)
	_model.rotation.z = clampf(_goyang, -1.0, 1.0) * 0.14
	if _rangka != null:
		for i in _rest:
			var nama: = _rangka.get_bone_name(i)
			var q: Quaternion = _rest[i]
			if nama in TULANG_PEGANGAN:

				var arah: = -1.0 if nama == TULANG_PEGANGAN[0] else 1.0
				q = q * Quaternion(Vector3(0, 0, 1), arah * ( - p * 1.6) + _goyang * 0.35)
			else:
				q = q * Quaternion(Vector3(0, 0, 1), _goyang * 0.12)
			_rangka.set_bone_pose_rotation(i, q)


func _can_drop_data(_pos: Vector2, data: Variant) -> bool:
	var boleh: bool = data is Dictionary and data.has("barang")
	if boleh != _disorot:
		_disorot = boleh
		_sorot()
	return boleh


func _drop_data(_pos: Vector2, data: Variant) -> void :
	_disorot = false
	_sorot()
	dijatuhi.emit(String(data["barang"]))


func _notification(what: int) -> void :
	if what == NOTIFICATION_DRAG_END or what == NOTIFICATION_MOUSE_EXIT:
		if _disorot:
			_disorot = false
			_sorot()


func _sorot() -> void :
	if _gambar != null:
		_gambar.modulate = Color(1.35, 1.25, 0.85) if _disorot else Color.WHITE
	queue_redraw()






func _has_point(titik: Vector2) -> bool:
	var pusat: = Vector2(size.x * 0.5, size.y * 0.6)
	var jari: = Vector2(size.x * 0.33, size.y * 0.38)
	var d: = (titik - pusat) / jari
	return d.length_squared() <= 1.0


func _gui_input(event: InputEvent) -> void :
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		diketuk.emit()
		accept_event()


func _draw() -> void :
	var w: = size.x
	var h: = size.y
	if _vp != null:


		if siap:
			draw_set_transform(Vector2(w * 0.5, h * 0.84), 0.0, Vector2(1.0, 0.32))
			for i in 6:
				draw_circle(Vector2.ZERO, w * (0.62 - i * 0.07), Color(1.0, 0.85, 0.35, 0.13))
			for i in 24:
				if i % 2 == 0:
					draw_arc(Vector2.ZERO, w * 0.5, TAU * i / 24.0, TAU * (i + 1) / 24.0, 4, Color(1, 0.92, 0.5), 5.0, true)
			draw_set_transform(Vector2.ZERO)
		draw_set_transform(Vector2(w * 0.5, h * 0.86), 0.0, Vector2(1.0, 0.2))
		draw_circle(Vector2.ZERO, w * 0.36, Color(0, 0, 0, 0.35))
		draw_set_transform(Vector2.ZERO)

		if _disorot:
			draw_arc(Vector2(w / 2.0, h * 0.55), w * 0.46, 0.0, TAU, 40, WARNA_SOROT, 3.0, true)
		return

	draw_set_transform(Vector2(w * 0.5, h * 0.95), 0.0, Vector2(1.0, 0.22))
	draw_circle(Vector2.ZERO, w * 0.42, Color(0, 0, 0, 0.3))
	draw_set_transform(Vector2.ZERO)

	var tebal: = 9.0
	draw_arc(Vector2(w * 0.33, h * 0.3), w * 0.13, PI, TAU, 16, WARNA_PLASTIK, tebal, true)
	draw_arc(Vector2(w * 0.67, h * 0.3), w * 0.13, PI, TAU, 16, WARNA_PLASTIK, tebal, true)
	_gambar_isi(Vector2(w * 0.5, h * 0.22), w * 0.19, 46.0)

	var badan: = PackedVector2Array([
		Vector2(w * 0.16, h * 0.36), Vector2(w * 0.3, h * 0.4), Vector2(w * 0.5, h * 0.37), 
		Vector2(w * 0.7, h * 0.4), Vector2(w * 0.84, h * 0.36), 
		Vector2(w * 0.93, h * 0.62), Vector2(w * 0.9, h * 0.84), Vector2(w * 0.76, h * 0.93), 
		Vector2(w * 0.5, h * 0.95), Vector2(w * 0.24, h * 0.93), Vector2(w * 0.1, h * 0.84), 
		Vector2(w * 0.07, h * 0.62)])
	draw_colored_polygon(badan, WARNA_PLASTIK)
	if _disorot:
		var garis: = badan.duplicate()
		garis.append(badan[0])
		draw_polyline(garis, WARNA_SOROT, 4.0, true)

	draw_polyline(PackedVector2Array([Vector2(w * 0.22, h * 0.5), Vector2(w * 0.19, h * 0.64), Vector2(w * 0.22, h * 0.78)]), Color(WARNA_KILAP, 0.45), 4.0, true)
	draw_line(Vector2(w * 0.4, h * 0.4), Vector2(w * 0.44, h * 0.52), Color(WARNA_KILAP, 0.3), 2.0, true)
	draw_line(Vector2(w * 0.6, h * 0.4), Vector2(w * 0.57, h * 0.5), Color(WARNA_KILAP, 0.3), 2.0, true)

	var font: = get_theme_default_font()
	var teks: = "%d barang" % isi.size() if not isi.is_empty() else "Taruh di sini"
	var ukuran: = 18 if not isi.is_empty() else 15
	var lebar: = font.get_string_size(GameState.tk(teks), HORIZONTAL_ALIGNMENT_LEFT, -1, ukuran).x
	draw_string(font, Vector2((w - lebar) / 2.0, h * 0.72), GameState.tk(teks), HORIZONTAL_ALIGNMENT_LEFT, -1, ukuran, Color(1, 1, 1, 0.85))




func _gambar_isi(tengah: Vector2, jarak: float, s: float) -> void :
	var tampil: = isi.slice(maxi(isi.size() - 6, 0))
	for i in tampil.size():
		var tex: Texture2D = load("res://assets/barang/%s.png" % tampil[i])
		if tex == null:
			continue
		var sebaris: = mini(3, tampil.size() - (i / 3) * 3)
		var x: = tengah.x + (float(i % 3) - (sebaris - 1) / 2.0) * jarak - s / 2.0
		var pos: = Vector2(x, tengah.y - float(i / 3) * 16.0)
		draw_texture_rect(tex, Rect2(pos, Vector2(s, s)), false)
