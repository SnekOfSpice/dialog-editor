@tool
extends Node


func format_text_from_file(path:String) -> String:
	var file = FileAccess.open(path, FileAccess.READ)
	var content = file.get_as_text()
	return format_text(content)


func format_text(text:String, head_replacer_overrides := []) -> String:
	text = text.replace("\r", "\n")
	#if not text.begins_with("LINE"):
		#Pages.editor.notify("Missing LINE declaration")
		#return ""
	var lines := text.split("\n", false)
	
	var has_content_declaration := false
	var head := []
	var content := []
	for line : String in lines:
		#if line.begins_with("LINE"):
			#continue

		if has_content_declaration:
			content.append(line)
		else:
			head.append(line)
		#print(line.unicode_at(line.length() - 1), "    ", str("\"", line, "\""))
		if line.begins_with("CONTENT"):
			has_content_declaration = true
			head.remove_at(head.size() - 1)
	if not has_content_declaration:
		Pages.editor.notify("Missing CONTENT declaration")
		return ""
	#print(content)
	#return ""
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
			#Pages.editor.notify(str("Head declaration \"", actor, "\" incorrect."))
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

#func create_line_with_payload(text:String) -> Dictionary:
	#return {
		#"content" :  {
			#"content" : format_text(text)
		#}
	#}

func ingest_pages_from_file(path:String) -> void:
	var file = FileAccess.open(path, FileAccess.READ)
	var content = file.get_as_text()
	ingest_pages(content)

func ingest_pages(text:String) -> void:
	text = text.replace("\r", "\n")
	#print(text.contains("END ACTORS\n"))
	var head_section := text.split("END ACTORS\n", false)[0]
	#print("head ", head_section)
	text = text.split("END ACTORS\n", false)[1]
	var actors := _build_replacers(head_section.split("\n"))
	#print(actors)
	#printt(head_section, actors, text)
	#print(text)
	#print(text.contains("PAGE\n"))
	#return
	var pages := text.split("PAGE", false)
	var returns := Array(text.split("\n", false))
	var constructed_page := ""
	#print(returns)
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
		
	#for line in returns:
		#printt(line == "PAGE", line == "PAGE\n", line)
		#if line == "PAGE":
			#real_pages.append(constructed_page)
	#print(pages)
	#print(real_pages)
	#return
	for page in real_pages:
		print("PAGE ", page)
		await get_tree().process_frame
		Pages.editor.request_add_page_after_current()
		await get_tree().process_frame
		var lines : PackedStringArray = page.split("CONTENT\n")
		for line in lines:
			var formatted_text := format_text(str("CONTENT\n", line), actors)
			print(formatted_text)
			var line_obj := {
				"content" :  {
					"content" : formatted_text
				}
			}
			await get_tree().process_frame
			Pages.editor.add_line_to_end_of_page(line_obj)
			await get_tree().process_frame

## ## TODO

## 
## 
## 
## 
## In text format option to parse from file or clipboard
## 
## go by a single line of text only being PAGE or LINE
## 
## option to import entire file
## split at []>PAGE strings
## 
## and []>LINE strings
## then calls to the editor actions to add pagesat the veginning of itrrating ober each parsed []>PAGE chunk of the document 
## 
##  for and lines
