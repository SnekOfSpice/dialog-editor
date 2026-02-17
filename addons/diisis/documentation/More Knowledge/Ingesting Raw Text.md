DIISIS allows you to parse raw text into your working file. This can happen on two levels: File-level [importing](https://github.com/SnekOfSpice/dialog-editor/wiki/Importing-and-Exporting-raw-text) or line-level ingestion. Importing (File > Import) allows you to take a bit of raw text and build an entirely new DIISIS file around it, or update your existing one. The second case, is ingestion - which I use much more regularly. For ingestion, any Text Line can take text from a file or your clipboard, and transform it into valid DIISIS syntax. To allow this, the text needs to follow certain formatting guidelines.


![ingestionnn](https://github.com/user-attachments/assets/cdf00f5a-9862-456c-97a9-234bca78eb02)


# Actor declarations
Inside your project, you will usually have one unchanging set of actors. You can declare them in Utility > Ingestion Actors (Ctrl + I) with the following syntax:

They are separated with a space `` ``.

Syntax is added as needed so these are all valid actor declarations:

``n narrator``

``n: narrator``

``n []>narrator``

``n: []>narrator:``

etc...

<img width="421" height="178" alt="image" src="https://github.com/user-attachments/assets/784b0d21-7a39-4bcf-9d96-1f8351c22fbd" />


You can also try and have DIISIS auto-generate these based on your [dropdown setup](https://github.com/SnekOfSpice/dialog-editor/wiki/Dropdowns) using the "populate from character" button.

Alternatively, you can override these settings by writing out an actor declaration, newline "LINE" and then the content as usual. Then you have to declare all the actors however, even those that do not change.

![custom](https://github.com/user-attachments/assets/290cd5d7-c6f3-40fd-bc71-cffb0c636340)




