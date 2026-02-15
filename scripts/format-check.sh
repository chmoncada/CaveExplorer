#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

swift run --package-path Tools swift-format lint \
  --recursive \
  --configuration .swift-format \
  CaveExplorer/Sources CaveExplorer/Tests
