# 🚀 Xenon Streaming Engine

A Roblox script that optimizes performance by only rendering parts in a player's vicinity.

# 💻 Code by iiPython

Copyright (c) 2023 Dokito Development Team

# 💡 What Does This Code Do?

The script is designed to improve the performance of Roblox games by only rendering parts within a specified distance from the player. Parts that are too far away are stored in a separate folder (`ServerStorage.XenonParts`), which reduces the number of parts that need to be processed by the game engine.

# 🚨 Features

    Customizable render distance (default is 50 studs)
    Customizable delay between player updates (default is 0.1 seconds)
    Customizable magnitude difference to trigger update (default is 10 studs)
    Option to ignore locked parts (baseplates, etc.)
    Option to change configuration via Value objects

# 🚦 Getting Started

    Add the script to your game's `ServerScriptService`
    Create a folder in `Workspace` named "Xenon"
    Add all parts you want to stream to the "Xenon" folder
    If desired, add IntValue or BoolValue objects to the script to change its configuration
    Enjoy improved game performance!

# 💬 Contact

Have questions or feedback? Contact iiPython on Roblox, Discord, or on GitHub!

# 🎉 Version

The current version of the Xenon Streaming Engine is 1.1.4.
# 🚀 Happy Streaming! 🚀