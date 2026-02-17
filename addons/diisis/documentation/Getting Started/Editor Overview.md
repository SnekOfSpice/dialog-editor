Upon activating the plugin, you will find a new button in the top right corner of Godot. Click it to open the DIISIS editor.
![grafik](https://github.com/SnekOfSpice/dialog-editor/assets/69637995/33c6baf7-fc5d-4dd2-ba53-335303903510)

# UI
## Editor Controls
1. Undo / Redo: Click these buttons to go back and forth between your operations. The label beneath tells you the previous action.
2. Page navigation
3. Add pages
4. Line type selection
5. Line views

![grafik](https://github.com/SnekOfSpice/dialog-editor/assets/69637995/aa734c85-a7ed-4262-8987-430d4ab74137)



## Page Controls
1. Page key
2. Flow behavior
3. Select / deselect all lines
4. Page-bound facts

![grafik](https://github.com/SnekOfSpice/dialog-editor/assets/69637995/e780de80-03a0-49c2-ab51-45176d188876)

## Line Controls

1. Move line (use shift to move across folders)
2. Add line above/below: Inserts a new line of the selected line type
3. Set the [header](https://github.com/SnekOfSpice/dialog-editor/wiki/Header) data for this line (button is hidden unless a header schema is defined)
4. Edit [facts and conditionals](https://github.com/SnekOfSpice/dialog-editor/wiki/High%E2%80%90Level-Overview#facts--conditionals)
5. Select & Action menu (copy, cut, paste)
6. Count of references to this line from loopback (LB) and jump page (JP) in choices
7. Delete line

![grafik](https://github.com/SnekOfSpice/dialog-editor/assets/69637995/6e2b77f3-0dab-4c5d-8350-0e6b2df62ddf)

# Setting up the document
**MANDATORY:** [Basic text setup](https://github.com/SnekOfSpice/dialog-editor/wiki/Line-Type:-Text#actor-names)

The rest is optional:
- [Setting up instructions](https://github.com/SnekOfSpice/dialog-editor/wiki/Line-Type:-Instruction#creating-instructions)

# Exporting
Using the context menu, you can either save the file or use the Save As option to give it a custom name. These output files can be saved anywhere inside ``://res``The last file to be saved in the DIISIS window is the file to be read by the plugin (this can be overridden). Head to [LineReader & Parser](https://github.com/SnekOfSpice/dialog-editor/wiki/LineReader-&-Parser) to see how to display your work in-game.

![grafik](https://github.com/SnekOfSpice/dialog-editor/assets/69637995/934a59f6-68d1-48a3-bb0a-3663445fd59a)
