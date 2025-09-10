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
	if ProjectSettings.get_setting("diisis/plugin/updates/check_for_updates"):
		http_request.request(REMOTE_RELEASES_URL)

func _on_http_request_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	if result != HTTPRequest.RESULT_SUCCESS: return
	
	var current_version: String = Engine.get_meta("DIISISPlugin").get_version()
	var local_subversion:=""
	if "-" in current_version:
		local_subversion = current_version.split("-")[1]
		current_version = current_version.split("-")[0]
	while current_version.count(".") < 3:
		current_version += ".0"
	var version_value = ""
	for part in current_version.split("."):
		version_value += part.rpad(3, "0")
	version_value = int(version_value)
	
	var s : String = body.get_string_from_utf8()
	s = s.split("<h4 class=\"media-heading\">")[1]
	s = s.split("</small>")[0]
	s = s.split("<small>")[1]
	
	var tags_actual := [s]
	tags_actual = tags_actual.filter(func(tag):
		var subversion:=""
		if "-" in tag:
			subversion = tag.split("-")[1]
			tag = tag.split("-")[0]
		while tag.count(".") < 3:
			tag += ".0"
		var tag_value = ""
		for part in tag.split("."):
			tag_value += part.rpad(3, "0")
		
		tag_value = int(tag_value)
		
		if version_value == tag_value:
			# subversion is not some halfbaked shit
			if not local_subversion.is_empty() and subversion.is_empty():
				return true
			
			if not subversion.is_empty() and not local_subversion.is_empty():
				var subversion_value = subversion.trim_prefix("alpha")
				var local_subversion_value = local_subversion.trim_prefix("alpha")
				return int(subversion_value) > int(local_subversion_value)
		
		return tag_value > version_value
		)
	if tags_actual.size() > 0:
		var newest_version : String = tags_actual[0]
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
				
