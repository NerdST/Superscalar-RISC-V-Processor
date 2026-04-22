#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RUNNER="$ROOT_DIR/tests/run_tomasulo_modelsim.sh"

TESTS=(
  # Baseline: arithmetic, load/store, data forwarding (no branches)
  tests/tomasulo01_addi_smoke.mem
  tests/tomasulo02_add_chain.mem
  tests/tomasulo03_mul_basic.mem
  tests/tomasulo04_sw_lw_roundtrip.mem
  tests/tomasulo05_dual_independent.mem
  tests/tomasulo06_slot_dep.mem
  tests/tomasulo07_mul_add_mix.mem
  # ROB-specific: rename ordering, branch predict-not-taken, misprediction flush
  tests/rob01_waw_order.mem
  tests/rob02_beq_not_taken.mem
  tests/rob03_beq_taken.mem
  # Precise exception: misaligned LW raises trap; younger insns do not commit
  tests/rob04_misaligned_trap.mem
)

fails=0
FORWARD_ARGS=("$@")

for t in "${TESTS[@]}"; do
  echo "===== Running $t ====="
  if ! "$RUNNER" "$t" "$(basename "$t" .mem)" "${FORWARD_ARGS[@]}"; then
    fails=$((fails + 1))
  fi
done

if [[ "$fails" -ne 0 ]]; then
  echo "ModelSim suite finished with $fails failing test(s)."
  exit 1
fi

echo "All Tomasulo ModelSim tests passed."
