# Changing & Testing different options

**Options come from Options and get applied on game startup**

The template comes with its own set of autoloaded systems. Editing the default values of LineReader in GameStage, e.g. ``text_speed`` won't do anything. Instead, use ``Options.tscn`` to set the default behavior.

![grafik](https://github.com/user-attachments/assets/2fee65e2-bba4-4e13-8fc2-505fe7579bef)

Once the template has been booted up once, the user preferences will be saved in [``user://preferences.cfg``](https://docs.godotengine.org/en/stable/tutorials/io/data_paths.html#accessing-persistent-user-data-user). When you launch the game (exported or via F5 in editor), those will get applied. So if you want to test your game with various text speeds, use the options menu in the actual game, and not the nodes in the scenes. (Or delete the preferences.cfg file)

# Reserved Names
out of convention in my own gamedev processes, a few words are reserved within the vn template:
- for any instruction that references backgrounds or bgm, "none" and "null" will keep whatever value is currently set there
- "invisible" as emotion for characters will make them invisible instead of loading a sprite
