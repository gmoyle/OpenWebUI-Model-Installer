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
  
  if ! docker info > /dev/null 2>&1; then
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

function check_existing_installation() {
  OLLAMA_RUNNING=false
  OPENWEBUI_RUNNING=false
  
  # Check if containers exist and are running
  if docker ps -q -f name=ollama | grep -q .; then
    OLLAMA_RUNNING=true
  fi
  
  if docker ps -q -f name=openwebui | grep -q .; then
    OPENWEBUI_RUNNING=true
  fi
  
  if [ "$OLLAMA_RUNNING" = true ] && [ "$OPENWEBUI_RUNNING" = true ]; then
    return 0  # Installation exists
  else
    return 1  # No existing installation
  fi
}

function show_existing_models() {
  echo "📚 Currently installed models:"
  if docker exec ollama ollama list 2>/dev/null | grep -v "NAME" | grep -v "^$"; then
    echo ""
  else
    echo "   No models installed yet."
    echo ""
  fi
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
echo "=================================="
echo ""

check_system_requirements
check_docker
check_ollama

# Check if installation already exists
if check_existing_installation; then
  echo "✅ Found existing OpenWebUI + Ollama installation!"
  echo "   OpenWebUI: http://localhost:3000"
  echo "   Ollama API: http://localhost:11434"
  echo ""
  show_existing_models
  echo "What would you like to do?"
  echo "1) Install additional models"
  echo "2) Fresh install (remove existing setup)"
  echo "3) Exit"
  echo ""
  printf "Your choice [1-3]: "
  read action_choice </dev/tty
  echo ""
  
  case $action_choice in
    1)
      EXISTING_INSTALL=true
      ;;
    2)
      echo "Removing existing containers..."
      docker stop ollama openwebui 2>/dev/null || true
      docker rm ollama openwebui 2>/dev/null || true
      echo "Existing setup removed. Starting fresh installation..."
      EXISTING_INSTALL=false
      ;;
    3)
      echo "Exiting..."
      exit 0
      ;;
    *)
      echo "Invalid choice. Exiting."
      exit 1
      ;;
  esac
else
  EXISTING_INSTALL=false
fi

echo "Select a model to install:"
echo ""
echo "🚀 OpenAI Models (Advanced):"
echo "1) gpt-oss:20b   - 🔥 Advanced reasoning | 20B  | ~16GB+ VRAM/RAM"
echo "2) gpt-oss:120b  - 🔥 Most advanced     | 120B | ~60GB+ VRAM/RAM"
echo ""
echo "⚡ Premium Models (Fast & Capable):"
echo "3) mistral       - ⚡⚡⚡ Fast          | 7B   | ~8GB RAM"
echo "4) llama3.2      - ⚡⚡ Latest Meta     | 3B   | ~4GB RAM"
echo "5) qwen2.5:3b    - ⚡⚡ Great reasoning | 3B   | ~4GB RAM"
echo ""
echo "🏃 Lightweight Models (Very Fast):"
echo "6) phi3          - ⚡⚡⚡⚡ Very Fast      | 3.8B | ~4GB RAM"
echo "7) gemma2:2b     - ⚡⚡⚡⚡ Ultra Fast    | 2B   | ~3GB RAM"
echo ""
echo "🛠️  Specialized Models:"
echo "8) codellama     - 💻 Code-focused     | 13B  | ~12GB+ RAM"
echo "9) Install multiple models (Arena mode setup)"
echo ""
printf "Your choice [1-9]: "
read model_choice </dev/tty

case $model_choice in
    1)
        MODELS=("gpt-oss:20b")
        RAM_REQUIREMENTS=("16GB+ VRAM/RAM")
        MODEL_TYPES=("openai")
        ;;
    2)
        MODELS=("gpt-oss:120b")
        RAM_REQUIREMENTS=("60GB+ VRAM/RAM")
        MODEL_TYPES=("openai")
        ;;
    3)
        MODELS=("mistral")
        RAM_REQUIREMENTS=("8GB RAM")
        MODEL_TYPES=("ollama")
        ;;
    4)
        MODELS=("llama3.2")
        RAM_REQUIREMENTS=("4GB RAM")
        MODEL_TYPES=("ollama")
        ;;
    5)
        MODELS=("qwen2.5:3b")
        RAM_REQUIREMENTS=("4GB RAM")
        MODEL_TYPES=("ollama")
        ;;
    6)
        MODELS=("phi3")
        RAM_REQUIREMENTS=("4GB RAM")
        MODEL_TYPES=("ollama")
        ;;
    7)
        MODELS=("gemma2:2b")
        RAM_REQUIREMENTS=("3GB RAM")
        MODEL_TYPES=("ollama")
        ;;
    8)
        MODELS=("codellama")
        RAM_REQUIREMENTS=("12GB+ RAM")
        MODEL_TYPES=("ollama")
        ;;
    9)
        if [ "$TOTAL_RAM_GB" -ge 16 ]; then
          MODELS=("phi3" "gemma2:2b" "llama3.2" "qwen2.5:3b" "mistral")
          RAM_REQUIREMENTS=("4GB" "3GB" "4GB" "4GB" "8GB")
          MODEL_TYPES=("ollama" "ollama" "ollama" "ollama" "ollama")
          echo "🏟️  Installing Arena setup (5 models for comparison)"
        elif [ "$TOTAL_RAM_GB" -ge 12 ]; then
          MODELS=("phi3" "gemma2:2b" "llama3.2" "qwen2.5:3b")
          RAM_REQUIREMENTS=("4GB" "3GB" "4GB" "4GB")
          MODEL_TYPES=("ollama" "ollama" "ollama" "ollama")
          echo "🏟️  Installing Arena setup (4 models - optimized for your RAM)"
        else
          MODELS=("phi3" "gemma2:2b" "llama3.2")
          RAM_REQUIREMENTS=("4GB" "3GB" "4GB")
          MODEL_TYPES=("ollama" "ollama" "ollama")
          echo "🏟️  Installing Arena setup (3 lightweight models for your system)"
        fi
        ;;
    *)
        echo "Invalid choice. Exiting."
        exit 1
        ;;
esac

# Show selection summary
if [ ${#MODELS[@]} -eq 1 ]; then
  echo "You selected: ${MODELS[0]} (${RAM_REQUIREMENTS[0]})"
else
  echo "You selected ${#MODELS[@]} models for Arena mode:"
  for i in "${!MODELS[@]}"; do
    echo "  - ${MODELS[$i]} (${RAM_REQUIREMENTS[$i]})"
  done
fi
echo ""

# Set up containers only if not existing installation
if [ "$EXISTING_INSTALL" = false ]; then
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
  docker run -d \
    --name ollama \
    --restart unless-stopped \
    -v "$OLLAMA_DATA_PATH:/root/.ollama" \
    -p 11434:11434 \
    ollama/ollama
  
  # Wait for Ollama to be ready
  echo "Waiting for Ollama to start..."
  sleep 10
  
  echo ""
  echo "Starting Open WebUI container..."
  docker run -d \
    --name openwebui \
    --restart unless-stopped \
    -v "$OPENWEBUI_DATA_PATH:/app/backend/data" \
    -e "OLLAMA_BASE_URL=http://host.docker.internal:11434" \
    -p 3000:8080 \
    ghcr.io/open-webui/open-webui:main
  
  echo "Waiting for OpenWebUI to start..."
  sleep 5
fi

# Install models
echo ""
echo "Installing selected models..."
SUCCESSFUL_MODELS=()
FAILED_MODELS=()

for i in "${!MODELS[@]}"; do
  MODEL="${MODELS[$i]}"
  MODEL_TYPE="${MODEL_TYPES[$i]}"
  
  echo ""
  if [[ "$MODEL_TYPE" == "openai" ]]; then
    echo "Installing OpenAI model: $MODEL"
  else
    echo "Installing model: $MODEL"
  fi
  
  if docker exec ollama ollama pull "$MODEL"; then
    echo "✅ Model '$MODEL' installed successfully."
    SUCCESSFUL_MODELS+=("$MODEL")
  else
    echo "❌ Failed to install model '$MODEL'."
    FAILED_MODELS+=("$MODEL")
  fi
done

echo ""
echo "🎉 Installation Summary"
echo "======================="
echo ""
if [ ${#SUCCESSFUL_MODELS[@]} -gt 0 ]; then
  echo "✅ Successfully installed models:"
  for model in "${SUCCESSFUL_MODELS[@]}"; do
    echo "   - $model"
  done
fi

if [ ${#FAILED_MODELS[@]} -gt 0 ]; then
  echo ""
  echo "❌ Failed to install models:"
  for model in "${FAILED_MODELS[@]}"; do
    echo "   - $model"
  done
  echo "   Please check your internet connection and disk space."
fi

echo ""
echo "✅ OpenWebUI: http://localhost:3000"
echo "✅ Ollama API: http://localhost:11434"
echo ""
if [ ${#SUCCESSFUL_MODELS[@]} -gt 1 ]; then
  echo "🏟️  Arena Mode Ready! You can now compare multiple models side-by-side."
  echo ""
fi
echo "📋 Next steps:"
echo "1. Open your web browser and go to http://localhost:3000"
echo "2. Create an account or sign in"
if [ ${#SUCCESSFUL_MODELS[@]} -gt 1 ]; then
  echo "3. Try Arena mode to compare your models!"
else
  echo "3. Start chatting with your model!"
fi
echo ""
echo "💡 Tip: The first response may take a moment as models load into memory."
echo ""
echo "🛠️  To stop the services:"
echo "   docker stop ollama openwebui"
echo ""
echo "🔄 To restart the services:"
echo "   docker start ollama openwebui"
echo ""
echo "🔄 To run this script again to add more models:"
echo "   curl -fsSL https://raw.githubusercontent.com/gmoyle/OpenWebUI-Model-Installer/main/install-OpenAI-MacOS.sh | bash"

