@tool
extends Control

var instruction_name := ""
var selected_index := 0

func serialize():
	var result = {}
	
	result["name"] = instruction_name
	result["delay.before"] = find_child("DelayBeforeSpinBox").value
	result["delay.after"] = find_child("DelayAfterSpinBox").value
	#result["meta.selected_index"] = selected_index
	
	var content = []
	#for c in find_child("ArgContainer").get_children():
	var template_args = Pages.get_instruction_args(instruction_name).duplicate(true)
	var entered_text : String = find_child("InstructionTextEdit").text.trim_prefix(str(instruction_name, "("))
	entered_text = entered_text.trim_suffix(")")
	
	var entered_args : Array
	if entered_text.is_empty():
		entered_args = []
	else:
		entered_args = entered_text.split(",")
	var i = 0
	for ea in entered_args:
		while ea.begins_with(" "):
			ea = ea.trim_prefix(" ")
		while ea.ends_with(" "):
			ea = ea.trim_suffix(" ")
		entered_args[i] = ea
		i += 1
	
	
	var n = 0
	while entered_args.size() > template_args.size():
		template_args.append(str("overdefined", n))
		n += 1
	var m = 0
	while entered_args.size() < template_args.size():
		entered_args.append(str("underdefined", m))
		m += 1
	
	print(template_args)
	print(entered_args)
	
	
	for j in entered_args.size():
		var arg := {
			"name" : template_args[j],
			"value" : entered_args[j]
		}
		content.append(arg)
		
	result["content"] = content
	
	return result


func deserialize(data):
	instruction_name = data.get("name", "")
	if instruction_name.is_empty():
		return
		
	set_instruction_name(instruction_name)
	
	var line_content := str(instruction_name, "(")
	var last_value:String
	var i = 0
	for arg_with_value in data.get("content"):
		if arg_with_value.get("name").is_empty():
			continue
		line_content += arg_with_value.get("value")
		if i < data.get("content").size() - 1:
			line_content += ", "
		last_value = arg_with_value.get("value")
		i += 1
	line_content += ")"
	find_child("InstructionTextEdit").text = line_content
		
	
	find_child("DelayBeforeSpinBox").value = float(data.get("delay.before", data.get("delay", 0.0)))
	find_child("DelayAfterSpinBox").value = float(data.get("delay.after", 0.0))

func set_page_view(view:DiisisEditor.PageView):
	find_child("InputLockContainer").visible = view != DiisisEditor.PageView.Minimal

func _on_template_list_item_selected(index: int) -> void:
	set_instruction_name(find_child("TemplateList").get_item_text(index))
	selected_index = index
	

func set_instruction_name(instr_name : String):
	instruction_name = instr_name

func build_typing_hint():
	find_child("TypingHint").build(Pages.get_all_instruction_names())
	find_child("TypingHint").popup()
	var caret_pos = (
		get_window().position +
		Vector2i(find_child("InstructionTextEdit").global_position) +
		Vector2i(find_child("InstructionTextEdit").get_caret_draw_pos())
		)
	caret_pos.x += 40
	find_child("TypingHint").position = caret_pos

func _on_instruction_text_edit_focus_entered() -> void:
	if find_child("InstructionTextEdit").text.is_empty():
		build_typing_hint()


func _on_instruction_text_edit_caret_changed() -> void:
	if find_child("InstructionTextEdit").get_caret_column() == 0:
		var is_line_empty = find_child("InstructionTextEdit").get_line(find_child("InstructionTextEdit").get_caret_line()).is_empty()
		if is_line_empty:
			build_typing_hint()
	
	var caret_col = find_child("InstructionTextEdit").get_caret_column()
	var start = find_child("InstructionTextEdit").text.find("(")
	var end = find_child("InstructionTextEdit").text.find(")") + 1
	
	if caret_col > start and caret_col < end:
		var caret_pos = (
		get_window().position +
		Vector2i(find_child("InstructionTextEdit").global_position) +
		Vector2i(find_child("InstructionTextEdit").get_caret_draw_pos())
		)
		caret_pos.x += 40
		find_child("ArgHint").position = caret_pos		
		
		var args = Pages.get_instruction_args(instruction_name)
		var args_before_caret :int = find_child("InstructionTextEdit").text.count(",", 0, caret_col)
		
		var args_cleaned := ""
		
		var i := 0
		for a in args:
			if i == args_before_caret:
				args_cleaned += "[b]"
			args_cleaned += a
			if i < args.size() - 1:
				args_cleaned += ", "
			if i == args_before_caret:
				args_cleaned += "[/b]"
			i += 1
		
		find_child("ArgHint").build(args_cleaned)
		find_child("ArgHint").popup()
		
		find_child("InstructionTextEdit").set_caret_column(caret_col)
		find_child("InstructionTextEdit").call_deferred("grab_focus")
	else:
		find_child("ArgHint").hide()


func _on_typing_hint_item_chosen(item_name) -> void:
	find_child("InstructionTextEdit").insert_text_at_caret(str(item_name, "()"))
	find_child("InstructionTextEdit").set_caret_column(find_child("InstructionTextEdit").text.length() - 1)
	set_instruction_name(item_name)


func _on_instruction_text_edit_focus_exited() -> void:
	find_child("ArgHint").hide()


func _on_instruction_text_edit_text_changed() -> void:
	if find_child("InstructionTextEdit").text.is_empty():
		build_typing_hint()
