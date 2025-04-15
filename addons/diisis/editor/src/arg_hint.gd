@tool
extends Window

func build_str(text:String):
	size = Vector2.ONE
	find_child("TextLabel").text = text

func build(instruction_name: String, full_text:String, caret_column:int):
	size = Vector2.ONE
	var arg_names = Pages.get_instruction_arg_names(instruction_name)
	var arg_types = Pages.get_instruction_arg_types(instruction_name)
	var arg_defaults = Pages.get_instruction_arg_defaults(instruction_name)
	var arg_strings := []
	var i := 0
	while i < arg_names.size():
		var arg_name : String = arg_names[i]
		var arg_type : String = arg_types[i]
		var arg_default = arg_defaults.get(arg_name)
		var arg_string := str(arg_name, " : [i][color=b88d86EE]", arg_type, "[/color][/i]")
		if arg_default:
			arg_string += str("[color=ceb1bcB7] ?[/color] [color=ceb1bc]", arg_default, "[/color]")
		arg_strings.append(arg_string)
		i += 1
	var args_before_caret :int = full_text.count(",", 0, caret_column)
	
	var hint := ""
	
	i = 0
	var hit_index := 0
	for a in arg_strings:
		if i == args_before_caret:
			hit_index = i
			hint += "[u][bgcolor=05020a][outline_size=1][outline_color=e6c9c4DF]"
		hint += a
		if i == args_before_caret:
			hint += "[/outline_color][/outline_size][/bgcolor][/u]"
		if i < arg_strings.size() - 1:
			hint += ", "
		i += 1
	find_child("TextLabel").text = hint
	position.x -= size.x * (float(hit_index) / float (i))

func _on_close_requested() -> void:
	hide()

func get_hint_line_count() -> int:
	return find_child("TextLabel").get_line_count()

func get_text_in_line(line:int) -> String:
	var label_text : String = find_child("TextLabel").text
	var segments = label_text.split("\n")
	if segments.size() <= line:
		push_warning("Text too short.")
		return ""
	return segments[line]
