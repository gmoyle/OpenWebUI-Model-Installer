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
  
  # Check available disk space (in GB) - macOS compatible
  AVAILABLE_DISK_GB=$(df -h "$HOME" | awk 'NR==2 {print $4}' | sed 's/[^0-9]*//g')
  if [[ "$AVAILABLE_DISK_GB" =~ ^[0-9]+$ ]]; then
    echo "💾 Available disk space: ${AVAILABLE_DISK_GB}GB"
    
    if [ "$AVAILABLE_DISK_GB" -lt 50 ]; then
      echo "⚠️ Warning: You have less than 50GB of available disk space."
      echo "   The model download may require significant storage."
      printf "Do you want to continue? (y/N): "
      read continue_choice </dev/tty
      if [[ ! "$continue_choice" =~ ^[Yy]$ ]]; then
        echo "Installation cancelled."
        exit 1
      fi
    fi
  else
    echo "💾 Available disk space: Unable to determine"
    echo "⚠️ Please ensure you have at least 50GB of free disk space"
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
  printf "Enter path for OpenWebUI data [$DEFAULT_OPENWEBUI_DATA]: "
  read OPENWEBUI_DATA_PATH </dev/tty
  OPENWEBUI_DATA_PATH=${OPENWEBUI_DATA_PATH:-$DEFAULT_OPENWEBUI_DATA}

  printf "Enter path for Ollama data [$DEFAULT_OLLAMA_DATA]: "
  read OLLAMA_DATA_PATH </dev/tty
  OLLAMA_DATA_PATH=${OLLAMA_DATA_PATH:-$DEFAULT_OLLAMA_DATA}

  # Expand tilde
  OPENWEBUI_DATA_PATH=$(eval echo "$OPENWEBUI_DATA_PATH")
  OLLAMA_DATA_PATH=$(eval echo "$OLLAMA_DATA_PATH")
}

# --- Main Script ---
echo "🚀 AI Model Installer for macOS"
echo "==================================\n"

check_system_requirements
check_docker
check_ollama

echo ""
echo "Select a model to install:"
echo ""
echo "🚀 OpenAI Models (New):"
echo "1) gpt-oss-20b   - 🔥 Advanced reasoning | 20B  | ~24GB+ RAM"
echo "2) gpt-oss-120b  - 🔥 Most advanced     | 120B | ~48GB+ VRAM (GPU required)"
echo ""
echo "⚡ Ollama Models (Fast & Lightweight):"
echo "3) phi3          - ⚡⚡⚡⚡ Very Fast      | 3.8B | ~4GB RAM"
echo "4) mistral       - ⚡⚡⚡ Fast          | 7B   | ~8GB RAM"
echo "5) llama3        - ⚡⚡ Moderate        | 8B   | ~8GB+ RAM"
echo "6) codellama     - ⚡ Code-focused     | 13B  | ~12GB+ RAM"
echo ""
printf "Your choice [1-6]: "
read model_choice </dev/tty

case $model_choice in
    1)
        MODEL="gpt-oss-20b"
        MODEL_REPO="openai/gpt-oss-20b"
        RAM_REQUIREMENT="24GB+ RAM"
        MODEL_TYPE="openai"
        ;;
    2)
        MODEL="gpt-oss-120b"
        MODEL_REPO="openai/gpt-oss-120b"
        RAM_REQUIREMENT="48GB+ VRAM (dedicated GPU)"
        MODEL_TYPE="openai"
        ;;
    3)
        MODEL="phi3"
        MODEL_REPO="phi3"
        RAM_REQUIREMENT="4GB RAM"
        MODEL_TYPE="ollama"
        ;;
    4)
        MODEL="mistral"
        MODEL_REPO="mistral"
        RAM_REQUIREMENT="8GB RAM"
        MODEL_TYPE="ollama"
        ;;
    5)
        MODEL="llama3"
        MODEL_REPO="llama3"
        RAM_REQUIREMENT="8GB+ RAM"
        MODEL_TYPE="ollama"
        ;;
    6)
        MODEL="codellama"
        MODEL_REPO="codellama"
        RAM_REQUIREMENT="12GB+ RAM"
        MODEL_TYPE="ollama"
        ;;
    *)
        echo "Invalid choice. Exiting."
        exit 1
        ;;
esac

echo "You selected: $MODEL ($RAM_REQUIREMENT)"

# Provide RAM recommendations based on system memory
if [[ "$MODEL_TYPE" == "openai" ]]; then
  if [[ "$MODEL" == "gpt-oss-120b" ]] && [ "$TOTAL_RAM_GB" -lt 48 ]; then
    echo "⚠️  Warning: Your system has ${TOTAL_RAM_GB}GB RAM, but this model works best with 48GB+ VRAM."
    echo "   Consider using gpt-oss-20b or one of the lighter Ollama models for better performance."
  elif [[ "$MODEL" == "gpt-oss-20b" ]] && [ "$TOTAL_RAM_GB" -lt 24 ]; then
    echo "⚠️  Warning: Your system has ${TOTAL_RAM_GB}GB RAM, but this model works best with 24GB+."
    echo "   Consider using one of the lighter Ollama models for better performance."
  fi
else
  # Recommendations for Ollama models
  if [[ "$MODEL" == "codellama" ]] && [ "$TOTAL_RAM_GB" -lt 12 ]; then
    echo "⚠️  Your system has ${TOTAL_RAM_GB}GB RAM. Consider phi3 or mistral for better performance."
  elif [[ "$MODEL" == "llama3" || "$MODEL" == "mistral" ]] && [ "$TOTAL_RAM_GB" -lt 8 ]; then
    echo "⚠️  Your system has ${TOTAL_RAM_GB}GB RAM. Consider phi3 for better performance."
  elif [[ "$MODEL" == "phi3" ]]; then
    echo "✅ Great choice! Phi3 is optimized for systems with limited resources."
  fi
fi
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
if [[ "$MODEL_TYPE" == "openai" ]]; then
  echo "Attempting to pull the OpenAI model from Hugging Face via Ollama..."
else
  echo "Attempting to pull the model via Ollama..."
fi

if ollama pull "$MODEL_REPO"; then
  echo "✅ Model '$MODEL' pulled successfully."
else
  echo "❌ Failed to pull the model."
  if [[ "$MODEL_TYPE" == "openai" ]]; then
    echo "Please ensure you have enough disk space and internet connectivity."
    echo "The OpenAI models are large and may take time to download."
  else
    echo "Please ensure you have enough disk space and that the model '$MODEL_REPO' is available."
  fi
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

