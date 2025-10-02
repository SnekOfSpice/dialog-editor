@tool
extends Control
class_name FactItem

signal request_delete_fact(fact_name:String)

enum DataType{
	Bool,
	Int,
}
enum Comparator{
	EQ,
	UNEQ,
	LT,
	LTE,
	GT,
	GTE
}
enum Operator{
	Set,
	Add,
}

var fact_name := ""
var entered_text := ""
var is_conditional := false
var data_type : DataType = DataType.Bool
var int_comparator : Comparator = Comparator.EQ
var int_operator : Operator = Operator.Set

var virtual_hint_line := 0

func init() -> void:
	find_child("RegisterContainer").visible = false
	find_child("RegisterButton").visible = false
	
	DiisisEditorUtil.set_up_delete_modulate(self, find_child("DeleteButton"))

func serialize() -> Dictionary:
	var result := {}
	
	result["fact_name"] = get_fact_name()
	result["fact_value"] = get_fact_value()
	result["is_conditional"] = is_conditional
	result["data_type"] = data_type
	result["int_comparator"] = int_comparator
	result["int_operator"] = int_operator
	
	return result

func deserialize(data: Dictionary) -> void:
	set_fact(data.get("fact_name", ""), data.get("fact_value", true))
	set_is_conditional(data.get("is_conditional", false))
	set_data_type(data.get("data_type", DataType.Bool))
	set_int_comparator(data.get("int_comparator", Comparator.EQ))
	set_int_operator(data.get("int_operator", Operator.Set))
	find_child("RegisterButton").visible = Pages.is_fact_new_and_not_empty(data.get("fact_name", ""))
	find_child("FactName").completion_options = Pages.facts.keys()


func set_fact(new_fact_name: String, default_value):
	if default_value is bool:
		find_child("FactBoolValue").button_pressed = default_value
	else:
		if str(default_value).contains("."):
			pass # floats don't exist
		else:
			find_child("IntValueSpinBox").value = int(default_value)
	fact_name = new_fact_name
	find_child("FactName").text = fact_name
	find_child("FactName")._on_text_changed(fact_name)
	_on_fact_name_text_changed(fact_name)

func set_data_type(value:DataType):
	data_type = value
	find_child("FactBoolValue").visible = data_type == DataType.Bool
	find_child("FactIntValueContainer").visible = data_type == DataType.Int
	find_child("DataTypeButton").select(data_type)
	var entered_fact_name :String= find_child("FactName").text
	if Pages.facts.has(entered_fact_name):
		var is_registered_as_bool = Pages.facts.get(entered_fact_name) is bool
		var mismatch: bool
		if ((data_type == DataType.Int and is_registered_as_bool) or
		(data_type == DataType.Bool and not is_registered_as_bool)):
			mismatch = true
		else:
			mismatch = false
		find_child("TypeMismatchLabel").visible = mismatch
	else:
		find_child("TypeMismatchLabel").visible = false
	

func set_is_conditional(value:bool):
	is_conditional = value
	find_child("IntComparatorButton").visible = is_conditional
	find_child("IntOperandButton").visible = not is_conditional


func set_int_comparator(value:Comparator):
	int_comparator = value
	find_child("IntComparatorButton").select(int_comparator)

func set_int_operator(value:Operator):
	int_operator = value
	var button : Button = find_child("IntOperandButton")
	if int_operator == Operator.Set:
		button.text = "="
	elif int_operator == Operator.Add:
		button.text = "+"

func get_fact_value():
	if data_type == DataType.Bool:
		return find_child("FactBoolValue").button_pressed
	elif data_type == DataType.Int:
		return find_child("IntValueSpinBox").value

func get_fact_name() -> String:
	return find_child("FactName").text

func update_unregsitered_prompt() -> void:
	var new_text = entered_text
	find_child("RegisterButton").visible = Pages.is_fact_new_and_not_empty(entered_text)
	if not Pages.has_fact(new_text) and not new_text.is_empty():
		find_child("RegisterLabel").text = str(
			"Fact \"",
			new_text,
			"\" isn't registered.")
	else:
		if new_text.is_empty():
			find_child("RegisterLabel").text = str("Can't be empty!")
		else:
			find_child("RegisterLabel").text = ""
			find_child("FactName").tooltip_text = str(
				"Registered as ",
				Pages.facts.get(new_text)
			)
			if Pages.facts.get(new_text) is bool:
				set_data_type(DataType.Bool)
			else:
				set_data_type(DataType.Int)
		
	find_child("RegisterContainer").visible = not find_child("RegisterLabel").text.is_empty()

func _input(event: InputEvent) -> void:
	if not event is InputEventMouseButton:
		return
	if get_rect().has_point(get_local_mouse_position()):
		return
	$Hint.hide()

func update_hint(new_text: String):
	if new_text.is_empty() or not find_child("FactName").has_focus():
		$Hint.hide()
		return
	var facts := ""
	var valid_facts := []
	for fact : String in Pages.facts:
		if fact.contains(new_text):
			valid_facts.append(fact)
	
	if valid_facts.is_empty():
		virtual_hint_line == 0
		$Hint.hide()
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
	$Hint.popup()
	$Hint.build_str(facts)
	
	var caret_pos = (
			#get_window().position +
			Vector2i(global_position)
			)
	caret_pos.y -= 140
	$Hint.position = caret_pos



func _on_register_button_pressed() -> void:
	var value
	if data_type == DataType.Bool:
		value = not(find_child("FactBoolValue").button_pressed)
	elif data_type == DataType.Int:
		value = 0
	Pages.register_fact(entered_text, value)
	find_child("RegisterContainer").visible = false
	find_child("FactName").tooltip_text = str(
				"Registered as ",
				Pages.facts.get(entered_text)
			)
	
	$Hint.hide()


func _on_delete_button_pressed() -> void:
	emit_signal("request_delete_fact", get_fact_name())


func _on_fact_value_pressed() -> void:
	update_unregsitered_prompt()


func _on_fact_value_toggled(button_pressed: bool) -> void:
	update_unregsitered_prompt()


func _on_int_operand_button_pressed() -> void:
	var button : Button = find_child("IntOperandButton")
	if button.text == "=":
		set_int_operator(Operator.Add)
	elif button.text == "+":
		set_int_operator(Operator.Set)


func _on_fact_name_text_entered(new_text: String) -> void:
	entered_text = new_text
	update_unregsitered_prompt()


func _on_fact_name_text_submitted(new_text: String) -> void:
	if not $Hint.visible:
		_on_register_button_pressed()
		_on_fact_name_text_changed(new_text)
		find_child("FactName").text = new_text
		find_child("FactName").caret_column = new_text.length()


func _on_fact_name_text_changed(new_text: String) -> void:
	find_child("DataTypeButton").disabled = Pages.has_fact(new_text)


func _on_fact_name_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.is_command_or_control_pressed() and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			var fact_name := get_fact_name()
			if Pages.has_fact(fact_name):
				Pages.editor.open_facts_window(fact_name)
