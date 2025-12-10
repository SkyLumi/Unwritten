extends CharacterBody3D

# --- BAGIAN PENTING: SIGNAL ---
# Signal ini dikirim ke UI biar bar-nya update otomatis
signal health_changed(current_hp, max_hp)
signal boss_died()

# Properti Bee Enemy
@export var speed: float = 5.0
@export var chase_radius: float = 10.0
@export var attack_radius: float = 2.0
@export var damage: int = 10
@export var attack_cooldown: float = 3.0
@export var max_health: int = 50

# Node references
@onready var navigation_agent: NavigationAgent3D = $NavigationAgent3D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var attack_timer: Timer = $AttackTimer

# NOTE: Variable health_billboard DIHAPUS karena bikin error (Node not found)

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
	if animation_player and animation_player.has_animation("idle"):
		animation_player.play("idle")
	
	# KIRIM SIGNAL AWAL: Biar UI tahu boss sudah spawn & HP penuh
	health_changed.emit(current_health, max_health)

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
		if animation_player.current_animation != "idle":
			animation_player.play("idle")
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
	# --- MODE MANUAL (Tanpa Navigation Agent) ---
	# Ini buat ngetes doang, apakah velocity bekerja
	
	# Hitung arah langsung ke player (tanpa peduli tembok)
	var direction = (target.global_position - global_position).normalized()
	direction.y = 0 # Biar gak terbang/nembus tanah ke bawah
	
	# Masukkan ke velocity
	velocity.x = direction.x * speed
	velocity.z = direction.z * speed
	
	# Debug print (Cek di output bawah layar ada angkanya gak?)
	# print("Velocity: ", velocity) 
	
	move_and_slide()
	
	# Rotasi manual
	if direction.length() > 0.01:
		var target_rotation = atan2(direction.x, direction.z)
		rotation.y = lerp_angle(rotation.y, target_rotation, 10.0 * delta)
	
	# Play anim
	if animation_player.current_animation != "jalan":
		animation_player.play("jalan")

func look_at_target():
	var direction = (target.global_position - global_position).normalized()
	direction.y = 0
	if direction.length() > 0.01:
		var target_rotation = atan2(direction.x, direction.z)
		rotation.y = lerp_angle(rotation.y, target_rotation, 10.0 * get_physics_process_delta_time())

func attack():
	can_attack = false
	
	# Play attack animation
	if animation_player and animation_player.has_animation("nyerang"):
		animation_player.play("nyerang")
	
	# Wait for animation hit point
	await get_tree().create_timer(0.8).timeout
	
	# Deal damage to player if still in range
	if target and global_position.distance_to(target.global_position) <= attack_radius + 1.0:
		var model = target.get_node_or_null("Model")
		if model:
			var resources = model.get_node_or_null("Resources")
			if resources and resources.has_method("lose_health"):
				resources.lose_health(damage)
				print("Boss dealing damage to player: ", damage)
	
	# Start cooldown
	attack_timer.start()

func _on_attack_timer_timeout():
	can_attack = true
	# Return to idle animation after attack
	if animation_player.has_animation("idle"):
		animation_player.play("idle")

func take_damage(amount: int):
	current_health -= amount
	
	# --- UPDATE DISINI ---
	# Kita tidak update UI manual, tapi teriak (emit) signal ke CanvasLayer
	health_changed.emit(current_health, max_health)
	
	print("Boss took ", amount, " damage. Health: ", current_health, "/", max_health)
	
	if current_health <= 0:
		die()

# Called by Hurtbox when hit by weapon with hit_data
func hit(hit_data):
	if hit_data:
		take_damage(hit_data.damage)

# Called by Hurtbox as fallback
func lose_health(amount: int):
	take_damage(amount)

func _process(delta):
	# Periodic debug print (approx every 1 sec)
	if Engine.get_physics_frames() % 60 == 0:
		pass 
		# print("DEBUG HEARTBEAT: Boss Alive")
	
	# CODE LAMA YANG BIKIN ERROR (Animation Bar) SUDAH SAYA HAPUS DISINI
	# Karena animasi bar sekarang urusan script UI (BossHUD.gd)

func die():
	print("Boss died!")
	
	# Kirim signal mati (biar UI bisa hilang pelan-pelan/fade out)
	boss_died.emit()
	
	# Disable processing and collision
	set_physics_process(false)
	$CollisionShape3D.set_deferred("disabled", true)
	
	# Matikan hurtbox biar gak bisa dipukul lagi pas animasi mati
	if has_node("Hurtbox"):
		$Hurtbox.set_deferred("monitoring", false)
		$Hurtbox.set_deferred("monitorable", false)
	
	# Play death animation if available
	if animation_player and animation_player.has_animation("death"):
		animation_player.play("death")
		await animation_player.animation_finished
	elif animation_player and animation_player.has_animation("hurt"): 
		animation_player.play("hurt")
		await get_tree().create_timer(0.5).timeout
	else:
		await get_tree().create_timer(0.2).timeout
	
	queue_free()
