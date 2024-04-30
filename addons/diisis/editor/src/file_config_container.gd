@tool
extends Control


func init():
	_on_reset_evaluator_changes_button_pressed()
	
	find_child("ItemList").select(0)


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
