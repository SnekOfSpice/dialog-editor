@tool
extends Control


var working_memory_stringkits := {}
var working_memory_titles := []


func init():
	%AddButton.disabled = true
	working_memory_stringkits = Pages.stringkits.duplicate(true)
	working_memory_titles = Pages.stringkit_titles.duplicate(true)
	
	for t in %StringkitsContainer.get_children():
		t.queue_free()
	
	for t in working_memory_titles:
		var item = preload("res://addons/diisis/editor/src/stringkit_item.tscn").instantiate()
		item.init(t)
		%StringkitsContainer.add_child(item)
		item.set_list_size(Pages.editor.get_window().size * 0.25)
	_on_clear_search_button_pressed()
	Pages.apply_font_size_overrides(self)
	
	var size_before = (get_parent() as Window).size
	await RenderingServer.frame_post_draw
	(get_parent() as Window).size = size_before


func fill_dialog_argument_checkboxes():
	for c in %Dialog.get_children():
		c.queue_free()
	
	var items := []
	for dd_title : String in Pages.stringkit_titles:
		var cb = preload("res://addons/diisis/editor/src/dialog_argument_stringkit_item.tscn").instantiate()
		%Dialog.add_child(cb)
		cb.init(dd_title)
		cb.argument_pressed.connect(toggle_stringkit_dialog_argument)
		cb.syntax_pressed.connect(set_dialog_syntax_stringkit)
		items.append(cb)
	
	if items.is_empty():
		add_notice_to_container(
			%Dialog,
			"Currently there are no stringkits defined for this file. Head over to the [code]Definitions[/code] tab to declare them.\n\nYou can use this tab to declare any stringkit as speaker or dialog argument (using the [code]{|}[/code] syntax in text lines.)"
		)
	
	for item in items:
		item.set_syntax_button_group(load("res://addons/diisis/editor/src/dialog_argument_syntax_button_group.tres"))
	Pages.apply_font_size_overrides(self)


func toggle_stringkit_dialog_argument(stringkit_title: String, value: bool):
	if value:
		if not Pages.stringkit_dialog_arguments.has(stringkit_title):
			Pages.stringkit_dialog_arguments.append(stringkit_title)
	else:
		if Pages.stringkit_dialog_arguments.has(stringkit_title):
			Pages.stringkit_dialog_arguments.erase(stringkit_title)


func set_dialog_syntax_stringkit(stringkit_title:String):
	Pages.stringkit_title_for_dialog_syntax = stringkit_title


func _on_stringkit_name_edit_text_changed(new_text: String) -> void:
	%AddButton.disabled = Pages.is_new_stringkit_title_invalid(new_text)


func _on_stringkit_name_edit_text_submitted(new_text: String) -> void:
	create_new_stringkit()
	%AddButton.disabled = true


func _on_clear_search_button_pressed() -> void:
	%SearchLineEdit.text = ""
	_on_search_line_edit_text_changed("")


func _on_search_line_edit_text_changed(new_text: String) -> void:
	if new_text.is_empty():
		for child in %StringkitsContainer.get_children():
			child.visible = true
		return
	for child in %StringkitsContainer.get_children():
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


func create_new_stringkit() -> void:
	var dd_title : String = %StringkitNameEdit.text
	if dd_title.is_empty() or %AddButton.disabled:
		return
	Pages.stringkits[dd_title] = []
	Pages.stringkit_titles.append(dd_title)
	var item = preload("res://addons/diisis/editor/src/stringkit_item.tscn").instantiate()
	item.init(dd_title)
	%StringkitsContainer.add_child(item)
	item.set_list_size(Pages.editor.get_window().size * 0.25)
	%StringkitNameEdit.text = ""
	Pages.apply_font_size_overrides(self)


func _on_stringkits_container_resized() -> void:
	for child in %StringkitsContainer.get_children():
		child.set_list_size(Pages.editor.get_window().size * 0.25)
	
	%NoStringkitsNotice.visible = %StringkitsContainer.get_child_count() == 0



func _on_definitions_visibility_changed() -> void:
	if not %Definitions.visible:
		return
	
	for child in %StringkitsContainer.get_children():
		child.update_speaker_label()
	
	%NoStringkitsNotice.visible = %StringkitsContainer.get_child_count() == 0

func add_notice_to_container(container:Control, text:String):
	var label = RichTextLabel.new()
	label.bbcode_enabled = true
	label.fit_content = true
	container.add_child(label)
	label.text = text


func _on_tab_container_tab_changed(_tab: int) -> void:
	var size_before = (get_parent() as Window).size
	await RenderingServer.frame_post_draw
	(get_parent() as Window).size = size_before
