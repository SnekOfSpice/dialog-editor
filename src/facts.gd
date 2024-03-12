@tool
extends MarginContainer
class_name Facts

func serialize() -> Dictionary:
	var result := {}
	#var facts = {}
	for fact in find_child("FactsContainer").get_children():
		result[fact.get_fact_name()] = fact.get_fact_value()
	#result["facts"] = facts
	return result

func deserialize(data: Dictionary):
	var facts = data#.get("facts", {})
	for fact_name in facts.keys():
		add_fact(fact_name, facts.get(fact_name))

func add_fact(fact_name: String, fact_value: bool):
	var f = preload("res://src/fact_item.tscn").instantiate()
	find_child("FactsContainer").add_child(f)
	f.set_fact(fact_name, fact_value)

func _on_add_fact_button_pressed() -> void:
	add_fact(str("newfact", Pages.facts.keys().size()), true)
