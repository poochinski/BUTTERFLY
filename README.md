# Meadowlight

A cozy, painterly butterfly-catching game made in **Godot 4.7**.

Wander a sunset meadow with a butterfly net, sneak up on butterflies, and
fill your Field Journal with 15 North American species, from everyday
Monarchs to the very rare Diana Fritillary.

## How to play it (Windows)

1. Download this repository (green **Code** button → **Download ZIP**, then
   unzip it), or clone it with Git.
2. Open **Godot 4.7** → **Import** → choose the `project.godot` file in this
   folder → **Import & Edit**.
3. Press **F5** (or the ▶ Play button, top right).

The first launch takes a little longer while Godot compiles its shaders.

## Controls

| Action | Keyboard & mouse | Gamepad | Touch |
| --- | --- | --- | --- |
| Move | WASD / arrows | Left stick | Left side of screen (joystick) |
| Look | Mouse | Right stick | Drag on the right side |
| Swing net | Left click / E | RT / X / RB | **NET** button |
| Sneak (toggle) | C / Ctrl | B / L3 | **SNEAK** button |
| Run | Shift (hold) | LB / LT | — |
| Jump | Space | A | **JUMP** button |
| Field Journal | Tab / J | Y / Back | **BOOK** button |
| Zoom | Mouse wheel | D-pad up/down | — |
| Pause & settings | Esc / P | Start | **II** button |

Click the game window to capture the mouse; Esc releases it.

## How catching works

- Every butterfly notices you from a certain distance. **Rarer species
  notice you from further away.**
- The noise meter (bottom-left) shows how noticeable you are. **Sneaking**
  makes you about four times harder to notice, standing still helps, and
  running or jumping makes you much easier to spot.
- Butterflies resting on flowers are calmer than flying ones, so sneak up
  on a feeding butterfly and then swing.
- Every catch goes in your journal, and then the butterfly is gently
  released.
- Some species only fly at certain times of day, and each prefers a habitat
  (flower fields, open meadow, or woodland edges). The journal gives hints
  for the ones you haven't found yet.

Progress saves automatically.

## The look

Apart from the app icon, the game uses no image files. The terrain, grass, flowers, trees,
sky, character and every butterfly wing pattern are generated in code and
shaders. A watercolour filter (Kuwahara brush strokes, paper grain and edge
pooling) is applied on top. You can turn it off, along with the light rays,
in the pause menu.

## Project layout

```
scenes/main.tscn            entry scene (everything is built in code)
scripts/main.gd             assembles the game
scripts/core/               Game autoload (time, journal, save), input map
scripts/world/              terrain & masks, scenery scatter, sky/day cycle,
                            grass field, pollen & fireflies
scripts/player/             player movement, procedural character, camera
scripts/creatures/          species data, butterfly behaviour, spawner
scripts/ui/                 HUD, journal, pause menu, touch controls, filter
shaders/                    terrain, grass, flowers, shrubs, trees, water,
                            sky, butterfly wings, watercolour filter
```

To add a species, add an entry to `scripts/creatures/species.gd`. Each one
is a set of wing-painting parameters plus behaviour (rarity, shyness,
flight style, active hours and habitat).

## Roadmap

- [x] **Milestone 1:** painterly 3D meadow at sunset, character and camera,
      net swing, 15 butterfly species, journal, saving, day/night cycle,
      keyboard/gamepad/touch controls
- [ ] **Milestone 2:** moths, dragonflies, bees, beetles and fireflies with
      their own movement styles
- [ ] **Milestone 3:** more world detail (pond life, reeds, weather, night
      ambience)
- [ ] **Milestone 4:** fuller journal (sizes, records, rewards, net upgrades)
- [ ] **Milestone 5:** soft lullaby music and sound effects
- [ ] **Milestone 6:** title screen, polish, Windows export
