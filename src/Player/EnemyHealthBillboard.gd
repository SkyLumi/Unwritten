@tool
extends Node3D

@export var resources: HumanoidResources
@export_node_path("HumanoidResources") var resources_path: NodePath
@export var target: Node3D
@export var target_group: String = "player"
@export var show_distance: float = 10.0
@export var damage_delay: float = 0.5  # Delay before damage bar follows health bar
@onready var bar: ProgressBar = $SubViewport/Control/ProgressBar
@onready var damage_bar: ProgressBar = $SubViewport/Control/DamageBar
@onready var value_label: Label = $SubViewport/Control/ProgressBar/Value

var damage_bar_target: float = 0.0

func _ready():
	_resolve_resources()
	# Match player HUD style: green fill with dark background.
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color(0.12, 0.35, 0.12, 1)
	fill.border_width_left = 1
	fill.border_width_top = 1
	fill.border_width_right = 1
	fill.border_width_bottom = 1
	fill.border_color = Color(0.05, 0.15, 0.05, 1)
	bar.add_theme_stylebox_override("fill", fill)
	var bg := fill.duplicate()
	bg.bg_color = Color(0.05, 0.08, 0.05, 0.8)
	bar.add_theme_stylebox_override("background", bg)
	
	# Setup damage bar style (darker red background)
	var damage_fill := StyleBoxFlat.new()
	damage_fill.bg_color = Color(0.6, 0.15, 0.15, 1)
	damage_bar.add_theme_stylebox_override("fill", damage_fill)
	damage_bar.add_theme_stylebox_override("background", bg.duplicate())
	
	_sync_bar_from_resources()
	
	# Fix ViewportTexture path issues by assigning at runtime
	var sprite = get_node_or_null("Sprite3D")
	var vp = get_node_or_null("SubViewport")
	if sprite and vp:
		sprite.texture = vp.get_texture()

# Keeps billboard facing camera when parented under the enemy.
func _process(delta):
	_sync_bar_from_resources()
	
	# Smooth delayed damage bar animation (Genshin Impact style)
	if damage_bar and bar:
		# Update target when health decreases
		if bar.value < damage_bar.value:
			damage_bar_target = bar.value
		
		# Smoothly lerp damage bar to target
		if damage_bar.value > damage_bar_target:
			var lerp_speed = 2.0 / damage_delay  # Adjust speed based on delay
			damage_bar.value = lerp(damage_bar.value, damage_bar_target, lerp_speed * delta)
			# Snap to target when very close
			if abs(damage_bar.value - damage_bar_target) < 0.5:
				damage_bar.value = damage_bar_target
		else:
			damage_bar.value = bar.value
	
	# Toggle visibility based on distance to player/target
	var watcher := target
	if watcher == null and target_group != "":
		watcher = get_tree().get_first_node_in_group(target_group)
	if watcher:
		var dist = global_transform.origin.distance_to(watcher.global_transform.origin)
		visible = dist <= show_distance
	else:
		visible = true
	
	# Always face active camera
	var cam := get_viewport().get_camera_3d()
	if cam:
		look_at(cam.global_transform.origin, Vector3.UP)


func _resolve_resources():
	if resources:
		return
	if resources_path != NodePath() and has_node(resources_path):
		resources = get_node(resources_path) as HumanoidResources
		return
	var candidate := get_node_or_null("../Model/Resources")
	if candidate and candidate is HumanoidResources:
		resources = candidate


func _sync_bar_from_resources():
	bar.min_value = 0
	if damage_bar:
		damage_bar.min_value = 0
	
	if resources:
		var max_hp = max(1.0, resources.max_health)
		var current_hp = resources.health
		
		bar.max_value = max_hp
		bar.value = current_hp
		
		if damage_bar:
			damage_bar.max_value = max_hp
			# Initialize damage bar on first frame
			if damage_bar.value == 0:
				damage_bar.value = current_hp
				damage_bar_target = current_hp
		
		if value_label:
			value_label.text = "%d / %d" % [int(current_hp), int(max_hp)]
	elif Engine.is_editor_hint():
		# Editor fallback so the SubViewport preview shows a filled bar.
		bar.max_value = 100
		bar.value = 100
		if damage_bar:
			damage_bar.max_value = 100
			damage_bar.value = 100
		if value_label:
			value_label.text = "100 / 100"
