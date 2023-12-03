extends Window

var old_instructions
var new_instructions

signal validate_saved_instructions()

func _ready() -> void:
	fill()

func fill():
	old_instructions = templates2text(Pages.instruction_templates)
	new_instructions = templates2text(Pages.instruction_templates)
	
	find_child("CodeEdit").text = old_instructions

func text2templates(text: String):
	var result = []
	var split = text.split("\n")
	for i in split.size() - 1:
		var line = split[i]
		
		if line == "": # doesnt even happen I think
			continue
		
		var instr_name = line.split("(")[0]
		if "()" in line:
			result.append(
				{
					"name": instr_name,
					"args": []
				}
			)
			continue
		var arg_string = line.replace(instr_name, "")
		arg_string = arg_string.replace(")", "")
		arg_string = arg_string.replace("(", "")
		var args = Array(arg_string.split(","))
		result.append(
			{
				"name": instr_name,
				"args": args
			}
		)
	
	return result

func templates2text(templates: Array):
	var result = ""
	for t in templates:
		var line = str(t.get("name"))
		line += "("
		for i in t.get("args").size():
			line += t.get("args")[i]
			if i < t.get("args").size() - 1:
				line += ","
		line += ")"
		line += "\n"
		result += line
	
	return result

func _on_about_to_popup() -> void:
	fill()


func _on_close_requested() -> void:
	hide()


func _on_discard_button_pressed() -> void:
	find_child("CodeEdit").text = old_instructions
	hide()


func _on_save_button_pressed() -> void:
	save()

func save():
	new_instructions = find_child("CodeEdit").text
	if not new_instructions.ends_with("\n"):
		new_instructions += "\n"
	Pages.instruction_templates = text2templates(new_instructions)

func _on_save_close_button_pressed() -> void:
	emit_signal("validate_saved_instructions")
	save()
	hide()


func _on_help_button_pressed() -> void:
	pass # Replace with function body.
