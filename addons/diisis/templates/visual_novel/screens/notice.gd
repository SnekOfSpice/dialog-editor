class_name NoticeScreen
extends Screen

@export var default_title := ""

func _ready() -> void:
	super()

func _input(event: InputEvent) -> void:
	super(event)

## payload contains keys "title": String, "text": String, "allow_quit":bool. All are optional.
func handle_payload(payload:Dictionary):
	var title : String = payload.get("title", default_title)
	find_child("Title").visible = not title.is_empty()
	find_child("Title").text = title
	find_child("RichTextLabel").text = payload.get("text", "Notice.")
	find_child("QuitContainer").visible = payload.get("allow_quit", false)
	

func _on_button_pressed() -> void:
	close()


func _on_quit_button_pressed() -> void:
	if GameWorld.stage_root.stage == CONST.STAGE_GAME:
		Options.save_gamestate()
	Options.save_prefs()
	get_tree().quit()
