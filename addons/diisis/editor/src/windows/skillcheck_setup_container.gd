@tool
extends Control


func init():
	var starting_index := 0
	# we use size to ensure out of bounds of declared stringkits
	%StringkitOptionButton.add_item("None", Pages.stringkit_titles.size())
	var i := 0
	for title in Pages.stringkit_titles:
		%StringkitOptionButton.add_item(title, i)
		if title == Pages.stringkit_title_for_skillchecks:
			starting_index = i
		i += 1
	
	%StringkitOptionButton.select(starting_index)
	_rebuild()


func _rebuild():
	var title : String = Pages.stringkit_title_for_skillchecks
	if title.is_empty():
		%OptionList.text = ""
	else:
		%OptionList.text = "\n".join(Pages.stringkits.get(title))


func _on_stringkit_option_button_item_selected(index: int) -> void:
	var id : int = %StringkitOptionButton.get_item_id(index)
	if id == Pages.stringkit_titles.size():
		Pages.stringkit_title_for_skillchecks = ""
	else:
		Pages.stringkit_title_for_skillchecks = Pages.stringkit_titles[id]
	_rebuild()
