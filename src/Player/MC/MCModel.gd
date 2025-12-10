extends Node
class_name MCModel

# Compatibility properties for Player.gd
@export var is_enemy : bool = false
@export var base_health : float = 100
@export var base_stamina : float = 100
@export var stamina_regen : float = 10.0 # Stamina regen per second
@export var jump_stamina_cost : float = 10.0
@export var attack_stamina_cost : float = 15.0
@export var sprint_stamina_cost : float = 7.0 # Per second

class MCMove:
	var move_name: String = "idle"
	func _init(name: String):
		move_name = name

var current_move : MCMove = MCMove.new("idle")

var resources = {
	"health": 100.0,
	"max_health": 100.0,
	"stamina": 100.0,
	"max_stamina": 100.0
}

# State Management
enum State { IDLE, WALK, SPRINT, JUMP, FALL, ATTACK }
var current_state = State.IDLE
var state_time : float = 0.0

# Integration
@onready var player = $".."
@onready var visuals # Will be assigned by Player.gd via visuals.accept_model(self) but actually we need reference to visuals to drive animation.
# Player.gd does: visuals.accept_model(model). So Visuals knows Model.
# Model needs to tell Visuals what to play.
# We can use a signal or direct reference if Player.gd allows.
# looking at Player.gd: "visuals.accept_model(model)". 
# Let's add a setup logic.

var active_visuals : MCVisuals

# Movement Parameters
const WALK_SPEED = 5.0
const SPRINT_SPEED = 10.0
const JUMP_VELOCITY = 5.0
const GRAVITY = 9.8

# Jump Logic
var jump_count = 0
@export var max_jumps = 2

# Jump Settings (configurable per jump type)
@export_group("Idle Jump")
@export var idle_jump_velocity : float = 4.0
@export var idle_jump_air_speed : float = 4.0

@export_group("Walk Jump")
@export var walk_jump_velocity : float = 5.0
@export var walk_jump_air_speed : float = 5.0

@export_group("Sprint Jump")
@export var sprint_jump_velocity : float = 6.5
@export var sprint_jump_air_speed : float = 8.0
@export var sprint_jump_forward_boost : float = 3.0  # Extra forward momentum

# Current jump parameters (set when jumping)
var current_air_speed : float = 5.0
var jump_forward_boost : float = 0.0

# Attack Logic
var combo_count = 0
var attack_timer = 0.0

# Compatibility helper class for Resources
class ResourceWrapper:
	var model
	func _init(_model):
		model = _model
	
	var health: float:
		get: return model.resources.health
		set(value): model.resources.health = value
	
	var max_health: float:
		get: return model.resources.max_health
		set(value): model.resources.max_health = value
		
	func lose_health(amount: float):
		model.resources.health -= amount
		if model.resources.health < 0:
			model.resources.health = 0
		print("Player took damage: ", amount, " Current HP: ", model.resources.health)

var Resources : ResourceWrapper

func _ready():
	resources.health = base_health
	resources.max_health = base_health
	resources.stamina = base_stamina
	resources.max_stamina = base_stamina
	Resources = ResourceWrapper.new(self)

# Direct method for enemies to call - simplest approach
func lose_health(amount: float):
	resources.health -= amount
	if resources.health < 0:
		resources.health = 0
	print("MCModel.lose_health called: -", amount, " HP. Current: ", resources.health)

# Validates and executes a bounce/launch
func bounce(force: float = 15.0):
	print("MCModel.bounce called with force: ", force)
	player.velocity.y = force
	jump_count = 0 # Reset jumps so player can double jump after bounce
	_start_state(State.JUMP)

func update(input: InputPackage, delta: float):
	state_time += delta
	
	# Resolve Visuals reference if not already done (Hacky but works if Player.gd didn't inject it inversely)
	if not active_visuals and player.has_node("Visuals"):
		var v = player.get_node("Visuals")
		if v is MCVisuals:
			active_visuals = v
	
	match current_state:
		State.IDLE:
			_update_idle(input, delta)
		State.WALK:
			_update_move(input, delta, WALK_SPEED)
		State.SPRINT:
			_update_move(input, delta, SPRINT_SPEED)
		State.JUMP:
			_update_jump(input, delta)
		State.FALL:
			_update_fall(input, delta)
		State.ATTACK:
			_update_attack(input, delta)
	
	# Sprint Stamina Drain
	if current_state == State.SPRINT:
		resources.stamina = max(resources.stamina - sprint_stamina_cost * delta, 0)
		# If out of stamina, stop sprinting
		if resources.stamina <= 0:
			_start_state(State.WALK)
	
	# Stamina Regen (only when not sprinting)
	if current_state != State.SPRINT and resources.stamina < resources.max_stamina:
		resources.stamina = min(resources.stamina + stamina_regen * delta, resources.max_stamina)
	
	# Apply Physics to Player Body
	_apply_physics(delta)

func _start_state(new_state):
	# If re-entering Jump state (double jump), reset state_time to play anim from start
	if current_state == new_state and new_state == State.JUMP:
		state_time = 0.0
		# Force restart animation
		if active_visuals:
			active_visuals.stop_animation()
			active_visuals.play_animation("jump")
		return

	current_state = new_state
	state_time = 0.0
	
	# Update compatibility property
	var state_name = "idle"
	match new_state:
		State.IDLE: state_name = "idle"
		State.WALK: state_name = "walk"
		State.SPRINT: state_name = "sprint"
		State.JUMP: state_name = "jump"
		State.FALL: state_name = "fall"
		State.ATTACK: state_name = "attack"
	
	current_move.move_name = state_name
	
	if not active_visuals: return
	
	match new_state:
		State.IDLE:
			active_visuals.play_animation("idle")
			active_visuals.disable_hitbox()
		State.WALK:
			active_visuals.play_animation("walk")
			active_visuals.disable_hitbox()
		State.SPRINT:
			active_visuals.play_animation("run")
			active_visuals.disable_hitbox()
		State.JUMP:
			active_visuals.play_animation("jump")
			active_visuals.disable_hitbox()
		State.FALL:
			active_visuals.play_animation("fall")
			active_visuals.disable_hitbox() # Ensure disabled
		State.ATTACK:
			active_visuals.enable_hitbox()
			if combo_count % 2 == 0:
				active_visuals.play_animation("attack_light")
			else:
				active_visuals.play_animation("attack_heavy")

func _update_idle(input: InputPackage, delta: float):
	player.velocity.x = move_toward(player.velocity.x, 0, WALK_SPEED)
	player.velocity.z = move_toward(player.velocity.z, 0, WALK_SPEED)
	
	if check_jump(input): return
	if check_attack(input): return
	
	if input.input_direction.length() > 0:
		_start_state(State.WALK)

func _update_move(input: InputPackage, delta: float, speed: float):
	if check_jump(input): return
	if check_attack(input): return
	
	if input.input_direction.length() == 0:
		_start_state(State.IDLE)
		return
	
	if input.actions.has("sprint") and current_state != State.SPRINT:
		_start_state(State.SPRINT)
		return
	elif not input.actions.has("sprint") and current_state == State.SPRINT:
		_start_state(State.WALK)
		return
		
	# Rotate Player
	var target_dir = Vector3(input.input_direction.x, 0, input.input_direction.y).normalized()
	if target_dir.length() > 0.1:
		# Assume camera relative input or absolute, for simplicity absolute first or relative to player
		# Player.gd InputGatherer gets vector relative to camera usually? Let's assume input_direction is already processed relative to camera Y.
		# If we look at Input.gd, it gets raw "left", "right" etc. We might need camera basis.
		
		# For now, let's just move in the input direction converted to 3D
		var cam = player.get_node_or_null("CameraMount/PlayerCamera")
		var move_dir = target_dir
		if cam:
			var cam_basis = cam.global_transform.basis
			move_dir = (cam_basis.x * target_dir.x + cam_basis.z * target_dir.z).normalized()
			move_dir.y = 0
			move_dir = move_dir.normalized()
		
		player.velocity.x = move_dir.x * speed
		player.velocity.z = move_dir.z * speed
		
		# Rotate visual model or player? Player body rotation usually.
		if move_dir.length() > 0.01:
			var target_rot = atan2(move_dir.x, move_dir.z)
			player.rotation.y = lerp_angle(player.rotation.y, target_rot, 10 * delta)

func _update_jump(input: InputPackage, delta: float):
	# Allow double jump
	if check_jump(input): return
	
	# Air control - allow horizontal movement while jumping
	_apply_air_control(input, delta)
	
	# Wait a bit before transitioning to fall (gives time for double jump)
	# Only transition to fall after minimum jump time AND velocity is negative
	if state_time > 0.3 and player.velocity.y < 0:
		_start_state(State.FALL)
		return
		
	if player.is_on_floor() and state_time > 0.1:
		_start_state(State.IDLE)

func _update_fall(input: InputPackage, delta: float):
	# Allow double jump
	if check_jump(input): return
	
	# Air control - allow horizontal movement while falling
	_apply_air_control(input, delta)
	
	if player.is_on_floor():
		_start_state(State.IDLE)

func _apply_air_control(input: InputPackage, delta: float):
	# Use current_air_speed set when jump started (varies by jump type)
	
	var target_dir = Vector3(input.input_direction.x, 0, input.input_direction.y).normalized()
	if target_dir.length() > 0.1:
		var cam = player.get_node_or_null("CameraMount/PlayerCamera")
		var move_dir = target_dir
		if cam:
			var cam_basis = cam.global_transform.basis
			move_dir = (cam_basis.x * target_dir.x + cam_basis.z * target_dir.z).normalized()
			move_dir.y = 0
			move_dir = move_dir.normalized()
		
		# Apply horizontal velocity
		player.velocity.x = move_dir.x * current_air_speed
		player.velocity.z = move_dir.z * current_air_speed
		
		# Rotate player to face movement direction
		if move_dir.length() > 0.01:
			var target_rot = atan2(move_dir.x, move_dir.z)
			player.rotation.y = lerp_angle(player.rotation.y, target_rot, 5 * delta)

func _update_attack(input: InputPackage, delta: float):
	if state_time > 0.5: # Hardcoded attack duration for now
		_start_state(State.IDLE)

func check_jump(input: InputPackage) -> bool:
	if input.actions.has("jump_idle") or input.actions.has("jump_run") or input.actions.has("jump_sprint"):
		if jump_count < max_jumps and resources.stamina >= jump_stamina_cost:
			resources.stamina -= jump_stamina_cost
			
			# Determine jump type based on previous state
			var jump_vel = idle_jump_velocity
			current_air_speed = idle_jump_air_speed
			jump_forward_boost = 0.0
			
			if input.actions.has("jump_sprint") or current_state == State.SPRINT:
				# Sprint jump - highest and farthest
				jump_vel = sprint_jump_velocity
				current_air_speed = sprint_jump_air_speed
				jump_forward_boost = sprint_jump_forward_boost
			elif input.actions.has("jump_run") or current_state == State.WALK:
				# Walk jump - medium
				jump_vel = walk_jump_velocity
				current_air_speed = walk_jump_air_speed
			
			# Apply jump velocity
			player.velocity.y = jump_vel
			
			# Apply forward boost for sprint jump
			if jump_forward_boost > 0:
				var forward_dir = -player.global_transform.basis.z.normalized()
				forward_dir.y = 0
				player.velocity.x += forward_dir.x * jump_forward_boost
				player.velocity.z += forward_dir.z * jump_forward_boost
			
			jump_count += 1
			_start_state(State.JUMP)
			return true
	return false

func check_attack(input: InputPackage) -> bool:
	if input.combat_actions.has("light_attack_pressed"):
		if resources.stamina >= attack_stamina_cost:
			resources.stamina -= attack_stamina_cost
			combo_count += 1
			_start_state(State.ATTACK)
			return true
	return false

func reset_jump_count():
	jump_count = 0
	_start_state(State.IDLE)

func _apply_physics(delta: float):
	if not player.is_on_floor():
		player.velocity.y -= GRAVITY * delta
	else:
		# Reset jump count when on floor
		if current_state != State.JUMP: # Avoid resetting instantly when starting jump
			jump_count = 0
