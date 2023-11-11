extends Window

#
func fill():
	find_child("Facts").clear()
	for fact in Pages.facts.keys():
		var fact_reg = str(fact, ": ", Pages.facts.get(fact))
		find_child("Facts").add_item(fact_reg)
	
#	find_child("FactsTree").clear()
#	var root = find_child("FactsTree").create_item()
#	for fact in Pages.facts:
#		var f = find_child("FactsTree").create_item(root)
#		f.set_text(0, fact)
	



#
func _on_about_to_popup() -> void:
	fill()
#
#
func _on_close_requested() -> void:
	hide()


func _on_facts_item_clicked(index: int, at_position: Vector2, mouse_button_index: int) -> void:
	var f = find_child("Facts").get_item_text(index)
	var references = Pages.lines_referencing_fact(f)
	
	var s = "Pages containing fact:\n"
	for r in references.get("ref_pages"):
		s += str(r, "\t\t\t\t(", Pages.page_data.get(int(r)).get("page_key"), ")")
		s += "\n"
	find_child("RefPages").text = s
	
	s = "Conditionals referencing fact:\n"
	for r in references.get("ref_lines_condition"):
		s += str(r)
		s += "\n"
	find_child("RefDeclare").text = s
	
	s = "Lines declaring fact:\n"
	for r in references.get("ref_lines_declare"):
		s += str(r)
		s += "\n"
	find_child("RefChoiceDeclare").text = s
	
	s = "Choice Items declaring fact:\n"
	for r in references.get("ref_lines_choice_declare"):
		s += str(r)
		s += "\n"
	find_child("RefCondition").text = s
	
	s = "Choice Items referencing fact as conditional:\n"
	for r in references.get("ref_lines_choice_condition"):
		s += str(r)
		s += "\n"
	find_child("RefChoiceCondition").text = s
		
