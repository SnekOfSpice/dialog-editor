Add Character to ``game_stage.tscn``
- **Make sure to adapt ``character_name``**

![grafik](https://github.com/user-attachments/assets/768dc0f2-5c6a-4908-95b1-a02caa6e69ce)

Add respective dropdowns & set the emotions you want to start out with. Adding "neutral" and "invisible" is a good idea. ("invisible" is a reserved emotion that does what you think it does.)

![grafik](https://github.com/user-attachments/assets/c72141f2-4392-4eeb-bf28-60b1865d48af)

Add them to the argument list

![grafik](https://github.com/user-attachments/assets/ae2321a0-91f8-4c3c-965d-39d86e8588ce)

Have assets for all your required emotions

![grafik](https://github.com/user-attachments/assets/2fc25e77-b8f7-475a-b50a-b211970d5149)

Using the ``{}``-syntax here (``[]>character{character-emotion|neutral}:``) will call ``set_emotion()`` in ``character.gd``.