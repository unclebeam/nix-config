---
name: gridfinity
description: Gridfinity calculations — baseplate layout for a drawer or tray. Use for "will gridfinity fit", drawer/tray sizing in mm, or working out which baseplates to print.
argument-hint: baseplate <width>x<depth>
arguments: [calc, size]
allowed-tools: Read
---

# Gridfinity

Router for Gridfinity calculations. Requested calculation: `$calc`. Arguments: `$ARGUMENTS`.

## Constants

These are fixed — never re-derive or estimate them.

- **Grid pitch: 42 mm** per unit, both axes. An N×M baseplate measures exactly `42N × 42M` mm.
  Baseplates butt edge to edge; there is no gap between adjacent plates.
- **Max printable plate: 6 units (252 mm)** per axis — Bambu Lab X1 Carbon. Override only if the
  invocation explicitly gives a different printer or limit.
- **Input is millimetres.** No imperial parsing. If a value is given in inches, say that mm is required.

## Routing

| `$calc` | Read and follow |
| --- | --- |
| `baseplate`, or empty when the rest of the arguments look like dimensions | `${CLAUDE_SKILL_DIR}/references/baseplate.md` |

Read the routed file and follow it exactly. Do not answer from this router alone — the arithmetic lives
in the reference file, not here.

If `$calc` is missing with no dimensions to fall back on, or names a calculation not in the table above:
list the available calculations, say what was asked for, and stop. Never invent a calculation.

## Adding a calculation

Add one reference file under `references/`, add one row to the routing table. The algorithm stays out of
this file: a skill body remains in context for the whole session, while a reference file is read only when
routed to. Candidates: `bin` (bin footprints and 7 mm height units), `spacer` (filler strips for leftover gaps).
