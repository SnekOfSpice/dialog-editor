@tool
extends PanelContainer

func init(message:String, duration:=5.0):
	find_child("RichTextLabel").text = message
	
	var rect : ColorRect = find_child("ProgressRect")
	var t = create_tween()
	t.tween_property(rect, "scale:x", 0, duration)
	t.finished.connect(queue_free)

func _on_delete_button_pressed() -> void:
	queue_free()


func _on_rich_text_label_meta_clicked(meta: Variant) -> void:
	OS.shell_open(meta)
