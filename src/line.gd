extends Control


enum LineType {
	Text, Choice, Instruction
}


var line_type := LineType.Text

func set_line_type(value: int):
	line_type = value
	match line_type:
		LineType.Text:
			pass
	
	$TextContent.visible = line_type == LineType.Text
