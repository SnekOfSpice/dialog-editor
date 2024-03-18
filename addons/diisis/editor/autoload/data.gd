@tool
extends Node

var property_listeners := {}
var properties := {
	"editor.selected_line_type": DIISIS.LineType.Text,
}

func listen(listener, property: String, immediate_callback:=false):
	var cur_listeners = property_listeners.get(property)
	if cur_listeners == null:
		property_listeners[property] = [listener]
	else:
		if cur_listeners.has(listener):
			return
		else:
			cur_listeners.append(listener)
			property_listeners[property] = cur_listeners
	
	if immediate_callback:
		if listener.has_method("on_property_change"):
			listener.on_property_change(property, of(property), of(property))

func unlisten(listener, property):
	var cur_listeners = property_listeners.get(property)
	if cur_listeners == null:
		return
	
	if cur_listeners.has(listener):
		cur_listeners.erase(listener)
		property_listeners[property] = cur_listeners
		

func apply(property: String, new_value):
	var old = properties.get(property)
	properties[property] = new_value
	
	if not property_listeners.get(property):
		return
	
	for listener in property_listeners.get(property):
		if not is_instance_valid(listener):
			unlisten(listener, property)
			continue
		if listener.has_method("on_property_change"):
			listener.on_property_change(property, new_value, old)
		else:
			push_warning(str(listener, " doesnt have on_property_change"))

func of(property):
	return properties.get(property)

func change_by_int(property: String, change: int):
	apply(property, of(property) + change)
