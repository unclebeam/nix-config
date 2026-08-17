# Baseplate layout

How many Gridfinity units fit a space, and how to split that grid into printable plates.

## 1. Parse the input

Read `W x D` in millimetres from the arguments. Accept `355x240`, `355 x 240`, `355 x 240 mm`,
`355 by 240`. Decimals are fine.

- The numbers are the **inner / usable opening** — the space the plates drop into. Say so in the output,
  because measuring the outside of a drawer is the usual mistake.
- A third number is a height. Out of scope here: note it's ignored and carry on.
- Not parseable: ask for `WxD` in mm. Do not guess dimensions.

## 2. Fit the grid

    units_x = floor(W / 42)
    units_y = floor(D / 42)
    grid_x  = 42 × units_x        gap_x = W − grid_x
    grid_y  = 42 × units_y        gap_y = D − grid_y

If either axis yields 0 units, the space is too small for a baseplate — say that, give the shortfall
(`42 − dimension` mm), and stop. Do not print a 0-unit table.

## 3. Split into printable plates

**Fewest plates wins.** Never add a chunk to make sizes match — plate count is the priority, identical
sizes are only the tie-break within that count.

Why plate count is the thing to minimise, and the only thing:

- **Material and print time are already fixed** by the grid. Every valid split lays down the same
  `units_x × units_y` of baseplate. Splitting differently moves the seams; it does not print less.
- **What varies is job count.** Each extra plate adds a set of outer walls and — because these plates
  run close to the bed limit — usually a whole extra print job with its own heat-up and first layer.
- **Identical plates are worth nothing here.** Plates get placed once and stay put; it's the bins that
  move. Interchangeability doesn't pay back an extra print.

So the answer is always the minimum `ceil(units/6)` chunks per axis. Never present a
higher-plate-count layout as an option, even a tidier-looking one.

For each axis independently, with `n` units and `MAX = 6`:

    k    = ceil(n / MAX)      # number of chunks — the fewest that respect the limit, always
    base = floor(n / k)
    r    = n mod k            # r chunks of (base + 1), and (k − r) chunks of base

Balanced, not greedy: 8 → `4 + 4` (never `6 + 2`), 11 → `6 + 5`, 5 → `5`, 13 → `5 + 4 + 4`.
When `k` divides `n` the balanced split is already uniform (8 → `4 + 4`, 12 → `6 + 6`) — that is the
only way identical sizes are worth having. `9 → 5 + 4`, not `3 + 3 + 3`: three plates to print beats
two, and equal sizes don't buy back the extra plate.

Chunk order along an axis doesn't matter — the plates are interchangeable.

The plate list has `(distinct x-sizes) × (distinct y-sizes)` entries — up to 4 when neither axis
divides evenly. That is expected; do not "fix" it by adding chunks.

**Odd axes can never repeat.** A `k`-chunk axis only yields equal chunks when `k` divides `n`, so an
odd `n` split in two (7, 9, 11 …) always gives two different sizes. If both axes are odd, all four
plates differ and no rearrangement changes that — the grid area is odd, and matching pairs would need
an even area. Say this in one line if asked why nothing repeats; don't volunteer it otherwise.

Plates are the cross product of the x-chunks and the y-chunks. Group identical sizes and count them.

**Checksum before printing anything**: the plate areas in units must sum to `units_x × units_y`. Show it.
If it doesn't balance, say the split is wrong and stop — don't emit a table you can't verify.

## 4. Output

The print list first, then the gaps. Nothing else above them. Worked example for `355x240`:

    Drawer 355 × 240 mm (inner opening) — grid 8 × 5 u

    Print these
    1. 4u x 5u = 2 plates   (168 × 210 mm)

    Gap at the width  = 19 mm.
    Gap at the depth  = 30 mm.

    Checksum: 2 × 20 u = 40 u = 8 × 5 ✓

    Push the grid into one corner: that leaves a 19 × 210 mm channel down one side
    and a 336 × 30 mm channel across one end — two straight spacer strips, or two
    troughs deep enough to be useful.

Rules for the list:

- One numbered line per **distinct plate size**, largest area first. Never one line per plate.
- Format is exactly `N. <x>u x <y>u = <count> plates` — `1 plate` when the count is one.
- The mm size is a trailing parenthetical, for checking the size against the print bed.
- The two gap lines always both appear, even when a gap is 0 mm (`Gap at the width = 0 mm.`).
- The checksum stays, but as a single line under the gaps — it is verification, not the answer.
- Gap advice from §5 goes below all of that, as prose.
- The list is allowed to be four lines of `= 1 plate`. Don't apologise for it and don't offer a
  higher-plate-count alternative — §3 already settled that trade.
- **Three or more distinct sizes** — add one line telling them to mark the size on the underside of
  each plate as it comes off the bed. Similar grey rectangles that each fit exactly one corner are
  hard to sort out later.

### Build-plate packing

Plate count is the floor on print jobs; packing two plates into one job is the only way below it.
Bed is **256 × 256 mm** on the X1C, so treat **250 mm** as usable and leave 5 mm between parts:

    two plates share a job if  a + b + 5 ≤ 250  on one axis
                               and both fit 250 on the other

Check every pair. If any pair packs, add one line under the list — `Plates 3 and 4 share one build
plate side by side (84 + 126 + 5 = 215 mm)` — and give the resulting job count. If nothing packs,
say nothing; the plate count already is the job count.

Do not fudge the margin to make a pair fit. Two 126 mm plates need `126 + 126 + 5 = 257 mm` and do
**not** pack, even though 252 mm of parts nominally sits inside a 256 mm bed — that leaves 2 mm of
clearance per side. A failed print costs more than the job it saved.

## 5. Gap advice

Always cover both axes:

- **Under ~2 mm** — ignore it, that's print tolerance.
- **2–5 mm** — mention it, no action needed.
- **Over ~5 mm** — bins will slide. **Push the grid into one corner** and keep each gap whole. Give the
  two resulting channels by size (`gap_x × grid_y` down one side, `grid_x × gap_y` across one end) —
  each is either one straight spacer strip to print, or a usable trough for rulers, pens and files.
  Recommend centring (`gap / 2` per side) only when both gaps are under ~12 mm, where the halves are
  too narrow to hold anything anyway. Splitting a 30 mm gap into two 15 mm slivers wastes it twice.
- **≥ 42 mm on either axis** — impossible, another unit would have fit. The floor was computed wrong: say so
  and stop rather than printing the table.

## Not this calculation

Bin footprints (41.5 mm — 0.25 mm clearance per side) and height units (7 mm) belong to a future `bin`
calculation. Mention them only if asked.
