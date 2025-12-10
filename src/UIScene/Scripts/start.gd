extends Button


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


func _on_button_pressed():
	# Panggil si bos SceneManager buat loading ke level 1
	SceneManager.load_scene("res://src/Story/story_scene.tscn")
