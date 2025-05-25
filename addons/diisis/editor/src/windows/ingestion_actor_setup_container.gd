@tool
extends VBoxContainer

var text_edit : TextEdit

func init():
	text_edit = find_child("TextEdit")
	text_edit.text = Pages.ingestion_actor_declaration
	find_child("SaveButton").text = "save"
	find_child("HelpLabel").visible = false
	find_child("AutoIngestButton").text = "populate from %s" % Pages.dropdown_title_for_dialog_syntax
	
	var speakers_exist := not Pages.dropdown_title_for_dialog_syntax.is_empty()
	text_edit.visible = speakers_exist
	find_child("NoTitleWarning").visible = not speakers_exist
	find_child("Buttons").visible = speakers_exist

func _on_text_edit_text_changed() -> void:
	var save_button : Button = find_child("SaveButton")
	save_button.text = str("save", " (*)" if text_edit.text != Pages.ingestion_actor_declaration else "")


func _on_reset_button_pressed() -> void:
	text_edit.text = Pages.ingestion_actor_declaration
	_on_text_edit_text_changed()


func _on_save_button_pressed() -> void:
	Pages.ingestion_actor_declaration = text_edit.text
	_on_text_edit_text_changed()


func _on_help_button_pressed() -> void:
	find_child("HelpLabel").visible = not find_child("HelpLabel").visible


func _on_auto_ingest_button_pressed() -> void:
	var actors : Array = Pages.get_speakers()
	actors.sort()
	
	var initials_by_actor := {}
	
	var last_initial : String
	var last_initial_count := 0
	for actor : String in actors:
		if actor.is_empty():
			continue
		var initial = actor[0]
		if initial != last_initial:
			last_initial = initial
			last_initial_count = 0
		
		var suffix : String = str(last_initial_count) if last_initial_count > 0 else ""
		last_initial_count += 1
		initials_by_actor[actor] = initial + suffix
	
	var lines := []
	for actor in initials_by_actor.keys():
		lines.append("%s: %s" % [initials_by_actor.get(actor), actor])
	text_edit.text = "\n".join(lines)
	
	_on_text_edit_text_changed()


func _on_no_title_warning_meta_clicked(meta: Variant) -> void:
	Pages.editor.open_window_by_string("DropdownPopup")
	hide()
