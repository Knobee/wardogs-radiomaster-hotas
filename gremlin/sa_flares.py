"""Joystick Gremlin R16 script: TX15 switch SA -> one V tap (flares) per position change.

SA is reported on axis 6 (Z rotation): down = -1, mid = 0, up = +1. A fast flick
from one end to the other passes through mid, so changes arriving within
LOCKOUT seconds of the last tap are ignored to avoid a double tap.
"""

import time

from gremlin import keyboard, macro, user_script

TX15_GUID = "__RADIO_GUID__"  # filled in by setup/Install-WardogsHotas.ps1
SA_AXIS = 6
LOCKOUT = 0.35  # seconds; a deliberate second flick is slower than this
STARTUP_GRACE = 2.0  # ignore the axis refresh Gremlin sends when it activates

FLARES_KEY = keyboard.key_from_code(47, False)  # V

tx15 = user_script.JoystickDecorator("__RADIO_NAME__", TX15_GUID, "Default")

_state = {"position": None, "last_tap": 0.0, "loaded": time.monotonic()}


def _position(value: float) -> int:
    if value < -0.5:
        return -1
    if value > 0.5:
        return 1
    return 0


@tx15.axis(SA_AXIS)
def sa_changed(event) -> None:
    position = _position(event.value)
    now = time.monotonic()
    previous = _state["position"]
    _state["position"] = position

    if now - _state["loaded"] < STARTUP_GRACE:
        return
    if position == previous:
        return
    if now - _state["last_tap"] < LOCKOUT:
        return

    _state["last_tap"] = now
    tap = macro.Macro()
    tap.press(FLARES_KEY)
    tap.pause(0.05)
    tap.release(FLARES_KEY)
    macro.MacroManager().queue_macro(tap)
