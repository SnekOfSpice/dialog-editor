@tool
extends Control
class_name FactItem

signal request_delete_fact(fact_name:String)

var fact_name := ""
var entered_text := ""

var virtual_hint_line := 0

func _ready() -> void:
	find_child("RegisterContainer").visible = false

func set_fact(new_fact_name: String, default_value: bool):
	fact_name = new_fact_name
	find_child("FactName").text = fact_name
	find_child("FactValue").button_pressed = default_value
	_on_fact_name_text_changed(fact_name)

func get_fact_value():
	return find_child("FactValue").button_pressed

func get_fact_name():
	return find_child("FactName").text

func update_unregsitered_prompt():
	var new_text = entered_text
	var is_unregistered = (not Pages.facts.keys().has(new_text))
#		or Pages.facts.get(new_text) == find_child("FactValue").button_pressed
#	)
	find_child("RegisterContainer").visible = true
	if not Pages.facts.keys().has(new_text):
		find_child("RegisterLabel").text = str(
			"Fact \"",
			new_text,
			"\" isn't registered in global scope with default value ",
			not find_child("FactValue").button_pressed,
			". Would you like to register it?",
			" (Facts are registered with the inverse of the value that registered them.)",
		)
	else:
		find_child("RegisterLabel").text = str(
			"Registered as ",
			Pages.facts.get(new_text)
		)

func _input(event: InputEvent) -> void:
	if not event is InputEventMouseButton:
		return
	if get_rect().has_point(get_local_mouse_position()):
		return
	$ReadHint.hide()

func update_hint(new_text: String):
	if new_text.is_empty() or not find_child("FactName").has_focus():
		$ReadHint.hide()
		return
	var facts := ""
	var valid_facts := []
	for fact : String in Pages.facts:
		if fact.contains(new_text):
			valid_facts.append(fact)
	
	if valid_facts.is_empty():
		virtual_hint_line == 0
		$ReadHint.hide()
		return
	if virtual_hint_line >= valid_facts.size():
		virtual_hint_line = max(valid_facts.size() - 1, 0)
	
	var i := 0
	for fact : String in valid_facts:
		var fact_highlighted := fact.replace(new_text, str("[b]", new_text, "[/b]"))
		
		if i == virtual_hint_line:
			fact_highlighted = str(">", fact_highlighted)
		
		facts += fact_highlighted
		facts += "\n"
		i += 1
	
	facts = facts.trim_suffix("\n")
	$ReadHint.popup()
	$ReadHint.build(facts)
	
	var caret_pos = (
			get_window().position +
			Vector2i(global_position)
			)
	caret_pos.y -= 140
	$ReadHint.position = caret_pos

func _on_fact_name_text_changed(new_text: String) -> void:
	entered_text = new_text
	update_unregsitered_prompt()
	update_hint(new_text)


func _on_register_button_pressed() -> void:
	Pages.facts[entered_text] = not(find_child("FactValue").button_pressed)
	find_child("RegisterContainer").visible = false
	
	$ReadHint.hide()


func _on_delete_button_pressed() -> void:
	emit_signal("request_delete_fact", get_fact_name())


func _on_fact_value_pressed() -> void:
	update_unregsitered_prompt()


func _on_fact_value_toggled(button_pressed: bool) -> void:
	update_unregsitered_prompt()


func _on_fact_name_focus_exited() -> void:
	$ReadHint.hide()


func _on_fact_name_gui_input(event: InputEvent) -> void:
	if Input.is_key_pressed(KEY_DOWN):
		virtual_hint_line += 1
		if virtual_hint_line >= $ReadHint.get_hint_line_count():
			virtual_hint_line = 0
	if Input.is_key_pressed(KEY_UP):
		virtual_hint_line -= 1
		if virtual_hint_line < 0:
			virtual_hint_line = $ReadHint.get_hint_line_count() - 1
	update_hint(find_child("FactName").text)
	if Input.is_key_pressed(KEY_ENTER):
		var text_in_hint : String = $ReadHint.get_text_in_line(virtual_hint_line)
		text_in_hint = text_in_hint.replace(">", "")
		text_in_hint = text_in_hint.replace("[b]", "")
		text_in_hint = text_in_hint.replace("[/b]", "")
		find_child("FactName").text = text_in_hint
		
		await get_tree().process_frame
		$ReadHint.hide()



func _on_fact_name_focus_entered() -> void:
	virtual_hint_line = 0
