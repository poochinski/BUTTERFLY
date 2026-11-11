# PAPERCUT: Corrugated Warfare

A papercraft military shooter made in **Godot 4.7**. Classic 2009-era
multiplayer gunplay and movement, set in a world built from cardboard,
paper, felt and yarn.

> An original game. It borrows the *feel* of classic multiplayer shooters,
> including movement, aiming, loadouts, killstreaks and three-lane maps.
> It uses no names, characters, maps, art or audio from any existing game.

## Play it (Windows)

1. Download this branch (green **Code** button → **Download ZIP**, then
   unzip it).
2. Open **Godot 4.7** → **Import** → choose `project.godot` → **Import & Edit**.
3. Press **F5**.

The first launch compiles shaders and can take a few seconds.

## Mode: Team Deathmatch, 6 v 6 against bots

**Task Force Cardstock** (navy felt and olive helmets, your team) against
the **Corrugated Militia** (rust felt and knit beanies). The first team to 75 kills wins,
or the higher score after 10 minutes. You choose the bots' skill
(Recruit, Regular, Hardened, Veteran) and your loadout in the menu.

## Controls

| Action | Mouse & keyboard | Gamepad |
| --- | --- | --- |
| Move / look | WASD / mouse | Left stick / right stick |
| Fire / aim down sights | Left / right mouse | RT / LT |
| Sprint | Shift (hold) | L3 |
| Jump / mantle | Space | A |
| Crouch (hold for prone) | C | B |
| Prone | Ctrl or Z | hold B |
| Reload | R | X |
| Switch weapon | 1 / 2 / mouse wheel | Y |
| Pick up weapon (hold) | F | X (hold) |
| Knife | V or E | R3 |
| Frag grenade (hold to cook) | G | RB |
| Killstreak (UAV) | 5 | D-pad up |
| Scoreboard | Tab | Back |
| Pause | Esc | Start |

The gamepad has aim slowdown near enemies and a small snap toward the
nearest enemy when you aim down sights.

## What's in milestone 1

- **Movement:** walk, limited-stamina sprint, crouch, prone, jump, mantle
  over low cover, fall damage, and a sprint-out delay before you can fire.
- **Gunplay:** hitscan with damage falloff, headshot multipliers, hip-fire
  spread that grows when moving or jumping, aim down sights, recoil you pull
  against, reloads (empty reloads are slower), weapon swaps, knife lunge,
  cookable frags, and health regeneration.
- **Weapons:** M4A1, AK-47, PDW-9 SMG, Longbow .50 sniper (with scope),
  Pump-12 shotgun and M9 pistol, in 4 classes: Assault, Raider, Rusher
  and Marksman.
- **Bots:** they see with a field of view and line of sight, hear gunfire,
  path across the navmesh, strafe and crouch in fights, aim with human-like
  reaction time and error, fire in bursts, reload, knife, and throw frags.
- **Match:** spawns away from enemies, kill feed, assists, XP and ranks
  (saved), UAV killstreak at 3 kills (a paper airplane), killcam-lite, a
  scoreboard, and an end-of-match screen.
- **HUD:** a rotating minimap made from a real top-down render of the map,
  with red dots when enemies fire and everyone visible during a UAV. Also:
  crosshair spread, hitmarkers, damage arrows, a red paper vignette when
  hurt, and XP pop-ups.
- **Map: Gateway**, an original papercraft airport with three lanes:
  - The **baggage hall** (north): conveyors and roll-up doors.
  - The **terminal → jet bridge → walk-through airliner → rear stair truck**
    (middle).
  - The **open apron** with a business jet (south).

## Environment: felt and hand-made construction

The ground is now felt, laid like a crafter's diorama base: patchwork
tarmac slabs, layered lawns with fringe-cut grass, mud and puddles, felt
gravel, stitched road markings. Buildings are taped, tied with yarn,
pinned with brads and hot-glued. See `docs/ENVIRONMENT_PASS.md`.

## New in this update

- **Weapon pickups:** fallen soldiers drop their gun. Walk over a gun you
  already carry to scavenge its ammo, or hold **F** / **X** to swap the one
  in your hands for it.
- **Killstreak banners and medals:** a felt ribbon banner drops in at 3, 5,
  7, 10, 15 and 20 kills. Medal splashes include First Blood, Headshot,
  Double / Triple / Fury Kill, Payback, Longshot, Comeback, Paper Cut!
  (knife) and Confetti Bomb (frag). The HUD tracks your streak toward the
  UAV.
- **Optics:**
  - The M4A1 carries a tube red dot with a lit dot.
  - The PDW-9 carries a holographic sight with a ring-and-dot reticle.
  - The AK-47, shotgun and pistol use iron sights, and the Longbow keeps
    its scope.
- **Model-quality guns:** every gun is cut from real side-profile
  silhouettes, like laminated cardboard, with rails, brass rivets, tape
  wraps, foil barrels and curved mags. Gloved hands now have fingers.
- **Level revamp:**
  - window mullions, ceiling beams, column trims and parapets
  - rooftop units and giant cardboard GATEWAY lettering
  - gate seating, flight-info screens, queue ropes, vending machines,
    potted trees, rugs and an awning
  - stand markings and ground crew gear: power cart, belt loader, tug
    and chocks
  - floodlight masts and chain-link fencing
  - extra airliner details, a background hangar, parked planes and
    runway lights

## Art direction

**Every map is a real place, rebuilt as faithfully as possible by skilled
hobbyists using only what they could buy at an art, fabric and craft store.**
The realism comes from the colours, proportions and logic of the real place.
The charm comes from the materials: felt, card, construction paper, yarn,
tape, foil and cellophane. The full brief, with the palette, materials guide
and do/don't list, is in `docs/ART_DIRECTION.md`.
`docs/realism_pass_compare.jpg` shows before and after the realism pass.

Everything is generated in code and shaders; there are no textures or
models. One "craft" shader renders every supply in the game:
- corrugated cardboard, with worn kraft edges and visible flutes on cut edges
- construction paper
- fuzzy felt
- knitted yarn, with real stitch patterns
- masking tape, plastic buttons and caps, and foil

**The palette is real-world.** Gateway is precast concrete, grey steel
cladding, cellophane glass and charcoal felt tarmac. Saturated colour
appears only where it would at a real airport:
- safety yellow and orange
- signal red
- navy and teal airline livery
- the occasional cargo container

The lighting is neutral afternoon daylight with a natural sky, soft haze, an
AgX filmic tonemap and a gentle photographic grade.

Soldiers are plush felt dolls in quilted cardboard vests:
- Cardstock wears navy.
- Militia wears rust.

You can turn the expensive effects off under **Settings → High quality
graphics**. Characters and guns get ink outlines. Defeated soldiers fold flat
like paper and burst into confetti, and explosions are cotton-ball puffs. The
skyline is painted cardboard flats of concrete and glass towers in front of
knitted hills. Teased-cotton clouds hang on fishing line.

Sounds are synthesised at startup, so there are no audio files.

Fonts: Luckiest Guy (Apache 2.0) and Fredoka (SIL OFL). The licences are
in `assets/fonts/`.

## Project layout

```
scripts/core/      Game (settings, profile, ranks), input map, Sfx synth
scripts/art/       Craft material library and mesh kit
scripts/map/       map builder, props, the Gateway map
scripts/weapons/   weapon stats, gun builder, hitscan/explosions, FX
scripts/actors/    Soldier base, Player, Bot, papercraft doll, viewmodel
scripts/match/     Team Deathmatch rules, spawns, scoring, UAV
scripts/ui/        HUD, minimap, menus
shaders/           craft materials, ink outlines, cellophane, sky
```

## Roadmap

- [x] **M1:** map, movement, gunplay, 6 weapons, bots, TDM, UAV, HUD, menu
- [ ] **M2:** more killstreaks (care package, paper airstrike, chopper),
      perks, attachments, create-a-class
- [ ] **M3:** a second map (trailer-park style) and Domination / FFA modes
- [ ] **M4:** music, more sound polish, killcam replay, flash and stun
      grenades
- [ ] **M5:** graphics settings, a Windows export, performance passes
