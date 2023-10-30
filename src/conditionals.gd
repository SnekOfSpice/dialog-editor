extends Facts

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

func _ready() -> void:
	for a in ConditionalOperand:
		find_child("OperandOptionButton").add_item(a)
	
	for a in Behavior:
		find_child("BehaviorButton").add_item(a)
	
	set_operand(ConditionalOperand.AND)

func deserialize(data: Dictionary):
	super.deserialize(data.get("facts", {}))
	set_operand(data.get("operand", 0))
	find_child("BehaviorButton").select(data.get("behavior", 0))
	
	var args = data.get("operand_args", [])
	if args.size() > 0:
		find_child("OperandArg1").value = args[0]
		if args.size() > 1:
			find_child("OperandArg2").value = args[1]

func serialize() -> Dictionary:
	var facts = super.serialize()
	var conditional = {}
	conditional["facts"] = facts
	conditional["operand"] = operand
	conditional["operand_key"] = ConditionalOperand.keys()[operand]
	conditional["behavior_key"] = Behavior.keys()[selected_behavior]
	conditional["behavior"] = selected_behavior
	
	var args = []
	if find_child("OperandArg1").visible: args.append(find_child("OperandArg1").value)
	if find_child("OperandArg2").visible: args.append(find_child("OperandArg2").value)
	conditional["operand_args"] = args
	
	return conditional

func set_operand(value: int):
	operand = value
	find_child("OperandArg1").visible = (
		operand == ConditionalOperand.nOrLess or 
		operand == ConditionalOperand.nOrMore or 
		operand == ConditionalOperand.betweenNMincl 
		)
	find_child("OperandArg2").visible = (
		operand == ConditionalOperand.betweenNMincl 
		)

func _on_add_condition_button_pressed() -> void:
	add_fact(str("newfact", Pages.facts.size()), true)


func _on_operand_option_button_item_selected(index: int) -> void:
	set_operand(index)


func _on_behavior_button_item_selected(index: int) -> void:
	selected_behavior = index
