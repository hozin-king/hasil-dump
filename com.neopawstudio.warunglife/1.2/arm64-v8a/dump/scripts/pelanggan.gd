extends Sprite2D







signal sampai

const SCRIPT_KARAKTER_3D: = preload("res://scripts/karakter3d.gd")
const LANGKAH_PER_DETIK: = 2.4
const TINGGI_AYUN: = 5.0
const SUDUT_GOYANG: = 0.035
var tinggi_dewasa_latar: = 285.0
const TINGGI_DEWASA_METER: = 1.72

var tinggi_dasar: = 280.0
var y_berdiri: = 0.0
var sedang_jalan: = false
var waktu_jalan: = 0.0
var karakter: SubViewport = null
var skala_3d: = 1.0
var faktor_kecepatan: = 1.0
var cfg_3d: = {}
var _posisi_lalu: = Vector2.ZERO
var _lebar_bingkai_lalu: = 0
var bayangan: Sprite2D = null

var perspektif: Array = []

var arah_manual: = false



func atur(gambar: Texture2D, tinggi: float, y_titik_berdiri: float) -> void :
	texture = gambar
	tinggi_dasar = tinggi
	y_berdiri = y_titik_berdiri

	offset = Vector2(0, - gambar.get_height() / 2.0)
	_buat_bayangan(0.7)
	_perbarui_skala()



func atur_3d(cfg: Dictionary, y_titik_berdiri: float) -> void :
	cfg_3d = cfg
	faktor_kecepatan = float(cfg.get("kecepatan", 1.0))
	y_berdiri = y_titik_berdiri
	karakter = SCRIPT_KARAKTER_3D.new()

	if String(cfg.get("file", "")) != GameState.file_model_penjaga():
		karakter.jadikan_npc()
	add_child(karakter)
	karakter.rakit(cfg)
	_pasang_tekstur_3d()

	skala_3d = tinggi_dewasa_latar / (TINGGI_DEWASA_METER * karakter.piksel_per_meter())

	offset = Vector2(karakter.size) / 2.0 - karakter.titik_kaki()
	_buat_bayangan(0.85 * float(cfg.get("skala", 1.0)))
	_pasang_garis_tepi()
	_pasang_penanda_layar()
	_perbarui_skala()




func ganti_model_3d(cfg: Dictionary) -> void :
	var arah: = Vector2.DOWN
	var skala_lama: = skala_3d
	if is_instance_valid(karakter):
		arah = karakter.arah_layar
		karakter.queue_free()
	for n in [bayangan, _garis_tepi, _penanda_layar]:
		if is_instance_valid(n):
			n.queue_free()
	karakter = null
	bayangan = null
	_garis_tepi = null
	_penanda_layar = null
	texture = null
	atur_3d(cfg, y_berdiri)
	karakter.arah_layar = arah
	if skala_lama > 0.0:
		skala_3d = tinggi_dewasa_latar / (TINGGI_DEWASA_METER * karakter.piksel_per_meter())
		_perbarui_skala()







static var _bahan_garis: = {}
var _garis_tepi: Sprite2D = null

static func bahan_garis_tepi(skala_bingkai: float) -> ShaderMaterial:
	var kunci: = snappedf(skala_bingkai, 0.01)
	if not _bahan_garis.has(kunci):
		var b: = ShaderMaterial.new()
		b.shader = load("res://shader/npc_garis_tepi.gdshader")
		b.set_shader_parameter("garis", 3.0 * skala_bingkai)
		_bahan_garis[kunci] = b
	return _bahan_garis[kunci]


static var _bahan_warna: ShaderMaterial = null

func _pasang_garis_tepi() -> void :

	if GameState.kualitas == "rendah":
		return

	if material == null:
		if _bahan_warna == null:
			_bahan_warna = ShaderMaterial.new()
			_bahan_warna.shader = load("res://shader/npc_warna.gdshader")
		material = _bahan_warna
	_garis_tepi = Sprite2D.new()
	_garis_tepi.material = bahan_garis_tepi(karakter.skala_bingkai())
	_garis_tepi.show_behind_parent = true
	add_child(_garis_tepi)





var _penanda_layar: VisibleOnScreenNotifier2D = null

func _pasang_penanda_layar() -> void :
	_penanda_layar = VisibleOnScreenNotifier2D.new()
	add_child(_penanda_layar)
	_penanda_layar.screen_entered.connect( func(): if karakter != null: karakter.di_layar = true)
	_penanda_layar.screen_exited.connect( func(): if karakter != null: karakter.di_layar = false)


func _ikuti_penanda_layar() -> void :
	if _penanda_layar == null:
		return
	if texture == null:
		_penanda_layar.rect = Rect2(-50, -200, 100, 220)
	else:
		_penanda_layar.rect = get_rect().grow(get_rect().size.x * 0.25)




func skala_model() -> float:
	return float(cfg_3d.get("skala", 1.0)) if not cfg_3d.is_empty() else 1.0





var _posisi_laju_lalu: = Vector2.INF
var _laju_halus: = 0.0

func _ukur_laju_tanah(delta: float) -> void :
	if delta <= 0.0:
		return
	if _posisi_laju_lalu == Vector2.INF or not sedang_jalan:
		_posisi_laju_lalu = position
		_laju_halus = 0.0
		karakter.laju_tanah = -1.0
		return
	var g: = (position - _posisi_laju_lalu) / delta
	_posisi_laju_lalu = position
	var px_per_m: float = float(karakter.piksel_per_meter()) * absf(scale.x)
	if px_per_m <= 0.0:
		return
	var laju: float = Vector2(g.x, g.y / sin(deg_to_rad(float(karakter.SUDUT_KAMERA)))).length() / px_per_m

	_laju_halus = laju if _laju_halus <= 0.0 else lerpf(_laju_halus, laju, minf(delta * 6.0, 1.0))
	karakter.laju_tanah = _laju_halus



func _ikuti_garis_tepi() -> void :
	if _garis_tepi == null:
		return
	if _garis_tepi.texture != texture:
		_garis_tepi.texture = texture
	_garis_tepi.offset = offset
	_garis_tepi.centered = centered
	_garis_tepi.visible = texture != null and self_modulate.a > 0.01




func _pasang_tekstur_3d() -> void :
	texture = null
	for i in 3:
		await RenderingServer.frame_post_draw
	if is_instance_valid(karakter):
		texture = karakter.get_texture()



func hadap(arah: Vector2) -> void :
	if karakter != null:
		karakter.arah_layar = arah





var tween_jalan: Tween = null
var laju_jalan: = 0.0
var tertahan: = false
var skala_jalan: = 1.0
var lahir_ms: = Time.get_ticks_msec()



func jalan(titik: Array, kecepatan: float) -> void :
	sedang_jalan = true

	if karakter != null:
		karakter.batalkan_aksi()
	kecepatan *= faktor_kecepatan * skala_model()
	_posisi_lalu = position
	var tween: = create_tween()
	tween_jalan = tween
	laju_jalan = kecepatan
	tertahan = false
	skala_jalan = 1.0
	var dari: = position
	for t in titik:
		tween.tween_property(self, "position", t, dari.distance_to(t) / kecepatan)
		dari = t
	await tween.finished
	tertahan = false
	sedang_jalan = false
	rotation = 0.0
	if karakter == null:
		offset.y = - texture.get_height() / 2.0
	sampai.emit()




func pergi_pelan(titik: Array, kecepatan: float) -> void :
	await jalan(titik, kecepatan)
	var tween: = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.6)
	await tween.finished
	queue_free()



func pergi(titik: Array, kecepatan: float) -> void :
	var tween: = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 1.6).set_delay(0.6)
	jalan(titik, kecepatan)
	await tween.finished
	queue_free()


func _process(delta: float) -> void :
	_perbarui_skala()
	if karakter != null:
		karakter.berjalan = sedang_jalan and not tertahan

		if karakter.size.x != _lebar_bingkai_lalu:
			_lebar_bingkai_lalu = karakter.size.x
			offset = Vector2(karakter.size) / 2.0 - karakter.titik_kaki()
		var gerak: = position - _posisi_lalu



		if gerak.length() > 0.5:
			if sedang_jalan and not arah_manual:
				karakter.arah_layar = gerak.normalized()
			_posisi_lalu = position
		elif not sedang_jalan:
			_posisi_lalu = position
		_ikuti_garis_tepi()
		_ikuti_penanda_layar()
		_ukur_laju_tanah(delta)
		return
	if not sedang_jalan:
		return
	waktu_jalan += delta
	var fase: = waktu_jalan * LANGKAH_PER_DETIK * TAU
	var skala_gambar: = tinggi_dasar / texture.get_height()

	offset.y = - texture.get_height() / 2.0 - abs(sin(fase)) * TINGGI_AYUN / skala_gambar
	rotation = sin(fase) * SUDUT_GOYANG




func faktor_jarak() -> float:
	return _skala_perspektif() if not perspektif.is_empty() else clampf(1.0 + (position.y - y_berdiri) * 0.0008, 0.85, 1.15)



func _perbarui_skala() -> void :
	if texture == null and karakter == null:
		return
	var jarak: = faktor_jarak()
	var s: = (skala_3d if karakter != null else tinggi_dasar / texture.get_height()) * jarak
	scale = Vector2(s, s)



func _buat_bayangan(lebar: float) -> void :
	var gradasi: = Gradient.new()

	gradasi.offsets = PackedFloat32Array([0.0, 0.35, 1.0])
	gradasi.colors = PackedColorArray([Color(0, 0, 0, 0.62), Color(0, 0, 0, 0.36), Color(0, 0, 0, 0)])
	var tekstur: = GradientTexture2D.new()
	tekstur.gradient = gradasi
	tekstur.fill = GradientTexture2D.FILL_RADIAL
	tekstur.fill_from = Vector2(0.5, 0.5)
	tekstur.fill_to = Vector2(1.0, 0.5)
	tekstur.width = 128
	tekstur.height = 128
	bayangan = Sprite2D.new()
	bayangan.texture = tekstur
	bayangan.show_behind_parent = true
	add_child(bayangan)

	var s: = (skala_3d if karakter != null else tinggi_dasar / texture.get_height())
	bayangan.scale = Vector2(150.0 * lebar, 55.0 * lebar) / 128.0 / s




func aksi(jenis: String) -> void :
	var nama: String = cfg_3d.get("anim_" + jenis, "")
	if karakter != null and nama != "":
		await karakter.mainkan_sekali(nama)



func tinggi_badan() -> float:
	if karakter != null:


		var jarak: = scale.y / skala_3d if skala_3d > 0.0 else 1.0
		return tinggi_dewasa_latar * float(cfg_3d.get("skala", 1.0)) * cos(deg_to_rad(karakter.SUDUT_KAMERA)) * jarak
	return tinggi_dasar


func _skala_perspektif() -> float:
	var awal: Array = perspektif[0]
	if position.y <= float(awal[0]):
		return float(awal[1])
	for i in perspektif.size() - 1:
		var a: Array = perspektif[i]
		var b: Array = perspektif[i + 1]
		if position.y <= float(b[0]):
			return lerpf(float(a[1]), float(b[1]), (position.y - float(a[0])) / (float(b[0]) - float(a[0])))
	return float(perspektif[-1][1])




func atur_lebar_bingkai(lebar: int, faktor_tinggi: = 1.0) -> void :
	if karakter == null:
		return
	var skala: float = karakter.skala_bingkai()
	var ukuran_lama: Vector2i = karakter.size
	var ppm_lama: float = karakter.piksel_per_meter()
	var offset_lama: = offset
	var cadangan: Texture2D = null

	if texture != null and DisplayServer.get_name() != "headless":
		var img: = texture.get_image()
		if img != null:
			cadangan = ImageTexture.create_from_image(img)
	karakter.size.x = int((lebar if lebar > 0 else 440) * skala)


	karakter.size.y = int(660.0 * karakter.UKURAN_KAMERA / 1.95 * skala * faktor_tinggi)
	karakter.kamera.size = karakter.UKURAN_KAMERA * faktor_tinggi


	var ppm_baru: float = karakter.piksel_per_meter()
	if ppm_lama > 0.0 and ppm_baru > 0.0 and not is_equal_approx(ppm_lama, ppm_baru):
		skala_3d *= ppm_lama / ppm_baru
		_perbarui_skala()
		if bayangan != null:
			bayangan.scale *= ppm_baru / ppm_lama
	offset = Vector2(karakter.size) / 2.0 - karakter.titik_kaki()
	if karakter.size != ukuran_lama:
		_tunggu_gambar_baru(cadangan, offset_lama)




func _tunggu_gambar_baru(cadangan: Texture2D, offset_lama: Vector2) -> void :
	var offset_baru: = offset
	if cadangan != null:
		texture = cadangan
		offset = offset_lama
	else:
		self_modulate.a = 0.0
	if karakter != null:
		karakter.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	for i in 3:
		await RenderingServer.frame_post_draw
	if is_instance_valid(self) and karakter != null:
		texture = karakter.get_texture()
		offset = offset_baru
		self_modulate.a = 1.0
