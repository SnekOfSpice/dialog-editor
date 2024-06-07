extends Screen


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super()
	find_child("HistoryLabel").text = Parser.build_history_string()

func _input(event: InputEvent) -> void:
	super(event)

func _on_close_button_pressed() -> void:
	close()
