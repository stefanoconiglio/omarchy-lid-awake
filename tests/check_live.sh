#!/bin/bash
#
# check_live.sh: check the widget against the real lid-awake, in the running bar.
#
# Turns lid-awake off from the command line and waits for the widget to show it,
# then turns it on and off through the widget's click path (the IPC `toggle`,
# which runs the same function as a left click), then on again from the command
# line. Each step checks where it starts (lid-awake and the widget agree) and
# passes only when lid-awake itself changed and the widget shows it. lid-awake is
# off for a few seconds in between; it always ends with lid-awake on, and says so.
#
# It refuses to turn lid-awake off with the lid closed, checked before every
# step that does: releasing lid-awake's block then makes logind act on the closed
# lid at once and suspend the laptop (20 Oct 2026, 11:44: it slept for a minute,
# until the lid was opened).

LA=$HOME/.local/bin/lid-awake
TARGET=io.github.stefanoconiglio.lid-awake
failed=0

widget_on() {
  omarchy-shell "$TARGET" state | jq -r '.on'
}

# lid-awake with no terminal and its messages dropped, as the steps run it.
la() {
  $LA "$@" </dev/null >/dev/null
}

lid_open() {
  [[ $(busctl get-property org.freedesktop.login1 /org/freedesktop/login1 org.freedesktop.login1.Manager LidClosed) == "b false" ]]
}

# Ends the check with lid-awake on, whatever happened.
finish() {
  [[ $($LA status) == on ]] || la on
  echo "end: lid-awake $($LA status)"
  systemd-inhibit --list --no-pager | grep -E '^lid-awake ' || { echo "  FAIL: no lid-awake inhibitor"; failed=1; }
  omarchy-shell "$TARGET" state | jq -r '.tooltip'
  exit $failed
}

# step <description> <expected before: on|off> <command...>: runs the command
# and waits up to 10 s for lid-awake and the widget both to show the other state.
step() {
  local what=$1 before=$2 after start i
  shift 2
  [[ $before == on ]] && after=off || after=on
  echo "$what:"
  if [[ $before == on ]] && ! lid_open; then
    echo "  The lid is closed (or logind did not answer): turning lid-awake off now would suspend the laptop. Stopped." >&2
    failed=2
    finish
  fi
  if [[ $($LA status) != "$before" || $(widget_on) != $([[ $before == on ]] && echo true || echo false) ]]; then
    echo "  FAIL: expected to start from $before; lid-awake $($LA status), widget on=$(widget_on)"
    failed=1
    finish
  fi
  start=$(date +%s%N)
  "$@"
  for i in $(seq 1 40); do
    if [[ $($LA status) == "$after" && $(widget_on) == $([[ $after == on ]] && echo true || echo false) ]]; then
      echo "  lid-awake $after, widget agrees after $(( ($(date +%s%N) - start) / 1000000 )) ms"
      return 0
    fi
    sleep 0.25
  done
  echo "  FAIL: within 10 s lid-awake is $($LA status), widget on=$(widget_on); expected $after"
  failed=1
  finish
}

echo "start: lid-awake $($LA status), widget on=$(widget_on)"
[[ $($LA status) == on ]] || step "lid-awake on from the command line" off la on
step "lid-awake off from the command line" on la off
step "click path (toggle) while off" off omarchy-shell "$TARGET" toggle
step "click path (toggle) while on" on omarchy-shell "$TARGET" toggle
step "lid-awake on from the command line" off la on
finish
