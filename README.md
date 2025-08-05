# 🚀 OpenWebUI Model Installer

**The ultimate one-click installer for OpenWebUI with advanced AI models including OpenAI's latest local models!**

This installer provides a seamless setup experience for **OpenWebUI** + **Ollama** with support for cutting-edge AI models, including OpenAI's newly released laptop-compatible models (`gpt-oss:20b` and `gpt-oss:120b`) alongside popular lightweight models for **Arena mode** comparisons.

## ✨ Features

🔥 **Latest OpenAI Models**: First-class support for `gpt-oss:20b` and `gpt-oss:120b`  
🏟️ **Arena Mode Ready**: Install multiple models for side-by-side comparisons  
🧠 **Smart Installation Detection**: Add models to existing setups without reinstalling  
⚡ **8 Optimized Models**: From ultra-fast 2B to advanced 120B parameter models  
💻 **macOS Optimized**: Native compatibility with Apple Silicon and Intel Macs  
🔄 **Incremental Updates**: Run the script multiple times to build your model collection  
📊 **RAM-Aware Recommendations**: Automatic model suggestions based on your system specs

## 🎯 Quick Start

### One-Line Installation

```bash
curl -fsSL https://raw.githubusercontent.com/gmoyle/OpenWebUI-Model-Installer/main/install-OpenAI-MacOS.sh | bash
```

### Manual Installation

1. **Download and run the installer**:
   ```bash
   wget https://raw.githubusercontent.com/gmoyle/OpenWebUI-Model-Installer/main/install-OpenAI-MacOS.sh
   chmod +x install-OpenAI-MacOS.sh
   ./install-OpenAI-MacOS.sh
   ```

2. **Follow the interactive prompts** to select your preferred models
3. **Access OpenWebUI** at `http://localhost:3000`
4. **Start chatting** with your AI models!

## 🤖 Available Models

### 🚀 OpenAI Models (Advanced Reasoning)
| Model | Size | RAM Required | Description |
|-------|------|--------------|-------------|
| `gpt-oss:20b` | 13 GB | 16GB+ | Advanced reasoning and complex problem-solving |
| `gpt-oss:120b` | 65 GB | 60GB+ | Most advanced model with superior capabilities |

### ⚡ Premium Models (Fast & Capable)
| Model | Size | RAM Required | Description |
|-------|------|--------------|-------------|
| `mistral` | 4.4 GB | 8GB | Fast, reliable European model with great performance |
| `llama3.2` | 2.0 GB | 4GB | Latest Meta model with improved efficiency |
| `qwen2.5:3b` | 1.9 GB | 4GB | Alibaba's model excellent for reasoning tasks |

### 🏃 Lightweight Models (Ultra Fast)
| Model | Size | RAM Required | Description |
|-------|------|--------------|-------------|
| `phi3` | 2.2 GB | 4GB | Microsoft's optimized model for resource efficiency |
| `gemma2:2b` | 1.6 GB | 3GB | Google's ultra-fast model for quick responses |

### 🛠️ Specialized Models
| Model | Size | RAM Required | Description |
|-------|------|--------------|-------------|
| `codellama` | 3.8 GB | 12GB+ | Meta's specialized model for code generation and programming |

## 🏟️ Arena Mode

The installer includes an **Arena Mode** setup that automatically selects the best combination of models for your system:

- **24GB+ RAM**: 5 models (phi3, gemma2:2b, llama3.2, qwen2.5:3b, mistral)
- **16-24GB RAM**: 4 models (optimized selection)
- **12-16GB RAM**: 3 lightweight models

This allows you to compare different models side-by-side in OpenWebUI's Arena interface!

## 🔄 Smart Installation Management

### First Time Installation
- Automatically installs Docker (if needed)
- Sets up OpenWebUI and Ollama containers
- Installs your selected models
- Provides complete setup instructions

### Adding More Models
Run the script again to:
- Detect your existing installation
- Add new models without reinstalling containers
- Maintain all your existing data and configurations
- Build your model collection incrementally

### Fresh Installation
Option to completely remove existing setup and start fresh if needed.

## 💻 System Requirements

- **macOS** (Intel or Apple Silicon)
- **Docker Desktop** (auto-installed if missing)
- **50GB+ free disk space** (for model storage)
- **RAM requirements** vary by model (see table above)
- **Internet connection** for downloading models

## 🚀 Usage Examples

### Install a Single Model
```bash
# Run the installer and select option 6 for phi3
curl -fsSL https://raw.githubusercontent.com/gmoyle/OpenWebUI-Model-Installer/main/install-OpenAI-MacOS.sh | bash
```

### Install Arena Mode (Multiple Models)
```bash
# Run the installer and select option 9 for Arena setup
curl -fsSL https://raw.githubusercontent.com/gmoyle/OpenWebUI-Model-Installer/main/install-OpenAI-MacOS.sh | bash
```

### Add Models to Existing Installation
```bash
# The script automatically detects existing installations
curl -fsSL https://raw.githubusercontent.com/gmoyle/OpenWebUI-Model-Installer/main/install-OpenAI-MacOS.sh | bash
# Select "Install additional models" when prompted
```

---

## Troubleshooting

If you run into any issues during installation or uninstallation, the following steps may help:

1. **Docker Not Running**:
   - Ensure **Docker Desktop** is running. If it’s not, start Docker and try again.
   
2. **WSL2 Configuration (Windows Only)**:
   - If **WSL2** is not installed, the script will automatically install it for you.
   
3. **Disk Space**:
   - Ensure you have enough disk space (at least 30GB free) for Docker containers to function smoothly.

4. **Permissions**:
   - Ensure the script is run with **Administrator** privileges on Windows, or with **sudo** on macOS if needed.

---

## FAQ

### **Q: Do I need to manually install Docker?**
- **A**: No, the script will automatically install Docker if it's not already installed. For Windows, it uses **Chocolatey** to install Docker Desktop, and for macOS, it uses **Homebrew**.

### **Q: What if I don’t have **WSL2** (Windows Only)?**
- **A**: If **WSL2** is not installed, the script will automatically install it for you.

### **Q: What happens if I run the script without administrator rights?**
- **A**: If you don't run the script as **Administrator** on Windows, it will prompt you to do so. On macOS, you’ll be asked to use `sudo` if necessary.

### **Q: Can I change the default model used by **Ollama**?**
- **A**: Yes, the installation script detects your available memory and will prompt you to select the best model for your system. You can also modify the `docker-compose.yml` file manually for custom configurations.

---

### Contribution

Feel free to fork the repository and create pull requests to improve these scripts. If you encounter any issues, open an issue in the **Issues** section of this repository.

---

### License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---
