# Problem 2 — Optimization Report Draft

Baseline: `t0 = 3930 µs`, `s0 = 4280 Kbits`  
Code: `hw/cnn_accel_opt/`

---

## b. Optimization methods

### Mapping from lecture suggestions → this design

| Lecture idea | What we implemented | Key files |
|---|---|---|
| Reorder input + fewer DMA transactions | Packed **4 pixels / 32-bit word** with `butterfly_32bit_reorder.hex`; `num_trans = WIDTH/4`; line stride `+= WIDTH` bytes | `cnn_accel.v`, `top_system.v`, `top_system_tb.v`, `img/butterfly_32bit_reorder.hex` |
| Pipeline DMA ↔ conv to shrink input buffer | **Not** shrinking `in_img` (still full frame). Instead applied the *same idea to feature maps*: L2/L3 use a **3-line sliding window** while keeping one full fmap bank | `cnn_accel.v` (`sw_linebuf`, `lb_next`) |
| Fully utilize kernels on Layer 3 | Attempted 4px×4OC multipixel (`To=16` for `Cout=4`); **disabled** after last-row corner mismatch. L3 still uses all 16 kernels as in baseline (4 OC active) | `cnn_fsm.v`, `cnn_accel.v` |
| Layer fusion | **Partial**: removed 2nd fmap bank; L2 writes one bank; L3 reads via 3-line halo buffer (no full L2×L3 double buffer) | `cnn_accel.v` (single `u_fmap_buff`) |

### Additional (time / buffer)

- **HSYNC_DELAY = 2** (was 160): next halo line prefetched during DATA on the free fmap read port, so blanking need not be 128+ cycles.
- **N_CELL = 304** (was 432): weight SPRAM sized to real hex (`16+144+144` words).

### Modified-code summary (for the report)

1. **DMA (`cnn_accel.v`)**  
   - `PIX_PER_WORD=4`; on `data_vld_o_ld` write 4 bytes into `in_img`.  
   - `num_trans_ld = q_width/4`; address `+= q_width` per line.

2. **TB / system**  
   - `INIT_FILE = img/butterfly_32bit_reorder.hex`, `N_WORD = WIDTH*HEIGHT/4`.  
   - Per-layer delays: L1 `START_UP=160`, L2/L3 `START_UP=420`, `HSYNC=2`.

3. **Single fmap + 3-line buffer (`cnn_accel.v`)**  
   - Deleted second DPRAM.  
   - Window layout for output row `r`: `[r-1, r, r+1]`; row0 starts as `[0, fmap0, fmap1]`.  
   - Prefetch line `r+2` into `lb_next` during DATA; install on HSYNC.

4. **L3 schedule**  
   - Column stride = 1 (multipixel off for functional match).  
   - BMP: 1 pixel/valid on channels 0–3.

---

## c. Evaluation

### Functional check

```text
cd hw/cnn_accel_opt
# after Vivado sim of top_system_tb:
# MATLAB:
check_hardware_results.m
```

Expect: `Results of the channel 01..04 are same!`

### Buffer size **s** (declared on-chip)

| Buffer | Formula | Kbits |
|---|---|---|
| `in_img` | 128×128×8 | 128 |
| fmap (1 bank) | 128×128×16×8 | 2048 |
| `sw_linebuf` | 3×128×16×8 | 48 |
| `lb_next` | 128×16×8 | 16 |
| weights | 304×128 | 38.912 |
| bias+scale | 2×3×16×16 | 1.536 |
| **Total s** | | **≈ 2280.4** |

Baseline `s0 = 4280` → `s0/s ≈ 1.876`

### Execution time **t**

Fill from TB after sim:

```text
OPT DONE: t = <YOUR_NUMBER> us
```

Analytical estimate (100 MHz, multipixel off): **t ≈ 3200–3300 µs**  
(L1~17k + L2~148k + L3~148k cycles + DMA/config).

### Overall metric

\[
S_{\text{overall}} = \frac{t_0}{t} \times \frac{s_0}{s}
= \frac{3930}{t} \times \frac{4280}{2280.4}
\]

Example if `t = 3250 µs`:  
`S_overall ≈ 1.209 × 1.876 ≈ 2.27`

*(Replace with your measured `t`.)*

---

## 2. Optimality analysis (parameter choices)

### Why HSYNC = 2
Baseline HSYNC≈160 was mostly idle. A 3×3 needs the next bottom line before the next output row. We **prefetch that line during the current row’s DATA** (fmap read port free while compute uses `sw_linebuf`), so HSYNC only needs **≥1 cycle** for the register shift. `HSYNC=2` leaves one margin cycle. This cuts ~158 cycles × 128 lines × 3 layers of blanking.

### Why 3-line window (n = 3), not full 2nd fmap
For 3×3, output row `r` needs input rows `r−1, r, r+1` → **n = 3** is necessary and sufficient. A second full fmap is 2048 Kbits; 3 lines + 1 prefetch line ≈ 64 Kbits. Choosing `n>3` wastes SRAM; `n<3` cannot form the halo.

### Why row0 preload is 2 lines + zero pad
Window must be `[pad, row0, row1]` for the first output row (top halo is zeros). Loading `[row0,row1,row2]` misaligns the center tap. Preload length = `2×WIDTH`; `START_UP ≥ 144+256` for L2/L3.

### Why N_CELL = 304
Weight hex has exactly 16+144+144 words. `3×144=432` wasted ~16 Kbits of SPRAM.

### Why packed DMA with 4 px/word
AHB is 32-bit; grayscale is 8-bit → natural packing factor 4. Reorder hex matches byte order expected by the store path. Transactions per line: 128 → 32 (~4× fewer beats).

### Why L3 multipixel was not kept in the final design
Mapping `kernel i → (pixel=⌊i/4⌋, oc=i%4)` fully uses `To=16` when `Cout=4`, but the last column group on the last row mismatched reference pixels (HW zeros). For a correct baseline-equivalent design we kept **stride-1 L3** and took the buffer/DMA/HSYNC gains instead. Re-enabling multipixel is future work after fixing that corner case.

### Why not full DMA↔L1 input line pipeline
Reducing `in_img` to `n` lines needs a redesigned L1 schedule tightly locked to DMA. We prioritized fmap double-buffer removal (largest term in `s0`) which gives a larger `s0/s` than shaving the 128 Kbit input buffer alone.

---

## Files touched

- `cnn_accel.v` — DMA pack, N_CELL, single fmap, linebuf, L3 path  
- `cnn_fsm.v` — (multipixel stride available but set to 1)  
- `bmp_image_writer.v` — `PIXELS_PER_VALID` support  
- `top_system_tb.v` / `top_system.v` — reorder INIT, delays, `OPT DONE` print  
- `OPT_RESULTS.txt` — numeric scratch pad  
