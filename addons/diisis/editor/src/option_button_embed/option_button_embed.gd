@tool
extends Button

@export var options : Array[String] = []

signal option_pressed(index:int)
var container : VBoxContainer

func init(with := options):
	options = with
	text = options.front()
	container = find_child("OptionContainer")

func clear():
	options.clear()
	text = ""

func add_item(item:String):
	options.append(item)
	text = options.front()

func select(index:int):
	text = options[wrapi(index, 0, options.size())]

func get_selected_id() -> int:
	return options.find(text)

func clear_options():
	for child in container.get_children():
		child.queue_free()

func build_options():
	clear_options()
	var i := 0
	while i < options.size():
		var button = Button.new()
		container.add_child(button)
		button.text = options[i]
		button.add_theme_stylebox_override("normal", load("res://addons/diisis/editor/src/option_button_embed/normal.tres"))
		button.add_theme_stylebox_override("pressed", load("res://addons/diisis/editor/src/option_button_embed/pressed.tres"))
		button.add_theme_stylebox_override("hover", load("res://addons/diisis/editor/src/option_button_embed/hover.tres"))
		button.pressed.connect(on_option_pressed.bind(i))
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.disabled = disabled_items.has(i)
		i += 1
	
	#var is_selected_disabled := is_item_disabled(get_selected_id())
	#var safety := 0
	#var index := get_selected_id()
	#while is_selected_disabled:
		#select(index + safety)
		#safety += 1
		#is_selected_disabled = is_item_disabled(get_selected_id())
		#
		#if safety > options.size():
			#break

func is_item_disabled(index:int) -> bool:
	return disabled_items.has(index)

var disabled_items := []

func set_item_disabled(index:int, is_disabled:bool):
	if is_disabled:
		if not disabled_items.has(index):
			disabled_items.append(index)
	else:
		disabled_items.erase(index)
	#(container.get_child(index) as Button).disabled = is_disabled
	
	

func _on_pressed() -> void:
	if $Window.visible:
		$Window.hide()
		return
	
	
	var offset : Vector2
	var parent = get_parent()
	while is_instance_valid(parent):
		if parent is DiisisEditor:
			break
		if parent is Window:
			offset = Vector2(parent.position)
			break
		parent = parent.get_parent()
	build_options()
	$Window.popup()
	$Window.position = Vector2(offset) + Vector2(0, size.y) + global_position
	$Window.size.x = max(size.x, container.size.x + 2)
	$Window.size.y = max(size.y, container.size.y + 2)


func on_option_pressed(index):
	clear_options()
	$Window.hide()
	emit_signal("option_pressed", index)
	text = options[index]


func _on_visibility_changed() -> void:
	if not visible:
		$Window.hide()


func _on_hidden() -> void:
	$Window.hide()


func _on_window_mouse_entered() -> void:
	$Timer.stop()


func _on_window_mouse_exited() -> void:
	$Timer.start(1)


func _on_timer_timeout() -> void:
	$Window.hide()


func _on_mouse_entered() -> void:
	$Timer.stop()


func _on_mouse_exited() -> void:
	$Timer.start(1)
