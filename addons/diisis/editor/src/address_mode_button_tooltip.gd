@tool
extends RichTextLabel

@export_multiline var base_tooltip : String = ""

func init():
	text = base_tooltip

func add_address(address:String):
	text += "\n\n"
	text += "[color=E9C55D][wave amp=10.0 freq=-4 connected=1]RClick to go here[/wave][/color] --> "+address + " <-- [color=E9C55D][wave amp=10.0 freq=-4 connected=1]:3[/wave][/color]"
