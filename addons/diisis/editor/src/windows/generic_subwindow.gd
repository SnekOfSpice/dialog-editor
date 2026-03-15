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
		
		#container.resized.connect(
			#func():
				#await get_tree().process_frame
				#if container.size.x < size.x and container.size.y < size.y:
					#size = Vector2i.ONE
				##size.x = max(size.x, container.size.x)
				##size.y = max(size.y, container.size.y)
		#)
		##
		#await get_tree().process_frame
		#size.x = max(size.x, container.size.x)
		#size.y = max(size.y, container.size.y)


func _on_close_requested() -> void:
	for child in get_children():
		child.queue_free()
	hide()
