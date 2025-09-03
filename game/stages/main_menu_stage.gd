extends Stage

## Music key (same as instructions in DIISIS) to be played on [method _ready] Doesn't play anything if empty.
@export var menu_music := ""
@export var start_fade_time := 0.1

@warning_ignore("unused_signal")
signal start_game()
@warning_ignore("unused_signal")
signal load_game()
@warning_ignore("unused_signal")
signal start_epilogue()

func _ready() -> void:
	set_save_slot(Options.save_slot)
	find_child("BlackLayer").visible = false
	if not menu_music.is_empty():
		Sound.play_bgm(menu_music)
	find_child("QuitButton").visible = not OS.has_feature("web")
	
	update_load_button()
	#if GameWorld.just_started:
		#GameWorld.just_started = false
		#find_child("SoundCheckOverlay").visible = not Options.has_savedata(0)
	
	find_child("SaveContainer").visible = Options.has_savedata(0)
	
	find_child("EpilogueButton").pressed.connect(emit_signal.bind("start_epilogue"))
	#if Options.just_finished_game:
		#Options.just_finished_game = false
		#if not Options.unlocked_epilogue:
			#Options.unlocked_epilogue = true
			#find_child("UnlockedEpilogueOverlay").visible = Options.unlocked_epilogue
			#Options.save_prefs()
	
	#find_child("EpilogueButton").visible = Options.unlocked_epilogue or OS.has_feature("editor")


func update_load_button():
	find_child("LoadButton").visible = Options.has_savedata()
	find_child("LoadButton").text = str("Load (", int(Parser.get_game_progress(Options.get_savedata_dir_name()) * 100), "%)")
	

func _gui_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if GameWorld.stage_root.get_node("ScreenContainer").get_child_count() == 0:
			GameWorld.stage_root.set_screen("")
		else:
			GameWorld.stage_root.set_screen(CONST.SCREEN_OPTIONS)

func set_save_slot(slot:int):
	find_child("SaveSlotLabel").text = str("Save Slot: ", slot + 1)
	update_load_button()

func _on_quit_button_pressed() -> void:
	Options.save_prefs()
	get_tree().quit()


func _on_options_button_pressed() -> void:
	GameWorld.stage_root.set_screen(CONST.SCREEN_OPTIONS)


func _on_credits_button_pressed() -> void:
	GameWorld.stage_root.set_screen(CONST.SCREEN_CREDITS)


func _on_cw_button_pressed() -> void:
	GameWorld.stage_root.set_screen(CONST.SCREEN_CONTENT_WARNING)







func _on_save_slot_button_pressed() -> void:
	GameWorld.stage_root.set_screen(CONST.SCREEN_SAVE)


func _on_unlocked_epilogue_button_pressed() -> void:
	find_child("UnlockedEpilogueOverlay").visible = false


func _on_start_button_pressed() -> void:
	var black : ColorRect = find_child("Black")
	find_child("BlackLayer").visible = true
	var t = create_tween()
	black.modulate.a = 0
	t.tween_property(black, "modulate:a", 1, start_fade_time)
	
	t.finished.connect(emit_signal.bind("start_game"))


func _on_load_button_pressed() -> void:
	var black : ColorRect = find_child("Black")
	find_child("BlackLayer").visible = true
	var t = create_tween()
	black.modulate.a = 0
	t.tween_property(black, "modulate:a", 1, start_fade_time)
	t.finished.connect(emit_signal.bind("load_game"))


func get_screen_container() -> Control:
	return find_child("ScreenContainer")
