extends Node


var head_defaults := {
	"speaker":"narrator",
	"emotion":"happy",
}

enum DataTypes {_String, _Integer, _Float, _Array, _Dictionary}
var head_data_types := {
	"speaker": DataTypes._String,
	"emotion": DataTypes._String,
}


# {number:1, "page_key":"lmao", "data": {}}
var page_data := {}

#var page_count := 0

func get_page_count() -> int:
	return page_data.size()

func create_page(number:=get_page_count()):
	if page_data.keys().has(number):
		push_warning(str("page_data already has page with number ", number))
		return
	
	page_data[number] = {
		"head": head_defaults,
		"body": {}
	}
