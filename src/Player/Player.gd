extends CharacterBody3D


@onready var input_gatherer = $Input as InputGatherer
@onready var model = $Model
@onready var visuals = $Visuals
@onready var camera_mount = $CameraMount
@onready var collider = $Collider


@onready var respawn_point : Vector3

func _ready():
	respawn_point = global_position
	visuals.accept_model(model)
	#$CameraMount/PlayerCamera.current = false
	#print_tree_pretty()


func _physics_process(delta):
	var input = input_gatherer.gather_input()
	
	# Debug: Check velocity BEFORE model update
	if Engine.get_physics_frames() % 60 == 0:
		print("BEFORE model.update - velocity: ", velocity)
	
	model.update(input, delta)
	
	# Debug: Check velocity AFTER model update, BEFORE move_and_slide
	if Engine.get_physics_frames() % 60 == 0:
		print("AFTER model.update, BEFORE move_and_slide - velocity: ", velocity)
	
	# Fall detection
	if global_position.y < -2:
		die_and_respawn()
		
	move_and_slide()

# New function for respawn logic
func die_and_respawn():
	global_position = respawn_point
	velocity = Vector3.ZERO
	model.reset_jump_count() # Reset jump count just in case
	
	# Reset resources
	if model.resources:
		model.resources.health = model.resources.max_health
		model.resources.stamina = model.resources.max_stamina


	
	# Visuals -> follow parent transformations
