@tool
extends Window

# TODO: Refactor other windows to also use this

@export_file("*.tscn") var container_path


func _on_about_to_popup() -> void:
	if container_path:
		var container = load(container_path).instantiate()
		add_child(container)
		if container.has_method("init"):
			container.init()
		else:
			push_warning("LMAO")
		Pages.apply_font_size_overrides(container)


func _on_close_requested() -> void:
	for child in get_children():
		child.queue_free()
	hide()
