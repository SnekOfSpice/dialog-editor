extends Control
class_name MainMenu

const PATH := "res://game/stages/main_menu_stage.tscn"

## Music key (same as instructions in DIISIS) to be played on [method _ready] Doesn't play anything if empty.
@export var menu_music := ""
@export var start_fade_time := 0.1


func _ready() -> void:
	Game.hook_up_button_sfx(self)
	set_save_slot(Options.save_slot)
	%QuitButton.visible = not OS.has_feature("web")
	Sound.switch_to("main_menu")
	update_load_button()
	
	if %LoadButton.visible:
		%LoadButton.grab_focus()
	else:
		%StartButton.grab_focus()
	
	EventBus.screen_changed.connect(func(_old_screen :String, new_screen : String):
		if new_screen.is_empty():
			if %LoadButton.visible:
				%LoadButton.grab_focus()
			else:
				%StartButton.grab_focus()
			show()
		)
	
	if Sound.player.volume_linear < 1:
		Sound.set_music_volume_linear(1, 4)
	
	
	EventBus.save_slot_set.connect(set_save_slot)
	%SaveContainer.visible = Options.has_savedata(0)
	if %SaveContainer.visible:
		%StartButton.focus_neighbor_bottom = %SaveSlotButton.get_path()
		%AuxButtons.get_child(0).focus_neighbor_top = %SaveSlotButton.get_path()
	else:
		%StartButton.focus_neighbor_bottom = %AuxButtons.get_child(0).get_path()
		%AuxButtons.get_child(0).focus_neighbor_top = %StartButton.get_path()



func update_load_button():
	%LoadButton.visible = Options.has_savedata()	


func _gui_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if Game.get_node("ScreenContainer").get_child_count() == 0:
			Game.set_screen("")
		else:
			Game.set_screen(CONST.SCREEN_OPTIONS)


func set_save_slot(slot:int):
	%SaveSlotLabel.text = str("Save Slot: ", slot + 1)
	update_load_button()

func _on_quit_button_pressed() -> void:
	Options.save_prefs()
	get_tree().quit()


func _on_options_button_pressed() -> void:
	Game.set_screen(CONST.SCREEN_OPTIONS)


func _on_credits_button_pressed() -> void:
	Game.set_screen(CONST.SCREEN_CREDITS)


func _on_cw_button_pressed() -> void:
	Game.set_screen(CONST.SCREEN_CONTENT_WARNING)


func _on_save_slot_button_pressed() -> void:
	Game.set_screen(CONST.SCREEN_SAVE)


func start_new_game():
	EventBus.new_game_started.emit()
	Game.start_data = GameStartData.new()
	Game.start_data.game_start_callable = Parser.reset_and_start
	
	SceneLoader.request_background_loading(GameStage.PATH, true)


func _on_load_button_pressed() -> void:
	Game.start_data = GameStartData.new()
	Game.start_data.game_start_callable = Options.load_gamestate
	
	SceneLoader.request_background_loading(GameStage.PATH, true)
