@tool
extends Node


func format_text_from_file(path:String) -> String:
	var file = FileAccess.open(path, FileAccess.READ)
	var content = file.get_as_text()
	return format_text(content)


func format_text(text:String, head_replacer_overrides := []) -> String:
	text = text.replace("\r", "\n")
	var lines := text.split("\n", false)
	
	if not lines.has(str("CONTENT")):
		text = str(Pages.ingestion_actor_declaration, "\nCONTENT\n", text)
		lines = text.split("\n", false)
	
	var has_content_declaration := false
	var head := []
	var content := []
	for line : String in lines:
		if has_content_declaration:
			content.append(line)
		else:
			head.append(line)
		if line.begins_with("CONTENT"):
			has_content_declaration = true
			head.remove_at(head.size() - 1)
	if not has_content_declaration:
		Pages.editor.notify("Missing CONTENT declaration")
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
			var key = replacer[0]
			var value = replacer[1]
			if not line.begins_with(key):
				continue
			true_content.append(line.replace(key, value))
			replaced = true
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
	ingest_pages(content, payload)

func ingest_pages(text:String, payload:={}) -> void:
	var capitalize : bool = payload.get("capitalize", false)
	var neaten_whitespace : bool = payload.get("neaten_whitespace", false)
	var fix_punctuation : bool = payload.get("fix_punctuation", false)
	
	text = text.replace("\r", "\n")
	
	if not text.contains("END ACTORS\n"):
		text = str(Pages.ingestion_actor_declaration, "\nEND ACTORS\n", text)
	
	var head_section := text.split("END ACTORS\n", false)[0]
	text = text.split("END ACTORS\n", false)[1]
	var actors := _build_replacers(head_section.split("\n"))

	var pages := text.split("PAGE", false)
	var returns := Array(text.split("\n", false))
	var constructed_page := ""
	
	var real_pages := []
	while not returns.is_empty():
		var current_line : String = returns.pop_front()
		current_line += "\n"
		if current_line == "PAGE\n":
			real_pages.append(constructed_page)
			constructed_page = ""
			#continue
		else:
			constructed_page += current_line
	if not constructed_page.is_empty():
		real_pages.append(constructed_page)
		
	for page in real_pages:
		await get_tree().process_frame
		Pages.editor.request_add_page_after_current()
		await get_tree().process_frame
		var lines : PackedStringArray = page.split("CONTENT\n")
		for line in lines:
			var formatted_text := format_text(str("CONTENT\n", line), actors)
			
			if capitalize:
				formatted_text = Pages.capitalize_sentence_beginnings(formatted_text)
			if neaten_whitespace:
				formatted_text = Pages.neaten_whitespace(formatted_text)
			if fix_punctuation:
				formatted_text = Pages.fix_punctuation(formatted_text)
			
			var line_obj := {
				"content" :  {
					"content" : formatted_text
				}
			}
			await get_tree().process_frame
			Pages.editor.add_line_to_end_of_page(line_obj)
			await get_tree().process_frame
