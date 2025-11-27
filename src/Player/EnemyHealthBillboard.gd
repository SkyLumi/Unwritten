extends Node3D

@export var resources: HumanoidResources
@export var target: Node3D
@export var target_group: String = "player"
@export var show_distance: float = 10.0
@onready var bar: ProgressBar = $SubViewport/Control/ProgressBar

# Keeps billboard facing camera when parented under the enemy.
func _process(_delta):
	if resources:
		bar.max_value = resources.max_health
		bar.value = resources.health
	
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
