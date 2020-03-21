# Mouse movement script for MTA: SA

This script allows using the middle mouse button in combination with left shift to move, rotate, and zoom the camera in the Multi Theft Auto: San Andreas editor.

[![Example of use](https://i.imgur.com/6VzcyhU.gif)](https://i.imgur.com/6VzcyhU.gifv)


## Installation

1. Download the repository (either through the releases page for a stable version, or using "Clone or download" -> "Download ZIP" from any branch).
2. Rename the downloaded zip to `mouse_camera.zip`.
3. Put the zip in `server/mods/deathmatch/resources/` (the recommended folder is `[editor]/`).
4. Start the editor.
5. Open the console with the `~` or `F8` button.
6. Type in `start mouse_camera`.

Alternatively, to edit the settings, you may unpack the zip after step 3 (making sure that all the files remain in a single directory named `mouse_camera`) and edit the `mouse_camera.lua` file where the options are located.


## Usage

### Moving the camera

Hold the middle mouse button while in cursor mode, then drag. The camera will move to keep the location you clicked under your cursor.


### Rotating the camera

Hold left shift and the middle mouse button at the same time while in cursor mode. The camera will rotate around the world position in the middle of your screen.

If you want to invert or change the sensitivity of rotation, please follow the instructions in the installation section.


### Zooming the camera

You can scroll up and down to move the camera backwards and forwards. Holding left shift will reduce the rate at which the camera moves.
