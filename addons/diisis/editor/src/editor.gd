@tool
extends Control
class_name DiisisEditor

const AUTO_SAVE_INTERVAL := 900.0 # 15 mins
const BACKUP_PATH := "user://DIISIS_autosave/"
var auto_save_timer := AUTO_SAVE_INTERVAL
var is_open := false
var undo_redo_count_at_last_save := 0

var _page = preload("res://addons/diisis/editor/src/page.tscn")
var current_page: Page
var undo_redo = UndoRedo.new()
var core:Control
var page_container:Control

var content_scale := 1.0

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

signal scale_editor_up()
signal scale_editor_down()
signal open_new_file()

func refresh(serialize_before_load:=true, fragile:=false):
	var cpn:int
	if current_page:
		cpn = current_page.number
	else:
		cpn = 0
	if serialize_before_load:
		current_page.save()
	await get_tree().process_frame
	if fragile:
		for node in get_tree().get_nodes_in_group("diisis_fragile"):
			node.update_fragile()
	else:
		load_page(cpn, not serialize_before_load)

func init(active_file_path:="") -> void:
	core = find_child("Core")
	page_container = core.find_child("PageContainer")
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
	print("init editor")
	Pages.connect("pages_modified", update_controls)
	Pages.editor = self
	is_open = true
	
	request_add_page(0, 0)
	
	update_controls()
	
	for c in get_tree().get_nodes_in_group("editor_popup_button"):
		c.init()
	
	core.visible = true
	$GraphView.visible = false
	undo_redo.clear_history()
	undo_redo.version_changed.connect(update_undo_redo_buttons)
	update_undo_redo_buttons()
	
	find_child("File").set_item_checked(8, Pages.empty_strings_for_l10n)
	
	for popup : Window in $Popups.get_children():
		popup.visible = false
		popup.exclusive = false
		popup.always_on_top = true
		popup.wrap_controls = true
		popup.transient = false
		popup.popup_window = false
	
	
	
	open_from_path(active_file_path)
	
	print("init editor successful")


func set_content_scale(factor:float):
	content_scale = factor
	var bar : MenuBar = find_child("MenuBar")
	bar.get_node("File").content_scale_factor = factor
	bar.get_node("Utility").content_scale_factor = factor
	bar.get_node("Setup").content_scale_factor = factor

func update_page_view(view:PageView):
	for node in get_tree().get_nodes_in_group("diisis_page_view_sensitive"):
		node.set_page_view(view)

func load_page(number: int, discard_without_saving:=false):
	await get_tree().process_frame
	number = clamp(number, 0, Pages.get_page_count() - 1)
	
	for page in page_container.get_children():		
		if not discard_without_saving:
			page.save()
	
	var page_instance:Page
	if page_container.get_child_count() == 0:
		page_instance = _page.instantiate()
		page_container.add_child(page_instance)
	else:
		page_instance = page_container.get_child(0)
		
	page_instance.init(number)
	current_page = page_instance
	
	update_controls()
	await get_tree().process_frame

func get_selected_line_type() -> int:
	var line_type:=DIISIS.LineType.Text
	
	for button : LineTypeButton in find_child("LineTypes").get_children():
		if button.button_pressed:
			line_type = button.line_type
			break
	
	return line_type

func select_line_type(line_type:int):
	for button : LineTypeButton in find_child("LineTypes").get_children():
		if button.line_type == line_type:
			button.button_pressed = true

func get_selected_page_view() -> PageView:
	var view:=PageView.Full
	
	for button : PageViewButton in find_child("ViewTypesButtonContainer").get_children():
		if button.button_pressed:
			view = button.page_view
			break
	
	return view

func set_save_path(value:String):
	var parts = value.split("/")
	active_file_name = parts[parts.size() - 1]
	active_dir = value.trim_suffix(active_file_name)
	find_child("SavePathLabel").text = str(active_dir, active_file_name)
	DiisisEditorUtil.set_project_file_path(active_dir, active_file_name)

func _process(delta: float) -> void:
	if not is_open:
		return
	if not active_dir.is_empty() and has_saved:
		time_since_last_save += delta
	
	if undo_redo_count_at_last_save != undo_redo.get_history_count():
		auto_save_timer -= delta
	
	if auto_save_timer <= 0.0:
		auto_save_timer = AUTO_SAVE_INTERVAL
		save_to_file(str(BACKUP_PATH, Time.get_datetime_string_from_system().replace(":", "-"), ".json"), true)

func _shortcut_input(event):
	if event is InputEventKey:
		if not event.pressed:
			return
		
		if event.key_label == KEY_F1:
			OS.shell_open("https://github.com/SnekOfSpice/dialog-editor/wiki/")
		
		if event.is_ctrl_pressed():
			match event.key_label:
				KEY_N:
					emit_signal("open_new_file")
				KEY_S:
					attempt_save_to_dir()
				KEY_F:
					open_popup($Popups.get_node("TextSearchPopup"))
				KEY_Z:
					if event.is_shift_pressed():
						undo_redo.redo()
						update_undo_redo_buttons()
					else:
						undo_redo.undo()
						update_undo_redo_buttons()
				KEY_Y:
					undo_redo.redo()
					update_undo_redo_buttons()
				KEY_O:
					if active_dir != "":
						$Popups.get_node("FDOpen").current_dir = active_dir
					open_popup($Popups.get_node("FDOpen"), true)
				KEY_A:
					add_line_to_end_of_page()
				KEY_1:
					select_line_type(DIISIS.LineType.Text)
				KEY_2:
					select_line_type(DIISIS.LineType.Choice)
				KEY_3:
					select_line_type(DIISIS.LineType.Instruction)
				KEY_4:
					select_line_type(DIISIS.LineType.Folder)
				KEY_MINUS:
					emit_signal("scale_editor_down")
				KEY_PLUS:
					emit_signal("scale_editor_up")
		if event.is_alt_pressed():
			match event.key_label:
				KEY_LEFT:
					if event.is_ctrl_pressed():
						request_load_first_page()
					else:
						request_load_previous_page()
				KEY_RIGHT:
					if event.is_ctrl_pressed():
						request_load_last_page()
					else:
						request_load_next_page()
				KEY_A:
					if event.is_shift_pressed():
						request_add_last_page()
					else:
						request_add_page_after_current()
				
				

func set_graph_view_visible(value:bool):
	core.visible = not value
	$GraphView.visible = value
	
func update_controls():
	if not current_page:
		return
	
	find_child("First").disabled = current_page.number <= 0
	find_child("Prev").disabled = current_page.number <= 0
	find_child("Next").disabled = current_page.number >= Pages.get_page_count() - 1
	find_child("Last").disabled = current_page.number >= Pages.get_page_count() - 1
	find_child("GoTo").set_current_page_count(str(current_page.number))
	find_child("GoTo").set_page_count(str(Pages.get_page_count() - 1))
	find_child("DeleteCurrent").disabled = Pages.get_page_count() == 1
	
	await get_tree().process_frame
	current_page.update()

func get_current_page_number() -> int:
	if not current_page:
		return 0
	return current_page.number

func has_open_popup() -> bool:
	for popup in $Popups.get_children():
		if popup.visible:
			return true
	return false

func _on_first_pressed() -> void:
	request_load_first_page()

func _on_last_pressed() -> void:
	request_load_last_page()

func _on_prev_pressed() -> void:
	request_load_previous_page()


func _on_next_pressed() -> void:
	request_load_next_page()


func request_load_previous_page():
	request_load_page(current_page.number - 1, "Move to previous page")

func request_load_next_page():
	request_load_page(current_page.number + 1, "Move to next page")

func request_load_first_page():
	request_load_page(0, "Move to first page")

func request_load_last_page():
	request_load_page(Pages.get_page_count() - 1, "Move to last page")

func _on_add_last_pressed() -> void:
	request_add_last_page()
func request_add_last_page():
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
	request_add_page_after_current()

func request_add_page_after_current():
	request_add_page(get_current_page_number() + 1)

func request_add_page(at:int, page_reference_change:=1):
	undo_redo.create_action("Insert page")
	undo_redo.add_do_method(DiisisEditorActions.add_page.bind(at, page_reference_change))
	undo_redo.add_do_method(DiisisEditorActions.load_page.bind(at))
	undo_redo.add_undo_method(DiisisEditorActions.load_page.bind(get_current_page_number()))
	undo_redo.add_undo_method(DiisisEditorActions.delete_page.bind(at))
	undo_redo.commit_action()

func open_save_popup():
	if active_dir != "":
		$Popups.get_node("FDSave").current_dir = active_dir
	open_popup($Popups.get_node("FDSave"), true)

func save_to_file(path:String, is_autosave:=false):
	if current_page and not is_autosave:
		current_page.save()
	
	if path.begins_with(BACKUP_PATH):
		if not DirAccess.dir_exists_absolute(BACKUP_PATH):
			DirAccess.make_dir_absolute(BACKUP_PATH)
	
	var file = FileAccess.open(path, FileAccess.WRITE)
	
	var data_to_save = Pages.serialize()
	file.store_string(JSON.stringify(data_to_save, "\t"))
	file.close()
	if is_autosave:
		notify(str("Autosaved to ", ProjectSettings.globalize_path(path), "!"))
	else:
		set_save_path(path)
		time_since_last_save = 0.0
		last_system_save = Time.get_time_dict_from_system()
		has_saved = true
	
		notify(str("Saved to ", active_file_name, "!"))
	
	undo_redo_count_at_last_save = undo_redo.get_history_count()

func _on_fd_save_file_selected(path: String) -> void:
	save_to_file(path)

func open_from_path(path:String):
	var file = FileAccess.open(path, FileAccess.READ)
	
	if not file:
		return
	
	var data : Dictionary = JSON.parse_string(file.get_as_text())
	file.close()
	
	set_save_path(path)
	
	Pages.deserialize(data)
	find_child("File").set_item_checked(8, Pages.empty_strings_for_l10n)
	
	load_page(0, true)

func _on_fd_open_file_selected(path: String) -> void:
	open_from_path(path)

func request_go_to_address(address:String, action_message:=""):
	if action_message.is_empty():
		action_message = str("Go to ", address)
	else:
		action_message = str(action_message, "(Go to ", address,  ")")
	undo_redo.create_action(action_message)
	undo_redo.add_do_method(DiisisEditorActions.go_to.bind(address))
	undo_redo.add_undo_method(DiisisEditorActions.go_to.bind(str(get_current_page_number())))
	undo_redo.commit_action()

func request_load_page(number:int, action_message:String):
	request_go_to_address(str(number), action_message)

func notify(message:String, duration:=5.0):
	var notification = load("res://addons/diisis/editor/src/editor_notification.tscn").instantiate()
	$NotificationContainer.add_child(notification)
	notification.init(message, duration)

func _on_add_line_button_pressed() -> void:
	add_line_to_end_of_page()

func add_line_to_end_of_page():
	undo_redo.create_action("Add Line")
	var line_count = current_page.get_line_count()
	DiisisEditorActions.blank_override_line_addresses.append(str(get_current_page_number(), ".", line_count))
	undo_redo.add_do_method(DiisisEditorActions.add_line.bind(line_count))
	undo_redo.add_undo_method(DiisisEditorActions.delete_line.bind(line_count))
	undo_redo.commit_action()


func _on_header_popup_update() -> void:
	await get_tree().process_frame
	current_page.update()

func _on_instruction_definition_timer_timeout() -> void:
	find_child("ErrorTextBox").text = Pages.get_all_invalid_instructions()

func _on_instruction_popup_validate_saved_instructions() -> void:
	find_child("ErrorTextBox").text = Pages.get_all_invalid_instructions()

func update_undo_redo_buttons():
	find_child("UndoButton").disabled = not undo_redo.has_undo()
	find_child("RedoButton").disabled = not undo_redo.has_redo()
	
	find_child("LastUndoStepLabel").text = undo_redo.get_current_action_name()#undo_redo.get_history_count()

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
		popup.size.y -= 50
		popup.size.x -= 50
	
	popup.content_scale_factor = content_scale
	Pages.editor.refresh()
	popup.popup()
	popup.grab_focus()
	
	popup.size.x = min(popup.size.x, size.x)
	popup.size.y = min(popup.size.y, size.y)
	popup.position.y = max(popup.position.y, 20)


func _on_setup_index_pressed(index: int) -> void:
	match index:
		1: # header
			open_popup($Popups.get_node("HeaderPopup"))
		2: # dd
			open_popup($Popups.get_node("DropdownPopup"))
		3: # instr
			open_popup($Popups.get_node("InstructionPopup"))
		5: # facts
			open_popup($Popups.get_node("FactsPopup"))
		6: # pages
			open_popup($Popups.get_node("MovePagePopup"))

func _on_utility_index_pressed(index: int) -> void:
	match index:
		0: 
			open_popup($Popups.get_node("WordCountDialog"))
		1: 
			open_popup($Popups.get_node("TextSearchPopup"))

# opens opoup if active_dir isn't set, otherwise saves to file
func attempt_save_to_dir():
	if active_dir.is_empty():
		open_save_popup()
		return
	save_to_file(str(active_dir, active_file_name))

func _on_file_id_pressed(id: int) -> void:
	match id:
		0: #save
			attempt_save_to_dir()
		1: # save as
			open_save_popup()
		2:
			# open
			if active_dir != "":
				$Popups.get_node("FDOpen").current_dir = active_dir
			open_popup($Popups.get_node("FDOpen"), true)
		3:
			# config
			open_popup($Popups.get_node("FileConfigPopup"), true)
		5: # locales
			open_popup($Popups.get_node("LocaleSelectionWindow"), true)
		6: # export blank l10n
			open_popup($Popups.get_node("FDExportLocales"), true)
		8:
			Pages.empty_strings_for_l10n = not Pages.empty_strings_for_l10n
			find_child("File").set_item_checked(9, Pages.empty_strings_for_l10n)
		9:
			emit_signal("open_new_file")


func _on_funny_debug_button_pressed() -> void:
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

func _on_fd_export_locales_dir_selected(dir: String) -> void:
	var addresses : Dictionary = Pages.get_localizable_addresses_with_content()
	for locale in Pages.locales_to_export:
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



func align_menu_item(menu_item:PopupMenu):
	var menu_bar = find_child("MenuBar")
	menu_item.position.x = (menu_item.position.x) * content_scale
	menu_item.position.y += (menu_bar.size.y) * content_scale - menu_bar.size.y
	menu_item.size *= content_scale * 1.01

func _on_file_visibility_changed() -> void:
	align_menu_item(find_child("File"))


func _on_setup_visibility_changed() -> void:
	align_menu_item(find_child("Setup"))


func _on_utility_visibility_changed() -> void:
	align_menu_item(find_child("Utility"))
