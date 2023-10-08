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
		prints("reindexing ", i, " to ", new_number)
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
		data["number"] = data.get("number") - 1
		page_data[i] = data
	
	# the last page is now a duplicate
	page_data.erase(get_page_count())
	
	emit_signal("pages_modified")
