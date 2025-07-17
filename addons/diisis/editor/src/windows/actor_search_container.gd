@tool
extends Control

func init():
	%ActorList.clear()
	%ResultsList.clear()
	var speakers := Pages.get_speakers()
	speakers.sort()
	for actor in speakers:
		%ActorList.add_item(actor)
	%ResultLabel.text = ""

# get_text_line_adrs_with_speakers

func fetch_results() -> void:
	%ResultsList.clear()
	var selected_indices : PackedInt32Array = %ActorList.get_selected_items()
	var actors := []
	for index in selected_indices:
		actors.append(%ActorList.get_item_text(index))
	var adrs : Array = Pages.get_text_line_adrs_with_speakers(actors, find_child("ExactCheckBox").button_pressed)
	for address in adrs:
		%ResultsList.add_item(address)


func _on_results_list_item_selected(index: int) -> void:
	var address = %ResultsList.get_item_text(index)
	var text_id : String = Pages.get_data_from_address(address).get("content").get("text_id")
	%ResultLabel.text = Pages.get_text(text_id)


func _on_go_to_button_pressed() -> void:
	if %ResultsList.item_count == 0:
		return
	go_to_results_index(%ResultsList.get_selected_items()[0])

func go_to_results_index(index:int):
	var address = %ResultsList.get_item_text(index)
	Pages.editor.request_go_to_address(address)


func _on_results_list_item_activated(index: int) -> void:
	go_to_results_index(index)
