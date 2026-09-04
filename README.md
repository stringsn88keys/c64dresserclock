# c64dresserclock

A Commodore 64 port of [c128dresserclock](../c128dresserclock), a
Copal-style dresser flip clock. Text-mode digits stand in for flipping
cards; the time comes from a small PowerShell TCP server over the
emulated userport RS232 (device 2), so there's no C64 RTC dependency.

`clock.bas` is plain BASIC 2.0 - the original's C128-only BASIC 7.0
`scnclr`/`color` statements are swapped for `chr$(147)` (clear screen)
and direct screen/color-RAM `poke`s.

The C128 original positions text by printing `chr$(17)`/`chr$(19)`
(cursor-down/home) to walk the cursor into place, but that doesn't
survive the port: those two codes are also the RS232 XON/XOFF
flow-control bytes, and once the RS232 channel is open the C64's
software UART intercepts them, corrupting cursor position. So this
port pokes screen/color RAM directly instead (`gosub9000`).

That surfaced a second, gnarlier C64-only issue: once RS232 is open,
reading a variable (or array element) that hasn't been touched in a
while comes back wrong - almost certainly the RS232 NMI receive
handler interrupting BASIC's variable-table scan mid-step. Two things
dodge it: the 6 fixed screen positions used after `open` are hardcoded
literal addresses rather than computed from `pr`/`sc` on the spot, and
the digit-shape lookup avoids a 2D array in favor of a literal
pattern-code table plus glyph strings that get recomputed fresh on
every call (see the `ponytail:` comments in `clock.bas`). The C128
original doesn't hit either of these because its native-mode RS232
KERNAL is different hardware/code, not the C64's bit-banged one.

## Prerequisites

- [VICE](https://vice-emu.sourceforge.io/) (for `x64sc` and `petcat`)
- PowerShell 7+ (`pwsh`) - the scripts use `pwsh`-only syntax

cc65 is referenced in `paths.ini` but unused; `clock.bas` is plain
BASIC, tokenized with `petcat`.

## Configure

Copy `paths.ini.example` to `paths.ini` and point it at your local
VICE (and cc65) install:

```
cp paths.ini.example paths.ini
```

```ini
[VICE]
RootPath="C:\path\to\root\of\vice"

[CC65]
RootPath="c:\path\to\cc65"
```

`paths.ini` is gitignored - it's machine-specific.

## Run

```
pwsh ./run-clock.ps1 [-Port 6510]
```

This tokenizes `clock.bas` to `clock.prg` via `petcat` (Basic v2.0
keywords), launches `time-server.ps1` in its own window (streams
`HH:mm:ss` once a second on `127.0.0.1:<Port>`), and autostarts the
program in `x64sc` with its userport wired to that server via
`-rsdev1ip232`. Closing the emulator stops the time server.

To run the time server standalone: `pwsh ./time-server.ps1 [-Port 6510]`.
