extends Resource
class_name LineReaderActorConfig


## whatever. doesnt do anything atm. come back when i feel more like it!
@export_group("Name", "name_")
@export var name_display := ""
@export var name_prefix := ""
@export var name_suffix := ""

@export_group("Color")
@export_subgroup("Base")
## Use Color.TRANSPARENT to use the default theme label color.
@export var color := Color.TRANSPARENT
@export var outline_color := Color.WHITE
@export var outline_size := 0
@export_subgroup("Chatlog", "chatlog_")
@export var chatlog_name_display := ""
@export var chatlog_color := Color.WHITE
@export var chatlog_outline_color := Color.WHITE
@export var chatlog_outline_size := 0
## If true, if no chatlog color or outline color is set, will attempt to use the base values before falling back to the LineReader base
@export var chatlog_default_to_base := false

@export_group("Body Label", "body_label")
@export var body_label_prefix := ""
@export var body_label_suffix := ""
