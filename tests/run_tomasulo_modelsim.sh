#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MSIM_BIN="/home/sangeeth/intelFPGA/20.1/modelsim_ase/bin"
VLIB="$MSIM_BIN/vlib"
VLOG="$MSIM_BIN/vlog"
VSIM="$MSIM_BIN/vsim"

if [[ ! -x "$VSIM" || ! -x "$VLOG" || ! -x "$VLIB" ]]; then
  echo "ModelSim tools not found under $MSIM_BIN"
  exit 1
fi

cd "$ROOT_DIR"

TEST_MEM="${1:-tests/tomasulo01_addi_smoke.mem}"
TEST_NAME="${2:-$(basename "$TEST_MEM" .mem)}"
MAX_CYC="${MAXCYC:-2000}"
LOG_FILE="modelsim_${TEST_NAME}.log"
EXPECTED="${3:-}"
DBG_EN="${DBG:-0}"

if [[ -z "$EXPECTED" ]]; then
  case "$TEST_NAME" in
    tomasulo01_addi_smoke) EXPECTED=5 ;;
    tomasulo02_add_chain) EXPECTED=21 ;;
    tomasulo03_mul_basic) EXPECTED=42 ;;
    tomasulo04_sw_lw_roundtrip) EXPECTED=33 ;;
    tomasulo05_dual_independent) EXPECTED=11 ;;
    tomasulo06_slot_dep) EXPECTED=9 ;;
    tomasulo07_mul_add_mix) EXPECTED=17 ;;
    *) EXPECTED="" ;;
  esac
fi

rm -rf work
"$VLIB" work
"$VLOG" -sv src/*.sv

"$VSIM" -c testbench \
  +MEM="$TEST_MEM" \
  +TEST="$TEST_NAME" \
  +MAXCYC="$MAX_CYC" \
  +DBG="$DBG_EN" \
  -l "$LOG_FILE" \
  -do "run -all; quit -f"

if grep -q "TIMEOUT:" "$LOG_FILE"; then
  echo "FAIL: $TEST_NAME timed out (see $LOG_FILE)"
  exit 1
fi

if ! grep -q "FINAL_SIGNATURE:" "$LOG_FILE"; then
  echo "FAIL: $TEST_NAME did not produce FINAL_SIGNATURE (see $LOG_FILE)"
  exit 1
fi

sig_line="$(grep "FINAL_SIGNATURE:" "$LOG_FILE" | tail -n 1)"
actual="$(echo "$sig_line" | sed -n 's/.*WriteData=\([-0-9][0-9]*\).*/\1/p')"

if [[ -z "$actual" ]]; then
  echo "FAIL: $TEST_NAME could not parse signature value (see $LOG_FILE)"
  exit 1
fi

if [[ -n "$EXPECTED" && "$actual" != "$EXPECTED" ]]; then
  echo "FAIL: $TEST_NAME expected=$EXPECTED actual=$actual"
  echo "  line: $sig_line"
  exit 1
fi

if [[ -n "$EXPECTED" ]]; then
  echo "PASS: $TEST_NAME expected=$EXPECTED actual=$actual"
else
  echo "PASS: $TEST_NAME actual=$actual"
fi
