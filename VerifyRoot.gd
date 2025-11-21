extends SceneTree

func _init():
	var lib_path = "res://src/Assets/Ready Animations/params_extraction_lib.res"
	if not ResourceLoader.exists(lib_path):
		print("Library not found")
		quit()
		return

	var library = ResourceLoader.load(lib_path) as AnimationLibrary
	if not library.has_animation("walk_params"):
		print("walk_params not found")
		quit()
		return

	var anim = library.get_animation("walk_params")
	var track_idx = anim.find_track("MoveDatabase:root_position", Animation.TYPE_VALUE)
	
	if track_idx == -1:
		print("Track 'MoveDatabase:root_position' NOT found in walk_params")
	else:
		var key_count = anim.track_get_key_count(track_idx)
		print("Track found. Key count: ", key_count)
		if key_count > 0:
			print("First key value: ", anim.track_get_key_value(track_idx, 0))
			print("Last key value: ", anim.track_get_key_value(track_idx, key_count - 1))
			
	quit()
