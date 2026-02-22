@tool
extends Control
class_name DiisisEditor


signal request_template_setup(template_id : int)


const AUTO_SAVE_INTERVAL := 900.0 # 15 mins
const BACKUP_PATH := "user://DIISIS_autosave/"
const RECENT_FILES_PATH := "user://recents.json"
const RECENT_FILE_SEPARATOR := "  ||  "
var auto_save_timer := AUTO_SAVE_INTERVAL
var is_open := false
var opening := true # spaghetti yum
var undo_redo_count_at_last_save := 0

var undo_redo = UndoRedo.new()
var core:Control
var page_container:Control

var content_scale := 1.0


#var active_file_name := ""
var active_path := "":
	set(path):
		active_path = path
		ProjectSettings.set_setting("diisis/project/file/path", path)
		ProjectSettings.save()
		DiisisEditorEventBus.active_path_set.emit(path)
var active_dir : String:
	get():
		if active_path.is_empty():
			return ""
		var parts = active_path.split("/")
		var file_name : String = parts[parts.size() - 1]
		return active_path.trim_suffix(file_name)
var active_file : String:
	get():
		if active_path.is_empty():
			return ""
		var parts = active_path.split("/")
		return parts[parts.size() - 1]
var time_since_last_save := 0.0
var error_update_countdown := 0.0
var last_system_save := {}
var has_saved := false
var altered_history := false
var was_playing_scene := false

enum PageView {
	Full,
	Truncated,
	Minimal
}

var embed_init := false


signal scale_editor_up()
signal scale_editor_down()
signal open_new_file()
signal request_reload()
#signal save_path_set(active_dir:String, active_file_name:String)
signal save_path_set(path:String)
signal history_altered(is_altered:bool)

const DELETE_MODULATE := "#cfa2bfb3"

func get_current_page() -> Page:
	if page_container.get_child_count() > 0:
		if page_container.get_child(0) is Page:
			return page_container.get_child(0)
	return null

func refresh(serialize_before_load:=true, fragile:=false):
	var goto_has_focus : bool = find_child("GoTo").address_bar_has_focus()
	var cpn:int
	if get_current_page():
		cpn = get_current_page().number
	else:
		return
	if serialize_before_load:
		get_current_page().save()
	await get_tree().process_frame
	if fragile:
		for node in get_tree().get_nodes_in_group("diisis_fragile"):
			node.update_fragile()
	else:
		load_page(cpn, not serialize_before_load)
	
	await get_tree().process_frame
	if goto_has_focus:
		find_child("GoTo")._address_bar_grab_focus()


func _exit_tree() -> void:
	Pages.editor = null

var recents_item : PopupMenu
func init(active_file_path:="") -> void:
	Pages.editor = self
	set_opening_cover_visible(true)
	set_importing_cover_visible(false)
	was_playing_scene = EditorInterface.is_playing_scene()
	Pages.clear()
	DiisisEditorActions.clear()
	opening = true
	core = find_child("Core")
	page_container = core.find_child("PageContainer")
	
	Pages.connect("pages_modified", update_controls)
	
	is_open = true
	
	request_add_page(0, 0)
	DiisisEditorEventBus.active_path_set.connect(_on_active_path_set)
	
	update_controls()
	
	var text_size_button : OptionButton = %TextSizeButton
	text_size_button.clear()
	
	for s in Pages.FONT_SIZES:
		text_size_button.add_item(str(s))
	text_size_button.select(2)
	
	tree_entered.connect(on_tree_entered)
	
	core.visible = true
	undo_redo.clear_history()
	undo_redo.version_changed.connect(update_undo_redo_buttons)
	update_undo_redo_buttons()
	
	for popup : Window in $Popups.get_children():
		popup.visible = false
		popup.exclusive = false
		popup.always_on_top = not DiisisEditorUtil.embedded
		popup.wrap_controls = true
		popup.transient = false
		popup.popup_window = false
		popup.initial_position = Window.WINDOW_INITIAL_POSITION_CENTER_SCREEN_WITH_MOUSE_FOCUS
		popup.theme = theme
		popup.add_to_group("diisis_scalable_popup")
	
	find_child("ShowErrorsButton").button_pressed = false
	var file_item : PopupMenu = %File
	recents_item = PopupMenu.new()
	%File.add_child(recents_item)
	recents_item.index_pressed.connect(func(index:int):
		var recent_path := recents_item.get_item_text(index)
		recent_path = recent_path.split(RECENT_FILE_SEPARATOR)[1]
		open_from_path(recent_path))
	file_item.add_submenu_node_item("Recent", recents_item)
	update_recents_item()
	file_item.add_separator()
	file_item.add_item("Import    (Shift+I)", 6)
	file_item.add_item("Export    (Shift+E)", 5)
	file_item.add_separator()
	# nts those submenus have to be invisible otherwise they break for the first hover
	
	file_item.add_submenu_node_item("Localization", file_item.get_node("L10NMenu"))
	file_item.add_item("Open with Ctrl + ...")
	file_item.set_item_disabled(file_item.item_count - 1, true)
	
	%Editor.set_item_disabled(0, DiisisEditorUtil.embedded)
	
	var utility_item : PopupMenu = %Utility
	if Pages.silly:
		utility_item.add_separator("Silly")
		utility_item.add_submenu_node_item("Find in Library of Babel", %LibraryOfBabel)
	utility_item.add_item("Open with Ctrl + ...")
	utility_item.set_item_disabled(utility_item.item_count - 1, true)
	
	if DiisisEditorUtil.embedded:
		%Setup.add_separator("Project")
		%Setup.add_submenu_node_item("Templates", %TemplatesMenu)
	%Setup.add_item("Open with Ctrl + ...")
	%Setup.set_item_disabled(%Setup.item_count - 1, true)
	
	open_from_path(active_file_path)
	
	undo_redo.version_changed.connect(set_altered_history.bind(true))
	
	if not Pages.shader.is_empty():
		var layer = CanvasLayer.new()
		add_child(layer)
		var rect = ColorRect.new()
		rect.set_anchors_preset(Control.PRESET_FULL_RECT)
		rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		layer.add_child(rect)
		var mat = ShaderMaterial.new()
		mat.shader = load(Pages.shader)
		rect.material = mat
	
	await get_tree().process_frame
	
	if active_file_path == "user://import_override_temp.json":
		set_importing_cover_visible(true)
		var access = FileAccess.open("user://import_override_temp.json", FileAccess.READ)
		var data = JSON.parse_string(access.get_as_text())
		access.close()
		set_save_path(data.get("original_path"))
		
		await get_tree().process_frame
		
		
		var d = DirAccess.remove_absolute("user://import_override_temp.json")
		await get_tree().process_frame
		load_page(0)
		await get_tree().process_frame
		step_through_pages()
	elif active_file_path.is_empty():
		await get_tree().process_frame
		opening = false
		if Pages.evaluator_paths.is_empty():
			Pages.evaluator_paths = get_line_reader_scripts()
	
	%EmbedHint.visible = DiisisEditorUtil.embedded
	if DiisisEditorUtil.embedded:
		%UpdateAvailable.check_for_updates()
		%SillyCompanionEmbedLabel.text = Pages.make_puppy() if Pages.silly else ""
		if active_file_path.is_empty():
			%FilePathLabel.text = "~unsaved~"
	if not DiisisEditorUtil.embedded:
		# CRITICAL do not touch this camera. i can't remember why we need it but the editor won't be visible without it lmao
		var cam := Camera2D.new()
		add_child(cam)
	
	save_to_recent_files(active_file_path)
	

func on_tree_entered():
	for c in get_tree().get_nodes_in_group("editor_popup_button"):
		c.init()

func set_altered_history(value:bool):
	altered_history = value
	emit_signal("history_altered", altered_history)

func set_content_scale(factor:float):
	content_scale = factor
	var bar : MenuBar = find_child("MenuBar")
	bar.get_node("File").content_scale_factor = factor
	bar.get_node("Utility").content_scale_factor = factor
	bar.get_node("Setup").content_scale_factor = factor
	
	for window : Window in $Popups.get_children():
		window.content_scale_factor = content_scale

func update_page_view(view:PageView):
	Pages.editor_page_view = view
	for node in get_tree().get_nodes_in_group("diisis_page_view_sensitive"):
		node.set_page_view(view)

func load_page(number: int, discard_without_saving:=false):
	if opening:
		return
	await get_tree().process_frame
	number = clamp(number, 0, Pages.get_page_count() - 1)
	for page in page_container.get_children():
		if not discard_without_saving:
			page.save()
	
	var page_instance:Page
	if page_container.get_child_count() == 0:
		page_instance = preload("res://addons/diisis/editor/src/page.tscn").instantiate()
		page_container.add_child(page_instance)
		Pages.apply_font_size_overrides(page_instance)
	else:
		page_instance = page_container.get_child(0)
	if not page_instance.is_connected("request_delete", request_delete_current_page):
		page_instance.request_delete.connect(request_delete_current_page)
	
	page_instance.init(number)
	update_controls()
	await get_tree().process_frame
	set_opening_cover_visible(false)
	
	if not get_save_path().is_empty():
		Pages.current_page_number_by_file_name.set(get_save_path(), number)

func get_line_data(index:int):
	return 

func get_selected_line_type() -> int:
	var line_type:=DIISIS.LineType.Text
	
	for button in find_child("LineTypes").get_children():
		if not button is LineTypeButton:
			continue
		if button.button_pressed:
			line_type = button.line_type
			break
	
	return line_type

func select_line_type(line_type:int):
	for button in find_child("LineTypes").get_children():
		if not button is LineTypeButton:
			continue
		if button.line_type == line_type:
			button.button_pressed = true

func get_selected_page_view() -> PageView:
	var view:=PageView.Full
	
	for button : PageViewButton in find_child("ViewTypesButtonContainer").get_children():
		if button.button_pressed:
			view = button.page_view
			break
	
	return view

# TODO
func get_save_path() -> String:
	return active_path

func set_save_path(path:String):
	#var parts = value.split("/")
	#var new_file_name : String = parts[parts.size() - 1]
	#var new_dir : String = value.trim_suffix(new_file_name)
	#if new_dir == active_dir and new_file_name == active_file_name:
	if path == active_path:
		return
	#active_file_name = new_file_name
	#active_dir = value.trim_suffix(active_file_name)
	active_path = path

func _process(delta: float) -> void:
	if not is_open:
		return
	
	if not was_playing_scene and EditorInterface.is_playing_scene():
		if Pages.save_on_play:
			save_to_dir_if_active_dir()
	was_playing_scene = EditorInterface.is_playing_scene()
	
	if not active_path.is_empty() and has_saved:
		time_since_last_save += delta
	
	if undo_redo_count_at_last_save != undo_redo.get_history_count():
		auto_save_timer -= delta
	
	if auto_save_timer <= 0.0:
		auto_save_timer = AUTO_SAVE_INTERVAL
		save_to_file(str(BACKUP_PATH, Time.get_datetime_string_from_system().replace(":", "-"), ".json"), true)
	
	if error_update_countdown > 0 and error_update_countdown - delta <= 0:
		update_error_text_box()
	error_update_countdown -= delta
	
var ctrl_down := false
var focused_control_before_ctrl:Control
func _shortcut_input(event):
	if not visible:
		return
	if event is InputEventKey:
		# on linux (or at least my steam deck), there's a bug where ctrl shortcuts still send their key inputs
		# so e.g. ctrl+s to save also inserts an s in a text edit if it's currently focused
		# this takes the focus away while holding down ctrl
		# it's kinda scuffed ngl
		if event.key_label == KEY_CTRL and OS.get_name() == "Linux":
			var prev_ctrl_down = ctrl_down
			var ctrl_start:bool
			var ctrl_release:bool
			if event.pressed:
				if not prev_ctrl_down:
					ctrl_start = true
					focused_control_before_ctrl = get_viewport().gui_get_focus_owner()
				ctrl_down = true
			else:
				if prev_ctrl_down:
					ctrl_release = true
				ctrl_down = false
			
			if ctrl_start or ctrl_release:
				if ctrl_release:
					if focused_control_before_ctrl:
						var scroll := -1
						if focused_control_before_ctrl is TextEdit or focused_control_before_ctrl is LineEdit:
							scroll = get_current_page().find_child("ScrollContainer").scroll_vertical
						focused_control_before_ctrl.grab_focus()
						if scroll != -1:
							await get_tree().process_frame
							get_current_page().find_child("ScrollContainer").set_deferred("scroll_vertical", scroll)
						focused_control_before_ctrl = null
				elif ctrl_start:
					grab_focus()
				return
		if not event.pressed:
			return
		
		match event.key_label:
			KEY_F1:
				OS.shell_open("https://github.com/SnekOfSpice/dialog-editor/wiki/")
			KEY_F5:
				EditorInterface.play_main_scene()
			KEY_F6:
				EditorInterface.play_current_scene()
			KEY_F8:
				EditorInterface.stop_playing_scene()
			
		if event.is_command_or_control_pressed():
			match event.key_label:
				KEY_E:
					if event.is_shift_pressed():
						open_window_by_string("TextExportWindow")
					else:
						get_current_page().set_editing_page_key(true)
				KEY_G:
					find_child("GoTo").toggle_active()
				KEY_N:
					emit_signal("open_new_file")
				KEY_S:
					attempt_save_to_dir()
				KEY_I:
					if event.is_shift_pressed():
						open_window_by_string("TextImportWindow")
					else:
						open_window_by_string("IngestionActorSetupWindow")
				KEY_F:
					if event.is_shift_pressed():
						open_popup($Popups.get_node("FactsPopup"))
					else:
						open_window_by_string("TextSearchPopup")
				KEY_T:
					open_popup($Popups.get_node("MovePagePopup"))
				KEY_D:
					open_popup($Popups.get_node("StringkitWindow"))
				KEY_H:
					open_popup($Popups.get_node("DialogConfigWindow"))
				KEY_R:
					open_popup($Popups.get_node("HandlerWindow"), true)
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
				#KEY_A:
					#add_line_to_end_of_page()
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
				KEY_LEFT, KEY_A:
					if event.is_command_or_control_pressed():
						request_load_first_page()
					else:
						request_load_previous_page()
				KEY_RIGHT, KEY_D:
					if event.is_command_or_control_pressed():
						request_load_last_page()
					else:
						request_load_next_page()
				KEY_S:
					if event.is_shift_pressed():
						request_add_last_page()
					else:
						request_add_page_after_current()
				
	
func update_controls():
	var current_page := get_current_page()
	if not current_page:
		await get_tree().process_frame
		if not current_page:
			#var page_instance:Page
			#if page_container.get_child_count() == 0:
				#page_instance = _page.instantiate()
				#page_container.add_child(page_instance)
#
			#if not page_instance.is_connected("request_delete", request_delete_current_page):
					#page_instance.request_delete.connect(request_delete_current_page)
			return
	find_child("First").disabled = current_page.number <= 0
	find_child("Prev").disabled = current_page.number <= 0
	find_child("Next").disabled = current_page.number >= Pages.get_page_count() - 1
	find_child("Last").disabled = current_page.number >= Pages.get_page_count() - 1
	find_child("GoTo").set_current_page_count(str(current_page.number))
	find_child("GoTo").set_page_count(str(Pages.get_page_count() - 1))
	
	await get_tree().process_frame
	current_page.update()

func get_current_page_number() -> int:
	if not get_current_page():
		return 0
	return get_current_page().number

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
	request_load_page(get_current_page().number - 1, "Move to previous page")

func request_load_next_page():
	request_load_page(get_current_page().number + 1, "Move to next page")

func request_load_first_page():
	request_load_page(0, "Move to first page")

func request_load_last_page():
	request_load_page(Pages.get_page_count() - 1, "Move to last page")

func _on_add_last_pressed() -> void:
	request_add_last_page()
func request_add_last_page():
		request_add_page(Pages.get_page_count())

func request_delete_current_page():
	request_delete_page(get_current_page_number())

func request_delete_page(number:int) -> void:
	if Pages.get_page_count() <= 1:
		push_warning("you cannot delete the last page")
		return
	
	if number == 0:
		notify("You cannot delete page of index 0")
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
	if get_current_page() and not is_autosave:
		get_current_page().save()
	
	if path.begins_with(BACKUP_PATH):
		if not DirAccess.dir_exists_absolute(BACKUP_PATH):
			DirAccess.make_dir_absolute(BACKUP_PATH)
	
	if not is_autosave:
		Pages.purge_unused_text_ids()
	
	var file = FileAccess.open(path, FileAccess.WRITE)
	
	var data_to_save = {}
	# there used to be editor here
	# dont need it anymore but lets keep the nesting for compatibility and future versions
	data_to_save["pages"] = Pages.serialize()
	file.store_string(JSON.stringify(data_to_save, "\t"))
	file.close()
	if is_autosave:
		notify(str("Autosaved to [url=",ProjectSettings.globalize_path(path),"]", ProjectSettings.globalize_path(path), "!"))
	else:
		set_save_path(path)
		time_since_last_save = 0.0
		last_system_save = Time.get_time_dict_from_system()
		has_saved = true
		set_altered_history(false)
	
		notify(str("Saved to ", active_file, "!"))
		
		save_to_recent_files(active_path)
		
	undo_redo_count_at_last_save = undo_redo.get_history_count()
	
	await get_tree().process_frame
	refresh()


func get_recent_files() -> Array:
	var recent_files := FileAccess.open(RECENT_FILES_PATH, FileAccess.READ)
	if recent_files.get_length() == 0:
		return []
	var recent_data : Array = JSON.parse_string(recent_files.get_as_text()) 
	print(recent_data)
	recent_files.close()
	return recent_data


func save_to_recent_files(path : String) -> void:
	var recent_files := FileAccess.open(RECENT_FILES_PATH, FileAccess.READ)
	#if not recent_files:
		#return
	var recent_data : Array
	if recent_files.get_length() > 0:
		recent_data = JSON.parse_string(recent_files.get_as_text())
	else:
		recent_data = []
	
	recent_files = FileAccess.open(RECENT_FILES_PATH, FileAccess.WRITE)
	if recent_data.has(path):
		recent_data.erase(path)
	recent_data.insert(0, path)
	if recent_data.size() > 10:
		recent_data.resize(10)
	
	recent_files.store_string(JSON.stringify(recent_data, "\t"))
	recent_files.close()
	
	update_recents_item()


func _on_fd_save_file_selected(path: String) -> void:
	save_to_file(path)

func set_opening_cover_visible(value:bool):
	$OpeningCover.visible = value
func set_importing_cover_visible(value:bool):
	$ImportingCover.visible = value

func open_from_path(path:String):
	var file = FileAccess.open(path, FileAccess.READ)
	%OpeningCover.show()
	if not file:
		set_opening_cover_visible(false)
		return
	
	var data : Dictionary = JSON.parse_string(file.get_as_text())
	file.close()
	
	save_to_recent_files(path)
	set_save_path(path)
	Pages.deserialize(data.get("pages"))
	
	await get_tree().process_frame
	
	for button : PageViewButton in find_child("ViewTypesButtonContainer").get_children():
		if not button.pressed.is_connected(update_page_view):
			button.pressed.connect(update_page_view.bind(button.page_view))
	
	await get_tree().process_frame
	set_text_size(Pages.editor_text_size_id)
	%TextSizeButton.select(Pages.editor_text_size_id)
	update_page_view(Pages.editor_page_view)
	
	await get_tree().process_frame
	opening = false
	load_page(Pages.current_page_number_by_file_name.get(get_save_path(), 0), true)

func _on_fd_open_file_selected(path: String) -> void:
	open_from_path(path)

func request_go_to_address(address:String, action_message:=""):
	if action_message.is_empty():
		action_message = str("Go to ", address)
	else:
		action_message = str(action_message, " (Go to ", address,  ")")
	undo_redo.create_action(action_message)
	undo_redo.add_do_method(DiisisEditorActions.go_to.bind(address))
	undo_redo.add_undo_method(DiisisEditorActions.go_to.bind(str(get_current_page_number())))
	undo_redo.commit_action()

func request_load_page(number:int, action_message:=""):
	DiisisEditorUtil.block_next_flash_highlight = true
	request_go_to_address(str(number), action_message)

func notify(message:String, duration:=5.0):
	var notification = load("res://addons/diisis/editor/src/editor_notification.tscn").instantiate()
	$NotificationContainer.add_child(notification)
	$NotificationContainer.move_child(notification, 0)
	notification.init(message, duration)
	Pages.apply_font_size_overrides(notification)

func _on_add_line_button_pressed() -> void:
	add_line_to_end_of_page()

func add_line_to_end_of_page(data:={}):
	undo_redo.create_action("Add Line")
	var line_count = get_current_page().get_line_count()
	DiisisEditorActions.blank_override_line_addresses.append(str(get_current_page_number(), ".", line_count))
	undo_redo.add_do_method(DiisisEditorActions.add_line.bind(line_count, data))
	undo_redo.add_undo_method(DiisisEditorActions.delete_line.bind(line_count))
	undo_redo.commit_action()


func _on_instruction_definition_timer_timeout() -> void:
	update_error_text_box()

func update_error_text_box():
	var error_text_box : RichTextLabel = find_child("ErrorTextBox")
	var invalid_instructions : String = Pages.get_all_invalid_instructions()
	error_text_box.text = ""
	if not error_text_box.text.is_empty() and Pages.evaluator_paths.is_empty():
		error_text_box.text += "Function errors are present but no evaluating LineReader has been defined. Consider defining one in [url=open-HandlerWindow-1]Setup > Functions & Variables[/url]. "
	
	error_text_box.text += invalid_instructions
	error_text_box.text += Pages.get_all_invalid_address_pointers()
	
	for node in get_tree().get_nodes_in_group("diisis_method_validator"):
		node.update_compliance_prompt()

func _on_instruction_popup_validate_saved_instructions() -> void:
	update_error_text_box()

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


func open_popup(popup:Window, fit_to_size:=false):
	if not popup:
		push_warning("No popup set.")
		return
	if fit_to_size:
		popup.size = size
		popup.size.y -= 50
		popup.size.x -= 50
	
	popup.content_scale_factor = content_scale
	refresh()
	popup.popup()
	popup.grab_focus()
	
	popup.size.x = min(popup.size.x, size.x)
	popup.size.y = min(popup.size.y, size.y)
	popup.position.y = max(popup.position.y, 35)
	
	popup.content_scale_factor = content_scale
	popup.size *= content_scale


func hide_window_by_string(window_name:String) -> Window:
	var window : Window = $Popups.get_node(window_name)
	window.close_requested.emit()
	return window


func open_window_by_string(window_name:String) -> Window:
	var window : Window = $Popups.get_node(window_name)
	open_popup(window, window_name in [
		"HandlerWindow",
		"FactsPopup",
		"TextExportWindow",
		"TextImportWindow",
		"FileConfigPopup",
	])
	return window

func open_handler_window(method_to_select:=""):
	var window := open_window_by_string("HandlerWindow")
	window.select_function(method_to_select)

func open_facts_window(fact_to_select:=""):
	var window := open_window_by_string("FactsPopup")
	window.get_child(0).select_fact(fact_to_select)

# opens popup if active_dir isn't set, otherwise saves to file
func attempt_save_to_dir():
	if active_path.is_empty():
		open_save_popup()
		return
	save_to_file(active_path)

func save_to_dir_if_active_dir():
	if not active_path.is_empty():
		save_to_file(active_path)

#region MenuBar

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
		
		5:
			open_window_by_string("TextExportWindow")
		6:
			open_window_by_string("TextImportWindow")
		#8:
			#Pages.empty_strings_for_l10n = not Pages.empty_strings_for_l10n
			#%File.set_item_checked(9, Pages.empty_strings_for_l10n)
		9:
			emit_signal("open_new_file")

func _on_l_10n_menu_id_pressed(id: int) -> void:
	match id:
		0: # locales
			open_popup($Popups.get_node("LocaleSelectionWindow"), true)
		1: # export blank l10n
			open_popup($Popups.get_node("FDExportLocales"), true)
		2: #merge
			open_popup($Popups.get_node("FDMergeL10N"), true)

func _on_editor_id_pressed(id: int) -> void:
	match id:
		0:
			emit_signal("request_reload")
		1:
			open_window_by_string("PunctuationRulesWindow")
		3:
			# config
			open_window_by_string("FileConfigPopup")
		4:
			popup_accept_dialogue(
				str(
					"[center][color=#f51068][b]DIISIS is a machine of gore and wires[/b][/color]", "\n\n",
					"[color=#ffffff][b]DIISIS is antifascist software[/b][/color]", "\n\n",
					"[color=#ff42d6][b]DIISIS loves you[/b][/color][/center]",
				),
				"About DIISIS"
			)
		5:
			OS.shell_open("https://github.com/SnekOfSpice/dialog-editor/wiki")

func _on_utility_id_pressed(id: int) -> void:
	match id:
		0: 
			var total : Vector2i = Pages.get_count_total()
			var total_with_skip : Vector2i = Pages.get_count_total(true)
			var on_page : Vector2i = Pages.get_count_on_page(get_current_page_number())
			var on_page_with_skip : Vector2i = Pages.get_count_on_page(get_current_page_number(), true)
			
			var total_word_skip_diff := ""
			var total_char_skip_diff := ""
			var page_word_skip_diff := ""
			var page_char_skip_diff := ""
			
			if total.x != total_with_skip.x:
				total_word_skip_diff = " (%s including skipped)" % total_with_skip.x
			if total.y != total_with_skip.y:
				total_char_skip_diff = " (%s including skipped)" % total_with_skip.y
			if on_page.x != on_page_with_skip.x:
				page_word_skip_diff = " (%s including skipped)" % on_page_with_skip.x
			if on_page.y != on_page_with_skip.y:
				page_char_skip_diff = " (%s including skipped)" % on_page_with_skip.y
			var dialog_text := str(
				"Total Word Count: [b]%s[/b] %s\n" % [total.x, total_word_skip_diff],
				"Total Character Count: [b]%s[/b] %s" % [total.y, total_char_skip_diff],
				"\n\n",
				"Word Count on page: [b]%s[/b] %s\n" % [on_page.x, page_word_skip_diff],
				"Character Count on page: [b]%s[/b] %s\n" % [on_page.y, page_char_skip_diff],
				"\n",
				"[wave amp=10.0 freq=-4 connected=1][color=f2e260]Note:[/color][/wave]",
				" Words are counted by spaces."
			)
			popup_accept_dialogue(dialog_text, "Word & Character Count")
		1: 
			open_window_by_string("TextSearchPopup")
		2:
			open_window_by_string("IngestionActorSetupWindow")
		3:
			step_through_pages()
		4:
			open_window_by_string("ActorSearchWindow")


func _on_setup_id_pressed(id: int) -> void:
	match id:
		1:
			open_popup($Popups.get_node("DialogConfigWindow"))
		2:
			open_popup($Popups.get_node("StringkitWindow"))
		3: # instr
			open_popup($Popups.get_node("HandlerWindow"), true)
		5: # facts
			open_popup($Popups.get_node("FactsPopup"), true)
		6: # pages
			if Pages.get_page_count() == 0:
				notify("No pages in file.") # popup relies on there being pages
				return
			open_popup($Popups.get_node("MovePagePopup"))
		8:
			open_window_by_string("DialogConfigWindow")

#endregion


func request_arg_hint(text_box:Control):
	if not (text_box is LineEdit or text_box is TextEdit):
		push_error(str("Tried calling request_arg_hint with object of type ", text_box.get_class()))
		return
	
	var caret_pos = Vector2i.ZERO
	#if text_box is TextEdit:
	caret_pos += Vector2i(text_box.get_caret_draw_pos())
	
	
	if text_box is LineEdit:
		caret_pos.x -= 50
		caret_pos.x = text_box.get_theme_font("font").get_string_size(text_box.text.substr(0, text_box.get_caret_column())).x
		#caret_pos.y += text_box.size.y
		caret_pos.y += Vector2i(text_box.global_position).y
	elif text_box is TextEdit:
		caret_pos += Vector2i(text_box.global_position)
	caret_pos *= content_scale
	caret_pos += Vector2(0, 10) * content_scale
	
	_place_arg_hint(caret_pos)
	
	text_box.set_caret_column(text_box.get_caret_column())
	text_box.call_deferred("grab_focus")

func _place_arg_hint(at:Vector2):
	(find_child("ArgHint") as DIISISArgHint).position = Vector2i(at)

func build_arg_hint(instruction_name:String, full_arg_text:String, caret_column:int, on_node : Control = null):
	(find_child("ArgHint") as DIISISArgHint).build(instruction_name, full_arg_text, caret_column, on_node)
	(find_child("ArgHint") as DIISISArgHint).popup()

func hide_arg_hint():
	find_child("ArgHint").hide()

func step_through_pages():
	var next_page = get_current_page_number() + 1
	if next_page >= Pages.get_page_count():
		next_page = 0
	var steps : int = Pages.get_page_count()
	var i := 0
	while i < steps:
		%ImportProgressLabel.text = "Regenerating page %s/%s" % [i+1, steps]
		load_page(next_page)
		await get_tree().process_frame
		next_page = get_current_page_number() + 1
		if next_page >= Pages.get_page_count():
			next_page = 0
		i += 1
	await get_tree().process_frame
	set_importing_cover_visible(false)


func _on_funny_debug_button_pressed() -> void:
	for id in Pages.text_data.keys():
		var id_count := 0
		for number in Pages.page_data.keys():
			var page_data = Pages.page_data.get(number)
			for line in page_data.get("lines"):
				#if line.get("id") == id:
					#id_count += 1
				if line.get("line_type") == DIISIS.LineType.Text:
					var tid = line.get("content").get("text_id")
					if tid == id:
						id_count += 1
		if id_count > 1:
			printt(id_count, id)
	return
	emit_signal("request_reload")
	return
	step_through_pages()
	return
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

func _on_fd_export_locales_file_selected(path: String) -> void:
	var l10n := {}
	for text_id in Pages.text_data.keys():
		var lines_by_locale := {
			"changed" : true,
			Pages.default_locale : Pages.get_text(text_id)
		}
		for locale in Pages.locales_to_export:
			if locale != Pages.default_locale:
				lines_by_locale[locale] = ""
		l10n[text_id] = lines_by_locale
	
	var file = FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(l10n, "\t"))
	file.close()


func _on_fd_merge_l_10n_file_selected(path: String) -> void:
	var input_file = FileAccess.open(path, FileAccess.READ)
	var input_data : Dictionary = JSON.parse_string(input_file.get_as_text())
	input_file.close()
	
	var l10n := {}
	var handled_locales := []
	for text_id in Pages.text_data.keys():
		var previous_default_text : String = input_data.get(text_id, {}).get(Pages.default_locale)
		var lines_by_locale := {
			"changed" : previous_default_text != Pages.get_text(text_id),
			Pages.default_locale : Pages.get_text(text_id)
		}
		
		for locale in Pages.locales_to_export:
			handled_locales.append(locale)
			if locale != Pages.default_locale and input_data.get(text_id).has(locale):
				lines_by_locale[locale] = input_data.get(text_id).get(locale)
		
		l10n[text_id] = lines_by_locale
	
	for text_id : String in input_data.keys():
		if not l10n.has(text_id):
			l10n[text_id] = {}
		for locale in input_data.get(text_id):
			if locale in handled_locales:
				continue
			var new_file_has_locale = l10n.get(text_id).has(locale)
			if not new_file_has_locale:
				l10n[text_id][locale] = input_data.get(text_id).get(locale)
	
	var file = FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(l10n, "\t"))
	file.close()

func _on_refresh_button_pressed() -> void:
	refresh()

func clipboard_set_notify(text:String) -> void:
	DisplayServer.clipboard_set(text)
	var message := "Copied to clipboard:\n"
	message += text.left(36)
	if text.length() > 36:
		message += "..."
	notify(message)

func handle_meta(meta:Variant):
	if str(meta).begins_with("goto-"):
		goto_with_meta(meta)
	elif str(meta).begins_with("copy-"):
		clipboard_set_notify(str(meta).trim_prefix("copy-"))
	elif str(meta).begins_with("open-"):
		var target_window := str(meta).trim_prefix("open-")
		open_window_by_string(target_window)

func goto_with_meta(meta:Variant):
	if str(meta).begins_with("goto-"):
		var target_address := str(meta).trim_prefix("goto-")
		request_go_to_address(target_address, str("Go to ", target_address))

func _on_error_text_box_meta_clicked(meta: Variant) -> void:
	meta = str(meta)
	if meta.begins_with("open-"):
		meta = meta.trim_prefix("open-")
		var callable_after_open
		if meta.begins_with("HandlerWindow"):
			var tab := int(meta.split("-")[1])
			meta = meta.split("-")[0]
			callable_after_open = $Popups/HandlerWindow.set_tab.bind(tab)
		open_window_by_string(meta)
		if callable_after_open:
			callable_after_open.call()
	else:
		goto_with_meta(meta)



func align_menu_item(menu_item:PopupMenu):
	var menu_bar = find_child("MenuBar")
	#menu_item.position.x = menu_item.position.x + ((menu_item.position.x) * content_scale)- ( menu_bar.size.y * content_scale)
	menu_item.position.x += (menu_bar.position.x * content_scale - menu_bar.position.x)
	menu_item.position.y += (menu_bar.size.y) * content_scale - menu_bar.size.y
	menu_item.size *= content_scale * 1.01

func _on_file_visibility_changed() -> void:
	align_menu_item(%File)


func _on_setup_visibility_changed() -> void:
	align_menu_item(%Setup)


func _on_utility_visibility_changed() -> void:
	align_menu_item(%Utility)


func _on_show_errors_button_toggled(toggled_on: bool) -> void:
	if toggled_on:
		find_child("ErrorTextBox").custom_minimum_size.y = 90
	else:
		find_child("ErrorTextBox").custom_minimum_size.y = find_child("ShowErrorsButton").size.y
		


func _on_text_size_button_item_selected(index: int) -> void:
	set_text_size(index)
	
func set_text_size(size_index:int):
	Pages.editor_text_size_id = size_index
	var label_size = Pages.FONT_SIZES[size_index]
	Pages.set_size_override(Pages.get_editor_window(), label_size)


func popup_ingest_file_dialog(context:Array):
	ingest_context = context
	$Popups.get_node("FDIngest").title = str("Ingest from file: ", "Page" if context[0] == "PAGE" else "Individual Line")
	open_popup($Popups.get_node("FDIngest"), true)

var ingest_context : Array # either line address or PAGE
func _on_fd_ingest_file_selected(path: String) -> void:
	if ingest_context[0] == "PAGE":
		TextToDiisis.ingest_pages_from_file(path, ingest_context[1])
	else:
		var text : String = TextToDiisis.format_text_from_file(path)
		
		if ingest_context[1].get("capitalize", false):
			text = Pages.capitalize_sentence_beginnings(text)
		if ingest_context[1].get("neaten_whitespace", false):
			text = Pages.neaten_whitespace(text)
		
		var parts : Array = DiisisEditorUtil.get_split_address(ingest_context[0])
		get_current_page().get_line(parts[1]).find_child("TextContent").set_text(text)

func prompt_change_text_id(id:String):
	var popup : Window = $Popups.get_node("ChangeTextIDWindow")
	open_popup(popup)
	popup.set_id(id)

func view_incoming_references(page_index:int, line_index:=-1):
	var popup : Window = $Popups.get_node("IncomingReferencesWindow")
	open_popup(popup)
	popup.display_references(page_index, line_index)

func popup_confirm_dialogue(rich_text:="", title:="", confirm_callable:=Callable()) -> RichTextConfirmationDialog:
	var dialog = preload("res://addons/diisis/editor/src/rich_text_confirmation_dialog.tscn").instantiate()
	$Popups.add_child(dialog)
	dialog.close_requested.connect(dialog.hide)
	if confirm_callable:
		dialog.confirmed.connect(confirm_callable)
	dialog.set_rich_text(rich_text)
	dialog.popup_centered()
	dialog.content_scale_factor = content_scale
	if not title.is_empty():
		dialog.title = title
	Pages.apply_font_size_overrides(dialog)
	return dialog
func popup_accept_dialogue(rich_text:="", title:="", at:=Vector2.ZERO) -> RichTextAcceptDialog:
	var dialog = preload("res://addons/diisis/editor/src/rich_text_accept_dialog.tscn").instantiate()
	$Popups.add_child(dialog)
	dialog.close_requested.connect(dialog.hide)
	dialog.set_rich_text(rich_text)
	dialog.popup_centered()
	dialog.content_scale_factor = content_scale
	if not title.is_empty():
		dialog.title = title
	if at != Vector2.ZERO:
		dialog.position = at
	if Pages.silly:
		dialog.ok_button_text = Pages.make_puppy()
	Pages.apply_font_size_overrides(dialog)
	return dialog

# returns true if the prompt got opened
func try_prompt_fact_deletion_confirmation(address:String, delete_callable:Callable) -> bool:
	if not Pages.warn_on_fact_deletion:
		return false
	
	var fact_data : Dictionary = Pages.get_fact_data_payload_before_deletion(address)
	if fact_data.is_empty():
		return false
	
	var dialog : RichTextConfirmationDialog = popup_confirm_dialogue()
	dialog.confirmed.connect(delete_callable)
	
	var text := ""
	var object_type_str : String
	match DiisisEditorUtil.get_address_depth(address):
		DiisisEditorUtil.AddressDepth.Page:
			object_type_str = "Page"
		DiisisEditorUtil.AddressDepth.Line:
			object_type_str = "Line"
		DiisisEditorUtil.AddressDepth.ChoiceItem:
			object_type_str = "Choice"
	
	var page_text := ""
	var line_text := ""
	var choice_text := ""
	for address_in_payload in fact_data.keys():
		for fact : Dictionary in fact_data.get(address_in_payload).values():
			if DiisisEditorUtil.get_address_depth(address_in_payload) == DiisisEditorUtil.AddressDepth.Page:
				page_text += str("    ", address_in_payload, ": ", fact.get("fact_name"), ": ", fact.get("fact_value"), "\n")
			if DiisisEditorUtil.get_address_depth(address_in_payload) == DiisisEditorUtil.AddressDepth.Line:
				line_text += str("    ", address_in_payload, ": ", fact.get("fact_name"), ": ", fact.get("fact_value"), "\n")
			if DiisisEditorUtil.get_address_depth(address_in_payload) == DiisisEditorUtil.AddressDepth.ChoiceItem:
				choice_text += str("    ", address_in_payload, ": ", fact.get("fact_name"), ": ", fact.get("fact_value"), "\n")
	
	if not page_text.is_empty(): page_text = "  = In Page:\n" + page_text
	if not line_text.is_empty(): line_text = "  = In Lines:\n" + line_text
	if not choice_text.is_empty(): choice_text = "  = In Choices:\n" + choice_text
	text = page_text + "\n" + line_text + "\n" + choice_text
	
	dialog.set_rich_text(str(
		"[b]The following object contains facts: ",
		object_type_str, " at address ", address,
		"[/b]\n",
		text,
		"\n",
		"[b]Are you sure you want to delete it?[/b]"
	))
	dialog.content_scale_factor = content_scale
	dialog.size *= content_scale
	
	return true


func _on_handler_window_close_requested() -> void:
	await get_tree().process_frame
	Pages.update_all_compliances()
	await get_tree().process_frame
	refresh()


func _on_file_config_popup_close_requested() -> void:
	get_current_page().update_incoming_references()


func _on_library_of_babel_index_pressed(index: int) -> void:
	var text : String
	var object_of_desire : String
	match index:
		0: # script
			text = Pages.get_text_on_all_pages()
			object_of_desire = "Script"
		1: # page
			text = Pages.get_text_on_page(get_current_page_number())
			object_of_desire = "Page %s" % get_current_page_number()
	
	text = Pages.remove_tags(text)
	
	text = text.to_lower()
	var allowed_characters = Pages.LETTERS.duplicate()
	allowed_characters.append(".")
	allowed_characters.append(",")
	allowed_characters.append(" ")
	for idx in text.length():
		if not text[idx] in allowed_characters:
			text.erase(idx)
			text.insert(idx, ".")
	
	var length_warning := ""
	if text.length() > 3200:
		length_warning = "The resulting text is larger than 3200 (%s) and will be trimmed down." % text.length()
		text = text.left(3200)
	
	var message := "%s contents have been copied to the clipboard. Have fun!" % object_of_desire
	if not length_warning.is_empty():
		message += "\n" + length_warning
	notify(message, 60)
	DisplayServer.clipboard_set(text)
	
	var t = get_tree().create_timer(2)
	t.timeout.connect(OS.shell_open.bind("https://libraryofbabel.info/search.html"))



func is_importing() -> bool:
	return $ImportingCover.visible



var found_handlers := []
func get_line_reader_scripts() -> Array:
	found_handlers.clear()
	_get_line_reader_scripts_r("res://")
	return found_handlers
func _get_line_reader_scripts_r(path: String) -> void:
	var directories = DirAccess.get_directories_at(path)
	for d in directories:
		if d == "addons":
			continue
		if path == "res://":
			_get_line_reader_scripts_r(path + d)
		else:
			_get_line_reader_scripts_r(path + "/" + d)
		
	var files = DirAccess.get_files_at(path)
	
	for f in files:
		if not f.get_extension() == "gd":
			continue
		var script : Script = load(path + "/" + f)
		var file := FileAccess.open(path + "/" + f, FileAccess.READ)
		var lines = file.get_as_text()
		
		var has_expression : = false
		for expression in [
			"extends LineReader",
			"extends\nLineReader",
			"extends \nLineReader",
			]:
			if expression in lines:
				has_expression = true
		if has_expression:
			var local_path : String = path + "/" + f
			local_path = local_path.replace("///", "//") # this happens with scripts in the project root
			found_handlers.append(local_path)
			


func _on_templates_menu_id_pressed(id: int) -> void:
	request_template_setup.emit(id)

func _on_active_path_set(path : String):
	%FilePathLabel.text = path
	%SillyCompanionEmbedLabel.text = Pages.make_puppy() if Pages.silly else ""


func update_recents_item():
	recents_item.clear()
	var recent_data := get_recent_files()
	for file : String in recent_data:
		var file_name := file.trim_prefix(file.left(file.rfind("/") + 1))
		recents_item.add_item("%s%s%s" % [file_name, RECENT_FILE_SEPARATOR, file])
