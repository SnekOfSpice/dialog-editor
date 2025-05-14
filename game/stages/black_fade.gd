extends ColorRect

var hide_characters_on_full_black_reached := false
var new_background_on_full_black_reached := ""
var release_on_full_black_reached := 1.0
var sustain_on_full_black_reached := 1.0
var new_bgm_on_full_black_reached := ""

signal request_background_change(background_name: String)

func _ready() -> void:
	modulate.a = 0.0
	visible = true

func fade_in(duration: float):
	if duration == 0.0:
		modulate.a = 1.0
		on_full_black_reached()
		return
	var t = get_tree().create_tween()
	t.tween_property(self, "modulate:a", 1.0, duration)
	t.connect("finished", on_full_black_reached)

func fade_out(duration:= release_on_full_black_reached):
	if duration == 0.0:
		modulate.a = 0.0
		await get_tree().process_frame
		on_clear_reached()
		return
	var t = get_tree().create_tween()
	t.tween_property(self, "modulate:a", 0.0, duration)
	t.connect("finished", on_clear_reached)


func on_full_black_reached():
	if GameWorld.game_stage:
		GameWorld.game_stage.set_fade_out(0, 0)
		GameWorld.game_stage.hide_cg()
	if hide_characters_on_full_black_reached:
		for c in get_tree().get_nodes_in_group("character"):
			c.visible = false
	
	GameWorld.stage_root.set_background(new_background_on_full_black_reached)
	#emit_signal("request_background_change", new_background_on_full_black_reached)
	
	if not new_bgm_on_full_black_reached.is_empty():
		Sound.play_bgm(new_bgm_on_full_black_reached, release_on_full_black_reached)
		
	if sustain_on_full_black_reached > 0:
		var t = get_tree().create_timer(sustain_on_full_black_reached)
		t.connect("timeout", fade_out)
		return
	
	fade_out()
	

func on_clear_reached():
	Parser.inform_instruction_completed()


func _on_handler_start_black_fade(fade_in_duration, hold_time, fade_out_duration, hide_characters, new_background, new_bgm):
	if GameWorld.skip:
		fade_out_duration = 0.1
		hold_time = 0.1
		fade_in_duration = 0.1
	hide_characters_on_full_black_reached = hide_characters
	new_background_on_full_black_reached = new_background
	release_on_full_black_reached = fade_out_duration
	sustain_on_full_black_reached = hold_time
	new_bgm_on_full_black_reached = new_bgm
	fade_in(fade_in_duration)
