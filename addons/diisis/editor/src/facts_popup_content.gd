@tool
extends Control

var ref_pages_fact : ItemList
var ref_lines_fact : ItemList
var ref_lines_condition : ItemList
var ref_choices_fact : ItemList
var ref_choices_condition : ItemList
var ref_lists := []

signal request_hide
signal request_popup

func fill():
	ref_pages_fact = find_child("RefPagesFact")
	ref_lines_fact = find_child("RefLinesFact")
	ref_lines_condition = find_child("RefLinesCondition")
	ref_choices_fact = find_child("RefChoicesFact")
	ref_choices_condition = find_child("RefChoicesCondition")
	ref_lists = [ref_pages_fact, ref_lines_fact, ref_lines_condition, ref_choices_fact, ref_choices_condition]
	find_child("Facts").clear()
	
	for list : ItemList in ref_lists:
		list.clear()
		if not list.item_selected.is_connected(drop_other_focused.bind(list)):
			list.item_selected.connect(drop_other_focused.bind(list))
	
	for fact in Pages.facts.keys():
		var fact_reg = fact#str(fact, ": ", Pages.facts.get(fact))
		var texture:Texture2D
		var value = Pages.facts.get(fact)
		if value is bool:
			if value:
				texture = load("res://addons/diisis/editor/visuals/true.png")
			else:
				texture = load("res://addons/diisis/editor/visuals/false.png")
		elif value is int:
			texture = load("res://addons/diisis/editor/visuals/int.png")
		find_child("Facts").add_item(fact_reg, texture)
	find_child("RenameFactButton").visible = true
	find_child("DeleteFactButton").visible = true
	find_child("FactRenameEditContainer").visible = false
	find_child("FactInteractionContainer").visible = false
	find_child("CancelRenameButton").visible = false
	find_child("FactDuplicateLabel").visible = false
	find_child("FactNameLabel").text = ""
	drop_other_focused()

func drop_other_focused(selected_index:=0, clicked_item_list:ItemList=null):
	for list in ref_lists:
		if clicked_item_list != list:
			list.deselect_all()
	
	find_child("GoToAddressButton").disabled = clicked_item_list == null
	find_child("GoToAddressLabel").text = ""
	if clicked_item_list != null:
		find_child("GoToAddressLabel").text = clicked_item_list.get_item_text(selected_index)

func _on_facts_item_clicked(index: int, at_position: Vector2, mouse_button_index: int) -> void:
	find_child("FactInteractionContainer").visible = true
	for list in ref_lists:
		list.clear()
	var f = find_child("Facts").get_item_text(index)
	find_child("FactNameLabel").text = f
	var references = Pages.lines_referencing_fact(f)
	
	#var s = "Pages containing fact:\n"
	for r in references.get("ref_pages_fact"):
		var s := ""
		var page_key : String = Pages.page_data.get(int(r)).get("page_key")
		s += str(r)
		var page_bound_icon:Texture
		if references.get("ref_pages_page_bound").has(r):
			page_bound_icon = load("res://addons/diisis/editor/visuals/fact-on-page.png")
		else:
			page_bound_icon = load("res://addons/diisis/editor/visuals/fact-not-on-page.png")
		if not page_key.is_empty():
			s += str("\t\t\t\t(", page_key, ")")
		
		ref_pages_fact.add_item(s, page_bound_icon)
	
	#s = "Conditionals referencing fact:\n"
	for r in references.get("ref_lines_condition"):
		ref_lines_condition.add_item(str(r))
	
	#s = "Lines declaring fact:\n"
	for r in references.get("ref_lines_fact"):
		#s += str(r)
		#s += "\n"
		ref_lines_fact.add_item(str(r))
	
	#s = "Choice Items declaring fact:\n"
	for r in references.get("ref_choices_fact"):
		ref_choices_fact.add_item(str(r))
	
	#s = "Choice Items referencing fact as conditional:\n"
	for r in references.get("ref_choices_condition"):
		ref_choices_condition.add_item(str(r))
		


func _on_rename_fact_button_pressed() -> void:
	find_child("FactRenameEditContainer").visible = true
	find_child("CancelRenameButton").visible = true
	find_child("DeleteFactButton").visible = false
	find_child("RenameFactButton").visible = false

func _on_cancel_rename_button_pressed() -> void:
	find_child("RenameFactButton").visible = true
	find_child("DeleteFactButton").visible = true
	find_child("FactRenameEditContainer").visible = false
	find_child("CancelRenameButton").visible = false


func _on_confirm_rename_button_pressed() -> void:
	emit_signal("request_hide")
	
	var undo_redo = Pages.editor.undo_redo
	undo_redo.create_action("Rename Fact")
	undo_redo.add_do_method(DiisisEditorActions.rename_fact.bind(find_child("FactNameLabel").text, find_child("NewNameEdit").text))
	undo_redo.add_undo_method(DiisisEditorActions.rename_fact.bind(find_child("NewNameEdit").text, find_child("FactNameLabel").text))
	undo_redo.commit_action()
	
	await get_tree().process_frame
	emit_signal("request_popup")


func _on_new_name_edit_text_changed(new_text: String) -> void:
	find_child("ConfirmRenameButton").disabled = Pages.facts.has(new_text)
	find_child("FactDuplicateLabel").visible = Pages.facts.has(new_text)


func _on_delete_fact_button_pressed() -> void:
	var fact = find_child("FactNameLabel").text
	$ConfirmDelete.dialog_text = str(
		"Do you want to delete fact [", fact, "]?\n
		This deletes it from all pages, lines, and choice items, in both fact and conditional declarations.\n
		This action cannot be undone."
		)
	$ConfirmDelete.popup()


func _on_confirm_delete_canceled() -> void:
	$ConfirmDelete.hide()


func _on_confirm_delete_confirmed() -> void:
	emit_signal("request_hide")
	
	Pages.delete_fact(find_child("FactNameLabel").text)
	
	await get_tree().process_frame
	emit_signal("request_popup")


func _on_go_to_address_button_pressed() -> void:
	emit_signal("request_hide")
	Pages.editor.request_go_to_address(find_child("GoToAddressLabel").text)
