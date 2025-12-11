extends Button

func _on_button_pressed():
	# Panggil si bos SceneManager buat loading ke level 1
	get_tree().change_scene_to_file("res://src/Story/story_scene.tscn")
