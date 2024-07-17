extends Camera2D


@export var strength := 20.0
@export var fade = 5.0

var rng = RandomNumberGenerator.new()

var shake_strength := 0.0

func _ready() -> void:
	GameWorld.camera = self

func _process(delta: float) -> void:
	if shake_strength > 0:
		shake_strength = lerpf(shake_strength, 0, fade * delta)
		
		offset = get_random_offset()

func apply_shake():
	shake_strength = strength

func get_random_offset() -> Vector2:
	return Vector2(randf_range(-shake_strength, shake_strength), randf_range(-shake_strength, shake_strength))
