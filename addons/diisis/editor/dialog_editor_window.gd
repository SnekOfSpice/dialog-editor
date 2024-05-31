@tool
extends Window

var editor : DiisisEditor
var editor_window : Window
var window_factor_window : Window
var editor_start_size:Vector2
var editor_content_scale:=1.0

func _on_about_to_popup() -> void:
	editor = find_child("Editor")
	editor_window = find_child("Window")
	window_factor_window = find_child("WindowFactorWindow")
	editor_start_size = editor.size
	editor.init()
	
	editor_window.visible = true
	window_factor_window.visible = true
	
	await get_tree().process_frame
	update_content_scale(1.0)

func _process(delta):
	if not editor or not editor_window:
		return
	update_content_scale(editor_content_scale)

func _on_close_requested() -> void:
	if editor.undo_redo.get_history_count() == 0:
		_on_quit_dialog_confirmed()
	var text := ""
	text += "Do you want to close DIISIS?\n"
	if editor.active_dir.is_empty() or not editor.has_saved:
		text += str("You have not saved since opening.")
	else:
		var seconds_since_last_save = int(editor.time_since_last_save)
		var minutes_since_last_save := 0
		var hours_since_last_save := 0
		var last_system_save = editor.last_system_save
		
		var second_word:String
		var minute_word:String
		var hour_word:String
		
		
		if seconds_since_last_save >= 60:
			minutes_since_last_save = floor(seconds_since_last_save / 60.0)
			seconds_since_last_save -= 60 * minutes_since_last_save
			if minutes_since_last_save >= 60:
				hours_since_last_save = floor(minutes_since_last_save / 60.0)
				minutes_since_last_save -= 60 * hours_since_last_save
		
		second_word = "second" if seconds_since_last_save == 1 else "seconds"
		minute_word = "minute" if minutes_since_last_save == 1 else "minutes"
		hour_word = "hour" if hours_since_last_save == 1 else "hours"
		
		var system_str := str(str(last_system_save.get("hour")).pad_zeros(2), ":", str(last_system_save.get("minute")).pad_zeros(2), ":", str(last_system_save.get("second")).pad_zeros(2))
		text += str("You last saved at ", system_str, ".\n")
		
		var ago_string:=""
		if hours_since_last_save > 0:
			ago_string += str(hours_since_last_save, " ", hour_word, ", ")
		if minutes_since_last_save > 0:
			ago_string += str(minutes_since_last_save, " ", minute_word, ", ")
		
		ago_string += str(seconds_since_last_save, " ", second_word)
		text += str("(", ago_string, " ago.)")
	$QuitDialog.dialog_text = text
	$QuitDialog.popup()

func _on_quit_dialog_canceled() -> void:
	$QuitDialog.hide()

func _on_quit_dialog_confirmed() -> void:
	editor.is_open = false
	hide()
	queue_free()

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
	
	if editor:
		editor.content_scale = scale_factor


func _on_size_changed() -> void:
	update_content_scale(editor_content_scale)

func _on_window_factor_scale_value_changed(value):
	editor_content_scale = value


func _on_window_mouse_entered():
	if not has_focus():
		return
	if $QuitDialog.visible:
		return
	if editor.has_open_popup():
		return
	editor_window.grab_focus()


func _on_window_mouse_exited():
	grab_focus()

func _on_window_factor_window_mouse_entered():
	if not has_focus():
		return
	if $QuitDialog.visible:
		return
	window_factor_window.grab_focus()


func _on_window_factor_window_mouse_exited():
	grab_focus()


func _on_editor_scale_editor_down():
	find_child("WindowFactorScale").value -= 0.05


func _on_editor_scale_editor_up():
	find_child("WindowFactorScale").value += 0.05
