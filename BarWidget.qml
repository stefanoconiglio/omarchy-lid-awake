import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower
import qs.Commons
import qs.Ui

// What closing the lid does right now, from lid-awake (~/.local/bin/lid-awake):
// while it is on, its user unit holds logind's block on the lid switch and the
// laptop keeps working with the lid closed; while it is off, closing the lid
// suspends. One laptop icon at the size of Omarchy's indicators beside it, always
// shown: lit when on, dimmed when off, in the theme's urgent colour when on and
// running on battery. `lid-awake status` is read every 3 seconds, so a change
// made from a terminal shows within that.
//
// Left click turns it off when it shows on and on when it shows off: the click
// does what the tooltip said, even if the state changed meanwhile.
BarWidget {
  id: root
  moduleName: "io.github.stefanoconiglio.lid-awake"

  readonly property string lidAwake: Quickshell.env("HOME") + "/.local/bin/lid-awake"

  // Unknown until the first read answers "on" or "off".
  property bool known: false
  property bool on: false
  // logind ignores the lid while docked (an external monitor connected), so
  // with lid-awake off the lid sleeps only once that monitor is gone.
  property bool docked: false
  readonly property bool onBattery: UPower.onBattery
  readonly property bool switching: switchProc.running

  readonly property string tooltip: {
    if (switching) return on ? "Turning lid-awake off…" : "Turning lid-awake on…"
    if (!known) return "Lid-awake: no answer from " + lidAwake + " status"
    if (on) {
      return "Lid-awake on: closing the lid keeps working\n"
        + "(the screen goes dark; the laptop does not sleep)\n"
        + (onBattery
          ? "On battery: it keeps draining with the lid closed;\nturn it off before putting the laptop in a bag\n"
          : "")
        + "Click to turn it off"
    }
    return (docked
        ? "Lid-awake off: closing the lid sleeps once the external monitor is unplugged\n"
          + "(while one is connected, closing the lid does nothing)\n"
        : "Lid-awake off: closing the lid sleeps\n"
          + "(the work stops until the lid opens)\n")
      + "Click to keep working with the lid closed"
  }

  function update(text) {
    var lines = String(text || "").split("\n")
    var state = (lines[0] || "").trim()
    known = state === "on" || state === "off"
    on = state === "on"
    docked = /^b true/.test((lines[1] || "").trim())
  }

  function refresh() {
    if (!statusProc.running) statusProc.running = true
  }

  function toggle() {
    if (!known || switchProc.running) return
    switchProc.verb = on ? "off" : "on"
    switchProc.command = [lidAwake, switchProc.verb]
    switchProc.running = true
  }

  implicitWidth: iconButton.implicitWidth
  implicitHeight: iconButton.implicitHeight

  IpcHandler {
    target: "io.github.stefanoconiglio.lid-awake"

    function refresh(): void {
      root.broadcast("refresh")
    }

    // The same as a left click on the icon.
    function toggle(): void {
      root.toggle()
    }

    function state(): string {
      return JSON.stringify({
        known: root.known,
        on: root.on,
        docked: root.docked,
        onBattery: root.onBattery,
        tooltip: root.tooltip
      })
    }
  }

  Process {
    id: statusProc
    command: ["sh", "-c", "\"$1\" status; busctl get-property org.freedesktop.login1 /org/freedesktop/login1 org.freedesktop.login1.Manager Docked 2>/dev/null", "sh", root.lidAwake]
    stdout: StdioCollector { waitForEnd: true; onStreamFinished: root.update(text) }
  }

  // lid-awake's own messages go to its terminal, which a click has none of, so a
  // failure is said in a notification; the bars of every screen read again.
  Process {
    id: switchProc
    property string verb: ""
    onExited: function(exitCode) {
      if (exitCode !== 0)
        Quickshell.execDetached(["notify-send", "-u", "critical", "lid-awake " + verb + " failed",
          "See: journalctl --user -u lid-awake"])
      root.broadcast("refresh")
    }
  }

  Timer {
    interval: 3000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: root.refresh()
  }

  // Sized like BarIndicator (Omarchy's indicators), which is not used itself:
  // it hides an inactive icon unless its row is hovered, and this one must stay.
  BarIconButton {
    id: iconButton
    anchors.fill: parent
    bar: root.bar
    text: "󰌢"
    foreground: root.on && root.onBattery && root.bar ? root.bar.urgent : (root.bar ? root.bar.barForeground : Color.foreground)
    dimmed: !root.on
    keepSpace: true
    useActiveColor: false
    tooltipText: root.tooltip
    fontSize: Style.font.caption
    horizontalMargin: 5
    verticalPadding: 5
    fixedWidth: root.vertical ? -1 : Style.bar.statusSlot
    fixedHeight: root.vertical ? Style.bar.statusSlot : -1
    onPressed: function(button) {
      if (button === Qt.LeftButton) root.toggle()
    }
  }
}
