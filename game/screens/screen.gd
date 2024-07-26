extends Control
class_name Screen

var ignore_event := true

func _ready() -> void:
	if GameWorld.game_stage:
		GameWorld.game_stage.hide_ui()
	tree_exiting.connect(restore_ui)
	
	mouse_filter = Control.MOUSE_FILTER_STOP
	gui_input.connect(handle_input)
	
	await get_tree().process_frame
	ignore_event = false

func handle_input(event: InputEvent):
	if event is InputEventMouseButton:
		if event.button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT]:
			close()

func restore_ui():
	if is_instance_valid(GameWorld.game_stage):
		GameWorld.game_stage.show_ui()

func close():
	GameWorld.stage_root.set_screen("")
	get_viewport().set_input_as_handled()

func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("ui_cancel"):
		close()
