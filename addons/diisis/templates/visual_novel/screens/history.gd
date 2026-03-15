extends Screen

@warning_ignore("integer_division")
@onready var index : int = Parser.history.size() / 100
@onready var max_index := index

func _ready() -> void:
	super()
	update_labels()
	%ForwardButton.disabled = true
	if index == 0:
		%BackButton.disabled = true

func _input(event: InputEvent) -> void:
	super(event)
	if event.is_action_pressed("history"):
		close()


func update_labels():
	%HistoryLabel.text = Parser.build_history_string("\n", index * 100, index * 100 + 99)
	%EntryLabel.text = str("Entries: ", index * 100, "-", index * 100 + 99)

func _on_forward_button_pressed() -> void:
	index += 1
	if index > 0:
		%BackButton.disabled = false
	if index >= max_index:
		%ForwardButton.disabled = true
	update_labels()


func _on_back_button_pressed() -> void:
	index -= 1
	if index <= 0:
		%BackButton.disabled = true
	if index < max_index:
		%ForwardButton.disabled = false
	update_labels()
