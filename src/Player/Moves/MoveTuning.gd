extends Resource
class_name MoveTuning

# Centralized tuning values for move scripts. Override these in the inspector
# to tweak movement without digging through individual scripts.

@export_category("Run")
@export var run_speed: float = 3.0
@export var run_turn_speed: float = 2.0

@export_category("Walk")
@export var walk_speed: float = 2.0
@export var walk_turn_speed: float = 5.0

@export_category("Sprint")
@export var sprint_speed: float = 3.0
@export var sprint_turn_speed: float = 3.2
@export var sprint_stamina_cost_per_second: float = 20.0

@export_category("Jump")
@export var jump_transition_timing: float = 0.44
@export var jump_impulse_delay: float = 0.1
@export var jump_run_speed: float = 1.0
@export var jump_run_vertical_boost: float = 1.2
@export var jump_idle_vertical_boost: float = 1.5
@export var jump_sprint_speed: float = 2.0
@export var jump_sprint_vertical_boost: float = 1.5
@export var jump_sprint_transition_timing: float = 0.4
@export var jump_sprint_impulse_delay: float = 0.0657

@export_category("Midair")
@export var midair_delta_vector_length: float = 6.0
@export var midair_jump_speed: float = 2.0
@export var midair_second_jump_multiplier: float = 2.2
@export var midair_landing_height: float = 1.163
