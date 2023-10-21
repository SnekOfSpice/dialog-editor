extends Window

#
func fill():
	find_child("Facts").clear()
	for fact in Pages.facts:
		find_child("Facts").add_item(fact)

#
func _on_about_to_popup() -> void:
	fill()
#
#
func _on_close_requested() -> void:
	hide()
