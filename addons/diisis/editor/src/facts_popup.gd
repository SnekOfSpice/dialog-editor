@tool
extends Window

func select_fact(fact:String):
	$FactsPopupContent.select_fact(fact)

func _on_about_to_popup() -> void:
	$FactsPopupContent.init()

func _on_close_requested() -> void:
	hide()
