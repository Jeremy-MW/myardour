#!/bin/bash
# Generate revision.cc for Ardour build

cd "$(dirname "${BASH_SOURCE[0]}")/../ardour"

rev=$(git describe --tags 2>/dev/null || git rev-parse --short HEAD)
date_str=$(git log -1 --format='%ci')

cat > libs/ardour/revision.cc << EOF
namespace ARDOUR { const char* revision = "$rev"; const char* date = "$date_str"; }
EOF

echo "Generated libs/ardour/revision.cc with:"
cat libs/ardour/revision.cc
