@tool
extends Facts
class_name Conditionals

enum ConditionalOperand {
	AND, OR, nOrMore, nOrLess, betweenNMincl
}

const OPERAND_NAMES := {
	ConditionalOperand.AND : "All",
	ConditionalOperand.OR : "Any",
	ConditionalOperand.nOrMore : "At Least",
	ConditionalOperand.nOrLess : "At Most",
	ConditionalOperand.betweenNMincl : "Between",
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
	
	find_child("OperandOptionButton").clear()
	find_child("BehaviorButton").clear()
	
	for a in ConditionalOperand.size():
		find_child("OperandOptionButton").add_item(OPERAND_NAMES.get(a))
	
	for a in Behavior:
		# depth 2 is choice item. only choice item has a meaningful difference between hide/show and enable/disable
		if (a == "Enable" or a == "Disable") and address_depth != 2:
			continue
		find_child("BehaviorButton").add_item(a)
	
	set_operand(ConditionalOperand.AND)
	set_controls_collapsed(Pages.collapse_conditional_controls_by_default)

func set_visibility(value:bool):
	super.set_visibility(value)
	find_child("BehaviorContainer").visible = value

func set_behavior_container_visible(value:bool):
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
	result["meta.controls_collapsed"] = get_controls_collapsed()
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
	selected_behavior = int(data.get("behavior", 0))
	find_child("BehaviorButton").select(selected_behavior)
	
	var args = data.get("operand_args", [])
	if args.size() > 0:
		find_child("OperandArg1").value = args[0]
		if args.size() > 1:
			find_child("OperandArg2").value = args[1]
	
	set_visibility(data.get("meta.visible", false))
	set_controls_collapsed(data.get("meta.controls_collapsed", Pages.collapse_conditional_controls_by_default))
	
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


func _on_operand_option_button_item_selected(index: int) -> void:
	set_operand(index)


func _on_behavior_button_item_selected(index: int) -> void:
	selected_behavior = index

func get_controls_collapsed() -> bool:
	return find_child("CollapseControlButton").button_pressed

func _get_operand_string() -> String:
	var result : String = find_child("OperandOptionButton").text
	if operand in [ConditionalOperand.nOrMore, ConditionalOperand.nOrLess, ConditionalOperand.betweenNMincl]:
		result += str(" ", int(find_child("OperandArg1").value))
	if operand in [ConditionalOperand.betweenNMincl]:
		result += str(" - ", int(find_child("OperandArg2").value))
	
	return result

func set_controls_collapsed(value:bool):
	var button : Button = find_child("CollapseControlButton")
	find_child("BehaviorInfoLabel").visible = not value
	find_child("BehaviorButton").visible = not value
	find_child("OperandContainer").visible = not value
	if value:
		button.text = str(
			_get_operand_string(),
			" > ",
			find_child("BehaviorButton").text
		)
		button.tooltip_text = "Click to expand controls"
	else:
		button.text = "<"
		button.tooltip_text = "Click to collapse controls"
