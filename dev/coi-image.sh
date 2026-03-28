#!/bin/bash

# This script provides a simple interface for managing the 'mneme-dev'
# image using the 'coi' development tool. It supports building,
# starting a shell, listing, and deleting images.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IMAGE_NAME="mneme-dev"

# Parse command line arguments
case "${1:-}" in
  build)
    # Ensure the 'coi' command is available
    if ! command -v coi &> /dev/null; then
      echo "Error: 'coi' command not found. Please install it or ensure it's in your PATH." >&2
      exit 1
    fi
    # Check for the existence of the build script before attempting to build
    if [[ ! -f "$SCRIPT_DIR/coi-build.sh" ]]; then
      echo "Error: 'coi-build.sh' not found in $SCRIPT_DIR." >&2
      exit 1
    fi
    echo "Building image $IMAGE_NAME..."
    coi build custom "$IMAGE_NAME" --base coi --compression none --script "$SCRIPT_DIR/coi-build.sh"
    ;;
  lint)
    echo "Checking script syntax..."
    bash -n "$SCRIPT_DIR/coi-build.sh" "$SCRIPT_DIR/coi-image.sh" "$SCRIPT_DIR/validate-env.sh"
    echo "Checking script permissions..."
    for script in coi-build.sh coi-image.sh validate-env.sh; do
      if [[ ! -x "$SCRIPT_DIR/$script" ]]; then
        echo "Error: '$script' is not executable. Run 'chmod +x $SCRIPT_DIR/$script'." >&2
        exit 1
      fi
    done
    echo "Linting passed."
    ;;
  shell)
    # Ensure the 'coi' command is available
    if ! command -v coi &> /dev/null; then
      echo "Error: 'coi' command not found. Please install it or ensure it's in your PATH." >&2
      exit 1
    fi
    echo "Starting shell in $IMAGE_NAME..."
    echo "Note: You can run 'dev/validate-env.sh' inside the container to verify the toolchain."
    coi shell --image "$IMAGE_NAME"
    ;;
  list)
    # Ensure the 'coi' command is available
    if ! command -v coi &> /dev/null; then
      echo "Error: 'coi' command not found. Please install it or ensure it's in your PATH." >&2
      exit 1
    fi
    coi image list --prefix mneme-
    ;;
  delete)
    # Ensure the 'coi' command is available
    if ! command -v coi &> /dev/null; then
      echo "Error: 'coi' command not found. Please install it or ensure it's in your PATH." >&2
      exit 1
    fi
    echo "Deleting image $IMAGE_NAME..."
    coi image delete "$IMAGE_NAME"
    ;;
  *)
    echo "Usage: $0 {build|shell|list|delete|lint}"
    echo ""
    echo "Commands:"
    echo "  build   Build the 'mneme-dev' development image."
    echo "  shell   Enter a shell in the development container."
    echo "  list    List existing 'mneme-' images."
    echo "  delete  Delete the 'mneme-dev' image."
    echo "  lint    Run syntax checks and verify permissions for scripts."
    echo ""
    echo "Validation:"
    echo "  Once inside the shell, run 'dev/validate-env.sh' to verify the environment."
    exit 1
    ;;
esac
