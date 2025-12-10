extends Control

# Ambil referensi node
@onready var display_gambar = $TextureRect

# --- DATA STORY DI SINI ---
# Format: { "img": preload("lokasi_gambar"), "txt": "Kata-kata cerita" }
var story_data = [
	{
		"img": preload("res://src/Assets/Story/1.png"), 
	},
	{
		"img": preload("res://src/Assets/Story/2.png"), 
	},
	{
		"img": preload("res://src/Assets/Story/3.png"), 
	},
	{
		"img": preload("res://src/Assets/Story/4.png"), 
	},
	{
		"img": preload("res://src/Assets/Story/5.png"), 
	},
	{
		"img": preload("res://src/Assets/Story/6.png"), 
	},
	{
		"img": preload("res://src/Assets/Story/7.png"), 
	}
]

var index_sekarang = 0 # Penanda kita lagi di slide nomor berapa

func _ready():
	update_tampilan() # Tampilkan slide pertama pas mulai

# Fungsi buat ganti tampilan
func update_tampilan():
	var data = story_data[index_sekarang]
	display_gambar.texture = data["img"]

# Input: Klik mouse atau Spasi/Enter buat lanjut
func _input(event):
	if event.is_action_pressed("ui_accept") or (event is InputEventMouseButton and event.pressed):
		lanjut_cerita()

func lanjut_cerita():
	# Pindah ke index selanjutnya
	index_sekarang += 1
	
	# Cek apakah slide sudah habis?
	if index_sekarang < story_data.size():
		update_tampilan()
	else:
		# Kalau habis, pindah ke Gameplay
		selesai()

func selesai():
	# Ganti ke scene gameplay atau menu
	SceneManager.load_scene("res://src/MainGame/Stage1.tscn")
