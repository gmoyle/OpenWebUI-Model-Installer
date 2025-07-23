#!/bin/bash

set -e

INSTALL_DIR="$(pwd)"
DATA_DIR="$HOME/openwebui-ollama-data"
DOCKER_COMPOSE_YML="$INSTALL_DIR/docker-compose.yml"
VOLUME_NAME="ollama_data"
MODEL="phi3" # Default model, can be changed in script

# Set paths
DEFAULT_OPENWEBUI_DATA=~/openwebui-data
DEFAULT_OLLAMA_DATA=~/ollama-data

# Prompt for model
echo "Select a model by number (1-4):"
echo "1) phi3        - ⚡⚡⚡⚡ Very Fast | 3.8B | ~4GB RAM"
echo "2) mistral     - ⚡⚡ Moderate    | 7B   | ~8GB RAM"
echo "3) llama3      - ⚡  Slower      | 8B   | ~8GB+ RAM"
echo "4) codellama   - 🐌 Slowest     | 13B  | ~12GB+ RAM"
echo ""
read -p "Your choice [1-4]: " model_choice

case $model_choice in
    1)
        MODEL="phi3"
        ;;
    2)
        MODEL="mistral"
        ;;
    3)
        MODEL="llama3"
        ;;
    4)
        MODEL="codellama"
        ;;
    *)
        echo "Invalid choice, defaulting to phi3."
        MODEL="phi3"
        ;;
esac

echo "You selected: $MODEL"
echo ""

read -e -p "Enter path for OpenWebUI data [$DEFAULT_OPENWEBUI_DATA]: " OPENWEBUI_DATA_PATH
OPENWEBUI_DATA_PATH=${OPENWEBUI_DATA_PATH:-~/openwebui-data}

read -e -p "Enter path for Ollama data [$DEFAULT_OLLAMA_DATA]: " OLLAMA_DATA_PATH
OLLAMA_DATA_PATH=${OLLAMA_DATA_PATH:-~/ollama-data}

# Expand ~
OPENWEBUI_DATA_PATH=$(eval echo $OPENWEBUI_DATA_PATH)
OLLAMA_DATA_PATH=$(eval echo $OLLAMA_DATA_PATH)

# Create directories
echo ""
echo "Creating data directories..."
mkdir -p "$OPENWEBUI_DATA_PATH"
mkdir -p "$OLLAMA_DATA_PATH"

# Pull Docker images
echo ""
echo "Pulling Docker images..."
docker pull ollama/ollama
docker pull ghcr.io/open-webui/open-webui:main

# Start Ollama container
echo ""
echo "Starting Ollama container..."
docker run -d \
  --name ollama \
  --restart unless-stopped \
  -v "$OLLAMA_DATA_PATH:/root/.ollama" \
  -p 11434:11434 \
  --network bridge \
  ollama/ollama

# Wait for Ollama to be ready
echo ""
echo "Waiting for Ollama to start..."
until curl -s http://localhost:11434/api/tags >/dev/null; do
  sleep 1
done

# Pull the selected model
echo ""
echo "Pulling model: $MODEL ..."
ollama pull "$MODEL"

# Start Open WebUI container
echo ""
echo "Starting Open WebUI container..."
docker run -d \
  --name openwebui \
  --restart unless-stopped \
  -v "$OPENWEBUI_DATA_PATH:/app/backend/data" \
  -e "OLLAMA_API_BASE_URL=http://localhost:11434" \
  -p 3000:3000 \
  --network bridge \
  ghcr.io/open-webui/open-webui:main

# Completion
echo ""
echo "✅ Setup complete!"
echo "Visit: http://localhost:3000"
