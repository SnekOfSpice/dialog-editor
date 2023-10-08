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


# {"number":1, "page_key":"lmao", "data": {}}
# data: {}
var page_data := {}

#var page_count := 0

func get_page_count() -> int:
	return page_data.size()

func create_page(number:int):
	if page_data.keys().has(number):
		push_warning(str("page_data already has page with number ", number))
		return
	prints("creating page ", number)
	page_data[number] = {
		"number":number,
		"page_key":"",
		"data": {}
	}

func get_lines(page_number: int):
	return page_data.get(page_number).get("data")


func key_exists(key: String) -> bool:
	if key == "":
		return false
	
	for i in page_data.size():
		if page_data.get(i).get("page_key") == key:
			return true
	
	return false
