@tool
extends Control

var working_memory_dropdowns := {}
var working_memory_titles := []

func init():
	find_child("AddButton").disabled = true
	working_memory_dropdowns = Pages.dropdowns.duplicate(true)
	working_memory_titles = Pages.dropdown_titles.duplicate(true)
	
	
	for t in find_child("DropdownsContainer").get_children():
		t.queue_free()
	
	for t in working_memory_titles:
		var item = preload("res://addons/diisis/editor/src/dropdown_item.tscn").instantiate()
		item.init(t)
		find_child("DropdownsContainer").add_child(item)
		item.set_list_size(Pages.editor.get_window().size * 0.25)
	
	_on_clear_search_button_pressed()
	Pages.apply_font_size_overrides(self)

func fill_code_edit(tab_title: String):
	var s = ""
	for c in working_memory_dropdowns.get(tab_title, []):
		s += str(c)
		s += "\n"
	
	find_child("DropDownTabContainer").get_current_tab_control().text = s


func fill_dialog_argument_checkboxes():
	for c in find_child("Dialog").get_children():
		c.queue_free()
	
	var items := []
	for dd_title : String in Pages.dropdown_titles:
		var cb = preload("res://addons/diisis/editor/src/dialog_argument_dropdown_item.tscn").instantiate()
		find_child("Dialog").add_child(cb)
		cb.init(dd_title)
		cb.argument_pressed.connect(toggle_dropdown_dialog_argument)
		cb.syntax_pressed.connect(set_dialog_syntax_dropdown)
		items.append(cb)
	
	for item in items:
		item.set_syntax_button_group(load("res://addons/diisis/editor/src/dialog_argument_syntax_button_group.tres"))
	Pages.apply_font_size_overrides(self)

func toggle_dropdown_dialog_argument(dropdown_title: String, value: bool):
	if value:
		if not Pages.dropdown_dialog_arguments.has(dropdown_title):
			Pages.dropdown_dialog_arguments.append(dropdown_title)
	else:
		if Pages.dropdown_dialog_arguments.has(dropdown_title):
			Pages.dropdown_dialog_arguments.erase(dropdown_title)

func set_dialog_syntax_dropdown(dropdown_title:String):
	Pages.dropdown_title_for_dialog_syntax = dropdown_title

func _on_create_dd_name_text_edit_text_changed(new_text: String) -> void:
	find_child("AddButton").disabled = Pages.is_new_dropdown_title_invalid(new_text)


func _on_clear_search_button_pressed() -> void:
	find_child("SearchLineEdit").text = ""
	_on_search_line_edit_text_changed("")


func _on_search_line_edit_text_changed(new_text: String) -> void:
	if new_text.is_empty():
		for child in find_child("DropdownsContainer").get_children():
			child.visible = true
		return
	for child in find_child("DropdownsContainer").get_children():
		var filter:String
		var search_term:String
		if new_text.contains(":"):
			filter = new_text.split(":")[0]
			search_term = new_text.split(":")[1]
		else:
			filter = ""
			search_term = new_text
		child.visible = child.get_string_contents(filter).contains(search_term)


func _on_dialog_syntax_visibility_changed():
	fill_dialog_argument_checkboxes()


func create_new_dropdown() -> void:
	var dd_title : String = find_child("CreateDDNameTextEdit").text
	if dd_title.is_empty() or find_child("AddButton").disabled:
		return
	Pages.dropdowns[dd_title] = []
	Pages.dropdown_titles.append(dd_title)
	var item = preload("res://addons/diisis/editor/src/dropdown_item.tscn").instantiate()
	item.init(dd_title)
	find_child("DropdownsContainer").add_child(item)
	item.set_list_size(Pages.editor.get_window().size * 0.25)
	find_child("CreateDDNameTextEdit").text = ""
	Pages.apply_font_size_overrides(self)


func _on_dropdowns_container_resized() -> void:
	for child in find_child("DropdownsContainer").get_children():
		child.set_list_size(Pages.editor.get_window().size * 0.25)


func _on_create_dd_name_text_edit_text_submitted(_new_text: String) -> void:
	create_new_dropdown()
	find_child("AddButton").disabled = true


func _on_definitions_visibility_changed() -> void:
	if not find_child("Definitions").visible:
		return
	
	for child in find_child("DropdownsContainer").get_children():
		child.update_speaker_label()
