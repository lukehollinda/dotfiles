#!/usr/bin/env bash
# Test harness for tmux session management scripts.
# Runs against an isolated tmux server socket so the user's real sessions are untouched.

set -euo pipefail

SOCKET="claude-test-$$"
T="tmux -L $SOCKET"
SCRIPTS="$(cd "$(dirname "$0")" && pwd)"
PASS=0
FAIL=0

export TMUX_SESSION_HISTORY
TMUX_SESSION_HISTORY=$(mktemp)

cleanup() {
    $T kill-server 2>/dev/null || true
    rm -f "$TMUX_SESSION_HISTORY"
}
trap cleanup EXIT

# -----------------------------------------------------------------------
# Helpers
# -----------------------------------------------------------------------

pass() { echo "  PASS: $1"; ((PASS++)) || true; }
fail() { echo "  FAIL: $1 — $2"; ((FAIL++)) || true; }

# Wait up to 5s for a sentinel file to appear, then remove it.
wait_for() {
    local f="$1"
    for _ in $(seq 50); do
        [[ -f "$f" ]] && { rm -f "$f"; return 0; }
        sleep 0.1
    done
    rm -f "$f"
    return 1
}

# Simulate the client-session-changed hook for $session.
# Runs on-session-switch.bash inside a new-window of the test server so that
# $TMUX is set to the test socket and `tmux display-message -p '#S'` returns
# the correct session name — no interactive shell init race.
simulate_switch() {
    local session="$1"
    local sentinel
    sentinel=$(mktemp); rm -f "$sentinel"

    $T has-session -t "$session" 2>/dev/null || $T new-session -d -s "$session"

    $T new-window -d -t "$session" \
        "TMUX_SESSION_HISTORY='$TMUX_SESSION_HISTORY' bash '$SCRIPTS/on-session-switch.bash'; touch '$sentinel'"

    wait_for "$sentinel" || echo "  WARN: sentinel timeout for simulate_switch($session)"
}

# Run on-session-closed.bash for a session that has already been killed.
simulate_close() {
    local session="$1"
    $T kill-session -t "$session" 2>/dev/null || true
    TMUX_SESSION_HISTORY="$TMUX_SESSION_HISTORY" \
        bash "$SCRIPTS/on-session-closed.bash" "$session" 2>/dev/null || true
}

history_top()      { head -n1 "$TMUX_SESSION_HISTORY" 2>/dev/null || true; }
history_count()    { grep -c '.' "$TMUX_SESSION_HISTORY" 2>/dev/null || echo 0; }
history_contains() { grep -qx "$1" "$TMUX_SESSION_HISTORY" 2>/dev/null; }

# -----------------------------------------------------------------------
# Setup
# -----------------------------------------------------------------------

echo ""
echo "Starting isolated tmux server (socket: $SOCKET)..."
# -f /dev/null prevents the test server from loading ~/.tmux.conf and its hooks,
# which would otherwise fire on-session-switch.bash during test operations and
# pollute the history file with unexpected writes.
tmux -L "$SOCKET" -f /dev/null new-session -d -s seed

echo ""
echo "Running tests..."
echo ""

# -----------------------------------------------------------------------
# Test 1: session_switch_adds_to_history
# -----------------------------------------------------------------------
> "$TMUX_SESSION_HISTORY"
simulate_switch "alpha"
if [[ "$(history_top)" == "alpha" ]]; then
    pass "session_switch_adds_to_history"
else
    fail "session_switch_adds_to_history" "expected 'alpha' at top, got '$(history_top)'"
fi

# -----------------------------------------------------------------------
# Test 2: session_switch_removes_duplicates
# -----------------------------------------------------------------------
> "$TMUX_SESSION_HISTORY"
$T has-session -t "alpha" 2>/dev/null || $T new-session -d -s "alpha"
$T has-session -t "beta"  2>/dev/null || $T new-session -d -s "beta"
simulate_switch "alpha"
simulate_switch "beta"
simulate_switch "alpha"
count=$(grep -c "^alpha$" "$TMUX_SESSION_HISTORY" 2>/dev/null || echo 0)
if [[ "$count" -eq 1 ]] && [[ "$(history_top)" == "alpha" ]]; then
    pass "session_switch_removes_duplicates"
else
    fail "session_switch_removes_duplicates" "alpha appears ${count}x, top=$(history_top)"
fi

# -----------------------------------------------------------------------
# Test 3: session_switch_limits_to_10
# -----------------------------------------------------------------------
> "$TMUX_SESSION_HISTORY"
for i in $(seq 1 12); do
    $T has-session -t "s$i" 2>/dev/null || $T new-session -d -s "s$i"
    simulate_switch "s$i"
done
count=$(history_count)
if [[ "$count" -le 10 ]]; then
    pass "session_switch_limits_to_10 (got $count entries)"
else
    fail "session_switch_limits_to_10" "expected ≤10, got $count"
fi

# -----------------------------------------------------------------------
# Test 4: session_closed_removes_from_history
# -----------------------------------------------------------------------
> "$TMUX_SESSION_HISTORY"
$T has-session -t "alpha" 2>/dev/null || $T new-session -d -s "alpha"
$T has-session -t "beta"  2>/dev/null || $T new-session -d -s "beta"
simulate_switch "alpha"
simulate_switch "beta"
simulate_close "alpha"
if ! history_contains "alpha"; then
    pass "session_closed_removes_from_history"
else
    fail "session_closed_removes_from_history" "alpha still present"
fi

# -----------------------------------------------------------------------
# Test 5: session_closed_leaves_remaining_entries
# -----------------------------------------------------------------------
> "$TMUX_SESSION_HISTORY"
$T has-session -t "alpha" 2>/dev/null || $T new-session -d -s "alpha"
$T has-session -t "beta"  2>/dev/null || $T new-session -d -s "beta"
$T has-session -t "gamma" 2>/dev/null || $T new-session -d -s "gamma"
simulate_switch "alpha"
simulate_switch "beta"
simulate_switch "gamma"
simulate_close "gamma"
if history_contains "beta" && history_contains "alpha" && ! history_contains "gamma"; then
    pass "session_closed_leaves_remaining_entries"
else
    fail "session_closed_leaves_remaining_entries" \
        "history: $(cat "$TMUX_SESSION_HISTORY" | tr '\n' ',')"
fi

# -----------------------------------------------------------------------
# Test 6: safe_kill_no_nvim
# Run the kill script from the 'seed' session so killing 'killtest'
# doesn't terminate our own window mid-script.
# -----------------------------------------------------------------------
$T has-session -t "killtest" 2>/dev/null || $T new-session -d -s "killtest"
sentinel=$(mktemp); rm -f "$sentinel"
$T new-window -d -t "seed" \
    "bash '$SCRIPTS/tmux-safe-kill-session-by-name.bash' 'killtest' 2>/dev/null; touch '$sentinel'"
wait_for "$sentinel" || true
if ! $T has-session -t "killtest" 2>/dev/null; then
    pass "safe_kill_no_nvim"
else
    fail "safe_kill_no_nvim" "killtest session still exists"
fi

# -----------------------------------------------------------------------
# Summary
# -----------------------------------------------------------------------

echo ""
echo "Results: $PASS passed, $FAIL failed"
echo ""
[[ $FAIL -eq 0 ]]
