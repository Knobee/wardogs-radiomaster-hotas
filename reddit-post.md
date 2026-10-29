**Title:** Got a RadioMaster RC transmitter working as a helicopter HOTAS (the game doesn't see EdgeTX radios directly, here's the workaround + setup script)

---

If you've tried flying with an RC radio (RadioMaster TX15/TX16S/TX12/Boxer/etc. in USB joystick mode), you've probably found that Windows sees it fine but WARDOGS doesn't react to it at all. There's also an [open Steam report](https://steamcommunity.com/app/1867240/discussions/3/585061197374639125/) about a TX12 with the same problem. I spent an evening on this and got it working well, so here's what worked.

**TL;DR:** route the radio through a virtual joystick (vJoy) using Joystick Gremlin, and point the game's HOTAS bindings at vJoy. The game reads vJoy fine.

**What I ended up with (TX15 Max):**

- Right stick = cyclic, left stick = collective + yaw
- SF (spring switch) = fire (held left mouse)
- SE flipped up = `G`
- SA, any position change = flares (`V`). It fires once per flick, even end-to-end.

**Things I learned the hard way:**

1. **Season 2 reportedly reset `bUseHOTASHelicopters` to False** and scrambled HOTAS axis bindings for some people. They live in `%LOCALAPPDATA%\Wardogs\Saved\Config\WindowsClient\GameUserSettings.ini`, so check there first.
2. The game's default HOTAS **Sensitivity is 2.0**. With a radio, that's about twice as twitchy as it should be. 1.0 feels right.
3. The **collective uses the full axis**: stick down = descend, centre = middle. Don't use a 0–100% curve on it, or you lose the bottom half.
4. Disable **Steam Input** for WARDOGS.
5. Auto-hover / auto-level aren't keybinds. They're the Flight Assists settings (Stability + Auto-Hover), and they're always on when enabled.

**Repo with the full write-up, Gremlin profile, the switch script and a PowerShell setup script:**
https://github.com/Knobee/wardogs-radiomaster-hotas

The README explains the .ini format (including which number is the axis index) and how to map a different radio or layout using `joy.cpl`, so it should work for any EdgeTX radio, not just the TX15.

It would be great if native support for EdgeTX/RC radios came at some point. Until then, hopefully this saves someone else the evening. Happy to answer questions.
