@tool
extends Window
class_name DiisisEditorWindow

var editor : DiisisEditor
var editor_window : Window
var window_factor_window : Window
var editor_start_size:Vector2
var editor_content_scale:=1.0

var file_path := ""
#var last_quit_header := ""

signal open_new_file()
signal closing_editor()


func _on_about_to_popup() -> void:
	await get_tree().process_frame
	editor = find_child("Editor")
	editor_window = find_child("Window")
	window_factor_window = find_child("WindowFactorWindow")
	editor_start_size = editor.size
	editor.init(file_path)
	
	editor.close_window_request.connect(close_window)
	
	editor_window.visible = true
	window_factor_window.visible = true
	
	if not DiisisEditorEventBus.active_path_set.is_connected(_on_save_path_set):
		DiisisEditorEventBus.active_path_set.connect(_on_save_path_set)
	
	await get_tree().process_frame
	update_content_scale(1.0)
	
	await get_tree().process_frame
	%UpdateAvailable.check_for_updates()
	_on_save_path_set(file_path)



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

func update_content_scale(scale_factor:float):
	if not editor_window or not editor:
		return
	
	editor_window.content_scale_factor = scale_factor
	
	editor.size.x = max(size.x, editor_start_size.x) / scale_factor
	editor.size.y = max(size.y, editor_start_size.y) / scale_factor
	
	editor_window.size = size
	editor_window.size *= 2
	editor_window.size.y -= find_child("WindowFactorContainer").size.y*2
	editor_window.position = -size
	editor_window.position.y += find_child("WindowFactorContainer").size.y
	
	find_child("WindowFactorLabel").text = str(scale_factor * 100, "%")
	window_factor_window.position.y = size.y - find_child("WindowFactorContainer").size.y
	window_factor_window.size.x = size.x
	find_child("WindowFactorContainer").size.x = size.x
	
	if editor:
		editor.set_content_scale(scale_factor)


func _on_size_changed() -> void:
	if is_inside_tree():
		await get_tree().process_frame
	update_content_scale(editor_content_scale)

func _on_window_factor_scale_value_changed(value):
	editor_content_scale = value
	update_content_scale(editor_content_scale)
	for window : Window in get_tree().get_nodes_in_group("diisis_scalable_popup"):
		window.content_scale_factor = value


func _on_window_mouse_entered():
	return
	if not has_focus():
		return
	if $QuitDialog.visible:
		return
	if editor.has_open_popup():
		return
	editor_window.grab_focus()


func _on_window_mouse_exited():
	return
	grab_focus()

func _on_window_factor_window_mouse_entered():
	return
	if not has_focus():
		return
	if $QuitDialog.visible:
		return
	if not window_factor_window:
		return
	window_factor_window = find_child("WindowFactorWindow")
	if not window_factor_window:
		return
	window_factor_window.grab_focus()


func _on_window_factor_window_mouse_exited():
	grab_focus()


func _on_editor_scale_editor_down():
	find_child("WindowFactorScale").value -= 0.05


func _on_editor_scale_editor_up():
	find_child("WindowFactorScale").value += 0.05


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


func _on_reset_scale_button_pressed() -> void:
	find_child("WindowFactorScale").set_value(1.0)


func _on_help_button_pressed() -> void:
	OS.shell_open("https://snekofspice.github.io/diisis-docs/")


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
