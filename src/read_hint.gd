@tool
extends Window


func build(hint: String):
	find_child("TextLabel").text = hint

func _on_close_requested() -> void:
	hide()
