@tool
extends Control



func init():
	%CapitalizeCheckBox.tooltip_text = Pages.TOOLTIP_CAPITALIZE
	%WhitespaceCheckBox.tooltip_text = Pages.TOOLTIP_NEATEN_WHITESPACE
	%PunctuationCheckBox.tooltip_text = Pages.TOOLTIP_FIX_PUNCTUATION
	%SkillcheckCheckBox.tooltip_text = Pages.TOOLTIP_FIX_SKILLCHECK_INDENTATION
	
	if Pages.silly:
		%PuppyLabel.text = Pages.make_puppy()
	else:
		%PuppyLabel.text = ""


func no_options_pressed() -> bool:
	return not (
		%CapitalizeCheckBox.button_pressed or
		%WhitespaceCheckBox.button_pressed or
		%PunctuationCheckBox.button_pressed or
		%SkillcheckCheckBox.button_pressed
	)


func _on_confirm_button_pressed() -> void:
	if no_options_pressed():
		return
	
	var text_index := 0
	var text_count := Pages.text_data.size()
	for key in Pages.text_data.keys():
		var text : String = Pages.get_text(key)
		
		if %CapitalizeCheckBox.button_pressed:
			text = Pages.capitalize_sentence_beginnings(text)
		if %WhitespaceCheckBox.button_pressed:
			text = Pages.neaten_whitespace(text)
		if %PunctuationCheckBox.button_pressed:
			text = Pages.fix_punctuation(text)
		if %SkillcheckCheckBox.button_pressed:
			var result : Pages.IndentResult = Pages.fix_skillcheck_indentation(text)
			if result.fail_string == "OK":
				text = result.text
		
		Pages.save_text(key, text)
		text_index += 1
		%ProgressLabel.text = "Working, please wait... [%s/%s]" % [text_index, text_count]
	
	Pages.editor.refresh_text()
	await get_tree().process_frame
	%ProgressLabel.text = ""


func _on_toggle_selection_button_pressed() -> void:
	var goal : bool = not %CapitalizeCheckBox.button_pressed
	
	for button : CheckBox in %Buttons.get_children():
		button.set_pressed_no_signal(goal)
