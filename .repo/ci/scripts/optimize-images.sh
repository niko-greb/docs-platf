#!/usr/bin/env bash
set -euo pipefail
echo "🪶 Optimizing images..."
find docs -type f \( -name "*.png" -o -name "*.jpg" \) | while read -r img; do
  echo "🔧 Compressing $img"
  mogrify -strip -interlace Plane -sampling-factor 4:2:0 -quality 85 "$img"
done
