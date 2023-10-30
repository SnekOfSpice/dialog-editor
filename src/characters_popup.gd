extends Window

func fill():
	var s = ""
	for c in Pages.characters:
		s += str(c)
		s += "\n"

func text2arr() -> Array:
	return $CodeEdit.text.split("\n")

func _on_about_to_popup() -> void:
	fill()

func _on_close_requested() -> void:
	Pages.characters = text2arr()
	hide()
