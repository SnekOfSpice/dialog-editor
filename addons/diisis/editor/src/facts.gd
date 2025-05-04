@tool
extends PanelContainer
class_name Facts

## Override this to hide the built-in visibility toggle button.
@export var visibility_toggle_button:Button
@export_enum("Page", "Line", "Choice Item") var address_depth := 0

@export var facts_container:VBoxContainer

func init():
	var button := _get_visibility_toggle_button()
	if not button.pressed.is_connected(toggle_visibility):
		button.connect("pressed", toggle_visibility)
	button.add_theme_icon_override("checked", load("uid://3gqp3bocdpbm"))
	button.add_theme_icon_override("unchecked", load("uid://3gqp3bocdpbm"))
	set_visibility(button.button_pressed)
	
	if visibility_toggle_button:
		find_child("VisibilityToggleButton").visible = false
	
	if not gui_input.is_connected(_on_gui_input):
		gui_input.connect(_on_gui_input)
	
	_get_visibility_toggle_button().tooltip_text = "Toggle " + "conditionals" if self is Conditionals else "facts"
	_get_visibility_toggle_button().add_theme_font_override("font", load("uid://clp0ef7vbq100"))
	_get_visibility_toggle_button().add_theme_font_size_override("font_size", 20)
	_get_visibility_toggle_button().visible = Pages.show_facts_buttons
	visible = Pages.show_facts_buttons
	update()

func _get_visibility_toggle_button() -> CheckButton:
	if visibility_toggle_button:
		return visibility_toggle_button
	else:
		return find_child("VisibilityToggleButton")

func set_visibility(value:bool):
	_get_visibility_toggle_button().set_pressed_no_signal(value)
	
	if visibility_toggle_button:
		visible = value
	else:
		find_child("Controls").visible = value
		facts_container.visible = value

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
	var child_count := facts_container.get_child_count()
	var button_label := str(child_count) if child_count > 0 else ""
	if visibility_toggle_button:
		visibility_toggle_button.text = button_label
	else:
		find_child("VisibilityToggleButton").text = button_label


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


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			set_visibility(false)
