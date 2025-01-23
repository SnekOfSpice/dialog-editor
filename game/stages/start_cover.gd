extends ColorRect


func _ready() -> void:
	visible = Parser.page_index == 0
	ParserEvents.read_new_line.connect(on_read_new_line)

func on_read_new_line(index:int):
	if index >= 0:
		get_tree().create_timer(1).timeout.connect(set.bind("visible", false))
