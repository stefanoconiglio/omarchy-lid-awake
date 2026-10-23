#!/bin/bash
#
# refuse_closed_lid.sh [script]: check that `lid-awake off` and the toggle
# refuse while the lid is closed and nothing is docked, unless --force.
#
# Runs the script (default: bin/lid-awake beside this folder) against stubs of
# systemctl, busctl, omarchy-toggle-idle and omarchy-brightness-display, put
# first on PATH: the real lid-awake, logind and the screen are never touched,
# so it is safe with lid-awake on and the lid closed.

here=$(dirname "$(readlink -f "$0")")
script=$(readlink -f "${1:-$here/../bin/lid-awake}")
stubs=$(mktemp -d)
trap 'rm -rf "$stubs"' EXIT
failed=0

# systemctl: lid-awake is on; a stop is written to the calls file.
cat >"$stubs/systemctl" <<'EOF'
#!/bin/bash
echo "systemctl $*" >>"$STUB_CALLS"
[[ " $* " == *" is-active "* ]] && exit 0
exit 0
EOF
# busctl: LidClosed and Docked from STUB_LID and STUB_DOCK ("true", "false",
# or empty for a property logind does not answer).
cat >"$stubs/busctl" <<'EOF'
#!/bin/bash
case "${@: -1}" in
  LidClosed) [[ -n $STUB_LID ]] && echo "b $STUB_LID" || exit 1 ;;
  Docked) [[ -n $STUB_DOCK ]] && echo "b $STUB_DOCK" || exit 1 ;;
esac
EOF
printf '#!/bin/bash\necho "$(basename "$0") $*" >>"$STUB_CALLS"\n' >"$stubs/omarchy-toggle-idle"
cp "$stubs/omarchy-toggle-idle" "$stubs/omarchy-brightness-display"
chmod +x "$stubs"/*

# check <name> <lid> <dock> <want: stopped|refused> <args...>
check() {
  local name=$1 lid=$2 dock=$3 want=$4 code got
  shift 4
  export STUB_CALLS="$stubs/calls" STUB_LID=$lid STUB_DOCK=$dock
  : >"$STUB_CALLS"
  PATH="$stubs:$PATH" "$script" "$@" </dev/null >/dev/null 2>"$stubs/err"
  code=$?
  if grep -q "systemctl --user stop lid-awake" "$STUB_CALLS"; then got=stopped; else got=refused; fi
  if [[ $got == "$want" && ( $want == stopped && $code == 0 || $want == refused && $code == 3 ) ]]; then
    echo "  ok   $name: $got (exit $code)"
  else
    echo "  FAIL $name: $got (exit $code), wanted $want"; failed=1
  fi
}

echo "lid-awake: $script"
check "off, lid closed, undocked"          true  false refused off
check "toggle, lid closed, undocked"       true  false refused
check "off --force, lid closed, undocked"  true  false stopped off --force
check "--force toggle, lid closed"         true  false stopped --force
check "off, lid closed, docked"            true  true  stopped off
check "off, lid open"                      false false stopped off
check "off, Docked unreadable, lid closed" true  ""    refused off
check "off, LidClosed unreadable"          ""    false stopped off
exit $failed
