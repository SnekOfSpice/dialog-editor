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


func _on_meta_clicked(meta: Variant) -> void:
	OS.shell_open(str(meta))
