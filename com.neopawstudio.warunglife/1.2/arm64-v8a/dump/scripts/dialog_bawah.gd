extends Control








signal selesai
signal dipilih(nomor: int)
signal baris_dimulai(siapa: String)


const KECEPATAN_TOKOH: = {"nenek": 30.0, "petani": 38.0, "haji_doni": 36.0, "anak": 58.0, "siswi": 52.0}
var sinematik: = false
var _gelap: ColorRect
var _siapa_sekarang: = ""
var _huruf_terakhir: = 0

const TEMA: = preload("res://ui/tema.tres")
const GH: = preload("res://scripts/gaya_hud.gd")
const KECEPATAN_KETIK: = 45.0
const NAMA: = {"bapak": "Pak Misran", "haji_doni": "Haji Doni", "pak_rt": "Pak RT", "nenek": "Nenek", "petani": "Pak Tani", 
	"santri_putih": "Santri", "santri_hitam": "Santri", "ibu_rumah_tangga": "Bu Ida", "tukang": "Mang Ujang"}

var _antrean: Array = []
var _bingkai_potret: PanelContainer
var _gambar_potret: TextureRect
var _kotak_nama: PanelContainer
var _nama: Label
var _teks: Label
var _tween: Tween

var _siap_lanjut: = false
var _potret: = {}
var _cfg_tokoh: = {}
var _petunjuk: Label
var _kotak_pilihan: VBoxContainer
var _kotak: PanelContainer


var tinggi_bar_sinema: = 0.12
const TINGGI_KOTAK: = 220.0
const JARAK_BAWAH: = 30.0
var _memilih: = false


func _ready() -> void :
	theme = TEMA
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	hide()
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/pelanggan.json"))
	VarianBaju.gabung(data)
	for p in data["pelanggan"]:
		_cfg_tokoh[String(p["id"])] = p["model3d"]
	for id in data.get("tokoh", {}):
		_cfg_tokoh[String(id)] = data["tokoh"][id]["model3d"]
	_cfg_tokoh["bapak"] = GameState.cfg_penjaga({"file": GameState.file_model_penjaga(), "anim_diam": "Idle_11", "anim_bicara": "Talk_with_Right_Hand_Open", "skala": 1.0})

	var gelap: = ColorRect.new()
	gelap.color = Color(0.03, 0.02, 0.01, 0.35)
	gelap.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	gelap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(gelap)
	_gelap = gelap
	var kotak: = PanelContainer.new()
	kotak.mouse_filter = Control.MOUSE_FILTER_IGNORE
	kotak.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	kotak.offset_left = 60
	kotak.offset_right = -60
	kotak.offset_top = -250
	kotak.offset_bottom = -30
	add_child(kotak)
	_kotak = kotak
	var baris: = HBoxContainer.new()
	baris.add_theme_constant_override("separation", 18)
	kotak.add_child(baris)
	_bingkai_potret = PanelContainer.new()
	_bingkai_potret.theme_type_variation = &"KartuBarang"
	_bingkai_potret.custom_minimum_size = Vector2(176, 176)
	_bingkai_potret.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	baris.add_child(_bingkai_potret)
	_gambar_potret = TextureRect.new()
	_gambar_potret.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_gambar_potret.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_bingkai_potret.add_child(_gambar_potret)
	var isi: = VBoxContainer.new()
	isi.add_theme_constant_override("separation", 8)
	isi.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	baris.add_child(isi)
	_kotak_nama = PanelContainer.new()
	_kotak_nama.theme_type_variation = &"PanelHud"
	_kotak_nama.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	isi.add_child(_kotak_nama)
	_nama = Label.new()
	_nama.theme_type_variation = &"LabelHud"
	_kotak_nama.add_child(_nama)
	_teks = Label.new()
	_teks.add_theme_font_size_override("font_size", 30)
	_teks.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_teks.size_flags_vertical = Control.SIZE_EXPAND_FILL
	isi.add_child(_teks)
	_petunjuk = Label.new()
	var petunjuk: = _petunjuk
	petunjuk.text = "Klik untuk lanjut  ▸"
	petunjuk.add_theme_font_size_override("font_size", 18)
	petunjuk.add_theme_color_override("font_color", Color(0.55, 0.4, 0.25))
	petunjuk.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	isi.add_child(petunjuk)
	GH.gaya_kotak_dialog(kotak, _bingkai_potret, _gambar_potret, _kotak_nama, _nama, _teks, petunjuk)


func tampilkan(baris: Array) -> void :
	_antrean = baris.duplicate()
	_gelap.color.a = 0.08 if sinematik else 0.35
	_atur_letak_kotak()
	show()
	_baris_berikut()



func tanya(b: Dictionary, opsi: Array) -> int:
	_antrean = []
	show()
	_tampilkan_baris(b)

	if _tween:
		_tween.kill()
	_teks.visible_ratio = 1.0
	if _kotak_pilihan == null:
		_kotak_pilihan = VBoxContainer.new()
		_kotak_pilihan.add_theme_constant_override("separation", 10)
		_kotak_pilihan.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
		_kotak_pilihan.grow_horizontal = Control.GROW_DIRECTION_BEGIN
		_kotak_pilihan.grow_vertical = Control.GROW_DIRECTION_BEGIN
		_kotak_pilihan.offset_right = -70
		_kotak_pilihan.offset_bottom = -262
		add_child(_kotak_pilihan)
	_atur_letak_kotak()
	for t in _kotak_pilihan.get_children():
		t.queue_free()
	for i in opsi.size():
		var tombol: = Button.new()
		var teks_pilihan: = String(opsi[i]["teks"])


		GH.gaya_tombol(tombol, false, 26)

		for k in ["normal", "hover", "pressed", "hover_pressed", "disabled"]:
			var sb: = (tombol.get_theme_stylebox(k) as StyleBoxFlat).duplicate() as StyleBoxFlat
			sb.content_margin_left = 64.0
			sb.border_width_left = 6
			sb.border_color = GH.KUNING_NOTIF if k != "disabled" else Color(GH.KUNING_NOTIF, 0.4)
			sb.corner_radius_top_left = 5
			sb.corner_radius_bottom_left = 5
			if k in ["hover", "pressed", "hover_pressed"]:
				sb.border_width_left = 9
			tombol.add_theme_stylebox_override(k, sb)
		tombol.alignment = HORIZONTAL_ALIGNMENT_LEFT
		tombol.custom_minimum_size = Vector2(480, 62)


		var rt: = RichTextLabel.new()
		rt.bbcode_enabled = true
		rt.fit_content = true
		rt.scroll_active = false
		rt.autowrap_mode = TextServer.AUTOWRAP_OFF
		rt.mouse_filter = Control.MOUSE_FILTER_IGNORE
		rt.add_theme_font_override("normal_font", GH.cetak())
		rt.add_theme_font_size_override("normal_font_size", 26)
		rt.add_theme_color_override("default_color", Color.WHITE)
		var kuning: = "#" + GH.KUNING.to_html(false)
		var cari: = RegEx.create_from_string("\\(reward[^)]*\\)")
		rt.text = cari.sub(teks_pilihan.replace("[", "[lb]"), "[color=%s]$0[/color]" % kuning, true)
		rt.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		rt.offset_left = 64.0
		rt.offset_right = -10.0
		rt.offset_top = 14.0
		rt.modulate.a = 1.0 if bool(opsi[i].get("aktif", true)) else 0.45


		var lebar_teks: = GH.cetak().get_string_size(tr(teks_pilihan), HORIZONTAL_ALIGNMENT_LEFT, -1, 26).x + 64.0 + 30.0
		var lebar_maks: = maxf(480.0, get_viewport_rect().size.x - 140.0)
		if lebar_teks <= lebar_maks:
			tombol.custom_minimum_size.x = maxf(480.0, lebar_teks)
		else:
			tombol.custom_minimum_size.x = lebar_maks
			rt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			var baris_teks: = ceili(lebar_teks / (lebar_maks - 20.0))
			tombol.custom_minimum_size.y = 62.0 + 34.0 * (baris_teks - 1)
		tombol.add_child(rt)
		var angka: = GH.label(str(i + 1), 34, GH.KUNING, true, 4)
		angka.set_anchors_and_offsets_preset(Control.PRESET_LEFT_WIDE)
		angka.offset_left = 22.0
		angka.offset_right = 58.0
		angka.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		tombol.add_child(angka)

		tombol.disabled = not bool(opsi[i].get("aktif", true))
		tombol.pressed.connect( func():
			GameState.klik()
			dipilih.emit(i))
		_kotak_pilihan.add_child(tombol)
	_kotak_pilihan.show()
	_petunjuk.hide()
	_memilih = true
	var nomor: int = await dipilih
	_memilih = false
	_kotak_pilihan.hide()
	_petunjuk.show()
	hide()
	return nomor


func _baris_berikut() -> void :
	if _antrean.is_empty():
		hide()
		selesai.emit()
		return
	_tampilkan_baris(_antrean.pop_front())


func _tampilkan_baris(b: Dictionary) -> void :
	var siapa: = String(b.get("siapa", ""))
	_kotak_nama.visible = siapa != ""
	_nama.text = String(b.get("nama", NAMA.get(siapa, siapa.capitalize())))
	_tampilkan_potret(siapa)
	_teks.text = String(b["teks"])
	_teks.add_theme_color_override("font_color", Color(1, 1, 1, 0.75) if siapa == "" else Color.WHITE)
	_siap_lanjut = false
	_teks.visible_ratio = 0.0
	_siapa_sekarang = siapa
	_huruf_terakhir = 0
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(_teks, "visible_ratio", 1.0, _teks.text.length() / float(KECEPATAN_TOKOH.get(siapa, KECEPATAN_KETIK)))
	baris_dimulai.emit(siapa)


func _gui_input(event: InputEvent) -> void :
	var ditekan: bool = (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT)
	if ditekan:
		lanjut()



func lanjut() -> void :
	GameState.klik()
	if _memilih:

		if _tween:
			_tween.kill()
		_teks.visible_ratio = 1.0
		return
	if not _siap_lanjut:
		_siap_lanjut = true
		if _tween:
			_tween.kill()
		_teks.visible_ratio = 1.0
	else:
		_baris_berikut()



func segarkan_bapak() -> void :
	_cfg_tokoh["bapak"] = GameState.cfg_penjaga({"file": GameState.file_model_penjaga(), "anim_diam": "Idle_11", "anim_bicara": "Talk_with_Right_Hand_Open", "skala": 1.0})
	if _potret.has("bapak"):
		var vp = (_potret["bapak"] as Array)[0]
		if is_instance_valid(vp):
			vp.queue_free()
		_potret.erase("bapak")


func _tampilkan_potret(siapa: String) -> void :
	_bingkai_potret.visible = siapa != "" and _cfg_tokoh.has(siapa)
	if not _bingkai_potret.visible:
		return
	if not _potret.has(siapa):
		_potret[siapa] = _buat_potret(_cfg_tokoh[siapa])
	var p: Array = _potret[siapa]



	for lain in _potret:
		var vp_lain: = (_potret[lain] as Array)[0] as SubViewport
		if vp_lain != null:
			vp_lain.render_target_update_mode = SubViewport.UPDATE_ALWAYS if lain == siapa else SubViewport.UPDATE_DISABLED
	if p[0] == null:
		_gambar_potret.texture = p[3]
		return
	_gambar_potret.texture = (p[0] as SubViewport).get_texture()
	var animasi: AnimationPlayer = p[1]
	var cfg: Dictionary = p[2]
	var bicara: = String(cfg.get("anim_bicara", ""))
	if animasi != null and animasi.has_animation(bicara):
		animasi.play(bicara, 0.2)
		animasi.queue(String(cfg.get("anim_diam", "")))



func _buat_potret(cfg: Dictionary) -> Array:
	var vp: = SubViewport.new()
	vp.size = Vector2i(352, 352)
	vp.transparent_bg = true
	vp.own_world_3d = true
	vp.msaa_3d = GameState.msaa_3d()
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(vp)
	var lingkungan: = Environment.new()
	lingkungan.background_mode = Environment.BG_CLEAR_COLOR
	lingkungan.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	lingkungan.ambient_light_color = Color(1.0, 0.85, 0.7)
	lingkungan.ambient_light_energy = 0.55
	lingkungan.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	var dunia: = WorldEnvironment.new()
	dunia.environment = lingkungan
	vp.add_child(dunia)
	var lampu: = DirectionalLight3D.new()
	lampu.light_color = Color(1.0, 0.85, 0.65)
	lampu.light_energy = 1.3
	lampu.rotation = Vector3(deg_to_rad(-25), deg_to_rad(30), 0)
	vp.add_child(lampu)
	var model: Node3D = GameState.muat_model("res://assets/karakter3d/" + String(cfg["file"]))

	if GameState.cari_anak(model, "MeshInstance3D").is_empty():
		var foto: = _foto_diam(String(cfg["file"]))
		if foto != null:
			model.free()
			vp.queue_free()
			return [null, null, cfg, foto]
	vp.add_child(model)
	if cfg.has("varian_baju") and not (cfg["varian_baju"].get("bagian", []) as Array).is_empty():
		VarianBaju.pasang(model, cfg["varian_baju"])
	var skala: = float(cfg.get("skala", 1.0))
	var tinggi: = 0.0
	for mi: MeshInstance3D in GameState.cari_anak(model, "MeshInstance3D"):
		tinggi = maxf(tinggi, (mi.global_transform * mi.get_aabb()).size.y)
	if tinggi > 0.0:
		var s: = 1.72 * skala / tinggi
		model.scale = Vector3(s, s, s)
	var animasi: AnimationPlayer = null
	var semua: = GameState.cari_anak(model, "AnimationPlayer")
	if not semua.is_empty():
		animasi = semua[0]
		if String(cfg["file"]) == GameState.FILE_MODEL_PENJAGA["ibu"]:
			GameState.siapkan_animasi_penjaga(animasi)
		var diam: = String(cfg.get("anim_diam", ""))
		if animasi.has_animation(diam):
			animasi.get_animation(diam).loop_mode = Animation.LOOP_LINEAR
			animasi.play(diam)

	var wajah: = 1.47 * skala
	var kamera: = Camera3D.new()
	kamera.fov = 26.0
	kamera.position = Vector3(0.25 * skala, wajah + 0.08 * skala, 1.35 * skala)
	var sasaran: = Vector3(0, wajah, 0)

	if cfg.has("putar_model"):
		model.rotation.y = deg_to_rad(float(cfg["putar_model"]))
	if String(cfg.get("gerak", "")) == "kucing":
		var rangka: = GameState.cari_anak(model, "Skeleton3D")
		if not rangka.is_empty():
			rangka[0].add_child(load("res://scripts/kucing_hidup.gd").new())

	if cfg.has("potret"):
		var p: Array = cfg["potret"]
		var t: = 1.72 * skala
		sasaran = Vector3(0, float(p[0]) * t, float(p[1]) * t)
		kamera.position = sasaran + Vector3(0.18, 0.05, 1.0) * float(p[2])
	vp.add_child(kamera)
	kamera.look_at(sasaran)
	kamera.current = true
	return [vp, animasi, cfg]




func _foto_diam(file_model: String) -> Texture2D:
	var nama: = file_model.get_basename().trim_prefix("meshy_")
	for calon in ["res://assets/potret/%s.png" % nama, "res://assets/potret/warga_%s.png" % nama]:
		if ResourceLoader.exists(calon):
			return load(calon)
	return null



func _atur_letak_kotak() -> void :
	var bawah: = JARAK_BAWAH
	if sinematik:
		bawah = maxf(JARAK_BAWAH, get_viewport_rect().size.y * tinggi_bar_sinema + 8.0)
	_kotak.offset_bottom = - bawah
	_kotak.offset_top = - bawah - TINGGI_KOTAK
	if _kotak_pilihan != null:
		_kotak_pilihan.offset_bottom = - bawah - TINGGI_KOTAK - 12.0
