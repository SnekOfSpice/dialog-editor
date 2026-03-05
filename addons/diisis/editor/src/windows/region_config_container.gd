@tool
extends Control


func init() -> void:
	%HelpLabel.hide()
	%BakeCheckBox.button_pressed = Pages.region_baking_enabled
	_on_bake_check_box_toggled(Pages.region_baking_enabled)
	if Pages.region_delination == Pages.RegionDeliniation.Pages:
		%PagesCheckBox.button_pressed = true
	elif Pages.region_delination == Pages.RegionDeliniation.Instructions:
		%InstructionCheckBox.button_pressed = true
	set_view(Pages.region_delination)
	%DeliniatorNameLineEdit.text = Pages.region_delinator_instruction


func set_view(deliniation : Pages.RegionDeliniation):
	%InstructionContainer.visible = deliniation == Pages.RegionDeliniation.Instructions
	Pages.region_delination = deliniation

func save_deliniator_name():
	Pages.region_delinator_instruction = %DeliniatorNameLineEdit.text
	

func _on_save_deliniator_name_button_pressed() -> void:
	save_deliniator_name()
	%SaveDeliniatorNameButton.text = "save"


func _on_pages_check_box_pressed() -> void:
	set_view(Pages.RegionDeliniation.Pages)


func _on_instruction_check_box_pressed() -> void:
	set_view(Pages.RegionDeliniation.Instructions)


func _on_deliniator_name_line_edit_text_changed(new_text: String) -> void:
	%SaveDeliniatorNameButton.text = "save"
	if new_text != Pages.region_delinator_instruction:
		%SaveDeliniatorNameButton.text = "save (*)"


func _on_deliniator_name_line_edit_text_submitted(_new_text: String) -> void:
	save_deliniator_name()


func _on_help_button_toggled(toggled_on: bool) -> void:
	%HelpLabel.visible = toggled_on


func _on_bake_check_box_toggled(toggled_on: bool) -> void:
	Pages.region_baking_enabled = toggled_on
	%Contents.visible = toggled_on
	%DisabledNotice.visible = not toggled_on
