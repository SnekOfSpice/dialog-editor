@tool
extends RichTextLabel

const REMOTE_RELEASES_URL = "https://api.github.com/repos/SnekOfSpice/dialog-editor/tags"
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
	while current_version.count(".") < 3:
		current_version += ".0"
	var version_value = ""
	for part in current_version.split("."):
		version_value += part.rpad(3, "0")
	# Work out the next version from the releases information on GitHub
	var response = JSON.parse_string(body.get_string_from_utf8())
	
	if typeof(response) != TYPE_ARRAY: return
	
	# GitHub releases are in order of creation, not order of version
	var versions = (response as Array)
	var tags := []
	for version in versions:
		tags.append(version.get("name"))
	var tags_actual := []
	for tag in tags:
		if tag.begins_with("v"):
			tag = tag.trim_prefix("v")
		if not "." in tag:
			continue
		tags_actual.append(tag)
	tags_actual = tags_actual.filter(func(tag):
		while tag.count(".") < 3:
			tag += ".0"
		var tag_value = ""
		for part in tag.split("."):
			tag_value += part.rpad(3, "0")
		return int(tag_value) > int(version_value)
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


func _on_meta_clicked(meta: Variant) -> void:
	OS.shell_open(str(meta))
