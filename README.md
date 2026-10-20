# Lid awake

An Omarchy shell plugin that shows in the bar what closing the laptop's lid
does right now: keep working, or put the laptop to sleep. It reads and
switches `lid-awake`, a small script of mine that keeps the laptop computing
with the lid closed.

![The icon (lit, on battery) between Omarchy's indicators and the clock](preview.png)

`lid-awake on` starts a user unit, `lid-awake.service`, that holds logind's
block on the lid switch, sleep and idle, so closing the lid only turns the
screen off. `lid-awake off` stops it, and closing the lid suspends again.

The widget is one laptop icon, `󰌢`, the size of Omarchy's indicators beside
it, and always shown:

- **lit** while lid-awake is on: closing the lid keeps working;
- **in the theme's urgent colour** while it is on and the laptop runs on
  battery, which drains with the lid closed;
- **dim** while it is off: closing the lid puts the laptop to sleep.

Hover for what closing the lid does now; on battery the tooltip says so.
While an external monitor is connected logind ignores the lid anyway (it is
"docked"), and with lid-awake off the tooltip says the lid sleeps once the
monitor is unplugged.

Click to turn lid-awake off when the icon is lit and on when it is dim: the
click does what the tooltip said, even if the state changed meanwhile. A
failure (lid-awake did not start) comes as a notification. A change made
elsewhere, from a terminal or another program, shows within 3 seconds, the
interval at which the widget reads `lid-awake status` and logind's `Docked`.

## Install

Needs Omarchy Quattro (the Quickshell-based `omarchy-shell`) and
`~/.local/bin/lid-awake`: the script is in this repository, `bin/lid-awake`
(its header explains it), a short bash script around `systemd-run --user` and
`systemd-inhibit --what=handle-lid-switch:sleep:idle --mode=block`. The widget
only needs it to answer `lid-awake status` with `on` or `off` and to take
`lid-awake on` and `lid-awake off`, exiting non-zero when it fails.

From a clone, link the script and the plugin, then enable it:

```bash
git clone https://github.com/stefanoconiglio/omarchy-lid-awake.git ~/repos/omarchy-lid-awake
ln -s ~/repos/omarchy-lid-awake/bin/lid-awake ~/.local/bin/lid-awake
ln -s ~/repos/omarchy-lid-awake ~/.config/omarchy/plugins/io.github.stefanoconiglio.lid-awake
omarchy-shell shell rescanPlugins
omarchy plugin enable io.github.stefanoconiglio.lid-awake --section center --before omarchy.clock
```

`lid-awake` alone toggles; `lid-awake on`, `off` and `status` do what they say.
Never turn it off with the lid closed and no external monitor: logind then
suspends the laptop at once.

## Scripting

```bash
omarchy-shell io.github.stefanoconiglio.lid-awake state     # JSON: on, docked, onBattery, tooltip
omarchy-shell io.github.stefanoconiglio.lid-awake refresh   # read lid-awake again at once
omarchy-shell io.github.stefanoconiglio.lid-awake toggle    # the same as a left click
```

`tests/check_live.sh` checks the widget against the real lid-awake in the
running bar: it turns lid-awake off and on, both from the command line and
through the click, and ends with it on. It refuses to run with the lid
closed, where turning lid-awake off suspends the laptop at once.

On a vertical bar the icon keeps its place and its colours.

## License

MIT
