# Sprites

What the sprite system is for, and the rules any design for it has to satisfy.

## 1. Use Cases

1. Shows a static image.
2. Animates an image defined on a sheet of one row.
3. Animates an image defined on a sheet of N rows.
4. Plays a sprite by the row it names on the sheet, or by its place in a run taken from one.
5. Concatenates a series of sprites and accesses them with a row cursor, as if it was one image.
6. Maps a sprite's namespace from `int` to any `T`.
7. Sets the core animation properties of `start`, `end`, `loop`, and `fps`/`duration` at multiple levels.
8. Takes the frames of a sheet one at a time, unanimated, the way a tile map uses them.

## 2. Requirements

1. `play()` takes a single, typesafe name to play.
2. The simplest case is the most concise one.
3. An optional feature never makes a parameter required.
4. Names live outside the art. Art goes unnamed, and naming is a layer over it.
5. A positional list never implicitly shifts the cursor. Passing rows over is stated, not implied.
6. `reassemble` stays simple.
7. Frames are cut once, not on every draw.

## 3. Design

Every type answers one question.

| Type              | Answers                                                               |
|-------------------|-----------------------------------------------------------------------|
| `Sprite<T>`       | What entries do I hold, and which one does this key name?             |
| `SpriteEntry<T>`  | What is one entry: its frames, its timing, its key?                   |
| `SpriteRegion`    | Which piece of which asset?                                           |
| `SpriteImage`     | One region, drawn still.                                              |
| `SpriteAnimation` | One region, played.                                                   |
| `SpriteSheet`     | Which piece of an image is that? Hands out sprites, and is not one.   |
| `SpriteGroup`     | Several sprites end to end, under a row cursor.                       |
| `SpriteMap<T>`    | What are these entries called?                                        |
| `SheetRow`        | How does one row of a sheet play?                                     |

Configuration is stated once, where the animation is defined. The sheet holds none of it, and holds nothing derived either - an asset and a cell size, and rows are coordinates it is asked about rather than things it keeps.

```dart
SpriteImage('assets/logo.png');
SpriteAnimation('assets/slime_idle.png', SLIME_SIZE, fps: 16);

final sheet = SpriteSheet('assets/slime.png', SLIME_SIZE);

sheet.image(column: 3);
sheet.animation(row: 1, end: 30, fps: 24);
sheet.animations(fps: 16, rows: [.new(end: 14), .new(end: 30)]);

SpriteGroup([...]);
SpriteMap({'idle': ..., 'jump': ...});
```

`SpriteImage` and `SpriteAnimation` both hold `SpriteRegion`s, and their plain constructors make them under the hood. A region states its derivation - the asset, the cell size, and where in the grid - rather than a finished `Rect`, so it re-resolves itself through the cache and recomputes against a replacement image of another size. That is what lets an animation reload without a reference back to the sheet that cut it.

`SpriteAnimation` asserts the grid is one row where no row is named, since leaving it unstated says the file is the animation. Naming a row is how any row comes out of a grid, and is what `SpriteSheet.animation` does. `sheet.animations` returns a `SpriteGroup`, so the bulk form needs no collection type of its own. Taking one row twice is two calls, so repeats need no mechanism.
