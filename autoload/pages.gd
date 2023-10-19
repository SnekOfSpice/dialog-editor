extends Node


var head_defaults := [
	{
		"property_name": "speaker",
		"value":"narrator",
		"data_type": DataTypes._String
	},
	{
		"property_name": "emotion",
		"value":"happy",
		"data_type": DataTypes._String
	},
]


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

enum DataTypes {_String, _Integer, _Float, _Array, _Dictionary}
const DATA_TYPE_STRINGS := {
	DataTypes._String : "String",
	DataTypes._Integer : "Integer",
	DataTypes._Float : "Float",
	DataTypes._Array : "Array",
	DataTypes._Dictionary : "Dictionary",
}

var head_data_types := {
	"speaker": DataTypes._String,
	"emotion": DataTypes._String,
}

var editor

# {"number":1, "page_key":"lmao", "lines": []}
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
	prints("creating page ", number)
	page_data[number] = {
		"number":number,
		"page_key":"",
		"lines": []
	}
	
	emit_signal("pages_modified")

func get_lines(page_number: int):
	return page_data.get(page_number).get("lines")


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
		#prints("reindexing ", i, " to ", new_number)
	
	# the last page is now a duplicate
	print(page_data.size())
	page_data.erase(get_page_count() - 1)
	print(page_data.size())
	emit_signal("pages_modified")


func get_defaults(property_key:String):
	for p in head_defaults:
		if p.get("property_name") == property_key:
			return p
	
	return {
		"name": "empty-instruction",
		"value":"defaultvalue",
		"data_type":DataTypes._String
	}

func get_instruction_args(instruction_name: String):
	for p in instruction_templates:
		if p.get("name") == instruction_name:
			return p.get("args")
	
	return []

# new schema with keys and values
func apply_new_header_schema(new_schema: Array):
	for i in page_data:
		var lines = page_data.get(i).get("lines")
		#print(lines)
		
		for line in lines:
			print(Pages.page_data)
			prints("PRETRANSFORM-", line["header"], " SCHEMA-> ", new_schema)
			line["header"] = transform_header(line.get("header"), new_schema, head_defaults)
			prints("POSTRTRANSFORM-", line["header"])
	
	
	editor.refresh()
	head_defaults = new_schema


func transform_header(header_to_transform: Array, new_schema: Array, old_schema):
	# TODO: use sort_custom and add an index to each head property to make this flexible when changing head defaults
	var transformed = []
	transformed.resize(new_schema.size())
	
#	# transpose all with same property_name
#	for old_prop in old:
#		var old_name = old_prop.get("property_name")
#		var old_value = old_prop.get("value")
#		var old_type = old_prop.get("data_type")
#
#		for new_prop in new:
#			var new_name = new_prop.get("property_name")
#			var new_value = new_prop.get("value")
#			var new_type = new_prop.get("data_type")
#
#			if new_name == old_name:
#				if new_type == old_type:
#					# preserve old if it differs from the default value
#			else:
#				transformed.append(new_prop)
	
	for i in min(old_schema.size(), new_schema.size()):
		var old_name = header_to_transform[i].get("property_name")
		var old_value = header_to_transform[i].get("value")
		var old_type = header_to_transform[i].get("data_type")
		var old_default = old_schema[i].get("value")
		
		var new_name = new_schema[i].get("property_name")
		var new_value = new_schema[i].get("value")
		var new_type = new_schema[i].get("data_type")
		
		printt(old_name, old_value, old_type)
		printt(old_default)
		printt(new_name, new_value, new_type)
		
		
		
		# if the header was the default value here, just apply the new default schema
		if old_value == old_default:
			transformed[i] = new_schema[i]
		# the old value wasn't the default...
		else:
			# if the data type stayed the same, we assume the rest to also be adjusted accordingly
			var converted_value 
			
			
			# BIG TODO LMAO
			# TODO: handle type conversions,
			# for now lets just assume everything is a string
	
			match old_type:
				Pages.DataTypes._String:
					match new_type:
						Pages.DataTypes._Array:
							pass
						Pages.DataTypes._String:
							converted_value = header_to_transform[i].get("value")
						Pages.DataTypes._Dictionary:
							pass
						Pages.DataTypes._Float:
							pass
						Pages.DataTypes._Integer:
							pass
			
			
			transformed[i] = {
					"property_name": new_name,
					"value": converted_value,
					"data_type": new_type
				}
	
	# idk this seems bad
	for j in transformed.size():
		if transformed[j] == null:
			transformed[j] = new_schema[j]
	
	return transformed
