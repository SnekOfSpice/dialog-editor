@tool
extends EditorPlugin
class_name DIISISPlugin

var dia_editor_window:Window
var embedder:Control
var toolbar_button:Control
var confirmation_window:Window
var accept_dialogue:AcceptDialog

var _embedded : bool:
	get():
		return ProjectSettings.get_setting("diisis/plugin/view/embedded")

const AUTOLOAD_PAGES = "Pages"
const AUTOLOAD_PARSER = "Parser"
const AUTOLOAD_EDITOR_ACTIONS = "DiisisEditorActions"
const AUTOLOAD_EDITOR_TEXT_TO_DIISIS = "TextToDiisis"
const AUTOLOAD_EDITOR_UTIL = "DiisisEditorUtil"
const AUTOLOAD_PARSER_EVENTS = "ParserEvents"
const AUTOLOAD_SHARED_DIISIS = "DIISIS"

const TEMPLATE_VN_AUTOLOAD_CONST = "CONST"
const TEMPLATE_VN_AUTOLOAD_GO_BACK_HANDLER = "GoBackHandler"
const TEMPLATE_VN_AUTOLOAD_OPTIONS = "Options"
const TEMPLATE_VN_AUTOLOAD_SOUND = "Sound"
const TEMPLATE_VN_AUTOLOAD_STYLE = "Style"
const TEMPLATE_VN_AUTOLOAD_GAME = "Game"
const TEMPLATE_VN_AUTOLOAD_EVENT_BUS = "EventBus"
const TEMPLATE_VN_AUTOLOAD_SCENE_LOADER = "SceneLoader"

## TODO ugly workaround to make internal docs work
## Godot 4.5 will make this unnecessary
func _ready() -> void:
	ResourceSaver.save(preload("res://addons/diisis/parser/src/line_reader.gd"))
	ResourceSaver.save(preload("res://addons/diisis/parser/autoload/parser_events.gd"))
	ResourceSaver.save(preload("res://addons/diisis/parser/autoload/parser.gd"))

func setup_vn_template():
	var bus_path_game := str("res://game/sounds/default_bus_layout.tres")
	var bus_path_plugin := str("res://addons/diisis/templates/visual_novel/sounds/default_bus_layout.tres")
	if ResourceLoader.exists(bus_path_game):
		AudioServer.set_bus_layout(load(bus_path_game))
	if ResourceLoader.exists(bus_path_plugin):
		AudioServer.set_bus_layout(load(bus_path_plugin))
	var e1 = InputEventMouseButton.new()
	e1.button_index = MOUSE_BUTTON_LEFT
	var e2 = InputEventKey.new()
	e2.keycode = KEY_SPACE
	e2.physical_keycode = KEY_SPACE
	var e3 = InputEventKey.new()
	e3.keycode = KEY_ENTER
	e3.physical_keycode = KEY_ENTER
	var e4 = InputEventKey.new()
	e4.keycode = KEY_LEFT
	e4.physical_keycode = KEY_LEFT
	ProjectSettings.set_setting("input/advance",
		{
		"deadzone": 0.5,
		"events": [e1,e2,e3,e4]
		}
	)
	
	var e5 = InputEventMouseButton.new()
	e5.button_index = MOUSE_BUTTON_WHEEL_DOWN
	var e6 = InputEventKey.new()
	e6.keycode = KEY_RIGHT
	e6.physical_keycode = KEY_RIGHT
	ProjectSettings.set_setting("input/go_back",
		{
		"deadzone": 0.5,
		"events": [e5,e6]
		}
	)
	
	var e7 = InputEventKey.new()
	e7.keycode = KEY_A
	e7.physical_keycode = KEY_A
	ProjectSettings.set_setting("input/toggle_auto_continue",
		{
		"deadzone": 0.5,
		"events": [e7]
		}
	)
	
	var e8 = InputEventKey.new()
	e8.keycode = KEY_S
	e8.physical_keycode = KEY_S
	ProjectSettings.set_setting("input/screenshot",
		{
		"deadzone": 0.5,
		"events": [e8]
		}
	)
	var e9 = InputEventKey.new()
	e9.keycode = KEY_H
	e9.physical_keycode = KEY_H
	ProjectSettings.set_setting("input/toggle_ui",
		{
		"deadzone": 0.5,
		"events": [e9]
		}
	)
	var e10 = InputEventKey.new()
	e10.keycode = KEY_F1
	e10.physical_keycode = KEY_F1
	ProjectSettings.set_setting("input/cheats",
		{
		"deadzone": 0.5,
		"events": [e10]
		}
	)
	var e11 = InputEventKey.new()
	e11.keycode = KEY_L
	e11.physical_keycode = KEY_L
	ProjectSettings.set_setting("input/history",
		{
		"deadzone": 0.5,
		"events": [e11]
		}
	)
	
	for file_name :String in ["scene_loader","event_bus", "const", "go_back_handler", "options", "sound", "style", "game"]:
		var path_game := str("res://game/autoloads/", file_name, ".tscn")
		var path_plugin := str("res://addons/diisis/templates/visual_novel/autoloads/", file_name, ".tscn")
		var autoload_name : String = get(str("TEMPLATE_VN_AUTOLOAD_", file_name.to_upper()))
		if FileAccess.file_exists(path_game):
			add_autoload_singleton(autoload_name, path_game)
		elif FileAccess.file_exists(path_plugin):
			add_autoload_singleton(autoload_name, path_plugin)
		else:
			popup_accept_dialogue("Error", str("Couldn't find VN template autoload ", file_name, " in res://game/autoloads/ or res://addons/diisis/templates/visual_novel/autoloads/"))
			return
		await get_tree().process_frame
	
	var source_path_game := "res://game/diisis_integration/demo_script.json"
	if FileAccess.file_exists(source_path_game):
		var existing_path : String = ProjectSettings.get_setting("diisis/project/file/path")
		if not ProjectSettings.has_setting("diisis/project/file/path"):
			ProjectSettings.set_setting("diisis/project/file/path", source_path_game)
		elif existing_path.is_empty():
			ProjectSettings.set_setting("diisis/project/file/path", source_path_game)
	else:
		popup_accept_dialogue("Error", str("Couldn't find ", source_path_game, "."))
		return
	
	var root_template := "res://addons/diisis/templates/visual_novel/stages/main_menu_stage.tscn"
	var root_game := "res://game/stages/main_menu_stage.tscn"
	if FileAccess.file_exists(root_template):
		ProjectSettings.set_setting("application/run/main_scene", root_template)
	elif FileAccess.file_exists(root_game):
		ProjectSettings.set_setting("application/run/main_scene", root_game)
	else:
		popup_accept_dialogue("Error", "Couldn't find main_menu_stage.tscn.")
		return
	
	ProjectSettings.set_setting("display/window/stretch/mode", "canvas_items")
	
	ProjectSettings.save()
	popup_accept_dialogue("Setup Successful!", "Visual Novel Template has been set up correctly :3\nRestart the editor to apply <3")

func add_editor_singletons():
	add_autoload_singleton(AUTOLOAD_PAGES, "res://addons/diisis/editor/autoload/pages.tscn")
	add_autoload_singleton(AUTOLOAD_EDITOR_UTIL, "res://addons/diisis/editor/autoload/diisis_editor_util.tscn")
	add_autoload_singleton(AUTOLOAD_EDITOR_ACTIONS, "res://addons/diisis/editor/autoload/diisis_editor_actions.tscn")
	add_autoload_singleton(AUTOLOAD_EDITOR_TEXT_TO_DIISIS, "res://addons/diisis/editor/autoload/text_to_diisis.tscn")

func add_parser_singletons():
	add_autoload_singleton(AUTOLOAD_PARSER, "res://addons/diisis/parser/autoload/parser.tscn")
	add_autoload_singleton(AUTOLOAD_PARSER_EVENTS, "res://addons/diisis/parser/autoload/parser_events.tscn")

func remove_editor_singletons():
	remove_autoload_singleton(AUTOLOAD_PAGES)
	remove_autoload_singleton(AUTOLOAD_EDITOR_UTIL)
	remove_autoload_singleton(AUTOLOAD_EDITOR_ACTIONS)
	remove_autoload_singleton(AUTOLOAD_EDITOR_TEXT_TO_DIISIS)

func remove_parser_singletons():
	remove_autoload_singleton(AUTOLOAD_PARSER)
	remove_autoload_singleton(AUTOLOAD_PARSER_EVENTS)

func _enter_tree():
	Engine.set_meta("DIISISPlugin", self)
	if not ProjectSettings.has_setting("diisis/plugin/view/embedded"):
		ProjectSettings.set_setting("diisis/plugin/view/embedded", false)
	ProjectSettings.set_restart_if_changed("diisis/plugin/view/embedded", true)
	# property info doesnt work
	# but in case you get it to work, here's the descriptions
	if not ProjectSettings.has_setting("diisis/project/file/path"):
		# "Path to the latest edited file, uses by DIISIS internally. If you want to change / override which file gets read, use [member Parser.source_path_override] instead."
		ProjectSettings.set_setting("diisis/project/file/path", "")
		ProjectSettings.save()
	ProjectSettings.add_property_info({
	"name": "diisis/project/file/path",
	"type": TYPE_STRING,
	"hint_string": "one,two,three"
}

)
	if not ProjectSettings.has_setting("diisis/plugin/updates/check_for_updates"):
		# "Sends a HTTP request to GitHub on opening DIISIS to check for new version tags."
		ProjectSettings.set_setting("diisis/plugin/updates/check_for_updates", true)
		ProjectSettings.save()
	add_autoload_singleton(AUTOLOAD_SHARED_DIISIS, "res://addons/diisis/shared/autoload/Diisis.tscn")
	add_editor_singletons()
	add_parser_singletons()
	add_custom_type("LineReader", "Node", preload("res://addons/diisis/parser/src/line_reader.gd"), preload("res://addons/diisis/parser/style/icon_line_reader.svg"))
	
	if not OS.has_feature("editor"):
		return
	
	if _embedded:
		await get_tree().process_frame
		add_new_dialog_editor_window()
	else:
		toolbar_button = preload("res://addons/diisis/editor/open_editor_button.tscn").instantiate()
		add_control_to_container(EditorPlugin.CONTAINER_TOOLBAR, toolbar_button)
		toolbar_button.visible = true
		toolbar_button.is_in_editor = true
		toolbar_button.request_open_diisis.connect(open_editor)
		toolbar_button.request_setup_template.connect(on_request_setup_template)
	
		await get_tree().process_frame
		toolbar_button.get_parent().move_child(toolbar_button, -2)
	

	var welcome_message := "[font=res://addons/diisis/editor/visuals/theme/fonts/text_main_base-medium.tres]"
	welcome_message += "Thank you for using [hint=Dialog Interface Sister System]DIISIS[/hint]! Feel free to reach out on GitHub with any bugs you encounter and features you yearn for :3"
	print_rich(welcome_message)

func on_request_setup_template(template:int):
	var load_error := ""
	if not ResourceLoader.exists("res://addons/diisis/templates/_meta/template_setup_confirmation_window.tscn"):
		load_error = "res://addons/diisis/templates/_meta/template_setup_confirmation_window.tscn"
	if not DirAccess.dir_exists_absolute("res://addons/diisis/templates/_meta"):
		load_error = "res://addons/diisis/templates/_meta"
	if not DirAccess.dir_exists_absolute("res://addons/diisis/templates"):
		load_error = "res://addons/diisis/templates"
	if not load_error.is_empty():
		push_warning("%s doesn't exist! If you moved or deleted the templates, you can restore them by downloading the plugin again." % load_error)
		return
	match template:
		0:
			if is_instance_valid(confirmation_window):
				confirmation_window.queue_free()
			confirmation_window = load("res://addons/diisis/templates/_meta/template_setup_confirmation_window.tscn").instantiate()
			get_editor_interface().get_base_control().add_child.call_deferred(confirmation_window)
			confirmation_window.confirmed.connect(setup_vn_template)
			confirmation_window.canceled.connect(confirmation_window.queue_free)
			confirmation_window.title = "Add Visual Novel Template?"
			confirmation_window.show()

func popup_accept_dialogue(dia_title:String, dia_text:String, dia_ok_button_text:="OK"):
	if is_instance_valid(accept_dialogue):
		accept_dialogue.queue_free()
	accept_dialogue = AcceptDialog.new()
	get_editor_interface().get_base_control().add_child.call_deferred(accept_dialogue)
	accept_dialogue.dialog_autowrap = true
	accept_dialogue.initial_position = Window.WINDOW_INITIAL_POSITION_CENTER_SCREEN_WITH_MOUSE_FOCUS
	accept_dialogue.size = Vector2(499, 236)
	accept_dialogue.confirmed.connect(confirmation_window.queue_free)
	accept_dialogue.canceled.connect(confirmation_window.queue_free)
	accept_dialogue.title = dia_title
	accept_dialogue.dialog_text = dia_text
	accept_dialogue.ok_button_text = dia_ok_button_text
	accept_dialogue.show()

func open_editor():
	if _embedded:
		return
	if is_instance_valid(dia_editor_window):
		dia_editor_window.set_windowed()
		dia_editor_window.grab_focus()
	else:
		add_new_dialog_editor_window()
		var project_file_path : String = ProjectSettings.get_setting("diisis/project/file/path")
		if FileAccess.file_exists(project_file_path) and not project_file_path.is_empty():
			dia_editor_window.file_path = project_file_path
		
		await get_tree().process_frame
		dia_editor_window.popup()
		dia_editor_window.open_new_file.connect(open_new_file)
		dia_editor_window.request_reload_editor.connect(on_window_request_reload_editor)
		dia_editor_window.closing_editor.connect(set.bind("dia_editor_window", null))


func add_new_dialog_editor_window():
	if _embedded:
		if embedder:
			embedder.queue_free()
		await get_tree().process_frame
		embedder = preload("res://addons/diisis/editor/src/editor.tscn").instantiate()
		embedder.size_flags_vertical = Control.SIZE_EXPAND_FILL
		EditorInterface.get_editor_main_screen().add_child(embedder)
		var project_file_path : String = ProjectSettings.get_setting("diisis/project/file/path")
		if FileAccess.file_exists(project_file_path) and not project_file_path.is_empty():
			embedder.init(project_file_path)
		else:
			embedder.init()
		_make_visible(false)
		embedder.open_new_file.connect(open_new_file)
		embedder.request_template_setup.connect(on_request_setup_template)
	else:
		dia_editor_window = preload("res://addons/diisis/editor/dialog_editor_window.tscn").instantiate()
		get_editor_interface().get_base_control().add_child.call_deferred(dia_editor_window)


func _make_visible(visible):
	if embedder:
		embedder.visible = visible

func _get_plugin_name():
	return "DIISIS"

func _has_main_screen():
	return _embedded


func _get_plugin_icon():
	return load("res://addons/diisis/logos/icon_buttonbw smooth.png")


func open_new_file():
	if FileAccess.file_exists("user://import_override_temp.json") and _embedded:
		ProjectSettings.set_setting("diisis/project/file/path", "user://import_override_temp.json")
	else:
		ProjectSettings.set_setting("diisis/project/file/path", "")
	add_new_dialog_editor_window()
	if _embedded:
		return
	if FileAccess.file_exists("user://import_override_temp.json"):
		dia_editor_window.file_path = "user://import_override_temp.json"
	else:
		dia_editor_window.file_path = ""
	dia_editor_window.tree_entered.connect(dia_editor_window.popup)
	dia_editor_window.open_new_file.connect(open_new_file)
	dia_editor_window.request_reload_editor.connect(on_window_request_reload_editor)
	dia_editor_window.title = "DIISIS"

func on_window_request_reload_editor():
	await get_tree().process_frame
	open_editor()

func _process(delta: float) -> void:
	if is_instance_valid(dia_editor_window):
		dia_editor_window.wrap_controls = true

func _exit_tree():
	Engine.remove_meta("DIISISPlugin")
	remove_editor_singletons()
	remove_parser_singletons()
	remove_autoload_singleton(AUTOLOAD_SHARED_DIISIS)
	if dia_editor_window:
		dia_editor_window.queue_free()
	if embedder:
		embedder.queue_free()
	remove_control_from_container(EditorPlugin.CONTAINER_TOOLBAR, toolbar_button)

func get_version() -> String:
	var config: ConfigFile = ConfigFile.new()
	config.load(get_plugin_path() + "/plugin.cfg")
	return config.get_value("plugin", "version")


## Get the current path of the plugin
func get_plugin_path() -> String:
	return get_script().resource_path.get_base_dir()
