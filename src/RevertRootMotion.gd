extends Node

func _ready():
	print("Reverting Root Motion Fix...")
	revert_animations()
	print("Revert Complete. Please restart the game.")
	get_tree().quit()

func revert_animations():
	var lib_path = "res://src/Assets/Ready Animations/params_extraction_lib.res"
	
	if not ResourceLoader.exists(lib_path):
		print("Error: Library not found at ", lib_path)
		return

	var library = ResourceLoader.load(lib_path) as AnimationLibrary
	
	var anim_names = ["walk_params", "run_params", "sprint_params"]
	
	for name in anim_names:
		if library.has_animation(name):
			var anim = library.get_animation(name)
			var track_idx = anim.find_track("MoveDatabase:root_position", Animation.TYPE_VALUE)
			if track_idx != -1:
				print("Removing root motion track from ", name)
				anim.remove_track(track_idx)
			else:
				print("No root motion track found in ", name)
		else:
			print("Animation not found: ", name)

	# Save the library
	var error = ResourceSaver.save(library, lib_path)
	if error != OK:
		print("Error saving library: ", error)
	else:
		print("Library reverted successfully.")
