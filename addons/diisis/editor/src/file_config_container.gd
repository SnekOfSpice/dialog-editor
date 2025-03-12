@tool
extends Control


func init():
	_on_reset_evaluator_changes_button_pressed()
	find_child("UseDialogSyntaxCheckBox").button_pressed = Pages.use_dialog_syntax
	find_child("LeadTimeSpinBoxSameActor").value = Pages.text_lead_time_same_actor
	find_child("LeadTimeSpinBoxOtherActor").value = Pages.text_lead_time_other_actor
	find_child("AddressModeButtonPage").set_mode(Pages.default_address_mode_pages)
	find_child("ItemList").select(0)
	_on_item_list_item_selected(0)


# ======== evaluator ========
func _on_item_list_item_selected(index: int) -> void:
	for c in find_child("ContentContainer").get_children():
		c.visible = c.get_index() == index

func _on_save_evaluator_changes_button_pressed() -> void:
	var label : TextEdit = find_child("EvaluatorLabel")
	Pages.evaluator_paths = label.text.split("\n")
	find_child("SaveEvaluatorChangesButton").text = "save changes"

func _on_reset_evaluator_changes_button_pressed() -> void:
	var label : TextEdit = find_child("EvaluatorLabel")
	label.text = "\n".join(Pages.evaluator_paths)

func _on_evaluator_sort_button_pressed() -> void:
	var label : TextEdit = find_child("EvaluatorLabel")
	var paths := label.text.split("\n")
	paths.sort()
	label.text = "\n".join(paths)
	Pages.evaluator_paths = label.text.split("\n")


func _on_evaluator_label_text_changed() -> void:
	find_child("SaveEvaluatorChangesButton").text = "save changes" if "\n".join(Pages.evaluator_paths) == find_child("EvaluatorLabel").text else "save changes (*)"


func _on_use_dialog_syntax_check_box_pressed():
	Pages.use_dialog_syntax = find_child("UseDialogSyntaxCheckBox").button_pressed
	for line : Line in Pages.editor.current_page.find_child("Lines").get_children():
		line.find_child("TextContent").set_use_dialog_syntax(Pages.use_dialog_syntax)


func _on_lead_time_spin_box_same_actor_value_changed(value):
	Pages.text_lead_time_same_actor = value


func _on_lead_time_spin_box_other_actor_value_changed(value):
	Pages.text_lead_time_other_actor = value


func _on_address_mode_button_page_mode_set(mode: AddressModeButton.Mode) -> void:
	Pages.default_address_mode_pages = mode
