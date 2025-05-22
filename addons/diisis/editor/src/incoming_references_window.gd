@tool
extends Window


func _on_close_requested() -> void:
	hide()


## line_index -1 for pages
func display_references(page_index:int, line_index := -1):
	for child in find_child("LoopbackContainer").get_children():
		child.queue_free()
	for child in find_child("JumpContainer").get_children():
		child.queue_free()
	for child in find_child("NextContainer").get_children():
		child.queue_free()
	var loopback_references : Array
	var jump_references : Array
	var next_references := []
	if line_index != -1:
		loopback_references = Pages.get_loopback_references_to(page_index, line_index)
		jump_references = Pages.get_jump_references_to(page_index, line_index)
	else:
		var results : Dictionary = Pages.get_references_to_page(page_index)
		loopback_references = results.get("loopback")
		jump_references = results.get("jump")
		next_references = results.get("next")
	
	
	var destination_address : String 
	if line_index != -1:
		destination_address = str(page_index, ".", line_index)
	else:
		destination_address = str(page_index)
	find_child("DestinationLabel").text = str(
		"[url=goto-", destination_address, "]",
		page_index, ": ", DiisisEditorUtil.humanize_address(destination_address),
		"[/url]"
		)
	
	for address in loopback_references:
		add_label_to_container(address, find_child("LoopbackContainer"))
	for address in jump_references:
		add_label_to_container(address, find_child("JumpContainer"))
	for address in next_references:
		add_label_to_container(address, find_child("NextContainer"))
	
	find_child("LoopbackSection").visible = not loopback_references.is_empty()
	find_child("JumpSection").visible = not jump_references.is_empty()
	find_child("NextSection").visible = not next_references.is_empty()
	
	var no_references : bool
	if line_index != -1:
		no_references = loopback_references.is_empty() and jump_references.is_empty()
	else:
		no_references = loopback_references.is_empty() and jump_references.is_empty() and next_references.is_empty()
	find_child("NoReferencesLabel").visible = no_references

func add_label_to_container(address:String, container:Control):
	var label = RichTextLabel.new()
	label.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	label.meta_underlined = false
	label.bbcode_enabled = true
	label.fit_content = true
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.meta_clicked.connect(Pages.editor.goto_with_meta)
	
	if DiisisEditorUtil.get_address_depth(address) == DiisisEditorUtil.AddressDepth.ChoiceItem:
		label.text = str(
			"[url=goto-", address, "]",
			address, " - ", Pages.get_choice_text_adr(address),
			"[/url]"
		)
	elif DiisisEditorUtil.get_address_depth(address) == DiisisEditorUtil.AddressDepth.Page:
		label.text = str(
			"[url=goto-", address, "]",
			address, " - ", Pages.get_page_key(int(address)),
			"[/url]"
		)
	container.add_child(label)

func _on_destination_label_meta_clicked(meta: Variant) -> void:
	Pages.editor.goto_with_meta(meta)
