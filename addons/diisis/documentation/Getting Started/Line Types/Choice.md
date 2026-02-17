Choices are a way of giving the game world a feeling of interactivity and plasticity.

When you first add a Choice line, it will be empty. Press the **+ button** to add a choice item.

![grafik](https://github.com/SnekOfSpice/dialog-editor/assets/69637995/d7a196d9-0c83-4593-bea3-25f1dd221d70)

![grafik](https://github.com/SnekOfSpice/dialog-editor/assets/69637995/b18f8484-ca34-4a7a-9e6d-d52fc7a16fd2)

# Choice Items

A choice item has the following anatomy:
1. Delete and move the choice item
2. Selection and action menu (copy, paste, cut)
3. [Conditionals](https://github.com/SnekOfSpice/dialog-editor/wiki/Facts-&-Conditionals#choice-items)
4. Jump flags
5. View behavior
6. Display Texts
7. [Facts](https://github.com/SnekOfSpice/dialog-editor/wiki/Facts-&-Conditionals#choice-item)

![grafik](https://github.com/SnekOfSpice/dialog-editor/assets/69637995/e3b248b5-6684-4829-a4b6-c9a477cc41db)

## Jump Flags
### Jump Page
When selecting a choice item, if its jump page flag is set, it will switch the line readers position to that page / line address.

### Loopback
Loopback choice options allow the line reader to automatically go back to where the choice was first pressed. This is useful for fanning dialogue structures. By setting a loopback address, the line reader will continue reading. When it has __finished__ reading the line at that index, it will loop back to the choice line that originally contained the choice item.

The behavior set for the "after 1st" property determines how any given choice item will appear when it is viewed again.

An example:
![grafik](https://github.com/SnekOfSpice/dialog-editor/assets/69637995/6a4d1fbc-da83-4ba9-b826-21ef3d66adb0)

## View behavior
Determines if the default apparence of the choice is in a enabled or disabled state.

# Auto Switch
Auto Switch is a flag that overrides the behavior of the choice line. Instead of presenting buttons, it will instead iterate over each choice item. On the first item where its conditional is empty or evaluates to true, the LineReader will implicitly switch to its Jump Page target.

