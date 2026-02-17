The Arguments tab in Setup > Functions & Variables allows you to further customize the arguments you pass to your scripts.

# Default

As the window informs you, you can optionally define a second layer of defaults to function arguments.

Within the argument hint, a double colon ``::=`` means the default comes from DIISIS. A ``:=`` means it comes from the script itself.

![image](https://github.com/user-attachments/assets/7deca3f0-3b87-49d6-b5f7-b70b08ba0da2)
![image](https://github.com/user-attachments/assets/5f101081-f5f7-4e05-b768-74935fb46b65)

When writing functions, if a default argument is before a mandatory argument, use ``*`` to access the default.


# Dropdown Typing
Additionally, you can type any String argument as [Dropdown](https://github.com/SnekOfSpice/dialog-editor/wiki/Dropdowns).

![image](https://github.com/user-attachments/assets/e386ee1f-e463-42a6-a2ea-3b67ddfc2661)


If you do this, the argument needs to be one of the options of the dropdown. e.g. ``foo(bar:character)`` and character is a dropdown. You can permit multiple dropdowns as types. Then, the argument will be valid as long as the argument is an option in any one of the dropdowns.



