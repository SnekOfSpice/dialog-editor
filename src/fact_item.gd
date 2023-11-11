extends Control


var fact_name := ""

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
	var new_text = find_child("FactName").text
	var is_unregistered = (not Pages.facts.keys().has(new_text)
		or Pages.facts.get(new_text) == find_child("FactValue").button_pressed
	)
	find_child("RegisterContainer").visible = is_unregistered
	if find_child("RegisterContainer").visible:
		find_child("RegisterLabel").text = str(
			"Fact \"",
			new_text,
			"\" isn't registered in global scope with default value ",
			not find_child("FactValue").button_pressed,
			". Would you like to register it?",
			"(Facts are registered with the inverse of the value that registered them.)",
		)

func _on_fact_name_text_changed(new_text: String) -> void:
	update_unregsitered_prompt()


func _on_register_button_pressed() -> void:
	Pages.facts[find_child("FactName").text] = not(find_child("FactValue").button_pressed)
	find_child("RegisterContainer").visible = false


func _on_delete_button_pressed() -> void:
	queue_free()


func _on_fact_value_pressed() -> void:
	update_unregsitered_prompt()


func _on_fact_value_toggled(button_pressed: bool) -> void:
	update_unregsitered_prompt()
