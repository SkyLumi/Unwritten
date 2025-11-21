extends Move


func default_lifecycle(input) -> String:
	if not player.is_on_floor():
		return "midair"
	
	if input.input_direction != Vector2.ZERO:
		return "walk"
	
	return "idle"


func on_enter_state():
	player.velocity = Vector3.ZERO
	# Re-enable floor snapping for ground movement
	player.floor_snap_length = 0.6
