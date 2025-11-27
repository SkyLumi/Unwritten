extends Move


func default_lifecycle(input : InputPackage):
	if not player.is_on_floor():
		return "midair" 
	
	return best_input_that_can_be_paid(input)


func update(input : InputPackage, delta : float):
	# Manual movement logic (copied/adapted from Run.gd)
	var input_direction = (player.camera_mount.basis * Vector3(-input.input_direction.x, 0, -input.input_direction.y)).normalized()
	
	# Rotate player
	if input.input_direction != Vector2.ZERO:
		var face_direction = player.basis.z
		var angle = face_direction.signed_angle_to(input_direction, Vector3.UP)
		player.rotate_y(clamp(angle, -tuning.walk_turn_speed * delta, tuning.walk_turn_speed * delta))
	
	# Apply velocity
	player.velocity.x = input_direction.x * tuning.walk_speed
	player.velocity.z = input_direction.z * tuning.walk_speed
	
	# Apply gravity (keep existing Y velocity or apply gravity)
	player.velocity.y -= gravity * delta
	
	# print("Walk velocity: ", player.velocity)


func on_enter_state():
	# Re-enable floor snapping for ground movement
	player.floor_snap_length = 0.6
