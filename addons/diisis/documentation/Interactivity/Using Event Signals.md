The class `DiisisParserEvents` (available in the internal documentation with `F1`) provides hooks for you to react to in your game. It sends out events whenever something notable happens in the LineReader. Have a look through the documentation and find the signals you need!

It is available as an autoload to your Project as `ParserEvents`.

If you had a character scene that needs to display varying emotions, a script snipped could look like this:
```gdscript
@export var character_name = ""

func _ready() -> void:
    ParserEvents.dialog_line_args_passed.connect(on_dialog_line_args_passed)

func on_dialog_line_args_passed(actor_name: String, args: Dictionary):
    if args.has(str(character_name, "-emotion")):
        var emotion_to_display : String = args.get(str(character_name, "-emotion"))
        set_emotion(emotion_to_display)

func set_emotion(emotion: String):
    pass # load a sprite or something
```
