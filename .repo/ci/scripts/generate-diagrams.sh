#!/usr/bin/env bash
set -euo pipefail
echo "🎨 Generating diagrams with doctoolchain..."
./gradlew generateDiagrams
