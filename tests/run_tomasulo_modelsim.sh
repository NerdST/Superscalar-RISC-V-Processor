#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  run_tomasulo_modelsim.sh [TEST_MEM] [TEST_NAME] [EXPECTED] [-- VSIM_ARGS...]
  run_tomasulo_modelsim.sh [options] [-- VSIM_ARGS...]

Options:
  -m, --mem FILE         Memory image path (default: tests/tomasulo01_addi_smoke.mem)
  -t, --test NAME        Test name (default: basename of memory file)
  -e, --expected VALUE   Expected WriteData signature
      --maxcyc VALUE     Max cycles plusarg (default: env MAXCYC or 2000)
      --dbg VALUE        Debug plusarg (default: env DBG or 0)
      --gui              Launch ModelSim UI (omit -c)
      --help             Show this help

Notes:
  - Positional arguments remain supported for compatibility.
  - Anything after '--' is forwarded directly to vsim as "other options".
  - Env VAR VSIM_EXTRA_OPTS can also inject extra options (space-separated).

Examples:
  ./tests/run_tomasulo_modelsim.sh -m tests/tomasulo03_mul_basic.mem -t tomasulo03_mul_basic -- -voptargs=+acc
  ./tests/run_tomasulo_modelsim.sh --test tomasulo04_sw_lw_roundtrip --gui -- -wlf waves.wlf
  ./tests/run_tomasulo_modelsim.sh tests/tomasulo01_addi_smoke.mem tomasulo01_addi_smoke 5
EOF
}

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

TEST_MEM="tests/tomasulo01_addi_smoke.mem"
TEST_NAME=""
MAX_CYC="${MAXCYC:-2000}"
EXPECTED=""
DBG_EN="${DBG:-0}"
GUI_MODE=0
VSIM_ARGS=()
POSITIONAL=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    -m|--mem)
      TEST_MEM="$2"
      shift 2
      ;;
    -t|--test)
      TEST_NAME="$2"
      shift 2
      ;;
    -e|--expected)
      EXPECTED="$2"
      shift 2
      ;;
    --maxcyc)
      MAX_CYC="$2"
      shift 2
      ;;
    --dbg)
      DBG_EN="$2"
      shift 2
      ;;
    --gui)
      GUI_MODE=1
      shift
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    --)
      shift
      VSIM_ARGS+=("$@")
      break
      ;;
    -*)
      echo "Unknown option: $1"
      usage
      exit 2
      ;;
    *)
      POSITIONAL+=("$1")
      shift
      ;;
  esac
done

# Backward-compatible positional mode:
#   arg1=TEST_MEM arg2=TEST_NAME arg3=EXPECTED
if [[ ${#POSITIONAL[@]} -ge 1 ]]; then
  TEST_MEM="${POSITIONAL[0]}"
fi
if [[ ${#POSITIONAL[@]} -ge 2 ]]; then
  TEST_NAME="${POSITIONAL[1]}"
fi
if [[ ${#POSITIONAL[@]} -ge 3 ]]; then
  EXPECTED="${POSITIONAL[2]}"
fi

if [[ -z "$TEST_NAME" ]]; then
  TEST_NAME="$(basename "$TEST_MEM" .mem)"
fi

LOG_FILE="modelsim_${TEST_NAME}.log"

if [[ ! -f "$TEST_MEM" ]]; then
  echo "Memory image not found: $TEST_MEM"
  exit 1
fi

if [[ -n "${VSIM_EXTRA_OPTS:-}" ]]; then
  # shellcheck disable=SC2206
  extra_from_env=(${VSIM_EXTRA_OPTS})
  VSIM_ARGS+=("${extra_from_env[@]}")
fi

if [[ -z "$EXPECTED" ]]; then
  case "$TEST_NAME" in
    tomasulo01_addi_smoke) EXPECTED=5 ;;
    tomasulo02_add_chain) EXPECTED=21 ;;
    tomasulo03_mul_basic) EXPECTED=42 ;;
    tomasulo04_sw_lw_roundtrip) EXPECTED=33 ;;
    tomasulo05_dual_independent) EXPECTED=11 ;;
    tomasulo06_slot_dep) EXPECTED=9 ;;
    tomasulo07_mul_add_mix) EXPECTED=17 ;;
    rob01_waw_order) EXPECTED=99 ;;
    rob02_beq_not_taken) EXPECTED=43 ;;
    rob03_beq_taken) EXPECTED=77 ;;
    rob04_misaligned_trap) EXPECTED="TRAP:8" ;;
    *) EXPECTED="" ;;
  esac
fi

rm -rf work
"$VLIB" work
"$VLOG" -sv src/*.sv

if [[ "$GUI_MODE" -eq 1 ]]; then
  "$VSIM" testbench \
    +MEM="$TEST_MEM" \
    +TEST="$TEST_NAME" \
    +MAXCYC="$MAX_CYC" \
    +DBG="$DBG_EN" \
    -l "$LOG_FILE" \
    "${VSIM_ARGS[@]}"
else
  "$VSIM" -c testbench \
    +MEM="$TEST_MEM" \
    +TEST="$TEST_NAME" \
    +MAXCYC="$MAX_CYC" \
    +DBG="$DBG_EN" \
    -l "$LOG_FILE" \
    "${VSIM_ARGS[@]}" \
    -do "run -all; quit -f"
fi

if grep -q "TIMEOUT:" "$LOG_FILE"; then
  echo "FAIL: $TEST_NAME timed out (see $LOG_FILE)"
  exit 1
fi

# Expected values of the form "TRAP:<pc>" check for a TRAP_SIGNATURE instead
# of a FINAL_SIGNATURE — used for precise-exception tests.
if [[ "$EXPECTED" == TRAP:* ]]; then
  exp_pc="${EXPECTED#TRAP:}"
  if ! grep -q "TRAP_SIGNATURE:" "$LOG_FILE"; then
    echo "FAIL: $TEST_NAME did not produce TRAP_SIGNATURE (see $LOG_FILE)"
    exit 1
  fi
  sig_line="$(grep "TRAP_SIGNATURE:" "$LOG_FILE" | tail -n 1)"
  actual_pc="$(echo "$sig_line" | sed -n 's/.*trapPC=\([-0-9][0-9]*\).*/\1/p')"
  if [[ -z "$actual_pc" ]]; then
    echo "FAIL: $TEST_NAME could not parse trap PC (see $LOG_FILE)"
    exit 1
  fi
  if [[ "$actual_pc" != "$exp_pc" ]]; then
    echo "FAIL: $TEST_NAME expected trapPC=$exp_pc actual=$actual_pc"
    echo "  line: $sig_line"
    exit 1
  fi
  echo "PASS: $TEST_NAME expected trapPC=$exp_pc actual=$actual_pc"
  exit 0
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
