@tool
extends Control
class_name DiisisEditor

const AUTO_SAVE_INTERVAL := 30000.0

var _page = preload("res://addons/diisis/editor/src/page.tscn")
var current_page: Page
var undo_redo = UndoRedo.new()

var active_dir := ""
var active_file_name := ""
var time_since_last_save := 0.0
var last_system_save := {}
var has_saved := false

enum PageView {
	Full,
	Truncated,
	Minimal
}

func refresh(serialize_before_load:=true):
	var cpn:int
	if current_page:
		cpn = current_page.number
	else:
		cpn = 0
	if serialize_before_load:
		current_page.save()
	await get_tree().process_frame
	load_page(cpn, not serialize_before_load)

func init() -> void:
	var n = Node.new()
	var node_functions := n.get_method_list()
	var node_functions_names := []
	for f in node_functions:
		node_functions_names.append(f.get("name"))
	var handler_functions :Array= load("res://sample/Handler.gd").get_script_method_list()
	var handler_functions_names := []
	for f in handler_functions:
		handler_functions_names.append(f.get("name"))
	n.queue_free()
	var unique_functions := []
	for f in handler_functions_names:
		if not node_functions_names.has(f):
			unique_functions.append(f)
	node_functions_names.sort()
	handler_functions_names.sort()
	unique_functions.sort()
	#print("\n".join(PackedStringArray(node_functions_names)))
	#print("\n".join(PackedStringArray(handler_functions_names)))
	print("\n".join(PackedStringArray(unique_functions)))
	print("init editor")
	Pages.connect("pages_modified", update_controls)
	Pages.editor = self
	
	#add_empty_page()
	request_add_page(0)
	
	update_controls()
	
	#set_current_page_changeable(false)
	
	find_child("FDOpen").size = get_window().size * 0.75
	find_child("FDSave").size = get_window().size * 0.75
	find_child("MovePagePopup").size = get_window().size * 0.75
	find_child("FactsPopup").size = get_window().size * 0.75
	
	for c in get_tree().get_nodes_in_group("editor_popup_button"):
		c.init()
	
	$AutoSaveTimer.wait_time = AUTO_SAVE_INTERVAL
	$Core.visible = true
	$GraphView.visible = false
	undo_redo.clear_history()
	undo_redo.version_changed.connect(update_undo_redo_buttons)
	update_undo_redo_buttons()
	
	find_child("File").set_item_checked(8, Pages.empty_strings_for_l10n)
	print("init editor successful")

func update_page_view(view:PageView):
	for node in get_tree().get_nodes_in_group("page_view_sensitive"):
		node.set_page_view(view)

func load_page(number: int, discard_without_saving:=false):
	await get_tree().process_frame
	number = clamp(number, 0, Pages.get_page_count() - 1)
	
	for c in $Core/PageContainer.get_children():
		if not c is Page:
			push_warning(str("PageContainer has a child that's not a page: ", c))
			continue
		
		if not discard_without_saving:
			c.save()
		c.queue_free()
	
	var page = _page.instantiate()
	$Core/PageContainer.add_child(page)
	page.init(number)
	current_page = page
	
	update_controls()
	
	$AutoSaveTimer.wait_time = AUTO_SAVE_INTERVAL
	await get_tree().process_frame

func get_selected_line_type() -> int:
	var line_type:=DIISIS.LineType.Text
	
	for button : LineTypeButton in find_child("LineTypes").get_children():
		if button.button_pressed:
			line_type = button.line_type
			break
	
	return line_type

func get_selected_page_view() -> PageView:
	var view:=PageView.Full
	
	for button : PageViewButton in find_child("ViewTypes").get_children():
		if button.button_pressed:
			view = button.page_view
			break
	
	return view

func set_save_path(value:String):
	var parts = value.split("/")
	active_file_name = parts[parts.size() - 1]
	active_dir = value.trim_suffix(active_file_name)
	find_child("SavePathLabel").text = str(active_dir, active_file_name)

func _process(delta: float) -> void:
	if not active_dir.is_empty() and has_saved:
		time_since_last_save += delta
	#find_child("AutosaveAnnounceLabel").visible = $AutoSaveTimer.time_left < 6.0
	#find_child("AutosaveAnnounceLabel").text = str("Autosave in: ", floor($AutoSaveTimer.time_left))
	

func set_graph_view_visible(value:bool):
	$Core.visible = not value
	$GraphView.visible = value
	
func update_controls():
	if not current_page:
		return
	
	find_child("First").disabled = current_page.number <= 0
	find_child("Prev").disabled = current_page.number <= 0
	find_child("Next").disabled = current_page.number >= Pages.get_page_count() - 1
	find_child("Last").disabled = current_page.number >= Pages.get_page_count() - 1
	#find_child("PageCountCurrent").text = str(current_page.number)
	find_child("GoTo").set_current_page_count(str(current_page.number))
	find_child("GoTo").set_page_count(str(Pages.get_page_count() - 1))
	#find_child("PageCountMax").text = str(Pages.get_page_count() - 1)
	find_child("DeleteCurrent").disabled = Pages.get_page_count() == 1
	
	await get_tree().process_frame
	current_page.update()

func get_current_page_number() -> int:
	if not current_page:
		return 0
	return current_page.number

func _on_first_pressed() -> void:
	request_load_page(0, "Move to first page")

func _on_prev_pressed() -> void:
	request_load_page(current_page.number - 1, "Move to previous page")

func _on_next_pressed() -> void:
	request_load_page(current_page.number + 1, "Move to next page")

func _on_last_pressed() -> void:
	request_load_page(Pages.get_page_count() - 1, "Move to last page")

func _on_add_last_pressed() -> void:
	request_add_page(Pages.get_page_count())

func _on_delete_current_pressed() -> void:
	request_delete_page(get_current_page_number())

func request_delete_page(number:int):
	if Pages.get_page_count() <= 1:
		push_warning("you cannot delete the last page")
		return
	
	undo_redo.create_action("Delete Page")
	if number == 0:
		undo_redo.add_do_method(DiisisEditorActions.load_page.bind(number + 1))
	else:
		undo_redo.add_do_method(DiisisEditorActions.load_page.bind(number - 1))
	undo_redo.add_do_method(DiisisEditorActions.delete_page.bind(number))
	undo_redo.add_undo_method(DiisisEditorActions.add_page.bind(number))
	undo_redo.add_undo_method(DiisisEditorActions.load_page.bind(number))
	undo_redo.commit_action()

func _on_add_after_pressed() -> void:
	request_add_page(get_current_page_number() + 1)

func request_add_page(at:int):
	undo_redo.create_action("Insert page")
	undo_redo.add_do_method(DiisisEditorActions.add_page.bind(at))
	undo_redo.add_do_method(DiisisEditorActions.load_page.bind(at))
	undo_redo.add_undo_method(DiisisEditorActions.load_page.bind(get_current_page_number()))
	undo_redo.add_undo_method(DiisisEditorActions.delete_page.bind(at))
	undo_redo.commit_action()

func open_save_popup():
	if active_dir != "":
		get_node("FDSave").current_dir = active_dir
	open_popup(find_child("FDSave"), true)

func save_to_file(path:String):
	if current_page:
		current_page.save()
	
	var file = FileAccess.open(path, FileAccess.WRITE)
	var data_to_save = Pages.serialize()
	file.store_string(JSON.stringify(data_to_save, "\t"))
	file.close()
	set_save_path(path)
	time_since_last_save = 0.0
	last_system_save = Time.get_time_dict_from_system()
	has_saved = true

func _on_fd_save_file_selected(path: String) -> void:
	save_to_file(path)


func _on_fd_open_file_selected(path: String) -> void:
	var file = FileAccess.open(path, FileAccess.READ)
	var data : Dictionary = JSON.parse_string(file.get_as_text())
	file.close()
	
	set_save_path(path)
	
	Pages.deserialize(data)
	find_child("File").set_item_checked(8, Pages.empty_strings_for_l10n)
	
	load_page(0, true)

func request_go_to_address(address:String, action_message:=""):
	if action_message.is_empty():
		action_message == str("Go to ", address)
	undo_redo.create_action(action_message)
	undo_redo.add_do_method(DiisisEditorActions.go_to.bind(address))
	undo_redo.add_undo_method(DiisisEditorActions.go_to.bind(str(get_current_page_number())))
	undo_redo.commit_action()

func request_load_page(number:int, action_message:String):
	request_go_to_address(str(number), action_message)

func _on_add_line_button_pressed() -> void:
	undo_redo.create_action("Add Line")
	var line_count = current_page.get_line_count()
	DiisisEditorActions.blank_override_line_indices.append(str(get_current_page_number(), ".", line_count))
	undo_redo.add_do_method(DiisisEditorActions.add_line.bind(line_count))
	undo_redo.add_undo_method(DiisisEditorActions.delete_line.bind(line_count))
	undo_redo.commit_action()

func _on_edit_characters_button_pressed() -> void:
	current_page.save()
	$DropdownPopup.popup()


func _on_header_popup_update() -> void:
	await get_tree().process_frame
	current_page.update()

func _on_instruction_definition_timer_timeout() -> void:
	find_child("ErrorTextBox").text = Pages.get_all_invalid_instructions()

func _on_auto_save_timer_timeout() -> void:
	current_page.save()

func _on_instruction_popup_validate_saved_instructions() -> void:
	find_child("ErrorTextBox").text = Pages.get_all_invalid_instructions()

func update_undo_redo_buttons():
	find_child("UndoButton").disabled = not undo_redo.has_undo()
	find_child("RedoButton").disabled = not undo_redo.has_redo()

func _on_undo_button_pressed() -> void:
	undo_redo.undo()
	update_undo_redo_buttons()

func _on_redo_button_pressed() -> void:
	undo_redo.redo()
	update_undo_redo_buttons()


func _on_toggle_search_button_pressed() -> void:
	find_child("TextSearchContainer").visible = not find_child("TextSearchContainer").visible
	if find_child("TextSearchContainer").visible:
		find_child("PageContainer").size_flags_vertical = VBoxContainer.SIZE_EXPAND
	else:
		find_child("PageContainer").size_flags_vertical = VBoxContainer.SIZE_EXPAND_FILL


func open_popup(popup:Window, fit_to_size:=false):
	if not popup:
		push_warning("No popup set.")
		return
	if fit_to_size:
		popup.size = size
	Pages.editor.refresh()
	popup.popup()
	popup.grab_focus()


func _on_setup_index_pressed(index: int) -> void:
	match index:
		1: # header
			open_popup(find_child("HeaderPopup"))
		2: # dd
			open_popup(find_child("DropdownPopup"))
		3: # instr
			open_popup(find_child("InstructionPopup"))
		5: # facts
			open_popup(find_child("FactsPopup"))
		6: # pages
			open_popup(find_child("MovePagePopup"))


func _on_utility_index_pressed(index: int) -> void:
	match index:
		0: 
			open_popup(find_child("WordCountDialog"))
		1: 
			open_popup(find_child("TextSearchPopup"))


func _on_file_index_pressed(index: int) -> void:
	match index:
		0: #save
			if active_dir.is_empty():
				open_save_popup()
				return
			save_to_file(str(active_dir, active_file_name))
		1: # save as
			open_save_popup()
		2:
			# open
			if active_dir != "":
				get_node("FDSave").current_dir = active_dir
			open_popup(find_child("FDOpen"), true)
		4:
			# config
			open_popup(find_child("FileConfigPopup"), true)
		6: # locales
			open_popup(find_child("LocaleSelectionWindow"), true)
		7: # export blank l10n
			open_popup(find_child("FDExportLocales"), true)
		8:
			Pages.empty_strings_for_l10n = not Pages.empty_strings_for_l10n
			find_child("File").set_item_checked(8, Pages.empty_strings_for_l10n)


func _on_funny_debug_button_pressed() -> void:
	#print(Pages.get_localizable_addresses())
	var doms := ["af_ZA",
"sq_AL",
"ar_SA",
"ar_SA",
"ar_SA",
"ar_SA",
"ar_SA",
"ar_SA",
"ar_SA",
"ar_SA",
"ar_SA",
"ar_SA",
"ar_SA",
"ar_SA",
"ar_SA",
"ar_SA",
"ar_SA",
"ar_SA",
"hy_AM",
"az_AZ",
"eu_ES",
"be_BY",
"bn_IN",
"bs_BA",
"bg_BG",
"ca_ES",
"zh_CN",
"zh_TW",
"zh_TW",
"zh_CN",
"zh_TW",
"hr_HR",
"cs_CZ",
"da_DK",
"nl_NL",
"nl_NL",
"en_US",
"en_US",
"en_US",
"en_US",
"en_US",
"en_US",
"en_US",
"en_US",
"en_US",
"en_US",
"en_US",
"en_US",
"en_US",
"et_EE",
"fo_FO",
"fi_FI",
"fr_FR",
"fr_FR",
"fr_FR",
"fr_FR",
"fr_FR",
"fr_FR",
"gl_ES",
"ka_GE",
"de_DE",
"de_DE",
"de_DE",
"de_DE",
"de_DE",
"el_GR",
"gu_IN",
"he_IL",
"hi_IN",
"hu_HU",
"is_IS",
"id_ID",
"it_IT",
"it_IT",
"ja_JP",
"kn_IN",
"kk_KZ",
"kok_IN",
"ko_KR",
"lv_LV",
"lt_LT",
"mk_MK",
"ms_MY",
"ms_MY",
"ml_IN",
"mt_MT",
"mr_IN",
"mn_MN",
"se_NO",
"nb_NO",
"nn_NO",
"fa_IR",
"pl_PL",
"pt_BR",
"pt_BR",
"pa_IN",
"ro_RO",
"ru_RU",
"sr_BA",
"sr_BA",
"sk_SK",
"sk_SK",
"es_ES",
"es_ES",
"es_ES",
"es_ES",
"es_ES",
"es_ES",
"es_ES",
"es_ES",
"es_ES",
"es_ES",
"es_ES",
"es_ES",
"es_ES",
"es_ES",
"es_ES",
"es_ES",
"es_ES",
"es_ES",
"es_ES",
"sw_KE",
"sv_SE",
"sv_SE",
"syr_SY",
"ta_IN",
"te_IN",
"th_TH",
"tn_ZA",
"tr_TR",
"uk_UA",
"uz_UZ",
"vi_VN",
"cy_GB",
"xh_ZA",
"zu_ZA"]
	var uniques := []
	for d in doms:
		if not uniques.has(d):
			uniques.append(d)
	print(uniques)

func _on_fd_export_locales_dir_selected(dir: String) -> void:
	var addresses : Dictionary = Pages.get_localizable_addresses_with_content()
	for locale in Pages.locales_to_export:
		prints("saving", locale)
		var file = FileAccess.open(str(dir, "/diisis_l10n_", locale, ".json"), FileAccess.WRITE)
		var data_to_save = {}
		for address in addresses:
			if Pages.empty_strings_for_l10n:
				data_to_save[address] = ""
			else:
				data_to_save[address] = addresses.get(address)
		file.store_string(JSON.stringify(data_to_save, "\t"))
		file.close()


func _on_refresh_button_pressed() -> void:
	refresh()


func _on_error_text_box_meta_clicked(meta: Variant) -> void:
	if str(meta).begins_with("goto-"):
		var target_address := str(meta).trim_prefix("goto-")
		request_go_to_address(target_address, str("Go to ", target_address))
