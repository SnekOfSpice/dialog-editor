@tool
extends Window


func _on_about_to_popup() -> void:
	#var p := position
	$IngestionActorSetupContainer.init()
	await get_tree().process_frame
	size = Vector2i.ZERO
	
	position = get_mouse_position()
	#var rect : Rect2i = DisplayServer.screen_get_usable_rect(DisplayServer.SCREEN_WITH_MOUSE_FOCUS)
	#position.y += 25


func _on_close_requested() -> void:
	hide()


func _on_page_ingestion_actor_setup_container_resized() -> void:
	if %IngestionActorSetupContainer.size.y > 5000:
		await get_tree().process_frame
		size = Vector2i.ZERO


func _on_size_changed() -> void:
	%IngestionActorSetupContainer.size = size
