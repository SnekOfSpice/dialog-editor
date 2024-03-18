@tool
extends Window


var working_memory_dropdowns := {}
var working_memory_titles := []

func fill():
	working_memory_dropdowns = Pages.dropdowns.duplicate(true)
	working_memory_titles = Pages.dropdown_titles.duplicate(true)
	
	for t in find_child("DropDownTabContainer").get_children():
		t.queue_free()
	
	for t in working_memory_titles:
		add_code_edit(t)
	
	fill_code_edit(working_memory_titles.back())
	
	#find_child("DropDownTabContainer").set_current_tab(working_memory_titles.back())
	#find_child("DropDownTabContainer").set_tab_title(find_child("DropDownTabContainer").current_tab, working_memory_titles.back())

func fill_code_edit(tab_title: String):
	var s = ""
	for c in working_memory_dropdowns.get(tab_title, []):
		s += str(c)
		s += "\n"
	#find_child("DropDownTabContainer").set_current_tab(working_memory_titles.find(tab_title))
	find_child("DropDownTabContainer").get_current_tab_control().text = s
	

func get_current_title():
	return find_child("DropDownTabContainer").get_tab_title(find_child("DropDownTabContainer").current_tab)

func save_current_text():
	var options = find_child("DropDownTabContainer").get_current_tab_control().text.split("\n")
	working_memory_dropdowns[get_current_title()] = options


func _on_about_to_popup() -> void:
	fill()

func _on_close_requested() -> void:
	hide()

func add_code_edit(tab_title: String):
	if not working_memory_titles.has(tab_title):
		working_memory_titles.append(tab_title)
		working_memory_dropdowns[tab_title] = []
	var bar = find_child("DropDownTabContainer")
	var ce = CodeEdit.new()
	bar.add_child(ce)
	
	bar.set_current_tab(bar.get_tab_count()-1)
	bar.set_tab_title(bar.current_tab, tab_title)
	
	find_child("NameEdit").text = tab_title
	
#	save_tab_name()
	
	find_child("SaveNameButton").visible = working_memory_titles.size() > 0
	find_child("SaveContentButton").visible = working_memory_titles.size() > 0

func _on_add_button_pressed() -> void:
	var tab_title = str("untitled", find_child("DropDownTabContainer").get_tab_count()-1)
	add_code_edit(tab_title)
	fill_code_edit(tab_title)



func _on_save_button_pressed() -> void:
	var cleaned_dropdowns := {}
	for dd in working_memory_dropdowns.keys():
		if working_memory_titles.has(dd):
			cleaned_dropdowns[dd] = working_memory_dropdowns.get(dd)
	working_memory_dropdowns = cleaned_dropdowns
	Pages.dropdowns = working_memory_dropdowns.duplicate(true)
	Pages.dropdown_titles = working_memory_titles.duplicate(true)




func _on_tab_container_tab_changed(tab: int) -> void:
	if tab == 1:
		save_tab_name()
		save_current_text()
		Pages.dropdowns = working_memory_dropdowns.duplicate(true)
		Pages.dropdown_titles = working_memory_titles.duplicate(true)
	


#func _on_tab_container_tab_selected(tab: int) -> void:
#	return
#	var i = working_memory_titles.size()#find_child("DropDownTabContainer").get_tab_count()
#	while i <= tab:
#		working_memory_titles.append(str("untitled", i))
#		i += 1
#
#	find_child("NameEdit").text = find_child("DropDownTabContainer").get_tab_title(tab)

#func sync_tab_working_titles():
#	for i in find_child("DropDownTabContainer").get_tab_count():
#		working_memory_titles[i] = find_child("DropDownTabContainer").get_tab_title(i)

func _on_save_name_button_pressed() -> void:
	save_tab_name()

func save_tab_name():
	if find_child("DropDownTabContainer").get_tab_count() <= 0:
		find_child("NameEdit").text = ""
		return
	
	var current_tab = find_child("DropDownTabContainer").current_tab
	find_child("DropDownTabContainer").set_tab_title(find_child("DropDownTabContainer").current_tab, find_child("NameEdit").text)
#	while current_tab > working_memory_titles.size():
#		working_memory_titles.append(str("whatever", working_memory_titles.size()))
#		working_memory_dropdowns[str("whatever", working_memory_titles.size())] = []
	if current_tab > working_memory_titles.size() - 1:
		working_memory_titles.resize(current_tab)
	working_memory_titles[current_tab] = find_child("NameEdit").text
	


func _on_remove_button_pressed() -> void:
	if not find_child("DropDownTabContainer").get_current_tab_control():
		return 
	
	working_memory_dropdowns.erase(working_memory_titles[find_child("DropDownTabContainer").current_tab])
	working_memory_titles.erase(working_memory_titles[find_child("DropDownTabContainer").current_tab])
	find_child("DropDownTabContainer").get_current_tab_control().queue_free()
	
	if find_child("DropDownTabContainer").get_tab_count() <= 0:
		find_child("NameEdit").text = ""
		
	find_child("SaveNameButton").visible = working_memory_titles.size() > 0
	find_child("SaveContentButton").visible = working_memory_titles.size() > 0


func _on_save_content_button_pressed() -> void:
	save_current_text()

func fill_dialog_argument_checkboxes():
	for c in find_child("DialogArguments").get_children():
		c.queue_free()
	
	for t in Pages.dropdown_titles:
		var cb = preload("res://addons/diisis/editor/src/labeled_check_box.tscn").instantiate()
		find_child("DialogArguments").add_child(cb)
		cb.text = t
		cb.button_pressed = Pages.dropdown_dialog_arguments.has(t)
		cb.labeled_pressed.connect(toggle_dropdown_dialog_argument)

func toggle_dropdown_dialog_argument(dropdown_title: String, value: bool):
	if value:
		if not Pages.dropdown_dialog_arguments.has(dropdown_title):
			Pages.dropdown_dialog_arguments.append(dropdown_title)
	else:
		if Pages.dropdown_dialog_arguments.has(dropdown_title):
			Pages.dropdown_dialog_arguments.erase(dropdown_title)


func _on_dialog_arguments_visibility_changed() -> void:
	fill_dialog_argument_checkboxes()


func _on_drop_down_tab_container_tab_changed(tab: int) -> void:
	var i = working_memory_titles.size()#find_child("DropDownTabContainer").get_tab_count()
#	while i < tab:
#		working_memory_titles.append(str("untitled", i))
#		i += 1
	
	#working_memory_titles[find_child("DropDownTabContainer").get_previous_tab()] = find_child("NameEdit").text
	find_child("NameEdit").text = find_child("DropDownTabContainer").get_tab_title(tab)
	
#	if tab == find_child("DropDownTabContainer").get_previous_tab():
	fill_code_edit(find_child("DropDownTabContainer").get_tab_title(tab))
