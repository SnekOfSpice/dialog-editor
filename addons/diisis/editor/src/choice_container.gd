@tool
extends VBoxContainer

var do_jump_page := true

func serialize() -> Dictionary:
	var result = {}
	
	var choices = []
	for c in $ChoiceList.get_children():
		choices.append(c.serialize())
	result["choices"] = choices
	result["auto_switch"] = find_child("AutoSwitchButton").button_pressed
	
	result["meta.do_jump_page"] = do_jump_page
	
	return result

func deserialize(data):
	for c in $ChoiceList.get_children():
		c.queue_free()
	
	var choices
	if data is Array: # backwards compat
		choices = data
	else:
		choices = data.get("choices", [])
		set_do_jump_page(data.get("meta.do_jump_page"))
	
	for d in choices:
		add_choice(d)
	
	find_child("AutoSwitchButton").button_pressed = data.get("auto_switch", false)
	set_auto_switch(find_child("AutoSwitchButton").button_pressed)
	

func add_choice(choice_data:={
		"choice_text": "choice label",
		"target_page": 0,}
	):
	var choice = preload("res://addons/diisis/editor/src/choice_edit.tscn").instantiate()
	$ChoiceList.add_child(choice)
	choice.init()
	choice.deserialize(choice_data)

func _on_add_button_pressed() -> void:
	add_choice()

func set_do_jump_page(do: bool):
	do_jump_page = do
	find_child("JumpPageButton").button_pressed = do_jump_page
	for c in find_child("ChoiceList").get_children():
		c.set_do_jump_page(find_child("JumpPageButton").button_pressed)

func _on_jump_page_button_pressed() -> void:
	set_do_jump_page(find_child("JumpPageButton").button_pressed)

func set_auto_switch(value: bool):
	for c in $ChoiceList.get_children():
		c.set_text_lines_visible(not value)

func _on_auto_switch_button_pressed() -> void:
	set_auto_switch(find_child("AutoSwitchButton").button_pressed)
