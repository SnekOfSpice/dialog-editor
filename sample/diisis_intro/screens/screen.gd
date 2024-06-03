extends Control
class_name Screen


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if GameWorld.game_stage:
		GameWorld.game_stage.hide_ui()
	tree_exiting.connect(restore_ui)

func restore_ui():
	if GameWorld.game_stage:
		GameWorld.game_stage.show_ui()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		GameWorld.stage_root.set_screen("")
		
