extends VBoxContainer





const UI: = preload("res://scripts/hp/hp_ui.gd")
const WARNA: = Color(0.36, 0.42, 0.38)
const MAKS_ANGKA: = 15

var hp: Control
var _layar_rumus: Label
var _layar_angka: Label
var _angka: = "0"
var _simpan: = 0
var _operator: = ""
var _baru: = true
var _rumus: = ""


func _ready() -> void :
	add_theme_constant_override("separation", 0)
	add_child(UI.kepala("Kalkulator", WARNA))
	var tepi: = MarginContainer.new()
	tepi.size_flags_vertical = Control.SIZE_EXPAND_FILL
	for sisi in ["left", "right", "top", "bottom"]:
		tepi.add_theme_constant_override("margin_" + sisi, 12)
	add_child(tepi)
	var kolom: = VBoxContainer.new()
	kolom.add_theme_constant_override("separation", 10)
	tepi.add_child(kolom)

	var layar: = UI.panel(Color(0.78, 0.86, 0.78), 12, 12)
	kolom.add_child(layar)
	var isi_layar: = VBoxContainer.new()
	isi_layar.add_theme_constant_override("separation", 2)
	layar.add_child(isi_layar)
	_layar_rumus = UI.label("", 16, Color(0.85, 0.92, 0.85))
	_layar_rumus.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_layar_rumus.clip_text = true
	isi_layar.add_child(_layar_rumus)
	_layar_angka = UI.label("0", 40, Color.WHITE)
	_layar_angka.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_layar_angka.clip_text = true
	isi_layar.add_child(_layar_angka)

	var grid: = GridContainer.new()
	grid.columns = 4
	grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	kolom.add_child(grid)
	for k in ["C", "DEL", ":", "x", "7", "8", "9", "-", "4", "5", "6", "+", "1", "2", "3", "=", "0", "00", "000", "%"]:
		var warna: = Color(1, 1, 1, 0.14)
		if k in ["+", "-", "x", ":", "%"]:
			warna = Color(0.95, 0.55, 0.15)
		elif k == "=":
			warna = Color(0.2, 0.62, 0.3)
		elif k in ["C", "DEL"]:
			warna = Color(0.78, 0.25, 0.2)
		var t: = UI.tombol(k, warna, 24, 58)
		t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		t.size_flags_vertical = Control.SIZE_EXPAND_FILL
		t.pressed.connect(_tekan.bind(k))
		grid.add_child(t)
	_perbarui()


func tampil() -> void :
	_perbarui()


func _tekan(k: String) -> void :
	GameState.klik()
	match k:
		"C":
			_angka = "0"
			_simpan = 0
			_operator = ""
			_rumus = ""
			_baru = true
		"DEL":
			if _baru:
				return
			_angka = _angka.substr(0, _angka.length() - 1)
			if _angka == "" or _angka == "-":
				_angka = "0"
				_baru = true
		"+", "-", "x", ":":
			if _operator != "" and not _baru:
				_hitung()
			else:
				_simpan = int(_angka)
			_operator = k
			_rumus = "%s %s" % [_format(_simpan), k]
			_baru = true
		"=":
			if _operator == "":
				return
			var kanan: = int(_angka)
			_rumus = "%s %s %s =" % [_format(_simpan), _operator, _format(kanan)]
			_hitung()
			_operator = ""
			_baru = true
		"%":


			var n: = int(_angka)
			if _operator == "x":
				_rumus = "%s x %s%% =" % [_format(_simpan), _format(n)]
				_angka = str(int(round(_simpan * n / 100.0)))
				_simpan = int(_angka)
				_operator = ""
				_baru = true
			elif _operator in ["+", "-"]:
				_angka = str(int(round(_simpan * n / 100.0)))
				_baru = false
			else:
				_angka = str(int(round(n / 100.0)))
				_baru = true
		_:
			if _baru:
				_angka = "0"
				_baru = false
			if _angka.length() + k.length() > MAKS_ANGKA:
				return
			_angka = k if _angka == "0" and k != "00" and k != "000" else (_angka if _angka == "0" else _angka + k)
	_perbarui()



func _hitung() -> void :
	var kanan: = int(_angka)
	var hasil: = _simpan
	match _operator:
		"+": hasil = _simpan + kanan
		"-": hasil = _simpan - kanan
		"x": hasil = _simpan * kanan
		":":
			if kanan == 0:
				_angka = "0"
				_rumus = "Tidak bisa dibagi 0"
				_simpan = 0
				return
			hasil = int(round(float(_simpan) / float(kanan)))
	_simpan = hasil
	_angka = str(hasil)



func _format(n: int) -> String:
	var s: = str(absi(n))
	var hasil: = ""
	while s.length() > 3:
		hasil = "." + s.substr(s.length() - 3) + hasil
		s = s.substr(0, s.length() - 3)
	return ("-" if n < 0 else "") + s + hasil


func _perbarui() -> void :
	if _layar_angka == null:
		return
	_layar_angka.text = _format(int(_angka))
	_layar_rumus.text = _rumus
