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
| Killstreak: UAV (3 kills) | 5 | D-pad up |
| Killstreak: Attack helicopter (5 kills) | 6 | D-pad right |
| Killstreak: Attack dogs (7 kills) | 7 | D-pad left |
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
- **Weapons:**
  - M4A1, AK-47, PDW-9 SMG, Longbow .50 sniper (with scope), Pump-12
    shotgun and M9 pistol.
  - New: M249 SAW light machine gun, Mk 14 EBR marksman rifle and
    .44 Magnum revolver.
  - Four default classes plus five custom slots (see below).
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

## Progression, Create-a-Class and kill streaks

- **Levels 1–30.** Rank titles run from Private I to Colonel III. Every
  level-up gets a banner listing any guns it unlocks.
- **Guns unlock by level:**
  - level 1: M4A1, PDW-9 and M9
  - level 2: Pump-12
  - level 4: AK-47
  - level 6: .44 Magnum
  - level 8: Longbow .50
  - level 10: M249 SAW
  - level 13: Mk 14 EBR
- **Attachments unlock by kills with that gun.** Choose from red dot,
  holographic sight, ACOG (4x), suppressor, foregrip and extended mags.
  - Without an optic, rifles use flip-up iron sights.
  - A suppressor keeps you off the enemy radar when firing and quietens
    your shots.
  - A foregrip cuts recoil.
  - Extended mags hold more rounds.
- **Create-a-Class** (main menu) has five custom slots. Each takes a
  primary and a secondary with one attachment each. The four default
  classes are always available too.
- **Kill streaks:**
  - **3, UAV:** the paper plane shows enemies on the radar.
  - **5, Attack helicopter:** a papercraft gunship circles the map for 40
    seconds and shoots any enemy it can see.
  - **7, Attack dogs:** ten felt shepherds, three on the ground at a time.
    Each fallen dog is replaced until all ten are gone or 40 seconds
    pass. Dogs can be shot, and killing one is worth XP.
  - Bots call their streaks in too.
- **Damage direction:** when you're hit, red bleeds in from the side the
  shots came from, and a red arc around the crosshair points at the
  shooter. Both keep tracking as you turn.

## Map: Lodgepole

An original hillside forest retreat, and the first map with real hills.
Switch maps with the **MAP** button in the main menu.
- **West:** Cardstock spawns on the helipad on the high ground, beside
  the woodshed and its log stacks.
- **Middle:** a two-storey timber-and-glass lodge on its knoll.
  - Open-plan kitchen and living room with a stone fireplace.
  - Stairs up to an office and a bedroom, with a balcony over the deck.
  - Next to it, a garage workshop; below it, a greenhouse.
- **North:** a creek gully with two footbridges, crumpled-paper boulders
  and a hunting stand.
- **South:** a pond with a dock and an open meadow.
- **East:** Militia spawns at the gravel turnaround by the gate.

The landscape is layered felt over rolling hills. Pines are stacked felt
cones on cardboard-tube trunks, and the distant mountains are felt with
snowcaps. See `docs/lodgepole.jpg`.

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

Soldiers are felt action figures in real kit (see below).

You can turn the expensive effects off under **Settings → High quality
graphics**. Characters and guns get ink outlines. Defeated soldiers fold flat
like paper and burst into confetti, and explosions are cotton-ball puffs. The
skyline is painted cardboard flats of concrete and glass towers in front of
knitted hills. Teased-cotton clouds hang on fishing line.

**Arms and gear.** The guns are prop-maker replicas: laminated
card with real finishes (matte black, flat dark earth, OD green, wood
grain), rubbed paint and dry-brushed edges. They have foil barrels, brads
for pins, cellophane lenses and webbing slings.

The soldiers are felt action figures in real kit:
- Cardstock: plate carriers with MOLLE, mag pouches, radios, and helmets
  with NVG mounts.
- Militia: chest rigs, beanies and shemaghs.

Uniforms are cut-felt camo, and every soldier's face and skin tone vary.

Reloads are fully hand-animated: the old mag drops to the floor, a new one
is fetched and slapped home, and the gun is charged on empty. Slides,
bolts and pumps all cycle, and brass bounces across the floor. See
`docs/ART_DIRECTION.md` and `docs/arms_pass_compare.jpg`.

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
- [x] **M2 (part):** attack helicopter and dog killstreaks, attachments,
      Create-a-Class, 30 levels
- [ ] **M2 (rest):** perks, care package, airstrike
- [ ] **M3:** more maps (Lodgepole done) and Domination / FFA modes
- [ ] **M4:** music, more sound polish, killcam replay, flash and stun
      grenades
- [ ] **M5:** graphics settings, a Windows export, performance passes
