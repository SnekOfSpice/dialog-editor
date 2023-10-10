extends VBoxContainer


func serialize() -> Array:
	var result = []
	
	for c in $ChoiceList.get_children():
		result.append(c.serialize())
	
	return result

func deserialize(data: Array):
	for c in $ChoiceList.get_children():
		c.queue_free()
	
	for d in data:
		add_choice(d)

func add_choice(choice_data:={
		"choice_text": "choice label",
		"target_page": 0,}
	):
	var choice = preload("res://src/choice_edit.tscn").instantiate()
	$ChoiceList.add_child(choice)
	choice.deserialize(choice_data)

func _on_add_button_pressed() -> void:
	add_choice()
