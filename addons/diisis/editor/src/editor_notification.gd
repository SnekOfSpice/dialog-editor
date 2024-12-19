@tool
extends PanelContainer

var target_duration := 0.0
var remaining_duration := 0.0
var initialized := false

func init(message:String, duration:=5.0):
	target_duration = duration
	remaining_duration = duration
	find_child("RichTextLabel").text = message
	initialized = true

func _process(delta: float) -> void:
	if not initialized:
		return
	
	remaining_duration -= delta
	if remaining_duration <= 0:
		queue_free()
	
	find_child("ProgressRect").scale.x = remaining_duration / target_duration

func _on_delete_button_pressed() -> void:
	queue_free()


func _on_rich_text_label_meta_clicked(meta: Variant) -> void:
	OS.shell_open(meta)
