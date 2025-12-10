extends Node
class_name InputGatherer

@onready var model  = $"../Model"

func gather_input() -> InputPackage:
	var new_input = InputPackage.new()
	
	new_input.actions.append("idle")
	
	# If dead, ignore further inputs.
	if _is_dead():
		return new_input
	
	var movement_locked = _movement_locked()
	if not movement_locked:
		new_input.input_direction = Input.get_vector("left", "right", "forward", "backward")
		if new_input.input_direction != Vector2.ZERO:
			new_input.actions.append("walk")
			if Input.is_action_pressed("sprint"):		# sprint is hidden here to avoid standing in place and sprinting
				new_input.actions.append("sprint")
	else:
		new_input.input_direction = Vector2.ZERO
	
	if Input.is_action_pressed("parry"):
		new_input.actions.append("parry")
	
	if Input.is_action_pressed("roll"):
		new_input.actions.append("roll")
	
	if Input.is_action_pressed("block"):
		new_input.actions.append("block")
	
	if Input.is_action_just_pressed("jump"):
		if new_input.actions.has("sprint"):
			new_input.actions.append("jump_sprint")
		elif new_input.actions.has("walk") or new_input.input_direction != Vector2.ZERO:
			new_input.actions.append("jump_run")
		else:
			new_input.actions.append("jump_idle")
	
	if Input.is_action_just_pressed("light_attack"):
		new_input.combat_actions.append("light_attack_pressed")
	#if Input.is_action_just_pressed("heavy_attack"):
		#new_input.combat_actions.append("heavy_attack_pressed")
	
	#print(new_input.input_direction)
	return new_input


func _is_dead() -> bool:
	if not model:
		return false
	if model.resources and model.resources.health < 1:
		return true
	return model.current_move and model.current_move.move_name == "death"


func _movement_locked() -> bool:
	if not model or not model.current_move:
		return false
	return model.current_move.move_name in ["parry", "block", "parried", "riposte", "staggered", "death"]
