extends Control
class_name Screen


signal closing()

var screen_on_close := ""

func _ready() -> void:
	if is_instance_valid(Game.game_stage):
		Game.game_stage.hide_ui()
	tree_exiting.connect(restore_ui)
	
	mouse_filter = Control.MOUSE_FILTER_STOP
	gui_input.connect(handle_input)

func handle_input(_event: InputEvent):
	pass

func restore_ui():
	if is_instance_valid(Game.game_stage):
		Game.game_stage.show_ui()

func close():
	closing.emit()
	Game.set_screen(screen_on_close)
	get_viewport().set_input_as_handled()

func _input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("ui_cancel"):
		close()
