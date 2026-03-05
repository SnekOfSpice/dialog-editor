extends Resource
class_name TerminatorData


enum TerminatorStyle {
	## No terminator will be added.
	None,
	## A floating [Label] will be added to the end of the text in [member body_label]. [member terminator_text] will be its text.
	Text,
	## A floating [RichTextLabel] will be added to the end of the text in [member body_label]. [member terminator_text] will be its text, with BBCode enabled.
	RichText,
	## A floating [TextureRect] will be added to the end of the text in [member body_label]. [member terminator_texture] will be its texture.
	Texture,
	## A floating [Control] will be added to the end of the text in [member body_label]. [member terminator_scene] will be its child.
	Scene
}

## A terminator is a visual element denoting the end of the current line in [member body_label]. It will be hidden if the full text is visible, i.e. [member RichTextLabel.visible_ratio] is [code]1.0[/code].
## [br][br]
## [b]Note:[/b] Currently the spacing is kinda fucked up if you use bbcode in your [member body_label].
@export var terminator_style : TerminatorStyle = TerminatorStyle.None:
	set(value):
		terminator_style = value
		notify_property_list_changed()
## Text set into the terminator. See [enum TerminatorStyle] for more info.
@export var terminator_text := ""
## Texture loaded into the terminator. See [enum TerminatorStyle] for more info.
@export var terminator_texture : Texture
## Scene instanced as a child of the terminator. See [enum TerminatorStyle] for more info.
@export var terminator_scene : PackedScene

func _validate_property(property: Dictionary):
	match terminator_style:
		TerminatorStyle.None:
			if property.name in ["terminator_text", "terminator_texture", "terminator_scene"]:
				property.usage = PROPERTY_USAGE_NO_EDITOR
		TerminatorStyle.Text:
			if property.name in ["terminator_texture", "terminator_scene"]:
				property.usage = PROPERTY_USAGE_NO_EDITOR
		TerminatorStyle.RichText:
			if property.name in ["terminator_texture", "terminator_scene"]:
				property.usage = PROPERTY_USAGE_NO_EDITOR
		TerminatorStyle.Texture:
			if property.name in ["terminator_text", "terminator_scene"]:
				property.usage = PROPERTY_USAGE_NO_EDITOR
		TerminatorStyle.Scene:
			if property.name in ["terminator_texture", "terminator_text"]:
				property.usage = PROPERTY_USAGE_NO_EDITOR
