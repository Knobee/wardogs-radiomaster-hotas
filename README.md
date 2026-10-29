# WARDOGS helicopters with a RadioMaster (EdgeTX) radio

Fly WARDOGS helicopters with a RadioMaster radio as a USB joystick: sticks for
cyclic/collective/yaw, switches for fire, flares, and any other key.

WARDOGS **does not see EdgeTX radios directly** (at least as of Season 2), even
though Windows does. The workaround is to pass the radio through a virtual joystick
(**vJoy**) with **Joystick Gremlin**, and point the game's HOTAS bindings at vJoy.
Gremlin also turns the radio's switches into key presses and mouse clicks.

Tested with a **RadioMaster TX15 Max** (EdgeTX) on Windows 11, vJoy 2.1.9.1 and
Joystick Gremlin R16. Any EdgeTX radio should work the same way. Only the axis and
button numbers change.

| Radio control | In-game |
|---|---|
| Right stick | Cyclic: roll and pitch |
| Left stick up/down | Collective (bottom = down, centre = middle, top = full) |
| Left stick left/right | Yaw |
| SF (momentary) | Fire: holds left mouse while held |
| SE (2-pos) down→up | Taps `G` once |
| SA (3-pos), any move | Taps `V` (flares) once per move, including a fast end-to-end flick |

---

## What you need

- A RadioMaster/EdgeTX radio and a USB cable
- [vJoy 2.1.9.1](https://github.com/jshafer817/vJoy/releases) (the version tested; newer forks such as [BrunnerInnovation/vJoy](https://github.com/BrunnerInnovation/vJoy/releases) should also work). Enable device 1 with at least 8 axes in **Configure vJoy**.
- [Joystick Gremlin](https://whitemagic.github.io/JoystickGremlin/) **R16** (the portable zip is fine)
- WARDOGS on Steam, with **Steam Input disabled** for the game (Steam → WARDOGS → Properties → Controller)

## Quick start

1. **Radio:** connect by USB and pick **USB Joystick (HID)**. In the model's
   **Setup → USB Joystick**, use **Advanced** mode and check which axis or button
   each stick and switch shows up as (see *Finding your axis numbers* below).
2. **Windows:** run `joy.cpl` once with the radio plugged in, so Windows registers it.
3. **Setup script** (from this repo, in PowerShell, with the game **closed**):

   ```powershell
   .\setup\Install-WardogsHotas.ps1 -PatchIni -GremlinExe "C:\path\to\Joystick.Gremlin.R16\joystick_gremlin.exe"
   ```

   This:
   - finds the DirectInput GUIDs of your radio and of vJoy
   - writes a ready-to-load Gremlin profile and script to `Documents\WardogsHotas\`
   - backs up and patches `GameUserSettings.ini` (details below)
   - creates a **WARDOGS HOTAS (Gremlin)** desktop shortcut

   Leave out `-PatchIni` if you'd rather edit the .ini yourself, and leave out
   `-GremlinExe` if you don't want the shortcut. If your radio isn't an EdgeTX radio,
   pass its ID, for example `-VidPid 'VID_03EB&PID_6200'`. The ID is the
   `VID_xxxx&PID_xxxx` part shown in Device Manager → device → Details → Hardware Ids.
4. **Before each session,** start Gremlin from the shortcut, then start the game.
   Gremlin must stay running while you play.

> **When you close Gremlin, always pick "Don't Save".** Gremlin flags the profile as
> changed even when nothing has changed. Saving writes Gremlin's in-memory copy over
> the file, so any edit you made to the file while Gremlin was open is lost.

---

## How it works

```
 Radio (USB HID, 1209:4F54)
        │  DirectInput
        ▼
 Joystick Gremlin ──► vJoy device 1 (axes X, Y, Z, Rx)      ──► WARDOGS HOTAS bindings
        │
        └──────────► keyboard / mouse (SendInput)          ──► WARDOGS key bindings
```

### 1. The game's HOTAS settings

The bindings live in `%LOCALAPPDATA%\Wardogs\Saved\Config\WindowsClient\GameUserSettings.ini`
under `[/Script/WDJoystick.WDJoystickSettings]`. Each axis line looks like this:

```
Roll=(DeviceIdentifier="1234:BEAD:vJoy Device",_aaaajdmbkojdnhnkhhfhe=0,bInvert=False, ... ,Sensitivity=1.000000,DeadZone=0.000000)
```

- **`DeviceIdentifier`** is `VID:PID:name`, where the name is what DirectInput reports.
  For vJoy that's `1234:BEAD:vJoy Device`.
- **The first number after `DeviceIdentifier`** is the axis index, counted from 0 in
  DirectInput order: X=0, Y=1, Z=2, Rx=3, Ry=4, Rz=5, Slider=6, Dial=7.
  `-1` means unbound. The field name is obfuscated and may change between game
  versions, so the setup script matches it by position, not by name.
- **`Sensitivity`** defaults to `2.0`, which feels about twice as twitchy as it should
  with a radio. `1.0` is a 1:1 response.
- **`DeadZone`** for Throttle defaults to `0.1`. Set it to `0.0`.

Other settings in the same file:

```
bUseHOTASHelicopters=True       ; required. Reportedly reset to False by the Season 2 update
bCollectiveSelfCentering=False
bFlightAssistsEnabled=True      ; master switch for the assists below
bHeliAssistStabilityEnabled=True     ; levels the aircraft when you release the cyclic
bHeliAssistAutoHoverEnabled=True     ; holds a hover with the collective at neutral (stick centred)
bHeliAssistEnvelopeLimitsEnabled=False
bHeliAssistTurnCoordinationEnabled=False
```

These assists are always-on settings. There's no key for auto-hover or auto-level.

What `-PatchIni` writes:

| Line | DeviceIdentifier | Axis | Sensitivity | DeadZone |
|---|---|---|---|---|
| Roll | `1234:BEAD:vJoy Device` | 0 (X) | 1.0 | 0 |
| Pitch | `1234:BEAD:vJoy Device` | 1 (Y) | 1.0 | 0 |
| Throttle | `1234:BEAD:vJoy Device` | 2 (Z) | 1.0 | 0 |
| Yaw | `1234:BEAD:vJoy Device` | 3 (Rx) | 1.0 | 0 |

`bInvert` is left alone. Pitch is usually `True`. Change it in-game if any axis
works backwards. **Close the game before editing the .ini**, because the game
rewrites the file when it exits.

### 2. Gremlin profile (`gremlin/TX15.template.xml`)

| Radio input (Gremlin numbering, from 1) | Action |
|---|---|
| Axis 1 (X), Axis 2 (Y), Axis 3 (Z), Axis 4 (Rx) | **Map to vJoy**, device 1, same axis, absolute, no curve |
| Button 2 (SF) | **Map to Mouse**, Left button (held while SF is held) |
| Axis 5 (Ry, SE) | Virtual button over the range 0.5…1.0 → **Macro** `G` down, 50 ms, `G` up. Activation **press** only, so it fires on down→up only |
| Axis 6 (Rz, SA) | Handled by the script below |

The collective uses the **full** axis: bottom of the stick is collective down,
centre is the middle. Don't add a "0–100%" half-range curve. That makes
stick-fully-down equal to middle collective, so the helicopter can't descend.

### 3. Script: a switch that fires once per move (`gremlin/sa_flares.py`)

A 3-position switch is a single axis (−1 / 0 / +1). The obvious approach is a virtual
button over the middle position, with the macro firing on both press and release.
That fires twice on a fast up→down flick, because the switch passes through the
middle. Gremlin macros queue repeats rather than dropping them, so a macro can't
debounce this.

The script works out the switch position (down/mid/up) on every axis event. It taps
the key when the position changes, and ignores further changes for **0.35 s**. It
also ignores the first 2 s after Gremlin starts, because Gremlin re-reads every axis
when it activates. You can change `LOCKOUT`, `SA_AXIS` and the key code at the top
of the file.

---

## Adapting it to another radio or another layout

### Finding your axis numbers

Open `joy.cpl`, select the radio, click **Properties** and move each control:

| What moves in joy.cpl | Gremlin input | Game .ini index (if bound directly) |
|---|---|---|
| X Axis | axis 1 | 0 |
| Y Axis | axis 2 | 1 |
| Z Axis | axis 3 | 2 |
| X Rotation | axis 4 | 3 |
| Y Rotation | axis 5 | 4 |
| Z Rotation | axis 6 | 5 |
| Slider / Dial | axis 7 / 8 | 6 / 7 |
| Button *n* | button *n* | – |

The TX15 defaults (AETR channel order): roll = X, pitch = Y, throttle = Z,
yaw = X Rotation. SE showed up as Y Rotation, SA as Z Rotation and SF as button 2.

If a switch doesn't show up at all, route it on the radio: **Model → Setup →
USB Joystick → pick a free channel → Mode: Button** (or Axis), then add a **mix**
on that channel with the switch as the source.

### Changing the profile

It's easiest to load the generated profile in Gremlin, change the inputs in its UI,
and then **Save** that one time. If you edit the XML instead, inputs are matched
by `<device-id>`, `<input-type>` and `<input-id>`. Keyboard keys use **scan codes**
(for example G = 34, V = 47, Space = 57).

Keep each radio axis mapped to its **own** vJoy axis. Mapping two radio inputs to the
same vJoy axis makes them fight over it, and the symptom is "only one stick works".

### Other RadioMaster models

- **EdgeTX radios** (TX16S, TX12, Boxer, Zorro, Pocket, MT12, TX15…) all report as
  `1209:4F54`. Windows caches the *first* name it saw for that ID, so the radio may
  appear as e.g. "RM TX16S Joystick" whatever model it is. That's harmless.
- **T8L/T8 Lite** reported as `03EB:6200` ("RADIOMASTER SIM") in our tests. Pass
  `-VidPid 'VID_03EB&PID_6200'` to the setup script.
- **ExpressLRS Bluetooth joystick** reports as `E502:BBAB`. It's untested here but
  should work the same way through vJoy.

---

## Troubleshooting

| Symptom | Fix |
|---|---|
| Game ignores the radio completely | That's the original problem. Bind the game to vJoy, not to the radio. |
| Game ignores vJoy too | Is Gremlin running, with the profile enabled? In `joy.cpl`, check that the **vJoy Device** bars move with the sticks. Is Steam Input disabled for WARDOGS? |
| vJoy bars in joy.cpl move, then freeze | That's the joy.cpl test page, not the setup. Close and reopen Properties. |
| Controls far too twitchy | Check that `Sensitivity` is 1.0, not the game's default 2.0. |
| Collective can't go below the middle | Remove any response curve on the throttle input. The game wants the full axis. |
| A switch fires twice | Use a script with a lockout, like `sa_flares.py`. |
| Bindings reset after a game update | Re-run the setup script with `-PatchIni` (the game must be closed). |
| Stray key press when Gremlin starts | Put 2-position switches in their "off" position before starting Gremlin. |

## Files

```
gremlin/TX15.template.xml        Gremlin R16 profile template (GUIDs and script path filled in by setup)
gremlin/sa_flares.py             Gremlin script: one key tap per 3-position-switch move, with a lockout
setup/Install-WardogsHotas.ps1   Builds the profile, patches the .ini, makes the shortcut
reddit-post.md                   The post that announced this
```

## Background

- [Steam report: RadioMaster TX12 not detected by WARDOGS](https://steamcommunity.com/app/1867240/discussions/3/585061197374639125/). This is the same bug. Windows sees the radio, the game doesn't.
- [EdgeTX joystick mapping information](https://manual.edgetx.org/edgetx-how-to/joystick-mapping-information-for-game-developers)
- [Joystick Gremlin documentation](https://whitemagic.github.io/JoystickGremlin/)

Not affiliated with WARDOGS, Team17, RadioMaster or EdgeTX. Use at your own risk, and
keep the `.bak` files the setup script makes.
