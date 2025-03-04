extends Control

## Music key (same as instructions in DIISIS) to be played on [method _ready] Doesn't play anything if empty.
@export var menu_music := ""

signal start_game()
signal load_game()
signal start_epilogue()

func _ready() -> void:
	if not menu_music.is_empty():
		Sound.play_bgm(menu_music)
	find_child("QuitButton").visible = not OS.has_feature("web")
	
	update_load_button()
	#if GameWorld.just_started:
		#GameWorld.just_started = false
		#find_child("SoundCheckOverlay").visible = not Options.has_savedata(0)
	
	find_child("SaveContainer").visible = Options.has_savedata(0)
	
	#if Options.just_finished_game:
		#Options.just_finished_game = false
		#if not Options.unlocked_epilogue:
			#Options.unlocked_epilogue = true
			#find_child("UnlockedEpilogueOverlay").visible = Options.unlocked_epilogue
			#Options.save_prefs()
	
	#find_child("EpilogueButton").visible = Options.unlocked_epilogue or OS.has_feature("editor")

func update_load_button():
	find_child("LoadButton").visible = Options.has_savedata()
	find_child("LoadButton").text = str("Load (", int(Parser.get_game_progress_from_file(Options.get_savedata_path()) * 100), "%)")
	

func _gui_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if GameWorld.stage_root.get_node("ScreenContainer").get_child_count() == 0:
			GameWorld.stage_root.set_screen("")
		else:
			GameWorld.stage_root.set_screen(CONST.SCREEN_OPTIONS)

func set_save_slot(slot:int):
	find_child("SaveSlotLabel").text = str("Current Save Slot: ", slot + 1)
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


func _on_discord_button_pressed() -> void:
	OS.shell_open("https://discord.gg/jPU4RvmTvP")


func _on_git_hub_button_pressed() -> void:
	OS.shell_open("https://github.com/SnekOfSpice/dialog-editor")


func _on_sound_check_button_pressed() -> void:
	find_child("SoundCheckOverlay").visible = false


func _on_save_slot_button_pressed() -> void:
	GameWorld.stage_root.set_screen(CONST.SCREEN_SAVE)


func _on_unlocked_epilogue_button_pressed() -> void:
	find_child("UnlockedEpilogueOverlay").visible = false
