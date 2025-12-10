extends Control

# Masukkan file lagu sedihnya di sini
var music_sad = preload("res://src/Assets/Musics/Rosalina's Storybook Theme Extended - Super Mario Galaxy.mp3")

func _ready():
	# Panggil Autoload langsung
	Backsound.ganti_musik(music_sad)
