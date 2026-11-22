extends Control





@onready var judul: Label = $Judul


func _ready() -> void :
	var ukuran_layar: Vector2 = get_viewport_rect().size
	judul.text = "Warung Madura\nTahap 1 Berhasil!\n\nUkuran layar: %d x %d" % [int(ukuran_layar.x), int(ukuran_layar.y)]
