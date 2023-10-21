extends Control


var fact_name := ""

func _ready() -> void:
	find_child("RegisterContainer").visible = false

func set_fact(fact_name: String, default_value: bool):
	self.fact_name = fact_name
	find_child("FactName").text = fact_name
	find_child("FactValue").button_pressed = default_value
	_on_fact_name_text_changed(fact_name)

func get_fact_value():
	return find_child("FactValue").button_pressed

func get_fact_name():
	return find_child("FactName").text

func _on_fact_name_text_changed(new_text: String) -> void:
	printt(new_text, Pages.facts.has(new_text))
	find_child("RegisterContainer").visible = not Pages.facts.has(new_text)
	if find_child("RegisterContainer").visible:
		find_child("RegisterLabel").text = str(
			"Fact \"",
			new_text,
			"\" isn't registered in global scope. Would you like to register it?"
		)


func _on_register_button_pressed() -> void:
	Pages.facts.append(find_child("FactName").text)
	find_child("RegisterContainer").visible = false
