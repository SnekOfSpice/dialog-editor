@warning_ignore("missing_tool")
extends LineReader

signal start_black_fade(
	fade_in:float,
	hold_time:float,
	fade_out:float,
	hide_characters:bool,
	new_background:String,
	new_bgm:String)

signal start_show_cg(
	cg_name:String,
	fade_in:float,
	on_top:bool)

signal start_hide_cg(fade_out:float)
signal start_rolling_credits()
signal splatter(amount:int)
signal start_chapter_cover(pov_name:String, bottom_text, new_background, zoom, bgm)
signal request_object_visible(object_name:String, visibility:bool)

func play_sfx(_name:String):
	Sound.play_sfx(_name)
	return false

func set_bgm(_name:String, fade_in:float):
	Sound.play_bgm(_name, fade_in)
	return false

func set_text_style(style: String) -> bool:
	if style == "ToBottom":
		GameWorld.game_stage.set_text_style(GameStage.TextStyle.ToBottom)
	elif style == "ToCharacter":
		GameWorld.game_stage.set_text_style(GameStage.TextStyle.ToCharacter)
	return false

func black_fade(fade_in:float, hold_time:float, fade_out:float, hide_characters:bool, new_background:String, new_bgm:String):
	var bg = new_background
	if new_background == "none":
		bg = GameWorld.background
	
	var bgm = new_bgm
	if not bg:
		push_warning(str("COULDN'T FIND MUSIC ", new_bgm, "!"))
		bgm = "main_menu"
	if new_bgm == "none" or new_bgm == "null":
		bgm = Sound.bgm_key
	
	emit_signal("start_black_fade",
	fade_in,
	hold_time,
	fade_out,
	hide_characters,
	bg,
	bgm,
	)
	return true


func hide_all_characters() -> bool:
	for character: Character in get_tree().get_nodes_in_group("character"):
		character.visible = false
	return false


func show_cg(_name:String, fade_in_time:float, continue_dialog_through_cg:bool):
	emit_signal("start_show_cg",
	_name,
	fade_in_time,
	not continue_dialog_through_cg
	)
	return true

func hide_cg(fade_out:=2.0):
	emit_signal("start_hide_cg", fade_out)
	return false

func set_background(_name:String, fade_time:float):
	GameWorld.stage_root.set_background(
				_name,
				fade_time
			)
	return false


func play_chapter_intro(pov_name: String, bottom_text: String, new_background: String, zoom: float, bgm: = "One <3") -> bool:
	if bgm == "null":
		bgm = Sound.bgm_key
	emit_signal("start_chapter_cover", pov_name, bottom_text, new_background, zoom, bgm)
	return true


func zoom_to(value : float, duration : float) -> bool:
	GameWorld.camera.zoom_to(value, duration)
	return false

func splatter_blood(amount) -> bool:
	emit_signal("splatter", int(amount))
	return false

func set_emotion(actor_name: String, emotion_name: String) -> bool:
	for character : Character in get_tree().get_nodes_in_group("character"):
		if character.character_name == actor_name:
			character.set_emotion(emotion_name)
	return false

func show_character(character_name: String, clear_others: bool) -> bool:
	for character : Character in get_tree().get_nodes_in_group("character"):
		if character.character_name == character_name:
			character.visible = true
		elif clear_others:
			character.visible = false
	return false


func shake_camera(strength:float) -> bool:
	if GameWorld.camera:
		GameWorld.camera.apply_shake(strength)
	return false


func set_x_position(character_name: String, index:int, time:float, wait_for_reposition:bool) -> bool:
	if GameWorld.game_stage:
		var character : Character = GameWorld.game_stage.get_character(character_name)
		@warning_ignore("narrowing_conversion")
		character.set_x_position(int(index), time, wait_for_reposition)
	return wait_for_reposition

func sway_camera(intensity : float) -> bool:
	if GameWorld.camera:
		GameWorld.camera.set_sway_intensity(intensity)
	return false

func move_camera_to(x: float, y: float, duration: float) -> bool:
	if GameWorld.camera:
		GameWorld.camera.move_to(x, y, duration)
	return false

func wound_fx(shake_intensity: float, splatter_count: float) -> bool:
	shake_camera(shake_intensity)
	splatter_blood(splatter_count)
	play_sfx("squelch")
	return false

func control_camera(zoom : float, x : float, y : float, duration : float) -> bool:
	zoom_to(zoom, duration)
	move_camera_to(x, y, duration)
	return false

func roll_credits() -> bool:
	emit_signal("start_rolling_credits")
	return true

func set_character_name(character: String, new_name: String) -> bool:
	if Parser.line_reader:
		Parser.line_reader.set_actor_name(character, new_name)
	return false


func set_object_visible(object_name: String, visibility: bool) -> bool:
	emit_signal("request_object_visible", object_name, visibility)
	return false

func use_ui(id: float) -> bool:
	GameWorld.game_stage.use_ui(int(id))
	return false
