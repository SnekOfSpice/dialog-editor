@tool
extends Window

func build_str(text:String):
	content_scale_factor = Pages.editor.content_scale
	size = Vector2.ONE
	find_child("TextLabel").text = text

func build(instruction_name: String, full_text:String, caret_column:int):
	content_scale_factor = Pages.editor.content_scale
	size = Vector2.ONE
	var arg_names = Pages.get_custom_method_arg_names(instruction_name)
	var arg_types = Pages.get_custom_method_types(instruction_name)
	var arg_defaults = Pages.get_custom_method_defaults(instruction_name)
	var arg_strings := []
	var i := 0
	while i < arg_names.size():
		var arg_name : String = arg_names[i]
		var arg_type : String = DIISIS.type_to_str(arg_types[i])

		var dropdowns : Array = Pages.custom_method_dropdown_limiters.get(instruction_name, {}).get(arg_name, {}).get("selected", [])
		if dropdowns.size() > 0:
			arg_type = ", ".join(dropdowns)
		
		var arg_default = arg_defaults.get(arg_name)
		var arg_string := str(arg_name, " : [i][color=b88d86EE]", arg_type, "[/color][/i]")
		var default_color : String
		if arg_default == Pages.get_custom_method_base_defaultsd(instruction_name).get(arg_name, null):
			default_color = "c9acf2"
		else:
			default_color = "ceb1bc"
		if arg_default != null:
			arg_string += str("[color=ceb1bcB7] ?[/color] [color=", default_color, "]", arg_default, "[/color]")
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
	var back_offset : float
	if i > 0:
		back_offset = (float(hit_index) / float (i))
	else:
		back_offset = 0.5
	position.x -= size.x * back_offset
	
	await get_tree().process_frame
	if hint.is_empty():
		hide()

func _on_close_requested() -> void:
	hide()

func get_hint_line_count() -> int:
	return find_child("TextLabel").get_line_count()

func get_text_in_line(line:int) -> String:
	var label_text : String = find_child("TextLabel").text
	if not visible:
		return ""
	var segments = label_text.split("\n")
	if segments.size() <= line:
		push_warning("Text too short.")
		return ""
	return segments[line]
