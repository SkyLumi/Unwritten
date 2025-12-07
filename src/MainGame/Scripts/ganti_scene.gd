extends Area3D

@export var next_scene: String = "res://src/MainGame/Stage2.tscn"

func _ready():
	connect("body_entered", _on_body_entered)

func _on_body_entered(body):
	if body.name == "player":  # pastiin nama node player itu "Player"
		call_deferred("_ganti_scene")
	 
func _ganti_scene():
	get_tree().change_scene_to_file(next_scene)
