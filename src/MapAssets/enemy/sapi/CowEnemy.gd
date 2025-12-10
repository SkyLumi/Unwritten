extends CharacterBody3D

# Properti Cow Enemy
@export var speed: float = 3.0 # Cows are slower than bees
@export var chase_radius: float = 12.0
@export var attack_radius: float = 2.5
@export var damage: int = 15 # Cows hit harder
@export var attack_cooldown: float = 2.0
@export var max_health: int = 100 # Cows are tankier

# Node references
@onready var navigation_agent: NavigationAgent3D = $NavigationAgent3D
# Sapi scene instance is named "sapi"
@onready var animation_player: AnimationPlayer = $sapi/AnimationPlayer 
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
	
	# Setup navigation agent
	call_deferred("setup_navigation")
	
	# Play idle animation
	play_anim("sapi-idle")
	
	# Update health bar
	update_health_bar()

func setup_navigation():
	await get_tree().physics_frame
	
	navigation_agent.path_desired_distance = 1.0 # Cows are bigger
	navigation_agent.target_desired_distance = 1.5
	
	if target:
		navigation_agent.target_position = target.global_position

func _physics_process(delta):
	# Gravity
	if not is_on_floor():
		velocity += get_gravity() * delta
		
	if not target:
		move_and_slide()
		return
	
	var distance_to_target = global_position.distance_to(target.global_position)
	
	# Check if player is in chase radius
	if distance_to_target > chase_radius:
		# Too far, just idle
		play_anim("sapi-idle")
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)
		move_and_slide()
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
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)
	else:
		# Move towards player
		move_to_target(delta)
	
	move_and_slide()

func move_to_target(delta):
	if navigation_agent.is_navigation_finished():
		return
	
	var next_position = navigation_agent.get_next_path_position()
	var direction = (next_position - global_position).normalized()
	direction.y = 0  
	
	# Move
	velocity.x = direction.x * speed
	velocity.z = direction.z * speed
	
	# Rotate to face movement direction
	if direction.length() > 0.01:
		var target_rotation = atan2(direction.x, direction.z)
		rotation.y = lerp_angle(rotation.y, target_rotation, 5.0 * delta) # Cows turn slower
	
	# Play walk animation
	play_anim("sapi-jalan")

func look_at_target():
	var direction = (target.global_position - global_position).normalized()
	direction.y = 0
	if direction.length() > 0.01:
		var target_rotation = atan2(direction.x, direction.z)
		rotation.y = lerp_angle(rotation.y, target_rotation, 5.0 * get_physics_process_delta_time())

func attack():
	can_attack = false
	
	# Play attack animation
	play_anim("sapi-nyerang")
	
	# Wait for animation hit point
	await get_tree().create_timer(0.5).timeout
	
	# Deal damage to player if still in range and target exists
	if target and global_position.distance_to(target.global_position) <= attack_radius + 1.0:
		var model = target.get_node_or_null("Model")
		if model:
			var resources = model.get_node_or_null("Resources")
			if resources and resources.has_method("lose_health"):
				resources.lose_health(damage)
				print("Cow dealing damage to player: ", damage)
	
	# Start cooldown
	attack_timer.start()

func _on_attack_timer_timeout():
	can_attack = true
	# Return to idle animation if not moving (handled in process)

func play_anim(anim_name):
	# Prevent interrupting attack unless it's another attack or death
	if animation_player.current_animation == "sapi-nyerang" and animation_player.is_playing() and anim_name != "sapi-nyerang":
		return
		
	if animation_player and animation_player.has_animation(anim_name):
		if animation_player.current_animation != anim_name:
			animation_player.play(anim_name)

func take_damage(amount: int):
	current_health -= amount
	update_health_bar()
#	print("Cow took ", amount, " damage. Health: ", current_health, "/", max_health)
	
	if current_health <= 0:
		die()

# Called by BeeHurtbox when hit by weapon with hit_data
func hit(hit_data):
	if hit_data:
		take_damage(hit_data.damage)

# Called by BeeHurtbox as fallback
func lose_health(amount: int):
	take_damage(amount)

func _process(delta):
	# Animate Damage Bar (catch up effect)
	if health_billboard:
		var progress_bar = health_billboard.get_node_or_null("SubViewport/Control/ProgressBar")
		var damage_bar = health_billboard.get_node_or_null("SubViewport/Control/DamageBar")
		
		if progress_bar and damage_bar:
			if damage_bar.value > progress_bar.value:
				damage_bar.value = lerp(damage_bar.value, progress_bar.value, 5.0 * delta)
			else:
				damage_bar.value = progress_bar.value

func update_health_bar():
	if health_billboard:
		var progress_bar = health_billboard.get_node_or_null("SubViewport/Control/ProgressBar")
		var value_label = health_billboard.get_node_or_null("SubViewport/Control/ProgressBar/Value")
		
		var percent = (float(current_health) / float(max_health)) * 100.0
		
		if progress_bar:
			progress_bar.value = percent
			
		if value_label:
			value_label.text = str(max(current_health, 0)) + " / " + str(max_health)

func die():
#	print("Cow died!")
	set_physics_process(false)
	$CollisionShape3D.set_deferred("disabled", true)
	$Hurtbox.set_deferred("monitoring", false)
	$Hurtbox.set_deferred("monitorable", false)
	
	# Simple death effect - shrink or fall
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector3.ZERO, 0.5)
	await tween.finished
	
	queue_free()
