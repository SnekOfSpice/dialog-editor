extends Control
class_name Screen

var ignore_event := true

func _ready() -> void:
	if GameWorld.game_stage:
		GameWorld.game_stage.hide_ui()
	tree_exiting.connect(restore_ui)
	
	await get_tree().process_frame
	ignore_event = false

func restore_ui():
	if GameWorld.game_stage:
		GameWorld.game_stage.show_ui()

func close():
	GameWorld.stage_root.set_screen("")
	get_viewport().set_input_as_handled()

func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("ui_cancel"):
		close()
