@tool
extends Window
class_name DiisisEditorWindow

var editor : DiisisEditor

var file_path := ""

signal open_new_file()
signal closing_editor()


func _on_about_to_popup() -> void:
	await get_tree().process_frame
	editor = %Editor
	editor.init(file_path)
	
	editor.close_window_request.connect(close_window)
	
	if not DiisisEditorEventBus.active_path_set.is_connected(_on_save_path_set):
		DiisisEditorEventBus.active_path_set.connect(_on_save_path_set)
	
	await get_tree().process_frame
	_on_save_path_set(file_path)
	
	content_scale_factor = (EditorInterface.get_editor_settings().get_setting("diisis/plugin/view/editor_scale"))


func _on_quit_dialog_canceled() -> void:
	$QuitDialog.hide()


func close_window():
	editor.save_preferences()
	emit_signal("closing_editor")
	await get_tree().process_frame
	if is_instance_valid(editor):
		editor.is_open = false
	hide()
	if is_instance_valid(editor):
		editor.update_page_view(DiisisEditor.PageView.Full)
	
	for i in Pages.page_data.size():
		Pages.consume_from_user("changed%s" % i, true)
	
	queue_free()


func close_window_and_open_new_file():
	DiisisEditorEventBus.quit.new_file.emit()
	close_window()


func reload_editor():
	DiisisEditorEventBus.quit.window_reload.emit()
	close_window()


	
	#if editor:
		#editor.set_content_scale(scale_factor)




func _on_editor_open_new_file() -> void:
	if not editor.has_unsaved_changes:
		close_window_and_open_new_file()
	editor.build_quit_dialog(DIISIS.QUIT_DIALOG_TITLE_NEW)


func _on_close_requested() -> void:
	if not editor.has_unsaved_changes:
		close_window()
	editor.build_quit_dialog(DIISIS.QUIT_DIALOG_TITLE_CLOSE)


func _on_save_path_set(path : String) -> void:
	if path.is_empty():
		title = DIISIS.UNSAVED_FILE_PATH
		return
	var parts := path.split("/")
	var file_name := parts[parts.size() - 1]
	title = str(file_name.trim_suffix(".json"), " - DIISIS - (", path, ")")


func _on_editor_history_altered(is_altered: bool) -> void:
	if is_altered:
		if not title.begins_with("(*) "):
			title = str("(*) ", title)
	else:
		title = title.trim_prefix("(*) ")


func _on_focus_entered() -> void:
	Pages.ensure_line_reader_scripts()
	if Pages.validate_function_calls_on_focus:
		Pages.update_all_compliances()

func minimize():
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MINIMIZED, get_window_id())

func set_windowed():
	var window_size := DisplayServer.window_get_size(get_window_id())
	var screen_with_window := DisplayServer.window_get_current_screen(get_window_id())
	var screen_size := DisplayServer.screen_get_size(screen_with_window)
	if window_size.x == screen_size.x:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MAXIMIZED, get_window_id())
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED, get_window_id())


func _on_editor_close_window_request() -> void:
	close_window()


func _on_editor_reload_window_request() -> void:
	reload_editor()


func _on_size_changed() -> void:
	await get_tree().process_frame
	var a : Vector2= %Editor.position + (%Editor.size * 0.5)
	$Camera2D.set_deferred("position", a)
	#%Editor.size = size
	#%Editor.set_deferred("size",-size)
	#%Editor.set_deferred("position", -size)
	#%Editor.set_anchors_and_offsets_preset.bind(Control.PRESET_FULL_RECT).call_deferred()
