extends VBoxContainer
class_name Page

var number := 0
var page_key := ""


func init(n:=number):
	var data = Pages.page_data.get(n)
	set_page_key(data.get("page_key"))
	number = n
	$Info/Number.text = str(n)
	deserialize(data.get("data"))

func set_page_key(key: String):
	page_key = key
	$Info/PageKey.text = page_key

func deserialize(page_data: Dictionary):
	# instantiate lines
	print(page_data)
	
	enable_page_key_edit(false)

func clear():
	for c in get_children():
		c.queue_free()

func save():
	Pages.page_data[number] = serlialize()

func serlialize() -> Dictionary:
	var data := {}
	
	data["number"] = number
	data["page_key"] = page_key
	
	var lines_data := {}
	data["data"] = lines_data
	
	return data

func _on_page_key_edit_pressed() -> void:
	pass # Replace with function body.

func enable_page_key_edit(value: bool):
	$Info/PageKey.visible = not value
	$Info/PageKeyLineEdit.visible = value
	$Info/PageKeyLineEdit.text = page_key
	
	$Info/Seperator.visible = page_key != ""

func _on_page_key_edit_button_toggled(button_pressed: bool) -> void:
	if not button_pressed:
		# add check for duplicates later
		set_page_key($Info/PageKeyLineEdit.text)
		save()
	
	enable_page_key_edit(button_pressed)


func _on_page_key_line_edit_text_changed(new_text: String) -> void:
	$Info/PageKeyEditButton.disabled = Pages.key_exists(new_text)
