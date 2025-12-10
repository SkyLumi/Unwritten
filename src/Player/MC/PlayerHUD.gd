extends CanvasLayer
class_name PlayerHUD

@onready var health_bar: ProgressBar = $Control/VBoxContainer/HealthBar
@onready var stamina_bar: ProgressBar = $Control/VBoxContainer/StaminaBar
@onready var health_value: Label = $Control/VBoxContainer/HealthBar/Value
@onready var stamina_value: Label = $Control/VBoxContainer/StaminaBar/Value

var model # MCModel reference

func _ready():
	# Find model from Player
	var player = get_tree().get_first_node_in_group("player")
	if player:
		model = player.get_node_or_null("Model")
	
	if not model:
		push_warning("PlayerHUD: Could not find player Model node")

func _process(delta):
	if model and model.resources:
		var health_percent = (model.resources.health / model.resources.max_health) * 100.0
		var stamina_percent = (model.resources.stamina / model.resources.max_stamina) * 100.0
		
		health_bar.value = health_percent
		stamina_bar.value = stamina_percent
		
		# Update text labels
		health_value.text = str(int(model.resources.health)) + " / " + str(int(model.resources.max_health))
		stamina_value.text = str(int(model.resources.stamina)) + " / " + str(int(model.resources.max_stamina))
