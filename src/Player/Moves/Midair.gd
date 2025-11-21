extends Move

@export var DELTA_VECTOR_LENGTH = 6
@export var VERTICAL_SPEED_ADDED : float = 2.5
var jump_direction : Vector3

var landing_height : float = 1.163
var just_jumped = false

@export var JUMP_SPEED : float = 8.0 # sesuaikan dengan lompat utama kamu

#func default_lifecycle(input : InputPackage):
	#if Input.is_action_just_pressed("jump") and model.jump_count < model.MAX_JUMPS:
		#just_jumped = true
		#model.jump_count += 1
		#player.velocity.y = VERTICAL_SPEED_ADDED
#
		## Play the jump animation again
		#var xz_velocity = player.velocity
		#xz_velocity.y = 0
		#if xz_velocity.length_squared() >= 10:
			#model.animator.set_torso_animation("jump_sprint")
		#else:
			#model.animator.set_torso_animation("jump_run")
		#return "midair"
func default_lifecycle(input : InputPackage):
	# Idealnya pakai input dari InputPackage, tapi kalau belum ada:
	if Input.is_action_just_pressed("jump") and model.jump_count < model.MAX_JUMPS:
		just_jumped = true
		model.jump_count += 1

		# Kalau lagi jatuh, nolkan dulu biar double jump nggak kepotong
		if player.velocity.y < 0.0:
			player.velocity.y = 0.0

		# Selalu kasih power lompat PENUH (sama dengan lompat pertama)
		player.velocity.y = JUMP_SPEED

		# Animasi
		var xz_velocity = player.velocity
		xz_velocity.y = 0
		if xz_velocity.length_squared() >= 10:
			model.animator.set_torso_animation("jump_sprint")
		else:
			model.animator.set_torso_animation("jump_run")

		# Tetap di midair
		return "midair"

	var floor_distance = area_awareness.get_floor_distance()
	
	# Transition if close to floor OR if physics engine says we are on floor
	if floor_distance < landing_height or player.is_on_floor():
		var xz_velocity = player.velocity
		xz_velocity.y = 0
		if xz_velocity.length_squared() >= 10:
			return "landing_sprint"
		return "landing_run"
	else:
		return "okay"


#func update(input : InputPackage, delta ):
	#if just_jumped:
		#just_jumped = false
	#else:
		#player.velocity.y -= gravity * delta
	#process_input_vector(input, delta)
	#player.move_and_slide()

func update(input : InputPackage, delta ):
	if just_jumped:
		# Frame ini: baru saja lompat → jangan kasih gravitasi dulu
		just_jumped = false
	else:
		player.velocity.y -= gravity * delta

	process_input_vector(input, delta)
	player.move_and_slide()


func process_input_vector(input : InputPackage, delta : float):
	var input_direction = (player.camera_mount.basis * Vector3(-input.input_direction.x, 0, -input.input_direction.y)).normalized()
	var input_delta_vector = input_direction * DELTA_VECTOR_LENGTH
	
	jump_direction = (jump_direction + input_delta_vector * delta).limit_length(clamp(player.velocity.length(), 1, 999999))
	player.look_at(player.global_position - jump_direction)
	
	var new_velocity = (player.velocity + input_delta_vector * delta).limit_length(player.velocity.length())
	player.velocity = new_velocity


func on_enter_state():
	# Initialize velocity if starting from rest
	if player.velocity.length() == 0:
		player.velocity.y = -0.1  # Small downward velocity to start falling
	
	# CRITICAL: Disable floor snapping while in air!
	# This prevents move_and_slide from "sticking" to floor
	player.floor_snap_length = 0.0
	
	# the clamp construction is here to 
	# 1) prevent look_at annoying errors when our velocity is zero and it can't look_at properly
	# 3) have a way to scale from velocity. The longer the vector is, the harder it is to modify it by adding a delta.
	#    Scaling jump_direction with velocity is giving us that natural behaviour of faster jumps (sprints)
	#    being less controllable, and jumps from standing position being more volatile.
	#    The dependance on velocity paramter is not critical, delete this if you don't like the approach.
	jump_direction = Vector3(player.basis.z) * clamp(player.velocity.length(), 1, 999999)
	jump_direction.y = 0
