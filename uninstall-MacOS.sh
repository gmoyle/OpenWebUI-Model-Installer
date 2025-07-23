#!/bin/bash

set -e

INSTALL_DIR="$(pwd)"
DATA_DIR="$HOME/openwebui-ollama-data"
DOCKER_COMPOSE_YML="$INSTALL_DIR/docker-compose.yml"
VOLUME_NAME="ollama_data"
FORCE=false

# Parse args
if [[ "$1" == "--force" ]]; then
  FORCE=true
fi

echo "🧹 Open WebUI + Ollama Uninstaller"

# Helper to print and exit
function fail() {
  echo "❌ $1"
  exit 1
}

# Confirmation unless forced
if [[ "$FORCE" == false ]]; then
  read -p "⚠️ This will remove containers, volumes, and local data. Are you sure? [y/N]: " confirm
  if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    echo "❌ Uninstall canceled."
    exit 0
  fi
fi

# Check Docker
if ! command -v docker &>/dev/null; then
  fail "Docker is not installed. Nothing to uninstall."
fi

if ! docker info &>/dev/null; then
  fail "Docker is installed but not running. Please start Docker Desktop to continue."
fi

# Stop and remove containers
echo "🛑 Stopping and removing containers..."
docker stop openwebui ollama || true
docker rm openwebui ollama || true

# Remove images
echo "🧼 Removing Docker images..."
docker rmi ollama/ollama ghcr.io/open-webui/open-webui:main || true

# Remove volumes
echo "🧼 Removing Docker volumes..."
docker volume rm "$VOLUME_NAME" || true

# Remove data directory
if [[ -d "$DATA_DIR" ]]; then
  echo "🗑️ Removing data directory: $DATA_DIR"
  rm -rf "$DATA_DIR"
else
  echo "ℹ️ No data directory found at $DATA_DIR"
fi

echo "✅ Uninstallation complete."
