extends Move

var jump_direction : Vector3

var just_jumped = false


func default_lifecycle(input : InputPackage):
	# ---- HANDLE JUMP / DOUBLE JUMP ----
	if Input.is_action_just_pressed("jump") and model.jump_count < model.MAX_JUMPS:
		just_jumped = true
		model.jump_count += 1

		# Reset kecepatan jatuh biar double jump tetap kuat
		if player.velocity.y < 0.0:
			player.velocity.y = 0.0

		# Kekuatan lompat
		var jump_power = tuning.midair_jump_speed
		if model.jump_count == 2:
			jump_power *= tuning.midair_second_jump_multiplier

		player.velocity.y = jump_power

		# Animasi
		var xz_velocity = player.velocity
		xz_velocity.y = 0
		if xz_velocity.length_squared() >= 10:
			model.animator.set_torso_animation("jump_sprint")
		else:
			model.animator.set_torso_animation("jump_run")

		# Tetap di midair
		return "midair"

	# ---- CHECK TRANSITION TO LANDING ----
	var floor_distance = area_awareness.get_floor_distance()

	if floor_distance < tuning.midair_landing_height or player.is_on_floor():
		var xz_velocity = player.velocity
		xz_velocity.y = 0
		if xz_velocity.length_squared() >= 10:
			return "landing_sprint"
		return "landing_run"

	# Tetap di state ini
	return "okay"



func update(input : InputPackage, delta ):
	if just_jumped:
		just_jumped = false
	else:
		player.velocity.y -= gravity * delta

	process_input_vector(input, delta)
	player.move_and_slide()



func process_input_vector(input : InputPackage, delta : float):
	var input_direction = (player.camera_mount.basis * Vector3(-input.input_direction.x, 0, -input.input_direction.y)).normalized()
	var input_delta_vector = input_direction * tuning.midair_delta_vector_length
	
	jump_direction = (jump_direction + input_delta_vector * delta).limit_length(clamp(player.velocity.length(), 1, 999999))
	player.look_at(player.global_position - jump_direction)
	
	var new_velocity = (player.velocity + input_delta_vector * delta).limit_length(player.velocity.length())
	player.velocity = new_velocity



func on_enter_state():
	# Kasih sedikit dorongan turun kalau 0
	if player.velocity.length() == 0:
		player.velocity.y = -0.1
	
	# Disable floor snapping saat di udara
	player.floor_snap_length = 0.0
	
	jump_direction = Vector3(player.basis.z) * clamp(player.velocity.length(), 1, 999999)
	jump_direction.y = 0
