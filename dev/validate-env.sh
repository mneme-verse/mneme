#!/bin/bash
set -euo pipefail

# This script verifies the toolchain components inside the development container.

echo "=== Toolchain Validation ==="

# Source bashrc to get PATH updates
source /etc/bash.bashrc 2>/dev/null || true

# Suppress Flutter's root warning when running in container
export CI=true

# 1. Flutter
echo -n "Flutter: "
if command -v flutter &> /dev/null; then
  flutter --version | head -n 1
else
  echo "MISSING"
  exit 1
fi

# 2. Android SDK
echo -n "Android SDK (sdkmanager): "
if command -v sdkmanager &> /dev/null; then
  sdkmanager --version
else
  echo "MISSING"
  exit 1
fi

# 3. OpenCode
echo -n "OpenCode: "
if command -v opencode &> /dev/null; then
  # opencode --version might not be supported, so we check existence
  opencode --version || echo "Available (version check failed)"
else
  echo "MISSING"
  exit 1
fi

# 4. RTK
echo -n "RTK: "
if command -v rtk &> /dev/null; then
  rtk --version || echo "Available (version check failed)"
else
  echo "MISSING"
  exit 1
fi

# 5. sqlite3
echo -n "sqlite3: "
if command -v sqlite3 &> /dev/null; then
  sqlite3 --version
else
  echo "MISSING"
  exit 1
fi

# 6. Superpowers plugin
echo -n "OpenCode Superpowers plugin: "
if command -v opencode &> /dev/null; then
  if opencode plugin list | grep -q "superpowers"; then
    echo "OK"
  else
    echo "MISSING"
    exit 1
  fi
else
  echo "N/A (OpenCode missing)"
  exit 1
fi

echo "=== All toolchain components verified successfully! ==="
