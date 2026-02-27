@tool
extends Node


signal active_path_set(path : String)


@onready var last_active_path := ProjectSettings.get_setting("diisis/project/file/path", "")

var quit := Quit.new()


func _enter_tree() -> void:
	ProjectSettings.settings_changed.connect(on_project_settings_changed)


## We cannot hook this up in diisis_plugin.gd because the autoloads won't exist on startup, causing errors.
func on_project_settings_changed():
	var path := ProjectSettings.get_setting("diisis/project/file/path", "")
	if path != last_active_path:
		last_active_path = path
		active_path_set.emit(path)


class Quit:
	signal window_reload()
	signal new_file()
