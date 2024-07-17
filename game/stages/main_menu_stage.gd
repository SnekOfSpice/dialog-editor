extends Control

signal start_game()
signal load_game()

func _ready() -> void:
	Sound.play_bgm(CONST.MUSIC_MAIN_MENU)
	find_child("QuitButton").visible = not OS.has_feature("web")
	find_child("LoadButton").visible = Options.does_savegame_exist()

func _gui_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		GameWorld.stage_root.set_screen(CONST.SCREEN_OPTIONS)

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
