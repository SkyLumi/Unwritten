extends Node

func _ready():
	print("Starting Root Motion Fix...")
	fix_animations()
	print("Root Motion Fix Complete. Please restart the game.")
	get_tree().quit()

func fix_animations():
	var lib_path = "res://src/Assets/Ready Animations/params_extraction_lib.res"
	var walk_source_path = "res://src/Assets/Ready Animations/mixamo_legs_animations/walk_legs.res"
	var model_scene_path = "res://src/Player/HumanoidModel/HumanoidModel.tscn"
	
	if not ResourceLoader.exists(lib_path):
		print("Error: Library not found at ", lib_path)
		return

	var library = ResourceLoader.load(lib_path) as AnimationLibrary
	
	# 1. Fix Walk (from external file)
	if ResourceLoader.exists(walk_source_path):
		print("Baking walk...")
		var walk_source = ResourceLoader.load(walk_source_path) as Animation
		bake_to_library(library, "walk_params", walk_source)
	else:
		print("Error: Walk source not found at ", walk_source_path)

	# 2. Fix Run and Sprint (from HumanoidModel scene)
	if ResourceLoader.exists(model_scene_path):
		print("Loading HumanoidModel to extract Run/Sprint...")
		var model_scene = ResourceLoader.load(model_scene_path) as PackedScene
		var model_node = model_scene.instantiate()
		
		# Find DEV_SkeletonAnimator
		var skeleton_animator = model_node.get_node_or_null("DEV_SkeletonAnimator")
		if skeleton_animator and skeleton_animator.has_method("get_animation_library"):
			var lib_name = skeleton_animator.get_animation_library_list()[0]
			var internal_lib = skeleton_animator.get_animation_library(lib_name)
			
			if internal_lib.has_animation("run"):
				print("Baking run...")
				bake_to_library(library, "run_params", internal_lib.get_animation("run"))
			else:
				print("Warning: 'run' animation not found in HumanoidModel.")
				
			if internal_lib.has_animation("sprint"):
				print("Baking sprint...")
				bake_to_library(library, "sprint_params", internal_lib.get_animation("sprint"))
			else:
				print("Warning: 'sprint' animation not found in HumanoidModel.")
		else:
			print("Error: DEV_SkeletonAnimator not found or invalid.")
		
		model_node.free()
	else:
		print("Error: HumanoidModel scene not found.")

	# Save the library
	var error = ResourceSaver.save(library, lib_path)
	if error != OK:
		print("Error saving library: ", error)
	else:
		print("Library saved successfully.")

func bake_to_library(library: AnimationLibrary, target_name: String, source: Animation):
	if not library.has_animation(target_name):
		print("Error: Target animation '", target_name, "' not found in library.")
		return
	
	var target = library.get_animation(target_name)
	bake_root_motion(source, target)

func bake_root_motion(source: Animation, target: Animation):
	var hips_track = source.find_track("%GeneralSkeleton:Hips", Animation.TYPE_POSITION_3D)
	if hips_track == -1:
		hips_track = source.find_track("Hips", Animation.TYPE_POSITION_3D)
	
	if hips_track == -1:
		print("Error: Hips track not found in source animation.")
		return

	var target_track = target.find_track("MoveDatabase:root_position", Animation.TYPE_VALUE)
	if target_track == -1:
		target_track = target.add_track(Animation.TYPE_VALUE)
		target.track_set_path(target_track, "MoveDatabase:root_position")
	
	# Clear existing keys by removing and re-adding track
	target.remove_track(target_track)
	target_track = target.add_track(Animation.TYPE_VALUE)
	target.track_set_path(target_track, "MoveDatabase:root_position")

	var key_count = source.track_get_key_count(hips_track)
	for i in range(key_count):
		var time = source.track_get_key_time(hips_track, i)
		var pos = source.track_get_key_value(hips_track, i)
		target.track_insert_key(target_track, time, pos)
	
	print("Baked ", key_count, " keys into ", target.resource_name if target.resource_name else "target")
