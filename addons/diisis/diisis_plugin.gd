@tool
extends EditorPlugin

var dia_editor_window:Window
var toolbar_button

const AUTOLOAD_DATA = "Data"
const AUTOLOAD_PAGES = "Pages"
const AUTOLOAD_PARSER = "Parser"
const AUTOLOAD_EDITOR_ACTIONS = "DiisisEditorActions"
const AUTOLOAD_EDITOR_UTIL = "DiisisEditorUtil"
const AUTOLOAD_PARSER_EVENTS = "ParserEvents"
const AUTOLOAD_SHARED_DIISIS = "DIISIS"

func add_editor_singletons():
	add_autoload_singleton(AUTOLOAD_DATA, "res://addons/diisis/editor/autoload/data.tscn")
	add_autoload_singleton(AUTOLOAD_PAGES, "res://addons/diisis/editor/autoload/pages.tscn")
	add_autoload_singleton(AUTOLOAD_EDITOR_UTIL, "res://addons/diisis/editor/autoload/diisis_editor_util.tscn")
	add_autoload_singleton(AUTOLOAD_EDITOR_ACTIONS, "res://addons/diisis/editor/autoload/diisis_editor_actions.tscn")

func add_parser_singletons():
	add_autoload_singleton(AUTOLOAD_PARSER, "res://addons/diisis/parser/autoload/parser.tscn")
	add_autoload_singleton(AUTOLOAD_PARSER_EVENTS, "res://addons/diisis/parser/autoload/parser_events.tscn")

func remove_editor_singletons():
	remove_autoload_singleton(AUTOLOAD_DATA)
	remove_autoload_singleton(AUTOLOAD_PAGES)
	remove_autoload_singleton(AUTOLOAD_EDITOR_UTIL)
	remove_autoload_singleton(AUTOLOAD_EDITOR_ACTIONS)

func remove_parser_singletons():
	remove_autoload_singleton(AUTOLOAD_PARSER)
	remove_autoload_singleton(AUTOLOAD_PARSER_EVENTS)

func _enter_tree():
	toolbar_button = Button.new()
	toolbar_button.text = "hi"
	add_control_to_container(EditorPlugin.CONTAINER_TOOLBAR, toolbar_button)
	toolbar_button.focus_mode = Control.FOCUS_NONE
	toolbar_button.visible = true
	toolbar_button.pressed.connect(open_editor)
	add_autoload_singleton(AUTOLOAD_SHARED_DIISIS, "res://addons/diisis/shared/autoload/Diisis.tscn")
	add_editor_singletons()
	add_parser_singletons()
	add_custom_type("LineReader", "Control", preload("res://addons/diisis/parser/src/line_reader.gd"), preload("res://addons/diisis/parser/style/reader_icon_Zeichenfläche 1.svg"))

func open_editor():
	if is_instance_valid(dia_editor_window):
		dia_editor_window.grab_focus()
	else:
		remove_editor_singletons()
		add_editor_singletons()
		dia_editor_window = preload("res://addons/diisis/editor/dialog_editor_window.tscn").instantiate()
		get_editor_interface().get_base_control().add_child.call_deferred(dia_editor_window)
		await get_tree().process_frame
		dia_editor_window.popup()
		#dia_editor_window.close_requested.connect(dia_editor_window.hide)
		#dia_editor_window.close_requested.connect(dia_editor_window.queue_free)
		#dia_editor_window.editor_closed.connect(remove_singletons)

func _process(delta: float) -> void:
	if is_instance_valid(dia_editor_window):
		dia_editor_window.wrap_controls = true
#		print(dia_editor_window.get_children())

func _exit_tree():
	remove_editor_singletons()
	remove_parser_singletons()
	remove_autoload_singleton(AUTOLOAD_SHARED_DIISIS)
	if dia_editor_window:
		dia_editor_window.queue_free()
	remove_control_from_container(EditorPlugin.CONTAINER_TOOLBAR, toolbar_button)
