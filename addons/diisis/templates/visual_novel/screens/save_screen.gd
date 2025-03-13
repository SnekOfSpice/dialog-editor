extends Screen


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super()
	for i in Options.MAX_SAVE_SLOTS:
		var item = preload("res://game/screens/save_item.tscn").instantiate()
		find_child("Slots").add_child(item)
		item.set_slot(i)
		item.pressed.connect(Options.set_save_slot.bind(i))
		item.pressed.connect(close)
