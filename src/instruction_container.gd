extends HBoxContainer

var instruction_name := ""

func _ready() -> void:
	var list : ItemList = find_child("TemplateList")
	for instr in Pages.instruction_templates:
		list.add_item(instr.get("name"))
	
#	if list.is_item_selectable(0):
#		list.select(0)
	
	list.sort_items_by_text()




func serialize():
	var result = {}
	
	result["name"] = instruction_name
	result["delay"] = find_child("DelaySpinBox").value
	
	var content = []
	for c in find_child("ArgContainer").get_children():
		content.append(c.serialize())
	result["content"] = content
	
	return result


func deserialize(data):
	if data.get("content") is Array: # deserializing with {name, value}
		for c in find_child("ArgContainer").get_children():
			c.queue_free()
		
		for arg_with_value in data.get("content"):
			
	
	
	
			var a = preload("res://src/instruction_argument.tscn").instantiate()
			find_child("ArgContainer").add_child(a)
			var formatted = {
				"name": arg_with_value.get("name"),
				"value": arg_with_value.get("value")
			}
			a.deserialize(formatted)
	else:
		fill_args(data.get("content").get("args"))
	
	find_child("DelaySpinBox").value = float(data.get("delay", 0.0))
	
		

func fill_args(args: Array):
	for c in find_child("ArgContainer").get_children():
		c.queue_free()
	
	
	for arg in args:
		var a = preload("res://src/instruction_argument.tscn").instantiate()
		find_child("ArgContainer").add_child(a)
		var formatted = {
			"name": arg,
			"value": ""
		}
		a.deserialize(formatted)

func _on_template_list_item_selected(index: int) -> void:
	set_selected_instruction(find_child("TemplateList").get_item_text(index))
	

func set_selected_instruction(instr_name : String):
	instruction_name = instr_name
	var args = Pages.get_instruction_args(instruction_name)
	fill_args(args)
