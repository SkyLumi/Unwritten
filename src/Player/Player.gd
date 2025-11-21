extends CharacterBody3D


@onready var input_gatherer = $Input as InputGatherer
@onready var model = $Model as PlayerModel
@onready var visuals = $Visuals as PlayerVisuals
@onready var camera_mount = $CameraMount
@onready var collider = $Collider


func _ready():
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
	
	move_and_slide()
	
	# Visuals -> follow parent transformations
