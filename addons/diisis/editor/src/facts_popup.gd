@tool
extends Window

#
func fill():
	find_child("Facts").clear()
	for fact in Pages.facts.keys():
		var fact_reg = fact#str(fact, ": ", Pages.facts.get(fact))
		var texture:Texture2D
		if Pages.facts.get(fact):
			texture = load("res://addons/diisis/editor/visuals/true.png")
		else:
			texture = load("res://addons/diisis/editor/visuals/false.png")
		find_child("Facts").add_item(fact_reg, texture)
	find_child("RenameFactButton").visible = true
	find_child("FactRenameEditContainer").visible = false
	find_child("CancelRenameButton").visible = false
	find_child("FactDuplicateLabel").visible = false
	find_child("FactNameLabel").text = ""

func _on_about_to_popup() -> void:
	fill()

func _on_close_requested() -> void:
	hide()


func _on_facts_item_clicked(index: int, at_position: Vector2, mouse_button_index: int) -> void:
	var f = find_child("Facts").get_item_text(index)
	find_child("FactNameLabel").text = f
	var references = Pages.lines_referencing_fact(f)
	
	var s = "Pages containing fact:\n"
	for r in references.get("ref_pages"):
		var page_key : String = Pages.page_data.get(int(r)).get("page_key")
		s += str(r)
		if references.get("ref_pages_page_bound").has(r):
			s += "i"
		if not page_key.is_empty():
			s += str("\t\t\t\t(", page_key, ")")
		
		s += "\n"
	find_child("RefPages").text = s
	
	s = "Conditionals referencing fact:\n"
	for r in references.get("ref_lines_condition"):
		s += str(r)
		s += "\n"
	find_child("RefDeclare").text = s
	
	s = "Lines declaring fact:\n"
	for r in references.get("ref_lines_declare"):
		s += str(r)
		s += "\n"
	find_child("RefChoiceDeclare").text = s
	
	s = "Choice Items declaring fact:\n"
	for r in references.get("ref_lines_choice_declare"):
		s += str(r)
		s += "\n"
	find_child("RefCondition").text = s
	
	s = "Choice Items referencing fact as conditional:\n"
	for r in references.get("ref_lines_choice_condition"):
		s += str(r)
		s += "\n"
	find_child("RefChoiceCondition").text = s
		


func _on_rename_fact_button_pressed() -> void:
	find_child("FactRenameEditContainer").visible = true
	find_child("CancelRenameButton").visible = true
	find_child("RenameFactButton").visible = false

func _on_cancel_rename_button_pressed() -> void:
	find_child("RenameFactButton").visible = true
	find_child("FactRenameEditContainer").visible = false
	find_child("CancelRenameButton").visible = false


func _on_confirm_rename_button_pressed() -> void:
	hide()
	
	var undo_redo = Pages.editor.undo_redo
	undo_redo.create_action("Rename Fact")
	undo_redo.add_do_method(DiisisEditorActions.rename_fact.bind(find_child("FactNameLabel").text, find_child("NewNameEdit").text))
	undo_redo.add_undo_method(DiisisEditorActions.rename_fact.bind(find_child("NewNameEdit").text, find_child("FactNameLabel").text))
	undo_redo.commit_action()
	
	await get_tree().process_frame
	popup()


func _on_new_name_edit_text_changed(new_text: String) -> void:
	find_child("ConfirmRenameButton").disabled = Pages.facts.has(new_text)
	find_child("FactDuplicateLabel").visible = Pages.facts.has(new_text)
