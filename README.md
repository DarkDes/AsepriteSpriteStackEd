# Introduction
Scripts for Aseprite program.
**Requirements: Aseprite v1.3-rc2**

# Installation
1. Copy files _"SpriteStack_Previewer.lua"_ and _"SpriteStack_Slicer.lua"_.
2. Paste these files to the path **"%AppData%/Aseprite/scripts/"**.
3. Start Aseprite or, if the program is running, click **File > Scripts > Rescan Scripts Folder**.
4. The scripts will appear in **File > Scripts**.

### SpriteStack Previewer
Auxiliary window for displaying a sprite using Sprite Stack technology. Each frame is a slice.The window displays a preview of the sprite.  
Features:
- Real-time preview
- Sprite Stack in 360 degrees.
- Ability to view each slice.
- Changing the distance between slices.
- Filling the distance between slices with "hard pixels".
- Double zoomed preview.
- Preview with reduced sprite height (camera tilt effect).
- Export preview as a sprite with 360 rotation animation.
This script DOES NOT create a SpriteStack, it is just a preview that affects the convenience of creating such sprites.

You can detach the preview-canvas from the script window.
Current view of the running script: 
![Preview-Image](./docs/version_2024-02-13.png)

Exported sprite from preview-canvas:
![gif-4](./docs/canvas_export.gif)

(Old version gif's)
![gif 1](./docs/rotate.gif) ![gif 2](./docs/slices.gif) ![gif 3](./docs/distance_height.gif)

### SpriteStack Slicer
Creates a new sprite based on a flat sprite image by slicing it along vertical lines.

![gif](./docs/flatslicer.gif)


# LICENSES
The scripts are distributed under the [MIT license](LICENSE.txt).

Sprites are distributed under [CC-BY-NC4.0 license](https://creativecommons.org/licenses/by-nc/4.0/). ![CC-BY-NC image](https://i.creativecommons.org/l/by-nc/4.0/88x31.png)


