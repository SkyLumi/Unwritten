extends Move

var jumped : bool = false


func default_lifecycle(_input : InputPackage):
	if works_longer_than(tuning.jump_transition_timing):
		jumped = false
		return "midair"
	else: 
		return "okay"


func update(_input : InputPackage, _delta ):
	process_jump()
	player.move_and_slide()


func process_jump():
	if works_longer_than(tuning.jump_impulse_delay):
		if not jumped:
			model.jump_count += 1
			player.velocity = player.basis.z * tuning.jump_run_speed 
			player.velocity.y += tuning.jump_run_vertical_boost
			jumped = true


func on_enter_state():
	player.velocity = player.velocity.normalized() * tuning.jump_run_speed 
