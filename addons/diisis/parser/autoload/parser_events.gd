extends Node

## List of all events:

# "choice_pressed"
#		args:
#			"do_jump_page": bool,
#			"target_page": int,
#			"choice_text": String,
#	
# "choices_presented"
#		args:
#			"choices": Array
#				where every item is {
#					"disabled": bool,
#					"option_text": String,
#					"facts": Dictionary (dictionary of fact String and the value of the fact if the choice is pressed),
#					"do_jump_page": bool,
#					"target_page": int,
#				}
# "dialog_line_args_passed"
#		args:
#			"actual_name": actual_name,
#			"dialog_line_arg_dict": dialog_line_arg_dict
#		
# "fact_changed"
# 	args:
#		"old_value" : Array of Strings
#		"fact_name": String
#		"new_value": bool
#
# "name_label_updated"
	## uses the actual string that ends up in LineReader.name_label
#	args:
#		"actor_name": String
#		"is_name_container_visible": bool
#
# "new_actor_speaking"
	## uses internal key of the name from name_label_updated (may be identical)
#	"actor_name": String
#	"is_name_container_visible": bool
#
# "new_header"
#	args:
#		"header": Array where every item is {"data_type": int, "property_name": String, "values": Array of size 2}
#
# "page_finished"
#	args:
#		"page_index": int
#
# "read_new_page"
#	args:
#		"number":int
#
# "terminate_page"
#	args:
#		"page_index": int
#
# "text_content_text_changed"
#	the entire text, irregardless of visible_characters
#	args:
#		"old_text": String
#		"new_text": String
#
# "word_read"
#	args:
#		"word": String

var event_listeners := {}

# all listeners should implement
# func handle_event(event_name: String, event_args: Dictionary):
func listen(listener: Node, event_name: String):
	var listeners: Array = event_listeners.get(event_name, [])
	if not listeners.has(listener):
		listeners.append(listener)
		if not listener.tree_exiting.is_connected(remove_listener):
			listener.tree_exiting.connect(remove_listener.bind(listener))
	event_listeners[event_name] = listeners

## removes the listener from all events by iterating over all values of event_listeners
func remove_listener(listener: Node):
	for key in event_listeners.keys():
		unlisten(listener, key)

func unlisten(listener: Node, event_name: String):
	var listeners: Array = event_listeners.get(event_name, [])
	if listeners.has(listener):
		listeners.erase(listener)
		listener.tree_exiting.disconnect(remove_listener.bind(listener))
	event_listeners[event_name] = listeners

func start(event_name: String, event_args: Dictionary):
	for l in event_listeners.get(event_name, []):
		if not l.has_method("handle_event"):
			push_warning(str("Listener ", l, " doesn't have method handle_event"))
			continue
		l.handle_event(event_name, event_args)
