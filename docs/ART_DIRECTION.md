# PAPERCUT: Art Direction

## The idea in one sentence

**Every map is a real place, rebuilt as faithfully as possible by skilled
hobbyists using only what they could buy at an art store, a fabric store
and a craft store.**

It is not a cartoon world made of paper. It is a *realistic* world: an
airport, a trailer park, a harbour, made by people who care about
getting it right, the way model-railway builders, wargaming terrain
makers and museum diorama artists do. The realism comes from the
**colours, proportions and logic** of the real place. The charm comes
from the **materials**: you can always see it is felt, card, paper, yarn
and tape.

## Pillars

1. **Real place first.** Before building anything, ask: what does this
   look like in real life? A terminal is precast concrete, glass and
   steel. A tarmac is charcoal asphalt with faded yellow paint. A cargo
   can is dull aluminium. Build *that*, out of craft supplies.
2. **Honest materials.** Felt for ground, grass, fabric and upholstery.
   Corrugated card and mount board for structures. Construction paper
   and cardstock for paint, signage and skins. Yarn and embroidery
   thread for cables, ropes and straps. Masking tape and hot glue for
   joins. Foil, bottle caps and buttons for metal and hardware.
   Cellophane for glass and water. Nothing is plastic-toy smooth.
3. **A muted, real-world palette.** Colour comes from where it comes
   from in reality: safety markings, signage, airline liveries, a few
   painted doors. Everything else is concrete, asphalt, steel, glass,
   timber, grass and soil, weathered and slightly dusty.
4. **Visible craft.** Seams, stitches, cut edges, tape strips, brads,
   glue blobs and slightly crooked placement stay. They are what makes it
   hand-made. They should be quiet up close, never loud from afar.
5. **Natural light.** Neutral daylight, soft real shadows, a natural sky,
   gentle haze. The scene should photograph like a well-lit tabletop
   diorama, not like a saturated platformer.

## Palette

Values are sRGB 0–1 (`Craft` constants in `scripts/art/craft.gd`).

| Role | Name | Value | Used for |
| --- | --- | --- | --- |
| Concrete (light) | `CONCRETE` | 0.72, 0.70, 0.66 | facades, sidewalks, pillars |
| Concrete (dark) | `CONCRETE_DARK` | 0.50, 0.49, 0.47 | bands, plinths, curbs |
| Asphalt | `ASPHALT` | 0.26, 0.27, 0.29 | tarmac, roads |
| Steel / cladding | `SLATE` | 0.42, 0.45, 0.50 | hangars, baggage hall, equipment |
| Aluminium | `ALUMINIUM` | 0.70, 0.72, 0.74 | cargo cans, rails, trim |
| Off-white | `WHITE`, `CREAM` | 0.88, 0.87, 0.83 / 0.85, 0.82, 0.74 | aircraft skin, signs, ceilings |
| Kraft / timber | `KRAFT`, `KRAFT_DARK` | 0.66, 0.50, 0.34 / 0.48, 0.36, 0.25 | boxes, pallets, counters |
| Safety yellow | `YELLOW` | 0.86, 0.68, 0.16 | ground markings, signs, vehicles |
| Safety orange | `ORANGE` | 0.82, 0.40, 0.14 | cones, barriers, hi-vis |
| Signal red | `RED` | 0.62, 0.17, 0.14 | fire equipment, stop bars |
| Livery navy | `BLUE` | 0.17, 0.24, 0.38 | airline livery, uniforms |
| Livery teal | `TEAL` | 0.22, 0.42, 0.46 | airline accent, terminal accent |
| Muted rose | `PINK` | 0.58, 0.38, 0.38 | rare accents only |
| Slate blue | `PURPLE` | 0.36, 0.38, 0.46 | (legacy) mapped to cladding |
| Grass | `GRASS` | 0.30, 0.40, 0.21 | lawns, verges, foliage |
| Soil / mud | felt | 0.33, 0.25, 0.18 | mud, planters |

Rules:
- Saturated colour covers **at most ~10% of any view**, mostly safety
  markings, signage and liveries.
- Nothing pure white, nothing pure black. Everything is slightly
  weathered.
- Team colours are real uniforms: Cardstock wears navy and olive;
  Militia wears rust and khaki.

## Materials guide

| Real thing | Craft equivalent |
| --- | --- |
| Asphalt, concrete slabs | charcoal and grey felt, cut and butted |
| Grass verges | layered green felt with fringe-cut tufts |
| Mud, puddles | brown felt, gloss medium, cellophane |
| Gravel | felt pebbles, pom-poms |
| Building walls | painted corrugated card panels on a frame |
| Glass | cellophane in card mullions |
| Steel cladding | ribbed card painted grey |
| Roofs | dark roofing-felt sheet |
| Metal hardware | foil, brads, bottle caps, buttons |
| Cables, ropes, straps | yarn and embroidery thread |
| Joins and repairs | masking tape, hot glue |
| Upholstery, carpet | felt, with stitching |
| Signs | printed construction paper and cardstock |
| Lights | paper over glowing beads |

## Do / Don't

**Do:**
- concrete, steel, glass and tarmac first
- real signage conventions
- weathering
- tidy craft joins

**Don't:**
- candy palettes or party decorations (no bunting or fairy lights in
  working areas)
- felt suns
- pastel buildings
- neon greens
- random rainbow colours
- toy-like glossy plastic

## Realism pass checklist (Gateway)

- [x] R1. Art direction written (this document)
- [x] R2. `Craft` palette remapped to real-world tones; added `CONCRETE`,
  `CONCRETE_DARK`, `ALUMINIUM` and `OLIVE`
- [x] R3. Lighting and grade:
  - neutral sun and sky fill
  - natural sky
  - AgX tonemap
  - saturation 1.32 → 1.06
  - subtle grade
  - more aerial haze
- [x] R4. Buildings and interiors:
  - precast concrete terminal and grey roofing felt
  - steel-clad baggage hall
  - concrete pillars, terrazzo floor and grey stairs
  - dark gate seating, muted carpets, real shop fascias
  - dark wayfinding signs and white GATEWAY letters
  - bunting and fairy lights removed
- [x] R5. Vehicles and aircraft:
  - white airliner with navy/teal livery
  - aluminium cargo cans, plus faded shipping containers
  - yellow GSE
  - burgundy business jet
- [x] R6. Ground, plants and backdrop:
  - muted felt grass and wildflowers, realistic trees
  - concrete and glass skyline
  - concrete control tower
  - muted hills
  - cotton clouds on fishing line
  - felt sun removed
- [x] R7. Clutter and people:
  - paper scraps instead of confetti, dropped boarding passes
  - neutral luggage, real notices and adverts
  - work-site yarn and tape colours
  - navy/rust team uniforms
- [x] R8. Verification:
  - before/after comparison (`realism_pass_compare.jpg`)
  - full bot match with no errors
