extends Control





@onready var tombol_ibu: Button = %TombolIbu
@onready var tombol_bapak: Button = %TombolBapak
@onready var tombol_kembali: Button = %TombolKembali
@onready var pesan: Label = %Pesan


func _ready() -> void :
	theme = load("res://scripts/gaya_hud.gd").tema_jendela()
	tombol_ibu.pressed.connect(_on_ibu_ditekan)
	tombol_bapak.pressed.connect(_on_bapak_ditekan)
	tombol_kembali.pressed.connect(_on_kembali_ditekan)
	pesan.text = ""


func _on_ibu_ditekan() -> void :
	_pilih("ibu")


func _on_bapak_ditekan() -> void :
	_pilih("bapak")


func _on_kembali_ditekan() -> void :
	GameState.ganti_layar(self, "res://scenes/main_menu.tscn")


func _pilih(pilihan: String) -> void :
	if GameState.tutorial_selesai:
		GameState.mulai_game_baru()
	else:
		GameState.mulai_latihan()
	GameState.pilih_penjaga(pilihan)

	GameState.ganti_layar(self, "res://scenes/warung.tscn")
