extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Parser.reset_and_start(0)
	#DialogLogger.start_new_log()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			$LineReader.request_advance()


func _on_interrupt_button_pressed() -> void:
	$LineReader.interrupt()


func _on_continue_button_pressed() -> void:
	$LineReader.continue_after_interrupt()
