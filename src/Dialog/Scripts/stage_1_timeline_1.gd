extends Area3D

@export var dialog_path : String = "res://src/Dialog/stage1-timeline1.dtl"

func _ready():
	connect("body_entered", _on_body_entered)

func _on_body_entered(body):
	if body.name == "player":
		print("player masuk")
		call_deferred("_start_dialog")

func _start_dialog():
	var dialog = Dialogic.start(dialog_path)
	get_tree().current_scene.add_child(dialog)
	queue_free()
