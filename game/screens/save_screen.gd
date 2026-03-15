extends Screen
class_name SaveScreen

enum ButtonMode {
	SelectSlot,
	Save
}
var button_mode :  ButtonMode = ButtonMode.SelectSlot

func _ready() -> void:
	super()
	build_buttons()

func build_buttons():
	for child in find_child("Slots").get_children():
		child.queue_free()
	for i in Options.MAX_SAVE_SLOTS:
		var item = preload("res://game/screens/save_item.tscn").instantiate()
		find_child("Slots").add_child(item)
		item.set_slot(i)
		if button_mode == ButtonMode.SelectSlot:
			item.pressed.connect(select_slot.bind(i))
			%TitleLabel.text = "Select Save Slot"
		elif button_mode == ButtonMode.Save:
			item.pressed.connect(save.bind(i))
			%TitleLabel.text = "Save To Slot"
		%TitleLabel.text += "\nCurrent Slot: %s" % (Options.save_slot + 1)

func select_slot(slot:int):
	Options.set_save_slot(slot)
	close()

func save(slot:int):
	var current_slot = Options.save_slot
	Options.set_save_slot(slot)
	Options.save_gamestate()
	Options.save_prefs()
	Options.set_save_slot(current_slot)
	build_buttons()
