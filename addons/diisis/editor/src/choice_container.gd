@tool
extends Control

var do_jump_page := true

func init():
	find_child("AddButton").grab_focus()

func serialize() -> Dictionary:
	var result = {}
	
	var choices = []
	for c : ChoiceEdit in $ChoiceList.get_children():
		choices.append(c.serialize())
	result["choices"] = choices
	result["auto_switch"] = find_child("AutoSwitchButton").button_pressed
	result["meta.do_jump_page"] = do_jump_page
	result["choice_title"] = find_child("ChoiceTitleLineEdit").text
	
	return result

func deserialize(data):
	for c in $ChoiceList.get_children():
		c.queue_free()
	
	var choices
	if data is Array: # backwards compat
		choices = data
	else:
		choices = data.get("choices", [])
		#set_do_jump_page(data.get("meta.do_jump_page"))
	
	var auto_switch = data.get("auto_switch", false)
	find_child("AutoSwitchButton").button_pressed = auto_switch
	set_auto_switch(auto_switch)
	find_child("ChoiceTitleLineEdit").text = data.get("choice_title", "")
	
	for d in choices:
		d["auto_switch"] = auto_switch
		add_choice(-1, d)
	
	update()
	

func add_choice(at_index:=-1, choice_data:={}):
	var choice = preload("res://addons/diisis/editor/src/choice_edit.tscn").instantiate()
	$ChoiceList.add_child(choice)
	choice.init()
	if at_index != -1:
		$ChoiceList.move_child(choice, at_index)
	choice.deserialize(choice_data)
	choice.connect("move_choice_edit", request_move_choice_edit)
	choice.grab_focus()
	update()

func request_add_choice():
	var undo_redo = Pages.editor.undo_redo
	var address :String= DiisisEditorUtil.get_address(self, DiisisEditorUtil.AddressDepth.Line)
	var item_address := str(address, ".", get_choice_item_count())
	undo_redo.create_action("Add Choice")
	DiisisEditorActions.blank_override_choice_item_addresses.append(item_address)
	undo_redo.add_do_method(DiisisEditorActions.add_choice_item.bind(item_address))
	undo_redo.add_undo_method(DiisisEditorActions.delete_choice_item.bind(item_address))
	undo_redo.commit_action()

func request_move_choice_edit(choice_edit: ChoiceEdit, direction:int):
	var undo_redo = Pages.editor.undo_redo
	var address = DiisisEditorUtil.get_address(choice_edit, DiisisEditorUtil.AddressDepth.ChoiceItem)
	var switched_item : ChoiceEdit = find_child("ChoiceList").get_child(choice_edit.get_index() + direction)
	var switched_address :String= DiisisEditorUtil.get_address(switched_item, DiisisEditorUtil.AddressDepth.ChoiceItem)
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

func set_page_view(view:DiisisEditor.PageView):
	$Controls.visible = view != DiisisEditor.PageView.Minimal

func _on_add_button_pressed() -> void:
	request_add_choice()

#func set_do_jump_page(do: bool):
	#do_jump_page = do
	#find_child("JumpPageButton").button_pressed = do_jump_page

func set_auto_switch(value: bool):
	for c : ChoiceEdit in $ChoiceList.get_children():
		c.set_auto_switch(value)

func _on_auto_switch_button_pressed() -> void:
	set_auto_switch(find_child("AutoSwitchButton").button_pressed)

func set_all_items_selected(value:bool):
	for c : ChoiceEdit in find_child("ChoiceList").get_children():
		c.set_selected(value)

func _on_select_index_pressed(index: int) -> void:
	match index:
		1: # keep others selected
			set_all_items_selected(true)
		2: # drop other selections
			for container in get_tree().get_nodes_in_group("diisis_choice_container"):
				container.set_all_items_selected(false)
			set_all_items_selected(true)
		4: # drop all selections here
			set_all_items_selected(false)
		5: # drop all selections everywhere
			for container in get_tree().get_nodes_in_group("diisis_choice_container"):
				container.set_all_items_selected(false)
		6:
			for container in get_tree().get_nodes_in_group("diisis_choice_container"):
				if not container == self:
					container.set_all_items_selected(false)
