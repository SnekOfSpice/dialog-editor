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
		
	for line in text_lines:
		print(line)
	return
	#var real_pages := [] ## this currently wont work anymore
	#while not text_lines.is_empty():
		#var current_line : String = text_lines.pop_front()
		#current_line += "\n"
		#if current_line == "PAGE\n":
			#real_pages.append(constructed_page)
			#constructed_page = ""
			##continue
		#else:
			#constructed_page += current_line
	#if not constructed_page.is_empty():
		#real_pages.append(constructed_page)
		#
	#for page in real_pages:
		#await get_tree().process_frame
		#Pages.editor.request_add_page_after_current()
		#await get_tree().process_frame
		#var lines : PackedStringArray = page.split("CONTENT\n")
		#for line in lines:
			#var formatted_text := format_text(str("CONTENT\n", line), actors)
			#
			#if capitalize:
				#formatted_text = Pages.capitalize_sentence_beginnings(formatted_text)
			#if neaten_whitespace:
				#formatted_text = Pages.neaten_whitespace(formatted_text)
			#if fix_punctuation:
				#formatted_text = Pages.fix_punctuation(formatted_text)
			#
			#var line_obj := {
				#"content" :  {
					#"content" : formatted_text
				#}
			#}
			#await get_tree().process_frame
			#Pages.editor.add_line_to_end_of_page(line_obj)
			#await get_tree().process_frame

func override_existing_data(imported_lines:Array, payload:={}, actor_ingestion_override:=[]):
	var new_page_data := {}
	
	# iterare over every imported_lines
	# ingest content when needed
	# then override Pages.page_data
	# update
	var page_id : String
	var current_page_data : Dictionary
	var current_line_data : Dictionary
	while not imported_lines.is_empty():
		var line : String = imported_lines.pop_front()
		if line.begins_with("PAGE"):
			page_id = line.split("ID:")[1]
			if not current_page_data.is_empty(): # happens on first iteration
				current_page_data["lines"] = current_line_data
				new_page_data[current_page_data.get("number")] = current_page_data.duplicate(true)
			current_page_data = get_page_data_without_line_data(page_id)
		
	if not current_page_data.is_empty(): # happens on first iteration
		new_page_data[current_page_data.get("number")] = current_page_data.duplicate(true)
	


func update_existing_data(imported_lines:Array, payload:={}, actor_ingestion_override:=[]):
	var line_content_by_id : Dictionary[String, Dictionary] = {}
	var line_data : Dictionary
	while not imported_lines.is_empty():
		var line : String = imported_lines.pop_front()
		if line.begins_with("PAGE"):
			continue
		var line_type : DIISISGlobal.LineType
		if line.begins_with("LINE i"):
			line_type = DIISISGlobal.LineType.Instruction
		if line.begins_with("LINE c"):
			line_type = DIISISGlobal.LineType.Choice
		if line.begins_with("LINE f"):
			line_type = DIISISGlobal.LineType.Folder
		else:
			line_type = DIISISGlobal.LineType.Text
		var line_id = line.split("ID:")[1]
		
		var lines_for_line_content := []
		var line_content_farm := imported_lines.duplicate(true)
		while not line_content_farm.is_empty():
			var local_line : String = line_content_farm.pop_front()
			if local_line.begins_with("LINE"):
				break
			lines_for_line_content.append(local_line)
			imported_lines.pop_front()
		
		# construct line_data_by_id
		match line_type:
			DIISISGlobal.LineType.Text:
				var capitalize : bool = payload.get("capitalize", false)
				var neaten_whitespace : bool = payload.get("neaten_whitespace", false)
				var fix_punctuation : bool = payload.get("fix_punctuation", false)
				var formatted_text := format_text("\n".join(lines_for_line_content), actor_ingestion_override)
				if capitalize:
					formatted_text = Pages.capitalize_sentence_beginnings(formatted_text)
				if neaten_whitespace:
					formatted_text = Pages.neaten_whitespace(formatted_text)
				if fix_punctuation:
					formatted_text = Pages.fix_punctuation(formatted_text)
				line_content_by_id[line_id] = {
					"text" : formatted_text
				}
			DIISISGlobal.LineType.Choice:
				var choice_texts := []
				for content_line : String in lines_for_line_content:
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
				line_content_by_id[line_id] = {
					"choice_texts" : choice_texts
				}
			DIISISGlobal.LineType.Instruction:
				var instruction_data := {}
				for content_line : String in lines_for_line_content:
					if content_line.begins_with("x<"): # reverse present but disabled
						instruction_data["meta.has_reverse"] = false
						instruction_data["meta.reverse_text"] = content_line.trim_prefix("x<")
					elif content_line.begins_with("<"): # reverse present but disabled
						instruction_data["meta.has_reverse"] = true
						instruction_data["meta.reverse_text"] = content_line.trim_prefix("<")
					else: # default
						instruction_data["meta.text"] = content_line
				line_content_by_id[line_id] = instruction_data
			DIISISGlobal.LineType.Folder:
				line_content_by_id[line_id] = {
					"range" : lines_for_line_content.front()
				}
	
	# then go over Pages.page_data and insert the updated line content
	
	Pages.update_line_content(line_content_by_id)
	#for line_id :String in line_content_by_id.keys():
		#
		##var pages_line_data := get_line_data_by_id(line_id)
		#
		
	



func get_line_data_by_id(line_id:String) -> Dictionary:
	for i in Pages.page_data.size():
		var page_data = Pages.get_page_data(i)
		for line : Dictionary in page_data.get("lines", []):
			if line.get("id") == line_id:
				return line.duplicate(true)
	return {}

func get_page_data_without_line_data(page_id:String) -> Dictionary:
	for i in Pages.page_data.size():
		var page_data = Pages.get_page_data(i)
		if page_data.get("id", "") == page_id:
			var ddata = page_data.duplicate(true)
			ddata.erase("lines")
			return ddata
	return {}
