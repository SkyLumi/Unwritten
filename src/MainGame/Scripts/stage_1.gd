extends Node3D

# Masukkan file lagu sedihnya di sini
var music_seneng = preload("res://src/Assets/Musics/Wind Waker The Great Sea (Ocean) Music Extended.mp3")

func _ready():
	# Panggil Autoload langsung
	Backsound.ganti_musik(music_seneng)
