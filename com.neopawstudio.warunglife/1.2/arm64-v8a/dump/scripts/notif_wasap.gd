extends CanvasLayer






const LAMA_TAMPIL: = 3.6
const TINGGI: = 96.0
const LEBAR: = 600.0
const GH: = preload("res://scripts/gaya_hud.gd")
const BATAS_USAP: = 30.0

var _antre: Array = []
var _kartu: PanelContainer
var _foto: TextureRect
var _judul: Label
var _teks: Label
var _tampil: = false
var _sisa: = 0.0
var _kontak: = ""
var _langsung_chat: = false
var _tekan_y: = -1.0
var _tahan: = 0.0
var _tween: Tween


func _ready() -> void :
	layer = 90
	process_mode = Node.PROCESS_MODE_ALWAYS


	_kartu = PanelContainer.new()
	_kartu.add_theme_stylebox_override("panel", GH.kaca(0.75, 18, Vector4(14, 12, 18, 8)))
	_kartu.anchor_left = 0.5
	_kartu.anchor_right = 0.5
	_kartu.offset_left = - LEBAR / 2.0
	_kartu.offset_right = LEBAR / 2.0
	_kartu.offset_top = - TINGGI - 30.0
	_kartu.offset_bottom = -30.0
	_kartu.mouse_filter = Control.MOUSE_FILTER_STOP
	_kartu.gui_input.connect(_on_input)
	add_child(_kartu)
	var tumpuk: = VBoxContainer.new()
	tumpuk.add_theme_constant_override("separation", 6)
	tumpuk.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_kartu.add_child(tumpuk)
	var baris: = HBoxContainer.new()
	baris.add_theme_constant_override("separation", 14)
	baris.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tumpuk.add_child(baris)
	var wadah_foto: = Control.new()
	wadah_foto.custom_minimum_size = Vector2(60, 60)
	wadah_foto.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	wadah_foto.mouse_filter = Control.MOUSE_FILTER_IGNORE
	baris.add_child(wadah_foto)
	_foto = TextureRect.new()
	_foto.size = Vector2(60, 60)
	_foto.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_foto.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_foto.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wadah_foto.add_child(_foto)
	var lencana: = Panel.new()
	lencana.add_theme_stylebox_override("panel", GH.kotak(Color(0.18, 0.62, 0.35), 7))
	lencana.position = Vector2(40, 40)
	lencana.size = Vector2(24, 24)
	lencana.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var ikon: = TextureRect.new()
	ikon.texture = load("res://assets/ikon/chat.svg")
	ikon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ikon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ikon.position = Vector2(3, 3)
	ikon.size = Vector2(18, 18)
	ikon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lencana.add_child(ikon)
	wadah_foto.add_child(lencana)
	var kolom: = VBoxContainer.new()
	kolom.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	kolom.add_theme_constant_override("separation", -2)
	kolom.mouse_filter = Control.MOUSE_FILTER_IGNORE
	baris.add_child(kolom)
	var atas: = HBoxContainer.new()
	atas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	kolom.add_child(atas)
	_judul = GH.label("", 26, GH.BIRU_NAMA, true)
	_judul.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_judul.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	atas.add_child(_judul)
	atas.add_child(GH.label("WASAP · SEKARANG", 15, Color(1, 1, 1, 0.6), true, 0))
	_teks = GH.label("", 17, Color.WHITE)
	_teks.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_teks.custom_minimum_size.x = 420
	kolom.add_child(_teks)
	var usap: = ColorRect.new()
	usap.color = Color(1, 1, 1, 0.45)
	usap.custom_minimum_size = Vector2(60, 4)
	usap.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	usap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tumpuk.add_child(usap)
	_kartu.hide()



func kabari(kontak: String, judul: String, teks: String, langsung_chat: = false) -> void :
	_antre.append({"kontak": kontak, "judul": judul, "teks": teks, "chat": langsung_chat})
	if not _tampil:
		_berikutnya()


func _berikutnya() -> void :
	if _antre.is_empty():
		return
	var n: Dictionary = _antre.pop_front()

	if _antre.size() >= 2:
		n = {"kontak": n["kontak"], "judul": "Wasap", "teks": "%d pesan baru" % (_antre.size() + 1)}
		_antre.clear()
	_kontak = String(n["kontak"])
	_langsung_chat = bool(n.get("chat", false))
	_judul.text = String(n["judul"]).to_upper()
	_teks.text = String(n["teks"]).replace("\n", " ")
	var foto: = "res://assets/potret/%s.png" % (("warga_" + _kontak.substr(6)) if _kontak.begins_with("utang:") else _kontak)
	_foto.texture = load(foto) if ResourceLoader.exists(foto) else load("res://assets/ikon/chat.svg")
	_foto.modulate = Color.WHITE if ResourceLoader.exists(foto) else Color(0.18, 0.62, 0.35)
	_foto.material = GH.bahan_bulat() if ResourceLoader.exists(foto) else null
	_tampil = true
	_sisa = LAMA_TAMPIL
	_kartu.show()
	GameState.bunyi("notif")
	_geser_ke(14.0)


func _geser_ke(y: float, lalu: Callable = Callable()) -> void :
	if _tween != null:
		_tween.kill()
	_tween = create_tween().set_trans(Tween.TRANS_BACK if y > 0 else Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_tween.tween_property(_kartu, "offset_top", y, 0.35)
	_tween.parallel().tween_property(_kartu, "offset_bottom", y + TINGGI, 0.35)
	if lalu.is_valid():
		_tween.tween_callback(lalu)


func _process(delta: float) -> void :
	if not _tampil:
		return
	if _tekan_y >= 0.0:



		_tahan += delta
		if _tahan > 0.25 and not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			_tekan_y = -1.0
			_geser_ke(14.0)
		elif _tahan > 6.0:
			_tekan_y = -1.0
			_tutup()
		return
	_sisa -= delta
	if _sisa <= 0.0:
		_tutup()


func _tutup() -> void :
	if not _tampil:
		return
	_tampil = false
	_geser_ke( - TINGGI - 30.0, func():
		_kartu.hide()
		_berikutnya())


func _on_input(e: InputEvent) -> void :
	if (e is InputEventMouseButton or e is InputEventScreenTouch) and e.pressed:
		_tekan_y = e.position.y
		_tahan = 0.0
	elif e is InputEventMouseMotion or e is InputEventScreenDrag:
		if _tekan_y >= 0.0:

			var geser: = minf(0.0, e.position.y - _tekan_y)
			_kartu.offset_top = 14.0 + geser
			_kartu.offset_bottom = 14.0 + geser + TINGGI
	elif (e is InputEventMouseButton or e is InputEventScreenTouch) and not e.pressed and _tekan_y >= 0.0:
		var geser: float = e.position.y - _tekan_y
		_tekan_y = -1.0
		if geser < - BATAS_USAP:
			_tutup()
		elif absf(geser) < 10.0:
			_buka_wasap()
			_tutup()
		else:
			_geser_ke(14.0)



func _buka_wasap() -> void :
	var adegan: = get_tree().current_scene
	if adegan == null or adegan.get("hp") == null or adegan.get("dialog_aktif") == true or adegan.get("sibuk") == true:
		return
	adegan.hp.buka("wasap")



	if _langsung_chat or (_kontak != "" and _judul.text != "WASAP" and not GameState.pesan_chat(_kontak).is_empty()):
		adegan.hp.aplikasi("wasap").buka_chat(_kontak)
