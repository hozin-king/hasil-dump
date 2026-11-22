extends PanelContainer





const GH: = preload("res://scripts/gaya_hud.gd")
const FP: = preload("res://scripts/foto_profil.gd")
const WARNA_MEDALI: = [Color(1.0, 0.78, 0.15), Color(0.78, 0.82, 0.88), Color(0.85, 0.5, 0.22)]

var kerja: = ""
const LEBAR_TEKS: = 432.0
var _isi: VBoxContainer
var _kaki: Label


func _ready() -> void :
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_theme_stylebox_override("panel", GH.bingkai_emas(Vector4(14, 10, 14, 10)))
	var aman: = GH.tepi_kiri_kanan(get_viewport())
	position = Vector2(maxf(aman.x, 20.0), 92)
	custom_minimum_size = Vector2(460, 0)
	var kolom: = VBoxContainer.new()
	kolom.mouse_filter = Control.MOUSE_FILTER_IGNORE
	kolom.add_theme_constant_override("separation", 4)
	add_child(kolom)
	var judul: = GH.label("JUARA MINGGU INI", 27, GH.KUNING, true, 5)
	judul.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	kolom.add_child(judul)
	var sub: = GH.label(String(GameState.KERJA_SAMPINGAN.get(kerja, {}).get("judul", "")), 18, Color(1, 1, 1, 0.85), false, 3)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	sub.clip_text = true
	kolom.add_child(sub)
	_isi = VBoxContainer.new()
	_isi.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_isi.add_theme_constant_override("separation", 2)
	kolom.add_child(_isi)
	_kaki = GH.label("", 18, Color(1, 0.9, 0.7), true, 3)
	_kaki.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_kaki.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_kaki.custom_minimum_size.x = LEBAR_TEKS
	kolom.add_child(_kaki)
	if GameState.papan != null:
		GameState.papan.diperbarui.connect(_gambar)
		GameState.papan.ambil_papan_kerja()
	_gambar()
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.2)


func _exit_tree() -> void :
	if GameState.papan != null and GameState.papan.diperbarui.is_connected(_gambar):
		GameState.papan.diperbarui.disconnect(_gambar)


static func teks_skor(skor: int, detik: float) -> String:
	if detik < 19.95:
		return "%d · %s dtk" % [skor, ("%.1f" % detik).replace(".", ",")]
	return str(skor)


func _gambar() -> void :
	if not is_inside_tree():
		return
	for anak in _isi.get_children():
		_isi.remove_child(anak)
		anak.queue_free()
	var data: Dictionary = GameState.papan.papan_kerja(kerja) if GameState.papan != null else {}
	var daftar: Array = data.get("daftar", [])
	var kode_saya: String = GameState.papan.kode(GameState.id_papan) if GameState.papan != null and GameState.id_papan != "" else ""
	if daftar.is_empty():
		var kosong: = GH.label("Memuat papan..." if GameState.papan != null and GameState.papan.status_kerja == "memuat" else "Belum ada juara minggu ini. Jadilah yang pertama!", 19, Color(1, 1, 1, 0.8), false, 3)
		kosong.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		kosong.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		kosong.custom_minimum_size.x = LEBAR_TEKS
		_isi.add_child(kosong)
	for i in mini(daftar.size(), 10):
		_isi.add_child(_baris(i + 1, daftar[i], String(daftar[i][3]) == kode_saya))
	var saya = data.get("saya")
	if saya is Dictionary and saya.get("peringkat") != null:
		_kaki.text = tr("Kamu: peringkat #%d · skor %s") % [int(saya["peringkat"]), teks_skor(_int(saya.get("skor")), _float(saya.get("detik"), 20.0))]
	elif saya is Dictionary:
		_kaki.text = "Skormu sedang diperiksa."
	else:
		_kaki.text = "Skormu minggu ini belum ada. Main dan masuk papan!"
	_muat_di_atas_dialog.call_deferred()




func _muat_di_atas_dialog() -> void :
	if not is_inside_tree():
		return
	var batas: = get_viewport_rect().size.y - 220.0 - 30.0 - 10.0
	var baris: = _isi.get_children().filter( func(n): return not n.is_queued_for_deletion())
	while baris.size() > 3 and position.y + get_combined_minimum_size().y > batas:
		var akhir: Node = baris.pop_back()
		_isi.remove_child(akhir)
		akhir.queue_free()
	reset_size()


static func _int(v) -> int:
	return int(v) if v is int or v is float or (v is String and v.is_valid_float()) else 0


static func _float(v, bawaan: float) -> float:
	return float(v) if v is int or v is float or (v is String and v.is_valid_float()) else bawaan


func _baris(nomor: int, b: Array, saya: bool) -> Control:
	var p: = PanelContainer.new()
	var g: = StyleBoxFlat.new()
	g.bg_color = Color(0.96, 0.55, 0.12, 0.9) if saya else Color(1, 1, 1, 0.06 if nomor % 2 == 0 else 0.11)
	g.set_corner_radius_all(8)
	g.content_margin_left = 6
	g.content_margin_right = 8
	g.content_margin_top = 3
	g.content_margin_bottom = 3
	p.add_theme_stylebox_override("panel", g)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var h: = HBoxContainer.new()
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_theme_constant_override("separation", 7)
	p.add_child(h)
	var no: = GH.label(str(nomor), 22, WARNA_MEDALI[nomor - 1] if nomor <= 3 else Color.WHITE, true, 4)
	no.custom_minimum_size.x = 28
	no.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	h.add_child(no)
	h.add_child(FP.bulat(int(b[4]) if b.size() > 4 and b[4] != null else 0, 34, WARNA_MEDALI[nomor - 1] if nomor <= 3 else Color(1, 1, 1, 0.7), String(b[0])))
	var nama: = GH.label(String(b[0]), 21, Color.WHITE, true, 3)
	nama.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	nama.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nama.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	nama.clip_text = true
	h.add_child(nama)
	h.add_child(GH.label(teks_skor(_int(b[1] if b.size() > 1 else 0), _float(b[2] if b.size() > 2 else null, 20.0)), 20, GH.KUNING, true, 3))
	return p
