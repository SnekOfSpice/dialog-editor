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
	
	update()
	

func add_choice(choice_data:={}):
	var choice = preload("res://addons/diisis/editor/src/choice_edit.tscn").instantiate()
	$ChoiceList.add_child(choice)
	choice.init()
	choice.deserialize(choice_data)
	choice.connect("move_choice_edit", request_move_choice_edit)
	#if find_child("JumpPageButton").button_pressed: # override
		#choice.set_do_jump_page(true)
		#choice.set_jump_page_toggle_visible(false)
	update()

func request_add_choice():
	var undo_redo = Pages.editor.undo_redo
	var address := DiisisEditorUtil.get_address(self, DiisisEditorUtil.AddressDepth.Line)
	var item_address := str(address, ".", get_choice_item_count())
	undo_redo.create_action("Add Choice")
	undo_redo.add_do_method(DiisisEditorActions.add_choice_item.bind(address))
	undo_redo.add_undo_method(DiisisEditorActions.delete_choice_item.bind(item_address))
	undo_redo.commit_action()

func request_move_choice_edit(choice_edit: ChoiceEdit, direction:int):
	var undo_redo = Pages.editor.undo_redo
	var address = DiisisEditorUtil.get_address(choice_edit, DiisisEditorUtil.AddressDepth.ChoiceItem)
	var switched_item : ChoiceEdit = find_child("ChoiceList").get_child(choice_edit.get_index() + direction)
	var switched_address:=DiisisEditorUtil.get_address(switched_item, DiisisEditorUtil.AddressDepth.ChoiceItem)
	undo_redo.create_action("Move Choice Item")
	undo_redo.add_do_method(DiisisEditorActions.move_choice_item.bind(address, direction))
	undo_redo.add_undo_method(DiisisEditorActions.move_choice_item.bind(switched_address, -direction))
	undo_redo.commit_action()

func get_choice_item_count() -> int:
	return find_child("ChoiceList").get_child_count()

func move_choice_item_by_index(at_index:int, direction:int):
	var choice = $ChoiceList.get_child(at_index)
	$ChoiceList.move_child(choice, at_index + direction)
	update()

func update():
	for c : ChoiceEdit in $ChoiceList.get_children():
		c.update()

func get_item(at_index:int) -> ChoiceEdit:
	return find_child("ChoiceList").get_child(at_index)

func _on_add_button_pressed() -> void:
	request_add_choice()

func set_do_jump_page(do: bool):
	do_jump_page = do
	find_child("JumpPageButton").button_pressed = do_jump_page
	#for c in find_child("ChoiceList").get_children():
		#c.set_do_jump_page(find_child("JumpPageButton").button_pressed)
		#c.set_jump_page_toggle_visible(not do_jump_page)

func _on_jump_page_button_pressed() -> void:
	set_do_jump_page(find_child("JumpPageButton").button_pressed)

func set_auto_switch(value: bool):
	for c in $ChoiceList.get_children():
		c.set_text_lines_visible(not value)

func _on_auto_switch_button_pressed() -> void:
	set_auto_switch(find_child("AutoSwitchButton").button_pressed)
