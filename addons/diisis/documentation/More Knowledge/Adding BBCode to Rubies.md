Rubies themselves cannot parse BBCode: ``<ruby:[b]aaaa[/b]>`` will not work because of how DIISIS parses the text content at runtime. However, we can use Godot's native localization (l10n) system to take care of that.

## Step 1: Create rubies with localizable keys.
``<ruby:rubies.boldscream>``

## Step 2: Create a google doc
![[Pasted image 20260227082552.png]]

Download this as a csv file & move it into the godot project files

## Step 3: Add it to the project in project settings
![[Pasted image 20260227082632.png]]

## Step 4: Wow it works

![[Pasted image 20260227082724.png]]

> Why does this work?

This takes advantage of the fact that all ``Label``s and ``RichTextLabel``s in Godot will automatically look up their contents on the translation server. if we assume english as the default, we're just adding an english-english translation (common practice)