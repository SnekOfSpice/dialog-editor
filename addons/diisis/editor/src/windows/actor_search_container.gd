@tool
extends Control
class_name ActorSearchContainer

enum SearchMode {
	Any,
	All,
	Exact
}

func init():
	%ActorList.clear()
	%ResultsList.clear()
	var speakers : Array = Pages.get_speakers()
	speakers.sort()
	for actor in speakers:
		%ActorList.add_item(actor)
	%ResultLabel.text = ""
	find_child("GoToButton").disabled = true

# get_text_line_adrs_with_speakers

func fetch_results() -> void:
	var previous_selected_address : String
	if get_selected_address_index() != -1:
		previous_selected_address = %ResultsList.get_item_text(get_selected_address_index())
	%ResultsList.clear()
	var selected_indices : PackedInt32Array = %ActorList.get_selected_items()
	var actors := []
	for index in selected_indices:
		actors.append(%ActorList.get_item_text(index))
	
	var mode : SearchMode
	if %AnyCheckBox.button_pressed:
		mode = SearchMode.Any
	if %AllCheckBox.button_pressed:
		mode = SearchMode.All
	if %ExactCheckBox.button_pressed:
		mode = SearchMode.Exact
	var adrs : Array = Pages.get_text_line_adrs_with_speakers(actors, mode)
	for address in adrs:
		%ResultsList.add_item(address)
		if address == previous_selected_address:
			%ResultsList.select(%ResultsList.item_count - 1)
	
	find_child("GoToButton").disabled = get_selected_address_index() == -1


func _on_results_list_item_selected(index: int) -> void:
	var address = %ResultsList.get_item_text(index)
	var text_id : String = Pages.get_data_from_address(address).get("content").get("text_id")
	%ResultLabel.text = Pages.get_text(text_id)
	find_child("GoToButton").disabled = false


func _on_go_to_button_pressed() -> void:
	if %ResultsList.get_selected_items().size() == 0:
		return
	if %ResultsList.item_count == 0:
		return
	go_to_results_index(get_selected_address_index())

func get_selected_address_index() -> int:
	if %ResultsList.get_selected_items().size() == 0:
		return -1
	return %ResultsList.get_selected_items()[0]

func go_to_results_index(index:int):
	var address = %ResultsList.get_item_text(index)
	Pages.editor.request_go_to_address(address)


func _on_results_list_item_activated(index: int) -> void:
	go_to_results_index(index)
