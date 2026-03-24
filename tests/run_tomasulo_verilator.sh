#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

verilator --lint-only --timing -Wall -Wno-fatal -Wno-EOFNEWLINE -Wno-UNUSEDSIGNAL -Wno-INITIALDLY --top-module testbench src/*.sv

echo "Verilator lint complete for Project2 Tomasulo test setup."
