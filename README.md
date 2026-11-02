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
failure (lid-awake did not start, or would not turn off with the lid closed)
comes as a notification. A change made
elsewhere, from a terminal or another program, shows within 3 seconds, the
interval at which the widget reads `lid-awake status` and logind's `Docked`.

## Install

```bash
omarchy plugin add https://github.com/stefanoconiglio/omarchy-lid-awake --enable
omarchy bar move io.github.stefanoconiglio.lid-awake --section center --before omarchy.clock
```

`--enable` asks for a bar section and puts the icon there; the second line
moves it where I keep it, just before the clock. The widget runs the
plugin's own copy of the script,
`~/.config/omarchy/plugins/io.github.stefanoconiglio.lid-awake/bin/lid-awake`.
For the terminal command too:
`ln -s ~/.config/omarchy/plugins/io.github.stefanoconiglio.lid-awake/bin/lid-awake ~/.local/bin/lid-awake`.

Or from a clone of your own, linked in:

```bash
git clone https://github.com/stefanoconiglio/omarchy-lid-awake.git ~/repos/omarchy-lid-awake
ln -s ~/repos/omarchy-lid-awake/bin/lid-awake ~/.local/bin/lid-awake   # for the terminal
ln -s ~/repos/omarchy-lid-awake ~/.config/omarchy/plugins/io.github.stefanoconiglio.lid-awake
omarchy-shell shell rescanPlugins
omarchy plugin enable io.github.stefanoconiglio.lid-awake --section center --before omarchy.clock
```

Needs Omarchy Quattro (the Quickshell-based `omarchy-shell`). The script,
`bin/lid-awake` (its header explains it), is a short bash script around
`systemd-run --user` and
`systemd-inhibit --what=handle-lid-switch:sleep:idle --mode=block`; it also
uses `systemctl`, `busctl` and `journalctl` (systemd), `hyprctl`, `jq`, and
Omarchy's own `omarchy-toggle-idle`, `omarchy-brightness-display`,
`omarchy-hw-laptop-closed` and `omarchy-hw-external-monitors`. The widget
adds `sh`, `busctl` (logind's `Docked`), `notify-send` and UPower (through
Quickshell).

`lid-awake` alone toggles; `lid-awake on`, `off` and `status` do what they say.
Turning it off with the lid closed and no external monitor would make logind
suspend the laptop at once, so `lid-awake off` (and the toggle) refuses then,
exits 3 and says why; a click on the icon says it in a notification.
`lid-awake off --force` turns it off anyway.

## Remove

Turn lid-awake off first, with the lid open (or an external monitor
connected: with the lid closed and nothing docked it refuses, and
`--force` suspends the laptop at once), then remove the plugin:

```bash
lid-awake off      # or a click on the icon, if it is lit
omarchy plugin remove io.github.stefanoconiglio.lid-awake
rm -f ~/.local/bin/lid-awake   # if you made the link
```

Without the link, the first line is
`~/.config/omarchy/plugins/io.github.stefanoconiglio.lid-awake/bin/lid-awake off`.
If the plugin went while lid-awake was on, `systemctl --user stop lid-awake`
turns it off all the same (it also puts Omarchy back to idling normally).

`omarchy plugin remove` takes the icon out of the bar when it was in it;
if `io.github.stefanoconiglio.lid-awake` is still listed in
`~/.config/omarchy/shell.json`, delete that entry and run
`omarchy restart shell`.

## Scripting

```bash
omarchy-shell io.github.stefanoconiglio.lid-awake state     # JSON: on, docked, onBattery, tooltip, command
omarchy-shell io.github.stefanoconiglio.lid-awake refresh   # read lid-awake again at once
omarchy-shell io.github.stefanoconiglio.lid-awake toggle    # the same as a left click
```

`tests/check_live.sh` checks the widget against the real lid-awake in the
running bar: it turns lid-awake off and on, both from the command line and
through the click, and ends with it on. It refuses to run with the lid
closed, where turning lid-awake off suspends the laptop at once.
`tests/refuse_closed_lid.sh` checks the refusal and `--force` against stubs of
`systemctl` and `busctl`, never the real lid-awake: safe at any time.

On a vertical bar the icon keeps its place and its colours.

## License

MIT
