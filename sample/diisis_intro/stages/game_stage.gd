extends Control



func _ready():
	ParserEvents.actor_name_changed.connect(on_actor_name_changed)
	ParserEvents.text_content_text_changed.connect(on_text_content_text_changed)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			$LineReader.request_advance()


func on_actor_name_changed(actor_name: String,
	is_name_container_visible: bool):
		pass
		# move to neutral position if not visible
		# move to actor if visible

func on_text_content_text_changed(
	old_text: String,
	new_text: String,
	lead_time: float,
):
	pass

func _on_line_reader_line_reader_ready():
	Parser.reset_and_start(0)
	print("start")

func _process(delta):
	$Icon.global_position = $Control/TextContainer/MarginContainer/VBoxContainer/Panel/RichTextLabel.global_position
