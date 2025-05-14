@tool
extends Control

func _make_custom_tooltip(for_text: String) -> Object:
	var tt = RichTextLabel.new()
	tt.fit_content = true
	tt.custom_minimum_size.x = 400
	tt.visible = true
	tt.bbcode_enabled = true
	tt.text = for_text
	#tt.theme = load("uid://jddhsc4auo55")
	return tt
