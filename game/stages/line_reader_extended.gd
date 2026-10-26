@tool
extends LineReader

# Extend a script from LineReader to have diisis be able to make
# function calls to this node.
# NOTE: Only one LineReader can be active at any given time.

# CRITICAL: When you rename this script, remember to also edit the path
# saved in DIISIS > Setup > Functions & Variables

@export var camera : GameCamera
@export var credits : RollingCredits


#region setting up
func _ready():
	super()
	if Engine.is_editor_hint():
		return
	
	auto_continue = Options.auto_continue
	text_speed = Options.text_speed
	auto_continue_delay = Options.auto_continue_delay
	EventBus.settings_changed.connect(_on_settings_changed)
	_on_settings_changed()


func _on_settings_changed():
	text_speed = Options.text_speed
	auto_continue = Options.auto_continue
	auto_continue_delay = Options.auto_continue_delay
#endregion


#region controlling characters
func show_character(character_name: String, clear_others: bool) -> bool:
	for character : Character in get_tree().get_nodes_in_group("character"):
		if character.character_name == character_name:
			character.visible = true
		elif clear_others:
			character.visible = false
	return false


func hide_all_characters() -> bool:
	for character: Character in get_tree().get_nodes_in_group("character"):
		character.visible = false
	return false


func set_emotion(character_name: String, emotion_name: String) -> bool:
	for character : Character in get_tree().get_nodes_in_group("character"):
		if character.character_name == character_name:
			character.set_emotion(emotion_name)
	return false


func set_x_position(
	character_name: String,
	index:int,
	time:float,
	wait_for_reposition:bool) -> bool:
	var character : Character = Game.game_stage.get_character(character_name)
	@warning_ignore("narrowing_conversion")
	character.set_x_position(int(index), time, wait_for_reposition)
	return wait_for_reposition


func set_character_name(character: String, new_name: String) -> bool:
	set_actor_name(character, new_name)
	return false
#endregion


#region cgs
func hide_cg(fade_out := 0.0):
	Game.game_stage.hide_cg(fade_out)


func show_cg(cg_name: String, fade_in: float, continue_dialog_through_cg: bool) -> bool:
	if continue_dialog_through_cg:
		Game.game_stage.set_cg_bottom(cg_name, fade_in)
	else:
		Game.game_stage.emit_insutrction_complete_on_cg_hide = true
		Game.game_stage.set_cg_top(cg_name, fade_in)
	
	return not continue_dialog_through_cg
#endregion


#region hooking into the global audio system
func play_sfx(_name:String):
	Sound.play_sfx(_name)
	return false


func set_bgm(_name:String, fade_in:float):
	Sound.play_bgm(_name, fade_in)
	return false
#endregion


#region camera controls
func shake_camera(strength:float) -> bool:
	camera.apply_shake(strength)
	return false


func sway_camera(intensity : float) -> bool:
	camera.set_sway_intensity(intensity)
	return false


func move_camera_to(x: float, y: float, duration: float) -> bool:
	camera.move_to(x, y, duration)
	return false


func control_camera(zoom : float, x : float, y : float, duration : float) -> bool:
	zoom_to(zoom, duration)
	move_camera_to(x, y, duration)
	return false


func zoom_to(value : float, duration : float) -> bool:
	camera.zoom_to(value, duration)
	return false
#endregion


#region dramatics
func roll_credits() -> bool:
	credits.start()
	return true


func set_background(new_bg_key:String, fade_time:=0.0):
	return Game.game_stage.set_background(new_bg_key, fade_time)


func chapter_break(
	new_background : String,
	new_bgm : String,
	transition_time := 0.0
):
	Sound.switch_to(new_bgm)
	Game.game_stage.set_background(new_background, transition_time)
	
	var callback_timer := get_tree().create_timer(transition_time)
	callback_timer.timeout.connect(Parser.function_acceded)
	return true
#endregion
