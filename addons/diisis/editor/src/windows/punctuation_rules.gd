@tool
extends Control

func init():
	%PeriodCheckBox.button_pressed = Pages.append_periods
	%ShrineLabel.visible = Pages.silly
	
	var rules : Array
	if Pages.replacement_rules.is_empty():
		rules = Pages.DEFAULT_REPLACEMENT_RULES.duplicate(true)
		Pages.replacement_rules = rules
	else:
		rules = Pages.replacement_rules
	
	for rule : Dictionary in rules:
		add_rule(rule)

func add_rule(rule_definition:Dictionary):
	var rule_item = preload("res://addons/diisis/editor/src/replacement_rule.tscn").instantiate()
	find_child("ReplacementRules").add_child(rule_item)
	rule_item.deserialize(rule_definition)
	rule_item.rule_updated.connect(on_rule_updated)

func _on_period_check_box_pressed() -> void:
	Pages.append_periods = %PeriodCheckBox.button_pressed


func _on_add_rule_button_pressed() -> void:
	add_rule({})
	update_save_button()

func on_rule_updated():
	await get_tree().process_frame
	update_save_button()

func update_save_button():
	var has_changed = not DiisisEditorUtil.array_equals(serialize_rules(), Pages.replacement_rules)
	%SaveRulesButton.text = "save"
	if has_changed:
		%SaveRulesButton.text += " (*)"

func serialize_rules() -> Array:
	var result := []
	for rule : ReplacementRule in %ReplacementRules.get_children():
		result.append(rule.serialize())
	return result

func _on_save_rules_button_pressed() -> void:
	%SaveRulesButton.text = "save"
	Pages.replacement_rules = serialize_rules()


func _on_add_defaults_button_pressed() -> void:
	for rule in Pages.DEFAULT_REPLACEMENT_RULES:
		add_rule(rule)
