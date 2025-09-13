extends Screen

@warning_ignore("integer_division")
@onready var index : int = Parser.history.size() / 100
@onready var max_index := index

func _ready() -> void:
	super()
	update_label()
	find_child("ForwardButton").disabled = true
	if index == 0:
		find_child("BackButton").disabled = true

func _input(event: InputEvent) -> void:
	super(event)
	if event.is_action_pressed("history"):
		close()

func _on_close_button_pressed() -> void:
	close()

func update_label():
	find_child("HistoryLabel").text = Parser.build_history_string("\n", index * 100, index * 100 + 99)
	find_child("EntryLabel").text = str("Entries: ", index * 100, "-", index * 100 + 99)

func _on_forward_button_pressed() -> void:
	index += 1
	if index > 0:
		find_child("BackButton").disabled = false
	if index >= max_index:
		find_child("ForwardButton").disabled = true
	update_label()


func _on_back_button_pressed() -> void:
	index -= 1
	if index <= 0:
		find_child("BackButton").disabled = true
	if index < max_index:
		find_child("ForwardButton").disabled = false
	update_label()
