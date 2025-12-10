extends Area3D
class_name MCWeapon

var hitbox_ignore_list : Array[Area3D] = []
var is_attacking : bool = false
@export var damage : int = 20

func _ready():
	add_to_group("player_weapon")
	# Start disabled - only enable during attacks
	monitoring = false
	monitorable = false
	visible = false

func get_hit_data():
	return { "damage": damage }

func enable():
	is_attacking = true
	hitbox_ignore_list.clear()
	monitoring = true
	monitorable = true
	visible = true
	print("MCWeapon: ENABLED - Hitbox active")
	
	# Check for areas already overlapping when enabled
	# Use deferred call to ensure physics has updated
	call_deferred("_check_overlapping_areas")

func _check_overlapping_areas():
	if not is_attacking:
		return
	var overlapping = get_overlapping_areas()
	print("MCWeapon: Checking overlapping areas: ", overlapping.size())
	for area in overlapping:
		# Emit signal manually for already-overlapping areas
		area_entered.emit(area)

func disable():
	is_attacking = false
	hitbox_ignore_list.clear()
	monitoring = false
	monitorable = false
	visible = false
	print("MCWeapon: DISABLED - Hitbox inactive")
