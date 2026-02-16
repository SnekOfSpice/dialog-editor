@tool
extends PanelContainer


func init():
	find_child("FoundHandlersLabel").text = ""
	_on_reset_evaluator_changes_button_pressed()

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

func _on_find_handlers_button_pressed() -> void:
	var found_handlers : Array = Pages.editor.get_line_reader_scripts()
	find_child("EvaluatorLabel").text = "\n".join(found_handlers)
	find_child("FoundHandlersLabel").text = str("Found ", found_handlers.size(), " LineReader", "s" if found_handlers.size() != 1 else "", "! :3")
	_on_evaluator_label_text_changed()
