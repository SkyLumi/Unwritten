extends Node
class_name PlayerModel

@export var is_enemy : bool = false
@export var base_health : float = 100
@export var base_stamina : float = 100

var jump_count = 0
const MAX_JUMPS = 2


@onready var player = $".."
@onready var skeleton = %GeneralSkeleton
@onready var animator = $SplitBodyAnimator
@onready var combat = $Combat as HumanoidCombat
@onready var resources = $Resources as HumanoidResources
@onready var hurtbox = $Root/Hitbox as Hurtbox
@onready var legs = $Legs as Legs
@onready var area_awareness = $AreaAwareness as AreaAwareness

@onready var active_weapon : Weapon = $RightWrist/WeaponSocket/Sword as Sword
#@onready var weapons = {
	#"sword" = $....Sword,
	#"bow" = $....Bow,
	#"greatsword" = $....Greatsword,
	#....
#}

@onready var current_move : Move
@onready var moves_container = $States as HumanoidStates


func _ready():
	print("=== Model._ready() START ===")
	_configure_factions_and_hits()
	_apply_base_resources()
	moves_container.player = player
	moves_container.model = self
	print("Player assigned to moves_container")
	
	moves_container.accept_moves()
	print("Moves accepted, available moves: ", moves_container.moves.keys())
	
	# Always start in midair - will transition to idle/walk when landing
	if "midair" in moves_container.moves:
		current_move = moves_container.moves["midair"]
		print("Starting in MIDAIR state")
		switch_to("midair")
	else:
		print("ERROR: 'midair' state not found! Available: ", moves_container.moves.keys())
		current_move = moves_container.moves["idle"]
		switch_to("idle")
	
	legs.current_legs_move = moves_container.get_move_by_name("idle")
	legs.accept_behaviours()
	print("=== Model._ready() COMPLETE ===")


func update(input : InputPackage, delta : float):
	input = combat.contextualize(input)
	area_awareness.last_input_package = input
	var relevance = current_move.check_relevance(input)
	if relevance != "okay":
		switch_to(relevance)
	#print(animator.torso_animator.current_animation)
	current_move.update_resources(delta) # moved back here for now, because of TorsoMoves triggering _update from legs behaviour -> doubledipping
	current_move._update(input, delta)


func switch_to(state : String):
	print(current_move.move_name + " -> " + state)
	current_move._on_exit_state()
	current_move = moves_container.moves[state]
	current_move._on_enter_state()

func reset_jump_count():
	jump_count = 0


func _configure_factions_and_hits():
	var own_weapon_group = "player_weapon"
	if is_enemy:
		own_weapon_group = "enemy_weapon"

	# Make sure weapon carries only its faction group.
	if active_weapon:
		active_weapon.remove_from_group("player_weapon")
		active_weapon.remove_from_group("enemy_weapon")
		active_weapon.add_to_group(own_weapon_group)

	# Hurtbox should ignore only self weapons (to avoid self-hit), not opponent.
	if hurtbox:
		var ignore_groups : Array[String] = []
		ignore_groups.append(own_weapon_group)
		hurtbox.ignored_weapon_groups = ignore_groups


func _apply_base_resources():
	if resources:
		resources.max_health = base_health
		resources.health = base_health
		resources.max_stamina = base_stamina
		resources.stamina = base_stamina
