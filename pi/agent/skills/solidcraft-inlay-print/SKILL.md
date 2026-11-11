---
name: solidcraft-inlay-print
description: Prepare multi-color face-down bed inlay 3D prints from SolidCraft designs and slice them with OrcaSlicer for the Creality Ender-3 S1 Pro (Klipper @ 10.100.0.60). Use when the user asks to make recessed features or text/logos printable in another filament color, create flush inlays, or slice multi-color / two-pass G-code for their Ender-3 S1 Pro.
---

# SolidCraft Face-Down Bed Inlay & Multi-Color Slicing

Use this workflow when turning recessed pockets/features in a SolidCraft model into flush multi-color bed inlays and slicing them for the user's **Creality Ender-3 S1 Pro (Klipper / Mainsail at `http://10.100.0.60`)**.

## 1. How Face-Down Bed Inlays Work on a Single-Extruder Printer
Instead of printing face-up and swapping filament for an entire Z-layer (which colors the outer walls too), the model is flipped **180° face-down** onto the build plate:
1. **Inlay Thickness (`0.4 mm` = 2 layers at `0.20 mm`):**
   - Recessed pockets on the front face (e.g., at `Z = 5.0 mm`) are filled from their floor up to `Z_top - 0.4 mm` (e.g., `Z = 4.6 mm`) using `solid.extrude {operation: "join"}` on the pocket bottom faces so **all existing vertical/edge fillets are preserved**.
   - Each pocket floor (now at `Z_top - 0.4 mm`) is extruded `+0.4 mm` (`operation: "new"`) to create flush inlay bodies (`Inlay_*`) occupying `[Z_top - 0.4, Z_top]`.
2. **Two-Pass Printing (Only 1 Filament Swap):**
   - **Pass 1 (`*-pass1-black-inlays.gcode`):** Prints *only* the `0.4 mm` (2-layer) inlay bodies on the bed, lifts to `Z = 30.4 mm`, parks at `(X10, Y200)`, **keeps the heated bed ON at `60°C`** and **leaves steppers locked** (no `M84`).
   - **Filament Swap:** The user peels only the left purge line, swaps from Inlay Filament → Body Filament, and purges clean.
   - **Pass 2 (`*-pass2-white-body.gcode`):** Runs `G28 X Y` (homes X/Y without probing Z in the center where the inlays sit), draws the purge line, lifts to `Z = 0.8 mm`, and prints the main body around and over the inlays using **`0.6 mm` Z-Hop** (`Normal Lift` on `All Surfaces`) and **no skirt/brim**.

## 2. Step-by-Step SolidCraft MCP Procedure
1. **Save a backup first:**
   Call `mcp__solidcraft__save` to `<name>-backup.sc` before modifying geometry.
2. **Find the pocket floor faces:**
   Call `mcp__solidcraft__body_topology` on the main body (`Body1`) and locate the planar floor faces of the recessed features (e.g., `plane_normal` parallel to `[0, 0, 1]` at `Z = Z_floor`).
3. **Raise pocket floors to `Z_top - 0.4 mm` (if deeper than `0.4 mm`):**
   Use `mcp__solidcraft__execute` or `mcp__solidcraft__batch` with `solid.extrude`:
   ```json
   {
     "command": "solid.extrude",
     "params": {
       "faces": [[x1, y1, z_floor], [x2, y2, z_floor]],
       "direction": "positive",
       "distance": "Z_top - 0.4 - Z_floor",
       "operation": "join",
       "targets": ["Body1"],
       "name": "Fill_Pockets_To_0.4mm"
     }
   }
   ```
   *(Joining from the floor faces preserves all existing fillets on the pocket walls, unlike editing the earlier cut feature which can invalidate downstream fillet edge IDs).*
4. **Extrude each inlay body (`0.4 mm` thick, `operation: "new"`):**
   ```json
   {
     "command": "solid.extrude",
     "params": {
       "face": [x1, y1, Z_top - 0.4],
       "face_body": "Body1",
       "direction": "positive",
       "distance": 0.4,
       "operation": "new",
       "body_name": "Inlay_1",
       "name": "Inlay_1"
     }
   }
   ```
5. **Assign contrasting appearances & export individual STLs:**
   - Assign `appearance.assign` (`#f5f5f5` for `Body1`, `#1a1a1a` for `Inlay_*`).
   - Save the modified design (`<name>-inlay.sc`).
   - Export `Body1.stl` and each `Inlay_*.stl` individually via `mcp__solidcraft__export`.

## 3. Slicing with `slice-inlay` CLI
Run `/home/earn/.local/bin/slice-inlay`:
```bash
slice-inlay \
  --body /path/to/Body1.stl \
  --inlays /path/to/Inlay_1.stl /path/to/Inlay_2.stl \
  --out-dir /path/to/output \
  --name my-part
```
Add `--upload` if the user wants the Pass 1 and Pass 2 G-code files uploaded directly to Mainsail (`http://10.100.0.60`).

### What `slice-inlay` Produces
- `<name>-orcaslicer-project.3mf`: Ready-to-open OrcaSlicer project with all bodies rotated 180° face-down, aligned at `(110, 110)`, two filaments assigned, `0.6 mm` Z-Hop, no skirt/brim/tower, and Klipper G-code flavor.
- `<name>-pass1-black-inlays.gcode`: Pass 1 G-code (2 layers, keeps bed at `60°C` and motors locked at finish).
- `<name>-pass2-white-body.gcode`: Pass 2 G-code (`G28 X Y` only, `0.6 mm` Z-Hop over inlays).
- `<name>-single-job-klipper.gcode`: Single-file version using Klipper `PAUSE X=10 Y=200 Z_MIN=30`.
