#!/usr/bin/env bash
#
# Dependencies are managed with uv (https://docs.astral.sh/uv/). The suite runs
# through `uv run`, using the locked environment from uv.lock.
#
# Default behaviour: run the tests on **Chrome and Firefox in parallel** (via
# pabot) and merge the results into a single report.
#
# Usage:
#   ./run_tests.sh                 # Chrome + Firefox in parallel (headless)
#   BROWSER=chrome ./run_tests.sh  # single browser only (chrome | firefox)
#   HEADLESS=False ./run_tests.sh  # show the browser window(s)
#
# Any extra arguments are passed straight through to robot/pabot, e.g.:
#   ./run_tests.sh --test "Valid Login Succeeds"
#
set -euo pipefail

HEADLESS="${HEADLESS:-True}"
RESULTS_DIR="${RESULTS_DIR:-results}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${SCRIPT_DIR}"

# Snap workaround
SNAP_FIREFOX="/snap/firefox/current/usr/lib/firefox/firefox"
if [[ -z "${FIREFOX_BINARY:-}" && -x "${SNAP_FIREFOX}" ]]; then
    FIREFOX_BINARY="${SNAP_FIREFOX}"
fi
EXTRA_ARGS=()
if [[ -n "${FIREFOX_BINARY:-}" ]]; then
    EXTRA_ARGS+=(--variable "FIREFOX_BINARY:${FIREFOX_BINARY}")
fi

# ESET workaround
if lsmod 2>/dev/null | grep -q '^eset_wap' || pgrep -x wapd >/dev/null 2>&1; then
    EXTRA_ARGS+=(--variable CHROME_LOOPBACK_FIX:True)
fi

# A single explicit browser bypasses parallel execution
if [[ -n "${BROWSER:-}" ]]; then
    uv run robot \
        --variable "BROWSER:${BROWSER}" \
        --variable "HEADLESS:${HEADLESS}" \
        "${EXTRA_ARGS[@]}" \
        --outputdir "${RESULTS_DIR}" \
        "$@" \
        tests/
    status=$?
    if ! pgrep -af 'cdp-profile-|remote-debugging-port' >/dev/null 2>&1; then
        rm -rf /tmp/cdp-profile-*
    fi
    exit "${status}"
fi

# Default: Chrome and Firefox in parallel, merged into one report
uv run pabot \
    --argumentfile1 args/chrome.args \
    --argumentfile2 args/firefox.args \
    --variable "HEADLESS:${HEADLESS}" \
    "${EXTRA_ARGS[@]}" \
    --outputdir "${RESULTS_DIR}" \
    "$@" \
    tests/
status=$?
if ! pgrep -af 'cdp-profile-|remote-debugging-port' >/dev/null 2>&1; then
    rm -rf /tmp/cdp-profile-*
fi
exit "${status}"

