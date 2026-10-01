# lepton

A small, retained-mode **TUI framework** for [Ionic](../ionic): an alternate
screen buffer, raw-mode input, and a diff-based repaint.

```ionic
import "../src/screen.ionic";   // or vendor src/ into your project

tui_begin();
tui_clear(TUI_DEFAULT, TUI_DEFAULT);
tui_box_titled("Demo", 2, 2, 7, 30, TUI_CYAN, TUI_DEFAULT);
tui_put("Hello, TUI", 4, 4, TUI_GREEN, TUI_DEFAULT);
tui_flush();                    // paint only what changed

let k = tui_key();              // block for a keypress
tui_end();                      // restore the terminal
```

Build the demo and run it on a real terminal:

```sh
./build.sh && ./demo
```

## Modules

- `src/term.ionic` — keys (`KEY_*`), colors (`TUI_*`), `tui_cols`, `tui_rows`,
  `tui_key`, `tui_poll`, `tui_sgr`, `tui_move`, `tui_key_name`.
- `src/screen.ionic` — the retained buffer and widgets. Imports `term.ionic`
  and re-exports its symbols.

Import the whole thing with `import "../src/screen.ionic";` (adjust the path).

## Lifecycle

- `tui_begin()` — switch to the alternate screen, enter raw mode, hide the
  cursor, allocate the buffer at the current size.
- `tui_end()` — leave the alternate screen and restore the terminal.
- A runtime `atexit` hook restores the terminal even on a crash, but always
  call `tui_end()` on normal exit.

## Drawing

Coordinates are **1-based** `(row, col)`; rows grow downward.

- `tui_clear(fg, bg)` — blank the whole buffer.
- `tui_put(str, row, col, fg, bg)` / `tui_text(str, row, col)` — text (UTF-8
  aware: one cell per codepoint).
- `tui_center(str, row, fg, bg)` — horizontally centered text.
- `tui_put_char(row, col, code, fg, bg)` — a single codepoint.
- `tui_fill(row, col, h, w, fg, bg)` — a solid rectangle.
- `tui_hline` / `tui_vline` — box-drawing runs.
- `tui_box(row, col, h, w, fg, bg)` — a bordered box.
- `tui_box_titled(title, row, col, h, w, fg, bg)` — box with a title.

Coordinates outside the buffer are ignored, so widgets can be drawn partially
off-screen.

## Presenting

- `tui_flush()` — emit only the cells changed since the previous flush.
- `tui_flush_all()` — repaint everything on the next flush.
- `tui_resize()` — re-read the terminal size and reallocate (clears).
- `tui_show_cursor(row, col)` — show and position the cursor after a flush.

## Input

- `tui_key()` — block for one keypress. Printable keys return their codepoint;
  arrows/Home/End/PageUp/PageDown/Insert/Delete return the `KEY_*` sentinels
  (>= 1000); `-1` on EOF. UTF-8 is decoded to a codepoint.
- `tui_poll(ms)` — wait up to `ms` ms for input (1 = ready, 0 = timeout):

```ionic
tui_flush();
while (tui_poll(16) == 0) {   // ~60 fps tick
    update_animation();
    tui_flush();
}
let k = tui_key();
```

In raw mode `Ctrl-C` arrives as the byte `KEY_ETX` (3), not a signal.

## Rendering model

Cells live in flat `int64` arrays of length `width * height` (row-major), one
entry per column. `tui_put` decodes UTF-8 and stores one codepoint per cell, so
box-drawing characters and other non-ASCII glyphs land in a single cell.
`tui_flush` re-encodes each codepoint to UTF-8 via `tui_utf8`.

## Requirements

The `term_*` runtime builtins (raw mode, alternate screen, key decoding) live in
the Ionic compiler's C runtime — `ionic/src/ionic_model_runtime.c` — and are
registered in `checker.ionic` / `codegen/native.ionic`. You need an Ionic
compiler built with those (see the `../ionic` tree). The `.ionic` sources here
are otherwise plain Ionic.

## Known Ionic codegen quirks

- `break`/`continue` inside a `while` body miscompile (they work in `for`
  loops). Use `for` when you need early exit.
- Structs with array fields are not usable.
- `char_to_str(c)` is a raw byte for `c` in 0..255; UTF-8 encoding is done in
  Ionic (`tui_utf8`).
