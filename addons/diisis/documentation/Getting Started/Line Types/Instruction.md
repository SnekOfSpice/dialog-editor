This page is about the Instruction line type. For more information on function calls in DIISIS, see [Accessing functions and variables in DIISIS](https://github.com/SnekOfSpice/dialog-editor/wiki/Accessing-functions-and-variables-in-DIISIS).



**This is the DIISIS 0.6 version of this page. None of this will make sense if you're on an earlier version. See page history!**


# The Line
Instructions have two components: The function call itself and a delay. The call gets [sent to Godot](https://github.com/SnekOfSpice/dialog-editor/wiki/Accessing-functions-and-variables-in-DIISIS).

## Delay

The delay before call will block the line reader for that many seconds before executing the instruction. Similarly, the delay after the call will block the LineReader from going to the next line for that many seconds.


# Editing Existing Functions
When you edit function signatures in your line reader script, this may lead to errors in DIISIS, just like it would in GDScript. These you have to fix yourself. (Text search + replace on ctrl+F might be handy here)

In File>Preferences>Editor you have the 
![image](https://github.com/user-attachments/assets/7328ae5e-63c3-4e6a-9bb5-dcf9e16da9ab)
option. This may cause small stutters but will validate all functions as soon as possible. If turned off, you will see errors populate the document as DIISIS reindexes the functions as you go through it.





# Reverse Instructions

The function ``LineReader.request_go_back()`` allows you to go back up the dialogue tree to almost any previous point in time. (Until you hit a Choice or Folder).

The ![image](https://github.com/user-attachments/assets/3cf208c6-4854-4d2f-9158-f9400fb18b7a) "Reverse" toggle determines if the function will be called again as you do this. Personally, I don't use them for scenic transitions like fades-to-black or chapter splash screens, but enable "reverse" for SFX or screen shakes.

If you leave the reverse text box empty, the regular function will be called again. If you want to override it, you can declare a custom function to be called instead (doesn't have to be the same function.)

Reverse functions will ignore the delay before/after call.

![image](https://github.com/user-attachments/assets/f510d181-99a2-480c-ab17-708cfbce3db0)
