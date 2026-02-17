# Text Syntax in the Editor

Lines of the Text type are what determines the bulk of the text that will be displayed in your game.

## Actor Names
All text displayed needs to be allocated to an actor / speaker / character / whatever. To create those, go to [Dropdowns](https://github.com/SnekOfSpice/dialog-editor/wiki/Dropdowns) in the Setup menu.

![grafik](https://github.com/SnekOfSpice/dialog-editor/assets/69637995/955affc4-3abc-4ea8-ae8d-303c588c037f)

Name a dropdown to the key you want to use to address your actors, e.g. "characters", and enter the different values you'll need. Note that these are internal keys, and the names that actually get displayed to the player can be overridden [at a later point in time](https://github.com/SnekOfSpice/dialog-editor/wiki/Quick-Start-Guide-%E2%80%90-LineReader-&-Parser#name-setup).

![grafik](https://github.com/SnekOfSpice/dialog-editor/assets/69637995/cac40ca1-29ad-4aaf-b2cc-c1d3e6878821)

Then, head over to the DialogSyntax tab, and select the dropdown you just created to be the speaking dropdown, using the radio buttons to the right.

![grafik](https://github.com/SnekOfSpice/dialog-editor/assets/69637995/07a36420-f649-4883-8e3d-938ad5d45499)

Now you're ready to start writing text. Add a line of Text type, and you will be prompted with the text completion for the characters you declared.

![grafik](https://github.com/SnekOfSpice/dialog-editor/assets/69637995/998e2a83-ab8f-4859-b8b0-6d5ac4f1bb09)

The syntax is the following: Newline characters do not get interpreted as line breaks. Instead, when you hit enter, a new symbol sequence will be created (`[]>`) to denote a new speaking part.
```
[]>narrator: It was once upon a time, that there was a lone programmer. They were really gay.
[]>character1: I am super gay.
```
This would already be sufficient to display text in your game.

## Dialog Arguments

Additionally to the names of actors, you can also pass different arguments for each spoken line of text.

Configuring which dropdowns are treated as dialog arguments can also be adjusted in the DialogSyntax tab of the Dropdowns menu.

![grafik](https://github.com/SnekOfSpice/dialog-editor/assets/69637995/c7e19c79-fc08-418a-9548-e9d1b405cd09)

When you move the cursor in front of the colon `:` after the actor, and enter a curly brace `{`, you can enter dialog arguments. This can be used to e.g. give your characters varying emotions as they speak. See [Using Event Signals](https://github.com/SnekOfSpice/dialog-editor/wiki/Using-Event-Signals).

![dialog_args](https://github.com/SnekOfSpice/dialog-editor/assets/69637995/102366ce-f126-4e20-ae89-eb9a0125df22)


## Inline Tags
Additionally, several inline tags can be used to create more dynamic text.
### BBCode
Typing a square bracket `[` will prompt you with different [BBCode tags](https://docs.godotengine.org/en/stable/tutorials/ui/bbcode_in_richtextlabel.html). The code completion is not exhaustive and all text offers full BBCode support. You can escape BBCode tags with a backslash `\`.

### Other
Typing an angle bracket `<` will instead give you other dynamic options.
#### `<advance>`
Force Advance: Will advance LineReader immediately upon finishing a line of text. Can be used for pacing or to simulate characters cutting each other off. Only works when put at the end of a line of text. (Either before a new speaking part begins with `[]>` or before a `<lc>` tag)

#### `<ap>`
Auto-Pause: Make the LineReader pause for `LineReader.auto_pause_duration` of seconds.

#### `<call:FUNCNAME(...)>`
Called Function: Calls FUNCNAME in InlineEvaluator when that position in the text is reached. Takes in any number of arguments.

#### `<clname:NAME>`
Chatlog Name.

#### `<comment:TEXT>`
Comment: Emits ``ParserEvents.comment`` with the content of the comment when that position in the text is reached.

#### `<fact:NAME>`
Fact: Inserts the string representation of fact NAME. true/false or integer. If you need a custom response, use the ``<func>`` tag.


#### `<fbrf:FUNCNAME(...)>`
Full Body Replacement Function. Use as the **only** text inside a text line to instead replace the text body with the return value of the function. The return value must still follow diisis formatting.

#### `<func:FUNCNAME(...)>`
Evaluated Function: Calls FUNCNAME in ``LineReader.instruction_handler`` at the start and inserts the result. Takes in any number of arguments. Functions called this way should return a String.

#### `<lc>`
Line Clear: Break up text spoken by the same character.
#### `<mp>`
Manual Pause: The body label will stop displaying text until ``LineReader.request_advace()`` successfully requests the advancement. The body label will not be cleared upon advancing.
#### `<name:NAME>`
Evaluated Name: Inserts the value of key NAME in the name map.
#### `<strpos>`
String Position: Gets replaced with a blank string. When the line starts getting read, the `ParserEvents.notify_string_positions` signal will contain an array of ints that correspond to the marked positions.
#### `<ts_*>`
Text speed overrides.

`<ts_abs:VALUE>` sets the text speed to an absolute value. `<ts_rel:VALUE>` multiplies the text speed by the given value. 

They override each other and always use the LineReader's base text speed / cannot be chained. Suppose a text speed of 30, then `text <ts_abs:50>more text <ts_rel:2>even more text` would result in a text speed of [50, then 60], not [50, then 100].

The resulting text speed overrides LineReader.text_speed for that line chunk. (So until a new line starts with `[]>`). The resulting text speed is clamped between 1 and the highest text speed below instant. **These will have no effect when text speed is set to Instant.**

`<ts_reset>` resets the override set with `<ts_abs:VALUE>` or `<ts_rel:VALUE>`.

#### `<var:VARNAME>`
Evaluated Variable: Inserts the string representation of that variable in the respective LineReader script or autoload.