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


func _gui_input(event: InputEvent) -> void:#(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and not ignore_event:
		GameWorld.stage_root.set_screen("")
		
