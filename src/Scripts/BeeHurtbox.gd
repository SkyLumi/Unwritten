extends Area3D

# Simple Hurtbox for non-humanoid enemies
# Detects weapons and notifies parent to take damage

@export var processor: Node
@export var ignored_weapon_groups: Array[String] = ["enemy_weapon"]

func _ready():
	# Ensure monitoring is enabled
	monitoring = true
	monitorable = true
	
	# Fallback: if processor (exported node) is null, assume parent is the processor
	if not processor:
		processor = get_parent()
		
	print("BeeHurtbox ready! Processor: ", processor)

func _physics_process(delta):
	if not monitoring:
		return
		
	var areas = get_overlapping_areas()
	if areas.size() > 0:
		for area in areas:
			# print("BeeHurtbox PER-FRAME OVERLAP: ", area.name, " Groups: ", area.get_groups(), " Layer: ", area.collision_layer)
			_on_area_contact(area)

func _on_area_contact(area: Area3D):
	if _is_eligible_attacking_weapon(area):
		if not area.hitbox_ignore_list.has(self):
			area.hitbox_ignore_list.append(self)
			
			var hit_data = area.get_hit_data() if area.has_method("get_hit_data") else null
			var final_damage = 0
			
			if hit_data:
				final_damage = hit_data.damage
			
			# Fallback: If damage is 0 (e.g. idle/walk state) or hit_data missing, force default damage
			if final_damage <= 0:
				print("BeeHurtbox: Weapon detected but damage was 0/null. Forcing 10 damage.")
				final_damage = 10
			
			print("BeeHurtbox: Applying damage: ", final_damage)
			
			if processor:
				if processor.has_method("hit") and hit_data:
					hit_data.damage = final_damage
					processor.hit(hit_data)
				elif processor.has_method("lose_health"):
					processor.lose_health(final_damage)
		else:
			print("BeeHurtbox: Weapon ignored (already in ignore list for this swing)")

func _is_eligible_attacking_weapon(area: Area3D) -> bool:
	# Check ignored groups (e.g. enemy_weapon)
	for group in ignored_weapon_groups:
		if area.is_in_group(group):
			print("BeeHurtbox ignoring weapon in group: ", group)
			return false
	
	# If it's a player weapon, check is_attacking status
	if area.is_in_group("player_weapon"):
		if area.get("is_attacking") == true:
			print("BeeHurtbox: Valid attacking player_weapon detected!")
			return true
		else:
			return false
	
	if "is_attacking" in area:
		if area.is_attacking:
			return true
		else:
			print("BeeHurtbox: Weapon found but is_attacking is false.")
			return false
	
	print("BeeHurtbox: Area is not a valid weapon (no is_attacking property)")
	return false
