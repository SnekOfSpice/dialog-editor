extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Parser.reset_and_start(0)
	
	ParserEvents.text_content_filled.connect(on_text_content_filled)
	ParserEvents.text_content_visible_characters_changed.connect(on_text_content_visible_characters_changed)
	ParserEvents.text_content_visible_ratio_changed.connect(on_text_content_visible_ratio_changed)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			$LineReader.request_advance()

func on_text_content_filled():
	print("filled")

func on_text_content_visible_characters_changed(a):
	prints("char", a)
func on_text_content_visible_ratio_changed(a):
	prints("ratio", a)

func _on_interrupt_button_pressed() -> void:
	$LineReader.interrupt()


func _on_continue_button_pressed() -> void:
	$LineReader.continue_after_interrupt()
