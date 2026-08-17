# Norns mod. txo nb voice.

This mod allows you to use a txo / txo+ as an nb voice via crow.

## Players

* **`txo 1`–`txo 4`** — monophonic voices (one port each): oscillator + AR envelope + velocity/level
* **`txo poly`** — polyphonic across ports 1–N
* **`txo unison`** — multi-voice unison with detune

Wave selection covers 327 wave types on a txo+ (use the first ~5 indexes for a plain txo), with blending between main wavetable types.

### `txo poly` params

* **voice count** (1–4) — only those ports are used (leave higher ports free for other uses)
* **alloc mode** — `rotate`, `random`, or `lru`
* **trigger mode**
  * `trigger` — `env_trig` on note-on; note-off does not cut amplitude
  * `gate` — `env(port, 1/0)` when env is on; otherwise level via `cv` on/off
* **shared timbre** — env, attack, decay, wave type, wave blend (applied to ports 1–N)

### `txo unison` params

* **voice count** (2–4)
* **detune** (cents) and **detune mode** — `random` (±amount/2 jitter) or `spread` (even spacing across amount)
* **shared timbre** — same wave/env set as poly (separate param group)

Unison uses trigger-style envelopes (`env_trig`), matching mono note-on behavior.

## Notes

* Poly and unison always use ports **1 … voice count** (low ports first). Higher ports stay free for other CV duties (e.g. LFOs), or carefully for mono players, as long as those ports are above the poly/unison range.
* Selecting overlapping mono and poly/unison ports at the same time can fight over hardware — avoid sharing a port between two active players.
* Pitch uses `(note - 0) / 12` (matching the mono players). Many other nb crow voices (e.g. Just Friends, w/syn) use `(note - 60) / 12` so middle C = 0V; revisit if you need pitch to match those without an octave offset.

## Future: start port / port range

Today there is no lower-bound / start-port param — ranges always begin at port 1. A **start + count** range on poly and unison (ports `S .. S+N-1`, clamped to 4) would unlock splits such as:

* `txo poly` on ports 1–2 and `txo unison` on 3–4 (or the reverse)

That works **without** a second registered unison player, because poly and unison are already separate `note_players`. A second registered unison (e.g. `txo unison a` / `txo unison b`) would only be needed for **two concurrent unison** blocks (e.g. unison on 1–2 and another unison on 3–4).

## Still to do

* start port / port range for poly and unison (see above)
* second unison player only if dual-unison blocks are needed
* slew
* more refinement of wavetable navigation / modulation
* pulse width modulation for the variable square wave
* interesting things with trigger outputs
