extends Node3D

# Pastikan path ini benar. Kalau error "null", drag node AnimationPlayer ke sini.
@onready var anim = $AnimationPlayer 
@onready var hitbox = $Hitbox

@export var clouds: Array[Node3D]
var is_active: bool = false

func _ready():
	# Cek dulu biar gak crash
	if not anim:
		print("ERROR: AnimationPlayer tidak ditemukan!")
		return
	
	# Set posisi awal ke OFF
	anim.play("turn_off")
	# Langsung seek ke akhir animasi biar gak muter pas start
	anim.seek(anim.current_animation_length, true)
	
	# Connect signal area_entered dari child Hitbox
	if hitbox and not hitbox.area_entered.is_connected(_on_area_entered):
		hitbox.area_entered.connect(_on_area_entered)

func _on_area_entered(area):
	print("Lever: Area entered: ", area.name, " Groups: ", area.get_groups())
	
	# Check for player weapon (MCWeapon or Weapon) by group
	# If it entered, it means an attack is happening (weapon only monitors during attacks)
	if area.is_in_group("player_weapon"):
		print("Lever: player_weapon detected - triggering toggle!")
		# Prevent multiple hits per swing using hitbox_ignore_list
		if area.get("hitbox_ignore_list") != null:
			if area.hitbox_ignore_list.has(hitbox):
				print("Lever: Already hit this swing, ignoring")
				return
			area.hitbox_ignore_list.append(hitbox)
		toggle_lever()
		return
		
	# Check for old Weapon class (legacy system - not in player_weapon group)
	if area is Weapon:
		var weapon = area as Weapon
		var holder = weapon.holder
		
		var is_attacking_move = false
		if holder and holder.current_move:
			var move_name = holder.current_move.move_name
			if "longsword" in move_name or "attack" in move_name or "slash" in move_name:
				is_attacking_move = true
				
		if is_attacking_move:
			if not area.hitbox_ignore_list.has(hitbox):
				area.hitbox_ignore_list.append(hitbox)
				toggle_lever()
	else:
		print("Lever: Not a recognized weapon type")

func toggle_lever():
	# Debounce sederhana: kalau animasi lagi jalan, jangan terima input dulu
	if anim.is_playing():
		return

	is_active = !is_active
	
	if is_active:
		anim.play("turn_on")
		print("Lever ON")
		for cloud in clouds:
			if cloud and cloud.has_method("activate"):
				cloud.activate()
	else:
		anim.play("turn_off")
		print("Lever OFF")
		for cloud in clouds:
			if cloud and cloud.has_method("deactivate"):
				cloud.deactivate()

# Fungsi ini otomatis dipanggil setiap kali animasi selesai
func _on_anim_finished(anim_name):
	pass # Tidak perlu loop otomatis lagi
