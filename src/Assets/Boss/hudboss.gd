extends CanvasLayer

@onready var health_bar = $Control/ProgressBar
@onready var damage_bar = $Control/DamageBar 
@onready var label_name = $Control/Label
# Ambil referensi ke Label angka yang baru dibuat
@onready var label_value = $Control/ProgressBar/Value

func _ready():
	visible = false

func setup_boss(boss_node):
	boss_node.health_changed.connect(_on_boss_health_changed)
	boss_node.boss_died.connect(_on_boss_died)
	
	label_name.text = "SINGA ULUNG"
	
	health_bar.max_value = boss_node.max_health
	health_bar.value = boss_node.max_health
	damage_bar.max_value = boss_node.max_health
	damage_bar.value = boss_node.max_health
	
	label_value.text = str(boss_node.max_health) + " / " + str(boss_node.max_health)
	
	visible = true

func _on_boss_health_changed(current, max_hp):
	health_bar.value = current
	
	label_value.text = str(max(current, 0)) + " / " + str(max_hp)
	
	var tween = create_tween()
	tween.tween_property(damage_bar, "value", current, 0.5).set_delay(0.2)

func _on_boss_died():
	label_value.text = "0 / " + str(damage_bar.max_value)
	
	var tween = create_tween()
	tween.tween_property($Control, "modulate:a", 0.0, 1.0)
	await tween.finished
	queue_free()
