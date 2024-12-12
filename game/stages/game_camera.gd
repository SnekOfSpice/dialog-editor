extends Camera2D
class_name GameCamera

@export var fade = 5.0

var rng = RandomNumberGenerator.new()

var shake_strength := 0.0

var zoom_tween:Tween
var move_tween:Tween

var sway_intensity := 0.0
var sway_speed := 1.0
var sway_intensity_lerp_strength := 0.02

var screen_shake_hard := false

var flat_offset := Vector2.ZERO

func _ready() -> void:
	GameWorld.camera = self

func serialize() -> Dictionary:
	var result := {}
	
	result["sway_intensity"] = sway_intensity
	result["sway_intensity_lerp_strength"] = sway_intensity_lerp_strength
	result["position"] = position
	result["zoom"] = zoom
	result["flat_offset"] = flat_offset
	
	return result

func str_to_vec2(s:String) -> Vector2:
	s = s.replace("(", "")
	s = s.replace(")", "")
	
	var segments = s.split(",")
	
	return Vector2(float(segments[0]), float(segments[1]))

func deserialize(data:Dictionary):
	var z = data.get("zoom")
	if z is String:
		zoom = str_to_vec2(z)
	else:
		zoom = data.get("zoom", Vector2(zoom))
	
	
	var p = data.get("position")
	if p is String:
		position = str_to_vec2(p)
	else:
		position = data.get("position", position)
	
	var f = data.get("flat_offset")
	if f is String:
		flat_offset = str_to_vec2(f)
	else:
		flat_offset = data.get("flat_offset", flat_offset)
	
	sway_intensity_lerp_strength = data.get("sway_intensity_lerp_strength", sway_intensity_lerp_strength)
	sway_intensity = data.get("sway_intensity", sway_intensity)

func set_sway_intensity(value:float):
	sway_intensity = value

func _process(delta: float) -> void:
	if shake_strength > 0:
		shake_strength = lerpf(shake_strength, 0, fade * delta)
	
	var x:float
	if randf() < 0.5:
		x = asin(Time.get_ticks_msec() / 660.0) - 0.5
	else:
		x = acos(Time.get_ticks_msec() / 660.0) - 0.5
	var y:float
	if randf() < 0.5:
		y = sin(Time.get_ticks_msec() / 660.0) - 0.5
	else:
		y = cos(Time.get_ticks_msec() / 660.0) - 0.5
	
	offset = lerp(
		offset,
		get_random_offset() + Vector2(
			x * sway_intensity,
			y * sway_intensity),
		sway_intensity_lerp_strength) + flat_offset
	sway_intensity_lerp_strength = lerp(sway_intensity_lerp_strength, 0.02, 0.03)

func apply_shake(strength:float):
	shake_strength = strength
	sway_intensity_lerp_strength = 1.0

func get_random_offset() -> Vector2:
	return Vector2(randf_range(-shake_strength, shake_strength), randf_range(-shake_strength, shake_strength))

func get_screen_container() -> Control:
	return find_child("ScreenContainer")

func zoom_to(value:float, duration:float):
	if zoom_tween:
		zoom_tween.kill()
	zoom_tween = create_tween()
	zoom_tween.tween_property(self, "zoom", Vector2(value, value), duration).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)

func move_to(x:float, y:float, duration:float):
	if move_tween:
		move_tween.kill()
	move_tween = create_tween()
	move_tween.tween_property(self, "flat_offset", Vector2(x, y), duration).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
