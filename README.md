# SF Symbol Builder

Some time ago I needed to convert several vector icons to custom SF Symbols, to use them in Control Center widgets. This led to writing
some code in a playground, that does three things:
 - reads SVG icons one by one,
 - inserts these icons, stripping all style, into a SF Symbols file template,
 - saves the result template to the disk, so that it can be imported into SF Symbols.app and exported from there as a proper SF Symbol.

In several months I needed this playground again. So I just packed it into a simple app, that allows me to open several SVG files, and
save them to a directory of my choice.

So this is the app.

## How to prepare SVG for the conversion

 - SVG file must have only "fills", and not "strokes". In terms of Figma, all strokes must be outlined.
 - SVG must not have any effects. Just simple filled paths. There can be several paths.
 - SVG must be in a square.

Here is an example of SVG, exported from Figma, and ready for conversion:

```xml
<svg width="256" height="256" viewBox="0 0 256 256"
    fill="none" xmlns="http://www.w3.org/2000/svg">
<path d="M79.5605 50C85.0834 50 89.5605 54.4772 89.5605 60V185H114.04V60C114.04 
    54.4772 118.517 50 124.04 50H168.52C174.042 50 178.52 54.4772 178.52 60V185H213C218.523 
    185 223 189.477 223 195C223 200.523 218.523 205 213 205H168.52C162.997 205 158.52 200.523
    158.52 195V70H134.04V195C134.04 200.523 129.563 205 124.04 205H79.5605C74.0378 205
    69.5605 200.523 69.5605 195V70H42C36.4772 70 32 65.5228 32 60C32 54.4772 36.4772 50
    42 50H79.5605Z" fill="black"/>
</svg>
```

## How to convert

 1. Open the App
 2. Open SVGs there. They will be previewed
 3. Press "Build SF Symbols" button. It will ask for a directory where to save them
 4. Import resulting svg files into SF Symbols.app. You can do that by dropping svg files into "Custom Symbols" in the Library there.
 5. Edit them as you want
 6. Export them and add them to Xcode Assets directory.
 7. Use them in your SwiftUI code: `Image("<asset name>")`

## Limitations

The app does not create SF Symbol with different weights, only different sizes will be available.
