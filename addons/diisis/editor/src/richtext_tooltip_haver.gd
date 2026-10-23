@tool
extends CheckBox



func _make_custom_tooltip(for_text:String) -> Object:
	var tt = RichTextLabel.new()
	tt.visible = true
	tt.text = for_text
	tt.bbcode_enabled = true
	tt.fit_content = true
	tt.custom_minimum_size.x = max(get_window().size.x * 0.1, 260)
	#if _get_target_address():
		#tt.add_address(_get_target_address())
	return tt
