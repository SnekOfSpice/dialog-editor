# Upgrade to a new version
1. disable addon 

    ![grafik](https://github.com/user-attachments/assets/b05bdf2a-9342-4dda-b3cd-ed55708ea14d)
2. delete addon files (``addons/diisis``)
    > Watch out you don't delete your script.
3. [reinstall](https://github.com/SnekOfSpice/dialog-editor/wiki/Get-the-plugin)
    - don't forget to enable the plugin again, and reload the editor afterwards


# new data formats
Sometimes new versions introduce new underlying file structure to diisis. When you upgrade to a new version, it is recommended that the first thing you do is open diisis, and - if no file corruption happens - click through all the pages in the document so that you can load the old data and serialized it with the new underlying data structures. (Alternatively, use Utility > Step through pages to let DIISIS do it for you) If the file is missing things, or the console gives you a bunch of errors, the diisis version you're trying to upgrade to is probably incompatible with the one you created your project in.

I try to make my code backwards-compatible where possible, but sometimes new versions do break compatibility. Sorry!

# If you used the visual novel template:
1. Remove all template-specific autoloads (Project Settings -> Globals)
![grafik](https://github.com/user-attachments/assets/76c65067-557b-401b-b538-0d1b5764953a)

2. By downloading the plugin again, you'll have downloaded duplicates of all scenes in the VN template. This will conflict with their ``class_name``s. **Delete the new files in the template in the plugin folder (all contents of ``addons/diisis/templates/visual_novel``).**

3. Run through the [automated setup](https://github.com/SnekOfSpice/dialog-editor/wiki/Using-the-visual-novel-template#automated-setup) again.
    Don't forget to reload the project again.