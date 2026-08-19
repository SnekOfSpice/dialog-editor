extends Screen


func _ready() -> void:
	super()

func _input(event: InputEvent) -> void:
	super(event)

func _on_rich_text_label_meta_clicked(meta: Variant) -> void:
	OS.shell_open(str(meta))
