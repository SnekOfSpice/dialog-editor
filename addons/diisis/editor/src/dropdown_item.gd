@tool
extends VBoxContainer

var dropdown_options := []
var list_size:Vector2

func get_string_contents(filter:="") -> String:
	var search_content := ""
	var title_contents := str(find_child("TitleLabel").text, find_child("LineEdit").text)
	var option_contents := str("".join(dropdown_options), find_child("DropdownOptionsText").text)
	if filter.is_empty() or filter.to_lower() == "t":
		search_content += title_contents
	if filter.is_empty() or filter.to_lower() == "o":
		search_content += option_contents
	return search_content

func init(title:String):
	find_child("TitleLabel").text = title
	find_child("LineEdit").text = title
	find_child("EditContainer").visible = false
	find_child("OptionsContainer").visible = false
	dropdown_options = Pages.dropdowns.get(title)

func _on_edit_button_pressed() -> void:
	find_child("EditContainer").visible = true
	find_child("DisplayContainer").visible = false


func _on_save_title_button_pressed() -> void:
	var from : String = find_child("TitleLabel").text
	var to : String = find_child("LineEdit").text
	find_child("TitleLabel").text = to
	find_child("EditContainer").visible = false
	find_child("DisplayContainer").visible = true
	var undo_redo = Pages.editor.undo_redo
	undo_redo.create_action("Rename Dropdown Title")
	undo_redo.add_do_method(DiisisEditorActions.rename_dropdown_title.bind(from, to))
	undo_redo.add_undo_method(DiisisEditorActions.rename_dropdown_title.bind(to, from))
	undo_redo.commit_action()


func _on_discard_title_button_pressed() -> void:
	find_child("LineEdit").text = find_child("TitleLabel").text
	find_child("EditContainer").visible = false
	find_child("DisplayContainer").visible = true


func _on_line_edit_text_changed(new_text: String) -> void:
	find_child("SaveOptionsButton").disabled = find_child("TitleLabel").text != find_child("LineEdit").text
	if Pages.dropdown_titles.has(new_text):
		if new_text != find_child("TitleLabel").text:
			find_child("SaveTitleButton").disabled = true
			return
	find_child("SaveTitleButton").disabled = false


func _on_expand_button_toggled(toggled_on: bool) -> void:
	if toggled_on:
		find_child("DropdownOptionsText").text = "\n".join(dropdown_options)
		find_child("OptionsContainer").visible = true
	else:
		find_child("OptionsContainer").visible = false


func _on_dropdown_options_text_text_changed() -> void:
	var entered_args = find_child("DropdownOptionsText").text.split("\n")
	var args := []
	for arg : String in entered_args:
		if not arg.is_empty():
			args.append(arg)
	if "".join(args) == "".join(dropdown_options):
		find_child("SaveOptionsButton").text = "save options"
		find_child("ExpandButton").disabled = false
	else:
		find_child("SaveOptionsButton").text = "save options (*)"
		find_child("ExpandButton").disabled = find_child("EditContainer").visible
	

func _on_discard_options_button_pressed() -> void:
	find_child("DropdownOptionsText").text = "\n".join(dropdown_options)
	find_child("ExpandButton").disabled = false


func _on_save_options_button_pressed() -> void:
	var replace_speaker = not Input.is_key_pressed(KEY_SHIFT)
	var entered_args = find_child("DropdownOptionsText").text.split("\n")
	var args := []
	for arg : String in entered_args:
		if not arg.is_empty():
			args.append(arg)
	var title = find_child("TitleLabel").text
	var undo_redo = Pages.editor.undo_redo
	dropdown_options = args
	undo_redo.create_action("Change Dropdown Options")
	undo_redo.add_do_method(DiisisEditorActions.set_dropdown_options.bind(title, args, replace_speaker))
	undo_redo.add_undo_method(DiisisEditorActions.set_dropdown_options.bind(title, dropdown_options, replace_speaker))
	undo_redo.commit_action()
	
	find_child("OptionsContainer").visible = false
	find_child("ExpandButton").disabled = false




func _on_edit_container_visibility_changed() -> void:
	find_child("SaveOptionsButton").disabled = find_child("EditContainer").visible


func _on_options_container_visibility_changed():
	if find_child("OptionsContainer").visible:
		find_child("ExpandButton").text = "v"
	else:
		find_child("ExpandButton").text = ">"


func _on_dropdown_options_text_resized() -> void:
	var text_box_size : Vector2 = find_child("DropdownOptionsText").size
	if text_box_size.y <= list_size.y - 80 * Pages.editor.content_scale:
		find_child("ScrollContainer").custom_minimum_size.y = text_box_size.y
	else:
		find_child("ScrollContainer").custom_minimum_size.y = list_size.y - 80 * Pages.editor.content_scale


func set_list_size(s: Vector2):
	list_size = s
	_on_dropdown_options_text_resized()
