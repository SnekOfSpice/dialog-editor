@tool
extends Control

var addresses_by_index := {}
var details_by_address := {}

var last_search_query := ""

func init():
	find_child("GoToButton").text = str("Go To")
	find_child("ReplaceContainer").visible = false
	find_child("ReplaceAllInTypeButton").text = "Replace all in Type"
	
func display_results(search:String):
	find_child("ReplaceContainer").visible = false
	var result = Pages.search_string(search)
	var item_list:ItemList = find_child("ItemList")
	item_list.clear()
	var i = 0
	# this is duplicated for relevancy
	var keys := ["text", "choices", "facts"]
	find_child("GoToButton").visible = false
	
	for k : String in keys:
		if result.get(k).is_empty():
			continue
		find_child("GoToButton").visible = true
		i += 1
		item_list.add_item(str("-- ", k.capitalize(), " --"), null, false)
		for address in result.get(k):
			addresses_by_index[i] = address
			details_by_address[address] = result.get(k).get(address)
			item_list.add_item(address)
	
	find_child("NoResultsLabel").visible = not find_child("GoToButton").visible


func request_replace_local():
	last_search_query = find_child("QueryTextEdit").text
	var address = find_child("ItemList").get_item_text(find_child("ItemList").get_selected_items()[0])
	var replace_str = find_child("ReplaceTextEdit").text
	
	var undo_redo = Pages.editor.undo_redo
	match DiisisEditorUtil.get_address_depth(address):
		DiisisEditorUtil.AddressDepth.Line:
			undo_redo.create_action("Replace Text Local")
			undo_redo.add_do_method(DiisisEditorActions.replace_line_content_text.bind(address, last_search_query, replace_str))
			undo_redo.add_undo_method(DiisisEditorActions.replace_line_content_text.bind(address, replace_str, last_search_query))
			undo_redo.commit_action()
		DiisisEditorUtil.AddressDepth.ChoiceItem:
			undo_redo.create_action("Replace Text Local")
			undo_redo.add_do_method(DiisisEditorActions.replace_choice_content_text.bind(address, last_search_query, replace_str))
			undo_redo.add_undo_method(DiisisEditorActions.replace_choice_content_text.bind(address, replace_str, last_search_query))
			undo_redo.commit_action()
	
	display_results(last_search_query)
	find_child("ResultLabel").text = ""
	find_child("GoToButton").text = "Go To"

func request_replace_all_in_type():
	var start_selection : int = find_child("ItemList").get_selected_items()[0]
	var addresses_in_type := [find_child("ItemList").get_item_text(start_selection)]
	var i := start_selection - 1
	while i >= 0 and find_child("ItemList").is_item_selectable(i):
		addresses_in_type.append(find_child("ItemList").get_item_text(i))
		i -= 1
	i = start_selection + 1
	while i < find_child("ItemList").get_item_count() and find_child("ItemList").is_item_selectable(i):
		addresses_in_type.append(find_child("ItemList").get_item_text(i))
		i += 1
	
	last_search_query = find_child("QueryTextEdit").text
	var replace_str = find_child("ReplaceTextEdit").text
	var undo_redo = Pages.editor.undo_redo
	
	var start_address : String = addresses_in_type.front()
	match DiisisEditorUtil.get_address_depth(start_address):
		DiisisEditorUtil.AddressDepth.Line:
			undo_redo.create_action("Replace Text In Type")
			undo_redo.add_do_method(DiisisEditorActions.replace_line_content_texts.bind(addresses_in_type, last_search_query, replace_str))
			undo_redo.add_undo_method(DiisisEditorActions.replace_line_content_texts.bind(addresses_in_type, replace_str, last_search_query))
			undo_redo.commit_action()
		DiisisEditorUtil.AddressDepth.ChoiceItem:
			undo_redo.create_action("Replace Text In Type")
			undo_redo.add_do_method(DiisisEditorActions.replace_choice_content_texts.bind(addresses_in_type, last_search_query, replace_str))
			undo_redo.add_undo_method(DiisisEditorActions.replace_choice_content_texts.bind(addresses_in_type, replace_str, last_search_query))
			undo_redo.commit_action()
	
	display_results(last_search_query)
	find_child("ResultLabel").text = ""
	find_child("GoToButton").text = "Go To"

func _on_search_button_pressed() -> void:
	last_search_query = find_child("QueryTextEdit").text
	display_results(last_search_query)

func _on_item_list_item_selected(index: int) -> void:
	var address = find_child("ItemList").get_item_text(index)
	var details : String = details_by_address.get(address)
	details = details.replace(last_search_query, str("[color=#f8f6f8][b]", last_search_query, "[/b][/color]"))
	find_child("ResultLabel").text = details
	
	find_child("GoToButton").text = str("Go To ", address)
	find_child("ReplaceContainer").visible = false
	if DiisisEditorUtil.get_address_depth(address) == DiisisEditorUtil.AddressDepth.Line:
		find_child("ReplaceContainer").visible = true
		find_child("ReplaceAllInTypeButton").text = "Replace all in Text"
	if DiisisEditorUtil.get_address_depth(address) == DiisisEditorUtil.AddressDepth.ChoiceItem:
		find_child("ReplaceContainer").visible = true
		find_child("ReplaceAllInTypeButton").text = "Replace all in Choices"


func _on_go_to_button_pressed() -> void:
	var address = find_child("ItemList").get_item_text(find_child("ItemList").get_selected_items()[0])
	Pages.editor.request_go_to_address(address)
