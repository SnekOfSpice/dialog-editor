@tool
extends Node

enum ImportMode {
	## build a map of all IDs in the import.
	## plap it on top of page_data where those IDs exist.
	## assumes all lines and pages in the DTF file have an ID
	UpdateExistingData,
	## take all the existing data. if an ID is present there, it gets ingested 
	## on import.
	## new lines will be created when no ID is present. existing lines whose ID
	## is not in the ingested file are deleted.
	## [b]the entire thing is rebuilt[/b]
	OverrideFile
}

func format_text_from_file(path:String) -> String:
	var file = FileAccess.open(path, FileAccess.READ)
	var content = file.get_as_text()
	file.close()
	return format_text(content)


func format_text(text:String, head_replacer_overrides := []) -> String:
	text = text.replace("\r", "\n")
	var lines := text.split("\n", false)
	
	if not lines.has(str("LINE")):
		text = str(Pages.ingestion_actor_declaration, "\nLINE\n", text)
		lines = text.split("\n", false)
	
	var has_content_declaration := false
	var head := []
	var content := []
	for line : String in lines:
		if has_content_declaration:
			content.append(line)
		else:
			head.append(line)
		if line.begins_with("LINE"):
			has_content_declaration = true
			head.remove_at(head.size() - 1)
	if not has_content_declaration:
		Pages.editor.notify("Missing LINE declaration")
		return ""
	var head_replacers := []
	if head_replacer_overrides.is_empty():
		head_replacers = _build_replacers(head)
	else:
		head_replacers = head_replacer_overrides
	
	var true_content := []
	for line : String in content:
		var replaced := false
		for replacer : Array in head_replacers:
			var key : String = replacer[0]
			var value : String = replacer[1]
			if not line.begins_with(key):
				var raw_value : = value.trim_prefix("[]>")
				raw_value = raw_value.trim_suffix(":")
				if line.begins_with(raw_value + ":") or line.begins_with(raw_value + "{"):
					replaced = true
					line = str("[]>", line)
					true_content.append(line)
					break
				continue
			line = line.trim_prefix(key)
			if line.begins_with(":"):
				value = value.trim_suffix(":")
			line = str(value, line)
			true_content.append(line)
			replaced = true
			break
		if not replaced:
			true_content.append(line)
	
	return "\n".join(true_content)

func _build_replacers(head_lines:Array) -> Array:
	var head_replacers := []
	for actor : String in head_lines:
		var parts = actor.split(" ", false)
		if parts.size() != 2:
			continue
		var key : String = parts[0]
		if not key.ends_with(":"):
			key += ":"
		
		var value : String = parts[1]
		if not value.begins_with("[]>"):
			value = str("[]>", value)
		if not value.ends_with(":"):
			value += ":"
		
		head_replacers.append([key, value])
	return head_replacers

func ingest_pages_from_file(path:String, payload:={}) -> void:
	var file = FileAccess.open(path, FileAccess.READ)
	var content = file.get_as_text()
	file.close()
	ingest_pages(content, payload)



## TODO make this ingest different line types
## and either take in or override the existing data
func ingest_pages(text:String, payload:={}) -> void:
	var import_mode : ImportMode = payload.get("import_mode", ImportMode.UpdateExistingData)
	
	text = text.replace("\r", "\n")
	
	if not text.contains("END ACTORS\n"):
		text = str(Pages.ingestion_actor_declaration, "\nEND ACTORS\n", text)
	
	var head_section := text.split("END ACTORS\n", false)[0]
	text = text.split("END ACTORS\n", false)[1]
	var actors := _build_replacers(head_section.split("\n"))

	var text_lines := Array(text.split("\n", false))
	
	var constructed_page := ""
	
	if import_mode == ImportMode.UpdateExistingData:
		update_existing_data(text_lines, payload, actors)
	elif import_mode == ImportMode.OverrideFile:
		override_existing_data(text_lines, payload, actors)
		
	return

func override_existing_data(imported_lines:Array, payload:={}, actor_ingestion_override:=[]):
	var new_page_data := {}
	
	var handled_line_ids := []
	
	var imported_lines_per_page := []
	var working_page := []
	var page_content_line : String = imported_lines.pop_front()
	working_page.append(page_content_line)
	while not imported_lines.is_empty():
		page_content_line = imported_lines.pop_front()
		if page_content_line.begins_with("PAGE"):
			if not working_page.is_empty():
				imported_lines_per_page.append(working_page.duplicate(true))
			working_page.clear()
		#else:
		working_page.append(page_content_line)
	if not working_page.is_empty():
		imported_lines_per_page.append(working_page)
	
	for lines_for_page : Array in imported_lines_per_page:
		var page_line : String = lines_for_page.pop_front()
		var current_page_data := {}
		
		if page_line.contains("ID:"):
			var id : String = page_line.split("ID:")[1]
			print("hehe1")
			current_page_data = get_page_data(id)
		var lines_for_line_content := []
		var line_content_farm := lines_for_page.duplicate(true)
		var working_imported_lines_for_line := []
		var local_line : String = line_content_farm.pop_front()
		
		working_imported_lines_for_line.append(local_line)
		while not line_content_farm.is_empty():
			local_line = line_content_farm.pop_front()
			if local_line.begins_with("LINE") and not working_imported_lines_for_line.is_empty():
				lines_for_line_content.append(working_imported_lines_for_line.duplicate(true))
				working_imported_lines_for_line.clear()
			working_imported_lines_for_line.append(local_line)
		if not working_imported_lines_for_line.is_empty():
			lines_for_line_content.append(working_imported_lines_for_line.duplicate(true))
		
		var line_data_on_page := []
		for lines : Array in lines_for_line_content:
			var line_data := {}
			var line_declaration = lines.pop_front()
			
			var line_id : String
			if line_declaration.contains("ID:"):
				line_id = line_declaration.split("ID:")[1]
			if not line_id.is_empty():
				if handled_line_ids.has(line_id):
					continue
				line_data = get_line_data_by_id(line_id)
				handled_line_ids.append(line_id)
			
			var line_type : DIISISGlobal.LineType
			if line_declaration.begins_with("LINE i"):
				line_type = DIISISGlobal.LineType.Instruction
				line_data["content"] = make_instruction_data(lines)
			elif line_declaration.begins_with("LINE c"):
				line_type = DIISISGlobal.LineType.Choice
				var texts : Array = make_choice_data(lines).get("choice_texts")
				var content := {}
				var choices := []
				
				var pre_existing_choices : Array = line_data.get("content", {}).get("choices", [])
				var pre_existing_ids := []
				for choice : Dictionary in pre_existing_choices:
					pre_existing_ids.append(choice.get("id"))
				
				# contains all optional fields "id" "enabled" "disabled"
				for text_data : Dictionary in texts:
					var text_id : String = text_data.get("id", "")
					var choice_data := {}
					if pre_existing_ids.has(text_id):
						choice_data = pre_existing_choices[pre_existing_ids.find(text_id)].duplicate(true)
						choice_data["id"] = text_id
						
						if text_data.has("enabled"):
							var id = choice_data.get("text_id_enabled")
							Pages.save_text(id, text_data.get("enabled"))
						if text_data.has("disabled"):
							var id = choice_data.get("text_id_disabled")
							Pages.save_text(id, text_data.get("disabled"))
					else:
						if text_data.has("id"):
							choice_data["id"] = text_data.get("id")
						if text_data.has("enabled"):
							var id = Pages.get_new_id()
							Pages.save_text(id, text_data.get("enabled"))
							choice_data["text_id_enabled"] = id
						if text_data.has("disabled"):
							var id = Pages.get_new_id()
							Pages.save_text(id, text_data.get("disabled"))
							choice_data["text_id_disabled"] = id
					
					choices.append(choice_data)
				content["choices"] = choices
				line_data["content"] = content
			elif line_declaration.begins_with("LINE f"):
				line_type = DIISISGlobal.LineType.Folder
				line_data["content"] = make_folder_data(lines)
			else:
				line_type = DIISISGlobal.LineType.Text
				var text_data = make_text_data(lines)
				var id = line_data.get("content", {}).get("text_id", Pages.get_new_id())
				line_data["content"] = {"text_id" : id}
				print("text1")
				Pages.save_text(id, text_data.get("text"))
			line_data["line_type"] = line_type
			line_data_on_page.append(line_data)
			#await get_tree().process_frame
		current_page_data["lines"] = line_data_on_page
		
		var cpn : int = new_page_data.size()
		current_page_data["number"] = cpn
		new_page_data[cpn] = current_page_data
	await get_tree().process_frame
	var file = FileAccess.open("user://import_override_temp.json", FileAccess.WRITE)
	var path := Pages.editor.get_save_path()
	var data = Pages.serialize()
	var data_to_save := {}
	data_to_save["editor"] = Pages.editor.serialize()
	data_to_save["original_path"] = Pages.editor.get_save_path()
	data_to_save["pages"] = Pages.serialize()
	data_to_save["pages"]["page_data"] = new_page_data
	
	file.store_string(JSON.stringify(data_to_save, "\t"))
	file.close()
	await get_tree().process_frame
	Pages.editor.open_new_file.emit()
	

func make_instruction_data(lines:Array) -> Dictionary:
	var instruction_data := {}
	for content_line : String in lines:
		if content_line.begins_with("x<"): # reverse present but disabled
			instruction_data["meta.has_reverse"] = false
			instruction_data["meta.reverse_text"] = content_line.trim_prefix("x<")
		elif content_line.begins_with("<"): # reverse present but disabled
			instruction_data["meta.has_reverse"] = true
			instruction_data["meta.reverse_text"] = content_line.trim_prefix("<")
		else: # default
			instruction_data["meta.text"] = content_line
	return instruction_data

func make_choice_data(lines:Array) -> Dictionary:
	var choice_texts := []
	for content_line : String in lines:
		var text_data := {}
		if content_line.contains("ID:"):
			var parts = content_line.split("ID:")
			content_line = parts[0]
			text_data["id"] = parts[1]
		if content_line.begins_with(">"): # enabled exists
			content_line = content_line.trim_prefix(">")
			var enabled_text : String
			var disabled_text : String
			if content_line.contains("<"):
				var split = content_line.split("<")
				enabled_text = split[0]
				disabled_text = split[1]
			else:
				enabled_text = content_line
			text_data["enabled"] = enabled_text
			if not disabled_text.is_empty():
				text_data["disabled"] = disabled_text
		elif content_line.begins_with("<"): # only disabled
			text_data["disabled"] = content_line.trim_prefix("<")
		choice_texts.append(text_data)
	
	print("CCCmade choices ", choice_texts.size(), choice_texts)
	return {"choice_texts" : choice_texts.duplicate(true)}

func make_text_data(lines:Array, payload:={}, actor_ingestion_override:=[]) -> Dictionary:
	var capitalize : bool = payload.get("capitalize", false)
	var neaten_whitespace : bool = payload.get("neaten_whitespace", false)
	var fix_punctuation : bool = payload.get("fix_punctuation", false)
	var formatted_text := format_text("\n".join(lines), actor_ingestion_override)
	if capitalize:
		formatted_text = Pages.capitalize_sentence_beginnings(formatted_text)
	if neaten_whitespace:
		formatted_text = Pages.neaten_whitespace(formatted_text)
	if fix_punctuation:
		formatted_text = Pages.fix_punctuation(formatted_text)
	return {
		"text" : formatted_text
	}

func make_folder_data(lines:Array) -> Dictionary:
	var range := float(lines.front())
	return {
		"range" : range
	}

func update_existing_data(imported_lines:Array, payload:={}, actor_ingestion_override:=[]):
	var line_content_by_id : Dictionary[String, Dictionary] = {}
	while not imported_lines.is_empty():
		var line : String = imported_lines.pop_front()
		if line.begins_with("PAGE"):
			continue
		var lines_for_line_content := []
		var line_content_farm := imported_lines.duplicate(true)
		while not line_content_farm.is_empty():
			var local_line : String = line_content_farm.pop_front()
			if local_line.begins_with("LINE"):
				break
			lines_for_line_content.append(local_line)
			imported_lines.remove_at(0)
		var line_id = line.split("ID:")[1]
		
		if line.begins_with("LINE i"):
			line_content_by_id[line_id] = make_instruction_data(lines_for_line_content)
		if line.begins_with("LINE c"):
			line_content_by_id[line_id] = make_choice_data(lines_for_line_content)
		if line.begins_with("LINE f"):
			line_content_by_id[line_id] = make_folder_data(lines_for_line_content)
		else:
			if line_content_by_id.has(line_id):
				# idk why this happens but nontext lines get counted double
				continue
			line_content_by_id[line_id] = make_text_data(lines_for_line_content, payload, actor_ingestion_override)
	
	print("-------- are we saving the page after this?")
	# then go over Pages.page_data and insert the updated line content
	Pages.update_line_content(line_content_by_id)

func get_line_data_by_id(line_id:String) -> Dictionary:
	for i in Pages.page_data.size():
		print("hehe2")
		var page_data = Pages.get_page_data(i)
		for line : Dictionary in page_data.get("lines", []):
			if line.get("id") == line_id:
				return line.duplicate(true)
	return {}

func get_page_data(page_id:String) -> Dictionary:
	print("hehe3")
	for i in Pages.page_data.size():
		var page_data = Pages.get_page_data(i)
		if page_data.get("id", "") == page_id:
			var ddata = page_data.duplicate(true)
			return ddata
	return {}
