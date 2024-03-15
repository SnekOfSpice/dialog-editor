@tool
extends EditorPlugin

var dia_editor_window:Window
var toolbar_button

const AUTOLOAD_DATA = "Data"
const AUTOLOAD_PAGES = "Pages"

func add_singletons():
	add_autoload_singleton(AUTOLOAD_DATA, "res://addons/diisis/editor/autoload/data.tscn")
	add_autoload_singleton(AUTOLOAD_PAGES, "res://addons/diisis/editor/autoload/pages.tscn")

func remove_singletons():
	remove_autoload_singleton(AUTOLOAD_DATA)
	remove_autoload_singleton(AUTOLOAD_PAGES)

func _enter_tree():
	toolbar_button = Button.new()
	toolbar_button.text = "hi"
	add_control_to_container(EditorPlugin.CONTAINER_TOOLBAR, toolbar_button)
	toolbar_button.focus_mode = Control.FOCUS_NONE
	toolbar_button.visible = true
	toolbar_button.pressed.connect(open_editor)
	add_singletons()

func open_editor():
	if is_instance_valid(dia_editor_window):
		dia_editor_window.grab_focus()
	else:
		remove_singletons()
		add_singletons()
		dia_editor_window = preload("res://addons/diisis/editor/dialog_editor_window.tscn").instantiate()
		get_editor_interface().get_base_control().add_child(dia_editor_window)
		dia_editor_window.popup()
		#dia_editor_window.close_requested.connect(dia_editor_window.hide)
		#dia_editor_window.close_requested.connect(dia_editor_window.queue_free)
		#dia_editor_window.editor_closed.connect(remove_singletons)

func _process(delta: float) -> void:
	if is_instance_valid(dia_editor_window):
		dia_editor_window.wrap_controls = true
#		print(dia_editor_window.get_children())

func _exit_tree():
	remove_singletons()
	if dia_editor_window:
		dia_editor_window.queue_free()
	remove_control_from_container(EditorPlugin.CONTAINER_TOOLBAR, toolbar_button)
