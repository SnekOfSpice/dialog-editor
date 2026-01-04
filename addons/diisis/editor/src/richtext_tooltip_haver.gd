@tool
extends CheckBox



func _make_custom_tooltip(for_text:String) -> Object:
	var tt = RichTextLabel.new()
	tt.visible = true
	#tt.init()
	tt.text = for_text
	tt.bbcode_enabled = true
	tt.fit_content = true
	tt.custom_minimum_size.x = get_window().size.x * 0.1
	#if _get_target_address():
		#tt.add_address(_get_target_address())
	Pages.apply_font_size_overrides(tt)
	return tt
