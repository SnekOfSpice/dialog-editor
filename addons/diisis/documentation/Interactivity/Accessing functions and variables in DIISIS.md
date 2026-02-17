# Boundaries

Within the function bodies discussed here, you need to handle calls to the rest of the game architecture yourself. If you use the [VN template](https://github.com/SnekOfSpice/dialog-editor/wiki/Using-the-visual-novel-template), the project will include several functions already defined, with the matching game architecture to match.

DIISIS *itself* doesn't know what a background music is. These are all systems you have to implement yourself if you don't use a template from the project.

# Exposing Scripts
DIISIS can call functions from two places: LineReaders and Autoloads, but those need to be exposed to DIISIS first. To do this, go to Setup > Functions & Variables.

## LineReader
Somewhere in your project, you'll have a node that extends LineReader, which will contain the functions you want to call from within DIISIS. Conventionally, these would be fairly close to the root of your game. Enter the path to that script manually, or let DIISIS try to find it itself with the "Auto Search" button. **Don't forget to save the changes at the bottom.**

![image](https://github.com/user-attachments/assets/b5737c6e-d47d-4339-9079-02d159c829bb)

## Autoloads

In the Autoload tab, you can also toggle any autoloads you want to be able to access functions from. This can be used to avoid code duplication if all you'd do in your LineReader is call an autoload function.

![image](https://github.com/user-attachments/assets/c839718c-1cbd-4521-a0d1-ad72c8ed9c1c)

## You did it!

Once exposed, DIISIS can validate the function syntax and help with code completion!

![image](https://github.com/user-attachments/assets/680cb657-edb6-403e-8a19-6e1887a2f0a7) ![help](https://github.com/user-attachments/assets/12ca4373-7e76-4bd6-a176-299cc180c492) 

# Return types & acceding

You can make DIISIS not continue after calling a function by having that function return a boolean ``true``. If you do, the document won't be read further until you call ``Parser.function_acceded()``from somewhere in your code.


# Calling functions & accessing variables

Once set up, you can call functions and access variables at different points in DIISIS.

## Instruction Line

An instruction line is a singular line that calls the function in its text box.

![image](https://github.com/user-attachments/assets/134d8dbb-ce57-42e6-bf11-5dd98c0c43d4)


For further reading, see [[Instruction]].


## Inline Tags

There's 3 types of tag relevant for our purposes here:
- ``call`` will call the function.
- ``func`` will call the function and insert its return value as a String in its position.
- ``var`` will access the variable and insert its value as a String in its position.

If a ``call`` tag returns true, the LineReader will wait until ``Parser.function_acceded()`` has been called, just like with instruction lines. A ``func`` tag will **not** cause LineReader to wait and instead just insert a String ``"true"`` if you try to. 

For further reading on tags, see [here](https://github.com/SnekOfSpice/dialog-editor/wiki/Line-Type:-Text#inline-tags)


# Helpful tips

You can hold ctrl and click on any variable or function in DIISIS and Godot will pull up the respective script and place within the script, provided the script editor is open. (If you're currently in 2D view for example, this doesn't work)

# Restrictions
Only arguments of type String, float, int, and bool are currently supported. Untyped arguments are defaulted to be Strings.

![image](https://github.com/user-attachments/assets/32c6d66c-4d42-4076-8594-4d4b27258752)
![image](https://github.com/user-attachments/assets/cde71603-8250-4132-b7a8-85d0f31b653e)

![image](https://github.com/user-attachments/assets/d81281cd-240e-4e5d-abbe-7d480c760f2a)
![image](https://github.com/user-attachments/assets/10e0e7d1-2ef8-4785-95c8-d16362e8400b)


