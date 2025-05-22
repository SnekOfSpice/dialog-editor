@tool
extends Control

var addresses_by_index := {}
var details_by_address := {}
var fact_start_index := -1
var instruction_start_index := -1

var last_search_query := ""

func init():
	find_child("GoToButton").text = str("Go To")
	find_child("ReplaceContainer").visible = false
	find_child("ReplaceAllInTypeButton").text = "Replace all in Type"
	find_child("QueryTextEdit").grab_focus()

func _shortcut_input(event):
	if event is InputEventKey:
		if not event.pressed:
			return
		
		if event.is_command_or_control_pressed():
			match event.key_label:
				KEY_F:
					find_child("QueryTextEdit").release_focus()
					find_child("QueryTextEdit").grab_focus()

func get_include_tags() -> bool:
	return find_child("IncludeTagsButton").button_pressed

func display_results(search:String):
	var item_list:ItemList = find_child("ItemList")
	
	
	
	var selection_index_before := 0
	var selection_text_before := ""
	if not item_list.get_selected_items().is_empty():
		selection_index_before = item_list.get_selected_items()[0]
		selection_text_before = item_list.get_item_text(selection_index_before)
	
	find_child("ResultLabel").text = ""
	fact_start_index = -1
	instruction_start_index = -1
	var case_insensitive = not find_child("CaseSensitiveButton").button_pressed
	var include_tags = get_include_tags()
	find_child("ReplaceContainer").visible = false
	var result = Pages.search_string(search, case_insensitive, include_tags)
	item_list.clear()
	var i = 0
	# this is duplicated for relevancy
	var keys := ["text", "choices", "instructions", "facts"]
	find_child("GoToButton").disabled = true
	
	var result_count := 0
	
	for k : String in keys:
		if result.get(k).is_empty():
			continue
		find_child("GoToButton").disabled = false
		i += 1
		item_list.add_item(str("-- ", k.capitalize(), " --"), null, false)
		if k == "facts":
			fact_start_index = item_list.item_count
		if k == "instructions":
			instruction_start_index = item_list.item_count
		for address in result.get(k):
			addresses_by_index[i] = address
			details_by_address[address] = result.get(k).get(address)
			item_list.add_item(address)
			result_count += 1
	
	find_child("ResultCountLabel").text = "%s results" % result_count
	
	var reselected_text := false
	for idx in item_list.item_count:
		if item_list.get_item_text(idx) == selection_text_before:
			item_list.select(idx)
			_on_item_list_item_selected(idx)
			reselected_text = true
			break
	if not reselected_text:
		if item_list.item_count >= selection_index_before:
			item_list.select(selection_index_before)
			_on_item_list_item_selected(selection_index_before)


func request_replace_local():
	last_search_query = find_child("QueryTextEdit").text
	var address = find_child("ItemList").get_item_text(find_child("ItemList").get_selected_items()[0])
	var replace_str = find_child("ReplaceTextEdit").text
	var case_insensitive = not find_child("CaseSensitiveButton").button_pressed
	var undo_redo = Pages.editor.undo_redo
	match DiisisEditorUtil.get_address_depth(address):
		DiisisEditorUtil.AddressDepth.Line:
			undo_redo.create_action("Replace Text Local")
			undo_redo.add_do_method(DiisisEditorActions.replace_line_content_text.bind(address, last_search_query, replace_str, case_insensitive))
			undo_redo.add_undo_method(DiisisEditorActions.replace_line_content_text.bind(address, replace_str, last_search_query, case_insensitive))
			undo_redo.commit_action()
		DiisisEditorUtil.AddressDepth.ChoiceItem:
			undo_redo.create_action("Replace Text Local")
			undo_redo.add_do_method(DiisisEditorActions.replace_choice_content_text.bind(address, last_search_query, replace_str, case_insensitive))
			undo_redo.add_undo_method(DiisisEditorActions.replace_choice_content_text.bind(address, replace_str, last_search_query, case_insensitive))
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
	var case_insensitive = not find_child("CaseSensitiveButton").button_pressed
	var start_address : String = addresses_in_type.front()
	match DiisisEditorUtil.get_address_depth(start_address):
		DiisisEditorUtil.AddressDepth.Line:
			undo_redo.create_action("Replace Text In Type")
			undo_redo.add_do_method(DiisisEditorActions.replace_line_content_texts.bind(addresses_in_type, last_search_query, replace_str, case_insensitive))
			undo_redo.add_undo_method(DiisisEditorActions.replace_line_content_texts.bind(addresses_in_type, replace_str, last_search_query, case_insensitive))
			undo_redo.commit_action()
		DiisisEditorUtil.AddressDepth.ChoiceItem:
			undo_redo.create_action("Replace Text In Type")
			undo_redo.add_do_method(DiisisEditorActions.replace_choice_content_texts.bind(addresses_in_type, last_search_query, replace_str, case_insensitive))
			undo_redo.add_undo_method(DiisisEditorActions.replace_choice_content_texts.bind(addresses_in_type, replace_str, last_search_query, case_insensitive))
			undo_redo.commit_action()
	
	display_results(last_search_query)
	find_child("ResultLabel").text = ""
	find_child("GoToButton").text = "Go To"

func _on_search_button_pressed() -> void:
	update_query(find_child("QueryTextEdit").text)

func update_query(query:String) -> void:
	last_search_query = query
	display_results(last_search_query)

func _on_item_list_item_selected(index: int) -> void:
	var address = find_child("ItemList").get_item_text(index)
	var details : String = details_by_address.get(address, "")
	var raw_details := details
	
	var case_insensitive = not find_child("CaseSensitiveButton").button_pressed
	var substrings_to_highlight := []
	var highlight_index : int
	if case_insensitive:
		highlight_index = details.findn(last_search_query)
	else:
		highlight_index = details.find(last_search_query)
	while highlight_index != -1:
		var substring_to_highlight = details.substr(highlight_index, last_search_query.length())
		if not substrings_to_highlight.has(substring_to_highlight):
			substrings_to_highlight.append(substring_to_highlight)
		if case_insensitive:
			highlight_index = details.findn(last_search_query, highlight_index + 1)
		else:
			highlight_index = details.find(last_search_query, highlight_index + 1)
	
	if not get_include_tags():
		find_child("ResultLabel").text = details
		details = find_child("ResultLabel").get_parsed_text()
	
	for substr in substrings_to_highlight:
		details = details.replace(substr, str("[color=#f8f6f8][b]", substr, "[/b][/color]"))
	find_child("ResultLabel").text = details
	
	find_child("GoToButton").text = str("Go To ", address)
	find_child("ReplaceContainer").visible = false
	if DiisisEditorUtil.get_address_depth(address) == DiisisEditorUtil.AddressDepth.Line:
		find_child("ReplaceContainer").visible = true
		find_child("ReplaceAllInTypeButton").text = "Replace all in Text"
	if DiisisEditorUtil.get_address_depth(address) == DiisisEditorUtil.AddressDepth.ChoiceItem:
		find_child("ReplaceContainer").visible = true
		find_child("ReplaceAllInTypeButton").text = "Replace all in Choices"
	
	var after_valid_region = (index >= fact_start_index and fact_start_index != -1) or (index >= instruction_start_index and instruction_start_index != -1)
	find_child("ReplaceLocallyButton").disabled = after_valid_region
	find_child("ReplaceAllInTypeButton").disabled = after_valid_region
	find_child("GoToButton").disabled = index >= fact_start_index
	if fact_start_index == -1:
		find_child("GoToButton").disabled = false
	
	if fact_start_index == -1 and instruction_start_index == -1:
		find_child("ReplaceLocallyButton").disabled = false
		find_child("ReplaceAllInTypeButton").disabled = false
	
	if (index >= instruction_start_index and instruction_start_index != -1) and (index < fact_start_index or fact_start_index == -1):
		find_child("ResultLabel").text = "[url=search_method]%s[/url]" % raw_details
	elif index >= fact_start_index and fact_start_index != -1:
		find_child("ResultLabel").text = "[url=fact/%s]%s[/url]" % [raw_details, raw_details]


func _on_go_to_button_pressed() -> void:
	await get_tree().process_frame
	var address = find_child("ItemList").get_item_text(find_child("ItemList").get_selected_items()[0])
	Pages.editor.request_go_to_address(address)


func _on_case_sensitive_button_toggled(_toggled_on: bool) -> void:
	update_query(find_child("QueryTextEdit").text)


func _on_item_list_item_activated(index: int) -> void:
	await get_tree().process_frame
	var address = find_child("ItemList").get_item_text(find_child("ItemList").get_selected_items()[0])
	Pages.editor.request_go_to_address(address)


func _on_include_tags_button_toggled(toggled_on: bool) -> void:
	update_query(find_child("QueryTextEdit").text)


func _on_result_label_meta_clicked(meta: Variant) -> void:
	meta = str(meta)
	if meta == "search_method":
		var text : String = find_child("ResultLabel").get_parsed_text()
		text = text.split("(")[0]
		DiisisEditorUtil.search_function(text)
	elif meta.begins_with("fact/"):
		var fact = meta.trim_prefix("fact/")
		Pages.editor.open_facts_window(fact)
