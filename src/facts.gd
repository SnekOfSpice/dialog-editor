extends MarginContainer


func serialize() -> Dictionary:
	var result := {}
	for fact in find_child("FactsContainer").get_children():
		result[fact.get_fact_name()] = fact.get_fact_value()
	return result

func deserialize(data: Dictionary):
	for fact_name in data.keys():
		add_fact(fact_name, data.get(fact_name))

func add_fact(fact_name: String, fact_value: bool):
	var f = preload("res://src/fact_item.tscn").instantiate()
	find_child("FactsContainer").add_child(f)
	f.set_fact(fact_name, fact_value)

func _on_add_fact_button_pressed() -> void:
	add_fact(str("newfact", Pages.facts.size()), true)
