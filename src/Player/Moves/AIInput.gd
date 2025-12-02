extends InputGatherer
class_name AIInputGatherer

# Simple AI input provider: chases a target using NavigationAgent3D if available,
# otherwise moves directly toward the target. Adds basic melee attack intent when close.

@export var target: Node3D
@export var navigation_agent: NavigationAgent3D
@export var attack_distance: float = 2.0
@export var sprint_distance: float = 5.0
@export var attack_cooldown: float = 3.0 # seconds between attack attempts
@export var strafe_distance: float = 3.5 # start strafing/dodging instead of closing in

# Small tolerance to stop jittering when very close to the target.
@export var stop_distance: float = 0.5
@export var target_group: String = "player"

var _last_attack_time := -9999.0
var _last_delta := 0.0


func _ready():
	# Fallback: auto-find target by group if not wired in the scene.
	if not target and target_group != "":
		target = get_tree().get_first_node_in_group(target_group)


func gather_input() -> InputPackage:
	_last_delta = get_process_delta_time()
	var input := InputPackage.new()
	input.actions = ["idle"]
	input.combat_actions = []
	input.input_direction = Vector2.ZERO
	
	var direction: Vector3 = Vector3.ZERO
	var distance := 0.0
	
	if target:
		var target_pos = target.global_transform.origin
		var owner_body: CharacterBody3D = get_parent() as CharacterBody3D
		
		if navigation_agent:
			navigation_agent.target_position = target_pos
			var next_position = navigation_agent.target_position
			if not navigation_agent.is_navigation_finished():
				next_position = navigation_agent.get_next_path_position()
			direction = next_position - navigation_agent.global_transform.origin
		elif owner_body:
			direction = target_pos - owner_body.global_transform.origin
		
		direction.y = 0
		distance = direction.length()
	
	if distance > stop_distance and direction != Vector3.ZERO:
		input.actions.append("walk")
		
		# Sprint if far enough.
		if distance > sprint_distance:
			input.actions.append("sprint")
		elif distance < strafe_distance:
			# Dodge/strafe by circling target instead of full chase.
			direction = direction.rotated(Vector3.UP, deg_to_rad(50))
		
		# Convert world direction into local input relative to the owner's camera.
		var owner_cam_basis: Basis = get_parent().get_node("CameraMount").global_transform.basis if get_parent().has_node("CameraMount") else Basis.IDENTITY
		var local_dir = owner_cam_basis.inverse() * direction.normalized()
		input.input_direction = Vector2(-local_dir.x, -local_dir.z).normalized()
	else:
		input.actions.append("idle")
	
	if distance <= attack_distance and _can_attack_now():
		input.combat_actions.append("light_attack_pressed")
		_last_attack_time = Time.get_unix_time_from_system()
	
	return input


func _can_attack_now() -> bool:
	var now = Time.get_unix_time_from_system()
	return (now - _last_attack_time) >= attack_cooldown
