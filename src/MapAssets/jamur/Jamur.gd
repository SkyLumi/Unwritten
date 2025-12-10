extends Area3D

@export var bounce_force: float = 18.0

func _ready():
	# Connect the body_entered signal
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D):
	# Check if the body is the player group or name
	if body.is_in_group("player"):
		# Try to find the MCModel
		var model = body.get_node_or_null("Model")
		if model and model.has_method("bounce"):
			model.bounce(bounce_force)
			_play_bounce_animation()

func _play_bounce_animation():
	# Optional: Add scale bounce effect on the mushroom itself
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector3(1.2, 0.8, 1.2), 0.1)
	tween.tween_property(self, "scale", Vector3(1.0, 1.0, 1.0), 0.1)
