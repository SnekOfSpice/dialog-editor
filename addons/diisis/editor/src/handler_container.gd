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

var found_handlers := []
func _on_find_handlers_button_pressed() -> void:
	found_handlers.clear()
	count_dir("res://")
	find_child("EvaluatorLabel").text = "\n".join(found_handlers)
	find_child("FoundHandlersLabel").text = str("Found ", found_handlers.size(), " LineReader", "s" if found_handlers.size() != 1 else "", "! :3")
	_on_evaluator_label_text_changed()

func count_dir(path: String):
	var directories = DirAccess.get_directories_at(path)
	for d in directories:
		if d == "addons":
			continue
		if path == "res://":
			count_dir(path + d)
		else:
			count_dir(path + "/" + d)
		
	var files = DirAccess.get_files_at(path)
	
	for f in files:
		if not f.get_extension() == "gd":
			continue
		var script : Script = load(path + "/" + f)
		var file := FileAccess.open(path + "/" + f, FileAccess.READ)
		var lines = file.get_as_text()
		
		var has_expression : = false
		for expression in [
			"extends LineReader",
			"extends\nLineReader",
			"extends \nLineReader",
			]:
			if expression in lines:
				has_expression = true
		if has_expression:
			var local_path : String = path + "/" + f
			local_path = local_path.replace("///", "//") # this happens with scripts in the project root
			found_handlers.append(local_path)
			
