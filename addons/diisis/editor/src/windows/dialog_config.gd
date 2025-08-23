@tool
extends PanelContainer

func init():
	find_child("LeadTimeSpinBoxSameActor").value = Pages.text_lead_time_same_actor
	find_child("LeadTimeSpinBoxOtherActor").value = Pages.text_lead_time_other_actor
	find_child("UseDialogSyntaxCheckBox").button_pressed = Pages.use_dialog_syntax

func _on_lead_time_spin_box_same_actor_value_changed(value):
	Pages.text_lead_time_same_actor = value


func _on_lead_time_spin_box_other_actor_value_changed(value):
	Pages.text_lead_time_other_actor = value



func _on_use_dialog_syntax_check_box_toggled(toggled_on: bool) -> void:
	Pages.use_dialog_syntax = toggled_on
