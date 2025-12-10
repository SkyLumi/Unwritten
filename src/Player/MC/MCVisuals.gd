extends Node3D
class_name MCVisuals

@onready var animation_player : AnimationPlayer = $mc/AnimationPlayer
@onready var model # Will be injected

var current_animation : String = ""

func accept_model(_model):
	model = _model
	# Additional setup if needed

func play_animation(anim_name: String, blend_time: float = 0.1):
	if current_animation == anim_name and animation_player.is_playing():
		return
	
	# Map semantic names to AnimationLibrary keys
	var target_anim = anim_name
	
	match anim_name:
		"idle": target_anim = "idle"
		"walk": target_anim = "walk"
		"run": target_anim = "run" 
		"jump": target_anim = "jump"
		"fall": target_anim = "midair"
		"attack_light": target_anim = "attack1"
		"attack_heavy": target_anim = "attack3"
		
	if animation_player.has_animation(target_anim):
		animation_player.play(target_anim, blend_time)
		current_animation = anim_name
	else:
		push_warning("MCVisuals: Animation not found: " + target_anim)

func stop_animation():
	animation_player.stop()
	current_animation = ""
	disable_hitbox()

func enable_hitbox():
	# Use get_node to be safe or cache it
	var weapon = $WeaponHitbox
	if weapon and weapon.has_method("enable"):
		weapon.enable()

func disable_hitbox():
	var weapon = $WeaponHitbox
	if weapon and weapon.has_method("disable"):
		weapon.disable()
