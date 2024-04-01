extends Node


## Emitted when a choice button has been pressed.
signal choice_pressed(
	do_jump_page:bool,
	target_page:int,
	choice_text:String
)

##"choices": Array [br]
##				where every item is {[br]
##					"button": Button,[br]
##					"disabled": bool,[br]
##					"option_text": String,[br]
##					"facts": Dictionary (dictionary of fact String and the value of the fact if the choice is pressed),[br]
##					"do_jump_page": bool,[br]
##					"target_page": int,[br]
##				}
signal choices_presented(
	choices:Array[Dictionary]
)

## [param actor_name] is the internal name of the actor.
signal dialog_line_args_passed(
	actor_name: String,
	dialog_line_args: Dictionary
)

## Emitted when a fact changes its value. During initialization, this will emit with [param old_value] being equal to [param new_value].
signal fact_changed(
	fact_name:String,
	old_value:bool,
	new_value:bool,
)

## Emitted when a new line of dialog is read. Passes the actual string that ends up in [param LineReader.name_label].[nr]
## See [signal actor_name_changed].
signal display_name_changed(
	display_name:String,
	is_name_container_visible: bool
)

## Emitted when a new line of dialog is read. Passes the internal key of the actor.[br]
## This will be identical to the [param display_name] in [signal actor_name_changed] if no name map override has been set.)[br]
## See [signal actor_name_changed].
signal actor_name_changed(
	actor_name: String,
	is_name_container_visible: bool
)


## Array where every item is {"data_type": int, "property_name": String, "values": Array of size 2}
signal new_header(
	header:Array[Dictionary]
)

signal page_finished(
	page_index: int
)

signal read_new_page(
	number:int
)

signal page_terminated(
	page_index: int
)

## the entire text, irregardless of visible_characters
signal text_content_text_changed(
	old_text: String,
	new_text: String
)

signal word_read(
	word: String
)
