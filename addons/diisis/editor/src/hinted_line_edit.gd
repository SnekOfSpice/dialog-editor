@tool
extends LineEdit
class_name HintedLineEdit

@export var submission_append := ""

## On submission, moves the caret by this amount. -1 goes back 1 character.
@export var submission_offset := 0

var completion_options := []
var virtual_hint_line := 0
var just_submitted := false
var last_caret_column := 0

signal text_entered(new_text:String)
signal caret_changed()

func update_hint(new_text: String):
	if new_text.is_empty() or not has_focus():
		$ArgHint.hide()
		return
	var option_list_string := ""
	var valid_options := []
	for option : String in completion_options:
		if option.contains(new_text):
			valid_options.append(option)
	
	if valid_options.is_empty():
		virtual_hint_line == 0
		$ArgHint.hide()
		return
	
	if virtual_hint_line >= valid_options.size():
		virtual_hint_line = max(valid_options.size() - 1, 0)
	
	#for i in virtual_hint_line:
		#valid_options.append(valid_options.pop_front())
	
	var i := 0
	for option : String in valid_options:
		var highlighted_substr := option.replace(new_text, str("[b]", new_text, "[/b]"))
		
		if i == virtual_hint_line:
			highlighted_substr = str(">", highlighted_substr)
		
		option_list_string += highlighted_substr
		option_list_string += "\n"
		i += 1
	
	option_list_string = option_list_string.trim_suffix("\n")
	if not just_submitted:
		$ArgHint.popup()
		just_submitted = false
	
	var caret_pos = Vector2i(global_position + Vector2(get_caret_draw_pos().x, 0))
	caret_pos.y += size.y
	$ArgHint.build_str(option_list_string)
	$ArgHint.position = caret_pos

func _on_gui_input(event: InputEvent) -> void:
	if Input.is_key_pressed(KEY_DOWN):
		virtual_hint_line += 1
		if virtual_hint_line >= $ArgHint.get_hint_line_count():
			virtual_hint_line = 0
	if Input.is_key_pressed(KEY_UP):
		
		virtual_hint_line -= 1
		if virtual_hint_line < 0:
			virtual_hint_line = $ArgHint.get_hint_line_count() - 1
	just_submitted = false
	update_hint(text)
	if Input.is_key_pressed(KEY_ENTER) or Input.is_key_pressed(KEY_TAB):
		just_submitted = true
		var text_in_hint : String = $ArgHint.get_text_in_line(virtual_hint_line)
		if text_in_hint.is_empty():
			return
		text_in_hint = text_in_hint.replace(">", "")
		text_in_hint = text_in_hint.replace("[b]", "")
		text_in_hint = text_in_hint.replace("[/b]", "")
		text = str(text_in_hint, submission_append)
		
		await get_tree().process_frame
		$ArgHint.hide()
		
		release_focus()
		grab_focus()
		caret_column = text.length() + submission_offset
		_on_text_changed(text_in_hint)
	if caret_column != last_caret_column:
		emit_signal("caret_changed")
	last_caret_column = caret_column


func _on_text_changed(new_text: String) -> void:
	update_hint(new_text)
	emit_signal("text_entered", new_text)
	emit_signal("caret_changed")
	
func get_caret_draw_pos() -> Vector2:
	var font : Font = get_theme_font("font")
	var substring = text.left(caret_column)
	return font.get_multiline_string_size(substring)


func _on_focus_exited() -> void:
	$ArgHint.hide()


func _on_focus_entered() -> void:
	virtual_hint_line = 0
