extends Node


var head_defaults := [
#	{
#		"property_name": "speaker",
#		"value":"narrator",
#		"data_type": DataTypes._String
#	},
#	{
#		"property_name": "emotion",
#		"value":"happy",
#		"data_type": DataTypes._String
#	},
]


var dropdowns := {"dropdown1": ["0", "1"], "dropdown2": ["a", "b"]}
var dropdown_titles := ["dropdown1", "dropdown2"]
var dropdown_dialog_arguments := []

var facts := {}

# TODO: code highlighting
# true / false take precedent
# only numerical input gets converted to int
# if exactly one period in numerical, convert to float
# else string
# also convert to string if in single or double quotes
var instruction_templates := [
	{
		"name": "show-character",
		"args": [
			"character-name",
			"clear-others"
		]
	}
]

enum DataTypes {_String, _Integer, _Float, _Array, _Dictionary, _DropDown, _Boolean}
const DATA_TYPE_STRINGS := {
	DataTypes._String : "String",
	DataTypes._Integer : "Integer",
	DataTypes._Float : "Float",
	DataTypes._Array : "Array",
	DataTypes._Dictionary : "Dictionary",
	DataTypes._DropDown : "Drop Down",
	DataTypes._Boolean : "Boolean",
}

var head_data_types := {
	"speaker": DataTypes._DropDown,
	"emotion": DataTypes._String,
}

var editor

# {"number":1, "page_key":"lmao", "lines": [], "terminate": false}
# data: {}
var page_data := {}

#var page_count := 0


signal pages_modified

func get_page_count() -> int:
	return page_data.size()

func create_page(number:int, overwrite_existing:= false):
	if page_data.keys().has(number) and not overwrite_existing:
		push_warning(str("page_data already has page with number ", number))
		return
	page_data[number] = {
		"number": number,
		"page_key": "",
		"lines": [],
		"next": number + 1
	}
	
	emit_signal("pages_modified")
	
	change_page_references_dir(number, 1)

func swap_pages(page_a: int, page_b: int):
	if not (page_data.keys().has(page_a) and page_data.keys().has(page_b)):
		return
	
	swap_page_references(page_a, page_b)
	
	var data_a = page_data.get(page_a)
	var data_b = page_data.get(page_b)
	data_b["number"] = page_a
	data_a["number"] = page_b
	page_data[page_a] = data_b
	page_data[page_b] = data_a
	
	

func swap_page_references(from: int, to: int):
	for page in page_data.values():
		var next = page.get("next")
		if next == from:
			page["next"] = to
		elif next == to:
			page["next"] = from
		
		for line in page.get("lines"):
			if line.get("line_type") == Data.LineType.Choice:
				var content = line.get("content")
				for choice in content.get("choices"):
					if choice.get("target_page") == from:
						choice["target_page"] = to
					elif choice.get("target_page") == to:
						choice["target_page"] = from
	

func get_lines(page_number: int):
	return page_data.get(page_number).get("lines")

func change_page_references_dir(changed_page: int, operation:int):
	
	# this works for everything but the currently loaded pages
	for page in page_data.values():
		var next = page.get("next")
		if next >= changed_page:
			page["next"] = next + operation
		
		
		for line in page.get("lines"):
			if line.get("line_type") == Data.LineType.Choice:
				var content = line.get("content")
				var choices = content.get("choices")
				for choice in choices:
					if choice.get("target_page") >= changed_page:
						choice["target_page"] = choice.get("target_page") + operation
	
	# idk what this is but it doesn't work. doesn't matter tho lmao
#	if editor:
#		editor.refresh()

func key_exists(key: String) -> bool:
	if key == "":
		return false
	
	for i in page_data.size():
		if page_data.get(i).get("page_key") == key:
			return true
	
	return false


func insert_page(at: int):
	# reindex all after at
	for i in range(get_page_count() - 1, at - 1, -1):
		var data = page_data.get(i)
		var new_number = i + 1#data.get("number") + 1
		data["number"] = new_number
		page_data[new_number] = data
	
	# insert page
	create_page(at, true)

func delete_page(at: int):
	if not page_data.keys().has(at):
		push_warning(str("could not delete page ", at, " because it doesn't exist"))
		return
	
	# reindex all after at, this automatically overwrites the page at at
	for i in range(at + 1, get_page_count()):
		var data = page_data.get(i)
		var new_number = data.get("number") - 1
		data["number"] = new_number
		page_data[i] = data
	
	# the last page is now a duplicate
	page_data.erase(get_page_count() - 1)
	emit_signal("pages_modified")
	
	change_page_references_dir(at, -1)


func get_defaults(property_key:String):
	for p in head_defaults:
		if p.get("property_name") == property_key:
			return p
	
	return {
		"name": "empty-instruction",
		"value":"defaultvalue",
		"data_type":DataTypes._String
	}

func get_all_instruction_names() -> Array:
	var result := []
	for p in instruction_templates:
		result.append(p.get("name", ""))
	
	return result

func get_instruction_args(instruction_name: String) -> Array:
	for p in instruction_templates:
		if p.get("name", "") == instruction_name:
			return p.get("args", [])
	
	return []

func get_all_invalid_instructions() -> String:
	var warning := ""
	
	var overdefined_instructions := []
	var underdefined_instructions := []
	var malformed_instructions := []
	for i in page_data:
		var lines = page_data.get(i).get("lines")
		var j = 0
		for l in lines:
			if l.get("line_type") != Data.LineType.Instruction:
				j += 1
				continue
			
			var content = l.get("content", {})
			var instruction_name = content.get("name")
			var instruction_args : Array = content.get("content")
			
			if instruction_args.size() != get_instruction_args(instruction_name).size():
				malformed_instructions.append(str(i, ".", j))
			
			for arg in instruction_args:
				if arg.get("value", "").begins_with("underdefined"):
			#if instruction_args.size() != get_instruction_args(instruction_name).size():
					underdefined_instructions.append(str(i, ".", j))
				elif arg.get("name", "").begins_with("overdefined"):
					overdefined_instructions.append(str(i, ".", j))
			j += 1

	if not underdefined_instructions.is_empty():
		warning = "Warning: underdefined instructions at: "
		for inv in underdefined_instructions:
			warning += inv
			warning += ", "
		warning = warning.trim_suffix(", ")
	
	if not warning.is_empty():
		warning += "\n"
	
	if not overdefined_instructions.is_empty():
		warning += "Warning: overdefined instructions at: "
		for inv in overdefined_instructions:
			warning += inv
			warning += ", "
		warning = warning.trim_suffix(", ")
	
	if not warning.is_empty():
		warning += "\n"
	
	if not malformed_instructions.is_empty():
		warning += "Warning: malformed instructions at: "
		for inv in malformed_instructions:
			warning += inv
			warning += ", "
		warning = warning.trim_suffix(", ")
	
	return warning

# new schema with keys and values
func apply_new_header_schema(new_schema: Array):
	for i in page_data:
		var lines = page_data.get(i).get("lines")
		
		for line in lines:
			print(Pages.page_data)
			prints("PRETRANSFORM-", line["header"], " SCHEMA-> ", new_schema)
			line["header"] = transform_header(line.get("header"), new_schema, head_defaults)
			prints("POSTTRANSFORM-", line["header"])
	
	
	editor.refresh()
	head_defaults = new_schema


func transform_header(header_to_transform: Array, new_schema: Array, old_schema):
	# TODO: use sort_custom and add an index to each head property to make this flexible when changing head defaults
	var transformed = []
	transformed.resize(new_schema.size())
	
#	
	
	for i in min(old_schema.size(), new_schema.size()):
		var old_name = header_to_transform[i].get("property_name")
		var old_value = header_to_transform[i].get("values", [header_to_transform[i].get("value", null), null])
		var old_type = header_to_transform[i].get("data_type")
		var old_default = old_schema[i].get("values")
		
		var new_name = new_schema[i].get("property_name")
		var new_value = new_schema[i].get("values", [header_to_transform[i].get("value", null), null])
		var new_type = new_schema[i].get("data_type")
		
		printt(old_name, old_value, old_type)
		printt(old_default)
		printt(new_name, new_value, new_type)
		
		
		
		# if the header was the default value here, just apply the new default schema
		if old_value[0] == old_default[0] and old_value[1] == old_default[1]:
			transformed[i] = new_schema[i]
		# the old value wasn't the default...
		else:
			
			var a = new_value
			if new_value[0] != old_value[0] or new_value[1] != old_value[1]:
				a = old_value
			
			var converted_value = {
				"property_name": new_name,
				"values": a,
				"data_type": new_type,
			}
			prints("converting ", header_to_transform[i], " to ", converted_value)
			transformed[i] = converted_value
			
			
	
	# idk this seems bad
	for j in transformed.size():
		if transformed[j] == null:
			transformed[j] = new_schema[j]
	
	return transformed


#func register_facts():
#	for page in page_data.values():
#		for line in page.get("lines", []):
#			for fact in line.get("facts", {}).keys():
#				if not facts.has(fact):
#					facts.append(fact)
		
	# step over every fact in page data and save its name

func lines_referencing_fact(fact_name: String):
	fact_name = fact_name.split(":")[0]
	var ref_pages := []
	var ref_lines_declare := []
	var ref_lines_condition := []
	var ref_lines_choice_declare := []
	var ref_lines_choice_condition := []
	for page in page_data.values():
		for i in page.get("lines", []).size():
			var line = page.get("lines")[i]
			for fact in line.get("facts", {}).keys():
				if fact == fact_name: #also untested atm
					if not ref_pages.has(page.get("number")):
						ref_pages.append(page.get("number"))
					ref_lines_declare.append(str(page.get("number"), ".", i))
			if line.get("line_type") == Data.LineType.Choice:
				var options = line.get("content")
				for option in options.get("choices", {}):
					for fact in option.get("conditionals", {}).get("facts", {}):
						if fact == fact_name:
							if not ref_pages.has(page.get("number")):
								ref_pages.append(page.get("number"))
							ref_lines_choice_condition.append(str(page.get("number"), ".", i))
					for fact in option.get("facts", {}).keys():
						if fact == fact_name: #also untested atm
							if not ref_pages.has(page.get("number")):
								ref_pages.append(page.get("number"))
							ref_lines_choice_declare.append(str(page.get("number"), ".", i))
			for fact in line.get("conditionals", {}).get("facts", {}):
				if fact == fact_name:
					if not ref_pages.has(page.get("number")):
						ref_pages.append(page.get("number"))
					ref_lines_condition.append(str(page.get("number"), ".", i))
	
	var all_refs := {
		"ref_pages": ref_pages,
		"ref_lines_declare": ref_lines_declare,
		"ref_lines_condition": ref_lines_condition,
		"ref_lines_choice_declare": ref_lines_choice_declare,
		"ref_lines_choice_condition": ref_lines_choice_condition
	}
	return all_refs


func character_count_on_page_approx(page_number: int) -> int:
	var count := 0
	for line in page_data.get(page_number, {}).get("lines", []):
		var line_type = line.get("line_type")
		var content = line.get("content")
		match line_type:
			Data.LineType.Choice:
				for choice in content.get("choices"):
					count += str(choice.get("choice_text.enabled")).length()
					count += str(choice.get("choice_text.disabled")).length()
			Data.LineType.Text:
				count += str(content.get("content")).length()
	return count

func word_count_on_page_approx(page_number: int) -> int:
	var count := 0
	for line in page_data.get(page_number, {}).get("lines", []):
		var line_type = line.get("line_type")
		var content = line.get("content")
		match line_type:
			Data.LineType.Choice:
				for choice in content.get("choices"):
					count += str(choice.get("choice_text.enabled")).count(" ") + 1
					count += str(choice.get("choice_text.disabled")).count(" ") + 1
			Data.LineType.Text:
				count += str(content.get("content")).count(" ") + 1
	return count

func character_count_total_approx() -> int:
	var sum := 0
	for i in page_data.keys():
		sum += character_count_on_page_approx(i)
	
	return sum
func word_count_total_approx() -> int:
	var sum := 0
	for i in page_data.keys():
		sum += word_count_on_page_approx(i)
	
	return sum

#func speaking_characters_on_page(page_number: int) -> Array:
#	var result = []
#
#	return result
