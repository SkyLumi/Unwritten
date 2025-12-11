extends Control

var music_sad = preload("res://src/Assets/Musics/Rosalina's Storybook Theme Extended - Super Mario Galaxy.mp3")

# Ambil referensi node
@onready var display_gambar = $TextureRect

# --- DATA STORY DI SINI ---
# Format: { "img": preload("lokasi_gambar"), "txt": "Kata-kata cerita" }
var story_data = [
	{
		"img": preload("res://src/Assets/Story/Ending/end-1.png"), 
	},
	{
		"img": preload("res://src/Assets/Story/Ending/end-2.png"), 
	},
	{
		"img": preload("res://src/Assets/Story/Ending/end-3.png"), 
	},
	{
		"img": preload("res://src/Assets/Story/Ending/end-4.png"), 
	},
	{
		"img": preload("res://src/Assets/Story/Ending/end-5.png"), 
	},
	{
		"img": preload("res://src/Assets/Story/Ending/end-6.png"), 
	},
	{
		"img": preload("res://src/Assets/Story/Ending/end-7.png"), 
	},
	{
		"img": preload("res://src/Assets/Story/Ending/end-8.png"), 
	},
	{
		"img": preload("res://src/Assets/Story/Ending/end-9.png"), 
	}
]

var index_sekarang = 0 # Penanda kita lagi di slide nomor berapa

func _ready():
	
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	Backsound.ganti_musik(music_sad)
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
	SceneManager.load_scene("res://src/UIScene/MainMenu.tscn")
