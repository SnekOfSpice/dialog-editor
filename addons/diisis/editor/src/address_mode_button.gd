@tool
extends TextureButton
class_name AddressModeButton

@export var address_source:Control
@export var address_function:String

signal mode_set(mode:Mode)

enum Mode {
	Objectt,
	Address
}

var mode : Mode = Mode.Objectt

func _make_custom_tooltip(for_text:String) -> Object:
	var tt = preload("res://addons/diisis/editor/src/address_mode_button_tooltip.tscn").instantiate()
	tt.visible = true
	tt.init()
	if _get_target_address():
		tt.add_address(_get_target_address())
	return tt

func get_mode() -> Mode:
	return mode


func set_mode(value:int):
	mode = value
	match mode:
		Mode.Objectt:
			texture_normal = load("res://addons/diisis/editor/visuals/address_mode_obj.png")
		Mode.Address:
			texture_normal = load("res://addons/diisis/editor/visuals/address_mode_adr.png")

func _get_target_address() -> String:
	if address_source:
		if address_source.has_method(address_function):
			var target := str(address_source.call(address_function))
			return target
		else:
			push_warning(str("address source doesn't have method ", address_function))
	return ""

func _on_pressed() -> void:
	set_mode(wrap(mode + 1, 0, Mode.size()))
	emit_signal("mode_set", mode)

func set_page_view(view:DiisisEditor.PageView):
	if not address_source:
		return
	visible = view == DiisisEditor.PageView.Full

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == 2 and event.pressed:
			var target := _get_target_address()
			if not target.is_empty():
				Pages.editor.request_go_to_address(target)
