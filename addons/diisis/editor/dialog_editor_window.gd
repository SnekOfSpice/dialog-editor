@tool
extends Window

signal editor_closed()

var editor : DiisisEditor
var editor_start_size:Vector2
var editor_content_scale:=1.0

func _process(delta):
	#printt(editor_start_size, size)
	if not editor:
		return
	update_content_scale(editor_content_scale)
	return
	
	#find_child("Window").position = -position*0.5
	#find_child("Window").size = size#editor.size * find_child("Window").content_scale_factor
	
	fix_camera_offset()
	
	#find_child("Window").size.y -= 23
	#printt(find_child("Window").size, size)
	#find_child("Window").position = -size * 0.5
	
	

func _on_about_to_popup() -> void:
	editor = find_child("Editor")
	editor_start_size = editor.size
	editor.init()
	
	find_child("Window").visible = true
	find_child("WindowFactorWindow").visible = true
	fix_camera_offset()
	
	await get_tree().process_frame
	update_content_scale(1.0)

func _on_size_changed() -> void:
	update_content_scale(editor_content_scale)
	#find_child("Window").size = size
	#find_child("Window").position = -size * 0.5
	#find_child("Window").global_position = global_canvas_transform.get_origin()
	pass
	

func fix_camera_offset():
	#find_child("Window").position = -size * 0.5
	return
	if not find_child("Window").get_viewport():
		#print("no viewport")
		return
	if not find_child("Window").get_viewport().get_camera_2d():
		#print("no cam")
		return
	#print("yay")
	find_child("Window").get_viewport().get_camera_2d().offset = (size * 0.5) / find_child("Window").content_scale_factor
	find_child("Window").get_viewport().get_camera_2d().offset.x += (size.x * 0.5) * find_child("Window").content_scale_factor
	#find_child("Window").get_viewport().get_camera_2d().position = size * 0.5

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
	emit_signal("editor_closed")
	hide()
	queue_free()

func update_content_scale(scale_factor:float):
	var resolution_correction = (Vector2(1920.0, 1080.0)/editor_start_size).x
	find_child("Window").content_scale_factor = scale_factor
	
	if size.x > editor_start_size.x:
		editor.size.x = size.x / scale_factor
	else:
		editor.size.x = editor_start_size.x / scale_factor
	if size.y > editor_start_size.y:
		editor.size.y = size.y / scale_factor
	else:
		editor.size.y = editor_start_size.y / scale_factor
	#editor.size *= 2
	find_child("Window").size = size#editor.size * scale_factor
	find_child("Window").size *= 2
	find_child("Window").size.y -= 23
	find_child("Window").position = -size
	fix_camera_offset()
	
	find_child("WindowFactorLabel").text = str(scale_factor)
	find_child("WindowFactorWindow").position.y = size.y - find_child("WindowFactorContainer").size.y

func _on_window_factor_scale_value_changed(value):
	editor_content_scale = value
