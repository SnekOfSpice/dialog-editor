@tool
extends Window


func _on_about_to_popup() -> void:
	#var p := position
	$IngestionActorSetupContainer.init()
	await get_tree().process_frame
	size = Vector2i.ZERO
	
	await RenderingServer.frame_post_draw
	position = Pages.editor.size * 0.5 - size * 0.5


func _on_close_requested() -> void:
	hide()


func _on_page_ingestion_actor_setup_container_resized() -> void:
	if %IngestionActorSetupContainer.size.y > 5000:
		await get_tree().process_frame
		size = Vector2i.ZERO


func _on_size_changed() -> void:
	%IngestionActorSetupContainer.size = size
