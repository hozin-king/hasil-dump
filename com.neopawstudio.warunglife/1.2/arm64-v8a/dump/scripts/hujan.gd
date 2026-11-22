extends Node2D





var ukuran: = Vector2(1280, 720)


var larangan: Array = []
var induk_percik: Node = null
var urutan_percik: = -1
var _percik: CPUParticles2D = null
var _suara: AudioStreamPlayer
var _jam_kilat: Timer
const VOLUME_SUARA_DB: = -13.0


func _ready() -> void :
	z_index = 20

	for lapis in [[3, 46, 700, 1700.0, 0.35], [5, 80, 260, 2300.0, 0.55]]:
		var g: = Gradient.new()
		g.set_color(0, Color(1, 1, 1, 0.0))
		g.set_color(1, Color(1, 1, 1, 1.0))
		var garis: = GradientTexture2D.new()
		garis.gradient = g
		garis.width = lapis[0]
		garis.height = lapis[1]
		garis.fill_from = Vector2(0, 0)
		garis.fill_to = Vector2(0, 1)
		var p: = CPUParticles2D.new()
		p.texture = garis
		p.amount = int(lapis[2] * clampf(ukuran.x * ukuran.y / (1536.0 * 1024.0), 0.4, 1.5))
		p.lifetime = (ukuran.y + 120.0) / lapis[3]
		p.preprocess = p.lifetime
		p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
		p.emission_rect_extents = Vector2(ukuran.x / 2.0 + 250.0, 10.0)
		p.direction = Vector2(-0.2, 1.0)
		p.spread = 2.0
		p.gravity = Vector2.ZERO
		p.initial_velocity_min = lapis[3] * 0.9
		p.initial_velocity_max = lapis[3] * 1.1
		p.particle_flag_align_y = true
		p.color = Color(0.8, 0.86, 0.98, lapis[4])
		if GameState.google_play_pc():
			p.material = GameState.bahan_partikel(p.color)
		p.position = Vector2(0, - ukuran.y / 2.0 - 60.0)
		add_child(p)

	var cincin: = GradientTexture2D.new()
	var gc: = Gradient.new()
	gc.offsets = PackedFloat32Array([0.0, 0.55, 0.75, 1.0])
	gc.colors = PackedColorArray([Color(1, 1, 1, 0), Color(1, 1, 1, 0), Color(1, 1, 1, 1), Color(1, 1, 1, 0)])
	cincin.gradient = gc
	cincin.fill = GradientTexture2D.FILL_RADIAL
	cincin.fill_from = Vector2(0.5, 0.5)
	cincin.fill_to = Vector2(1.0, 0.5)
	cincin.width = 32
	cincin.height = 32
	var percik: = CPUParticles2D.new()
	percik.texture = cincin
	percik.amount = 160
	percik.lifetime = 0.35
	percik.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	percik.emission_rect_extents = Vector2(ukuran.x / 2.0, ukuran.y * 0.3)
	percik.position = Vector2(0, ukuran.y * 0.18)
	percik.direction = Vector2.ZERO
	percik.spread = 0.0
	percik.gravity = Vector2.ZERO
	percik.initial_velocity_min = 0.0
	percik.initial_velocity_max = 0.0
	var besar: = Curve.new()
	besar.add_point(Vector2(0, 0.3))
	besar.add_point(Vector2(1, 1.0))
	percik.scale_amount_curve = besar
	percik.scale_amount_min = 0.5
	percik.scale_amount_max = 0.9
	var pudar: = Gradient.new()
	pudar.set_color(0, Color(0.85, 0.9, 1.0, 0.7))
	pudar.set_color(1, Color(0.85, 0.9, 1.0, 0.0))
	percik.color_ramp = pudar
	if GameState.google_play_pc():

		percik.color_ramp = null
		percik.material = GameState.bahan_partikel(Color(0.85, 0.9, 1.0, 0.45))
		var besar_pc: = Curve.new()
		besar_pc.add_point(Vector2(0, 0.3))
		besar_pc.add_point(Vector2(0.75, 1.0))
		besar_pc.add_point(Vector2(1, 0.0))
		percik.scale_amount_curve = besar_pc
	percik.scale = Vector2(1.0, 0.45)
	percik.z_index = -1
	if not larangan.is_empty():

		var titik: = PackedVector2Array()
		var coba: = 0
		while titik.size() < 2500 and coba < 20000:
			coba += 1
			var p: = Vector2(randf_range( - ukuran.x / 2.0, ukuran.x / 2.0), ukuran.y * 0.18 + randf_range( - ukuran.y * 0.3, ukuran.y * 0.3))
			var kena: = false
			for poli in larangan:
				if Geometry2D.is_point_in_polygon(p, poli):
					kena = true
					break
			if not kena:
				titik.append(Vector2(p.x, p.y / percik.scale.y))
		percik.emission_shape = CPUParticles2D.EMISSION_SHAPE_POINTS
		percik.emission_points = titik
		percik.position = Vector2.ZERO
	_percik = percik
	if induk_percik != null:
		percik.z_index = 0
		percik.position += position
		induk_percik.add_child(percik)
		if urutan_percik >= 0:
			induk_percik.move_child(percik, urutan_percik)
	else:
		add_child(percik)

	var kilat: = ColorRect.new()
	kilat.color = Color(0.85, 0.9, 1.0, 0.0)
	kilat.size = ukuran + Vector2(400, 400)
	kilat.position = - ukuran / 2.0 - Vector2(200, 200)
	kilat.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var terang: = CanvasItemMaterial.new()
	terang.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	kilat.material = terang
	add_child(kilat)
	_jam_kilat = Timer.new()
	_jam_kilat.one_shot = true
	add_child(_jam_kilat)
	_jam_kilat.timeout.connect( func():
		var t: = kilat.create_tween()
		t.tween_property(kilat, "color:a", 0.7, 0.04)
		t.tween_property(kilat, "color:a", 0.08, 0.1)
		t.tween_property(kilat, "color:a", 0.55, 0.04)
		t.tween_property(kilat, "color:a", 0.0, 0.5)
		GameState.get_tree().create_timer(randf_range(0.3, 1.2), false).timeout.connect( func(): GameState.bunyi(["petir", "petir_2", "petir_3"].pick_random()))
		_jam_kilat.start(randf_range(12.0, 25.0)))
	_jam_kilat.start(randf_range(2.0, 5.0))

	_suara = AudioStreamPlayer.new()
	_suara.stream = _buat_suara_hujan()
	_suara.volume_db = -50.0
	_suara.bus = "Sekitar"
	add_child(_suara)
	_suara.play()
	create_tween().tween_property(_suara, "volume_db", VOLUME_SUARA_DB, 2.5)


func _exit_tree() -> void :
	if is_instance_valid(_percik) and _percik.get_parent() != self:
		_percik.queue_free()



func berhenti() -> void :
	for p in get_children():
		if p is CPUParticles2D:
			p.emitting = false
	if is_instance_valid(_percik):
		_percik.emitting = false
	if _jam_kilat != null:
		_jam_kilat.stop()
	var t: = create_tween()
	if _suara != null:
		t.tween_property(_suara, "volume_db", -50.0, 2.0)
	else:
		t.tween_interval(1.0)
	t.tween_callback(queue_free)



static var _cache_suara: AudioStreamWAV

static func _buat_suara_hujan() -> AudioStreamWAV:
	if _cache_suara != null:
		return _cache_suara
	var laju: = 22050
	var jumlah: = laju * 3
	var data: = PackedByteArray()
	data.resize(jumlah * 2)
	var rendah: = 0.0
	var tinggi_lalu: = 0.0
	var tetes: = 0.0
	for i in jumlah:
		var putih: = randf_range(-1.0, 1.0)
		rendah = rendah * 0.86 + putih * 0.14
		var tinggi: = putih - tinggi_lalu * 0.7
		tinggi_lalu = putih
		if randf() < 0.0009:
			tetes = randf_range(0.3, 0.7)
		tetes *= 0.993
		var s: = rendah * 0.9 + tinggi * 0.12 + putih * tetes * 0.5

		var tepi: = minf(1.0, minf(i, jumlah - 1 - i) / 300.0)
		data.encode_s16(i * 2, int(clampf(s * tepi * 0.8, -1.0, 1.0) * 32767.0))
	var w: = AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = laju
	w.data = data
	w.loop_mode = AudioStreamWAV.LOOP_FORWARD
	w.loop_end = jumlah
	_cache_suara = w
	return w
