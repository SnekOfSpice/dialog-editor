@tool
extends PanelContainer
class_name Facts

## Override this to hide the built-in visibility toggle button.
@export var visibility_toggle_button:Button
@export_enum("Page", "Line", "Choice Item") var address_depth := 0

@export var facts_container:VBoxContainer

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
	
	update()

func set_visibility(value:bool):
	if visibility_toggle_button:
		#visibility_toggle_button.button_pressed = value
		visible = value
	else:
		find_child("Controls").visible = value
		facts_container.visible = value
		#find_child("VisibilityToggleButton").button_pressed = value

func toggle_visibility():
	if visibility_toggle_button:
		set_visibility(not visible)
	else:
		set_visibility(not find_child("Controls").visible)

func serialize() -> Dictionary:
	var result := {}
	var fact_data := {}
	for fact in find_child("FactsContainer").get_children():
		fact_data[fact.get_fact_name()] = fact.serialize()
	result["fact_data_by_name"] = fact_data
	if visibility_toggle_button:
		result["meta.visible"] = visible
	else:
		result["meta.visible"] = find_child("Controls").visible
	return result

func deserialize(data: Dictionary):
	for fact in facts_container.get_children():
		fact.queue_free()
	for fact in data.get("fact_data_by_name", {}).values():
		add_fact_from_serialized(fact)
	set_visibility(data.get("meta.visible", false))
	if visibility_toggle_button:
		visibility_toggle_button.button_pressed = data.get("meta.visible", false)
	else:
		find_child("VisibilityToggleButton").button_pressed = data.get("meta.visible", false)
	if find_child("PuppyLabel"):
		find_child("PuppyLabel").text = Pages.make_puppy() if Pages.silly else ""
	update()

func add_fact_from_serialized(fact_data:Dictionary):
	var f = preload("res://addons/diisis/editor/src/fact_item.tscn").instantiate()
	facts_container.add_child(f)
	f.init()
	f.deserialize(fact_data)
	f.request_delete_fact.connect(request_delete_fact)
	update()

func add_fact(fact_name: String, fact_value, conditional:=false):
	var f = preload("res://addons/diisis/editor/src/fact_item.tscn").instantiate()
	facts_container.add_child(f)
	var data := {
		"fact_name":fact_name,
		"fact_value":fact_value,
		"is_conditional":conditional,
	}
	f.init()
	f.deserialize(data)
	f.request_delete_fact.connect(request_delete_fact)
	update()

func update():
	await get_tree().process_frame
	var button_label := ""
	var child_count := facts_container.get_child_count()
	if visibility_toggle_button:
		visibility_toggle_button.text = str(button_label, " (", child_count, ")")
	else:
		find_child("VisibilityToggleButton").text = str(button_label, " (", child_count, ")")


func request_delete_fact(fact_name:String):
	var address := get_address_suffixed()
	var undo_redo = Pages.editor.undo_redo
	var fact_value:bool
	for c : FactItem in facts_container.get_children():
		if c.get_fact_name() == fact_name:
			fact_value = c.get_fact_value()
			break
	undo_redo.create_action("Delete Fact")
	undo_redo.add_do_method(DiisisEditorActions.delete_fact_local.bind(address, address_depth, fact_name))
	undo_redo.add_undo_method(DiisisEditorActions.add_fact.bind(address, address_depth, fact_name, fact_value))
	undo_redo.commit_action()

func delete_fact(fact_name:String):
	for c : FactItem in facts_container.get_children():
		if c.get_fact_name() == fact_name:
			c.queue_free()
			
			break
	await get_tree().process_frame
	update()

func get_address_suffixed() -> String:
	var address = DiisisEditorUtil.get_address(self, address_depth)
	
	if self is Conditionals:
		address += "c"
	else:
		address += "f"
	
	return address

func request_add_fact():
	var fact_name = ""
	var address := get_address_suffixed()
	var undo_redo = Pages.editor.undo_redo
	undo_redo.create_action("Add Fact")
	undo_redo.add_do_method(DiisisEditorActions.add_fact.bind(address, address_depth, fact_name, true))
	undo_redo.add_undo_method(DiisisEditorActions.delete_fact_local.bind(address, address_depth, fact_name))
	undo_redo.commit_action()
