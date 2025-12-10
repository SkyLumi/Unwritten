extends CharacterBody3D

# Properti Bee Enemy
@export var speed: float = 5.0
@export var chase_radius: float = 10.0
@export var attack_radius: float = 2.0
@export var damage: int = 10
@export var attack_cooldown: float = 3.0
@export var max_health: int = 50

# Node references
@onready var navigation_agent: NavigationAgent3D = $NavigationAgent3D
@onready var animation_player: AnimationPlayer = $bee/AnimationPlayer
@onready var attack_timer: Timer = $AttackTimer
@onready var health_billboard = $HealthBillboard

var target: Node3D = null
var can_attack: bool = true
var current_health: int

func _ready():
	current_health = max_health
	
	# Cari player
	target = get_tree().get_first_node_in_group("player")
	
	# Setup attack timer
	attack_timer.wait_time = attack_cooldown
	attack_timer.one_shot = true
	attack_timer.timeout.connect(_on_attack_timer_timeout)
	
	# Setup navigation agent - IMPORTANT: wait for navigation to be ready!
	call_deferred("setup_navigation")
	
	# Play idle animation
	if animation_player and animation_player.has_animation("idlewalk"):
		animation_player.play("idlewalk")
	
	# Update health bar
	update_health_bar()

func setup_navigation():
	# Wait for first physics frame to make sure navigation is ready
	await get_tree().physics_frame
	
	navigation_agent.path_desired_distance = 0.5
	navigation_agent.target_desired_distance = 0.5
	
	if target:
		navigation_agent.target_position = target.global_position

func _physics_process(delta):
	if not target:
		return
	
	var distance_to_target = global_position.distance_to(target.global_position)
	
	# Check if player is in chase radius
	if distance_to_target > chase_radius:
		# Too far, just idle
		if animation_player.current_animation != "idlewalk":
			animation_player.play("idlewalk")
		return
	
	# Update navigation target
	navigation_agent.target_position = target.global_position
	
	# Check if close enough to attack
	if distance_to_target <= attack_radius:
		# Attack player
		if can_attack:
			attack()
		# Stop moving, just rotate to face player
		look_at_target()
	else:
		# Move towards player
		move_to_target(delta)

func move_to_target(delta):
	if navigation_agent.is_navigation_finished():
		return
	
	var next_position = navigation_agent.get_next_path_position()
	var direction = (next_position - global_position).normalized()
	direction.y = 0  # Keep on same height
	
	# Move
	velocity = direction * speed
	move_and_slide()
	
	# Rotate to face movement direction
	if direction.length() > 0.01:
		var target_rotation = atan2(direction.x, direction.z)
		rotation.y = lerp_angle(rotation.y, target_rotation, 10.0 * delta)
	
	# Play walk animation
	if animation_player.current_animation != "idlewalk":
		animation_player.play("idlewalk")

func look_at_target():
	var direction = (target.global_position - global_position).normalized()
	direction.y = 0
	if direction.length() > 0.01:
		var target_rotation = atan2(direction.x, direction.z)
		rotation.y = lerp_angle(rotation.y, target_rotation, 10.0 * get_physics_process_delta_time())

func attack():
	can_attack = false
	
	# Play attack animation
	if animation_player and animation_player.has_animation("attack_001"):
		animation_player.play("attack_001")
	
	# Wait for animation hit point (approx 0.8s for typical attack anims)
	await get_tree().create_timer(0.8).timeout
	
	# Deal damage to player if still in range and target exists
	if target and global_position.distance_to(target.global_position) <= attack_radius + 1.0:
		var model = target.get_node_or_null("Model")
		if model:
			print("Bee: Found model, attempting damage...")
			# Method 1: Direct lose_health on model (MCModel style)
			if model.has_method("lose_health"):
				model.lose_health(damage)
				print("Bee dealing damage via model.lose_health: ", damage)
			# Method 2: Try Resources property (MCModel style)
			elif model.get("Resources") != null:
				var res = model.Resources
				if res and res.has_method("lose_health"):
					res.lose_health(damage)
					print("Bee dealing damage via Resources.lose_health: ", damage)
			# Method 3: Try as child node (HumanoidModel style)  
			else:
				var resources = model.get_node_or_null("Resources")
				if resources and resources.has_method("lose_health"):
					resources.lose_health(damage)
					print("Bee dealing damage via child node: ", damage)
				else:
					print("Bee: Could not find any way to damage player!")
		else:
			print("Bee: Target has no Model")
	
	# Start cooldown
	attack_timer.start()

func _on_attack_timer_timeout():
	can_attack = true
	# Return to idle animation after attack
	if animation_player.has_animation("idlewalk"):
		animation_player.play("idlewalk")

func take_damage(amount: int):
	current_health -= amount
	update_health_bar()
	
	print("Bee took ", amount, " damage. Health: ", current_health, "/", max_health)
	
	if current_health <= 0:
		die()

# Called by BeeHurtbox when hit by weapon with hit_data
func hit(hit_data):
	# Directly access damage property, assuming hit_data is valid if passed
	if hit_data:
		take_damage(hit_data.damage)

# Called by BeeHurtbox as fallback if hit_data doesn't work
func lose_health(amount: int):
	take_damage(amount)

func _process(delta):
	# Periodic debug print (approx every 1 sec)
	#if Engine.get_physics_frames() % 60 == 0:
		#print("DEBUG HEARTBEAT: Bee Health: ", current_health, "/", max_health)

	# Animate Damage Bar (catch up effect)
	if health_billboard:
		var progress_bar = health_billboard.get_node_or_null("SubViewport/Control/ProgressBar")
		var damage_bar = health_billboard.get_node_or_null("SubViewport/Control/DamageBar")
		
		if progress_bar and damage_bar:
			if damage_bar.value > progress_bar.value:
				# Lerp damage bar down slowly
				damage_bar.value = lerp(damage_bar.value, progress_bar.value, 5.0 * delta)
			else:
				# Snap if somehow lower (e.g. healing)
				damage_bar.value = progress_bar.value

func update_health_bar():
	if health_billboard:
		var progress_bar = health_billboard.get_node_or_null("SubViewport/Control/ProgressBar")
		var damage_bar = health_billboard.get_node_or_null("SubViewport/Control/DamageBar")
		var value_label = health_billboard.get_node_or_null("SubViewport/Control/ProgressBar/Value")
		
		var percent = (float(current_health) / float(max_health)) * 100.0
		# print("DEBUG: Updating bars to percent: ", percent)
		
		if progress_bar:
			progress_bar.value = percent
			# NOTE: We DO NOT update damage_bar here, so it stays high and reveals the red color
			# It will catch up in _process
			
		if value_label:
			value_label.text = str(max(current_health, 0)) + " / " + str(max_health)
	else:
		print("DEBUG: HealthBillboard is null!")

func die():
	print("Bee died!")
	
	# Disable processing and collision
	set_physics_process(false)
	$CollisionShape3D.set_deferred("disabled", true)
	$Hurtbox.set_deferred("monitoring", false)
	$Hurtbox.set_deferred("monitorable", false)
	
	# Play death animation if available
	if animation_player and animation_player.has_animation("death"):
		animation_player.play("death")
		await animation_player.animation_finished
	elif animation_player and animation_player.has_animation("hurt"): # Backup anim
		animation_player.play("hurt")
		await get_tree().create_timer(0.5).timeout
	else:
		# Fallback visual effect: simply fall down or wait a bit
		await get_tree().create_timer(0.2).timeout
	
	queue_free()
