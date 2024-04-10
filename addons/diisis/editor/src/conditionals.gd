@tool
extends Facts
class_name Conditionals

enum ConditionalOperand {
	AND, OR, nOrMore, nOrLess, betweenNMincl
}
enum Behavior {
	Show,
	Hide,
	Disable,
	Enable,
}

var operand:= ConditionalOperand.AND
var selected_behavior := Behavior.Show

func init() -> void:
	super.init()
	for a in ConditionalOperand:
		find_child("OperandOptionButton").add_item(a)
	
	for a in Behavior:
		find_child("BehaviorButton").add_item(a)
	
	set_operand(ConditionalOperand.AND)

func set_visibility(value:bool):
	super.set_visibility(value)
	find_child("BehaviorContainer").visible = value

func toggle_visibility():
	if visibility_toggle_button != find_child("VisibilityToggleButton"):
		set_visibility(not visible)
	else:
		set_visibility(not find_child("Controls").visible)

func serialize() -> Dictionary:
	var result = {}
	result["facts"] = super.serialize()
	result["operand"] = operand
	result["operand_key"] = ConditionalOperand.keys()[operand]
	result["behavior_key"] = Behavior.keys()[selected_behavior]
	result["behavior"] = selected_behavior
	if visibility_toggle_button != find_child("VisibilityToggleButton"):
		result["meta.visible"] = visible
	else:
		result["meta.visible"] = find_child("Controls").visible
	
	var args = []
	if find_child("OperandArg1").visible: args.append(find_child("OperandArg1").value)
	if find_child("OperandArg2").visible: args.append(find_child("OperandArg2").value)
	result["operand_args"] = args
	
	return result

func deserialize(data: Dictionary):
	super.deserialize(data.get("facts", {}))
	set_operand(data.get("operand", 0))
	find_child("BehaviorButton").select(data.get("behavior", 0))
	
	var args = data.get("operand_args", [])
	if args.size() > 0:
		find_child("OperandArg1").value = args[0]
		if args.size() > 1:
			find_child("OperandArg2").value = args[1]
	
	set_visibility(data.get("meta.visible", false))
	
	visibility_toggle_button.button_pressed = data.get("meta.visible", false)
	

func set_operand(value: int):
	operand = value
	find_child("OperandOptionButton").select(operand)
	find_child("OperandArg1").visible = (
		operand == ConditionalOperand.nOrLess or 
		operand == ConditionalOperand.nOrMore or 
		operand == ConditionalOperand.betweenNMincl 
		)
	find_child("OperandArg2").visible = (
		operand == ConditionalOperand.betweenNMincl 
		)

func _on_add_condition_button_pressed() -> void:
	add_fact(str("newfact", Pages.facts.keys().size()), true)


func _on_operand_option_button_item_selected(index: int) -> void:
	set_operand(index)


func _on_behavior_button_item_selected(index: int) -> void:
	selected_behavior = index
