# Editor & Parser
DIISIS has two core components: An [editor](https://github.com/SnekOfSpice/dialog-editor/wiki/Editor-Overview) to create a JSON file. That file is then parser by a [Parser](https://github.com/SnekOfSpice/dialog-editor/wiki/LineReader-&-Parser) and displayed with a dedicated LineReader node.

![grafik](https://github.com/user-attachments/assets/cec562c6-6bb1-4532-b61f-7bfa4c12578d)


# Pages & Lines
DIISIS is structured into Pages and Lines. These are rough guides for laying out the structure of your document. Generally, you want to use pages for isolated scenes, then fill them with lines.

![grafik](https://github.com/user-attachments/assets/49e86174-5b70-4e3a-b52e-f7eba78e669d)

Lines can have one of four types:
* [Text](https://github.com/SnekOfSpice/dialog-editor/wiki/Line-Type:-Text): Displays text to the screen, using a bespoke syntax.
* [Choice](https://github.com/SnekOfSpice/dialog-editor/wiki/Line-Type:-Choice): Offers choices to the player. Can also be used to implictly switch pages.
* [Instruction](https://github.com/SnekOfSpice/dialog-editor/wiki/Line-Type:-Instruction): Calls functions to interact with the rest of the game.
* Folder: Structures lines into groups to assist with reactivity in-game and readability in-editor.


# Facts & Conditionals
DIISIS comes with a boolean fact system. For any page, line, or choice item, you can declare any fact to become `true` or `false` when that point of the dialog is reached.

With conditionals attached to individual lines or choice items, you can make the game reactive to player decisions.