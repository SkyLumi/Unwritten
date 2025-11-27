extends Resource
class_name HitData

var is_parryable : bool
var damage : float
var hit_move_animation : String

var weapon : Weapon
var effects : Dictionary = {}

static func blank() -> HitData:
	var h = HitData.new()
	h.effects = {}
	return h
