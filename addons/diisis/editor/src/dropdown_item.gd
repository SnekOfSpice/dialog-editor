@tool
extends VBoxContainer

var dropdown_options := []
var list_size:Vector2

func get_string_contents(filter:="") -> String:
	var search_content := ""
	var title_contents := str(find_child("TitleLabel").text, get_line_edit_text())
	var option_contents := str("".join(dropdown_options), find_child("DropdownOptionsText").text)
	if filter.is_empty() or filter.to_lower() == "t":
		search_content += title_contents
	if filter.is_empty() or filter.to_lower() == "o":
		search_content += option_contents
	return search_content

func update_speaker_label():
	var title : String = find_child("TitleLabel").text
	var is_speaker : bool = Pages.dropdown_title_for_dialog_syntax == title
	%ReplaceSpeakersCheckBox.visible = is_speaker
	%SpeakerNotice.visible = is_speaker

func init(title:String):
	find_child("TitleLabel").text = title
	find_child("LineEdit").text = title
	find_child("EditContainer").visible = false
	find_child("OptionsContainer").visible = false
	update_speaker_label()
	find_child("ReplaceInTextCheckBox").button_pressed = true
	%ReplaceSpeakersCheckBox.button_pressed = true
	find_child("Parameters").visible = false
	find_child("DuplicateOptionsLabel").visible = false
	find_child("DeleteParameters").visible = false
	find_child("DeleteParametersButton").visible = Pages.dropdown_dialog_arguments.has(title)
	dropdown_options = Pages.dropdowns.get(title)


func _on_edit_button_pressed() -> void:
	find_child("EditContainer").visible = true
	find_child("DisplayContainer").visible = false
	find_child("LineEdit").grab_focus()
	find_child("LineEdit").caret_column = find_child("LineEdit").text.length()

## trims leading and trailing spaces
func get_line_edit_text() -> String:
	var raw_text : String = find_child("LineEdit").text
	return DIISIS.trim_bilateral_spaces(raw_text)


func _on_save_title_button_pressed() -> void:
	var from : String = find_child("TitleLabel").text
	var to : String = get_line_edit_text()
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
	set_save_options_button_disabled((find_child("TitleLabel").text != get_line_edit_text()) or find_child("EditContainer").visible)
	if Pages.is_new_dropdown_title_invalid(DIISIS.trim_bilateral_spaces(new_text), find_child("TitleLabel").text):
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
	var entered_args := Array(find_child("DropdownOptionsText").text.split("\n"))
	var args := []
	var has_duplicate := false
	for arg : String in entered_args:
		arg = DIISIS.trim_bilateral_spaces(arg)
		if not arg.is_empty():
			if entered_args.count(arg) > 1:
				has_duplicate = true
				break
			args.append(arg)
	if has_duplicate:
		set_save_options_button_disabled(true)
		find_child("DuplicateOptionsLabel").visible = true
		return
	set_save_options_button_disabled((find_child("TitleLabel").text != get_line_edit_text()) or find_child("EditContainer").visible)
	find_child("DuplicateOptionsLabel").visible = false
	
	if "".join(args) == "".join(dropdown_options):
		find_child("SaveOptionsButton").text = "save options"
		find_child("ExpandButton").disabled = false
	else:
		find_child("SaveOptionsButton").text = "save options (*)"
		find_child("ExpandButton").disabled = find_child("EditContainer").visible
	

func _on_discard_options_button_pressed() -> void:
	var text_edit : TextEdit = find_child("DropdownOptionsText")
	var col = text_edit.get_caret_column()
	var line = text_edit.get_caret_line()
	
	find_child("DropdownOptionsText").text = "\n".join(dropdown_options)
	find_child("ExpandButton").disabled = false
	_on_dropdown_options_text_text_changed()
	
	text_edit.set_caret_column(col)
	text_edit.set_caret_line(line)


func _on_save_options_button_pressed() -> void:
	var replace_speaker : bool = %ReplaceSpeakersCheckBox.button_pressed
	var replace_in_text : bool = find_child("ReplaceInTextCheckBox").button_pressed
	var entered_args = find_child("DropdownOptionsText").text.split("\n")
	var args := []
	for arg : String in entered_args:
		arg = DIISIS.trim_bilateral_spaces(arg)
		if not arg.is_empty():
			args.append(arg)
	var title = find_child("TitleLabel").text
	var undo_redo = Pages.editor.undo_redo
	dropdown_options = args
	undo_redo.create_action("Change Dropdown Options")
	undo_redo.add_do_method(DiisisEditorActions.set_dropdown_options.bind(title, args, replace_in_text, replace_speaker))
	undo_redo.add_undo_method(DiisisEditorActions.set_dropdown_options.bind(title, dropdown_options, replace_in_text, replace_speaker))
	undo_redo.commit_action()
	
	find_child("OptionsContainer").visible = false
	find_child("ExpandButton").disabled = false


func _on_edit_container_visibility_changed() -> void:
	set_save_options_button_disabled(find_child("EditContainer").visible)

func set_save_options_button_disabled(value:bool):
	find_child("SaveOptionsButton").disabled = value
	find_child("SaveTitleWarning").visible = value

func _on_options_container_visibility_changed():
	if find_child("OptionsContainer").visible:
		find_child("ExpandButton").text = "q"
	else:
		find_child("ExpandButton").text = "n"


func _on_dropdown_options_text_resized() -> void:
	var text_box_size : Vector2 = find_child("DropdownOptionsText").size
	var scale_factor:float
	if Pages.editor:
		scale_factor = Pages.editor.content_scale
	else:
		scale_factor = 1
	if text_box_size.y <= list_size.y - 80 * scale_factor:
		find_child("ScrollContainer").custom_minimum_size.y = text_box_size.y
	else:
		find_child("ScrollContainer").custom_minimum_size.y = list_size.y - 80 * scale_factor


func set_list_size(s: Vector2):
	list_size = s
	_on_dropdown_options_text_resized()


func _on_replace_in_text_check_box_toggled(toggled_on: bool) -> void:
	%ReplaceSpeakersCheckBox.disabled = not toggled_on


func _on_save_parameters_button_pressed() -> void:
	find_child("Parameters").visible = not find_child("Parameters").visible


func _on_delete_button_pressed() -> void:
	if Pages.dropdown_title_for_dialog_syntax == find_child("TitleLabel").text:
		Pages.editor.notify("Cannot delete speaker arg dropdown.")
		return
	var title = find_child("TitleLabel").text
	Pages.delete_dropdown(title, find_child("EraseFromTextCheckBox").button_pressed)
	queue_free()


func _on_delete_parameters_button_pressed() -> void:
	find_child("DeleteParameters").visible = not find_child("DeleteParameters").visible


func _on_line_edit_text_submitted(_new_text: String) -> void:
	if find_child("SaveTitleButton").disabled:
		return
	_on_save_title_button_pressed()


func _on_line_edit_gui_input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.pressed and event.keycode == KEY_ESCAPE:
			_on_discard_title_button_pressed()
