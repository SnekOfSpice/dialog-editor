@tool
extends RichTextLabel

#const REMOTE_RELEASES_URL = "https://api.github.com/repos/SnekOfSpice/dialog-editor/tags"
const REMOTE_RELEASES_URL = "https://godotengine.org/asset-library/asset/3188"
const VERSION_COMPARE_LENGTH := 6

# shoutout to dialog manager, ripped this code straight from there
@onready var http_request: HTTPRequest = $HTTPRequest
@export_tool_button("lmao") var a = check_for_updates

func check_for_updates() -> void:
	visible = false
	text = ""
	if ProjectSettings.get_setting("diisis/plugin/checks/check_for_updates"):
		http_request.request(REMOTE_RELEASES_URL)

func _on_http_request_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	if result != HTTPRequest.RESULT_SUCCESS: return
	
	var current_version: String = Engine.get_meta("DIISISPlugin").get_version()
	
	var s : String = body.get_string_from_utf8()
	s = s.split("<h4 class=\"media-heading\">")[1]
	s = s.split("</small>")[0]
	s = s.split("<small>")[1]
	
	var version_strings := [s]
	version_strings.append(current_version)
	version_strings.sort_custom(func(s1 : String, s2 : String):
		return s1.naturalnocasecmp_to(s2) == 1
		)
	
	var newest_version : String = version_strings.front()
	
	if newest_version != current_version:
		text = str(
			"[url=https://godotengine.org/asset-library/asset/3188]",
			"update available: ",
			newest_version,
			"[/url]"
		)
		visible = true

func find_button(start:Node, path_to_here:=""):
	if path_to_here.contains("DialogEditorWindow"):
		return
	var path = path_to_here + " > " + start.name
	if start is LineEdit:
		print(path)
	for c in start.get_children():
		find_button(c, path)



func _on_meta_clicked(_meta: Variant) -> void:
	#OS.shell_open(str(meta))
	DiisisEditorUtil.select_godot_main_window_tab("AssetLib")
	
	for c in EditorInterface.get_editor_main_screen().get_children():
		if c.name.contains("EditorAssetLibrary"):
			var vbox : VBoxContainer = c.get_child(0)
			for cc in vbox.get_children():
				if not cc is HBoxContainer:
					continue
				var line_edit = DiisisEditorUtil.find_child_that_contains(cc, "LineEdit")
				if line_edit is LineEdit:
					line_edit.text = "diisis"
					line_edit.caret_column = "diisis".length()
					line_edit.text_changed.emit("diisis")
					
					var editor_window : Window = Pages.get_editor_window()
					editor_window.minimize()
				
