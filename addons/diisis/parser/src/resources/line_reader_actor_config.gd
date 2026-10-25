extends Resource
class_name LineReaderActorConfig

## A resource class used to control how actors are displayed. Used by [LineReader].[br]
## When changed during runtime, LineReader updates automatically.[br][br]
## [b]Note:[/b] For outlines across all actors, consider using a [Theme] instead.

@export_group("Name", "name_")
## The proper name of the character you want to show to the player. Localization doesn't cover all use cases yet.
@export var name_display := "":
	set(value):
		if value != name_display:
			name_display = value
			emit_changed()
@export var name_prefix := "":
	set(value):
		if value != name_prefix:
			name_prefix = value
			emit_changed()
@export var name_suffix := "":
	set(value):
		if value != name_suffix:
			name_suffix = value
			emit_changed()

## When [member LineReader.chatlog_enabled] is true, these names will be used if not empty. If empty, defaults to [member name_display].
@export var chatlog_name_display := "":
	set(value):
		if value != chatlog_name_display:
			chatlog_name_display = value
			emit_changed()

@export_group("Appearance")
@export var default_settings : LabelSettings:
	set(value):
		if value != default_settings:
			default_settings = value
			if default_settings:
				default_settings.changed.connect(emit_changed)
			emit_changed()
@export var chatlog_settings : LabelSettings:
	set(value):
		if value != chatlog_settings:
			chatlog_settings = value
			if chatlog_settings:
				chatlog_settings.changed.connect(emit_changed)
			emit_changed()


@export_group("Body Label", "body_label")
## Gets prefixed to text lines, after [member LineReader.body_label_prefix].
@export var body_label_prefix := "":
	set(value):
		if value != body_label_prefix:
			body_label_prefix = value
			emit_changed()
## Gets suffixed to text lines, before [member LineReader.body_label_prefix].
@export var body_label_suffix := "":
	set(value):
		if value != body_label_suffix:
			body_label_suffix = value
			emit_changed()
