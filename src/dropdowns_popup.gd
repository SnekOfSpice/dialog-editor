extends Window


var working_memory_dropdowns := {}
var working_memory_titles := []

func fill():
	working_memory_dropdowns = Pages.dropdowns
	working_memory_titles = Pages.dropdown_titles
	var s = ""
	for c in Pages.characters:
		s += str(c)
		s += "\n"

func fill_code_edit(tab_title: String):
	var s = ""
	for c in working_memory_dropdowns.get(tab_title, []):
		s += str(c)
		s += "\n"
	find_child("TabContainer").get_current_tab_control().text = s


func save_dropdowns():
	for c in find_child("TabContainer").get_children():
		c.text.split("\n")

func _on_about_to_popup() -> void:
	fill()

func _on_close_requested() -> void:
	#Pages.characters = text2arr()
	hide()


func _on_add_button_pressed() -> void:
	var bar = find_child("TabContainer")
	var tab_title = str("untitled", bar.get_tab_count()-1)
	var ce = CodeEdit.new()
	bar.add_child(ce)
	
	bar.set_current_tab(bar.get_tab_count()-1)
	bar.set_tab_title(bar.current_tab, tab_title)
	
	
	find_child("NameEdit").text = tab_title
	
	save_tab_name()
	
	fill_code_edit(tab_title)




func _on_save_button_pressed() -> void:
	Pages.dropdowns = working_memory_dropdowns
	Pages.dropdown_titles = working_memory_titles




func _on_tab_container_tab_changed(tab: int) -> void:
	var i = working_memory_titles.size()#find_child("TabContainer").get_tab_count()
	while i <= tab:
		working_memory_titles.append(str("untitled", i))
		i += 1
	
	#working_memory_titles[find_child("TabContainer").get_previous_tab()] = find_child("NameEdit").text
	find_child("NameEdit").text = find_child("TabContainer").get_tab_title(tab)
	
	fill_code_edit(find_child("TabContainer").get_tab_title(tab))


func _on_tab_container_tab_selected(tab: int) -> void:
	var i = working_memory_titles.size()#find_child("TabContainer").get_tab_count()
	while i <= tab:
		working_memory_titles.append(str("untitled", i))
		i += 1
	
	find_child("NameEdit").text = find_child("TabContainer").get_tab_title(tab)

#func sync_tab_working_titles():
#	for i in find_child("TabContainer").get_tab_count():
#		working_memory_titles[i] = find_child("TabContainer").get_tab_title(i)

func _on_save_name_button_pressed() -> void:
	save_tab_name()

func save_tab_name():
	if find_child("TabContainer").get_tab_count() <= 0:
		find_child("NameEdit").text = ""
		return
	
	
	find_child("TabContainer").set_tab_title(find_child("TabContainer").current_tab, find_child("NameEdit").text)
	working_memory_titles[find_child("TabContainer").current_tab] = find_child("NameEdit").text
	


func _on_remove_button_pressed() -> void:
	working_memory_dropdowns.erase(working_memory_titles[find_child("TabContainer").current_tab])
	working_memory_titles.erase(working_memory_titles[find_child("TabContainer").current_tab])
	find_child("TabContainer").get_current_tab_control().queue_free()
	
	if find_child("TabContainer").get_tab_count() <= 0:
		find_child("NameEdit").text = ""

func get_current_title():
	return find_child("TabContainer").get_tab_title(find_child("TabContainer").current_tab)

func save_current_text():
	var options = find_child("TabContainer").get_current_tab_control().text.split("\n")
	working_memory_dropdowns[get_current_title()] = options

func _on_save_content_button_pressed() -> void:
	save_current_text()
