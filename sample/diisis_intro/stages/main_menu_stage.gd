extends Control

signal start_game()
signal load_game()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	find_child("QuitButton").visible = not OS.has_feature("web")


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
