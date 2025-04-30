@tool
extends ConfirmationDialog
class_name RichTextConfirmationDialog

func set_rich_text(text:String):
	find_child("RichTextLabel").text = text

func _on_rich_text_label_item_rect_changed() -> void:
	if not is_instance_valid(Pages.editor):
		return
	
	DiisisEditorUtil.limit_scroll_container_height(
		find_child("ScrollContainer"),
		0.5,
		#find_child("ScrollHintTop"),
		#find_child("ScrollHintBottom"),
	)
