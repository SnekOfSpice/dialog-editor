extends Resource
class_name LineReaderActorConfig

## A resource class used to control how actors are displayed. Used by [LineReader].[br][br]
## [b]Note:[/b] For outlines across all actors, consider using a [Theme] instead.

@export_group("Name", "name_")
@export var name_display := ""
@export var name_prefix := ""
@export var name_suffix := ""

@export_group("Color")
## Use [const Color.TRANSPARENT] to use the default theme color.
## Will use color of [Label] if [LineReader.name_style] is [LineReader.NameStyle.NameLabel]
## or the normal text color of [RichTextLabel] if [LineReader.name_style] is [LineReader.NameStyle.Prepend].
@export var color := Color.TRANSPARENT
@export var outline_color := Color.WHITE
@export var outline_size := 0
@export_group("Chatlog", "chatlog_")
## When [member LineReader.chatlog_enabled] is true, these names will be used if not empty. If empty, defaults to [member name_display].
@export var chatlog_name_display := ""
## Color used if [member LineReader.chatlog_enabled] is true. See [member color].
@export var chatlog_color := Color.TRANSPARENT
@export var chatlog_outline_color := Color.WHITE
@export var chatlog_outline_size := 0

@export_group("Body Label", "body_label")
## Gets prefixed to text lines, after [member LineReader.body_label_prefix].
@export var body_label_prefix := ""
## Gets suffixed to text lines, before [member LineReader.body_label_prefix].
@export var body_label_suffix := ""
