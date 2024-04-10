@tool
extends MarginContainer
class_name Facts

## Override this to hide the built-in visibility toggle button.
@export var visibility_toggle_button:Button
@export_enum("Page", "Line", "Choice Item") var address_depth := 0

func init():
	if visibility_toggle_button:
		find_child("VisibilityToggleButton").visible = false
		if not visibility_toggle_button.pressed.is_connected(toggle_visibility):
			visibility_toggle_button.connect("pressed", toggle_visibility)
		set_visibility(visibility_toggle_button.button_pressed)
	else:
		if not find_child("VisibilityToggleButton").pressed.is_connected(toggle_visibility):
			find_child("VisibilityToggleButton").connect("pressed", toggle_visibility)
		#find_child("VisibilityToggleButton").button_pressed = find_child("Controls").visible
		set_visibility(find_child("VisibilityToggleButton").button_pressed)

func set_visibility(value:bool):
	if visibility_toggle_button:
		#visibility_toggle_button.button_pressed = value
		visible = value
	else:
		find_child("Controls").visible = value
		find_child("FactsContainer").visible = value
		#find_child("VisibilityToggleButton").button_pressed = value

func toggle_visibility():
	if visibility_toggle_button:
		set_visibility(not visible)
	else:
		set_visibility(not find_child("Controls").visible)

func serialize() -> Dictionary:
	var result := {}
	var facts := {}
	for fact in find_child("FactsContainer").get_children():
		facts[fact.get_fact_name()] = fact.get_fact_value()
	result["values"] = facts
	if visibility_toggle_button:
		result["meta.visible"] = visible
	else:
		result["meta.visible"] = find_child("Controls").visible
	return result

func deserialize(data: Dictionary):
	for fact_name in data.get("values", {}).keys():
		add_fact(fact_name, data.get("values", {}).get(fact_name))
	set_visibility(data.get("meta.visible", false))
	if visibility_toggle_button:
		visibility_toggle_button.button_pressed = data.get("meta.visible", false)
	else:
		find_child("VisibilityToggleButton").button_pressed = data.get("meta.visible", false)

func add_fact(fact_name: String, fact_value: bool):
	var f = preload("res://addons/diisis/editor/src/fact_item.tscn").instantiate()
	find_child("FactsContainer").add_child(f)
	f.set_fact(fact_name, fact_value)
	f.request_delete_fact.connect(request_delete_fact)

func request_delete_fact(fact_name:String):
	var address := get_address_suffixed()
	var undo_redo = Pages.editor.undo_redo
	var fact_value:bool
	for c : FactItem in find_child("FactsContainer").get_children():
		if c.get_fact_name() == fact_name:
			fact_value = c.get_fact_value()
			break
	undo_redo.create_action("Delete Fact")
	undo_redo.add_do_method(DiisisEditorActions.delete_fact_local.bind(address, address_depth, fact_name))
	undo_redo.add_undo_method(DiisisEditorActions.add_fact.bind(address, address_depth, fact_name, fact_value))
	undo_redo.commit_action()

func delete_fact(fact_name:String):
	for c : FactItem in find_child("FactsContainer").get_children():
		if c.get_fact_name() == fact_name:
			c.queue_free()
			return

func get_address_suffixed() -> String:
	var address := ""
	
	if address_depth == DiisisEditorActions.AddressDepths.Page:
		address = str(get_parent().get("number"))
	elif address_depth == DiisisEditorActions.AddressDepths.Line:
		var parent_line = get_parent()
		while not parent_line is Line:
			parent_line = parent_line.get_parent()
		var parent_page = parent_line.get_parent()
		while not parent_page is Page:
			parent_page = parent_page.get_parent()
		address = str(parent_page.get("number"), ".", parent_line.get_index())
	elif address_depth == DiisisEditorActions.AddressDepths.ChoiceItem:
		var parent_choice = get_parent()
		while not parent_choice is ChoiceEdit:
			parent_choice = parent_choice.get_parent()
		var parent_line = parent_choice.get_parent()
		while not parent_line is Line:
			parent_line = parent_line.get_parent()
		var parent_page = parent_line.get_parent()
		while not parent_page is Page:
			parent_page = parent_page.get_parent()
		address = str(parent_page.get("number"), ".", parent_line.get_index(), ".", parent_choice.get_index())
		
	
	if self is Conditionals: # proxy for if conditional
		prints("added con at ", address)
		address += "c"
	else:
		prints("added f at ", address)
		address += "f"
	
	return address

func _on_add_fact_button_pressed() -> void:
	var fact_name = str("newfact", Pages.facts.keys().size())
	var address := get_address_suffixed()
	var undo_redo = Pages.editor.undo_redo
	undo_redo.create_action("Add Fact")
	undo_redo.add_do_method(DiisisEditorActions.add_fact.bind(address, address_depth, fact_name, true))
	undo_redo.add_undo_method(DiisisEditorActions.delete_fact_local.bind(address, address_depth, fact_name))
	undo_redo.commit_action()
