@tool
extends AcceptDialog




func _on_about_to_popup() -> void:
	dialog_text = str(
		"Total Word Count*: ", Pages.get_word_count_total_approx(), "\n",
		"Total Character Count*: ", Pages.get_character_count_total_approx(), "\n\n",
		"Word Count on page*: ", Pages.get_word_count_on_page_approx(Pages.editor.get_current_page().number), "\n",
		"Character Count on page*: ", Pages.get_character_count_on_page_approx(Pages.editor.get_current_page().number), "\n\n",
		"* Values are approximated:\n- Words are counted by spaces.\n- Characters are counted in total.\n(Dialog syntax & LineReaders may affect this)"
	)
	


func _on_close_requested() -> void:
	hide()
