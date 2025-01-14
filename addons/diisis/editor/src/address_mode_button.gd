@tool
extends TextureButton
class_name AddressModeButton


enum Mode {
	Objectt,
	Address
}

var mode : Mode = Mode.Objectt

func get_mode() -> Mode:
	return mode


func set_mode(value:int):
	mode = value
	match mode:
		Mode.Objectt:
			texture_normal = load("res://addons/diisis/editor/visuals/address_mode_obj.png")
		Mode.Address:
			texture_normal = load("res://addons/diisis/editor/visuals/address_mode_adr.png")


func _on_pressed() -> void:
	set_mode(wrap(mode + 1, 0, Mode.size()))
