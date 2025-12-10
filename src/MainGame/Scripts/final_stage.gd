extends Node3D

@onready var boss = $NavigationRegion3D/singahehe
@onready var boss_hud = $hudboss

func _ready():
	# Sambungkan Boss ke UI
	if boss and boss_hud:
		boss_hud.setup_boss(boss)
