#!/bin/bash

set -e

# --- Configuration ---
INSTALL_DIR="$(pwd)"
DEFAULT_OPENWEBUI_DATA=~/openwebui-data
DEFAULT_OLLAMA_DATA=~/ollama-data

# --- Helper Functions ---
function check_docker() {
  if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed."
    echo "Please install Docker Desktop from https://www.docker.com/products/docker-desktop"
    exit 1
  fi
  
  if ! docker info >/dev/null 2>&1; then
    echo "❌ Docker is not running."
    echo "Please start Docker Desktop and rerun the script."
    exit 1
  fi
  echo "✅ Docker is running."
}

function check_system_requirements() {
  echo "Checking system requirements..."
  
  # Check available RAM
  TOTAL_RAM_GB=$(( $(sysctl -n hw.memsize) / 1024 / 1024 / 1024 ))
  echo "💻 Available RAM: ${TOTAL_RAM_GB}GB"
  
  # Check available disk space (in GB)
  AVAILABLE_DISK_GB=$(df -BG "$HOME" | awk 'NR==2 {print $4}' | sed 's/G//')
  echo "💾 Available disk space: ${AVAILABLE_DISK_GB}GB"
  
  if [ "$AVAILABLE_DISK_GB" -lt 50 ]; then
    echo "⚠️ Warning: You have less than 50GB of available disk space."
    echo "   The model download may require significant storage."
    read -p "Do you want to continue? (y/N): " continue_choice
    if [[ ! "$continue_choice" =~ ^[Yy]$ ]]; then
      echo "Installation cancelled."
      exit 1
    fi
  fi
}

function check_ollama() {
  if ! command -v ollama &> /dev/null; then
    echo "❌ Ollama is not installed."
    echo "Installing Ollama..."
    if command -v brew &> /dev/null; then
      brew install ollama
    else
      curl -fsSL https://ollama.ai/install.sh | sh
    fi
  fi
  echo "✅ Ollama is available."
}

function prompt_for_paths() {
  read -e -p "Enter path for OpenWebUI data [$DEFAULT_OPENWEBUI_DATA]: " OPENWEBUI_DATA_PATH
  OPENWEBUI_DATA_PATH=${OPENWEBUI_DATA_PATH:-$DEFAULT_OPENWEBUI_DATA}

  read -e -p "Enter path for Ollama data [$DEFAULT_OLLAMA_DATA]: " OLLAMA_DATA_PATH
  OLLAMA_DATA_PATH=${OLLAMA_DATA_PATH:-$DEFAULT_OLLAMA_DATA}

  # Expand tilde
  OPENWEBUI_DATA_PATH=$(eval echo "$OPENWEBUI_DATA_PATH")
  OLLAMA_DATA_PATH=$(eval echo "$OLLAMA_DATA_PATH")
}

# --- Main Script ---
echo "🚀 OpenAI Model Installer for macOS"
echo "=====================================\n"

check_system_requirements
check_docker
check_ollama

echo ""
echo "Select an OpenAI model to install:"
echo "1) gpt-oss-20b  - Optimized for personal computers (~24GB+ RAM recommended)"
echo "2) gpt-oss-120b - Requires a dedicated GPU (~48GB+ VRAM recommended)"
echo ""
read -p "Your choice [1-2]: " model_choice

case $model_choice in
    1)
        MODEL="gpt-oss-20b"
        MODEL_REPO="openai/gpt-oss-20b"
        RAM_REQUIREMENT="24GB+ RAM"
        ;;
    2)
        MODEL="gpt-oss-120b"
        MODEL_REPO="openai/gpt-oss-120b"
        RAM_REQUIREMENT="48GB+ VRAM (dedicated GPU)"
        ;;
    *)
        echo "Invalid choice. Exiting."
        exit 1
        ;;
esac

echo "You selected: $MODEL"
echo ""

prompt_for_paths

echo ""
echo "Creating data directories..."
mkdir -p "$OPENWEBUI_DATA_PATH"
mkdir -p "$OLLAMA_DATA_PATH"

echo ""
echo "Pulling Docker images..."
docker pull ollama/ollama
docker pull ghcr.io/open-webui/open-webui:main

echo ""
echo "Starting Ollama container..."
# Remove existing container if it exists
docker rm -f ollama 2>/dev/null || true

docker run -d \
  --name ollama \
  --restart unless-stopped \
  -v "$OLLAMA_DATA_PATH:/root/.ollama" \
  -p 11434:11434 \
  --network bridge \
  ollama/ollama

# Wait for Ollama to be ready
echo "Waiting for Ollama to start..."
sleep 10

echo ""
echo "Attempting to pull the model from Hugging Face via Ollama..."
if ollama pull "$MODEL_REPO"; then
  echo "✅ Model '$MODEL' pulled successfully."
else
  echo "❌ Failed to pull the model."
  echo "Please ensure you have enough disk space and that the model repository '$MODEL_REPO' is correct."
  exit 1
fi
echo ""
echo "Starting Open WebUI container..."
# Remove existing container if it exists
docker rm -f openwebui 2>/dev/null || true

docker run -d \
  --name openwebui \
  --restart unless-stopped \
  -v "$OPENWEBUI_DATA_PATH:/app/backend/data" \
  -e "OLLAMA_API_BASE_URL=http://localhost:11434" \
  -p 3000:3000 \
  --network bridge \
  ghcr.io/open-webui/open-webui:main

echo ""
echo "🎉 Setup complete!"
echo "=================="
echo ""
echo "✅ Model: $MODEL ($RAM_REQUIREMENT)"
echo "✅ OpenWebUI: http://localhost:3000"
echo "✅ Ollama API: http://localhost:11434"
echo ""
echo "📋 Next steps:"
echo "1. Open your web browser and go to http://localhost:3000"
echo "2. Create an account or sign in"
echo "3. Start chatting with your $MODEL model!"
echo ""
echo "💡 Tip: The first response may take a moment as the model loads into memory."
echo ""
echo "🛠️  To stop the services:"
echo "   docker stop ollama openwebui"
echo ""
echo "🔄 To restart the services:"
echo "   docker start ollama openwebui"

