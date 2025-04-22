@tool
extends Window


func _on_close_requested() -> void:
	hide()


func display_references(page_index:int, line_index:int):
	for child in find_child("LoopbackContainer").get_children():
		child.queue_free()
	for child in find_child("JumpContainer").get_children():
		child.queue_free()
	var loopback_references : Array = Pages.get_loopback_references_to(page_index, line_index)
	var jump_references : Array = Pages.get_jump_references_to(page_index, line_index)
	
	var destination_address := str(page_index, ".", line_index)
	find_child("DestinationLabel").text = str(
		"[url=goto-", destination_address, "]",
		page_index, ".", DiisisEditorUtil.humanize_address(destination_address),
		"[/url]"
		)
	
	for address in loopback_references:
		add_label_to_container(address, find_child("LoopbackContainer"))
	for address in jump_references:
		add_label_to_container(address, find_child("JumpContainer"))

func add_label_to_container(address:String, container:Control):
	var label = RichTextLabel.new()
	label.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	label.meta_underlined = false
	label.bbcode_enabled = true
	label.fit_content = true
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.meta_clicked.connect(Pages.editor.goto_with_meta)
	label.text = str(
		"[url=goto-", address, "]",
		address, " - ", Pages.get_choice_text_adr(address),
		"[/url]"
	)
	container.add_child(label)

func _on_destination_label_meta_clicked(meta: Variant) -> void:
	Pages.editor.goto_with_meta(meta)
