extends MarginContainer

enum ConditionalOperand {
	AND, OR, nOrMore, nOrLess, betweenXYincl
}

var operand:= ConditionalOperand.AND

func serialize() -> Dictionary:
	return {}

func deserialize(data: Dictionary):
	return

func _on_add_condition_button_pressed() -> void:
	pass # Replace with function body.
