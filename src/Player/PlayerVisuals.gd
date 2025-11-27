extends Node3D
class_name PlayerVisuals

@onready var model : PlayerModel

@onready var beta_joints = $Beta_Joints
@onready var beta_surface = $Beta_Surface

@onready var sword_visuals_1 = $SwordVisuals1
@onready var stamina_label = $"Stamina _bar_"
@onready var health_label = $"Health _bar_"
@onready var health_bar = $UI/Status/VBox/HealthBar
@onready var stamina_bar = $UI/Status/VBox/StaminaBar
@onready var health_value_label = $UI/Status/VBox/HealthBar/Value
@onready var stamina_value_label = $UI/Status/VBox/StaminaBar/Value

var default_surface_modulate : Color
var default_sword_modulate : Color

var surface_material : StandardMaterial3D
var sword_material : StandardMaterial3D
var health_style := StyleBoxFlat.new()
var stamina_style := StyleBoxFlat.new()

func accept_model(_model : PlayerModel):
	model = _model
	beta_surface.skeleton = _model.skeleton.get_path()
	beta_joints.skeleton = _model.skeleton.get_path()
	surface_material = _extract_material(beta_surface)
	sword_material = _extract_material(sword_visuals_1)
	if surface_material:
		default_surface_modulate = surface_material.albedo_color
	if sword_material:
		default_sword_modulate = sword_material.albedo_color
	# Hide HUD for enemies; show for player and init values.
	$UI.visible = not model.is_enemy
	health_bar.max_value = model.resources.max_health
	stamina_bar.max_value = model.resources.max_stamina
	health_bar.value = model.resources.health
	stamina_bar.value = model.resources.stamina
	_setup_status_bar_styles()


func _process(_delta):
	update_resources_interface()
	adjust_weapon_visuals()


func adjust_weapon_visuals():
	sword_visuals_1.global_transform = model.active_weapon.global_transform


func update_resources_interface():
	if not model.is_enemy:
		stamina_label.text = "Stamina " + "%10.3f" % model.resources.stamina
		health_label.text = "Health " + "%10.3f" % model.resources.health
		health_bar.value = model.resources.health
		stamina_bar.value = model.resources.stamina
		health_value_label.text = "%d / %d" % [round(model.resources.health), round(model.resources.max_health)]
		stamina_value_label.text = "%d / %d" % [round(model.resources.stamina), round(model.resources.max_stamina)]


func flash_damage():
	# Briefly flash the character to show impact.
	if not is_inside_tree():
		return
	if not surface_material:
		return
	var tween = create_tween()
	tween.tween_property(surface_material, "albedo_color", Color(1, 0.4, 0.4, 1), 0.05)
	tween.tween_property(surface_material, "albedo_color", default_surface_modulate, 0.12)


func flash_attack():
	# Highlight weapon on attack start.
	if not is_inside_tree():
		return
	if not sword_material:
		return
	var tween = create_tween()
	tween.tween_property(sword_material, "albedo_color", Color(1, 1, 0.3, 1), 0.05)
	tween.tween_property(sword_material, "albedo_color", default_sword_modulate, 0.12)


func _extract_material(node : Node) -> StandardMaterial3D:
	if not node:
		return null
	var mesh_instance : MeshInstance3D = null
	if node is MeshInstance3D:
		mesh_instance = node
	else:
		for child in node.get_children():
			if child is MeshInstance3D:
				mesh_instance = child
				break
	if mesh_instance == null:
		return null
	var mat : Material = mesh_instance.get_active_material(0)
	if mat:
		mat = mat.duplicate()
		mesh_instance.material_override = mat
	if mat is StandardMaterial3D:
		return mat
	return null


func _setup_status_bar_styles():
	# Health: green fill, dark background
	health_style.bg_color = Color(0.12, 0.35, 0.12, 1)
	health_style.border_width_left = 1
	health_style.border_width_top = 1
	health_style.border_width_right = 1
	health_style.border_width_bottom = 1
	health_style.border_color = Color(0.05, 0.15, 0.05, 1)
	health_bar.add_theme_stylebox_override("fill", health_style)
	var health_bg := health_style.duplicate()
	health_bg.bg_color = Color(0.05, 0.08, 0.05, 0.8)
	health_bar.add_theme_stylebox_override("background", health_bg)

	# Stamina: orange fill
	stamina_style.bg_color = Color(0.9, 0.5, 0.1, 1)
	stamina_style.border_width_left = 1
	stamina_style.border_width_top = 1
	stamina_style.border_width_right = 1
	stamina_style.border_width_bottom = 1
	stamina_style.border_color = Color(0.25, 0.15, 0.05, 1)
	stamina_bar.add_theme_stylebox_override("fill", stamina_style)
	var stamina_bg := stamina_style.duplicate()
	stamina_bg.bg_color = Color(0.1, 0.06, 0.02, 0.8)
	stamina_bar.add_theme_stylebox_override("background", stamina_bg)
