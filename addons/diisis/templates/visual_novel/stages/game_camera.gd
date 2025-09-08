extends Camera2D
class_name GameCamera

@export var fade = 5.0
@export var move_cg_with_camera := false
@onready var cg_bottom_container : Control = find_child("CGBottomContainer")

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


func deserialize(data:Dictionary):
	zoom = GameWorld.str_to_vec2(data.get("zoom", zoom))
	position = GameWorld.str_to_vec2(data.get("position", position))
	flat_offset = GameWorld.str_to_vec2(data.get("flat_offset", flat_offset))
	

	
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
	
	if move_cg_with_camera:
		for child : CGTexture in cg_bottom_container.get_children():
			child.set_texture_offset(offset)
	sway_intensity_lerp_strength = lerp(sway_intensity_lerp_strength, 0.02, 0.03)
	
	if GameWorld.game_stage:
		# For shaking CGs like in No Empty Threats, put offset here
		# but that also requires all CG assets to have extra margins and stuff
		# and we're not doing that as the base case
		GameWorld.game_stage.set_cg_offset(Vector2.ZERO)

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
